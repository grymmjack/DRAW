#!/bin/bash
# =============================================================================
# tbed-browser-band.sh — QA test: Customize Toolbars stays usable with the
# Browser docked as a bottom band. Rick (2026-10-09): the editor sized itself
# down to the status bar and the band drew over its buttons. The band is not
# free space for floating windows (FPANEL_band_trim), and a floating window
# draws and clicks above a docked one (ZORDER_DOCKED_WINDOW).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt WORKSPACES_DIR=QA/.tbed-ws BROWSER_VISIBLE=1 BROWSER_POS_X=300 BROWSER_POS_Y=60
# =============================================================================
source "$DRAW_ROOT/QA/tbed-lib.sh"
tb_reset_ws

info "=== Customize Toolbars above the Browser band ==="
dk_begin
dk_move_expect browser band-bottom; dk_check "browser along the bottom"
tb_open
dk_park; dk_settle
dk_band
read -r _ _ DX DY DW DH <<< "$(grep '^TBC done ' "$DK_DUMP")"
read -r _ _ WX WY WW WH _ <<< "$(grep '^WIN tbed ' "$DK_DUMP")"
info "band y=$B_Y h=$B_H; editor y=$WY h=$WH (bottom $(( WY + WH ))); DONE button y=$DY h=$DH"
if (( WY + WH <= B_Y )); then pass "the editor ends above the band ($(( WY + WH )) <= $B_Y)"; else fail "the editor runs into the band ($(( WY + WH )) > $B_Y)"; fi
if (( DY + DH <= B_Y )); then pass "its DONE button is above the band"; else fail "its DONE button is under the band ($(( DY + DH )) > $B_Y)"; fi
# the DONE button works (it is on top, it takes the click)
tb_click done
dk_settle
tb_state
if [[ "$TB_EDIT" != "-1" ]]; then pass "DONE closed the editor"; else fail "DONE did not respond (covered?)"; fi
assert_no_crash
tb_reset_ws
