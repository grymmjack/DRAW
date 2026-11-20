#!/bin/bash
# =============================================================================
# tool-options-paint.sh — QA test: the Tool Options bar's shared painting set
# (GUI/SEL-BAR; PLANS/TOOL-OPTIONS-BAR.md phase 1b - "every tool gets options";
# the Selection Bar grew into the Tool Options bar):
#   - the brush shows the bar: SIZE · SHAPE (ROUND / SQUARE / / / \) + SOFT ·
#     OPACITY · PIXEL PERFECT / AA · SYMMETRY, every control inside it
#   - each control drives the same state its keys do (and the keys show on the bar):
#     SIZE track / wheel / middle-click default, SHAPE chips (SOFT only for round),
#     OPACITY slider + keys 1-0, PIXEL PERFECT and AA turn each other off
#   - SYMMETRY chips: + mirrors a stroke four ways; OFF turns it off
#   - per tool: the line has no PIXEL PERFECT, the marquee its selection controls,
#     a tool with nothing on it (the picker) no bar
# Dump: SELBAR vis x y w h lines ... tool; SELBARP size px shape soft opacity pp aa
# sym; SELBARC id x y w trackX (viewport px at Auto). Ids: GUI/SEL-BAR.BI.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE SELECTION_BAR=TRUE ANTIALIAS=FALSE BRUSH_SOFT=0
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"

ROW_H=14 # THEME.TEXT_BAR_ROW_HEIGHT (the stock theme)
# control ids (GUI/SEL-BAR.BI)
ID_REPLACE=1; ID_SIZE=24; ID_ROUND=26; ID_SQUARE=27; ID_SLASH=28; ID_BACKSLASH=29
ID_SOFT=30; ID_OPACITY=31; ID_PP=32; ID_AA=33; ID_SYM0=35; ID_SYMX=37; ID_SYM3=38

sb_read() { read -r _ S_ON S_X S_Y S_W S_H S_LN _ _ _ _ _ _ _ _ _ _ _ _ S_TOOL _ <<< "$(grep -m1 '^SELBAR ' "$DK_DUMP")"; }
sp_read() { read -r _ P_SIZE P_PX P_SHAPE P_SOFT P_OP P_PP P_AA P_SYM _ <<< "$(grep -m1 '^SELBARP ' "$DK_DUMP")"; }
sbc() { C_ID=""; read -r _ C_ID C_X C_Y C_W C_TX _ <<< "$(grep -m1 "^SELBARC $1 " "$DK_DUMP")"; [[ -n "$C_ID" ]]; }
sb_click() { # sb_click ID WHAT — the control's middle
    if sbc "$1"; then click $(( C_X + C_W / 2 )) $(( C_Y + ROW_H / 2 )); wait_for 0.4 "$2"; dk_park; dk_settle; else fail "no control $1 ($2) on the bar"; fi
}
sb_track() { # sb_track ID DX WHAT — press the slider's track DX px from its left end (0 = 1 px left of it, inside the slider's 2 px slack: a Retina click 1-3 px off still means "the left end")
    if sbc "$1"; then click $(( C_TX + ($2 > 0 ? $2 : -1) )) $(( C_Y + ROW_H / 2 )); wait_for 0.4 "$3"; dk_park; dk_settle; else fail "no slider $1 ($3) on the bar"; fi
}
sb_inside() {
    local why="" id x y w tx
    while read -r _ id x y w tx; do
        (( x >= S_X && x + w <= S_X + S_W && y >= S_Y && y + ROW_H <= S_Y + S_H )) || why+=" control $id at $x,$y w $w"
    done < <(grep '^SELBARC ' "$DK_DUMP")
    [[ -z "$why" ]] && pass "$1: every control inside the bar ($S_LN lines, ${S_W}x$S_H)" || fail "$1:$why"
}
has_all() { # has_all WHAT ID... — every id on the bar
    local miss="" id
    for id in "${@:2}"; do sbc "$id" || miss+=" $id"; done
    [[ -z "$miss" ]] && pass "$1" || fail "$1: missing$miss"
}

info "=== Tool Options: the painting set ==="
dk_begin

