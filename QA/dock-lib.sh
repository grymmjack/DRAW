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
#   BAND side x y w h shiftY                (the Browser's row - its old band; side 0 none, 1 top, 2 bottom)
#   ROWS full y1 y2 toph both                (top / bottom rows: full width?, first y under the top rows,
#                                             last y above the bottom ones, their heights)
#   COL  id side ord x y w h vis hidden      (side 1 = left, 2 = right, 3 = a top row, 4 = a bottom row;
#                                             hidden = by the small-window rule)
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
#       band-top | band-bottom       a new innermost row along the top / bottom (any panel)
#       left OTHER | right OTHER     beside OTHER in its row (a slot before / after it)
#   dk_check LABEL                 invariants after a step (see below)
#   dk_expect_tree REGEX LABEL     the TREE line matches REGEX
# =============================================================================

DK_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
DK_NATIVE=" preview colormixer advcolorpicker colorspace3d pen browser animation swatches "

dk_seq()  { if [[ -f "$DK_DUMP" ]]; then awk 'NR==1 {print $2}' "$DK_DUMP"; else echo 0; fi; }
dk_tree() { sed -n 's/^TREE //p' "$DK_DUMP" 2>/dev/null; }
dk_scr()  { read -r _ SCR_W SCR_H CAN_LX CAN_RX DOCK_TOP DOCK_BOT <<< "$(grep '^SCR ' "$DK_DUMP")"; }
dk_band() { read -r _ B_SIDE B_X B_Y B_W B_H B_SHIFT <<< "$(grep '^BAND ' "$DK_DUMP")"; }
dk_rows() { read -r _ R_FULL R_Y1 R_Y2 R_TOPH R_BOTH <<< "$(grep '^ROWS ' "$DK_DUMP")"; R_Y1=${R_Y1:-0}; R_Y2=${R_Y2:-0}; }

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
    local name=$1 f x
    dk_p "$name" || return 1
    if (( P_TW > 0 )); then
        GX=$(( P_TX + P_TW / 2 )); GY=$(( P_HY + 5 ))
    elif (( P_HW > 0 && P_HH > 0 )); then
        if (( P_HW > 40 )); then GX=$(( P_HX + P_HW / 3 )); else GX=$(( P_HX + P_HW / 2 )); fi
        if (( P_HH <= 4 )); then GY=$(( P_HY + 1 )); else GY=$(( P_HY + P_HH / 2 )); fi
        # a handle partly under a floating window (a docked panel's under any; a
        # floating panel's under another - fuzz 19 step 13: the edit bar floated
        # over the floating layers' grab point): press where nothing covers it
        # (DRAW rightly ignores a press through a window)
        local own=$name fo=0 # (its own window never covers it - a docked native has a WIN line too)
        (( P_FL != 0 )) && fo=1 # (a floating panel draws over every docked window)
        if dk_covered "$GX" "$GY" 0 "$own" "$fo"; then
            for f in 1 2 4 5 6 7 8 9; do
                x=$(( P_HX + P_HW * f / 10 ))
                if ! dk_covered "$x" "$GY" 0 "$own" "$fo"; then GX=$x; break; fi
            done
            # all of it under other windows (fuzz 19 step 13: the floating layers
            # under the Browser + Color Mixer): nothing a user could grab either
            dk_covered "$GX" "$GY" 0 "$own" "$fo" && return 1
        fi
    else
        return 1
    fi
}

