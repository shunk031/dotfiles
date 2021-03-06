POWERLEVEL9K_MODE='nerdfont-complete'

POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
POWERLEVEL9K_PROMPT_ON_NEWLINE=true
POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=""
POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="%B%F{217}❯%F{174}❯%F{250}❯%f%b "

# settings for ``
## color
POWERLEVEL9K_OS_ICON_FOREGROUND="236"
POWERLEVEL9K_OS_ICON_BACKGROUND="138"

# settings for `user`
## color
POWERLEVEL9K_USER_DEFAULT_FOREGROUND="236"
POWERLEVEL9K_USER_DEFAULT_BACKGROUND="250"
POWERLEVEL9K_USER_ROOT_FOREGROUND=${POWERLEVEL9K_USER_DEFAULT_FOREGROUND}
POWERLEVEL9K_USER_ROOT_BACKGROUND=${POWERLEVEL9K_USER_DEFAULT_BACKGROUND}

# settings for `dir`
POWERLEVEL9K_SHORTEN_DIR_LENGTH=1
POWERLEVEL9K_SHORTEN_DELIMITER=""
POWERLEVEL9K_SHORTEN_STRATEGY="truncate_from_right"
## color
POWERLEVEL9K_DIR_DEFAULT_FOREGROUND="138"
POWERLEVEL9K_DIR_DEFAULT_BACKGROUND="235"
POWERLEVEL9K_DIR_HOME_FOREGROUND=${POWERLEVEL9K_DIR_DEFAULT_FOREGROUND}
POWERLEVEL9K_DIR_HOME_BACKGROUND=${POWERLEVEL9K_DIR_DEFAULT_BACKGROUND}
POWERLEVEL9K_DIR_HOME_SUBFOLDER_FOREGROUND=${POWERLEVEL9K_DIR_DEFAULT_FOREGROUND}
POWERLEVEL9K_DIR_HOME_SUBFOLDER_BACKGROUND=${POWERLEVEL9K_DIR_DEFAULT_BACKGROUND}

# settings for `pyenv`
POWERLEVEL9K_PYENV_PROMPT_ALWAYS_SHOW=true
## color
POWERLEVEL9K_PYENV_FOREGROUND="250"
POWERLEVEL9K_PYENV_BACKGROUND="235"

# settings for `virtualenv`
## color
POWERLEVEL9K_VIRTUALENV_FOREGROUND="250"
POWERLEVEL9K_VIRTUALENV_BACKGROUND="235"

# settings for `rbenv`
POWERLEVEL9K_RBENV_FOREGROUND="250"
POWERLEVEL9K_RBENV_BACKGROUND="235"

# settings for `vcs`

# Left Prompt setting
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(os_icon user dir pyenv rbenv)

# Right Prompt setting
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status vcs)
