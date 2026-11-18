#!/bin/bash
# =============================================================================
# aa-shapes-dividers.sh — QA test: antialiased rounded smart shapes, solid
# dice, brush-sized dividers, and the Advanced Color Picker wheel
# (Rick 2026-11-17: "pill smart shape looks not round"; "same with tab - i bet
# anywhere trying to do rounded corners will have this issue"; "pacman pie
# shape too"; "dice smart shape draws pixely in filled mode"; "rect with smart
# dividers isn't honoring stroke size"; "nor is elipse - and it's not
# antialiased either"; the color wheel + triangle "can we apply the same
# antialiasing on it?").
#   1. Rounded rect / tab / pill / pac-man, committed with Antialias on: soft
#      edge pixels (capsules between the exact curve points, a point every
#      ~1.5px instead of 8-12 chords).
#   2. Rect with dividers (Right / Down while dragging) and ellipse with
#      spokes: the dividers are drawn with the brush (size 6) - as wide as the
#      outline - and soft.
#   3. A solid die (right-drag, BG color faces): supersampled - soft edges.
#   4. The Advanced Color Picker: screenshot of the antialiased ring + triangle.
# Coverage = (after - before) / (1 - before): white paint over the checkerboard.
# QA-OPTIONS: WORKSPACE=default ANTIALIAS=TRUE DEFAULT_BRUSH_SIZE=6 DEFAULT_BRUSH_SHAPE=0 TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE PALETTE_DEFAULT_BG_TRANSPARENT=FALSE
# =============================================================================
info "=== Antialiased smart shapes + dividers + color wheel ==="
CX=$CANVAS_CX; CY=$CANVAS_CY

coverage() { # BEFORE AFTER NAME -> FULL SOFT (and a coverage map beside AFTER)
    local cov="${2%.png}-coverage.png"
    magick "$2" "$1" -colorspace gray -fx "v >= 0.999 ? 0 : (u - v) / (1 - v)" "$cov" 2>/dev/null
    FULL=$(magick "$cov" -fx "u >= 0.97 ? 1 : 0" -format "%[fx:mean*w*h]" info: 2>/dev/null); FULL=${FULL%.*}
    SOFT=$(magick "$cov" -fx "(u > 0.03 && u < 0.97) ? 1 : 0" -format "%[fx:mean*w*h]" info: 2>/dev/null); SOFT=${SOFT%.*}
    info "$3: $FULL full px, $SOFT soft px ($(basename "$cov"))"
}
check_soft() { # NAME [MIN SOFT %] (after coverage) - mostly-straight shapes (a rect's
    # long sides at whole pixels are hard by right) pass a lower share
    local pct=${2:-12}
    if (( ${FULL:-0} < 150 )); then fail "$1: barely painted ($FULL px)"
    elif (( SOFT * 100 < FULL * pct )); then fail "$1: hard edges - $SOFT soft px for $FULL full px"
    else pass "$1: smooth ($SOFT soft px for $FULL full px)"; fi
}
palette_run() { key question; wait_for 0.4 "palette"; type_text "$1"; wait_for 0.3 "filter"; key Return; wait_for 0.8 "$1"; }
# S activates the remembered smart shape; each further S within 600ms cycles
# to the next (POLYGON 0, PIE 1, ROUNDED RECT 2, TAB 3, PILL 4, PAC-MAN 5, 3D 6)
ss_taps() { draw_focus; local i; for (( i = 0; i <= $1; i++ )); do raw_key down s; sleep 0.08; raw_key up s; sleep 0.15; done; sleep 0.4; }
# shape NAME TAPS X1 Y1 X2 Y2 [BTN]: draw it in a box region, check, undo
shape() {
    local name=$1 taps=$2 x1=$3 y1=$4 x2=$5 y2=$6 btn=${7:-1}
    park_mouse; wait_for 0.2 "park"
    snap_region $(( x1 - 12 )) $(( y1 - 12 )) $(( x2 - x1 + 24 )) $(( y2 - y1 + 24 )) "$name-before"; local B="$SNAP_RESULT"
    ss_taps "$taps"
    drag "$x1" "$y1" "$x2" "$y2" "$btn"
    wait_for 0.8 "$name committed"
    park_mouse; wait_for 0.3 "park"
    snap_region $(( x1 - 12 )) $(( y1 - 12 )) $(( x2 - x1 + 24 )) $(( y2 - y1 + 24 )) "$name"; local A="$SNAP_RESULT"
    screenshot "aa-$name"
    if [[ "$btn" == 1 ]]; then coverage "$B" "$A" "$name"; check_soft "$name" "${8:-12}"
    else assert_regions_differ "$B" "$A" "$name: drawn"; fi
    key ctrl+z; wait_for 0.4 "undo"
}

