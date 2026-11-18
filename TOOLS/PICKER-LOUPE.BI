'
' DRAW - TOOLS/PICKER-LOUPE.BI
' =============================================================================
' Runtime state and declarations for the picker loupe overlay.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

TYPE PICKER_LOUPE_OBJ
    ACTIVE         AS INTEGER
    BUFFER         AS LONG
    BUFFER_W       AS INTEGER
    BUFFER_H       AS INTEGER
    TEXT_BUFFER    AS LONG
    TEXT_BUFFER_W  AS INTEGER
    TEXT_BUFFER_H  AS INTEGER
    FONT_HANDLE    AS LONG
    LAST_FONT_SIZE AS INTEGER
    SAMPLE_COLOR   AS _UNSIGNED LONG
    ' The Alt eyedropper over chrome (Rick 2026-11-16: "i can't pick colors or
    ' use the loupe over the docked vertical bars ... hold alt to zoom in and
    ' drag"): the docked panels and native windows are drawn straight to
    ' screen 0 after SCENE_CACHE is saved, so the chrome loupe and the pick
    ' read SNAP - the frame as shown, copied while Alt is held - and the loupe
    ' is drawn after the windows (PICKER_LOUPE_screen_pass)
    SNAP           AS LONG ' the shown frame, viewport px
    SNAP_OK        AS INTEGER
    OVL            AS LONG ' the loupe drawn here, then its box put on screen 0
    WIN_PASS       AS INTEGER ' TRUE while PICKER_LOUPE_render draws the chrome loupe
    LX1            AS INTEGER ' the box the last draw covered (viewport px)
    LY1            AS INTEGER
    LX2            AS INTEGER
    LY2            AS INTEGER
    DRAG_BTN       AS INTEGER ' an Alt eyedrop press still held: 1 left (FG) / 2 right (BG)
END TYPE

DIM SHARED PICKER_LOUPE AS PICKER_LOUPE_OBJ
DIM SHARED PICKER_LOUPE_LAST_FONT$


PICKER_LOUPE_init