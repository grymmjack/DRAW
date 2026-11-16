#!/bin/bash
# =============================================================================
# marquee-space-reposition.sh — QA test: hold SPACE while making a selection to
# slide it (Photoshop-style), for every marquee shape (BUGS.md 2026-11-15)
#
# For each of rect / ellipse / freehand / polygon: start the shape, hold SPACE
# and move the cursor 40px right, let go of SPACE, finish. The selection's
# left edge lands 40 screen px right of where the shape started, and its size
# is only what was drawn with SPACE up. The rect had this already; the ellipse,
# freehand and polygon selections ignored SPACE (or panned the view).
#
# Fixture: a 320x200 transparent PNG.
# Dump: LPSEL <active> <x> <y> <w> <h> <pixels> <layers> (canvas px) |
#       VIEW zoom offX offY tool | CVORG x y | BTN toolbox i kind id name x y w h
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Marquee: SPACE slides the selection being made ==="
MS_DIR="$(mktemp -d /tmp/draw-qa-mspace-XXXXXX)"
magick -size 320x200 xc:none "PNG32:$MS_DIR/blank.png"
draw_quit; draw_settle
DRAW_EXTRA_ARGS="$MS_DIR/blank.png"
draw_launch 15; wait_for 1.5 "loaded"
assert_no_crash
dk_begin
CX=$CANVAS_CX; CY=$CANVAS_CY
read -r _ Z _ <<< "$(grep -m1 '^VIEW ' "$DK_DUMP")"
read -r _ OX OY <<< "$(grep -m1 '^CVORG ' "$DK_DUMP")"
info "zoom $Z%, canvas at $OX,$OY"
btn() { awk -v n="$1" '$1=="BTN" && $2=="toolbox" && $6==n {print $7+int($9/2)" "$8+int($10/2); exit}' "$DK_DUMP"; }
sel() { read -r _ S_ACT S_X S_Y S_W S_H _ <<< "$(grep -m1 '^LPSEL ' "$DK_DUMP")"; }
cvx() { echo $(( ($1 - OX) * 100 / Z )); }   # screen x -> canvas x
SHIFT_CV=$(( 40 * 100 / Z ))                 # the SPACE-held move, canvas px
TOL=$(( 300 / Z + 2 ))

# start x of each shape (screen), left of the middle
SX=$(( CX - 80 )); SY=$(( CY - 30 ))
check() { # NAME STARTX(screen) WANT_W(canvas)
    dk_park; dk_settle; sel
    local want_x=$(( $(cvx "$2") + SHIFT_CV ))
    info "$1: selection $S_X,$S_Y ${S_W}x$S_H (want x ~$want_x, w ~$3)"
    if (( S_ACT != 0 )) && (( (S_X - want_x) * (S_X - want_x) <= TOL * TOL )) && (( (S_W - $3) * (S_W - $3) <= TOL * TOL )); then
        pass "$1: SPACE slid the selection ${SHIFT_CV}px right, same size"
    else
        fail "$1: selection at x $S_X w $S_W (want x $want_x w $3, tolerance $TOL)"
    fi
    key ctrl+d; wait_for 0.3 "deselect"
}
space_slide() { # moves the cursor 40px right with SPACE held, from X Y
    raw_key down space; sleep 0.2
    hover $(( $1 + 20 )) "$2"; sleep 0.1; hover $(( $1 + 40 )) "$2"; sleep 0.2
    raw_key up space; sleep 0.2
}
pick() { read -r BX BY <<< "$(btn "$1")"; [[ -n "$BY" ]] || { fail "no $1 button"; return 1; }; click "$BX" "$BY"; wait_for 0.3 "$1"; }

# -- rect: drag 60x40, slide 40 --
pick marquee && {
    mouse_down $SX $SY; sleep 0.1
    hover $(( SX + 30 )) $(( SY + 20 )); hover $(( SX + 60 )) $(( SY + 40 )); sleep 0.15
    space_slide $(( SX + 60 )) $(( SY + 40 ))
    mouse_up; wait_for 0.4 "rect done"
    check "rect" $SX $(( 60 * 100 / Z ))
}

# -- ellipse: same moves --
pick marquee-ellipse && {
    mouse_down $SX $SY; sleep 0.1
    hover $(( SX + 30 )) $(( SY + 20 )); hover $(( SX + 60 )) $(( SY + 40 )); sleep 0.15
    space_slide $(( SX + 60 )) $(( SY + 40 ))
    mouse_up; wait_for 0.4 "ellipse done"
    check "ellipse" $SX $(( 60 * 100 / Z ))
}

# -- freehand: a 60px-wide loop, slide 40 mid-way, finish the loop --
pick marquee-free && {
    mouse_down $SX $SY; sleep 0.1
    hover $(( SX + 30 )) $(( SY + 5 )); hover $(( SX + 60 )) $(( SY + 20 )); sleep 0.15
    space_slide $(( SX + 60 )) $(( SY + 20 ))
    hover $(( SX + 100 )) $(( SY + 40 )); hover $(( SX + 70 )) $(( SY + 40 )); hover $(( SX + 40 )) $(( SY + 30 )); sleep 0.1
    mouse_up; wait_for 0.4 "freehand done"
    check "freehand" $SX $(( 60 * 100 / Z ))
}

# -- polygon: two clicks, slide 40 with SPACE (no button), a third, close --
pick marquee-poly && {
    click $SX $SY; sleep 0.25
    click $(( SX + 60 )) $SY; sleep 0.25
    hover $(( SX + 60 )) $(( SY + 40 )); sleep 0.15
    space_slide $(( SX + 60 )) $(( SY + 40 ))
    click $(( SX + 100 )) $(( SY + 40 )); sleep 0.25
    right_click $(( SX + 100 )) $(( SY + 40 )); wait_for 0.4 "polygon done"
    check "polygon" $SX $(( 60 * 100 / Z ))
}
read -r _ Z2 _ <<< "$(grep -m1 '^VIEW ' "$DK_DUMP")"; read -r _ OX2 OY2 <<< "$(grep -m1 '^CVORG ' "$DK_DUMP")"
(( OX2 == OX && OY2 == OY && Z2 == Z )) && pass "SPACE did not pan or zoom the view" || fail "the view moved: $OX,$OY $Z% -> $OX2,$OY2 $Z2%"
screenshot "marquee-space"
assert_no_crash
rm -rf "$MS_DIR"
