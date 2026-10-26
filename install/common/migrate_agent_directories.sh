#!/usr/bin/env bash
# @file migrate_agent_directories.sh
# @brief Preserve runtime-created files before replacing source-linked agent directories.
# @description Copies untracked files into their home targets and atomically moves source entries into retained backups.
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
backup_state_directory="$destination_home/.local/state/chezmoi-migration"
backup_directory=""

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
pending_errors=0
verified_backup_count=0

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

path_device() {
    case "$(uname -s)" in
    Darwin) stat -f '%d' "$1" ;;
    *) stat -c '%d' "$1" ;;
    esac
}

same_filesystem() {
    [ "$(path_device "$1")" = "$(path_device "$2")" ]
}

create_backup_directory() {
    local real_backup_state_directory
    [ -n "$backup_directory" ] && return 0
    mkdir -p "$backup_state_directory"
    real_backup_state_directory="$(cd "$backup_state_directory" && pwd -P)"
    case "$real_backup_state_directory" in
    "$repo_root" | "$repo_root"/*)
        printf 'Backup location must be outside the source repository: %s\n' "$real_backup_state_directory" >&2
        return 1
        ;;
    esac
    backup_directory="$(mktemp -d "$real_backup_state_directory/$(date '+%Y%m%dT%H%M%S').XXXXXX")"
}

print_backup_recovery() {
    local backup_file="$1" target_file="$2"
    printf 'Retained migration backup: %s\nTarget: %s\n' "$backup_file" "$target_file"
    printf 'After reviewing the backup, install it and retry:\n  mkdir -p %q\n  cp -pP %q %q\n  bash %q migrate %q %q\n  chezmoi apply\n' \
        "${target_file%/*}" "$backup_file" "$target_file" "$0" "$source_dir" "$destination_home"
}

resolve_pending_marker() {
    local marker="$1" session_directory="$2" index="$3" relative_path="$4"
    local resolved_marker="$session_directory/resolved/$index/$relative_path"
    mkdir -p "${resolved_marker%/*}"
    mv "$marker" "$resolved_marker"
    verified_backup_count=$((verified_backup_count + 1))
}

check_pending_backups() {
    local marker marker_relative session_name pending_relative index relative_path
    local source_file session_directory backup_file target_file
    [ -d "$backup_state_directory" ] || return 0
    find "$backup_state_directory" -type f -path '*/pending/*' -print0 > "$entries_file"
    while IFS= read -r -d '' marker; do
        marker_relative="${marker#"$backup_state_directory"/}"
        session_name="${marker_relative%%/*}"
        pending_relative="${marker_relative#*/pending/}"
        index="${pending_relative%%/*}"
        relative_path="${pending_relative#*/}"
        case "$index" in
        0 | 1 | 2 | 3 | 4) ;;
        *)
            printf 'Invalid migration backup marker: %s\n' "$marker"
            pending_errors=1
            continue
            ;;
        esac
        session_directory="$backup_state_directory/$session_name"
        source_file="$source_dir/${source_directories[$index]}/$relative_path"
        backup_file="$session_directory/files/$index/$relative_path"
        target_file="$destination_home/${target_directories[$index]}/$relative_path"
        if [ -e "$backup_file" ] || [ -L "$backup_file" ]; then
            if files_match "$backup_file" "$target_file"; then
                if [ "$operation" = migrate ]; then
                    resolve_pending_marker "$marker" "$session_directory" "$index" "$relative_path"
                fi
            else
                printf 'Unresolved migration backup needs review:\n'
                print_backup_recovery "$backup_file" "$target_file"
                pending_errors=1
            fi
        elif [ -e "$source_file" ] || [ -L "$source_file" ]; then
            if [ "$operation" = migrate ]; then
                resolve_pending_marker "$marker" "$session_directory" "$index" "$relative_path"
            fi
        else
            printf 'Migration backup is missing; inspect the retained marker: %s\n' "$marker"
            pending_errors=1
        fi
    done < "$entries_file"
}

check_pending_backups
if [ "$operation" = migrate ] && [ "$pending_errors" -ne 0 ]; then
    exit 1
fi

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

    if ! create_backup_directory; then
        migration_errors=1
        continue
    fi
    if ! same_filesystem "$legacy_directory" "$backup_directory"; then
        printf 'Backup location is on another filesystem; refusing non-atomic migration: %s\n' "$backup_directory" >&2
        migration_errors=1
        continue
    fi

    if [ "$target_is_source_link" -eq 1 ]; then
        unlink "$target_directory"
    fi
    mkdir -p "$target_directory"
    while IFS= read -r -d '' candidate; do
        relative_path="${candidate#"$legacy_directory"/}"
        staged_path="$staged_directory/$relative_path"
        target_path="$target_directory/$relative_path"
        if ! create_backup_directory; then
            migration_errors=1
            conflicts=1
            continue
        fi
        if ! same_filesystem "${candidate%/*}" "$backup_directory"; then
            printf 'Refusing non-atomic backup across filesystems: %s\n' "$candidate" >&2
            migration_errors=1
            conflicts=1
            continue
        fi

        backup_file="$backup_directory/files/$index/$relative_path"
        pending_marker="$backup_directory/pending/$index/$relative_path"
        mkdir -p "${backup_file%/*}" "${pending_marker%/*}"
        : > "$pending_marker"
        if ! mv "$candidate" "$backup_file"; then
            printf 'Could not move source into retained backup: %s\n' "$candidate" >&2
            migration_errors=1
            conflicts=1
            continue
        fi

        if ! files_match "$staged_path" "$backup_file"; then
            printf 'Source changed while migrating; target not replaced.\n'
            print_backup_recovery "$backup_file" "$target_path"
            migration_errors=1
            conflicts=1
            continue
        fi

        mkdir -p "${target_path%/*}"
        if [ ! -e "$target_path" ] && [ ! -L "$target_path" ]; then
            cp -pP "$staged_path" "$target_path"
        fi
        if ! files_match "$staged_path" "$target_path"; then
            printf 'Migration verification failed; backup retained: %s\n' "$backup_file" >&2
            migration_errors=1
            conflicts=1
            continue
        fi
        if ! files_match "$staged_path" "$backup_file"; then
            printf 'Source changed after comparison; target not replaced.\n'
            print_backup_recovery "$backup_file" "$target_path"
            migration_errors=1
            conflicts=1
            continue
        fi

        resolve_pending_marker "$pending_marker" "$backup_directory" "$index" "$relative_path"
        migrated_files=$((migrated_files + 1))
    done < "$manifest_file"

    if [ "$conflicts" -ne 0 ]; then
        migration_errors=1
        continue
    fi
    migrated_directories=$((migrated_directories + 1))
done

if [ "$operation" = check ]; then
    printf 'Found %s untracked file(s) across %s directory(ies).\n' "$found_files" "$found_directories"
    if [ "$found_files" -eq 0 ] && [ "$pending_errors" -eq 0 ]; then
        exit 0
    fi
    exit 1
fi

if [ "$migration_errors" -ne 0 ]; then
    if [ -n "$backup_directory" ]; then
        printf 'Backups retained at: %s\n' "$backup_directory"
    fi
    exit 1
fi
printf 'Migrated %s file(s) across %s directory(ies).\n' "$migrated_files" "$migrated_directories"
if [ "$verified_backup_count" -gt 0 ]; then
    printf 'Verified %s retained backup(s).\n' "$verified_backup_count"
fi
if [ -n "$backup_directory" ]; then
    printf 'Backups retained at: %s\n' "$backup_directory"
fi
