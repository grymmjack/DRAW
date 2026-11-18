#!/bin/bash
# =============================================================================
# sel-soft-move.sh — QA test: a soft (feathered) selection through the Move tool
# and paste (Rick 2026-11-18: "as soon as i make a selection with these settings and
# go to [move] with V it makes it show transparency behind it in a rectangle" / "same
# is true for any selection tool when i paste too" / "when i hit ctrl d it looks right").
#   1. FEATHER 6 rectangle on a filled layer, V, dragged right: the live preview of the
#      hole it leaves is exactly what Ctrl+D commits (it used to clear the whole box)
#   2. the same selection copied, pasted onto a new empty layer over the fill, Ctrl+D:
#      the area is still one colour - the soft rim lands as the fill's colour (QB64's
#      _BLEND turned it grey over the empty layer)
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE SELECTION_FEATHER=0 SELECTION_MODE=REPLACE SELECTION_BAR=TRUE ANTIALIAS=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"

ROW_H=14
sbc() { C_ID=""; read -r _ C_ID C_X C_Y C_W C_TX _ <<< "$(grep -m1 "^SELBARC $1 " "$DK_DUMP")"; [[ -n "$C_ID" ]]; }
sb_track() { if sbc "$1"; then click $(( C_TX + $2 )) $(( C_Y + ROW_H / 2 )); wait_for 0.4 "$3"; dk_park; dk_settle; else fail "no slider $1 ($3)"; fi; }
feather() { read -r _ _ _ _ _ _ _ _ F _ <<< "$(grep -m1 '^SELBAR ' "$DK_DUMP")"; echo "$F"; }
colours() { magick "$1" -format '%k' info: 2>/dev/null; }
ae() { magick compare -metric AE "$1" "$2" null: 2>&1 | awk '$1 ~ /^[0-9.]+$/ {print int($1); exit} {print "ERR"; exit}'; }
select_rect() { key m; wait_for 0.5 "marquee"; drag $(( CANVAS_CX - 40 )) $(( CANVAS_CY - 20 )) $(( CANVAS_CX + 40 )) $(( CANVAS_CY + 20 )); wait_for 0.5 "selection"; }
# the hole's left part: left of where the moved float's soft edge starts (moved 50 px)
hole() { park_mouse; wait_for 0.4 "settle"; snap_region $(( CANVAS_CX - 52 )) $(( CANVAS_CY - 30 )) 46 60 "$1"; }

info "=== Soft selection through Move and paste ==="
dk_begin
canvas_focus f
wait_for 0.3 "fill tool"
click $(( CANVAS_CX - 60 )) $(( CANVAS_CY - 50 )); wait_for 0.5 "filled"
park_mouse; wait_for 0.3 "settle"
snap_region $(( CANVAS_CX - 70 )) $(( CANVAS_CY - 40 )) 140 80 "filled"; FILLED="$SNAP_RESULT"

key m; wait_for 0.6 "marquee"; dk_park; dk_settle
sb_track 5 4 "feather ~6"
F=$(feather); (( F >= 4 && F <= 8 )) && pass "FEATHER set ($F)" || fail "FEATHER $F"

# --- 1. Move: the preview's hole = the committed hole ----------------------------------
select_rect
key v; wait_for 0.5 "move tool"
dk_drag "$CANVAS_CX" "$CANVAS_CY" $(( CANVAS_CX + 50 )) "$CANVAS_CY" 6
wait_for 0.5 "dragged"
hole "mv-preview"; PRE="$SNAP_RESULT"
screenshot "sel-soft-move-preview"
N=$(colours "$PRE")
(( N > 2 )) && pass "the preview's hole is soft ($N colours)" || fail "the preview's hole has $N colours (a hard box?)"
key ctrl+d; wait_for 0.8 "commit"
hole "mv-commit"; POST="$SNAP_RESULT"
D=$(ae "$PRE" "$POST")
[[ "$D" == 0 ]] && pass "the Move preview shows exactly what Ctrl+D commits" || fail "preview vs commit: $D px differ (the box cleared in the preview?)"
# Ctrl+D's deselect is its own undo step: Ctrl+Z twice (the deselect, the move)
key ctrl+z; wait_for 0.6 "undo the deselect"; key ctrl+z; wait_for 0.8 "undo the move"
key ctrl+d; wait_for 0.4 "deselect"; park_mouse; wait_for 0.3 "settle"
snap_region $(( CANVAS_CX - 70 )) $(( CANVAS_CY - 40 )) 140 80 "undone"
D=$(ae "$FILLED" "$SNAP_RESULT")
[[ "$D" == 0 ]] && pass "undo puts the fill back exactly" || fail "after undo: $D px differ from the fill"

# --- 2. paste a soft copy onto an empty layer over the fill: one colour ----------------------
key m; wait_for 0.5 "marquee"
select_rect
key ctrl+c; wait_for 0.6 "copy"
key ctrl+d; wait_for 0.4 "deselect"
key ctrl+shift+n; wait_for 0.8 "new layer"
park_mouse
key ctrl+v; wait_for 1.0 "paste"
park_mouse; wait_for 0.4 "settle"
screenshot "sel-soft-paste-float"
key ctrl+d; wait_for 0.8 "commit the paste"
park_mouse; wait_for 0.4 "settle"
snap_region $(( CANVAS_CX - 70 )) $(( CANVAS_CY - 40 )) 140 80 "paste-commit"
N=$(colours "$SNAP_RESULT")
(( N == 1 )) && pass "a soft paste over the same colour leaves one colour (no grey rim)" || fail "a soft paste over the fill shows $N colours (a grey rim?)"
screenshot "sel-soft-paste-commit"
assert_no_crash
