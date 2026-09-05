# Ch. 16  ⌨️ Keyboard Shortcuts & Command Palette

> **What you'll learn:** How to find any command instantly via the Command Palette, and the most important shortcuts grouped by activity.

---

## Command Palette — 200+ Commands at Your Fingertips

> 🎯 **Goal:** Access any command instantly.

Press `?` to open the **Command Palette**. Start typing — DRAW does fuzzy-matching across command names so you can type `flip` to find both *Flip Horizontal* and *Flip Canvas Vertical*. Each match shows its hotkey on the right; arrow keys to highlight, Enter to run.

Use `Help → Cheat Sheet` for **Quick Reference Mode**, which lists every command in the application without filtering — handy for learning what's available.

The Palette is grouped into categories that match the menus:

- Tools
- File
- Edit
- View
- Color
- Brush
- Layer
- Canvas
- Assist
- Grid
- Symmetry
- Select
- Help
- Image
- Audio

<div class="page-break"></div>

## Keyboard Shortcuts Cheat Sheet

> 🎯 **Goal:** Memorize the essential shortcuts.

The full, authoritative list is in [`SHORTCUTS.md`](../../SHORTCUTS.md) at the repository root — generated directly from the input registry, so it never drifts from the app, and it covers **both keyboard and mouse**. Below are the essentials — what you'll use thousands of times a session.

### Tool selection (single key)

| Key | Tool |
| :---: | --- |
| `B` | Brush |
| `D` | Dot |
| `L` | Line |
| `R` | Rectangle (`Shift+R` filled) |
| `C` | Ellipse (`Shift+C` filled) |
| `P` | Polygon (`Shift+P` filled) |
| `F` | Fill |
| `K` | Spray |
| `I` | Picker |
| `E` | Eraser |
| `M` | Marquee |
| `W` | Wand |
| `V` | Move |
| `Z` | Zoom |
| `T` | Text |
| `Q` | Bezier |
| (Toolbar) | Smart Shapes (Polygon, Pie/Donut, Rounded Rect, Tab, Pill, Pac-Man, 3D Dice, Bevel Rect, Arrow, 3D Text) |

<div class="page-break"></div>

### Essential combos

| Combo | Action |
| --- | --- |
| `Ctrl+S` / `Ctrl+O` / `Ctrl+N` | Save / Open / New |
| `Ctrl+Z` / `Ctrl+Y` | Undo / Redo |
| `Ctrl+C` / `Ctrl+X` / `Ctrl+V` | Copy / Cut / Paste |
| `Ctrl+A` / `Ctrl+D` / `Ctrl+E` | Select All / Deselect / Clear |
| `Ctrl+L` | Toggle Layer Panel |
| `[` / `]` | Brush Size − / + |
| `\` | Brush Shape (circle ↔ square) |
| `X` | Swap FG / BG |
| `0`–`9` | Paint Opacity 100% / 10–90% |
| `'` `;` `.` `,` | Grid: toggle / snap / size+ / size− |
| `/` | Toggle grid alignment (Corner ↔ Center) |
| `G+Arrow` | Adjust grid width/height independently |
| `}` / `{` | Music: next / previous track |
| `F4`–`F9`, `F11` | Panel and mode toggles |
| `Tab` | Toggle Toolbar |
| `?` | Command Palette |

### Smart Shapes & 3D Tool Modifiers

| Key | Function |
|-----|----------|
| `Up/Down/Left/Right` | Adjust shape parameters (segments, bevel, mouth, Z depth, etc.) |
| `Mouse Wheel` | Adjust primary parameter |
| `Shift` | Constrain aspect ratio |
| `Left-click drag` | Wireframe mode (FG color) |
| `Right-click drag` | Solid mode (BG color fill, FG color wireframe) |
| `4`/`6`/`8`/`0`/`1`/`2` | Switch dice type (D4/D6/D8/D10/D12/D20) |
| `W`/`A`/`S`/`D`/`Q`/`E` | Orbit light |
| `=`/`-` | Change light elevation |
| `L`+`0..9` | Light intensity presets |

### Bezier Tool

