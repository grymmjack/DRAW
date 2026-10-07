# Chapter 22 — 🧰 Workspaces & Screenshot Annotation

> 🎯 **Goal:** Make DRAW fit the job in front of you. A workspace switches the
> whole UI to a preset (fewer panels, a smaller toolbox, other keys), and
> **Capture Screen** turns DRAW into a screenshot annotator.

---

## Workspaces

A **workspace** is a named layout preset. It decides:
- which panels show and where they dock;
- which toolbox buttons exist, in what order, and how many per row;
- which menus and menu items appear;
- which edit bar, advanced bar and organizer buttons show;
- single-key shortcuts that only work while it is active;
- a few starting options.

A workspace is an **overlay** on your own setup. Switching to one notes how
everything is now, and leaving it puts every panel, dock and option back
exactly as it was. Nothing a workspace changes is written to `DRAW.cfg`. DRAW
only remembers *which* workspace you were in, so it reopens there.

### Built-in workspaces

| Workspace | What it is |
| --- | --- |
| **Default** | Your own layout. No overlay. Always there; can't be deleted. |
| **Simple** | Everyday drawing: a 2-column toolbox of 10 tools, File / Edit / View / Help menus, no advanced bar or power panels. |
| **Annotate** | Screenshot markup: a 1-column annotation toolbox docked left, a trimmed edit bar, the palette strip, single-key annotation tools, Rect in red, zoomed to fit. Capture Screen lands here. |

### Switching

| How | |
| --- | --- |
| **View → Workspace ▸** | Every workspace, with a check on the active one, plus Switcher, Configure, Open Folder and Reload |
| **`Ctrl+Shift+W`** | The workspace switcher: the command palette filtered to `Workspace:`. Type a few letters (`ann`) and press `Enter`. |
| **Command palette** (`Ctrl+P` / `?`) | Type `Workspace:` |
| **`[WS: name]` badge** | At the right end of the status bar; click it to open the switcher |
| `DRAW --workspace annotate shot.png` | Start in a workspace **for this run only** (not remembered) |
| `DRAW --workspaces` | List the workspaces (the remembered one is starred) and exit |

**There is always a way back.** Whatever a workspace hides:
- `Ctrl+Shift+W` and the command palette still work.
- **`F11`** shows everything the workspace hid, and a second `F11` hides it again. Outside a workspace, `F11` toggles all UI as before.
- Hidden commands keep their keys. Hiding means "not shown", not "disabled".

Things you toggle while in a workspace (opening the Color Mixer, say) last for
that session. To make them part of the workspace, save the layout (below).

### Arranging and saving a layout

Panels dock on the **left and right** edges of the window. The menu bar always
stays on top, and the status bar and color strip always stay at the bottom.

**Drag a docked panel's inner edge** (the edge facing the canvas) to resize it.
The pointer turns into a ↔ arrow over the edge. The panel snaps as you drag:

| Panel | Dragging changes |
| --- | --- |
| **Toolbox** | Button columns (1 to 8) |
| **Edit bar**, **advanced bar** | Icon columns (1 to 4) |
| **Layers** | Width in pixels (60 to 400) |

When you let go, the new size is saved:
- **In a workspace:** into that workspace. A built-in gets your own copy, which **RESET** in the configurator removes.
- **In Default:** into `DRAW.cfg` (`TOOLBOX_COLUMNS`, `EDIT_BAR_COLUMNS`, `ADV_BAR_COLUMNS`, `LAYER_PANEL_WIDTH`).

Everything in the toolbox column follows its width:
- **Toolbox buttons:** more columns are added when the buttons don't fit the window height. A 1-column toolbox of 28 tools in a short window becomes 2 columns.
- **Organizer:** its four widget stacks fit into 1 to 4 columns.
- **Drawer:** as many bin columns as fit. In a narrow toolbox, the mini palette moves under the bins, and **`Shift`+wheel** over the bins scrolls them.
- **Empty space:** when a workspace hides the organizer and drawer, the column under the buttons is drawn as panel, not as a black gap.

