# Machine-Specific Overrides

This directory contains machine-specific configuration overrides that merge with or replace shared settings.

## Structure

```
overrides/
├── MACHINE_ID/
│   ├── user-settings/
│   │   └── @jupyterlab/
│   │       └── apputils-extension/
│   │           └── themes.jupyterlab-settings  # Override theme
│   └── custom.css                               # Appended to base CSS
```

## How Overrides Work

### JSON Settings (Deep Merge)
JSON files are **deep merged** using `jq`. The override file's values take precedence:

**Base** (`themes.jupyterlab-settings`):
```json
{
    "theme": "JupyterLab Dark",
    "theme-scrollbars": true
}
```

**Override** (`work-laptop/user-settings/@jupyterlab/apputils-extension/themes.jupyterlab-settings`):
```json
{
    "theme": "JupyterLab Light"
}
```

**Result**:
```json
{
    "theme": "JupyterLab Light",
    "theme-scrollbars": true
}
```

### CSS Files (Concatenation)
CSS override files are **concatenated** to the base CSS:
- Base CSS rules apply first
- Override CSS can add new rules or override existing ones using specificity

## Machine ID

The machine ID is determined by:
1. First argument to `apply-jupyter-configs.sh`
2. Falls back to `hostname -s` (short hostname)

## Example Machine IDs

- `work-laptop` - Corporate machine (light theme, smaller fonts)
- `home-desktop` - Personal desktop (dark theme, default fonts)
- `server` - Remote server (minimal overrides)

## Creating Overrides

1. Create directory: `mkdir -p overrides/MY_MACHINE/user-settings`
2. Add override files matching the structure in `jupyterlab/user-settings/`
3. Only override what you need - missing files use shared defaults
4. Run: `./scripts/apply-jupyter-configs.sh MY_MACHINE`
