''
' DRAW - GUI/FLOAT-PANEL.BI
' =============================================================================
' Shared look for the hand-drawn floating panels (3D Color Space, Pen
' Pressure): the themed UI font and the Color Mixer's geometry, so every
' floating panel shares one title bar, close box, chip, slider and checkbox
' style. Metrics are derived from the font height exactly as the Color Picker
' library does in CP_THEME_scale_geometry (CP-API.BM); colors are THEME.CP_*.
'
' Callers draw into their own native-resolution panel image, then blit it at
' the integer toolbar scale (USCALE.mixer) like COLORMIXER_render.
'
' Placement: every floating window (Color Mixer, Advanced Color Picker, 3D
' Color Space, Pen Pressure, Image Browser, Preview) runs its drag through
' FPANEL_place, which snaps its edges to the other floating windows and the
' work-area chrome and keeps it from overlapping another floating window.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

OPTION _EXPLICIT
OPTION _EXPLICITARRAY

CONST FPANEL_SNAP         = 6 ' snap distance (viewport px)
CONST FPANEL_FLOAT_COUNT  = 6 ' floating windows taking part in placement (FPANEL_float_region%)

TYPE FLOAT_PANEL_STYLE_OBJ
    ready     AS INTEGER ' TRUE once FPANEL_ensure has loaded the font
    font      AS LONG    ' themed UI font (THEME.GLOBAL_FONT_*); 0 = built-in 8x8
    fontH     AS INTEGER ' _FONTHEIGHT of the font (CP_STATE.fontH)
    fontW     AS INTEGER ' width of "M" (CP_STATE.fontW)
    titleH    AS INTEGER ' title bar height (CP titleBarH)
    rowH      AS INTEGER ' chip / button row height (CP posterizeRowH)
    sliderH   AS INTEGER ' slider track height (CP sliderH)
    gap       AS INTEGER ' gap between slider rows (CP sliderGap)
    section   AS INTEGER ' gap between sections (CP sectionGap)
    pad       AS INTEGER ' panel padding (CP padding)
    panelW    AS INTEGER ' shared native width of the color/pen panels (FPANEL_panel_w%)
END TYPE

DIM SHARED FPANEL AS FLOAT_PANEL_STYLE_OBJ
