#!/bin/bash
# =============================================================================
# file-export-qb64-fill.sh — QA test: QB64 Code export keeps shapes under a fill
#
# Bug report (2.3.3, Windows): three filled rectangles in different colors, then
# a flood fill around them. The exported program showed the fill color over
# every rectangle except the last one drawn: the export wrote
# PAINT (x, y), fill, <color of the last shape>, and PAINT only stops at that
# one color. DRAW's fill replaces the connected area of the clicked color; the
# export now does the same (FloodFill helper).
#
#   1. Filled rects in chips 4, 9, 12; fill the background with chip 15.
#   2. Export As BMP (DRAW's own pixels) and Export QB64 Project (Ctrl+Shift+Q).
#   3. Compile the exported .bas (made to save its screen and quit) and compare
#      its image with the BMP: every pixel must match.
# =============================================================================

info "=== QB64 export: fill around shapes ==="

QF_DIR="$HOME"
QF_NAME="draw-qa-qb64fill-$$"
QF_BAS="$QF_DIR/$QF_NAME.bas"
QF_BMP="$QF_DIR/$QF_NAME.bmp"
QF_WORK="$(mktemp -d)"
QB64PE_BIN="${QB64PE:-$HOME/git/qb64pe/qb64pe}"

qf_cleanup() {
    [[ -n "$QF_KEEP" ]] && { info "QF_KEEP: left $QF_BAS and $QF_WORK"; return; }
    rm -rf "$QF_WORK" "$QF_DIR/${QF_NAME}_ASSETS"
    rm -f "$QF_BAS" "$QF_BMP"
}
rm -f "$QF_BAS" "$QF_BMP"

CHIP_W=${PALETTE_CHIP_WIDTH:-16}
chip_x() { echo $(( 16 + $1 * (CHIP_W + 1) + CHIP_W / 2 )); }
CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))

# -- 1. Three filled rectangles, each its own color --
canvas_focus r
wait_for 0.3 "Rectangle tool"
key shift+r
wait_for 0.3 "Filled rectangle"
key grave
wait_for 0.1 "Pointer arrow hidden"

click $(chip_x 4) $CHIP_Y
wait_for 0.2 "FG = chip 4"
drag $(( CANVAS_CX - 50 )) $(( CANVAS_CY - 30 )) $(( CANVAS_CX - 25 )) $(( CANVAS_CY + 10 ))
wait_for 0.4 "Rect 1"

click $(chip_x 9) $CHIP_Y
wait_for 0.2 "FG = chip 9"
drag $(( CANVAS_CX + 10 )) $(( CANVAS_CY - 20 )) $(( CANVAS_CX + 40 )) $(( CANVAS_CY + 25 ))
wait_for 0.4 "Rect 2"

click $(chip_x 12) $CHIP_Y
wait_for 0.2 "FG = chip 12"
drag $(( CANVAS_CX - 40 )) $(( CANVAS_CY + 20 )) $(( CANVAS_CX )) $(( CANVAS_CY + 35 ))
wait_for 0.4 "Rect 3"
assert_no_crash

# -- Fill around them --
key f
wait_for 0.3 "Fill tool"
click $(chip_x 15) $CHIP_Y
wait_for 0.2 "FG = chip 15"
click $(( CANVAS_CX + 60 )) $(( CANVAS_CY - 45 ))
wait_for 0.6 "Background filled"
assert_no_crash
park_mouse
screenshot "qb64fill-canvas"

# -- 2a. DRAW's own pixels: Export As BMP --
info "Export As BMP via command palette"
key question
wait_for 0.5 "Command palette"
type_text "export as bmp"
wait_for 0.3 "Filter"
key Return
wait_for 1.2 "Export dialog open"
type_text "$QF_NAME.bmp"
wait_for 0.3 "Name typed"
key Return
wait_for 1.5 "BMP written"
assert_no_crash

# -- 2b. Export QB64 Project --
info "Ctrl+Shift+Q (export QB64 project)"
key ctrl+shift+q
wait_for 1.2 "Export dialog open"
key ctrl+a
type_text "$QF_NAME.bas"
wait_for 0.3 "Name typed"
key Return
wait_for 1.5 "QB64 project written"
key Return
wait_for 0.5 "Export alert dismissed"
assert_no_crash

if [[ ! -s "$QF_BMP" ]]; then
    fail "Export As BMP did not write $QF_BMP"
    qf_cleanup; return 0 2>/dev/null || exit 0
fi
if [[ ! -s "$QF_BAS" ]]; then
    fail "Export QB64 Project did not write $QF_BAS"
    qf_cleanup; return 0 2>/dev/null || exit 0
fi
pass "Both exports written"

if grep -q '^ *PAINT ' "$QF_BAS"; then
    fail "Export still uses PAINT for the fill: $(grep -m1 '^ *PAINT ' "$QF_BAS")"
else
    pass "Export has no PAINT"
fi
if grep -q '^ *FloodFill ' "$QF_BAS"; then
    pass "Fill exported as FloodFill"
else
    fail "No FloodFill call in the export"
fi

# -- 3. Run the export headless: draw to an image, save it, quit --
if [[ ! -x "$QB64PE_BIN" ]]; then
    info "No QB64-PE compiler at $QB64PE_BIN - skipping the pixel comparison"
    qf_cleanup; return 0 2>/dev/null || exit 0
fi
{
    echo '$CONSOLE:ONLY'
    sed -e 's/^SCREEN _NEWIMAGE(CANVAS_W, CANVAS_H, 32)$/DIM SHARED qaScreen AS LONG: qaScreen = _NEWIMAGE(CANVAS_W, CANVAS_H, 32): _DEST qaScreen/' \
        -e 's/^_DEST 0$/_DEST qaScreen/' \
        -e 's/^LOOP UNTIL _KEYHIT = 27$/LOOP WHILE 0/' \
        -e 's/^_DISPLAY$//' \
        -e "s|^Cleanup\$|_SAVEIMAGE \"$QF_WORK/out.png\", qaScreen: Cleanup|" \
        <(tr -d '\r' < "$QF_BAS")   # QB64 PRINT # writes CRLF
} > "$QF_WORK/run.bas"
if ! "$QB64PE_BIN" -w -x -o "$QF_WORK/run" "$QF_WORK/run.bas" > "$QF_WORK/compile.log" 2>&1; then
    fail "Exported program does not compile: $(grep -m3 -iE 'error|line' "$QF_WORK/compile.log" | tr '\n' ' ')"
    qf_cleanup; return 0 2>/dev/null || exit 0
fi
pass "Exported program compiles"
( cd "$QF_DIR" && timeout 30 "$QF_WORK/run" > /dev/null 2>&1 )
if [[ ! -s "$QF_WORK/out.png" ]]; then
    fail "Exported program wrote no image"
    qf_cleanup; return 0 2>/dev/null || exit 0
fi

DIFF_PX=$(compare -metric AE "$QF_BMP" "$QF_WORK/out.png" null: 2>&1 | awk '{print $1}')
if [[ "$DIFF_PX" == "0" ]]; then
    pass "Exported program draws exactly DRAW's image (0 pixels differ)"
else
    cp "$QF_WORK/out.png" "${QA_OUT_DIR:-/tmp}/qb64fill-program-out.png" 2>/dev/null
    fail "Exported program differs from DRAW's image in $DIFF_PX pixels"
fi

qf_cleanup
assert_window_exists
info "=== QB64 export fill test done ==="
