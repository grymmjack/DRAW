#!/bin/bash
# =============================================================================
# edge-mode-button-grafx2.sh — QA test (the GraFX2 workspace: the bars in a bottom row): the shared Pixel-Perfect / Anti-Aliasing button (action
# 959; a right-click switches its target, 960). Rick 2026-11-18: "clicking it, doesn't
# actually enable anti aliasing, and clicking it off again does not either - it was right
# click on PP to get AA to go on and off, but it doesn't work. to enable it i have to use
# EDIT -> ANTI ALIASING".
#   1. a click turns its mode (Pixel-Perfect) on, a second click off
#   2. a right-click makes it the AA button; a click turns AA on, another off
#   3. on the edit bar and on the advanced bar alike
# Dump: BTN panel idx kind id name x y w h; BTNS panel idx id enabled available
# (enabled = its mode is on); TBED ... (GUI/TOOLBAR-EDITOR TBED_dump$).
# QA-OPTIONS: WORKSPACE=grafx2 DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE ANTIALIAS=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"

# on PANEL: the edge button's centre -> BX BY (1 = not on that panel)
edge_btn() { local l x y w h; l=$(grep -m1 "^BTN $1 [0-9]* 2 959 " "$DK_DUMP") || return 1; read -r _ _ _ _ _ _ x y w h <<< "$l"; (( w > 0 )) || return 1; BX=$(( x + w / 2 )); BY=$(( y + h / 2 )); }
edge_on() { read -r _ _ _ _ E_ON _ <<< "$(grep -m1 "^BTNS $1 [0-9]* 959 " "$DK_DUMP")"; }
tap() { click "$BX" "$BY"; wait_for 0.4 "$1"; dk_park; dk_settle; edge_on "$P"; }

info "=== The Pixel-Perfect / Anti-Aliasing button ==="
dk_begin
for P in editbar advbar; do
    if ! edge_btn "$P"; then
        if [[ "$P" == advbar ]]; then
            info "no edge-mode button on the advanced bar in this workspace"
        else
            fail "no edge-mode button (cmd:959) on the $P"
        fi
        continue
    fi
    edge_on "$P"; E0=$E_ON
    info "$P: edge button at $BX,$BY, on '$E0'"
    tap "click"; E1=$E_ON
    tap "click again"; E2=$E_ON
    (( E1 != 0 && E2 == 0 )) && pass "$P: a click turns Pixel-Perfect on, another off ($E0 -> $E1 -> $E2)" || fail "$P: Pixel-Perfect clicks $E0 -> $E1 -> $E2 (want on, then off)"
    right_click "$BX" "$BY"; wait_for 0.4 "right-click: the AA face"; dk_park; dk_settle; edge_on "$P"; R=$E_ON
    tap "click (AA)"; A1=$E_ON
    tap "click (AA) again"; A2=$E_ON
    (( A1 != 0 && A2 == 0 )) && pass "$P: after the right-click a click turns Anti-Aliasing on, another off ($R -> $A1 -> $A2)" || fail "$P: AA clicks $R -> $A1 -> $A2 (want on, then off)"
    right_click "$BX" "$BY"; wait_for 0.4 "back to the PP face"; dk_park; dk_settle
done
screenshot "edge-mode-button"
assert_no_crash
