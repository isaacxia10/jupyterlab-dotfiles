#!/usr/bin/env bash
# wsl-quick-setup.sh
# Quick setup script specifically for WSL environments
# Run this inside WSL for a complete dotfiles + tools setup

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ${NC} $*"; }
log_success() { echo -e "${GREEN}✓${NC} $*"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $*"; }
log_error() { echo -e "${RED}✗${NC} $*" >&2; }

# Check if running in WSL
if ! grep -qEi "(microsoft|wsl)" /proc/version 2>/dev/null; then
    log_error "This script is designed for WSL. Run it inside WSL."
    exit 1
fi

echo ""
echo "╔═══════════════════════════════════════════╗"
echo "║       WSL Quick Setup Script              ║"
echo "╚═══════════════════════════════════════════╝"
echo ""

# Check if we're in the dotfiles directory
if [ ! -f "scripts/wsl-quick-setup.sh" ]; then
    log_error "Please run this script from the dotfiles directory"
    log_error "  cd ~/.dotfiles"
    log_error "  ./scripts/wsl-quick-setup.sh"
    exit 1
fi

DOTFILES_DIR="$(pwd)"

# Install Rust and Cargo
if ! command -v cargo >/dev/null 2>&1; then
    log_info "Installing Rust and Cargo..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    log_success "Rust installed"
else
    log_info "Rust already installed"
fi

# Install CLI tools via Cargo
log_info "Installing CLI tools via Cargo..."
TOOLS="starship bat eza zoxide git-delta"
for tool in $TOOLS; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        log_info "Installing $tool..."
        cargo install "$tool"
    else
        log_info "$tool already installed"
    fi
done

# Install fzf and zsh plugins via apt
log_info "Installing apt packages..."
sudo apt update
PACKAGES="fzf zsh zsh-autosuggestions zsh-syntax-highlighting git curl"
for pkg in $PACKAGES; do
    if ! dpkg -l | grep -q "^ii  $pkg"; then
        log_info "Installing $pkg..."
        sudo apt install -y "$pkg"
    else
        log_info "$pkg already installed"
    fi
done

# Apply shell configuration
log_info "Applying shell configuration..."
"$DOTFILES_DIR/scripts/apply-shell-configs.sh"

# Apply JupyterLab configuration (if user wants it)
echo ""
read -p "Apply JupyterLab configuration? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    "$DOTFILES_DIR/scripts/apply-jupyter-configs.sh"
fi

# Optionally set Zsh as default shell
if [ "$SHELL" != "$(which zsh)" ]; then
    echo ""
    read -p "Set Zsh as default shell? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        chsh -s "$(which zsh)"
        log_success "Zsh set as default shell (restart terminal to take effect)"
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_success "WSL setup complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
log_info "Next steps:"
echo "  1. Reload your shell: source ~/.zshrc (or logout/login)"
echo "  2. Verify tools work: starship --version, bat --version, eza --version"
echo "  3. Optional: Install Python/uv for JupyterLab"
echo "     curl -LsSf https://astral.sh/uv/install.sh | sh"
echo "     uv pip install jupyterlab jupyterlab-vim jupyterlab-execute-time"
echo ""
log_info "See WSL_SETUP.md for more WSL-specific tips and troubleshooting"
echo ""