# the floating panels' and native windows' rects (x y w h per line)
# (SKIPNAME: leave out that panel's own window - a native one has a WIN line too;
# FLOATONLY 1: leave out docked windows too - a floating panel draws over them)
# (with FLOATONLY, only the windows in front of SKIPNAME's: the WZ line lists the
# floating ones front to back - two floated to the same spot cover each other's
# title bars, the front one is the one a press reaches)
dk_float_rects() {
    local front=""
    if [[ "${2:-0}" == 1 && -n "${1:-}" ]]; then front=$(dk_wz_front "$1"); fi
    { awk -v n="${1:-}" -v fr="$front" 'BEGIN {k = split(fr, a, " "); for (i = 1; i <= k; i++) f[a[i]] = 1}
           $1=="P" && $2!=n && $3!=0 && $10!=0 && (fr == "" || ($2 in f)) {print $11, $12, $13, $14}' "$DK_DUMP"
      awk -v n="${1:-}" -v fo="${2:-0}" -v fr="$front" 'BEGIN {k = split(fr, a, " "); for (i = 1; i <= k; i++) f[a[i]] = 1}
           $1=="WIN" && $2!=n && (fo==0 || $7==0) && (fr == "" || ($2 in f)) {print $3, $4, $5, $6}' "$DK_DUMP"; } 2>/dev/null
}
# the floating windows in front of NAME (panel names; "-" = none in front, "" =
# NAME is not in the WZ line, so z is unknown)
dk_wz_front() {
    awk -v n="$1" '$1=="WZ" {
        m["mixer"] = "colormixer"; m["advcp"] = "advcolorpicker"; m["cs3d"] = "colorspace3d"; m["anim"] = "animation"
        out = "-"
        for (i = 3; i <= NF; i++) { nm = ($i in m) ? m[$i] : $i; if (nm == n) { print out; exit }; out = out " " nm }
        exit }' "$DK_DUMP" 2>/dev/null
}
# (x, y) under a floating panel / window (within M px, default 0; SKIP = a
# panel's name whose own window does not count; FLOATONLY 1 = only floating
# windows count, for a floating panel's handle)
dk_covered() {
    local x=$1 y=$2 m=${3:-0} skip=${4:-} fo=${5:-0} fx fy fw fh
    while read -r fx fy fw fh; do
        [[ -z "$fx" ]] && continue
        if (( x >= fx - m && x < fx + fw + m && y >= fy - m && y < fy + fh + m )); then return 0; fi
    done < <(dk_float_rects "$skip" "$fo")
    return 1
}

# a drop point for TARGET -> TX TY (1 = no such point)
dk_point() {
    local kind=${1:-} other=${2:-} c last y2 line sy sh
    dk_scr
    case "$kind" in
        edge-left)  TX=2; TY=$(( (DOCK_TOP + DOCK_BOT) / 2 )) ;;
        edge-right) TX=$(( SCR_W - 3 )); TY=$(( (DOCK_TOP + DOCK_BOT) / 2 )) ;;
        band-top)    dk_rows; TX=$(( (CAN_LX + CAN_RX) / 2 )); TY=$(( R_Y1 + 4 )) ;;
        band-bottom) dk_rows; TX=$(( (CAN_LX + CAN_RX) / 2 )); TY=$(( R_Y2 - 4 )) ;;
        float)
            if [[ -n "${2:-}" ]]; then TX=$2; TY=${3:-$2}; else TX=$(( (CAN_LX + CAN_RX) / 2 )); TY=$(( (DOCK_TOP + DOCK_BOT) / 2 )); fi ;;
        newcol|above|below|tab|bottom|left|right)
            dk_p "$other" || return 1
            if (( P_SLOT == 0 )); then return 1; fi
            dk_slot "$P_SLOT"; dk_col "$S_COL"
            # not on screen (a hidden column, a collapsed / inactive slot): its rect is stale
            if (( S_VIS == 0 || C_VIS == 0 || ${C_HID:-0} != 0 )); then return 1; fi
            # a row (side 3 top / 4 bottom): its slots lie side by side
            if (( C_SIDE >= 3 )); then
                case "$kind" in
                    left)   TX=$(( S_X + S_W / 6 )); TY=$(( S_Y + S_H / 2 )) ;;
                    right)  TX=$(( S_X + S_W - 1 - S_W / 6 )); TY=$(( S_Y + S_H / 2 )) ;;
                    above)  TX=$(( S_X + S_W / 2 )); TY=$(( C_Y + 2 )) ;;
                    below)  TX=$(( S_X + S_W / 2 )); TY=$(( C_Y + C_H - 3 )) ;;
                    tab)    TX=$(( S_X + S_W / 2 )); TY=$(( S_Y + S_H / 2 )) ;;
                    bottom|newcol)
                        last=$C_X
                        while read -r line; do
                            read -r _ _ _ _ sy _ sh _ <<< "$line"
                            if (( sy + sh > last )); then last=$(( sy + sh )); fi
                        done < <(awk -v cc="$S_COL" '$1=="SLOT" && $3==cc && $9==-1' "$DK_DUMP")
                        if (( C_X + C_W - last < 6 )); then return 1; fi
                        TX=$(( (last + C_X + C_W) / 2 )); TY=$(( C_Y + C_H / 2 )) ;;
                esac
                return 0
            fi
            case "$kind" in
                left|right) return 1 ;;
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

