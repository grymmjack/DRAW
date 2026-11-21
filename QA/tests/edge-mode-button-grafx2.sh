#!/bin/bash
# =============================================================================
# edge-mode-button-grafx2.sh — QA test (the GraFX2 workspace: the bars in a bottom row): the bars' Pixel-Perfect button (action 959,
# once the shared Pixel-Perfect / Anti-Aliasing "edge mode" button). Rick 2026-11-21: "i no
# longer want PP pixel perfect overlayed with any AA stuff since i have a dedicated toolbox
# button for it" - so a right-click no longer switches it to AA (action 960 is gone).
#   1. a click turns Pixel-Perfect on, a second click off
#   2. a right-click changes nothing: it stays Pixel-Perfect
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

info "=== The bars' Pixel-Perfect button ==="
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
    tap "click (on)"; R0=$E_ON
    right_click "$BX" "$BY"; wait_for 0.4 "right-click"; dk_park; dk_settle; edge_on "$P"; R1=$E_ON
    tap "click (off)"; R2=$E_ON
    (( R0 != 0 && R1 != 0 && R2 == 0 )) && pass "$P: a right-click leaves it Pixel-Perfect ($R0 -> $R1 -> $R2)" || fail "$P: on, right-click, click: $R0 -> $R1 -> $R2 (want on, on, off)"
done
screenshot "edge-mode-button"
assert_no_crash
