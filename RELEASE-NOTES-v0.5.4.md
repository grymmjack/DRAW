# DRAW v0.5.4 Release Notes

**Release Date:** January 24, 2026

## ✨ New Features

### Image Import Tool (Oversized Images)
A powerful new interactive image placement system for loading images larger than your canvas:

- **Interactive Placement**: Load oversized images and draw a marquee to define exactly where to place them
- **Real-time Zoom**: Mouse wheel zooms into/out of the source image for precise cropping
- **Pan & Crop**: Navigate within the image using Alt+Arrow keys or right-click drag
- **Keyboard Controls**: Full marquee-style keyboard support:
  - Arrow keys: Move destination box (1px, or 10px with Shift)
  - Ctrl+Arrows: Resize destination box
  - Alt+Arrows: Pan within image crop
  - Enter: Apply import
  - Escape: Cancel import
- **Visual Feedback**: Semi-transparent overlay with marching ants border and resize handles
- **Non-destructive**: Preview changes before committing to canvas

**Workflow:** Load an image larger than canvas → Draw placement marquee (or Enter for full canvas) → Zoom/pan/adjust → Enter to apply

## 🔧 Improvements

### Pixel Grid Rendering
- Added alpha transparency to pixel grid lines for better visibility without obscuring artwork
- Improved drawing logic at high zoom levels for cleaner grid rendering

## 📚 Documentation

- Updated CHEATSHEET.md with comprehensive Image Import controls and workflow tips

## 🗂️ Files Changed

### New Files
- `TOOLS/IMAGE-IMPORT.BI` - Image import type definitions and declarations
- `TOOLS/IMAGE-IMPORT.BM` - Full implementation (~800 lines)

### Modified Files
- `_ALL.BI` / `_ALL.BM` - Added image import includes
- `TOOLS/LOAD.BM` - Integration with image import for oversized images
- `INPUT/KEYBOARD.BM` - Added import mode keyboard handling (Enter/Escape/Arrows)
- `INPUT/MOUSE.BM` - Added import mode mouse handling (placement, pan, zoom)
- `OUTPUT/SCREEN.BM` - Added IMAGE_IMPORT_draw call for preview rendering
- `CHEATSHEET.md` - Added Image Import documentation section

---

**Full Changelog:** [v0.5.3...v0.5.4](https://github.com/grymmjack/DRAW/compare/v0.5.3...v0.5.4)
