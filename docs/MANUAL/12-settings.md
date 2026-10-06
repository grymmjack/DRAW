# Ch. 12  ⚙️ UI Customization & Settings

> **What you'll learn:** How to configure DRAW to your taste — the eight-tab settings dialog, theming, panel docking, and the various ways `DRAW.cfg` works under the hood.

---

## Settings Dialog — All 8 Tabs Explained

> 🎯 **Goal:** Configure DRAW to your preferences.

Open the settings dialog with `Ctrl+,` (comma) or `Edit → Settings`. The dialog has eight tabs covering every persistent option.

| Tab | What it controls |
| --- | --- |
| **General** | Display scale, fullscreen toggle, FPS limit, UI scaling, tooltips and the **Help Card** (on/off, which edge of the canvas area it docks to, hover delay). **Tooltip Delay** and **Help Card Delay** work the same way: 0–5000 ms (0 = instant). The **−**/**+** buttons and the mouse wheel step by 50 ms, and you can click the number to type an exact value, **Enable AI Features**. |
| **Grid** | Default grid size, geometry, alignment, snap state, crosshair appearance. |
| **Palette** | Default palette, recent-palettes list size, Lospec UI visibility. |
| **Panels** | Default visibility for Toolbox, Layers, Edit Bar, Advanced Bar, Preview, Character Map, Drawer, Color Mixer. |
| **Audio** | SFX and music enable/disable, master volume, mute. |
| **Fonts** | Default font and size, paths to scan for TTF/OTF. |
| **Appearance** | Various color scheme configurations. |
| **Directories** | Where DRAW looks for templates, palettes, music. |

### Enable AI Features

AI image generation is **off by default**, and while it is off DRAW surfaces
nothing about it — no AI menu, no commands, no layer markers, no status text.
Some people want nothing to do with generative tooling, and a disabled-but-
visible feature is still in the way.

Tick **Enable AI Features** in the General tab to turn it on. That checkbox is
the only place AI is mentioned while disabled. See
[Ch. 21 — AI Image Generation](21-ai-generation.md).

### User fonts

Drop your own fonts into DRAW's **user data directory** and they show up in the
font pickers — no reinstall, no config editing. The base folder is
`<data>/FONTS/` (Linux `~/.local/share/DRAW/FONTS/`, with the platform data-dir
equivalent on macOS/Windows). Where each type goes:

| Font type | Extensions | Where to put it |
| --- | --- | --- |
| **TTF / OTF** | `.ttf` `.otf` | `FONTS/` root **or** any subfolder |
| **Bitmap** | `.fxx`/F16/F14/F08, `.psf`, `.bdf`, `.pcf`, `.fon` | a **subfolder** of `FONTS/` |
| **Color bitmap (CBF)** | DPaint-style `.bmp` spritesheets | a **subfolder** of `FONTS/` |
| **TheDraw** | `.TDF` | `FONTS/THEDRAW/` — plain `.TDF` files, no `.TDX` index needed |

A subfolder's name becomes its group label in the font dropdown. Each source has
a checkbox in the **Fonts** settings tab — **User TTF/OTF Fonts**, **User Bitmap
Fonts**, **User TDF Fonts** — mirrored by `FONTS_INCLUDE_USER`,
`FONTS_INCLUDE_USER_BITMAP`, and `FONTS_INCLUDE_USER_TDF` in `DRAW.cfg`. Toggles
take effect on the next launch.

### `DRAW.cfg`

`DRAW.cfg` is a plain-text key/value file that lives next to the executable. You can hand-edit it any time. There are also **OS-specific** variants — `DRAW.linux.cfg`, `DRAW.macOS.cfg`, `DRAW.windows.cfg` — that override the base file when present.

CLI flags:

- `--config /path/to/your.cfg` — use a non-default config file.
- `--config-upgrade` — reconcile your existing config with any new defaults introduced by an upgrade. Recommended after each release.
- `--option KEY=VALUE` — override any config key from the command line (repeatable; beats the `.cfg`). E.g. `--option FONTS_INCLUDE_USER_TDF=TRUE`.
- `--options-list` — print every config key with its default and description, then exit.
- `--cfg` — print the path of the config file DRAW is actually using (after `--config`, OS-specific files and `--portable` are taken into account), then exit. Handy as `vim $(DRAW --cfg)`.
- `--dirs` — list every DRAW folder: config, data, cache, crash logs, templates, brush/pattern/gradient sets, palettes, fonts, and the current theme's images, sounds, music, cursors and fonts.
- `--dir-NAME` — print one of those folders as a bare path, e.g. `cd $(DRAW --dir-theme-sounds)` or `ls $(DRAW --dir-crash-logs)`. Names: `cfg data cache crash-logs templates brushes patterns gradients palettes fonts theme theme-images theme-sounds theme-music theme-cursors theme-fonts`.

`DRAW --help` is colored in a terminal (plain when piped, with `--no-color`, or when `NO_COLOR` is set). If `ASSETS/DRAW.ans` exists, the ANSI-art logo in it is printed above the help.

<div class="page-break"></div>

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

<div class="page-break"></div>

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

### Workspaces

A **workspace** is a layout preset that DRAW overlays on your own setup. It can set which panels show, the toolbox, the menus, the bars and extra keys. Leaving it puts everything back, and nothing it changes is saved to `DRAW.cfg`. Switch with **View → Workspace**, **`Ctrl+Shift+W`**, or the `[WS: name]` status badge. Inside a workspace, `F11` shows what it hid. See **[Chapter 22 — Workspaces & Screenshot Annotation](22-workspaces-capture.md)**.

### Cursor system

The cursor system uses your OS-native cursor for UI hovers and a custom-painted cursor for tool-specific feedback (crosshair on dot, brush footprint on brush, etc.). This is automatic and themeable.

---

➡️ Next: [Chapter 13 — Audio: Music & Sound Effects](13-audio.md)
