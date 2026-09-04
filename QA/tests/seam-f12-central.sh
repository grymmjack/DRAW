#!/bin/bash
# =============================================================================
# seam-f12-central.sh — Phase 2A: F12 (Export Custom Brush) via CENTRAL DISPATCH
#
# F12 was a keycode-variant landmine: the legacy custom-brush handler used
# _KEYDOWN(34304); the registry dev-dump binding used 28416 (which a GLFW probe
# proved NEVER fires); the shortcuts keyname map also said 28416. Probe verdict:
# F12 = 34304 under GLFW (F11 34048 + 256). Migration:
#
#   F12 (34304) + CTX_CUSTOM_BRUSH_ACTIVE -> action 1110 (Export Brush PNG, dialog)
#   F12 (34304), no custom brush          -> action 9999 (dev-mode debug dump)
#
# Two context-disjoint bindings (mirrors the Home/End brush-vs-layer pattern), so
# the 9999-vs-1110 id overlap is resolved. Legacy KEYBOARD.BM handler removed;
# keyname map corrected 28416 -> 34304.
#
# Behaviour is proven live via fire-f12-probe.sh (--developer FIRE log). THIS test
# guards the source so a refactor can't reintroduce the wrong keycode.
# =============================================================================

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
source "$HERE/lib/source-guard.sh"

echo "=== F12 central-dispatch source guards ==="

# Registry: brush-export (1110) requires the custom-brush context; dev-dump (9999)
# forbids it — both on the PROBED keycode 34304.
assert_grep  "REG" "INPUT/INPUT.BM" 'INPUT_register_key%\(34304, 0, allMods%, CTX_CUSTOM_BRUSH_ACTIVE, CTX_TEXT_ACTIVE, 1110, TRUE' "F12+brush -> 1110 dispatched=TRUE"
assert_grep  "REG" "INPUT/INPUT.BM" 'INPUT_register_key%\(34304, 0, allMods%, 0, CTX_TEXT_ACTIVE OR CTX_CUSTOM_BRUSH_ACTIVE, 9999, TRUE' "F12 (no brush) -> 9999 dispatched=TRUE"

# The wrong keycode 28416 must be gone from the registry F12 binding.
assert_absent "REG" "INPUT/INPUT.BM" 'INPUT_register_key%\(28416,' "dead 28416 F12 binding removed"

# Legacy _KEYDOWN(34304) export handler removed from KEYBOARD.BM.
assert_absent "LEG" "INPUT/KEYBOARD.BM" 'IF _KEYDOWN\(34304\) THEN' "legacy F12 _KEYDOWN handler removed"

# Shortcuts keyname map corrected to the probed keycode.
assert_grep  "DOC" "OUTPUT/SHORTCUTS-DUMP.BM" 'CASE 34304 +: SHORTCUTS_keyname\$ = "F12"' "keyname map F12 = 34304"

guard_footer "an F12 migration guard was removed"
if [ "${BASH_SOURCE[0]}" = "$0" ]; then [ "$fails" -eq 0 ] && exit 0 || exit 1; fi
