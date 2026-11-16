#!/bin/bash
# =============================================================================
# swatches-from-image.sh — QA test: new swatch sets from the image and Lospec.
#   ☰ → NEW SET FROM IMAGE on an empty canvas makes no set ("no colors")
#   two dots painted (red, then green lower down) → a set in My Swatches with
#     those two colors, in reading order
#   with a marquee around the green dot the item reads NEW SET FROM SELECTION
#     and the set has only the green
#   ☰ → LOSPEC... opens the Lospec dialog; a palette that lands in the
#     palettes folder while it is open (a download - faked here, no network)
#     becomes a set when it closes; closing with nothing new changes nothing
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt SWATCHES_VISIBLE=1 SWATCHES_X=-1 SWATCHES_Y=-1 SWATCHES_W=0 SWATCHES_H=0 SWATCHES_SCALE=0 SWATCHES_COLS=0 SWATCHES_CELL=10 SWATCHES_GAP=1 SWATCHES_STRETCH=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
source "$DRAW_ROOT/QA/swatches-lib.sh"
colors_only() { tr ' ' '\n' | grep -v '^[-|]$' | tr '\n' ' ' | sed 's/ $//'; }

info "=== Swatches: new sets from the image and Lospec ==="
sw_isolate SWATCHES_SET=QA/fixtures/swatches-edit.gpl
dk_begin
sw_read; K0=$SW_KEY

sw_menu_edit; sw_menu_click 219; sw_read
sw_expect "no selection: the item reads" "$SM_LABEL" "NEW SET FROM IMAGE"
sw_expect "empty canvas: no new set" "$SW_KEY" "$K0"

# two dots: red (3C0000) up-left, green (003C00) down-right
RX=$(( CANVAS_CX - 30 )); RY=$(( CANVAS_CY - 20 )); GX=$(( CANVAS_CX + 30 )); GY=$(( CANVAS_CY + 20 ))
sw_click 1; key b; dk_settle; click "$RX" "$RY"; dk_settle
sw_click 9; key b; dk_settle; click "$GX" "$GY"; dk_settle; dk_park; dk_settle
screenshot "swatches-image-dots"
sw_menu_edit; sw_menu_click 219; sw_read
if [[ "$SW_KEY" == "$SW_MINE"/*.gpl ]]; then pass "NEW SET FROM IMAGE: a set in My Swatches ($(basename "$SW_KEY"))"; else fail "NEW SET FROM IMAGE: the set is $SW_KEY"; fi
sw_expect "... the two colors in reading order" "$(sw_hexes | colors_only)" "3C0000 003C00"
[[ "$(basename "$SW_KEY")" == *colors*.gpl ]] && pass "... named for the image's colors" || fail "name $(basename "$SW_KEY")"
KIMG=$SW_KEY

# a marquee around the green dot
key m; dk_settle
mouse_down $(( GX - 12 )) $(( GY - 12 )); sleep 0.15; hover "$GX" "$GY"; sleep 0.1; hover $(( GX + 12 )) $(( GY + 12 )); sleep 0.15; mouse_up; dk_settle; dk_park; dk_settle
sw_menu_edit; sw_menu_click 219; sw_read
sw_expect "with a selection the item reads" "$SM_LABEL" "NEW SET FROM SELECTION"
if [[ "$SW_KEY" == "$SW_MINE"/*selection*.gpl ]]; then pass "with a selection: a 'selection' set ($(basename "$SW_KEY"))"; else fail "with a selection: the set is $SW_KEY"; fi
sw_expect "... only the green" "$(sw_hexes | colors_only)" "003C00"
key Escape; dk_settle

# Lospec: a palette downloaded while the dialog is open becomes a set
PALS="$XDG_DATA_HOME/DRAW/PALETTES"
sw_menu_edit; sw_menu_click 223; wait_for 1.5 "the Lospec dialog"
screenshot "swatches-lospec-dialog"
mkdir -p "$PALS"
printf 'GIMP Palette\nName: QA Lospec\nColumns: 4\n#\n 17  34  51 a\n 68  85 102 b\n119 136 153 c\n170 187 204 d\n' > "$PALS/QA Lospec (4).gpl"
key Escape; wait_for 1.2 "closed"; dk_settle; sw_read
sw_expect "LOSPEC: the download became a set" "$SW_KEY" "$SW_MINE/QA Lospec (4).gpl"
sw_expect "... with its colors" "$(sw_hexes | colors_only)" "112233 445566 778899 AABBCC"
K1=$SW_KEY
sw_menu_edit; sw_menu_click 223; wait_for 1.5 "the Lospec dialog again"
key Escape; wait_for 1.2 "closed"; dk_settle; sw_read
sw_expect "LOSPEC with nothing new: the set unchanged" "$SW_KEY" "$K1"
if [[ -f "$PALS/QA Lospec (4).gpl" ]]; then pass "the downloaded palette stays a palette too"; else fail "the palette file is gone"; fi
screenshot "swatches-from-image-end"
assert_window_exists
info "=== Swatches: new sets from the image and Lospec PASSED ==="
