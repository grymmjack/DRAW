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
check "re-slice keeps a count that fits", STR$(ANIM.count), STR$(3)
ANIM.count = 5
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

'$INCLUDE:'../../TOOLS/ANIM.BM'
