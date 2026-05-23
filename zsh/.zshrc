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
alias lg='lazygit'

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

# zsh -> tmux command lifecycle bridge.
# Makes long-running foreground commands visible through the same breathing pane-border mood system.
_tmux_command_state_file="${HOME}/.cache/tmux-agent-ring-state"
_tmux_shell_status_file="${HOME}/.cache/tmux-shell-command-state"
if [[ -n "${TMUX_PANE:-}" ]]; then
    _tmux_shell_status_file="${HOME}/.cache/tmux-shell-command-state-${TMUX_PANE//[^A-Za-z0-9_]/_}"
fi
_tmux_command_started_at=0
_tmux_command_text=""
_tmux_command_checkpoint_token=""
_tmux_command_checkpoint_file="${_tmux_shell_status_file}.checkpoint"
: ${ZSH_COMMAND_CHECKPOINT_SECONDS:=5}

_tmux_format_duration() {
    local elapsed=$1 mins secs
    mins=$(( elapsed / 60 ))
    secs=$(( elapsed % 60 ))
    if (( mins > 0 )); then
        print -r -- "${mins}m ${secs}s"
    else
        print -r -- "${secs}s"
    fi
}

_tmux_prompt_escape() {
    print -r -- "${1//%/%%}"
}

_tmux_set_command_state() {
    [[ -n "${TMUX:-}" ]] || return 0
    mkdir -p "${_tmux_command_state_file:h}" 2>/dev/null || return 0
    local state="$1" ttl="${2:-}" expires=""
    if [[ -n "$ttl" ]]; then
        expires=$(( EPOCHSECONDS + ttl ))
    fi
    print -r -- "$state $expires" >| "$_tmux_command_state_file" 2>/dev/null || true
}

_tmux_command_preexec() {
    _tmux_command_started_at=$EPOCHSECONDS
    _tmux_command_text="$1"
    _tmux_command_checkpoint_token="${EPOCHSECONDS}:${$}:${RANDOM}"
    local start_clock="${(%):-%D{%H:%M:%S}}"
    local command_line="${_tmux_command_text%%$'\n'*}"
    command_line="$(_tmux_prompt_escape "$command_line")"

    _tmux_set_command_state "shell-running"
    [[ -n "${TMUX:-}" ]] && printf '%s\t%s\t%s\n' "running" "$_tmux_command_started_at" "${_tmux_command_text%%$'\n'*}" >| "$_tmux_shell_status_file" 2>/dev/null || true
    printf '%s\n' "$_tmux_command_checkpoint_token" >| "$_tmux_command_checkpoint_file" 2>/dev/null || true

    {
        sleep "$ZSH_COMMAND_CHECKPOINT_SECONDS"
        if [[ -f "$_tmux_command_checkpoint_file" && "$(<"$_tmux_command_checkpoint_file")" == "$_tmux_command_checkpoint_token" ]]; then
            print -P -- "\n%F{202}╭─%f %F{103}started ${start_clock}%f %F{202}·%f %F{103}${command_line}%f" > /dev/tty 2>/dev/null || true
        fi
    } &!
}

