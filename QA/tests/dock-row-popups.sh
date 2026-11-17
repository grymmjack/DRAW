#!/bin/bash
# =============================================================================
# dock-row-popups.sh — QA test: popups from panels in a top dock row
# (Rick 2026-11-16, two screenshots).
#  1 "the smart shape popup is not aligned properly when vertical, and it does
#    not also scale with the correct scale": the toolbox in a top row -> the
#    flyout drops DOWN from the Smart Shapes button as a column, its buttons
#    the parent button's size. At the toolbox's own Scale (a panel surface,
#    GUI_TB in units) it still opens at the button, at the button's size
#    (it used to open by the menu bar, tiny). Back at the left edge: a row to
#    the right of the button, as before.
#  2 "text tool menu is not aligned properly when dock exists at top": the
#    text bar's two lines sit above the row (the row starts under the bar),
#    and the font list opened from it is drawn OVER the row (POPUP textbar:
#    its frame rows one colour, no docked panel over it).
# Dump (flags dump TRUE as -1): SUBFLY active x y w h vertical btnW btnH; TEXTBAR visible x y w h
# topbarH fontBtnX fontBtnW; BTN toolbox i kind id name x y w h; POPUP kind x y w h.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/popup-lib.sh"
info "=== Popups from a top dock row: Smart Shapes flyout, text bar font list ==="
dk_begin

row_of() { dk_p "$1" || return 1; dk_slot "$P_SLOT"; dk_col "$S_COL"; }
ssbtn() { read -r _ _ _ _ _ _ BX BY BW BH <<< "$(awk '$1=="BTN" && $2=="toolbox" && $6=="smart-shapes" && $9>0' "$DK_DUMP" | head -1)"; }
sfly() { read -r _ F_ON F_X F_Y F_W F_H F_V F_BW F_BH <<< "$(grep -m1 '^SUBFLY ' "$DK_DUMP")"; }
pick_scale() { # NAME DPID VALUE (menu row: 20 Auto, 20+k = kx)
    local ry rh
    dk_settle
    if ! dk_grab_point "$1"; then fail "$1 has no handle"; return 1; fi
    right_click "$GX" "$GY"; wait_for 0.6 "the handle menu"; dk_settle
    read -r _ MO MP _ MX _ <<< "$(grep -m1 '^DMENU ' "$DK_DUMP")"
    if [[ "$MO" != -1 || "$MP" != "$2" ]]; then fail "$1: no handle menu (open '$MO' panel '$MP')"; key Escape; return 1; fi
    read -r ry rh _ <<< "$(awk -v v="$3" '$1=="DMENUR" && $3==v {print $4" "$5; exit}' "$DK_DUMP")"
    if [[ -z "$ry" ]]; then fail "$1: no Scale row $3 in its menu"; key Escape; return 1; fi
    click $(( MX + 12 )) $(( ry + rh / 2 )); wait_for 0.8 "scale row $3"; dk_park; dk_settle
}
# hold the Smart Shapes button, read the flyout, release on the button (keeps the tool)
hold_flyout() { # LABEL
    ssbtn
    if [[ -z "$BW" || "$BW" == 0 ]]; then fail "$1: no Smart Shapes button in the dump"; return 1; fi
    mouse_down $(( BX + BW / 2 )) $(( BY + BH / 2 )); sleep 0.6; dk_settle
    sfly
    info "$1: button $BX,$BY ${BW}x$BH; flyout on=$F_ON at $F_X,$F_Y ${F_W}x$F_H vertical=$F_V buttons ${F_BW}x$F_BH"
    if popup_rect subtool; then frame_ok_sub "$1"; else fail "$1: no POPUP subtool (not reblitted over the panels)"; fi
    FLY_IMG=""
    if [[ -n "$PW" ]]; then snap_region "$PX" "$PY" "$PW" "$PH" "$1-flyout"; FLY_IMG=$SNAP_RESULT; fi
    mouse_up; sleep 0.4; dk_park; dk_settle
    [[ -n "$F_ON" && "$F_ON" != 0 ]] || { fail "$1: the flyout did not open"; return 1; } # (TRUE dumps as -1)
}
frame_ok_sub() {
    local bad="" f
    snap_region "$PX" "$PY" "$PW" 1 "$1-ftop"; local FT=$SNAP_RESULT
    snap_region "$PX" $(( PY + PH - 1 )) "$PW" 1 "$1-fbot"; local FB=$SNAP_RESULT
    for f in "$FT" "$FB"; do one_color "$f" || bad+=" $(basename "$f")"; done
    if [[ -z "$bad" ]]; then pass "$1: the flyout's frame is whole (drawn over the panels)"; else fail "$1: something is drawn over the flyout:$bad"; fi
}
near() { (( $1 - $2 <= $3 && $2 - $1 <= $3 )); }

