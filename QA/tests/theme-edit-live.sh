#!/bin/bash
# =============================================================================
# theme-edit-live.sh — QA test: Theme Edit mode's inspector in a running DRAW
# (CFG/THEME-EDIT.BM over GUI/UIKIT/UIP-INSPECTOR.BM, PLANS/THEME-EDIT.md).
# A new theme is made from DEFAULT, the inspector starts docked right; picking
# the canvas lists its sections, the wheel edits GRID_SIZE_X live (after a click on it), SAVE writes
# it into THEME.CFG with a .history backup, middle-click reverts, and
# Ctrl+Alt+` hides the panel.
#
# Geometry (viewport px), from UIP-INSPECTOR at Auto scale (1 panel px = 1
# viewport px): docked right, 230 wide, below the 12px menu bar. Title + button
# bar = 22, then the ELEMENTS tree (120 high, 10px rows: WINDOW, MENU BAR, ...),
# a 4px divider, the component line (10) and filter (11) +1: the property list
# starts at 12+22+120+4+22 = 180. Picking CANVAS lists [CANVAS] BORDER [GRID]
# COLOR_FG OPACITY SIZE_X ... - SIZE_X is row 6. The value column starts at 45%
# of the panel (x +103) - one row lower, plus one per file, when the part picked
# shows an ELEMENT (TEELEM in the dump). The inspector's dock / scale state file
# beside the config is removed first and last, so the defaults hold.
#
# Everything on screen is a node of the tree (TEN lines of the dock dump, window
# px): menu titles, status bar swatches, colour chips, layer rows and their icons,
# and an open popup's items; picking a status swatch names it.
#
# QA-OPTIONS: DOCK_DUMP=QA/.dock-dump-te.txt
# =============================================================================

info "=== Theme Edit live inspector Test ==="
TL_NAME="QATEL$$"
TL_DIR="$DRAW_ROOT/ASSETS/THEMES/$TL_NAME"
TL_CFG="$TL_DIR/THEME.CFG"
rm -rf "$TL_DIR"

PX=$(( VIEWPORT_W - 230 ))   # panel left
TOP=12; TREE_Y=$(( TOP + 22 )); LIST_Y=$(( TREE_Y + 120 + 4 + 22 )); ROW_H=10
TL_STATE="$DRAW_ROOT/QA/DRAW.qa.cfg.theme-edit"
rm -f "$TL_STATE"
SIZE_X_Y=$(( LIST_Y + 5 * ROW_H + 5 ))
VAL_X=$(( PX + 103 + 6 ))
SAVE_X=$(( PX + 44 )); SAVE_Y=$(( TOP + 11 + 5 ))

_tl_val() { grep -E '^GRID_SIZE_X *=' "$TL_CFG" | sed 's/.*= *//' | tr -d '\r '; }

draw_quit
draw_settle
DRAW_EXTRA_ARGS="--theme-edit --theme-name $TL_NAME --theme-edit-start-inspector --theme-edit-keep-num-backups 2"
draw_launch 15
wait_for 1.5 "loaded"
assert_no_crash

if [[ -f "$TL_CFG" ]]; then pass "theme $TL_NAME created from DEFAULT"; else fail "no $TL_CFG"; fi
V0=$(_tl_val)

TL_DUMP="$DRAW_ROOT/QA/.dock-dump-te.txt"
# every part on screen is in the tree
wait_for 1.0 "tree built"
for k in "MR:0 MENU FILE" "SB:FG FOREGROUND SWATCH" "PC:0 COLOR" "LR:1 LAYER" "LR:1:EYE VISIBILITY" "LP:B4 BUTTON NEW LAYER" "TB:"; do
    if grep -q "^TEN .* $k" "$TL_DUMP" 2>/dev/null; then pass "the tree has $k"; else fail "no '$k' node in the tree ($(grep -c '^TEN' "$TL_DUMP" 2>/dev/null) nodes)"; fi
done
# picking a status bar swatch names it (the dump's TEN boxes are window px)
read -r _ _ SWX SWY SWW SWH _ <<< "$(grep -m1 '^TEN .* SB:FG ' "$TL_DUMP")"
if [[ -n "$SWX" ]]; then
    hover $(( (SWX + SWW / 2) / DISPLAY_SCALE )) $(( (SWY + SWH / 2) / DISPLAY_SCALE )); wait_for 0.8 "picking the swatch"
    if grep -q '^TEPICK STATUS_BAR .*FOREGROUND SWATCH' "$TL_DUMP"; then pass "picking names the status bar's FG swatch"; else fail "pick: $(grep '^TEPICK' "$TL_DUMP")"; fi
fi

# pick the canvas: hover shows it, a click locks it
hover "$CANVAS_CX" "$CANVAS_CY"; wait_for 0.5 "picking"
click "$CANVAS_CX" "$CANVAS_CY"; wait_for 0.5 "locked"
# a part of the canvas picked (the checker): its ELEMENT row(s) come first
read -r _ TL_NF _ <<< "$(grep -m1 '^TEELEM ' "$TL_DUMP")"
if [[ -n "$TL_NF" ]]; then SIZE_X_Y=$(( SIZE_X_Y + (1 + TL_NF) * ROW_H )); info "element shown: $(grep -m1 '^TEELEM ' "$TL_DUMP")"; fi
snap_region "$PX" $(( SIZE_X_Y - 4 )) 230 9 "size_x_before"; S0="$SNAP_RESULT"

