#!/bin/bash
# =============================================================================
# dock-preview-docked-cursor.sh — QA test: a DOCKED Preview shows no resize
# cursor on its edges (the slot sets its size; dragging there does nothing),
# and its title-bar arrow zone is the drawn title bar (native px x its render
# scale), not the unscaled height that reached into the content.
# Reads CURSOR <id> <flip> (CURSOR_RESIZE_CORNER/HORIZ/VERT = 7/8/9, NULL = 0).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt PREVIEW_VISIBLE=1
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: docked Preview cursor Test ==="
dk_begin
cursor_id() { awk '$1 == "CURSOR" {print $2}' "$DK_DUMP"; }
cur_at() { hover "$1" "$2"; sleep 0.3; hover "$1" $(( $2 + 1 )); sleep 0.3; hover "$1" "$2"; sleep 0.3; dk_settle; CID=$(cursor_id); }

dk_move_expect preview below organizer; dk_check "preview below the organizer"
dk_park; dk_settle
read -r _ _ WX WY WW WH _ <<< "$(grep '^WIN preview ' "$DK_DUMP")"
dk_p preview
info "preview drawn at $WX,$WY ${WW}x$WH, title $P_HH px"
# 2-3 px in from the edges: inside the window's own resize band (>= 3 px),
# outside the dock's column edge / slot divider (+-2 px) - those DO resize
for spot in "left $(( WX + 2 )) $(( WY + WH / 2 ))" "right $(( WX + WW - 3 )) $(( WY + WH / 2 ))" "bottom $(( WX + WW / 2 )) $(( WY + WH - 3 ))"; do
    read -r nm x y <<< "$spot"
    cur_at "$x" "$y"
    if (( CID >= 7 && CID <= 9 )); then
        fail "docked Preview's $nm edge ($x,$y) shows a resize cursor ($CID) it does not honour"
    else
        pass "docked Preview's $nm edge ($x,$y): no resize cursor ($CID)"
    fi
done
# just below the drawn title bar = content (pan hand), not the title's arrow
cur_at $(( WX + WW / 2 )) $(( WY + P_HH + P_HH / 2 ))
if (( CID != 0 )); then pass "just below the title bar is content (cursor $CID, not the title's arrow)"; else fail "the title-bar arrow reaches into the content (cursor $CID at y=$(( WY + P_HH + P_HH / 2 )))"; fi
assert_window_exists
info "=== Dock: docked Preview cursor Test PASSED ==="
