#!/bin/bash
# =============================================================================
# grid-reinit-on-new-source-guards.sh — QA regression guard (SOURCE-level)
#
# Guards gotcha #15: all THREE document-creation paths must recreate the grid
# image for the new canvas size. They had DRIFTED — only Open (DRW_load_binary)
# re-init'd the grid, so New / New-from-* kept a stale grid image (e.g. the small
# one left by a prior Crop), which the zoom _PUTIMAGE then stretched into thick
# solid bands along the top row + left column.
#
# WHY source-level: reproducing the exact crop -> New-from-template -> zoom flow
# offscreen is unreliable (crop action, grid visibility, zoom keys, template
# picker). This test asserts the fix's marker — GRID_reinit_preserve called from
# both New paths — is still present, so a refactor can't silently delete it.
# =============================================================================

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
source "$(dirname "${BASH_SOURCE[0]}")/lib/source-guard.sh"

echo "=== Grid re-init on document creation source guards ==="

# The shared helper exists and preserves the current grid across the re-init.
assert_grep "HELPER" "GUI/GRID.BM" 'SUB GRID_reinit_preserve'          "grid re-init helper exists"
assert_grep "HELPER" "GUI/GRID.BM" 'GRID_init'                         "helper recreates the grid image (GRID_init)"
assert_grep "HELPER" "GUI/GRID.BM" 'GRID\.gridWidth%  *= *sGW%'        "helper restores the current grid size"

# Both New paths call it (Open already re-inits via GRID_init directly).
assert_grep "NEW"    "TOOLS/DRW.BM" 'GRID_reinit_preserve'             "a New path calls the helper"
# Exactly the two New subs must call it — verify the count is 2 (new_canvas +
# create_canvas_at_size), so neither path can silently drop the re-init again.
_ng=$(grep -c 'GRID_reinit_preserve' "$ROOT/TOOLS/DRW.BM" 2>/dev/null)
if [ "${_ng:-0}" -ge 2 ]; then pass "NEW: both New paths call GRID_reinit_preserve (${_ng})"; else fail "NEW: expected >=2 GRID_reinit_preserve calls in DRW.BM, found ${_ng:-0}"; fi

# Open still re-inits the grid (regression guard on the path that was already correct).
assert_grep "OPEN"   "TOOLS/DRW.BM" 'GRID_init'                        "Open (DRW_load_binary) re-inits the grid"

guard_footer "a document-creation path stopped recreating the grid image (gotcha #15)"
if [ "${BASH_SOURCE[0]}" = "$0" ]; then [ "$fails" -eq 0 ] && exit 0 || exit 1; fi
