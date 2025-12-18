#!/usr/bin/env bash
# apply-jupyter-configs.sh
# Synchronize JupyterLab settings across machines with machine-specific overrides
# Usage: ./apply-jupyter-configs.sh [MACHINE_ID] [--symlink]

set -euo pipefail

#######################################
# Configuration
#######################################

# Determine script directory (works with symlinks)
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

JUPYTER_CONFIG_DIR="${JUPYTER_CONFIG_DIR:-$HOME/.jupyter}"
MACHINE_ID="${1:-$(hostname -s)}"
USE_SYMLINK="${2:-}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

check_dependencies() {
    local missing_deps=()

    for cmd in jq rsync; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done

    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        log_error "Install with: brew install jq (macOS) or apt-get install jq (Linux)"
        return 1
    fi
}

validate_json() {
    local file="$1"
    if ! jq empty "$file" 2>/dev/null; then
        log_error "Invalid JSON in file: $file"
        return 1
    fi
}

merge_json_files() {
    local base_file="$1"
    local override_file="$2"
    local output_file="$3"

    log_info "Merging: $(basename "$base_file") + $(basename "$override_file")"

    # Validate both files
    validate_json "$base_file" || return 1
    validate_json "$override_file" || return 1

    # Deep merge: override_file takes precedence
    # This uses jq's recursive merge (*)
    jq -s '.[0] * .[1]' "$base_file" "$override_file" > "$output_file"

    # Validate output
    validate_json "$output_file" || return 1

    log_success "Merged to: $output_file"
}

copy_or_symlink() {
    local src="$1"
    local dest="$2"
    local use_symlink="$3"

    # Create parent directory if needed
    mkdir -p "$(dirname "$dest")"

    # Remove existing file/symlink
    if [ -e "$dest" ] || [ -L "$dest" ]; then
        rm -f "$dest"
    fi

    if [ "$use_symlink" = "--symlink" ]; then
        ln -s "$src" "$dest"
        log_success "Symlinked: $(basename "$src") → $dest"
    else
        cp "$src" "$dest"
        log_success "Copied: $(basename "$src") → $dest"
    fi
}

#######################################
# Main Functions
#######################################

setup_directories() {
    log_info "Setting up JupyterLab directories..."

    mkdir -p "$JUPYTER_CONFIG_DIR/lab/user-settings"
    mkdir -p "$JUPYTER_CONFIG_DIR/lab/workspaces"
    mkdir -p "$JUPYTER_CONFIG_DIR/custom"

    log_success "Created directories in $JUPYTER_CONFIG_DIR"
}

apply_shared_settings() {
    log_info "Applying shared user settings..."

    local settings_dir="$DOTFILES_ROOT/jupyterlab/user-settings"
    local target_dir="$JUPYTER_CONFIG_DIR/lab/user-settings"

    if [ ! -d "$settings_dir" ]; then
        log_warn "No shared settings found at $settings_dir"
        return 0
    fi

    # Find all .jupyterlab-settings files
    while IFS= read -r -d '' settings_file; do
        # Get relative path from settings_dir
        local rel_path="${settings_file#$settings_dir/}"
        local target_file="$target_dir/$rel_path"
        local override_file="$DOTFILES_ROOT/overrides/$MACHINE_ID/user-settings/$rel_path"

        # Check if machine-specific override exists
        if [ -f "$override_file" ]; then
            log_info "Found override for: $rel_path"

            # Create temp file for merged result
            local temp_file
            temp_file=$(mktemp)

            # Merge and copy
            if merge_json_files "$settings_file" "$override_file" "$temp_file"; then
                mkdir -p "$(dirname "$target_file")"
                mv "$temp_file" "$target_file"
                log_success "Applied merged settings: $rel_path"
            else
                log_error "Failed to merge: $rel_path"
                rm -f "$temp_file"
                return 1
            fi
        else
            # No override, just copy/symlink
            copy_or_symlink "$settings_file" "$target_file" "$USE_SYMLINK"
        fi
    done < <(find "$settings_dir" -type f -name "*.jupyterlab-settings" -print0)
}

apply_workspaces() {
    log_info "Applying workspaces..."

    local workspaces_dir="$DOTFILES_ROOT/jupyterlab/workspaces"
    local target_dir="$JUPYTER_CONFIG_DIR/lab/workspaces"

    if [ ! -d "$workspaces_dir" ]; then
        log_warn "No workspaces found at $workspaces_dir"
        return 0
    fi

    # Copy/symlink all workspace files
    while IFS= read -r -d '' workspace_file; do
        local filename
        filename=$(basename "$workspace_file")
        local target_file="$target_dir/$filename"

        copy_or_symlink "$workspace_file" "$target_file" "$USE_SYMLINK"
    done < <(find "$workspaces_dir" -type f -name "*.jupyterlab-workspace" -print0)
}

apply_custom_css() {
    log_info "Applying custom CSS..."

    local css_file="$DOTFILES_ROOT/jupyterlab/custom.css"
    local target_file="$JUPYTER_CONFIG_DIR/custom/custom.css"
    local override_css="$DOTFILES_ROOT/overrides/$MACHINE_ID/custom.css"

    if [ -f "$css_file" ]; then
        if [ -f "$override_css" ]; then
            # Concatenate CSS files (override appends to base)
            log_info "Merging custom CSS with machine override"
            mkdir -p "$(dirname "$target_file")"
            cat "$css_file" "$override_css" > "$target_file"
            log_success "Applied merged custom CSS"
        else
            copy_or_symlink "$css_file" "$target_file" "$USE_SYMLINK"
        fi
    fi
}

show_summary() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_success "JupyterLab configuration applied!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Machine ID: $MACHINE_ID"
    echo "Config dir: $JUPYTER_CONFIG_DIR"
    echo "Method: $([ "$USE_SYMLINK" = "--symlink" ] && echo "Symlinks" || echo "Copied files")"
    echo ""
    log_info "Restart JupyterLab for changes to take effect:"
    echo "    jupyter lab"
    echo ""
}

#######################################
# Main Execution
#######################################

main() {
    echo ""
    echo "╔═══════════════════════════════════════════╗"
    echo "║  JupyterLab Config Synchronization Tool  ║"
    echo "╚═══════════════════════════════════════════╝"
    echo ""

    # Check dependencies
    if ! check_dependencies; then
        exit 1
    fi

    log_info "Machine ID: $MACHINE_ID"
    log_info "Dotfiles root: $DOTFILES_ROOT"
    log_info "Target directory: $JUPYTER_CONFIG_DIR"
    echo ""

    # Execute setup steps
    setup_directories
    apply_shared_settings
    apply_workspaces
    apply_custom_css

    show_summary
}

# Run main function
main "$@"
