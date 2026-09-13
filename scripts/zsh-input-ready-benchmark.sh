#!/usr/bin/env bash

# @file scripts/zsh-input-ready-benchmark.sh
# @brief Measure Zsh prompt display and line-editor readiness through a PTY.
# @description
#   Render the selected Sheldon configuration from this repository, start Zsh
#   with that configuration, and measure the first and later prompt latency.
#   The compinit and dump-state options also provide controlled mechanism
#   experiments for the first-prompt input delay. The input byte is written
#   immediately after the prompt unless an experiment requests a settle delay.
# @option --source DIR Chezmoi source directory.
# @option --data-dir DIR Sheldon data directory.
# @option --system NAME Benchmark the server, client, or both configurations.
# @option --samples COUNT Number of PTY samples per configuration.
# @option --compinit MODE Use the real block or a controlled compinit mode.
# @option --dump-state STATE Use the host, absent, fresh, or stale dump state.
# @option --settle-ms MS Delay before the first input byte.
# @option --later-settle-ms MS Delay before the later-prompt input byte.
# @option --trace Print deferred item execution traces.
# @option -h | --help Print command usage.
# @arg $@ string Command-line options and their values.
# @example
#   scripts/zsh-input-ready-benchmark.sh --system both --samples 20

set -euo pipefail

usage() {
    cat << 'EOF'
Usage: zsh-input-ready-benchmark.sh [options]

Options:
  --source DIR       Chezmoi source directory (default: git repository root)
  --data-dir DIR     Sheldon data directory (default: ~/.local/share/sheldon)
  --system NAME      server, client, or both (default: both)
  --samples COUNT    Number of PTY samples per system (default: 20)
  --compinit MODE    real, plain, C, i, u, or skip (default: real)
  --dump-state STATE host, absent, fresh, or stale (default: host)
  --settle-ms MS      Delay after prompt detection (default: 0)
  --later-settle-ms MS
                      Delay before the later-prompt input sample (default: 1000)
  --trace             Print the deferred item execution trace
  -h, --help         Show this help
EOF
}

source_dir="$(git rev-parse --show-toplevel)"
host_home="$HOME"
sheldon_data_dir="${HOME}/.local/share/sheldon"
systems=(server client)
samples=20
compinit_mode=real
dump_state=host
trace_enabled=0
settle_ms=0
later_settle_ms=1000

while (($# > 0)); do
    case "$1" in
    --source)
        source_dir="$2"
        shift 2
        ;;
    --system)
        case "$2" in
        both) systems=(server client) ;;
        client | server) systems=("$2") ;;
        *)
            printf 'Unknown system: %s\n' "$2" >&2
            exit 2
            ;;
        esac
        shift 2
        ;;
    --data-dir)
        sheldon_data_dir="$2"
        shift 2
        ;;
    --samples)
        samples="$2"
        shift 2
        ;;
    --compinit)
        compinit_mode="$2"
        shift 2
        ;;
    --dump-state)
        dump_state="$2"
        shift 2
        ;;
    --trace)
        trace_enabled=1
        shift
        ;;
    --settle-ms)
        settle_ms="$2"
        shift 2
        ;;
    --later-settle-ms)
        later_settle_ms="$2"
        shift 2
        ;;
    -h | --help)
        usage
        exit 0
        ;;
    *)
        printf 'Unknown option: %s\n' "$1" >&2
        usage >&2
        exit 2
        ;;
    esac
done

case "$compinit_mode" in
real | plain | C | i | u | skip) ;;
*)
    printf 'Unknown compinit mode: %s\n' "$compinit_mode" >&2
    exit 2
    ;;
esac

case "$dump_state" in
host | absent | fresh | stale) ;;
*)
    printf 'Unknown dump state: %s\n' "$dump_state" >&2
    exit 2
    ;;
esac

if ! [[ "$samples" =~ ^[1-9][0-9]*$ ]]; then
    printf 'Samples must be a positive integer: %s\n' "$samples" >&2
    exit 2
fi

