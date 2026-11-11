#!/bin/bash
# =============================================================================
# display-scale-lib.sh — a live display scale change against fresh starts
# (tests/dock-display-scale-live*.sh source it, each with its own layout in
# QA-OPTIONS).
#
# ds_run: start at the profile's scale S (2; the user profile 3); B = Display
# Scale Down (command palette) to S - 1; C = Display Scale Up back to S. A
# live change sizes the window to the desktop, so each is compared with a
# fresh start at its scale and viewport: B with D (S - 1), C with E (S) - the
# harness's geometry model is set to match for those starts, and put back
# after.
# Compared: COL / SLOT / SCR lines whole; P lines (shown, box when visible,
# slot, floating, and a floating panel's size); WIN lines (size; place too
# when docked). A test may define ds_check_live, called after C with the
# snapshots in $DS_T (NAME, and NAME.raw = the whole dump).
# =============================================================================

DS_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"

ds_settle() { { hover 300 250; wait_for 0.3 "render"; hover 305 252; wait_for 0.5 "render"; } >&2; }

# NAME -> $DS_T/NAME: the layout lines of the dump
ds_snap() {
    ds_settle
    cp "$DS_DUMP" "$DS_T/$1.raw"
    python3 - "$DS_DUMP" > "$DS_T/$1" <<'PY'
import sys
for ln in open(sys.argv[1]):
    f = ln.split()
    if not f: continue
    k = f[0]
    if k in ('COL', 'SLOT', 'SCR'):
        print(' '.join(f))
    elif k == 'P':   # P name shown rVis rx ry rw rh slot fl fx fy fw fh ...
        nm, v = f[1], f[2:]
        out = v[0:8]
        if v[1] == '0': out[2:6] = ['-'] * 4   # not visible: its last box is no layout
        if v[7] != '0': out += ['size', v[10], v[11]]   # floating: its size
        print('P', nm, ' '.join(out))
    elif k == 'WIN': # WIN name x y w h slot
        nm, x, y, w, h, s = f[1:7]
        print('WIN', nm, (x + ' ' + y) if s != '0' else '-', w, h, s)
PY
}

ds_palette() { park_mouse; key question; wait_for 1.0 "palette"; type_text "$1"; wait_for 0.5 "filtered"; key Return; wait_for 2.5 "$1"; }

# A B LABEL
ds_diff() {
    if diff -q "$DS_T/$1" "$DS_T/$2" >/dev/null; then
        pass "$3: the same ($(grep -c '^COL' "$DS_T/$1") columns, $(grep -c '^SLOT' "$DS_T/$1") slots, $(grep -c '^P' "$DS_T/$1") panels, $(grep -c '^WIN' "$DS_T/$1") windows)"
    else
        fail "$3: the layout differs ('<' fresh start, '>' after the live change)"
        diff "$DS_T/$1" "$DS_T/$2" | grep '^[<>]' | head -24 | while IFS= read -r l; do info "    $l"; done
    fi
}

ds_scale() { awk '/^SCR /{print $2" "$3; exit}' "$DS_T/$1"; }

# SCALE W H NAME: a fresh start at that scale and viewport -> $DS_T/NAME
ds_fresh() {
    draw_quit
    draw_settle
    DISPLAY_SCALE=$1; VIEWPORT_W=$2; VIEWPORT_H=$3
    DRAW_EXTRA_ARGS="--option DISPLAY_SCALE=$1 --option SCREEN_WIDTH=$2 --option SCREEN_HEIGHT=$3"
    draw_launch 15
    wait_for 2.0 "settle"
    ds_snap "$4"
    info "$4 (fresh at $1): viewport $(ds_scale "$4")"
}

# [PANEL...]: panels that must be shown at the start (P <name> -1)
ds_run() {
    local p BW BH CW CH DS_SAVE S0=$DISPLAY_SCALE
    DS_T="$(mktemp -d /tmp/draw-qa-dscale-XXXXXX)"
    draw_quit
    draw_settle
    DRAW_EXTRA_ARGS=""
    draw_launch 15
    wait_for 2.0 "settle"
    assert_no_crash
    ds_snap A
    info "A (scale $S0): viewport $(ds_scale A)"
    for p in "$@"; do
        grep -q "^P $p -1 " "$DS_T/A" || fail "the $p panel is not shown: $(grep "^P $p " "$DS_T/A")"
    done

    ds_palette "display scale down"
    ds_snap B
    info "B (live down to $(( S0 - 1 ))): viewport $(ds_scale B)"
    ds_palette "display scale up"
    ds_snap C
    info "C (live back to $S0): viewport $(ds_scale C)"
    assert_no_crash
    # a test's own checks on A / B / C ($DS_T/NAME, $DS_T/NAME.raw = the whole dump)
    declare -F ds_check_live >/dev/null && ds_check_live

    DS_SAVE=("$DISPLAY_SCALE" "$VIEWPORT_W" "$VIEWPORT_H")
    read -r BW BH <<< "$(ds_scale B)"; read -r CW CH <<< "$(ds_scale C)"
    if [[ -n "$BW" && "$BW" != "$(ds_scale A | cut -d' ' -f1)" ]]; then
        ds_fresh $(( S0 - 1 )) "$BW" "$BH" D
        ds_diff D B "scale $S0 -> $(( S0 - 1 )) at run time against a fresh start at $(( S0 - 1 ))"
        ds_fresh "$S0" "$CW" "$CH" E
        ds_diff E C "scale $(( S0 - 1 )) -> $S0 at run time against a fresh start at $S0"
    else
        fail "Display Scale Down changed nothing (viewport '$BW $BH')"
    fi
    DISPLAY_SCALE=${DS_SAVE[0]}; VIEWPORT_W=${DS_SAVE[1]}; VIEWPORT_H=${DS_SAVE[2]}
    assert_no_crash
    rm -rf "$DS_T"

    draw_quit
    draw_settle
    DRAW_EXTRA_ARGS=""
    draw_launch 15
    assert_window_exists
}
