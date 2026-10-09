#!/bin/bash
# =============================================================================
# popup-lib.sh — popups over windows (tests/popups-over-*.sh source it).
# check_popup: with a popup open (its frame from the dump's POPUP lines), the
# 2px strips around it must be identical open and closed, its 1px frame
# rows / columns one colour (no window drawn over it), and every window it
# does not touch identical open and closed.
# run_popups: opens each kind in turn - layer context menu, drawer context
# menu, a dock handle menu (HANDLE_PANEL, default colormixer), the command
# palette, the palette menu, the EFFECTS dropdown and one of its flyouts.
# =============================================================================

source "$DRAW_ROOT/QA/tbed-lib.sh"

# first POPUP line of KIND (a prefix) -> PX PY PW PH (1 = none)
popup_rect() {
    local line
    line=$(grep "^POPUP $1" "$DK_DUMP" | head -1) || return 1
    [[ -n "$line" ]] || return 1
    read -r _ PK PX PY PW PH <<< "$line"
}
# a snapped image has one color only
one_color() { [[ "$(identify -format '%k' "$1" 2>/dev/null)" == "1" ]]; }

# hover a point of the canvas area that is inside no window and no docked
# panel (a hover / tooltip there would change what the snaps compare)
park_free() {
    local x y w wn wx wy ww wh ok
    dk_scr
    for (( y = DOCK_BOT - 12; y > DOCK_TOP + 10; y -= 16 )); do
        for (( x = CAN_LX + 8; x < CAN_RX - 8; x += 16 )); do
            ok=1
            while read -r w; do
                read -r _ wn wx wy ww wh _ <<< "$w"
                if (( x >= wx - 2 && x < wx + ww + 2 && y >= wy - 2 && y < wy + wh + 2 )); then ok=0; break; fi
            done < <(grep '^WIN ' "$DK_DUMP")
            if (( ok )); then hover "$x" "$y"; sleep 0.3; return 0; fi
        done
    done
    dk_park
}

declare -a WINS
load_wins() { mapfile -t WINS < <(grep '^WIN ' "$DK_DUMP"); }

# check_popup KIND LABEL CLOSE-CMD [FROMX] — the popup KIND is open now.
# FROMX: strips start at this x (a flyout overlaps its parent dropdown, which
# closes with it, so the columns under the parent are not compared)
check_popup() {
    local kind=$1 label=$2 close=$3 fromx=${4:-0} w i
    # the pointer off any chrome (a tooltip popping up later would differ);
    # not for a flyout, which closes when the pointer leaves its parent row
    if [[ "$kind" != flyout* ]]; then park_free; fi
    dk_settle
    if ! popup_rect "$kind"; then fail "$label: no '$kind' popup was redrawn on top"; eval "$close"; return; fi
    info "$label: $PK at $PX,$PY ${PW}x$PH"
    load_wins
    local over=""
    for w in "${WINS[@]}"; do
        read -r _ wn wx wy ww wh _ <<< "$w"
        if (( PX < wx + ww && PX + PW > wx && PY < wy + wh && PY + PH > wy )); then over+=" $wn"; fi
    done
    info "$label: over the windows:${over:- (none)}"
    local bx=$PX bw=$PW
    if (( fromx > PX )); then bw=$(( PW - (fromx - PX) )); bx=$fromx; fi
    snap_region $(( PX - 2 )) "$PY" 2 "$PH" "$label-L1"; local L1=$SNAP_RESULT
    snap_region $(( PX + PW )) "$PY" 2 "$PH" "$label-R1"; local R1=$SNAP_RESULT
    snap_region "$bx" $(( PY + PH )) "$bw" 2 "$label-B1"; local B1=$SNAP_RESULT
    snap_region "$PX" "$PY" "$PW" 1 "$label-ftop"; local FT=$SNAP_RESULT
    snap_region "$PX" $(( PY + PH - 1 )) "$PW" 1 "$label-fbot"; local FB=$SNAP_RESULT
    snap_region "$PX" "$PY" 1 "$PH" "$label-fleft"; local FL=$SNAP_RESULT
    snap_region $(( PX + PW - 1 )) "$PY" 1 "$PH" "$label-fright"; local FR=$SNAP_RESULT
    local -a WO=()
    local ex=0 ey=0 ew=0 eh=0
    [[ -n "${PARENT_RECT:-}" ]] && read -r ex ey ew eh <<< "$PARENT_RECT"
    for i in "${!WINS[@]}"; do
        read -r _ wn wx wy ww wh _ <<< "${WINS[i]}"
        if (( PX < wx + ww && PX + PW > wx && PY < wy + wh && PY + PH > wy )); then WO[i]=""; continue; fi
        # (under the parent dropdown of a flyout, which closes with it)
        if (( ew > 0 && ex < wx + ww && ex + ew > wx && ey < wy + wh && ey + eh > wy )); then WO[i]=""; continue; fi
        snap_region "$wx" "$wy" "$ww" "$wh" "$label-win-$wn-1"; WO[i]=$SNAP_RESULT
    done
    eval "$close"
    sleep 0.3; park_free; sleep 0.3; dk_settle
    if popup_rect "$kind"; then fail "$label: the popup did not close"; fi
    if (( fromx <= PX && PX >= 2 )); then snap_region $(( PX - 2 )) "$PY" 2 "$PH" "$label-L0"; assert_regions_same "$SNAP_RESULT" "$L1" "$label: the strip left of it is untouched" 0; fi
    if (( PX + PW + 2 <= VIEWPORT_W )); then snap_region $(( PX + PW )) "$PY" 2 "$PH" "$label-R0"; assert_regions_same "$SNAP_RESULT" "$R1" "$label: the strip right of it is untouched" 0; fi
    if (( PY + PH + 2 <= VIEWPORT_H )); then snap_region "$bx" $(( PY + PH )) "$bw" 2 "$label-B0"; assert_regions_same "$SNAP_RESULT" "$B1" "$label: the strip below it is untouched" 0; fi
    local f bad=""
    for f in "$FT" "$FB" "$FL" "$FR"; do one_color "$f" || bad+=" $(basename "$f")"; done
    if [[ -z "$bad" ]]; then pass "$label: its frame is whole (nothing drawn over it)"; else fail "$label: its frame is broken:$bad"; fi
    for i in "${!WINS[@]}"; do
        [[ -z "${WO[i]}" ]] && continue
        read -r _ wn wx wy ww wh _ <<< "${WINS[i]}"
        snap_region "$wx" "$wy" "$ww" "$wh" "$label-win-$wn-0"
        assert_regions_same "$SNAP_RESULT" "${WO[i]}" "$label: the $wn window stays drawn" 0
    done
}


