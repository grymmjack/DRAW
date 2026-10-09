#!/bin/bash
# =============================================================================
# dock-preview-short.sh — QA test: a docked Preview never draws past its slot
# onto the panel stacked under it (Rick, 2026-10-08: "the layer text went
# under the preview window"). The Preview has a minimum size; its slot must
# not shrink below it (DOCK_min_h%), so dragging the divider all the way up
# stops there and the layers below are never covered (dk_check's WIN rule).
#   above   Preview over the layers, divider dragged to the top
#   below   layers over the Preview, divider dragged to the bottom
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt PREVIEW_VISIBLE=1 DOCK_CUSTOM=1 DOCK_LEFT_1=WIDTH:140;preview|layers DOCK_LEFT_2=AUTO;editbar DOCK_RIGHT_1=AUTO;toolbox|organizer|drawer DOCK_RIGHT_2=AUTO;advbar
# =============================================================================

source "$DRAW_ROOT/QA/dock-lib.sh"

info "=== Docked Preview stays inside its slot ==="
wait_for 1.0 "settle"
key Escape
dk_park
dk_settle
for i in $(seq 1 8); do key ctrl+shift+n; sleep 0.2; done
dk_park; dk_settle
dk_check "preview over the layers"

# divider (top of the layers' slot) dragged to the top
dk_p layers; dk_slot "$P_SLOT"
dk_drag $(( S_X + S_W / 2 )) $(( S_Y - 2 )) $(( S_X + S_W / 2 )) 2 6; dk_park; dk_settle
dk_check "divider dragged to the top"
grep -E '^(P preview|WIN preview|P layers)' "$DK_DUMP" | while read -r l; do info "$l"; done
screenshot "dock-preview-short-above"

# the other way round: the layers over the Preview, divider dragged to the bottom
dk_move preview below layers; dk_expect_stacked layers preview; dk_check "preview under the layers"
dk_p preview; dk_slot "$P_SLOT"
dk_scr
dk_drag $(( S_X + S_W / 2 )) $(( S_Y - 2 )) $(( S_X + S_W / 2 )) $(( DOCK_BOT - 2 )) 6; dk_park; dk_settle
dk_check "divider dragged to the bottom"
grep -E '^(P preview|WIN preview|P layers)' "$DK_DUMP" | while read -r l; do info "$l"; done
screenshot "dock-preview-short-below"
assert_no_crash
