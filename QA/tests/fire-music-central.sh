#!/bin/bash
# =============================================================================
# fire-music-central.sh — BEHAVIOURAL check: music transport keys dispatch through
# the central input dispatcher (Phase 2A migration).
#
# Complements the SOURCE guard seam-music-central.sh: this drives the actual keys
# and proves the central dispatcher fires the right ACTION, via the --developer
# FIRE log (QA/tests/lib/fire-log.sh).
#
#   }  (braceright, keycode 125) -> action 427  Next music track
#   {  (braceleft,  keycode 123) -> action 428  Prev music track
#   *  (asterisk,   keycode  42) -> action 433  Random music track
#
# Requires developer mode so DRAW writes inputs.log:
#   DRAW_EXTRA_ARGS=--developer ./draw-qa.sh tests/fire-music-central.sh
# Without it, the asserts SKIP (harmless) — so this test is safe in a normal run.
# =============================================================================

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib/fire-log.sh"

info "=== Music transport central-dispatch FIRE test ==="

if ! fire_log_available; then
    info "inputs.log not present — DRAW not in developer mode."
    info "Run: DRAW_EXTRA_ARGS=--developer ./draw-qa.sh tests/fire-music-central.sh"
fi

canvas_focus b
wait_for 0.4 "Brush ready / canvas focused"

info "Press } (Next track)"
key braceright
wait_for 0.3 "dispatch }"
assert_action_fires 427 "} = Next music track"

info "Press { (Prev track)"
key braceleft
wait_for 0.3 "dispatch {"
assert_action_fires 428 "{ = Prev music track"

info "Press * (Random track)"
key asterisk
wait_for 0.3 "dispatch *"
assert_action_fires 433 "* = Random music track"

assert_no_crash
info "=== Music transport FIRE test done ==="
