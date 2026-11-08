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
r = ANIM_deserialize%(MKI$(9) + MID$(s, 3) + "future")
check "a version far ahead still loads its frames", STR$(r) + STR$(ANIM.count), STR$(TRUE) + STR$(7)

' --- the frames one loop shows (exports, 3.1) ---
SCRN.canvasW = 64: SCRN.canvasH = 32: ANIM_reset
check "no frames: no order", STR$(ANIM_play_order%), STR$(0)
r = ANIM_set_layout%(16, 16, 0, 0): ANIM.count = 4
check "forward", order$, "1 2 3 4"
ANIM.loopMode = ANIM_LOOP_REV: check "reverse", order$, "4 3 2 1"
ANIM.loopMode = ANIM_LOOP_PING: check "ping-pong written out", order$, "1 2 3 4 3 2"
ANIM.loopMode = ANIM_LOOP_ONCE: check "once", order$, "1 2 3 4"
ANIM.loopMode = ANIM_LOOP_PING: ANIM.count = 2: check "ping-pong of 2", order$, "1 2"
ANIM.count = 1: check "ping-pong of 1", order$, "1"
ANIM_reset

' --- layer flags (2.8): by historyId, saved after the holds, also without frames ---
ANIM_reset
ANIM_LF_set 7, ANIM_LF_REF: ANIM_LF_set 9, ANIM_LF_REF OR ANIM_LF_SAME
check "flags set", STR$(ANIM_LF_N) + STR$(ANIM_LF_get%(7)) + STR$(ANIM_LF_get%(9)) + STR$(ANIM_LF_get%(8)), STR$(2) + STR$(1) + STR$(3) + STR$(0)
s = ANIM_serialize$
check "a picture without frames saves its flags", STR$(LEN(s)), STR$(20 + 2 + 2 * 6)
ANIM_reset
check "reset drops the flags", STR$(ANIM_LF_N), STR$(0)
r = ANIM_deserialize%(s)
check "flags back, still no frames", STR$(r) + STR$(ANIM_LF_get%(7)) + STR$(ANIM_LF_get%(9)), STR$(FALSE) + STR$(1) + STR$(3)
ANIM_LF_set 7, 0
check "flag 0 drops the entry", STR$(ANIM_LF_N) + STR$(ANIM_LF_get%(7)) + STR$(ANIM_LF_get%(9)), STR$(1) + STR$(0) + STR$(3)
r = ANIM_set_layout%(16, 16, 0, 0): ANIM.count = 4: ANIM_set_hold 2, 3: s = ANIM_serialize$
ANIM_reset: r = ANIM_deserialize%(s)
check "with frames and holds", STR$(r) + STR$(ANIM.count) + STR$(ANIM_hold%(2)) + STR$(ANIM_LF_get%(9)), STR$(TRUE) + STR$(4) + STR$(3) + STR$(3)
r = ANIM_deserialize%(LEFT$(s, LEN(s) - 3))
check "truncated flags: frames load, the cut entry is left out", STR$(r) + STR$(ANIM.count) + STR$(ANIM_LF_N), STR$(TRUE) + STR$(4) + STR$(0)
r = ANIM_deserialize%(MKI$(1) + MID$(s, 3))
check "a version 1 blob: no flags read", STR$(r) + STR$(ANIM_LF_N), STR$(TRUE) + STR$(0)
ANIM_reset


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

' --- playback: the frames each loop mode steps through ---
SCRN.canvasW = 64: SCRN.canvasH = 32: ANIM_reset
r = ANIM_set_layout%(16, 16, 0, 0): ANIM.count = 4: ANIM.wanted = 4: ANIM.current = 1: ANIM_set_fps 10
ANIM.loopMode = ANIM_LOOP_FWD
check "fwd", playseq$(7), "1 2 3 4 1 2 3 4"
ANIM.loopMode = ANIM_LOOP_REV: ANIM.current = 3
check "rev from 3", playseq$(6), "3 2 1 4 3 2 1"
ANIM.loopMode = ANIM_LOOP_PING: ANIM.current = 2
check "ping-pong", playseq$(9), "2 3 4 3 2 1 2 3 4 3"
ANIM.loopMode = ANIM_LOOP_ONCE: ANIM.current = 2
check "once stops at the end", playseq$(6), "2 3 4 stop"
ANIM.current = 4: r = ANIM_play_start%(0, 0, 0)
check "once from the last frame starts over", STR$(ANIM.current), STR$(1)
ANIM.loopMode = ANIM_LOOP_FWD: ANIM.current = 1
r = ANIM_play_start%(2, 3, 0)
check "a range: starts inside it", STR$(r) + STR$(ANIM.current), STR$(TRUE) + STR$(2)
check "a range loops inside it", playseq$(4), "2 3 2 3 2"
ANIM.count = 1
check "one frame: nothing to play", STR$(ANIM_play_start%(0, 0, 0)), STR$(FALSE)
ANIM.count = 4

