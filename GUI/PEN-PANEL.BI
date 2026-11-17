''
' DRAW - GUI/PEN-PANEL.BI
' =============================================================================
' Pen Control panel (was Pen Pressure; renamed 2026-11-17 when it took on
' the stroke filters) — floating non-modal panel with the pen tablet
' controls: a live pressure meter + response curve graph, and a checkbox +
' "lightest touch" slider for each thing pressure can drive (brush size,
' opacity, mix paint), plus the pressure curve; and the INPUT/STABILIZER
' filters (position smoothing, pressure processing, speed scaling). Toggle
' via View > Pen Control (action 2028). Same frame model as GUI/COLOR-SPACE-3D (title bar, drag, close,
' region, auto-hide while drawing over it, F11). All values are CFG.PEN_*,
' shared with Settings > Pen Control (tab 10). Look (font, title bar,
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
' SMOOTHING tab (INPUT/STABILIZER: position smoothing + pressure processing)
CONST PENP_CTL_STAB_ON   = 10
CONST PENP_CTL_STAB_MODE = 11 ' segments: STRING | AVERAGE | EMA | INERTIA
CONST PENP_CTL_STAB_AMT  = 12
CONST PENP_CTL_CATCH     = 13
CONST PENP_CTL_GUIDE_LN  = 14
CONST PENP_CTL_GUIDE_CUR = 15
CONST PENP_CTL_PROC_ON   = 16
CONST PENP_CTL_PROC_MODE = 17 ' segments: FIXED | HOLD | AVERAGE | EMA
CONST PENP_CTL_PROC_AMT  = 18
' SPEED tab (pressure speed scaling)
CONST PENP_CTL_SPD_ON    = 19
CONST PENP_CTL_SPD_SLOW  = 20
CONST PENP_CTL_SPD_FAST  = 21
CONST PENP_CTL_SPD_AT    = 22
CONST PENP_CTL_SPD_SMOOTH = 23
CONST PENP_CTL_TABS      = 24 ' the tab strip (every tab)
CONST PENP_CTL_COUNT     = 24

CONST PENP_TAB_PRESSURE = 0 ' CFG.PEN_PANEL_TAB
CONST PENP_TAB_SMOOTH   = 1
CONST PENP_TAB_SPEED    = 2
CONST PENP_TAB_COUNT    = 3

' Command palette actions (GUI/COMMAND.BM; 2030-2035 checked free 2026-11-17)
CONST PENP_ACT_STAB      = 2030 ' Toggle Smoothing
CONST PENP_ACT_STAB_MODE = 2031 ' Next Smoothing Mode
CONST PENP_ACT_STAB_UP   = 2032 ' Smoothing Amount +5
CONST PENP_ACT_STAB_DOWN = 2033 ' Smoothing Amount -5
CONST PENP_ACT_PROC      = 2034 ' Toggle Pressure Smoothing
CONST PENP_ACT_SPEED     = 2035 ' Toggle Speed Scaling

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
    fitW AS INTEGER ' docked: native size its slot gives it (0 = natural) - FPANEL_fit
    fitH AS INTEGER
    natW AS INTEGER ' its natural (floating) native size, from its layout
    natH AS INTEGER
    hoverCtl   AS INTEGER        ' PENP_CTL_* under the pointer (hover highlight)
    closeHover AS INTEGER        ' pointer is on the close box

    ' Layout (native px, from PENP_layout): row tops + slider track span
    yStatus  AS INTEGER
    yMeter   AS INTEGER
    yGraph   AS INTEGER
    graphH   AS INTEGER ' response graph height (PENP_GRAPH_H, taller docked with room)
    subX     AS INTEGER          ' x of a checkbox's label (sub-slider labels align here)
    trackX0  AS INTEGER
    trackX1  AS INTEGER
    inRow    AS INTEGER ' docked in a top / bottom row: its groups side by side in columns
    gx0      AS INTEGER ' the response graph's x span
    gx1      AS INTEGER

    dragging    AS INTEGER       ' title-bar drag
    dragStartMX AS INTEGER
    dragStartMY AS INTEGER
    dragStartDX AS INTEGER
    dragStartDY AS INTEGER
    sliding     AS INTEGER       ' PENP_CTL_* of the slider being dragged (0 = none)
    lastP       AS SINGLE        ' pressure shown on the last render (redraw when it changes)
    hoverSeg    AS INTEGER       ' segment (0-based) of a tab strip / mode row under the pointer
    colW        AS INTEGER       ' in a row: a group column's width
    tabH        AS INTEGER       ' the tab strip's height
    hbx0 AS INTEGER ' SMOOTHING: the mode hint box
    hby0 AS INTEGER
    hbx1 AS INTEGER
    hby1 AS INTEGER
    sgx0 AS INTEGER ' SPEED: the speed -> gain graph
    sgy0 AS INTEGER
    sgx1 AS INTEGER
    sgy1 AS INTEGER
    rdX  AS INTEGER ' SPEED: the NOW / AVG / TOP readout
    rdY  AS INTEGER
    rdX1 AS INTEGER
    lastSpeed AS SINGLE ' speed shown on the last render (SPEED tab)
    lastTop   AS SINGLE
END TYPE

DIM SHARED PENP AS PEN_PANEL_OBJ
DIM SHARED PENP_ctlY(1 TO PENP_CTL_COUNT) AS INTEGER ' native top of each control row (PENP_layout)
' each control's column (x0..x1) and slider track span (tx0..tx1), native px:
' one column across the panel, or a column per group in a row (Rick 2026-11-16)
DIM SHARED PENP_ctlX0(1 TO PENP_CTL_COUNT) AS INTEGER, PENP_ctlX1(1 TO PENP_CTL_COUNT) AS INTEGER
DIM SHARED PENP_ctlTX0(1 TO PENP_CTL_COUNT) AS INTEGER, PENP_ctlTX1(1 TO PENP_CTL_COUNT) AS INTEGER
DIM SHARED PENP_ctlTab(1 TO PENP_CTL_COUNT) AS INTEGER ' the tab a control is on (-1 = every tab)
CONST PENP_ROW_COL_W = 130 ' a group's column in a row (native px): the width it asks for
CONST PENP_ROW_COL_MIN = 84 ' ... and the narrowest, short of room
CONST PENP_ROW_GAP = 8
