#!/bin/bash
# =============================================================================
# zoom-tool-rightclick-source-guard.sh — QA regression guard (SOURCE-level)
#
# The Zoom tool must zoom OUT on RIGHT-click (B2). Alt+Left-click also zooms out
# but Linux WMs steal Alt+Left-click for "move window", so it never reaches DRAW
# — right-click is the reliable path. Clicking the canvas to zoom is not reliably
# targetable offscreen, so this pins the wiring; verify the gesture live.
# =============================================================================
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
source "$HERE/lib/source-guard.sh"

echo "=== Zoom tool right-click zoom-out source guard ==="
assert_grep "ZOOM" "INPUT/MOUSE.BM" 'MOUSE.OLD_B2% AND NOT MOUSE.B2% AND NOT ZOOM.DRAGGING' "right-click (B2) release path in MOUSE_release_zoom"
assert_grep "ZOOM" "INPUT/MOUSE.BM" 'ZOOM_out_at rawX%, rawY%'                              "B2 release zooms OUT at cursor"
# The release dispatcher must route B2 release to the zoom tool.
assert_grep "ZOOM" "INPUT/MOUSE.BM" 'MOUSE.OLD_B1% OR MOUSE.OLD_B2%'                        "release dispatcher fires on either button"

guard_footer "the zoom-tool right-click guard was removed"
if [ "${BASH_SOURCE[0]}" = "$0" ]; then [ "$fails" -eq 0 ] && exit 0 || exit 1; fi
