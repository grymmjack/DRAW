#!/bin/bash
# =============================================================================
# dock-browser-scroll.sh — QA test: a docked Browser scrolls a long thumbnail
# list all the way down (Rick 2026-11-16, GRAFX 2 workspace: Browser in a left
# column, thumbnails, 724 files - "the browser won't scroll", no scrollbar).
# FILE_DIALOG kept the list's height and scroll offset in INTEGERs: one column
# of 724 thumbnail cells is ~113k px, which wrapped negative, so maxScroll was 0
# (no scrollbar, the wheel clamped to 0); a shorter list wrapped positive and
# cut the end of the list off instead.
#   - 724 files, Browser docked left at WIDTH:312 (as in grafx2.workspace)
#   - BROWSERSC: maxScroll covers every row of cells (> 32767 here)
#   - the wheel over the list scrolls it
#   - drag the scrollbar's thumb down: the list scrolls to its end (FILE_DIALOG
#     had no scrollbar drag - only the wheel)
#   - the pointer off the Browser: the thumbnails at the end still load (they
#     loaded only while the pointer was over it)
# Dump: BROWSERS ... scroll count view | BROWSERSC maxScroll contentW contentH cellW cellH loaded lastLoaded
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE BROWSER_VISIBLE=1 DOCK_CUSTOM=1 DOCK_LEFT_1=WIDTH:312;browser DOCK_RIGHT_1=AUTO;toolbox|layers BROWSER_SCALE=2 BROWSER_DEFAULT_VIEW_MODE=2 BROWSER_DEFAULT_ZOOM_LEVEL=2 BROWSER_DEFAULT_PREVIEW_OPEN=-1 BROWSER_PLACES_MIN_W=175 BROWSER_PREVIEW_MIN_W=200
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Browser: a docked Browser scrolls a long thumbnail list ==="

N=724
SC_DIR="/tmp/draw-qa-brsc-$$"
mkdir -p "$SC_DIR"
magick -size 16x16 xc:red "PNG32:$SC_DIR/f-000.png"
for (( i = 1; i < N; i++ )); do cp "$SC_DIR/f-000.png" "$SC_DIR/$(printf 'f-%03d.png' "$i")"; done
draw_quit
draw_settle
DRAW_TEST_OPTIONS+=" --option BROWSER_DEFAULT_FOLDER=$SC_DIR"
draw_launch 15
wait_for 1.5 "launched, the Browser at $SC_DIR"
dk_begin

bs()  { read -r _ BS_VIS BS_SEL BS_LAST BS_ROWH BS_TOP BS_SCROLL BS_N BS_VIEW _ <<< "$(grep -m1 '^BROWSERS ' "$DK_DUMP")"; }
bsc() { read -r _ SC_MAX SC_CW SC_CH SC_CELLW SC_CELLH SC_LOADED SC_LASTOK _ <<< "$(grep -m1 '^BROWSERSC ' "$DK_DUMP")"; }
bwin() { read -r _ _ WX WY WW WH _ <<< "$(grep -m1 '^WIN browser ' "$DK_DUMP")"; read -r _ _ LX _ _ _ _ DW _ <<< "$(grep -m1 '^BROWSERL' "$DK_DUMP")"; }
done_test() { rm -rf "$SC_DIR"; assert_no_crash; exit 0; }

for t in 1 2 3 4 5 6; do bs; (( ${BS_N:-0} >= N )) && break; wait_for 1.0 "the folder listing"; dk_settle; done
bs; bsc; bwin
info "browser $WX,$WY ${WW}x$WH (dialog $DW FD px), $BS_N items, view $BS_VIEW, scroll $BS_SCROLL; maxScroll $SC_MAX, content ${SC_CW}x$SC_CH, cell ${SC_CELLW}x$SC_CELLH"
[[ -n "$WW" && -n "$SC_MAX" ]] || { fail "no Browser window / BROWSERSC line [$(dk_tree)]"; done_test; }
(( BS_VIEW == 2 && BS_N >= N )) && pass "thumbnails of $BS_N items in the docked Browser" || fail "view $BS_VIEW with $BS_N items (want thumbnails, >= $N)"

# every row of cells reachable: maxScroll >= rows * cellH - contentH
COLS=$(( (SC_CW - 12) / SC_CELLW )); (( COLS < 1 )) && COLS=1
ROWS=$(( (BS_N + COLS - 1) / COLS ))
WANT=$(( ROWS * SC_CELLH - SC_CH ))
info "$COLS column(s), $ROWS rows: want maxScroll ~$WANT"
(( SC_MAX > 0 && SC_MAX >= WANT - SC_CELLH && SC_MAX <= WANT + SC_CELLH )) \
    && pass "the scroll range covers the whole list ($SC_MAX, past 32767: $(( SC_MAX > 32767 )))" \
    || fail "maxScroll $SC_MAX, want ~$WANT (the list's height wrapped?)"

# the wheel over the list
FX=$(( LX + SC_CELLW / 2 )); FY=$(( BS_TOP + SC_CELLH / 2 ))
VX=$(( WX + FX * WW / DW )); VY=$(( WY + FY * WW / DW ))
hover "$VX" "$VY"; wait_for 0.5 "pointer over the list"
for i in 1 2 3 4 5; do driver_input_scroll down 1; sleep 0.05; done
wait_for 0.6 "the wheel"; dk_settle; bs
(( BS_SCROLL > 0 )) && pass "the wheel scrolls the docked list (scroll $BS_SCROLL)" || fail "the wheel left the list at scroll $BS_SCROLL"

# the scrollbar: press its thumb (at the top) and drag it past the bottom
SBX=$(( WX + (LX + SC_CW - 6) * WW / DW ))
SBY0=$(( WY + (BS_TOP + 8) * WW / DW )); SBY1=$(( WY + (BS_TOP + SC_CH + 30) * WW / DW ))
mouse_down "$SBX" "$SBY0"; sleep 0.25
for (( y = SBY0 + 30; y < SBY1; y += 30 )); do hover "$SBX" "$y"; sleep 0.05; done
hover "$SBX" "$SBY1"; sleep 0.3; mouse_up; sleep 0.15
dk_park # (off the Browser at once: its thumbnails loaded only under the pointer)
wait_for 2.5 "scrolled to the end, thumbnails loading with the pointer away"; dk_settle; bs; bsc
info "scrollbar dragged $SBX: $SBY0 -> $SBY1: scroll $BS_SCROLL of $SC_MAX"
(( BS_SCROLL == SC_MAX && SC_MAX > 0 )) \
    && pass "the scrollbar dragged down: the list at its end ($BS_SCROLL)" \
    || fail "scrollbar drag: scroll $BS_SCROLL of $SC_MAX"
info "pointer parked: $SC_LOADED thumbnails loaded, the last one: $SC_LASTOK"
(( SC_LASTOK == -1 )) && pass "the pointer off the Browser: the end's thumbnails load ($SC_LOADED loaded)" || fail "the pointer off the Browser: the last item's thumbnail not loaded ($SC_LASTOK, $SC_LOADED loaded)"
screenshot "dock-browser-scroll-end"
assert_window_exists
info "=== Browser: docked long-list scroll done ==="
done_test
