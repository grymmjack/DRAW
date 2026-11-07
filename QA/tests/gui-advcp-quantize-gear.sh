#!/bin/bash
# =============================================================================
# gui-advcp-quantize-gear.sh — QA test: the Advanced Color Picker's Quantize
# Steps slider (under the wheel, above the shade rows) and its gear button.
# Rick, 2026-11-07: "i would also like the quantize slider in the advanced
# color picker at the top, and a top right button that looks like a gear in -
# to open the settings to the panel -> advanced color mixer section".
#   - an ACPQ line (slider track + steps + gear) is in the dump
#   - a click at the left end of the track = OFF (0), the right end = 32,
#     the middle ~16; dragging from the left end to 1/4 = ~8
#   - the gear opens Settings on the PANELS tab with the "Advanced Color
#     Picker" section scrolled to the top; ESC closes it, the picker stays
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ADV_COLOR_PICKER_VISIBLE=1 TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Advanced Color Picker: Quantize slider + gear ==="
dk_begin
acpq() { read -r _ TX TY TW TH STEPS GX GY GW GH <<< "$(grep '^ACPQ ' "$DK_DUMP")"; }
acpq
if [[ -z "$TW" ]]; then fail "no ACPQ line in the dump (no Quantize slider)"; assert_no_crash; exit 0; fi
info "slider at $TX,$TY ${TW}x$TH, steps $STEPS; gear at $GX,$GY ${GW}x$GH"
(( TW > 40 )) && pass "the Quantize slider is shown (${TW}px wide)" || fail "the Quantize slider is ${TW}px wide"
MY=$(( TY + TH / 2 ))

click $(( TX + 1 )) "$MY"; dk_park; dk_settle; acpq
[[ "$STEPS" == "0" ]] && pass "the left end turns quantize off" || fail "the left end gave $STEPS steps, not 0"
click $(( TX + TW - 2 )) "$MY"; dk_park; dk_settle; acpq
[[ "$STEPS" == "32" ]] && pass "the right end gives 32 steps" || fail "the right end gave $STEPS steps, not 32"
click $(( TX + TW / 2 )) "$MY"; dk_park; dk_settle; acpq
(( STEPS >= 14 && STEPS <= 18 )) && pass "the middle gives ~16 steps ($STEPS)" || fail "the middle gave $STEPS steps"
drag $(( TX + 1 )) "$MY" $(( TX + TW / 4 )) "$MY"; dk_park; dk_settle; acpq
(( STEPS >= 6 && STEPS <= 10 )) && pass "dragging to 1/4 gives ~8 steps ($STEPS)" || fail "dragging to 1/4 gave $STEPS steps"

# the gear -> Settings > PANELS, at the Advanced Color Picker section
rm -f "$DK_DUMP.settings"
click $(( GX + GW / 2 )) $(( GY + GH / 2 )); sleep 1.2
if [[ ! -f "$DK_DUMP.settings" ]]; then
    fail "the gear did not open Settings"
else
    read -r _ STAB SSCROLL SSY SNAME <<< "$(tr -d "\r" < "$DK_DUMP.settings")" # (QB64 PRINT # writes CRLF)
    info "settings: tab $STAB scroll $SSCROLL section '$SNAME' at y $SSY"
    [[ "$STAB" == "3" ]] && pass "the gear opens Settings on the PANELS tab" || fail "the gear opened Settings on tab $STAB, not PANELS (3)"
    [[ "$SNAME" == "Advanced Color Picker" ]] && (( SSCROLL > 0 && SSY >= 0 && SSY < 40 )) && pass "the Advanced Color Picker section is at the top (y $SSY)" || fail "the Advanced Color Picker section is not at the top ('$SNAME' y $SSY, scroll $SSCROLL)"
    wake_draw; key Escape; sleep 1.2
fi
dk_park; dk_settle; acpq
[[ -n "$TW" ]] && pass "after Settings closes the picker is still up" || fail "the picker is gone after Settings closed"
assert_no_crash
