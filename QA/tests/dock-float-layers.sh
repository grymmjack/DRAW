#!/bin/bash
# =============================================================================
# dock-float-layers.sh — QA test: the layers panel floating.
#   - a grip, no "Layers" title bar on top of its own LAYERS header (Rick: "this
#     text is redundant when layers is floated"); the header is the handle
#   - right-clicking the header opens the dock menu
#   - it resizes narrower than the column it came from (down to its buttons)
#   - the pointer over its grip / frame is the arrow, not the tool crosshair
#   - dragged next to another floating panel it snaps against its edge, like
#     the native windows (the Browser) do
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt LAYER_PANEL_WIDTH=200
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: floating layers Test ==="
dk_begin
dk_p layers; DOCKED_W=$P_W
dk_scr
dk_move layers float $(( (CAN_LX + CAN_RX) / 2 )) $(( DOCK_TOP + 80 ))
dk_expect_floating layers
dk_p layers
info "floating: window $P_FX,$P_FY ${P_FW}x$P_FH, content y=$P_Y, handle $P_HX,$P_HY ${P_HW}x$P_HH (docked width $DOCKED_W)"
TOP=$(( P_Y - P_FY ))
if (( TOP <= 7 )); then pass "no title bar over the LAYERS header (content starts ${TOP}px down)"; else fail "a ${TOP}px title bar sits over the LAYERS header"; fi
if (( P_HH >= TOP + 12 )); then pass "the header is part of the handle (${P_HH}px)"; else fail "the handle is only ${P_HH}px tall"; fi

# the pointer over the grip and the frame: the arrow
hover $(( P_FX + P_FW / 2 )) $(( P_FY + 2 )); sleep 0.5
read -r _ CUR _ <<< "$(grep '^CURSOR ' "$DK_DUMP")"
if (( CUR == 0 )); then pass "arrow over the grip"; else fail "cursor $CUR over the grip (not the arrow)"; fi
hover $(( P_FX + 1 )) $(( P_FY + P_FH / 2 )); sleep 0.5
read -r _ CUR _ <<< "$(grep '^CURSOR ' "$DK_DUMP")"
if (( CUR == 0 )); then pass "arrow over the frame"; else fail "cursor $CUR over the frame (not the arrow)"; fi

# right-click the header: the dock menu
right_click $(( P_FX + P_FW / 3 )) $(( P_FY + P_HH - 5 )); sleep 0.6
read -r _ MOPEN MPANEL _ <<< "$(grep '^DMENU ' "$DK_DUMP")"
if (( MOPEN != 0 )); then pass "right-clicking the header opens the dock menu"; else fail "no dock menu on the header"; fi
screenshot "dock-float-layers-menu"
key Escape; sleep 0.3; dk_park; dk_settle

# narrower than it was docked
dk_p layers
CX=$(( P_FX + P_FW - 2 )); CY=$(( P_FY + P_FH - 2 ))
dk_drag "$CX" "$CY" $(( CX - 300 )) "$CY"
dk_park; dk_settle
dk_p layers
if (( P_FW < DOCKED_W - 20 )); then pass "it resizes narrower than its docked width ($DOCKED_W -> $P_FW)"; else fail "stuck at ${P_FW}px (docked width $DOCKED_W)"; fi

# snapping: float the toolbox, drop the layers 3px right of it -> they touch
dk_move toolbox float $(( CAN_LX + 40 )) $(( DOCK_TOP + 200 ))
dk_expect_floating toolbox
dk_p toolbox; TBR=$(( P_FX + P_FW )); TBY=$P_FY
dk_p layers
GX=$(( P_FX + P_FW / 2 )); GY=$(( P_FY + 2 ))
OFFX=$(( GX - P_FX )); OFFY=$(( GY - P_FY ))
TX=$(( TBR + 3 + OFFX )); TY=$(( TBY + 30 + OFFY ))
info "drag the layers from $GX,$GY to $TX,$TY (left edge 3px right of the toolbox at $TBR)"
dk_drag "$GX" "$GY" "$TX" "$TY"
dk_park; dk_settle
dk_p layers
if (( P_FX == TBR )); then pass "the layers snapped against the toolbox (x=$P_FX)"; else fail "no snap: layers at x=$P_FX, toolbox right edge $TBR"; fi
screenshot "dock-float-layers-snap"

assert_window_exists
info "=== Dock: floating layers Test PASSED ==="
