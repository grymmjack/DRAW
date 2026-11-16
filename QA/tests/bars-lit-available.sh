#!/bin/bash
# =============================================================================
# bars-lit-available.sh — QA test: Edit / Advanced bar button states (BUGS.md
# 2026-11-15)
#
#  - an OFF toggle (Pixel Perfect 609) is dim but still AVAILABLE: hovering it
#    outlines it (BARHOVER) - it used to answer hover only when ON
#  - an unavailable command (Undo 301 with nothing to undo, Clear Ref 1503 with
#    no reference) is not available
#  - REF ON (1501) is lit only while a reference is shown (none loaded: unlit)
#  - Angle Snap (414) toggles: lit (degrees) -> click -> unlit (pixel art) -> lit
#
# Dump: BTN <panel> i kind id name x y w h | BTNS <panel> i id lit available |
# BARHOVER <panel> <i>
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE ANGLE_SNAP_PIXEL_ART=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Bars: lit vs available ==="
dk_begin

btns() { awk -v id="$1" '$1=="BTNS" && $4==id {print $2" "$3" "$5" "$6; exit}' "$DK_DUMP"; } # ID -> panel i lit avail
btnxy() { awk -v p="$1" -v i="$2" '$1=="BTN" && $2==p && $3==i {print $7+int($9/2)" "$8+int($10/2)" "$9; exit}' "$DK_DUMP"; }

PP_P=""
for T in 2020 440 911 910 609; do # an OFF toggle on a bar: Grayscale, Tile Mode, Smart Guides, Pixel Perfect
    read -r PP_P PP_I PP_LIT PP_AV <<< "$(btns $T)"
    [[ -n "$PP_P" && "$PP_LIT" == 0 ]] && break
    PP_P=""
done
if [[ -z "$PP_P" ]]; then
    skip "no OFF toggle on a bar in this workspace"
else
    [[ "$PP_AV" == -1 ]] && pass "toggle $T off: unlit but available" || fail "$T lit '$PP_LIT' available '$PP_AV'"
    read -r BX BY BW <<< "$(btnxy "$PP_P" "$PP_I")"
    if [[ -n "$BW" && "$BW" -gt 0 ]]; then
        snap_region $(( BX - BW / 2 - 2 )) $(( BY - BW / 2 - 2 )) $(( BW + 4 )) $(( BW + 4 )) "off-toggle-idle"; IDLE="$SNAP_RESULT"
        hover "$BX" "$BY"; wait_for 0.4 "over the off toggle"; dk_settle
        snap_region $(( BX - BW / 2 - 2 )) $(( BY - BW / 2 - 2 )) $(( BW + 4 )) $(( BW + 4 )) "off-toggle-hover"
        assert_regions_differ "$IDLE" "$SNAP_RESULT" "hovering the OFF toggle draws its outline"
        HV=$(awk -v p="$PP_P" '$1=="BARHOVER" && $2==p {print $3}' "$DK_DUMP")
        [[ "$HV" == "$PP_I" ]] && pass "hovering the OFF toggle outlines it (hover $HV)" || fail "hover over the off toggle: '$HV' (want $PP_I)"
        screenshot "bars-off-toggle-hover"
        dk_park
    else
        skip "toggle $T is not drawn (scrolled away)"
    fi
fi

read -r _ _ U_LIT U_AV <<< "$(btns 301)"
[[ -z "$U_AV" || "$U_AV" == 0 ]] && pass "Undo with nothing to undo: unavailable" || fail "301 available '$U_AV'"
read -r _ _ CR_LIT CR_AV <<< "$(btns 1503)"
[[ -z "$CR_AV" || "$CR_AV" == 0 ]] && pass "Clear Reference with none loaded: unavailable" || fail "1503 available '$CR_AV'"
read -r _ _ RO_LIT RO_AV <<< "$(btns 1501)"
[[ -z "$RO_LIT" || ( "$RO_LIT" == 0 && "$RO_AV" == -1 ) ]] && pass "REF ON with none loaded: unlit, available (it loads one)" || fail "1501 lit '$RO_LIT' available '$RO_AV'"

read -r AS_P AS_I AS_LIT _ <<< "$(btns 414)"
if [[ -z "$AS_P" ]]; then
    skip "Angle Snap (414) is not on a bar in this workspace"
else
    [[ "$AS_LIT" == -1 ]] && pass "Angle Snap starts lit (degrees)" || fail "414 lit '$AS_LIT' at start"
    read -r BX BY BW <<< "$(btnxy "$AS_P" "$AS_I")"
    click "$BX" "$BY"; wait_for 0.5 "angle snap click"; dk_park; dk_settle
    read -r _ _ AS_LIT _ <<< "$(btns 414)"
    [[ "$AS_LIT" == 0 ]] && pass "a click turns Angle Snap (degrees) off (pixel art)" || fail "after a click 414 lit '$AS_LIT'"
    click "$BX" "$BY"; wait_for 0.5 "angle snap click 2"; dk_park; dk_settle
    read -r _ _ AS_LIT _ <<< "$(btns 414)"
    [[ "$AS_LIT" == -1 ]] && pass "a second click turns it back on" || fail "after the second click 414 lit '$AS_LIT'"
fi
assert_no_crash
