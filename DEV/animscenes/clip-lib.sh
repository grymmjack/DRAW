#!/bin/bash
# =============================================================================
# clip-lib.sh - the second half of the scene driver: everything the example
# PROJECTS (SAMPLES/ANIMPROJECTS) use beyond drive-lib.sh - frames picked on the
# X-sheet, holds, tags, frame notes, layer names / flags / linked cells, and
# clip layers with keyframe lanes, modulators, modes, flips, sources and sounds.
# Every step goes through DRAW's own UI (palette commands, the Animation
# panel's boxes, X-sheet clicks) and is read back from the QA dump.
#
# Sourced after drive-lib.sh. Wants the X-sheet on and zoomed so every frame
# fits (XSHEET=1 XSHEET_ZOOM=10) and the Animation panel shown.
#
# Dump lines: ANIMXS / ANIMXSF (header ticks), ANIMTG (tags), ANIMNT (notes),
# ANIMP (panel; hold of the current frame), ANIMPL (frame rows), CLIPP / CLIP
# (the current clip), CLIPL / CLIPLM / CLIPLV (lanes), ANIMPLN (lane rows),
# CLIPQ (sounds), LAYER (layers).
# =============================================================================

CL_LANES=(_ X Y SX SY ROT OP TINT PVX PVY VOL PAN)   # lane ids 1..11 (TOOLS/CLIP.BI)
lane_id() { local i; for i in "${!CL_LANES[@]}"; do [[ "${CL_LANES[$i]}" == "$1" ]] && { echo "$i"; return; }; done; echo 0; }
PJ_LOG=""   # every clip / lane / tag step, written to NAME-clips.txt by pj_finish
pjlog() { PJ_LOG+="$*"$'\n'; }

# ------------------------------------------------------------ reading -------
xs_rd() {
    read -r _ XS_ON _ _ XY1 _ _ _ XRH XTW _ <<< "$(ln_ ANIMXS)"
    XF=($(ln_ ANIMXSF))
}
crd() { # rd + the X-sheet + the current clip + its lanes
    rd; xs_rd
    read -r _ CP_PLACING CP_CUR _ <<< "$(ln_ CLIPP)"
    read -r _ P_VIS _ _ _ _ _ _ P_HOLD _ <<< "$(ln_ ANIMP)"
    read -r _ L_NAV L_R1 L_R2 L_R3 L_R4 L_R5 L_R6 _ L_RH L_MX L_PX L_CW _ <<< "$(ln_ ANIMPL)"
    read -r _ LN_Y10 LN_Y11 LN_Y12 LN_LX LN_LW LN_RX LN_RW _ _ _ _ LN_EX LN_EW LN_MX LN_MW LN_PICK _ <<< "$(ln_ ANIMPLN)"
    C_LINE=""; C_SLOT=""
    read -r _ _ CUR_LAYER _ <<< "$(ln_ LPANEL)"   # CLIPP's current is the clip's index; CLIP lines go by layer
    if [[ -n "$CP_CUR" && "$CP_CUR" != 0 && -n "$CUR_LAYER" ]]; then
        C_LINE=$(grep -m1 "^CLIP $CUR_LAYER " "$DK_DUMP" | cut -d' ' -f3-)
        C_SLOT=$CUR_LAYER
        read -r C_SRC C_IN C_OUT C_START C_EVERY C_MODE C_FX C_FY C_PX C_PY _ <<< "$C_LINE"
    fi
}
lbox() { # ROWY SLOT TEXT - a number box of the lane rows (LN_Y10 value, LN_Y12 MOD boxes)
    local x y; crd
    x=$(( P_X + (PM_S$2 + PM_VW / 2) * P_SC / 100 )); y=$(( P_Y + ($1 + L_RH / 2) * P_SC / 100 ))
    hclick "$x" "$y"; wait_for 0.8 "input box"
    type_text "$3"; wait_for 0.3 "typed"; key Return; wait_for 0.7 "typed $3"
}
lane_keys() { grep "^CLIPL $C_SLOT $1 " "$DK_DUMP" | cut -d' ' -f4-; }   # n f:v:e ...
lane_mod() { grep "^CLIPLM $C_SLOT $1 " "$DK_DUMP" | cut -d' ' -f4-; }   # kind shape amount period phase seed
nclips() { grep -c '^CLIP [0-9]' "$DK_DUMP" 2>/dev/null; }

