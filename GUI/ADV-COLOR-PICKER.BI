''
' DRAW - GUI/ADV-COLOR-PICKER.BI
' =============================================================================
' Advanced Color Picker — floating non-modal panel declarations.
' Wraps the QB64_GJ_LIB ADV_COLOR_PICKER (ACP) widget (Krita-style hue ring +
' SV triangle) in a DRAW floating panel with live FG-color sync. Toggle via
' View > Advanced Color Picker. State persists to DRAW.cfg.
'
' Mirrors the COLOR-MIXER panel model (render to screen 0 at integer toolbar
' scale; region + hit-testing in viewport/canvas space).
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

OPTION _EXPLICIT
OPTION _EXPLICITARRAY

' Native (pre-upscale) geometry of the panel.
CONST ADVCP_TITLE_H      = 14    ' Title bar height (native px)
CONST ADVCP_WHEEL_NATIVE = 190   ' Hue-ring + triangle wheel size (native px)

TYPE ADV_COLOR_PICKER_OBJ
    visible       AS INTEGER        ' TRUE = panel shown
    positioned    AS INTEGER        ' TRUE once auto-positioned / restored
    initialized   AS INTEGER        ' TRUE after first ACP_init
    autoHidden    AS INTEGER        ' Auto-hidden (reserved; unused in phase 2)
    lastSyncColor AS _UNSIGNED LONG ' Last color synced to/from the widget
    editTarget    AS INTEGER        ' 0 = editing FG (left btn), 1 = editing BG (right btn)

    ' Display geometry (viewport / canvas coords)
    dispX       AS INTEGER
    dispY       AS INTEGER
    dispW       AS INTEGER
    dispH       AS INTEGER
    renderScale AS SINGLE           ' native -> viewport scale (ts/ds)

    ' Native panel composite buffer (title bar + wheel)
    panelImg    AS LONG
    panelW      AS INTEGER          ' native width
    panelH      AS INTEGER          ' native height
    titleFont   AS LONG             ' themed title-bar font (same as Color Mixer); 0 = built-in

    ' Title-bar drag
    dragging    AS INTEGER
    dragStartMX AS INTEGER
    dragStartMY AS INTEGER
    dragStartDX AS INTEGER
    dragStartDY AS INTEGER
END TYPE

DIM SHARED ADVCP AS ADV_COLOR_PICKER_OBJ
