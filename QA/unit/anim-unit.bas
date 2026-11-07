' =============================================================================
' QA/unit/anim-unit.bas - headless unit test for TOOLS/ANIM.BM (the sprite
' sheet frame math: cells, layout, frame at a point, holds, stepping). Stubs
' the one DRAW global the module reads (SCRN canvas size). Build + run:
'   ~/git/qb64pe/qb64pe -w -x -o anim-unit.run anim-unit.bas && ./anim-unit.run
' Exit code 0 = all pass.
' =============================================================================
$CONSOLE:ONLY
OPTION _EXPLICIT
CONST TRUE = -1, FALSE = 0
TYPE SCRN_STUB
    canvasW AS LONG
    canvasH AS LONG
END TYPE
DIM SHARED SCRN AS SCRN_STUB
DIM SHARED FAILS AS INTEGER, PASSES AS INTEGER
'$INCLUDE:'../../TOOLS/ANIM.BI'

DIM x AS LONG, y AS LONG, w AS LONG, h AS LONG, s AS STRING, i AS INTEGER, r AS INTEGER
DIM pc AS INTEGER, pcur AS INTEGER ' ANIM_plan% outputs (BYREF INTEGERs)

' --- a plain picture has no frames ---
SCRN.canvasW = 64: SCRN.canvasH = 32
check "off by default", STR$(ANIM.active), STR$(FALSE)
check "no cells when off", STR$(ANIM_cells%), STR$(0)
check "no frame at a point when off", STR$(ANIM_frame_at%(5, 5)), STR$(0)
check "default fps", STR$(ANIM.fps), STR$(ANIM_FPS_DEFAULT)

' --- 64x32 canvas, 16x16 frames: 4 x 2 cells ---
r = ANIM_set_layout%(16, 16, 0, 0)
check "layout on", STR$(r), STR$(TRUE)
check "cols", STR$(ANIM_cols%), STR$(4)
check "rows", STR$(ANIM_rows%), STR$(2)
check "count = cells on first layout", STR$(ANIM.count), STR$(8)
check "current starts at 1", STR$(ANIM.current), STR$(1)
r = ANIM_cell_rect%(6, x, y, w, h)
check "cell 6 rect", STR$(x) + STR$(y) + STR$(w) + STR$(h), STR$(16) + STR$(16) + STR$(16) + STR$(16)
check "no cell 9", STR$(ANIM_cell_rect%(9, x, y, w, h)), STR$(FALSE)
check "no cell 0", STR$(ANIM_cell_rect%(0, x, y, w, h)), STR$(FALSE)
s = "": FOR i = 0 TO 63 STEP 8: s = s + _TRIM$(STR$(ANIM_frame_at%(i, 20))): NEXT
check "frames along row 2", s, "55667788"
check "frame at (15,15) is 1", STR$(ANIM_frame_at%(15, 15)), STR$(1)
check "frame at (16,15) is 2", STR$(ANIM_frame_at%(16, 15)), STR$(2)
check "off the canvas", STR$(ANIM_frame_at%(64, 0)), STR$(0)

' --- gutter 2, margin 3 on 64x32: (64-6+2)\(16+2) = 3 across, (32-6+2)\18 = 1 down ---
r = ANIM_set_layout%(16, 16, 2, 3)
check "gutter+margin cols", STR$(ANIM_cols%), STR$(3)
check "gutter+margin rows", STR$(ANIM_rows%), STR$(1)
check "count shrinks to the cells there are", STR$(ANIM.count), STR$(3)
r = ANIM_cell_rect%(2, x, y, w, h)
check "cell 2 with gutter+margin", STR$(x) + STR$(y), STR$(21) + STR$(3)
check "margin is no frame", STR$(ANIM_frame_at%(2, 5)), STR$(0)
check "gutter is no frame", STR$(ANIM_frame_at%(19, 5)), STR$(0)
check "just past the gutter", STR$(ANIM_frame_at%(21, 5)), STR$(2)
check "spare space right of the cells", STR$(ANIM_frame_at%(60, 5)), STR$(0)

' --- count below cells: the rest of the row is spare ---
r = ANIM_set_layout%(16, 16, 0, 0)
check "the frames a smaller layout hid come back", STR$(ANIM.count), STR$(8)
ANIM.count = 5: ANIM.wanted = 5
r = ANIM_set_layout%(22, 16, 0, 0)
check "a layout with fewer cells (2 x 2) shows fewer", STR$(ANIM.count), STR$(4)
r = ANIM_set_layout%(16, 16, 0, 0)
check "a re-slice keeps the wanted count", STR$(ANIM.count), STR$(5)
check "cell 7 exists", STR$(ANIM_cell_rect%(7, x, y, w, h)), STR$(TRUE)
check "but is past the last frame", STR$(ANIM_frame_at%(40, 20)), STR$(0)

