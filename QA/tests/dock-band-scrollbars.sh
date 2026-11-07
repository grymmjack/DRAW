#!/bin/bash
# =============================================================================
# dock-band-scrollbars.sh — QA test: the Browser docked in its band (top or
# bottom of the canvas area) and the canvas scrollbars.
# Rick, 2026-11-07:
#   "when the browser is docked to the bottom it occludes the bottom most
#    scroll bar ... the scrollbars [should go] to the canvas boundary"
#   "the vertical scroll bar should not render behind it ... compensate for
#    top/bottom dock of the browser"
#   "when i click the red x, and browser is docked to the top, it is acting
#    like i'm clicking the scrollbar"
#   "when i click the x ... when the brush tool ... is selected it punches
#    through the browser, and closes the browser, but also draws on the canvas"
# For the band along the bottom, then along the top, zoomed in so both bars show:
#   - both scrollbar tracks end at the band's edge (SBAR line vs BAND line)
#   - with the brush, a click on the Browser's X closes it and draws nothing
#     (the undo count is unchanged): its middle (bottom band), its right end in
#     the corner's resize grip (top band)
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt BROWSER_VISIBLE=1 BROWSER_POS_X=300 BROWSER_POS_Y=60 TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Browser band + canvas scrollbars Test ==="
dk_begin
sbar() { read -r _ H_ON H_X H_Y H_W H_H V_ON V_X V_Y V_W V_H HIST <<< "$(grep '^SBAR ' "$DK_DUMP")"; }

for i in 1 2 3 4 5 6 7 8; do key ctrl+equal; sleep 0.1; done
dk_park; dk_settle

check_side() { # SIDE (band-bottom | band-top) XOFF (click the X this far left of the right edge)
    local side=$1 xoff=$2
    dk_move_expect browser "$side"; dk_check "browser in the $side"
    dk_park; dk_settle
    dk_band; sbar
    info "$side: band y=$B_Y h=$B_H; h-bar on=$H_ON y=$H_Y h=$H_H x=$H_X w=$H_W; v-bar on=$V_ON y=$V_Y h=$V_H x=$V_X"
    if [[ "$H_ON" != "-1" || "$V_ON" != "-1" ]]; then fail "$side: zoomed in, but the scrollbars are not both shown"; return; fi
    if [[ "$side" == band-bottom ]]; then
        (( H_Y + H_H <= B_Y )) && pass "$side: the horizontal bar is above the Browser band" || fail "$side: the horizontal bar ($H_Y..$(( H_Y + H_H - 1 ))) is behind the band (from $B_Y)"
        (( V_Y + V_H <= B_Y )) && pass "$side: the vertical bar stops above the band" || fail "$side: the vertical bar runs behind the band ($V_Y..$(( V_Y + V_H - 1 )), band from $B_Y)"
    else
        (( V_Y >= B_Y + B_H )) && pass "$side: the vertical bar starts below the Browser band" || fail "$side: the vertical bar runs behind the band (from $V_Y, band ends $(( B_Y + B_H - 1 )))"
        (( H_Y >= B_Y + B_H )) && pass "$side: the horizontal bar is below the band" || fail "$side: the horizontal bar ($H_Y) is inside the band"
    fi

    # the Browser's X (right end of its title bar) with the brush in hand
    key b; sleep 0.3; dk_settle; sbar; local h0=$HIST
    read -r _ _ wx wy ww wh _ <<< "$(grep '^WIN browser ' "$DK_DUMP")"
    if [[ -z "$ww" ]]; then fail "$side: no WIN browser line"; return; fi
    info "$side: browser window at $wx,$wy ${ww}x$wh"
    click $(( wx + ww - xoff )) $(( wy + 6 )); sleep 0.5
    dk_park; dk_settle; sbar
    grep -q '^WIN browser ' "$DK_DUMP" && fail "$side: the X did not close the Browser" || pass "$side: the X closes the Browser"
    [[ "$HIST" == "$h0" ]] && pass "$side: the click on the X drew nothing (undo count $h0)" || fail "$side: the click on the X went through to the brush (undo count $h0 -> $HIST)"
}

# the middle of the X (the old code closed the Browser there - and the brush drew)
check_side band-bottom 16
# show it again (View > Browser), it comes back in its band
key question; sleep 0.5; type_text "toggle browser"; sleep 0.3; key Return; sleep 0.8
dk_park; dk_settle
# the right end of the X, inside the corner's resize grip (the old code resized)
check_side band-top 5
assert_no_crash
