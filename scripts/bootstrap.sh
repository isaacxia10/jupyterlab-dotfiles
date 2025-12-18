#!/usr/bin/env bash
# bootstrap.sh
# Complete machine bootstrap script for JupyterLab configuration
# Usage: curl -fsSL https://raw.githubusercontent.com/isaacxia10/jupyterlab-dotfiles/main/scripts/bootstrap.sh | bash

set -euo pipefail

#######################################
# Configuration
#######################################

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/isaacxia10/jupyterlab-dotfiles.git}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
MACHINE_ID="${MACHINE_ID:-$(hostname -s)}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

#######################################
# Helper Functions
#######################################

log_info() {
    echo -e "${BLUE}ℹ${NC} $*"
}

log_success() {
    echo -e "${GREEN}✓${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $*"
}

log_error() {
    echo -e "${RED}✗${NC} $*" >&2
}

#######################################
# Installation Steps
#######################################

install_dependencies() {
    log_info "Checking dependencies..."

    # Detect OS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if ! command -v brew >/dev/null 2>&1; then
            log_error "Homebrew not found. Install from https://brew.sh"
            exit 1
        fi

        if ! command -v jq >/dev/null 2>&1; then
            log_info "Installing jq..."
            brew install jq
        fi

    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if ! command -v jq >/dev/null 2>&1; then
            log_info "Installing jq..."
            if command -v apt-get >/dev/null 2>&1; then
                sudo apt-get update && sudo apt-get install -y jq
            elif command -v yum >/dev/null 2>&1; then
                sudo yum install -y jq
            else
                log_error "Package manager not supported. Please install jq manually."
                exit 1
            fi
        fi
    fi

    log_success "Dependencies installed"
}

clone_dotfiles() {
    log_info "Setting up dotfiles..."

    if [ -d "$DOTFILES_DIR" ]; then
        log_info "Dotfiles already exist at $DOTFILES_DIR"
        log_info "Pulling latest changes..."
        cd "$DOTFILES_DIR"
        git pull
    else
        log_info "Cloning dotfiles from $DOTFILES_REPO"
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    fi

    log_success "Dotfiles ready at $DOTFILES_DIR"
}

setup_jupyter() {
    log_info "Configuring JupyterLab..."

    cd "$DOTFILES_DIR"

    # Run the apply script
    bash scripts/apply-jupyter-configs.sh "$MACHINE_ID"

    log_success "JupyterLab configured for machine: $MACHINE_ID"
}

#######################################
# Main Execution
#######################################

main() {
    echo ""
    echo "╔═════════════════════════════════════════╗"
    echo "║     Machine Bootstrap Script            ║"
    echo "╚═════════════════════════════════════════╝"
    echo ""
    echo "Machine ID: $MACHINE_ID"
    echo "Dotfiles dir: $DOTFILES_DIR"
    echo ""

    install_dependencies
    clone_dotfiles
    setup_jupyter

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_success "Bootstrap complete!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    log_info "Next steps:"
    echo "  1. Install Python and JupyterLab: pip install jupyterlab"
    echo "  2. Install extensions: pip install jupyterlab-vim jupyterlab-vimrc jupyterlab-execute-time"
    echo "  3. Launch: jupyter lab"
    echo ""
}

main "$@"
