# Vim Keybindings in JupyterLab 4

JupyterLab 4 uses `jupyterlab-vim` extension which provides vim keybindings out of the box.

## Current Status

❌ **jupyterlab-vimrc is NOT compatible with JupyterLab 4**
- `jupyterlab-vimrc` only supports JupyterLab 3.x
- For JupyterLab 4, use native settings instead

✅ **Use jupyterlab-vim alone**
- Install: `uv pip install jupyterlab-vim`
- Provides full vim keybindings
- Configure through JupyterLab's Advanced Settings Editor

## Default Vim Behavior

Out of the box with `jupyterlab-vim`:

### Command Mode (navigating between cells)
- `j`/`k` - Move down/up between cells
- `Enter` - Enter cell in vim normal mode
- `Shift+Enter` - Run cell and move to next
- `dd` - Delete cell
- `yy` - Copy cell
- `p` - Paste cell below
- `o` - Insert cell below
- `O` - Insert cell above

### Edit Mode (inside cell - Normal)
- `i`/`a` - Enter insert mode
- `Esc` - Return to normal mode
- All standard vim motions: `w`, `b`, `e`, `$`, `0`, etc.
- `dd` - Delete line
- `yy` - Yank line
- `p` - Paste

### Edit Mode (inside cell - Insert)
- Standard typing
- `Esc` or `Ctrl+[` - Back to normal mode
- `Shift+Esc` - Back to command mode

## Custom Keybindings (JupyterLab 4)

To add custom vim-style mappings, use JupyterLab's Keyboard Shortcuts:

1. Open JupyterLab
2. Settings → Advanced Settings Editor
3. Keyboard Shortcuts → User Preferences

Example configuration:

```json
{
  "shortcuts": [
    {
      "command": "notebook:run-cell-and-select-next",
      "keys": ["Ctrl Enter"],
      "selector": ".jp-Notebook:focus"
    }
  ]
}
```

## Ergonomic Suggestions

Since `jupyterlab-vimrc` doesn't work with JupyterLab 4, here are alternative approaches:

### Option 1: Use Default Vim Bindings
Just use `jupyterlab-vim` as-is. It provides:
- Full vim modal editing
- Standard vim motions
- Cell navigation with j/k

### Option 2: CodeMirror Vim Config (Advanced)

Create a JupyterLab extension to configure CodeMirror's vim:

```javascript
// In a custom extension
define(['codemirror/keymap/vim'], function(vim) {
  // Map jk to Escape in insert mode
  vim.Vim.map("jk", "<Esc>", "insert");

  // Map H and L to beginning/end of line
  vim.Vim.map("H", "^", "normal");
  vim.Vim.map("L", "$", "normal");
});
```

### Option 3: Wait for jupyterlab-vimrc Update

Track the issue: https://github.com/ianhi/jupyterlab-vimrc/issues

The extension author may release a JupyterLab 4 compatible version in the future.

## Installation

```bash
# Install jupyterlab-vim only (NOT jupyterlab-vimrc)
uv pip install jupyterlab-vim

# Or with other extensions
uv pip install jupyterlab jupyterlab-vim jupyterlab-execute-time
```

## What We Lost from jupyterlab-vimrc

The `jupyterlab-vimrc` extension allowed easy configuration like:

```json
{
  "imap": [["jk", "<Esc>"]],
  "nmap": [["H", "^"], ["L", "$"]]
}
```

**Workaround**: For now, get used to the default vim bindings or wait for JupyterLab 4 support.

## References

- [jupyterlab-vim](https://github.com/jupyterlab-contrib/jupyterlab-vim)
- [jupyterlab-vimrc](https://github.com/ianhi/jupyterlab-vimrc) (JupyterLab 3 only)
- [CodeMirror Vim](https://codemirror.net/5/demo/vim.html)