| Key / Action | Function |
|--------------|----------|
| `Q` | Activate Bezier tool |
| Click | Drop corner anchor |
| Click+drag | Drop smooth anchor, shape handle |
| `H` | Toggle handle visualisation |
| `Backspace` | Remove last anchor |
| `Enter` | Commit curve |
| `Escape` | Cancel |

### Line Tool — End Caps

| Key | Function |
|-----|----------|
| `s` | Cycle start cap (while dragging) |
| `e` | Cycle end cap (while dragging) |

## Hold-Key Combos (Non-Modifier)

The following combos require holding a non-modifier key (not Ctrl/Alt/Shift) and clicking, pressing, or dragging another input. These are distinct from standard modifier shortcuts and are easy to miss!

| Hold Key | + Action | Effect |
|----------|----------|--------|
| `F`      | Left Click | Global Fill — flood-fills all visible non-locked layers with FG color (contiguous) |
| `F`      | Right Click | Global Fill — flood-fills all visible non-locked layers with BG color (contiguous) |
| `Shift+F`| Left Click | Replace-all Global Fill — replaces all matching pixels across all visible layers with FG color |
| `Shift+F`| Right Click | Replace-all Global Fill — replaces all matching pixels across all visible layers with BG color |
| `E`      | Click      | Flood Erase — erases contiguous same-color pixels to transparent (no selection step) |
| `W`      | Click      | Magic Wand — select from merged canvas (all visible layers) |
| `G`      | Arrow Key  | Resize grid width/height independently |
| `L`      | Digit (0-9) | Set Smart Shape 3D light intensity preset |
| `R`      | Click      | Picker — sample from reference image instead of visible layers |

> See also: Tool-specific sections for additional drag-time and context-sensitive combos (e.g., Smart Shapes, Line End Caps, etc.).

For everything else, use the Command Palette or read the chapter where the feature is introduced.

<div class="page-break"></div>

## Customize Controls — Rebind Anything (New in 2.1.0)

> 🎯 **Goal:** Make DRAW's controls match your muscle memory.

Every shortcut in DRAW is now **rebindable** — keyboard *and* mouse. Open **Edit → Customize Controls** (or search "Customize Controls" in the Command Palette).

**Rebinding a control**

1. Type in the **FIND** box to filter the list by command name.
2. Click **SET…** on a row to open the capture dialog.
3. Press the new key, click a **mouse button**, spin the **wheel**, or **tilt** the wheel left/right — whatever you press is captured. Toggle the Ctrl/Shift/Alt checkboxes to require modifiers.
4. If the input is already bound elsewhere, DRAW **warns and steals** it (the old binding is unbound). Click **OK** to apply — changes take effect immediately.

Rows you've changed from the factory default show a marker and a "= changed from default" legend. **RESET ALL** restores every control to the shipped defaults instantly.

**Mouse controls you can bind**

| Control | Default | Notes |
|---------|---------|-------|
| Vertical wheel | Zoom in/out (cursor-centered) | Rebindable; can be set to canvas pan or brush size |
| Wheel **tilt** (left/right) | Brush size − / + | Tilt right = bigger; rebind to **Pan Left/Right** for horizontal scroll |
| `Ctrl` + wheel | Brush size | |
| Thumb buttons (Back / Forward) | Undo / Redo | |
| Right-click (Zoom tool) | Zoom **out** | Left-click zooms in |
| Pan drag button | Middle / Space+drag | Rebindable |

There are also dedicated **Pan Up / Down / Left / Right** actions you can bind to the wheel or tilt for scroll-to-pan.

**Presets & export**

- **Load preset** applies a full keymap in one click: *Aseprite, Photoshop, GIMP, Krita, Illustrator, Procreate, MS Paint, Pro Motion, DeluxePaint*.
- **Export as…** writes your live keymap (including overrides) to **Markdown, HTML, or PDF**.
- Bindings persist across sessions in `DRAW.bindings`; the CLI flag `--load-preset <name>` applies one at launch.

---

➡️ Next: [Chapter 17 — Undo, Redo & History](17-history.md)
