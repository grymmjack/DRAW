#!/bin/bash
# =============================================================================
# swatches-row-frames.sh — QA test: Swatches docked in a top row keep the FG
# frame's top line on the first row of chips (Rick 2026-11-16: "they are
# clipping the borders of the swatch chip"). The FG frame sits 1 px outside the
# cell, in the grid's 1 px margin: its top row of pixels (y - 1) is the
# frame's bright colour, not the grid background.
# Dump: SWATC i x y w h kind RRGGBB flags; SWATG grid rect
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt SWATCHES_VISIBLE=1 SWATCHES_RECENT=1 TOOLTIPS_DISABLED=TRUE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Swatches in a row: chip frames ==="
dk_begin
dk_move swatches band-top
dk_p swatches; dk_slot "$P_SLOT"; dk_col "$S_COL"
(( C_SIDE == 3 )) && pass "Swatches in a top row (h $C_H)" || fail "Swatches not in a top row [$(dk_tree)]"
read -r _ CI CX CY CW CH _ <<< "$(awk '$1=="SWATC" && $7==0 {print; exit}' "$DK_DUMP")"
[[ -n "$CY" ]] || read -r _ CI CX CY CW CH _ <<< "$(grep -m1 '^SWATC' "$DK_DUMP")"
info "first chip $CI at $CX,$CY ${CW}x$CH"
click $(( CX + CW / 2 )) $(( CY + CH / 2 )); dk_park; dk_settle
read -r _ CI CX CY CW CH _ <<< "$(awk -v i="$CI" '$1=="SWATC" && $2==i {print; exit}' "$DK_DUMP")"
snap_region $(( CX - 2 )) $(( CY - 2 )) $(( CW + 4 )) $(( CH + 4 )) "swatch-fg-frame"
# the frame's top line: viewport y CY-1 -> the screen at 2x; sample its middle
TOP=$(magick "$SNAP_RESULT" -format "%[hex:p{$(( CW + 4 )),2}]" info: 2>/dev/null)
BOT=$(magick "$SNAP_RESULT" -format "%[hex:p{$(( CW + 4 )),$(( (CH + 2) * 2 ))}]" info: 2>/dev/null)
screenshot "swatches-row-frames"
info "frame pixels: top $TOP, bottom $BOT"
[[ -n "$TOP" && "${TOP:0:6}" == "${BOT:0:6}" && "${TOP:0:6}" != "1E1E1E" ]] && pass "the FG frame has its top line ($TOP, as its bottom)" || fail "the FG frame's top ($TOP) differs from its bottom ($BOT): clipped"
assert_window_exists
info "=== Swatches in a row: done ==="