# --- 1. rounded smart shapes ---------------------------------------------------------
shape rrect 2 $(( CX - 120 )) $(( CY - 70 )) $(( CX - 20 )) $(( CY - 10 )) 1 1 # S + 2 taps -> ROUNDED RECT
shape tab   1 $(( CX - 120 )) $(( CY - 70 )) $(( CX - 20 )) $(( CY - 10 )) 1 1 # remembered RR + 1 -> TAB
shape pill  1 $(( CX - 120 )) $(( CY - 70 )) $(( CX + 20 )) $(( CY - 10 )) 1 6 # -> PILL
shape pacman 1 $(( CX - 120 )) $(( CY - 70 )) $(( CX - 40 )) $(( CY + 10 )) # -> PAC-MAN

# --- 3. a solid die (right-drag: BG color faces) ----------------------------------------
shape dice  1 $(( CX - 110 )) $(( CY - 70 )) $(( CX - 20 )) $(( CY + 20 )) 3 # -> 3D, right-drag = solid

key b; wait_for 0.3 "brush"

# --- 2. dividers / spokes with the brush ------------------------------------------------
park_mouse; wait_for 0.2 "park"
snap_region $(( CX - 130 )) $(( CY - 80 )) 140 100 "rdiv-before"; RB="$SNAP_RESULT"
key r; wait_for 0.3 "rect"
mouse_down $(( CX - 120 )) $(( CY - 70 ))
hover $(( CX - 60 )) $(( CY - 40 )); hover $(( CX )) $(( CY + 10 )); wait_for 0.3 "dragging"
key Right; key Right; key Down; wait_for 0.3 "dividers"
hover $(( CX + 1 )) $(( CY + 10 )); wait_for 0.2 "move"
mouse_up; wait_for 0.8 "rect committed"
park_mouse; wait_for 0.3 "park"
snap_region $(( CX - 130 )) $(( CY - 80 )) 140 100 "rdiv"; RA="$SNAP_RESULT"
screenshot "aa-rect-dividers"
coverage "$RB" "$RA" "rect+dividers"
# outline (4 sides) alone at size 6 ~ 6*(2*120+2*80) = 2400 px; 3 dividers add ~6*(80+80+120)
if (( ${FULL:-0} > 2900 )); then pass "rect dividers drawn with the brush ($FULL full px)"
else fail "rect dividers look 1px ($FULL full px, expected > 2900)"; fi
check_soft "rect+dividers" 0
key ctrl+z; wait_for 0.4 "undo"

park_mouse; wait_for 0.2 "park"
snap_region $(( CX - 130 )) $(( CY - 80 )) 120 120 "espoke-before"; EB="$SNAP_RESULT"
key c; wait_for 0.3 "ellipse"
mouse_down $(( CX - 120 )) $(( CY - 70 ))
hover $(( CX - 60 )) $(( CY - 20 )); hover $(( CX - 20 )) $(( CY + 30 )); wait_for 0.3 "dragging"
key Right; key Right; key Right; wait_for 0.3 "spokes"
hover $(( CX - 21 )) $(( CY + 30 )); wait_for 0.2 "move"
mouse_up; wait_for 0.8 "ellipse committed"
park_mouse; wait_for 0.3 "park"
snap_region $(( CX - 130 )) $(( CY - 80 )) 120 120 "espoke"; EA="$SNAP_RESULT"
screenshot "aa-ellipse-spokes"
coverage "$EB" "$EA" "ellipse+spokes"
# ring alone ~ 6 * pi * 100 = 1900; 3 spokes add ~6 * 3 * 95
if (( ${FULL:-0} > 2500 )); then pass "ellipse spokes drawn with the brush ($FULL full px)"
else fail "ellipse spokes look 1px ($FULL full px, expected > 2500)"; fi
check_soft "ellipse+spokes"
key ctrl+z; wait_for 0.4 "undo"
key b; wait_for 0.2 "brush"

# --- 4. the Advanced Color Picker wheel -------------------------------------------------
palette_run "toggle advanced color picker"
park_mouse; wait_for 0.6 "picker"
screenshot "aa-acp"
palette_run "toggle advanced color picker"

assert_no_crash
