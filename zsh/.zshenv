# ZSH Environment Variables
# ~/.zshenv - Loaded for all shells (login, interactive, scripts)

# Default programs
export EDITOR='hx'
export VISUAL='hx'
export PAGER='less'
export BROWSER='open'

# Language settings
export LANG='en_US.UTF-8'
export LC_ALL='en_US.UTF-8'

# Path configuration
typeset -U path PATH
path=(
    $HOME/bin
    $HOME/.local/bin
    /usr/local/bin
    /usr/local/sbin
    /opt/homebrew/bin
    /opt/homebrew/sbin
    $path
)
export PATH

# Development paths
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"
path=($GOBIN $path)

# Rust
[ -d "$HOME/.cargo/bin" ] && path=($HOME/.cargo/bin $path)

# Node.js
export NVM_DIR="$HOME/.nvm"

# Python
export PYTHONDONTWRITEBYTECODE=1
export PYTHONUNBUFFERED=1

# Ruby
[ -d "$HOME/.rbenv/bin" ] && path=($HOME/.rbenv/bin $path)

# XDG Base Directory
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"

# Less configuration
export LESS='-F -g -i -M -R -S -w -X -z-4'
export LESSHISTFILE="$XDG_CACHE_HOME/less/history"

# FZF defaults
export FZF_DEFAULT_OPTS='
    --height 40%
    --layout=reverse
    --border
    --inline-info
    --color=dark
    --color=fg:-1,bg:-1,hl:#5fff87,fg+:-1,bg+:-1,hl+:#ffaf5f
    --color=info:#af87ff,prompt:#5fff87,pointer:#ff87d7,marker:#ff87d7,spinner:#ff87d7
'

# Homebrew
if [[ -f "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Disable telemetry
export HOMEBREW_NO_ANALYTICS=1
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export GATSBY_TELEMETRY_DISABLED=1
export NEXT_TELEMETRY_DISABLED=1

# Security
export GPG_TTY=$(tty)

# Custom configuration
export DOTFILES="$HOME/Code/dotfiles"