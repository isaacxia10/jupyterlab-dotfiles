# JupyterLab Dotfiles

Synchronize JupyterLab settings across multiple machines with machine-specific overrides and deep JSON merging.

## Features

- 🔄 **Deep JSON Merge**: Override specific keys without losing shared settings
- 🖥️ **Machine-Specific Overrides**: Different themes, vim mappings, or CSS per machine
- 🔗 **Symlink or Copy**: Choose your deployment strategy
- ✅ **JSON Validation**: Automatic validation with helpful error messages
- 🎨 **CSS Concatenation**: Append machine-specific CSS to shared base
- 🚀 **Bootstrap Ready**: One-command setup for new machines

## Quick Start

### Option 1: Bootstrap (New Machine)

```bash
# Clone this repo (or your fork)
git clone https://github.com/USER/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Run bootstrap
./scripts/bootstrap.sh MY_MACHINE_ID

# Or use auto-detected hostname
./scripts/bootstrap.sh
```

### Option 2: Manual Application

```bash
cd ~/.dotfiles

# Apply with machine ID
./scripts/apply-jupyter-configs.sh work-laptop

# Or use symlinks (changes sync automatically)
./scripts/apply-jupyter-configs.sh work-laptop --symlink
```

## Directory Structure

```
dotfiles/
├── jupyterlab/
│   ├── user-settings/                          # Shared settings
│   │   ├── @jupyterlab/
│   │   │   ├── apputils-extension/
│   │   │   │   └── themes.jupyterlab-settings  # Dark theme
│   │   │   ├── notebook-extension/
│   │   │   │   └── tracker.jupyterlab-settings # Line numbers, timing
│   │   │   └── shortcuts-extension/
│   │   │       └── shortcuts.jupyterlab-settings
│   │   ├── jupyterlab-execute-time/
│   │   │   └── *.jupyterlab-settings           # Cell execution time
│   │   └── jupyterlab-vimrc/
│   │       └── plugin.jupyterlab-settings      # Vim mappings
│   ├── workspaces/
│   │   └── default.jupyterlab-workspace        # Saved layouts
│   └── custom.css                              # Base CSS
│
├── overrides/                                  # Machine-specific
│   ├── work-laptop/
│   │   ├── user-settings/
│   │   │   └── @jupyterlab/apputils-extension/
│   │   │       └── themes.jupyterlab-settings  # Light theme override
│   │   └── custom.css                          # Smaller fonts
│   └── home-desktop/
│       └── user-settings/
│           └── @jupyterlab/apputils-extension/
│               └── themes.jupyterlab-settings  # Dark theme, no scrollbars
│
└── scripts/
    ├── apply-jupyter-configs.sh                # Main sync script
    └── bootstrap.sh                            # New machine setup
```

## JSON Merge Strategy

Settings are **deep merged** using `jq`. Override files only need to specify keys that differ.

### Example: Theme Override

**Shared** (`jupyterlab/user-settings/@jupyterlab/apputils-extension/themes.jupyterlab-settings`):
```json
{
    "theme": "JupyterLab Dark",
    "theme-scrollbars": true
}
```

**Override** (`overrides/work-laptop/user-settings/@jupyterlab/apputils-extension/themes.jupyterlab-settings`):
```json
{
    "theme": "JupyterLab Light"
}
```

**Result on work-laptop**:
```json
{
    "theme": "JupyterLab Light",
    "theme-scrollbars": true
}
```

### Example: Vim Mappings

**Shared** (`jupyterlab/user-settings/jupyterlab-vimrc/plugin.jupyterlab-settings`):
```json
{
    "imap": [
        ["jk", "<Esc>"]
    ],
    "nmap": [
        ["H", "^"],
        ["L", "$"]
    ]
}
```

**Override** (`overrides/work-laptop/user-settings/jupyterlab-vimrc/plugin.jupyterlab-settings`):
```json
{
    "imap": [
        ["jj", "<Esc>"]
    ],
    "nmap": [
        ["<Space>w", ":w<CR>"]
    ]
}
```

**Result on work-laptop** (arrays are replaced, not merged):
```json
{
    "imap": [
        ["jj", "<Esc>"]
    ],
    "nmap": [
        ["<Space>w", ":w<CR>"]
    ]
}
```

⚠️ **Note**: JSON arrays are **replaced entirely**, not merged. If you override an array, provide all desired values.

## CSS Concatenation

CSS files are **concatenated** rather than merged:

1. Base CSS from `jupyterlab/custom.css` is applied first
2. Machine override CSS from `overrides/MACHINE_ID/custom.css` is appended
3. Override rules can use CSS specificity to override base rules

**Example**:

```css
/* Base: Full width cells */
:root {
    --jp-notebook-max-width: 100%;
}

/* Override: Smaller fonts for work laptop */
:root {
    --jp-code-font-size: 12px;  /* Overrides or adds to base */
}
```

## Machine Identification

Machine ID is determined by (in order):
1. First argument to `apply-jupyter-configs.sh`
2. Environment variable `$MACHINE_ID`
3. Short hostname from `hostname -s`

### Setting Up a New Machine