' --- playback timing: fps and holds ---
ANIM.loopMode = ANIM_LOOP_FWD: ANIM.current = 1: ANIM_set_hold 2, 3
r = ANIM_play_start%(0, 0, 100)
r = ANIM_play_advance%(100.05): check "not due yet (1 tick = 0.1 s at 10 fps)", STR$(r) + STR$(ANIM.current), STR$(FALSE) + STR$(1)
r = ANIM_play_advance%(100.1): check "due: frame 2", STR$(r) + STR$(ANIM.current), STR$(TRUE) + STR$(2)
r = ANIM_play_advance%(100.35): check "frame 2 holds 3 ticks", STR$(r) + STR$(ANIM.current), STR$(FALSE) + STR$(2)
r = ANIM_play_advance%(100.4): check "then frame 3", STR$(r) + STR$(ANIM.current), STR$(TRUE) + STR$(3)
r = ANIM_play_advance%(130)
check "a long stall: no burst after it", STR$(ANIM_PLAY.nextT > 130), STR$(TRUE)
ANIM.loopMode = ANIM_LOOP_ONCE: ANIM.current = 3: r = ANIM_play_start%(0, 0, 200)
r = ANIM_play_advance%(200.1): r = ANIM_play_advance%(200.2)
check "once: stopped on the last frame", STR$(ANIM_PLAY.playing) + STR$(ANIM.current), STR$(FALSE) + STR$(4)
r = ANIM_play_start%(0, 0, 0): ANIM_reset
check "a new document stops playback", STR$(ANIM_PLAY.playing), STR$(FALSE)

' --- the strip selection (2.3, R-12: the layers panel's rules) ---
SCRN.canvasW = 64: SCRN.canvasH = 32
r = ANIM_set_layout%(16, 16, 0, 0): ANIM.count = 7: ANIM.wanted = 7: ANIM.current = 3
check "nothing selected: the current frame is the selection", sel$ + "|" + STR$(ANIM_SEL_is%(3)), "|" + STR$(TRUE)
ANIM_SEL_click 5, FALSE, FALSE
check "click: current and the only one selected", sel$ + " c" + _TRIM$(STR$(ANIM.current)), "5 c5"
ANIM_SEL_click 2, TRUE, FALSE
check "ctrl+click adds, current follows", sel$ + " c" + _TRIM$(STR$(ANIM.current)), "2 5 c2"
ANIM_SEL_click 2, TRUE, FALSE
check "ctrl+click again takes it out; the nearest selected is current", sel$ + " c" + _TRIM$(STR$(ANIM.current)) + " a" + _TRIM$(STR$(ANIM_SEL_ANCHOR)), "5 c5 a2"
ANIM_SEL_click 5, FALSE, FALSE: ANIM_SEL_click 7, FALSE, TRUE
check "shift+click: a range from the anchor", sel$ + " c" + _TRIM$(STR$(ANIM.current)), "5 6 7 c7"
ANIM_SEL_click 1, TRUE, FALSE: ANIM_SEL_click 2, TRUE, TRUE
check "ctrl+shift+click adds a range", sel$, "1 2 5 6 7"
ANIM_SEL_click 4, FALSE, FALSE: ANIM_SEL_click 2, FALSE, TRUE
check "shift+click back from the anchor", sel$ + " c" + _TRIM$(STR$(ANIM.current)), "2 3 4 c2"
DIM sa AS INTEGER, sb AS INTEGER
ANIM_SEL_span sa, sb: check "playback plays the selected span", STR$(sa) + STR$(sb), STR$(2) + STR$(4)
ANIM_SEL_click 4, FALSE, FALSE: ANIM_SEL_span sa, sb
check "one frame selected: play them all", STR$(sa) + STR$(sb), STR$(0) + STR$(0)
ANIM_SEL_click 9, FALSE, FALSE
check "a click past the frames does nothing", sel$, "4"

