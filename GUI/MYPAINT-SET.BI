''
' DRAW - GUI/MYPAINT-SET.BI
' =============================================================================
' The MyPaint Brush Settings panel (Rick 2026-11-18: MyPaint's Freehand options -
' "make it a panel similar to pen control, ok? so it can be docked"): a dock panel
' (DP_MYPSET, View > MyPaint Brush Settings, CFG.MYPAINT_SETTINGS) of sliders for the
' brush in use, as MyPaint's own:
'   SIZE     DRAW's brush size (CFG.MYPAINT_SIZE_FROM_BRUSH, the default: a BRUSH_PIXEL_SIZES index)
'            or the radius over the file's (CFG.MYPAINT_SIZE: tenths of a log step, -40..40)
'   OPAQUE   opaque            0..2
'   SHARP    hardness          0..1
'   GAIN     pressure_gain_log -1.8..1.8
'   PIGMENT  paint_mode        0..1 (spectral pigment mixing)
'   SMOOTH   slow_tracking     0..10
'   PRESSURE the pressure the mouse paints with (CFG.MYPAINT_MOUSE_PRESSURE %; a pen its own)
'   TWIST    the pen barrel rotation every event gets (CFG.MYPAINT_TWIST degrees, mp_set_twist)
' OPAQUE .. SMOOTH change the loaded brush (mp_set_base) and go back to the file's at the
' next load; RESET puts every one back (the file's, SIZE 0, PRESSURE 50, TWIST 0); SAVE
' writes the brush with them as a .myb in MY BRUSHES (MYPAINT_ACT_SAVE). Each slider takes
' the universal value input (GUI/PANEL-SLIDER). In a column the sliders stack; in a wide
' row they go side by side in columns.
'
$INCLUDEONCE

CONST MPS_MIN_W = 120 ' narrowest (its units): stacked sliders
CONST MPS_COL_W = 200 ' the width it asks of a column
CONST MPS_SLIDER_W = 190 ' a slider's width in a row of them (a wide dock)
CONST MPS_N = 8

' sliders (MPS.hover / drag ids; MPSB_* are its buttons)
CONST MPS_SIZE = 1
CONST MPS_OPAQUE = 2
CONST MPS_SHARP = 3
CONST MPS_GAIN = 4
CONST MPS_PIGMENT = 5
CONST MPS_SMOOTH = 6
CONST MPS_PRESSURE = 7
CONST MPS_TWIST = 8
CONST MPSB_RESET = 20
CONST MPSB_SAVE = 21

' actions (GUI/COMMAND.BM; free range checked 2026-11-18)
CONST MPS_ACT_PANEL = 2687 ' View > MyPaint Brush Settings
CONST MPS_ACT_RESET = 2688 ' every setting back to the brush file's

TYPE MPS_OBJ
    x       AS INTEGER ' the rect it was given (its units)
    y       AS INTEGER
    w       AS INTEGER
    h       AS INTEGER
    visible AS INTEGER
    hover   AS INTEGER ' the slider / button under the pointer
    drag    AS INTEGER ' the slider held (0 = none)
    cols    AS INTEGER ' last laid out: slider columns
    sw      AS INTEGER ' a slider's width
    lw      AS INTEGER ' its label column
    vw      AS INTEGER ' its value column
    footY   AS INTEGER ' the buttons' row
    idsOK   AS INTEGER ' MPS_ID filled
END TYPE
DIM SHARED MPS AS MPS_OBJ
DIM SHARED MPS_SX(1 TO MPS_N) AS INTEGER, MPS_SY(1 TO MPS_N) AS INTEGER ' last laid out (its units)
DIM SHARED MPS_BX(MPSB_RESET TO MPSB_SAVE) AS INTEGER, MPS_BW(MPSB_RESET TO MPSB_SAVE) AS INTEGER
DIM SHARED MPS_ID(1 TO MPS_N) AS LONG    ' libmypaint setting ids (OPAQUE .. SMOOTH)
DIM SHARED MPS_FILEV(1 TO MPS_N) AS INTEGER ' the brush file's values in slider units (MPS_capture)
