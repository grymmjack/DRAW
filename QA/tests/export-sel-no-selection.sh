#!/bin/bash
# =============================================================================
# export-sel-no-selection.sh — QA test: the Export Selection toolbox button
# with nothing selected lets you make the selection, then exports it
# (BUGS.md 2026-11-15)
#
# It used to stop with an alert ("No selection to export"). Now it picks the
# rectangle marquee and waits; the next selection made opens the export dialog.
#
# Fixture: a 320x200 red PNG. A 50x30 (canvas px) box is dragged after the
# click; the exported PNG must be 50x30 (give or take the inclusive edge).
# Dump: VIEW zoom offX offY tool | CVORG x y | BTN toolbox i kind id name x y w h
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Export Selection with no selection ==="
EX_DIR="$(mktemp -d /tmp/draw-qa-exsel-XXXXXX)"
magick -size 320x200 xc:'#c00000' "PNG32:$EX_DIR/red.png"
draw_quit; draw_settle
DRAW_EXTRA_ARGS="$EX_DIR/red.png"
draw_launch 15; wait_for 1.5 "loaded"
assert_no_crash
dk_begin
read -r _ Z _ _ _ <<< "$(grep -m1 '^VIEW ' "$DK_DUMP")"
read -r _ OX OY <<< "$(grep -m1 '^CVORG ' "$DK_DUMP")"
sx() { echo $(( OX + $1 * Z / 100 )); }
sy() { echo $(( OY + $1 * Z / 100 )); }
read -r BX BY <<< "$(awk '$1=="BTN" && $2=="toolbox" && $6=="export-sel" {print $7+int($9/2)" "$8+int($10/2); exit}' "$DK_DUMP")"
[[ -n "$BY" ]] || fail "no export-sel button in the toolbox dump"
key b; wait_for 0.3 "brush tool"

click "$BX" "$BY"; wait_for 0.8 "export with nothing selected"
dk_park; dk_settle
read -r _ _ _ _ TOOL <<< "$(grep -m1 '^VIEW ' "$DK_DUMP")"
(( TOOL == 5 )) && pass "with no selection the button picks the marquee (tool $TOOL)" || fail "tool $TOOL after the click (want the marquee, 5) - an alert?"
screenshot "export-sel-armed"

drag "$(sx 100)" "$(sy 60)" "$(sx 150)" "$(sy 90)"; wait_for 1.5 "select -> the export dialog"
screenshot "export-sel-dialog"
type_text "$EX_DIR/part.png"; sleep 0.3
key Return; wait_for 1.5 "export"
if [[ -f "$EX_DIR/part.png" ]]; then
    read -r PW PH <<< "$(magick identify -format '%w %h' "$EX_DIR/part.png" 2>/dev/null)"
    (( PW >= 49 && PW <= 51 && PH >= 29 && PH <= 31 )) && pass "the selection made after the click was exported (${PW}x$PH)" || fail "exported ${PW}x$PH, want 50x30"
else
    fail "nothing exported to $EX_DIR/part.png"
    ls "$EX_DIR" >&2
fi

# Esc while it waits: no export
key Escape; wait_for 0.3 "esc"; key ctrl+d; wait_for 0.3 "deselect"
click "$BX" "$BY"; wait_for 0.8 "arm again"
key Escape; wait_for 0.4 "cancel"
drag "$(sx 20)" "$(sy 20)" "$(sx 60)" "$(sy 50)"; wait_for 1.2 "a selection after Esc"
type_text "$EX_DIR/after-esc.png"; key Return; wait_for 1.0 "(nothing should take it)"
[[ ! -f "$EX_DIR/after-esc.png" ]] && pass "Esc ends the wait: the next selection is not exported" || fail "exported after Esc"
assert_no_crash
rm -rf "$EX_DIR"