```bash
# Option 1: Explicit ID
./scripts/apply-jupyter-configs.sh work-laptop

# Option 2: Set environment variable
export MACHINE_ID=work-laptop
./scripts/apply-jupyter-configs.sh

# Option 3: Use hostname (automatic)
# If hostname is "macbook-pro", it uses "macbook-pro"
./scripts/apply-jupyter-configs.sh
```

## Copy vs Symlink

### Copy Mode (Default)
```bash
./scripts/apply-jupyter-configs.sh work-laptop
```

- ✅ Settings survive dotfiles repo deletion
- ✅ Settings won't change unexpectedly
- ❌ Must re-run script to sync changes

### Symlink Mode
```bash
./scripts/apply-jupyter-configs.sh work-laptop --symlink
```

- ✅ Changes sync automatically (edit once, applies everywhere)
- ✅ Easy to track what settings are active
- ❌ Breaks if dotfiles repo is moved/deleted
- ⚠️ Overrides still create copies (merged JSON can't be symlinked)

## Integration with Machine Bootstrap

Add to your machine setup script:

```bash
#!/bin/bash
# setup-new-machine.sh

# 1. Clone dotfiles
git clone https://github.com/USER/dotfiles.git ~/.dotfiles

# 2. Set machine ID
export MACHINE_ID="work-laptop"  # or "home-desktop", etc.

# 3. Run bootstrap
cd ~/.dotfiles
./scripts/bootstrap.sh

# 4. Install JupyterLab
pip install jupyterlab jupyterlab-vim jupyterlab-vimrc jupyterlab-execute-time

# 5. Launch
jupyter lab
```

Or use the one-liner:
```bash
curl -fsSL https://raw.githubusercontent.com/USER/dotfiles/main/scripts/bootstrap.sh | MACHINE_ID=work-laptop bash
```

## Dependencies

- **jq**: JSON processing (`brew install jq` or `apt-get install jq`)
- **rsync**: File synchronization (usually pre-installed)
- **git**: For cloning/updating (usually pre-installed)

## Example Configurations

### Dark Mode + Full Width + Vim
Already configured in `jupyterlab/user-settings/`!

### Work Machine (Light Theme, Smaller Fonts)
```bash
mkdir -p overrides/work-laptop/user-settings/@jupyterlab/apputils-extension

cat > overrides/work-laptop/user-settings/@jupyterlab/apputils-extension/themes.jupyterlab-settings <<EOF
{
    "theme": "JupyterLab Light"
}
EOF

cat > overrides/work-laptop/custom.css <<EOF
:root {
    --jp-code-font-size: 12px;
    --jp-content-font-size1: 13px;
}
EOF
```

### Home Machine (Dark Theme, No Scrollbars)
```bash
mkdir -p overrides/home-desktop/user-settings/@jupyterlab/apputils-extension

cat > overrides/home-desktop/user-settings/@jupyterlab/apputils-extension/themes.jupyterlab-settings <<EOF
{
    "theme": "JupyterLab Dark",
    "theme-scrollbars": false
}
EOF
```

## Troubleshooting

### Invalid JSON Error
```bash
# Validate a specific file
jq empty path/to/file.jupyterlab-settings

# Find all invalid JSON files
find dotfiles -name "*.jupyterlab-settings" -exec sh -c 'jq empty "{}" 2>&1 || echo "Invalid: {}"' \;
```

### Settings Not Applying
1. Check JupyterLab is closed
2. Verify files copied: `ls -la ~/.jupyter/lab/user-settings/`
3. Check for JSON syntax errors in logs
4. Clear browser cache (Cmd+Shift+R or Ctrl+Shift+R)

### Symlinks Not Working
- Merged override files are always copied (can't symlink a merge result)
- Check symlink exists: `ls -la ~/.jupyter/lab/user-settings/@jupyterlab/apputils-extension/`
- macOS may require allowing symlinks: `xattr -d com.apple.quarantine ~/.jupyter`

## Workflow Tips

### Daily Workflow
```bash
# Edit settings
vim ~/.dotfiles/jupyterlab/user-settings/jupyterlab-vimrc/plugin.jupyterlab-settings

# Apply changes
cd ~/.dotfiles
./scripts/apply-jupyter-configs.sh

# Restart JupyterLab
# Settings take effect immediately
```

### Adding a New Machine
1. Use on the new machine: `./scripts/apply-jupyter-configs.sh NEW_MACHINE`
2. Create overrides if needed: `mkdir -p overrides/NEW_MACHINE/user-settings`
3. Commit overrides: `git add overrides/NEW_MACHINE && git commit && git push`

### Backing Up Current Settings
```bash
# Export current JupyterLab settings
rsync -av ~/.jupyter/lab/user-settings/ dotfiles/jupyterlab/user-settings/
rsync -av ~/.jupyter/lab/workspaces/ dotfiles/jupyterlab/workspaces/
rsync -av ~/.jupyter/custom/custom.css dotfiles/jupyterlab/custom.css

# Commit
git add dotfiles/jupyterlab/
git commit -m "Update JupyterLab settings"
git push
```

## License

MIT - Feel free to use and modify!
