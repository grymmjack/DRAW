#!/bin/bash
# =============================================================================
# clip-drop.sh — QA test: an animated GIF dropped on the canvas becomes a clip
# (TOOLS/CLIP CLIP_drop_file%, INPUT/DROP; phase 2 K4).
#
#   - a 3-frame GIF (a 3x3 square, red / green / blue) dropped on frame 4 of a
#     6-frame sheet (sheet view): a clip layer, In 4, its cels in frames 4-6,
#     centred on the drop point; its source is named after the file
#   - Ctrl+Z takes the clip away
#   - a one-frame GIF and a plain PNG dropped there: no clip (a picture, as before)
#
# The OS drop is the QA stand-in: the path written to <DOCK_DUMP>.drop is
# queued at the pointer (DROP_qa_poll).
# Dump: CLIP / CLIPC / CLIPX / CLIPS (clip-lib.sh), ANIMC (Layer 1's cells).
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 LIGHTBOX_PANES=3 LIGHTBOX_STRIP_FLOW=ROW
# =============================================================================
info "=== Clip layers: drop an animated GIF on the canvas ==="
source "$DRAW_ROOT/QA/clip-lib.sh"
for c in ff0000 00ff00 0000ff; do
    magick -size 8x8 xc:none -fill "#$c" -draw "rectangle 2,2 4,4" "PNG32:$CL_DIR/g$c.png"
done
magick -dispose Background -delay 10 "$CL_DIR/gff0000.png" "$CL_DIR/g00ff00.png" "$CL_DIR/g0000ff.png" -loop 0 "$CL_DIR/walk.gif"
magick "$CL_DIR/gff0000.png" "$CL_DIR/one.gif"
cp "$CL_DIR/gff0000.png" "$CL_DIR/still.png"
cd_nclips() { grep -c '^CLIP ' "$CL_DUMPF"; }
cd_animc() { cl_line ANIMC | cut -d' ' -f2-; }
cd_drop() { # FILE CX CY - the pointer on canvas px (CX, CY), then the stand-in drop
    hover "$(cl_cx "$2")" "$(cl_cy "$3")"; wait_for 0.3 "pointer at the drop point"
    echo "$1" > "$CL_DUMPF.drop"
    wait_for 1.2 "drop $(basename "$1")"
    cl_read
}

if [[ -s "$CL_DIR/clip.draw" && -s "$CL_DIR/walk.gif" ]]; then
    draw_quit; draw_settle
    DRAW_EXTRA_ARGS="$CL_DIR/clip.draw"
    draw_launch 15
    wait_for 1.5 "Sheet loaded"
    assert_no_crash
    rm -f "$CL_DUMPF.drop"
    park_mouse; cl_read
    B0=$(cd_animc)

    # -- the animated GIF on frame 4 --
    cd_drop "$CL_DIR/walk.gif" 56 8
    [[ "$C_LINE" == "1 4 0 1 1 LOOP 0 0 7 7" && "$C_CELS" == "...123" ]] \
        && pass "the GIF dropped on frame 4: a clip from frame 4, centred on the drop point" || fail "GIF drop: $(cl_s)"
    [[ "$C_PIX" == *"4:7:7:3:3:ff0000:ff0000"* && "$C_PIX" == *"5:7:7:3:3:00ff00:00ff00"* && "$C_PIX" == *"6:7:7:3:3:0000ff:0000ff"* ]] \
        && pass "frames 4-6 show the GIF's frames in turn" || fail "GIF clip pixels [$C_PIX]"
    [[ "$C_SRCS" == "1 3 3 3 0 walk"* ]] && pass "its source: 3 cels of 3x3, named after the file" || fail "CLIPS [$C_SRCS]"
    [[ "$(cd_animc)" == "$B0" ]] && pass "Layer 1 untouched" || fail "Layer 1 [$(cd_animc)] (was [$B0])"
    screenshot "clip-drop-gif"
    cl_key ctrl+z; cl_read
    [[ "$(cd_nclips)" == 0 ]] && pass "Ctrl+Z: no clip" || fail "undo the drop: $(cd_nclips) clips"

    # -- one frame, a plain PNG: pictures, as before --
    cd_drop "$CL_DIR/one.gif" 56 8
    [[ "$(cd_nclips)" == 0 ]] && pass "a one-frame GIF: no clip" || fail "one-frame GIF made a clip: $(cl_s)"
    cl_key ctrl+z
    cd_drop "$CL_DIR/still.png" 56 8
    [[ "$(cd_nclips)" == 0 && "$(cd_animc)" != "$B0" ]] && pass "a plain PNG: stamped on Layer 1, no clip" \
        || fail "plain PNG: $(cd_nclips) clips, Layer 1 changed: $([[ "$(cd_animc)" != "$B0" ]] && echo yes || echo no)"
    rm -f "$CL_DUMPF.drop"
else
    fail "fixtures: $(ls "$CL_DIR")"
fi
cl_done
info "=== Clip layers: drop: done ==="