# ------------------------------------------------------------- frames -------
hx() { # FRAME -> its header's x (ANIMXSF: frame x w ...; empty when not shown)
    local k; for (( k = 1; k + 2 < ${#XF[@]}; k += 3 )); do [[ "${XF[$k]}" == "$1" ]] && { echo $(( XF[k + 1] + XF[k + 2] / 2 )); return; }; done
}
hy() { echo $(( XY1 + 1 + XRH / 2 )); }
go() { # FRAME - make it current (a click on its X-sheet header)
    local t
    for t in 1 2 3 4; do
        crd
        [[ "$A_CUR" == "$1" ]] && return 0
        [[ "$XS_ON" == -1 ]] || { k_ KP_8; crd; }
        [[ -n "$(hx "$1")" ]] || { info "  frame $1 not on the X-sheet (${#XF[@]} fields)"; k_ KP_1; continue; }
        click "$(hx "$1")" "$(hy)"; wait_for 0.35 "frame $1"
    done
    crd; [[ "$A_CUR" == "$1" ]] || fail "go $1: frame is $A_CUR"
}
sel() { # A B - frames A..B selected (B current)
    go "$1"; crd
    [[ -n "$(hx "$2")" ]] || { fail "sel $1-$2: frame $2 is not on the X-sheet"; return 1; }
    with_mods shift click "$(hx "$2")" "$(hy)"; wait_for 0.4 "frames $1-$2"; crd
}
hold() { # FRAME N - the frame shows N ticks (the panel's HOLD + stepper)
    local i t x y
    go "$1"
    for t in 1 2 3; do
        crd; (( ${P_HOLD:-1} == $2 )) && break
        if (( ${P_HOLD:-1} < $2 )); then x=$(( P_X + (L_PX + L_CW / 2) * P_SC / 100 )); else x=$(( P_X + (L_MX + L_CW / 2) * P_SC / 100 )); fi
        y=$(( P_Y + (L_R6 + L_RH / 2) * P_SC / 100 ))
        for (( i = ${P_HOLD:-1}; i != $2; i += ($2 > ${P_HOLD:-1} ? 1 : -1) )); do hclick "$x" "$y"; wait_for 0.25 "hold"; done
    done
    crd; [[ "$P_HOLD" == "$2" ]] && { info "frame $1: hold $2"; pjlog "hold|frame $1|$2 ticks"; } || fail "hold $1: $P_HOLD, wanted $2"
}
tag() { # A B NAME - Tag Frames...
    sel "$1" "$2"
    cmd "tag frames"; wait_for 0.5 "the box"
    type_text "$3"; wait_for 0.3 "typed"; key Return; wait_for 0.8 "tagged"; crd
    ln_ ANIMTG | grep -q " $3 $1 $2" && { pass "tag $3: frames $1-$2"; pjlog "tag|$3|frames $1-$2"; } || fail "tag $3 $1-$2: $(ln_ ANIMTG)"
}
note() { # FRAME TEXT - Frame Note...
    go "$1"
    cmd "frame note"; wait_for 0.5 "the box"
    type_text "$2"; wait_for 0.3 "typed"; key Return; wait_for 0.8 "noted"; crd
    ln_ ANIMNT | grep -q " $1 ${2// /_}" && { info "note on $1: $2"; pjlog "note|frame $1|$2"; } || fail "note $1 '$2': $(ln_ ANIMNT)"
}

# ------------------------------------------------------------- layers -------
lname() { # NAME - rename the current layer
    cmd "rename layer"; wait_for 0.5 "the box"
    type_text "$1"; wait_for 0.3 "typed"; key Return; wait_for 0.6 "renamed"
}
reflayer() { cmd "reference layer"; crd; pjlog "reference layer|$(ln_ ANIMLF)"; }
link() { # A B - Link Cells on the current layer over frames A..B
    sel "$1" "$2"; cmd "link cells"; crd; pjlog "link cells|frames $1-$2"
}

# --------------------------------------------------------------- clips ------
panel_on() { crd; [[ "$P_VIS" == -1 ]] || { cmd "animation panel"; crd; }; [[ "$P_VIS" == -1 ]] || fail "the Animation panel is not showing"; }
clip_place() { # CX CY FRAME LABEL - the picked AnimBrush as a clip, cel 1 at (CX, CY) in FRAME
    local n0 t
    go "$3"; n0=$(nclips)
    for t in 1 2 3; do
        cmd "clip layer: place animbrush"; crd
        hover "$(sx "$1")" "$(sy "$2")"; wait_for 0.25 "over"
        hclick "$(sx "$1")" "$(sy "$2")"; wait_for 0.7 "placed"; crd
        (( $(nclips) > n0 )) && break
        info "  place $4 not seen (placing $CP_PLACING) - again"; [[ "$CP_PLACING" == 0 ]] || k_ Escape
    done
    (( $(nclips) > n0 )) && { info "clip $4: [$C_LINE]"; lname "$4"; crd; pjlog "clip|$4|placed in frame $3 at $1,$2|src $C_SRC"; } || fail "clip $4 was not placed"
}
cset() { # ROW SLOT VALUE VAR LABEL - a clip row box (3 IN/OUT, 4 CEL/EVERY, 5 X/Y)
    local t
    for t in 1 2 3; do
        box_type "$1" "$2" "$3"; crd
        [[ "${!4}" == "$3" ]] && { pjlog "  $5 $3"; return 0; }
    done
    fail "clip box $5 = ${!4}, wanted $3"
}
clip_in()    { cset 3 2 "$1" C_IN IN; }
clip_out()   { cset 3 3 "$1" C_OUT OUT; }
clip_cel()   { cset 4 2 "$1" C_START "START CEL"; }
clip_every() { cset 4 3 "$1" C_EVERY EVERY; }
clip_mode() { # LOOP PING ONCE HOLD REV
    local c; case $1 in LOOP) c="mode loop" ;; PING) c="mode ping-pong" ;; ONCE) c="mode once" ;; HOLD) c="mode hold" ;; REV) c="mode reverse" ;; esac
    cmd "clip layer: $c"; crd
    [[ "$C_MODE" == "$1"* || "$C_MODE" == "${1:0:3}"* ]] && pjlog "  mode $C_MODE" || fail "mode $1: [$C_LINE]"
}
clip_flip() { cmd "clip layer: flip ${1,,}"; crd; pjlog "  flip $1 [$C_FX $C_FY]"; }