' --- moving the selected frames (the strip's drag) ---
ANIM_SEL_click 2, FALSE, FALSE: ANIM_SEL_click 3, FALSE, TRUE ' 2-3 selected, current 3
ANIM_MOVE_TO = 6: check "2-3 dropped before 6", plan$(ANIM_OP_MOVE_SEL), "7 5:1 4 5 2 3 6 7"
ANIM_MOVE_TO = 8: check "2-3 dropped at the end", plan$(ANIM_OP_MOVE_SEL), "7 7:1 4 5 6 7 2 3"
ANIM_MOVE_TO = 1: check "2-3 dropped at the start", plan$(ANIM_OP_MOVE_SEL), "7 2:2 3 1 4 5 6 7"
ANIM_MOVE_TO = 2: check "dropped where they are: no step", plan$(ANIM_OP_MOVE_SEL), "refused"
ANIM_MOVE_TO = 4: check "dropped just after themselves: no step", plan$(ANIM_OP_MOVE_SEL), "refused"
ANIM_MOVE_TO = 9: check "past the end: refused", plan$(ANIM_OP_MOVE_SEL), "refused"
ANIM_SEL_click 6, FALSE, FALSE: ANIM_SEL_click 2, TRUE, FALSE ' 2 and 6 selected, current 2
ANIM_MOVE_TO = 4: check "a scattered selection lands together", plan$(ANIM_OP_MOVE_SEL), "7 3:1 3 2 6 4 5 7"
ANIM_set_hold 6, 4
r = ANIM_plan%(ANIM_OP_MOVE_SEL, pc, pcur): ANIM_apply_plan pc, pcur
check "the selection and holds go with their frames", sel$ + " h" + _TRIM$(STR$(ANIM_hold%(4))) + " c" + _TRIM$(STR$(ANIM.current)), "3 4 h4 c3"
ANIM_SEL_click 1, FALSE, FALSE
r = ANIM_plan%(ANIM_OP_INSERT_BEFORE, pc, pcur): ANIM_apply_plan pc, pcur
check "an inserted frame is not selected; the old one moves on", sel$, "2"
ANIM_reset: check "a new document: nothing selected", STR$(ANIM_SEL_count%), STR$(0)

' --- the lightbox's total (2.4) ---
r = ANIM_set_layout%(16, 16, 0, 0): ANIM.count = 7: ANIM.wanted = 7: ANIM.current = 3
ANIM_COUNT_TO = 9: check "total 9: two blank frames at the end", plan$(ANIM_OP_SET_COUNT), "9 3:1 2 3 4 5 6 7 0 0"
ANIM_COUNT_TO = 5: check "total 5: the last two dropped", plan$(ANIM_OP_SET_COUNT), "5 3:1 2 3 4 5"
ANIM.current = 6: ANIM_COUNT_TO = 4: check "total 4 from frame 6: current steps back", plan$(ANIM_OP_SET_COUNT), "4 4:1 2 3 4"
ANIM_COUNT_TO = 7: check "the same total: no step", plan$(ANIM_OP_SET_COUNT), "refused"
ANIM_COUNT_TO = 0: check "total 0: refused", plan$(ANIM_OP_SET_COUNT), "refused"
ANIM_COUNT_TO = ANIM_MAX_FRAMES + 1: check "past the most frames: refused", plan$(ANIM_OP_SET_COUNT), "refused"

' --- deleting the selected frames / inserting n blank ones (2.5 cut / paste) ---
ANIM.current = 3: ANIM_SEL_clear
check "nothing selected: delete the current frame", plan$(ANIM_OP_DELETE_SEL), "6 3:1 2 4 5 6 7"
ANIM_SEL_click 2, FALSE, FALSE: ANIM_SEL_click 4, FALSE, TRUE ' 2-4, current 4
check "2-4 cut: current is the frame after them", plan$(ANIM_OP_DELETE_SEL), "4 2:1 5 6 7"
ANIM_SEL_click 6, FALSE, FALSE: ANIM_SEL_click 7, FALSE, TRUE
check "6-7 cut: current is the last frame left", plan$(ANIM_OP_DELETE_SEL), "5 5:1 2 3 4 5"
ANIM_SEL_click 1, FALSE, FALSE: ANIM_SEL_click 7, FALSE, TRUE
check "all of them: refused", plan$(ANIM_OP_DELETE_SEL), "refused"
ANIM_SEL_clear: ANIM.current = 3: ANIM_COUNT_TO = 2
check "insert 2 after frame 3", plan$(ANIM_OP_INSERT_N), "9 4:1 2 3 0 0 4 5 6 7"
ANIM.current = 7: ANIM_COUNT_TO = 1
check "insert 1 after the last", plan$(ANIM_OP_INSERT_N), "8 8:1 2 3 4 5 6 7 0"
ANIM_COUNT_TO = 0: check "insert 0: refused", plan$(ANIM_OP_INSERT_N), "refused"
ANIM_COUNT_TO = ANIM_MAX_FRAMES: check "insert past the most frames: refused", plan$(ANIM_OP_INSERT_N), "refused"