run_popups() {
    local HANDLE_PANEL=${HANDLE_PANEL:-colormixer}
    # --- layer context menu (right-click a layer row) ----------------------------------
    dk_p layers
    right_click $(( P_X + 40 )) $(( P_Y + 26 )); sleep 0.5
    check_popup popup "layer-menu" 'key Escape'

    # --- drawer context menu (right-click a drawer slot) --------------------------------
    # (a right-click on its mini palette sets the BG colour instead: probe down the
    #  drawer for a bin slot)
    dk_p drawer
    for (( yy = P_Y + 6; yy < P_Y + P_H - 4; yy += 8 )); do
        right_click $(( P_X + 10 )) "$yy"; sleep 0.4; dk_settle
        if grep -q '^POPUP popup' "$DK_DUMP"; then break; fi
    done
    check_popup popup "drawer-menu" 'key Escape'

    # --- dock handle menu (right-click the Color Mixer's handle) ---------------------------
    dk_p "$HANDLE_PANEL"
    right_click $(( P_HX + P_HW / 2 )) $(( P_HY + P_HH / 2 )); sleep 0.5
    check_popup popup "handle-menu" 'key Escape; dk_park'

    # --- command palette ---------------------------------------------------------------
    key question; sleep 0.6
    check_popup cmdpalette "command-palette" 'key Escape'

    # --- palette menu (the palette name, bottom right) -------------------------------------
    read -r _ nx ny nw nh <<< "$(grep '^PALNAME ' "$DK_DUMP")"
    click $(( nx + nw / 2 )) $(( ny + nh / 2 )); sleep 0.6
    check_popup palettemenu "palette-menu" 'key Escape'

    # --- menu bar dropdown + a flyout (EFFECTS > ADJUST) --------------------------------------
    r=$(grep '^MROOT effects ' "$DK_DUMP"); read -r _ _ rx rw <<< "$r"
    click $(( rx + rw / 2 )) 5; sleep 0.6
    check_popup dropdown "effects-menu" 'key Escape'
    click $(( rx + rw / 2 )) 5; sleep 0.6; dk_settle
    read -r _ mx my mw mh <<< "$(grep '^MENU ' "$DK_DUMP")"
    # hover down the dropdown until a flyout opens
    for (( yy = my + 6; yy < my + mh - 4; yy += 6 )); do
        hover $(( rx + 30 )) "$yy"; sleep 0.25
        dk_settle
        if grep -q '^POPUP flyout' "$DK_DUMP"; then break; fi
    done
    PARENT_RECT="$mx $my $mw $mh" check_popup flyout "effects-flyout" 'key Escape; sleep 0.3; key Escape' $(( mx + mw ))


}
