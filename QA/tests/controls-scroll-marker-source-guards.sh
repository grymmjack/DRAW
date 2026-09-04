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

fails=0
declare -F pass >/dev/null || pass() { printf '  \033[32mPASS\033[0m  %s\n' "$1"; }
declare -F fail >/dev/null || fail() { printf '  \033[31mFAIL\033[0m  %s\n' "$1"; fails=$((fails+1)); }

# assert_grep <tag> <file> <extended-regex> <human description>
assert_grep() {
  local tag="$1" file="$2" re="$3" desc="$4"
  if [ ! -f "$ROOT/$file" ]; then fail "$tag: file missing: $file"; return; fi
  if grep -Eq -- "$re" "$ROOT/$file"; then pass "$tag: $desc"; else fail "$tag: MISSING in $file — $desc"; fi
}

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

echo "---------------------------------------------"
if [ "$fails" -eq 0 ]; then
  echo -e "\033[32mALL GUARDS PRESENT\033[0m"
else
  echo -e "\033[31m$fails GUARD(S) MISSING — a Customize Controls polish fix was removed\033[0m"
fi
if [ "${BASH_SOURCE[0]}" = "$0" ]; then [ "$fails" -eq 0 ] && exit 0 || exit 1; fi