# dk_rmenu NAME - right-click NAME's handle: its dock menu (M_OPEN M_PANEL M_X M_Y M_W M_N)
dk_rmenu() {
    dk_settle
    if ! dk_grab_point "$1"; then fail "dk_rmenu: $1 has no handle"; return 1; fi
    right_click "$GX" "$GY"; wait_for 0.6 "dock menu"; dk_settle
    read -r _ M_OPEN M_PANEL _ M_X M_Y M_W M_N <<< "$(grep -m1 '^DMENU ' "$DK_DUMP")"
}
dk_menu_has() { awk -v v="$1" '$1=="DMENUR" && $3==v {f=1} END {exit !f}' "$DK_DUMP"; }
# dk_pick VALUE LABEL - click the open dock menu's row with VALUE (DOCK_ACT_*)
dk_pick() {
    local row ry rh
    row=$(awk -v v="$1" '$1=="DMENUR" && $3==v {print $4, $5; exit}' "$DK_DUMP")
    if [[ -z "$row" ]]; then fail "$2: no dock menu row $1"; key Escape; return 1; fi
    read -r ry rh <<< "$row"
    click $(( M_X + 20 )) $(( ry + rh / 2 )); wait_for 0.9 "$2"; dk_park; dk_settle
}

# park the pointer on the bare canvas: the canvas center, 20px above the work
# area's bottom (inside any top / bottom rows), else the first other spot no
# floating panel or native window covers (a parked pointer over a floating bar
# raises a tooltip that covers a row's seam)
dk_park() {
    local y1 y2 x y
    dk_scr; dk_rows
    y1=$DOCK_TOP; y2=$DOCK_BOT
    if (( R_Y2 > R_Y1 )); then y1=$R_Y1; y2=$R_Y2; fi
    for y in $(( y2 - 20 )) $(( y2 - 60 )) $(( (y1 + y2) / 2 )) $(( y1 + 20 )); do
        for x in $(( (CAN_LX + CAN_RX) / 2 )) $(( CAN_LX + 20 )) $(( CAN_RX - 20 )) $(( (3 * CAN_LX + CAN_RX) / 4 )) $(( (CAN_LX + 3 * CAN_RX) / 4 )); do
            if ! dk_covered "$x" "$y" 4; then hover "$x" "$y"; return 0; fi
        done
    done
    hover $(( (CAN_LX + CAN_RX) / 2 )) $(( y2 - 20 ))
}

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
    if ! dk_grab_point "$name"; then
        fail "dk_move: $name has no handle to grab [$(grep -m1 "^P $name " "$DK_DUMP")] [covers: $(dk_float_rects "$name" | tr '\n' ';')]"
        return 1
    fi
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
    names=$(sed -E 's/(LEFT|RIGHT|TOP|BOTTOM)\.[0-9]+://g; s/[|+;]/ /g' <<< "$t")
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
    #    (except a window taller than the room between the top / bottom rows:
    #    LAY_clamp lets an axis it is too big for go, so it can only lie over a row)
    local wl wn wx wy ww wh ws r
    dk_rows
    while read -r wl; do
        read -r _ wn wx wy ww wh ws <<< "$wl"
        for r in "${rects[@]}"; do
            local b=($r) ox oy
            [[ "${b[0]}" == "$wn" ]] && continue
            if (( ws == 0 && R_Y2 > R_Y1 && wh > R_Y2 - R_Y1 + 1 && (b[2] + b[4] <= R_Y1 || b[2] > R_Y2) )); then continue; fi
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
        # (sides in the tree's order: LEFT, RIGHT, TOP, BOTTOM)
        saved=$(grep -E '^DOCK_(LEFT|RIGHT|TOP|BOTTOM)_[0-9]+=' "$QA_CFG" | tr -d '\r' | \
            awk -F_ '{ r = ($2 == "LEFT") ? 1 : ($2 == "RIGHT") ? 2 : ($2 == "TOP") ? 3 : 4; split($3, n, "="); print r, n[1], $0 }' | sort -k1,1n -k2,2n | cut -d' ' -f3- | \
            sed -E 's/^DOCK_(LEFT|RIGHT|TOP|BOTTOM)_([0-9]+)=/\1.\2: /; s/(AUTO|WIDTH:[0-9]+|HEIGHT:[0-9]+); //; s/@[0-9]+//g; s/[*!]//g' | paste -sd';' | sed 's/;/ ; /g')
        local live_t; live_t=$(sed -E 's/ +/ /g' <<< "$t")
        saved=$(sed -E 's/ +/ /g' <<< "$saved")
        if [[ "$saved" != "$live_t" ]]; then bad+=" saved [$saved] != on screen [$live_t];"; fi
        while read -r line; do
            read -r _ nm _ _ _ _ _ _ slot fl _ <<< "$line"
            if (( fl == 0 )); then continue; fi
            if [[ "$DK_NATIVE" == *" $nm "* ]]; then continue; fi
            if ! grep -qi "^DOCK_FLOAT_${nm}=" "$QA_CFG"; then bad+=" floating $nm not saved;"; fi
        done < <(grep '^P ' "$DK_DUMP")
        # the old band key is never written again (it loads as a row)
        if grep -q '^DOCK_BAND=' "$QA_CFG"; then bad+=" DOCK_BAND= still saved;"; fi
    fi
    if [[ -z "$bad" ]]; then pass "$label: invariants hold [$t]"
    else
        # keep the dump that failed, beside the screenshots
        local keep="${SCREENSHOTS_DIR:-.}/_inv_$(date +%H%M%S%N | cut -c1-9).dump"
        cp -f "$DK_DUMP" "$keep" 2>/dev/null
        fail "$label:$bad [dump $(basename "$keep")]"
    fi
    # 7: one border line on every column's inner edge (dk_seams)
    dk_seams "$label"
    assert_no_crash
}

