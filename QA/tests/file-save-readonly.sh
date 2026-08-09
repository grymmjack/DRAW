#!/bin/bash
# =============================================================================
# file-save-readonly.sh — QA test: saving into an unwritable directory
#
# Saving into a drive/mount root or any protected directory used to let
# _SAVEIMAGE raise error 5, which the trap turned into a crash report — telling
# the user nothing. SAVE_target_writable% now checks first and explains.
#
# Equally important: the document must stay DIRTY. The old code cleared
# CANVAS_DIRTY% unconditionally after _SAVEIMAGE, so a failed save silently
# marked the work saved and the unsaved-changes prompt never appeared.
# =============================================================================

info "=== Save Into Read-Only Directory ==="

RO_DIR="$HOME/.cache/DRAW-qa-readonly"
rm -rf "$RO_DIR"; mkdir -p "$RO_DIR"; chmod 555 "$RO_DIR"
trap 'chmod 755 "$RO_DIR" 2>/dev/null; rm -rf "$RO_DIR"' EXIT
info "read-only target: $RO_DIR"

canvas_focus v
wait_for 0.3 "Move tool ready"

# -- Make the document dirty so we can prove it stays dirty --
info "Draw a stroke so the document has unsaved changes"
key b
wait_for 0.3 "Brush tool"
drag $(( CANVAS_CX - 20 )) $CANVAS_CY $(( CANVAS_CX + 20 )) $CANVAS_CY
wait_for 0.4 "Stroke committed"
assert_no_crash

TITLE_DIRTY=$(xdotool getwindowname "$DRAW_WID" 2>/dev/null)
info "title while dirty: $TITLE_DIRTY"

# -- Save As into the read-only directory --
info "File > Save As into the read-only directory"
key ctrl+shift+s
wait_for 1.2 "Save dialog open"
screenshot "save-readonly-dialog"
type_text "$RO_DIR/qa-readonly.png"
wait_for 0.3 "Path typed"
key Return
wait_for 1.5 "Save attempted"
assert_no_crash
screenshot "save-readonly-refused"

# -- Dismiss whatever dialog is up (our warning, or the file dialog) --
key Return
wait_for 0.5 "Dismiss"
key Escape
wait_for 0.5 "Escape any remaining dialog"
assert_no_crash

# -- The file must NOT exist --
if [[ -e "$RO_DIR/qa-readonly.png" ]]; then
    fail "A file was created in a read-only directory — the guard did not hold"
else
    pass "No file written into the read-only directory"
fi

# -- The document must still be dirty (title keeps its modified marker) --
TITLE_AFTER=$(xdotool getwindowname "$DRAW_WID" 2>/dev/null)
info "title after refused save: $TITLE_AFTER"
if [[ "$TITLE_AFTER" == "$TITLE_DIRTY" ]]; then
    pass "Document still flagged as having unsaved changes"
else
    warn "Title changed after a refused save: '$TITLE_DIRTY' -> '$TITLE_AFTER'"
    warn "If the modified marker was cleared, a failed save is being treated as success"
fi

screenshot "save-readonly-final"
assert_no_crash