' --- a layout with no room for a cell turns frames off ---
r = ANIM_set_layout%(100, 16, 0, 0)
check "too wide: off", STR$(r) + STR$(ANIM.count) + STR$(ANIM.current), STR$(FALSE) + STR$(0) + STR$(0)
r = ANIM_set_layout%(0, 0, 0, 0)
check "zero size: off", STR$(ANIM.active), STR$(FALSE)

' --- current frame, stepping wraps ---
r = ANIM_set_layout%(16, 16, 0, 0)
check "count after off/on", STR$(ANIM.count), STR$(8)
r = ANIM_go%(3) ' (call first: operand order inside one expression is unspecified)
check "go 3", STR$(r) + STR$(ANIM.current), STR$(TRUE) + STR$(3)
check "go 3 again: no change", STR$(ANIM_go%(3)), STR$(FALSE)
r = ANIM_go%(99)
check "go 99 clamps to last", STR$(r) + STR$(ANIM.current), STR$(TRUE) + STR$(8)
r = ANIM_step%(1)
check "next from the last wraps to 1", STR$(ANIM.current), STR$(1)
r = ANIM_step%(-1)
check "previous from 1 wraps to the last", STR$(ANIM.current), STR$(8)
r = ANIM_step%(-10)
check "step -10 of 8 from 8", STR$(ANIM.current), STR$(6)

' --- holds and fps ---
check "hold defaults to 1", STR$(ANIM_hold%(4)), STR$(1)
ANIM_set_hold 4, 3
check "hold 3", STR$(ANIM_hold%(4)), STR$(3)
ANIM_set_hold 4, 500
check "hold capped", STR$(ANIM_hold%(4)), STR$(ANIM_HOLD_MAX)
ANIM_set_fps 0
check "fps floor", STR$(ANIM.fps), STR$(1)
ANIM_set_fps 999
check "fps cap", STR$(ANIM.fps), STR$(ANIM_FPS_MAX)

' --- reset clears everything ---
ANIM_reset
check "reset", STR$(ANIM.active) + STR$(ANIM.count) + STR$(ANIM_hold%(4)) + STR$(ANIM.fps), STR$(FALSE) + STR$(0) + STR$(1) + STR$(ANIM_FPS_DEFAULT)

' --- saved data round trip (the "drAn" PNG chunk) ---
ANIM_reset
check "nothing saved without frames", STR$(LEN(ANIM_serialize$)), STR$(0)
SCRN.canvasW = 64: SCRN.canvasH = 32
r = ANIM_set_layout%(16, 16, 0, 0)
ANIM.count = 7: r = ANIM_go%(5): ANIM_set_fps 12: ANIM.loopMode = ANIM_LOOP_PING
ANIM_set_hold 3, 4: ANIM_set_hold 6, 2
s = ANIM_serialize$
check "blob size: header + 6 holds", STR$(LEN(s)), STR$(20 + 12)
ANIM_reset
r = ANIM_deserialize%(s)
check "loads", STR$(r), STR$(TRUE)
check "layout back", STR$(ANIM.frameW) + STR$(ANIM.frameH) + STR$(ANIM.gutter) + STR$(ANIM.margin), STR$(16) + STR$(16) + STR$(0) + STR$(0)
check "count/current/fps/loop back", STR$(ANIM.count) + STR$(ANIM.current) + STR$(ANIM.fps) + STR$(ANIM.loopMode), STR$(7) + STR$(5) + STR$(12) + STR$(ANIM_LOOP_PING)
check "holds back", STR$(ANIM_hold%(2)) + STR$(ANIM_hold%(3)) + STR$(ANIM_hold%(6)) + STR$(ANIM_hold%(7)), STR$(1) + STR$(4) + STR$(2) + STR$(1)
check "same bytes saved again", STR$(ANIM_serialize$ = s), STR$(TRUE)
' gutter/margin survive
r = ANIM_set_layout%(16, 16, 2, 3)
r = ANIM_deserialize%(ANIM_serialize$)
check "gutter/margin back", STR$(ANIM.gutter) + STR$(ANIM.margin) + STR$(ANIM.count), STR$(2) + STR$(3) + STR$(3)
' a smaller canvas than the data was saved for: count clamps to the cells there are
r = ANIM_set_layout%(16, 16, 0, 0): ANIM.count = 7: r = ANIM_go%(7): s = ANIM_serialize$
SCRN.canvasW = 32
r = ANIM_deserialize%(s)
check "count clamps to cells", STR$(ANIM.count) + STR$(ANIM.current), STR$(4) + STR$(4)
' frames that do not fit the canvas at all: no frames
SCRN.canvasW = 8
r = ANIM_deserialize%(s)
check "too small: no frames", STR$(r) + STR$(ANIM.active), STR$(FALSE) + STR$(FALSE)
SCRN.canvasW = 64
check "short blob: no frames", STR$(ANIM_deserialize%(LEFT$(s, 10))), STR$(FALSE)
check "version 0: no frames", STR$(ANIM_deserialize%(MKI$(0) + MID$(s, 3))), STR$(FALSE)
r = ANIM_deserialize%(LEFT$(s, 16) + MKI$(9) + MID$(s, 19))
check "bad loop mode falls back", STR$(r) + STR$(ANIM.loopMode), STR$(TRUE) + STR$(ANIM_LOOP_FWD)
r = ANIM_deserialize%(LEFT$(s, 18) + MKI$(50) + MKI$(3))
check "truncated holds: keeps what is there", STR$(r) + STR$(ANIM_hold%(1)) + STR$(ANIM_hold%(2)), STR$(TRUE) + STR$(3) + STR$(1)
SCRN.canvasW = 64: SCRN.canvasH = 32: ANIM_reset
r = ANIM_deserialize%(MKI$(2) + MID$(s, 3) + "future")
check "a newer version with extra fields still loads", STR$(r) + STR$(ANIM.count), STR$(TRUE) + STR$(7)


