#!/bin/bash
# =============================================================================
# build-scenes.sh — builds the AnimBrush example scenes IN DRAW, the way a
# user would, from the AnimBrush pack (make-pack.py). Not a test: a QA-harness
# script, so it runs offscreen (Xvfb) on the pinned QA config.
#
#   ABS_PACK=.../animbrush-pack.dset ABS_SCENES=.../scenes ABS_OUT=DIR \
#   ./QA/draw-qa.sh --rerun-passed DEV/animbrush-pack/build-scenes.sh
#
# For each scene: open NAME-base.png (24 frames of 160x120, the background in
# frame 1), Num 0 (lightbox), Layer Same on Every Frame on the background,
# then per element: a new layer, click its Drawer bin, Alt+] for its phase,
# click in the frame (AnimBrush Step: Every Frame at Once) - or Move Brush:
# Start, drag the path, Enter. Saves ABS_OUT/NAME.draw and ABS_OUT/NAME.gif.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt DRAWER_MINI_PALETTE=0 TOOLTIPS_DISABLED=TRUE ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 LIGHTBOX_PANES=3 LIGHTBOX_STRIP_FLOW=ROW
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== AnimBrush example scenes ==="

: "${ABS_PACK:?ABS_PACK = the pack .dset}"; : "${ABS_SCENES:?ABS_SCENES = the scenes dir}"; : "${ABS_OUT:?ABS_OUT = where to write}"
mkdir -p "$ABS_OUT"
FW=160; FH=120