# --- the brush shows the bar ------------------------------------------------------
key b; wait_for 0.6 "brush"; dk_park; dk_settle; sb_read; sp_read
[[ -n "$S_ON" && "$S_ON" != 0 ]] && pass "the bar shows with the brush (tool $S_TOOL)" || { fail "no Tool Options bar with the brush (SELBAR: $(grep -m1 '^SELBAR ' "$DK_DUMP"))"; assert_no_crash; exit 0; }
sb_inside "brush"
has_all "brush: SIZE, the shape chips, SOFT, OPACITY, PIXEL PERFECT, AA, the symmetry chips" $ID_SIZE $ID_ROUND $ID_SQUARE $ID_SLASH $ID_BACKSLASH $ID_OPACITY $ID_PP $ID_AA $ID_SYM0 $ID_SYMX $ID_SYM3
sbc $ID_REPLACE && fail "selection mode chips shown with the brush" || pass "no selection controls with the brush"
screenshot "topt-brush"

# --- SIZE ---------------------------------------------------------------------------
sb_track $ID_SIZE 43 "size: the track's right end"; sp_read
(( P_PX >= 90 )) && pass "SIZE track right: a big brush ($P_PX px)" || fail "SIZE track right: $P_PX px (index $P_SIZE)"
sb_track $ID_SIZE 2 "size: the track's left end"; sp_read
S0=$P_SIZE
(( P_PX <= 5 )) && pass "SIZE track left: a small brush ($P_PX px)" || fail "SIZE track left: $P_PX px"
sbc $ID_SIZE && { scroll_up $(( C_TX + 20 )) $(( C_Y + ROW_H / 2 )); wait_for 0.4 "wheel up on SIZE"; dk_park; dk_settle; }
sp_read
(( P_SIZE == S0 + 1 )) && pass "wheel up on SIZE: one step ($S0 -> $P_SIZE)" || fail "wheel up on SIZE: $S0 -> $P_SIZE"
key bracketright; wait_for 0.3 "]"; dk_park; dk_settle; sp_read
(( P_SIZE == S0 + 2 )) && pass "] steps the size the bar shows ($P_SIZE)" || fail "]: size $P_SIZE (wanted $(( S0 + 2 )))"
sbc $ID_SIZE && { middle_click $(( C_TX + 20 )) $(( C_Y + ROW_H / 2 )); wait_for 0.4 "middle-click SIZE"; dk_park; dk_settle; }
sp_read
DEF=$(sed -n 's/^DEFAULT_BRUSH_SIZE=//p' "$DRAW_ROOT/QA/DRAW.qa.cfg" | head -1); DEF=${DEF%%[^0-9]*}; DEF=${DEF:-1}
(( P_SIZE == DEF )) && pass "middle-click SIZE: the start size ($DEF)" || fail "middle-click SIZE: $P_SIZE (start size $DEF)"

# --- SHAPE + SOFT -------------------------------------------------------------------
sb_click $ID_SQUARE "SQUARE chip"; sp_read
(( P_SHAPE == -1 )) && pass "SQUARE chip: a square nib" || fail "SQUARE chip: shape $P_SHAPE"
sbc $ID_SOFT && fail "SOFT shown for a square nib" || pass "no SOFT for a square nib"
sb_click $ID_SLASH "/ chip"; sp_read
(( P_SHAPE == 2 )) && pass "/ chip: a slant nib" || fail "/ chip: shape $P_SHAPE"
sb_click $ID_ROUND "ROUND chip"; sp_read
(( P_SHAPE == 0 )) && pass "ROUND chip: a round nib" || fail "ROUND chip: shape $P_SHAPE"
sbc $ID_SOFT && pass "SOFT shown for a round nib" || fail "no SOFT for a round nib"
sb_track $ID_SOFT 22 "SOFT: the middle"; sp_read
(( P_SOFT >= 30 && P_SOFT <= 70 )) && pass "SOFT track middle: $P_SOFT %" || fail "SOFT track middle: $P_SOFT"
key backslash; wait_for 0.3 "\\ toggles round / square"; dk_park; dk_settle; sp_read
(( P_SHAPE == -1 )) && pass "\\ key: square, and the bar shows it" || fail "\\ key: shape $P_SHAPE"
sb_click $ID_SQUARE "SQUARE chip again" # (stays square)
sp_read; (( P_SHAPE == -1 )) || fail "SQUARE chip on a square nib: shape $P_SHAPE"

