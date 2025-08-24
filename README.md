# Dotfiles

My personal development environment configuration files.

## 🛠 Tools Configured

- **[ZSH](#zsh)** - Shell with custom aliases, functions, and environment setup
- **[Git](#git)** - Version control with useful aliases and better defaults
- **[Helix](#helix)** - Modern text editor with LSP support and git blame integration
- **[tmux](#tmux)** - Terminal multiplexer with vim-style navigation
- **[Hyper](#hyper)** - Terminal emulator with custom theme

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
│   └── .tmux.conf      # tmux configuration
├── hyper/
    └── .hyper.js       # Hyper terminal configuration
```

## 🚀 New Computer Setup

Setting up your development environment on a new Mac.

### 1. Install Homebrew
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2. Install Essential Tools
```bash
# Core tools
brew install git stow zsh tmux helix

# Python tools
brew install uv
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

### 4. Link Everything with Stow
```bash
# Link all configs at once
stow zsh git helix tmux

# Or link individually if you prefer
stow zsh    # Shell config
stow git    # Git config
stow helix  # Editor config
stow tmux   # Terminal multiplexer
```

### 5. Install Python Language Servers for Helix
```bash
# Install Python LSPs
uv tool install pyright
uv tool install ruff-lsp
```

### 6. Set ZSH as Default Shell
```bash
# Add homebrew zsh to allowed shells
sudo sh -c "echo $(which zsh) >> /etc/shells"

# Change default shell
chsh -s $(which zsh)
```

### 7. Restart Terminal
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
```

## 📦 Stow Management

### Basic Commands
```bash
# Link configurations
stow zsh                        # Link single package
stow zsh git helix              # Link multiple packages

# Unlink configurations
stow -D zsh                     # Remove single package
stow -D zsh git helix           # Remove multiple packages

# Relink configurations (useful after updates)
stow -R zsh                     # Relink single package
stow -R -v zsh git helix        # Relink multiple with verbose output

# Dry run (preview changes)
stow -n -v zsh                  # See what would happen
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
- Catppuccin Mocha theme
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

### Hyper

**Features:**
- Fira Code font with ligatures
- Dracula-inspired color scheme
- WebGL renderer for performance
- Custom tab styling
- ZSH as default shell

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
stow vim
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
