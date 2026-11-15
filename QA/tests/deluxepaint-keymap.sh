#!/bin/bash
# =============================================================================
# deluxepaint-keymap.sh — QA test: the Deluxe Paint keymap
# (ASSETS/PRESETS/deluxepaint.bindings) gives DPaint's keys their DPaint jobs
# (Rick, 2026-11-14: "the deluxe paint still uses ctrl-z for undo, that should be
# u, and i guess SHIFT U for redo?" / "make the deluxe paint shortcuts accurate").
#
# Before: the preset had no rows at all, so "Load preset > DeluxePaint" changed
# nothing; and a keymap could only move a key an action already had, never take
# a key from another action (two on one key = the first registered won).
#
#  1. every mapped key fires its action (FIRE log), and not the DRAW action that
#     had the key (e = ellipse, not the eraser; 1 = previous frame, not opacity)
#  2. U undoes a stroke, Shift+U redoes it; Ctrl+Z does nothing now
#  3. [ ] step the FG color, { } the BG color; . is the one-pixel brush
#  4. b = Brush Selector: the next box dragged becomes the custom brush
#  5. keys a row took from DRAW are unbound (i was the picker: nothing fires)
#
# Dump: KMAP <fg> <bg> <customBrush> <brushSize> <selectorArmed> <loopMode> <binds> (flags: 0 / -1)
# QA-BINDINGS: ASSETS/PRESETS/deluxepaint.bindings
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt DEVELOPER_MODE=TRUE TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
LOG="$DRAW_ROOT/inputs.log"
info "=== Deluxe Paint keymap ==="
dk_begin
[[ -f "$LOG" ]] || { fail "no inputs.log (DEVELOPER_MODE=TRUE did not take)"; assert_no_crash; return 0 2>/dev/null || exit 0; }
[[ -n "$QA_CONFIG_DIR" && -f "$QA_CONFIG_DIR/DRAW.bindings" ]] && pass "the test's own config, keymap seeded ($(grep -cvE '^\s*(#|$)' "$QA_CONFIG_DIR/DRAW.bindings") rows)" \
    || fail "no seeded DRAW.bindings (QA_CONFIG_DIR '$QA_CONFIG_DIR')"
grep -q '^\[KEYMAP\]' "$LOG" && info "keys taken from DRAW: $(grep -c '^\[KEYMAP\]' "$LOG")"

kmap() { read -r _ KM_FG KM_BG KM_CB KM_BS KM_SEL KM_LOOP KM_N <<< "$(grep -m1 '^KMAP ' "$DK_DUMP")"; }
# fired KEY: press KEY, FIRED = the action ids the dispatcher fired for it
fired() {
    local n; n=$(wc -l < "$LOG")
    key "$1"; wait_for 0.35 "$1"
    FIRED=" $(tail -n +$(( n + 1 )) "$LOG" | grep -o 'action=[0-9]*' | cut -d= -f2 | tr '\n' ' ')"
}
# want KEY ID [NOT_ID...] "what": KEY fires ID (and none of NOT_ID)
want() {
    local k=$1 id=$2; shift 2
    local desc="${*: -1}" bad="" x
    fired "$k"
    for x in "${@:1:$#-1}"; do [[ "$FIRED " == *" $x "* ]] && bad+=" $x"; done
    if [[ "$FIRED " == *" $id "* && -z "$bad" ]]; then pass "$k -> $desc ($id)"; else fail "$k: want $id ($desc), fired [$FIRED ]${bad:+, not wanted:$bad}"; fi
}

# --- 1. the keys ------------------------------------------------------------------
want d 101 "continuous freehand = Brush"
want s 102 1706 "dotted freehand = Dot (not Smart Shapes)"
want v 105 113 "line (not Move)"
want w 106 117 "polygon (not the wand)"
want shift+w 107 "filled polygon"
want e 110 118 "ellipse (not the eraser)"
want shift+e 111 "filled ellipse"
want c 110 "circle = ellipse"
want shift+a 1702 "airbrush = Spray"
want q 122 "curve = Bezier"
want shift+t 116 115 "choose font = Text (custom font)"
want comma 104 905 "pick colour (not grid size)"
want g 8101 "grid on";  want g 8101 "grid off"
want p 2021 106 "palette mixer = Color Mixer"; want p 2021 "Color Mixer off"
want Tab 2060 401 "colour cycling (not the toolbar)"; want Tab 2060 "colour cycling off"
want greater 406 "zoom in"; want less 407 "zoom out"
want slash 8007 8105 "symmetry (not grid alignment)"; for i in 1 2 3; do key slash; wait_for 0.2 "cycle"; done
want equal 602 "brush larger"; want minus 601 "brush smaller"
want x 315 517 "flip horizontal (not swap FG/BG)"; want x 315 "flip back"
want y 316 "flip vertical"; want y 316 "flip back"
want o 1104 1707 "outline (custom brush; nothing without one)"
want F9 8011 "menu bar off"; want F9 8011 "menu bar on"
want F10 401 402 "toolbox (not the status bar)"; want F10 401 "toolbox back"
want shift+F10 403 "hide every panel"; want shift+F10 403 "show them again"
want 1 2502 501 "previous frame (not opacity 10%)"
want 2 2503 502 "next frame"
want 7 2565 507 "previous AnimBrush cel"
want 8 2566 508 "next AnimBrush cel"
want exclam 2501 "Shift+1 = first frame"
want at 2504 "Shift+2 = last frame"
want alt+a 2505 "animation panel"; want alt+a 2505 "animation panel off"
want l 2519 105 "LightTable = Lightbox (not Line)"; want l 2519 "Lightbox off"
fired i; [[ "$FIRED" != *"104"* ]] && pass "i (DRAW's picker key, taken by ,) fires nothing now [$FIRED ]" || fail "i still picks: [$FIRED ]"
fired k; [[ "$FIRED" != *"1702"* ]] && pass "k (DRAW's spray key) is free [$FIRED ]" || fail "k still sprays"
dk_park; dk_settle

