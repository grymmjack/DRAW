''
' DRAW - GUI/PANEL-SURFACE.BI
' =============================================================================
' Panel surfaces: a docked panel (toolbox, organizer, drawer, layers, the edit
' and advanced bars, the character map) at its own Scale, in real screen
' pixels like the floating windows (Rick, 2026-11-14: "real 1x like floating
' panels").
'
' These panels draw into the viewport, so one panel px is displayScale screen
' px - a 1x or 2x below that cannot be drawn there. A panel whose Scale is set
' (right-click its handle > Scale) and differs from its Auto draws instead
' into its own image in panel units, and that image goes onto the window at
' k screen px a unit (k = its Scale), over the presented canvas like the
' native windows (SCREEN_render_windows). In the viewport the panel keeps a
' footprint: the dock rect it was given, filled with its background.
'
' Panel units: the panel's code is unchanged - it draws at its usual absolute
' coordinates, from the footprint's top-left (vx, vy), but in a rect of
' uw x uh units (the footprint x displayScale / k). Its hit tests get the
' pointer in units (PSURF_mx% / PSURF_my%: from the window position, so a 1x
' panel resolves single screen pixels).
'
' Auto (or a Scale equal to it) draws into the viewport as before: nothing
' changes for a panel left at Auto.
' =============================================================================
$INCLUDEONCE

TYPE PSURF_OBJ
    img   AS LONG    ' the panel's own image (unit coords = viewport coords from vx, vy)
    vx    AS INTEGER ' footprint in the viewport (the dock rect)
    vy    AS INTEGER
    vw    AS INTEGER
    vh    AS INTEGER
    uw    AS INTEGER ' the rect in panel units
    uh    AS INTEGER
    k     AS SINGLE  ' screen px a unit, as last drawn (1.5, 2.5 ..: a half-step Scale)
    ready AS INTEGER ' drawn since its rect was set
    sdirty AS INTEGER ' drawn again since its half-step picture (HSC_IMG) was made
END TYPE

CONST PSURF_N = 17 ' the dock panels: DP_TOOLBOX .. DP_IOBAR
DIM SHARED PSURF(1 TO PSURF_N) AS PSURF_OBJ

' Half-step copies onto the window (HSC_put): a panel or native window at 1.5x, 2.5x ..
' resampled (CFG.PANEL_HALF_FILTER) into HSC_IMG(slot), and the source as last
' resampled in HSC_COPY(slot) (skip when nothing changed). Slots: the DP_* ids, then
' the extra pictures some windows put up (HSC_ADVCP_MENU).
CONST HSC_N = 24
CONST HSC_ADVCP_MENU = 22 ' the Advanced Color Picker's context menu
CONST HSC_SWATCH_MENU = 23 ' the Swatches set list / gear menu
DIM SHARED HSC_IMG(1 TO HSC_N) AS LONG, HSC_COPY(1 TO HSC_N) AS LONG
