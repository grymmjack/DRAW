#!/bin/bash
# =============================================================================
# swatches-copy-names.sh — QA test: the copy an edit makes goes to My Swatches
# under the set's name, never over a file that is there already; editing the
# Document Palette set makes a copy too and leaves the palette strip alone.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt SWATCHES_VISIBLE=1 SWATCHES_X=-1 SWATCHES_Y=-1 SWATCHES_W=0 SWATCHES_H=0 SWATCHES_SCALE=0 SWATCHES_SET=QA/fixtures/swatches-edit.gpl SWATCHES_COLS=0 SWATCHES_CELL=10 SWATCHES_GAP=1 SWATCHES_STRETCH=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
source "$DRAW_ROOT/QA/swatches-lib.sh"

info "=== Swatches: the copies an edit makes ==="
sw_isolate
# a "QA Edit.gpl" is in My Swatches already: the copy must not replace it
mkdir -p "$SW_MINE"
printf 'GIMP Palette\nName: Keep Me\n#\n  1   2   3\tOne\n' > "$SW_MINE/QA Edit.gpl"
SUMK=$(md5sum < "$SW_MINE/QA Edit.gpl")
sw_quit_wait; draw_launch 15; wait_for 1.0 "relaunched"
dk_begin
sw_click 1; sw_hover_panel; key Delete; dk_settle; sw_read
sw_expect "Del: entries" "$SW_N" 20
if [[ "$SW_KEY" == *"/SWATCHES/QA Edit (1).gpl" ]]; then pass "the copy is 'QA Edit (1).gpl'"; else fail "the copy is $SW_KEY"; fi
if [[ "$(md5sum < "$SW_MINE/QA Edit.gpl")" == "$SUMK" ]]; then pass "the file already there is untouched"; else fail "QA Edit.gpl was overwritten"; fi
# a second edit saves into the same copy (no third file)
sw_click 1; sw_hover_panel; key Delete; dk_settle; sw_read
sw_expect "second Del: entries" "$SW_N" 19
N=$(command ls "$SW_MINE" | grep -c '^QA Edit')
sw_expect "files named QA Edit*" "$N" 2

# the Document Palette set: an edit makes a copy, the strip keeps its colors
sw_geo; click $(( B_X + B_W / 2 )) $(( B_Y + B_H / 2 )); dk_settle
R=$(awk '$1=="SWATMI" && $4==100 {print; exit}' "$DK_DUMP")
read -r _ _ _ _ _ MX MY MW MH _ <<< "$R"
if [[ -z "$MX" ]]; then fail "no Document Palette row in the set list"; else
    click $(( MX + MW / 2 )) $(( MY + MH / 2 )); dk_settle; sw_read
    sw_expect "the document palette is showing" "$SW_KEY" ""
    P0=$SW_N
    sw_edit_state; sw_expect "the document palette is not in My Swatches" "$SE_MINE" 0
    sw_click 1; sw_hover_panel; key Delete; dk_settle; sw_read; sw_edit_state
    sw_expect "Del in the document palette set: entries" "$SW_N" $(( P0 - 1 ))
    sw_expect "now a copy in My Swatches" "$SE_MINE" 1
    if [[ "$SW_KEY" == *"/SWATCHES/"*.gpl ]]; then pass "the palette copy: $(basename "$SW_KEY")"; else fail "palette copy key: $SW_KEY"; fi
    # back to the document palette: still every color
    click $(( B_X + B_W / 2 )) $(( B_Y + B_H / 2 )); dk_settle
    R=$(awk '$1=="SWATMI" && $4==100 {print; exit}' "$DK_DUMP"); read -r _ _ _ _ _ MX MY MW MH _ <<< "$R"
    click $(( MX + MW / 2 )) $(( MY + MH / 2 )); dk_settle; sw_read
    sw_expect "the document palette still has every color" "$SW_N" "$P0"
fi
assert_window_exists
info "=== Swatches: the copies an edit makes PASSED ==="
