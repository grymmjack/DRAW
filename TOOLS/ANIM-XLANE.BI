$INCLUDEONCE
' =============================================================================
' TOOLS/ANIM-XLANE.BI - the X-sheet's lane rows (branch xsheet-holds-lanes,
' PLANS/XSHEET-HOLDS-LANES.md phase 2). A clip layer's disclosure arrow opens
' a row per lane in use (X, Y, SCALE X ... the TOOLS/CLIP keyframe lanes) and a
' + LANE row: each lane row plots its value along the frames with the eases
' (LINEAR straight, IN / OUT / IN-OUT curved, HOLD a step) and its keys as
' diamonds - drag one along the row to retime it, up / down to change its
' value; double-click to add a key / type a value; right-click for the ease,
' delete, the modulator. Text in the X-sheet's Tiny5, UPPERCASE (Rick
' 2026-11-16).
' =============================================================================

CONST XS_LANE_ARROW_W = 10 ' the disclosure arrow before a clip layer's name

CONST XL_MENU_LANE = 6 ' ANIM_LB.menuKind: a lane row's menu
CONST XL_MENU_ADD = 7  ' the + LANE row's menu
CONST XL_V_VALUE = 31000 ' lane menu values (POPUP_MENU_VALUES are INTEGER: keep under 32768): Value...
CONST XL_V_EASE = 31001  ' + CLIP_EASE_* (0..4)
CONST XL_V_DELETE = 31010
CONST XL_V_ADDKEY = 31011
CONST XL_V_MOD = 31020   ' + 0 none, 1-4 LFO sine / triangle / square / saw, 5 noise
CONST XL_V_REMOVE = 31030
CONST XL_V_PICK = 31031  ' show it in the Animation panel's LANE row
CONST XL_V_TINTFG = 31032 ' the TINT lane's colour = the FG colour
CONST XL_V_MODAMT = 31040 ' the modulator's amount...
CONST XL_V_MODPER = 31041 ' its period (frames)... (noise: how often it changes)
CONST XL_V_MODENV = 31042 ' its envelope (ADSR)...
CONST XL_V_SUBFREQ = 31043 ' + its FREQUENCY sub-lane (CLIP_SUB_FREQ)
CONST XL_V_SUBAMP = 31044  ' + its AMPLITUDE sub-lane (CLIP_SUB_AMP)
CONST XL_V_KMOD = 31050     ' this key's span: the modulator on / off (CLIP_KF_MODOFF)
CONST XL_V_KONESHOT = 31051 ' ... one cycle from the key (CLIP_KF_ONESHOT)
CONST XL_V_KRETRIG = 31052  ' ... the wave restarts at the key (CLIP_KF_RETRIG)
CONST XL_V_KFROZEN = 31053  ' the NOISE lane: this key's grain held (CLIP_KF_FROZEN)
CONST XL_V_ADD = 31100   ' + LANE menu: + lane
CONST XL_V_BLEND = 31200 ' the BLEND lane's menu: + a BLEND_* mode, keyed on that frame
CONST XL_V_BTYPE = 31240 ' the BLUR TYPE lane's menu: + a CLIP_BLUR_*, keyed on that frame

TYPE ANIM_XL_OBJ
    ' a key drag (XS_DRAG_LANEKEY)
    slot  AS INTEGER
    k     AS INTEGER ' its clip instance
    L     AS INTEGER ' its lane
    rel0  AS INTEGER ' the key's frame (from In) at the press
    rel   AS INTEGER ' where it is now
    v0    AS SINGLE  ' its value at the press
    v     AS SINGLE  ' now
    e     AS INTEGER ' its ease
    lo    AS SINGLE  ' the row's range at the press (kept while dragging)
    hi    AS SINGLE
    moved AS INTEGER ' changed anything
    ' the lane / + LANE menus
    mSlot AS INTEGER
    mL    AS INTEGER
    mRel  AS INTEGER ' the frame right-clicked (from In)
    rRow  AS INTEGER ' a right press on a lane / + LANE row: that row (the menu on the release)
    rF    AS INTEGER ' and its frame
    ' double-clicks
    lastT AS DOUBLE
    lastRow AS INTEGER
    lastF AS INTEGER
    lastTick AS LONG ' (ANIM_LOOP_TICK: a slow frame between the clicks still counts)
    ' a Move tool drag recording an armed layer's X / Y (ANIM_XL_move_*)
    mvOn  AS INTEGER
    mvSlot AS INTEGER
    mvPX  AS INTEGER ' the press (viewport px)
    mvPY  AS INTEGER
    mvSc  AS SINGLE  ' viewport px per canvas px (the zoom, or the lightbox pane's)
    mvBX  AS SINGLE  ' X / Y at the press
    mvBY  AS SINGLE
    mvDX  AS INTEGER ' the move so far (canvas px)
    mvDY  AS INTEGER
END TYPE
DIM SHARED ANIM_XL AS ANIM_XL_OBJ
DIM SHARED ANIM_XL_KEYS0 AS STRING  ' the dragged lane's keys at the press
DIM SHARED ANIM_XL_BEFORE AS STRING ' CLIP_state$ at the press (the undo step)
DIM SHARED ANIM_XL_OPEN AS STRING   ' MKL$(historyId) of each layer whose lanes are open

' Recording (Rick 2026-11-16: "a red dot ... like arming an automation lane in
' a DAW"): an armed layer's moves / scales / flips / opacity / tint key its
' lanes at the current frame instead of changing its pixels. Session state.
CONST ANIM_ACT_ARM = 2670        ' ANIM > Arm Layer for Recording (the current layer; toggles)
CONST ANIM_ACT_DISARM_ALL = 2671 ' ANIM > Disarm All Layers
CONST ANIM_ACT_SETTINGS = 2672   ' ANIM > Animation Settings... (Settings, its Animation tab)
DIM SHARED ANIM_XL_ARM_IDS AS STRING      ' MKL$(historyId) of each armed layer
DIM SHARED ANIM_XL_REC_ON AS INTEGER  ' a recording in progress (ANIM_XL_rec_begin .. _end): its layer
DIM SHARED ANIM_XL_REC_BEFORE AS STRING ' its lanes at the start (the undo step)
DIM SHARED ANIM_XL_LCLR(1 TO 11) AS _UNSIGNED LONG ' each lane's colour (CFG.ANIM_LANE_COLORS; 0 = the theme's), parsed once
DIM SHARED ANIM_XL_LCLR_SRC AS STRING
DIM SHARED ANIM_XL_LCLR_OK AS INTEGER
DIM SHARED ANIM_XL_LIVE_SLOT AS INTEGER ' the lanes just recorded: purple dots on their rows (fade out)
DIM SHARED ANIM_XL_LIVE_MASK AS LONG    ' bit L
DIM SHARED ANIM_XL_LIVE_DRAWN AS INTEGER ' live lane dots the last X-sheet render drew (QA dump XLREC d:N)
DIM SHARED ANIM_XL_REC_LABEL AS STRING ' the gesture a mouse-held recording belongs to (ANIM_XL_rec_tick ends it)
DIM SHARED ANIM_XL_LIVE_T AS DOUBLE     ' when (TIMER)

' Key selection (Rick 2026-11-16: "a cursor that's a crosshair when we are on a
' lane we could drag to select the cells across lanes ... just one solid rect"):
' frames SEL_F1..SEL_F2 on the lane rows in SEL_ROWS (MKL$(historyId) + MKI$(lane)
' each, display order) - kept by id, so opening / closing other lanes keeps it.
DIM SHARED ANIM_XL_SEL_ON AS INTEGER
DIM SHARED ANIM_XL_SEL_F1 AS INTEGER
DIM SHARED ANIM_XL_SEL_F2 AS INTEGER
DIM SHARED ANIM_XL_SEL_ROWS AS STRING
DIM SHARED ANIM_XL_SEL_R0 AS INTEGER ' the rect drag (XS_DRAG_LSEL): its press's row (ANIM_XS_ROW index) and frame
DIM SHARED ANIM_XL_SEL_FA AS INTEGER
' Edits on the selection (move / copy / delete / paste): its rows' keys at the
' start (ANIM_XL_sel_snapshot) and each layer's lanes before (one undo step,
' every layer in it - HISTORY_begin_group)
DIM SHARED ANIM_XL_SMN AS INTEGER
DIM SHARED ANIM_XL_SMS(1 TO 3 * MAX_LAYERS) AS INTEGER ' row i: its layer slot
DIM SHARED ANIM_XL_SML(1 TO 3 * MAX_LAYERS) AS INTEGER ' its lane
DIM SHARED ANIM_XL_SMK(1 TO 3 * MAX_LAYERS) AS STRING  ' its keys at the start
DIM SHARED ANIM_XL_SMB(1 TO MAX_LAYERS) AS STRING      ' per slot: ANIM_XL_state$ at the start
DIM SHARED ANIM_XL_SMBON(1 TO MAX_LAYERS) AS INTEGER   ' that slot is in it
DIM SHARED ANIM_XL_SMF1 AS INTEGER ' the selection's frames at the press (a move)
DIM SHARED ANIM_XL_SMF2 AS INTEGER
DIM SHARED ANIM_XL_SMLO AS INTEGER ' how far it may go: back / on (frames)
DIM SHARED ANIM_XL_SMHI AS INTEGER
DIM SHARED ANIM_XL_SMD AS INTEGER  ' the move so far (frames)
DIM SHARED ANIM_XL_SMCOPY AS INTEGER ' Alt held: a copy (the keys stay too)
' The keys' clipboard (Ctrl+C / X on the selection, Ctrl+V at the playhead):
' a row per selected lane, its keys from the rect's first frame (MKI$ frame
' offset + value + ease, the CLIP_lks format), edges baked ("copy what you see")
CONST ANIM_ACT_KEYS_COPY = 2673   ' ANIM > Copy Keys (Ctrl+C on the X-sheet's key selection)
CONST ANIM_ACT_KEYS_CUT = 2674    ' ANIM > Cut Keys
CONST ANIM_ACT_KEYS_PASTE = 2675  ' ANIM > Paste Keys (at the current frame)
CONST ANIM_ACT_KEYS_DELETE = 2676 ' ANIM > Delete Keys
DIM SHARED ANIM_XL_CB_N AS INTEGER
DIM SHARED ANIM_XL_CB_W AS INTEGER ' its frames
DIM SHARED ANIM_XL_CB_L(1 TO 3 * MAX_LAYERS) AS INTEGER ' row i: its lane
DIM SHARED ANIM_XL_CB_ID(1 TO 3 * MAX_LAYERS) AS LONG   ' the layer it came from (historyId)
DIM SHARED ANIM_XL_CB_K(1 TO 3 * MAX_LAYERS) AS STRING  ' its keys, frames from the rect's first
DIM SHARED ANIM_XL_CB_LAST AS INTEGER ' the keys are the newest copy (a pixel copy / cut clears it): Ctrl+V pastes keys
