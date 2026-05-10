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

The full, authoritative list is in [`CHEATSHEET.md`](../../CHEATSHEET.md) at the repository root. Below are the essentials — what you'll use thousands of times a session.

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

For everything else, use the Command Palette or read the chapter where the feature is introduced.

---

➡️ Next: [Chapter 17 — Undo, Redo & History](17-history.md)