# --- OPACITY ------------------------------------------------------------------------
key 5; wait_for 0.3 "key 5: opacity 50"; dk_park; dk_settle; sp_read
(( P_OP == 50 )) && pass "key 5: opacity 50, the bar shows it" || fail "key 5: opacity $P_OP"
sb_track $ID_OPACITY 43 "OPACITY: the right end"; sp_read
(( P_OP >= 95 )) && pass "OPACITY track right: $P_OP %" || fail "OPACITY track right: $P_OP"
sb_track $ID_OPACITY 2 "OPACITY: the left end"; sp_read
(( P_OP >= 10 && P_OP <= 15 )) && pass "OPACITY track left: $P_OP % (no lower than the keys' 10)" || fail "OPACITY track left: $P_OP"
sbc $ID_OPACITY && { middle_click $(( C_TX + 20 )) $(( C_Y + ROW_H / 2 )); wait_for 0.4 "middle-click OPACITY"; dk_park; dk_settle; }
sp_read
(( P_OP == 100 )) && pass "middle-click OPACITY: 100" || fail "middle-click OPACITY: $P_OP"

# --- PIXEL PERFECT / AA ---------------------------------------------------------------
sb_click $ID_PP "PIXEL PERFECT"; sp_read
(( P_PP != 0 && P_AA == 0 )) && pass "PIXEL PERFECT on" || fail "PIXEL PERFECT: pp $P_PP aa $P_AA"
sb_click $ID_AA "AA"; sp_read
(( P_AA != 0 && P_PP == 0 )) && pass "AA on turns PIXEL PERFECT off" || fail "AA: pp $P_PP aa $P_AA"
sb_click $ID_AA "AA off"; sp_read
(( P_AA == 0 && P_PP == 0 )) && pass "AA off" || fail "AA off: pp $P_PP aa $P_AA"

# --- SYMMETRY -------------------------------------------------------------------------
sb_track $ID_SIZE 6 "a small brush for the stroke"
sb_click $ID_SYMX "+ chip"; sp_read
(( P_SYM == 2 )) && pass "+ chip: four-way symmetry" || fail "+ chip: symmetry $P_SYM"
# the bottom-right quadrant, apart from the stroke (top-left). Tall, because the bar at
# the top moves the canvas down from CANVAS_CY (the guides inside it are in both snaps)
snap_region $(( CANVAS_CX + 10 )) $(( CANVAS_CY + 5 )) 50 75 "topt-mirror-before"
MB="$SNAP_RESULT"
drag $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 25 )) $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 15 ))
wait_for 0.5 "stroke"; dk_park; dk_settle
snap_region $(( CANVAS_CX + 10 )) $(( CANVAS_CY + 5 )) 50 75 "topt-mirror-after"
assert_regions_differ "$MB" "$SNAP_RESULT" "the + mirror of the stroke shows in the opposite quadrant"
sb_click $ID_SYM0 "OFF chip"; sp_read
(( P_SYM == 0 )) && pass "OFF chip: no symmetry" || fail "OFF chip: symmetry $P_SYM"
key F7; wait_for 0.3 "F7"; dk_park; dk_settle; sp_read
(( P_SYM == 1 )) && pass "F7 cycles the mode the chips show ($P_SYM)" || fail "F7: symmetry $P_SYM"
key F8; wait_for 0.3 "F8 clears"; dk_park; dk_settle; sp_read
(( P_SYM == 0 )) || fail "F8: symmetry $P_SYM"

# --- per tool ---------------------------------------------------------------------------
key l; wait_for 0.6 "line"; dk_park; dk_settle; sb_read
(( S_ON != 0 )) && pass "the line shows the bar" || fail "line: no bar"
has_all "line: SIZE, shape chips, OPACITY, AA, symmetry" $ID_SIZE $ID_ROUND $ID_OPACITY $ID_AA $ID_SYM0
sbc $ID_PP && fail "PIXEL PERFECT shown with the line (brush and dot only)" || pass "no PIXEL PERFECT with the line"
sb_inside "line"
key m; wait_for 0.6 "marquee"; dk_park; dk_settle; sb_read
sbc $ID_REPLACE && pass "the marquee: its selection controls" || fail "marquee: no REPLACE chip"
sbc $ID_SIZE && fail "SIZE shown with the marquee" || pass "no painting set with the marquee"
key t; wait_for 0.6 "text tool"; dk_park; dk_settle; sb_read
(( S_ON == 0 )) && pass "the text tool: the Text Bar instead of Tool Options" || fail "text tool: SELBAR on=$S_ON"
key b; wait_for 0.6 "brush again"; dk_park; dk_settle
dk_check "the Tool Options bar with the brush"

assert_no_crash
assert_window_exists
info "=== Tool Options: the painting set PASSED ==="