' --- frame operations: ANIM_plan% (new frame n = old frame ANIM_SRC(n), 0 = blank) ---
SCRN.canvasW = 64: SCRN.canvasH = 32: ANIM_reset
r = ANIM_set_layout%(16, 16, 0, 0): ANIM.count = 5: ANIM.wanted = 5: ANIM.current = 3
check "append: copy of the last", plan$(ANIM_OP_APPEND), "6 6:1 2 3 4 5 5"
check "append blank", plan$(ANIM_OP_APPEND_BLANK), "6 6:1 2 3 4 5 0"
check "insert before the current", plan$(ANIM_OP_INSERT_BEFORE), "6 3:1 2 0 3 4 5"
check "insert after the current", plan$(ANIM_OP_INSERT_AFTER), "6 4:1 2 3 0 4 5"
check "duplicate the current", plan$(ANIM_OP_DUPLICATE), "6 4:1 2 3 3 4 5"
check "delete the current", plan$(ANIM_OP_DELETE), "4 3:1 2 4 5"
check "move earlier", plan$(ANIM_OP_EARLIER), "5 2:1 3 2 4 5"
check "move later", plan$(ANIM_OP_LATER), "5 4:1 2 4 3 5"
check "reverse", plan$(ANIM_OP_REVERSE), "5 3:5 4 3 2 1"
ANIM.current = 5
check "delete the last: current steps back", plan$(ANIM_OP_DELETE), "4 4:1 2 3 4"
check "the last can't move later", plan$(ANIM_OP_LATER), "refused"
ANIM.current = 1
check "the first can't move earlier", plan$(ANIM_OP_EARLIER), "refused"
check "reverse from the first", plan$(ANIM_OP_REVERSE), "5 5:5 4 3 2 1"
ANIM.count = 1: ANIM.wanted = 1
check "the only frame can't be deleted", plan$(ANIM_OP_DELETE), "refused"
check "one frame: no reverse", plan$(ANIM_OP_REVERSE), "refused"
check "one frame: append", plan$(ANIM_OP_APPEND), "2 2:1 1"
ANIM_reset
check "no frames: refused", plan$(ANIM_OP_APPEND), "refused"
check "no frames: delete has a reason", STR$(LEN(ANIM_op_refusal$(ANIM_OP_DELETE)) > 0), STR$(TRUE)
check "no frames: add is allowed (it becomes frame 1)", ANIM_op_refusal$(ANIM_OP_APPEND), ""
check "no frames: add blank too", ANIM_op_refusal$(ANIM_OP_APPEND_BLANK), ""
SCRN.canvasW = 9000
check "too wide for a frame beside it", STR$(LEN(ANIM_op_refusal$(ANIM_OP_APPEND)) > 0), STR$(TRUE)
SCRN.canvasW = 64

