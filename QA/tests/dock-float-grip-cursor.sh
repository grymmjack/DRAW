#!/bin/bash
# =============================================================================
# dock-float-grip-cursor.sh — QA test: over a floating dock panel's grip / title
# bar and its frame the pointer is the arrow, never the drawing tool's
# crosshair - even when the window sits over the canvas. Rick, 2026-11-06:
# "when the cursor is over the drag handle for the palettes floating - they
# should be arrows ... not a crosshair".
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: arrow over floating panels' grips Test ==="
dk_begin
cursor_at() { hover "$1" "$2"; sleep 0.5; read -r _ CUR _ <<< "$(grep '^CURSOR ' "$DK_DUMP")"; }
for name in editbar advbar drawer toolbox layers; do
    dk_scr
    dk_move "$name" float $(( (CAN_LX + CAN_RX) / 2 )) $(( (DOCK_TOP + DOCK_BOT) / 2 - 40 ))
    dk_expect_floating "$name"
    dk_p "$name"
    info "$name floating at $P_FX,$P_FY ${P_FW}x$P_FH"
    cursor_at $(( P_FX + P_FW / 2 )) $(( P_FY + 2 ))
    if (( CUR == 0 )); then pass "$name: arrow over its grip"; else fail "$name: cursor $CUR over its grip (not the arrow)"; fi
    cursor_at $(( P_FX )) $(( P_FY + P_FH / 2 ))
    if (( CUR == 0 )); then pass "$name: arrow over its frame"; else fail "$name: cursor $CUR over its frame (not the arrow)"; fi
    # dock it back (double-click the grip) so the next one has the canvas to itself
    double_click $(( P_FX + P_FW / 2 )) $(( P_FY + 2 )); sleep 0.6
    dk_park; dk_settle
done
assert_window_exists
info "=== Dock: arrow over floating panels' grips Test PASSED ==="
