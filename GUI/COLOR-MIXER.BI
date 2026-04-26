''
' DRAW - GUI/COLOR-MIXER.BI
' =============================================================================
' Color Mixer — floating non-modal color picker panel declarations.
' Wraps the QB64_GJ_LIB COLOR_PICKER (CP module) in a DRAW-style floating
' panel with live color editing that syncs with the current FG color.
' Toggle via organizer button or View > Color Mixer.
' State persists to DRAW.cfg.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

OPTION _EXPLICIT
OPTION _EXPLICITARRAY

TYPE COLOR_MIXER_OBJ
    visible       AS INTEGER        ' TRUE = panel is shown
    positioned    AS INTEGER        ' TRUE once auto-positioned
    initialized   AS INTEGER        ' TRUE after first CP_init call
    autoHidden    AS INTEGER        ' Auto-hidden while drawing over panel
    lastSyncColor AS _UNSIGNED LONG ' Last color synced to/from mixer
    renderScale   AS SINGLE         ' Scale factor for display (<= 1.0)
    dispW         AS INTEGER        ' Displayed width on SCRN.CANVAS
    dispH         AS INTEGER        ' Displayed height on SCRN.CANVAS
    dispX         AS INTEGER        ' Displayed X (viewport coords)
    dispY         AS INTEGER        ' Displayed Y (viewport coords)
    dragging      AS INTEGER        ' TRUE while title-bar drag is active
    dragStartMX   AS INTEGER        ' Raw mouse X at drag start
    dragStartMY   AS INTEGER        ' Raw mouse Y at drag start
    dragStartDX   AS INTEGER        ' dispX at drag start
    dragStartDY   AS INTEGER        ' dispY at drag start
END TYPE

DIM SHARED COLORMIXER AS COLOR_MIXER_OBJ

