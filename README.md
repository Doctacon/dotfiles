# Dotfiles

My personal development environment configuration files.

## 🛠 Tools Configured

- **[ZSH](#zsh)** - Shell with custom aliases, functions, and environment setup
- **[Git](#git)** - Version control with useful aliases and better defaults
- **[Helix](#helix)** - Modern text editor with LSP support and git blame integration
- **[tmux](#tmux)** - Terminal multiplexer with vim-style navigation and popups
- **[Ghostty](#ghostty)** - Terminal emulator with Light Owl styling and shaders
- **[Yazi](#yazi)** - Terminal file manager launched from tmux popups
- **[LazyGit](#lazygit)** - Terminal Git UI with delta and difftastic pagers
- **[Pi](#pi)** - Coding-agent TUI configured with matching theme/keybindings

## 📁 Directory Structure

```
dotfiles/
├── zsh/
│   ├── .zshrc          # Main ZSH configuration
│   └── .zshenv         # Environment variables
├── git/
│   ├── .gitconfig      # Git configuration
│   └── .gitignore_global # Global ignore patterns
├── helix/
│   └── .config/helix/
│       └── config.toml # Helix editor settings
├── tmux/
│   ├── .tmux.conf      # tmux configuration
│   └── .tmux/scripts/  # tmux status/pane helper scripts
├── ghostty/
│   └── .config/ghostty/config
├── yazi/
│   └── .config/yazi/
├── lazygit/
│   └── Library/Application Support/lazygit/config.yml
├── atuin/
│   └── .config/atuin/config.toml
├── direnv/
│   └── .config/direnv/direnv.toml
├── pi/
│   └── .pi/agent/
```

## 🚀 New Computer Setup

Setting up your development environment on a new Mac.

### 1. Install Homebrew
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2. Install Bootstrap Tools
```bash
# Enough to clone this repo and link configs
brew install git stow
```

### 3. Clone Your Dotfiles
```bash
# Create directory structure
mkdir -p ~/Code
cd ~/Code

# Clone your dotfiles
git clone https://github.com/Doctacon/dotfiles.git
cd dotfiles
```

### 4. Install Packages from Brewfile
```bash
brew bundle install --file Brewfile
```

### 5. Link Everything with Stow
```bash
# Link all configs at once
stow --target="$HOME" zsh git helix tmux ghostty yazi lazygit atuin direnv pi

# Or link individually if you prefer
stow --target="$HOME" zsh      # Shell config
stow --target="$HOME" git      # Git config
stow --target="$HOME" helix    # Editor config
stow --target="$HOME" tmux     # Terminal multiplexer
stow --target="$HOME" ghostty  # Terminal emulator
stow --target="$HOME" yazi     # Terminal file manager
stow --target="$HOME" lazygit  # Terminal Git UI
stow --target="$HOME" pi       # Coding-agent TUI
```

### 6. Install Python Language Servers for Helix
```bash
# Install Python LSPs
uv tool install pyright
uv tool install ruff-lsp
```

### 7. Set ZSH as Default Shell
```bash
# Add homebrew zsh to allowed shells
sudo sh -c "echo $(which zsh) >> /etc/shells"

# Change default shell
chsh -s $(which zsh)
```

### 8. Restart Terminal
Close and reopen your terminal, or run:
```bash
source ~/.zshrc
```

### That's it! 🎉

Your environment is ready. Test it out:
```bash
# Check helix is working with LSP
hx --health python

# Test git aliases
git s

# Test ripgrep
rg "test"

# Test lazygit + delta/difftastic stack
lazygit --version
delta --version
difft --version
```

## 🏢 Work Machine Setup

If you're setting this up on a work machine with existing configs and sensitive environment variables:

### 1. Back Up Your Existing Environment Variables
Before running stow, save your work-specific settings:
```bash
# Copy your existing environment variables to a local file
cp ~/.zshrc ~/.zshrc.local

# Edit to keep only work-specific stuff (API keys, paths, etc.)
hx ~/.zshrc.local
# Remove everything except your work-specific exports and configs
```

### 2. Run Normal Setup
Follow the setup steps above. When you run `stow zsh`, it will replace your `.zshrc` with the dotfiles version.

### 3. Your Work Variables Are Safe!
The `.zshrc` from dotfiles automatically sources `~/.zshrc.local` if it exists, so all your work-specific environment variables will still load.

### 4. What Goes Where?

**In `~/.zshrc.local` (never committed):**
```bash
# Work-specific API keys
export OPENAI_API_KEY="sk-..."
export AWS_ACCESS_KEY_ID="..."
export DATABASE_URL="..."

# Company-specific paths
export WORK_REPO="/Users/you/work/repo"

# Corporate proxy settings
export HTTP_PROXY="..."
```

**In dotfiles `.zshrc` (committed to git):**
- General aliases and functions
- Tool configurations
- Generic PATH additions
- Theme and prompt settings

This way you get all your dotfiles goodness while keeping sensitive work data separate and secure.

## 📦 Stow Management

### Basic Commands
```bash
# Link configurations
stow --target="$HOME" zsh                        # Link single package
stow --target="$HOME" zsh git helix              # Link multiple packages

# Unlink configurations
stow --target="$HOME" -D zsh                     # Remove single package
stow --target="$HOME" -D zsh git helix           # Remove multiple packages

# Relink configurations (useful after updates)
stow --target="$HOME" -R zsh                     # Relink single package
stow --target="$HOME" -R -v zsh git helix        # Relink multiple with verbose output

# Dry run (preview changes)
stow --target="$HOME" -n -v zsh                  # See what would happen
```

### Check Current Status
```bash
# See all symlinks
ls -la ~ | grep -E "^l.*dotfiles"

# Check specific symlink
ls -la ~/.zshrc
```

## ⚙️ Configuration Details

### ZSH

**Features:**
- Smart prompt with git integration
- Extensive aliases for git, navigation, and common tasks
- History with deduplication and sharing
- fzf shell integration for file/directory pickers
- Atuin local-first history search
- Ripgrep aliases for data engineering (`rgs`, `rgpy`, `rgdata`, etc.)
- Custom functions (`mkcd`, `extract`, `backup`, `gacp`)
- Environment setup for development tools

**Key Aliases:**
- `ll`, `la` - Enhanced listing
- `gs`, `gd`, `gp` - Git shortcuts
- `rgs` - Search SQL files
- `rgpy` - Search Python files
- `rgdata` - Search data files (CSV, JSON, etc.)

### Git

**Features:**
- Helix as default editor
- Global gitignore for common files
- Better diff algorithms and merge conflict display
- Delta as the default syntax-highlighting pager
- Difftastic aliases for structural diffs (`git difft`, `git showt`)
- Auto-prune on fetch
- Rebase by default on pull
- SSH preference for GitHub

**Useful Aliases:**
- `git s` - Quick status
- `git ll` - Pretty log with graph
- `git cane` - Amend without editing message
- `git undo` - Undo last commit (keep changes)
- `git recent` - Show recent branches
- `git go <branch>` - Switch/create branch

### Helix

**Features:**
- Light Owl + orange accent theme
- Relative line numbers
- Git gutter indicators
- Mouse support
- Smart indentation

**Custom Keybindings:**
- `Alt-b` - Git blame for current line
- `Space e/f` - File picker
- `Space r` - Rename symbol
- `Space a` - Code action
- `Tab/Shift-Tab` - Buffer switching
- `jk` - Exit insert mode

### tmux

**Features:**
- Prefix: `Ctrl-a` (instead of `Ctrl-b`)
- Mouse support enabled
- Vim-style pane navigation (`h,j,k,l`)
- Window/pane indexing starts at 1
- 256 color support

**Key Bindings:**
- `Prefix |` - Vertical split
- `Prefix -` - Horizontal split
- `Prefix r` - Reload config
- `Prefix h/j/k/l` - Navigate panes
- `Prefix H/J/K/L` - Resize panes
- `Prefix p` - Open Pi in a popup
- `Prefix B` - Open Yazi in a popup
- `Prefix u` - Open LazyGit in a popup

### Yazi

**Features:**
- Terminal file manager with Light Owl flavor
- Shell escape keybinding (`!`) for opening a blocking shell in the current directory
- Launched from tmux with `Prefix B`

### LazyGit

**Features:**
- Terminal Git UI installed via Homebrew
- Uses Delta as the first diff pager
- Includes Difftastic as a second pager for syntax-aware diffs
- Opens files in Helix via LazyGit's `helix` edit preset
- Launched from tmux with `Prefix u` or from zsh with `lg`

### Pi

**Features:**
- Light Owl orange readable theme
- High default thinking level
- Custom newline keybindings for the TUI input
- Loom, web access, ask-user-question, and flight-recorder packages enabled

### Ghostty

**Features:**
- IBM Plex Mono with ligatures
- Light Owl theme shared with tmux, Helix, Yazi, and Pi
- Subtle shader effects and orange cursor styling
- macOS-native keybindings for tabs, splits, search, and font size
- ZSH shell integration

## 🔧 Customization

### Local Overrides

For machine-specific configurations:
- ZSH: Create `~/.zshrc.local`
- Git: Use `git config --local` in repositories

### Adding New Configurations

1. Create a new directory in `~/Code/dotfiles/`
2. Mirror the home directory structure
3. Run `stow <package>` to create symlinks

Example for adding vim configuration:
```bash
mkdir -p ~/Code/dotfiles/vim
echo "set number" > ~/Code/dotfiles/vim/.vimrc
cd ~/Code/dotfiles
stow --target="$HOME" vim
```

## 🐛 Common Issues & Fixes

### "stow: conflict" error
This means files already exist where stow wants to create symlinks.
```bash
# Option 1: Back up existing file and retry
mv ~/.zshrc ~/.zshrc.backup
stow zsh

# Option 2: Force adopt existing files
stow --adopt zsh
```

### Helix can't find Python packages
Make sure you've installed and activated your virtual environment:
```bash
# Create and activate virtual environment
uv venv
source .venv/bin/activate

# Install project dependencies
uv sync  # if using pyproject.toml
# or
uv pip install <package>  # for individual packages
```

### Terminal doesn't look right
Make sure you restarted your terminal after setup, or run:
```bash
source ~/.zshrc
```

## 📚 Additional Resources

- [GNU Stow Documentation](https://www.gnu.org/software/stow/)
- [Helix Documentation](https://docs.helix-editor.com/)
- [tmux Cheat Sheet](https://tmuxcheatsheet.com/)
- [Ripgrep User Guide](https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md)

## 📄 License

MIT - Feel free to use and modify these configurations
