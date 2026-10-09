#!/bin/bash
# =============================================================================
# windows-input-guards.sh — QA test: input over a native window (floating or
# docked) stays with the window; the canvas behind it never reacts.
#   wheel                 over each window: the canvas zoom is unchanged
#   middle-drag           starting on each window: the canvas does not pan
#   middle double-click   on each window: the zoom is not reset
#   draw over             a brush stroke dragged from the canvas across a
#                         floating window hides it while drawing, and it comes
#                         back on release
# Windows: Color Mixer, Advanced Color Picker, Pen floating; 3D Color Space
# docked; Preview floating; Customize Toolbars open.
# These pin the behaviour of the per-window guards in INPUT/MOUSE.BM.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt WORKSPACES_DIR=QA/.tbed-ws COLOR_MIXER_VISIBLE=1 ADV_COLOR_PICKER_VISIBLE=1 PEN_PANEL_VISIBLE=1 COLOR_SPACE_3D_VISIBLE=1 PREVIEW_VISIBLE=1 COLOR_MIXER_X=150 COLOR_MIXER_Y=20 ADV_COLOR_PICKER_X=340 ADV_COLOR_PICKER_Y=20 PEN_PANEL_X=530 PEN_PANEL_Y=20 DOCK_CUSTOM=1 DOCK_LEFT_1=AUTO;layers DOCK_LEFT_2=AUTO;editbar DOCK_RIGHT_1=AUTO;toolbox|organizer|drawer DOCK_RIGHT_2=AUTO;colorspace3d|advbar
# =============================================================================

source "$DRAW_ROOT/QA/tbed-lib.sh"
tb_reset_ws

view() { read -r _ VZ VX VY VT <<< "$(grep '^VIEW ' "$DK_DUMP")"; }
# a canvas point inside no window -> FX FY
free_point() {
    local x y o ox oy ow oh ok
    dk_scr
    for (( y = DOCK_BOT - 12; y > DOCK_TOP + 10; y -= 12 )); do
        for (( x = CAN_LX + 8; x < CAN_RX - 8; x += 12 )); do
            ok=1
            for o in "${WINS[@]}"; do
                read -r _ _ ox oy ow oh _ <<< "$o"
                if (( x >= ox - 2 && x < ox + ow + 2 && y >= oy - 2 && y < oy + oh + 2 )); then ok=0; break; fi
            done
            if (( ok )); then FX=$x; FY=$y; return 0; fi
        done
    done
    return 1
}

info "=== Input over windows stays with the window ==="
wait_for 1.2 "settle"
key Escape
dk_park
dk_settle
key b; sleep 0.3                     # the brush
dk_park; dk_settle
mapfile -t WINS < <(grep '^WIN ' "$DK_DUMP")
info "windows: $(printf '%s | ' "${WINS[@]}")"
(( ${#WINS[@]} >= 5 )) || fail "only ${#WINS[@]} windows are up"

for w in "${WINS[@]}"; do
    read -r _ wn wx wy ww wh ws <<< "$w"
    cx=$(( wx + ww / 2 )); cy=$(( wy + wh - 12 ))   # low in the window (titles / headers are at the top)
    view; Z0=$VZ; X0=$VX; Y0=$VY
    scroll_down "$cx" "$cy"; sleep 0.2; scroll_down "$cx" "$cy"; sleep 0.4; dk_settle
    view
    if [[ "$VZ" == "$Z0" ]]; then pass "$wn: the wheel over it does not zoom the canvas"; else fail "$wn: the wheel zoomed the canvas ($Z0 -> $VZ)"; fi
    scroll_up "$cx" "$cy"; sleep 0.2; scroll_up "$cx" "$cy"; sleep 0.3
    view; X0=$VX; Y0=$VY
    mouse_down "$cx" "$cy" 2; sleep 0.15
    hover $(( cx - 30 )) $(( cy - 20 )); sleep 0.15; hover $(( cx - 60 )) $(( cy - 40 )); sleep 0.2
    mouse_up 2; sleep 0.4; dk_settle
    view
    if [[ "$VX $VY" == "$X0 $Y0" ]]; then pass "$wn: a middle-drag starting on it does not pan the canvas"; else fail "$wn: the canvas panned ($X0,$Y0 -> $VX,$VY)"; fi
done

# middle double-click resets the zoom on the canvas (control) but not on a window
# (the harness's click helpers are too slow for a double-click: drive it raw)
mdbl() {
    local ax ay
    read -r ax ay <<< "$(adapter_to_screen "$1" "$2")"
    driver_input_move "$ax" "$ay"; sleep 0.1
    driver_input_button down 2; sleep 0.07; driver_input_button up 2; sleep 0.07
    driver_input_button down 2; sleep 0.07; driver_input_button up 2   # (one press edge per frame: space them, < 0.3s)
    sleep 0.5; dk_settle
}
zoom_in() { free_point; for i in 1 2 3; do scroll_up "$FX" "$FY"; sleep 0.15; done; sleep 0.3; dk_settle; }
for w in "${WINS[@]}"; do
    read -r _ wn wx wy ww wh _ <<< "$w"
    zoom_in; view; Z1=$VZ
    mdbl $(( wx + ww / 2 )) $(( wy + wh - 12 )); view
    if [[ "$VZ" == "$Z1" ]]; then pass "$wn: a middle double-click on it keeps the zoom ($VZ)"; else fail "$wn: the zoom changed ($Z1 -> $VZ)"; fi
done
free_point; mdbl "$FX" "$FY"; view
if [[ "$VZ" != "$Z1" ]]; then pass "control: a middle double-click on the canvas resets the zoom ($Z1 -> $VZ)"; else info "control: the harness's middle double-click did not reset the zoom on the canvas either (window check above not conclusive)"; fi

# drawing across a floating window hides it while drawing
for w in "${WINS[@]}"; do
    read -r _ wn wx wy ww wh ws <<< "$w"
    (( ws > 0 )) && continue                   # docked: the canvas never reaches under it
    dk_scr
    sy=$(( wy + wh - 20 )); (( sy > DOCK_BOT - 4 )) && sy=$(( DOCK_BOT - 10 ))
    # start the stroke on the canvas at that height, outside every window,
    # as near the window as possible
    sx=""; best=99999
    for (( x = CAN_LX + 6; x < CAN_RX - 6; x += 4 )); do
        free=1
        for o in "${WINS[@]}"; do
            read -r _ _ ox oy ow oh _ <<< "$o"
            if (( x >= ox - 2 && x < ox + ow + 2 && sy >= oy - 2 && sy < oy + oh + 2 )); then free=0; break; fi
        done
        (( free )) || continue
        d=$(( x < wx ? wx - x : x - wx - ww )); (( d < 0 )) && d=$(( -d ))
        if (( d < best )); then best=$d; sx=$x; fi
    done
    [[ -z "$sx" ]] && { info "$wn: no free canvas at y=$sy to start a stroke"; continue; }
    mouse_down "$sx" "$sy"; sleep 0.15
    hover $(( wx + ww / 2 )) "$sy"; sleep 0.3; hover $(( wx + ww / 2 + 5 )) "$sy"; sleep 0.4
    dk_settle
    if grep -q "^WIN $wn " "$DK_DUMP"; then fail "$wn: still shown while drawing over it"; else pass "$wn: hidden while a stroke is drawn over it"; fi
    mouse_up; sleep 0.5; dk_park; dk_settle
    if grep -q "^WIN $wn " "$DK_DUMP"; then pass "$wn: back after the stroke"; else fail "$wn: did not come back after the stroke"; fi
    key ctrl+z; sleep 0.3
done
assert_no_crash
tb_reset_ws
