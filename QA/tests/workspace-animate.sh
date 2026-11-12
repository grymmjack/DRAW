#!/bin/bash
# =============================================================================
# workspace-animate.sh — QA test: the Animate built-in workspace (Animation
# L.2, ASSETS/WORKSPACES/animate.workspace).
#
# Animate shows the Animation panel and turns the lightbox on (with onion skin
# and the frame grid) as an overlay: a sheet with frames opens in the
# lightbox; Default puts back the user's sheet view and closes the panel;
# Animate again brings both back; toggling the lightbox in Animate never
# writes LIGHTBOX into DRAW.cfg, and the toggle sticks (the save guard puts
# back the live values, not the workspace's / --option's). On a picture
# without frames, Num + makes frames and the lightbox opens on them.
#
# Read back: the dump (ANIMLB shown, ANIMP visible, ANIM count) and the QA
# config file after DRAW has quit (its exit CONFIG_save).
#
# QA-OPTIONS: WORKSPACE=animate DOCK_DUMP=QA/.dock-dump.txt WORKSPACES_DIR=/tmp/draw-qa-ws-none
# =============================================================================
info "=== Workspace: Animate ==="

WA_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
WA_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
WA_T="$(mktemp -d /tmp/draw-qa-wsanim-XXXXXX)"
magick -size 96x16 xc:none -fill "#c04040" -draw "rectangle 3,4 8,9" -fill "#40c040" -draw "rectangle 20,4 25,9" "PNG32:$WA_T/plain.png"
python3 "$WA_PY" put "$WA_T/plain.png" "$WA_T/sheet.png" drAn "$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,6,1,10,0,0).hex())")"

wa_line() { grep -m1 "^$1 " "$WA_DUMP" 2>/dev/null; }
wa_read() { # A_ACT A_COUNT, LB_SHOWN, P_VIS
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2
    read -r _ A_ACT A_COUNT _ <<< "$(wa_line ANIM)"
    LB_SHOWN=""; read -r _ LB_SHOWN _ <<< "$(wa_line ANIMLB)"
    P_VIS=""; read -r _ P_VIS _ <<< "$(wa_line ANIMP)"
}
wa_s() { echo "frames ${A_COUNT:-?} (active ${A_ACT:-?}), lightbox shown '${LB_SHOWN:-}', panel visible '${P_VIS:-}'"; }
wa_switch() { # TEXT: the workspace switcher, filtered
    park_mouse; key ctrl+shift+w; wait_for 0.6 "switcher"
    type_text "$1"; wait_for 0.4 "filtered"; key Return; wait_for 1.2 "workspace $1"
}
wa_open() { # ARGS
    draw_quit
    draw_settle
    DRAW_EXTRA_ARGS="$1"
    draw_launch 15
    wait_for 1.5 "loaded"
    assert_no_crash
    wa_read
}

info "A sheet with frames, opened in Animate"
wa_open "$WA_T/sheet.png"
[[ "$LB_SHOWN" == -1 && "$P_VIS" == -1 && "$A_COUNT" == 6 ]] \
    && pass "Animate: the 6 frames open in the lightbox, the Animation panel shown" || fail "Animate on open: $(wa_s)"

# Num 0 twice: sheet view and back - and DRAW.cfg keeps the user's LIGHTBOX
park_mouse; key KP_0; wait_for 0.6 "Num 0"; wa_read; WA_OFF=$LB_SHOWN
park_mouse; key KP_0; wait_for 0.6 "Num 0"; wa_read
[[ "$WA_OFF" == 0 && "$LB_SHOWN" == -1 ]] && pass "Num 0: sheet view, Num 0 again: the lightbox" || fail "Num 0 in Animate: off '$WA_OFF', then $(wa_s)"

wa_switch "def"; wa_read
[[ "$LB_SHOWN" == 0 && "$P_VIS" == 0 ]] && pass "Default: the user's sheet view, the panel closed again" || fail "Default: $(wa_s)"
wa_switch "animate"; wa_read
[[ "$LB_SHOWN" == -1 && "$P_VIS" == -1 ]] && pass "Animate again: lightbox + panel back" || fail "back to Animate: $(wa_s)"

draw_quit
draw_settle
WA_CFG=$(grep -m1 '^LIGHTBOX=' "$DRAW_ROOT/QA/DRAW.qa.cfg" | cut -d= -f2 | tr -d '[:space:]')
WA_PCFG=$(grep -m1 '^ANIM_PANEL_VISIBLE=' "$DRAW_ROOT/QA/DRAW.qa.cfg" | cut -d= -f2 | tr -d '[:space:]')
[[ "$WA_CFG" =~ ^(0|FALSE)$ && "$WA_PCFG" =~ ^(0|FALSE)$ ]] \
    && pass "DRAW.cfg after quitting in Animate: LIGHTBOX and ANIM_PANEL_VISIBLE still the user's (0)" || fail "the overlay leaked into DRAW.cfg: LIGHTBOX='$WA_CFG' ANIM_PANEL_VISIBLE='$WA_PCFG'"

info "The same toggle under a --option override (Default workspace)"
wa_open "$WA_T/sheet.png --workspace default --option LIGHTBOX=1"
WA_L0=$LB_SHOWN
park_mouse; key KP_0; wait_for 0.6 "Num 0"; wa_read
[[ "$WA_L0" == -1 && "$LB_SHOWN" == 0 ]] && pass "--option LIGHTBOX=1: the lightbox; Num 0 turns it off and it stays off" || fail "--option toggle: before '$WA_L0', after Num 0 $(wa_s)"
draw_quit
draw_settle
WA_CFG=$(grep -m1 '^LIGHTBOX=' "$DRAW_ROOT/QA/DRAW.qa.cfg" | cut -d= -f2 | tr -d '[:space:]')
[[ "$WA_CFG" =~ ^(0|FALSE)$ ]] && pass "and DRAW.cfg keeps LIGHTBOX=0 (an override is never saved)" || fail "--option leaked into DRAW.cfg: LIGHTBOX='$WA_CFG'"

info "A picture without frames"
wa_open "$WA_T/plain.png"
WA_A0=$A_ACT; WA_L0=$LB_SHOWN
park_mouse; key KP_Add; wait_for 0.8 "Num +"; wa_read
[[ "$WA_A0" == 0 && "$WA_L0" == 0 && "$A_COUNT" == 2 && "$LB_SHOWN" == -1 ]] \
    && pass "plain.png: no frames, no lightbox; Num + makes frames 1-2 and the lightbox opens on them" || fail "plain picture: before active '$WA_A0' lightbox '$WA_L0', after Num + $(wa_s)"

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$WA_T"
assert_window_exists
