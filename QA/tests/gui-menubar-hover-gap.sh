#!/bin/bash
# =============================================================================
# gui-menubar-hover-gap.sh — QA test: with a menu open, moving the pointer off
# its root onto the empty menu bar (right of HELP) and back plays no "menu
# open" sound - nothing opens. Moving onto another root still does (it opens).
# Rick, 2026-11-06: "when i hover the mouse pointer to the right of HELP menu
# option while menu is open, i can hear it trying to open something - it plays
# the open sound, but there is nothing there".
# Reads MBAR <open> <hover> <sounds> and ROOT <i> <x> <w> <label>.
# QA-OPTIONS: DOCK_DUMP=QA/.dock-dump.txt
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Menu bar: no open sound over the empty bar Test ==="
dk_begin
mbar() { read -r _ MB_OPEN MB_HOVER MB_SND <<< "$(grep '^MBAR' "$DK_DUMP")"; }
root() { read -r _ R_I R_X R_W _ <<< "$(awk -v n="$1" '$1 == "ROOT" && $5 == n' "$DK_DUMP")"; }
root HELP; HI=$R_I; HX=$R_X; HW=$R_W
root EFFECTS; EI=$R_I; EX=$R_X
root AUDIO; AX=$R_X
info "HELP root $HI at $HX+$HW, EFFECTS at $EX, AUDIO at $AX"
[[ -n "$HX" && -n "$AX" ]] || { fail "no ROOT lines in the dump"; exit 1; }

click $(( HX + 4 )) 6; wait_for 0.6 "HELP open"
mbar; S0=$MB_SND
[[ "$MB_OPEN" == "$HI" ]] && pass "HELP is open" || fail "HELP did not open (open root $MB_OPEN)"
GAP=$(( (HX + HW + AX) / 2 ))
for x in $(( HX + HW + 6 )) "$GAP" $(( HX + HW + 6 )) "$GAP"; do hover "$x" 6; sleep 0.25; done
mbar
info "after moving over the empty bar: open $MB_OPEN hover $MB_HOVER sounds $S0 -> $MB_SND"
[[ "$MB_OPEN" == "$HI" ]] && pass "HELP stays open over the empty bar" || fail "the open menu changed to $MB_OPEN over the empty bar"
(( MB_SND == S0 )) && pass "no open sound over the empty bar" || fail "$(( MB_SND - S0 )) open sound(s) over the empty bar - nothing opened"
hover $(( HX + 4 )) 6; sleep 0.3; mbar
(( MB_SND == S0 )) && pass "no open sound back onto HELP, already open" || fail "back onto the open HELP played $(( MB_SND - S0 )) open sound(s)"
hover $(( EX + 6 )) 6; sleep 0.4; mbar
[[ "$MB_OPEN" == "$EI" ]] && pass "hovering EFFECTS opens it" || fail "EFFECTS did not open (open root $MB_OPEN)"
(( MB_SND == S0 + 1 )) && pass "switching to EFFECTS plays the open sound once" || fail "switching to EFFECTS played $(( MB_SND - S0 )) open sounds, not 1"
key Escape; wait_for 0.3 "closed"
assert_window_exists
info "=== Menu bar: no open sound over the empty bar Test PASSED ==="
