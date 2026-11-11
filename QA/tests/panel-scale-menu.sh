#!/bin/bash
# =============================================================================
# panel-scale-menu.sh — QA test: a floating-family panel's own scale, from
# the right-click menu on its title bar.
#
# Rick 2026-11-10: "it would also be good to have a per panel option for
# scale like right click on the panel bar and choose it". The Animation,
# Color Mixer, Pen, Advanced Color Picker and 3D Color Space panels each have
# a scale (CFG.*_SCALE: 0 = Auto, the UI Scale; 1-8 = fixed), in the title
# bar's menu (Scale: Auto / 1x-4x, the one in use checked) and in Settings >
# Panels > Panel Scale.
# - Auto (the default): the Animation panel at the display scale (100%)
# - right-click its title (docked with the layers) > Scale: 1x - 1/UI Scale
#   of the Auto size (half at UI 2), the dock follows, 1x checked, ANIM_PANEL_SCALE=1 saved
# - > Scale: 3x - 150%; > Scale: Auto - back to 100%
# - the floating Color Mixer keeps its size the whole time (its own setting)
# Builds before had no Scale rows in the menu.
#
# Dump: ANIMP (... dispW dispH renderScale*100), P animation (... the title
# handle hx hy hw hh), WIN (native windows), DMENU / DMENUR (the open menu).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLBAR_SCALE=0 ANIM_PANEL_VISIBLE=-1 COLOR_MIXER_VISIBLE=1 LAYER_PANEL_WIDTH=120 DOCK_CUSTOM=1 DOCK_LEFT_1=AUTO;toolbox|organizer|drawer DOCK_LEFT_2=AUTO;editbar DOCK_RIGHT_1=AUTO;animation|layers DOCK_RIGHT_2=AUTO;advbar
# =============================================================================
info "=== Panels: per-panel scale from the title bar menu ==="

PS_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
PS_CFG="$DRAW_ROOT/QA/DRAW.qa.cfg"
ps_read() {
    { hover 300 250; wait_for 0.2 "render"; hover 305 252; wait_for 0.4 "render"; } >&2
    read -r _ _ _ _ _ A_W A_H A_RS _ <<< "$(grep -m1 '^ANIMP ' "$PS_DUMP")"
    read -r _ _ _ _ _ _ _ _ _ _ _ _ _ _ H_X H_Y H_W H_H _ <<< "$(grep -m1 '^P animation ' "$PS_DUMP")"
    read -r _ _ _ _ AW_W _ _ <<< "$(grep -m1 '^WIN animation ' "$PS_DUMP")"
    read -r _ _ _ _ M_W M_H _ <<< "$(grep -m1 '^WIN colormixer ' "$PS_DUMP")"
    read -r _ M_OPEN M_PANEL _ M_X M_Y M_WW _ <<< "$(grep -m1 '^DMENU ' "$PS_DUMP")"
}
# VALUE -> "y h checked" of that menu row
ps_row() { awk -v v="$1" '$1=="DMENUR" && $3==v {print $4" "$5" "$6; exit}' "$PS_DUMP"; }
# open the Animation title bar's menu, pick the row with VALUE (20 = Auto, 20+k = kx)
ps_pick() {
    local ry rh rc
    ps_read
    right_click $(( H_X + H_W / 2 )) $(( H_Y + H_H / 2 )); wait_for 0.5 "the title bar's menu"
    ps_read
    if [[ "$M_OPEN" != -1 || "$M_PANEL" != 14 ]]; then
        fail "right-click on the Animation title: no menu (DMENU open '$M_OPEN' panel '$M_PANEL')"; return 1
    fi
    read -r ry rh rc <<< "$(ps_row "$1")"
    if [[ -z "$ry" ]]; then
        fail "the Animation title bar's menu has no Scale row $1"; key Escape; return 1
    fi
    PS_CHECKED_BEFORE=$(awk '$1=="DMENUR" && $6==-1 {print $3}' "$PS_DUMP" | head -1)
    click $(( M_X + 12 )) $(( ry + rh / 2 )); wait_for 0.8 "Scale row $1"
    ps_read
}

# K -> WANT_RS (renderScale*100) / WANT_W for Scale: Kx at this display scale (Auto = the display scale)
ps_want() { WANT_RS=$(( $1 * 100 / DISPLAY_SCALE )); WANT_W=$(( (W0 * $1 * 2 + DISPLAY_SCALE) / (2 * DISPLAY_SCALE) )); }

ps_read
W0=$A_W; MW0="$M_W $M_H"
[[ "$A_RS" == 100 ]] && pass "Auto: the Animation panel draws at the display scale (renderScale ${A_RS}%, ${A_W}x${A_H})" \
    || fail "Auto: renderScale '${A_RS:-?}' (wanted 100)"
[[ -n "$M_W" ]] || fail "the Color Mixer is not floating: $(grep '^WIN colormixer' "$PS_DUMP")"

# -- Scale: 1x --
if ps_pick 21; then
    [[ "$PS_CHECKED_BEFORE" == 20 ]] && pass "the menu has the Scale rows, Auto checked" || fail "the checked row before: '$PS_CHECKED_BEFORE' (wanted 20, Auto)"
    ps_want 1
    (( A_RS == WANT_RS && A_W >= WANT_W - 1 && A_W <= WANT_W + 1 )) && pass "Scale: 1x - 1/$DISPLAY_SCALE of the display scale (renderScale ${A_RS}%, ${W0} -> ${A_W} px)" \
        || fail "Scale: 1x - renderScale '$A_RS' (wanted $WANT_RS), width $W0 -> '$A_W' (wanted ~$WANT_W)"
    [[ "$AW_W" == "$A_W" ]] && pass "the dock places it at its new width ($AW_W px)" || fail "the docked window is $AW_W px wide, the panel $A_W"
    grep -q '^ANIM_PANEL_SCALE=1\b' "$PS_CFG" && pass "ANIM_PANEL_SCALE=1 saved" || fail "saved: '$(grep '^ANIM_PANEL_SCALE' "$PS_CFG")'"
    screenshot "panel-scale-1x"
fi

# -- Scale: 3x --
if ps_pick 23; then
    [[ "$PS_CHECKED_BEFORE" == 21 ]] && pass "reopened: 1x checked" || fail "the checked row: '$PS_CHECKED_BEFORE' (wanted 21, 1x)"
    ps_want 3
    (( A_RS == WANT_RS && A_W >= WANT_W - 1 && A_W <= WANT_W + 1 )) && pass "Scale: 3x - renderScale ${A_RS}% (${A_W}x${A_H})" \
        || fail "Scale: 3x - renderScale '$A_RS' (wanted $WANT_RS), width '$A_W' (wanted ~$WANT_W)"
    screenshot "panel-scale-3x"
fi

# -- Scale: Auto --
if ps_pick 20; then
    (( A_RS == 100 && A_W == W0 )) && pass "Scale: Auto - the UI Scale again (renderScale ${A_RS}%, ${A_W} px)" || fail "Scale: Auto - renderScale '$A_RS', width '$A_W' (was $W0)"
    grep -q '^ANIM_PANEL_SCALE=0\b' "$PS_CFG" && pass "ANIM_PANEL_SCALE=0 saved" || fail "saved: '$(grep '^ANIM_PANEL_SCALE' "$PS_CFG")'"
fi
[[ "$M_W $M_H" == "$MW0" ]] && pass "the Color Mixer kept its size throughout ($MW0)" || fail "the Color Mixer: $MW0 -> $M_W $M_H"

assert_no_crash
draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
assert_window_exists