# --- 2. U undo / Shift+U redo / no Ctrl+Z --------------------------------------------
read -r _ CVX CVY <<< "$(grep -m1 '^CVORG ' "$DK_DUMP")"
X1=$(( CVX + 40 )); Y1=$(( CVY + 40 ))
snap_region "$X1" "$Y1" 120 60 "dp-before"; B0=$SNAP_RESULT
key d; wait_for 0.2 "brush"
drag $(( X1 + 10 )) $(( Y1 + 30 )) $(( X1 + 110 )) $(( Y1 + 30 )); wait_for 0.5 "stroke"; dk_park; dk_settle
snap_region "$X1" "$Y1" 120 60 "dp-stroke"; B1=$SNAP_RESULT
assert_regions_differ "$B0" "$B1" "d + drag paints a stroke"
want u 301 "undo"; dk_park; wait_for 0.4 "undone"
snap_region "$X1" "$Y1" 120 60 "dp-undone"; assert_regions_same "$B0" "$SNAP_RESULT" "u undid the stroke"
want shift+u 302 "redo"; dk_park; wait_for 0.4 "redone"
snap_region "$X1" "$Y1" 120 60 "dp-redone"; assert_regions_same "$B1" "$SNAP_RESULT" "Shift+U redid it"
fired ctrl+z; [[ "$FIRED" != *"301"* ]] && pass "Ctrl+Z is not undo any more [$FIRED ]" || fail "Ctrl+Z still undoes"
dk_park; wait_for 0.3 "settle"
snap_region "$X1" "$Y1" 120 60 "dp-ctrlz"; assert_regions_same "$B1" "$SNAP_RESULT" "the stroke is still there after Ctrl+Z"

# --- 3. colors and the one-pixel brush -----------------------------------------------
dk_settle; kmap; F0=$KM_FG; G0=$KM_BG
want bracketright 521 602 "next FG colour (not brush size)"; dk_settle; kmap; F1=$KM_FG
want bracketleft 520 601 "previous FG colour"; dk_settle; kmap; F2=$KM_FG
(( F1 != F0 && F2 == F0 )) && pass "] / [ step the FG chip ($F0 -> $F1 -> $F2)" || fail "FG chip $F0 -> $F1 -> $F2"
# (the BG starts transparent: the first } puts it on a chip, the next steps it)
want braceright 523 427 "next BG colour (not the music)"; dk_settle; kmap; G1=$KM_BG
key braceright; wait_for 0.35 "}"; dk_settle; kmap; G2=$KM_BG
want braceleft 522 428 "previous BG colour"; dk_settle; kmap; G3=$KM_BG
(( G2 != G1 && G3 == G1 )) && pass "} / { step the BG chip ($G0 -> $G1 -> $G2 -> $G3)" || fail "BG chip $G0 -> $G1 -> $G2 -> $G3"
key equal; key equal; key equal; wait_for 0.3 "bigger"
want period 524 904 "one-pixel brush (not grid size)"; dk_settle; kmap
(( KM_BS == 1 && KM_CB == 0 )) && pass ". = the 1 px brush (size $KM_BS)" || fail ". left size $KM_BS custom $KM_CB"

# --- 4. b: the Brush Selector --------------------------------------------------------
want b 2598 "brush selector"; dk_settle; kmap
(( KM_SEL != 0 )) && pass "b arms the Brush Selector" || fail "Brush Selector not armed ($KM_SEL)"
drag $(( X1 + 2 )) $(( Y1 + 20 )) $(( X1 + 118 )) $(( Y1 + 40 )); wait_for 0.6 "box"; dk_park; dk_settle; kmap
read -r _ _ PTOOL <<< "$(grep -m1 '^PAINT ' "$DK_DUMP")"
(( KM_CB != 0 && KM_SEL == 0 && PTOOL == 1 )) && pass "the box became the brush, Brush tool in hand" || fail "after the box: custom $KM_CB armed $KM_SEL tool $PTOOL"
key x; wait_for 0.3 "flip the brush"; key x; wait_for 0.3 "back"
key u; wait_for 0.2 "-"
assert_no_crash
info "=== Deluxe Paint keymap: done ==="
