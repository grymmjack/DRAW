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
#   BAND side x y w h shiftY                (the Browser's top/bottom band; side 0 none, 1 top, 2 bottom)
#   COL  id side ord x y w h vis hidden      (side 1 = left, 2 = right; hidden = by the small-window rule)
#   SLOT id col ord x y w h vis collapsed act autocollapsed panel,panel
#   P    name shown live x y w h slot floating fx fy fw fh hx hy hw hh tabx tabw
#   WIN  name x y w h slot                 (a native window where it is drawn)
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
#       band-top | band-bottom       the Browser only: its band along the top / bottom
#   dk_check LABEL                 invariants after a step (see below)
#   dk_expect_tree REGEX LABEL     the TREE line matches REGEX
# =============================================================================

DK_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
DK_NATIVE=" preview colormixer advcolorpicker colorspace3d pen browser "

dk_seq()  { if [[ -f "$DK_DUMP" ]]; then awk 'NR==1 {print $2}' "$DK_DUMP"; else echo 0; fi; }
dk_tree() { sed -n 's/^TREE //p' "$DK_DUMP" 2>/dev/null; }
dk_scr()  { read -r _ SCR_W SCR_H CAN_LX CAN_RX DOCK_TOP DOCK_BOT <<< "$(grep '^SCR ' "$DK_DUMP")"; }
dk_band() { read -r _ B_SIDE B_X B_Y B_W B_H B_SHIFT <<< "$(grep '^BAND ' "$DK_DUMP")"; }

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
dk_slot() { read -r _ _ S_COL S_ORD S_X S_Y S_W S_H S_VIS S_COLL S_ACT S_AUTOC S_PANELS <<< "$(grep "^SLOT $1 " "$DK_DUMP")"; }
dk_col()  { read -r _ _ C_SIDE C_ORD C_X C_Y C_W C_H C_VIS C_HID <<< "$(grep "^COL $1 " "$DK_DUMP")"; }

