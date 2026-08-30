#!/bin/bash
# =============================================================================
# phantom-undo-guards.sh — QA: the no-op-undo guards (F1-F12) stay in place.
#
# Companion to phantom-undo-noop.sh. That test drives the GUI-reachable cases
# (F1/F2/F11); several findings are dialog- or mode-driven (image adjustments,
# Remove Background, Transform, Bezier, Stroke Selection, Clear Layer) and can't
# be synthesized reliably headless. This is a SOURCE regression guard: it asserts
# each fix's change-detection guard is still present, so a future edit can't
# silently drop one and reintroduce a phantom undo. Full behavior is verified
# manually on the fleet (checklist at the end).
#
# The shared guard is HISTORY_image_differs% (records only when the layer image
# actually changed); F5 uses TRANSFORM.MODIFIED, F6/F8 add a point-count gate,
# F7 adds CONTENT_FLIPPED to the clone gate.
# =============================================================================

info "=== Phantom-undo source guards (F1-F12) ==="

assert_window_exists
assert_no_crash

R="$DRAW_ROOT"

guard() { # $1 = file, $2 = grep -E pattern, $3 = human label
    if grep -qE "$2" "$R/$1" 2>/dev/null; then
        pass "$3"
    else
        fail "phantom-undo guard missing: $3  ($2 not found in $1)"
    fi
}

# Shared helper
guard "TOOLS/HISTORY.BM"      "FUNCTION HISTORY_image_differs%"                                   "helper: HISTORY_image_differs%"

# F1 — Flood Fill
guard "INPUT/MOUSE.BM"        "HISTORY_image_differs%\(fill_history_before&"                      "F1 fill records only on real change"
# F2 — Cut / Clear selection
guard "TOOLS/SELECTION.BM"    "HISTORY_image_differs%\(cutHistoryBefore&"                         "F2 cut records only on real change"
guard "TOOLS/SELECTION.BM"    "HISTORY_image_differs%\(clearHistoryBefore&"                       "F2 clear-selection records only on real change"
# F3 — Image adjustments (shared apply)
guard "GUI/IMAGE-ADJ.BM"      "adjChanged% = HISTORY_image_differs%\(adjOrigSnap&"                "F3 adjustments record only on real change"
# F4 — Remove Background
guard "GUI/IMAGE-ADJ.BM"      "HISTORY_image_differs%\(applySnap&"                                "F4 remove-background records only on real change"
# F5 — Transform commit (identity / no drag)
guard "TOOLS/TRANSFORM.BM"    "IF TRANSFORM.MODIFIED THEN"                                        "F5 transform commit gated on MODIFIED"
guard "TOOLS/TRANSFORM.BM"    "TRANSFORM.MODIFIED = TRUE"                                         "F5 transform sets MODIFIED on a real edit"
# F6 — Bezier single/coincident anchor
guard "TOOLS/BEZIER.BM"       "BEZIER.POINT_COUNT >= 2 _ANDALSO HISTORY_image_differs%"           "F6 bezier needs >=2 points AND a real change"
# F7 — Clone / Stamp in place
guard "TOOLS/MOVE.BM"         "moveDidChange% OR MOVE.CLONE_STAMPED OR MOVE.CONTENT_FLIPPED"       "F7 clone gate drops bare CLONING"
guard "TOOLS/MOVE.BM"         "HISTORY_image_differs%\(stampBefore&"                              "F7 stamp records only on real change"
# F8 — Spray / Polyline degenerate commits
guard "INPUT/MOUSE.BM"        "HISTORY_image_differs%\(SPRAY.HISTORY_BEFORE_IMG"                  "F8 spray records only on real change"
guard "INPUT/MOUSE.BM"        "POLY_LINE.POINT_COUNT >= 2 _ANDALSO HISTORY_image_differs%"         "F8 polyline needs >=2 points AND a real change"
# F9 — Wand clear transparent
guard "TOOLS/MARQUEE.BM"      "HISTORY_image_differs%\(history_before&, targetImg&\)"              "F9 wand-clear-transparent records only on real change"
# F10 — Stroke Selection
guard "GUI/STROKE-SEL.BM"     "HISTORY_image_differs%\(strokeHistoryBefore&"                      "F10 stroke-selection records only on real change"
# F11 — Flip / Rotate / Fill FG-BG + multi-select
guard "GUI/COMMAND.BM"        "HISTORY_image_differs%\(flipH_history_before&"                     "F11 flip-H records only on real change"
guard "GUI/COMMAND.BM"        "HISTORY_image_differs%\(flipV_history_before&"                     "F11 flip-V records only on real change"
guard "GUI/COMMAND.BM"        "HISTORY_image_differs%\(fillHistoryBefore&"                        "F11 fill-FG records only on real change"
guard "GUI/COMMAND.BM"        "HISTORY_image_differs%\(bgHistoryBefore&"                          "F11 fill-BG records only on real change"
guard "GUI/COMMAND.BM"        "HISTORY_image_differs%\(mlFBefore&"                                "F11 multi-select fill records only on real change"
# F12 — Clear Layer
guard "GUI/LAYERS.BM"         "HISTORY_image_differs%\(clearBefore&, LAYERS\(layerIndex%\)"        "F12 clear-layer records only on real change"

assert_no_crash

info "=== Manual fleet checks (per OS) — phantom-undo ==="
info "  F3: Image ▸ Brightness/Contrast, click OK without moving sliders → NO undo added"
info "  F4: Image ▸ Remove Background on a color not present → NO undo added"
info "  F5: Edit ▸ Transform, press Enter without dragging a handle → NO undo added"
info "  F6: Bezier tool, place ONE anchor, Enter → NO undo added"
info "  F10: Select ▸ Stroke Selection with no active selection → NO undo added"
info "  F12: Clear Layer on an already-empty layer → NO undo added"

info "=== Phantom-undo source guards COMPLETE ==="
