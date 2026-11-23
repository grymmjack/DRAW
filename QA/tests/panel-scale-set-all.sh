#!/bin/bash
# =============================================================================
# panel-scale-set-all.sh — QA test: Settings > Panels > Panel Scale > SET ALL
# (GUI/SETTINGS-TABS SETTINGS_panel_scale_all).
#
# Rick 2026-11-22: "a PANEL SCALE --- SET ALL: [.5/1/1.5/2 .. 8] dropdown that sets all
# the settings at once in the panel scale to be uniform". (No .5: a panel's floor is 1x.)
#
#   1. "Panel Scale Settings" (command palette) opens Settings on PANELS with the
#      section in view; the run pins LAYER_PANEL_SCALE=3, so the panels differ: SET ALL
#      shows MIXED
#   2. SET ALL > 2: every one of the 25 panels' Scale is 2 x its Auto / the UI Scale (Rick:
#      "the toolbox and the preview and the browser and all those that are different than
#      the universal scale for auto mode should still be honored"): Layers 2, the Toolbox
#      (Auto = the display scale x the toolbar scale) more; the box shows 2
#   3. SET ALL > AUTO: all 25 at Auto (0); > 2 again
#   4. OK, Settings opened again: all 25 at 2 (the real config took them)
#
# Dump: <dump>.settings line SETPS <box x> <box y> <box w> <box h> <item h> <mixed> <sel> <25 scales> / <UI Scale> <25 Autos>
# (box in window px).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE LAYER_PANEL_SCALE=3
# =============================================================================
info "=== Settings > Panel Scale > SET ALL ==="

PA_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"

