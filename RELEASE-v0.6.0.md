# DRAW v0.6.0 Release Notes

**Release Date:** January 31, 2026  
**Previous Version:** v0.5.5

## 🎨 Major New Features

### Custom Font Support for Text Tool
- **Middle-click text tool icon** to load custom TrueType (.ttf) or OpenType (.otf) fonts from disk
- **CTRL-T** activates text tool with loaded custom font
- Fonts render with:
  - ✨ Natural kerning pairs and proportional spacing
  - 🎯 Built-in font hinting for crisp rendering
  - 🔲 No anti-aliasing (DONTBLEND) for pixel-perfect output
- Automatic multi-size loading (tries 16px → 12px → 8px → 20px until success)
- Custom fonts persist across tool resets
- Standard `T` key continues using VGA font, `Shift+T` uses Tiny5 font

### Dither Pattern System
- **10 dither patterns** (NumPad 0-9) for sophisticated texture effects
- Works with: Brush, Dot, Fill, and filled shapes (Rectangle, Ellipse, Polygon)
- Patterns tile seamlessly across entire canvas using global coordinates
- Pattern preview in brush cursor and status bar indicator
- Patterns include:
  - **0:** Solid (no dithering)
  - **1:** Light Dots (6% fill)
  - **2:** Dots (12% fill)
  - **3:** Checkerboard (50% fill)
  - **4:** Medium Dots (25% fill)
  - **5:** Grid (2x2 boxes)
  - **6:** Horizontal lines
  - **7:** Vertical lines
  - **8:** Diagonal \ lines
  - **9:** Checker 2x2 blocks

## 🔧 Enhancements

### Custom Brush Improvements
- Enhanced custom brush controls documentation in cheatsheet
- Clear workflow for capture, flip, scale operations
- Export functionality with timestamp-based PNG filenames

### UI/UX Improvements
- Pattern name display in status bar
- NumLock indicator in status bar
- Enhanced brush preview showing active dither pattern
- Better pointer feedback for pattern selection

### Input Handling
- Robust NumPad key detection (works with NumLock ON or OFF)
- Improved keyboard handling for custom font activation
- Better CTRL+T keyboard shortcut implementation with debouncing

## 🐛 Bug Fixes & Code Quality

### Font System Fixes (Critical)
- **Fixed font handle validation**: Changed from negative (`< -1`) to positive (`> 0`) checks
  - QB64PE `_LOADFONT` returns POSITIVE handles for fonts, not negative like images
- **Fixed font loading retry logic**: Changed from `>= 0` to `<= 0` in retry conditions
  - Previously successful fonts were being overwritten by failed attempts
- **Fixed old_font initialization**: Now initialized BEFORE conditional blocks
  - Prevents "Invalid handle" runtime crashes
- **Fixed duplicate validation code**: Corrected right column button handler
- All font switching operations now properly save/restore font state

### Dither Pattern Implementation
- Seamless pattern tiling using global canvas coordinates
- Proper integration with filled shape drawing algorithms
- Consistent pattern behavior across all supported tools

## 📝 Documentation Updates

### CHEATSHEET.md Additions
- Complete custom font loading instructions
- Comprehensive dither pattern reference table
- Custom brush controls and workflow
- Pattern selection shortcuts
- NumLock indicator documentation

## 📊 Statistics

- **15 files changed**
- **723 insertions**
- **57 deletions**
- **5 commits** since v0.5.5

## 🔄 Technical Details

### Modified Files
- `DRAW.BAS` - Font cleanup on exit
- `GUI/TOOLBAR.BM` - Middle-click font loading handler
- `GUI/STATUS.BM` - Pattern and NumLock indicators
- `GUI/POINTER.BM` - Dither pattern preview in cursor
- `INPUT/KEYBOARD.BM` - Pattern selection, CTRL-T handler
- `INPUT/KEYBOARD.BI` - Custom font key tracking
- `INPUT/MOUSE.BM` - Middle-click detection
- `TOOLS/BRUSH.BM` - Dither pattern integration
- `TOOLS/BRUSH-DITHERS.BM` - Pattern drawing implementation
- `TOOLS/BRUSH-DITHERS.BI` - Pattern definitions
- `TOOLS/TEXT.BM` - Custom font rendering
- `TOOLS/TEXT.BI` - Custom font state fields
- `TOOLS/ELLIPSE.BM` - Dither pattern support
- `TOOLS/POLY-FILL.BM` - Dither pattern support
- `CHEATSHEET.md` - Comprehensive documentation updates

## 🎯 Breaking Changes

**None** - All changes are backwards compatible with existing workflows.

## 🚀 Upgrade Notes

1. Existing tools and workflows continue to work unchanged
2. Custom fonts are an optional feature accessed via middle-click
3. Dither patterns default to "Solid" (pattern 0) for existing behavior
4. No configuration file changes required

## 🙏 Acknowledgments

Special thanks to the QB64PE community for the robust font handling implementation and the ongoing development of the QB64PE compiler.

---

**Full Changelog:** https://github.com/grymmjack/DRAW/compare/v0.5.5...v0.6.0
