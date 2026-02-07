# DRAW v0.7.0 Release Notes

**Release Date:** February 7, 2026
**Previous Release:** v0.6.8 (February 4, 2026)

---

## Highlights

This release brings a major visual overhaul with PNG-based icons and cursors, plus new
drawing tools and an expanded toolbar. The entire icon system is now themeable.

---

## New Features

### Spray Paint Tool
- New spray paint tool activated with `K` key or toolbar button
- Sprays random dots within a circular area using the current brush size
- Density scales proportionally with radius (larger brush = more dots per frame)
- Left-click sprays with foreground color, right-click with background color
- Circle + dot pattern preview shown when not actively spraying
- Full symmetry support across all modes (vertical, cross, asterisk)
- Respects active marquee/wand selections as clipping mask
- Works with dither patterns

### Pan (Hand) Tool
- Dedicated pan tool mode accessible via toolbar button
- Left-click and drag to pan the canvas without holding spacebar
- Hand cursor indicates pan mode
- Spacebar+drag and middle-click drag still work from any tool

### Brush vs. Dot Tool Separation
- **Brush (B)**: Continuous freehand painting — click and drag to paint strokes
- **Dot (D)**: Single-pixel stamp — click to place one dot, no drag painting
- Previously Brush and Dot shared the same drag behavior
- Dot now only stamps on initial click, making it ideal for precise pixel placement

### CTRL+Click Layer Selection
- **CTRL+Left-Click** on a layer row in the layer panel creates a selection from all non-transparent pixels
- Generates a per-pixel selection mask (alpha > 0 = selected)
- Automatically computes bounding box for the selection
- Switches to the Marquee tool with the new selection active
- Replaces any existing marquee/wand selection

### Expanded Toolbar (14 → 20 buttons)
- Toolbar expanded from 7 rows to 10 rows (2 columns × 10 rows)
- **6 new toolbar buttons**: Brush, Hand (Pan), Picker, Spray, Crop, Help
- Brush tool has its own dedicated toolbar button (row 2, right column)
- Picker tool now has its own toolbar button (previously keyboard-only via `I`)
- Help button opens the command palette (same as `?` key)
- Crop button added as placeholder for future canvas crop/resize feature

### New Toolbar Layout

| Row | Left | Right |
|-----|------|-------|
| 1 | Marquee | Dot |
| 2 | Move | **Brush** |
| 3 | Fill | **Picker** |
| 4 | **Spray** | Line |
| 5 | Text | Polygon |
| 6 | Rect | Ellipse |
| 7 | Rect Filled | Ellipse Filled |
| 8 | Save | Open |
| 9 | **Crop** | QB64 Code |
| 10 | **Hand/Pan** | **Help** |

---

## Visual Overhaul

### PNG Cursor System
- Complete cursor system rewrite replacing procedural drawing with PNG-based cursors
- 13 cursor types: null (arrow), brush, dropper, fill, hand, marquee, move, resize-corner, resize-horizontal, resize-vertical, spray, wand, zoom
- Theme-configurable hotspots and overlay colors defined in `THEME.BI`
- Proper alpha transparency pipeline using dedicated `SCRN.CURSOR&` layer with `_BLEND`
- Resize cursors for move/marquee tool handles (corner, horizontal, vertical)
- Cursor flipping support for directional handle cursors
- Graceful fallback to procedural cursors when PNG files are missing

### Layer Panel Icons
- Layer panel buttons and indicators now use PNG icons instead of text characters
- Visibility toggle: eye icon (on/off states)
- Lock indicator: lock icon (on/off states)
- Bottom action buttons: up, down, merge, delete, add — all with PNG icons
- Automatic text fallback when icon PNGs are not found
- Icons loaded from current theme directory

### Theme-Based Icon Loading
- All toolbar, cursor, and layer panel icons load from `ASSETS/THEMES/<THEME>/`
- Removed hardcoded `DEFAULT` theme path — icons resolve dynamically from `CFG.THEME$`
- Enables full theme customization of all visual elements

---

## Bug Fixes

### Picker Toolbar Button
- Fixed: Clicking the Picker toolbar button did not activate color sampling
- Root cause: `PICKER.ACTIVE%` was never set to TRUE when selecting via toolbar click
- Fix: Added `PICKER_activate` / `PICKER_deactivate` calls in toolbar click handler

