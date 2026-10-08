#!/bin/bash
# =============================================================================
# dock-lib.sh — helpers for the docking QA tests (tests/dock-*.sh source it).
#
# DRAW writes its live dock layout to QA/.dock-dump.txt when a test passes
#   # QA-OPTIONS: ... DOCK_DUMP=QA/.dock-dump.txt
# (GUI/DOCK.BM DOCK_dump_write). Lines:
#   SEQ  n                                   (bumped on every change)
#   TREE LEFT.1: layers ; RIGHT.1: toolbox | organizer | drawer ; ...
#   SCR  w h canvasLX canvasRX dockTop dockBottom
#   COL  id side ord x y w h vis             (side 1 = left, 2 = right)
#   SLOT id col ord x y w h vis collapsed act panel,panel
#   P    name shown live x y w h slot floating fx fy fw fh hx hy hw hh tabx tabw
# Booleans are QB64's -1 / 0. Coordinates are viewport px (what click/hover use).
#
# So a test never hard-codes geometry: it asks where a panel's handle is, where
# "the top third of the layers" is, drags there, and checks the result.
#
#   dk_move NAME TARGET [ARG...]   drag NAME by its handle (or its tab) to:
#       edge-left | edge-right       a new outermost column on that edge
#       newcol OTHER                 a new column beside OTHER's, toward the canvas
#       above OTHER | below OTHER    a new slot above / below OTHER
#       tab OTHER                    a tab in OTHER's slot
#       bottom OTHER                 the empty rest of OTHER's column (stack at the end)
#       float [X Y]                  float it (default: the canvas center)
#   dk_check LABEL                 invariants after a step (see below)
#   dk_expect_tree REGEX LABEL     the TREE line matches REGEX
# =============================================================================

DK_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
DK_NATIVE=" preview colormixer advcolorpicker colorspace3d pen browser "

dk_seq()  { if [[ -f "$DK_DUMP" ]]; then awk 'NR==1 {print $2}' "$DK_DUMP"; else echo 0; fi; }
dk_tree() { sed -n 's/^TREE //p' "$DK_DUMP" 2>/dev/null; }
dk_scr()  { read -r _ SCR_W SCR_H CAN_LX CAN_RX DOCK_TOP DOCK_BOT <<< "$(grep '^SCR ' "$DK_DUMP")"; }

# wait until the layout stops changing (DRAW idles at 15 fps)
dk_settle() {
    local a b n=0
    a=$(dk_seq); sleep 0.35; b=$(dk_seq)
    while [[ "$a" != "$b" && $n -lt 10 ]]; do a=$b; sleep 0.3; b=$(dk_seq); n=$((n + 1)); done
}

# P_* for panel NAME; 1 = not in the dump
dk_p() {
    local line
    line=$(grep "^P $1 " "$DK_DUMP" 2>/dev/null) || return 1
    read -r _ _ P_SHOWN P_LIVE P_X P_Y P_W P_H P_SLOT P_FL P_FX P_FY P_FW P_FH P_HX P_HY P_HW P_HH P_TX P_TW <<< "$line"
}
dk_slot() { read -r _ _ S_COL S_ORD S_X S_Y S_W S_H S_VIS S_COLL S_ACT S_PANELS <<< "$(grep "^SLOT $1 " "$DK_DUMP")"; }
dk_col()  { read -r _ _ C_SIDE C_ORD C_X C_Y C_W C_H C_VIS <<< "$(grep "^COL $1 " "$DK_DUMP")"; }

dk_docked()   { dk_p "$1" && (( P_SLOT > 0 )); }
dk_floating() { dk_p "$1" && (( P_FL != 0 )); }
dk_side_of()  { dk_p "$1" || return 1; if (( P_SLOT == 0 )); then return 1; fi; dk_slot "$P_SLOT"; dk_col "$S_COL"; echo "$C_SIDE"; }

# where to press to move NAME: its tab, else its handle (title strip / layers
# header / 3px grip / a window's title bar) -> GX GY
dk_grab_point() {
    dk_p "$1" || return 1
    if (( P_TW > 0 )); then
        GX=$(( P_TX + P_TW / 2 )); GY=$(( P_HY + 5 ))
    elif (( P_HW > 0 && P_HH > 0 )); then
        if (( P_HW > 40 )); then GX=$(( P_HX + P_HW / 3 )); else GX=$(( P_HX + P_HW / 2 )); fi
        if (( P_HH <= 4 )); then GY=$(( P_HY + 1 )); else GY=$(( P_HY + P_HH / 2 )); fi
    else
        return 1
    fi
}