' --- tags (4.4) ---
ANIM_reset: r = ANIM_set_layout%(16, 16, 0, 0): ANIM.count = 8: ANIM.wanted = 8: ANIM.current = 1
r = ANIM_TG_put%("walk", 2, 4): check "tag walk 2-4", tags$, "walk 2 4"
r = ANIM_TG_put%(" run ", 6, 5): check "tag run 6-5: trimmed, in order", tags$, "walk 2 4|run 5 6"
r = ANIM_TG_put%("WALK", 3, 7): check "the same name (any case) moves it", tags$, "WALK 3 7|run 5 6"
check "past the frames: refused", STR$(ANIM_TG_put%("x", 7, 9)), STR$(0)
check "no name: refused", STR$(ANIM_TG_put%("  ", 1, 2)), STR$(0)
check "the shortest tag at frame 5", STR$(ANIM_TG_at%(5)), STR$(2)
check "the tag at frame 3", STR$(ANIM_TG_at%(3)), STR$(1)
check "no tag at frame 1", STR$(ANIM_TG_at%(1)), STR$(0)
ANIM_TG_select 2: check "select run: its frames, the first current", sel$ + " c" + _TRIM$(STR$(ANIM.current)), "5 6 c5"
check "selection = run", STR$(ANIM_TG_selected%), STR$(2)
ANIM_SEL_click 7, FALSE, TRUE: check "selection 5-7: no tag", STR$(ANIM_TG_selected%), STR$(0)
s = ANIM_serialize$
check "saved as v4", STR$(CVI(LEFT$(s, 2))), STR$(ANIM_CHUNK_VERSION_TAGS)
r = ANIM_deserialize%(s): check "tags back after a load", tags$, "WALK 3 7|run 5 6"
ANIM_SEL_clear: ANIM.current = 4
r = ANIM_plan%(ANIM_OP_INSERT_BEFORE, pc, pcur): ANIM_apply_plan pc, pcur
check "a frame put inside a tag joins it", tags$, "WALK 3 8|run 6 7"
ANIM.current = 1: r = ANIM_plan%(ANIM_OP_DELETE, pc, pcur): ANIM_apply_plan pc, pcur
check "a frame deleted before them: they move up", tags$, "WALK 2 7|run 5 6"
ANIM_SEL_click 5, FALSE, FALSE: ANIM_SEL_click 6, FALSE, TRUE
r = ANIM_plan%(ANIM_OP_DELETE_SEL, pc, pcur): ANIM_apply_plan pc, pcur
check "all of a tag's frames deleted: it goes", tags$, "WALK 2 5"
ANIM_EXP_A = 2: ANIM_EXP_B = 4: ANIM.loopMode = ANIM_LOOP_PING
r = ANIM_play_order%: s = "": FOR i = 1 TO r: s = s + _TRIM$(STR$(ANIM_ORDER(i))) + " ": NEXT i
check "a tag's play order (ping-pong)", RTRIM$(s), "2 3 4 3"
ANIM_EXP_A = 0: ANIM_EXP_B = 0: ANIM.loopMode = ANIM_LOOP_FWD
ANIM_TG_remove 1: check "removed", STR$(ANIM_TG_N), STR$(0)
check "no tags: not v4", STR$(CVI(LEFT$(ANIM_serialize$, 2)) = ANIM_CHUNK_VERSION_TAGS), STR$(FALSE)
ANIM_reset

