#!/bin/bash
# =============================================================================
# anim-menu-plain.sh — QA test: the ANIM menu on a picture without frames.
#
# Rick, 2026-11-08 (field kit T-3): with Lightbox, X-Sheet and Onion Skin on in
# DRAW.cfg, a plain picture's ANIM menu showed them checked and enabled; Lightbox
# could be unchecked but X-Sheet then would not uncheck (its toggle refused: no
# frames). They are views of the frames: on a plain picture they are greyed and
# unchecked, their settings kept for when the picture has frames.
#
# Dump: ANIMMENU id:checked:enabled for 2519 Lightbox, 2520 Panes, 2540 X-Sheet,
# 2527 Onion Skin (as the menu bar last drew them; -1 = yes, 0 = no).
#
# Visual: the open ANIM menu on the plain picture looks the same with those three
# settings on as with them off (old build: checked + enabled vs unchecked + greyed).
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt
# =============================================================================
info "=== Animation: ANIM menu on a plain picture ==="

MP_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
MP_DIR="/tmp/draw-qa-animmenuplain-$$"
mkdir -p "$MP_DIR"
magick -size 32x32 xc:'#204060' -fill '#c04040' -draw 'rectangle 8,8 20,20' "$MP_DIR/plain.png"

mp_settle() { { hover 300 250; wait_for 0.2 "render"; hover 305 252; wait_for 0.3 "render"; } >&2; }
mp_menu() { mp_settle; grep -m1 '^ANIMMENU' "$MP_DUMP" 2>/dev/null | cut -d' ' -f2-; }
mp_expect() { # WANT LABEL
    local got; got=$(mp_menu)
    [[ "$got" == "$1" ]] && pass "$2: $got" || fail "$2: ANIMMENU '$got', wanted '$1'"
}

# The rest of the ANIM menu (Rick, T-3 decision 2026-11-09): on a plain picture
# only the ways in stay enabled - Animation Panel, Add Frame, Add Blank Frame,
# Detect Frames, Create Frames from Grid, Import PNG Sequence. ANIMMENUX lists
# every ANIM-range item id:checked:enabled.
MP_WAYS_IN="2505 2510 2511 2547 2548 2551"
MP_FRAME_ITEMS="2523 2524 2525 2526 2529 2500 2507 2528 2521 2522 2530 2531 2541 2542 2543 2544 2545 2546 2549 2550 2539 2532 2533 2534 2535 2536 2537 2538"
mp_items() { # ENABLED(-1/0) CHECKED_MUST_BE_0(1/0) IDS... -> "" or the mismatches
    local want=$1 unchk=$2 id e c bad=""; shift 2
    local line; line=" $(mp_settle; grep -m1 '^ANIMMENUX' "$MP_DUMP" | cut -d' ' -f2-) "
    for id in "$@"; do
        [[ "$line" =~ \ $id:(-?[0-9]+):(-?[0-9]+)\  ]] || { bad+=" $id:missing"; continue; }
        c=${BASH_REMATCH[1]}; e=${BASH_REMATCH[2]}
        [[ "$e" == "$want" ]] || bad+=" $id:$c:$e"
        [[ "$unchk" == 1 && "$c" != 0 ]] && bad+=" $id:checked"
    done
    echo "$bad"
}
mp_items_expect() { # ENABLED CHECKED_MUST_BE_0 LABEL IDS...
    local w=$1 u=$2 l=$3 r; shift 3
    r=$(mp_items "$w" "$u" "$@")
    [[ -z "$r" ]] && pass "$l" || fail "$l:$r"
}

mp_snap_menu() { # LABEL -> $SNAP_RESULT: the open ANIM dropdown
    local ax aw mx my mw mh
    read -r _ _ ax aw <<< "$(mp_settle; grep -m1 '^MROOT anim ' "$MP_DUMP")"
    [[ -z "$ax" ]] && { fail "$1: no ANIM menu"; return 1; }
    click $(( ax + aw / 2 )) 6
    wait_for 0.6 "ANIM menu open"
    read -r _ mx my mw mh <<< "$(grep -m1 '^MENU ' "$MP_DUMP")"
    [[ -z "$mw" ]] && { fail "$1: the ANIM menu did not open"; return 1; }
    snap_region "$mx" "$my" "$mw" "$mh" "$1"
    key Escape; wait_for 0.4 "menu closed"
}
mp_launch() { # OPTION_VALUE (1 / 0) for LIGHTBOX, XSHEET, ONION_SKIN and the frame settings
    draw_quit
    draw_settle
    DRAW_EXTRA_ARGS="--option LIGHTBOX=$1 --option XSHEET=$1 --option ONION_SKIN=$1 --option FRAME_GRID=$1 --option PREVIEW_SHOWS_FRAME=$1 --option ONION_TINT=$1 --option CLIP_FRAME_LIGHTBOX=$1 --option CLIP_FRAME_SHEET=$1 $MP_DIR/plain.png"
    draw_launch 15
    wait_for 1.5 "Picture loaded"
    assert_no_crash
}

mp_launch 1
mp_snap_menu "animmenu-plain-on" && cp "$SNAP_RESULT" "$MP_DIR/on.png"

mp_expect "2519:0:0 2520:0:0 2540:0:0 2527:0:0" "plain picture: Lightbox / Panes / X-Sheet / Onion Skin greyed and unchecked"
mp_items_expect 0 1 "plain picture: the frame commands and frame settings greyed, settings unchecked" $MP_FRAME_ITEMS
mp_items_expect -1 0 "plain picture: the ways in stay enabled (panel, add frame, detect, from grid, PNG sequence)" $MP_WAYS_IN

park_mouse; key KP_Add; wait_for 0.8 "Num + (Add Frame)"
mp_expect "2519:-1:-1 2520:0:-1 2540:-1:-1 2527:-1:-1" "after Add Frame: the kept settings show (checked) and the items work"
mp_items_expect -1 0 "after Add Frame: the frame commands and settings enabled" $MP_FRAME_ITEMS
R=$(mp_items -1 0 2521); [[ -z "$R" && " $(grep -m1 '^ANIMMENUX' "$MP_DUMP") " == *" 2521:-1:-1 "* ]] && pass "after Add Frame: Clip Strokes in the Lightbox shows its kept setting (checked)" || fail "Clip in the Lightbox after Add Frame: $(grep -m1 '^ANIMMENUX' "$MP_DUMP")"

park_mouse; key ctrl+z; wait_for 0.8 "Undo"
mp_expect "2519:0:0 2520:0:0 2540:0:0 2527:0:0" "undone back to a plain picture: greyed and unchecked again"
mp_items_expect 0 1 "undone: the frame commands greyed again" $MP_FRAME_ITEMS

mp_launch 0
mp_snap_menu "animmenu-plain-off" && cp "$SNAP_RESULT" "$MP_DIR/off.png"
if [[ -f "$MP_DIR/on.png" && -f "$MP_DIR/off.png" ]]; then
    assert_regions_same "$MP_DIR/on.png" "$MP_DIR/off.png" \
        "plain picture: the ANIM menu looks the same with the frame views and settings on as off" 3
fi

DRAW_EXTRA_ARGS=""
draw_quit
draw_settle
draw_launch 15
rm -rf "$MP_DIR"
assert_no_crash
