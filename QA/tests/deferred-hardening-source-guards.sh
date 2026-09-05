#!/bin/bash
# =============================================================================
# deferred-hardening-source-guards.sh — QA regression guard (SOURCE-level)
#
# Guards the six deferred/UNVERIFIED Field Kit hardening fixes shipped 2026-08-31
# (BUG-21, 37, 39, 69, 76, 77). These defend against ADVERSARIAL or EDGE inputs —
# a corrupt .aseprite / .TDX, a >32767px image, untrusted cross-instance layer
# metadata, an async job finishing on a busy frame. None of those inputs can be
# synthesized in the xdotool GUI harness (they need crafted binary fixtures or an
# impractically huge image), so a behavioral test is not feasible here.
#
# Instead this is a SOURCE-regression guard: it asserts each fix's guard logic is
# still present in the code, so a future refactor cannot silently delete it. It
# FAILS (red) the moment a guard goes missing — exactly the "must fail on the
# buggy build" contract, applied at the source layer. It launches nothing.
#
# Behavioral fixtures for these paths (a corrupt-cel .aseprite, an out-of-bounds
# .TDX, a synthetic clipboard blendMode) are a follow-up for Rick.
#
# Run directly:  bash QA/tests/deferred-hardening-source-guards.sh
# =============================================================================

# Resolve repo root (this file lives in <root>/QA/tests/).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"

fails=0
# When SOURCED by the QA harness (runner.sh does `source "$test_file"`), use
# ITS pass/fail so a missing guard bumps the suite's FAIL counter and registers
# as a real failure. Define fallbacks ONLY for standalone `bash <this>` runs —
# never redefine the harness's, or a failure would be invisible to the suite.
# Shared source-guard scaffolding (pass/fail/assert_grep/assert_absent/guard_footer).
source "$(dirname "${BASH_SOURCE[0]}")/lib/source-guard.sh"

echo "=== Deferred hardening source guards (BUG-21/37/39/69/76/77) ==="

# BUG-21 — AI job undo recorded UNCONDITIONALLY (the NOT HISTORY_saved_this_frame% gate is gone).
assert_grep  "BUG-21" "AI/AI-JOB.BM" 'HISTORY_record_transform .*"AI Generate"' "AI Generate undo is recorded"
assert_absent "BUG-21" "AI/AI-JOB.BM" 'IF NOT HISTORY_saved_this_frame%' "one-shot undo no longer gated on the shared frame flag"

# BUG-37 — the slot-walk adopts the claimed slot as identity.
assert_grep  "BUG-37" "CORE/INSTANCE.BM" 'INST\.id% *= *i%' "walk sets INST.id% = claimed slot i"

# BUG-39 — pasted/sent blendMode is range-clamped like opacity.
assert_grep  "BUG-39" "TOOLS/LAYERXFER.BM" 'blv% >= BLEND_NORMAL AND blv% <= BLEND_MODE_COUNT - 1' "blendMode clamped to 0..18"

# BUG-76 — .TDX face records validated against the font file, load-time + render-time.
assert_grep  "BUG-76" "GUI/TDF-FONT.BM" 'TDF_BLOCK_OFFSET \+ rec\.blockSz\) > tdxTgtLen&' "load-time extent check skips out-of-range faces"
assert_grep  "BUG-76" "GUI/TDF-FONT.BM" 'TDF_BLOCK_OFFSET \+ blockSize&\) > LOF\(fh%\)' "render-time extent re-check"

# BUG-77 — PIXEL-COACH refuses >32767px images.
assert_grep  "BUG-77" "PIXEL-COACH/PRECOMPUTE.BM" 'coachRawW& > 32767 OR coachRawH& > 32767' "refuse images over 32767 per side"

# BUG-69 — Aseprite cel size computed in 64-bit with an overflow guard (submodule).
assert_grep  "BUG-69" "includes/QB64_GJ_LIB/ASEPRITE/ASEPRITE.BM" 'esz64 <= 0 OR esz64 > 2147483647' "64-bit overflow guard on expected_size"

guard_footer "a hardening fix was removed"
# Tests are SOURCED by the harness — an `exit` here would kill the runner
# mid-suite (it aborted the whole suite at this test before this was fixed).
# Only exit when run standalone; when sourced, pass/fail already recorded above.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then [ "$fails" -eq 0 ] && exit 0 || exit 1; fi