# start every dock test from a fresh dump
# (DRAW rewrites the dump at its first layout, so it is fresh by now)
# dk_ws_state FILE - the whole live layout (what Save Current Layout stores:
# SECTION.KEY=value lines, then WSA=<active>) into FILE (GUI/WORKSPACE-APPLY WS_layout_state$)
dk_ws_state() {
    local n=0
    rm -f "$DK_DUMP.ws"; touch "$DK_DUMP.wsreq"
    while [[ ! -f "$DK_DUMP.ws" && $n -lt 40 ]]; do sleep 0.2; n=$((n + 1)); done
    if [[ -f "$DK_DUMP.ws" ]]; then tr -d '\r' < "$DK_DUMP.ws" | sort > "$1"; else fail "no layout state ($DK_DUMP.ws)"; : > "$1"; fi
}

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
        above)      if [[ "$(dk_side_of "$other")" -ge 3 ]] 2>/dev/null; then dk_expect_row_order "$name" "$other" above; else dk_expect_stacked "$name" "$other"; fi ;;
        below)      if [[ "$(dk_side_of "$other")" -ge 3 ]] 2>/dev/null; then dk_expect_row_order "$name" "$other" below; else dk_expect_stacked "$other" "$name"; fi ;;
        tab)        dk_expect_tabs "$other" "$name" ;;
        bottom)     dk_expect_last "$name" "$other" ;;
        float)      dk_expect_floating "$name" ;;
        band-top)    dk_expect_row "$name" 3 ;;
        band-bottom) dk_expect_row "$name" 4 ;;
        left)        dk_expect_beside "$name" "$other" ;;
        right)       dk_expect_beside "$other" "$name" ;;
    esac
}

