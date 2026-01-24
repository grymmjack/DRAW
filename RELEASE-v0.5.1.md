# DRAW v0.5.1 Release Notes
**Date:** January 24, 2026

## Summary
Major feature release with significant improvements to text tools, drawing precision, move/transform capabilities, and a new pixel grid for precise pixel art work at high zoom levels.

---

## New Features

### 🔤 Text Tool Enhancements
- **Tiny5 Pixel Font Support** - Added bundled Tiny5-Regular.ttf font optimized for pixel art
- **Accurate Cursor Positioning** - Fixed cursor positioning using `_PRINTWIDTH` for precise character placement
- **Export Selection** - New ability to export selected regions

### 🎯 Pixel Grid Overlay
- **New Pixel Grid** - Fine grid showing individual pixel boundaries at 400%+ zoom
- **Toggle with `SHIFT+'`** - Independent toggle from regular grid
- **Theme Customizable** - Configure grid color in theme files (`THEME.PIXEL_GRID_color1~&`)
- **Works with Regular Grid** - Both grids can display simultaneously

### 🖱️ Move Tool Improvements
- **Keyboard Controls** - Arrow keys for nudging (1px), Shift+Arrows (10px)
- **Resize with Ctrl+Arrows** - Scale selections with keyboard
- **Flip Selections** - `H` for horizontal flip, `V` for vertical flip
- **Alt Clone Mode** - Hold Alt while moving to clone instead of cut
- **Real-time Preview Buffer** - Smooth visual feedback during transformations

### ✏️ Pixel Perfect Drawing Mode
- **Toggle with `F6`** - Removes L-shaped corners for cleaner freehand strokes
- **Smoother Lines** - Better results for pixel art brush strokes

### 💾 File Handling Improvements
- **Quick Save** - `Ctrl+S` saves to current filename without dialog
- **Single-Press Detection** - Prevents accidental double-triggers on open/save
- **Filename Tracking** - Remembers current file for quick save operations

### 🗑️ Clear Canvas
- **Delete Key** - Clear canvas with confirmation prompt
- **Backspace Key** - Clear canvas instantly (no prompt)

---

## Improvements

### Drawing Tool Previews (Zoomed)
- **Line Tool** - Preview now correctly displays at zoomed coordinates
- **Rectangle Tool** - Zoomed preview while dragging
- **Ellipse Tool** - Zoomed preview while dragging  
- **Polygon Tool** - Zoomed preview for all polygon operations

### Grid System
- **Regular Grid** - Now stays visible at high zoom (user-controlled toggle)
- **Grid Documentation** - Updated cheatsheet and README with all grid controls

### Mouse Coordinate Precision
- **INT() Rounding** - Added explicit integer rounding for pixel-perfect coordinate mapping at high zoom levels

### Dynamic Drawing Colors
- **Left Click** - Uses foreground color
- **Right Click** - Uses background color (for sampling and drawing)

---

## Files Changed (30 files)

### New Files
- `ASSETS/FONTS/Tiny5-Regular.ttf` - Pixel-optimized font

### Modified Core Files
| File | Changes |
|------|---------|
| `DRAW.BAS` | Font initialization, cleanup |
| `OUTPUT/SCREEN.BM` | Pixel grid rendering, zoomed tool previews |
| `INPUT/KEYBOARD.BM` | Text tool fixes, pixel grid toggle, clear canvas |
| `INPUT/MOUSE.BM` | Coordinate precision, dynamic colors |
| `GUI/GRID.BI/BM` | Pixel grid type and functions |
| `GUI/STATUS.BM` | Export selection support |
| `GUI/TOOLBAR.BM` | Enhanced toolbar functionality |

### Tool Files
| File | Changes |
|------|---------|
| `TOOLS/TEXT.BI/BM` | Tiny5 support, cursor positioning |
| `TOOLS/MOVE.BI/BM` | Keyboard controls, flip, clone mode |
| `TOOLS/BRUSH.BM` | Pixel perfect mode |
| `TOOLS/BRUSH-SIZE.BI/BM` | Brush adjustments |
| `TOOLS/SAVE.BM` | Quick save, filename tracking |
| `TOOLS/MARQUEE.BM` | Selection improvements |
| `TOOLS/FILL.BM` | Color assignment fix |

### Configuration
| File | Changes |
|------|---------|
| `CFG/CONFIG-THEME.BI` | Pixel grid color definitions |
| `ASSETS/THEMES/DEFAULT/THEME.BI` | Pixel grid color values |
| `CFG/BINDINGS-KEYBOARD.BI` | New key bindings |

### Documentation
| File | Changes |
|------|---------|
| `README.MD` | Grid controls, pixel grid feature |
| `CHEATSHEET.md` | Full keyboard reference update |

---

## Keyboard Reference (New/Changed)

| Key | Function |
|-----|----------|
| `SHIFT+'` | Toggle pixel grid (400%+ zoom) |
| `F6` | Toggle pixel perfect drawing mode |
| `Delete` | Clear canvas (with prompt) |
| `Backspace` | Clear canvas (instant) |
| `Ctrl+S` | Quick save to current file |
| `H` | Flip selection horizontally (Move tool) |
| `V` | Flip selection vertically (Move tool) |
| `Alt+Drag` | Clone selection (Move tool) |
| `Arrow Keys` | Nudge selection 1px (Move tool) |
| `Shift+Arrows` | Nudge selection 10px (Move tool) |
| `Ctrl+Arrows` | Resize selection (Move tool) |

---

## Stats
- **Commits:** 11 (since v0.5.0)
- **Lines Changed:** +1,209 / -116
- **Files Modified:** 30

---

## Building

```bash
qb64pe -w -x -o DRAW.run DRAW.BAS
```

**Requires:** QB64PE v3.12+
