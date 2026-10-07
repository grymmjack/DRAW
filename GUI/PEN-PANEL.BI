''
' DRAW - GUI/PEN-PANEL.BI
' =============================================================================
' Pen Pressure panel — floating non-modal panel with the pen tablet controls:
' a live pressure meter + response curve graph, and a checkbox + "lightest
' touch" slider for each thing pressure can drive (brush size, opacity, mix
' paint), plus the pressure curve. Toggle via View > Pen Pressure (action
' 2028). Same frame model as GUI/COLOR-SPACE-3D (title bar, drag, close,
' region, auto-hide while drawing over it, F11). All values are CFG.PEN_*,
' shared with Settings > General > Pen Tablet. Look (font, title bar,
' sliders, checkboxes) is shared via GUI/FLOAT-PANEL so it matches the Color
' Mixer; the layout is derived from that font in PENP_layout.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

OPTION _EXPLICIT
OPTION _EXPLICITARRAY

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
CONST PENP_CTL_TIP       = 9
CONST PENP_CTL_COUNT     = 9

CONST PENP_GRAPH_H   = 44  ' response graph height (native px)

TYPE PEN_PANEL_OBJ
    visible           AS INTEGER ' TRUE = panel shown
    positioned        AS INTEGER ' TRUE once auto-positioned / restored
    initialized       AS INTEGER
    autoHidden        AS INTEGER ' TRUE while hidden because the user is drawing over it
    hiddenByToggleAll AS INTEGER ' TRUE only when Toggle-All UI (F11) hid this panel

    docked      AS INTEGER ' in a dock slot (GUI/DOCK): the slot places it; no clamp
    dispX       AS INTEGER       ' viewport coords
    dispY       AS INTEGER
    dispW       AS INTEGER
    dispH       AS INTEGER
    renderScale AS SINGLE        ' native -> viewport scale (ts/ds)

    panelImg   AS LONG           ' native panel image
    panelW     AS INTEGER        ' native panel width (shared floating-panel width)
    panelH     AS INTEGER        ' native panel height (font-derived, PENP_layout)
    hoverCtl   AS INTEGER        ' PENP_CTL_* under the pointer (hover highlight)
    closeHover AS INTEGER        ' pointer is on the close box

    ' Layout (native px, from PENP_layout): row tops + slider track span
    yStatus  AS INTEGER
    yMeter   AS INTEGER
    yGraph   AS INTEGER
    subX     AS INTEGER          ' x of a checkbox's label (sub-slider labels align here)
    trackX0  AS INTEGER
    trackX1  AS INTEGER

    dragging    AS INTEGER       ' title-bar drag
    dragStartMX AS INTEGER
    dragStartMY AS INTEGER
    dragStartDX AS INTEGER
    dragStartDY AS INTEGER
    sliding     AS INTEGER       ' PENP_CTL_* of the slider being dragged (0 = none)
    lastP       AS SINGLE        ' pressure shown on the last render (redraw when it changes)
END TYPE

DIM SHARED PENP AS PEN_PANEL_OBJ
DIM SHARED PENP_ctlY(1 TO PENP_CTL_COUNT) AS INTEGER ' native top of each control row (PENP_layout)
