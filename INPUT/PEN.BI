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
' Pressure -> opacity: each written pixel is recomposited from a stroke-start
' snapshot at the STRONGEST opacity any dab reached on it (a per-pixel byte
' mask). Overlapping dabs therefore never compound, and the result is visible
' live while drawing (the plain Opacity setting only applies on release).
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
    skipSeg   AS INTEGER ' this segment is below the tip threshold: draw nothing
    painted   AS INTEGER ' the current stroke has drawn at least one segment
    penSeen   AS INTEGER ' the current stroke had at least one pen-driven segment
    ' Pressure -> opacity (one stroke at a time; see PEN_opacity_begin)
    opStroke  AS INTEGER ' TRUE while this stroke's opacity follows pressure
    opErase   AS INTEGER ' TRUE when that stroke erases (Eraser / transparent paint)
    dabOp     AS SINGLE  ' opacity 0..1 of the dab being drawn (includes PAINT_OPACITY)
    opBakImg  AS LONG    ' layer snapshot at stroke start (buffer coords incl. apron)
    opW       AS LONG
    opH       AS LONG
END TYPE

DIM SHARED TABLET AS PEN_OBJ
DIM SHARED TABLET_BAK_MEM  AS _MEM ' _MEMIMAGE view of TABLET.opBakImg
DIM SHARED TABLET_MASK_MEM AS _MEM ' 1 byte per buffer pixel: strongest opacity laid this stroke
TABLET.dabP  = 1
TABLET.dabOp = 1