### Moving, stacking, tabbing and floating panels

Every panel can be arranged by hand, the way Photoshop, GIMP or Krita allow:
the toolbox, organizer, drawer, layers, edit bar, advanced bar and character
map, and the Preview, Color Mixer, Advanced Color Picker, 3D Color Space, Pen
Pressure and Browser windows.

**The handle** is what you grab:
- a panel with a title strip (a tab, a collapsed slot, a docked window): the strip;
- the layers panel: its header;
- the toolbox, organizer, drawer and bars, which have no title: hover the panel's
  **top edge** and a thin grip appears.

| Do this | And |
| --- | --- |
| **Drag a handle** | A blue preview shows where the panel will land, with a label: *new column*, *stack here*, *add as a tab* or *float here* |
| …drop on a **screen edge**, or between two columns | It gets a column of its own there |
| …drop on the **top or bottom third** of a panel | It stacks above or below that panel in the same column |
| …drop on the **middle** of a panel | It becomes a **tab** next to it |
| …drop anywhere else | It **floats** in its own window |
| **Drag the line between two stacked panels** | Moves height between them (the pointer turns into ↕) |
| **Click a tab** | Shows that panel |
| **Click the chevron**, or **double-click a title** | Collapses the slot to its title strip; its height goes to the others |
| **Click a collapsed title** | Opens it again (click one of its tabs to open on that tab) |
| **Double-click a floating panel's title** | Docks it back where it was |
| **Right-click a handle** | Move to Left Edge / Move to Right Edge, Collapse to Title / Expand, Float / Dock Back, Reset Arrangement |

The floating windows (Preview, Color Mixer, Advanced Color Picker, 3D Color
Space, Pen Pressure, Browser) keep their own title bar. **Drag the title bar
onto a dock target** to dock one; docked, its title bar is the handle, and
dropping it anywhere off the docks floats it again at its old size.

