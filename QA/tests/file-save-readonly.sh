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
#
# HARDENED (2026-09-09): this test used to type an absolute path that the custom
# file dialog MANGLED (it joined the typed path onto the browse dir, yielding
# <curdir>/<abs>, a non-existent directory) — so "no file written" passed for the
# WRONG reason (bad path), never actually exercising the read-only guard. The FD
# now honors an absolute path typed in the FILENAME field (FD-INPUT.BM), so the
# refusal is genuinely about permissions. To prove that, a WRITABLE control save
# runs first: it must land a file (which also guards against a regression of the
# FD absolute-path fix), so the read-only "not created" is a real negative.
# =============================================================================

info "=== Save Into Read-Only Directory ==="

WR_DIR="$HOME/.cache/DRAW-qa-writable-$$"
RO_DIR="$HOME/.cache/DRAW-qa-readonly-$$"
rm -rf "$WR_DIR" "$RO_DIR"
mkdir -p "$WR_DIR"; chmod 755 "$WR_DIR"
mkdir -p "$RO_DIR"; chmod 555 "$RO_DIR"
trap 'chmod 755 "$RO_DIR" 2>/dev/null; rm -rf "$WR_DIR" "$RO_DIR"' EXIT
info "writable control : $WR_DIR"
info "read-only target : $RO_DIR"

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

# ---------------------------------------------------------------------------
# 1. Read-only case FIRST (while the document is still dirty)
# ---------------------------------------------------------------------------
info "File > Save As into the read-only directory (absolute path)"
key ctrl+shift+s
wait_for 1.2 "Save dialog open"
screenshot "save-readonly-dialog"
type_text "$RO_DIR/qa-readonly.png"
wait_for 0.3 "Path typed"
key Return
wait_for 1.5 "Save attempted"
assert_no_crash
screenshot "save-readonly-refused"

# -- Dismiss whatever dialog is up (the "Cannot Save Here" warning, then the FD) --
key Return
wait_for 0.5 "Dismiss warning"
key Escape
wait_for 0.5 "Escape any remaining dialog"
assert_no_crash

# -- The file must NOT exist in the read-only directory --
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

# ---------------------------------------------------------------------------
# 2. Writable control — the SAME kind of save into a writable dir MUST succeed.
#    This proves the read-only "not created" above was a genuine permission
#    refusal (not a mangled path), and regression-guards the FD absolute-path fix.
# ---------------------------------------------------------------------------
info "Control: File > Save As into a WRITABLE directory (absolute path) — must land"
key ctrl+shift+s
wait_for 1.2 "Save dialog open"
type_text "$WR_DIR/qa-writable.png"
wait_for 0.3 "Path typed"
key Return
wait_for 1.5 "Save attempted"
assert_no_crash
# Dismiss any residual dialog (there should be none on success)
key Escape
wait_for 0.4 "Escape any residual dialog"

if [[ -s "$WR_DIR/qa-writable.png" ]]; then
    pass "Writable absolute-path save landed a file ($(stat -c%s "$WR_DIR/qa-writable.png" 2>/dev/null) bytes)"
else
    fail "Writable absolute-path save produced no file — the FD may be mangling absolute paths again"
fi

screenshot "save-readonly-final"
assert_no_crash
