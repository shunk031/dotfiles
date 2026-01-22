#!/usr/bin/env zsh

# -----------------------------------------------------------------------------
# chezmoi-notify: Asynchronous update check plugin for chezmoi for Starship
# -----------------------------------------------------------------------------

function _check_chezmoi_update_async() {  
  local check_interval=3600 # Check every hour (3600 seconds)
  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/starship-chezmoi"
  local status_file="$cache_dir/count"
  local last_check_file="$cache_dir/last_check"

  [[ -d "$cache_dir" ]] || mkdir -p "$cache_dir"

  local current_time=$(date +%s)
  local last_check=0
  [[ -f "$last_check_file" ]] && last_check=$(cat "$last_check_file")

  if (( current_time - last_check > check_interval )); then
    echo "$current_time" >! "$last_check_file"

    # Run the following block in the background
    (
      if command -v chezmoi >/dev/null 2>&1; then
        chezmoi git -- fetch -q

        # Count the differences with the remote master branch
        local count=$(chezmoi git -- rev-list --count HEAD..origin/master 2>/dev/null)
        
        if [[ "$count" -gt 0 ]]; then
          echo "$count" >! "$status_file"
        else
          rm -f "$status_file"
        fi
      fi
    ) &!
  fi
}

# Register the hook (precmd: executed just before prompt display)
autoload -Uz add-zsh-hook
add-zsh-hook precmd _check_chezmoi_update_async
