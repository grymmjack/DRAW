' =============================================================================
' QA/unit/pcyc-unit.bas - headless unit test for GUI/PALETTE-CYCLE.BM
' (shift math, range bookkeeping, serialization, buffer remap). Stubs the few
' DRAW globals the module touches. Build + run:
'   ~/git/qb64pe/qb64pe -w -x -o pcyc-unit.run pcyc-unit.bas && ./pcyc-unit.run
' Exit code 0 = all pass.
' =============================================================================
$CONSOLE:ONLY
OPTION _EXPLICIT
CONST TRUE = -1, FALSE = 0
TYPE COLOR_OBJ
    name  AS STRING
    value AS _UNSIGNED LONG
END TYPE
TYPE PALETTE_OPS_OBJ
    ACTIVE  AS INTEGER
    SEL_IDX AS INTEGER
END TYPE
TYPE MOUSE_STUB
    B1 AS INTEGER
    B2 AS INTEGER
    B3 AS INTEGER
END TYPE
TYPE MOD_STUB
    ctrl  AS INTEGER
    shift AS INTEGER
END TYPE
TYPE SCRN_STUB
    canvasW AS LONG
    canvasH AS LONG
END TYPE
DIM SHARED MOUSE AS MOUSE_STUB, MODIFIERS AS MOD_STUB, SCRN AS SCRN_STUB
DIM SHARED PAL(0 TO 255) AS COLOR_OBJ, PAL_COLOR_COUNT AS INTEGER
DIM SHARED SCENE_DIRTY AS INTEGER, GUI_NEEDS_REDRAW AS INTEGER, FRAME_IDLE AS INTEGER
DIM SHARED SCREEN_RENDER_SEQ AS LONG, PALETTE_STRIP_HOVER_IDX AS INTEGER
DIM SHARED PALETTE_OPS AS PALETTE_OPS_OBJ, PALETTE_OPS_MARKED(0 TO 255) AS INTEGER
DIM SHARED PAL_FG_IS_TRANSPARENT AS INTEGER, PAL_FG_IDX AS INTEGER
DIM SHARED FAILS AS INTEGER, PASSES AS INTEGER
'$INCLUDE:'../../GUI/PALETTE-CYCLE.BI'
'$INCLUDE:'../../OUTPUT/PAL-INDEX.BI'

DIM i AS INTEGER, s AS STRING, r AS INTEGER
PAL_COLOR_COUNT = 16
FOR i = 0 TO 15: PAL(i).value = _RGB32(i * 10, i * 5, 200 - i): NEXT

' --- shift math ---
r = PCYC_add_range%(2, 5, PCYC_RATE_UNIT, PCYC_FWD) ' n = 4
s = "": FOR i = 0 TO 5: s = s + _TRIM$(STR$(PCYC_shift_at%(r, i))): NEXT
check "FWD shifts", s, "012301"
PCYC_R(r).cmode = PCYC_REV
s = "": FOR i = 0 TO 5: s = s + _TRIM$(STR$(PCYC_shift_at%(r, i))): NEXT
check "REV shifts", s, "032103"
PCYC_R(r).cmode = PCYC_PING
s = "": FOR i = 0 TO 7: s = s + _TRIM$(STR$(PCYC_shift_at%(r, i))): NEXT
check "PING shifts", s, "01232101"
check "PING period", STR$(PCYC_period&(r)), STR$(6)
PCYC_R(r).cmode = PCYC_FWD
check "period FWD", STR$(PCYC_period&(r)), STR$(4)
PCYC.ENABLED = TRUE
PCYC_R(r).shift = 1
' chip lo+j shows PAL(lo + (j - s) mod n): j=0 -> 3 -> idx 5
check "display idx 2 @shift1", STR$(PCYC_display_index%(2)), STR$(5)
check "display idx 3 @shift1", STR$(PCYC_display_index%(3)), STR$(2)
check "display outside", STR$(PCYC_display_index%(9)), STR$(9)
PCYC_R(r).shift = 0

' --- rate conversions ---
check "sps 16384", STR$(PCYC_sps!(16384)), STR$(60!)
check "rate for 10/s", STR$(PCYC_rate_for&(10)), STR$(2731)