# NAME docked in a row on SIDE (3 top, 4 bottom) and laid out; the canvas
# shift is (top rows - bottom rows) / 2
dk_expect_row() {
    local s want; s=$(dk_side_of "$1"); dk_band; dk_rows
    want=$(( (R_TOPH - R_BOTH) / 2 ))
    if [[ "$s" == "$2" ]] && dk_visible "$1" && (( B_SHIFT == want )); then
        pass "$1 in a row along the $( (( $2 == 3 )) && echo top || echo bottom ) (canvas shift $B_SHIFT)"
    else
        fail "$1 not in a row on side $2 (side '${s:-none}', shift $B_SHIFT, want $want) [$(dk_tree)]"
    fi
}

# NAME's row directly above / below OTHER's row (a drop on a row's edge)
dk_expect_row_order() {
    local a=0 b=0 ya yb
    if dk_p "$1"; then a=$P_SLOT; fi
    if dk_p "$2"; then b=$P_SLOT; fi
    if (( a == 0 || b == 0 )); then fail "$1 / $2 not both docked [$(dk_tree)]"; return 0; fi
    dk_slot "$a"; dk_col "$S_COL"; ya=$C_Y; local ca=$S_COL sa=$C_SIDE
    dk_slot "$b"; dk_col "$S_COL"; yb=$C_Y
    if (( sa < 3 || ca == S_COL )); then fail "$1 not in a row of its own beside $2's row [$(dk_tree)]"; return 0; fi
    if [[ "$3" == above ]] && (( ya < yb )); then pass "$1's row above $2's"; return 0; fi
    if [[ "$3" == below ]] && (( ya > yb )); then pass "$1's row below $2's"; return 0; fi
    fail "$1's row (y $ya) not $3 $2's (y $yb) [$(dk_tree)]"
}

# A directly left of B in one row
dk_expect_beside() {
    local a=0 b=0 ca cb oa ob
    if dk_p "$1"; then a=$P_SLOT; fi
    if dk_p "$2"; then b=$P_SLOT; fi
    if (( a == 0 || b == 0 )); then fail "$1 / $2 not both docked [$(dk_tree)]"; return 0; fi
    dk_slot "$a"; ca=$S_COL; oa=$S_ORD; dk_slot "$b"; cb=$S_COL; ob=$S_ORD
    if (( ca == cb && ob == oa + 1 )); then pass "$1 beside $2 (left of it)"; else fail "$1 not directly left of $2 [$(dk_tree)]"; fi
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
            # any panel can take a row along the top / bottom (DK_FUZZ_ROWS=0: not)
            if [[ "${DK_FUZZ_ROWS:-1}" != 0 ]] && (( RANDOM % 6 == 0 )); then
                if (( RANDOM % 2 )); then kind=band-top; else kind=band-bottom; fi
            fi
            case "$kind" in edge-*|float|band-*) other="" ;; esac
            # targets that need OTHER docked, and a source that can be grabbed
            if [[ -n "$other" ]] && ! dk_visible "$other"; then (( tries < 50 )) && continue; kind=edge-right; other=""; fi
            if [[ "$kind" == bottom ]] && ! dk_point bottom "$other"; then (( tries < 50 )) && continue; kind=edge-left; other=""; fi
            dk_visible "$src" && dk_grab_point "$src" && break
            (( tries < 50 )) || break
        done
        # no docked panel to grab (fuzz 19 step 13: every panel floating, the
        # one picked wholly under the Browser + Color Mixer): a floating one
        # that can be grabbed, else skip - no move a user could make either
        if ! { dk_visible "$src" && dk_grab_point "$src"; } && ! { dk_floating "$src" && dk_grab_point "$src"; }; then
            local p2 alt=""
            for p2 in "${panels[@]}"; do dk_floating "$p2" && dk_grab_point "$p2" && { alt=$p2; break; }; done
            if [[ -z "$alt" ]]; then info "fuzz $seed step $i: no panel to grab - skipped"; continue; fi
            src=$alt; [[ "$other" == "$src" ]] && { kind=edge-left; other=""; }
        fi
        info "fuzz $seed step $i: $src $kind $other"
        dk_move_expect "$src" "$kind" $other
        dk_check "fuzz $seed step $i ($src $kind $other)"
    done
}