### Layer Panel Drag Bug
- Fixed: Clicking a layer row then trying to draw on the canvas would show the layer stack
  moving instead of allowing canvas interaction
- Root cause: `dragPending%` flag was not cleared when mouse released without exceeding
  the drag threshold
- Fix: Added `LAYER_PANEL_drag_cancel` call before early exit in `LAYER_PANEL_handle_drop`

### Marquee Handle Visibility
- Adjusted marquee handle size scaling to a minimum of 2px for better visibility
- Increased hit area for marquee resize handles to improve usability

---

## New Assets

### Theme Icons (ASSETS/THEMES/DEFAULT/)
- 5 new toolbar button PNGs: `hand.png`, `picker.png`, `spray.png`, `crop.png`, `help.png`
- 4 layer panel icon PNGs: visibility on/off, lock on/off
- 13 cursor PNGs in `CURSORS/` subdirectory
- Various additional icons for future features: assistant icons, pattern icons, brush size, zoom, palette navigation

### Design Files (PLANS/)
- Updated cursor sprite sheets (Aseprite, PSD, GIF formats)

---

## New Files

| File | Purpose |
|------|---------|
| `TOOLS/SPRAY.BI` | Spray tool type definition and state |
| `TOOLS/SPRAY.BM` | Spray tool implementation |
| `TOOLS/CROP.BI` | Crop tool type definition (stub) |
| `TOOLS/CROP.BM` | Crop tool reset (stub) |
| `GUI/CURSOR.BI` | PNG cursor system declarations and constants |
| `GUI/CURSOR.BM` | PNG cursor loading, rendering, and cleanup |
| `ASSETS/THEMES/DEFAULT/THEME.BI` | Theme-specific cursor hotspots and overlay config |

## Modified Files

| File | Changes |
|------|---------|
| `_COMMON.BI` | Added `TOOL_PAN`, `TOOL_SPRAY`, `TOOL_CROP` constants |
| `GUI/GUI.BI` | Added `TOOL_HELP` constant, expanded `GUI_TB` array to 20 (0-19) |
| `GUI/TOOLBAR.BI` | 6 new button constants (including `TB_BRUSH`), 20-position layout arrays, new button properties |
| `GUI/TOOLBAR.BM` | Updated all loops for 20 buttons, blank slot skip logic, special click handlers for Help/Crop/Pan, Picker activate/deactivate fix |
| `GUI/POINTER.BM` | PNG cursor system integration, tool-specific cursor mappings for Pan/Spray/Crop, spray brush preview (circle + dot pattern) |
| `GUI/STATUS.BM` | Added status bar labels for Pan, Spray, Crop, Help tools |
| `GUI/LAYERS.BI` | Added 9 icon handle fields to `LAYER_PANEL_OBJ`, `LAYER_select_non_transparent` declaration |
| `GUI/LAYERS.BM` | PNG icon loading/cleanup, rendering with text fallback, CTRL+Click non-transparent pixel selection |
| `INPUT/KEYBOARD.BM` | Added `K` = Spray shortcut, `SPRAY_reset` in all tool switch blocks |
| `INPUT/MOUSE.BM` | Spray tool mouse handling, pan tool LMB panning, `TOOL_SPRAY` in `isDrawingTool%`, Brush/Dot behavior split (DOT stamp-only) |
| `OUTPUT/SCREEN.BM` | Toolbar render range 0-19, cursor layer alpha compositing |
| `TOOLS/PAN.BI` | Added `PAN_OBJ` type |
| `TOOLS/PAN.BM` | Added `PAN_reset` implementation |
| `_ALL.BI` / `_ALL.BM` | Added includes for Spray, Crop, and Cursor modules |
| `DRAW.BAS` | Cursor and layer icon initialization/cleanup calls |

---

## Keyboard Shortcut Changes

| Key | Action | Status |
|-----|--------|--------|
| `K` | Spray paint tool | **New** |

All existing keyboard shortcuts remain unchanged.

---

## Breaking Changes

None. All existing functionality, tools, and keyboard shortcuts are preserved.

---

## Building

```bash
qb64pe -w -x -o DRAW.run DRAW.BAS
```

Requires QB64-PE v3.12 or later.
