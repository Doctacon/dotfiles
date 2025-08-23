# ZSH Configuration
# Path to your oh-my-zsh installation (if using oh-my-zsh)
# export ZSH="$HOME/.oh-my-zsh"

# History configuration
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Directory navigation
setopt auto_cd
setopt auto_pushd
setopt pushd_ignore_dups
setopt pushdminus

# Completion
autoload -Uz compinit
compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu select

# Key bindings
bindkey -e  # Emacs key bindings (change to -v for vi mode)
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate'

# Environment variables
export EDITOR='hx'  # Set helix as default editor
export VISUAL='hx'
export PAGER='less'

# Colors for ls
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad

# Prompt customization (simple and clean)
# For more advanced prompts, consider using starship or powerlevel10k
PROMPT='%F{blue}%n@%m%f:%F{cyan}%~%f$ '

# Functions
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract various archive formats
extract() {
    if [ -f $1 ]; then
        case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar e $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)     echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Source local configuration if it exists
[ -f ~/.zshrc.local ] && source ~/.zshrc.local

# Initialize tools (uncomment as needed)
# eval "$(starship init zsh)"  # For starship prompt
# eval "$(zoxide init zsh)"     # For zoxide (better cd)
# eval "$(fzf --zsh)"          # For fzf fuzzy finder