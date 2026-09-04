#!/bin/bash
# =============================================================================
# seam-music-central.sh — Phase 2A: music transport keys via CENTRAL DISPATCH
#
# The music transport shortcuts migrated from legacy INKEY$ handlers to the
# central input dispatcher:
#
#   {  (keycode 123) -> action 428  Prev music track
#   }  (keycode 125) -> action 427  Next music track
#   *  (keycode  42) -> action 433  Random music track
#
# The CMD handlers (427/428/433) already existed; MUSIC_next_track /
# MUSIC_prev_track self-guard on CFG.MUSIC_ENABLED%, and CASE 433 is guarded so
# the migrated '*' no-ops when music is off (parity with the old key handler).
#
# WHY source-level: music is AUDIO — there is no visual region to diff, and the
# offscreen Xvfb harness has no audio device, so a behavioural region test can't
# observe track changes. The dispatch itself is proven live via --developer
# (inputs.log shows [FIRE] action=427/428/433). THIS test guards that the three
# dispatched bindings are present AND the legacy handlers are gone, so a refactor
# can't silently resurrect the old double-dispatch path. It launches nothing.
#
# Run directly:  bash QA/tests/seam-music-central.sh
# =============================================================================

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"

# Shared source-guard scaffolding (pass/fail/assert_grep/assert_absent/guard_footer).
source "$(dirname "${BASH_SOURCE[0]}")/lib/source-guard.sh"

echo "=== Music transport central-dispatch source guards ==="

# -- Registry: the three dispatched bindings exist (keycode -> action) --------
assert_grep "REG" "INPUT/INPUT.BM" 'INPUT_register_key%\(123, 0, allMods%, 0, .*, 428, TRUE' "{ -> 428 dispatched=TRUE"
assert_grep "REG" "INPUT/INPUT.BM" 'INPUT_register_key%\(125, 0, allMods%, 0, .*, 427, TRUE' "} -> 427 dispatched=TRUE"
assert_grep "REG" "INPUT/INPUT.BM" 'INPUT_register_key%\(42, 0, allMods%, 0, .*, 433, TRUE'  "* -> 433 dispatched=TRUE"

# -- Legacy handlers removed (no INKEY$ CMD_execute_action for these) ---------
assert_absent "LEG" "INPUT/KEYBOARD.BM" 'CMD_execute_action 428' "legacy { handler removed"
assert_absent "LEG" "INPUT/KEYBOARD.BM" 'CMD_execute_action 427' "legacy } handler removed"
assert_absent "LEG" "INPUT/KEYBOARD.BM" 'CMD_execute_action 433' "legacy * handler removed"

# -- '*' no-op-when-off parity: CASE 433 guarded on MUSIC_ENABLED -------------
assert_grep "GUARD" "GUI/COMMAND.BM" 'IF CFG\.MUSIC_ENABLED% THEN MUSIC_play_random' "CASE 433 guards MUSIC_ENABLED"

guard_footer "a music-key migration guard was removed"
if [ "${BASH_SOURCE[0]}" = "$0" ]; then [ "$fails" -eq 0 ] && exit 0 || exit 1; fi
