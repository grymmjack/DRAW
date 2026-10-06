# Workspaces + built-in screenshot capture: plan

A **workspace** is a named preset that decides which UI chrome exists: which toolbox buttons and in what order, which menus and menu items, which panels, the palette strip, docking, keys and starting options. A workspace is layered on top of your normal config, so leaving it restores everything. Workspaces can be switched from the View menu or the command palette, edited in a GIMP-style configurator, and launched with `DRAW --workspace annotate`.

They make room for **built-in screenshot capture**. A hotkey (or `DRAW --capture` bound to a desktop shortcut) grabs the screen. You drag a region and get a new document in the **Annotate** workspace, where single-key hotkeys pick the annotation tools. This replaces the separate Shottr-style tool idea in the *Drive ideas* doc.

## What the code and probes showed (2026-10-06)

**Capture: QB64-PE's `_SCREENIMAGE` only works on Windows.** In `qb64pe/internal/c/libqb.cpp`, the GLFW branch is a `// GLFW_TODO` that returns a blank image the size of the desktop.

| Probe on this machine (Plasma 6.3.6, Wayland, 3840×2160, DRAW through XWayland) | Result |
|---|---|
| `_SCREENIMAGE` | 3840×2160 and entirely black: 0% non-black pixels, one color. |
| `spectacle -b -n -f -o file` | Real content: 3840×2160 with 21,176 colors, captured in **0.47 s**. |
| `grim` | Refused: "compositor doesn't support wlr-screencopy" (KWin is not wlroots). |

So capture needs a **backend per platform**: the native call on Windows, and an OS tool everywhere else.

