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

# Zsh global aliases: expand anywhere in a command line.
# Examples: `git log --oneline L`, `docker ps J`, `rg TODO C`.
alias -g G='| grep'
alias -g R='| rg'
alias -g J='| jq'
alias -g L='| less -R'
alias -g C='| pbcopy'
alias -g H='| head'
alias -g T='| tail'

# Zsh suffix aliases: type a file path directly to open it with the right tool.
alias -s md=hx
alias -s markdown=hx
alias -s json=hx
alias -s toml=hx
alias -s yaml=hx
alias -s yml=hx
alias -s txt=hx
alias -s png=open
alias -s jpg=open
alias -s jpeg=open
alias -s gif=open
alias -s webp=open
alias -s pdf=open

# Environment variables
export EDITOR='hx'  # Set helix as default editor
export VISUAL='hx'
export PAGER='less'

# Colors for ls
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad

# Prompt customization - Light Owl / Ghostty orange + teal
# 37 = teal, 73 = soft cyan-teal, 202 = ember orange, 103 = muted lavender-gray.
setopt prompt_subst

prompt_git_info() {
    local branch dirty
    branch=$(GIT_OPTIONAL_LOCKS=0 git rev-parse --abbrev-ref HEAD 2>/dev/null) || return 0
    [[ "$branch" == "HEAD" ]] && branch=$(GIT_OPTIONAL_LOCKS=0 git rev-parse --short HEAD 2>/dev/null)

    if ! GIT_OPTIONAL_LOCKS=0 git diff --quiet --ignore-submodules -- 2>/dev/null || \
       ! GIT_OPTIONAL_LOCKS=0 git diff --cached --quiet --ignore-submodules -- 2>/dev/null || \
       [[ -n "$(GIT_OPTIONAL_LOCKS=0 git ls-files --others --exclude-standard 2>/dev/null | head -n 1)" ]]; then
        dirty="*"
        print -r -- " %F{202} ${branch}${dirty}%f"
    else
        print -r -- " %F{37} ${branch}%f"
    fi
}

PROMPT='%F{37}%n%f:%F{73}%2~%f$(prompt_git_info) %F{202}❯%f ' 

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

# Claude Code wrapper with Z.ai API configuration
zclaude() {
    env -u GOOGLE_GENAI_USE_VERTEXAI \
        -u CLAUDE_CODE_USE_VERTEX \
        -u CLOUD_ML_REGION \
        -u ANTHROPIC_VERTEX_PROJECT_ID \
        -u MCP_TIMEOUT \
        ANTHROPIC_AUTH_TOKEN="$ZAI_API_KEY" \
        ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic" \
        API_TIMEOUT_MS="3000000" \
        claude "$@"
}

# zoxide init
eval "$(zoxide init zsh)"

# Atuin local shell history. Ctrl+R opens fuzzy history search; Up Arrow remains normal zsh history.
if command -v atuin >/dev/null 2>&1; then
    eval "$(atuin init zsh --disable-up-arrow --disable-ai)"
fi

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
export PATH="$PATH:$HOME/go/bin"

# Kiro CLI post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh"

# Kiro CLI post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh"

# bun completions
[ -s "/Users/crlough/.bun/_bun" ] && source "/Users/crlough/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="/Users/crlough/Code/external/opencode/packages/opencode/dist/opencode-darwin-arm64/bin:$PATH"