' --- add / overlap / sort ---
r = PCYC_add_range%(10, 8, 1000, PCYC_REV)  ' reversed args
check "count 2", STR$(PCYC.COUNT), STR$(2)
check "sorted 2nd lo", STR$(PCYC_R(2).lo), STR$(8)
r = PCYC_add_range%(4, 9, 500, PCYC_FWD)    ' overlaps both -> replaces both
check "overlap replaces", STR$(PCYC.COUNT), STR$(1)
check "overlap span", ranges$, "4-9"
r = PCYC_add_range%(0, 1, 500, PCYC_FWD)
r = PCYC_add_range%(12, 15, 500, PCYC_FWD)
check "three ranges", ranges$, "0-1,4-9,12-15"
check "range_at 7", STR$(PCYC_range_at%(7)), STR$(2)
check "range_at 11", STR$(PCYC_range_at%(11)), STR$(0)
check "refuse 1-color", STR$(PCYC_add_range%(11, 11, 1, 0)), STR$(0)

' --- bookkeeping ---
PCYC_on_delete 5            ' inside 4-9 -> 4-8; 12-15 -> 11-14
check "delete inside", ranges$, "0-1,4-8,11-14"
PCYC_on_delete 0            ' 0-1 -> 0-0 dropped
check "delete drops", ranges$, "3-7,10-13"
PCYC_on_insert 6            ' inside 3-7 -> 3-8 ; 10-13 -> 11-14
check "insert grows", ranges$, "3-8,11-14"
PCYC_on_insert 3            ' at start -> shifts
check "insert at start shifts", ranges$, "4-9,12-15"
' reorder: reverse 0..15 -> 4-9 becomes 6-11 (contiguous), 12-15 -> 0-3
DIM ord(0 TO 255) AS INTEGER
FOR i = 0 TO 15: ord(i) = 15 - i: NEXT
PCYC_on_reorder ord(), 16
check "reorder follows", ranges$, "0-3,6-11"
' reorder that scatters range 0-3: swap 1 and 8 -> keeps span
FOR i = 0 TO 15: ord(i) = i: NEXT
ord(1) = 8: ord(8) = 1
PCYC_on_reorder ord(), 16
check "reorder scattered keeps span", ranges$, "0-3,6-11"

' --- validate on palette shrink ---
PAL_COLOR_COUNT = 8
PCYC_validate
check "validate clips", ranges$, "0-3,6-7"
PAL_COLOR_COUNT = 16

' --- serialize round trip ---
PCYC_R(1).cmode = PCYC_PING: PCYC_R(1).active = FALSE: PCYC_R(1).heldStep = 7: PCYC_R(1).rate = 1234
s = PCYC_serialize$
PCYC.COUNT = 0
DIM used AS LONG
used = PCYC_deserialize&("xx" + s, 3)
check "deser bytes", STR$(used), STR$(LEN(s))
check "deser ranges", ranges$, "0-3,6-7"
check "deser fields", STR$(PCYC_R(1).cmode) + STR$(PCYC_R(1).active) + STR$(PCYC_R(1).heldStep) + STR$(PCYC_R(1).rate), STR$(PCYC_PING) + STR$(0) + STR$(7) + STR$(1234)
check "deser bad", STR$(PCYC_deserialize&(MKI$(99), 1)), STR$(0)

' --- duplicates ---
DIM fl(0 TO 255) AS INTEGER
PAL(2).value = PAL(14).value ' chip 2 (in 0-3) duplicates nothing earlier... make 6 dup of 1
PAL(6).value = PAL(1).value
check "blocked count", STR$(PCYC_blocked_count%(fl())), STR$(1)
check "blocked flag 6", STR$(fl(6)), STR$(TRUE)

' --- present: cycled buffer, composite untouched ---
FOR i = 0 TO 15: PAL(i).value = _RGB32(i * 16, 0, 0): NEXT
PCYC.COUNT = 0
r = PCYC_add_range%(1, 3, PCYC_RATE_UNIT, PCYC_FWD)
DIM comp AS LONG, outI AS LONG
comp = _NEWIMAGE(4, 1, 32)
_DEST comp: _DONTBLEND comp: PSET (0, 0), PAL(1).value: PSET (1, 0), PAL(2).value: PSET (2, 0), _RGBA32(48, 0, 0, 128): PSET (3, 0), PAL(9).value: _DEST _CONSOLE
SCREEN_RENDER_SEQ = 1
outI = PCYC_present&(comp)
check "present shift0 same", pxs$(outI), pxs$(comp)
PCYC_R(1).shift = 1: SCREEN_RENDER_SEQ = 2
outI = PCYC_present&(comp)
' shift 1: idx1 shows PAL(3), idx2 shows PAL(1), idx3 (alpha 128) shows PAL(2) w/ alpha kept, idx 9 untouched
check "present shift1", pxs$(outI), HEX$(PAL(3).value) + " " + HEX$(PAL(1).value) + " " + HEX$(&H80000000 OR (PAL(2).value AND &HFFFFFF)) + " " + HEX$(PAL(9).value)
check "composite untouched", HEX$(POINTat~&(comp, 0)), HEX$(PAL(1).value)
PCYC.ENABLED = FALSE
check "present off -> comp", STR$(PCYC_present&(comp)), STR$(comp)

