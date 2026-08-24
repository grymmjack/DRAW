#!/bin/bash
# QA-OPTIONS: ANTIALIAS=TRUE
# =============================================================================
# antialias-toggle.sh — QA: experimental Anti-Aliasing flag (Phase 0+1).
#
# Verifies (headless-friendly):
#   1. ANTIALIAS defaults to FALSE in the option registry (--options-list).
#   2. The AA-off byte-equality invariant is preserved *by construction* — the
#      routing chokepoints keep their `IF CFG.ANTIALIAS%` gate WITH a verbatim
#      original branch (static source guard, so a future refactor that deletes
#      the hard-edged fallback fails here loudly).
#   3. Launching with ANTIALIAS=TRUE (this test's QA-OPTIONS) doesn't crash.
#
# NOTE: AA-*on* visual quality is inherently visual and NOT machine-checkable —
# a human reviews the soft brush/line rendering. This test only guards the flag
# plumbing, the AA-off invariant structure, and an AA-on non-crash smoke.
# =============================================================================

info "=== Anti-Aliasing toggle test ==="

# --- 1. Default is FALSE in the registry (reads DRAW.cfg.default) ---
OPTLIST=$( cd "$DRAW_ROOT" && timeout 15 "$DRAW_BIN" --options-list 2>/dev/null )
if grep -qE '^[[:space:]]*ANTIALIAS[[:space:]]+=[[:space:]]+FALSE' <<<"$OPTLIST"; then
    pass "ANTIALIAS defaults to FALSE in --options-list"
else
    fail "ANTIALIAS is missing or not defaulting to FALSE"
fi

# --- 2. Source-route guard: AA-off keeps the verbatim original path ---
if grep -q 'IF CFG.ANTIALIAS% THEN' "$DRAW_ROOT/TOOLS/BRUSH.BM" \
   && grep -q 'PAINT_draw_filled_circle ' "$DRAW_ROOT/TOOLS/BRUSH.BM"; then
    pass "brush stamp keeps AA gate + verbatim hard-circle branch"
else
    fail "brush stamp AA gate or hard-circle fallback missing"
fi
if grep -q 'IF CFG.ANTIALIAS% AND (BRUSH_SIZE_pixels% <= 1) THEN' "$DRAW_ROOT/TOOLS/LINE.BM"; then
    pass "line tool keeps gated Wu-AA route with Bresenham fallback"
else
    fail "line tool AA route/guard missing"
fi

# --- 3. AA-on smoke (this test's instance launched with ANTIALIAS=TRUE) ---
wait_for 1 "idle render with AA on"
screenshot "antialias-on-launch"
assert_no_crash
assert_window_exists
info "=== Anti-Aliasing toggle test PASSED ==="
