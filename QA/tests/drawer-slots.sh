#!/bin/bash
# =============================================================================
# drawer-slots.sh — QA test: the Drawer has 96 bins per mode (2.8; 30 before),
# and the slots past the classic 30 survive the files:
#   - a .dset with its extension block (DSX1) loads slot 40
#   - a .draw with a "drAx" chunk loads slot 40 (brush) and 35 (pattern)
#   - Ctrl+S writes the drAx chunk back, and a reload still has them
# Fixtures: QA/fixtures/make-drawer-fixtures.py. State: the DRAWERS dump line
# (slots per mode, last used brush / pattern / gradient slot, that brush's w h).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt DEFAULT_DSET_BRUSHES_FILE=QA/fixtures/drawer-40.dset DRAWER_MINI_PALETTE=0
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"

ds_read() { read -r _ DS_N DS_B DS_P DS_G DS_BW DS_BH <<< "$(grep '^DRAWERS ' "$DK_DUMP")"; }
ds_expect() { if [[ "$2" == "$3" ]]; then pass "$1 = $3"; else fail "$1 = '$2', want '$3'"; fi; }

info "=== Drawer: 96 bins, slots past 30 in .dset and .draw ==="
dk_begin
ds_read
ds_expect "bins per mode" "$DS_N" 96
read -r _ DL_COLS DL_ROWS _ <<< "$(grep '^DRAWERL ' "$DK_DUMP")"
if [[ -n "$DL_COLS" ]] && (( DL_COLS * DL_ROWS >= 96 )); then pass "the grid has room for 96 ($DL_COLS x $DL_ROWS)"; else fail "grid $DL_COLS x $DL_ROWS < 96"; fi
ds_expect ".dset: last brush slot" "$DS_B" 40
ds_expect ".dset: slot 40 size" "${DS_BW}x$DS_BH" "7x5"

# a .draw with a drAx chunk (no spaces: DRAW_EXTRA_ARGS is expanded unquoted)
RT_FILE="${RESULTS_DIR:-/tmp}/drawer-slots-$$.draw"
cp "$DRAW_ROOT/QA/fixtures/drawer-40.draw" "$RT_FILE" || fail "could not stage $RT_FILE"
draw_quit
DRAW_EXTRA_ARGS="$RT_FILE"
draw_launch 15
wait_for 1.5 "drawer-40.draw loaded"
dk_settle
ds_read
ds_expect ".draw: last brush slot" "$DS_B" 40
ds_expect ".draw: slot 40 size" "${DS_BW}x$DS_BH" "7x5"
ds_expect ".draw: last pattern slot" "$DS_P" 35

# Ctrl+S writes the slots past 30 back (drAx), a reload reads them again
wake_draw
key ctrl+s
wait_for 2.0 "saved"
if grep -qa 'drAx' "$RT_FILE"; then pass "the saved .draw has a drAx chunk"; else fail "no drAx chunk in the saved .draw"; fi
draw_quit
draw_launch 15
wait_for 1.5 "reloaded"
dk_settle
ds_read
ds_expect "reload: last brush slot" "$DS_B" 40
ds_expect "reload: last pattern slot" "$DS_P" 35
screenshot "drawer-slots-reloaded"

rm -f "$RT_FILE"
draw_quit
DRAW_EXTRA_ARGS=""
draw_launch 15
wait_for 0.8 "Default instance restored"
assert_window_exists
info "=== Drawer slots PASSED ==="
