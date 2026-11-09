#!/bin/bash
# =============================================================================
# anim-panel-export.sh — QA test: export in the Animation panel (field kit
# T-17, Rick 2026-11-08: "the export scale is a strange design in the menu it
# doesn't tell me what scale it currently is - Can we simply add this to the
# Animation panel? I also had buttons there in the original design for GIF /
# APNG / BAS").
#
# The panel has a SCALE row (1X 2X 4X chips, the current one lit; sets
# CFG.ANIM_EXPORT_SCALE) and an EXPORT row (GIF APNG BAS: the ANIM > Export
# items, each opens its save dialog). The ANIM menu's item reads
# "EXPORT SCALE: 2X (1X / 2X / 4X)". The old build had neither row.
#
# Dump: ANIMP / ANIMPL (... yScale yExport exportScale at the end).
# Fixture: the 64x32 sheet of anim-panel.sh (16x16, 7 frames, current 3).
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Animation: export in the Animation panel ==="

AE_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
AE_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
AE_DIR="/tmp/draw-qa-animpexp-$$"
mkdir -p "$AE_DIR"
magick -size 64x32 xc:'#204060' -fill '#c04040' -draw 'rectangle 20,4 27,11' "$AE_DIR/plain.png"
AE_BLOB=$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,7,3,12,0,0).hex())")
python3 "$AE_PY" put "$AE_DIR/plain.png" "$AE_DIR/sheet.png" drAn "$AE_BLOB"

ae_settle() { { hover 300 250; wait_for 0.2 "render"; hover 305 252; wait_for 0.3 "render"; } >&2; }
ae_line() { grep -m1 "^$1 " "$AE_DUMP" 2>/dev/null; }
ae_read() {
    ae_settle
    read -r _ P_VIS P_DOCK P_X P_Y P_W P_H P_SC _ <<< "$(ae_line ANIMP)"
    read -r _ L_NAV L_R1 L_R2 L_R3 L_R4 L_R5 L_R6 L_LOOP L_RH L_MX L_PX L_CW L_PAD L_PW L_OPS L_MODE \
        L_ON L_O1 L_O2 L_O3 O_BEF O_AFT O_OPA L_YS L_YE E_SC _ <<< "$(ae_line ANIMPL)"
}
ae_vx() { echo $(( P_X + $1 * P_SC / 100 )); }
ae_vy() { echo $(( P_Y + $1 * P_SC / 100 )); }
ae_chip() { # NATIVE_ROW_Y K - click chip K (0-3) of a 4-chip row
    ae_read
    local span=$(( L_PW - 2 * L_PAD )); local cw=$(( (span - 6) / 4 ))
    click "$(ae_vx $(( L_PAD + $2 * (cw + 2) + cw / 2 )))" "$(ae_vy $(( $1 + L_RH / 2 )))"
    wait_for 0.5 "chip $2"
}

info "Launching DRAW with a 64x32 sheet of 16x16 frames"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$AE_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
park_mouse
key ctrl+0
wait_for 0.5 "Zoom 100%"
for try in 1 2; do
    park_mouse; key question; wait_for 1.0 "Command palette"
    type_text "animation panel"; wait_for 0.4 "Filtered"; key Return; wait_for 0.6 "Panel toggled"
    ae_read; [[ "$P_VIS" == -1 ]] && break
    key Escape; wait_for 0.3 "Escape"
done
ae_read
if [[ "$P_VIS" != -1 || -z "$L_MODE" ]]; then
    fail "the Animation panel did not open (visible=$P_VIS)"
else
    pass "panel open (export scale '${E_SC:-}')"
    # the export rows sit under the onion rows (the old build has none: aim where they would be)
    YS=${L_YS:-$(( L_O3 + L_RH + 6 ))}; YE=${L_YE:-$(( YS + L_RH + 2 ))}
    ae_chip "$YS" 2; ae_read
    [[ "$E_SC" == 2 ]] && pass "SCALE 2X chip: exports at 2x" || fail "SCALE 2X chip: export scale '${E_SC:-}', wanted 2"
    ae_chip "$YS" 3; ae_read
    [[ "$E_SC" == 4 ]] && pass "SCALE 4X chip: 4x" || fail "SCALE 4X chip: export scale '${E_SC:-}', wanted 4"
    screenshot "anim-panel-export"
    ae_chip "$YS" 1; ae_read
    [[ "$E_SC" == 1 ]] && pass "SCALE 1X chip: 1x" || fail "SCALE 1X chip: export scale '${E_SC:-}', wanted 1"

    # GIF opens the save dialog; Escape closes it
    park_mouse; wait_for 0.3 "park"
    snap_region 240 120 480 280 "anim-pexp-before" >/dev/null && cp "$SNAP_RESULT" "$AE_DIR/before.png"
    ae_chip "$YE" 1
    wait_for 1.5 "save dialog"
    snap_region 240 120 480 280 "anim-pexp-dialog" >/dev/null && cp "$SNAP_RESULT" "$AE_DIR/dialog.png"
    screenshot "anim-panel-export-dialog"
    assert_regions_differ "$AE_DIR/before.png" "$AE_DIR/dialog.png" "EXPORT GIF button: a save dialog opens"
    key Escape; wait_for 1.0 "dialog cancelled"
    park_mouse; wait_for 0.5 "park"
    assert_no_crash
    ae_read
    [[ "$P_VIS" == -1 ]] && pass "Escape closes the dialog, the panel is still there" || fail "after the GIF dialog: panel visible '$P_VIS'"
fi
assert_no_crash

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$AE_DIR"
assert_window_exists