if ! [[ "$settle_ms" =~ ^[0-9]+$ ]]; then
    printf 'Settle delay must be a non-negative integer: %s\n' "$settle_ms" >&2
    exit 2
fi

if ! [[ "$later_settle_ms" =~ ^[0-9]+$ ]]; then
    printf 'Later settle delay must be a non-negative integer: %s\n' "$later_settle_ms" >&2
    exit 2
fi

benchmark_root="$(mktemp -d "${TMPDIR:-/tmp}/zsh-input-ready.XXXXXX")"
cleanup() {
    rm -rf "$benchmark_root"
}
trap cleanup EXIT

prepare_data_dir() {
    printf '%s\n' "$sheldon_data_dir"
}

render_plugins() {
    local system="$1"
    local output="$2"
    local rendered="$output/rendered.toml"

    chezmoi --source "$source_dir" execute-template \
        --override-data "{\"system\":\"$system\"}" \
        < "$source_dir/home/dot_config/exact_sheldon/plugins.toml.tmpl" \
        > "$rendered"

    case "$compinit_mode" in
    real)
        cp "$rendered" "$output/plugins.toml"
        ;;
    plain | C | i | u | skip)
        awk -v mode="$compinit_mode" '
            function emit_compinit() {
                if (mode == "skip") {
                    print "inline = '\''true'\''"
                } else if (mode == "plain") {
                    print "inline = '\''autoload -Uz compinit && zsh-defer compinit'\''"
                } else {
                    print "inline = '\''autoload -Uz compinit && zsh-defer compinit -" mode "'\''"
                }
            }
            /^\[plugins\.compinit\]$/ {
                print
                in_compinit = 1
                emitted = 0
                next
            }
            in_compinit && /^\[plugins\./ {
                if (!emitted) {
                    emit_compinit()
                    emitted = 1
                }
                in_compinit = 0
                print
                next
            }
            in_compinit { next }
            { print }
            END {
                if (in_compinit && !emitted) emit_compinit()
            }
        ' "$rendered" > "$output/plugins.toml"
        ;;
    esac
}

prepare_dump() {
    local run_dir="$1"
    local zdotdir="$2"
    local config="$3"
    local data_dir="$4"

    case "$dump_state" in
    host)
        if [[ -f "${host_home}/.zcompdump" ]]; then
            cp "${host_home}/.zcompdump" "$zdotdir/.zcompdump"
        fi
        ;;
    absent)
        ;;
    fresh)
        local prep_dir="$run_dir/prep"
        mkdir -p "$prep_dir"
        awk '
            /^\[plugins\.compinit\]$/ {
                print
                in_compinit = 1
                emitted = 0
                next
            }
            in_compinit && /^\[plugins\./ {
                if (!emitted) print "inline = '\''true'\''"
                in_compinit = 0
                print
                next
            }
            in_compinit { next }
            { print }
            END {
                if (in_compinit && !emitted) print "inline = '\''true'\''"
            }
        ' "$config" > "$run_dir/prep.toml"
        cat > "$prep_dir/.zshrc" << EOF
#!/usr/bin/env zsh
typeset -gU path fpath
path=(\$path /usr/local/{,s}bin(N-/) \${HOME}/.local/bin(N-/) \${HOME}/.local/bin/common(N-/))
fpath=(\$fpath \${HOME}/.local/bin/common(N-/))
eval "\$(SHELDON_CONFIG_FILE='$run_dir/prep.toml' SHELDON_DATA_DIR='$data_dir' sheldon source)"
autoload -Uz compinit
compinit -d '$zdotdir/.zcompdump'
EOF
        ZDOTDIR="$prep_dir" SHELDON_CONFIG_FILE="$run_dir/prep.toml" \
            SHELDON_DATA_DIR="$data_dir" zsh -i -c exit \
            < /dev/null > "$run_dir/prep.stdout" 2> "$run_dir/prep.stderr"
        ;;
    stale)
        if [[ -f "${host_home}/.zcompdump" ]]; then
            cp "${host_home}/.zcompdump" "$zdotdir/.zcompdump"
            touch -d '3 days ago' "$zdotdir/.zcompdump"
        fi
        mkdir -p "$run_dir/stale-fpath"
        printf '#compdef __zsh_input_ready_stale\n' > "$run_dir/stale-fpath/_stale"
        ;;
    esac
}

