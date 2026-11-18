#!/bin/bash
# =============================================================================
# dock-row-zoomfit.sh — QA test: zoom to fit (double-click the Hand) fits the
# canvas between the top and bottom dock rows (Rick 2026-11-16: "the double
# click on hand to zoom to fit doesn't account for that, and positions the
# canvas underneath those docks"). ZOOM_viewport_rect leaves the rows out.
# Dump: CANVR x y w h (the canvas on screen); ROWS full y1 y2 toph both
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock rows: zoom to fit between them ==="
dk_begin
canvr() { read -r _ CV_X CV_Y CV_W CV_H <<< "$(grep -m1 '^CANVR' "$DK_DUMP")"; }
btn() { awk -v n="$1" '$1=="BTN" && $2=="toolbox" && $6==n {print $7+int($9/2)" "$8+int($10/2); exit}' "$DK_DUMP"; }
dk_move toolbox band-top
dk_move drawer band-bottom
dk_rows
info "rows: top $R_TOPH (canvas from y $R_Y1), bottom $R_BOTH (to y $R_Y2)"
(( R_TOPH > 0 && R_BOTH > 0 )) && pass "a top and a bottom row" || fail "rows top $R_TOPH bottom $R_BOTH [$(dk_tree)]"
read -r HX HY <<< "$(btn hand)"
[[ -n "$HY" ]] || fail "no Hand button in the toolbox dump"
double_click "$HX" "$HY"; dk_park; dk_settle; dk_rows; canvr
info "after the fit: canvas $CV_X,$CV_Y ${CV_W}x$CV_H"
(( CV_Y >= R_Y1 )) && pass "the canvas starts under the top row ($CV_Y >= $R_Y1)" || fail "the canvas starts at $CV_Y, under the top row (ends $R_Y1)"
(( CV_Y + CV_H - 1 <= R_Y2 )) && pass "the canvas ends over the bottom row ($(( CV_Y + CV_H - 1 )) <= $R_Y2)" || fail "the canvas ends at $(( CV_Y + CV_H - 1 )), the bottom row starts at $(( R_Y2 + 1 ))"
MID=$(( (R_Y1 + R_Y2) / 2 )); CM=$(( CV_Y + CV_H / 2 ))
(( CM - MID <= 2 && MID - CM <= 2 )) && pass "centred between them (centre $CM, middle $MID)" || fail "the canvas centre $CM, the space's middle $MID"
screenshot "dock-row-zoomfit"
assert_window_exists
info "=== Dock rows: zoom to fit done ==="
