#!/bin/bash
# =============================================================================
# paste-move-wand-source-guards.sh — QA regression guard (SOURCE-level)
#
# Guards the five v2.0.3 fixes for the Magic Wand -> Copy -> Paste -> Move ->
# Flip cluster reported by a Windows beta tester against v2.0.1 (Feedbacks.pdf).
# See BUGS-v2.0.3.md for the full write-up.
#
#   A — paste ALWAYS centres on the canvas (no mouse/menu dependency).
#   B — a pasted float stays floating and composites ONCE at a terminal commit
#       (deselect / tool-switch / ESC / next-paste / save), not per-release, so
#       repeated drags reposition instead of "cutting themselves away"; plus the
#       terminal commit records a Clone undo entry (wasPaste% in the guard).
#   C — the float composites with _BLEND, so a paste's transparent bbox shows the
#       layer through instead of erasing it (was _DONTBLEND).
#   D — flip during a floating paste no longer ghosts/fuses (falls out of B:
#       nothing is baked under the float, so only the flipped result shows).
#   E — the Magic Wand honours the apron offset (gotcha #14) after a paste/move
#       promotes an apron, so a fresh wand-select reads the right pixels.
#
# WHY source-level: the multi-step floating-move + wand workflow cannot be driven
# reliably under the offscreen Xvfb harness (mouse-vs-keyboard event timing, float
# grabbing, marquee copies come back empty, the wand click lands on transparent).
# The behavioural guards live in seam-copy-then-wand / wand-*-offcanvas-crash /
# tool-move; THIS test asserts each fix's guard logic is still present so a future
# refactor cannot silently delete it. It launches nothing. It FAILS (red) the
# moment a fix's marker goes missing — the "must fail on the buggy build" contract
# applied at the source layer.
#
# Run directly:  bash QA/tests/paste-move-wand-source-guards.sh
# =============================================================================

# Resolve repo root (this file lives in <root>/QA/tests/).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"

fails=0
# When SOURCED by the QA harness (runner.sh does `source "$test_file"`), use ITS
# pass/fail so a missing guard bumps the suite's FAIL counter. Define fallbacks
# ONLY for standalone `bash <this>` runs — never redefine the harness's.
declare -F pass >/dev/null || pass() { printf '  \033[32mPASS\033[0m  %s\n' "$1"; }
declare -F fail >/dev/null || fail() { printf '  \033[31mFAIL\033[0m  %s\n' "$1"; fails=$((fails+1)); }

# assert_grep <bug> <file> <extended-regex> <human description>
assert_grep() {
  local bug="$1" file="$2" re="$3" desc="$4"
  if [ ! -f "$ROOT/$file" ]; then fail "$bug: file missing: $file"; return; fi
  if grep -Eq -- "$re" "$ROOT/$file"; then pass "$bug: $desc"; else fail "$bug: MISSING in $file — $desc"; fi
}

echo "=== Paste/Move/Wand source guards (v2.0.3 A/B/C/D/E) ==="

# A — paste position no longer depends on the mouse; it is forced to canvas centre.
assert_grep  "BUG-A" "TOOLS/SELECTION.BM" 'mouseX% = SCRN\.canvasW& \\ 2' "paste X forced to canvas centre"
assert_grep  "BUG-A" "TOOLS/SELECTION.BM" 'mouseY% = SCRN\.canvasH& \\ 2' "paste Y forced to canvas centre"

# B — pasted float stays floating: the release handler has an IS_PASTE branch that
# syncs the base instead of baking (MOVE_apply_transform).
assert_grep  "BUG-B" "INPUT/MOUSE.BM" 'ELSEIF MOVE\.IS_PASTE THEN' "release: pasted float defers its composite"
# B — the terminal paste-commit records an undo entry (wasPaste% joins the guard,
# because a float syncs ORIGINAL==CURRENT so moveDidChange% is FALSE at commit).
assert_grep  "BUG-B" "TOOLS/MOVE.BM"  'moveDidChange% OR MOVE\.CLONE_STAMPED OR MOVE\.CONTENT_FLIPPED OR wasPaste%' "paste commit is undoable"
# B — save finalises a live float first so the paste is baked before writing.
assert_grep  "BUG-B" "TOOLS/SAVE.BM"  'IF MOVE\.ACTIVE THEN MOVE_reset' "save finalises a floating paste"

# C — the float composites with _BLEND (transparency preserved; not _DONTBLEND).
assert_grep  "BUG-C" "TOOLS/MOVE.BM"  '_BLEND targetImg&' "float composite blends (transparency shows through)"

# E — the wand crops the apron buffer to canvas coords before flooding (gotcha #14).
assert_grep  "BUG-E" "TOOLS/MARQUEE.BM" 'wandCropped& = _NEWIMAGE\(SCRN\.canvasW&, SCRN\.canvasH&, 32\)' "wand apron-crops to canvas coords"
assert_grep  "BUG-E" "TOOLS/MARQUEE.BM" 'SAFE_FREEIMAGE wandCropped&' "wand crop buffer is freed"

echo "---------------------------------------------"
if [ "$fails" -eq 0 ]; then
  echo -e "\033[32mALL GUARDS PRESENT\033[0m"
else
  echo -e "\033[31m$fails GUARD(S) MISSING — a paste/move/wand fix was removed\033[0m"
fi
# Tests are SOURCED by the harness — an `exit` here would kill the runner
# mid-suite. Only exit when run standalone.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then [ "$fails" -eq 0 ] && exit 0 || exit 1; fi
