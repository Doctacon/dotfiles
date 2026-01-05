# Kiro CLI pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh"
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

# Claude directory management
export CLAUDE_HOME="$HOME/Code/dotfiles/claude"

# Copy .claude to current directory
claude-here() {
    if [ -e ".claude" ]; then
        echo "⚠️  .claude already exists here. Use 'claude-sync' to update it."
    else
        cp -r "$CLAUDE_HOME" .claude
        echo "✅ Copied .claude to current directory"
        echo "📁 $(find .claude -type f | wc -l | xargs) files copied"
    fi
}

# Sync/update existing .claude with latest from source
claude-sync() {
    if [ ! -e ".claude" ]; then
        echo "❌ No .claude here. Use 'claude-here' first."
    else
        # Use rsync to update, preserving local changes to settings.local.json
        rsync -av --delete --exclude='settings.local.json' "$CLAUDE_HOME/" .claude/
        # Only update settings.local.json if it doesn't exist locally
        if [ ! -f ".claude/settings.local.json" ] && [ -f "$CLAUDE_HOME/settings.local.json" ]; then
            cp "$CLAUDE_HOME/settings.local.json" .claude/
        fi
        echo "🔄 Synced .claude with latest from $CLAUDE_HOME"
        echo "📝 Preserved local settings.local.json"
    fi
}

# Remove .claude from current directory
claude-remove() {
    if [ -d ".claude" ]; then
        echo "⚠️  About to delete .claude directory and all its contents"
        echo -n "Are you sure? (y/N): "
        read confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            rm -rf .claude
            echo "🗑️  Removed .claude directory"
        else
            echo "❌ Cancelled"
        fi
    else
        echo "❓ No .claude found here"
    fi
}

# Check if .claude is available
claude-status() {
    if [ -d ".claude" ]; then
        echo "📁 .claude exists as a directory"
        echo "📊 $(find .claude -type f | wc -l | xargs) files"
        echo "💾 $(du -sh .claude | cut -f1) total size"
        # Check if it's up to date
        if [ -f "$CLAUDE_HOME/settings.local.json" ] && [ -f ".claude/settings.local.json" ]; then
            if ! diff -q "$CLAUDE_HOME/settings.local.json" ".claude/settings.local.json" > /dev/null 2>&1; then
                echo "ℹ️  Local settings.local.json differs from source"
            fi
        fi
    else
        echo "❌ No .claude in current directory"
    fi
}

# Push local .claude changes back to source (careful!)
claude-push() {
    if [ ! -d ".claude" ]; then
        echo "❌ No .claude directory here"
    else
        echo "⚠️  This will overwrite $CLAUDE_HOME with local .claude"
        echo -n "Are you sure? (y/N): "
        read confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            rsync -av --delete .claude/ "$CLAUDE_HOME/"
            echo "⬆️  Pushed local .claude to $CLAUDE_HOME"
        else
            echo "❌ Cancelled"
        fi
    fi
}

# Shorthand aliases
alias ch='claude-here'
alias cr='claude-remove'
alias cs='claude-status'
alias csync='claude-sync'
alias cpush='claude-push'

# zoxide init
eval "$(zoxide init zsh)"

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

# Ripgrep aliases for data engineering
alias rgs='rg --type=sql'           # Search SQL files
alias rgpy='rg --type=py'           # Search Python files  
alias rgdata='rg --type=data'       # Search data files (csv, json, etc)
alias rgconfig='rg --type=config'   # Search config files
alias rgnb='rg --type=notebook'     # Search Jupyter notebooks
alias rgdocker='rg --type=docker'   # Search Docker files
alias rgk8s='rg --type=k8s'         # Search Kubernetes files
alias rgdbt='rg --type=dbt'         # Search DBT files
alias rgi='rg --no-ignore'          # Search including ignored files
alias rgf='rg --files'              # List all files that would be searched
alias rgc='rg --count'              # Count matches per file

# Source local configuration if it exists
[ -f ~/.zshrc.local ] && source ~/.zshrc.local

# Initialize tools (uncomment as needed)
# eval "$(starship init zsh)"  # For starship prompt
# eval "$(zoxide init zsh)"     # For zoxide (better cd)
# eval "$(fzf --zsh)"          # For fzf fuzzy finder
eval "$(direnv hook zsh)"     # For direnv environment management

export PATH="$HOME/.local/bin:$PATH"

# Kiro CLI post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh"