dk_docked()   { dk_p "$1" && (( P_SLOT > 0 )); }
# docked AND laid out on screen (its column not hidden by the small-window rule)
dk_visible()  { dk_p "$1" || return 1; (( P_SLOT > 0 )) || return 1; dk_slot "$P_SLOT"; dk_col "$S_COL"; (( S_VIS != 0 && C_VIS != 0 && ${C_HID:-0} == 0 )); }
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
        band-top)    TX=$(( (CAN_LX + CAN_RX) / 2 )); TY=$(( DOCK_TOP + 4 )) ;;
        band-bottom) TX=$(( (CAN_LX + CAN_RX) / 2 )); TY=$(( DOCK_BOT - 4 )) ;;
        float)
            if [[ -n "${2:-}" ]]; then TX=$2; TY=${3:-$2}; else TX=$(( (CAN_LX + CAN_RX) / 2 )); TY=$(( (DOCK_TOP + DOCK_BOT) / 2 )); fi ;;
        newcol|above|below|tab|bottom)
            dk_p "$other" || return 1
            if (( P_SLOT == 0 )); then return 1; fi
            dk_slot "$P_SLOT"; dk_col "$S_COL"
            # not on screen (a hidden column, a collapsed / inactive slot): its rect is stale
            if (( S_VIS == 0 || C_VIS == 0 || ${C_HID:-0} != 0 )); then return 1; fi
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
    # 5: native windows where they are drawn never cover a docked panel other
    #    than their own slot (Rick: the layer text went under a docked Preview)
    local wl wn wx wy ww wh ws r
    while read -r wl; do
        read -r _ wn wx wy ww wh ws <<< "$wl"
        for r in "${rects[@]}"; do
            local b=($r) ox oy
            [[ "${b[0]}" == "$wn" ]] && continue
            ox=$(( (wx + ww < b[1] + b[3] ? wx + ww : b[1] + b[3]) - (wx > b[1] ? wx : b[1]) ))
            oy=$(( (wy + wh < b[2] + b[4] ? wy + wh : b[2] + b[4]) - (wy > b[2] ? wy : b[2]) ))
            if (( ox > 1 && oy > 1 )); then bad+=" window $wn covers ${b[0]} (${ox}x$oy);"; fi
        done
        # its title bar stays reachable (a window taller than the work area
        # was once placed at y -94 when a dock column grew)
        if (( wy < 0 || wx + ww < 16 || wx > SCR_W - 16 )); then bad+=" window $wn title off screen ($wx,$wy ${ww}x$wh);"; fi
        # a docked window stays inside its own slot
        if (( ws > 0 )); then
            for r in "${rects[@]}"; do
                local o=($r)
                [[ "${o[0]}" != "$wn" ]] && continue
                if (( wx < o[1] - 1 || wy < o[2] - 1 || wx + ww > o[1] + o[3] + 1 || wy + wh > o[2] + o[4] + 1 )); then
                    bad+=" window $wn ($wx,$wy ${ww}x$wh) outside its slot (${o[1]},${o[2]} ${o[3]}x${o[4]});"
                fi
            done
        fi
    done < <(grep '^WIN ' "$DK_DUMP")
    # 6: every shown slot is at least its panel's declared minimum (dump SMIN:
    #    strip + DOCK_panel_box min) - unless its column has no room for all of
    #    them (a tiny window). Rick: a divider dragged the layers down to 24px,
    #    their buttons and their own divider went under the status bar.
    local mins
    mins=$(awk '
        $1=="COL"  { colh[$2]=$8 }
        $1=="SLOT" { col[$2]=$3; h[$2]=$8; vis[$2]=$9; coll[$2]=$10; autoc[$2]=$12; who[$2]=$13 }
        $1=="SMIN" { m[$2]=$3 }
        END {
            for (s in m) if (vis[s] != 0 && coll[s] == 0 && autoc[s] == 0) need[col[s]] += m[s]
            for (s in m) if (vis[s] != 0 && coll[s] == 0 && autoc[s] == 0 && h[s] < m[s] && need[col[s]] <= colh[col[s]])
                printf " slot %s (%s) %dpx < its minimum %dpx;", s, who[s], h[s], m[s]
        }' "$DK_DUMP")
    bad+="$mins"
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
        # the Browser's band
        dk_band
        local sb; sb=$(grep -m1 '^DOCK_BAND=' "$QA_CFG" | tr -d '\r' | cut -d= -f2 | cut -d, -f1)
        if (( B_SIDE == 1 )) && [[ "$sb" != TOP ]]; then bad+=" band top not saved ($sb);"; fi
        if (( B_SIDE == 2 )) && [[ "$sb" != BOTTOM ]]; then bad+=" band bottom not saved ($sb);"; fi
        if (( B_SIDE == 0 )) && [[ -n "$sb" ]]; then bad+=" a band saved ($sb) but none on screen;"; fi
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

# dk_move_expect NAME KIND [OTHER] — dk_move, then the outcome that KIND means:
#   edge-left/right  docked on that side     newcol OTHER  docked on OTHER's side
#   above/below      stacked over/under OTHER tab OTHER    tabs of one slot
#   bottom OTHER     last in OTHER's column  float         floating
dk_move_expect() {
    local name=$1 kind=$2 other=${3:-} side
    dk_move "$name" "$kind" "${@:3}" || return 1
    case "$kind" in
        edge-left)  dk_expect_side "$name" 1 ;;
        edge-right) dk_expect_side "$name" 2 ;;
        newcol)     side=$(dk_side_of "$other"); dk_expect_side "$name" "${side:-0}" ;;
        above)      dk_expect_stacked "$name" "$other" ;;
        below)      dk_expect_stacked "$other" "$name" ;;
        tab)        dk_expect_tabs "$other" "$name" ;;
        bottom)     dk_expect_last "$name" "$other" ;;
        float)      dk_expect_floating "$name" ;;
        band-top)    dk_expect_band 1 ;;
        band-bottom) dk_expect_band 2 ;;
    esac
}