# --- 1a: toolbox in a top row, Auto scale ---------------------------------------
dk_move toolbox band-top
row_of toolbox && (( C_SIDE == 3 )) && pass "toolbox in a top row" || fail "toolbox not in a top row [$(dk_tree)]"
if hold_flyout "top row"; then
    [[ "$F_V" != 0 ]] && pass "top row: the flyout is a column" || fail "top row: the flyout is not vertical ($F_V)"
    (( F_Y >= BY + BH - 1 )) && pass "top row: it drops below the button ($F_Y >= $(( BY + BH )))" || fail "top row: flyout top $F_Y, the button ends at $(( BY + BH ))"
    near "$F_X" "$BX" 6 && pass "top row: it lines up under the button (x $F_X vs $BX)" || fail "top row: flyout x $F_X, button x $BX"
    (( F_H > F_W )) && pass "top row: taller than wide (${F_W}x$F_H)" || fail "top row: ${F_W}x$F_H is not a column"
    [[ "$F_BW" == "$BW" ]] && pass "top row: buttons the parent's size ($F_BW)" || fail "top row: buttons $F_BW px, the parent $BW"
fi
screenshot "dock-row-flyout-top"

# --- 1b: the toolbox at its own Scale (1x): a panel surface ----------------------
if pick_scale toolbox 1 21; then
    if hold_flyout "own scale"; then
        (( F_Y >= BY + BH - 1 )) && pass "own scale: below the button ($F_Y >= $(( BY + BH )))" || fail "own scale: flyout top $F_Y, the button $BY..$(( BY + BH ))"
        near "$F_X" "$BX" 6 && pass "own scale: under the button (x $F_X vs $BX)" || fail "own scale: flyout x $F_X, button x $BX"
        near "$F_BW" "$BW" 1 && pass "own scale: buttons the parent's on-screen size ($F_BW vs $BW)" || fail "own scale: buttons $F_BW px, the parent $BW"
    fi
    screenshot "dock-row-flyout-scale1"
    pick_scale toolbox 1 20
fi

# --- 1c: at 3x its icons are whole 3x3 blocks -----------------------------------
# Rick 2026-11-17 ("the shape flyout when docked vertically is distorted"): at
# its own Scale the toolbox is k window px per unit, k / display scale view px
# (3 / 2 here) - the flyout drew its icons in view px, so rows / columns came
# out doubled unevenly. Now they are drawn at k window px per unit. A 24x24
# window px piece of the first icon must survive a k-down / k-up round trip at
# some phase.
blocky() { # IMG CX CY K - a 24x24 piece centred at CX,CY (image px) is KxK blocks
    local p q
    for (( p = 0; p < $4; p++ )); do for (( q = 0; q < $4; q++ )); do
        local x=$(( $2 - 12 + p )) y=$(( $3 - 12 + q ))
        if [[ "$(magick "$1" -crop 24x24+$x+$y +repage \( +clone -sample $(( 24 / $4 ))x$(( 24 / $4 ))! -sample 24x24! \) -metric AE -compare -format '%[distortion]' info: 2>/dev/null)" == 0 ]]; then return 0; fi
    done; done
    return 1
}
if pick_scale toolbox 1 23; then
    if hold_flyout "3x scale" && [[ -n "$FLY_IMG" ]]; then
        IW=$(identify -format '%w' "$FLY_IMG"); RS=$(( IW / PW )); (( RS < 1 )) && RS=1
        CX=$(( (F_X - PX + F_BW / 2 + 1) * RS )); CY=$(( (F_Y - PY + F_BH / 2 + 1) * RS ))
        blocky "$FLY_IMG" "$CX" "$CY" 3 && pass "3x scale: the flyout's icon is whole 3x3 blocks" || fail "3x scale: the flyout's icon is not 3x3 blocks (stretched unevenly) - $FLY_IMG"
    fi
    pick_scale toolbox 1 20