' --- frame notes (4.5) ---
ANIM_reset: r = ANIM_set_layout%(16, 16, 0, 0): ANIM.count = 6: ANIM.wanted = 6: ANIM.current = 1
check "no notes: not v5", STR$(CVI(LEFT$(ANIM_serialize$, 2)) = ANIM_CHUNK_VERSION_NOTES), STR$(FALSE)
ANIM_NT_set 2, "  foot " + CHR$(9) + "down  ": ANIM_NT_set 5, "ka-"
check "notes set (trimmed, control characters dropped)", notes$, "2=foot down|5=ka-"
ANIM_NT_set 3, STRING$(200, "x"): check "a note is cut at ANIM_NOTE_MAX", STR$(LEN(ANIM_NOTE(3))), STR$(ANIM_NOTE_MAX)
ANIM_NT_set 3, "": check "an empty note clears it", STR$(ANIM_NT_count%), STR$(2)
s = ANIM_serialize$: check "saved as v5", STR$(CVI(LEFT$(s, 2))), STR$(ANIM_CHUNK_VERSION_NOTES)
r = ANIM_deserialize%(s): check "notes back after a load", notes$, "2=foot down|5=ka-"
r = ANIM_TG_put%("hit", 4, 6): s = ANIM_serialize$: r = ANIM_deserialize%(s)
check "notes and tags both back", notes$ + " " + tags$, "2=foot down|5=ka- hit 4 6"
ANIM.current = 2: r = ANIM_plan%(ANIM_OP_DUPLICATE, pc, pcur): ANIM_apply_plan pc, pcur
check "a duplicate has no note", notes$, "2=foot down|6=ka-"
ANIM.current = 1: r = ANIM_plan%(ANIM_OP_REVERSE, pc, pcur): ANIM_apply_plan pc, pcur
check "reversed: the notes go with their frames", notes$, "2=ka-|6=foot down"
ANIM.current = 2: r = ANIM_plan%(ANIM_OP_DELETE, pc, pcur): ANIM_apply_plan pc, pcur
check "a frame deleted: its note goes", notes$, "5=foot down"
ANIM_reset: check "a new document: no notes", STR$(LEN(ANIM_NOTE(5))), STR$(0)

' --- soundtrack (L.1) ---
ANIM_reset: r = ANIM_set_layout%(16, 16, 0, 0): ANIM.count = 6: ANIM.wanted = 6: ANIM.current = 1
ANIM_SND_PATH = "/tmp/a b/beat.ogg": ANIM_SND_OFS = 250
s = ANIM_serialize$: check "a soundtrack: saved as v6", STR$(CVI(LEFT$(s, 2))), STR$(ANIM_CHUNK_VERSION_SOUND)
ANIM_SND_PATH = "": r = ANIM_deserialize%(s): check "the soundtrack back after a load", ANIM_SND_PATH + STR$(ANIM_SND_OFS), "/tmp/a b/beat.ogg 250"
ANIM_NT_set 2, "hit": r = ANIM_TG_put%("go", 1, 3): s = ANIM_serialize$: r = ANIM_deserialize%(s)
check "with notes and tags: all three back", ANIM_SND_PATH + " " + notes$ + " " + tags$, "/tmp/a b/beat.ogg 2=hit go 1 3"
ANIM_reset: check "a new document: no soundtrack", "[" + ANIM_SND_PATH + "]", "[]"

' --- Detect Frames (5.3) ---
check "4 sprites in 64 px: 16 wide, no gutter", dt$(sheet$(4, 16, 0, 0, 3, 10), sheet$(1, 16, 0, 0, 2, 12)), "16x16 g0 m0"
check "gutter 1: 67 px = 4 x 16 + 3", dt$(sheet$(4, 16, 1, 0, 3, 10), sheet$(2, 16, 1, 0, 2, 12)), "16x16 g1 m0"
check "margin 2 + gutter 2 (cells drawn edge to edge)", dt$(sheet$(3, 10, 2, 2, 0, 9), sheet$(2, 12, 2, 2, 0, 11)), "10x12 g2 m2"
check "sprites clear of their edges: the plainest grid that holds them", dt$(sheet$(3, 10, 2, 2, 1, 8), sheet$(2, 12, 2, 2, 1, 10)), "12x14 g0 m1"
check "one row: the height is the sheet's", dt$(sheet$(5, 8, 0, 0, 1, 6), "..####.."), "8x8 g0 m0"
check "one column, gutter 1", dt$("..####..", sheet$(3, 8, 1, 0, 1, 6)), "8x8 g1 m0"
check "a sprite with a gap is not split (its extent is filled)", dt$(sheet$(2, 16, 0, 0, 2, 14), "#"), "16x1 g0 m0"
check "same-size sprites centred in plain cells: not a gutter", dt$(sheet$(4, 16, 0, 0, 4, 11), "#"), "16x1 g0 m0"
check "full cells, gutter 1, margin 1 (all round), one row", dt$(sheet$(3, 12, 1, 1, 0, 11), ".######."), "12x6 g1 m1"
check "a detached foot does not make narrower cells (runs stay whole)", dt$("..#########.#..." + "..#########.#...", "#"), "16x1 g0 m0"
check "touching sprites: no grid", dt$(STRING$(64, "#"), STRING$(16, "#")), "none"
check "one sprite: no grid", dt$("...####...", "..##.."), "none"
check "nothing drawn: no grid", dt$(STRING$(32, "."), STRING$(16, ".")), "none"