# NAME is the last slot of OTHER's column
dk_expect_last() {
    local n1=$1 n2=$2 a=0 b=0 ca cb oa maxo=0 o
    if dk_p "$n1"; then a=$P_SLOT; fi
    if dk_p "$n2"; then b=$P_SLOT; fi
    if (( a == 0 || b == 0 )); then fail "$n1 / $n2 not both docked [$(dk_tree)]"; return 0; fi
    dk_slot "$a"; ca=$S_COL; oa=$S_ORD; dk_slot "$b"; cb=$S_COL
    for o in $(awk -v c="$cb" '$1=="SLOT" && $3==c {print $4}' "$DK_DUMP"); do
        if (( o > maxo )); then maxo=$o; fi
    done
    if (( ca == cb && oa == maxo )); then pass "$n1 at the bottom of $n2's column"; else fail "$n1 not last in $n2's column [$(dk_tree)]"; fi
}

# A seeded chain of N random moves among PANELS (deterministic: the same seed
# makes the same moves, so a failure reproduces). dk_check after every move.
dk_fuzz() {
    local seed=$1 steps=$2; shift 2
    local panels=("$@") kinds=(edge-left edge-right newcol above below tab bottom float) i src kind other tries
    RANDOM=$seed
    for (( i = 1; i <= steps; i++ )); do
        tries=0
        while :; do
            src=${panels[RANDOM % ${#panels[@]}]}
            kind=${kinds[RANDOM % ${#kinds[@]}]}
            other=${panels[RANDOM % ${#panels[@]}]}
            tries=$((tries + 1))
            [[ "$other" == "$src" && "$kind" != edge-* && "$kind" != float ]] && { (( tries < 50 )) && continue; kind=edge-left; }
            # the Browser can also take its band
            if [[ "$src" == browser ]] && (( RANDOM % 4 == 0 )); then
                if (( RANDOM % 2 )); then kind=band-top; else kind=band-bottom; fi
            fi
            case "$kind" in edge-*|float|band-*) other="" ;; esac
            # targets that need OTHER docked, and a source that can be grabbed
            if [[ -n "$other" ]] && ! dk_visible "$other"; then (( tries < 50 )) && continue; kind=edge-right; other=""; fi
            if [[ "$kind" == bottom ]] && ! dk_point bottom "$other"; then (( tries < 50 )) && continue; kind=edge-left; other=""; fi
            dk_grab_point "$src" && break
            (( tries < 50 )) || break
        done
        info "fuzz $seed step $i: $src $kind $other"
        dk_move_expect "$src" "$kind" $other
        dk_check "fuzz $seed step $i ($src $kind $other)"
    done
}

# the Browser in its band on SIDE (1 top, 2 bottom): laid out, not in the tree,
# not floating, and the canvas shifted away from it
dk_expect_band() {
    dk_band; dk_p browser
    if (( B_SIDE == $1 && B_H > 0 && P_SLOT == 0 && P_FL == 0 )) && { (( $1 == 1 && B_SHIFT > 0 )) || (( $1 == 2 && B_SHIFT < 0 )); }; then
        pass "browser in its band (side $1, y $B_Y, h $B_H, canvas shift $B_SHIFT)"
    else
        fail "browser not in band $1 (band side=$B_SIDE h=$B_H shift=$B_SHIFT; slot=$P_SLOT floating=$P_FL)"
    fi
}

# dk_divider_extremes UPPER LOWER LABEL — drag the divider between two stacked
# slots (the top edge of LOWER's slot) to the top of the column, then to the
# bottom, dk_check after each: neither panel / window may spill over the other
# however small its slot gets (a docked window has a minimum size).
dk_divider_extremes() {
    local up=$1 lo=$2 label=$3 x y
    dk_scr
    dk_p "$lo" || { fail "$label: $lo not in the dump"; return 1; }
    (( P_SLOT > 0 )) || { fail "$label: $lo not docked"; return 1; }
    dk_slot "$P_SLOT"; x=$(( S_X + S_W / 2 )); y=$(( S_Y - 2 ))
    dk_drag "$x" "$y" "$x" $(( DOCK_TOP + 2 )) 6; dk_park; dk_settle
    dk_check "$label: divider to the top"
    dk_p "$lo"; dk_slot "$P_SLOT"; y=$(( S_Y - 2 ))
    dk_drag "$x" "$y" "$x" $(( DOCK_BOT - 2 )) 6; dk_park; dk_settle
    dk_check "$label: divider to the bottom"
}
