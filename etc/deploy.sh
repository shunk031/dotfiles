#!/usr/bin/env bash

function deploy_dotfiles() {
    dotfiles_ui_path="$1"

    dotfiles=$(find "$dotfiles_ui_path" -type f -name ".*" -printf "%f\n" | sed -e 's|//|/|' | sed -e 's|./.|.|' | sort)

    # shellcheck disable=SC2068
    for dotfile in ${dotfiles[@]}; do
        ln -sfnv "$dotfiles_ui_path"/"$dotfile" "$HOME"/"$dotfile"
    done

    # make symboliclink for ./dotfiles/bin to $HOME/bin
    ln -sfnv "$DOTPATH"/bin "$HOME"/bin
}

function deploy_gui_dotfiles() {
    deploy_dotfiles "${DOTPATH}/.files/gui"
}

function deploy_cui_dotfiles() {
    deploy_dotfiles "${DOTPATH}/.files/cui"
}

function deploy_ui_specific_dotfiles() {
    # Convert to the $1 argument to lower case
    ui=$(echo "$1" | tr '[:upper:]' '[:lower:]')

    if [ "$ui" != "gui" ] && [ "$ui" != "cui" ]; then
        echo "The ui option is \`gui\` or \`cui\` only. But got \`$1\`." >&2
        exit 1
    fi

    if [ "$ui" == "gui" ]; then
        deploy_gui_dotfiles
    elif [ "$ui" == "cui" ]; then
        deploy_cui_dotfiles
    else
        echo "Unknown UI: $ui."
        exit 1
    fi
}

function deploy_dotfiles_cmd() {
    deploy_ui_specific_dotfiles "$1"
}
