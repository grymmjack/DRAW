''
' DRAW - GUI/PEN-PANEL.BI
' =============================================================================
' Pen Pressure panel — floating non-modal panel with the pen tablet controls:
' a live pressure meter + response curve graph, and a checkbox + "lightest
' touch" slider for each thing pressure can drive (brush size, opacity, mix
' paint), plus the pressure curve. Toggle via View > Pen Pressure (action
' 2028). Same frame model as GUI/COLOR-SPACE-3D (title bar, drag, close,
' region, auto-hide while drawing over it, F11). All values are CFG.PEN_*,
' shared with Settings > General > Pen Tablet.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

OPTION _EXPLICIT
OPTION _EXPLICITARRAY

CONST PENP_W       = 200 ' native panel width
CONST PENP_TITLE_H = 14  ' title bar height (native px)

' Controls (PENP_hit% ids)
CONST PENP_CTL_NONE      = 0
CONST PENP_CTL_ON        = 1
CONST PENP_CTL_SIZE_ON   = 2
CONST PENP_CTL_SIZE      = 3
CONST PENP_CTL_OPAC_ON   = 4
CONST PENP_CTL_OPAC      = 5
CONST PENP_CTL_MIX_ON    = 6
CONST PENP_CTL_MIX       = 7
CONST PENP_CTL_CURVE     = 8

' Layout (native px, y of each row's top)
CONST PENP_Y_STATUS  = 18
CONST PENP_Y_ON      = 30
CONST PENP_Y_METER   = 44
CONST PENP_Y_SIZE    = 60
CONST PENP_Y_OPAC    = 90
CONST PENP_Y_MIX     = 120
CONST PENP_Y_CURVE   = 150
CONST PENP_Y_GRAPH   = 176
CONST PENP_GRAPH_H   = 48
CONST PENP_H         = 230 ' native panel height incl. title
CONST PENP_TRACK_X0  = 52  ' slider track (native x)
CONST PENP_TRACK_X1  = 150

TYPE PEN_PANEL_OBJ
    visible           AS INTEGER ' TRUE = panel shown
    positioned        AS INTEGER ' TRUE once auto-positioned / restored
    initialized       AS INTEGER
    autoHidden        AS INTEGER ' TRUE while hidden because the user is drawing over it
    hiddenByToggleAll AS INTEGER ' TRUE only when Toggle-All UI (F11) hid this panel

    dispX       AS INTEGER       ' viewport coords
    dispY       AS INTEGER
    dispW       AS INTEGER
    dispH       AS INTEGER
    renderScale AS SINGLE        ' native -> viewport scale (ts/ds)

    panelImg  AS LONG            ' native panel image
    titleFont AS LONG            ' themed title font; 0 = built-in

    dragging    AS INTEGER       ' title-bar drag
    dragStartMX AS INTEGER
    dragStartMY AS INTEGER
    dragStartDX AS INTEGER
    dragStartDY AS INTEGER
    sliding     AS INTEGER       ' PENP_CTL_* of the slider being dragged (0 = none)
    lastP       AS SINGLE        ' pressure shown on the last render (redraw when it changes)
END TYPE

DIM SHARED PENP AS PEN_PANEL_OBJ
