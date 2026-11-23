#!/bin/bash
# =============================================================================
# canvas-recording.sh — QA test: canvas recording, the time-lapse (TOOLS/CANVAS-REC;
# Rick 2026-11-22: "keep it always on if it's low overhead? A rec button to make it
# obvious though. And make it toggle for users" / "Inside the .draw file would be great").
#   1. a picture opened: one frame (START), the whole picture
#   2. three brush dabs: three frames; Ctrl+Z / Ctrl+Y: an UNDO and a REDO frame
#   3. the status bar REC badge pauses: a dab adds nothing; again resumes: that dab's frame
#   4. View: Canvas Recording plays it (a screenshot; Escape closes)
#   5. Ctrl+S: the PNG holds a drRc chunk (version 1, the frame count); reopened, the
#      recording is back, no frame added
#   6. Canvas Recording: Delete (asks): one frame again (the picture now)
#   7. Canvas Recording: On / Off: off, a dab adds nothing; on again: its frame
# Dump: CREC on paused frames bytes thinned pending badgeX1 badgeX2 barY1 barY2 last-name.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE ANTIALIAS=FALSE CANVAS_RECORDING=TRUE CANVAS_RECORDING_MB=64
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Canvas recording (time-lapse) ==="

CR_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
CR_DIR="$(mktemp -d /tmp/draw-qa-crec-XXXXXX)"
magick -size 160x120 "xc:#808080" "PNG32:$CR_DIR/pic.png" # grey: a dab of any colour changes it

# a mouse move renders a frame, so the dump is current
cr_read() { hover 300 250; wait_for 0.3 "render"; hover 306 252; dk_settle
    read -r _ C_ON C_PAU C_N C_B C_TH C_PEND C_BX1 C_BX2 C_BY1 C_BY2 C_LB <<< "$(grep -m1 '^CREC ' "$DK_DUMP")"; }
cr_s() { echo "on $C_ON paused $C_PAU frames $C_N bytes $C_B pending $C_PEND last '$C_LB'"; }
cr_badge() { cr_read; click $(( (C_BX1 + C_BX2) / 2 )) $(( (C_BY1 + C_BY2) / 2 )); wait_for 0.6 "REC badge"; dk_park; }
pcmd() { dk_park; key question; wait_for 1.0 "command palette"; type_text "$1"; wait_for 0.6 "filtered"; key Return; wait_for 1.0 "$1"; dk_park; dk_settle; }
DX=$CANVAS_CX; DY=$CANVAS_CY
dab() { click $(( DX + $1 )) "$DY"; wait_for 0.6 "dab $1"; }

draw_quit
draw_settle
DRAW_EXTRA_ARGS="$CR_DIR/pic.png"
draw_launch 15
wait_for 1.5 "picture loaded"
assert_no_crash

# --- 1. the start frame ---------------------------------------------------------------------
cr_read
if [[ -z "$C_N" ]]; then
    fail "no CREC line in the dump (a DRAW without canvas recording?)"
