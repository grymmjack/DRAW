#!/bin/bash
# =============================================================================
# ai-dialog-dropdowns.sh — QA test: the File > New from AI dialog's Tool /
# Style / Preset dropdowns open on a click (a list drops below the combo) and
# close again on a second click.
# Rick, 2026-11-06: "the dropdown menus in the NEW FROM AI are not working...
# they don't open."
# QA-OPTIONS: AI_ENABLED=-1
# =============================================================================
info "=== AI dialog dropdowns Test ==="
canvas_focus v
wait_for 0.3 "ready"
click $(( WORK_LEFT + 12 )) 6; wait_for 0.6 "FILE menu"
click $(( WORK_LEFT + 40 )) 80; wait_for 1.5 "AI dialog open"
screenshot "ai-dlg-open"
# the dialog (338x369 viewport px) is centred in the viewport; its Tool /
# Style / Preset combos sit 33 / 55 / 77 px below its top, from x + 70
DX=$(( (VIEWPORT_W - 338) / 2 )); DY=$(( (VIEWPORT_H - 369) / 2 ))
for row in "Tool 33" "Style 55" "Preset 77"; do
    set -- $row; name=$1; cy=$(( DY + $2 ))
    snap_region $(( DX + 70 )) $(( cy + 12 )) 250 40 "ai-$name-closed"; CLOSED=$SNAP_RESULT
    click $(( DX + 190 )) "$cy"; wait_for 0.6 "$name clicked"
    snap_region $(( DX + 70 )) $(( cy + 12 )) 250 40 "ai-$name-open"; OPEN=$SNAP_RESULT
    screenshot "ai-dlg-$name-open"
    assert_regions_differ "$CLOSED" "$OPEN" "the $name dropdown opens a list"
    click $(( DX + 190 )) "$cy"; wait_for 0.6 "$name clicked again"
    snap_region $(( DX + 70 )) $(( cy + 12 )) 250 40 "ai-$name-reclosed"
    assert_regions_same "$CLOSED" "$SNAP_RESULT" "a second click closes the $name list" 40
done
assert_no_crash
key Escape; wait_for 0.5 "closed"
info "=== AI dialog dropdowns Test PASSED ==="
