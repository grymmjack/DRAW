#!/bin/bash
# =============================================================================
# canvas-recording-save.sh — QA test: what goes into the file, and the viewer's export
# buttons (TOOLS/CANVAS-REC).
#   1. Save As a new PNG asks "keep this document's canvas recording?": Yes - the file
#      holds the drRc chunk with every frame
#   2. Save As another PNG, No - the file has no drRc (the picture and its layers only),
#      and the document says so (dump CRECT omit)
#   3. a later Ctrl+S of that document leaves the recording out too
#   4. View > Canvas Recording: EXPORT APNG... / EXPORT GIF... / EXPORT PNGS... write their
#      files (a frame each), CLOSE closes; nothing is added to the recording
# The file dialogs open in $HOME (the QA config has no save dirs): only base names are typed,
# and every file is removed at the end. The viewer is modal, so it writes its geometry to
# DOCK_DUMP + ".crecv" (CRECV x y scale bw b2w btnY btn2Y frame).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE ANTIALIAS=FALSE CANVAS_RECORDING=TRUE CANVAS_RECORDING_MB=64
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Canvas recording: Save As keeps or drops it; the viewer's export buttons ==="

CS_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
CS_DIR="$(mktemp -d /tmp/draw-qa-crecsave-XXXXXX)"
magick -size 160x120 "xc:#808080" "PNG32:$CS_DIR/pic.png"
CS_TAG="draw-qa-crec-$$"
CS_KEEP="$CS_TAG-keep.png"; CS_DROP="$CS_TAG-drop.png"
CS_APNG="$CS_TAG-anim.apng"; CS_GIF="$CS_TAG-anim.gif"; CS_SEQ="$CS_TAG-seq.png"
cs_clean() { rm -f "$HOME/$CS_TAG"-* "$DK_DUMP.crecv"; }
cs_clean

cs_read() { hover 300 250; wait_for 0.3 "render"; hover 306 252; dk_settle
    read -r _ C_ON C_PAU C_N C_B _ <<< "$(grep -m1 '^CREC ' "$DK_DUMP")"
    read -r _ _ _ _ C_OMIT <<< "$(grep -m1 '^CRECT ' "$DK_DUMP")"; }
pcmd() { dk_park; key question; wait_for 1.0 "command palette"; type_text "$1"; wait_for 0.6 "filtered"; key Return; wait_for 1.0 "$1"; }
DX=$CANVAS_CX; DY=$CANVAS_CY
dab() { click $(( DX + $1 )) "$DY"; wait_for 0.6 "dab $1"; }
# Save As NAME, then answer the keep question: yes / no
save_as() { wake_draw; key ctrl+shift+s; wait_for 1.2 "Save As"; type_text "$1"; wait_for 0.3 "typed"; key Return; wait_for 1.2 "the keep question"
    if [[ "$2" == no ]]; then key Tab; wait_for 0.3 "No"; fi
    key Return; wait_for 1.5 "saved"; dk_park; }
rc_hex() { python3 "$CS_PY" get "$1" drRc 2>/dev/null; }
# the viewer's second-row button I (0 APNG, 1 GIF, 2 PNGS, 3 CLOSE): click it
vbtn() { local x y bw b2w by b2y
    read -r _ x y _ bw b2w by b2y _ < "$DK_DUMP.crecv"
    # (dialog px x scale = window px; the dialog's scale is the display scale here, so a
    # dialog px is a viewport px - the harness's click unit)
    click $(( x + 8 + (b2w + 4) * $1 + b2w / 2 )) $(( y + b2y + 10 )); wait_for 1.0 "viewer button $1"; }
# a viewer export: button I, then the file dialog takes NAME
# (the export dialog suggests the document's name: clear the field first)
vexport() { local i; vbtn "$1"; for i in $(seq 1 48); do key BackSpace; done; wait_for 0.3 "cleared"
    type_text "$2"; wait_for 0.3 "typed"; key Return; wait_for 2.0 "exported"; }

draw_quit
draw_settle
DRAW_EXTRA_ARGS="$CS_DIR/pic.png"
draw_launch 15
wait_for 1.5 "picture loaded"
assert_no_crash
cs_read
if [[ -z "$C_N" ]]; then
    fail "no CREC line in the dump"