pa_cmd() {
    park_mouse; key question; wait_for 1.0 "Command palette"
    type_text "$1"; wait_for 0.4 "Filtered"; key Return; wait_for 1.5 "$1"
}
pa_settings() { # SETPS fields into PS_* (waits for the line)
    local ln="" _i
    for _i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
        hover 400 300; sleep 0.1; hover 402 301; sleep 0.1
        ln="$(tr -d '\r' < "$PA_DUMP.settings" 2>/dev/null | grep -m1 '^SETPS ')"
        [[ -n "$ln" ]] && break
        sleep 0.2
    done
    read -r _ PS_X PS_Y PS_W PS_H PS_IH PS_MIXED PS_SEL PS_REST <<< "$ln"
    PS_V=(${PS_REST%%/*})
    PS_A=(); PS_BASE=1
    [[ "$PS_REST" == */* ]] && { PS_A=(${PS_REST#*/}); PS_BASE=${PS_A[0]:-1}; PS_A=("${PS_A[@]:1}"); }
}
pa_want() { # PANEL_INDEX(0..22) VALUE: SET ALL VALUE for it = VALUE x its Auto / the UI Scale, a half step, 1 .. 8
    awk -v v="$2" -v a="${PS_A[$1]}" -v b="$PS_BASE" 'BEGIN { if (v == 0) { print 0; exit } r = int(v * a / b * 2 + 0.5) / 2; if (r < 1) r = 1; if (r > 8) r = 8; print r }'
}
pa_pick() { # ITEM_INDEX: open SET ALL, click that list row
    click $(( PS_X + PS_W / 2 )) $(( PS_Y + PS_H / 2 )); wait_for 0.6 "the list"
    click $(( PS_X + 20 )) $(( PS_Y + PS_H + 1 + $1 * PS_IH + PS_IH / 2 )); wait_for 0.6 "picked"
    pa_settings
}
pa_all() { # VALUE: is every one of the 25 what SET ALL VALUE gives it?
    local i
    (( ${#PS_V[@]} == 25 && ${#PS_A[@]} == 25 )) || return 1
    for i in "${!PS_V[@]}"; do [[ "${PS_V[$i]}" == "$(pa_want "$i" "$1")" ]] || return 1; done
}

draw_quit
draw_settle
draw_launch 15
assert_window_exists
park_mouse

# --- 1. open at Panel Scale, MIXED ---------------------------------------------------------------
rm -f "$PA_DUMP.settings"
pa_cmd "panel scale settings"
pa_settings
screenshot "panel-scale-set-all-open"
if [[ -z "$PS_X" ]]; then
    fail "Settings did not open on PANELS with SET ALL (no SETPS line: $(head -c 200 "$PA_DUMP.settings" 2>&1))"
else
    (( PS_Y > 0 && PS_Y < 700 )) && pass "Panel Scale Settings: Settings on PANELS, SET ALL in view (y $PS_Y)" || fail "SET ALL at y $PS_Y (not in view)"
    (( PS_MIXED == 1 && PS_SEL == 0 )) && [[ "${PS_V[11]}" == 3 ]] && pass "the panels differ (Layers 3): SET ALL shows MIXED" || fail "mixed '$PS_MIXED' sel '$PS_SEL' layers '${PS_V[11]}' [${PS_V[*]}]"

    # --- 2. SET ALL > 2 (list: MIXED AUTO 1 1.5 2 ..) --------------------------------------------
    pa_pick 4
    screenshot "panel-scale-set-all-2"
    pa_all 2 && (( PS_MIXED == 0 && PS_SEL == 3 )) && pass "SET ALL > 2: all 25 panels set (2 x their Auto / the UI Scale), the box shows 2" || fail "after SET ALL 2: mixed '$PS_MIXED' sel '$PS_SEL' [${PS_V[*]}] autos [${PS_A[*]}] / $PS_BASE"
    info "UI Scale $PS_BASE; Autos [${PS_A[*]}]; SET ALL 2 gave [${PS_V[*]}]"
    [[ "${PS_V[11]}" == 2 ]] && pass "Layers (Auto = the UI Scale): 2" || fail "Layers '${PS_V[11]}' (Auto ${PS_A[11]}, UI Scale $PS_BASE)"
    if [[ "${PS_A[8]}" != "$PS_BASE" ]]; then
        [[ "${PS_V[8]}" == "$(pa_want 8 2)" && "${PS_V[8]}" != 2 ]] && pass "Toolbox keeps its proportion (Auto ${PS_A[8]} / ${PS_BASE}): ${PS_V[8]}" || fail "Toolbox '${PS_V[8]}' (Auto ${PS_A[8]} / $PS_BASE)"
    else
        info "Toolbox Auto = the UI Scale in this run: no proportion to keep"
    fi

    # --- 3. SET ALL > AUTO (no MIXED row now: AUTO 1 1.5 ..), then 2 again ---------------------
    pa_pick 0
    pa_all 0 && (( PS_SEL == 0 && PS_MIXED == 0 )) && pass "SET ALL > AUTO: all 25 at Auto (0)" || fail "after SET ALL AUTO: mixed '$PS_MIXED' sel '$PS_SEL' [${PS_V[*]}]"
    pa_pick 3
    pa_all 2 && (( PS_SEL == 3 )) && pass "SET ALL > 2 again" || fail "after SET ALL 2 (again): sel '$PS_SEL' [${PS_V[*]}]"

    # --- 4. OK: the config took them (OK clears the run's pinned DISPLAY_SCALE - the window's
    #     scale changes - so no clicks after it: the values are read from the dump) ----------
    PS_SET="${PS_V[*]}"
    key Return; wait_for 1.5 "OK"
    screenshot "panel-scale-set-all-applied"
    rm -f "$PA_DUMP.settings"
    pa_cmd "panel scale settings"
    pa_settings
    # (the Autos move with that scale change, so compare with what was set, not pa_all)
    [[ "${PS_V[*]}" == "$PS_SET" ]] && pass "OK, Settings opened again: the 25 scales SET ALL 2 gave are kept (the config took them)" || fail "reopened: [${PS_V[*]}] (set [$PS_SET])"
    key Escape; wait_for 1.0 "close"
fi
assert_no_crash
