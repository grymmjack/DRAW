#!/bin/bash
# =============================================================================
# controls-preset-picker-source-guards.sh — QA regression guard (SOURCE-level)
#
# Guards the in-app keymap-preset picker: a "Load preset ▾" dropdown in Customize
# Controls loads a shipped ASSETS/PRESETS/<name>.bindings live (restore defaults →
# apply preset overrides → refresh the key column). Also guards that all shipped
# preset files exist and that load_preset resets to defaults first (clean switch).
# =============================================================================

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
source "$HERE/lib/source-guard.sh"

echo "=== Preset picker + loader source guards ==="

# Picker UI.
assert_grep "UI" "GUI/CONTROLS.BI" 'CONST CTRL_DD_PRESET'                        "preset-dropdown id constant"
assert_grep "UI" "GUI/CONTROLS.BM" 'DIALOG_dropdown%\(CONTROLS.ctx, CTRL_DD_PRESET' "Load-preset dropdown widget"
assert_grep "UI" "GUI/CONTROLS.BM" 'BINDINGS_load_preset pname\$'                "picker loads the chosen preset live"
assert_grep "UI" "GUI/CONTROLS.BM" 'CASE 5: pname\$ = "krita"'                   "picker lists the new apps (krita)"

# Loader: clean switch (restore defaults before applying).
assert_grep "LOADER" "CFG/BINDINGS.BM" 'SUB BINDINGS_restore_live_defaults'      "DRY restore-defaults helper"
assert_grep "LOADER" "CFG/BINDINGS.BM" 'BINDINGS_restore_live_defaults'          "load_preset/reset call the helper"

# All shipped preset files exist.
for p in draw-default photoshop gimp krita illustrator aseprite deluxepaint procreate mspaint promotion; do
    if [ -f "$ROOT/ASSETS/PRESETS/$p.bindings" ]; then
        pass "PRESET: $p.bindings present"
    else
        fail "PRESET: $p.bindings MISSING"
    fi
done

# The two provably-safe remaps are present (Ctrl+J on the free key 106).
assert_grep "SAFE" "ASSETS/PRESETS/photoshop.bindings" '321 106 1 0'             "photoshop Ctrl+J -> Copy to New Layer"
assert_grep "SAFE" "ASSETS/PRESETS/krita.bindings"     '707 106 1 0'             "krita Ctrl+J -> Duplicate Layer"

guard_footer "a preset-picker guard was removed"
if [ "${BASH_SOURCE[0]}" = "$0" ]; then [ "$fails" -eq 0 ] && exit 0 || exit 1; fi