_tmux_command_precmd() {
    local exit_code=$? elapsed=0
    if (( _tmux_command_started_at > 0 )); then
        elapsed=$(( EPOCHSECONDS - _tmux_command_started_at ))
        if (( exit_code != 0 )); then
            _tmux_set_command_state "error" 8
        else
            _tmux_set_command_state "waiting"
        fi
        [[ -n "${TMUX:-}" ]] && printf '%s\t%s\t%s\t%s\t%s\n' "done" "$(( EPOCHSECONDS + 8 ))" "$exit_code" "$elapsed" "${_tmux_command_text%%$'\n'*}" >| "$_tmux_shell_status_file" 2>/dev/null || true

        if (( elapsed >= ZSH_COMMAND_CHECKPOINT_SECONDS )); then
            local duration="$(_tmux_format_duration "$elapsed")"
            local finished_clock="${(%):-%D{%H:%M:%S}}"
            if (( exit_code == 0 )); then
                print -P "%F{202}╰─%f %F{37}finished ${finished_clock}%f %F{202}·%f %F{37}exit 0%f %F{202}· took ${duration}%f"
            else
                print -P "%F{202}╰─%f %F{196}finished ${finished_clock}%f %F{202}·%f %F{196}exit ${exit_code}%f %F{202}· after ${duration}%f"
            fi
        fi
    else
        _tmux_set_command_state "waiting"
        [[ -n "${TMUX:-}" ]] && rm -f "$_tmux_shell_status_file" 2>/dev/null || true
    fi
    rm -f "$_tmux_command_checkpoint_file" 2>/dev/null || true
    _tmux_command_started_at=0
    _tmux_command_text=""
    _tmux_command_checkpoint_token=""
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec _tmux_command_preexec
add-zsh-hook precmd _tmux_command_precmd

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

# Fuzzy finder shell integration: Ctrl+T files, Alt-C directories; Atuin owns Ctrl+R below.
if command -v fzf >/dev/null 2>&1; then
    eval "$(fzf --zsh)"
fi

# Atuin local shell history. Ctrl+R opens fuzzy history search; Up Arrow remains normal zsh history.
if command -v atuin >/dev/null 2>&1; then
    eval "$(atuin init zsh --disable-up-arrow --disable-ai)"
fi

# Natural-language shell command drafts with Pi.
# Type: ?? find my last modified .png file
# Press Enter, and Pi replaces it with a proposed command for you to review/edit.
# It never auto-runs the generated command; press Enter again if you approve it.
_pi_shell_command_from_nl() {
    emulate -L zsh
    setopt localoptions no_nomatch

    if [[ "$BUFFER" != '?? '* ]]; then
        zle .accept-line
        return
    fi

    local request="${BUFFER#\?\? }"
    request="$(print -r -- "$request" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    if [[ -z "$request" ]]; then
        zle -M "Usage: ?? describe the shell command you want"
        return
    fi

    if ! command -v pi >/dev/null 2>&1; then
        zle -M "pi not found; cannot draft command"
        return
    fi

    zle -M "Pi drafting a safe shell command…"

    local system_prompt user_prompt output pi_exit_status
    system_prompt='You convert a natural-language request into a safe zsh shell command for macOS. Output exactly one command and nothing else: no markdown, no code fences, no explanation. Never execute anything. Prefer non-destructive preview/list commands for destructive requests. If a request is dangerous or unclear, output a safe echo command explaining what must be reviewed. Prefer commands compatible with zsh on macOS. Use the current working directory context when relevant.'
    user_prompt="CWD: $PWD
Request: $request"

    output=$(pi -p --no-session --no-tools --no-extensions --no-skills --no-prompt-templates --no-context-files --thinking minimal --system-prompt "$system_prompt" "$user_prompt" 2>/tmp/pi-zsh-command.err)
    pi_exit_status=$?

    if [[ $pi_exit_status -ne 0 || -z "${output//[[:space:]]/}" ]]; then
        local err="$(tail -n 1 /tmp/pi-zsh-command.err 2>/dev/null)"
        zle -M "Pi command draft failed${err:+: $err}"
        return
    fi

    # Be forgiving if the model still emits fences or surrounding prose.
    output="${output//$'\r'/}"
    output="${output#\`\`\`zsh$'\n'}"
    output="${output#\`\`\`bash$'\n'}"
    output="${output#\`\`\`sh$'\n'}"
    output="${output#\`\`\`$'\n'}"
    output="${output%$'\n'\`\`\`}"
    output="$(print -r -- "$output" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"

    BUFFER="$output"
    CURSOR=${#BUFFER}
    zle -M "Command drafted; review/edit, then press Enter to run"
    zle redisplay
}
zle -N accept-line _pi_shell_command_from_nl

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
# fzf is initialized above with command existence checks.
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
