#!/bin/bash
# =============================================================================
# file-save-passed-in-format.sh — QA test: saving a file passed on the command line
#
#   A. art.png passed in, Ctrl+S        -> art.png rewritten WITH layers (drAw
#                                          chunk), no art.draw
#   B. art.gif passed in, Ctrl+S        -> SAVE_DRAW_SIDECAR=TRUE (default):
#                                          art.draw written, art.gif untouched
#   C. art.gif passed in, Ctrl+S        -> SAVE_DRAW_SIDECAR=FALSE: art.gif
#                                          rewritten as a GIF, no art.draw
#   D. art.gif passed in, Ctrl+Alt+Shift+S (Flatten & Save) -> art.gif
#                                          rewritten, no art.draw
#   E. art.png passed in, Ctrl+Alt+Shift+S -> art.png rewritten flat (no drAw
#                                          chunk), no art.draw
#
# Manages its own DRAW instances; MUST restore DRAW_EXTRA_ARGS="" and leave a
# plain instance running (the harness shares this shell with later tests).
# Paths go on the command line unquoted, so they must contain no spaces.
# =============================================================================

info "=== Save passed-in file in its own format ==="

SP_DIR="$HOME/draw-qa-passed-in-$$"
rm -rf "$SP_DIR"; mkdir -p "$SP_DIR"

sp_make_images() {
    rm -f "$SP_DIR"/*
    convert -size 64x48 xc:'#3050a0' "$SP_DIR/art.png"
    convert -size 64x48 xc:'#3050a0' "$SP_DIR/art.gif"
}
sp_sum()   { md5sum "$1" 2>/dev/null | cut -d' ' -f1; }
sp_chunk() { grep -ac 'drAw' "$1" 2>/dev/null; }
sp_is()    { file -b "$1" 2>/dev/null | cut -d' ' -f1; }   # PNG / GIF

# Open $1 (plus extra args), draw a stroke, press $2.
sp_run() {
    local file="$1" keys="$2"; shift 2
    draw_quit
    sleep 1.5   # a relaunch straight after a quit can read the new window as 0x0
    DRAW_EXTRA_ARGS="$* $file"
    draw_launch 15
    wait_for 1.5 "$(basename "$file") loaded"
    assert_no_crash
    canvas_focus b
    wait_for 0.3 "Brush tool"
    drag $(( CANVAS_CX - 10 )) $CANVAS_CY $(( CANVAS_CX + 10 )) $CANVAS_CY
    wait_for 0.4 "Stroke drawn"
    wake_draw
    key "$keys"
    wait_for 1.5 "Saved"
    assert_no_crash
}

# -- A --------------------------------------------------------------------
sp_make_images
BEFORE=$(sp_sum "$SP_DIR/art.png")
info "A. art.png passed in, Ctrl+S"
sp_run "$SP_DIR/art.png" ctrl+s
if [[ "$(sp_sum "$SP_DIR/art.png")" != "$BEFORE" && "$(sp_chunk "$SP_DIR/art.png")" -gt 0 && ! -e "$SP_DIR/art.draw" ]]; then
    pass "A: Ctrl+S saved into art.png with the layers inside, no art.draw"
else
    fail "A: art.png changed=$([[ "$(sp_sum "$SP_DIR/art.png")" != "$BEFORE" ]] && echo y || echo n) drAw=$(sp_chunk "$SP_DIR/art.png") art.draw=$([[ -e "$SP_DIR/art.draw" ]] && echo y || echo n)"
fi

# -- B --------------------------------------------------------------------
sp_make_images
BEFORE=$(sp_sum "$SP_DIR/art.gif")
info "B. art.gif passed in, Ctrl+S, SAVE_DRAW_SIDECAR=TRUE"
sp_run "$SP_DIR/art.gif" ctrl+s --option SAVE_DRAW_SIDECAR=TRUE
if [[ -s "$SP_DIR/art.draw" && "$(sp_sum "$SP_DIR/art.gif")" == "$BEFORE" ]]; then
    pass "B: sidecar on - art.draw written, art.gif untouched"
else
    fail "B: art.draw=$([[ -s "$SP_DIR/art.draw" ]] && echo y || echo n) art.gif untouched=$([[ "$(sp_sum "$SP_DIR/art.gif")" == "$BEFORE" ]] && echo y || echo n)"
fi

# -- C --------------------------------------------------------------------
sp_make_images
BEFORE=$(sp_sum "$SP_DIR/art.gif")
info "C. art.gif passed in, Ctrl+S, SAVE_DRAW_SIDECAR=FALSE"
sp_run "$SP_DIR/art.gif" ctrl+s --option SAVE_DRAW_SIDECAR=FALSE
if [[ "$(sp_sum "$SP_DIR/art.gif")" != "$BEFORE" && "$(sp_is "$SP_DIR/art.gif")" == "GIF" && ! -e "$SP_DIR/art.draw" ]]; then
    pass "C: sidecar off - art.gif rewritten as a GIF, no art.draw"
else
    fail "C: art.gif changed=$([[ "$(sp_sum "$SP_DIR/art.gif")" != "$BEFORE" ]] && echo y || echo n) type=$(sp_is "$SP_DIR/art.gif") art.draw=$([[ -e "$SP_DIR/art.draw" ]] && echo y || echo n)"
fi

# -- D --------------------------------------------------------------------
sp_make_images
BEFORE=$(sp_sum "$SP_DIR/art.gif")
info "D. art.gif passed in, Ctrl+Alt+Shift+S (Flatten & Save)"
sp_run "$SP_DIR/art.gif" ctrl+alt+shift+s
if [[ "$(sp_sum "$SP_DIR/art.gif")" != "$BEFORE" && "$(sp_is "$SP_DIR/art.gif")" == "GIF" && ! -e "$SP_DIR/art.draw" ]]; then
    pass "D: Flatten & Save rewrote art.gif as a GIF, no art.draw"
else
    fail "D: art.gif changed=$([[ "$(sp_sum "$SP_DIR/art.gif")" != "$BEFORE" ]] && echo y || echo n) type=$(sp_is "$SP_DIR/art.gif") art.draw=$([[ -e "$SP_DIR/art.draw" ]] && echo y || echo n)"
    key Escape
fi

# -- E --------------------------------------------------------------------
sp_make_images
BEFORE=$(sp_sum "$SP_DIR/art.png")
info "E. art.png passed in, Ctrl+Alt+Shift+S (Flatten & Save)"
sp_run "$SP_DIR/art.png" ctrl+alt+shift+s
if [[ "$(sp_sum "$SP_DIR/art.png")" != "$BEFORE" && "$(sp_chunk "$SP_DIR/art.png")" -eq 0 && ! -e "$SP_DIR/art.draw" ]]; then
    pass "E: Flatten & Save rewrote art.png flat (no layers inside), no art.draw"
else
    fail "E: art.png changed=$([[ "$(sp_sum "$SP_DIR/art.png")" != "$BEFORE" ]] && echo y || echo n) drAw=$(sp_chunk "$SP_DIR/art.png") art.draw=$([[ -e "$SP_DIR/art.draw" ]] && echo y || echo n)"
    key Escape
fi
screenshot "passed-in-flatten-png"

# -- Cleanup: plain instance for the next test ------------------------------
rm -rf "$SP_DIR"
draw_quit
DRAW_EXTRA_ARGS=""
draw_launch 15
wait_for 0.8 "Default instance restored"
assert_no_crash
assert_window_exists
info "=== Save passed-in file Test PASSED ==="
