#!/bin/bash
# =============================================================================
# effect-shape-reparent.sh — QA test / regression guard
#
# EFFECTS > SHAPE > Bevel (child 3) and Chrome (child 4) are Eye-Candy "Shape"
# homes for the existing Layer-FX engines (shared actions 2126 / 2129). This
# test guards the SHAPE flyout child NUMBERING at indices 3 and 4 — the exact
# thing the 2026-08-14 child-index fix corrected (hidden generic-flyout children
# were miscounted, so category clicks dispatched the wrong effect). If numbering
# regresses, open_effect 7 3 / 7 4 open some other dialog and the region diff
# changes character — but more importantly a broken flyout would dispatch a
# same-size adjust and this still guards that the SHAPE entries reach a dialog.
#
# Thick green blob on a transparent layer; apply each; assert the region changed.
# =============================================================================

info "=== Effect: SHAPE re-parent (Bevel/Chrome) Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
key ctrl+shift+n ; wait_for 0.4 "New transparent layer"
for n in 1 2 3 4 5 6 7 8 9 10 11 12; do key bracketright; done
wait_for 0.2 "Brush enlarged"

CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 11*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Green FG"
drag $(( CANVAS_CX - 40 )) "$CANVAS_CY" $(( CANVAS_CX + 40 )) "$CANVAS_CY"
key grave
wait_for 0.3 "Content drawn"
assert_no_crash

GX=$(( CANVAS_CX - 44 )); GY=$(( CANVAS_CY - 16 )); GW=88; GH=32

# ---- SHAPE > Bevel (child index 3) ----------------------------------------
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "shape-bevel-before"
BEFORE="$SNAP_RESULT"
open_effect 7 3 ; wait_for 0.5 "SHAPE>Bevel dialog open"
screenshot "shape-bevel-dialog"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "shape-bevel-after"
AFTER="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$AFTER" \
    "SHAPE>Bevel (open_effect 7 3) must reach the Bevel dialog and alter the shape"

# ---- SHAPE > Chrome (child index 4) ---------------------------------------
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "shape-chrome-before"
BEFORE2="$SNAP_RESULT"
open_effect 7 4 ; wait_for 0.5 "SHAPE>Chrome dialog open"
screenshot "shape-chrome-dialog"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "shape-chrome-after"
AFTER2="$SNAP_RESULT"
assert_regions_differ "$BEFORE2" "$AFTER2" \
    "SHAPE>Chrome (open_effect 7 4) must reach the Chrome dialog and alter the shape"

# ---- SHAPE > Extrude (child index 5) --------------------------------------
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "shape-extrude-before"
BEFORE3="$SNAP_RESULT"
open_effect 7 5 ; wait_for 0.5 "SHAPE>Extrude dialog open"
screenshot "shape-extrude-dialog"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "shape-extrude-after"
AFTER3="$SNAP_RESULT"
assert_regions_differ "$BEFORE3" "$AFTER3" \
    "SHAPE>Extrude (open_effect 7 5) must reach the Extrude dialog and alter the shape"

# ---- SHAPE > Inner Glow (child index 7 — deep-index numbering guard) -------
# Guards the flyout child numbering at a DEEP index (where the pre-fix miscount
# bit hardest). Inner Glow reliably alters the blob's own interior in FG colour,
# so it's a dependable region-differ. (Index 9 / Perspective Shadow was VISUALLY
# confirmed to open the correct "LONG SHADOW" dialog — see shape-pshadow-dialog
# screenshot — but its default cast blends with the black ground, so it makes a
# poor automated assert; Inner Glow is the reliable deep guard.)
click $(( 16 + 28*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "FG magenta (glow colour)"
GX2=$(( CANVAS_CX - 44 )); GY2=$(( CANVAS_CY - 16 )); GW2=88; GH2=32
park_mouse
snap_region "$GX2" "$GY2" "$GW2" "$GH2" "shape-innerglow-before"
BEFORE4="$SNAP_RESULT"
open_effect 7 7 ; wait_for 0.5 "SHAPE>Inner Glow dialog open"
screenshot "shape-innerglow-dialog"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash
park_mouse
snap_region "$GX2" "$GY2" "$GW2" "$GH2" "shape-innerglow-after"
AFTER4="$SNAP_RESULT"
assert_regions_differ "$BEFORE4" "$AFTER4" \
    "SHAPE>Inner Glow (open_effect 7 7, deep child) must glow the shape interior"

assert_no_crash
assert_window_exists
info "=== Effect: SHAPE re-parent (Bevel/Chrome/Extrude/Glows/Shadows) Test PASSED ==="