' --- indexer (OUTPUT/PAL-INDEX) ---
PCYC.COUNT = 0
FOR i = 0 TO 15: PAL(i).value = _RGB32(i * 16, i * 16, i * 16): NEXT
PAL(5).value = PAL(2).value ' duplicate: first index (2) wins
r = PCYC_add_range%(6, 8, 1000, PCYC_FWD)
DIM im AS LONG, ix AS STRING
im = _NEWIMAGE(5, 1, 32)
_DEST im: _DONTBLEND im
PSET (0, 0), PAL(3).value                ' exact -> 3
PSET (1, 0), PAL(5).value                ' dup of 2 -> 2
PSET (2, 0), _RGB32(7 * 16 + 2, 7 * 16, 7 * 16) ' nearest is 7 (in range) -> must skip to 9 or 5..: non-range nearest = 9? (9*16=144) vs 5? -> 5 is dup of 2 (32) -> choose 9 (144) or 4? (64)
PSET (3, 0), _RGBA32(255, 0, 0, 10)      ' transparent -> 16
PSET (4, 0), PAL(7).value                ' exact range color -> 7
_DEST _CONSOLE
ix = IDX_index_image$(im, IDX_transparent_slot%)
check "idx exact", STR$(ASC(ix, 1)), STR$(3)
check "idx dup first wins", STR$(ASC(ix, 2)), STR$(2)
check "idx nearest skips range", STR$(ASC(ix, 3) < 6 OR ASC(ix, 3) > 8), STR$(TRUE)
check "idx transparent slot", STR$(ASC(ix, 4)), STR$(16)
check "idx exact range color", STR$(ASC(ix, 5)), STR$(7)
check "idx counters", STR$(IDX_QUANTIZED) + STR$(IDX_TRANSPARENT), STR$(1) + STR$(1)

PRINT
PRINT "PASSED"; PASSES; " FAILED"; FAILS
IF FAILS THEN SYSTEM 1 ELSE SYSTEM 0

FUNCTION ranges$
    DIM i AS INTEGER, s AS STRING
    FOR i = 1 TO PCYC.COUNT
        IF i > 1 THEN s = s + ","
        s = s + _TRIM$(STR$(PCYC_R(i).lo)) + "-" + _TRIM$(STR$(PCYC_R(i).hi))
    NEXT
    ranges$ = s
END FUNCTION

FUNCTION POINTat~& (img AS LONG, x AS INTEGER)
    DIM os AS LONG: os = _SOURCE: _SOURCE img: POINTat~& = POINT(x, 0): _SOURCE os
END FUNCTION

FUNCTION pxs$ (img AS LONG)
    DIM i AS INTEGER, s AS STRING
    FOR i = 0 TO _WIDTH(img) - 1
        IF i > 0 THEN s = s + " "
        s = s + HEX$(POINTat~&(img, i))
    NEXT
    pxs$ = s
END FUNCTION

SUB check (label AS STRING, got AS STRING, want AS STRING)
    IF got = want THEN
        PASSES = PASSES + 1
    ELSE
        FAILS = FAILS + 1
        PRINT "FAIL "; label; ": got ["; got; "] want ["; want; "]"
    END IF
END SUB

' --- stubs for DRAW globals the module calls ---
SUB SAFE_FREEIMAGE (h AS LONG)
    IF h < -1 THEN _FREEIMAGE h
    h = 0
END SUB
SUB HISTORY_record_palette (a AS STRING, b AS STRING, l AS STRING)
END SUB
FUNCTION PALETTE_snapshot$
    PALETTE_snapshot$ = ""
END FUNCTION
SUB STATUS_flash (m AS STRING)
END SUB
FUNCTION PALETTE_OPS_calc_strip_index% (x AS INTEGER, y AS INTEGER)
    PALETTE_OPS_calc_strip_index% = -1
END FUNCTION
FUNCTION PALETTE_STRIP_in_bounds% (x AS INTEGER, y AS INTEGER)
    PALETTE_STRIP_in_bounds% = FALSE
END FUNCTION

'$INCLUDE:'../../GUI/PALETTE-CYCLE.BM'
'$INCLUDE:'../../OUTPUT/PAL-INDEX.BM'
