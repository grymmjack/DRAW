''
' DRAW - GUI/COLOR-SPACE-3D.BI
' =============================================================================
' 3D Color Space picker — floating non-modal panel declarations.
' Wraps the QB64_GJ_LIB COLOR-3D (C3D) widget: the sRGB gamut as a rotatable
' solid / point cloud in OKLab, CIELAB, XYZ or the RGB cube, with a lightness
' slice; click a color to set FG. Toggle via View > 3D Color Space (action 2024).
' View state persists to DRAW.cfg.
'
' Same panel model as ADV-COLOR-PICKER: the widget owns all picker behavior,
' this wrapper only frames it (title bar, drag, close, region, FG sync).
' Look (font, title bar, chips, slider) is shared via GUI/FLOAT-PANEL so it
' matches the Color Mixer.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

OPTION _EXPLICIT
OPTION _EXPLICITARRAY


TYPE COLOR_SPACE_3D_OBJ
    visible           AS INTEGER        ' TRUE = panel shown
    positioned        AS INTEGER        ' TRUE once auto-positioned / restored
    initialized       AS INTEGER        ' TRUE after first C3D_init
    autoHidden        AS INTEGER        ' TRUE while hidden because the user is drawing over it
    hiddenByToggleAll AS INTEGER        ' TRUE only when Toggle-All UI (F11) hid this panel
    lastSyncColor     AS _UNSIGNED LONG ' Last FG color pushed into the widget

    docked      AS INTEGER ' in a dock slot (GUI/DOCK): the slot places it; no clamp
    dispX       AS INTEGER              ' viewport coords
    dispY       AS INTEGER
    dispW       AS INTEGER
    dispH       AS INTEGER
    renderScale AS SINGLE               ' native -> viewport scale (ts/ds)

    panelImg  AS LONG                   ' native composite (title bar + widget)
    panelW    AS INTEGER
    panelH    AS INTEGER
    bodyX     AS INTEGER                ' widget origin inside the panel (native px)
    bodyY     AS INTEGER

    dragging    AS INTEGER              ' title-bar drag
    dragStartMX AS INTEGER
    dragStartMY AS INTEGER
    dragStartDX AS INTEGER
    dragStartDY AS INTEGER
END TYPE

DIM SHARED CS3D AS COLOR_SPACE_3D_OBJ
