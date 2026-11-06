#!/bin/bash
# =============================================================================
# gui-browser-pane-fit.sh — QA test: the floating Browser's three panes
# (places | file list | preview) always fit side by side. The layout floored
# each pane on its own (places 80, preview 100, list forced to 100) and never
# fitted them to the window, so a resize or a wide preview slid the list under
# the preview with the splitters drawn on top; the places pane could go under
# its configured minimum, and toggling the preview back on brought back a stale
# width and lost the list.
# Reads BROWSERL <placesW> <listX> <listW> <prevX> <prevW> <prevOn> <dialogW>
# <placesMin> <prevMin> <prevBtnX> <prevBtnY> (Browser/FILE_DIALOG px).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt BROWSER_VISIBLE=1 BROWSER_POS_X=40 BROWSER_POS_Y=40 BROWSER_WIDTH=420 BROWSER_HEIGHT=220 BROWSER_DEFAULT_PREVIEW_OPEN=1
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Browser: panes fit the window Test ==="
dk_begin
LISTMIN=100; SPL=4

bp_win() { read -r _ _ WX WY WW WH _ <<< "$(grep '^WIN browser ' "$DK_DUMP")"; }
bp_bl()  { read -r _ NAVW LX LW PX PW PON DW NAVMIN PVMIN BTNX BTNY <<< "$(grep '^BROWSERL' "$DK_DUMP")"; }
# FD px -> viewport px (the Browser draws DW FD px across WW viewport px)
bp_vx() { echo $(( WX + $1 * WW / DW )); }
bp_vy() { echo $(( WY + $1 * WW / DW )); }
bp_state() { dk_park; dk_settle; bp_win; bp_bl; }

bp_fits() { # $1 = label, $2 = 1 if the preview must be showing
    bp_state
    info "$1: window ${WW}x$WH, panes places $NAVW | list $LX+$LW | preview $PX+$PW on=$PON (dialog $DW, mins $NAVMIN/$PVMIN)"
    local bad=""
    (( NAVW >= NAVMIN )) || bad+=" places $NAVW < its minimum $NAVMIN;"
    (( LW >= LISTMIN ))  || bad+=" list $LW < $LISTMIN;"
    (( LX == NAVW + SPL )) || bad+=" list starts at $LX, not flush after the places ($(( NAVW + SPL )));"
    if (( PON != 0 && PW > 0 )); then
        (( PX == LX + LW + SPL )) || bad+=" preview at $PX overlaps / gaps the list (ends $(( LX + LW )));"
        (( PX + PW == DW ))       || bad+=" preview ends at $(( PX + PW )), not the edge $DW;"
    else
        (( LX + LW + SPL == DW )) || bad+=" list ends at $(( LX + LW )) with no preview (edge $DW);"
    fi
    if [[ "${2:-0}" == 1 ]] && (( PON == 0 || PW == 0 )); then bad+=" the preview is not showing;"; fi
    if [[ -z "$bad" ]]; then pass "$1: the panes fit"; else fail "$1:$bad"; fi
}

wait_for 0.6 "browser placed in the work area"
bp_state
read -r _ _ _ WAL WAR WAT WAB <<< "$(grep '^SCR ' "$DK_DUMP")" # work area left/right/top/bottom
[[ -n "$WW" && -n "$DW" ]] || { fail "no Browser window / BROWSERL line"; exit 1; }
bp_fits "opened"

(( WW < WAR - WAL - 100 )) || fail "the work area ($WAL..$WAR) leaves no room to widen the Browser"
# 1) wider, so all three panes have room
drag $(( WX + WW - 2 )) $(( WY + WH - 2 )) $(( WAR - 2 )) $(( WY + WH + 60 ))
wait_for 0.5 "browser resized wider"
bp_fits "resized wider" 1
screenshot "browser-pane-wide"

# 2) the places splitter as far left as it goes
MY=$(( WY + WH / 2 ))
drag "$(bp_vx $(( NAVW + 2 )))" "$MY" $(( WX + 4 )) "$MY"
wait_for 0.5 "places splitter dragged left"
bp_fits "places at its minimum" 1
(( NAVW == NAVMIN )) && pass "the places pane stops at its minimum ($NAVMIN)" || fail "the places pane went to $NAVW (minimum $NAVMIN)"

# 3) the preview splitter as far left as it goes (a wide preview)
drag "$(bp_vx $(( PX - 2 )))" "$MY" $(( WX + 8 )) "$MY"
wait_for 0.5 "preview splitter dragged left"
bp_fits "wide preview" 1

# 4) preview off, then on again
click "$(bp_vx "$BTNX")" "$(bp_vy "$BTNY")"; wait_for 0.5 "preview toggled off"
bp_state; (( PON == 0 )) && pass "the preview toggled off" || fail "the preview did not toggle off (button at FD $BTNX,$BTNY)"
bp_fits "preview off"
click "$(bp_vx "$BTNX")" "$(bp_vy "$BTNY")"; wait_for 0.5 "preview toggled on"
bp_fits "preview back on" 1
screenshot "browser-pane-toggled"

# 5) as small as the window goes, then back
drag $(( WX + WW - 2 )) $(( WY + WH - 2 )) $(( WX + 10 )) $(( WY + 10 ))
wait_for 0.5 "browser shrunk"
bp_fits "smallest window"
screenshot "browser-pane-small"
drag $(( WX + WW - 2 )) $(( WY + WH - 2 )) $(( WAR - 2 )) $(( WY + 300 ))
wait_for 0.5 "browser grown again"
bp_fits "grown again" 1

assert_window_exists
info "=== Browser: panes fit the window Test PASSED ==="