# the Browser in a row on SIDE (1 top, 2 bottom - its old band): laid out, not
# floating, and the canvas shifted away from it
dk_expect_band() {
    dk_band; dk_p browser
    if (( B_SIDE == $1 && B_H > 0 && P_SLOT > 0 && P_FL == 0 )) && { (( $1 == 1 && B_SHIFT > 0 )) || (( $1 == 2 && B_SHIFT < 0 )); }; then
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

# dk_seams LABEL — the borders between the dock columns and the canvas and
# between neighbouring columns: exactly one 1px seam line (the SEAM colour of
# its side) on every visible column's inner edge, the whole column height,
# and no second line beside it - not the seam colour again, and not a lighter
# frame line (a docked window's own frame). Rows under a floating window, a
# popup or a menu are skipped. Rick, 2026-11-07: "a double line on the right
# side of the toolbar/organizer ... docked to the right side, it's missing a
# pixel or 2 ... make sure that all docks are consistent ... in any
# configuration". DK_SEAMS=0 turns it off.
dk_seams() {
    local label=$1 png txt res
    [[ "${DK_SEAMS:-1}" == 0 ]] && return 0
    dk_scr
    # DK_SEAM_COLORS="404040 404040" stands in for the SEAM line (a build from
    # before it, to see the check fail on the old code)
    grep -q '^SEAM ' "$DK_DUMP" || [[ -n "${DK_SEAM_COLORS:-}" ]] || { fail "$label: no SEAM line in the dock dump"; return 0; }
    # the mouse off the panels first: a hover label left where the last drag ended
    # (the browser's path box over a place row) can reach a column edge and read
    # as a frame line beside the seam (2026-11-20)
    dk_park; dk_settle; dk_scr
    DK_SEAM_N=$(( ${DK_SEAM_N:-0} + 1 ))
    snap_region 0 0 "$SCR_W" "$SCR_H" "seams$DK_SEAM_N"
    png="$SNAP_RESULT"
    [[ -s "$png" ]] || { fail "$label: seam snap failed"; return 0; }
    txt="${png%.png}.txt"
    # back to viewport pixels at the exact scale: the capture can come up a few
    # rows short of the window, and stretching it to WxH slid rows by one
    local pw ph sc vh
    read -r pw ph < <(magick identify -format '%w %h' "$png" 2>/dev/null)
    sc=$(( (pw + SCR_W / 2) / SCR_W )); (( sc < 1 )) && sc=1
    vh=$(( ph / sc )); (( vh > SCR_H )) && vh=$SCR_H
    magick "$png" -background black -extent "$(( SCR_W * sc ))x$(( SCR_H * sc ))" -sample "${SCR_W}x${SCR_H}!" txt:- 2>/dev/null > "$txt"
    res=$(awk -v W="$SCR_W" -v H="$vh" -v SC="${DK_SEAM_COLORS:-}" '
        function h2(t) { t = toupper(t); return (index("0123456789ABCDEF", substr(t,1,1)) - 1) * 16 + index("0123456789ABCDEF", substr(t,2,1)) - 1 }
        function lum(c) { return (h2(substr(c,1,2)) + h2(substr(c,3,2)) + h2(substr(c,5,2))) / 3 }
        function covered(y, x1, x2,   i) {
            for (i = 1; i <= nr; i++) if (y >= ry[i] && y < ry[i] + rh[i] && x2 >= rx[i] && x1 < rx[i] + rw[i]) return 1
            return 0
        }
        function covered2(x, y1, y2,   i) {
            for (i = 1; i <= nr; i++) if (x >= rx[i] && x < rx[i] + rw[i] && y2 >= ry[i] && y1 < ry[i] + rh[i]) return 1
            return 0
        }
        function line(c, beyond) { return lum(c) >= lum(beyond) + 16 && lum(c) >= seamlum - 8 }
        # the rows (top / bottom docks): is (x, y) the T where the seam of row b meets a column seam, or inside a row?
        function rowT(x, y,   b) { for (b = 1; b <= nb; b++) if (y == byb[b] && x >= bx[b] && x < bx[b] + bw[b]) return 1; return 0 }
        # a side column seam starting just across a row seam (full-width rows): a T
        function colT(x, y,   i, xi) { for (i = 1; i <= nc; i++) { xi = (cs[i] == 1) ? cx[i] + cw[i] - 1 : cx[i]; if (x == xi && y >= cy[i] && y < cy[i] + ch[i]) return 1 }; return 0 }
        function inrow(x, y,   b) { for (b = 1; b <= nb; b++) if (y >= by[b] && y < by[b] + bh[b] && x >= bx[b] && x < bx[b] + bw[b]) return 1; return 0 }
        FNR == NR {
            if ($1 == "SCR") { clx = $4; crx = $5 }
            if ($1 == "SEAM") { seam[1] = $2; seam[2] = $3 }
            if ($1 == "COL" && $3 <= 2 && $9 != 0 && $10 == 0 && $7 > 0 && $8 > 0) { nc++; cid[nc] = $2; cs[nc] = $3; cx[nc] = $5; cy[nc] = $6; cw[nc] = $7; ch[nc] = $8 }
            if ($1 == "COL" && $3 >= 3 && $9 != 0 && $10 == 0 && $7 > 0 && $8 > 0) { nb++; bid[nb] = $2; bs[nb] = $3 - 2; bx[nb] = $5; by[nb] = $6; bw[nb] = $7; bh[nb] = $8 }
            if ($1 == "P" && $10 != 0) { nr++; rx[nr] = $11; ry[nr] = $12; rw[nr] = $13; rh[nr] = $14 }
            if ($1 == "WIN" && $7 == 0) { nr++; rx[nr] = $3; ry[nr] = $4; rw[nr] = $5; rh[nr] = $6 }
            if ($1 == "POPUP") { nr++; rx[nr] = $3; ry[nr] = $4; rw[nr] = $5; rh[nr] = $6 }
            # the line between side-by-side slots in a row meets its seam: a T, not a double
            if ($1 == "SLOT" && $9 != 0) { sep[$3 "," ($5 - 1)] = 1; sep[$3 "," ($5 + $7)] = 1 }
            if ($1 == "MENU") { nr++; rx[nr] = $2; ry[nr] = $3; rw[nr] = $4; rh[nr] = $5 }
            next
        }
        FNR == 1 { if (seam[1] == "" && SC != "") split(SC, seam, " ")
                   for (i = 1; i <= nc; i++) { d = (cs[i] == 1) ? 1 : -1; xi = (cs[i] == 1) ? cx[i] + cw[i] - 1 : cx[i]
                       for (k = -3; k <= 3; k++) want[xi + k * d] = 1 }
                   for (b = 1; b <= nb; b++) { byb[b] = (bs[b] == 1) ? by[b] + bh[b] - 1 : by[b]; for (k = -3; k <= 3; k++) wantrow[byb[b] + k] = 1 } }
        /^[0-9]/ { split($1, p, /[,:]/); x = p[1] + 0; y = p[2] + 0; if (!(x in want) && !(y in wantrow)) next
                   c = $3; sub(/^#/, "", c); px[x "," y] = substr(c, 1, 6) }
        END {
            out = ""
            for (i = 1; i <= nc; i++) {
                s = cs[i]; S = seam[s]; seamlum = lum(S); d = (s == 1) ? 1 : -1
                xi = (s == 1) ? cx[i] + cw[i] - 1 : cx[i]       # inner edge: the seam
                xn = xi + d; xin = xi - d                       # across it / just inside
                incol = 0                                       # the neighbour is another column?
                for (j = 1; j <= nc; j++) if (j != i && xn >= cx[j] && xn < cx[j] + cw[j]) incol = 1
                bad = 0; first = ""; run = 0
                for (y = cy[i]; y <= cy[i] + ch[i]; y++) {
                    why = ""; fl = 0
                    # (the band seam row meets this seam: a T, not a double;
                    # rows past H were not captured)
                    if (y < cy[i] + ch[i] && y < H && !covered(y, xi - 3, xi + 3) && !rowT(xn, y)) {
                        a = px[xin "," y]; b = px[xi "," y]; n = px[xn "," y]
                        if (b != S) why = "no seam (" b ")"
                        else if (a == S) why = "seam doubled inside (" a ")"
                        else if (xn >= 0 && xn < W && n == S) why = "seam doubled across (" n ")"
                        else if (line(a, px[(xin - d) "," y])) { why = "a frame line beside the seam inside (" a ")"; fl = 1 }
                        else if ((incol || inrow(xn, y)) && line(n, px[(xn + d) "," y])) { why = "a frame line beside the seam across (" n ")"; fl = 1 }
                    }
                    # a frame line runs down the edge: count it from 8 rows on
                    # (a marker or an icon touching the edge is a few rows)
                    if (fl) { if (run == 0) { runy = y; runwhy = why }; run++; continue }
                    if (run >= 8) { bad += run; if (first == "") first = "y " runy ": " runwhy " (" run " rows)" }
                    run = 0
                    if (why != "") { bad++; if (first == "") first = "y " y ": " why }
                }
                if (bad) out = out sprintf(" col %s (side %d x %d): %d rows bad, first %s;", cid[i], s, xi, bad, first)
                cnt++
            }
            # each top / bottom row: one seam row on its canvas side
            for (r = 1; r <= nb; r++) {
                S = seam[1]; seamlum = lum(S); d = (bs[r] == 1) ? 1 : -1
                yb = byb[r]; yn = yb + d; yin = yb - d
                bad = 0; first = ""; run = 0
                for (x = bx[r] + 2; x <= bx[r] + bw[r] - 2; x++) {
                    why = ""; fl = 0
                    if (x < bx[r] + bw[r] - 2 && !covered2(x, yb - 3, yb + 3) && !((bid[r] "," x) in sep)) {
                        a = px[x "," yin]; b = px[x "," yb]; n = px[x "," yn]
                        if (b != S) why = "no seam (" b ")"
                        else if (a == S) why = "seam doubled inside (" a ")"
                        else if (n == S && !inrow(x, yn) && !colT(x, yn)) why = "seam doubled across (" n ")"
                        else if (line(a, px[x "," (yin - d)])) { why = "a frame line beside the seam inside (" a ")"; fl = 1 }
                    }
                    if (fl) { if (run == 0) { runx = x; runwhy = why }; run++; continue }
                    if (run >= 8) { bad += run; if (first == "") first = "x " runx ": " runwhy " (" run " px)" }
                    run = 0
                    if (why != "") { bad++; if (first == "") first = "x " x ": " why }
                }
                if (bad) out = out sprintf(" row %s (side %d y %d): %d px bad, first %s;", bid[r], bs[r] + 2, yb, bad, first)
                cnt++
            }
            printf "%d|%s", cnt, out
        }' "$DK_DUMP" "$txt")
    rm -f "$txt"
    # an empty result is the awk failing (a quote in its text, say), never a pass
    if [[ -z "$res" ]]; then fail "$label: seam check printed nothing (awk error?)"
    elif [[ -z "${res#*|}" ]]; then pass "$label: seams ok (${res%%|*} edges)"
    else cp -f "$DK_DUMP" "${png%.png}.dump" 2>/dev/null; fail "$label: seams:${res#*|} [snap $(basename "$png") + .dump]"; fi
}
