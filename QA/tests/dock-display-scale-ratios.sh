#!/bin/bash
# =============================================================================
# dock-display-scale-ratios.sh — QA test: the floating panels follow the UI
# Scale with the default scale ratios (no toolbar scale override).
#
# Rick 2026-11-10: "the animation panel isn't actually resizing when the
# display scale changes". The floating panels (Animation, Color Mixer, Pen,
# Advanced Color Picker, 3D Color Space) draw straight to the window at
# USCALE.mixer = ROUND(UI Scale * SCALE_RATIO_MIXER 0.5): 1x at UI 1 and at
# UI 2, so a change from 2 to 1 left them as they were while everything else
# halved, and at UI 2 they were half the size of the Layers text beside them.
# The other display scale tests pin TOOLBAR_SCALE (QA's geometry model), which
# hid it - this one clears it, as a user's DRAW.cfg has it.
# Now the ratio is doubled for these panels: 0.5 = the UI Scale itself.
# - at the start and after each change the Animation panel draws at the
#   display scale (ANIMP renderScale 100; was 50 at scale 2)
# - its size, the Color Mixer's and the Pen panel's stay the same in viewport
#   pixels across the change (the same share of the UI); were half at scale 2
# - every column, slot and panel the same as a fresh start (ds_run)
#
# Layout (Rick's): toolbox | organizer | drawer and the edit bar on the left;
# animation | layers (120 px) and the advanced bar on the right; Color Mixer
# and Pen floating.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLBAR_SCALE=0 ANIM_PANEL_VISIBLE=-1 COLOR_MIXER_VISIBLE=1 PEN_PANEL_VISIBLE=1 PREVIEW_VISIBLE=1 LAYER_PANEL_WIDTH=120 DOCK_CUSTOM=1 DOCK_LEFT_1=AUTO;toolbox|organizer|drawer DOCK_LEFT_2=AUTO;editbar DOCK_RIGHT_1=AUTO;animation|layers DOCK_RIGHT_2=AUTO;advbar
# =============================================================================
info "=== Dock: floating panels follow the UI Scale (default ratios) ==="
source "$DRAW_ROOT/QA/display-scale-lib.sh"

# NAME -> "dispW dispH renderScale*100" of the Animation panel
dr_animp() { awk '/^ANIMP /{print $6" "$7" "$8; exit}' "$DS_T/$1.raw"; }
# NAME PANEL -> "w h" of a floating panel's window (WIN name - w h slot)
dr_float() { awk -v p="$2" '$1=="WIN" && $2==p && $3=="-" {print $4" "$5; exit}' "$DS_T/$1"; }

ds_check_live() {
    local n a p
    for n in A B C; do
        read -r _ _ a <<< "$(dr_animp $n)"
        [[ "$a" == 100 ]] && pass "$n: the Animation panel draws at the display scale (renderScale ${a}%)" \
            || fail "$n: the Animation panel draws at ${a:-?}% of the display scale (wanted 100: the menus' and Layers' pixel size)"
    done
    [[ "$(dr_animp A)" == "$(dr_animp B)" ]] && pass "the Animation panel keeps its share of the UI across the change ($(dr_animp A | cut -d' ' -f1,2) viewport px)" \
        || fail "the Animation panel: '$(dr_animp A)' at scale $S0, '$(dr_animp B)' after the change (dispW dispH renderScale)"
    for p in colormixer pen; do
        a=$(dr_float A $p)
        if [[ -z "$a" ]]; then
            fail "the $p panel is not floating: $(grep "^P $p " "$DS_T/A")"
        elif [[ "$a" == "$(dr_float B $p)" && "$a" == "$(dr_float C $p)" ]]; then
            pass "the floating $p panel keeps its share of the UI across the change ($a viewport px)"
        else
            fail "the floating $p panel: '$a' at scale $S0, '$(dr_float B $p)' after the change, '$(dr_float C $p)' back"
        fi
    done
}

ds_run animation layers colormixer pen
