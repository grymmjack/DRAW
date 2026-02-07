''
' DRAW - _ALL.BI
' =============================================================================
' Includes ALL code in sequence for BI files in one spot.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

' COMMON ----------------------------------------------------------------------
'$INCLUDE:'./_COMMON.BI'

' CORE ------------------------------------------------------------------------
'$INCLUDE:'./CORE/ERROR.BI'
'$INCLUDE:'./CORE/IMAGE.BI'

' CONFIG ----------------------------------------------------------------------
'$INCLUDE:'./CFG/CONFIG.BI'
'$INCLUDE:'./CFG/CONFIG-THEME.BI'
'$INCLUDE:'./CFG/CONFIG-KEYBOARD.BI'
'$INCLUDE:'./CFG/CONFIG-MOUSE.BI'
'$INCLUDE:'./CFG/CONFIG-STICK.BI'
'$INCLUDE:'./CFG/BINDINGS-KEYBOARD.BI'
'$INCLUDE:'./CFG/BINDINGS-MOUSE.BI'
'$INCLUDE:'./CFG/BINDINGS-STICK.BI'

' GUI -------------------------------------------------------------------------
'$INCLUDE:'./GUI/PALETTE.BI'
'$INCLUDE:'./GUI/PALETTE-LOADER.BI'
'$INCLUDE:'./GUI/PALETTE-STRIP.BI'
'$INCLUDE:'./GUI/GUI.BI'
'$INCLUDE:'./GUI/BRUSHES.BI'
'$INCLUDE:'./GUI/CROSSHAIR.BI'
'$INCLUDE:'./GUI/GRID.BI'
'$INCLUDE:'./GUI/HELP.BI'
'$INCLUDE:'./GUI/LAYERS.BI'
'$INCLUDE:'./GUI/PALETTE-PICKER.BI'
'$INCLUDE:'./GUI/PICKER.BI'
'$INCLUDE:'./GUI/CURSOR.BI'
'$INCLUDE:'./GUI/POINTER.BI'
'$INCLUDE:'./GUI/STATUS.BI'
'$INCLUDE:'./GUI/TOOLBAR.BI'
'$INCLUDE:'./GUI/TRANSPARENCY.BI'
'$INCLUDE:'./GUI/COMMAND.BI'

' INPUT -----------------------------------------------------------------------
'$INCLUDE:'./INPUT/KEYBOARD.BI'
'$INCLUDE:'./INPUT/MOUSE.BI'
'$INCLUDE:'./INPUT/STICK.BI'
'$INCLUDE:'./INPUT/FILE-BMP.BI'
'$INCLUDE:'./INPUT/FILE-BLOAD.BI'
'$INCLUDE:'./INPUT/FILE-PAL.BI'
'$INCLUDE:'./INPUT/API-LOSPEC.BI'

' OUTPUT ----------------------------------------------------------------------
'$INCLUDE:'./OUTPUT/SCREEN.BI'
'$INCLUDE:'./OUTPUT/FILE-BAS.BI'
'$INCLUDE:'./OUTPUT/FILE-BMP.BI'
'$INCLUDE:'./OUTPUT/FILE-BSAVE.BI'

' QB64_GJ_LIB -----------------------------------------------------------------
'$INCLUDE:'includes/QB64_GJ_LIB/_GJ_LIB.BI'

' TOOLS -----------------------------------------------------------------------
'$INCLUDE:'./TOOLS/BRUSH.BI'
'$INCLUDE:'./TOOLS/BRUSH-DITHERS.BI'
'$INCLUDE:'./TOOLS/BRUSH-FILL.BI'
'$INCLUDE:'./TOOLS/BRUSH-FX-OUTLINE.BI'
'$INCLUDE:'./TOOLS/BRUSH-SIZE.BI'
'$INCLUDE:'./TOOLS/BRUSH-TEXT.BI'
'$INCLUDE:'./TOOLS/COLOR-BG.BI'
'$INCLUDE:'./TOOLS/COLOR-FG.BI'
'$INCLUDE:'./TOOLS/COLOR-INVERT.BI'
'$INCLUDE:'./TOOLS/CUSTOM-BRUSH.BI'
'$INCLUDE:'./TOOLS/DOT.BI'
'$INCLUDE:'./TOOLS/ELLIPSE.BI'
'$INCLUDE:'./TOOLS/FILL.BI'
'$INCLUDE:'./TOOLS/LINE.BI'
'$INCLUDE:'./TOOLS/LOAD.BI'
'$INCLUDE:'./TOOLS/IMAGE-IMPORT.BI'
'$INCLUDE:'./TOOLS/MARQUEE.BI'
'$INCLUDE:'./TOOLS/UNDO.BI'
'$INCLUDE:'./TOOLS/WORKSPACE-UNDO.BI'
'$INCLUDE:'./TOOLS/MOVE.BI'
'$INCLUDE:'./TOOLS/MOVE-NUDGE.BI'
'$INCLUDE:'./TOOLS/PAN.BI'
'$INCLUDE:'./TOOLS/PICKER.BI'
'$INCLUDE:'./TOOLS/POLY-FILL.BI'
'$INCLUDE:'./TOOLS/POLY-LINE.BI'
'$INCLUDE:'./TOOLS/RAY.BI'
'$INCLUDE:'./TOOLS/RECT.BI'
'$INCLUDE:'./TOOLS/SAVE.BI'
'$INCLUDE:'./TOOLS/DRW.BI'
'$INCLUDE:'./TOOLS/NULL.BI'
'$INCLUDE:'./TOOLS/SELECTION.BI'
'$INCLUDE:'./TOOLS/SYMMETRY.BI'
'$INCLUDE:'./TOOLS/TEXT.BI'
'$INCLUDE:'./TOOLS/ZOOM.BI'

' THEME -----------------------------------------------------------------------
'$INCLUDE:'./ASSETS/THEMES/DEFAULT/THEME.BI'

' PALETTES --------------------------------------------------------------------
' Palettes are loaded dynamically from .GPL files via PALETTE-LOADER.BM

