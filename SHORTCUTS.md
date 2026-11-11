# DRAW — Shortcuts (Keyboard + Mouse)

> The single, canonical reference for every keyboard and mouse input in DRAW.
> This supersedes the old `CHEATSHEET.md`.
>
> **Status:** hand-authored and **reconciled against a source-level extraction** of the
> input tables (`INPUT/KEYBOARD.BM`, `INPUT/MOUSE.BM`, `INPUTS_register_all`, `CMD_init`,
> `MENUBAR`). Once the input registry is complete (Phase 1), this file becomes generated
> via `--dump-shortcuts`, so it can never drift. Full audit of registry coverage & gaps:
> `PLANS/SHORTCUTS-INVENTORY.md`. Plan: `PLANS/CUSTOMIZABLE-SHORTCUTS.md`.

---

## How to read this

**Modifier notation**

| Token | Meaning |
|-------|---------|
| **`Primary`** | The platform command modifier. **Ctrl** on Windows/Linux; **⌘ Cmd** on macOS *(planned — see note)*. Written as `Ctrl` throughout today because QB64-PE does not yet expose ⌘ on macOS, so DRAW uses Ctrl on all platforms. |
| `Ctrl` `Shift` `Alt` | Standard modifiers, held while pressing/clicking. |
| `Hold X + …` | A **hold-key chord**: hold a *non-modifier* key (e.g. `F`, `E`, `W`, `G`, `L`, `R`, `Space`) and then click/press/drag. Easy to miss — see [Hold-Key Chords](#hold-key-chords). |
| `A + B` | Press A and B together. |
| `A, B` | Press A, then B (sequence). |

> **macOS note.** QB64-PE does not detect the ⌘ Command key on macOS, so DRAW maps
> the `Primary` modifier to **Ctrl** on every platform today. `Ctrl+Click` is also
> converted to right-click by macOS — DRAW compensates (e.g. it still sets the symmetry
> center). See `MAC-USERS-README.md`. A future logical-`Primary` mapping (⌘ on macOS) is
> tracked in the customizable-shortcuts plan and depends on toolchain support.

**Mouse notation:** `L-Click` (left), `R-Click` (right), `M-Click` (middle),
`Wheel` (scroll), `Drag`, `Dbl-Click`. Region matters — the same button does different
things over the canvas vs. a panel; see [Mouse Reference](#mouse-reference).

**Context:** some bindings only fire in a context (text editing, a transform overlay,
Palette-Ops mode, over a specific panel). Context is noted in the row or section.

---

## Table of contents

1. [Global / Application](#global--application)
2. [File](#file)
3. [Edit · History · Clipboard](#edit--history--clipboard)
4. [View · UI · Zoom · Pan](#view--ui--zoom--pan)
5. [Tools](#tools)
6. [Drawing Modifiers](#drawing-modifiers)
7. [Selection · Marquee · Magic Wand](#selection--marquee--magic-wand)
8. [Layers · Groups · Symbols](#layers--groups--symbols)
9. [Color · Palette · Palette-Ops](#color--palette--palette-ops)
10. [Grid · Symmetry · Smart Guides](#grid--symmetry--smart-guides)
11. [Text · Character Map · Fonts](#text--character-map--fonts)
12. [Brush · Custom Brush · Spray](#brush--custom-brush--spray)
13. [Transform · Move](#transform--move)
14. [Image · Adjustments · Effects · CRT · AA](#image--adjustments--effects--crt--aa)
15. [Panels · Docking](#panels--docking) · [Workspaces · Capture · Annotate](#workspaces--capture--annotate)
16. [Animation](#animation)
17. [Audio · Music](#audio--music)
18. [Drag & Drop · Image Import](#drag--drop--image-import)
19. [Menu Bar · Command Palette](#menu-bar--command-palette)
20. [Mouse Reference](#mouse-reference)
21. [Hold-Key Chords](#hold-key-chords)
22. [Command Line](#command-line)
23. [Appendix: internal behaviors](#appendix-internal-behaviors)

---

## Global / Application

| Keys | Action |
|------|--------|
| `?` | Open/close the Command Palette (searchable command list) |
| `Ctrl+,` | Open Settings dialog |
| `Alt` (tap & release) | Open/close the menu bar |
| `Alt+X` | Exit DRAW (prompts if unsaved) |
| `Ctrl+Z` | Undo |
| `Ctrl+Y` | Redo |
| `Ctrl+Alt+N` | New Window — another isolated DRAW instance *(Settings → General → Allow Multiple Instances)* |
| `Ctrl+Alt+K` | Cancel the running AI generation (aborts the batch) *(AI enabled)* |

---

## File

### Documents & images
| Keys | Action |
|------|--------|
| `Ctrl+N` | New canvas (prompts to save unsaved changes) |
| `Ctrl+O` | Open / import image (PNG, BMP, JPG, GIF) |
| `Alt+O` | Open DRAW project (`.draw`) |
| `Ctrl+S` | Save (silent if previously saved; dialog if new). A `.png` saves back into itself with the layers inside; a GIF/BMP/JPG… writes a `.draw` beside it, or overwrites itself flattened when Settings → General → *Save .draw Beside Images* is off |
| `Ctrl+Shift+S` | Save As (always prompts) |
| `Ctrl+Alt+Shift+S` | Flatten & Save — write the merged image back to the document's own file, in its own format, no `.draw` (asks for a name only when there is no image file to write) |
| `Ctrl+Alt+S` | Export selection as cropped image |
| `Ctrl+Shift+Q` | QB64 Code Export — re-export to last project path (no dialog) |
| `Ctrl+Shift+E` | Export Again — repeat the last File → Export As (same format + file, no dialog) |
| `Ctrl+Shift+P` | Capture Screen — grab the screen, pick a region, annotate it (also `DRAW --capture`) |
| `Alt+1` … `Alt+9` | Open recent file #1–#9 |
| `Alt+0` | Open recent file #10 |

### Reference image
| Keys | Action |
|------|--------|
| `Ctrl+R` | Toggle reference image on/off (loads one if none) |
| `Ctrl+Shift+Wheel` | Adjust reference-image opacity (5–100%) |

**Reposition mode** (View → Reposition Reference): `Drag` move · `Wheel` scale · `Arrows` nudge 1px · `Enter` confirm · `Esc` cancel.

> `.draw` files are PNG images with an embedded `drAw` chunk preserving layers, blend
> modes, palette, tool state, reference image, and more. Standard image saves flatten
> visible layers. Full menu list: File menu (New from Template, Open Aseprite/PSD, Import
> ANSI, Export As, Export ANSI/Layer/Brush, Extract From/To Grid).

---

## Edit · History · Clipboard

| Keys | Action |
|------|--------|
| `Ctrl+Z` / `Ctrl+Y` | Undo / Redo (`Ctrl+Shift+Z` also redoes) |
| `Ctrl+C` | Copy selection |
| `Ctrl+Shift+C` | Copy merged (all visible layers) |
| `Ctrl+X` | Cut selection (copy + clear with BG) |
| `Ctrl+V` | Paste centered on the canvas (floats as a Move selection) |
| `Ctrl+Shift+V` | Paste from OS clipboard |
| `Ctrl+Alt+V` | Paste in Place (where it was copied from; in the lightbox, the same spot in the current frame) |
| `Ctrl+E` | Clear/erase selection (BG color, or transparent for wand selections) |
| `Ctrl+Alt+C` | Copy to new layer |
| `Ctrl+Alt+X` | Cut to new layer |
| `Delete` | Clear (selection, or whole layer if none) |
| `Backspace` | Fill with foreground color |
| `Shift+Backspace` | Fill with background color |

**Paste workflow:** select (`M`/`W`) → `Ctrl+C`/`Ctrl+X` → `Ctrl+V` (floats centered on the canvas, auto-engages Move) → drag to reposition (`Alt+drag` stamps copies) → `Enter` apply / `Esc` cancel. (`Ctrl+Z` removes a paste.)

---

## View · UI · Zoom · Pan

### UI toggles
| Keys | Action |
|------|--------|
| `Tab` | Toggle toolbar |
| `Ctrl+L` | Toggle layer panel |
| `F4` | Toggle preview window |
| `F5` | Toggle edit bar |
| `Shift+F5` | Toggle advanced bar |
| `Ctrl+Shift+F5` | Reload theme (hot-reload colors + icons) |
| `Ctrl+M` | Toggle Character Map panel |
| `Ctrl+Shift+M` | Toggle Advanced Color Picker panel |
| — | Toggle 3D Color Space panel (View menu / command palette) |
| `F10` | Toggle status bar |
| `F11` | Toggle ALL UI (also hides/shows the Advanced Color Picker and 3D Color Space panels). Inside a workspace that hides things: show what it hid / hide it again |
| `Ctrl+Shift+W` | Workspace switcher (command palette filtered to `Workspace:`) |
| `L-Drag` a docked panel's inner edge | Resize it: toolbox columns (1–8), edit/advanced bar columns (1–4), layers width (60–400 px). Saved to the active workspace, or `DRAW.cfg` in Default. **View → Workspace → Save Current Layout As…** saves the whole arrangement as a workspace |
| `Alt+Enter` | Toggle fullscreen (also **View → Fullscreen** / command palette; live, no restart, persists across launches) |
| `Ctrl+F11` | Toggle menu bar |
| `Ctrl+Shift+Up` | Hide/show menu bar (alt binding) |
| `Ctrl+Shift+Down` | Hide/show status bar + color strip |
| `Ctrl+Shift+Left` | Hide/show left-side UI (edit bar, layers) |
| `Ctrl+Shift+L` | Lock / unlock the layout (View → Lock Layout): panels and floating windows can't be dragged, re-docked or resized — for drawing with a shaky tablet pen |
| `Ctrl+Shift+Right` | Hide/show right-side UI (toolbar, organizer, drawer) |
| `#` | Toggle canvas border |
| `Shift` (hold) | Show crosshair while held |
| `Ctrl+Alt+Shift+G` | Toggle grayscale preview |
| `Ctrl+Alt+O` | Toggle CRT effect overlay |

### Zoom & pan
| Keys / Mouse | Action |
|--------------|--------|
| `Ctrl+0` | Reset zoom to 100% and center |
| `Ctrl+=` | Zoom in (1→2→3→5→7.5→10→15→20→25→50→100→200→300…800%; below 25% only for canvases big enough to stay 100px+ on screen) |
| `Ctrl+-` | Zoom out |
| `Wheel` | Zoom in/out at cursor |
| `Hold Z + 1…9` | Zoom preset 100 / 200 / 300 / 400 / 500 / 600 / 700 / 800 / 1600% |
| `Hold Z + 0` | Zoom 3200% |
| `Shift+Wheel` | Vertical pan |
| `Shift+Arrows` (no selection) | Pan viewport |
| `M-Click + Drag` | Pan canvas |
| `Space + L-Drag` | Pan canvas |
| `Dbl M-Click` | Reset zoom & pan |

**Zoom snap levels:** 25, 50, 100, 200, 300, 400, 500, 600, 700, 800%.
**Display Scale (window size):** Settings (`Ctrl+,`) → Display → UI Scale (`0`=auto, `1`–`8`), or the command palette (`?`): Display Scale Up / Down / Reset.

---

## Tools

Press a letter to select a tool. `Shift+letter` picks the filled/variant form.

| Key | Tool | Notes |
|-----|------|-------|
| `B` | Brush | Freehand painting (drag) |
| `D` | Dot | Single-pixel stamp (click) |
| `L` | Line | Straight lines |
| `R` / `Shift+R` | Rectangle / Filled | Outline / filled |
| `C` / `Shift+C` | Ellipse / Filled | Outline / filled |
| `P` / `Shift+P` | Polygon / Filled | Outline / filled |
| `Q` | Bezier | Cubic curves (drop anchors, drag handles) |
| `F` | Fill | Flood fill (`Shift` samples merged canvas) |
| `K` | Spray | Spray paint |
| `E` / `Hold E` | Eraser / temp Eraser | Tap = permanent; hold = while held |
| `I` | Picker | Eyedropper with loupe |
| `M` | Marquee | Rectangular selection |
| `W` | Magic Wand | Contiguous same-color select |
| `V` | Move | Move/transform selection |
| `Z` | Zoom | Click in / `Alt`+click out / drag region |
| `T` / `Shift+T` / `Ctrl+T` | Text (VGA / Tiny5 / custom font) | |
| `?` | Command Palette | |

> **Smart Shapes** and **3D Text** are on the toolbar's Smart Shapes flyout (long-press / right-click): Polygon, Pie/Donut, Rounded Rect, Tab, Pill, Pac-Man, 3D Dice, Bevel Rect, Arrow, 3D Text.

**Left vs right button:** L-Click draws with FG, R-Click draws with BG (Brush, Dot, Line, Rect, Ellipse, Fill, Spray). Exceptions: Picker R-Click picks BG; Polygon R-Click closes shape; Brush/Dot `Shift`+R-Click draws a connecting line from the last point.

---

## Drawing Modifiers

### Shape constraints (while dragging)
| Tool | Modifier | Effect |
|------|----------|--------|
| Line / Rect / Ellipse | `Shift` | Constrain to H/V |
| Brush / Spray | `Shift` | Constrain to H/V axis |
| Line / Polygon | `Ctrl+Shift` | Angle-snap + bypass grid snap |
| Rectangle | `Shift` | Perfect square |
| Rectangle | `Ctrl` | Draw from center |
| Ellipse | `Shift` | Perfect circle |
| Ellipse | `Ctrl` | Draw from center |
| Rectangle / Ellipse select | `Ctrl` | Select from center (with `Shift` = add, `Alt` = subtract) |

### Subdivisions (while dragging a Rect / Ellipse / Line)
| Key | Rectangle | Ellipse | Line |
|-----|-----------|---------|------|
| `→` / `←` | +/− column divider | +/− spoke | +/− radial spoke |
| `↓` / `↑` | +/− row divider | +/− concentric ring | — |

*(Rect up to 32/axis; Ellipse up to 16 spokes/rings; Line up to 16 spokes. Counts reset each drag.)*

### Angle snapping
`Ctrl+Shift` (hold while dragging/clicking) snaps to angle increments **and** bypasses grid snap. Increment set by `ANGLE_SNAP_DEGREES` in `DRAW.cfg` (default 45° → 8 directions; also 30/15/90°). Applies to Line, Polygon, Polygon-Filled, and Brush/Dot `Shift`+R-Click connecting lines.

### Line end caps (while dragging Line)
`s` cycle start cap · `e` cycle end cap (none → arrow → diamond → circle → square → …).

### Smart Shapes (while dragging)
`↑`/`↓` primary parameter · `←`/`→` secondary parameter · `Shift` constrain aspect · `Space` reposition without resizing · `Wheel` adjust primary.
**3D Dice/Text lighting:** `W`/`S` tilt · `A`/`D` (or `Q`/`E`) orbit · `=`/`-` push light · `Hold L + 0–9` intensity preset. **Dice type:** `4`/`6`/`8`/`0`/`1`/`2`/`3` = D4/D6/D8/D10/D12/D20/D30; L-drag wireframe (FG), R-drag solid (BG faces + FG wireframe).

---

## Selection · Marquee · Magic Wand

### Selection tools
| Key | Tool |
|-----|------|
| `M` | Rectangle marquee |
| `W` | Magic wand (contiguous same-color) |
| — | Freehand / Polygon / Ellipse select (toolbar or command palette) |

### Marquee mouse
`L-Drag` create · `Shift+Drag` add (union) · `Alt+Drag` subtract · drag corner/edge handle resize · drag inside move.

### Magic wand mouse
`L-Click` select contiguous · `Shift+Click` add · `Alt+Click` subtract · `Hold E + Click` flood-erase to transparent · `Hold F + Click` flood-fill FG · `Hold W + Click` select from merged canvas.

### Selection keyboard
| Keys | Action |
|------|--------|
| `Ctrl+A` | Select all |
| `Ctrl+Shift+I` | Invert selection |
| `Ctrl+H` | Hide/show marching ants (selection stays active) |
| `Hold M + =` / `Hold M + -` | Expand / contract selection 1px |
| `Hold M + Shift+=` / `Hold M + Shift+-` | Expand / contract selection (large step) |
| `Ctrl+D` / `Esc` | Deselect (from any tool) |
| `Arrows` | Move selection box 1px |
| `Shift+Arrows` | Move selection box 10px |
| `Ctrl+Arrows` | Move content 1px (lifts/floats, Photoshop-style) |
| `Ctrl+Shift+Arrows` | Move content N px (`NUDGE_N`) |
| `Ctrl+Alt+Arrows` | Clone content 1px (keeps original) |
| `Ctrl+Alt+Shift+Arrows` | Clone content N px |

**As a clipping mask:** an active selection clips all drawing tools to inside it. Grid snap (`;`) applies to marquee drags; `Ctrl+Shift` angle-snaps + bypasses grid for the start. Stroke Selection lives in Edit menu / command palette.

---

## Layers · Groups · Symbols

### Layer keyboard
| Keys | Action |
|------|--------|
| `Ctrl+L` | Toggle layer panel |
| `Ctrl+Shift+N` | New layer *(Ctrl+N is New Canvas)* |
| `Ctrl+Shift+D` | Duplicate layer |
| `Ctrl+Shift+R` | Rename layer |
| `Ctrl+Shift+Delete` | Delete layer |
| `Ctrl+PgUp` / `Ctrl+PgDn` | Move layer up / down |
| `Ctrl+Shift+]` / `Ctrl+Shift+[` | Arrange to top / bottom |
| `Ctrl+Alt+E` | Merge down |
| `Ctrl+Alt+Shift+E` | Merge all visible |
| `Ctrl+G` | New empty group |
| `Ctrl+Shift+G` | Group from selection (2+ layers) |
| `Ctrl+Shift+U` | Ungroup |
| `Ctrl+Alt+Shift+C` | Copy Layer to clipboard (for another DRAW window) |
| `Ctrl+Alt+Shift+V` | Paste Layer as new layer |

### Layer panel mouse
`L-Click` select · `Ctrl/Shift+L-Click` add/remove from multi-selection · `R-Click` select+rename · `Shift+R-Click` cycle blend mode · `Alt+L-Click eye` solo · `Click eye` toggle visibility · `Drag across eyes` swipe show/hide · `Click lock` opacity lock · `Click/Drag opacity bar` adjust · `Drag row` reorder · `Wheel` scroll list · `Wheel on opacity bar` adjust · `Esc` cancel drag · `Click triangle` collapse/expand group.

> 19 blend modes (Shift+R-Click a row to cycle). Groups have their own opacity/blend
> (Pass-Through default) and can nest. Symbol layers link a parent to children (Layer
> menu: Convert to Symbol, Add Instance, Sync, Rasterize, Detach, Select Parent).

---

## Color · Palette · Palette-Ops

### Color keyboard
| Keys | Action |
|------|--------|
| `X` | Swap FG/BG (including transparency state) |
| `Shift+Delete` | Set BG to transparent |
| `Ctrl+Alt+R` | Load a random palette |
| `F1` / `F2` / `F3` | Drawer Brush / Gradient / Pattern mode |
| `Shift+Tab` | Color cycling on/off (Palette → Cycle Colors; `[CYC]` in the status bar) |

### Palette strip mouse
`L-Click swatch` set FG · `R-Click swatch` set BG (the FG/BG frames only mark a swatch that *is* the current color) · `Wheel` scroll · `Shift+Wheel` fast scroll (32) · `Click ◄/►` scroll · `Click palette name` switch-palette dropdown · letter keys (in picker) jump to palette.

### Status-bar swatches
`Click FG swatch` / `Click BG swatch` → open color picker.

### Palette-Ops mode (toggle via organizer button)
A swatch *is* its pixels: changing a swatch recolors every pixel of that color.

`L-Click swatch` select it (yellow frame) and make it FG. While selected, **any** color change edits the swatch and its pixels live: the Color Mixer, Advanced Color Picker, 3D Color Space, picker or hex input. Each edit is one `Ctrl+Z`. The matching pixels are also wand-selected after 0.5s.

`L-Click selected swatch` / `L-Click blank strip area` deselect (the blank area also clears marks) · `Shift+L-Click swatch` ramp between the selected swatch and this one (Gradient Blend space; pixels follow) · `Dbl L-Click` change color in a dialog · `Drag` move swatch (a **marked** swatch moves all marked ones) · `R-Click` / `R-Drag` mark/unmark · `M-Click` delete color (remap to nearest; on a marked swatch, all marked) · `M-Drag` delete range · `Shift+M-Click` insert current FG color · `Esc` / `R-Click` organizer button exit. Undo/redo and opening the color panels keep Palette-Ops on.

**Color cycling ranges** (Palette-Ops + `Ctrl`; see manual ch. 3 *Color Cycling*): `Ctrl+L-Drag` across swatches new cycle range (white preview band) · `Ctrl+L-Click` range swatch direction Forward → Reverse → Ping-pong · `Ctrl+R-Click` pause/resume range · `Ctrl+M-Click` delete range · `Ctrl+Wheel` speed (table, wheel up = faster) · `Ctrl+Shift+Wheel` fine speed (5%). Hovering a range swatch shows it in the status bar (`CYC 2: 32-47 REV 8.0/s`). Range bands on the swatches: solid = forward, dash-dot = reverse, dashed = ping-pong, dim = paused, red checker = duplicate color (can't cycle).

---

## Grid · Symmetry · Smart Guides

### Grid
| Keys | Action |
|------|--------|
| `'` | Toggle grid |
| `Shift+'` | Toggle pixel grid (400%+) |
| `;` | Toggle snap-to-grid |
| `Ctrl+'` | Cycle geometry (Square → Diagonal → Isometric → Hex) |
| `.` / `,` | Grid size +1 / −1 (uniform, 2–50px) |
| `/` | Toggle alignment (Corner ↔ Center) |
| `Ctrl+Shift+/` | Set grid size from brush; enable center align + snap |
| `Hold G + →/←` | Grid **width** +1 / −1 |
| `Hold G + ↓/↑` | Grid **height** +1 / −1 |
| `Hold G + R` | Reset grid offset (0,0) |
| `Hold G + Shift+R` | Reset grid size to theme default |
| `Hold G + Ctrl+R` | Reset offset + size |
| `Ctrl+Shift` (hold) | Temporarily bypass grid snap |

*Cell Fill (View → Grid Cell Fill): Fill tool fills grid cells per geometry.*

### Symmetry
| Keys | Action |
|------|--------|
| `F7` | Cycle mode (Off → Vertical → Cross → Asterisk) |
| `F8` | Fill-Adjustment mode (if custom brush/paint mode) — otherwise turn symmetry off |
| `Ctrl+L-Click` | Reposition symmetry center |

*Status: `SYM:0/1/2/3`. Works with all drawing tools.*

### Fill Adjustment mode (F8 with custom brush/paint mode)
`Drag` reposition tile origin · `Wheel` scale uniform · corner handle scale XY · arm handles scale X/Y · rotation handle rotate · `Enter`/L-Click-outside apply · `Esc`/R-Click cancel.

### Smart Guides
View → Smart Guides (visibility) · Edit → Snap Smart Guides (snap).

---

## Text · Character Map · Fonts

### Text editing
| Keys | Action |
|------|--------|
| `T` / `Shift+T` / `Ctrl+T` | Text: VGA / Tiny5 / custom font |
| Type | Enter text |
| `Enter` | New line |
| `Backspace` / `Delete` | Delete before / after cursor |
| `Esc` | Apply/finish (commit text layer) |
| `←`/`→` `↑`/`↓` | Move cursor char / line |
| `Home` / `End` | Start / end of line |
| `Ctrl+←`/`→` | Move by word |
| `Ctrl+Home` / `Ctrl+End` | Start / end of text |
| `Shift+…` (arrows/Home/End) | Extend selection |
| `Ctrl+Shift+←`/`→` | Select word |
| `Ctrl+A` | Select all text |
| `Dbl/Triple/Quad-Click` | Select word / line / all |
| `Ctrl+Z` / `Ctrl+Y` | Text-local undo / redo (within edit session, 128 states) |

### Per-character formatting (while editing)
`Ctrl+B` bold · `Ctrl+I` italic · `Ctrl+U` underline · `Ctrl+Shift+X` strikethrough ·
`Ctrl+Shift+.` / `Ctrl+Shift+,` size +/− · `Alt+→` / `Alt+←` kerning +/− · `Ctrl+Alt+↑` / `Ctrl+Alt+↓` baseline raise/lower.
Outside an active edit, `Alt+U` picks up the style at the cursor and `Alt+V` pastes it.

### Character Map (`Ctrl+M`)
`L-Click cell` select glyph · CHAR button toggles Character Mode · `Alt+U` pick FG+BG from glyph under cursor. In Character Mode: arrows move a *virtual cursor*; F1–F12 insert ANSI block chars (░▒▓█▀▄▌▐■·); DOT/RECT tools fill cells with the glyph.

### Fonts
Middle-click the Text toolbar icon → load TTF/OTF. **TheDraw (TDF)** fonts: `[TDF]` text-bar button / Tools → TheDraw Font / palette `tdf`. Browser keys: type filter · `Tab` cycle focus · `↑/↓` move · `PgUp/PgDn` page · `Home/End` first/last · `F2` favorite · `Enter` use · `Esc` cancel. **CBF** (color bitmap) fonts chosen from the font dropdown.

---

## Brush · Custom Brush · Spray

### Brush
| Keys | Action |
|------|--------|
| `[` / `]` | Brush size − / + (fine, ±1) |
| Pen pressure | With a drawing tablet, pressure sets Brush / Eraser size and (optionally) opacity, and the mix brush's paint. **View → Pen Pressure** panel: live meter, per-target lightest-touch sliders, curve |
| `Ctrl+Wheel` | Brush size presets (1/3/5/7) |
| `` ` `` | Toggle brush preview / cursor visibility |
| `\` | Toggle brush shape / cursor shape |
| `F6` | Toggle pixel-perfect mode |

### Custom brush
| Keys | Action |
|------|--------|
| `Ctrl+B` | Capture selection as custom brush / clear when brush active |
| `F9` | Toggle recolor mode (paint brush in FG) |
| `Shift+O` | Apply 1px outline in BG (disables recolor) |
| `F12` | Export custom brush as PNG |
| `Home` / `End` | Flip custom brush H / V |
| `PgUp` / `PgDn` | Scale custom brush up / down |
| `/` | Reset custom brush scale |

### Spray (`K`)
L-Click spray FG · R-Click spray BG · `Shift` constrain axis · brush size sets nozzle + radius (2× per level). Works with symmetry, selection clipping, and custom brushes.

---

## Transform · Move

### Universal transforms (current layer / selection / float — no tool needed)
| Keys | Action |
|------|--------|
| `H` / `Home` | Flip horizontal |
| `Ctrl+Shift+H` / `End` | Flip vertical |
| `>` / `<` | Rotate 90° CW / CCW |
| `PgUp` / `PgDn` | Scale 2× / scale 50% |
| `Ctrl+Home` / `Ctrl+End` | Scale 2× horizontal / vertical (per-axis pixel-double) |

> When a **custom brush** is active, `Home`/`End`/`PgUp`/`PgDn`/`>`/`<`/`/` transform the
> *brush* instead (see [Custom Brush](#brush--custom-brush--spray)).

### Move tool (`V`)
`Arrows` move 1px · `Shift+Arrows` 10px · `Ctrl+Arrows` scale 1px · `Ctrl+Shift+Arrows` scale 10px · `Alt` (hold) clone mode · `Shift+Click` select topmost layer at cursor & begin move · `Enter` apply · `Esc` cancel.

### Edit → Transform overlay (Scale / Rotate / Shear / Distort / Perspective)
`Drag handle` apply mode · `Enter` apply & restore previous tool · `Esc` cancel. `Shift`: Scale=lock aspect · Rotate=snap 15° · Perspective=mirror opposite corner.

---

## Image · Adjustments · Effects · CRT · AA

- **Image menu:** Resize Canvas, Resize Image with Content (scales pixels too), Crop, Flip Canvas H/V, and adjustments (Brightness/Contrast, Hue/Saturation, Levels, Color Balance, Blur, Sharpen, Invert, Desaturate, Posterize, Pixelate). All adjustment dialogs: sliders + `Wheel` on slider fine-tune · `OK`/`Enter` apply · `Cancel`/`Esc` revert.
- **Effects menu** (Shape / Texture / Render engines): each dialog has a split ORIG/ADJ loupe, wheel-sliders, an angle dial, seed, MIX slider, Reset. Effects can clip to selection or run selection-as-shape.
- **Last-effect shortcuts:** `Ctrl+F` re-apply last effect · `Ctrl+Alt+F` recall last effect (re-open its dialog) · `Ctrl+Shift+F` blend/fade last effect (blend modes + isolate-to-new-layer).
- **CRT effect:** `Ctrl+Alt+O` toggle · View → CRT Effect Settings…
- **Anti-Aliasing** (experimental, off by default): Edit → Anti-Aliasing toggle (status shows **AA**); Edit Bar Edge-Mode button (L-Click toggle, R-Click switch Pixel-Perfect ⟷ AA). Config `ANTIALIAS`.
- **Crop tool:** `Click+Drag` region · handles resize (drag outward past an edge to *grow* the canvas) · `Arrows` nudge · `Ctrl+Arrows` resize · `Enter` apply · `Esc` cancel.

---

## Panels · Docking

### Docking
`Ctrl+Shift+Click` a panel → toggle dock side (left ↔ right). Panels: Toolbox, Layer Panel, Edit Bar, Advanced Bar, Character Map (View → Layout menu).

**Arranging panels** — the *handle* is a panel's title strip, the layers header, or the thin grip that appears when you hover the top edge of the toolbox, organizer, drawer or a bar.

| Mouse | Action |
|------|--------|
| `L-Drag` a handle | Move the panel: drop on a screen edge / between columns = new column · top or bottom third of a panel = stack above/below · middle = add as a tab · anywhere else = float |
| `L-Drag` the line between two stacked panels | Move height between them |
| `L-Click` a tab | Show that panel |
| `L-Drag` a tab strip past its tabs | Move the whole tab group |
| `L-Drag` the Browser's title to the top / bottom of the canvas | Dock it in a band along the top / bottom (drag the band's edge to resize it) |
| `L-Click` the chevron / `Dbl-Click` a title strip | Collapse the slot to its title / expand it |
| `L-Click` a collapsed title | Open it (on the tab you clicked) |
| `R-Click` a handle | Move to Left / Right Edge · Collapse to Title / Expand · Float / Dock Back · Reset Arrangement · Customize Buttons… (toolbox / bars) · Scale: Auto / 1x–4x (Animation, Color Mixer, Advanced Color Picker, 3D Color Space, Pen Pressure, Swatches: the panel's own size; Auto = the UI Scale; also Settings → Panels → Panel Scale) |
| `L-Drag` a floating window's title bar onto a dock target | Dock it (Preview, Color Mixer, Advanced Color Picker, 3D Color Space, Pen Pressure, Swatches, Browser) |
| `Dbl-Click` a floating panel's title | Dock it back where it was |
| `L-Drag` a floating panel's right / bottom edge or corner | Resize it (a floating bar adds icon columns as it widens). Floating bars have a slim grip strip instead of a title |
| `R-Click` (while dragging) | Cancel the move |

Arrangements save to the active workspace (or `DRAW.cfg` in Default); a workspace keeps them in `[DOCK]` / `[FLOAT]`.

### Customize Toolbars (View → Customize Toolbars…)
Edits the toolbox, edit bar and advanced bar: any tool or command, in any order, on any of them. Changes save into the active workspace (Default asks for a name and makes one).

| Input | Action |
| --- | --- |
| `L-Click` a tab | Edit that panel (Toolbox / Edit Bar / Advanced Bar) |
| Type in **Search…** | Filter the Available list (`Esc` clears, `Enter` ends) |
| `Dbl-Click` an Available row / **→** | Add it after the selected button |
| **←** / `Delete` | Remove the selected button |
| **↑ / ↓** | Move the selected button |
| **+ DIV** / **+ GAP** | Insert a divider (new row) / an empty cell |
| **RESET** · **COLUMNS − / +** | The panel's default buttons · its columns |
| `L-Drag` a row in the right list / onto Available | Reorder it / remove it |
| `L-Drag` an Available row onto the right list or a panel | Add it there |
| `Wheel` over a list | Scroll it |
| **While the window is open:** `L-Click` a toolbox / bar button | Select it (nothing runs) |
| **While the window is open:** `L-Drag` a toolbox / bar button | Move it (same panel or another); drop it off every panel to remove it |

### Preview window (`F4`)
Follow / Floating-Image modes (View → Preview Window). `Alt+Click` pick FG (CP enabled) · `Alt+R-Click` pick BG · `Wheel` zoom preview · drag title move · drag handle resize.

### Drawer panel
`F1/F2/F3` Brush/Gradient/Pattern mode · `L-Click slot` select · `Shift+L-Click` store current · `R-Click` context menu · `M-Click` cycle mode · `Shift+M-Click` clear slot · `Shift+R-Click` import into slot · `L/R-Click mini palette` set FG/BG (when it's on: Settings → Panels → Drawer) · `Wheel` over the bins switches `.dset` sets · `Shift+Wheel` over the bins scrolls them when a narrow drawer can't show every row · `Ctrl+Wheel` over the bins zooms them (up = fewer, bigger bins; down = more, smaller; R-Click → Bin Size: Auto resets).

### Color Mixer / Advanced Color Picker / Image Browser
View → Color Mixer (RGB/HSV sliders, hex). **View → Advanced Color Picker** (`Ctrl+Shift+M`, or middle-click the Color Mixer toolbox button): Krita-style hue ring + SV triangle, shade selector rows, and a color-history strip. `L-Click`/drag the wheel/triangle/shades/history → set FG (`X` swaps FG/BG). Drag the small ring markers to resize the hue-neighbors range. `R-Click` the history strip → Create Palette / Clear History. All options in Settings → Panels → Advanced Color Picker. **View → 3D Color Space**: the sRGB gamut as a 3D solid in OKLab / CIELAB / XYZ / RGB — `L-Click`/drag the solid → set FG · `R-Drag`/`M-Drag` (or `L-Drag` off the solid) spin · `Wheel` zoom · SOLID/CLOUD · SLICE + slider cut at a lightness. **Palette → Generate OKLCh Ramp from FG** makes an even dark→light palette (Settings → Panels → Color Blending + Ramps). **Brush → Mix Colors (Pigment)** makes the brush pick up and smear the colors it crosses, mixing like wet paint (blue through yellow = green; Smudge / Smudge Length / Smudge Radius in Settings); **Palette → Generate Pigment Mix FG > BG** makes a paint-mixed FG→BG palette. View → Browser: `Click` select · `Ctrl+Click` multi-select · `Dbl-Click` load · drag file → canvas/drawer/layer-panel · `Wheel` scroll · `Dbl-Click title` maximize. **Floating windows** (Color Mixer, Advanced Color Picker, 3D Color Space, Pen Pressure, Swatches, Image Browser, Preview, Customize Toolbars): drag a title bar to move. `Click` any floating window or floating panel to bring it to the front. With View → Snap Panel Edges on (default), edges snap to other floating windows and to the surrounding chrome and windows don't overlap; hold one still against a snap ~1.5 s to drop it on top. Off, they move freely.

### Swatches panel (View → Swatches)
A grid of swatches from a swatch set, beside the palette strip (which stays the document palette). `L-Click` a swatch → select it + FG · `Shift+L-Click` → select the range · `Ctrl+L-Click` → toggle it in the selection · `L-Drag` from an empty place → box select (`Ctrl+L-Drag` adds; dragging past the grid scrolls) · `Ctrl+A` / `Esc` with the pointer on the panel → select all / none · `R-Click` → BG · `Wheel` scroll · drag the scroll bar · `L-Drag` the corner grip (floating) → resize. `Click` the set name → the set list (Document Palette, My Swatches, the shipped swatch sets, every palette) · `Click` the gear → Columns (SET / FIT / 8–32), Cell, Gap, Stretch to width, Square cells, Cell borders, Black filler = empty cells, Load Swatches…, Open My Swatches Folder · `Esc` closes either list. Load Swatches… reads `.aco` `.gpl` `.act` `.pal` `.hex` `.txt` and saves a `.gpl` copy in My Swatches (the original is never written). Actions: 2600 toggle · 2601 Load Swatches… · 2602 Open My Swatches Folder.

---

## Animation

A sheet with frames (a `.draw` or PNG carrying the frame layout, or a picture you add a
frame to) is a **sprite sheet**: frame N is the Nth cell in reading order and every
tool works on the sheet as usual. The numpad keys need a numpad; with Num Lock on or
off they are frame keys, not digits, only while the sheet has frames (on a plain
picture only `Num +` is). The `Alt` keys are for keyboards without a numpad.

**File → New Animation...** starts one from scratch: type the frame size and how many frames -
`32x32 8`, add `@12` for 12 FPS - and you get a new document whose canvas is a sheet of that
many blank frames, as square as it fits. On a plain picture the ANIM menu greys out everything
that needs frames; only the ways in stay: Animation Panel, Add Frame, Add Blank Frame, Detect
Frames, Create Frames from Grid, Import PNG Sequence. The frame settings (Frame Grid, Preview
Shows Frame, Onion Skin Tint, Clip Strokes...) show unchecked there and come back once there are frames.

| Key | Action |
|-----|--------|
| `Num 1` / `Alt+Home` | First frame |
| `Num 4` / `Alt+,` | Previous frame (wraps to the last) |
| `Num 5` / `Alt+.` | Next frame (wraps to the first) |
| `Num 9` / `Alt+End` | Last frame |
| `Num Enter` / `Alt+/` | Play / stop (FPS, holds, loop mode); drawing is blocked while playing |
| `Num +` | Add a frame: a copy of the last one (on a plain picture: the picture becomes frame 1, frame 2 goes beside it) |
| `Shift+Num +` | Add a blank frame |
| `Num 0` | Lightbox on / off (below) |
| `Num *` | Lightbox panes: 3 → 5 → 7 |
| `Num 8` | X-sheet on / off: the lightbox's top band shows frames × layers (opens the lightbox from sheet view) |
| `Num /` | Onion skin on / off (in the lightbox) |
| `Num .` | Full-screen Preview: the frames playing over the whole window. Inside: `Space` / `Num Enter` play · pause, `←` / `→` step, `Home` / `End` first / last, click / drag the seek bar to scrub, `Wheel` zoom, double `M-Click` 100%, `M-Drag` pan, `Esc` / `Num .` close on the frame shown |
| `Ctrl+Z` / `Ctrl+Y` | Every frame operation, frame size / gutter / margin and FPS / hold change is one undo step |

Main-row digits keep setting opacity; `Alt+Home` / `Alt+End` no longer flip.

**ANIM menu:** Animation Panel · First / Previous / Next / Last Frame · Play · Add Frame ·
Add Blank Frame · Insert Frame Before / After · Duplicate Frame · Delete Frame · Move Frame
Earlier / Later · Reverse Frames · Copy Frames · Cut Frames · Paste Frames as New · Paste
Frames Over · Replace FG Color with BG in Frames · Frame Grid · Preview Shows Frame · Lightbox · Lightbox
Panes 3 / 5 / 7 · Onion Skin · Onion Skin Red / Blue Tint · Clip Strokes to the Frame in the Lightbox · Clip Strokes to the Frame in
Sheet View · Reference Layer (the current layer: shown, left out of every export; `[R]` in the
layers panel) · Layer Same on Every Frame (the current layer's drawing on every frame - draw in
any frame and it lands on all of them; `[=]`) · Link Cells (the current layer: with frames selected, their cells all show the first selected frame's drawing; with one frame, it links to the frame before. Paint any linked cell and the others change with it; linked cells are hatched in sheet view and the X-sheet) · Unlink Cells (the selected frames' cells keep their pixels and stop following). · Tag Frames... (name the selected frames; see Tags below) · Delete Tag · Frame Note... (the current frame's note; see Frame notes below) · Clear Frame Note · Soundtrack... (a WAV / OGG / MP3 / FLAC / MIDI that plays with the frames; see Soundtrack below) · Remove Soundtrack · Detect Frames (a sprite sheet without frames: finds the frame grid from the gaps between the sprites - frame size, gutter, margin - and slices it there) · Import PNG Sequence... (pick any file of name_0001.png, name_0002.png ...: they all come in as frames, a repeated file as a held frame). A marquee or wand selection inside the current frame moves with it to the next frame (same place in the cell). Export Animated GIF... (frames in loop order, holds, transparency, colour cycling) · Export Animated PNG (APNG)... (exact delays, every alpha level) · Export PNG Sequence... (one PNG per tick at the FPS) · Export BAS Player (DATA)... (a QB64 program that plays the frames, colour cycling along) · Export BAS Player + Sheet PNG... (the same, the frames cut out of a PNG beside it) · Export Sprite Sheet + Frame Data... (the sheet PNG + Aseprite-style JSON + a QB64 .bi of the frame rects) · Export Scale 1× / 2× / 4×. (Also View → Frame Grid
and View → Animation Panel; every item is in the command palette.)

### Animation panel (View / ANIM → Animation Panel)
| Control | Action |
|---------|--------|
| `\|<` `<` `PLAY` `>` `>\|` | First / previous / play-stop / next / last frame |
| `ADD` `DUP` `INS` `DEL` | Add (a copy of the last; `Shift+click` = blank), duplicate, insert a blank after, delete the current frame |
| `-` / `+` on a row | Step frame W / H, gutter, margin, FPS, the current frame's hold. `Shift+click` = 10 at a time; hold the button to repeat (one undo step) |
| A row's number | Wheel = +/- 1 (`Shift` = 10) · drag up / down = step it · click = type it · middle click = back to its default (gutter / margin 0, FPS 15, hold 1, onion 1 / 1 / 40 %). Works on the onion BEFORE / AFTER / OPACITY rows too |
| `RE-SLICE` / `RESIZE` | What a frame size change does to a drawn sheet: the grid moves over the pixels, or the frames resize and each drawing stays in its frame (the canvas refits). Asked on the first change, then remembered for the document |
| `FWD` `REV` `PING` `ONCE` | Loop mode: forward, backward, ping-pong, play once |
| SCALE `1X` `2X` `4X` | The export scale (the lit one is current; same as ANIM → Export Scale) |
| EXPORT `GIF` `APNG` `BAS` | Export an animated GIF / animated PNG / BAS player (ANIM → Export ...) |

The panel docks and floats like the other windows (drag its title bar; F11 hides it).

### Lightbox (ANIM → Lightbox, `Num 0`)
The **Animate** workspace (`Ctrl+Shift+W`, `anim`) opens it with onion skin, the frame grid and the Animation panel; leaving it puts your own view back.

The work area shows the frames instead of the sheet: a **strip** of frames along the top
(the current one outlined; it scrolls to keep it in view), the **transport bar**, and 3 / 5 / 7
**panes** (`Num *`) with the current frame in the middle and the frames before / after it
round it. You can draw in any pane: the one your stroke goes into (under the pointer) has a
thick magenta ring with a dashed edge (theme `ANIM_FRAME_DRAWING`). The frame keys, Play and frame operations work as in sheet view. A floating window
parked on the work area's left or right edge over the strip (a Color Mixer, say) moves the
lightbox over beside it.

| Transport bar | Action |
|---------------|--------|
| `\|<` `<` `PLAY` `>` `>\|` | First / previous / play-stop / next / last frame |
| `FWD` / `REV` / `PING` / `ONCE` | Click for a menu of the loop modes |
| time | Where the current frame comes up / the whole animation |
| `- FPS +` | Click `-` / `+` to step the FPS (`Shift+click` = 10), or wheel over it; each change undoes on its own |
| seek bar | Click or drag along it to scrub frames |
| `n/total` | Click and type: `5` goes to frame 5, `5/20` makes 20 frames and goes to 5, `/20` only sets the total. `Enter` applies, `Esc` cancels. A smaller total that would drop drawn frames asks first (`Enter` = drop, `Esc` = keep); always undoable |
| `+` | Add a frame (a copy of the last; `Shift+click` = blank) |

**Draw in any pane** with any tool: it paints that frame. A stroke stays inside its frame
(ANIM → Clip Strokes to the Frame in the Lightbox, on by default; turn it off to run over the
edge). ANIM → Clip Strokes to the Frame in Sheet View does the same on the sheet (off by
default). Zooming and panning stay with the sheet view.

| Strip | Action |
|-------|--------|
| Click a frame | Make it current (and the only one selected) |
| `Ctrl+click` | Add / remove a frame from the selection |
| `Shift+click` | Select the frames from the last one clicked to this one (`Ctrl+Shift` adds them) |
| Drag | Move the selected frames (or the frame dragged) to where you drop them - one undo step |
| Wheel | Scroll the strip (a tray: a row at a time); a frame change brings the current frame back into view |
| `Ctrl+Wheel` | Bigger / smaller cells (Settings → Panels → Lightbox Strip → Cell Size) |
| `R-Click` | The strip's menu: **Tray** (across, then down) or **Row** (across only), Fit Cells, Bigger / Smaller Cells |
| Drag the strip's bottom edge | Make the strip taller or shorter (the panes get the rest); the frames grow with it |
| Double-click the strip's bottom edge | Fit the cells again, and grow the strip until every frame shows (a row: every frame across) |

The strip is a **tray** by default, like an ice cube tray: it lays the frames across, then down
in rows, with the biggest cells that still show every frame. Cells shrink no smaller than
**Min Cell** (32 px; Settings → Panels → Lightbox Strip); past that, the strip scrolls a row at
a time. **Row** puts the frames in one row as tall as the strip, as before. While dragging frames
in a tray, move above or below the strip to scroll it a row.

With two or more frames selected, Play (`Num Enter`) plays just those (first to last).

**X-sheet** (`Num 8`, ANIM → X-Sheet, or the transport bar's `X-SHEET`): the strip becomes a
grid of frames across and layers down, top layer first as in the Layers panel. Each column is
one tick at the FPS, so a frame held 3 spans three columns; the header numbers the frames and
the bottom row gives each one's hold. A cell shows that layer's drawing in that frame, with a
line along the rest of its hold; a blank cell has nothing drawn. The current frame's column is
tinted, the current layer's row highlighted; hidden layers are dim, `R` marks a reference
layer, `=` a layer the same on every frame. Cells show what's drawn in them zoomed in, as the
Layers panel thumbnails do (Settings → Panels → Thumbnail Shows / Min Crop). A name too long
for its column ends in `~`; hover it for the whole name.

| X-sheet | Action |
|---------|--------|
| Click a cell | That frame and that layer become current (`Ctrl` / `Shift` select frames as in the strip) |
| Click a frame number or a hold | That frame (`Ctrl` / `Shift` as in the strip) |
| Click a layer name | That layer |
| Wheel | Scroll the frames; `Shift+Wheel` (or the wheel over the names) scrolls the layers when they don't all fit |
| Drag along the hold row | Change that frame's hold, one tick per column dragged (at least 1) |
| Drag a cell | Move its drawing to the cell you drop it on - another frame, another layer, or both; the drawing there is replaced. Hold `Ctrl` as you let go to copy it instead |
| Drag a frame number | Move the selected frames (or that one) to where you drop them, as in the strip |
| `Shift` + drag a cell (same row) | Link the cell you drop it on to the dragged cell's drawing (hatched; painting either changes both) |
| Drag the name column's right edge | Widen / narrow the layer names (double-click it: automatic) |
| Drag the X-sheet's bottom edge | More X-sheet, less panes or the other way (double-click it: automatic) |
| Drag the slider in the header's `LAYER` cell | Zoom the time line: left = every frame fits across, right = the default (a thumbnail per tick). Double-click it for the default. Shown only when the frames don't all fit |
| `Ctrl+Wheel` over the grid | Zoom the time line in / out around the frame under the pointer |
| `Ctrl+Shift+Wheel` | Layer rows' size: Text → Tiny → Small → Medium (thumbnails as in the Layers panel) |
| `R-Click` the header (frame numbers) | Zoom to Fit All Frames, Default Size, Zoom In / Out, Layer Rows: Text / Tiny / Small / Medium |
| `<` / `>` on the TAGS row | Go to the previous / next tag (selects its frames) |
| `R-Click` the TAGS row | Every tag listed at the top (with its frames): pick one to go to it; then Tag / Rename / Delete Tag and the frame notes |

Each drag is one undo step. Dragging past the left or right edge scrolls the grid.

The X-sheet is drawn to time: a frame is as wide as its hold, so a long animation with long holds
(60 frames held 24 ticks each) shows only a few frames at the default size. Zoom out with the
header's slider or `Ctrl+Wheel` to see them all; zoomed far out, a drawn cell shows as a bar
instead of a thumbnail. Settings → Panels → Lightbox Strip / X-Sheet → X-Sheet Rows sets the
size of the layer rows and the SOUND rows. In Text and Tiny rows a sound clip's name sits over its
waveform. In Small and Medium rows the name is on the first line, with a taller waveform under it.

**Opening an animated GIF** gives you its frames on a sheet: each frame as a browser shows it, the delays as the FPS and holds, looping as the GIF does. With Save .draw Beside Images off, Ctrl+S writes it back as an animated GIF.

**Opening a sprite sheet PNG with its frame data beside it** (`name.json` from Aseprite's Export Sprite Sheet, TexturePacker or DRAW's own Export Sprite Sheet) gives you its frames: a regular grid is sliced where it is, a packed atlas (trimmed or rotated sprites) is laid out again on a grid; durations become the FPS and holds, tags become tags. Without a .json, ANIM → Detect Frames finds the grid.

**Opening an Aseprite file with two or more frames** does the same: every layer keeps its own cels, one per frame cell; the frame durations become the FPS and holds, Aseprite's tags become tags, and linked cels become linked cells. A tag over all the frames sets the loop (reverse or ping-pong).

**Tags** name a run of frames - "walk", "jump". Select the frames (strip or X-sheet), then
ANIM → Tag Frames... and type a name (a name you already used moves that tag). Once a document
has tags, the X-sheet shows a TAGS row under HOLD: click a tag to select its frames, then Play
plays just that tag, and Export Animated GIF / APNG / PNG Sequence / BAS Player write just its
frames. The sprite sheet export keeps every frame and lists the tags in its JSON and .bi. With a
tag selected, Tag Frames... renames it; ANIM → Delete Tag removes it. Tags move with their
frames when you add, delete or move frames, and are saved with the document.

**Frame notes** are a line of text per frame - "foot down", "ka-" - like the action column of a
paper X-sheet. ANIM → Frame Note... writes the current frame's note; once any frame has one, the
X-sheet shows a NOTES row (each note runs from its frame to the next note). Click a note to go to
its frame (the full note shows on the status bar); double-click anywhere on the row to write or
change that frame's note. ANIM → Clear Frame Note removes the selected frames' notes. Notes move
with their frames and are saved with the document.

**Soundtrack**: ANIM → Soundtrack... picks a sound (WAV, OGG, MP3, FLAC, MIDI ...) that plays with
the frames. Each frame starts at its place in the sound (the frames before it, their holds, at
the FPS), so playing from any frame plays the sound from there, and the loop back to frame 1
starts it again. Stepping frames while stopped plays just that frame's bit of the sound (a
scrub), as do the full-screen preview's steps. The X-sheet shows a SOUND row with the waveform
under the frames it plays over (24-bit WAVs too: DRAW reads those itself); click it to go to a frame and hear it. The soundtrack is saved
with the document (by its path; a sound moved along with the document is found beside it), and
Export BAS Player copies it beside the program as NAME-sound.EXT and plays it in step. ANIM →
Remove Soundtrack takes it off (one undo step). The volume is `ANIM_SOUND_VOLUME` in DRAW.cfg
(0-100).

**Sound clips and tracks**: the soundtrack can be several sounds on up to 4 tracks (SOUND 1-4
rows on the X-sheet), mixed as they play. ANIM → Soundtrack... with sound already there adds the
picked files on a new track from the current frame; pick several files at once and they go one
after another. On a SOUND row: click a clip to pick it (outlined; the rows now have the keys) and
drag it to move it - it snaps to frame starts (Shift = anywhere), and dragging it onto another
SOUND row puts it on that track. **Ctrl+C / Ctrl+X / Delete** copy / cut / delete the picked
clip, or, with several frames selected (Shift+click), just that span of the track's sound - the
sound after it stays where it is. **Ctrl+V** pastes at the current frame, over what is there.
**Esc** or a click elsewhere gives the keys back. Right-click a SOUND row for Add Sound Here... ·
Add Sound on a New Track... · Copy / Cut / Paste Here / Delete · Split Here · Remove Soundtrack.
Every change is one undo step. Hover a clip for its file and times. Export BAS Player writes the
mix beside the program as NAME-sound.wav (a single sound that plays from frame 1 to its end is
still copied as it is).

**Dropping sound files, empty tracks**: every animation's X-sheet has a SOUND row; an empty one
says "drop a sound file here, or right-click" and is silence (nothing is played, saved or
exported). Drop a sound file (wav, ogg, mp3, flac, mid, mod, xm, it, s3m) from your file manager
onto a SOUND row and it goes on that track from the frame under the pointer; dropped anywhere
else it goes on a new track from the current frame. Right-click a SOUND row → **Add Empty Track**
for another silent row to drop or paste onto (up to 4), **Remove Track** to take one away with its
clips (the tracks under it move up). Each drop / removal is one undo step.

**COPY / PASTE / CUT** (the transport bar, or the ANIM menu): COPY puts the selected frames
(or the current one) on the clipboard; PASTE inserts them as new frames after the selection;
`Shift`+PASTE pastes over the frames from the first selected one (adding frames past the end);
CUT copies then deletes them. Each is one undo step, the pasted frames end up selected, and
another DRAW window can paste them too. Elsewhere in the lightbox a click only works the
transport bar.

**Onion skin** (`Num /`, ANIM → Onion Skin, on by default): the current pane shows the frames
before it (red) and after it (blue) faintly over its picture, so you can draw the in-between.
Only what differs from the current frame shows - a solid background stays clear. Set how many
frames each side (BEFORE / AFTER, 0-5) and how strong (OPACITY) in the Animation panel; ANIM →
Onion Skin Red / Blue Tint shows them in their own colours instead. Hidden while playing.

**Apply to the selected frames** (in the lightbox): with frames selected in the strip (or just
the current one), Flip (`Home` / `End`), Rotate (`>` / `<`, square frames), the IMAGE / EFFECTS
adjustments and Remap to Palette change only those frames, each frame flipped / turned in its own
cell. The Move tool dragged in a pane moves the drawing of every selected frame. ANIM → Replace
FG Color with BG in Frames swaps a colour in them (sheet view too). Each is one undo step.

**The current frame is the canvas** (in the lightbox): Layer → Align / Distribute line the
drawing up with its frame's edges (each selected frame on its own); with several layers selected
they line up with each other inside the frame. Smart guides snap to the frame's edges and centre
and to the other layers' drawing in that frame - also while the Move tool drags in a pane. The
Transform tool takes only the current frame's drawing and keeps the result inside that frame. Select
All (`Ctrl+A`) selects the current frame, and Invert Selection stays inside it. Copy / Cut / Copy
Merged with nothing selected take only the current frame; Paste centres on it (and stays inside
it). Symmetry mirrors about the centre of the frame you draw in. A dropped or imported image is
sized against the frame and placed in it; what spills past the frame's edges is cut off. Scale
2x / -50% (`PgUp` / `PgDn`) and 2x H / 2x V (`Ctrl+Home` / `Ctrl+End`) with nothing selected scale
each selected frame about its own centre (cut off at its edges). Fill, global fill and the Magic Wand stop
at the edges of the frame you click in. Select From Current Layer / Selected Layers take only the
current frame's pixels; a marquee stops at the edges of the frame the drag began in; a moved
selection or paste is cut off at the frame's edges when it lands (with clip to frame on). New
Text Layer starts at the frame's centre, and text wraps at the frame's right edge. Centred
effects (Twirl, Pinch / Bulge, Kaleidoscope, Lens Flare, Backlight, Ripples, Grid, Lightning,
the typed blurs) work on each selected frame as its own picture, centred on it; their preview
shows the current frame. A fill with a drawer gradient, and drawer image paint, span the frame
painted in. Edit → Paste in Place puts what was copied in one frame at the same spot in the
current frame. The Pixel Analyzer looks at the current frame; AI New Layer defaults to the
frame's size and place; a new reference image fits the frame. Crop Canvas is refused (it would cut
every frame) - change the frame size with ANIM → Resize.

---

## Audio · Music

| Keys | Action |
|------|--------|
| `}` | Next track |
| `{` | Previous track |
| `*` | Play a random track |

Everything else is in the **Audio** menu: Sound FX toggle/volume/mute, Music toggle/volume/mute, Random Track (per format), Explore Music, Now Playing. MIDI plays via OPL3 FM or a custom `.sf2` (Settings → Audio → MIDI Soundfont).

---

## Drag & Drop · Image Import

**Where you drop decides what happens:**

| Drop target | Result |
|-------------|--------|
| Canvas | Place on current layer (undoable) |
| Layer panel | New layer |
| Brush bin (drawer) | Custom brush in next free slot (new page if full) |
| Menu bar | Open in a separate DRAW window |

`Shift` while dropping centers on canvas. Images larger than the canvas open the interactive **Image Import** flow.

**Image Import controls:** `Drag` placement marquee · `Shift+corner` constrained resize · `Wheel` zoom · `Arrows` move box 1px · `Shift+Arrows` 10px · `Ctrl+Arrows` resize · `Alt+Arrows` pan crop · `R-Drag` pan crop · `>`/`<` rotate · `Home`/`End` flip · `Enter` apply · `Esc` cancel.

---

## Menu Bar · Command Palette

### Menu bar
`Alt` (tap) open/close · `Ctrl+F11` toggle · `←`/`→` navigate menus · `↑`/`↓` items · `Enter` execute · `Esc` close. Each item shows its hotkey; toggles show checkmarks.

### Command Palette (`?`)
Type to filter (subsequence/fuzzy) · `↑`/`↓` navigate · `Enter` execute · `Esc` close · `Backspace` delete char. **Smart case:** a lowercase query is case-insensitive; an ALL-CAPS query is a case-sensitive acronym match (e.g. `TDF` → the one TheDraw command).

---

## Mouse Reference

### Canvas (general)
| Trigger | Action |
|---------|--------|
| `L-Click`/`Drag` | Draw/select with FG (tool-dependent) |
| `R-Click` | Draw with BG (Brush/Dot/Line/Rect/Ellipse/Fill/Spray) |
| `M-Click + Drag` | Pan |
| `Dbl M-Click` | Reset zoom & pan |
| `Wheel` | Zoom |
| `Space + L-Drag` | Pan |
| `Ctrl+L-Click` | Set symmetry center |

### Rebindable mouse controls (Customize Controls)
Open **Customize Controls** (command palette → "customize controls") and look under
the **MOUSE** category. These rows can be reassigned with **SET…** → press the button
(the defaults above are what ships):

| Row | Default | Notes |
|-----|---------|-------|
| Paint with foreground color | `Left Button` | swap with BG to paint FG on the right |
| Paint with background color | `Right Button` | |
| Pan the canvas (drag) | `Middle Button` | whole pan drag follows the rebind |
| Undo (mouse back button) | `Button 4 (Back)` | any button → any action |
| Redo (mouse forward button) | `Button 5 (Fwd)` | |
| Canvas: Wheel tilt right - brush size increase | `Wheel Tilt Right` | horizontal wheel tilt (see below) |
| Canvas: Wheel tilt left - brush size decrease | `Wheel Tilt Left` | |

Extra buttons (back/forward and beyond, up to 8) are sampled from your device and can
drive **any** action. Overrides persist in `DRAW.bindings` separately from keyboard
overrides, so an action can keep both a key and a mouse trigger. **RESET ALL** restores
every default.

**Horizontal wheel tilt** (mice with a tilt wheel): tilting the wheel left/right adjusts
brush size by default, and is fully rebindable — **SET…** on a tilt row, then *tilt the
wheel* to capture the direction. DRAW reads the tilt from `_WHEEL(4)` on a typical mouse;
if yours differs, set `MOUSE_TILT_WHEEL` (see `--options-list`) to the right wheel index
(`0` disables tilt). *(Vertical-wheel zoom / brush-size and Alt-pick / Ctrl-symmetry
rebinding are not yet exposed.)*

### Per-tool (canvas)
| Tool | Mouse |
|------|-------|
| Zoom | L-Click in · **R-Click out** · `Alt`+L-Click out (if your WM doesn't grab Alt+click) · L-Drag zoom-to-region |
| Picker | L/R-Click pick FG/BG · `Alt`+L/R-Click temporary pick (returns tool on Alt release) |
| Dot | `Shift`+R-Click line from last point |
| Marquee | drag handles resize · drag inside move · `Shift`/`Alt`+Drag add/subtract |
| Move | drag handles scale · drag inside move · `Shift`+Click pick topmost layer |
| Bezier | Click corner anchor · Click+Drag smooth anchor · `Backspace` remove last · `Enter` commit · `Esc` cancel · `H` handles |

*(Layer panel, palette, drawer, preview, browser, toolbar mouse: see their sections above.)*

### Toolbar button extras
Text: L=VGA, R=Tiny5, M=load custom font. Open: L=open project, R=import image. Pan: M/Dbl-Click resets zoom+pan. Dot: Dbl-L-Click clears custom brush.

---

## Hold-Key Chords

Hold a **non-modifier** key, then click/press/drag. Easy to miss:

| Hold | + Action | Effect |
|------|----------|--------|
| `F` | L/R-Click | Global fill (contiguous) with FG / BG across all visible layers |
| `Shift+F` | L/R-Click | Replace-all global fill (FG / BG) |
| `E` | Click | Flood-erase contiguous pixels to transparent |
| `E` | (as a tool) | Hold to erase, release to restore previous tool |
| `W` | Click | Magic-wand from merged canvas |
| `G` | Arrow | Resize grid width/height independently |
| `L` | 0–9 | Smart-Shape 3D light intensity preset |
| `R` | Click | Picker samples the reference image |
| `Space` | Drag | Pan (any tool); or reposition a Smart Shape while dragging |

---

## Workspaces · Capture · Annotate

| Keys | Action |
|------|--------|
| `Ctrl+Shift+W` | Workspace switcher (type `ann` + `Enter`) |
| `F11` (in a workspace) | Show what the workspace hid / hide it again |
| `Ctrl+Shift+P` | Capture Screen |
| Region picker: `Drag` / `Enter` / dbl-click / `Space` / `Esc` / `Arrows` | Box / use it / use it / whole screen / cancel / nudge (`Shift` = 10) |

**Annotate workspace keys** (only while Annotate is active; also Tools → Annotate):

| Keys | Action |
|------|--------|
| `R` / `Shift+R` | Rectangle / filled |
| `O` | Ellipse |
| `L` | Line |
| `A` | Arrow (line with a sticky arrowhead) |
| `T` | Text |
| `H` | Highlighter (yellow brush on a "Highlight" layer at 45% opacity) |
| `X` | Redact — drag a box, pixelated on release |
| `N` / `Shift+N` | Numbered callout (click) / restart at 1 |
| `C` / `V` | Crop / Move |
| `Ctrl+C` | Copy the selection or the whole picture |
| `Ctrl+S` | Quick save PNG (no dialog) |
| `Ctrl+Enter` | Done — save, copy, back to the previous document + workspace (a cold `DRAW --capture` launch closes DRAW instead) |

A workspace's `[KEYS]` can remap any of these; menus and the command palette show the active workspace's keys.

---

## Command Line

```bash
./DRAW.run project.draw            # open a project
./DRAW.run image.png               # load an image (import flow if larger than canvas)
./DRAW.run --config DRAW.linux.cfg # specific config (-c)
./DRAW.run --config-upgrade        # reconcile cfg with new defaults
./DRAW.run --reset-defaults        # restore factory cfg
./DRAW.run --options-list          # print every config option + default, then exit
./DRAW.run --option KEY=VALUE      # override any config key for this run (repeatable; never saved)
./DRAW.run --workspace annotate    # start in a workspace for this run
./DRAW.run --workspaces            # list workspaces, then exit
./DRAW.run --capture               # capture the screen (hands off to a running DRAW)
```

Config priority: `--config` > OS-specific (`DRAW.macOS/linux/windows.cfg`) > `DRAW.cfg`.

---

## Pixel Art Analyzer (overlay)

When the Pixel Art Analyzer overlay is open (Help / Tools → Pixel Art Analyzer):

| Keys | Action |
|------|--------|
| `Esc` | Close |
| `Space` | Toggle overlay |
| `G` | Toggle grayscale |
| `1`–`8` | Toggle individual detectors (jaggies / islands / banding / fat-pixels / dithering / contrast / value / noise) |
| `0` / `9` | All detectors on / off |
| `[` / `]` | Confidence threshold − / + |
| `A` | Re-analyze |
| `Ctrl+=` / `Ctrl+-` / `Ctrl+0` | Zoom in / out / reset |

---

## Appendix: internal behaviors

These are behaviors rather than user shortcuts, kept out of the tables above:

- **Auto-hide:** UI panels hide while a tool is actively dragged over them; `Tab`/`F10`/`F11` manual toggles stay hidden until manually shown.
- **Drag thresholds:** zoom-to-region needs an 8px drag; layer-panel drag shows a blue drop indicator; browser drag-to-canvas starts image import.
- **Toolbar clicks** change the tool but do not draw on the canvas.
- **macOS:** `Ctrl+Click` → right-click (DRAW compensates for symmetry center); ⌘ not detected by QB64-PE (see `MAC-USERS-README.md`).

---

## Generated binding index

> **Auto-generated** from the live input registry by `DRAW --dump-shortcuts`
> (regenerate with `DEV/tools/gen-shortcuts.sh`). Everything between the `BINDINGS` markers
> is machine-written — to change it, edit the registry (`INPUT/INPUT.BM` → `INPUTS_register_all`),
> not this file. The curated sections above stay hand-authored (the "augment" model).

<!-- BINDINGS:START -->
<!-- GENERATED by `DRAW --dump-shortcuts` from the input registry (254 bindings).
     Do not hand-edit between the BINDINGS markers in SHORTCUTS.md; edit the registry (INPUTS_register_all) instead. -->

### Global / Application

| Trigger | Action | Dispatch |
|---------|--------|----------|
| `Ctrl+F11` | Toggle menubar | central |
| `Alt+,` | Previous frame (Alt+,) | central |
| `Alt+.` | Next frame (Alt+.) | central |
| `Alt+Home` | First frame (Alt+Home) | central |
| `Alt+End` | Last frame (Alt+End) | central |
| `Alt+/` | Play / stop (Alt+/) | central |
| `Ctrl+Shift+L` | Lock Layout | central |
| `Ctrl+Alt+K` | Cancel AI generation | central |
| `Ctrl+,` | Settings dialog | legacy |
| `F12` | F12 dev debug dump | central |
| `Ctrl+Alt+O` | Toggle CRT Effect | legacy |

### File

| Trigger | Action | Dispatch |
|---------|--------|----------|
| `Ctrl+Q` | Quit | central |
| `Ctrl+Shift+P` | Capture screen | central |
| `Ctrl+N` | New canvas | central |
| `Ctrl+O` | Open Image | central |
| `Ctrl+S` | Save Image | central |
| `Ctrl+Shift+S` | Save As | central |
| `Ctrl+Alt+S` | Export Selection | central |
| `Ctrl+Alt+Shift+S` | Flatten & Save | central |
| `Ctrl+Shift+Q` | Export QB64 Project | central |
| `Ctrl+Shift+E` | Export Again | central |
| `Alt+O` | Open Project | legacy |
| `Alt+X` | Exit | legacy |

### Edit / History / Clipboard

| Trigger | Action | Dispatch |
|---------|--------|----------|
| `H` | Flip horizontal | central |
| `Ctrl+Shift+H` | Flip vertical | central |
| `Home` | Flip horizontal (Home) | central |
| `End` | Flip vertical (End) | central |
| `PgUp` | Scale 2x (PgUp) | central |
| `PgDn` | Scale -50% (PgDn) | central |
| `Delete` | DEL - Clear selection | central |
| `Backspace` | Backspace - Fill with FG | central |
| `Shift+Backspace` | Shift+Backspace - Fill with BG | central |
| `Ctrl+Home` | Scale 2x horizontal | central |
| `Ctrl+End` | Scale 2x vertical | central |
| `Ctrl+D` | Deselect | central |
| `Ctrl+A` | Select All | central |
| `Ctrl+Shift+I` | Invert Selection | central |
| `Ctrl+H` | Hide Selection | central |
| `Ctrl+C` | Copy | central |
| `Ctrl+Shift+C` | Copy Merged | central |
| `Ctrl+Alt+C` | Copy to New Layer | central |
| `Ctrl+X` | Cut | central |
| `Ctrl+Alt+X` | Cut to New Layer | central |
| `Ctrl+V` | Paste | central |
| `Ctrl+Shift+V` | Paste from OS Clipboard | central |
| `Ctrl+Alt+V` | Paste in Place | central |
| `Ctrl+E` | Clear Selection | central |
| `Ctrl+Z` | Undo | central |
| `Ctrl+Y` | Redo | central |
| `Ctrl+Shift+Z` | Redo (Ctrl+Shift+Z) | central |

### View / Zoom / Pan

| Trigger | Action | Dispatch |
|---------|--------|----------|
| `1` | Z+1 zoom 100% | central |
| `2` | Z+2 zoom 200% | central |
| `3` | Z+3 zoom 300% | central |
| `4` | Z+4 zoom 400% | central |
| `5` | Z+5 zoom 500% | central |
| `6` | Z+6 zoom 600% | central |
| `7` | Z+7 zoom 700% | central |
| `8` | Z+8 zoom 800% | central |
| `9` | Z+9 zoom 1600% | central |
| `0` | Z+0 zoom 3200% | central |
| `F4` | F4 - Toggle preview window | central |
| `F5` | F5 - Toggle edit bar | central |
| `Shift+F5` | Shift+F5 - Toggle adv bar | central |
| `Ctrl+Shift+F5` | Ctrl+Shift+F5 - Reload theme | central |
| `F10` | F10 - toggle status bar | central |
| `F11` | F11 - toggle all UI | central |
| `Tab` | Tab - toggle toolbar | central |
| `Ctrl+L` | Toggle Layer Panel | central |
| `Ctrl+Shift+W` | Workspace switcher | central |
| `Ctrl+0` | Reset Zoom | central |
| `Ctrl+=` | Zoom In | central |
| `Ctrl+-` | Zoom Out | central |

### Tools

| Trigger | Action | Dispatch |
|---------|--------|----------|
| `B` | Brush tool | central |
| `D` | Dot tool | central |
| `F` | Fill tool | central |
| `L` | Line tool | central |
| `P` | Polygon tool | central |
| `Shift+P` | Polygon filled tool | central |
| `R` | Rectangle tool | central |
| `Shift+R` | Rectangle filled tool | central |
| `C` | Ellipse tool | central |
| `Shift+C` | Ellipse filled tool | central |
| `E` | Eraser tool | central |
| `M` | Marquee tool | central |
| `W` | Magic wand tool | central |
| `V` | Move tool | central |
| `T` | Text tool | central |
| `Shift+T` | Text tool (Tiny5 font) | central |
| `Z` | Zoom tool | central |
| `I` | Picker tool | central |
| `S` | Smart shapes tool | central |
| `Q` | Bezier tool | central |
| `K` | Spray tool | central |
| `O` | Bevel-rect outer style | central |
| `Ctrl+P` | Command palette | central |
| `Ctrl+T` | Text Tool (Custom Font) | central |

### Selection

| Trigger | Action | Dispatch |
|---------|--------|----------|
| `=` | M+= expand selection 1px | central |
| `-` | M+- contract selection 1px | central |
| `Shift+=` | M++ expand selection large | central |
| `Shift+-` | M+_ contract selection large | central |

### Layers / Groups

| Trigger | Action | Dispatch |
|---------|--------|----------|
| `Ctrl+Shift+N` | New Layer | central |
| `Ctrl+Shift+Delete` | Delete Layer | central |
| `Ctrl+Shift+D` | Duplicate Layer | central |
| `Ctrl+Shift+R` | Rename Layer | central |
| `Ctrl+Shift+[` | Layer to bottom | central |
| `Ctrl+Shift+]` | Layer to top | central |
| `Ctrl+PgUp` | Layer move up | central |
| `Ctrl+PgDn` | Layer move down | central |
| `Ctrl+Alt+E` | Merge layer down | central |
| `Ctrl+Alt+Shift+E` | Merge all visible | central |
| `Ctrl+G` | New Group | central |
| `Ctrl+Shift+G` | Group from Sel. | central |
| `Ctrl+Shift+U` | Ungroup | central |
| `Ctrl+Alt+Shift+C` | Copy Layer | central |
| `Ctrl+Alt+Shift+V` | Paste Layer | central |
| `Ctrl+Alt+N` | New Window | central |

### Color / Palette

| Trigger | Action | Dispatch |
|---------|--------|----------|
| `F1` | F1 - Drawer brush mode | central |
| `F2` | F2 - Drawer gradient mode | central |
| `F3` | F3 - Drawer pattern mode | central |
| `Shift+Tab` | Shift+Tab - toggle color cycling | central |
| `Shift+Delete` | Set BG transparent | central |
| `1` | Opacity 10% | central |
| `2` | Opacity 20% | central |
| `3` | Opacity 30% | central |
| `4` | Opacity 40% | central |
| `5` | Opacity 50% | central |
| `6` | Opacity 60% | central |
| `7` | Opacity 70% | central |
| `8` | Opacity 80% | central |
| `9` | Opacity 90% | central |
| `0` | Opacity 100% | central |
| `X` | Swap FG/BG | central |

### Grid / Symmetry

| Trigger | Action | Dispatch |
|---------|--------|----------|
| `R` | G+R reset grid offset | central |
| `Shift+R` | G+Shift+R reset grid size | central |
| `Ctrl+R` | G+Ctrl+R reset grid all | central |
| `O` | G+O grid offset pick mode | central |
| `Right` | G+Right grid width + | central |
| `Left` | G+Left grid width - | central |
| `Down` | G+Down grid height + | central |
| `Up` | G+Up grid height - | central |
| `Ctrl+Shift+?` | Match grid to brush size | central |
| `F7` | F7 - Symmetry cycle | central |
| `F8` | F8 - Fill Adjust toggle | central |
| `'` | ' Toggle grid visibility | central |
| `"` | Shift+apostrophe Toggle pixel grid | central |
| `Ctrl+'` | Ctrl+' Cycle grid mode | central |
| `;` | ; Toggle snap-to-grid | central |
| `/` | / Toggle grid alignment mode | central |
| `.` | . Increase grid size (uniform) | central |
| `,` | , Decrease grid size (uniform) | central |

### Brush / Custom Brush

| Trigger | Action | Dispatch |
|---------|--------|----------|
| `Home` | Flip custom brush H (Home) | central |
| `End` | Flip custom brush V (End) | central |
| `PgUp` | Scale custom brush up (PgUp) | central |
| `PgDn` | Scale custom brush down (PgDn) | central |
| `F6` | F6 - Pixel perfect toggle | central |
| `\` | \ Toggle brush shape | central |
| `|` | | (Shift+\) Toggle brush shape | central |
| `Ctrl+B` | Capture/Clear Custom Brush | central |
| `[` | Brush size - | central |
| `]` | Brush size + | central |
| `F12` | Export custom brush PNG (F12) | central |

### Image / Adjustments / Effects

| Trigger | Action | Dispatch |
|---------|--------|----------|
| `Ctrl+F` | Redo Last Effect (Ctrl+F) | central |
| `Ctrl+Alt+F` | Recall Last Effect (Ctrl+Alt+F) | central |
| `Ctrl+Shift+F` | Blend Last Effect (Ctrl+Shift+F) | central |

### Panels

| Trigger | Action | Dispatch |
|---------|--------|----------|
| `Ctrl+R` | Toggle reference image | central |
| `Ctrl+Alt+R` | Random palette | central |
| `Ctrl+Alt+Shift+G` | Grayscale preview | central |
| `Ctrl+M` | Toggle Character Map | central |
| `Ctrl+Shift+M` | Toggle Advanced Color Picker | central |

### Audio

| Trigger | Action | Dispatch |
|---------|--------|----------|
| `key#123` | Prev music track | central |
| `key#125` | Next music track | central |
| `key#42` | Random music track | central |

### Mouse

| Trigger | Action | Dispatch |
|---------|--------|----------|
| `L-Click` | Canvas: tool stroke begin (LMB down) | legacy |
| `L-Drag` | Canvas: tool drag begin | legacy |
| `L-Drag` | Canvas: tool drag continue | legacy |
| `L-Drag` | Canvas: tool drag end | legacy |
| `L-Click` | Canvas: tool stroke end (LMB up) | legacy |
| `L-Click` | Canvas: tap (single click no motion) | legacy |
| `R-Click` | Canvas: BG paint begin (RMB down) | legacy |
| `R-Drag` | Canvas: BG drag begin | legacy |
| `R-Click` | Canvas: BG end (RMB up) | legacy |
| `M-Click` | Canvas: pan begin (MMB down) | legacy |
| `M-Drag` | Canvas: pan drag | legacy |
| `M-Click` | Canvas: pan end (MMB up) | legacy |
| `Wheel Up` | Canvas: Wheel up - zoom in | legacy |
| `Wheel Down` | Canvas: Wheel down - zoom out | legacy |
| `Ctrl+Wheel Up` | Canvas: Ctrl+Wheel up - brush size increase | legacy |
| `Ctrl+Wheel Down` | Canvas: Ctrl+Wheel down - brush size decrease | legacy |
| `Wheel Tilt Right` | Canvas: Wheel tilt right - brush size increase | legacy |
| `Wheel Tilt Left` | Canvas: Wheel tilt left - brush size decrease | legacy |
| `(unassigned wheel/tilt)` | Canvas: Pan up (assign a wheel/tilt) | legacy |
| `(unassigned wheel/tilt)` | Canvas: Pan down (assign a wheel/tilt) | legacy |
| `(unassigned wheel/tilt)` | Canvas: Pan left (assign a wheel/tilt) | legacy |
| `(unassigned wheel/tilt)` | Canvas: Pan right (assign a wheel/tilt) | legacy |
| `Back Button` | Undo (mouse back button) | central |
| `Fwd Button` | Redo (mouse forward button) | central |
| `L-Click` | Paint with foreground color | legacy |
| `R-Click` | Paint with background color | legacy |
| `M-Click` | Pan the canvas (drag) | legacy |
| `L-Click` | Toolbar: click (select tool) | legacy |
| `Dbl L-Click` | Toolbar: double-click (subtool flyout) | legacy |
| `R-Click` | Toolbar: right-click (context menu) | legacy |
| `Hover enter` | Toolbar: hover enter (tooltip start) | legacy |
| `Hover leave` | Toolbar: hover leave (tooltip clear) | legacy |
| `Move` | Toolbar: cursor move (sub-button tracking) | legacy |
| `L-Click` | Menubar: click (open menu) | legacy |
| `Hover enter` | Menubar: hover (switch open menu) | legacy |
| `L-Click` | Layer panel: click (select layer) | legacy |
| `Dbl L-Click` | Layer panel: double-click (rename) | legacy |
| `R-Click` | Layer panel: right-click (context menu) | legacy |
| `L-Drag` | Layer panel: drag begin (reorder) | legacy |
| `L-Drag` | Layer panel: drag continue (reorder) | legacy |
| `L-Drag` | Layer panel: drag end (reorder) | legacy |
| `Wheel Up` | Layer panel: wheel up (scroll list) | legacy |
| `Wheel Down` | Layer panel: wheel down (scroll list) | legacy |
| `Move` | Layer panel: cursor move (row tracking) | legacy |
| `L-Click` | Palette: left-click (set FG color) | legacy |
| `R-Click` | Palette: right-click (set BG color) | legacy |
| `Dbl L-Click` | Palette: double-click (edit color) | legacy |
| `Hover enter` | Palette: hover enter | legacy |
| `Hover leave` | Palette: hover leave | legacy |
| `Wheel Up` | Palette: wheel up (next palette) | legacy |
| `Wheel Down` | Palette: wheel down (prev palette) | legacy |
| `L-Click` | Edit bar: click (invoke action) | legacy |
| `Hover enter` | Edit bar: hover (tooltip) | legacy |
| `L-Click` | Adv bar: click (invoke action) | legacy |
| `Hover enter` | Adv bar: hover (tooltip) | legacy |
| `L-Click` | Status bar: click (e.g. toggle indicator) | legacy |
| `L-Click` | Drawer: click (select bin) | legacy |
| `Dbl L-Click` | Drawer: double-click | legacy |
| `R-Click` | Drawer: right-click (context) | legacy |
| `L-Drag` | Drawer: drag begin | legacy |
| `Wheel Up` | Drawer: wheel up (page) | legacy |
| `Wheel Down` | Drawer: wheel down (page) | legacy |
| `L-Click` | Organizer: click | legacy |
| `Wheel Up` | Organizer: wheel up (cycle state) | legacy |
| `Wheel Down` | Organizer: wheel down (cycle state) | legacy |
| `L-Click` | Preview: click (button) | legacy |
| `L-Drag` | Preview: drag begin (move/resize) | legacy |
| `L-Drag` | Preview: drag continue | legacy |
| `L-Drag` | Preview: drag end | legacy |
| `Wheel Up` | Preview: wheel up | legacy |
| `Wheel Down` | Preview: wheel down | legacy |
| `L-Click` | Color mixer: click | legacy |
| `L-Drag` | Color mixer: drag begin | legacy |
| `L-Click` | Browser: click | legacy |
| `Dbl L-Click` | Browser: double-click (open) | legacy |
| `L-Drag` | Browser: drag begin (move/resize) | legacy |
| `L-Click` | Charmap: click (select char) | legacy |
| `Dbl L-Click` | Charmap: double-click (insert) | legacy |
| `Wheel Up` | Charmap: wheel up (page) | legacy |
| `Wheel Down` | Charmap: wheel down (page) | legacy |
| `L-Click` | Subtool flyout: click (select sub-tool) | legacy |
| `Move` | Subtool flyout: cursor track | legacy |
| `L-Click` | Text bar: click (button or dropdown) | legacy |


<!-- BINDINGS:END -->

---

<!-- Reconciled against source extraction (agents over KEYBOARD.BM / MOUSE.BM / INPUTS_register_all /
     CMD_init / MENUBAR). Registry coverage + gap audit: PLANS/SHORTCUTS-INVENTORY.md.
     A handful of UNCERTAIN keycode/collision items are listed there for manual confirm in Phase 1.
     The "Generated binding index" section below is spliced by DEV/tools/gen-shortcuts.sh from --dump-shortcuts. -->
