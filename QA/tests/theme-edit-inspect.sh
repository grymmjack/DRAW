#!/bin/bash
# =============================================================================
# theme-edit-inspect.sh — QA test: Theme Edit mode's console side
# (CFG/THEME-EDIT.BM, PLANS/THEME-EDIT.md). `--theme-edit-inspect [id]` prints
# KEY=VALUE lines and exits without a window; `--theme-edit --theme-name NEW
# --theme-edit-base BASE` creates NEW as a copy of BASE before DRAW loads it.
# Runs DRAW as a console program beside the harness's window, which it only
# checks is still fine afterwards.
# =============================================================================

info "=== Theme Edit inspect (console) Test ==="
TE_CFG="$DRAW_ROOT/QA/DRAW.qa.cfg"
TE_NAME="QATE$$"
TE_DIR="$DRAW_ROOT/ASSETS/THEMES/$TE_NAME"
rm -rf "$TE_DIR"

_te() { ( cd "$DRAW_ROOT" && env -u DISPLAY -u WAYLAND_DISPLAY timeout 30 "$DRAW_BIN" --config "$TE_CFG" "$@" 2>/dev/null ); }

# the component list
OUT=$(_te --theme-edit-inspect COMPONENTS); RC=$?
if [[ $RC -eq 0 ]] && grep -q '^TOOLBOX' <<<"$OUT" && grep -q '^LAYER_PANEL' <<<"$OUT"; then
    pass "COMPONENTS lists the components ($(wc -l <<<"$OUT") lines)"
else
    fail "COMPONENTS (rc=$RC): $(head -3 <<<"$OUT")"
fi

# one component: its sections' properties as KEY=VALUE
OUT=$(_te --theme-edit-inspect TOOLBOX); RC=$?
if [[ $RC -eq 0 ]] && grep -qE '^[A-Z0-9_]+=' <<<"$OUT"; then
    pass "TOOLBOX dumps KEY=VALUE lines ($(grep -cE '^[A-Z0-9_]+=' <<<"$OUT"))"
else
    fail "TOOLBOX dump (rc=$RC): $(head -3 <<<"$OUT")"
fi

# every property: one line per generated key, colours as R,G,B,A
OUT=$(_te --theme-edit-inspect ALL); RC=$?
N=$(grep -cE '^[A-Z0-9_]+=' <<<"$OUT")
if [[ $RC -eq 0 && $N -ge 600 ]] && grep -qE '^CANVAS_BORDER=[0-9]+,[0-9]+,[0-9]+,[0-9]+$' <<<"$OUT"; then
    pass "ALL dumps $N properties, colours as R,G,B,A"
else
    fail "ALL dump (rc=$RC, $N lines)"
fi

# a single key
OUT=$(_te --theme-edit-inspect GRID_SIZE_X); RC=$?
if [[ $RC -eq 0 ]] && grep -qE '^GRID_SIZE_X=[0-9]+$' <<<"$OUT"; then
    pass "a single key: $OUT"
else
    fail "single key (rc=$RC): $OUT"
fi

# an unknown id exits 2
_te --theme-edit-inspect NOT_A_THING_AT_ALL >/dev/null; RC=$?
if [[ $RC -eq 2 ]]; then pass "an unknown id exits 2"; else fail "unknown id exited $RC, wanted 2"; fi

# a new theme is created from the base before DRAW loads it
OUT=$(_te --theme-edit --theme-name "$TE_NAME" --theme-edit-base DARK --theme-edit-inspect CANVAS_BORDER); RC=$?
WANT=$(_te --theme-edit --theme-name DARK --theme-edit-inspect CANVAS_BORDER)
if [[ $RC -eq 0 && -f "$TE_DIR/THEME.CFG" ]] && cmp -s "$TE_DIR/THEME.CFG" "$DRAW_ROOT/ASSETS/THEMES/DARK/THEME.CFG"; then
    pass "--theme-name $TE_NAME --theme-edit-base DARK created a copy of DARK"
else
    fail "theme creation (rc=$RC): $(ls "$TE_DIR" 2>&1 | head -3)"
fi
if [[ -n "$OUT" && "$OUT" == "$WANT" ]]; then
    pass "the new theme is the one loaded ($OUT)"
else
    fail "loaded '$OUT', the base has '$WANT'"
fi
rm -rf "$TE_DIR"

assert_no_crash
assert_window_exists
info "=== Theme Edit inspect Test PASSED ==="
