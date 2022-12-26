''
' DRAW - CFG/KEYBOARD.BI
' =============================================================================
' UDT for keyboard bindings.
'
' @author Rick Christy <grymmjack@gmail.com>
'

$IF CONFIG_KEYBOARD_BI = UNDEFINED THEN
    $LET CONFIG_KEYBOARD_BI = 1
$END IF

TYPE DRAW_KEYBOARD_BINDINGS
    ' TOOLS -------------------------------------------------------------------
    BRUSH                 AS STRING
    BRUSH_CAPTURE         AS STRING
    DOT                   AS STRING
    ELLIPSE               AS STRING
    ELLIPSE_FILL_SOLID    AS STRING
    ELLIPSE_FILL_PATTERN  AS STRING
    FILL                  AS STRING
    LINE                  AS STRING
    POLYLINE              AS STRING
    POLYLINE_FILL_SOLID   AS STRING
    POLYLINE_FILL_PATTERN AS STRING
    LINE_RAY              AS STRING
    RECT                  AS STRING
    RECT_FILLED_SOLID     AS STRING
    RECT_FILLED_PATTERN   AS STRING
    TEXT                  AS STRING
    ' CLIPBOARD ---------------------------------------------------------------
    COPY                  AS STRING
    COPY_TO_NEW_LAYER     AS STRING
    COPY_MERGED           AS STRING
    CUT                   AS STRING
    CUT_TO_NEW_LAYER      AS STRING
    PASTE                 AS STRING
    PASTE_IN_PLACE        AS STRING
    ' MODIFIERS ---------------------------------------------------------------
    PAN                   AS STRING
    SELECT                AS STRING
    SELECT_ADD            AS STRING
    SELECT_SUB            AS STRING
    TRANSFORM_FLIP_H      AS STRING
    TRANSFORM_FLIP_V      AS STRING
    TRANSFORM_ROTATE_L    AS STRING
    TRANSFORM_ROTATE_R    AS STRING
    TRANSFORM_RESIZE_U    AS STRING
    TRANSFORM_RESIZE_D    AS STRING
    MOVE                  AS STRING
    MOVE_NUDGE_LEFT       AS STRING
    MOVE_NUDGE_RIGHT      AS STRING
    MOVE_NUDGE_UP         AS STRING
    MOVE_NUDGE_DOWN       AS STRING
    MOVE_NUDGE_LEFT_N     AS STRING
    MOVE_NUDGE_RIGHT_N    AS STRING
    MOVE_NUDGE_UP_N       AS STRING
    MOVE_NUDGE_DOWN_N     AS STRING
    ' BRUSH -------------------------------------------------------------------
    BRUSH_RESET           AS STRING
    BRUSH_SIZE_INC        AS STRING
    BRUSH_SIZE_DEC        AS STRING
    BRUSH_SIZE_1          AS STRING
    BRUSH_SIZE_2          AS STRING
    BRUSH_SIZE_3          AS STRING
    BRUSH_SIZE_4          AS STRING
    BRUSH_DITHER_1        AS STRING
    BRUSH_DITHER_2        AS STRING
    BRUSH_DITHER_3        AS STRING
    BRUSH_DITHER_4        AS STRING
    BRUSH_1_SET           AS STRING
    BRUSH_2_SET           AS STRING
    BRUSH_3_SET           AS STRING
    BRUSH_4_SET           AS STRING
    BRUSH_1_RECALL        AS STRING
    BRUSH_2_RECALL        AS STRING
    BRUSH_3_RECALL        AS STRING
    BRUSH_4_RECALL        AS STRING
    ' GUI TOGGLES -------------------------------------------------------------
    GUI_TOOLBAR_TOGGLE    AS STRING
    GUI_PALETTE_TOGGLE    AS STRING
    GUI_LAYERS_TOGGLE     AS STRING
    GUI_STATUS_TOGGLE     AS STRING
    GUI_ALL_TOGGLE        AS STRING
    ' MOUSE EMULATION ---------------------------------------------------------
    MOUSE_L               AS STRING
    MOUSE_R               AS STRING
    MOUSE_U               AS STRING
    MOUSE_D               AS STRING
    MOUSE_L_N             AS STRING
    MOUSE_R_N             AS STRING
    MOUSE_U_N             AS STRING
    MOUSE_D_N             AS STRING
    MOUSE_CLICK_L         AS STRING
    MOUSE_CLICK_M         AS STRING
    MOUSE_CLICK_R         AS STRING
    MOUSE_SCROLL_U        AS STRING
    MOUSE_SCROLL_D        AS STRING
    ' ASSISTANTS --------------------------------------------------------------
    POINTER_TOGGLE        AS STRING
    TRANSPARENCY_TOGGLE   AS STRING
    CROSSHAIR_TOGGLE      AS STRING
    GRID_TOGGLE           AS STRING
    GRID_SNAP_TOGGLE      AS STRING
    ZOOM                  AS STRING
    ZOOM_IN               AS STRING
    ZOOM_OUT              AS STRING
    ZOOM_RESET            AS STRING
    ' HISTORY -----------------------------------------------------------------
    UNDO                  AS STRING
    REDO                  AS STRING
    ' GUI EDITORS -------------------------------------------------------------
    EDITOR_GRID           AS STRING
    EDITOR_PAL            AS STRING
    EDITOR_COLOR          AS STRING
    EDITOR_BRUSH          AS STRING
    EDITOR_PATTERN        AS STRING
    EDITOR_LINE           AS STRING
    EDITOR_TEXT           AS STRING
    ' PALETTE -----------------------------------------------------------------
    PAL_SET_FG            AS STRING
    PAL_SET_BG            AS STRING
    PAL_SWITCH_FG_BG      AS STRING
    PAL_NEXT              AS STRING
    PAL_PREV              AS STRING
    PAL_PICK_COLOR        AS STRING
    PAL_FG_00             AS STRING
    PAL_FG_01             AS STRING
    PAL_FG_02             AS STRING
    PAL_FG_03             AS STRING
    PAL_FG_04             AS STRING
    PAL_FG_05             AS STRING
    PAL_FG_06             AS STRING
    PAL_FG_07             AS STRING
    PAL_FG_08             AS STRING
    PAL_FG_09             AS STRING
    PAL_FG_10             AS STRING
    PAL_FG_11             AS STRING
    PAL_FG_12             AS STRING
    PAL_FG_13             AS STRING
    PAL_FG_14             AS STRING
    PAL_FG_15             AS STRING
    PAL_BG_00             AS STRING
    PAL_BG_01             AS STRING
    PAL_BG_02             AS STRING
    PAL_BG_03             AS STRING
    PAL_BG_04             AS STRING
    PAL_BG_05             AS STRING
    PAL_BG_06             AS STRING
    PAL_BG_07             AS STRING
    PAL_BG_08             AS STRING
    PAL_BG_09             AS STRING
    PAL_BG_10             AS STRING
    PAL_BG_11             AS STRING
    PAL_BG_12             AS STRING
    PAL_BG_13             AS STRING
    PAL_BG_14             AS STRING
    PAL_BG_15             AS STRING
    ' LAYERS ------------------------------------------------------------------
    LAYER_NEW             AS STRING
    LAYER_SAVE            AS STRING
    LAYER_DUPLICATE       AS STRING
    LAYER_CLEAR           AS STRING
    LAYER_SELECT          AS STRING
    LAYER_FOCUS_INC       AS STRING
    LAYER_FOCUS_DEC       AS STRING
    LAYER_RENAME          AS STRING
    LAYER_ZINDEX_INC      AS STRING
    LAYER_ZINDEX_DEC      AS STRING
    LAYER_ZINDEX_TOP      AS STRING
    LAYER_ZINDEX_BOT      AS STRING
END TYPE
 