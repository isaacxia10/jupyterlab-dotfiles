# WSL (Windows Subsystem for Linux) Setup Guide

Complete setup guide for using this dotfiles repository with WSL.

## Prerequisites

1. **WSL 2** installed (recommended over WSL 1)
   ```powershell
   # In PowerShell (as Administrator)
   wsl --install
   # Or install specific distro
   wsl --install -d Ubuntu
   ```

2. **Windows Terminal** (optional but highly recommended)
   - Install from Microsoft Store
   - Much better than default WSL terminal

## Quick Setup

### 1. Install WSL and Clone Dotfiles

```bash
# Inside WSL (Ubuntu)
cd ~

# Clone dotfiles
git clone https://github.com/isaacxia10/jupyterlab-dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

### 2. Install Tools

**Option A: Using Cargo (Recommended - Latest Versions)**

```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"

# Install all tools via Cargo
cargo install starship bat eza zoxide git-delta

# Install fzf and zsh plugins via apt
sudo apt update
sudo apt install fzf zsh-autosuggestions zsh-syntax-highlighting

# Optional: Install Zsh if not default
sudo apt install zsh
chsh -s $(which zsh)  # Make Zsh default shell
```

**Option B: Using Homebrew (Alternative)**

```bash
# Install Homebrew on WSL
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Add Homebrew to PATH
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc

# Install tools
brew install starship bat eza zoxide fzf git-delta zsh-autosuggestions zsh-syntax-highlighting
```

### 3. Apply Shell Configuration

```bash
cd ~/.dotfiles
./scripts/apply-shell-configs.sh
```

### 4. Apply JupyterLab Configuration (Optional)

```bash
# If you're using JupyterLab in WSL
./scripts/apply-jupyter-configs.sh
```

### 5. Reload Shell

```bash
# If using Zsh
source ~/.zshrc

# If using Bash
source ~/.bashrc
```

## WSL-Specific Considerations

### File System Performance

WSL2 has different performance characteristics:

```bash
# ✅ FAST: Work in WSL filesystem
cd ~
cd ~/projects

# ❌ SLOW: Avoid Windows filesystem when possible
cd /mnt/c/Users/YourName/projects
```

**Recommendation**: Clone your repos and work inside WSL (`~/projects`), not in Windows (`/mnt/c/`).

### Git Configuration

Set up Git to handle line endings correctly:

```bash
# In WSL
git config --global core.autocrlf input
git config --global core.eol lf

# Verify
git config --global --list | grep -E "autocrlf|eol"
```

### Windows PATH Pollution

WSL inherits Windows PATH, which can slow down commands. To clean it up:

Edit `~/.dotfiles/overrides/$(hostname -s)/zshrc` (or create it):

```bash
# Filter out Windows paths from PATH
export PATH=$(echo "$PATH" | tr ':' '\n' | grep -v "/mnt/c" | tr '\n' ':' | sed 's/:$//')
```

### X11 / GUI Apps

If you want to run Linux GUI apps from WSL:

**Option 1: WSLg (WSL2 with Windows 11)**
- Built-in, no configuration needed
- Just install GUI apps: `sudo apt install gedit`

**Option 2: X Server (older Windows versions)**

```bash
# Install VcXsrv or Xming on Windows
# Then in WSL, add to your override config:
export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0
```

### Docker in WSL

```bash
# Install Docker Desktop on Windows with WSL2 backend (recommended)
# Or install Docker directly in WSL:
sudo apt update
sudo apt install docker.io
sudo usermod -aG docker $USER
# Logout and login for group change to take effect
```

## Troubleshooting

### "Command not found" after installing with Cargo

Add Cargo bin to PATH:

```bash
echo 'source "$HOME/.cargo/env"' >> ~/.bashrc
source ~/.bashrc
```

### Slow performance in Windows directories

Move your work to WSL filesystem:

```bash
# Copy projects from Windows to WSL
cp -r /mnt/c/Users/YourName/projects ~/projects
cd ~/projects
```

### Zsh plugins not loading

Check plugin location:

```bash
# Should be in /usr/share/
ls -la /usr/share/zsh*

# If missing, install:
sudo apt install zsh-autosuggestions zsh-syntax-highlighting
```

### Delta not showing in git diff

Verify git config:

```bash
git config --global --list | grep delta

# If missing, configure manually:
git config --global core.pager "delta"
git config --global interactive.diffFilter "delta --color-only"
```

## Integration with Windows

### Access Windows Files

```bash
# Windows C: drive
cd /mnt/c/Users/YourName

# Windows D: drive
cd /mnt/d/
```

### Open Files in Windows Apps

```bash
# Open file in Windows default editor
explorer.exe file.txt

# Open current directory in Windows Explorer
explorer.exe .

# Open in VS Code (if installed on Windows)
code .
```

### Run Windows Commands from WSL

```bash
# Windows commands work if you add .exe
ipconfig.exe
notepad.exe
powershell.exe -Command "Get-Date"
```

## Recommended WSL Setup

### Windows Terminal Configuration

Create a nice profile for your WSL distro:

1. Open Windows Terminal
2. Settings → Ubuntu (or your distro)
3. Set starting directory: `\\wsl$\Ubuntu\home\yourname`
4. Set icon, colors, font, etc.

### VSCode WSL Extension

```bash
# In WSL, install VS Code server
code .  # First time will install VS Code Server

# Or install the WSL extension in VS Code on Windows
# Then: Ctrl+Shift+P → "WSL: Connect to WSL"
```

## Complete Example Setup Script

```bash
#!/bin/bash
# WSL complete setup script

set -e

echo "📦 Installing Rust and Cargo..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"

echo "🔧 Installing CLI tools via Cargo..."
cargo install starship bat eza zoxide git-delta

echo "📦 Installing additional tools via apt..."
sudo apt update
sudo apt install -y fzf zsh zsh-autosuggestions zsh-syntax-highlighting git curl

echo "📁 Cloning dotfiles..."
git clone https://github.com/isaacxia10/jupyterlab-dotfiles.git ~/.dotfiles

echo "⚙️  Applying shell configuration..."
cd ~/.dotfiles
./scripts/apply-shell-configs.sh

echo "🐚 Setting Zsh as default shell..."
chsh -s $(which zsh)

echo "✅ Setup complete! Log out and back in for shell change to take effect."
echo "   Then run: source ~/.zshrc"
```

Save this as `wsl-setup.sh`, make it executable, and run it!

## Next Steps

1. Customize your configuration in `~/.dotfiles/overrides/$(hostname -s)/`
2. Install JupyterLab: `uv pip install jupyterlab jupyterlab-vim jupyterlab-execute-time`
3. Set up Python/uv: https://docs.astral.sh/uv/
4. Explore the tools: `starship`, `bat`, `eza`, `zoxide`, `fzf`, `delta`

Happy coding in WSL! 🚀