else
    (( C_ON != 0 && C_PAU == 0 && C_N == 1 )) && [[ "$C_LB" == START ]] && pass "opened: recording, one frame (START)" || fail "at open: $(cr_s)"

    # --- 2. dabs, undo, redo ----------------------------------------------------------------
    key b; wait_for 0.3 "brush tool"
    dab -30; dab 0; dab 30
    cr_read
    (( C_N == 4 && C_B > 0 )) && [[ "$C_LB" != START && "$C_LB" != - ]] && pass "three dabs: three frames (last '$C_LB', $C_B bytes)" || fail "after 3 dabs: $(cr_s)"
    key ctrl+z; wait_for 0.6 "undo"; cr_read
    (( C_N == 5 )) && [[ "$C_LB" == UNDO ]] && pass "Ctrl+Z: an UNDO frame" || fail "after undo: $(cr_s)"
    key ctrl+y; wait_for 0.6 "redo"; cr_read
    (( C_N == 6 )) && [[ "$C_LB" == REDO ]] && pass "Ctrl+Y: a REDO frame" || fail "after redo: $(cr_s)"

    # --- 3. the REC badge ---------------------------------------------------------------------
    (( C_BX2 > C_BX1 && C_BX1 > 0 )) && pass "the REC badge is on the status bar (x $C_BX1-$C_BX2)" || fail "no badge bounds: $C_BX1 $C_BX2"
    snap_region "$C_BX1" "$C_BY1" $(( C_BX2 - C_BX1 + 1 )) $(( C_BY2 - C_BY1 + 1 )) "crec-badge-rec"; BADGE_REC="$SNAP_RESULT"
    cr_badge; cr_read
    (( C_PAU != 0 )) && pass "a click on the badge pauses" || fail "after the badge click: $(cr_s)"
    snap_region "$C_BX1" "$C_BY1" $(( C_BX2 - C_BX1 + 1 )) $(( C_BY2 - C_BY1 + 1 )) "crec-badge-paused"
    assert_regions_differ "$BADGE_REC" "$SNAP_RESULT" "the badge shows it (REC PAUSED)"
    screenshot "canvas-recording-paused"
    dab 0; dab 15; cr_read
    (( C_N == 6 )) && pass "paused: dabs add no frame" || fail "paused, after dabs: $(cr_s)"
    cr_badge; cr_read
    (( C_PAU == 0 && C_N == 7 )) && pass "again: resumed, what changed while paused is one frame" || fail "resumed: $(cr_s)"

    # --- 4. the viewer --------------------------------------------------------------------------
    pcmd "View: Canvas Recording"; wait_for 0.8 "viewer"
    screenshot "canvas-recording-viewer"
    key End; wait_for 0.5 "last frame"; screenshot "canvas-recording-viewer-end"
    key Escape; wait_for 0.8 "closed"; dk_park
    assert_no_crash
    cr_read
    (( C_N == 7 )) && pass "the viewer adds nothing" || fail "after the viewer: $(cr_s)"

    # --- 5. saved and back ----------------------------------------------------------------------
    key ctrl+s; wait_for 1.5 "saved"
    CR_HEX=$(python3 "$CR_PY" get "$CR_DIR/pic.png" drRc 2>/dev/null | cut -c1-12)
    [[ "$CR_HEX" == 010007000000 ]] && pass "Ctrl+S: a drRc chunk, version 1, 7 frames" || fail "drRc chunk starts '$CR_HEX' (want 010007000000)"
    draw_quit
    draw_settle
    draw_launch 15
    wait_for 1.5 "saved picture loaded"
    assert_no_crash
    cr_read
    (( C_N == 7 && C_PAU == 0 )) && pass "reopened: the 7 frames are back, no frame added" || fail "reopened: $(cr_s)"

    # --- 6. delete ------------------------------------------------------------------------------
    pcmd "Canvas Recording: Delete"; key Return; wait_for 1.0 "answered"; dk_park
    cr_read
    (( C_N == 1 )) && [[ "$C_LB" == START ]] && pass "Delete (asks): one frame again, the picture now" || fail "after delete: $(cr_s)"

    # --- 7. the setting -------------------------------------------------------------------------
    key b; wait_for 0.3 "brush tool"
    pcmd "Canvas Recording: On / Off"; cr_read
    (( C_ON == 0 )) && pass "On / Off: off" || fail "toggled: $(cr_s)"
    dab -20; cr_read
    (( C_N == 1 )) && pass "off: a dab adds nothing" || fail "off, after a dab: $(cr_s)"
    pcmd "Canvas Recording: On / Off"; cr_read
    (( C_ON != 0 && C_N == 2 )) && pass "on again: that dab is a frame" || fail "on again: $(cr_s)"
fi
assert_no_crash

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$CR_DIR"
assert_window_exists
