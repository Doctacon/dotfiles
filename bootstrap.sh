#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo_error "This bootstrap script is designed for macOS only"
    exit 1
fi

DOTFILES_DIR="$HOME/Code/dotfiles"

echo_info "Starting dotfiles bootstrap..."

# Install Command Line Tools if not present
if ! command -v git &> /dev/null; then
    echo_info "Installing Xcode Command Line Tools..."
    xcode-select --install
    echo_warn "Please complete the Command Line Tools installation and run this script again"
    exit 0
fi

# Clone dotfiles if not present
if [[ ! -d "$DOTFILES_DIR" ]]; then
    echo_info "Cloning dotfiles repository..."
    mkdir -p "$HOME/Code"
    git clone https://github.com/YOUR_USERNAME/dotfiles.git "$DOTFILES_DIR"
    cd "$DOTFILES_DIR"
else
    echo_info "Dotfiles directory already exists"
    cd "$DOTFILES_DIR"
fi

# Install Homebrew if not present
if ! command -v brew &> /dev/null; then
    echo_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ $(uname -m) == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    echo_info "Homebrew already installed"
fi

# Install packages from Brewfile
if [[ -f "$DOTFILES_DIR/Brewfile" ]]; then
    echo_info "Installing packages from Brewfile..."
    brew bundle install --file="$DOTFILES_DIR/Brewfile"
else
    echo_warn "No Brewfile found, skipping package installation"
fi

# Setup dotfiles with GNU Stow (if available)
if command -v stow &> /dev/null; then
    echo_info "Setting up dotfiles with GNU Stow..."
    
    # Find all directories (excluding hidden ones and common non-config dirs)
    for dir in */; do
        dirname="${dir%/}"
        if [[ ! "$dirname" =~ ^\. ]] && [[ "$dirname" != "scripts" ]] && [[ "$dirname" != "docs" ]]; then
            echo_info "Stowing $dirname..."
            stow -v "$dirname" 2>/dev/null || echo_warn "Could not stow $dirname (may already exist)"
        fi
    done
else
    echo_warn "GNU Stow not available. You'll need to manually symlink your dotfiles"
    echo_info "Consider installing stow: brew install stow"
fi

# Make zsh the default shell if it isn't already
if [[ "$SHELL" != "$(which zsh)" ]]; then
    echo_info "Setting zsh as default shell..."
    chsh -s "$(which zsh)"
fi

# Source the new shell configuration
if [[ -f "$HOME/.zshrc" ]]; then
    echo_info "Sourcing new shell configuration..."
    source "$HOME/.zshrc"
fi

echo_info "Bootstrap complete! 🎉"
echo_info "You may need to:"
echo_info "  - Restart your terminal or run 'exec zsh'"
echo_info "  - Configure any remaining application settings"
echo_info "  - Update the git clone URL in this script to your actual repository"