fi

# --- 1c: back at the left edge: a row right of the button -----------------------
dk_move toolbox edge-left
if hold_flyout "left column"; then
    [[ "$F_V" == 0 ]] && pass "left column: a row, not a column" || fail "left column: vertical=$F_V"
    (( F_X >= BX + BW - 1 )) && pass "left column: right of the button ($F_X >= $(( BX + BW )))" || fail "left column: flyout x $F_X, the button ends at $(( BX + BW ))"
    (( F_Y <= BY + BH && F_Y + F_H >= BY )) && pass "left column: level with the button" || fail "left column: flyout y $F_Y..$(( F_Y + F_H )), button $BY..$(( BY + BH ))"
fi
key Escape; dk_settle

# --- 2: the text bar above a top row; its font list over the row ----------------
dk_move toolbox band-top
key t; wait_for 0.6 "text tool"; dk_park; dk_settle
read -r _ T_ON T_X T_Y T_W T_H T_TOP T_FX T_FW _ <<< "$(grep -m1 '^TEXTBAR ' "$DK_DUMP")"
row_of toolbox
info "text bar on=$T_ON y $T_Y h $T_H (topbar $T_TOP); toolbox row at y $C_Y h $C_H"
[[ -n "$T_ON" && "$T_ON" != 0 ]] && pass "the text bar shows" || fail "no text bar (TEXTBAR: $(grep -m1 '^TEXTBAR ' "$DK_DUMP"))"
(( C_Y >= T_Y + T_H )) && pass "the row starts under the text bar's two lines ($C_Y >= $(( T_Y + T_H )))" || fail "the row ($C_Y) covers the text bar (ends $(( T_Y + T_H )))"
screenshot "dock-row-textbar"
if [[ -n "$T_FW" && "$T_FW" -gt 0 ]]; then
    click $(( T_FX + T_FW / 2 )) $(( T_Y + 6 )); wait_for 0.8 "font list"; dk_settle
    if popup_rect textbar; then
        info "font list at $PX,$PY ${PW}x$PH"
        (( PY < C_Y + C_H && PY + PH > C_Y )) && pass "the font list reaches over the row" || info "the font list does not cross the row here"
        bad=""
        for yy in $(( PY + PH - 1 )); do snap_region "$PX" "$yy" "$PW" 1 "fontlist-$yy"; one_color "$SNAP_RESULT" || bad+=" bottom"; done
        snap_region "$PX" "$PY" 1 "$PH" "fontlist-left"; one_color "$SNAP_RESULT" || bad+=" left"
        [[ -z "$bad" ]] && pass "the font list's frame is whole (drawn over the row)" || fail "a panel is drawn over the font list:$bad"
        screenshot "dock-row-textbar-fontlist"
    else
        fail "no POPUP textbar with the font list open ($(grep '^POPUP' "$DK_DUMP" | tr '\n' ' '))"
    fi
    key Escape; dk_settle
else
    fail "no font button in TEXTBAR"
fi

assert_window_exists
info "=== Popups from a top dock row done ==="
