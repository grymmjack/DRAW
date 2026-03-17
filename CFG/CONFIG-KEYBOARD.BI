''
' DRAW - CFG/KEYBOARD.BI
' =============================================================================
' UDT for keyboard bindings.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

TYPE DRAW_KEYBOARD_BINDINGS
    ' TOOLS -------------------------------------------------------------------
    BRUSH                 AS STRING ' Activate brush tool
    BRUSH_CAPTURE         AS STRING ' Capture selection as custom brush
    DOT                   AS STRING ' Activate dot/pixel tool
    ERASER                AS STRING ' Activate eraser tool (hold=temp, tap=permanent)
    ELLIPSE               AS STRING ' Activate ellipse outline tool
    ELLIPSE_FILL_SOLID    AS STRING ' Activate ellipse filled with solid color
    ELLIPSE_FILL_PATTERN  AS STRING ' Activate ellipse filled with pattern
    FILL                  AS STRING ' Activate flood fill tool
    LINE                  AS STRING ' Activate line tool
    POLYLINE              AS STRING ' Activate polygon outline tool
    POLYLINE_FILL_SOLID   AS STRING ' Activate polygon filled with solid color
    POLYLINE_FILL_PATTERN AS STRING ' Activate polygon filled with pattern
    LINE_RAY              AS STRING ' Activate ray (infinite line) tool
    RECT                  AS STRING ' Activate rectangle outline tool
    RECT_FILLED_SOLID     AS STRING ' Activate rectangle filled with solid color
    RECT_FILLED_PATTERN   AS STRING ' Activate rectangle filled with pattern
    TEXT                  AS STRING ' Activate text tool
    ' CLIPBOARD ---------------------------------------------------------------
    COPY                  AS STRING ' Copy selection to clipboard
    COPY_TO_NEW_LAYER     AS STRING ' Copy selection to a new layer
    COPY_MERGED           AS STRING ' Copy merged (all visible layers) to clipboard
    CUT                   AS STRING ' Cut selection to clipboard
    CUT_TO_NEW_LAYER      AS STRING ' Cut selection to a new layer
    PASTE                 AS STRING ' Paste clipboard contents
    PASTE_IN_PLACE        AS STRING ' Paste clipboard at original position
    ' MODIFIERS ---------------------------------------------------------------
    PAN                   AS STRING ' Hold to pan canvas (spacebar)
    SELECT                AS STRING ' Activate marquee selection tool
    SELECT_ADD            AS STRING ' Modifier to add to current selection
    SELECT_SUB            AS STRING ' Modifier to subtract from current selection
    TRANSFORM_FLIP_H      AS STRING ' Flip selection/layer horizontally
    TRANSFORM_FLIP_V      AS STRING ' Flip selection/layer vertically
    TRANSFORM_ROTATE_L    AS STRING ' Rotate selection/layer counter-clockwise
    TRANSFORM_ROTATE_R    AS STRING ' Rotate selection/layer clockwise
    TRANSFORM_RESIZE_U    AS STRING ' Scale selection/layer up
    TRANSFORM_RESIZE_D    AS STRING ' Scale selection/layer down
    MOVE                  AS STRING ' Activate move tool
    MOVE_NUDGE_LEFT       AS STRING ' Nudge selection/layer left 1px
    MOVE_NUDGE_RIGHT      AS STRING ' Nudge selection/layer right 1px
    MOVE_NUDGE_UP         AS STRING ' Nudge selection/layer up 1px
    MOVE_NUDGE_DOWN       AS STRING ' Nudge selection/layer down 1px
    MOVE_NUDGE_LEFT_N     AS STRING ' Nudge selection/layer left N pixels
    MOVE_NUDGE_RIGHT_N    AS STRING ' Nudge selection/layer right N pixels
    MOVE_NUDGE_UP_N       AS STRING ' Nudge selection/layer up N pixels
    MOVE_NUDGE_DOWN_N     AS STRING ' Nudge selection/layer down N pixels
    ' BRUSH -------------------------------------------------------------------
    BRUSH_RESET           AS STRING ' Reset brush to default size/shape
    BRUSH_SIZE_INC        AS STRING ' Increase brush size
    BRUSH_SIZE_DEC        AS STRING ' Decrease brush size
    BRUSH_SIZE_1          AS STRING ' Set brush size preset 1
    BRUSH_SIZE_2          AS STRING ' Set brush size preset 2
    BRUSH_SIZE_3          AS STRING ' Set brush size preset 3
    BRUSH_SIZE_4          AS STRING ' Set brush size preset 4
    BRUSH_1_SET           AS STRING ' Store current brush to slot 1
    BRUSH_2_SET           AS STRING ' Store current brush to slot 2
    BRUSH_3_SET           AS STRING ' Store current brush to slot 3
    BRUSH_4_SET           AS STRING ' Store current brush to slot 4
    BRUSH_1_RECALL        AS STRING ' Recall brush from slot 1
    BRUSH_2_RECALL        AS STRING ' Recall brush from slot 2
    BRUSH_3_RECALL        AS STRING ' Recall brush from slot 3
    BRUSH_4_RECALL        AS STRING ' Recall brush from slot 4
    PIXEL_PERFECT_TOGGLE  AS STRING ' Toggle pixel-perfect stroke correction
    BRUSH_RECOLOR_TOGGLE  AS STRING ' Toggle custom brush recolor mode
    ' GUI TOGGLES -------------------------------------------------------------
    GUI_TOOLBAR_TOGGLE    AS STRING ' Toggle toolbar visibility
    GUI_PALETTE_TOGGLE    AS STRING ' Toggle palette strip visibility
    GUI_LAYERS_TOGGLE     AS STRING ' Toggle layer panel visibility
    GUI_STATUS_TOGGLE     AS STRING ' Toggle status bar visibility
    GUI_ALL_TOGGLE        AS STRING ' Toggle all GUI panels at once
    ' MOUSE EMULATION ---------------------------------------------------------
    MOUSE_L               AS STRING ' Move cursor left 1px
    MOUSE_R               AS STRING ' Move cursor right 1px
    MOUSE_U               AS STRING ' Move cursor up 1px
    MOUSE_D               AS STRING ' Move cursor down 1px
    MOUSE_L_N             AS STRING ' Move cursor left N pixels
    MOUSE_R_N             AS STRING ' Move cursor right N pixels
    MOUSE_U_N             AS STRING ' Move cursor up N pixels
    MOUSE_D_N             AS STRING ' Move cursor down N pixels
    MOUSE_CLICK_L         AS STRING ' Emulate left mouse click
    MOUSE_CLICK_M         AS STRING ' Emulate middle mouse click
    MOUSE_CLICK_R         AS STRING ' Emulate right mouse click
    MOUSE_SCROLL_U        AS STRING ' Emulate scroll wheel up
    MOUSE_SCROLL_D        AS STRING ' Emulate scroll wheel down
    ' ASSISTANTS --------------------------------------------------------------
    POINTER_TOGGLE        AS STRING ' Toggle pointer/cursor visibility
    TRANSPARENCY_TOGGLE   AS STRING ' Toggle transparency checkerboard
    CROSSHAIR_TOGGLE      AS STRING ' Toggle crosshair guide lines
    GRID_TOGGLE           AS STRING ' Cycle grid visibility modes
    GRID_SNAP_TOGGLE      AS STRING ' Toggle grid snapping
    BRUSH_PREVIEW_TOGGLE  AS STRING ' Toggle brush preview outline
    BRUSH_SHAPE_TOGGLE    AS STRING ' Toggle brush shape (circle/square)
    SYMMETRY_CYCLE        AS STRING ' Cycle symmetry mode (off/H/V/both)
    SYMMETRY_CLEAR        AS STRING ' Clear symmetry mode
    ZOOM                  AS STRING ' Activate zoom tool
    ZOOM_IN               AS STRING ' Zoom in one step
    ZOOM_OUT              AS STRING ' Zoom out one step
    ZOOM_RESET            AS STRING ' Reset zoom to 1:1
    ' HISTORY -----------------------------------------------------------------
    UNDO                  AS STRING ' Undo last action
    REDO                  AS STRING ' Redo last undone action
    ' GUI EDITORS -------------------------------------------------------------
    EDITOR_GRID           AS STRING ' Open grid settings dialog
    EDITOR_PAL            AS STRING ' Open palette editor dialog
    EDITOR_COLOR          AS STRING ' Open color picker dialog
    EDITOR_BRUSH          AS STRING ' Open brush editor dialog
    EDITOR_PATTERN        AS STRING ' Open pattern editor dialog
    EDITOR_LINE           AS STRING ' Open line style editor dialog
    EDITOR_TEXT           AS STRING ' Open text tool settings dialog
    ' PALETTE -----------------------------------------------------------------
    PAL_SET_FG            AS STRING ' Set foreground color from palette
    PAL_SET_BG            AS STRING ' Set background color from palette
    PAL_SWITCH_FG_BG      AS STRING ' Swap foreground and background colors
    PAL_NEXT              AS STRING ' Select next palette color
    PAL_PREV              AS STRING ' Select previous palette color
    PAL_PICK_COLOR        AS STRING ' Activate color picker from canvas
    PAL_FG_00             AS STRING ' Set foreground to palette index 0
    PAL_FG_01             AS STRING ' Set foreground to palette index 1
    PAL_FG_02             AS STRING ' Set foreground to palette index 2
    PAL_FG_03             AS STRING ' Set foreground to palette index 3
    PAL_FG_04             AS STRING ' Set foreground to palette index 4
    PAL_FG_05             AS STRING ' Set foreground to palette index 5
    PAL_FG_06             AS STRING ' Set foreground to palette index 6
    PAL_FG_07             AS STRING ' Set foreground to palette index 7
    PAL_FG_08             AS STRING ' Set foreground to palette index 8
    PAL_FG_09             AS STRING ' Set foreground to palette index 9
    PAL_FG_10             AS STRING ' Set foreground to palette index 10
    PAL_FG_11             AS STRING ' Set foreground to palette index 11
    PAL_FG_12             AS STRING ' Set foreground to palette index 12
    PAL_FG_13             AS STRING ' Set foreground to palette index 13
    PAL_FG_14             AS STRING ' Set foreground to palette index 14
    PAL_FG_15             AS STRING ' Set foreground to palette index 15
    PAL_BG_00             AS STRING ' Set background to palette index 0
    PAL_BG_01             AS STRING ' Set background to palette index 1
    PAL_BG_02             AS STRING ' Set background to palette index 2
    PAL_BG_03             AS STRING ' Set background to palette index 3
    PAL_BG_04             AS STRING ' Set background to palette index 4
    PAL_BG_05             AS STRING ' Set background to palette index 5
    PAL_BG_06             AS STRING ' Set background to palette index 6
    PAL_BG_07             AS STRING ' Set background to palette index 7
    PAL_BG_08             AS STRING ' Set background to palette index 8
    PAL_BG_09             AS STRING ' Set background to palette index 9
    PAL_BG_10             AS STRING ' Set background to palette index 10
    PAL_BG_11             AS STRING ' Set background to palette index 11
    PAL_BG_12             AS STRING ' Set background to palette index 12
    PAL_BG_13             AS STRING ' Set background to palette index 13
    PAL_BG_14             AS STRING ' Set background to palette index 14
    PAL_BG_15             AS STRING ' Set background to palette index 15
    ' LAYERS ------------------------------------------------------------------
    LAYER_NEW             AS STRING ' Create a new layer
    LAYER_SAVE            AS STRING ' Save/export current layer
    LAYER_DUPLICATE       AS STRING ' Duplicate current layer
    LAYER_CLEAR           AS STRING ' Clear current layer contents
    LAYER_SELECT          AS STRING ' Select layer under cursor
    LAYER_FOCUS_INC       AS STRING ' Focus next layer (up in stack)
    LAYER_FOCUS_DEC       AS STRING ' Focus previous layer (down in stack)
    LAYER_RENAME          AS STRING ' Rename current layer
    LAYER_ZINDEX_INC      AS STRING ' Move layer up in z-order
    LAYER_ZINDEX_DEC      AS STRING ' Move layer down in z-order
    LAYER_ZINDEX_TOP      AS STRING ' Move layer to top of z-order
    LAYER_ZINDEX_BOT      AS STRING ' Move layer to bottom of z-order
    LAYER_MERGE_DOWN      AS STRING ' Merge current layer into layer below
    LAYER_MERGE_VISIBLE   AS STRING ' Merge all visible layers into one
END TYPE

DIM SHARED KB AS DRAW_KEYBOARD_BINDINGS ' Global keyboard binding configuration
