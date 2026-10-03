''
' DRAW - INPUT/TABLET.BI
' =============================================================================
' Pen tablet pressure, via QB64_GJ_LIB PRESSURE_DEVICE (PD_). Pressure scales
' the Brush / Eraser size per dab and, for the mix brush, how much new paint
' each dab lays (light touch = more smudge). Mouse input is untouched: the
' library reports pressure 1 for a mouse.
'
' Lifecycle: PEN_init before the main loop (and lazily from PEN_poll if the
' feature is switched on later); PEN_poll at the top of every frame;
' PEN_stroke_begin on brush press; PAINT_on calls PEN_segment_begin /
' PEN_segment_end around each frame's segment so pressure is interpolated
' along it instead of stepping once per frame.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

OPTION _EXPLICIT
OPTION _EXPLICITARRAY

CONST PEN_MIN_VALID = 0.02 ' readings below this are a pen lifting / landing, not a stroke

TYPE PEN_OBJ
    tried     AS INTEGER ' PD_init% has been attempted
    ready     AS INTEGER ' a pressure backend is running
    lastValid AS SINGLE  ' last pressure >= PEN_MIN_VALID in this stroke (-1 = none yet)
    segP0     AS SINGLE  ' pressure at the start of the current segment (-1 = stroke start)
    segP1     AS SINGLE  ' pressure at the end of the current segment
    dabP      AS SINGLE  ' pressure of the dab being drawn (read by the mix brush)
    usingPen  AS INTEGER ' the current segment is pen-driven (pressure applies)
END TYPE

DIM SHARED TABLET AS PEN_OBJ
TABLET.dabP = 1
