#!/bin/bash
# =============================================================================
# browser-thumb-nav.sh — QA test: the mouse's back / forward (thumb) buttons
# walk the Browser's folder history (Rick, 2026-11-14: "please make mouse back
# button go back in the browser, and mouse forward go forward in browser - and
# in file dialogs, etc.").
#
# Before: the Browser fed the file dialog 0 for buttons 4 / 5, so its own nav
# history (FD_FS_nav_back / _forward) never ran there; the thumb buttons were
# always Undo / Redo, even over the Browser. And a quick thumb click (down and
# up inside one frame's _MOUSEINPUT drain) read as never pressed.
#
#  1. Help > Examples, double-click the first folder: one step of history
#  2. over the Browser, a quick back click (one XTEST press+release): the folder
#     before, one forward step - and no Undo fired
#  3. over the Browser, forward: the folder again - and no Redo fired
#  4. off the Browser (canvas), back: Undo fires, the Browser stays put
#
# Dump: BROWSERDIR <back depth> <forward depth> <folder> | BROWSERS | WIN browser
# X11 buttons 8 / 9 are back / forward (GLFW BUTTON_4 / 5 = _MOUSEBUTTON(4) / (5)).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt DEVELOPER_MODE=TRUE TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE BROWSER_POS_X=40 BROWSER_POS_Y=40 BROWSER_WIDTH=420 BROWSER_HEIGHT=420 BROWSER_DEFAULT_VIEW_MODE=0 BROWSER_DEFAULT_PREVIEW_OPEN=0
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
LOG="$DRAW_ROOT/inputs.log"
info "=== Browser: thumb buttons = back / forward ==="
dk_begin

bdir() { read -r _ BD_BACK BD_FWD BD_PATH <<< "$(grep -m1 '^BROWSERDIR ' "$DK_DUMP")"; }
bs() { read -r _ BS_VIS BS_SEL BS_LAST BS_ROWH BS_TOP BS_SCROLL BS_N _ <<< "$(grep -m1 '^BROWSERS ' "$DK_DUMP")"; }
bwin() { read -r _ _ WX WY WW WH _ <<< "$(grep -m1 '^WIN browser ' "$DK_DUMP")"; read -r _ _ LX _ _ _ _ DW _ <<< "$(grep -m1 '^BROWSERL' "$DK_DUMP")"; }
mark() { LOGN=$(wc -l < "$LOG" 2>/dev/null || echo 0); }
fired_since() { tail -n +$(( LOGN + 1 )) "$LOG" 2>/dev/null | grep -o 'action=[0-9]*' | cut -d= -f2 | tr '\n' ' '; }
# thumb N X Y: a quick click of X button N at X,Y - press and release in one
# XTEST batch, so both land inside one frame's drain (the latch's case)
thumb() {
    local ax ay
    hover "$2" "$3"; wait_for 0.3 "pointer there"
    read -r ax ay <<< "$(adapter_to_screen "$2" "$3")"
    xdotool mousemove $(( ax + 1 )) "$ay" click "$1"
    wait_for 0.8 "button $1"; dk_settle
}

[[ -f "$LOG" ]] || info "(no inputs.log yet - DEVELOPER_MODE writes it)"
# --- 1. into a folder ------------------------------------------------------------
read -r _ _ hx hw <<< "$(grep -m1 '^MROOT help ' "$DK_DUMP")"
click $(( hx + hw / 2 )) 6; wait_for 0.5 "HELP"; dk_settle
read -r _ mx my _ _ <<< "$(grep -m1 '^MENU ' "$DK_DUMP")"
click $(( mx + 30 )) $(( my + 9 + 12 * 7 + 5 * 4 )); wait_for 1.2 "Examples"; dk_park; dk_settle
bs; bdir; bwin
D0="$BD_PATH"; B0=$BD_BACK
(( BS_VIS == -1 )) && [[ "$D0" == *SAMPLES* ]] && pass "Help > Examples: the Browser at $D0" || fail "Examples: visible $BS_VIS folder '$D0'"
FY=$(( BS_TOP - BS_SCROLL + BS_ROWH / 2 ))
VX=$(( WX + (LX + 30) * WW / DW )); VY=$(( WY + FY * WW / DW ))
double_click "$VX" "$VY"; wait_for 1.2 "into the folder"; dk_park; dk_settle; bdir
D1="$BD_PATH"
[[ "$D1" != "$D0" && "$BD_BACK" == $(( B0 + 1 )) ]] && pass "double-click: now in $D1 (back $BD_BACK)" || fail "double-click: folder '$D1' back $BD_BACK (was '$D0' back $B0)"

# --- 2. back over the Browser ------------------------------------------------------
OX=$(( WX + WW / 2 )); OY=$(( WY + WH / 2 ))
mark; thumb 8 "$OX" "$OY"; bdir; F=" $(fired_since)"
[[ "$BD_PATH" == "$D0" && "$BD_FWD" == 1 ]] && pass "back (a quick click over the Browser): $D0 again, forward 1" || fail "back: folder '$BD_PATH' forward $BD_FWD, want '$D0' / 1"
[[ "$F " != *" 301 "* ]] && pass "and no Undo with it [$F ]" || fail "back over the Browser also fired Undo [$F ]"

# --- 3. forward over the Browser ---------------------------------------------------
mark; thumb 9 "$OX" "$OY"; bdir; F=" $(fired_since)"
[[ "$BD_PATH" == "$D1" && "$BD_FWD" == 0 ]] && pass "forward: $D1 again" || fail "forward: folder '$BD_PATH' forward $BD_FWD, want '$D1' / 0"
[[ "$F " != *" 302 "* ]] && pass "and no Redo with it [$F ]" || fail "forward over the Browser also fired Redo [$F ]"

# --- 4. back off the Browser = Undo -------------------------------------------------
mark; thumb 8 $(( WX + WW + 60 )) $(( WY + WH / 2 )); bdir; F=" $(fired_since)"
[[ "$F " == *" 301 "* ]] && pass "back over the canvas: Undo [$F ]" || fail "back over the canvas: no Undo [$F ]"
[[ "$BD_PATH" == "$D1" ]] && pass "and the Browser did not move ($D1)" || fail "back over the canvas moved the Browser to '$BD_PATH'"
assert_no_crash
info "=== Browser: thumb buttons = back / forward: done ==="
