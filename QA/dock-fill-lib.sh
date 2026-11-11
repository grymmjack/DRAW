#!/bin/bash
# =============================================================================
# dock-fill-lib.sh — helpers for tests/dock-fill-*.sh: a docked floating-family
# panel (Animation, Pen, Color Mixer, Advanced Color Picker, 3D Color Space)
# fills its slot (Rick 2026-11-10, PLANS/FLEXPANELS.svg: "can the panels be
# responsive? like width/height grow when docked to not be a giant gap").
#
#   df_run NAME GROWS   NAME = its dock name; GROWS 1 = it has an area that
#                       takes spare height (all but the Animation panel)
#
# Steps, dk_check after each docked one:
#   1 floating: its natural size (FIT natW natH; the WIN size is the fallback
#     on a build without FIT lines)
#   2 below the layers (300 px wide, wider than the panel): fills the slot's
#     width, its own height (the layers keep the spare height)
#   3 alone in a new column on the left (no flex panel): fills the width and,
#     if GROWS, takes spare height - but stays inside its slot
#   4 floating again: back to the natural size
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"

df_win() { read -r _ _ W_X W_Y W_W W_H _ <<< "$(grep "^WIN $1 " "$DK_DUMP")"; }
df_fit() { read -r _ _ F_W F_H <<< "$(grep "^FIT $1 " "$DK_DUMP")"; }
df_near() { local d=$(( $1 - $2 )); (( d >= -1 && d <= 1 )); }

df_run() {
    local nm=$1 grows=$2 natW natH
    info "=== Dock: $nm fills its slot ==="
    dk_begin
    df_win "$nm"; df_fit "$nm"
    if [[ -z "$W_W" ]]; then fail "$nm: no WIN line - is it open?"; return; fi
    natW=${F_W:-$W_W}; natH=${F_H:-$W_H}
    [[ -n "$F_W" ]] && pass "$nm: natural size $natW x $natH (FIT)" || fail "$nm: no FIT line (natural size) in the dump"
    if df_near "$W_W" "$natW" && df_near "$W_H" "$natH"; then pass "1 floating: natural size ($W_W x $W_H)"
    else fail "1 floating: $W_W x $W_H, natural $natW x $natH"; fi
    screenshot "dock-fill-$nm-1-floating"

    dk_move_expect "$nm" below layers; dk_check "$nm below the layers"
    dk_p "$nm"; df_win "$nm"
    if (( P_W <= natW + 2 )); then
        fail "2 below the layers: the slot ($P_W px) is not wider than the panel ($natW px) - the test needs a wider layers column"
    elif df_near "$W_W" "$P_W" && (( W_X >= P_X && W_X + W_W <= P_X + P_W )); then
        pass "2 below the layers: fills the slot's width ($W_W of $P_W px; natural $natW)"
    else
        fail "2 below the layers: $W_W px wide at x $W_X in a $P_W px slot at x $P_X (natural $natW) - a gap beside it"
    fi
    df_near "$W_H" "$natH" && pass "2 below the layers: its own height ($W_H px) - the layers keep the rest" \
        || fail "2 below the layers: $W_H px tall, natural $natH (the layers are the flex panel here)"
    screenshot "dock-fill-$nm-2-below-layers"

    dk_move_expect "$nm" edge-left; dk_check "$nm alone in a column"
    dk_p "$nm"; df_win "$nm"
    df_near "$W_W" "$P_W" && pass "3 alone: fills the column's width ($W_W of $P_W px)" \
        || fail "3 alone: $W_W px wide in a $P_W px slot"
    if (( W_Y + W_H > P_Y + P_H + 1 )); then
        fail "3 alone: runs past its slot (y $W_Y h $W_H, slot y $P_Y h $P_H)"
    elif (( grows )); then
        (( W_H > natH + 2 )) && pass "3 alone: takes spare height ($W_H px, natural $natH, slot $P_H)" \
            || fail "3 alone: $W_H px tall (natural $natH) in a $P_H px slot - a gap below it"
    else
        df_near "$W_H" "$natH" && pass "3 alone: keeps its height ($W_H px - nothing in it grows)" \
            || fail "3 alone: $W_H px tall, natural $natH (nothing in it should grow)"
    fi
    screenshot "dock-fill-$nm-3-alone"

    dk_move_expect "$nm" float
    df_win "$nm"
    if df_near "$W_W" "$natW" && df_near "$W_H" "$natH"; then pass "4 floating again: natural size ($W_W x $W_H)"
    else fail "4 floating again: $W_W x $W_H, natural $natW x $natH"; fi
    screenshot "dock-fill-$nm-4-floating"
    assert_window_exists
    info "=== Dock: $nm fills its slot PASSED ==="
}