ln_() { grep -m1 "^$1 " "$DK_DUMP" 2>/dev/null; }
rd() {
    dk_settle
    read -r _ _ A_COUNT A_CUR _ <<< "$(ln_ ANIM)"
    read -r _ AB_N AB_CUR AB_W AB_H _ _ AB_ON _ <<< "$(ln_ ABR)"
    read -r _ ST_STEP ST_ORD ST_ANCHOR _ <<< "$(ln_ ABRS)"
    read -r _ _ _ _ V_TOOL _ <<< "$(ln_ VIEW)"
    read -r _ LF_REF LF_SAME _ <<< "$(ln_ ANIMLF)"
    read -r _ M_ON M_DRAG M_PATH M_FROM M_EASE M_EVERY _ <<< "$(ln_ MVB)"
    local p k; p=($(ln_ ANIMLBP)); PX=""
    for (( k = 3; k + 4 < ${#p[@]}; k += 5 )); do
        [[ "${p[$k]}" == "$A_CUR" ]] && { PX=${p[$((k + 1))]}; PY=${p[$((k + 2))]}; PW=${p[$((k + 3))]}; PH=${p[$((k + 4))]}; }
    done
}
sx() { echo $(( PX + (2 * $1 + 1) * PW / (2 * FW) )); }   # cell px -> screen
sy() { echo $(( PY + (2 * $1 + 1) * PH / (2 * FH) )); }
k_() { park_mouse; key "$1"; wait_for 0.5 "$1"; }
# a click held for a moment: a press and release inside one slow frame is never seen
hclick() { mouse_down "$1" "$2"; sleep 0.15; mouse_up; }
pal_open() { grep -q '^POPUP cmdpalette' "$DK_DUMP" 2>/dev/null; }
# run a command from the palette; never types unless the palette is open (else the
# letters would go in as hotkeys)
cmd() {
    local t
    for t in 1 2 3 4; do
        park_mouse; key question; wait_for 1.0 "Command palette"; dk_settle
        pal_open && break
        info "  the command palette did not open (try $t)"
    done
    pal_open || { fail "the command palette would not open for '$1'"; return 1; }
    type_text "$1"; wait_for "$(awk -v n=${#1} 'BEGIN{printf "%.1f", 0.6 + n * 0.08}')" "filtered"
    key Return; wait_for 1.0 "$1"; dk_settle
    if pal_open; then key Escape; wait_for 0.5 "close"; fail "'$1': the palette was still open after Enter"; return 1; fi
}
bin_xy() {
    local DL_COLS DL_VIS DL_CX DL_CY DL_BW DL_BH DL_GX DL_GY DL_ROW0 i r c
    read -r _ DL_COLS _ DL_VIS _ _ _ DL_CX DL_CY DL_BW DL_BH DL_GX DL_GY _ <<< "$(ln_ DRAWERL)"
    read -r _ DL_ROW0 _ <<< "$(ln_ DRAWERR)"
    [[ -n "$DL_COLS" ]] || return 1
    i=$(( $1 - 1 )); r=$(( i / DL_COLS - DL_ROW0 )); c=$(( i % DL_COLS ))
    (( r >= 0 && r < DL_VIS )) || return 1
    BX=$(( DL_CX + c * (DL_BW + DL_GX) + DL_BW / 2 )); BY=$(( DL_CY + r * (DL_BH + DL_GY) + DL_BH / 2 ))
}
# pick bin N (an AnimBrush of CELS cels) - once more if the click was missed
pick() { # N CELS NAME
    local t
    for t in 1 2 3; do
        rd; bin_xy "$1" || { fail "bin $1 ($3) is not showing"; return 1; }
        hover "$BX" "$BY"; wait_for 0.3 "over bin $1"
        hclick "$BX" "$BY"; wait_for 0.6 "pick bin $1"; rd
        [[ "$AB_N" == "$2" ]] && { info "bin $1: $3 ($AB_N cels ${AB_W}x$AB_H, tool $V_TOOL, try $t)"; return 0; }
        screenshot "abs-pick-$1-try$t"
        info "  bin $1 at $BX,$BY: brush has $AB_N cels - $(ln_ DRAWERL)"
    done
    fail "bin $1 ($3): the brush has ${AB_N:-?} cels, wanted $2"; return 1
}
nlayers() { grep -c '^LAYER ' "$DK_DUMP" 2>/dev/null; }
layer() {
    local n0 t; dk_settle; n0=$(nlayers)
    for t in 1 2 3; do
        k_ ctrl+shift+n; dk_settle
        (( $(nlayers) > n0 )) && return 0
        info "  Ctrl+Shift+N not seen (layers $n0) - again"
    done
    fail "no new layer"
}
# phase: Alt+] N times (the cel each frame gets moves on by N)
phase() {
    local i t a0
    for (( i = 0; i < $1; i++ )); do
        rd; a0=$ST_ANCHOR
        for t in 1 2 3; do
            k_ alt+bracketright; rd
            [[ "$ST_ANCHOR" != "$a0" ]] && break
            info "  Alt+] not seen (anchor $a0) - again"
        done
    done
}
stamp() { # CX CY [PHASE] [same] - with the bin just picked (picking puts the phase back to 0)
    # "same": one held click, unchecked
    local a0 p0 p1 t
    if [[ "${4:-}" == same ]]; then
        hover "$(sx "$1")" "$(sy "$2")"; wait_for 0.25 "over the spot"
        hclick "$(sx "$1")" "$(sy "$2")"; wait_for 0.6 "stamp"
        info "  stamp at $1,$2 (a copy of the last)"; return 0
    fi
    [[ -n "${3:-}" && "$3" != 0 ]] && phase "$3"
    rd; a0=$ST_ANCHOR
    for t in 1 2 3; do
        p0=$(ln_ ANIMC)   # the current layer's checksum per frame
        hover "$(sx "$1")" "$(sy "$2")"; wait_for 0.25 "over the spot"
        hclick "$(sx "$1")" "$(sy "$2")"; wait_for 0.6 "stamp"
        rd; p1=$(ln_ ANIMC)
        [[ "$p1" != "$p0" ]] && break
        info "  stamp at $1,$2 not seen (the layer did not change) - again"
    done
    [[ "$p1" != "$p0" ]] || fail "stamp at $1,$2 never landed"
    info "  stamp at $1,$2 phase ${3:-0} (anchor $a0) $(ln_ ABRP | cut -c1-60)"
}
mvset() { # "COMMAND" VAR WANT
    local t
    for t in 1 2 3; do cmd "$1"; rd; [[ "${!2}" == "$3" ]] && return 0; info "  '$1' did not take ($2 = ${!2}) - again"; done
    fail "$1: $2 = ${!2}, wanted $3"
}
stepset() { # "COMMAND" WANT-ORDER
    cmd "$1"; rd; [[ "$ST_ORD" == "$2" ]] || { cmd "$1"; rd; }
    [[ "$ST_ORD" == "$2" ]] || fail "$1: order $ST_ORD, wanted $2"
}
# Move Brush along a path from (X0,Y0) to (X1,Y1), cell px
move() { # X0 Y0 X1 Y1
    local i n=6 t
    for t in 1 2 3; do
        cmd "move brush: start"; rd
        [[ "$M_ON" == -1 ]] && break
        info "  Move Brush did not start (MVB on '$M_ON') - again"
    done
    [[ "$M_ON" == -1 ]] || { fail "Move Brush would not start"; return 1; }
    mouse_down "$(sx "$1")" "$(sy "$2")"
    for (( i = 1; i <= n; i++ )); do
        hover "$(sx $(( $1 + ($3 - $1) * i / n )))" "$(sy $(( $2 + ($4 - $2) * i / n )))"; sleep 0.12
    done
    mouse_up; wait_for 0.6 "path"
    rd; info "  path: MVB on $M_ON path $M_PATH from frame $M_FROM ease $M_EASE every $M_EVERY"
    k_ Return; wait_for 0.8 "stamped"; rd
    [[ "$M_ON" == 0 ]] || { info "  Enter not seen - again"; k_ Return; wait_for 0.8 "stamped"; rd; }
    [[ "$M_ON" == 0 ]] && pass "Move Brush $1,$2 -> $3,$4 stamped" || fail "Move Brush still on after Enter"
}
save_as() { # COMMAND PATH
    cmd "$1"; wait_for 1.0 "the dialog"
    for (( i = 0; i < 40; i++ )); do key BackSpace; done
    type_text "$2"; wait_for 0.3 "typed"; key Return; wait_for 2.5 "written"
    [[ -s "$2" ]] && pass "wrote $(basename "$2") ($(stat -c %s "$2") bytes)" || { fail "no $2"; screenshot "abs-save-$(basename "$2")"; }
}

open_scene() { # NAME
    [[ -z "${ABS_ONLY:-}" || " $ABS_ONLY " == *" $1 "* ]] || return 1
    info "--- scene $1 ---"
    draw_quit; draw_settle
    DRAW_EXTRA_ARGS="--option DEFAULT_DSET_BRUSHES_FILE=$ABS_PACK $ABS_SCENES/$1-base.png"
    draw_launch 15; wait_for 1.5 "loaded"; assert_no_crash
    dk_begin
    k_ KP_0; rd
    [[ "$A_COUNT" == 24 && -n "$PX" ]] || { fail "$1: $A_COUNT frames, pane '${PX}'"; return 1; }
    info "lightbox pane $PX,$PY ${PW}x$PH, frame $A_CUR"
    # the background: drawn in frame 1, shown in every frame
    cmd "same on every frame"; rd
    [[ "$LF_SAME" == -1 || "$LF_SAME" == 1 ]] && pass "$1: background = Layer Same on Every Frame" || info "$1: ANIMLF same '$LF_SAME'"
    cmd "animbrush step: every frame at once"; rd
    [[ "$ST_STEP" == 2 ]] || { cmd "animbrush step: every frame at once"; rd; }
    [[ "$ST_STEP" == 2 ]] && pass "$1: AnimBrush Step = Every Frame at Once" || fail "$1: step $ST_STEP, wanted 2"
}
finish_scene() { # NAME
    screenshot "abs-$1-done"
    save_as "save project as" "$ABS_OUT/$1.draw"
    # the GIF: DRAW's batch export of the saved .draw (same Xvfb, same isolated dirs)
    draw_quit; draw_settle
    rm -f "$ABS_OUT/$1.gif"
    ( cd "$DRAW_ROOT" && QB64PE_NOPROMPT=y timeout 90 "$DRAW_BIN" --config "$QA_CFG" "$ABS_OUT/$1.draw" --export-anim "$ABS_OUT/$1.gif" ) > "$ABS_OUT/$1.export.log" 2>&1
    [[ -s "$ABS_OUT/$1.gif" ]] && pass "exported $1.gif ($(stat -c %s "$ABS_OUT/$1.gif") bytes)" || fail "batch export of $1.gif failed: $(tail -3 "$ABS_OUT/$1.export.log")"
}

# -------------------------------------------------------------- castle ------
if open_scene castle-night; then
    layer; pick 4 8 star
    stamp 20 14 0; stamp 58 24 3; stamp 92 9 5; stamp 150 46 2; stamp 10 50 6; stamp 102 30 1; stamp 140 8 4
    layer; pick 6 6 flag
    stamp 52 23 0; stamp 122 23 2
    layer; pick 1 6 torch
    stamp 64 77 0; stamp 96 77 3
    layer; pick 7 4 bat
    move 6 40 154 20
    layer; pick 8 4 ghost
    mvset "ease in-out" M_EASE 3; mvset "cel every 2" M_EVERY 2
    move 24 92 136 86
    mvset "ease none" M_EASE 0; mvset "cel every frame" M_EVERY 1
    finish_scene castle-night
fi

# ------------------------------------------------------------- campfire -----
if open_scene campfire-night; then
    layer; pick 3 8 smoke
    stamp 80 75 0
    layer; pick 2 6 campfire
    stamp 80 97 0
    layer; pick 9 12 owl
    stamp 114 39 0
    layer; pick 5 8 firefly
    stamp 40 70 0; stamp 60 54 3; stamp 100 64 5; stamp 120 82 1; stamp 30 86 6; stamp 148 60 2; stamp 70 40 4
    finish_scene campfire-night
fi

# ------------------------------------------------------------ waterfall -----
if open_scene waterfall-day; then
    layer; pick 10 4 waterfall
    stamp 80 34 0; stamp 80 50 0; stamp 80 66 0; stamp 80 82 0
    layer; pick 11 4 splash
    stamp 80 92 0
    layer; pick 12 8 ripple
    stamp 48 104 0; stamp 112 100 3; stamp 96 112 5; stamp 62 115 2
    layer; stepset "animbrush order: ping-pong" 2; pick 13 3 grass
    stamp 12 112 0; stamp 32 116 1; stamp 22 101 2; stamp 130 114 3; stamp 150 109 1; stamp 140 103 0
    stepset "animbrush order: forward" 0
    layer; pick 14 4 butterfly
    mvset "ease in-out" M_EASE 3
    move 14 106 66 84
    mvset "ease none" M_EASE 0
    layer; pick 15 4 bird
    mvset "cel every 2" M_EVERY 2
    move 150 14 10 24
    mvset "cel every frame" M_EVERY 1
    finish_scene waterfall-day
fi
park_mouse
