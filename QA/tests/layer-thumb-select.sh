#!/bin/bash
# =============================================================================
# layer-thumb-select.sh — QA test: selections from layer thumbnails (Rick,
# 2026-11-14: "Ctrl+click = selection from layer; Ctrl+Shift+click = add;
# Ctrl+Shift+click a layer already in = remove").
#
# Ctrl+click a layer's thumbnail: the selection is that layer's pixels (the
# current layer does not change). Ctrl+Shift+click another layer's thumbnail:
# its pixels are added. Ctrl+Shift+click a layer already in: its pixels are
# taken out again - but where another layer in the selection has pixels too,
# they stay selected. Ctrl+Shift+click elsewhere on the panel still swaps its
# dock side; Ctrl+click on a name still toggles the layer in the multi-select.
#
# Fixture: a 128x128 transparent canvas, an 8x8 red square at (100,10) = the
# bottom layer (row 1); a new layer on top (row 0) with a brush dot INSIDE the
# square, so the two overlap.
# Dump: LPSEL active x y w h pixels layers; LPTHUMB x size; LPGEO; LPANEL; VIEW.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE LAYER_THUMBNAILS=SMALL
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Layers: selections from thumbnails ==="

TS_DIR="/tmp/draw-qa-thumbsel-$$"
mkdir -p "$TS_DIR"
magick -size 128x128 xc:none -fill '#e02020' -draw 'rectangle 100,10 107,17' "PNG32:$TS_DIR/red.png"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$TS_DIR/red.png"
draw_launch 15
wait_for 1.5 "red.png loaded"
dk_begin

geo() { read -r _ G_HDR G_ROW G_BAR <<< "$(grep -m1 '^LPGEO ' "$DK_DUMP")"; }
thumb() { read -r _ T_X T_SZ <<< "$(grep -m1 '^LPTHUMB ' "$DK_DUMP")"; }
sel() { read -r _ S_ON S_X S_Y S_W S_H S_N S_FROM <<< "$(grep -m1 '^LPSEL ' "$DK_DUMP")"; }
cur() { awk '$1=="LPANEL" {print $3; exit}' "$DK_DUMP"; }
multi() { awk '$1=="LPANEL" {print $4; exit}' "$DK_DUMP"; }
# ROW -> TX TY: the middle of that row's thumbnail
at_thumb() { TX=$(( T_X + T_SZ / 2 )); TY=$(( P_Y + G_HDR + G_ROW * $1 + G_ROW / 2 )); }
settle_click() { wait_for 0.6 "$1"; dk_park; dk_settle; }

park_mouse; key ctrl+shift+n; wait_for 0.6 "a layer on top"; dk_settle
TOPL=$(cur)
# a dot inside the red square, on the new (top) layer
read -r _ VZ _ <<< "$(grep -m1 '^VIEW ' "$DK_DUMP")"; read -r _ VOX VOY <<< "$(grep -m1 '^CVORG ' "$DK_DUMP")"
DX=$(( VOX + 103 * VZ / 100 + VZ / 200 )); DY=$(( VOY + 13 * VZ / 100 + VZ / 200 ))
key b; wait_for 0.3 "Brush"
click "$DX" "$DY"; wait_for 0.6 "a dot"; dk_park; dk_settle
dk_p layers || fail "no layers panel in the dump"
geo; thumb
info "rows ${G_ROW}px, thumbnail ${T_SZ}px at x $T_X; top layer $TOPL; dot at ($DX,$DY)"
(( T_SZ == 32 )) || fail "thumbnails not SMALL ($T_SZ)"
BOTL=$(awk -v t="$TOPL" '$1=="LAYER" && $2!=t {print $2; exit}' "$DK_DUMP")
PX0=$P_X

# --- Ctrl+click the bottom layer's thumbnail: its 8x8 square ----------------
at_thumb 1; ctrl_click "$TX" "$TY"; settle_click "ctrl+click the bottom thumbnail"; sel
[[ "$S_ON" == -1 && "$S_N" == 64 && "$S_FROM" == "$BOTL" ]] && pass "Ctrl+click: the selection is the bottom layer's 64 px ($S_X,$S_Y ${S_W}x$S_H)" || fail "Ctrl+click bottom: LPSEL '$(grep '^LPSEL ' "$DK_DUMP")'"
[[ "$(cur)" == "$TOPL" ]] && pass "Ctrl+click: the current layer stays $TOPL" || fail "Ctrl+click: current layer $(cur), was $TOPL"
[[ "$(multi)" -le 1 ]] && pass "Ctrl+click on a thumbnail: no multi-select" || fail "Ctrl+click on a thumbnail multi-selected ($(multi))"

