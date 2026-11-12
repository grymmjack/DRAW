#!/bin/bash
# =============================================================================
# workspace-sprite-scene.sh - QA test: the Sprite and Scene workspaces
# (ASSETS/WORKSPACES, PLANS/PERSONAS.md) and [MENUS] ROOTS= knowing ANIM.
#
#  Sprite: Preview + Animation panel + Drawer shown, char map / Swatches
#          hidden, no EFFECTS / AUDIO menus, lightbox and onion skin off,
#          frame grid + Preview Shows Frame on, Brush tool
#  Scene:  Animation panel + Drawer shown, Big Frame + X-sheet (lightbox,
#          1 pane, X-sheet), onion skin off, Move tool, every menu
#  Default again: all of it back
#  ROOTS=ANIM: a workspace keeping only the ANIM menu is no longer ignored
#  (it was "names no menu" before ANIM joined WS_apply_menus' list).
#
# Dump lines: WF ... active | P name shown ... | MROOT label x w |
# ANIMMENUX id:checked:enabled (2500 grid, 2507 preview frame, 2519 lightbox,
# 2527 onion, 2540 X-sheet, 2593 big frame) | PAINT opacity tool.
# The workspaces' [OPTIONS] are not pinned here: --option (QA-OPTIONS) beats them.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt WORKSPACES_DIR=/tmp/draw-qa-ws-roots
# =============================================================================
info "=== Workspaces: Sprite, Scene, ROOTS=ANIM ==="

