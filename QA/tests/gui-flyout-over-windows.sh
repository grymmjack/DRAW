#!/bin/bash
# =============================================================================
# gui-flyout-over-windows.sh — QA test: the toolbox's Smart Shapes flyout is
# drawn on top of the native windows (Color Mixer, Advanced Color Picker,
# Preview ...) on every frame, not just the frames that redraw the GUI.
# Rick, 2026-11-07: "smart shape flyout menu is being drawn behind the docked
# panels to the left ... color mixer, advanced color mixer, 3d color mixer,
# browser, preview".
# Cause: POPUP_reblit_to_screen0 took the flyout's box from the region table,
# which is filled only on GUI-redraw frames; on cursor-only frames (holding
# the button, moving along the row) the windows drew over it.
#   - hold the Smart Shapes button: the flyout opens over the docked Color
#     Mixer; its 1px frame rows/columns are one colour (no window over it)
#   - move along the row (cursor-only frames): still one colour
#   - release over a child that lies over the mixer: that shape is chosen
#     and the flyout closes (the mixer took the release before the flyout),
#     the mixer's color is unchanged (no click through)
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt WORKSPACES_DIR=QA/.tbed-ws TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE COLOR_MIXER_VISIBLE=1 ADV_COLOR_PICKER_VISIBLE=1 DOCK_CUSTOM=1 DOCK_LEFT_1=AUTO;toolbox|organizer|drawer DOCK_LEFT_2=AUTO;advbar|editbar DOCK_LEFT_3=AUTO;colormixer|advcolorpicker DOCK_RIGHT_1=AUTO;layers
# =============================================================================

source "$DRAW_ROOT/QA/popup-lib.sh"

info "=== Smart Shapes flyout over the windows ==="
wait_for 1.2 "settle"
key Escape
dk_park; dk_settle
tool() { awk '$1 == "VIEW" {print $5}' "$DK_DUMP"; }
cmixfg() { grep '^CMIX ' "$DK_DUMP" | awk '{print $15}'; }

line=$(awk '$1 == "BTN" && $2 == "toolbox" && $6 == "smart-shapes"' "$DK_DUMP" | head -1)
if [[ -z "$line" ]]; then fail "no Smart Shapes button in the toolbox dump"; assert_no_crash; exit 0; fi
read -r _ _ _ _ _ _ BX BY BW BH <<< "$line"
info "Smart Shapes button at $BX,$BY ${BW}x$BH"
FG0=$(cmixfg)

frame_ok() { # LABEL: the flyout's frame rows / columns are one colour
    local bad="" f
    snap_region "$PX" "$PY" "$PW" 1 "$1-ftop"; local FT=$SNAP_RESULT
    snap_region "$PX" $(( PY + PH - 1 )) "$PW" 1 "$1-fbot"; local FB=$SNAP_RESULT
    snap_region $(( PX + PW - 1 )) "$PY" 1 "$PH" "$1-fright"; local FR=$SNAP_RESULT
    for f in "$FT" "$FB" "$FR"; do one_color "$f" || bad+=" $(basename "$f")"; done
    if [[ -z "$bad" ]]; then pass "$1: the flyout's frame is whole (no window drawn over it)"; else fail "$1: a window is drawn over the flyout:$bad"; fi
}

mouse_down $(( BX + BW / 2 )) $(( BY + BH / 2 )); sleep 0.6
dk_settle
if ! popup_rect subtool; then
    # the old code dropped the box on cursor-only frames: use the geometry it drew
    fail "the flyout was not redrawn on top of the windows (no POPUP subtool)"
    mouse_up; assert_no_crash; exit 0
fi
info "flyout at $PX,$PY ${PW}x$PH"
read -r _ wn wx wy ww wh _ <<< "$(grep '^WIN colormixer ' "$DK_DUMP")"
info "colormixer window at $wx,$wy ${ww}x$wh"
if (( PX + PW > wx && PX < wx + ww && PY < wy + wh && PY + PH > wy )); then pass "the flyout overlaps the Color Mixer"; else fail "the flyout does not reach the Color Mixer (test layout)"; fi
frame_ok "open"

# move along the row: cursor-only frames
LASTX=$(( PX + PW - BW / 2 - 2 )); MIDY=$(( PY + PH - BH / 2 - 2 )) # the row of shapes (the top row is the button)
for x in $(( BX + BW + 4 )) $(( (BX + LASTX) / 2 )) "$LASTX"; do
    hover "$x" "$MIDY"; sleep 0.35
done
dk_settle
popup_rect subtool || fail "the flyout dropped off the top while the pointer moved"
frame_ok "hovering"

T0=$(tool)
mouse_up; sleep 0.5 # (at the last hover point)
dk_park; dk_settle
T1=$(tool)
[[ "$T1" != "$T0" ]] && pass "releasing over the last shape (over the mixer) picks it (tool $T0 -> $T1)" || fail "the release over the last shape did not pick it (tool $T0 -> $T1)"
[[ "$(cmixfg)" == "$FG0" ]] && pass "the release over the mixer did not pick a color ($FG0)" || fail "the release went through to the mixer ($FG0 -> $(cmixfg))"
grep -q '^POPUP subtool' "$DK_DUMP" && fail "the flyout stayed open ($(grep '^POPUP' "$DK_DUMP" | tr '\n' ' '))" || pass "the flyout closed"
assert_no_crash
