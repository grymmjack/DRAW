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
    opByP     AS INTEGER ' TRUE when that stroke's opacity follows pressure (else the mask only keeps AA dabs from compounding)
    aaPen     AS INTEGER ' antialiased stroke (pen or mouse): dabs at fractional sizes and centers (PAINT_draw_disc_aa)
    ' ... its path (canvas px, a pixel's centre = its whole coordinate): the
    ' pointer's sub-pixel points, joined by quadratic curves through their
    ' midpoints (PAINT_aa_segment)
    aaT       AS INTEGER ' the segment being drawn ends exactly at aaTX / aaTY (PEN_aa_target)
    aaTX      AS SINGLE
    aaTY      AS SINGLE
    aaHas     AS INTEGER ' the stroke has its first point
    aaPX      AS SINGLE  ' the last point
    aaPY      AS SINGLE
    aaMX      AS SINGLE  ' where the drawn path ends (midway to the last point)
    aaMY      AS SINGLE
    dabOp     AS SINGLE  ' opacity 0..1 of the dab being drawn (includes PAINT_OPACITY)
    opBakImg  AS LONG    ' layer snapshot at stroke start (buffer coords incl. apron)
    opW       AS LONG
    opH       AS LONG
    ' Pen Control smoothing (INPUT/STABILIZER) for the stroke being drawn
    stabOn    AS INTEGER ' this stroke's points go through STAB_
    stabDX    AS INTEGER ' the point the stroke last drew to (canvas px)
    stabDY    AS INTEGER
    stepT     AS DOUBLE  ' TIMER of the last smoothing step (samples are timed between it and now)
    subN      AS INTEGER ' >0: this frame's stroke is drawn in subN pieces (MOUSE_brush_samples)
    subK      AS INTEGER ' ... the piece being drawn (1..subN)
    subFrom   AS SINGLE  ' ... the pressure the frame starts at
    subTo     AS SINGLE  ' ... and ends at (-1 = not read yet this frame)
    catching  AS INTEGER ' Catch Up on lift: hold the last pressure, skip the tip threshold
    speedOn   AS INTEGER ' this stroke's pressure gets the speed gain
    ' Mouse expression (QB64_GJ_LIB MOUSE_PRESSURE, CFG.PEN_MOUSE): a mouse stroke
    ' gets a made-up pressure and goes through everything a pen stroke does
    mexp      AS INTEGER ' this stroke is a mouse stroke with mouse expression
    mxTaper   AS INTEGER ' ... with a taper in / out: its dabs are logged (PEN_MX_*)
    mxS       AS SINGLE  ' path length of the stroke's dabs so far (canvas px)
    mxLX      AS SINGLE  ' the last dab's centre
    mxLY      AS SINGLE
    mxHas     AS INTEGER ' a dab has been logged
    mxN       AS LONG    ' dabs logged
END TYPE

DIM SHARED TABLET AS PEN_OBJ
' Mouse expression with a taper: every dab of the stroke (centre canvas px, its
' pressure, its distance along the stroke, its full size and kind - PEN_MXK_*), so
' the release can redraw the stroke's end narrowing to a point (PEN_mx_taper_out)
CONST PEN_MXK_AA   = 1 ' an antialiased disc (PAINT_draw_disc_aa), else a stamp (PAINT_stamp_size)
CONST PEN_MXK_SIZE = 2 ' its size follows pressure
REDIM SHARED PEN_MX_X(1 TO 1024) AS SINGLE, PEN_MX_Y(1 TO 1024) AS SINGLE
REDIM SHARED PEN_MX_P(1 TO 1024) AS SINGLE, PEN_MX_S(1 TO 1024) AS SINGLE
REDIM SHARED PEN_MX_F(1 TO 1024) AS INTEGER, PEN_MX_K(1 TO 1024) AS INTEGER
DIM SHARED TABLET_BAK_MEM  AS _MEM ' _MEMIMAGE view of TABLET.opBakImg
DIM SHARED TABLET_MASK_MEM AS _MEM ' 1 byte per buffer pixel: strongest opacity laid this stroke
TABLET.dabP  = 1
TABLET.dabOp = 1
