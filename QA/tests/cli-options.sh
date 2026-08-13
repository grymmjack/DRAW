#!/bin/bash
# =============================================================================
# cli-options.sh — QA test: --options-list registry + --option override plumbing.
#
# --options-list prints the option registry (from DRAW.cfg.default) and exits, so
# it's checked as a subprocess by inspecting stdout. The --option OVERRIDE path is
# covered end-to-end by layer-group-auto-layer.sh (its `# QA-OPTIONS:` line only
# makes that test pass because --option GROUP_DRAW_AUTO_LAYER=TRUE takes effect).
# =============================================================================

info "=== CLI options registry test ==="

# Run --options-list from DRAW_ROOT (it resolves DRAW.cfg.default relative to cwd).
OPTLIST=$( cd "$DRAW_ROOT" && timeout 15 "$DRAW_BIN" --options-list 2>/dev/null )

if grep -q 'GROUP_DRAW_AUTO_LAYER' <<<"$OPTLIST" && grep -q 'TOOLTIPS_DISABLED' <<<"$OPTLIST"; then
    pass "--options-list includes known option keys"
else
    fail "--options-list is missing expected keys"
fi

if grep -qE '^[0-9]+ options\.' <<<"$OPTLIST"; then
    pass "--options-list prints a total count"
else
    fail "--options-list has no total-count line"
fi

if grep -q -- '--option KEY=VALUE' <<<"$OPTLIST"; then
    pass "--options-list shows the --option usage hint"
else
    fail "--options-list is missing the --option usage hint"
fi

# Each listed option shows a default value (KEY = value form).
if grep -qE '  [A-Z_][A-Z0-9_]* += ' <<<"$OPTLIST"; then
    pass "--options-list shows KEY = default for each option"
else
    fail "--options-list rows are not in 'KEY = default' form"
fi

wait_for 0.3 "let the --options-list subprocess exit"
assert_no_crash
assert_window_exists
info "=== CLI options registry test PASSED ==="