# --- Ctrl+click the top layer's thumbnail: the dot ---------------------------
at_thumb 0; ctrl_click "$TX" "$TY"; settle_click "ctrl+click the top thumbnail"; sel
DOTN=$S_N
(( S_ON == -1 && DOTN > 0 && DOTN < 64 )) && [[ "$S_FROM" == "$TOPL" ]] && pass "Ctrl+click: the top layer's dot ($DOTN px)" || fail "Ctrl+click top: LPSEL '$(grep '^LPSEL ' "$DK_DUMP")'"

# --- Ctrl+Shift+click the bottom one: added ----------------------------------
at_thumb 1; ctrl_shift_click "$TX" "$TY"; settle_click "ctrl+shift+click the bottom thumbnail"; sel
[[ "$S_N" == 64 && "$S_FROM" == "$(echo -e "$BOTL\n$TOPL" | sort -n | paste -sd,)" ]] && pass "Ctrl+Shift+click: the square added (64 px, the dot inside it; layers $S_FROM)" || fail "add: LPSEL '$(grep '^LPSEL ' "$DK_DUMP")'"
dk_p layers
[[ "$P_X" == "$PX0" ]] && pass "Ctrl+Shift+click on a thumbnail: the panel kept its side" || fail "the panel moved ($PX0 -> $P_X): the dock-side swap fired"

# --- Ctrl+Shift+click the bottom one again: out, the dot (top layer) stays --
at_thumb 1; ctrl_shift_click "$TX" "$TY"; settle_click "ctrl+shift+click the bottom thumbnail again"; sel
[[ "$S_ON" == -1 && "$S_N" == "$DOTN" && "$S_FROM" == "$TOPL" ]] && pass "Ctrl+Shift+click a layer already in: out again, the top layer's $DOTN px kept" || fail "remove: LPSEL '$(grep '^LPSEL ' "$DK_DUMP")' (want $DOTN px from $TOPL)"

# --- and the top one: nothing left -------------------------------------------
at_thumb 0; ctrl_shift_click "$TX" "$TY"; settle_click "ctrl+shift+click the top thumbnail"; sel
[[ "$S_ON" == 0 ]] && pass "Ctrl+Shift+click the last one in: no selection" || fail "remove last: LPSEL '$(grep '^LPSEL ' "$DK_DUMP")'"

# --- a selection made some other way: Ctrl+Shift+click adds to it ------------
key ctrl+a; wait_for 0.5 "select all"; dk_settle; sel
ALLN=$S_N
at_thumb 1; ctrl_shift_click "$TX" "$TY"; settle_click "ctrl+shift+click onto select all"; sel
[[ "$S_ON" == -1 && "$S_N" == "$ALLN" && "$S_FROM" == "$BOTL" ]] && pass "onto Select All: added (still $ALLN px), the layer remembered" || fail "onto select all: LPSEL '$(grep '^LPSEL ' "$DK_DUMP")' (all was $ALLN)"
key ctrl+d; wait_for 0.4 "deselect"; dk_settle

# --- the rest of the row is unchanged ------------------------------------------
M0=$(multi)
ctrl_click $(( P_X + P_W - 24 )) $(( P_Y + G_HDR + G_ROW + G_ROW / 2 )); settle_click "ctrl+click the bottom name"; sel
[[ "$(multi)" != "$M0" && "$S_ON" == 0 ]] && pass "Ctrl+click a name: the multi-select ($M0 -> $(multi)), no selection" || fail "Ctrl+click name: multi $M0 -> $(multi), LPSEL '$(grep '^LPSEL ' "$DK_DUMP")'"
ctrl_shift_click $(( P_X + P_W - 24 )) $(( P_Y + G_HDR + G_ROW / 2 )); settle_click "ctrl+shift+click a name"
dk_p layers
[[ "$P_X" != "$PX0" ]] && pass "Ctrl+Shift+click a name: the dock side swaps as before" || fail "Ctrl+Shift+click name: the panel stayed at $P_X"
screenshot "layer-thumb-select"
assert_no_crash
rm -rf "$TS_DIR"
info "=== Layers: selections from thumbnails: done ==="
