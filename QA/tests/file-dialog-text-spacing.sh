#!/bin/bash
# =============================================================================
# file-dialog-text-spacing.sh — QA test: the file dialog's one-line text boxes
# draw their text at the font's real letter widths.
#
# Regression (QB64_GJ_LIB 25eab67, "one-line text stays inside its box"): the
# one-line renderer placed each glyph with TI__px_width%, which measured fixed
# fontW cells unless the widget was marked proportional. The file dialog's path
# and FILENAME boxes have their own TTF font but are not marked, so every letter
# got a cell as wide as the widest glyph: "DRAW-TEST" drew as "D R A W - T E S T".
#
# Check: in Save As, type 16 narrow letters (i), then 16 wide ones (M), and
# measure how wide each run is drawn (the bounding box of what changed against
# the empty field). Real widths: the i run is far narrower. Fixed cells: both
# runs are the same width.
# =============================================================================
info "=== File dialog: text at real letter widths ==="

FS_T="$(mktemp -d /tmp/draw-qa-fdspace-XXXXXX)"

fs_width() { # A.png B.png -> width of the box around the pixels that differ
    magick "$1" "$2" -compose difference -composite -colorspace gray -threshold 8% \
        -format '%@' info: 2>/dev/null | sed -E 's/^([0-9]+)x.*/\1/'
}
fs_geom() { magick "$1" "$2" -compose difference -composite -colorspace gray -threshold 8% -format '%@' info: 2>/dev/null; }
fs_clear() { local i; for i in $(seq 1 40); do key BackSpace; done; wait_for 0.3 "field cleared"; }

wake_draw
key ctrl+shift+s
wait_for 1.2 "Save As dialog open"
assert_no_crash
screenshot "fdspace-dialog"

fs_clear
park_mouse
snap_region 0 0 "$VIEWPORT_W" "$VIEWPORT_H" "fdspace-empty"; cp "$SNAP_RESULT" "$FS_T/empty.png"

type_text "iiiiiiiiiiiiiiii"
wait_for 0.3 "16 i typed"
snap_region 0 0 "$VIEWPORT_W" "$VIEWPORT_H" "fdspace-i"; cp "$SNAP_RESULT" "$FS_T/i.png"

fs_clear
type_text "MMMMMMMMMMMMMMMM"
wait_for 0.3 "16 M typed"
snap_region 0 0 "$VIEWPORT_W" "$VIEWPORT_H" "fdspace-m"; cp "$SNAP_RESULT" "$FS_T/m.png"
screenshot "fdspace-typed"

FS_WI=$(fs_width "$FS_T/empty.png" "$FS_T/i.png")
FS_WM=$(fs_width "$FS_T/empty.png" "$FS_T/m.png")
info "16 i drawn $(fs_geom "$FS_T/empty.png" "$FS_T/i.png"), 16 M drawn $(fs_geom "$FS_T/empty.png" "$FS_T/m.png")"

if [[ "$FS_WI" =~ ^[0-9]+$ && "$FS_WM" =~ ^[0-9]+$ && "$FS_WM" -gt 20 ]] && (( FS_WI * 100 < FS_WM * 60 )); then
    pass "FILENAME box: 16 i are drawn ${FS_WI}px wide, 16 M ${FS_WM}px - real letter widths"
else
    fail "FILENAME box: 16 i drawn '${FS_WI}'px, 16 M '${FS_WM}'px - letters on fixed cells (spread out)"
fi

key Escape
wait_for 0.5 "dialog closed"
assert_no_crash
rm -rf "$FS_T"
assert_window_exists
