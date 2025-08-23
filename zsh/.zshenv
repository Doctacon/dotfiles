# .zshenv - Sourced on all invocations of the shell
# This file should contain environment variables that should be available to all zsh instances

# XDG Base Directory Specification
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Path configuration
typeset -U path PATH
path=(
    $HOME/.local/bin
    $HOME/bin
    /usr/local/bin
    $path
)
export PATH

# Programming language specific paths (uncomment as needed)
# export GOPATH="$HOME/go"
# export CARGO_HOME="$XDG_DATA_HOME/cargo"
# export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
# export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"
# export NODE_REPL_HISTORY="$XDG_DATA_HOME/node_repl_history"

# Tool configurations
export LESSHISTFILE="$XDG_CACHE_HOME/less/history"
export ZDOTDIR="${ZDOTDIR:-$HOME}"

# Locale
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"