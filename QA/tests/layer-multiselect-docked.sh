#!/bin/bash
# =============================================================================
# layer-multiselect-docked.sh — QA test: Ctrl+click and Shift+click add layers
# to the multi-select, with the layer panel alone in its slot AND with the
# Preview docked above it (Rick's layout, where the Preview's input runs first).
# Reads LPANEL <scroll> <current> <selected count> and the last LAYER field
# (selected 0/-1). ctrl_click / shift_click hold the key through the click.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt PREVIEW_VISIBLE=1
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Layers: multi-select (docked) Test ==="
dk_begin
sel_count() { awk '$1 == "LPANEL" {print $4}' "$DK_DUMP"; }

key ctrl+shift+n; wait_for 0.5 "new layer"
key ctrl+shift+n; wait_for 0.5 "new layer"

# a hand click: press, drift a few px (as a real mouse does), release
wobble_click() { mouse_down "$1" "$2"; hover $(( $1 + 2 )) $(( $2 + 1 )); sleep 0.1; hover $(( $1 + 4 )) $(( $2 + 2 )); sleep 0.1; mouse_up; }
CLICK=click; MCLICK=ctrl_click; SCLICK=shift_click
try_layout() { # $1 = label
    local HDR=16 ROW=20 RX R1 R2 R3 n
    dk_park; dk_settle
    dk_p layers
    RX=$(( P_X + P_W / 2 ))
    R1=$(( P_Y + HDR + ROW / 2 )); R2=$(( R1 + ROW )); R3=$(( R2 + ROW ))
    $CLICK "$RX" "$R1"; wait_for 0.4 "plain click row 1"
    dk_park; dk_settle; n=$(sel_count)
    if [[ "$n" == "1" ]]; then pass "$1: a plain click selects one layer"; else fail "$1: plain click left $n selected"; fi
    $MCLICK "$RX" "$R2"; wait_for 0.4 "ctrl click row 2"
    dk_park; dk_settle; n=$(sel_count)
    if [[ "$n" == "2" ]]; then pass "$1: Ctrl+click adds a second layer"; else fail "$1: Ctrl+click left $n selected (want 2) [$(grep '^LPANEL' "$DK_DUMP")]"; fi
    $SCLICK "$RX" "$R3"; wait_for 0.4 "shift click row 3"
    dk_park; dk_settle; n=$(sel_count)
    if [[ "$n" == "3" ]]; then pass "$1: Shift+click extends to the third layer"; else fail "$1: Shift+click left $n selected (want 3)"; fi
    $CLICK "$RX" "$R1"; wait_for 0.4 "plain click row 1"
    dk_park; dk_settle; n=$(sel_count)
    if [[ "$n" == "1" ]]; then pass "$1: a plain click goes back to one"; else fail "$1: plain click left $n selected"; fi
}

try_layout "layers alone"
dk_move_expect preview above layers; dk_check "preview docked above the layers"
try_layout "preview above the layers"
CLICK=wobble_click
MCLICK="with_mods ctrl wobble_click"; SCLICK="with_mods shift wobble_click"
try_layout "hand clicks (3 px drift), preview above the layers"
assert_window_exists
info "=== Layers: multi-select (docked) Test PASSED ==="
