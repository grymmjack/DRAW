#!/bin/bash
# =============================================================================
# drive-lib.sh - drives DRAW (offscreen, the QA harness) to BUILD the animated
# example scenes the way a user would: open the scene's base sheet with its
# AnimBrush pack in the Drawer, put each element on its own layer, stamp
# AnimBrushes in every frame, and run Move Brush with values typed into the
# Animation panel's Move rows (position, MOVE Z, TURN X/Y/Z, SIZE, OPACITY,
# TINT, FROM / FRAMES, ease, cel every N), each read back from the QA dump
# before Enter and the stamps checked after. Then the soundtrack is dropped on
# (the QA stand-in for an OS drop), the .draw saved and a GIF exported.
#
# Sourced by the runner (DEV/animscenes/run-scene.sh, copied into QA/tests for
# the run) after QA/dock-lib.sh; the scene's own script (scenes/NAME.sh) then
# calls these. Env: ANS_DIR (the scene's build folder), ANS_NAME, FW / FH.
# =============================================================================

ln_() { grep -m1 "^$1 " "$DK_DUMP" 2>/dev/null; }
rd() {
    dk_settle
    read -r _ _ A_COUNT A_CUR _ <<< "$(ln_ ANIM)"
    read -r _ AB_N AB_CUR AB_W AB_H _ _ AB_ON _ <<< "$(ln_ ABR)"
    read -r _ ST_STEP ST_ORD ST_ANCHOR _ <<< "$(ln_ ABRS)"
    read -r _ _ _ _ V_TOOL _ <<< "$(ln_ VIEW)"
    read -r _ LF_REF LF_SAME _ <<< "$(ln_ ANIMLF)"
    read -r _ M_ON M_DRAG M_HAS M_FROM M_EASE M_EVERY M_X0 M_Y0 M_X1 M_Y1 M_N M_HIST _ <<< "$(ln_ MVB)"
    read -r _ V_PATH V_COUNT V_Z V_TX V_TY V_TZ V_S0 V_S1 V_O0 V_O1 V_T0 V_T1 V_PLAY V_NPTS V_DUR V_PLAIN V_FG _ <<< "$(ln_ MVBV)"
    read -r _ P_VIS P_DOCK P_X P_Y P_W P_H P_SC _ <<< "$(ln_ ANIMP)"
    read -r _ PM_ON PM_Y1 PM_Y2 PM_Y3 PM_Y4 PM_Y5 PM_Y6 PM_Y7 PM_Y8 PM_Y9 PM_Y10 PM_S1 PM_S2 PM_S3 PM_VW _ <<< "$(ln_ ANIMPM)"
    read -r _ _ _ _ _ _ _ _ _ L_RH _ _ _ L_PAD L_PW _ <<< "$(ln_ ANIMPL)"
    local p k; p=($(ln_ ANIMLBP)); PX=""
    for (( k = 3; k + 4 < ${#p[@]}; k += 5 )); do
        [[ "${p[$k]}" == "$A_CUR" ]] && { PX=${p[$((k + 1))]}; PY=${p[$((k + 2))]}; PW=${p[$((k + 3))]}; PH=${p[$((k + 4))]}; }
    done
}
sx() { echo $(( PX + (2 * $1 + 1) * PW / (2 * FW) )); }   # cell px -> screen
sy() { echo $(( PY + (2 * $1 + 1) * PH / (2 * FH) )); }
k_() { park_mouse; key "$1"; wait_for 0.5 "$1"; }
hclick() { mouse_down "$1" "$2"; sleep 0.15; mouse_up; }
pal_open() { grep -q '^POPUP cmdpalette' "$DK_DUMP" 2>/dev/null; }
mvs() { echo "MVB on $M_ON has $M_HAS from $M_FROM ease $M_EASE every $M_EVERY ($M_X0,$M_Y0)-($M_X1,$M_Y1) n $M_N | path $V_PATH count $V_COUNT z $V_Z turn $V_TX/$V_TY/$V_TZ size $V_S0>$V_S1 op $V_O0>$V_O1 tint $V_T0>$V_T1 pts $V_NPTS fg $V_FG"; }

# run a command from the palette; never types unless the palette is open
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
pick() { # BIN CELS NAME - pick a Drawer bin (an AnimBrush of CELS cels)
    local t
    for t in 1 2 3; do
        rd; bin_xy "$1" || { fail "bin $1 ($3) is not showing"; return 1; }
        hover "$BX" "$BY"; wait_for 0.3 "over bin $1"
        hclick "$BX" "$BY"; wait_for 0.6 "pick bin $1"; rd
        [[ "$AB_N" == "$2" ]] && { info "bin $1: $3 ($AB_N cels ${AB_W}x$AB_H)"; return 0; }
        info "  bin $1 at $BX,$BY: brush has $AB_N cels - $(ln_ DRAWERL)"
    done
    screenshot "ans-pick-$1"
    fail "bin $1 ($3): the brush has ${AB_N:-?} cels, wanted $2"; return 1
}
nlayers() { grep -c '^LAYER ' "$DK_DUMP" 2>/dev/null; }
layer() { # [NAME] - a new layer (and its name, F2-free: Layer > Rename via the palette is not scripted)
    local n0 t; dk_settle; n0=$(nlayers)
    for t in 1 2 3; do
        k_ ctrl+shift+n; dk_settle
        (( $(nlayers) > n0 )) && { info "layer $(( n0 + 1 )) ${1:-}"; return 0; }
        info "  Ctrl+Shift+N not seen (layers $n0) - again"
    done
    fail "no new layer"
}
phase() { # Alt+] N times (the cel each frame gets moves on by N)
    local i t a0
    for (( i = 0; i < $1; i++ )); do
        rd; a0=$ST_ANCHOR
        for t in 1 2 3; do
            k_ alt+bracketright; rd
            [[ "$ST_ANCHOR" != "$a0" ]] && break
        done
    done
}
stamp() { # CX CY [PHASE] - the picked AnimBrush in every frame at once (step 2)
    local p0 p1 t
    [[ -n "${3:-}" && "$3" != 0 ]] && phase "$3"
    for t in 1 2 3; do
        p0=$(ln_ ANIMC)
        hover "$(sx "$1")" "$(sy "$2")"; wait_for 0.25 "over the spot"
        hclick "$(sx "$1")" "$(sy "$2")"; wait_for 0.6 "stamp"
        rd; p1=$(ln_ ANIMC)
        [[ "$p1" != "$p0" ]] && break
        info "  stamp at $1,$2 not seen - again"
    done
    [[ "$p1" != "$p0" ]] && info "  stamp $1,$2 phase ${3:-0}" || fail "stamp at $1,$2 never landed"
}
stepset() { # "COMMAND" WANT-STEP (0 one frame, 1 next frame, 2 every frame at once)
    local t; for t in 1 2 3; do cmd "$1"; rd; [[ "$ST_STEP" == "$2" ]] && return 0; done
    fail "$1: step $ST_STEP, wanted $2"
}
orderset() { local t; for t in 1 2 3; do cmd "$1"; rd; [[ "$ST_ORD" == "$2" ]] && return 0; done; fail "$1: order $ST_ORD, wanted $2"; }

# ---------------------------------------------------------- the FG colour ---
fg_white() { local t; for t in 1 2; do cmd "default colors"; rd; [[ "${V_FG,,}" == ffffff ]] && return 0; done; fail "FG is $V_FG, not white"; }
fg_key() { fg_pick $1; }   # "X Y HEX" from keys.sh (unquoted on purpose: three words)
fg_pick() { # CX CY HEX - the picker (I) on frame 1's pixel, read back
    local t
    for t in 1 2 3; do
        k_ i; rd
        hover "$(sx "$1")" "$(sy "$2")"; wait_for 0.3 "over"
        hclick "$(sx "$1")" "$(sy "$2")"; wait_for 0.5 "picked"; rd
        # back to the brush (B): left on the picker, the next stamp would pick a colour instead
        [[ "${V_FG,,}" == "${3,,}" ]] && { info "FG = $V_FG (picked at $1,$2)"; k_ b; return 0; }
        info "  picked $V_FG at $1,$2, wanted $3 - again"
    done
    fail "FG $V_FG, wanted $3"
}

# ------------------------------------------------- the Move rows (panel) ----
box_xy() { # ROW SLOT -> "x y" of the number box
    local y="PM_Y$1" s="PM_S$2"
    echo "$(( P_X + (${!s} + PM_VW / 2) * P_SC / 100 )) $(( P_Y + (${!y} + L_RH / 2) * P_SC / 100 ))"
}
chip_xy() { # ROW K N
    local y="PM_Y$1" w x
    w=$(( (L_PW - 2 * L_PAD - 2 * ($3 - 1)) / $3 )); x=$(( L_PAD + $2 * (w + 2) + w / 2 ))
    echo "$(( P_X + x * P_SC / 100 )) $(( P_Y + (${!y} + L_RH / 2) * P_SC / 100 ))"
}
tap() { local x y; rd; read -r x y <<< "$(chip_xy "$@")"; hclick "$x" "$y"; wait_for 0.5 "chip"; }
box_type() { # ROW SLOT TEXT
    local x y; rd; read -r x y <<< "$(box_xy "$1" "$2")"
    hclick "$x" "$y"; wait_for 0.8 "input box"
    type_text "$3"; wait_for 0.3 "typed"; key Return; wait_for 0.7 "typed $3"
}
boxset() { # ROW SLOT VALUE VAR - type, read back, again if it did not take
    local t
    for t in 1 2 3; do
        box_type "$1" "$2" "$3"; rd
        [[ "${!4}" == "$3" ]] && return 0
        info "  box $1/$2 is '${!4}', not $3 - again"
    done
    fail "box $1/$2 ($4) = ${!4}, wanted $3"
}
mv_start() {
    local t
    for t in 1 2 3; do
        cmd "move brush: start"; rd
        [[ "$M_ON" == -1 && "$PM_ON" == -1 ]] && return 0
        info "  Move Brush did not start (MVB on '$M_ON', move rows '$PM_ON') - again"
        [[ "$M_ON" == -1 ]] && { k_ Escape; rd; }
    done
    fail "Move Brush would not start"; return 1
}
drag_pts() { # "x,y x,y ..." cell px - one held drag through every point
    local first=1 p x y
    for p in $1; do
        x=${p%,*}; y=${p#*,}
        if (( first )); then hover "$(sx "$x")" "$(sy "$y")"; wait_for 0.2 "start"; mouse_down "$(sx "$x")" "$(sy "$y")"; sleep 0.15; first=0
        else hover "$(sx "$x")" "$(sy "$y")"; sleep 0.07; fi
    done
    sleep 0.15; mouse_up; wait_for 0.6 "path"
}

# mv X0 Y0 X1 Y1 [key=value ...] - one Move Brush run with the picked brush.
#   path=line|drawn  pts="x,y x,y ..." (drawn: the stroke; X0..Y1 unused)
#   from=F count=N (0 = to the last) every=N ease=0..3 (none in out both)
#   z tx ty tz s0 s1 o0 o1 t0 t1   (RESET first: anything not given is the default)
mv() {
    local x0=$1 y0=$2 x1=$3 y1=$4; shift 4
    local -A o=([path]=line [from]=1 [count]=0 [every]=1 [ease]=0 [z]=0 [tx]=0 [ty]=0 [tz]=0 [s0]=100 [s1]=100 [o0]=100 [o1]=100 [t0]=0 [t1]=0 [pts]="" [label]="")
    local kv; for kv in "$@"; do o[${kv%%=*}]=${kv#*=}; done
    local c0 c1 t ok
    rd; c0=$(ln_ ANIMC)
    mv_start || return 1
    tap 10 1 4; rd   # RESET
    [[ "$V_PLAIN" == -1 ]] || { tap 10 1 4; rd; }
    if [[ "${o[path]}" == drawn ]]; then tap 1 1 3; else tap 1 0 3; fi; rd
    [[ "$V_PATH" == "$([[ ${o[path]} == drawn ]] && echo 1 || echo 0)" ]] || { info "  path chip again"; [[ "${o[path]}" == drawn ]] && tap 1 1 3 || tap 1 0 3; rd; }
    tap 9 "${o[ease]}" 4; rd
    [[ "$M_EASE" == "${o[ease]}" ]] || { tap 9 "${o[ease]}" 4; rd; }
    # the path: a held drag in frame 1's pane
    if [[ "${o[path]}" == drawn ]]; then
        drag_pts "${o[pts]}"
    else
        # the drag stays in the frame; an end outside it (flying off) is typed after
        local i P="$x0,$y0" cx1=$x1 cy1=$y1
        (( cx1 < 0 )) && cx1=0; (( cx1 > FW - 1 )) && cx1=$(( FW - 1 ))
        (( cy1 < 0 )) && cy1=0; (( cy1 > FH - 1 )) && cy1=$(( FH - 1 ))
        for (( i = 1; i <= 6; i++ )); do P+=" $(( x0 + (cx1 - x0) * i / 6 )),$(( y0 + (cy1 - y0) * i / 6 ))"; done
        drag_pts "$P"
    fi
    rd
    [[ "$M_HAS" == -1 ]] || { fail "${o[label]}: no path after the drag ($(mvs))"; k_ Escape; return 1; }
    if [[ "${o[path]}" == line ]]; then  # exact: the typed move
        for t in 1 2 3; do
            (( M_X1 - M_X0 == x1 - x0 )) || { box_type 3 1 $(( x1 - x0 )); rd; }
            (( M_Y1 - M_Y0 == y1 - y0 )) || { box_type 3 2 $(( y1 - y0 )); rd; }
            (( M_X1 - M_X0 == x1 - x0 && M_Y1 - M_Y0 == y1 - y0 )) && break
        done
        (( M_X1 - M_X0 == x1 - x0 && M_Y1 - M_Y0 == y1 - y0 )) || fail "${o[label]}: move $((M_X1 - M_X0)),$((M_Y1 - M_Y0)), wanted $((x1 - x0)),$((y1 - y0))"
    fi
    boxset 2 2 "${o[from]}" M_FROM
    [[ "$V_COUNT" == "${o[count]}" ]] || boxset 2 3 "${o[count]}" V_COUNT
    [[ "$M_EVERY" == "${o[every]}" ]] || boxset 8 3 "${o[every]}" M_EVERY
    [[ "${o[z]}" == 0 ]] || boxset 3 3 "${o[z]}" V_Z
    [[ "${o[tx]}" == 0 ]] || boxset 4 1 "${o[tx]}" V_TX
    [[ "${o[ty]}" == 0 ]] || boxset 4 2 "${o[ty]}" V_TY
    [[ "${o[tz]}" == 0 ]] || boxset 4 3 "${o[tz]}" V_TZ
    [[ "${o[s0]}" == 100 ]] || boxset 5 2 "${o[s0]}" V_S0
    [[ "${o[s1]}" == 100 ]] || boxset 5 3 "${o[s1]}" V_S1
    [[ "${o[o0]}" == 100 ]] || boxset 6 2 "${o[o0]}" V_O0
    [[ "${o[o1]}" == 100 ]] || boxset 6 3 "${o[o1]}" V_O1
    [[ "${o[t0]}" == 0 ]] || boxset 7 2 "${o[t0]}" V_T0
    [[ "${o[t1]}" == 0 ]] || boxset 7 3 "${o[t1]}" V_T1
    rd
    local want="${o[from]} ${o[ease]} ${o[every]} ${o[count]} ${o[z]} ${o[tx]} ${o[ty]} ${o[tz]} ${o[s0]} ${o[s1]} ${o[o0]} ${o[o1]} ${o[t0]} ${o[t1]}"
    local got="$M_FROM $M_EASE $M_EVERY $V_COUNT $V_Z $V_TX $V_TY $V_TZ $V_S0 $V_S1 $V_O0 $V_O1 $V_T0 $V_T1"
    [[ "$got" == "$want" ]] || fail "${o[label]}: values [$got], wanted [$want]"
    info "  ${o[label]}: $(mvs)"
    MV_LOG+="${o[label]}|${o[path]}|$M_X0,$M_Y0>$M_X1,$M_Y1|from ${o[from]} count ${o[count]} every ${o[every]} ease ${o[ease]}|z ${o[z]} turn ${o[tx]}/${o[ty]}/${o[tz]} size ${o[s0]}>${o[s1]} op ${o[o0]}>${o[o1]} tint ${o[t0]}>${o[t1]} fg $V_FG"$'\n'
    if [[ "${MV_APPLY:-}" == clip ]]; then   # Move Brush > Apply as Clip: a clip layer, the move in its lanes
        local nc0; nc0=$(grep -c '^CLIP [0-9]' "$DK_DUMP")
        for t in 1 2; do
            cmd "move brush: apply as clip"; rd
            [[ "$M_ON" == 0 ]] && break
        done
        (( $(grep -c '^CLIP [0-9]' "$DK_DUMP") > nc0 )) && pass "${o[label]}: applied as a clip" || fail "${o[label]}: Apply as Clip made no clip"
        MV_LOG+="  (applied as a clip)"$'\n'
        return 0
    fi
    for t in 1 2; do
        k_ Return; rd
        [[ "$M_ON" == 0 ]] && break
    done
    c1=$(ln_ ANIMC)
    [[ "$M_ON" == 0 && "$c1" != "$c0" ]] && pass "${o[label]}: stamped ($M_N frames)" || fail "${o[label]}: after Enter MVB on $M_ON, layer changed: $([[ "$c1" != "$c0" ]] && echo yes || echo no)"
}

# ------------------------------------------------------------- documents ---
save_as() { # PATH
    local i
    cmd "save project as"; wait_for 1.0 "the dialog"
    for (( i = 0; i < 60; i++ )); do key BackSpace; done
    type_text "$1"; wait_for 0.3 "typed"; key Return; wait_for 2.5 "written"
    # DRAW writes the flat PNG first, then deflates the layers into a drAw chunk (+ drAn for
    # the frames): a big sheet takes many seconds, and quitting before then leaves a flat PNG
    for (( i = 0; i < 240; i++ )); do
        [[ -s "$1" ]] && python3 "$DRAW_ROOT/DEV/animscenes/pngchunks.py" "$1" drAw drAn >/dev/null 2>&1 && break
        wait_for 0.5 "the drAw chunk"
    done
    python3 "$DRAW_ROOT/DEV/animscenes/pngchunks.py" "$1" drAw drAn >/dev/null 2>&1 \
        && pass "wrote $(basename "$1") ($(stat -c %s "$1") bytes, $(python3 "$DRAW_ROOT/DEV/animscenes/pngchunks.py" "$1"))" \
        || { fail "$1 has no drAw + drAn chunks ($(python3 "$DRAW_ROOT/DEV/animscenes/pngchunks.py" "$1" 2>&1))"; screenshot "ans-save"; }
}
sound_drop() { # FILE - a new SOUND track from the current frame (frame 1)
    local n0 n1
    read -r _ n0 _ <<< "$(ln_ ANIMSC)"
    park_mouse; echo "$1" > "$DK_DUMP.drop"; wait_for 1.5 "drop $(basename "$1")"; rd
    read -r _ n1 _ <<< "$(ln_ ANIMSC)"
    (( ${n1:-0} > ${n0:-0} )) && pass "soundtrack: $(basename "$1") on a new track ($(ln_ ANIMSND | cut -c1-80))" || fail "the drop of $(basename "$1") made no clip (clips ${n0:-?} -> ${n1:-?})"
}
open_scene() { # NAME FRAMES [shots] - open NAME-base.png with NAME-pack.dset in the Drawer, lightbox,
    # the background spread (Layer Same on Every Frame) unless "shots" (a picture per frame)
    info "--- scene $1 ---"
    draw_quit; draw_settle
    DRAW_EXTRA_ARGS="${ANS_EXTRA:+$ANS_EXTRA }--option DEFAULT_DSET_BRUSHES_FILE=$ANS_DIR/$1-pack.dset --option LAST_DIR_OPEN=$ANS_DIR $ANS_DIR/$1-base.png"
    draw_launch 15; wait_for 1.5 "loaded"; assert_no_crash
    dk_begin
    k_ KP_0; rd
    [[ "$A_COUNT" == "$2" && -n "$PX" ]] || { fail "$1: $A_COUNT frames (wanted $2), pane '${PX}'"; return 1; }
    info "lightbox pane $PX,$PY ${PW}x$PH, frame $A_CUR"
    if [[ "${3:-}" != shots ]]; then
        cmd "same on every frame"; rd
        [[ "$LF_SAME" == -1 || "$LF_SAME" == 1 ]] && pass "$1: background = Layer Same on Every Frame" || info "$1: ANIMLF same '$LF_SAME'"
    fi
    [[ -f "$ANS_DIR/keys.sh" ]] && source "$ANS_DIR/keys.sh"
    stepset "animbrush step: every frame at once" 2
    MV_LOG=""
}
finish_scene() { # NAME
    screenshot "ans-$1-done"
    printf '%s' "$MV_LOG" > "$ANS_DIR/$1-moves.txt"
    save_as "$ANS_DIR/$1.draw"
    draw_quit; draw_settle
    rm -f "$ANS_DIR/$1.gif"
    ( cd "$DRAW_ROOT" && QB64PE_NOPROMPT=y timeout 120 "$DRAW_BIN" --config "$QA_CFG" --option ANIM_SOUND_VOLUME=0 "$ANS_DIR/$1.draw" --export-anim "$ANS_DIR/$1.gif" ) > "$ANS_DIR/$1.export.log" 2>&1
    [[ -s "$ANS_DIR/$1.gif" ]] && pass "exported $1.gif ($(stat -c %s "$ANS_DIR/$1.gif") bytes)" || fail "batch export of $1.gif failed: $(tail -3 "$ANS_DIR/$1.export.log")"
}