else
    key b; wait_for 0.3 "brush"
    dab -30; dab 0; cs_read
    (( C_N == 3 )) && pass "two dabs: 3 frames" || fail "after two dabs: $C_N frames"

    # --- 1. Save As, Yes ----------------------------------------------------------------------
    save_as "$CS_KEEP" yes
    H=$(rc_hex "$HOME/$CS_KEEP")
    [[ "${H:0:12}" == 010003000000 ]] && pass "Save As + Yes: the new PNG holds the recording (drRc, 3 frames)" || fail "Save As + Yes: drRc '${H:0:12}' in $HOME/$CS_KEEP ($(ls "$HOME/$CS_TAG"-* 2>/dev/null | tr '\n' ' '))"
    cs_read
    (( C_OMIT == 0 )) && pass "the document keeps recording into its file (omit 0)" || fail "after Yes: omit '$C_OMIT'"

    # --- 2. Save As, No ------------------------------------------------------------------------
    dab 30; cs_read; N2=$C_N
    save_as "$CS_DROP" no
    H=$(rc_hex "$HOME/$CS_DROP")
    TY=$(python3 "$CS_PY" types "$HOME/$CS_DROP" 2>/dev/null)
    [[ "$H" == none && "$TY" == *drAw* ]] && pass "Save As + No: the PNG has its layers (drAw) and no recording" || fail "Save As + No: drRc '${H:0:12}', chunks '$TY'"
    cs_read
    (( C_OMIT != 0 && C_N == N2 )) && pass "the document now saves without it (omit $C_OMIT), still recording ($C_N frames)" || fail "after No: omit '$C_OMIT', $C_N frames (want $N2)"

    # --- 3. a later Ctrl+S ---------------------------------------------------------------------
    dab 15; cs_read; N3=$C_N
    T0=$(stat -c %Y "$HOME/$CS_DROP" 2>/dev/null); sleep 1
    wake_draw; key ctrl+s; wait_for 1.5 "saved"; dk_park
    T1=$(stat -c %Y "$HOME/$CS_DROP" 2>/dev/null)
    H=$(rc_hex "$HOME/$CS_DROP")
    [[ "$T1" != "$T0" && "$H" == none ]] && pass "Ctrl+S afterwards: written again, still without the recording" || fail "Ctrl+S: mtime $T0 -> $T1, drRc '${H:0:12}'"

    # --- 4. the viewer's export buttons ----------------------------------------------------------
    rm -f "$DK_DUMP.crecv"
    pcmd "View: Canvas Recording"; wait_for 0.8 "viewer"
    if [[ ! -s "$DK_DUMP.crecv" ]]; then
        fail "the viewer wrote no geometry ($DK_DUMP.crecv)"
        key Escape; wait_for 0.6 "closed"
    else
        info "viewer: $(cat "$DK_DUMP.crecv")"
        screenshot "canvas-recording-save-viewer"
        vexport 0 "$CS_APNG"
        A=$(python3 - "$HOME/$CS_APNG" <<'EOF'
import struct, sys
try: d = open(sys.argv[1], 'rb').read()
except OSError: print("none"); sys.exit()
p = 8
while p + 8 <= len(d):
    ln, = struct.unpack('>I', d[p:p+4]); t = d[p+4:p+8]
    if t == b'acTL': print(struct.unpack('>I', d[p+8:p+12])[0]); sys.exit()
    p += 12 + ln
print("noacTL")
EOF
)
        [[ "$A" == "$N3" ]] && pass "EXPORT APNG...: an animated PNG, $A frames" || fail "EXPORT APNG...: '$A' (want $N3 frames) - $(ls "$HOME/$CS_TAG"-* 2>/dev/null | tr '\n' ' ')"
        vexport 1 "$CS_GIF"
        G=$(magick identify "$HOME/$CS_GIF" 2>/dev/null | wc -l)
        (( G == N3 )) && pass "EXPORT GIF...: an animated GIF, $G frames" || fail "EXPORT GIF...: $G frames (want $N3)"
        vexport 2 "$CS_SEQ"
        P=$(ls "$HOME/$CS_TAG-seq"_*.png 2>/dev/null | wc -l)
        (( P == N3 )) && pass "EXPORT PNGS...: $P files, one a frame" || fail "EXPORT PNGS...: $P files (want $N3)"
        screenshot "canvas-recording-save-viewer-after"
        info "export files: $(find "$HOME" "$CS_DIR" "$DRAW_ROOT" /tmp -maxdepth 4 -name "$CS_TAG-anim*" -o -maxdepth 4 -name "$CS_TAG-seq*" 2>/dev/null | head -5 | tr '\n' ' ')"
        vbtn 3; dk_park
        assert_no_crash
        cs_read
        (( C_N == N3 )) && pass "CLOSE closes it; the exports added nothing ($C_N frames)" || fail "after the viewer: $C_N frames (want $N3), dump stale?"
    fi
fi
assert_no_crash

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
cs_clean
rm -rf "$CS_DIR"
assert_window_exists
