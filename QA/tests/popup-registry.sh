#!/bin/bash
# =============================================================================
# popup-registry.sh — QA test: every popup is in the one popup registry
# (GUI/POPUP-MENU), so it switches off what an open popup must switch off.
#
# (Rick, 2026-11-15, "yes" to the z-order refactor. Each popup used to be
# listed by hand in ~9 places - the render paths' popup blocks, the switches
# for the cursor-only redraw paths, tooltips, dock edges, the pointer shape,
# the loupe - and the color strip's size menu was in only 2 of them, so the
# strip covered it, black boxes showed on it and tooltips came through.)
#
# For each popup: open it, then
#   - the dump's POPK line names it, with "partial" (fast redraw paths off)
#     and "tips" (tooltips held off)
#   - moving the pointer along one row leaves the rest of the box unchanged
#     (no stale pixels copied over it)
#   - Esc closes it: POPK is empty again, and the fast paths come back
# Popups: layer context menu, drawer context menu, dock handle menu, command
# palette, palette menu, menu bar dropdown, color strip size menu, and the
# lightbox's loop menu (that one moved: it was drawn before the GUI went back
# over the canvas, now with the others on top).
#
# Dump: POPK <names...> [partial] [tips] | POPUP kind x y w h | PSTRIP | PSM |
# ANIMLB / ANIMLBC / ANIMLBE (the lightbox).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/popup-lib.sh"
info "=== The popup registry ==="
dk_begin

popk() { POPK=" $(grep -m1 '^POPK' "$DK_DUMP" | cut -c5-) "; }

# registered NAME LABEL: the open popup is in POPK with partial + tips
registered() {
    popk
    if [[ "$POPK" == *" $1 "* && "$POPK" == *" partial "* && "$POPK" == *" tips "* ]]; then
        pass "$2: registered as '$1', fast paths and tooltips off [$POPK]"
    else
        fail "$2: POPK is [$POPK], want '$1' + partial + tips"
    fi
}

# steady LABEL X Y W H: hover the box's first row, then along it; the rows
# below stay the same (row height 12, first row from y + 2)
steady() {
    local label=$1 x=$2 y=$3 w=$4 h=$5 dx A
    (( h > 30 )) || { info "$label: box too short to check rows ($h)"; return; }
    hover $(( x + w / 2 )) $(( y + 8 )); wait_for 0.4 "$label row 0"; dk_settle
    hover $(( x + w / 2 )) $(( y + 8 )); wait_for 0.3 "$label row 0"
    snap_region $(( x + 2 )) $(( y + 16 )) $(( w - 4 )) $(( h - 18 )) "$label-a"; A=$SNAP_RESULT
    for dx in 6 14 22 30 38; do hover $(( x + dx )) $(( y + 8 )); wait_for 0.12 "along row 0"; done
    hover $(( x + w / 2 )) $(( y + 8 )); wait_for 0.5 "back"
    snap_region $(( x + 2 )) $(( y + 16 )) $(( w - 4 )) $(( h - 18 )) "$label-b"
    assert_regions_same "$A" "$SNAP_RESULT" "$label: its rows stay put while the pointer moves along row 0"
}

# closed LABEL: after Esc nothing is open
closed() {
    dk_park; dk_settle; popk
    [[ "$POPK" == "  " ]] && pass "$1: Esc closes it, nothing registered open" || fail "$1: after Esc POPK is [$POPK]"
}

# --- nothing open ---------------------------------------------------------------------
key Escape; dk_park; dk_settle; popk
[[ "$POPK" == "  " ]] && pass "at rest nothing is open [$POPK]" || fail "at rest POPK is [$POPK]"

# --- layer context menu -----------------------------------------------------------------
dk_p layers
right_click $(( P_X + 40 )) $(( P_Y + 26 )); wait_for 0.5 "layer menu"; dk_settle
registered layerctx "layer context menu"
popup_rect popup && steady "layer menu" "$PX" "$PY" "$PW" "$PH"
key Escape; closed "layer context menu"

# --- drawer context menu (probe down the drawer for a bin slot) ----------------------------
if dk_visible drawer; then
    dk_p drawer
    for (( yy = P_Y + 6; yy < P_Y + P_H - 4; yy += 8 )); do
        right_click $(( P_X + 10 )) "$yy"; wait_for 0.4 "drawer slot"; dk_settle
        grep -q '^POPUP popup' "$DK_DUMP" && break
        key Escape
    done
    registered drawerctx "drawer context menu"
    popup_rect popup && steady "drawer menu" "$PX" "$PY" "$PW" "$PH"
    key Escape; closed "drawer context menu"