PRINT PASSES; "passed,"; FAILS; "failed"
IF FAILS THEN SYSTEM 1 ELSE SYSTEM 0

FUNCTION order$ ()
    DIM n AS INTEGER, k AS INTEGER, o AS STRING
    n = ANIM_play_order%
    FOR k = 1 TO n: o = o + _TRIM$(STR$(ANIM_ORDER(k))) + " ": NEXT k
    order$ = RTRIM$(o)
END FUNCTION

''
' A mask of n cells of size c (gutter g, margin m), "#" over a..b of each cell.
FUNCTION sheet$ (n AS INTEGER, c AS INTEGER, g AS INTEGER, m AS INTEGER, a AS INTEGER, b AS INTEGER)
    DIM t AS STRING, k AS INTEGER, i AS INTEGER
    t = STRING$(m, ".")
    FOR k = 1 TO n
        FOR i = 0 TO c - 1
            IF i >= a _ANDALSO i <= b THEN t = t + "#" ELSE t = t + "."
        NEXT i
        IF k < n THEN t = t + STRING$(g, ".")
    NEXT k
    sheet$ = t + STRING$(m, ".")
END FUNCTION

FUNCTION dt$ (mx AS STRING, my AS STRING)
    DIM fw AS INTEGER, fh AS INTEGER, g AS INTEGER, m AS INTEGER
    IF ANIM_DT_solve%(mx, my, fw, fh, g, m) = 0 THEN dt$ = "none": EXIT FUNCTION
    dt$ = _TRIM$(STR$(fw)) + "x" + _TRIM$(STR$(fh)) + " g" + _TRIM$(STR$(g)) + " m" + _TRIM$(STR$(m))
END FUNCTION

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

FUNCTION sel$ ()
    DIM i AS INTEGER, t AS STRING
    FOR i = 1 TO ANIM.count: IF ANIM_SEL(i) THEN t = t + _TRIM$(STR$(i)) + " "
    NEXT i
    sel$ = RTRIM$(t)
END FUNCTION

FUNCTION notes$ ()
    DIM f AS INTEGER, t AS STRING
    FOR f = 1 TO ANIM.count
        IF LEN(ANIM_NOTE(f)) > 0 THEN t = t + _IIF(LEN(t) > 0, "|", "") + _TRIM$(STR$(f)) + "=" + ANIM_NOTE(f)
    NEXT f
    notes$ = t
END FUNCTION

FUNCTION tags$ ()
    DIM k AS INTEGER, t AS STRING
    FOR k = 1 TO ANIM_TG_N: t = t + _IIF(k > 1, "|", "") + ANIM_TG_NAME(k) + STR$(ANIM_TG_A(k)) + STR$(ANIM_TG_B(k)): NEXT k
    tags$ = t
END FUNCTION

FUNCTION holds$ (n AS INTEGER)
    DIM i AS INTEGER, t AS STRING
    FOR i = 1 TO n: t = t + _TRIM$(STR$(ANIM_hold%(i))) + " ": NEXT i
    holds$ = RTRIM$(t)
END FUNCTION

''
' The current frame then n steps of ANIM_play_next% ("stop" when it ends).
' Starts playback over the whole range first unless one is already set up.
FUNCTION playseq$ (n AS INTEGER)
    DIM t AS STRING, i AS INTEGER, f AS INTEGER, r AS INTEGER
    IF ANIM_PLAY.playing = FALSE _ORELSE ANIM_PLAY.toF > ANIM.count THEN r = ANIM_play_start%(0, 0, 0)
    t = _TRIM$(STR$(ANIM.current))
    FOR i = 1 TO n
        f = ANIM_play_next%
        IF f = 0 THEN t = t + " stop": EXIT FOR
        ANIM.current = f: t = t + " " + _TRIM$(STR$(f))
    NEXT i
    ANIM_PLAY.playing = FALSE
    playseq$ = t
END FUNCTION

'$INCLUDE:'../../TOOLS/ANIM.BM'
