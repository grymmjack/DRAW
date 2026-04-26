# Ch. 12  ⚙️ UI Customization & Settings

> **What you'll learn:** How to configure DRAW to your taste — the eight-tab settings dialog, theming, panel docking, and the various ways `DRAW.cfg` works under the hood.

---

## Settings Dialog — All 8 Tabs Explained

> 🎯 **Goal:** Configure DRAW to your preferences.

Open the settings dialog with `Ctrl+,` (comma) or `Edit → Settings`. The dialog has eight tabs covering every persistent option.

| Tab | What it controls |
| --- | --- |
| **General** | Display scale, fullscreen toggle, FPS limit, UI scaling. |
| **Grid** | Default grid size, geometry, alignment, snap state, crosshair appearance. |
| **Palette** | Default palette, recent-palettes list size, Lospec UI visibility. |
| **Panels** | Default visibility for Toolbox, Layers, Edit Bar, Advanced Bar, Preview, Character Map, Drawer, Color Mixer. |
| **Audio** | SFX and music enable/disable, master volume, mute. |
| **Fonts** | Default font and size, paths to scan for TTF/OTF. |
| **Appearance** | Various color scheme configurations. |
| **Directories** | Where DRAW looks for templates, palettes, music. |

### `DRAW.cfg`

`DRAW.cfg` is a plain-text key/value file that lives next to the executable. You can hand-edit it any time. There are also **OS-specific** variants — `DRAW.linux.cfg`, `DRAW.macOS.cfg`, `DRAW.windows.cfg` — that override the base file when present.

CLI flags:

- `--config /path/to/your.cfg` — use a non-default config file.
- `--config-upgrade` — reconcile your existing config with any new defaults introduced by an upgrade. Recommended after each release.

## Theming — Icons, Colors & Sounds

> 🎯 **Goal:** Customize DRAW's look and feel.

A **theme** is a folder under `ASSETS/THEMES/` that contains:

- A `THEME.CFG` file with all UI colors.
- A directory of icon PNGs (replaceable per theme — see `ASSETS/THEMES/DEFAULT/IMAGES/`).
- A `SOUNDS/` folder of WAV/OGG files (per-theme SFX).
- A `MUSIC/` folder of tracker tunes that play on startup or via the Audio menu.
- A `FONTS/` folder of bitmap and vector fonts.
- A `splash.png` for the launch animation.

Anything you can theme — UI palette, transform-overlay frame, smart-guide colors, layer panel highlights — lives in `THEME.CFG`. **No recompile is required**; DRAW reloads themes at runtime.

### Display & Toolbar scale

- **Display Scale** — 1× through 8×. Suits HiDPI monitors.
- **Toolbar Scale** — 1× through 4×. Independent of display scale, so you can have small toolbar icons on a HiDPI display.

## Panel Layout & Docking

> 🎯 **Goal:** Arrange panels for your workflow.

### Dockable panels

| Panel | Toggle |
| --- | --- |
| Toolbox | `Tab` |
| Layer Panel | `Ctrl+L` |
| Edit Bar | `F5` |
| Advanced Bar | `Shift+F5` |
| Character Map | `Ctrl+M` |
| Preview Window | `F4` |
| Drawer | (Organizer / View menu) |
| Color Mixer | View → Color Mixer |

Each can be docked **left or right** by `Ctrl+Shift`+clicking on the panel itself.

### UI master toggles

- `F11` — toggle **all** UI (canvas-only mode).
- `Ctrl+F11` — keep only the menu bar.
- `F10` — toggle the status bar.

DRAW also supports **auto-hide** while drawing: panels fade out so they don't obscure your work, then return when the cursor leaves the canvas.

### Cursor system

The cursor system uses your OS-native cursor for UI hovers and a custom-painted cursor for tool-specific feedback (crosshair on dot, brush footprint on brush, etc.). This is automatic and themeable.

> 📸 **Screenshot needed — settings dialog (General tab)**
> - **Setup:** Open `Edit → Settings`. Default theme.
> - **Action:** None — capture the General tab.
> - **Capture:** Full dialog overlapping the canvas.
> - **Save as:** `images/ch12-settings-general.png`

---

➡️ Next: [Chapter 13 — Audio: Music & Sound Effects](13-audio.md)