# a drop point for TARGET -> TX TY (1 = no such point)
dk_point() {
    local kind=${1:-} other=${2:-} c last y2 line sy sh
    dk_scr
    case "$kind" in
        edge-left)  TX=2; TY=$(( (DOCK_TOP + DOCK_BOT) / 2 )) ;;
        edge-right) TX=$(( SCR_W - 3 )); TY=$(( (DOCK_TOP + DOCK_BOT) / 2 )) ;;
        float)
            if [[ -n "${2:-}" ]]; then TX=$2; TY=${3:-$2}; else TX=$(( (CAN_LX + CAN_RX) / 2 )); TY=$(( (DOCK_TOP + DOCK_BOT) / 2 )); fi ;;
        newcol|above|below|tab|bottom)
            dk_p "$other" || return 1
            if (( P_SLOT == 0 )); then return 1; fi
            dk_slot "$P_SLOT"; dk_col "$S_COL"
            case "$kind" in
                newcol)
                    if (( C_SIDE == 1 )); then TX=$(( C_X + C_W - 3 )); else TX=$(( C_X + 2 )); fi
                    TY=$(( C_Y + C_H / 2 )) ;;
                above)  TX=$(( S_X + S_W / 2 )); sh=$(( S_H / 6 )); if (( sh < 1 )); then sh=1; fi; TY=$(( S_Y + sh )) ;;
                below)  TX=$(( S_X + S_W / 2 )); sh=$(( S_H / 6 )); if (( sh < 1 )); then sh=1; fi; TY=$(( S_Y + S_H - 1 - sh )) ;;
                tab)    TX=$(( S_X + S_W / 2 )); TY=$(( S_Y + S_H / 2 )) ;;
                bottom)
                    c=$S_COL; last=$C_Y
                    while read -r line; do
                        read -r _ _ _ _ _ sy _ sh _ <<< "$line"
                        if (( sy + sh > last )); then last=$(( sy + sh )); fi
                    done < <(awk -v c="$c" '$1=="SLOT" && $3==c && $9==-1' "$DK_DUMP")
                    y2=$(( C_Y + C_H ))
                    if (( y2 - last < 4 )); then return 1; fi
                    TX=$(( C_X + C_W / 2 )); TY=$(( (last + y2) / 2 )) ;;
            esac ;;
        *) return 1 ;;
    esac
}

dk_park() { dk_scr; hover $(( (CAN_LX + CAN_RX) / 2 )) $(( DOCK_BOT - 20 )); }

# slow drag (DRAW idles at 15 fps): press, travel, settle on the target, release
dk_drag() {
    local x1=$1 y1=$2 x2=$3 y2=$4 steps=${5:-7} i
    mouse_down "$x1" "$y1"; sleep 0.2
    for (( i = 1; i <= steps; i++ )); do
        hover $(( x1 + (x2 - x1) * i / steps )) $(( y1 + (y2 - y1) * i / steps )); sleep 0.1
    done
    hover "$x2" "$y2"; sleep 0.3
    mouse_up; sleep 0.5
}

# dk_move NAME TARGET [ARG...] — returns 1 (and fails) when NAME has no handle
# or the target has no drop point
dk_move() {
    local name=$1; shift
    dk_settle
    if ! dk_grab_point "$name"; then fail "dk_move: $name has no handle to grab"; return 1; fi
    if ! dk_point "$@"; then fail "dk_move: no drop point for '$*'"; return 1; fi
    info "move $name: ($GX,$GY) -> $* ($TX,$TY)"
    dk_drag "$GX" "$GY" "$TX" "$TY"
    dk_park
    dk_settle
}

dk_expect_tree() {
    local t; t=$(dk_tree)
    if [[ "$t" =~ $1 ]]; then pass "$2 [$t]"; else fail "$2: tree [$t] !~ /$1/"; fi
}

# a panel docked on SIDE (1 left, 2 right)
dk_expect_side() {
    local s; s=$(dk_side_of "$1")
    if [[ "$s" == "$2" ]]; then pass "$1 docked on side $2"; else fail "$1 not on side $2 (got '${s:-floating/hidden}') [$(dk_tree)]"; fi
}
dk_expect_floating() {
    if dk_floating "$1"; then pass "$1 floating"; else fail "$1 not floating [$(dk_tree)]"; fi
}
dk_expect_docked() {
    if dk_docked "$1"; then pass "$1 docked"; else fail "$1 not docked [$(dk_tree)]"; fi
}
# A and B tabs of one slot
dk_expect_tabs() {
    local s1=0 s2=0
    if dk_p "$1"; then s1=$P_SLOT; fi
    if dk_p "$2"; then s2=$P_SLOT; fi
    if (( s1 > 0 && s1 == s2 )); then pass "$1 + $2 are tabs of one slot"; else fail "$1 / $2 not tabbed together [$(dk_tree)]"; fi
}
# A directly above B in one column
dk_expect_stacked() {
    local a=0 b=0 ca cb oa ob
    if dk_p "$1"; then a=$P_SLOT; fi
    if dk_p "$2"; then b=$P_SLOT; fi
    if (( a == 0 || b == 0 )); then fail "$1 / $2 not both docked [$(dk_tree)]"; return 0; fi
    dk_slot "$a"; ca=$S_COL; oa=$S_ORD; dk_slot "$b"; cb=$S_COL; ob=$S_ORD
    if (( ca == cb && ob == oa + 1 )); then pass "$1 stacked above $2"; else fail "$1 not directly above $2 [$(dk_tree)]"; fi
}