' --- span / any-layout cell rects (resizing frames) ---
check "span of 3 cells", STR$(ANIM_span&(3, 16, 2, 3)), STR$(3 + 16 + 2 + 16 + 2 + 16 + 3)
check "span of 0 cells", STR$(ANIM_span&(0, 16, 2, 3)), STR$(6)
ANIM_rect_at 6, 4, 20, 10, 1, 2, x, y
check "rect of cell 6 in a 4-column 20x10 layout", STR$(x) + STR$(y), STR$(2 + 21) + STR$(2 + 11)

' --- the re-slice / resize answer belongs to the document ---
ANIM_SIZE_MODE = ANIM_SIZE_RESIZE
r = ANIM_set_layout%(16, 16, 0, 0): s = ANIM_serialize$
r = ANIM_deserialize%(s)
check "undo / redo (deserialize) keep the answer", STR$(ANIM_SIZE_MODE), STR$(ANIM_SIZE_RESIZE)
ANIM_reset
check "a new document asks again", STR$(ANIM_SIZE_MODE), STR$(ANIM_SIZE_ASK)

' --- the sheet grows by whole rows ---
r = ANIM_set_layout%(16, 16, 0, 0) ' 4 x 2 = 8 cells
check "8 frames fit 32 px", STR$(ANIM_sheet_h&(8)), STR$(32)
check "9 frames need a third row", STR$(ANIM_sheet_h&(9)), STR$(48)
r = ANIM_set_layout%(16, 16, 2, 3) ' 3 across, 1 down on 64x32
check "gutter + margin: 4 frames = 2 rows", STR$(ANIM_sheet_h&(4)), STR$(3 + 16 + 2 + 16 + 3)
SCRN.canvasH = 50
check "never shorter than the canvas", STR$(ANIM_sheet_h&(1)), STR$(50)
SCRN.canvasH = 32

' --- ANIM_apply_plan: holds follow their frames ---
ANIM_reset: r = ANIM_set_layout%(16, 16, 0, 0): ANIM.count = 4: ANIM.wanted = 4: ANIM.current = 2
ANIM_set_hold 1, 2: ANIM_set_hold 2, 3: ANIM_set_hold 3, 4: ANIM_set_hold 4, 5
r = ANIM_plan%(ANIM_OP_DUPLICATE, pc, pcur): ANIM_apply_plan pc, pcur
check "duplicate: count / wanted / current", STR$(ANIM.count) + STR$(ANIM.wanted) + STR$(ANIM.current), STR$(5) + STR$(5) + STR$(3)
check "duplicate: the copy keeps its hold", holds$(5), "2 3 3 4 5"
r = ANIM_plan%(ANIM_OP_INSERT_BEFORE, pc, pcur): ANIM_apply_plan pc, pcur
check "a blank frame holds 1", holds$(6), "2 3 1 3 4 5"
r = ANIM_plan%(ANIM_OP_DELETE, pc, pcur): ANIM_apply_plan pc, pcur
check "delete: the holds close up", holds$(6), "2 3 3 4 5 1"
check "delete: the freed hold is cleared", STR$(ANIM_HOLDS(6)), STR$(0)
r = ANIM_plan%(ANIM_OP_REVERSE, pc, pcur): ANIM_apply_plan pc, pcur
check "reverse: holds reversed", holds$(5), "5 4 3 3 2"

PRINT PASSES; "passed,"; FAILS; "failed"
IF FAILS THEN SYSTEM 1 ELSE SYSTEM 0

SUB check (label AS STRING, got AS STRING, want AS STRING)
    IF got = want THEN
        PASSES = PASSES + 1
    ELSE
        FAILS = FAILS + 1
        PRINT "FAIL "; label; ": got ["; got; "] want ["; want; "]"
    END IF
END SUB

''
' "count current:src1 src2 ..." for op, or "refused". Leaves ANIM as it was.
FUNCTION plan$ (op AS INTEGER)
    DIM nc AS INTEGER, ncur AS INTEGER, i AS INTEGER, t AS STRING
    IF ANIM_plan%(op, nc, ncur) = 0 THEN plan$ = "refused": EXIT FUNCTION
    t = _TRIM$(STR$(nc)) + " " + _TRIM$(STR$(ncur)) + ":"
    FOR i = 1 TO nc: t = t + _TRIM$(STR$(ANIM_SRC(i))) + " ": NEXT i
    plan$ = RTRIM$(t)
END FUNCTION

FUNCTION holds$ (n AS INTEGER)
    DIM i AS INTEGER, t AS STRING
    FOR i = 1 TO n: t = t + _TRIM$(STR$(ANIM_hold%(i))) + " ": NEXT i
    holds$ = RTRIM$(t)
END FUNCTION

'$INCLUDE:'../../TOOLS/ANIM.BM'