# lanes: values are offsets / percents / degrees as the panel shows them; keys are frames
# from the clip's IN (LANE row value box = auto-key)
# step_cmd "CMD" STATE-FN [CLICK-FN] - one step (the panel chip CLICK-FN if given - fast -
# else / then the palette CMD), then wait (up to ~3 s) for STATE-FN's output to change: the
# dump can lag a step behind, and reading it early makes a stepper overshoot
step_cmd() {
    local before now i; crd; before=$($2)
    if [[ -n "${3:-}" ]]; then
        $3
        for i in 1 2 3 4 5 6; do crd; now=$($2); [[ "$now" != "$before" ]] && return 0; sleep 0.25; done
        info "  click step for '$1' changed nothing - the palette"
    fi
    cmd "$1"
    for i in 1 2 3 4 5 6 7 8 9 10; do crd; now=$($2); [[ "$now" != "$before" ]] && return 0; sleep 0.3; done
    info "  '$1' changed nothing visible ($before)"
}
# pclick ROWY X W - click a chip of the panel's lane rows (panel units, as ANIMPLN gives them)
pclick() { local x y; x=$(( P_X + ($2 + $3 / 2) * P_SC / 100 )); y=$(( P_Y + ($1 + L_RH / 2) * P_SC / 100 )); hover "$x" "$y"; sleep 0.15; hclick "$x" "$y"; sleep 0.35; }
ck_lane_next() { pclick "$LN_Y10" "$LN_RX" "$LN_RW"; }
ck_lane_prev() { pclick "$LN_Y10" "$LN_LX" "$LN_LW"; }
ck_ease()      { pclick "$LN_Y11" "$LN_EX" "$LN_EW"; }
ck_mod()       { pclick "$LN_Y12" "$LN_MX" "$LN_MW"; }
st_pick() { echo "$LN_PICK"; }
st_mod()  { lane_mod "$LN_PICK"; }
st_keys() { lane_keys "$LN_PICK"; }
lane() { # NAME (X Y SX SY ROT OP TINT PVX PVY VOL PAN)
    local want t; want=$(lane_id "$1")
    for (( t = 0; t < 13; t++ )); do
        crd; [[ "$LN_PICK" == "$want" ]] && return 0
        if (( (want - LN_PICK + 11) % 11 <= 5 )); then step_cmd "next lane (the panel's lane" st_pick ck_lane_next; else step_cmd "previous lane (the panel's lane" st_pick ck_lane_prev; fi
    done
    fail "lane $1: picked $LN_PICK"
}
lkey() { # FRAME VALUE [EASE] - a key on the picked lane (EASE 0 linear 1 in 2 out 3 in-out 4 hold)
    local L f t; L=$LN_PICK
    go "$1"; crd; f=$(( $1 - C_IN ))
    for t in 1 2 3; do
        lbox "$LN_Y10" 3 "$2"; crd
        [[ " $(lane_keys "$L") " == *" $f:$2:"* || " $(lane_keys "$L") " == *" $f:$2.00:"* ]] && break
        info "  key $1=$2 not seen [$(lane_keys "$L")]"
    done
    [[ " $(lane_keys "$L") " == *" $f:$2"* ]] || { fail "key ${CL_LANES[$L]} frame $1 = $2: [$(lane_keys "$L")]"; return 1; }
    [[ -n "${3:-}" && "$3" != 0 ]] && ease "$3"
    pjlog "  key ${CL_LANES[$L]} frame $1 (IN+$f) = $2 ease ${3:-0}"
}
keys() { # FRAME:VALUE[:EASE] ... on the picked lane
    local k a; for k in "$@"; do IFS=: read -r -a a <<< "$k"; lkey "${a[0]}" "${a[1]}" "${a[2]:-0}"; done
}
ease() { # E - the current frame's key on the picked lane gets ease E
    local L f t e; L=$LN_PICK; f=$(( A_CUR - C_IN ))
    for t in 1 2 3 4 5 6; do
        e=$(lane_keys "$L" | tr ' ' '\n' | grep "^$f:" | cut -d: -f3)
        [[ "$e" == "$1" ]] && return 0
        step_cmd "clip layer: next key ease" st_keys ck_ease
    done
    fail "ease $1 on frame $A_CUR: [$(lane_keys "$L")]"
}
mod() { # SHAPE AMOUNT PERIOD [PHASE|SEED] - SINE TRI SQUARE SAW NOISE (OFF)
    local L want t m s mk ms; L=$LN_PICK
    case $1 in OFF) want=0 ;; SINE) want=1 ;; TRI) want=2 ;; SQUARE) want=3 ;; SAW) want=4 ;; NOISE) want=5 ;; esac
    for t in 1 2 3 4 5 6 7 8 9; do
        m=$(lane_mod "$L"); s=0
        if [[ -n "$m" ]]; then read -r mk ms _ <<< "$m"; case $mk in 1) s=$(( ms + 1 )) ;; 2) s=5 ;; esac; fi
        (( s == want )) && break
        step_cmd "clip layer: next lane modulator" st_mod ck_mod
    done
    (( s == want )) || { fail "mod $1 on ${CL_LANES[$L]}: [$(lane_mod "$L")]"; return 1; }
    [[ "$1" == OFF ]] && return 0
    modbox 1 "$2" 3; modbox 2 "$3" 4
    [[ -n "${4:-}" ]] && modbox 3 "$4" $([[ "$1" == NOISE ]] && echo 6 || echo 5)
    pjlog "  mod ${CL_LANES[$L]} $1 amount $2 period $3 ${4:+$([[ $1 == NOISE ]] && echo seed || echo phase) $4} [$(lane_mod "$L")]"
}
modbox() { # SLOT VALUE FIELD - a MOD row box, read back from CLIPLM field FIELD
    local t v L=$LN_PICK
    for t in 1 2 3; do
        lbox "$LN_Y12" "$1" "$2"; crd
        v=$(lane_mod "$L" | cut -d' ' -f"$3")
        [[ "$v" == "$2" || "$v" == "$2.00" || "${v%%.00}" == "$2" ]] && return 0
    done
    fail "mod box $1 = '$v', wanted $2 [$(lane_mod "$L")]"
}
lanes_copy()  { cmd "clip layer: copy lanes"; pjlog "  copy lanes"; }
lanes_paste() { cmd "clip layer: paste lanes"; crd; pjlog "  paste lanes"; }
tint_fg()     { cmd "clip layer: tint toward the foreground"; pjlog "  tint toward FG $V_FG"; }
# sounds: a WAV in ANS_DIR (the file dialog opens there: LAST_DIR_OPEN)
clip_sound() { # cel|start|loop FILE - checks the new cue's kind (0 cel 1 start 2 loop) and redoes a wrong one
    local c want n0 n1 k t
    case $1 in cel) c="sound on this cel"; want=0 ;; start) c="sound when the clip starts"; want=1 ;; loop) c="sound each time the clip starts"; want=2 ;; esac
    for t in 1 2 3; do
        n0=$(grep -c '^CLIPQ ' "$DK_DUMP")
        cmd "clip layer: $c"; wait_for 0.8 "the file dialog"
        type_text "$2"; wait_for 0.4 "typed"; key Return; wait_for 1.0 "picked"; crd
        n1=$(grep -c '^CLIPQ ' "$DK_DUMP")
        (( n1 > n0 )) || { info "  clip sound $1 $2: CLIPQ $n0 -> $n1"; continue; }
        k=$(grep '^CLIPQ ' "$DK_DUMP" | tail -1 | cut -d' ' -f3)
        [[ "$k" == "$want" ]] && { pass "clip sound ($1) $2"; pjlog "  sound ($1) $2"; return 0; }
        info "  clip sound $1 $2 came out as kind $k - removed, again"
        cmd "clip layer: remove this clip sound"; crd
    done
    fail "clip sound $1 $2: [$(grep '^CLIPQ ' "$DK_DUMP" | tail -1)]"
}
clip_update_ab() { cmd "clip layer: update clip from animbrush"; crd; pjlog "  update clip from AnimBrush (src $C_SRC)"; }
clip_make() { # A B X0 Y0 X1 Y1 LABEL - Make Clip from Selected Frames: frames A..B, the box
    local n0; n0=$(nclips)
    sel "$1" "$2"; k_ m
    hover "$(sx "$3")" "$(sy "$4")"; mouse_down "$(sx "$3")" "$(sy "$4")"; sleep 0.15
    hover "$(sx $(( ($3 + $5) / 2 )))" "$(sy $(( ($4 + $6) / 2 )))"; sleep 0.1
    hover "$(sx "$5")" "$(sy "$6")"; sleep 0.2; mouse_up; wait_for 0.6 "marquee"
    cmd "clip layer: make clip from selected frames"; wait_for 0.8 "made"; crd
    k_ ctrl+d
    (( $(nclips) > n0 )) && { lname "$7"; crd; pjlog "clip|$7|made from frames $1-$2 box $3,$4-$5,$6|src $C_SRC [$C_LINE]"; } || fail "make clip $7: no new clip"
}
# nudge FRAME DX DY - Ctrl+arrows in the lightbox: the clip moves; with X / Y keys it keys FRAME
nudge() {
    local i k0 k1; go "$1"; crd; k0="$(lane_keys 1) | $(lane_keys 2)"
    for (( i = 0; i < ${2#-}; i++ )); do k_ "ctrl+$( (( $2 < 0 )) && echo Left || echo Right)"; sleep 0.12; done
    for (( i = 0; i < ${3#-}; i++ )); do k_ "ctrl+$( (( $3 < 0 )) && echo Up || echo Down)"; sleep 0.12; done
    wait_for 0.4 "nudged"; crd; k1="$(lane_keys 1) | $(lane_keys 2)"
    [[ "$k1" != "$k0" ]] && pass "nudge frame $1 by $2,$3: X | Y keys [$k1]" || fail "nudge frame $1: the keys did not change [$k1]"
    pjlog "  nudged on frame $1 by $2,$3 (Ctrl+arrows): X | Y keys $k1"
}
# clip_bake - Bake Clip to Pixels: the current clip layer becomes a pixel layer
clip_bake() {
    local n0; n0=$(nclips); cmd "clip layer: bake clip to pixels"; wait_for 1.0 "baked"; crd
    (( $(nclips) < n0 )) && pass "baked to pixels (clips $n0 -> $(nclips))" || fail "bake: still $(nclips) clips"
    pjlog "  BAKED to pixels"
}
# clip_src SRC - Next Clip Source until the current clip uses source SRC
clip_src() { # SRC - Next / Previous Clip Source (the shorter way) until the current clip uses SRC
    local t; for t in $(seq 1 40); do
        crd; [[ "$C_SRC" == "$1" ]] && break
        if (( C_SRC > $1 )); then step_cmd "clip layer: previous clip source" st_src; else step_cmd "clip layer: next clip source" st_src; fi
    done
    crd; [[ "$C_SRC" == "$1" ]] && pass "clip source -> $1" || fail "clip source is $C_SRC, wanted $1"
    pjlog "  source switched to $1 (Next / Previous Clip Source)"
}
st_src() { echo "$C_SRC"; }
# clip_purge - Remove Unused Clip Sources
clip_purge() { cmd "clip layer: remove unused clip sources"; crd; pjlog "remove unused clip sources"; }
# share NAME - right after clip_place: the first clip of NAME keeps its new source, the
# rest switch to it (Next Clip Source); pj_finish removes the sources left unused
share() { local v="SHARE_$1"; if [[ -z "${!v:-}" ]]; then printf -v "$v" '%s' "$C_SRC"; src_name "$1"; pjlog "  source $C_SRC = '$1' (shared)"; else clip_src "${!v}"; fi; }
# src_name NAME - Rename Clip Source (the current clip's source)
src_name() {
    cmd "clip layer: rename clip source"; wait_for 0.5 "the box"
    type_text "$1"; wait_for 0.3 "typed"; key Return; wait_for 0.6 "renamed"; crd
    grep -q "^CLIPS $C_SRC .* $1\$" "$DK_DUMP" && pass "clip source $C_SRC named $1" || info "  source $C_SRC: $(grep "^CLIPS $C_SRC " "$DK_DUMP")"
}
# mv_clip X0 Y0 X1 Y1 key=value... - drive-lib's mv, then Apply as Clip instead of Enter
mv_clip() { MV_APPLY=clip mv "$@"; }

# --------------------------------------------------------------- project ----
pj_open() { # NAME FRAMES - open_scene + the X-sheet zoomed to fit + the panel
    open_scene "$@" || return 1
    k_ KP_8; crd
    [[ "$XS_ON" == -1 ]] || fail "$1: the X-sheet is not on"
    panel_on
    PJ_LOG=""
}
pj_finish() { # NAME
    clip_purge
    printf '%s' "$PJ_LOG" > "$ANS_DIR/$1-clips.txt"
    finish_scene "$1"
}
