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
15. [Panels · Docking](#panels--docking)
16. [Audio · Music](#audio--music)
17. [Drag & Drop · Image Import](#drag--drop--image-import)
18. [Menu Bar · Command Palette](#menu-bar--command-palette)
19. [Mouse Reference](#mouse-reference)
20. [Hold-Key Chords](#hold-key-chords)
21. [Command Line](#command-line)
22. [Appendix: internal behaviors](#appendix-internal-behaviors)

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
| `Ctrl+S` | Save (silent if previously saved; dialog if new) |
| `Ctrl+Shift+S` | Save As (always prompts) |
| `Ctrl+Alt+Shift+S` | Export selection as cropped image |
| `Ctrl+Shift+Q` | QB64 Code Export — re-export to last project path (no dialog) |
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
| `F10` | Toggle status bar |
| `F11` | Toggle ALL UI |
| `Ctrl+F11` | Toggle menu bar |
| `Ctrl+Shift+Up` | Hide/show menu bar (alt binding) |
| `Ctrl+Shift+Down` | Hide/show status bar + color strip |
| `Ctrl+Shift+Left` | Hide/show left-side UI (edit bar, layers) |
| `Ctrl+Shift+Right` | Hide/show right-side UI (toolbar, organizer, drawer) |
| `#` | Toggle canvas border |
| `Shift` (hold) | Show crosshair while held |
| `Ctrl+Alt+Shift+G` | Toggle grayscale preview |
| `Ctrl+Alt+O` | Toggle CRT effect overlay |

### Zoom & pan
| Keys / Mouse | Action |
|--------------|--------|
| `Ctrl+0` | Reset zoom to 100% and center |
| `Ctrl+=` | Zoom in (25→50→100→200→300…800%) |
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
**Display Scale (window size):** Settings (`Ctrl+,`) → Display → UI Scale (`0`=auto, `1`–`8`).

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
| Rectangle | `Ctrl` | Perfect square |
| Rectangle | `Shift` (from center) | Draw from center |
| Ellipse | `Ctrl` | Perfect circle |
| Ellipse | `Shift` (from center) | Draw from center |

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

### Palette strip mouse
`L-Click swatch` set FG · `R-Click swatch` set BG · `Wheel` scroll · `Shift+Wheel` fast scroll (32) · `Click ◄/►` scroll · `Click palette name` switch-palette dropdown · letter keys (in picker) jump to palette.

### Status-bar swatches
`Click FG swatch` / `Click BG swatch` → open color picker.

### Palette-Ops mode (toggle via organizer button)
`L-Click swatch` wand-select matching pixels · `Dbl L-Click` change color (replaces on canvas) · `R-Click` toggle mark · `M-Click` delete color (remap to nearest) · `M-Click marked` batch-delete marked · `Shift+M-Click` insert blank transparent · `Drag` reorder · `Esc` exit.

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

### Preview window (`F4`)
Follow / Floating-Image modes (View → Preview Window). `Alt+Click` pick FG (CP enabled) · `Alt+R-Click` pick BG · `Wheel` zoom preview · drag title move · drag handle resize.

### Drawer panel
`F1/F2/F3` Brush/Gradient/Pattern mode · `L-Click slot` select · `Shift+L-Click` store current · `R-Click` context menu · `M-Click` cycle mode · `Shift+M-Click` clear slot · `Shift+R-Click` import into slot · `L/R-Click mini palette` set FG/BG.

### Color Mixer / Image Browser
View → Color Mixer (RGB/HSV sliders, hex). View → Browser: `Click` select · `Ctrl+Click` multi-select · `Dbl-Click` load · drag file → canvas/drawer/layer-panel · `Wheel` scroll · `Dbl-Click title` maximize.

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

## Command Line

```bash
./DRAW.run project.draw            # open a project
./DRAW.run image.png               # load an image (import flow if larger than canvas)
./DRAW.run --config DRAW.linux.cfg # specific config (-c)
./DRAW.run --config-upgrade        # reconcile cfg with new defaults
./DRAW.run --reset-defaults        # restore factory cfg
./DRAW.run --options-list          # print every config option + default, then exit
./DRAW.run --option KEY=VALUE      # override any config key (repeatable; beats the .cfg)
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
> (regenerate with `tools/gen-shortcuts.sh`). Everything between the `BINDINGS` markers
> is machine-written — to change it, edit the registry (`INPUT/INPUT.BM` → `INPUTS_register_all`),
> not this file. The curated sections above stay hand-authored (the "augment" model).

<!-- BINDINGS:START -->
<!-- GENERATED by `DRAW --dump-shortcuts` from the input registry (227 bindings).
     Do not hand-edit between the BINDINGS markers in SHORTCUTS.md; edit the registry (INPUTS_register_all) instead. -->

### Global / Application

| Trigger | Action | Dispatch |
|---------|--------|----------|
| `Ctrl+F11` | Ctrl+F11 — Toggle menubar | central |
| `Ctrl+Alt+K` | Cancel AI generation | central |
| `Ctrl+,` | Settings dialog | legacy |
| `F12` | F12 dev debug dump (dispatched=TRUE proof) | central |
| `Ctrl+Alt+O` | Toggle CRT Effect (Ctrl+Alt+O) | legacy |

### File

| Trigger | Action | Dispatch |
|---------|--------|----------|
| `Ctrl+Q` | Quit | central |
| `Ctrl+N` | New canvas | central |
| `Ctrl+O` | Open Image | central |
| `Ctrl+S` | Save Image | central |
| `Ctrl+Shift+S` | Save As | central |
| `Ctrl+Alt+Shift+S` | Export Selection | central |
| `Ctrl+Shift+Q` | Export QB64 Project | central |
| `Alt+O` | Open Project (Alt+O) | legacy |
| `Alt+X` | Exit (Alt+X) | legacy |

### Edit / History / Clipboard

| Trigger | Action | Dispatch |
|---------|--------|----------|
| `H` | Flip horizontal | central |
| `Ctrl+Shift+H` | Flip vertical | central |
| `Home` | Flip horizontal (Home) | central |
| `End` | Flip vertical (End) | central |
| `PgUp` | Scale 2x (PgUp) | central |
| `PgDn` | Scale -50% (PgDn) | central |
| `Delete` | DEL — Clear selection | central |
| `Backspace` | Backspace — Fill with FG | central |
| `Shift+Backspace` | Shift+Backspace — Fill with BG | central |
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
| `F4` | F4 — Toggle preview window | central |
| `F5` | F5 — Toggle edit bar | central |
| `Shift+F5` | Shift+F5 — Toggle adv bar | central |
| `Ctrl+Shift+F5` | Ctrl+Shift+F5 — Reload theme | central |
| `F10` | F10 — toggle status bar | central |
| `F11` | F11 — toggle all UI | central |
| `Tab` | Tab — toggle toolbar | central |
| `Ctrl+L` | Toggle Layer Panel | central |
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
| `F1` | F1 — Drawer brush mode | central |
| `F2` | F2 — Drawer gradient mode | central |
| `F3` | F3 — Drawer pattern mode | central |
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
| `F7` | F7 — Symmetry cycle | central |
| `F8` | F8 — Fill Adjust toggle | central |
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
| `F6` | F6 — Pixel perfect toggle | central |
| `\` | \ Toggle brush shape | central |
| `|` | | (Shift+\) Toggle brush shape | central |
| `Ctrl+B` | Capture/Clear Custom Brush | central |
| `[` | Brush size - | central |
| `]` | Brush size + | central |

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
| `Wheel down` | Canvas: Wheel down — zoom in | legacy |
| `Wheel up` | Canvas: Wheel up — zoom out | legacy |
| `Ctrl+Wheel up` | Canvas: Ctrl+Wheel up — brush size increase | legacy |
| `Ctrl+Wheel down` | Canvas: Ctrl+Wheel down — brush size decrease | legacy |
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
| `Wheel up` | Layer panel: wheel up (scroll list) | legacy |
| `Wheel down` | Layer panel: wheel down (scroll list) | legacy |
| `Move` | Layer panel: cursor move (row tracking) | legacy |
| `L-Click` | Palette: left-click (set FG color) | legacy |
| `R-Click` | Palette: right-click (set BG color) | legacy |
| `Dbl L-Click` | Palette: double-click (edit color) | legacy |
| `Hover enter` | Palette: hover enter | legacy |
| `Hover leave` | Palette: hover leave | legacy |
| `Wheel up` | Palette: wheel up (next palette) | legacy |
| `Wheel down` | Palette: wheel down (prev palette) | legacy |
| `L-Click` | Edit bar: click (invoke action) | legacy |
| `Hover enter` | Edit bar: hover (tooltip) | legacy |
| `L-Click` | Adv bar: click (invoke action) | legacy |
| `Hover enter` | Adv bar: hover (tooltip) | legacy |
| `L-Click` | Status bar: click (e.g. toggle indicator) | legacy |
| `L-Click` | Drawer: click (select bin) | legacy |
| `Dbl L-Click` | Drawer: double-click | legacy |
| `R-Click` | Drawer: right-click (context) | legacy |
| `L-Drag` | Drawer: drag begin | legacy |
| `Wheel up` | Drawer: wheel up (page) | legacy |
| `Wheel down` | Drawer: wheel down (page) | legacy |
| `L-Click` | Organizer: click | legacy |
| `Wheel up` | Organizer: wheel up (cycle state) | legacy |
| `Wheel down` | Organizer: wheel down (cycle state) | legacy |
| `L-Click` | Preview: click (button) | legacy |
| `L-Drag` | Preview: drag begin (move/resize) | legacy |
| `L-Drag` | Preview: drag continue | legacy |
| `L-Drag` | Preview: drag end | legacy |
| `Wheel up` | Preview: wheel up | legacy |
| `Wheel down` | Preview: wheel down | legacy |
| `L-Click` | Color mixer: click | legacy |
| `L-Drag` | Color mixer: drag begin | legacy |
| `L-Click` | Browser: click | legacy |
| `Dbl L-Click` | Browser: double-click (open) | legacy |
| `L-Drag` | Browser: drag begin (move/resize) | legacy |
| `L-Click` | Charmap: click (select char) | legacy |
| `Dbl L-Click` | Charmap: double-click (insert) | legacy |
| `Wheel up` | Charmap: wheel up (page) | legacy |
| `Wheel down` | Charmap: wheel down (page) | legacy |
| `L-Click` | Subtool flyout: click (select sub-tool) | legacy |
| `Move` | Subtool flyout: cursor track | legacy |
| `L-Click` | Text bar: click (button or dropdown) | legacy |


<!-- BINDINGS:END -->

---

<!-- Reconciled against source extraction (agents over KEYBOARD.BM / MOUSE.BM / INPUTS_register_all /
     CMD_init / MENUBAR). Registry coverage + gap audit: PLANS/SHORTCUTS-INVENTORY.md.
     A handful of UNCERTAIN keycode/collision items are listed there for manual confirm in Phase 1.
     The "Generated binding index" section below is spliced by tools/gen-shortcuts.sh from --dump-shortcuts. -->
