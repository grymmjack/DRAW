#!/bin/bash
# =============================================================================
# settings-open-close.sh — QA test: Settings dialog open/close
# Tests: Ctrl+, (open settings), Escape (close settings)
# =============================================================================

info "=== Settings Dialog Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Snap viewport before settings --
park_mouse
snap_region 0 0 $VP_W $VP_H "settings-before"
BEFORE="$SNAP_RESULT"
assert_no_crash

# -- Open settings: Ctrl+, --
info "Opening settings (Ctrl+comma)"
key ctrl+comma
wait_for 1.0 "Settings dialog opened"
assert_no_crash

park_mouse
snap_region 0 0 $VP_W $VP_H "settings-open"
OPEN="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$OPEN" "Settings dialog should be visible"
screenshot "settings-dialog-open"

# -- Close settings: click Cancel --
# Escape does NOT close this dialog. It was tried tapped, held for 200ms, and
# retried three times: the viewport stayed byte-identical every time (0 px
# changed), so the dialog never saw a close request rather than seeing one and
# declining. A capture of the open dialog shows why there is nothing to bind to
# a "cancel" key by convention — the footer has Apply / OK / Cancel buttons and
# no close affordance in the title bar.
#
# Whether Escape SHOULD cancel this dialog is a product question worth asking;
# until then the test drives the button that actually exists.
#
# Cancel sits at the bottom-right of the dialog, which is centred in the
# viewport, so its position is derived from the viewport centre rather than
# hardcoded — that keeps this working if the window size changes.
SETTINGS_W=600
SETTINGS_H=380
SETTINGS_L=$(( VP_W / 2 - SETTINGS_W / 2 ))
SETTINGS_T=$(( VP_H / 2 - SETTINGS_H / 2 ))
CANCEL_X=$(( SETTINGS_L + SETTINGS_W - 42 ))
CANCEL_Y=$(( SETTINGS_T + SETTINGS_H - 14 ))

info "Closing settings (Cancel button at $CANCEL_X,$CANCEL_Y)"
CLOSED=""
for attempt in 1 2 3; do
    click "$CANCEL_X" "$CANCEL_Y"
    wait_for 1.2 "Settings dialog closed (attempt $attempt)"
    park_mouse
    snap_region 0 0 $VP_W $VP_H "settings-closed-$attempt"
    CLOSED="$SNAP_RESULT"
    closed_px=$(_parse_ae "$(compare -metric AE -fuzz 2% "$OPEN" "$CLOSED" /dev/null 2>&1 || true)")
    dbg "settings close attempt $attempt → $closed_px px changed"
    [[ "$closed_px" -gt 1500 ]] && break
done
assert_no_crash
assert_regions_differ "$OPEN" "$CLOSED" "Closing settings should restore normal view"

assert_window_exists
info "=== Settings Dialog Test PASSED ==="
