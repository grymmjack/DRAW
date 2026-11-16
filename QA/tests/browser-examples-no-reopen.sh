#!/bin/bash
# =============================================================================
# browser-examples-no-reopen.sh — QA test: Help > Examples never opens a file
# by itself (Rick, 2026-11-14: "when i do help | examples -> the browser
# automatically tried to open the last file i opened from it, without me doing
# anything").
#
#  1. Help > Examples: the Browser shows SAMPLES; nothing is opened
#  2. double-click a file in it: that file opens (one open), the Browser hides
#  3. Help > Examples again - a human click, held while the hand drifts off the
#     menu: the Browser shows; still one open, and no drag of that file (the
#     double-click's press armed a file drag-out that outlived the Browser and
#     became a live drag here: its release dropped the file onto the canvas)
#  4. and with the Browser already showing: Help > Examples opens nothing
#
# Dump: BROWSERS visible selected lastClick rowH listTop scroll count view done
# opens dragArmed document | BROWSERL (FD px) | WIN browser x y w h | MROOT / MENU.
# Help menu: EXAMPLES is row 8 below 4 dividers (GUI/MENUBAR: rows from
# subY + 2, 12 px; dividers 5 px) -> MENU y + 9 + 12 * 7 + 5 * 4.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE BROWSER_POS_X=40 BROWSER_POS_Y=40 BROWSER_WIDTH=420 BROWSER_HEIGHT=420 BROWSER_DEFAULT_VIEW_MODE=0 BROWSER_DEFAULT_PREVIEW_OPEN=0
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Browser: Help > Examples opens nothing by itself ==="
dk_begin

bs() { read -r _ BS_VIS BS_SEL BS_LAST BS_ROWH BS_TOP BS_SCROLL BS_N BS_VIEW BS_DONE BS_OPENS BS_DRAG BS_DOC <<< "$(grep -m1 '^BROWSERS ' "$DK_DUMP")"; }
bwin() { read -r _ _ WX WY WW WH _ <<< "$(grep -m1 '^WIN browser ' "$DK_DUMP")"; read -r _ _ LX _ _ _ _ DW _ <<< "$(grep -m1 '^BROWSERL' "$DK_DUMP")"; }
bs_s() { bs; echo "visible $BS_VIS sel $BS_SEL n $BS_N opens $BS_OPENS done $BS_DONE drag $BS_DRAG doc '$BS_DOC'"; }
examples() { # the real menu path: a click on HELP, a click on EXAMPLES
    local hx hw mx my
    read -r _ _ hx hw <<< "$(grep -m1 '^MROOT help ' "$DK_DUMP")"
    [[ -z "$hx" ]] && { fail "$1: no HELP menu"; return 1; }
    click $(( hx + hw / 2 )) 6; wait_for 0.5 "HELP open"; dk_settle
    read -r _ mx my _ _ <<< "$(grep -m1 '^MENU ' "$DK_DUMP")"
    [[ -z "$mx" ]] && { fail "$1: the HELP menu did not open"; return 1; }
    # a human click: the button stays down a few frames (menu items fire on the
    # press, so the Browser is showing while it is still held)
    # press, while it is still held, the hand drifts a little (onto the canvas)
    local ey=$(( my + 9 + 12 * 7 + 5 * 4 ))
    # (just outside the Browser - the room beside it is canvas)
    mouse_down $(( mx + 30 )) "$ey"; wait_for 0.3 "held"; dk_settle; bwin
    info "$1, held: $(bs_s)"
    hover $(( WX + WW + 30 )) $(( WY + WH / 2 )); wait_for 0.3 "drifted"; dk_settle; info "$1, drifted: $(bs_s)"; DRIFT_DRAG=$BS_DRAG
    mouse_up; wait_for 1.0 "$1"
    dk_park; wait_for 0.6 "a few frames"; dk_settle
}

bs; info "start: $(bs_s)"
(( BS_VIS == 0 && BS_OPENS == 0 )) || fail "start: the Browser is showing or something was opened ($(bs_s))"

# --- 1. Examples -------------------------------------------------------------
examples "Help > Examples"; bs
(( BS_VIS == -1 )) && pass "Help > Examples: the Browser shows ($BS_N entries)" || fail "Examples: $(bs_s)"
(( BS_OPENS == 0 )) && pass "Help > Examples: nothing opened" || fail "Examples opened a file: $(bs_s)"
(( BS_N > 1 )) || fail "no entries in SAMPLES ($(bs_s))"

# --- 2. double-click the last entry (a file: folders sort first) ---------------
bwin
ROW=$(( BS_N - 1 ))
FY=$(( BS_TOP + ROW * BS_ROWH - BS_SCROLL + BS_ROWH / 2 ))
VX=$(( WX + (LX + 30) * WW / DW )); VY=$(( WY + FY * WW / DW ))
(( VY < WY + WH - 4 )) || fail "row $ROW (y $VY) is below the window ($WY + $WH): make the Browser taller"
double_click "$VX" "$VY"; wait_for 1.5 "the file opens"; dk_park; dk_settle; bs
FILE1="$BS_DOC"; info "after the double-click: $(bs_s)"
(( BS_OPENS == 1 )) && [[ "$FILE1" == *SAMPLES/* ]] && pass "double-click: opened $(basename "$FILE1") (one open)" || fail "double-click: $(bs_s)"
(( BS_VIS == 0 )) && pass "and the Browser hid" || fail "the Browser still shows: $(bs_s)"

# --- 3. Examples again ------------------------------------------------------------
examples "Help > Examples again"; bs
(( BS_VIS == -1 )) && pass "again: the Browser shows" || fail "again: $(bs_s)"
(( DRIFT_DRAG == 0 )) && pass "again: the held click moving off the menu drags nothing (no drag left armed by the double-click)" || fail "again: the held click became a drag of the last file (drag $DRIFT_DRAG: -1 armed, -2 dragging)"
(( BS_OPENS == 1 )) && pass "again: nothing re-opened (still one open)" || fail "again: opens $BS_OPENS, want 1 ($(bs_s))"
screenshot "browser-examples-again"

# --- 4. Examples with the Browser already showing --------------------------------
examples "Help > Examples, the Browser showing"; bs
(( BS_VIS == -1 && BS_OPENS == 1 )) && pass "showing: Examples opens nothing" || fail "showing: $(bs_s)"
assert_no_crash
info "=== Browser: Help > Examples opens nothing by itself: done ==="