# The invariants every step must keep:
#  1 each panel at most once in the tree; docked <=> in the tree; floating => not
#  2 shown docked panels lie on screen and don't overlap (1px shared frame ok)
#  3 the saved arrangement (DOCK_* in the --config file) is the one on screen
#  4 every floating docked panel is saved as DOCK_FLOAT_<name>
#  5 DRAW is alive (assert_no_crash)
dk_check() {
    local label=$1 t names n dup bad="" line nm slot fl live x y w h
    t=$(dk_tree)
    names=$(sed -E 's/(LEFT|RIGHT)\.[0-9]+://g; s/[|+;]/ /g' <<< "$t")
    dup=$(tr ' ' '\n' <<< "$names" | grep -v '^$' | sort | uniq -d | tr '\n' ' ')
    if [[ -n "$dup" ]]; then bad+=" twice in the tree: $dup;"; fi
    while read -r line; do
        read -r _ nm _ live x y w h slot fl _ <<< "$line"
        if (( slot > 0 )) && ! grep -qw "$nm" <<< "$names"; then bad+=" $nm slot $slot but not in the tree;"; fi
        if (( slot == 0 )) && grep -qw "$nm" <<< "$names"; then bad+=" $nm in the tree but not docked;"; fi
        if (( fl != 0 && slot > 0 )); then bad+=" $nm floating and docked;"; fi
    done < <(grep '^P ' "$DK_DUMP")
    # 2: live docked rects
    dk_scr
    local rects=() i j
    while read -r line; do
        read -r _ nm _ live x y w h slot fl _ <<< "$line"
        if (( live == 0 || slot == 0 || w <= 0 || h <= 0 )); then continue; fi
        if (( x < 0 || y < 0 || x + w > SCR_W || y + h > SCR_H )); then bad+=" $nm off screen ($x,$y ${w}x$h);"; fi
        rects+=("$nm $x $y $w $h")
    done < <(grep '^P ' "$DK_DUMP")
    for (( i = 0; i < ${#rects[@]}; i++ )); do
        for (( j = i + 1; j < ${#rects[@]}; j++ )); do
            local a=(${rects[i]}) b=(${rects[j]}) ox oy
            ox=$(( (a[1] + a[3] < b[1] + b[3] ? a[1] + a[3] : b[1] + b[3]) - (a[1] > b[1] ? a[1] : b[1]) ))
            oy=$(( (a[2] + a[4] < b[2] + b[4] ? a[2] + a[4] : b[2] + b[4]) - (a[2] > b[2] ? a[2] : b[2]) ))
            if (( ox > 1 && oy > 1 )); then bad+=" ${a[0]} overlaps ${b[0]} (${ox}x$oy);"; fi
        done
    done
    # 3 + 4: the saved arrangement
    if grep -q '^DOCK_CUSTOM=1' "$QA_CFG" 2>/dev/null || grep -q '^DOCK_CUSTOM=-1' "$QA_CFG" 2>/dev/null; then
        local saved
        saved=$(grep -E '^DOCK_(LEFT|RIGHT)_[0-9]+=' "$QA_CFG" | tr -d '\r' | sort -t_ -k2,2 -k3,3n | \
            sed -E 's/^DOCK_(LEFT|RIGHT)_([0-9]+)=/\1.\2: /; s/(AUTO|WIDTH:[0-9]+); //; s/@[0-9]+//g; s/[*!]//g' | paste -sd';' | sed 's/;/ ; /g')
        local live_t; live_t=$(sed -E 's/ +/ /g' <<< "$t")
        saved=$(sed -E 's/ +/ /g' <<< "$saved")
        if [[ "$saved" != "$live_t" ]]; then bad+=" saved [$saved] != on screen [$live_t];"; fi
        while read -r line; do
            read -r _ nm _ _ _ _ _ _ slot fl _ <<< "$line"
            if (( fl == 0 )); then continue; fi
            if [[ "$DK_NATIVE" == *" $nm "* ]]; then continue; fi
            if ! grep -qi "^DOCK_FLOAT_${nm}=" "$QA_CFG"; then bad+=" floating $nm not saved;"; fi
        done < <(grep '^P ' "$DK_DUMP")
    fi
    if [[ -z "$bad" ]]; then pass "$label: invariants hold [$t]"; else fail "$label:$bad"; fi
    assert_no_crash
}

# start every dock test from a fresh dump
# (DRAW rewrites the dump at its first layout, so it is fresh by now)
dk_begin() {
    wait_for 1.0 "settle"
    key Escape
    local n=0
    while [[ ! -f "$DK_DUMP" && $n -lt 20 ]]; do sleep 0.2; n=$((n + 1)); done
    if [[ ! -f "$DK_DUMP" ]]; then fail "no dock dump at $DK_DUMP (QA-OPTIONS needs DOCK_DUMP=QA/.dock-dump.txt)"; fi
    dk_park
    dk_settle
}
