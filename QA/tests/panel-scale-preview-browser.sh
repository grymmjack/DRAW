#!/bin/bash
# =============================================================================
# panel-scale-preview-browser.sh — QA test: Scale in the title bar's menu of
# the floating Preview and Browser windows (Rick, 2026-11-14: "add the same
# functions for scale of anything that floats that doesn't already have it in
# the right click menu ... preview ... browser").
#
# Each has CFG.PREVIEW_SCALE / BROWSER_SCALE: 0 = Auto (USCALE.previewAuto /
# browserAuto, their ratio of the UI Scale), 1-8 fixed. For each window:
#   - right-click its title: Scale rows, Auto checked
#   - a fixed scale k: the window is k/auto of its Auto size, the setting saved
#   - Auto: back to the Auto size, 0 saved
#
# Dump: WIN <name> x y w h slot, P <name> (... handle hx hy hw hh),
# DMENU open panel _ x y w, DMENUR _ value y h checked. Panel ids: preview 9,
# browser 14 (GUI/DOCK.BI DP_PREVIEW / DP_BROWSER).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt PREVIEW_VISIBLE=1 BROWSER_VISIBLE=1 TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
info "=== Panels: Scale for the Preview and the Browser ==="

PS_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
PS_CFG="$DRAW_ROOT/QA/DRAW.qa.cfg"
ps_read() { # NAME
    { hover 470 470; wait_for 0.2 "render"; hover 475 472; wait_for 0.4 "render"; } >&2
    read -r _ _ W_X W_Y W_W W_H _ <<< "$(grep -m1 "^WIN $1 " "$PS_DUMP")"
    read -r _ _ _ _ _ _ _ _ _ _ _ _ _ _ H_X H_Y H_W H_H _ <<< "$(grep -m1 "^P $1 " "$PS_DUMP")"
    read -r _ M_OPEN M_PANEL _ M_X M_Y M_WW _ <<< "$(grep -m1 '^DMENU ' "$PS_DUMP")"
}
ps_row() { awk -v v="$1" '$1=="DMENUR" && $3==v {print $4" "$5" "$6; exit}' "$PS_DUMP"; }
# NAME PANEL_ID VALUE: open NAME's title menu, pick the row with VALUE (20 = Auto, 20+k = kx)
ps_pick() {
    local ry rh rc
    ps_read "$1"
    right_click $(( H_X + H_W / 3 )) $(( H_Y + H_H / 2 )); wait_for 0.5 "the title bar's menu"
    ps_read "$1"
    if [[ "$M_OPEN" != -1 || "$M_PANEL" != "$2" ]]; then
        fail "right-click on the $1 title: no menu (DMENU open '$M_OPEN' panel '$M_PANEL')"; key Escape; return 1
    fi
    read -r ry rh rc <<< "$(ps_row "$3")"
    if [[ -z "$ry" ]]; then fail "the $1 title bar's menu has no Scale row $3"; key Escape; return 1; fi
    PS_CHECKED_BEFORE=$(awk '$1=="DMENUR" && $3>=20 && $3<=28 && $6==-1 {print $3}' "$PS_DUMP" | head -1)
    click $(( M_X + 12 )) $(( ry + rh / 2 )); wait_for 0.8 "Scale row $3"
    ps_read "$1"
}
near() { local d=$(( $1 - $2 )); (( d < 0 )) && d=$(( -d )); (( d <= ${3:-2} )); }

ps_panel() { # NAME PANEL_ID KEY
    local nm=$1 id=$2 key=$3 w0 h0 auto k want
    ps_read "$nm"
    if [[ -z "$W_W" ]]; then fail "$nm is not a floating window: $(grep "^WIN $nm" "$PS_DUMP")"; return; fi
    w0=$W_W; h0=$W_H
    info "$nm: Auto ${w0}x$h0 at $W_X,$W_Y"
    # the Auto row's label carries the auto scale: read it from the menu we open for 1x
    if ps_pick "$nm" "$id" 21; then
        [[ "$PS_CHECKED_BEFORE" == 20 ]] && pass "$nm: the menu has Scale rows, Auto checked" || fail "$nm: checked before '$PS_CHECKED_BEFORE' (want 20)"
        auto=$(( (w0 + W_W / 2) / W_W )); (( auto < 1 )) && auto=1
        info "$nm at 1x: ${W_W}x$W_H (Auto looks like ${auto}x)"
        grep -q "^$key=1\b" "$PS_CFG" && pass "$nm: $key=1 saved" || fail "$nm: saved '$(grep "^$key" "$PS_CFG")'"
        # 1x is never bigger than Auto; at Auto 1x it is the same size
        (( W_W <= w0 )) && pass "$nm: 1x is no bigger than Auto ($w0 -> $W_W)" || fail "$nm: 1x grew ($w0 -> $W_W)"
    fi
    # 3x: three times the 1x size
    local w1=$W_W
    if ps_pick "$nm" "$id" 23; then
        [[ "$PS_CHECKED_BEFORE" == 21 ]] && pass "$nm: reopened, 1x checked" || fail "$nm: checked '$PS_CHECKED_BEFORE' (want 21)"
        near "$W_W" $(( w1 * 3 )) 3 && pass "$nm: 3x = three times 1x ($w1 -> $W_W)" || fail "$nm: 3x is $W_W wide, 1x was $w1"
        grep -q "^$key=3\b" "$PS_CFG" && pass "$nm: $key=3 saved" || fail "$nm: saved '$(grep "^$key" "$PS_CFG")'"
        screenshot "panel-scale-$nm-3x"
    fi
    if ps_pick "$nm" "$id" 20; then
        near "$W_W" "$w0" 1 && near "$W_H" "$h0" 1 && pass "$nm: Auto again - ${W_W}x$W_H" || fail "$nm: Auto gives ${W_W}x$W_H, was ${w0}x$h0"
        grep -q "^$key=0\b" "$PS_CFG" && pass "$nm: $key=0 saved" || fail "$nm: saved '$(grep "^$key" "$PS_CFG")'"
    fi
}

ps_panel preview 9 PREVIEW_SCALE
ps_panel browser 14 BROWSER_SCALE
assert_no_crash
info "=== Panels: Scale for the Preview and the Browser: done ==="