SS_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
SS_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
SS_DIR="/tmp/draw-qa-ws-sprite-$$"
WS_DIR="/tmp/draw-qa-ws-roots"
mkdir -p "$SS_DIR" "$WS_DIR"
rm -f "$WS_DIR"/*.workspace
cat > "$WS_DIR/animonly.workspace" <<'EOF'
[WORKSPACE]
NAME=AnimOnly
BASED_ON=default

[MENUS]
ROOTS=ANIM
EOF
magick -size 64x32 xc:'#204060' -fill '#c04040' -draw 'rectangle 20,4 27,11' "$SS_DIR/plain.png"
python3 "$SS_PY" put "$SS_DIR/plain.png" "$SS_DIR/sheet.png" drAn "$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,7,3,12,0,0).hex())")"

ss_settle() { { hover 300 250; wait_for 0.2 "render"; hover 305 252; wait_for 0.3 "render"; } >&2; }
ss_line() { grep -m1 "^$1" "$SS_DUMP" 2>/dev/null; }
ss_read() {
    ss_settle
    SS_ACT=$(ss_line 'WF ' | awk '{print $8}')
    SS_ROOTS=$(grep '^MROOT ' "$SS_DUMP" | awk '{print $2}' | paste -sd, -)
    SS_MENU=" $(ss_line 'ANIMMENUX') "
    SS_TOOL=$(ss_line 'PAINT ' | awk '{print $3}')
}
ss_panel() { grep -m1 "^P $1 " "$SS_DUMP" | awk '{print $3}'; } # shown -1 / 0
ss_chk() { echo "$SS_MENU" | grep -o " $1:[^: ]*" | head -1 | cut -d: -f2; } # checked -1 / 0
ss_s() { echo "active ${SS_ACT:-?} roots [$SS_ROOTS] tool ${SS_TOOL:-?} lightbox $(ss_chk 2519) onion $(ss_chk 2527) xsheet $(ss_chk 2540) big $(ss_chk 2593) grid $(ss_chk 2500) pvframe $(ss_chk 2507)"; }
ss_switch() {
    park_mouse; key ctrl+shift+w; wait_for 0.8 "switcher open"
    type_text "$1"; wait_for 0.6 "filtered"
    key Return; wait_for 1.5 "workspace applied"
    ss_read
}
has() { [[ ",$1," == *",$2,"* ]]; }

info "Launching DRAW with a 64x32 sheet of 16x16 frames"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$SS_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
ss_read
info "Default: $(ss_s)"
D_LB=$(ss_chk 2519); D_ON=$(ss_chk 2527); D_XS=$(ss_chk 2540); D_ROOTS=$SS_ROOTS

ss_switch sprite
info "Sprite: $(ss_s)"
[[ "$SS_ACT" == sprite ]] && pass "switched to Sprite" || fail "active '$SS_ACT'"
[[ "$(ss_panel preview)" == -1 && "$(ss_panel animation)" == -1 && "$(ss_panel drawer)" == -1 ]] \
    && pass "Sprite shows the Preview, the Animation panel and the Drawer" || fail "panels: preview $(ss_panel preview) animation $(ss_panel animation) drawer $(ss_panel drawer)"
[[ "$(ss_panel charmap)" == 0 && "$(ss_panel swatches)" == 0 ]] && pass "Sprite hides the char map and Swatches" || fail "charmap $(ss_panel charmap) swatches $(ss_panel swatches)"
has "$SS_ROOTS" anim && ! has "$SS_ROOTS" effects && ! has "$SS_ROOTS" audio \
    && pass "Sprite's menus: ANIM kept, EFFECTS / AUDIO gone" || fail "roots [$SS_ROOTS]"
[[ "$(ss_chk 2519)" == 0 && "$(ss_chk 2527)" == 0 && "$(ss_chk 2500)" == -1 && "$(ss_chk 2507)" == -1 ]] \
    && pass "Sprite: sheet view (no lightbox), no onion skin, frame grid, Preview shows the frame" || fail "Sprite options: $(ss_s)"
[[ "$SS_TOOL" == 1 ]] && pass "Sprite starts on the Brush" || fail "tool '$SS_TOOL', wanted 1 (brush)"
screenshot "workspace-sprite"

ss_switch scene
info "Scene: $(ss_s)"
[[ "$SS_ACT" == scene ]] && pass "switched to Scene" || fail "active '$SS_ACT'"
[[ "$(ss_panel animation)" == -1 && "$(ss_panel drawer)" == -1 && "$(ss_panel layers)" == -1 ]] \
    && pass "Scene shows the Animation panel, the Drawer and the layers" || fail "panels: animation $(ss_panel animation) drawer $(ss_panel drawer) layers $(ss_panel layers)"
[[ "$(ss_chk 2593)" == -1 && "$(ss_chk 2540)" == -1 && "$(ss_chk 2527)" == 0 ]] \
    && pass "Scene: Big Frame + X-sheet, no onion skin" || fail "Scene options: $(ss_s)"
has "$SS_ROOTS" effects && has "$SS_ROOTS" anim && pass "Scene keeps every menu" || fail "roots [$SS_ROOTS]"
[[ "$SS_TOOL" == 34 ]] && pass "Scene starts on the Move tool" || fail "tool '$SS_TOOL', wanted 34 (move)"
screenshot "workspace-scene"

ss_switch def
info "Default again: $(ss_s)"
[[ "$SS_ACT" == default ]] && pass "back to Default" || fail "active '$SS_ACT'"
[[ "$(ss_chk 2519)" == "$D_LB" && "$(ss_chk 2527)" == "$D_ON" && "$(ss_chk 2540)" == "$D_XS" && "$SS_ROOTS" == "$D_ROOTS" ]] \
    && pass "Default gets its lightbox / onion / X-sheet / menus back" || fail "after Default: $(ss_s) (was lightbox $D_LB onion $D_ON xsheet $D_XS roots [$D_ROOTS])"

ss_switch animonly
info "AnimOnly: $(ss_s)"
[[ "$SS_ACT" == animonly && "$SS_ROOTS" == anim ]] && pass "ROOTS=ANIM keeps only the ANIM menu" || fail "AnimOnly: active '$SS_ACT' roots [$SS_ROOTS]"
ss_switch def

rm -rf "$SS_DIR"
assert_no_crash
assert_window_exists
info "=== Workspaces: Sprite, Scene, ROOTS=ANIM done ==="
