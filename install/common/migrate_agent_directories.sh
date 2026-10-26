#!/usr/bin/env bash
# @file migrate_agent_directories.sh
# @brief Preserve runtime-created files before replacing source-linked agent directories.
# @description Copies untracked files from legacy source directories into their real home targets before removing the source copies.
# @arg $1 Operation: check or migrate.
# @arg $2 Chezmoi source directory.
# @arg $3 Destination home directory.
# @example bash migrate_agent_directories.sh migrate "$source_dir" "$HOME"

set -euo pipefail

if [ "$#" -ne 3 ] || [[ "$1" != check && "$1" != migrate ]]; then
    printf 'Usage: %s check|migrate SOURCE_DIR HOME\n' "$0" >&2
    exit 2
fi

operation="$1"
source_dir="$(cd "$2" && pwd -P)"
destination_home="$(cd "$3" && pwd -P)"
repo_root="$(cd "$(git -C "$source_dir" rev-parse --show-toplevel)" && pwd -P)"
source_directories=(
    private_dot_config/claude/agents
    private_dot_config/claude/commands
    private_dot_config/claude/rules
    private_dot_config/exact_agents/agents
    private_dot_config/codex/agents
)
target_directories=(
    .claude/agents
    .claude/commands
    .claude/rules
    .agents/agents
    .codex/agents
)

umask 077
temporary_directory="$(mktemp -d "${TMPDIR:-/tmp}/chezmoi-agent-migration.XXXXXX")"
trap 'rm -rf "$temporary_directory"' EXIT
entries_file="$temporary_directory/entries"
manifest_file="$temporary_directory/manifest"
migrated_files=0
migrated_directories=0
found_files=0
found_directories=0
migration_errors=0

collect_untracked_files() {
    local legacy_directory="$1"
    local candidate repo_relative git_status
    : > "$manifest_file"
    candidate_count=0
    [ -d "$legacy_directory" ] || return 0
    find "$legacy_directory" \( -type f -o -type l \) -print0 > "$entries_file"
    while IFS= read -r -d '' candidate; do
        case "$candidate" in
        "$repo_root"/*) repo_relative="${candidate#"$repo_root"/}" ;;
        *)
            printf 'Source path is outside the repository: %s\n' "$candidate" >&2
            return 1
            ;;
        esac
        if git -C "$repo_root" ls-files --error-unmatch -- "$repo_relative" > /dev/null 2>&1; then
            continue
        else
            git_status=$?
            if [ "$git_status" -ne 1 ]; then
                printf 'Could not check tracked state for: %s\n' "$candidate" >&2
                return 1
            fi
        fi
        printf '%s\0' "$candidate" >> "$manifest_file"
        candidate_count=$((candidate_count + 1))
    done < "$entries_file"
}

file_modes_match() {
    local source_mode target_mode
    case "$(uname -s)" in
    Darwin)
        source_mode="$(stat -f '%Lp' "$1")"
        target_mode="$(stat -f '%Lp' "$2")"
        ;;
    *)
        source_mode="$(stat -c '%a' "$1")"
        target_mode="$(stat -c '%a' "$2")"
        ;;
    esac
    [ "$source_mode" = "$target_mode" ]
}

files_match() {
    if [ -L "$1" ] || [ -L "$2" ]; then
        [ -L "$1" ] && [ -L "$2" ] && [ "$(readlink "$1")" = "$(readlink "$2")" ]
    else
        [ -f "$1" ] && [ -f "$2" ] && cmp -s "$1" "$2" && file_modes_match "$1" "$2"
    fi
}

for index in "${!source_directories[@]}"; do
    legacy_directory="$source_dir/${source_directories[$index]}"
    target_directory="$destination_home/${target_directories[$index]}"
    collect_untracked_files "$legacy_directory"
    if [ "$candidate_count" -eq 0 ]; then
        continue
    fi

    if [ "$operation" = check ]; then
        printf '%s: %s untracked file(s)\n' "${target_directories[$index]}" "$candidate_count"
        found_files=$((found_files + candidate_count))
        found_directories=$((found_directories + 1))
        continue
    fi

    source_real="$(cd "$legacy_directory" && pwd -P)"
    target_is_source_link=0
    if [ -L "$target_directory" ]; then
        target_real="$(cd "$target_directory" && pwd -P)" || {
            printf 'Refusing unexpected directory symlink: %s\n' "$target_directory" >&2
            migration_errors=1
            continue
        }
        if [ "$target_real" = "$source_real" ]; then
            target_is_source_link=1
        else
            printf 'Refusing directory symlink outside its legacy source: %s\n' "$target_directory" >&2
            migration_errors=1
            continue
        fi
    fi

    staged_directory="$temporary_directory/$index"
    mkdir -p "$staged_directory"
    while IFS= read -r -d '' candidate; do
        relative_path="${candidate#"$legacy_directory"/}"
        staged_path="$staged_directory/$relative_path"
        mkdir -p "${staged_path%/*}"
        cp -pP "$candidate" "$staged_path"
    done < "$manifest_file"

    conflicts=0
    if [ "$target_is_source_link" -eq 0 ]; then
        while IFS= read -r -d '' candidate; do
            relative_path="${candidate#"$legacy_directory"/}"
            target_path="$target_directory/$relative_path"
            if [ -e "$target_path" ] || [ -L "$target_path" ]; then
                if ! files_match "$candidate" "$target_path"; then
                    printf 'Preserving source file because its target conflicts: %s\n' "$target_path" >&2
                    conflicts=1
                fi
            fi
        done < "$manifest_file"
    fi
    if [ "$conflicts" -ne 0 ]; then
        migration_errors=1
        continue
    fi

    if [ "$target_is_source_link" -eq 1 ]; then
        rm "$target_directory"
    fi
    mkdir -p "$target_directory"
    while IFS= read -r -d '' candidate; do
        relative_path="${candidate#"$legacy_directory"/}"
        staged_path="$staged_directory/$relative_path"
        target_path="$target_directory/$relative_path"
        mkdir -p "${target_path%/*}"
        if [ ! -e "$target_path" ] && [ ! -L "$target_path" ]; then
            cp -pP "$staged_path" "$target_path"
        fi
        if ! files_match "$staged_path" "$target_path"; then
            printf 'Migration verification failed; source retained: %s\n' "$candidate" >&2
            conflicts=1
        fi
    done < "$manifest_file"

    if [ "$conflicts" -ne 0 ]; then
        migration_errors=1
        continue
    fi
    while IFS= read -r -d '' candidate; do
        relative_path="${candidate#"$legacy_directory"/}"
        staged_path="$staged_directory/$relative_path"
        # shortcut: comparison and removal are not atomic; add a writer lock if that gap must be closed.
        if ! files_match "$staged_path" "$candidate"; then
            printf 'Source changed after staging; preserving source file: %s\n' "$candidate" >&2
            conflicts=1
            continue
        fi
        rm "$candidate"
    done < "$manifest_file"
    if [ "$conflicts" -ne 0 ]; then
        migration_errors=1
        continue
    fi
    migrated_files=$((migrated_files + candidate_count))
    migrated_directories=$((migrated_directories + 1))
done

if [ "$operation" = check ]; then
    printf 'Found %s untracked file(s) across %s directory(ies).\n' "$found_files" "$found_directories"
    if [ "$found_files" -eq 0 ]; then
        exit 0
    fi
    exit 1
fi

if [ "$migration_errors" -ne 0 ]; then
    exit 1
fi
printf 'Migrated %s file(s) across %s directory(ies).\n' "$migrated_files" "$migrated_directories"
