#!/bin/bash
# =============================================================================
# group-lane-ids.sh — QA test: a new layer / group never takes an id in use
# (GUI/LAYERS LAYERS_alloc_history_id& / LAYERS_history_ids_sync / _repair).
#
# Rick 2026-11-16: "when i group a few layers into a new group, the automation
# copies to the group itself ... removing the lane on the group removed it from
# the ball". The lanes are keyed by historyId; the Aseprite / PSD importers set
# the next id to LAYER_COUNT + 1 after handing ids out, and the .draw built from
# one (SAMPLES/XSHEET/bounce.draw) saved that, so a new group took the ball's id
# and shared its lanes.
#
#   - SAMPLES/XSHEET/bounce.draw opened: its lane entries (LLN id slot ...)
#   - Ctrl+G three times (new groups): as many layers keyed as before (record
#     dots 2 / 3) - before the fix the first new group came up keyed (purple)
#   - Ctrl+Z x3: the lanes as they were
#
# Dump: LLN entry id slot lanes..., XLREC on liveSlot mask slot:dot...
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0
# =============================================================================
info "=== Layers: a new group never shares a layer's id (lanes) ==="

GI_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
GI_DIR="/tmp/draw-qa-groupids-$$"
mkdir -p "$GI_DIR"
cp "$DRAW_ROOT/SAMPLES/XSHEET/bounce.draw" "$GI_DIR/bounce.draw"

gi_read() {
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2
    LLN="$(grep '^LLN ' "$GI_DUMP" 2>/dev/null | cut -d' ' -f3- | sort | tr '\n' '|')"
    XLREC=($(grep -m1 '^XLREC ' "$GI_DUMP" 2>/dev/null))
}
gi_keyed() { local e n=0; for e in "${XLREC[@]:4}"; do [[ "$e" == *:2 || "$e" == *:3 ]] && n=$(( n + 1 )); done; echo $n; } # layers with keys
gi_key() { park_mouse; key "$1"; wait_for 0.8 "$1"; gi_read; }

draw_quit
draw_settle
DRAW_EXTRA_ARGS="$GI_DIR/bounce.draw"
draw_launch 15
wait_for 2.0 "bounce.draw"
assert_no_crash
gi_read
LLN0="$LLN"
if [[ -z "$LLN0" ]]; then
    fail "bounce.draw: no lane entries in the dump [$(grep -c '^LLN' "$GI_DUMP" 2>/dev/null)]"
else
    pass "bounce.draw open: lane entries [$LLN0]"
    K0=$(gi_keyed); D0="${XLREC[*]:4}"
    BAD=""
    for n in 1 2 3; do
        gi_key ctrl+g
        [[ "$(gi_keyed)" == "$K0" ]] || BAD="$BAD after group $n: ${XLREC[*]:4};"
    done
    [[ -z "$BAD" ]] && pass "Ctrl+G x3: still $K0 keyed layer(s), no new group keyed (dots: ${XLREC[*]:4})" || fail "a new group came up keyed (was $K0: $D0):$BAD"
    [[ "$LLN" == "$LLN0" ]] && pass "the lane entries unchanged (no entry moved to a group's slot)" || fail "lanes now [$LLN], were [$LLN0]"
    screenshot "group-lane-ids"
    for n in 1 2 3; do gi_key ctrl+z; done
    [[ "$LLN" == "$LLN0" ]] && pass "Ctrl+Z x3: the lanes as they were" || fail "after undo: [$LLN] (were [$LLN0])"
fi
assert_no_crash
rm -rf "$GI_DIR"

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
assert_window_exists