# the wheel over a value it was not clicked on only scrolls (the list is at its top:
# nothing moves) - no stray edits while scrolling
scroll_up "$VAL_X" "$SIZE_X_Y"; wait_for 0.5 "wheel, not armed"
snap_region "$PX" $(( SIZE_X_Y - 4 )) 230 9 "size_x_unarmed"
assert_regions_same "$S0" "$SNAP_RESULT" "the wheel left an unclicked value alone"
# a click arms the value (outlined); then the wheel edits it live
click "$VAL_X" "$SIZE_X_Y"; wait_for 0.6 "armed"
snap_region "$PX" $(( SIZE_X_Y - 4 )) 230 9 "size_x_armed"; SA="$SNAP_RESULT"
scroll_up "$VAL_X" "$SIZE_X_Y"; wait_for 0.5 "wheel +1"
snap_region "$PX" $(( SIZE_X_Y - 4 )) 230 9 "size_x_wheeled"; S1="$SNAP_RESULT"
assert_regions_differ "$SA" "$S1" "after a click the wheel changed GRID_SIZE_X in the panel"

# SAVE writes it, with a backup of the old file
click "$SAVE_X" "$SAVE_Y"; wait_for 1.0 "saved"
V1=$(_tl_val)
if [[ -n "$V0" && "$V1" == "$(( V0 + 1 ))" ]]; then pass "SAVE wrote GRID_SIZE_X = $V1 (was $V0)"; else fail "GRID_SIZE_X in THEME.CFG: '$V1', wanted $(( V0 + 1 ))"; fi
NB=$(ls "$TL_DIR/.history" 2>/dev/null | wc -l)
if [[ $NB -ge 1 ]]; then pass "a backup is in .history ($NB)"; else fail "no backup in $TL_DIR/.history"; fi

# middle-click reverts to the session's starting value
middle_click "$VAL_X" "$SIZE_X_Y"; wait_for 0.5 "reverted"
snap_region "$PX" $(( SIZE_X_Y - 4 )) 230 9 "size_x_reverted"; S2="$SNAP_RESULT"
assert_regions_differ "$S1" "$S2" "middle-click reverted the row"
click "$SAVE_X" "$SAVE_Y"; wait_for 1.0 "saved again"
V2=$(_tl_val)
if [[ "$V2" == "$V0" ]]; then pass "revert + SAVE put GRID_SIZE_X back to $V0"; else fail "after revert THEME.CFG has '$V2', wanted $V0"; fi
screenshot "theme-edit-live-panel"

# the ELEMENTS tree: hovering its MENU BAR row outlines the menu bar (the tree
# scrolled to the picked CANVAS: back to its top first)
for _i in 1 2 3 4 5 6 7 8 9 10 11 12; do scroll_up $(( PX + 30 )) $(( TREE_Y + 40 )); done
park_mouse; wait_for 0.4 "pointer off"
snap_region 300 1 200 9 "menubar_plain"; S5="$SNAP_RESULT"
hover $(( PX + 30 )) $(( TREE_Y + ROW_H + 5 )); wait_for 0.6 "tree hover"
snap_region 300 1 200 9 "menubar_outlined"; S6="$SNAP_RESULT"
assert_regions_differ "$S5" "$S6" "hovering the tree's MENU BAR row outlined the menu bar"
screenshot "theme-edit-live-tree"

# Scale: right-click the title -> menu; its 2nd item is SCALE: 1X - the panel
# halves on screen (what was panel at its left becomes DRAW again) and the
# choice is kept in the state file
snap_region "$PX" 200 60 60 "panel_2x"; S7="$SNAP_RESULT"
right_click $(( PX + 20 )) $(( TOP + 5 )); wait_for 0.5 "menu"
click $(( PX + 40 )) $(( TOP + 5 + 17 )); wait_for 0.8 "scale 1x"
park_mouse; wait_for 0.4 "settle"
snap_region "$PX" 200 60 60 "panel_1x"; S8="$SNAP_RESULT"
assert_regions_differ "$S7" "$S8" "SCALE: 1X shrank the inspector"
if grep -q 'SCALE=2' "$TL_STATE" 2>/dev/null; then pass "the scale was saved ($(cat "$TL_STATE"))"; else fail "state file: $(cat "$TL_STATE" 2>&1)"; fi
screenshot "theme-edit-live-1x"

# an open popup's items are in the tree: right-click the layer row -> its menu
park_mouse; wait_for 0.3 "settle"
read -r _ _ LRX LRY LRW LRH _ <<< "$(grep -m1 '^TEN .* LR:1 ' "$TL_DUMP")"
if [[ -n "$LRX" ]]; then
    right_click $(( (LRX + LRW / 2) / DISPLAY_SCALE )) $(( (LRY + LRH / 2) / DISPLAY_SCALE )); wait_for 1.2 "layer menu"
    N=$(grep -c '^TEN .* POP:[0-9:]* ITEM ' "$TL_DUMP")
    if [[ $N -ge 3 ]]; then pass "the open popup's $N items are in the tree"; else fail "popup items in the tree: $N"; fi
    key Escape; wait_for 0.4 "menu closed"
fi

# Ctrl+Alt+` hides the inspector
snap_region $(( VIEWPORT_W - 110 )) 40 100 120 "panel_shown"; S3="$SNAP_RESULT"
park_mouse
raw_seq keydown ctrl keydown alt keydown grave; sleep 0.15; raw_seq keyup grave keyup alt keyup ctrl
wait_for 0.8 "hidden"
snap_region $(( VIEWPORT_W - 110 )) 40 100 120 "panel_hidden"; S4="$SNAP_RESULT"
assert_regions_differ "$S3" "$S4" "Ctrl+Alt+\` hid the inspector"

assert_no_crash
draw_quit
draw_settle
rm -f "$TL_DUMP"
rm -rf "$TL_DIR"
rm -f "$TL_STATE"
DRAW_EXTRA_ARGS=""
draw_launch 15
assert_window_exists
info "=== Theme Edit live inspector Test PASSED ==="
