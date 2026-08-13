#!/bin/bash
# =============================================================================
# keyboard-singles.sh — T4: single-key bindings.
#
# The bulk of "keyboard singles" is tool selection: each tool key sets
# CURRENT_TOOL, which moves the highlighted button in the toolbar. We press a
# sweep of DISTINCT tool keys and assert the toolbar highlight changes on every
# transition, then round-trip back to the first tool and confirm the toolbar
# matches — proving the keys are live and each selects its own tool.
#
# Tool keys (KEYBOARD_tools): b=brush f=fill d=dot l=line p=polygon r=rect
# c=ellipse q=bezier m=marquee w=wand v=move i=picker. We use a subset whose
# buttons all sit in the docked toolbar column (right edge, x 862..958).
# =============================================================================

TB_X=864; TB_Y=14; TB_W=90; TB_H=384      # toolbar column (holds the tool buttons)

info "=== Keyboard singles (T4) ==="
canvas_focus b
wait_for 0.3 "brush tool ready"

# Round-trip anchor: snapshot the toolbar with the brush selected.
key b
wait_for 0.2 "brush selected"
park_mouse
snap_region $TB_X $TB_Y $TB_W $TB_H "ks-tool-b-anchor"
ANCHOR_B="$SNAP_RESULT"

# Sweep distinct tool keys; each transition must move the toolbar highlight.
SWEEP="d l r c m v i f"
PREV="$ANCHOR_B"; PREVK="b"
for k in $SWEEP; do
    key "$k"
    wait_for 0.2 "tool '$k' selected"
    park_mouse
    snap_region $TB_X $TB_Y $TB_W $TB_H "ks-tool-$k"
    assert_regions_differ "$PREV" "$SNAP_RESULT" \
        "key '$k' must select a distinct tool (toolbar highlight moves from '$PREVK')"
    PREV="$SNAP_RESULT"; PREVK="$k"
    assert_no_crash
done

# Round-trip: back to brush — the toolbar must match the brush anchor again.
key b
wait_for 0.2 "back to brush"
park_mouse
snap_region $TB_X $TB_Y $TB_W $TB_H "ks-tool-b-return"
assert_regions_same "$ANCHOR_B" "$SNAP_RESULT" \
    "key 'b' must return to the brush tool (toolbar matches the initial brush state)"

# Esc must be handled without crashing (cancels any in-progress op / clears focus).
info "Esc is handled cleanly"
key Escape
wait_for 0.2 "escape handled"
assert_no_crash

assert_window_exists
info "=== Keyboard singles (T4) PASSED ==="