fi

# --- dock handle menu (the layer panel's handle) -----------------------------------------------
dk_p layers
right_click $(( P_HX + P_HW / 2 )) $(( P_HY + P_HH / 2 )); wait_for 0.5 "handle menu"; dk_settle
registered dockmenu "dock handle menu"
popup_rect popup && steady "handle menu" "$PX" "$PY" "$PW" "$PH"
key Escape; closed "dock handle menu"

# --- command palette ----------------------------------------------------------------------
key question; wait_for 0.6 "command palette"; dk_settle
registered cmdpalette "command palette"
key Escape; closed "command palette"

# --- palette menu (the palette name, bottom right) -------------------------------------------
read -r _ nx ny nw nh <<< "$(grep -m1 '^PALNAME ' "$DK_DUMP")"
if [[ -n "$nx" ]]; then
    click $(( nx + nw / 2 )) $(( ny + nh / 2 )); wait_for 0.6 "palette menu"; park_free; dk_settle
    registered palettemenu "palette menu"
    key Escape; closed "palette menu"
fi

# --- a menu bar dropdown ---------------------------------------------------------------------
read -r _ _ rx rw <<< "$(grep -m1 '^MROOT edit ' "$DK_DUMP")"
click $(( rx + rw / 2 )) 5; wait_for 0.6 "EDIT"; park_free; dk_settle
registered menubar "menu bar dropdown"
popup_rect dropdown && steady "EDIT dropdown" "$PX" "$PY" "$PW" "$PH"
key Escape; closed "menu bar dropdown"

# --- the color strip's size menu ---------------------------------------------------------------
read -r _ ST_Y ST_H _ <<< "$(grep -m1 '^PSTRIP ' "$DK_DUMP")"
if [[ -n "$ST_Y" ]]; then
    dk_scr
    right_click $(( SCR_W - 4 )) $(( ST_Y + ST_H / 2 )); wait_for 0.8 "size menu"; dk_settle
    registered stripsize "color strip size menu"
    read -r _ MX MY MW _ <<< "$(grep -m1 '^PSM ' "$DK_DUMP")"
    [[ -n "$MX" ]] && steady "strip menu" "$MX" "$MY" "$MW" $(( 4 * 12 + 4 ))
    key Escape; closed "color strip size menu"
fi

# --- the lightbox's loop menu (a sheet of 7 16x16 frames) ----------------------------------------
LB_DIR="/tmp/draw-qa-popreg-$$"; mkdir -p "$LB_DIR"
magick -size 64x32 xc:none -fill '#c04040' -draw 'rectangle 2,2 9,11' -fill '#4040c0' -draw 'rectangle 18,2 25,11' "$LB_DIR/plain.png"
python3 "$DRAW_ROOT/QA/fixtures/png-chunk.py" put "$LB_DIR/plain.png" "$LB_DIR/sheet.png" drAn \
    "$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,7,3,12,0,0).hex())")"
draw_quit; draw_settle
DRAW_EXTRA_ARGS="$LB_DIR/sheet.png"
draw_launch 15; wait_for 1.5 "sheet"
park_mouse; key KP_0; wait_for 0.6 "lightbox"; dk_settle
read -r _ LB_SHOWN _ _ _ _ _ _ LB_BY LB_BH _ <<< "$(grep -m1 '^ANIMLB ' "$DK_DUMP")"
c=($(grep -m1 '^ANIMLBC ' "$DK_DUMP"))
LX=${c[11]:-0}; LW=${c[12]:-0} # control 6 = LOOP
if [[ "$LB_SHOWN" == -1 ]] && (( LW > 0 )); then
    click $(( LX + LW / 2 )) $(( LB_BY + LB_BH / 2 )); wait_for 0.5 "LOOP"; dk_settle
    registered lbmenu "lightbox loop menu"
    read -r _ _ _ E_MENU _ _ E_MX E_MY E_MW _ <<< "$(grep -m1 '^ANIMLBE ' "$DK_DUMP")"
    [[ "$E_MENU" == -1 ]] && steady "loop menu" "$E_MX" "$E_MY" "$E_MW" $(( 4 * 12 + 4 ))
    key Escape; closed "lightbox loop menu"
else
    fail "lightbox: shown '$LB_SHOWN', LOOP control width '$LW'"
fi
rm -rf "$LB_DIR"
assert_no_crash
info "=== The popup registry: done ==="
