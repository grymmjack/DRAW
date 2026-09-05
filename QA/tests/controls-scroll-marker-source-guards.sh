#!/bin/bash
# =============================================================================
# controls-scroll-marker-source-guards.sh — QA regression guard (SOURCE-level)
#
# Guards two Phase 4 polish additions to the Customize Controls dialog
# (GUI/CONTROLS.BM / .BI):
#
#   (1) SCROLLBAR DRAG — the thumb can be grabbed and dragged, and clicking the
#       track above/below the thumb pages toward the click. Shared geometry
#       (CTRL_scrollbar_metrics) keeps draw + input agreeing on the thumb rect;
#       a grab consumes the click so a row's SET... button can't also fire.
#
#   (2) OVERRIDDEN-ROW "MODIFIED" MARKER — any binding a user rebind changed
#       (INPUT_BINDS().userOverridden) gets a left accent stripe + highlighted
#       key text, and the button bar carries a "= changed from default" legend.
#
# WHY source-level: driving a drag over a SCALED modal dialog offscreen (Xvfb)
# is unreliable (the dialog buffer scales independently of the viewport->screen
# map, so thumb pixel coords drift). controls-dialog-open / controls-find-filter
# cover the dialog opening + FIND; THIS test asserts the drag + marker logic is
# still present so a refactor can't silently delete it. It launches nothing and
# FAILS (red) the moment a guard marker goes missing.
#
# Run directly:  bash QA/tests/controls-scroll-marker-source-guards.sh
# =============================================================================

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"

# Shared source-guard scaffolding (pass/fail/assert_grep/assert_absent/guard_footer).
source "$(dirname "${BASH_SOURCE[0]}")/lib/source-guard.sh"

echo "=== Customize Controls scroll + marker source guards ==="

# (1) Scrollbar drag ----------------------------------------------------------
assert_grep "SCROLL" "GUI/CONTROLS.BI" 'scrollDrag  *AS INTEGER'                     "drag state field exists"
assert_grep "SCROLL" "GUI/CONTROLS.BI" 'scrollDragOff *AS INTEGER'                   "drag grab-offset field exists"
assert_grep "SCROLL" "GUI/CONTROLS.BM" 'SUB CTRL_scrollbar_metrics'                  "shared thumb-geometry helper exists"
assert_grep "SCROLL" "GUI/CONTROLS.BM" 'SUB CONTROLS_handle_scrollbar'              "drag/paging input handler exists"
assert_grep "SCROLL" "GUI/CONTROLS.BM" 'CONTROLS\.scrollDrag = TRUE'                 "thumb grab starts a drag"
assert_grep "SCROLL" "GUI/CONTROLS.BM" 'CONTROLS\.ctx\.justClicked = FALSE'          "grab consumes the click (no double-hit)"
assert_grep "SCROLL" "GUI/CONTROLS.BM" 'CONTROLS_handle_scrollbar'                   "handler is wired into the modal loop"
assert_grep "SCROLL" "GUI/CONTROLS.BM" 'CONTROLS\.viewportH   *' \
            "track paging uses a viewport-sized step"

# (2) Overridden-row modified marker -----------------------------------------
assert_grep "MARKER" "GUI/CONTROLS.BM" 'modf = INPUT_BINDS\(bi\)\.userOverridden'    "row reads userOverridden"
assert_grep "MARKER" "GUI/CONTROLS.BM" 'IF modf THEN LINE \(1, y\)-\(3'              "modified rows get a left accent stripe"
assert_grep "MARKER" "GUI/CONTROLS.BM" '= changed from default'                      "button bar carries the marker legend"

# (3) SET-button hit-rect clamped to the visible band -------------------------
# The REBIND (SET) column (x 448..540) overlaps CLOSE in X. A row straddling the
# bottom edge is painted over by the button bar, but its SET hit-rect used to
# extend under the bar, so clicking CLOSE also fired the occluded SET behind it
# (a random rebind modal popped up). The clamp confines the hit-rect to [top,
# bottom] so the under-bar (and under-header) region is inert.
assert_grep  "CLAMP" "GUI/CONTROLS.BM" 'IF btnTop% < top THEN btnTop% = top'         "SET hit-rect clamped to viewport top (header occlusion)"
assert_grep  "CLAMP" "GUI/CONTROLS.BM" 'IF btnBot% > bottom THEN btnBot% = bottom'   "SET hit-rect clamped to viewport bottom (button-bar occlusion)"
assert_grep  "CLAMP" "GUI/CONTROLS.BM" 'IF btnBot% > btnTop% THEN'                    "no hit-test when nothing of the SET button is visible"

guard_footer "a Customize Controls polish fix was removed"
if [ "${BASH_SOURCE[0]}" = "$0" ]; then [ "$fails" -eq 0 ] && exit 0 || exit 1; fi
