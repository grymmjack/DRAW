#!/bin/bash
# =============================================================================
# fill-adjust-leave.sh — QA test: Fill Adjust can always be left (Rick, 2026-11-15:
# "i cannot escape dither or fill adjust with enter, or escape, or d")
#
# A gradient fill, D (dither), another gradient slot clicked, D again, the slot's
# Gradient Editor opened (right-click > EDIT GRADIENT...) and closed with Enter,
# D again - each step keeps the fill adjusted, D keeps cycling, and Enter ends it.
# Enter / Esc are now taken first in FILL_ADJ_keys% (GUI/FILL-ADJ), so a held
# (or seemingly held) key can no longer swallow them.
#
# Dump: FILLADJ active mode ... dHeld | GRADSEL slot ... | DRWB x y w h | DRWAT slot | POPUP ...
# =============================================================================
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
source "$DRAW_ROOT/QA/dock-lib.sh"
FD_DIR="$(mktemp -d /tmp/draw-qa-faesc-XXXXXX)"
magick -size 320x200 xc:none "PNG32:$FD_DIR/blank.png"
draw_quit; draw_settle
DRAW_EXTRA_ARGS="$FD_DIR/blank.png"
draw_launch 15; wait_for 1.5 "loaded"
dk_begin
read -r _ Z _ _ _ <<< "$(grep -m1 '^VIEW ' "$DK_DUMP")"
read -r _ OX OY <<< "$(grep -m1 '^CVORG ' "$DK_DUMP")"
sx() { echo $(( OX + $1 * Z / 100 + Z / 200 )); }
sy() { echo $(( OY + $1 * Z / 100 + Z / 200 )); }
fa() { dk_settle; read -r _ F_ACT F_MODE F_AMT F_OX F_OY F_TW F_TH F_ROT F_OP F_DH <<< "$(grep -m1 '^FILLADJ ' "$DK_DUMP")"; info "$1: FILLADJ act=$F_ACT mode=$F_MODE dHeld=$F_DH | $(grep -m1 '^GRADSEL' "$DK_DUMP") | $(grep -m1 '^POPUP' "$DK_DUMP")"; }
key F2; sleep 0.3; key F8; sleep 0.3; key shift+r; sleep 0.3
drag "$(sx 50)" "$(sy 40)" "$(sx 200)" "$(sy 130)"; sleep 0.8
fa "filled"
key d; sleep 0.5; fa "after D"
read -r _ D_X D_Y D_W D_H <<< "$(grep -m1 '^DRWB ' "$DK_DUMP")"
info "first bin $D_X,$D_Y ${D_W}x$D_H"
S6X=$(( D_X + D_W / 2 + D_W + 4 )); S6Y=$(( D_Y + D_H / 2 + D_H + 4 ))
hover $S6X $S6Y; sleep 0.3; hover $(( S6X + 1 )) $S6Y; dk_settle; info "slot under: $(grep -m1 '^DRWAT' "$DK_DUMP")"
click $S6X $S6Y; sleep 0.6; fa "slot clicked"
dk_park; key d; sleep 0.5; fa "D after slot click"
right_click $S6X $S6Y
sleep 0.6; fa "right-clicked"
read -r _ _ PX PY PW PH <<< "$(grep -m1 '^POPUP' "$DK_DUMP")"
[[ -n "$PX" ]] && { click $(( PX + PW / 2 )) $(( PY + 8 )); sleep 1.0; }
screenshot "faesc-editor"
key Return; sleep 0.8; fa "editor closed (Enter)"
dk_park; key d; sleep 0.5; fa "D after editor"
key Return; sleep 0.8; fa "Enter"
(( F_ACT == 0 )) && pass "left Fill Adjust" || { fail "still adjusting (act $F_ACT dHeld $F_DH)"; screenshot faesc-stuck; key Escape; sleep 0.5; fa "Esc"; }
rm -rf "$FD_DIR"
assert_no_crash