run_system() {
    local system="$1"
    local run_dir="$benchmark_root/$system-$compinit_mode-$dump_state"
    local zdotdir="$run_dir/zdotdir"
    local home_dir="$run_dir/home"
    local data_dir

    mkdir -p "$zdotdir"
    mkdir -p "$home_dir/.config"
    ln -s "$host_home/.local" "$home_dir/.local"
    for config_name in alias shell zsh; do
        if [[ -e "$host_home/.config/$config_name" ]]; then
            ln -s "$host_home/.config/$config_name" "$home_dir/.config/$config_name"
        fi
    done
    mkdir -p "$home_dir/.config/powerlevel10k"
    if [[ -d "$sheldon_data_dir/repos/github.com/romkatv/powerlevel10k" ]]; then
        cp -a "$sheldon_data_dir/repos/github.com/romkatv/powerlevel10k/." \
            "$home_dir/.config/powerlevel10k/"
    fi
    cp "$source_dir/home/dot_config/powerlevel10k/p10k.zsh" \
        "$home_dir/.config/powerlevel10k/p10k.zsh"
    {
        printf 'typeset -g POWERLEVEL9K_DISABLE_GITSTATUS=1\n'
        awk '
            {
                if ($0 ~ /^[[:space:]]*typeset -g POWERLEVEL9K_VCS_BACKENDS=/) {
                    sub(/=.*/, "=()")
                }
                print
                if ($0 ~ /^  unset -m /) print "  typeset -g POWERLEVEL9K_DISABLE_GITSTATUS=1"
            }
        ' \
            "$home_dir/.config/powerlevel10k/p10k.zsh"
    } > "$run_dir/p10k.zsh"
    mv "$run_dir/p10k.zsh" "$home_dir/.config/powerlevel10k/p10k.zsh"
    data_dir="$(prepare_data_dir "$run_dir")"
    render_plugins "$system" "$run_dir"
    prepare_dump "$run_dir" "$zdotdir" "$run_dir/plugins.toml" "$data_dir"
    if [[ -f "$zdotdir/.zcompdump" ]]; then
        cp -p "$zdotdir/.zcompdump" "$run_dir/initial.zcompdump"
    fi

    cp "$source_dir/home/dot_zshenv" "$zdotdir/.zshenv"
    cp "$source_dir/home/dot_zshrc" "$zdotdir/.zshrc"
    if ((trace_enabled)); then
        cat >> "$zdotdir/.zshrc" << EOF
functions -c _zsh-defer-apply __zsh_input_ready_apply
function _zsh-defer-apply() {
    print -r -- "\${EPOCHREALTIME} start \$1" >> "$run_dir/defer.trace"
    __zsh_input_ready_apply "\$@"
    print -r -- "\${EPOCHREALTIME} end \$1" >> "$run_dir/defer.trace"
}
EOF
    fi
    if [[ "$dump_state" == stale ]]; then
        printf "fpath=(\"%s\" \$fpath)\n" "$run_dir/stale-fpath" >> "$zdotdir/.zshrc"
    fi
    cat >> "$zdotdir/.zshrc" << 'EOF'
function __zsh_input_ready_marker() {
    PROMPT+="${ZSH_INPUT_READY_PROMPT_MARKER:-} "
}
precmd_functions+=(__zsh_input_ready_marker)
EOF

    local prompt_marker='❯'

    SHELDON_CONFIG_FILE="$run_dir/plugins.toml" \
        SHELDON_DATA_DIR="$data_dir" \
        HOME="$home_dir" \
        ZDOTDIR="$zdotdir" \
        ZSH_INPUT_READY_SYSTEM="$system" \
        ZSH_INPUT_READY_SAMPLES="$samples" \
        ZSH_INPUT_READY_SETTLE_MS="$settle_ms" \
        ZSH_INPUT_READY_LATER_SETTLE_MS="$later_settle_ms" \
        ZSH_INPUT_READY_PROMPT_MARKER="$prompt_marker" \
        python3 - "$system" "$samples" << 'PY'
import os
import pty
import select
import signal
import statistics
import sys
import time

system = sys.argv[1]
samples = int(sys.argv[2])
marker = os.environ["ZSH_INPUT_READY_PROMPT_MARKER"].encode()


def read_until(fd, needle, timeout=10.0):
    data = bytearray()
    deadline = time.monotonic() + timeout
    while needle not in data:
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            tail = bytes(data[-400:]).decode(errors="replace")
            raise TimeoutError(f"timed out waiting for {needle!r}; tail={tail!r}")
        ready, _, _ = select.select([fd], [], [], remaining)
        if not ready:
            continue
        try:
            chunk = os.read(fd, 65536)
        except OSError as error:
            if error.errno == 5:
                break
            raise
        if not chunk:
            break
        data.extend(chunk)
    return bytes(data)


def measure_sample():
    environment = os.environ.copy()
    environment.update({"TERM": "xterm-256color", "LC_ALL": "C"})
    dump_path = os.path.join(environment["ZDOTDIR"], ".zcompdump")
    initial_dump = os.path.join(os.path.dirname(environment["ZDOTDIR"]), "initial.zcompdump")
    try:
        os.unlink(dump_path)
    except FileNotFoundError:
        pass
    if os.path.exists(initial_dump):
        with open(initial_dump, "rb") as source, open(dump_path, "wb") as target:
            target.write(source.read())
        os.utime(dump_path, (os.stat(initial_dump).st_atime, os.stat(initial_dump).st_mtime))
    start = time.monotonic()
    pid, fd = pty.fork()
    if pid == 0:
        os.execvpe("zsh", ["zsh", "-i"], environment)

    try:
        read_until(fd, marker)
        first_prompt_ms = (time.monotonic() - start) * 1000
        time.sleep(int(os.environ["ZSH_INPUT_READY_SETTLE_MS"]) / 1000)
        input_start = time.monotonic()
        os.write(fd, b"Q")
        read_until(fd, b"Q")
        first_input_ms = (time.monotonic() - input_start) * 1000

        later_prompt_start = time.monotonic()
        os.write(fd, b"\r")
        read_until(fd, marker)
        later_prompt_ms = (time.monotonic() - later_prompt_start) * 1000
        time.sleep(int(os.environ["ZSH_INPUT_READY_LATER_SETTLE_MS"]) / 1000)
        input_start = time.monotonic()
        os.write(fd, b"Q")
        read_until(fd, b"Q")
        later_input_ms = (time.monotonic() - input_start) * 1000
        os.write(fd, b"\x03exit\r")
        return (first_prompt_ms, first_input_ms, later_prompt_ms, later_input_ms)
    finally:
        try:
            os.close(fd)
        except OSError:
            pass
        try:
            os.killpg(pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
        os.waitpid(pid, 0)


measurements = [measure_sample() for _ in range(samples)]
print("system,sample,first_prompt_ms,first_input_ms,later_prompt_ms,later_input_ms")
for index, row in enumerate(measurements, 1):
    print(",".join([system, str(index), *(f"{value:.3f}" for value in row)]))
for index, label in enumerate(
    ("first_prompt_ms", "first_input_ms", "later_prompt_ms", "later_input_ms")
):
    values = [row[index] for row in measurements]
    print(
        f"summary,{label},median={statistics.median(values):.3f},"
        f"min={min(values):.3f},max={max(values):.3f}"
    )
PY
    if ((trace_enabled)) && [[ -f "$run_dir/defer.trace" ]]; then
        sed 's/^/trace,/' "$run_dir/defer.trace"
    fi
}

for system in "${systems[@]}"; do
    run_system "$system"
done