**Small windows:** when a column is too short, its lowest panels collapse to
their titles; when the window is too narrow, the outermost columns hide (the
toolbox's column last) so the canvas keeps some room. Nothing is changed in
your arrangement; widen the window and they come back.

**Reset Arrangement** (right-click any handle) returns to the classic layout,
where each panel's side follows View → Layout and `Ctrl+Shift+Click`.

Arrangements save like widths: into the active workspace (a built-in gets your
copy), or into `DRAW.cfg` in Default (`DOCK_*` keys). In a workspace file they
are the `[DOCK]` and `[FLOAT]` sections (see [Workspace files](#workspace-files)).

**Save what's on screen** from **View → Workspace ▸**:

| Item | Does |
| --- | --- |
| **Save Current Layout As…** | Asks for a name and saves a new workspace exactly as you see it: which panels show, dock sides, columns and widths. When you're in a workspace, its toolbox buttons, menus and keys come along. DRAW switches to it. |
| **Update Workspace From Layout** | Saves the current layout into the active workspace (a user copy for a built-in) |

Use the configurator only for what you can't arrange by hand: which toolbox
buttons and menus exist, the keys, and the starting options.

### The configurator

**View → Workspace → Configure Workspaces…** (also in the command palette).

- **Left:** every workspace. The active one is checked; `*` marks your own files.
- **Tabs:**

  | Tab | Edits |
  | --- | --- |
  | **Panels** | Keep / Show / Hide for each of the 16 panels and bars, Keep / Left / Right dock edges, and the layers width (0 = keep yours). *Keep* means "leave it however you have it". |
  | **Toolbox** | Columns (0 = keep yours, from `TOOLBOX_COLUMNS`), the button order (typed), and a checkbox per toolbox button |
  | **Menus** | A checkbox per menu on the bar, and hidden menu items (action ids or labels) |
  | **Bars** | Columns and button checkboxes for the edit bar and advanced bar, and organizer widget checkboxes |
  | **Keys** | The workspace's single-key overlay (`key = tool`), plus an add row |
  | **Options** | Name, description, `[START]` tool / color / zoom, and `DRAW.cfg` overrides for this workspace |
  | **Dock** | The `[DOCK]` / `[FLOAT]` arrangement line by line; **Use current** takes it from the screen, **Default** removes it |

- **Buttons:**

  | Button | Does |
  | --- | --- |
  | **NEW** | Start a blank workspace |
  | **DUPLICATE** | Copy the selected one |
  | **RENAME** | Change its display name (the file keeps its id) |
  | **DELETE** | Remove one of yours |
  | **RESET** | Drop your copy of a built-in |
  | **SAVE** | Write the file |
  | **USE** | Save and switch to it |
  | **CLOSE** | Leave; unsaved edits are discarded |

Editing a built-in and saving makes **your own copy** in your workspaces
folder. It wins over the built-in until you RESET it. Default is not editable,
since it means "no overlay": DUPLICATE it to start one of your own.

### Workspace files

Workspaces are plain `.workspace` text files, INI style:
- **Built-ins:** `ASSETS/WORKSPACES/`.
- **Yours:** the folder `DRAW --dir-workspaces` prints, also reachable from View → Workspace → Open Workspaces Folder. A file of yours with a built-in's name replaces it.
- After editing by hand, use **Reload Workspaces**.

```ini
[WORKSPACE]
NAME=Annotate
DESCRIPTION=Mark up screenshots
BASED_ON=default          ; inherit another workspace, override only what you list

[CHROME]                  ; SHOW | HIDE | KEEP
MENUBAR=SHOW
TOOLBOX=SHOW
TOOLBOX_DOCK=LEFT         ; *_DOCK = LEFT | RIGHT
LAYER_PANEL=HIDE
PALETTE_STRIP=SHOW        ; independent of STATUS_BAR
LAYER_PANEL_WIDTH=180     ; px, 60-400

[TOOLBOX]
COLUMNS=2                 ; 1-8; more are added when the buttons don't fit the height
BUTTONS=move,marquee,rect,ellipse,line,text,picker,crop   ; - = empty cell
ICON.crop=my-crop.png     ; theme TOOLBOX folder, a path, or your workspaces folder

[MENUS]
ROOTS=FILE,EDIT,VIEW,IMAGE,HELP
HIDE_ITEMS=209,NEW WINDOW ; action ids or labels

[EDIT_BAR]
BUTTONS=undo,redo,copy,paste
COLUMNS=2                 ; icon columns, 1-4

[ADVANCED_BAR]
BUTTONS=preview,grayscale
COLUMNS=1

[ORGANIZER]
WIDGETS=color-mixer,brush-size,grid

[KEYS]                    ; only while this workspace is active
r=rect
R=rect-filled             ; upper case = Shift
ctrl+s=quick-save
ctrl+enter=done

[OPTIONS]                 ; any DRAW.cfg key, this workspace only
ANGLE_SNAP_DEGREES=45

[START]                   ; applied each time you switch to it
TOOL=rect
FG=#FF2040
ZOOM=FIT                  ; or a percent, 100 = 1:1

[DOCK]                    ; the arrangement, one line per column, outermost first
LEFT.1=AUTO; toolbox | organizer | drawer
RIGHT.1=WIDTH:180; layers@2 | *preview+colormixer | !browser
                          ; AUTO or WIDTH:px; | stacks, + tabs, * active tab,
                          ; @n height share, ! collapsed to its title

[FLOAT]                   ; floating panels: x,y,w,h in window pixels
pen=640,120,220,300
```

You rarely type `[DOCK]` yourself: arrange the panels by hand and use **Update
Workspace From Layout**. A workspace without `[DOCK]` uses the classic layout,
with each side from the `*_DOCK` keys.

**Names you can use**

| Section | Names |
| --- | --- |
| `[CHROME]` panels | `MENUBAR` `TOOLBOX` `LAYER_PANEL` `EDIT_BAR` `ADVANCED_BAR` `STATUS_BAR` `PALETTE_STRIP` `PREVIEW` `COLOR_MIXER` `CHARMAP` `COLOR_SPACE_3D` `ADV_COLOR_PICKER` `PEN_PANEL` `BROWSER` `ORGANIZER` `DRAWER` |
| `[CHROME]` docks | `TOOLBOX_DOCK` `LAYER_PANEL_DOCK` `EDIT_BAR_DOCK` `ADVANCED_BAR_DOCK` `CHARMAP_DOCK` |
| `[DOCK]` / `[FLOAT]` panels | `toolbox organizer drawer layers editbar advbar charmap preview colormixer advcolorpicker colorspace3d pen browser` |
| Toolbox buttons | `move hand zoom crop marquee marquee-free marquee-poly marquee-ellipse wand picker text eraser dot brush spray fill line polygon polygon-filled save bezier rect rect-filled export-sel smart-shapes ellipse ellipse-filled open` |
| Menu roots | `FILE EDIT VIEW SELECT TOOLS BRUSH LAYER PALETTE IMAGE EFFECTS AI HELP AUDIO` |
| Edit bar | `undo redo cut copy copy-merged paste paste-in-place cut-to-layer copy-to-layer clear fill-fg fill-bg stroke flip-h flip-v scale-down scale-up rotate-cw rotate-ccw smart-guides smart-guides-snap edge-mode flip-canvas-h flip-canvas-v` |
| Advanced bar | `preview edit-bar char-map char-grid char-grid-snap tile-mode grid-cell-fill grid-brush-size fill-adjust brush-edges angle-snap grayscale ref-on ref-load ref-clear ref-adjust align-left align-center align-right align-top align-middle align-bottom distribute-h distribute-v` |
| Organizer | `color-mixer canvas-ops brush-size pattern-mode palette-ops transform-ops gradient-mode symmetry grid grid-snap color-mode` |
| `[KEYS]` / `[START] TOOL` | Any toolbox name above, plus `arrow highlight redact callout callout-reset quick-save done copy-image capture`, or a numeric action id |

`[KEYS]` takes one key (`a`, `R` = Shift+R, `1`), `ctrl+key`, `alt+key`,
`enter`, `space` or `tab`. Workspace keys win over DRAW's own while the
workspace is active. They never fire while you type text, in a dialog or menu,
or in the middle of a stroke. Menus and the command palette show the
workspace's keys, so **Ellipse Tool** reads `O` in Annotate.

---

## Screenshot capture

**File → Capture Screen…** (`Ctrl+Shift+P`, also in the command palette), or
`DRAW --capture` from a desktop shortcut.

1. DRAW hides its window, waits a moment, grabs the whole screen and comes back.
2. The **region picker** shows the frozen screen:

   | Do | To |
   | --- | --- |
   | Drag | Draw a box |
   | Drag inside the box | Move it |
   | Drag a handle | Resize it |
   | `Arrows` | Nudge 1 px (`Shift` = 10) |
   | `Enter` / double-click | Use the box (no box = whole screen) |
   | `Space` | Whole screen |
   | `Esc` / right-click | Cancel |

   A loupe and the pixel coordinates follow the pointer, and the box shows its size.
3. The region becomes a **new document** in the **Annotate** workspace. A region over 4096 px asks whether to scale it down or crop it.

The document you were working on is **not** lost. If it has a name or unsaved
changes, it is set aside in DRAW's cache (no "discard changes?" question), and
**Done** (`Ctrl+Enter`) brings it back.

### Annotate tools (keys work in the Annotate workspace)

| Key | Tool |
| --- | --- |
| `R` / `Shift+R` | Rectangle / filled rectangle |
| `O` | Ellipse |
| `L` | Line |
| `A` | **Arrow**: a line with an arrowhead that stays on for every line until you pick another tool. `S` / `E` while dragging change the caps. |
| `T` | Text |
| `H` | **Highlighter**: a yellow brush on a "Highlight" layer set to Multiply (created the first time) |
| `X` | **Redact**: drag a box; it is pixelated as soon as you let go. One undo step per box. |
| `N` / `Shift+N` | **Numbered callout**: each click places a filled circle with the next number, in the FG color. `Shift+N` restarts at 1. |
| `C` | Crop (to the selection, or interactive) |
| `V` | Move |
| `Ctrl+C` | Copy the selection, or the whole picture, to the clipboard |
| `Ctrl+S` | **Quick save** a PNG to the screenshots folder, no dialog. The first save is named `DRAW-YYYYMMDD-HHMMSS.png`; later saves overwrite it. |
| `Ctrl+Enter` | **Done**: quick save + copy to the clipboard + go back to the document and workspace you had before the capture. When DRAW was started by `DRAW --capture`, Done **closes DRAW** instead (Shottr-style) |

These tools are also under **Tools → Annotate** and in the command palette
(`Annotate:`), so they work in any workspace.

### Capture settings (Settings → General → Screen Capture)

| Setting | Key | Default |
| --- | --- | --- |
| Capture With | `CAPTURE_BACKEND` | `AUTO`: Windows built-in; macOS `screencapture`; KDE `spectacle`; GNOME `gnome-screenshot`; sway/Hyprland `grim`; X11 `maim` / `scrot` / `import` |
| Capture Command | `CAPTURE_COMMAND` | For *Custom Command*; `{file}` is the PNG DRAW reads back, e.g. `flameshot full -p {file}` |
| Capture Delay | `CAPTURE_DELAY` | 250 ms after hiding DRAW |
| Hide DRAW While Capturing | `CAPTURE_HIDE_DRAW` | on |
| Capture Workspace | `CAPTURE_WORKSPACE` | `annotate` (empty = stay) |
| — | `CAPTURE_SAVE_DIR` | Quick-save folder (empty = `Pictures/DRAW Screenshots`) |

> 💡 QB64-PE's own screen grab only works on Windows, which is why Linux and
> macOS use a capture tool. If none is installed, DRAW names the tools to
> install in the status bar. Wayland works through XWayland (verified on KDE
> Plasma 6).

### A global capture shortcut

`DRAW --capture` hands the capture to a running DRAW (no second window) or
starts DRAW if it is not running. Started that way, DRAW is **one-shot**:
- No splash screen; it goes straight to the grab.
- `Ctrl+Enter` saves, copies and closes DRAW.
- `Esc` in the region picker closes DRAW too.

So a shortcut gives you capture → mark up → `Ctrl+Enter`, and you're back where
you were. Bind it to a key:

- **KDE Plasma:** System Settings → Keyboard → Shortcuts → **Add New → Command or Script**. Command: `/path/to/DRAW.run --capture`. Then press the shortcut you want, for example `Meta+Shift+S`.
- **GNOME:** Settings → Keyboard → View and Customize Shortcuts → Custom Shortcuts → **+**. Command: `/path/to/DRAW.run --capture`.
- **Windows:** create a shortcut to `DRAW.exe`, add ` --capture` to *Target*, and set *Shortcut key* in its Properties.
- **macOS:** Shortcuts app → new shortcut → **Run Shell Script** `/path/to/DRAW --capture`. Assign a keyboard shortcut in its details.

---

## Troubleshooting

| Problem | Fix |
| --- | --- |
| A workspace hid the menu bar and I'm stuck | `Ctrl+Shift+W` → Default, or `F11` to show everything |
| My panels came back wrong after leaving a workspace | Leaving restores the state from when you *entered*; toggles made inside it are dropped by design |
| Capture says "no screen capture tool found" | Install the tool for your desktop (see the table above) or set a Custom Command |
| The capture includes DRAW's window | Raise the Capture Delay (the window may need longer to fade on your desktop) |
| A workspace key does nothing | It only works in that workspace, not while typing, and not while a mouse button is held |
| How do I leave Annotate after a capture? | `Ctrl+Enter` (Done). Or `Ctrl+Shift+W` → Default to keep the screenshot open. `Esc` belongs to the tools. |

---

➡️ Back to: [Chapter 1 — Introduction](01-introduction.md)