**UI chrome (full map in this plan's research notes):**
- **Persistence:** visibility of the toolbox column, status bar + palette strip (one flag, `SCRN.showStatus%`), menu bar and layer panel is **never saved**; they always start shown. The edit bar, advanced bar, character map and floating panels do save visibility. All five docked panels save their dock edge.
- **Things that undo a hide:** F11 (action 403) force-shows the toolbar, status bar, layer panel and menu bar. The auto-hide restore (`MOUSE_handle_ui_autohide_restore`) brings back any panel that is hidden but not `ManuallyHidden` (gotcha #12).
- **Toolbox:**
  - It is a fixed 4×7 grid (`TOOLBAR_BUTTON_ORDER(27)` + `TOOLBAR_BUTTON_TO_TOOL(27)`), and `-1` already means an empty cell everywhere.
  - Tooltips are indexed **by position**, so reordering scrambles them.
  - `TB_ROWS`/`TB_COLS` set the panel height, the organizer's Y in both render paths, and the minimum window size.
- **Menus:** there is no hidden flag. Root menus are referenced by **literal indices** (0–9, `openMenu = 10`, "HELP is last"). `MENUBAR_rebuild` already exists; the AI menu toggle is the precedent.
- **Keys:** `INPUT_dispatch_frame` fires the **first** matching binding in registration order, filtered by context bits (`CTX_*`). Unused bits are available, so workspace keys can be a context-scoped overlay registered before the defaults, with nothing swapped or restored. Some keys are read directly with `_KEYDOWN` (E hold, line caps S/E, L/A/R holds) and need their own guards.
- **Layout:** `SCREEN_compute_layout` runs every frame. After changing visibility: set the flags, including `ManuallyHidden`, then call `INVALIDATE_scene` (plus `MENUBAR_rebuild` for menus and `SCREEN_apply_window_size_limits` for the minimum window size).
- **New document from an image:** use the body of action 2058 (New from Clipboard) → `DRW_create_canvas_at_size`, then paste the pixels. Size is capped at 4096×4096.

## Workspace file

Built-in workspaces live in `ASSETS/WORKSPACES/<id>.workspace`; user workspaces in `<data dir>/workspaces/<id>.workspace`. A user file with the same id overrides the built-in. The format is INI-style like `DRAW.cfg`, so the existing key parser and `CONFIG_apply_key%` can be reused.

```ini
[WORKSPACE]
NAME=Annotate
DESCRIPTION=Mark up screenshots: shapes, arrows, text, highlight, redact
BASED_ON=default            ; inherit, then override

[CHROME]                    ; SHOW | HIDE | KEEP (keep = whatever the user has)
MENUBAR=SHOW
TOOLBOX=SHOW
TOOLBOX_DOCK=LEFT
ORGANIZER=HIDE
DRAWER=HIDE
LAYER_PANEL=HIDE
EDIT_BAR=SHOW
ADVANCED_BAR=HIDE
STATUS_BAR=SHOW
PALETTE_STRIP=SHOW          ; split from the status bar flag (W3)
PREVIEW=HIDE
COLOR_MIXER=HIDE
CHARMAP=HIDE

[TOOLBOX]
COLUMNS=2
BUTTONS=move,marquee,rect,ellipse,line,arrow,text,highlight,redact,callout,picker,crop
ICON.callout=callout.png    ; optional per-button icon (theme-relative or absolute)

[MENUS]
ROOTS=FILE,EDIT,VIEW,IMAGE,HELP
HIDE_ITEMS=219,1825          ; action ids (or labels) hidden inside visible menus

[EDIT_BAR]
BUTTONS=undo,redo,|,copy,paste,|,zoomfit

[KEYS]                      ; only while this workspace is active (context-scoped)
r=rect
a=arrow
o=ellipse
l=line
t=text
h=highlight
x=redact
n=callout
c=crop
v=move

[OPTIONS]                   ; any DRAW.cfg key, session-only (never written to DRAW.cfg)
DEFAULT_BRUSH_SIZE=3
SNAP_TO_GRID=FALSE

[START]
TOOL=rect
FG=#FF2040
ZOOM=FIT
```

## Behavior rules

- **A workspace is an overlay.** Applying one first snapshots the live state it touches; leaving restores the snapshot. It never writes its values into `DRAW.cfg`. `CFG.WORKSPACE` remembers the last workspace so DRAW reopens in it, and `--workspace` overrides that for one run.
- **Default** = no overlay (today's DRAW). It is always available and cannot be deleted.
- **There is always a way back,** whatever a workspace hides:
  1. the command palette (`?`);
  2. a workspace switcher popup on a fixed key (proposed Ctrl+Shift+W, in a context no workspace can override);
  3. a `[WS: Annotate]` status-bar badge that opens the switcher;
  4. F11 shows everything the workspace hid, and pressing it again hides them again.
- **Hidden things stay reachable** through the command palette and their key bindings. Hiding means "not shown", not "disabled".
- **Session vs saved changes:** what you toggle while in a workspace (for example opening the color mixer) lasts for that session only. Saving it into the workspace is the configurator's job, with a "save layout to workspace" command.

## Switching and launching

- **View → Workspace ▸** lists Default, the built-ins and user workspaces (radio items), then *Configure Workspaces…*.
- **Command palette:** `Workspace: <name>` for each, plus *Configure Workspaces*.
- **CLI:**
  - `DRAW --workspace annotate [file]` starts in that workspace.
  - `DRAW --workspaces` lists them and exits, like `--dirs`.
  - `DRAW --dir-workspaces` prints the user folder.
- **Keyboard:** Ctrl+Shift+W opens the switcher (arrows + Enter, or the first letter).

## Configurator

A dialog built on the Settings widget framework (`SW_*`). The workspace list is on the left: New, Duplicate, Rename, Delete, and Reset for built-ins. The editor has these tabs:

| Tab | What it edits |
|---|---|
| Panels | Each chrome element: Show / Hide / Keep, plus dock side |
| Toolbox | Grid editor: tick tools from a list of all tools, reorder (drag or up/down), columns, per-button icon, organizer widgets |
| Menus | Tree of roots and items with checkboxes |
| Bars | Edit bar and advanced bar buttons with checkboxes |
| Keys | Letter → tool/action table, with conflict warnings (reuses the Controls dialog's rebind UI) |
| Options | Session overrides of any `DRAW.cfg` key, and the start tool, color and zoom |

Changes apply live, because the preview is the real UI. Cancel restores the previous state.

## Built-in workspaces

| Workspace | What it shows |
|---|---|
| **Default** | Everything, as the user configured it (no overlay) |
| **Simple** | Toolbox: brush, eraser, fill, picker, line, rect, ellipse, text, move, marquee. Menus: File, Edit, View, Help. No advanced bar, character map, 3D color space or AI. |
| **Annotate** | The file above: annotation toolbox in two columns, edit bar, palette strip, single-key tools |

## Screenshot capture

**Flow**
1. **Trigger:** action *Capture Screen* (File → Capture Screen…, command palette, a hotkey), or `DRAW --capture`. Bound to a desktop global shortcut, `DRAW --capture` works even when DRAW is not focused: if DRAW is already running it asks that instance (through the multi-instance mailbox), otherwise it starts DRAW.
2. **Hide DRAW** (`_SCREENHIDE` or minimize), wait `CAPTURE_DELAY_MS` (default 250), grab the screen through the backend, then show DRAW again. An option keeps DRAW visible in the shot.
3. **Region picker:** a blocking full-window overlay (dialog-style loop) showing the frozen capture.
   - **Selecting:** drag a rectangle, then adjust it with handles. A loupe with a size readout follows the pointer (Shottr-style).
   - **Keys:** Enter or double-click accepts, Space takes the whole screen, Esc cancels.
   - **Window mode:** it uses a temporary fullscreen *without* the per-frame `CFG.FULLSCREEN` save (which would otherwise persist it).
4. **New document:** `DRW_new_from_image img&` (pulled out of action 2058) with the cropped region. The crop happens before the document exists, so nothing needs undoing. Larger than 4096 asks to scale or crop.
5. **Switch to the Annotate workspace,** unless `CAPTURE_WORKSPACE` names another.

**Backends** (`CAPTURE_BACKEND=AUTO|NATIVE|COMMAND`, plus `CAPTURE_COMMAND` with a `{file}` placeholder)

| Platform | AUTO picks | Status |
|---|---|---|
| Windows | `_SCREENIMAGE` (primary monitor) | Native QB64-PE |
| macOS | `screencapture -x {file}` | To test |
| Linux, KDE Wayland | `spectacle -b -n -f -o {file}` | **Verified:** 0.47 s, full 4K |
| Linux, GNOME | `gnome-screenshot -f {file}`, or the desktop portal | To test |
| Linux, wlroots (sway, Hyprland) | `grim {file}` | To test |
| Linux, X11 | `import -window root {file}` (ImageMagick), `maim`, or `scrot`; later a native `XGetImage` helper loaded with dlopen | To test |
| Anything else | The xdg-desktop-portal Screenshot call via `gdbus` (may show the portal dialog) | Fallback |

Detection uses `XDG_SESSION_TYPE`, `XDG_CURRENT_DESKTOP` and which tools are installed. A missing tool shows a clear message naming what to install.

**Annotation tools (Annotate workspace)**

| Key | Tool | New or existing |
|---|---|---|
| R / Shift+R | Rectangle / filled | Existing |
| O | Ellipse | Existing (C is taken by crop in Annotate) |
| L | Line | Existing |
| A | **Arrow:** the line tool with a sticky arrow end cap and thicker default stroke. Today the caps are cleared on every tool switch. | Small change |
| T | Text | Existing |
| H | **Highlighter:** a brush preset, wide, semi-transparent, Multiply. H is Flip Horizontal by default, so it's overridden only inside Annotate. | Preset |
| X | **Redact:** drag a box and it is pixelated (or blurred, an option) in one step | **New tool** |
| N | **Numbered callout:** click places a filled circle with an auto-incrementing number. Shift+N resets the count. | **New tool** |
| C | Crop to a dragged box | Existing (crop) |
| V | Move | Existing |

Finishing actions:
- **Ctrl+C** with no selection copies the whole image (Copy Merged, 322).
- **Ctrl+S** saves to `CAPTURE_SAVE_DIR` (default `~/Pictures/DRAW Screenshots`) as `DRAW-YYYYMMDD-HHMMSS.png`, without asking (revives the dead `SAVE_quick`).
- **Ctrl+Enter** copies, saves and closes back to the previous document and workspace.

## Phases

| # | Phase | Contents | Size |
|---|---|---|---|
| P0 | Probes + decisions | Capture probes (done above); confirm the open decisions below | S |
| W1 | Workspace engine | Format + loader (built-in/user, `BASED_ON`), apply/restore overlay for every panel's visibility + dock + `[OPTIONS]` + `[START]`; `CFG.WORKSPACE`; `--workspace`, `--workspaces`; View → Workspace menu, command palette, status badge, switcher + escape hatch; F11 and auto-hide made workspace-aware; Default + Simple built-ins | L |
| W2 | Toolbox layout | Build the order/tool arrays from `BUTTONS=`; variable columns and rows; re-key tooltips by `TB_*`; geometry from real rows (organizer Y in both render paths, minimum window size); hidden Smart Shapes parent; per-button icons; drawer anchor when the organizer is hidden | L |
| W3 | Panels + bars | Organizer widget, edit bar and advanced bar button visibility (by name lists); split the palette strip from the status bar flag | M |
| W4 | Menus | Named root handles instead of literal indices; a hidden-root map and an item filter applied in `MENUBAR_rebuild`; fix the stale `openMenu = 10` | M |
| W5 | Workspace keys | Context bit + per-workspace binding overlay registered first; guards on the `_KEYDOWN`-read keys; menu and command-palette hotkey labels follow the active workspace | M |
| W6 | Configurator | Dialog with the six tabs above, Save / Save As / Duplicate / Delete / Reset, live preview with Cancel restore | L |
| C1 | Capture backends | `CAPTURE_*` config + Settings, backend detection, hide/delay/show, action + menu + command palette, `DRAW --capture` | M |
| C2 | Region picker | Full-window frozen capture, drag box with handles, loupe + size readout, whole-screen and cancel, `DRW_new_from_image` | M |
| C3 | Annotate tools | Sticky-arrow line, highlighter preset, **Redact** and **Numbered callout** tools, copy / quick-save / done actions, Annotate built-in | L |
| C4 | Background capture | Route `DRAW --capture` to the running instance (mailbox) so a desktop shortcut works when DRAW is not focused | S |
| D | Docs + tests | Manual chapter "Workspaces & Screenshot Annotation", SHORTCUTS, instructions file, QA tests (switch/restore, toolbox layout, menus, key overlay, capture via a fake backend command), wiki after merge | M |

The minimum to use capture is **W1 + C1 + C2**: an Annotate workspace with panel visibility only, plus the existing tools. W2–W6 make workspaces fully customizable, and C3 adds the new annotation tools.

## Open decisions

1. **Order:** workspace engine first (W1), then capture (C1–C2), then the rest? (Recommended.)
2. **Capture hotkey inside DRAW:** Print Screen is usually taken by the desktop. Proposed: **Ctrl+Shift+P**. On Plasma, bind a global shortcut to `DRAW --capture`.
3. **Annotate letter keys:** R rect, O ellipse, L line, A arrow, T text, H highlight, X redact, N callout, C crop, V move. OK, or different letters?
4. **After Ctrl+Enter (done):** return to the previous document and workspace (recommended), or stay?
5. **Workspace files:** standalone `.workspace` files (recommended; shareable, could become a KIT item type), or keys inside `DRAW.cfg`?

## Found along the way

- `.claude/instructions/draw-chrome-geometry.md` says `MENU_MAX_ITEMS` 256 and `MENU_MAX_ROOT` 12; the code has 600 and 16.
- `draw-ui.md` says the advanced bar has 33 slots; there are 30.
- `CFG_validate` falls back to the opposite dock edges from the defaults (layers LEFT, toolbox RIGHT; the defaults are RIGHT and LEFT).
- `DRW_load_from_png`'s plain-image path is a fourth document-creation path with its own partial reset (gotcha #15 drift).
- `CROP_apply` records history only when the canvas grows, so a normal crop is not undoable.
- `DRAW.BAS` frees `GUI_TB(0..28)`, so slot 29 (Smart Shapes) is never freed.
