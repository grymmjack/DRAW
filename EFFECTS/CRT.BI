''
' DRAW - EFFECTS/CRT.BI
' =============================================================================
' CRT overlay effect — scanlines, phosphor mask, vignette, optional tint,
' optional flicker and rolling bar.
'
' Renders to screen 0 AFTER the canvas blit, BEFORE floating panels (color
' mixer, browser, tooltip). Never touches SCRN.CANVAS&, layer buffers, scene
' cache, or any persisted state. Pure presentation lens.
'
' Two-level cache:
'   - CRT.overlay&  : full-window pre-baked composite (scanlines + phosphor +
'                     vignette + tint). Rebuilt only when window size changes
'                     or CRT.dirty% is set (param change). Per-frame cost is
'                     one _PUTIMAGE.
'   - Animated layers (flicker, rolling bar) render fresh each frame and
'     force FRAME_IDLE% = FALSE while active.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

TYPE CRT_OBJ
    overlay      AS LONG    ' Pre-baked composite at viewport size (alpha overlay)
    lastW        AS LONG
    lastH        AS LONG
    lastIntensity AS INTEGER
    lastTint     AS INTEGER
    lastScanlines AS INTEGER
    lastPhosphor AS INTEGER
    lastVignette AS INTEGER
    lastThickness AS INTEGER
    lastGap      AS INTEGER
    dirty        AS INTEGER ' TRUE = force rebake on next render
END TYPE
DIM SHARED CRT AS CRT_OBJ

CRT.overlay&       = 0
CRT.lastW&         = 0
CRT.lastH&         = 0
CRT.lastIntensity% = -1
CRT.lastTint%      = -1
CRT.lastScanlines% = -1
CRT.lastPhosphor%  = -1
CRT.lastVignette%  = -1
CRT.lastThickness% = -1
CRT.lastGap%       = -1
CRT.dirty%         = TRUE
