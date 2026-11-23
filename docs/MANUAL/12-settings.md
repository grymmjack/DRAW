# Ch. 12  ⚙️ UI Customization & Settings

> **What you'll learn:** How to configure DRAW to your taste — the ten-tab settings dialog, theming, panel docking, and the various ways `DRAW.cfg` works under the hood.

---

## Settings Dialog — All 11 Tabs Explained

> 🎯 **Goal:** Configure DRAW to your preferences.

Open the settings dialog with `Ctrl+,` (comma) or `Edit → Settings`. The dialog has eleven tabs covering every persistent option.

| Tab | What it controls |
| --- | --- |
| **General** | Display scale, fullscreen toggle, FPS limit, UI scaling, tooltips and the **Help Card** (on/off, which edge of the canvas area it docks to, hover delay). **Tooltip Delay** and **Help Card Delay** work the same way: 0–5000 ms (0 = instant). The **−**/**+** buttons and the mouse wheel step by 50 ms, and you can click the number to type an exact value, **Enable AI Features**. |
| **Grid** | Default grid size, geometry, alignment, snap state, crosshair appearance. |
| **Palette** | Default palette, recent-palettes list size, Lospec UI visibility; the **Palette Strip**'s size and **Strip Edge** (Bottom / Top / Left / Right — on a side the strip is a column, its rows turned into columns, the palette dropdown above the chips; also the strip's right-click menu → Edge). |
| **Panels** | Default visibility for Toolbox, Layers, Edit Bar, Advanced Bar, PANELS Bar, I/O Bar, Preview, Character Map, Drawer, Color Mixer; Layers panel options, including **Thumbnails** (Off / Tiny / Small / Medium), **Thumbnail Shows** (Content / Canvas), **Min Crop (px)** and **Layer Bar** (Off / Top / Bottom); the animation **Lightbox Strip**: **Strip Layout** (Tray / Row), **Min Cell (px)** and **Cell Size (px)**, and **X-Sheet Rows** (Text / Tiny / Small / Medium: the layer rows and the SOUND rows, whose waveform grows with them). |
| **Audio** | SFX and music enable/disable, master volume, mute. |
| **Fonts** | Default font and size, paths to scan for TTF/OTF. |
| **Appearance** | Various color scheme configurations. |
| **Directories** | Where DRAW looks for templates, palettes, music. |
| **Browser** | The image browser's size, place and default view. |
| **Animation** | The X-sheet's default zoom (**Default Zoom: Show All Frames** - every frame across, or a thumbnail a tick), the X-sheet's **Contrast** (its grid, guides and dotted lines stronger or softer; also `Ctrl+Alt+Shift+wheel` over the X-sheet, `Ctrl+Alt+Shift+middle-click` resets), the transform widget's **Opacity %** (what it starts at and what `Ctrl+Alt+Shift+middle-click` over it restores), the lane curves' **Line Thickness** (1-4 px), **Lane Thumbnails** (Off / Keyframes / Every Frame: thumbnails drawn through the lanes on a laned layer's main X-sheet row), and **Keyframe Lane Colors** - one colour per lane (X, Y, SCALE X / Y, ROTATE, OPACITY, TINT, PIVOT X / Y, VOLUME, PAN) for its curve on the X-sheet and its swatch on the Animation panel's LANES page; **Default Colors** puts them back. Also **ANIM → Set Up → Animation Settings…**. |
| **Pen Control** | Everything for a drawing tablet and stroke smoothing, the same settings as the **Pen Control** panel (View → Panels → Pen Control). **Pen Tablet**: Pen Pressure on or off; pressure sets brush size, mix paint and opacity, each with its lightest-touch value; the tip threshold and the pressure curve. **Position Smoothing**: Smooth Position on or off, the mode (Pulled String / Moving Average / EMA / Inertia), Amount, Catch Up, the guide line and cursor and their colour. **Pressure Processing**: Smooth Pressure on or off, the mode (Fixed / Hold / Average / EMA) and Amount. **Speed Scaling**: Scale Pressure by Speed on or off, the gain at rest and at speed (×100), Fast Speed in screen px/s and Speed Smoothing. See *Pen Tablets & Pressure* and *Stroke Smoothing* in Ch. 2. |

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
- **Panel Scale** — the Animation, Color Mixer, Advanced Color Picker, 3D Color Space, Pen Control, Swatches, Preview and Browser panels, and the docked Toolbox, Organizer, Drawer, Layers, Edit Bar, Advanced Bar, PANELS Bar, I/O Bar, Character Map, Workflow Buttons, the text tool's bar, the Selection Bar, the MyPaint Brushes and MyPaint Brush Settings, Brushes, History and Actions, each have their own size: **Auto** (the default) follows the UI Scale, or fix one at 1× through 8× — that many screen pixels for each of the panel's pixels, so 1× is as small and sharp as your screen draws. Every panel also takes half steps (1.5×, 2.5× … 7.5×); at a half step the panel is smoothed (bicubic) so text stays even — except the artwork in the Preview window and its loupe, which keep hard pixels; set `PANEL_HALF_FILTER=SHARP` for crisper edges or `NEAREST` for hard pixels. Right-click the panel's title bar (a docked panel's handle) → **Scale**, or Settings → Panels → Panel Scale. **Set All** at the top of Panel Scale sets every panel at once (Auto, or 1×–8× in half steps). A panel whose Auto is bigger or smaller than the UI Scale — the Toolbox, Organizer and Drawer follow the toolbar ratios, the Preview and Browser their own — keeps that proportion: with the UI Scale at 2 and the Toolbox's Auto at 4, Set All 2 gives the Toolbox 4 and the rest 2 (half steps, 1×–8×). The box shows the value the panels match, or **Mixed** while they differ. The command palette's **Panel Scale Settings** opens Settings right at this section.
- **Top/Bottom Docks** — how wide the rows docked along the top and bottom of the canvas area are: **Between Side Docks** (the default; they fill the space between the left and right columns) or **Full Width** (they span the window, and the side columns sit between them). Saved with the arrangement and in workspaces.

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
| Color Mixer | View → Panels → Color Mixer |

Each can be docked **left or right** by `Ctrl+Shift`+clicking on the panel itself.

Beyond left and right, panels can be **stacked** in one column, **tabbed**,
**collapsed** to their title, **floated** in their own window and docked back.
Drag a panel by its handle (its title strip, the layers header, or the thin
grip that appears on a panel's top edge), and right-click a handle for Move to
Left/Right Edge, Dock Along the Top / Bottom, Collapse, Float, Reset Arrangement and
**Scale** (Auto or 1×–8×; see Panel Scale above for the panels that have one). The floating windows
(Preview, Color Mixer, the color pickers, Pen Control, Swatches, Browser) dock by
dragging their title bar onto a dock target. Docked, the Animation, Color
Mixer, color picker, 3D Color Space, Pen Control and Swatches panels fill their slot:
their rows and sliders stretch to the column's width, and in a column with
room to spare their big area — the color field, the wheel and its shade rows,
the 3D view, the response graph — grows taller. Floating, they go back to
their own size. See **[Chapter 22 — Moving,
stacking, tabbing and floating panels](22-workspaces-capture.md#moving-stacking-tabbing-and-floating-panels)**.

### UI master toggles

- `F11` — toggle **all** UI (canvas-only mode); a second `F11` puts back exactly what was showing, in a workspace too.
- `Ctrl+F11` — keep only the menu bar.
- `F10` — toggle the status bar.

DRAW also supports **auto-hide** while drawing: panels fade out so they don't obscure your work, then return when the cursor leaves the canvas.

### Workspaces

A **workspace** is a layout preset that DRAW overlays on your own setup. It can set which panels show, the toolbox, the menus, the bars and extra keys. Leaving it puts everything back, and nothing it changes is saved to `DRAW.cfg`. Switch with **View → Workspace**, **`Ctrl+Shift+W`**, or the `[WS: name]` status badge. Inside a workspace, `F11` shows what it hid. See **[Chapter 22 — Workspaces & Screenshot Annotation](22-workspaces-capture.md)**.

### Cursor system

The cursor system uses your OS-native cursor for UI hovers and a custom-painted cursor for tool-specific feedback (crosshair on dot, brush footprint on brush, etc.). This is automatic and themeable.

---

➡️ Next: [Chapter 13 — Audio: Music & Sound Effects](13-audio.md)
