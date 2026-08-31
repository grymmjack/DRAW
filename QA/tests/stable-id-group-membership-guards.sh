#!/bin/bash
# =============================================================================
# stable-id-group-membership-guards.sh — QA regression guard (SOURCE-level)
#
# Guards the "reference other layers by STABLE historyId&, never by raw slot
# index" fixes shipped 2026-08-31 (BUG-20 + the two AI async findings it
# surfaced). The pattern: a layer/group reference that OUTLIVES the slot it
# points at — a HISTORY undo record, or a long-lived AI job/batch global spanning
# async generation — must store the target's historyId& and resolve it back to a
# live slot on use. A raw slot index goes stale the moment LAYERS_new% recycles a
# freed slot, silently reattaching the layer to (or writing pixels onto) whatever
# now occupies that slot.
#
# None of these paths can be driven by the xdotool GUI harness: they need an undo
# performed after unrelated slot churn, or a layer deleted mid-async-generation.
# So this is a SOURCE-regression guard — it FAILS (red) the moment a fix's
# id-resolution is reverted to a raw-slot assignment.
#
# Run directly:  bash QA/tests/stable-id-group-membership-guards.sh
# =============================================================================

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"

fails=0
# When SOURCED by the QA harness (runner.sh does `source "$test_file"`), use
# ITS pass/fail so a missing guard bumps the suite's FAIL counter and registers
# as a real failure. Define fallbacks ONLY for standalone `bash <this>` runs —
# never redefine the harness's, or a failure would be invisible to the suite.
declare -F pass >/dev/null || pass() { printf '  \033[32mPASS\033[0m  %s\n' "$1"; }
declare -F fail >/dev/null || fail() { printf '  \033[31mFAIL\033[0m  %s\n' "$1"; fails=$((fails+1)); }

# assert_grep <bug> <file> <extended-regex> <human description>
assert_grep() {
  local bug="$1" file="$2" re="$3" desc="$4"
  if [ ! -f "$ROOT/$file" ]; then fail "$bug: file missing: $file"; return; fi
  if grep -Eq -- "$re" "$ROOT/$file"; then pass "$bug: $desc"; else fail "$bug: MISSING in $file — $desc"; fi
}

# assert_absent <bug> <file> <extended-regex> <human description>
assert_absent() {
  local bug="$1" file="$2" re="$3" desc="$4"
  if [ ! -f "$ROOT/$file" ]; then fail "$bug: file missing: $file"; return; fi
  if grep -Eq -- "$re" "$ROOT/$file"; then fail "$bug: REGRESSED in $file — $desc"; else pass "$bug: $desc"; fi
}

echo "=== Stable-id group/layer membership guards (BUG-20 + AI async) ==="

# NOTE: patterns are whitespace-TOLERANT ( *=* / +AS +) on purpose — DEV/align-qb64pe.py
# realigns the '=' and 'AS' columns, so any literal space count would false-fail the guard
# after an align pass even though the code is unchanged. Match tokens, not indentation.

# --- Shared helpers exist -----------------------------------------------------
assert_grep  "BUG-20" "TOOLS/HISTORY.BM" 'FUNCTION HISTORY_parent_slot_to_id&' "slot->id helper present"
assert_grep  "BUG-20" "TOOLS/HISTORY.BM" 'FUNCTION HISTORY_parent_id_to_slot%' "id->slot resolver present"

# --- Record type carries the stable-id fields ---------------------------------
assert_grep  "BUG-20" "TOOLS/HISTORY.BI" 'oldParentGroupId +AS +LONG' "record stores old parent as historyId&"
assert_grep  "BUG-20" "TOOLS/HISTORY.BI" 'newParentGroupId +AS +LONG' "record stores new parent as historyId&"
assert_grep  "BUG-20" "TOOLS/HISTORY.BI" 'parentGroupId +AS +LONG'    "merge-visible backup stores parent as historyId&"

# --- Capture side stores the PARENT ID, not the slot --------------------------
assert_grep  "BUG-20" "TOOLS/HISTORY.BM" 'oldParentGroupId& *= *HISTORY_parent_slot_to_id&' "layer add/delete capture stores parent id"
assert_grep  "BUG-20" "TOOLS/HISTORY.BM" 'newParentGroupId& *= *HISTORY_parent_slot_to_id&' "group reparent stores new parent id"

# --- Restore side RESOLVES the id back to a live slot -------------------------
# Every parentGroupIdx% restore in HISTORY must go through the id resolver.
assert_grep  "BUG-20" "TOOLS/HISTORY.BM" 'parentGroupIdx% *= *HISTORY_parent_id_to_slot%' "restore resolves parent by id"
# The old stale-slot restores must be GONE (these are the exact BUG-20 lines).
assert_absent "BUG-20" "TOOLS/HISTORY.BM" 'parentGroupIdx% *= *HISTORY_RECORDS\(recordIndex%\)\.x1%' "no raw-slot restore in create_layer_from_record"
assert_absent "BUG-20" "TOOLS/HISTORY.BM" 'parentGroupIdx% *= *HISTORY_RECORDS\(idx%\)\.(x1|y1)%'    "no raw-slot restore in reparent undo/redo"

# --- AI_JOB async target resolved by id, not the captured slot ----------------
assert_grep  "AI-JOB"   "AI/AI.BI"        'layerId +AS +LONG' "AI_JOB carries target historyId&"
assert_grep  "AI-JOB"   "AI/AI-JOB.BM"    'lyr% *= *HISTORY_find_layer_slot_by_id%\(AI_JOB\.layerId&\)' "finish resolves target by id"
assert_absent "AI-JOB"  "AI/AI-JOB.BM"    'lyr% *= *AI_JOB\.layerIdx' "finish no longer trusts the stale slot"

# --- AI_BATCH group resolved by id per item -----------------------------------
assert_grep  "AI-BATCH" "AI/AI.BI"        'groupId +AS +LONG' "AI_BATCH carries group historyId&"
assert_grep  "AI-BATCH" "AI/AI-BATCH.BM"  'batchGrpSlot% *= *HISTORY_find_layer_slot_by_id%\(AI_BATCH\.groupId&\)' "batch resolves group by id per item"
assert_absent "AI-BATCH" "AI/AI-BATCH.BM" 'parentGroupIdx% *= *AI_BATCH\.groupIdx' "batch no longer parents by the stale slot"

echo "---------------------------------------------"
if [ "$fails" -eq 0 ]; then
  echo -e "\033[32mALL STABLE-ID GUARDS PRESENT\033[0m"
else
  echo -e "\033[31m$fails GUARD(S) MISSING — a stable-id fix was reverted to raw-slot\033[0m"
fi
# Tests are SOURCED by the harness — an `exit` here would kill the runner
# mid-suite (it aborted the whole suite at this test before this was fixed).
# Only exit when run standalone; when sourced, pass/fail already recorded above.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then [ "$fails" -eq 0 ] && exit 0 || exit 1; fi
