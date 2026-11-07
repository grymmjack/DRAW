#!/bin/bash
# =============================================================================
# gui-colormixer-input.sh — QA test: Color Mixer input.
#   A) a click on the TOP rows of the SV square / hue bar picks a color (the
#      title-bar drag zone was the 24px default, taller than the drawn title,
#      and took the top of the square as a window drag)
#   B) the FG<>BG strip's FG end follows a color picked in the mixer
#   C) the hex box gets the keys: typed hex letters don't switch tools, ENTER
#      applies the color; after ENTER / a click away, DRAW's keys work again
#   D) Esc, an invalid ENTER and a click on the color square leave the box
#      and put the current color back in it
# Rick, 2026-11-07: "i can't click the top section of the color ramp at all",
# "FG <> BG isn't updating ... until I press X", "press delete/backspace ...
# it's acting on the canvas".
# Reads CMIX <sv x y w h> <hue x y w h> <hex x y w h> <focused> <FG> <BG>
# <strip FG> <strip BG>, WIN colormixer, VIEW (tool = 5th).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt COLOR_MIXER_VISIBLE=1 COLOR_MIXER_X=560 COLOR_MIXER_Y=60
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Color Mixer input Test ==="
dk_begin
cmix() { read -r _ SVX SVY SVW SVH HX HY HW HH TX TY TW TH FOC FG BG SFG SBG HEXT <<< "$(grep '^CMIX' "$DK_DUMP")"; }
win()  { read -r _ _ W_X W_Y _ <<< "$(grep '^WIN colormixer ' "$DK_DUMP")"; }
tool() { awk '$1 == "VIEW" {print $5}' "$DK_DUMP"; }
settle() { sleep 0.4; }
cmix; win
[[ -n "$SVX" ]] || { fail "no CMIX line (Color Mixer not showing?)"; exit 1; }
info "mixer at $W_X,$W_Y; SV $SVX,$SVY ${SVW}x$SVH; hue $HX,$HY; hex $TX,$TY ${TW}x$TH; FG $FG BG $BG strip $SFG..$SBG"

# ---- A) the top of the hue bar (red) and the top row of the SV square ----
click $(( HX + HW / 2 )) $(( HY + 1 )); settle
click $(( SVX + SVW - 2 )) $(( SVY + 1 )); settle
cmix; win
info "after the clicks: FG $FG, mixer at $W_X,$W_Y"
near() { # RRGGBB r g b: each channel within 16 of the target
    local c=$1; (( ${2:-0} - 16 <= 16#${c:0:2} && 16#${c:0:2} <= ${2:-0} + 16 && $3 - 16 <= 16#${c:2:2} && 16#${c:2:2} <= $3 + 16 && $4 - 16 <= 16#${c:4:2} && 16#${c:4:2} <= $4 + 16 ))
}
near "$FG" 255 0 0 \
    && pass "the top of the hue bar + the square's top-right corner pick pure red ($FG)" \
    || fail "the top of the square / hue bar did not pick (FG $FG) - taken as a title drag?"
W0X=$W_X; W0Y=$W_Y
click $(( SVX + 2 )) $(( SVY + 1 )); settle
cmix; win
near "$FG" 255 255 255 && pass "the square's top-left corner picks white ($FG)" || fail "the square's top-left corner gave $FG, not white"
[[ "$W_X,$W_Y" == "$W0X,$W0Y" ]] && pass "the mixer window did not move" || fail "the press moved the window ($W0X,$W0Y -> $W_X,$W_Y)"

# ---- B) the strip's FG end follows the picked FG ----
click $(( SVX + SVW - 2 )) $(( SVY + SVH / 2 )); settle
cmix
info "picked FG $FG: strip $SFG..$SBG"
[[ "$SFG" == "$FG" ]] && pass "the FG<>BG strip starts at the new FG ($FG)" || fail "the FG<>BG strip still starts at $SFG, not the FG $FG"
[[ "$SBG" == "$BG" ]] && pass "the strip ends at the BG ($BG)" || fail "the strip ends at $SBG, not the BG $BG"

# ---- C) typing in the hex box ----
T0=$(tool)
click $(( TX + TW / 2 )) $(( TY + TH / 2 )); settle
cmix
[[ "$FOC" == "-1" ]] && pass "a click focuses the hex box" || fail "the hex box did not take focus"
# clear the box, then type with edits: "0000ee", Left, Delete, BackSpace -> "0000", then "bb"
key End
for _ in 1 2 3 4 5 6 7 8 9; do key BackSpace; done; settle
type_text "0000ee"; settle
key Left; key Delete; key BackSpace; settle
type_text "bb"; settle
cmix
info "hex box text $HEXT"
[[ "$HEXT" == "[0000bb]" || "$HEXT" == "[#0000bb]" ]] && pass "End / BackSpace / Left / Delete edit the hex text ($HEXT)" || fail "the hex text is $HEXT, not [0000bb]"
[[ "$(tool)" == "$T0" ]] && pass "typing hex letters (e = eraser) and Delete / BackSpace leave the tool alone (tool $T0)" || fail "typing in the hex box switched the tool ($T0 -> $(tool))"
key Return; settle
cmix
[[ "$FG" == "0000BB" ]] && pass "ENTER applies the typed color (FG $FG)" || fail "the typed color was not applied (FG $FG, not 0000BB)"
[[ "$SFG" == "0000BB" ]] && pass "the strip follows the typed color" || fail "the strip starts at $SFG after typing"
[[ "$FOC" == "0" ]] && pass "ENTER leaves the hex box" || fail "the hex box kept focus after ENTER"
key v; settle
[[ "$(tool)" != "$T0" ]] && pass "after ENTER, DRAW's keys work again (v: tool $T0 -> $(tool))" || fail "after ENTER, v did not switch tools"
# focus again, then click away on the canvas: keys come back
click $(( TX + TW / 2 )) $(( TY + TH / 2 )); settle
dk_scr
click $(( CAN_LX + 40 )) $(( DOCK_BOT - 40 )); settle
cmix
[[ "$FOC" == "0" ]] && pass "a click away takes the focus off the hex box" || fail "the hex box kept focus after a click on the canvas"
T1=$(tool); key b; settle
[[ "$(tool)" != "$T1" ]] && pass "after the click away, DRAW's keys work (b: tool $T1 -> $(tool))" || fail "after the click away, b did not switch tools"
# ---- D) Esc / an invalid ENTER / a click elsewhere IN the mixer leave the box
#      and put the current color back in it (Rick: "when user hits enter, it
#      gives up focus, when they hit esc ... also clicks away")
shown() { local t="${HEXT#[}"; t="${t%]}"; [[ "${t^^}" == "#${FG^^}" ]]; }
# click and type straight away: the focusing click selects all, so the typing
# replaces the (full, 7-character) text
click $(( TX + TW / 2 )) $(( TY + TH / 2 )); settle
type_text "#00ff00"; settle
cmix
[[ "${HEXT,,}" == "[#00ff00]" ]] && pass "click + type replaces the hex text ($HEXT)" || fail "click + type gave $HEXT, not [#00ff00] (the focusing click must select all)"
key Return; settle
cmix
[[ "$FG" == "00FF00" ]] && pass "ENTER applies it (FG $FG)" || fail "the typed color was not applied (FG $FG, not 00FF00)"
cmix; FG0=$FG
click $(( TX + TW / 2 )) $(( TY + TH / 2 )); settle
type_text "zz"; settle
cmix; [[ "${HEXT,,}" == "[zz]" ]] && pass "typed text is in the box before Esc ($HEXT)" || fail "the box holds $HEXT before Esc, not [zz]"
key Escape; settle
cmix
[[ "$FOC" == "0" ]] && pass "Esc leaves the hex box" || fail "the hex box kept focus after Esc"
[[ "$FG" == "$FG0" ]] && pass "Esc leaves the color alone ($FG)" || fail "Esc changed the color ($FG0 -> $FG)"
shown && pass "after Esc the box shows the current color again ($HEXT)" || fail "after Esc the box still shows $HEXT, not #$FG"
click $(( TX + TW / 2 )) $(( TY + TH / 2 )); settle
type_text "#12"; settle
cmix; [[ "$HEXT" == "[#12]" ]] && pass "invalid text is in the box before ENTER ($HEXT)" || fail "the box holds $HEXT before ENTER, not [#12]"
key Return; settle
cmix
[[ "$FOC" == "0" ]] && pass "ENTER on invalid text leaves the hex box" || fail "the hex box kept focus after an invalid ENTER"
[[ "$FG" == "$FG0" ]] && pass "invalid text does not change the color ($FG)" || fail "invalid text changed the color ($FG0 -> $FG)"
shown && pass "after an invalid ENTER the box shows the current color ($HEXT)" || fail "after an invalid ENTER the box still shows $HEXT, not #$FG"
click $(( TX + TW / 2 )) $(( TY + TH / 2 )); settle
type_text "#ab"; settle
cmix
[[ "$FOC" == "-1" ]] || fail "the hex box did not take focus for the in-mixer click check"
click $(( SVX + SVW / 3 )) $(( SVY + SVH / 3 )); settle
cmix
[[ "$FOC" == "0" ]] && pass "a click on the color square leaves the hex box" || fail "the hex box kept focus after a click on the color square"
[[ "$FG" != "$FG0" ]] && pass "that click still picks a color ($FG0 -> $FG)" || fail "the click on the square did not pick a color"
shown && pass "the box shows the picked color ($HEXT)" || fail "the box shows $HEXT, not the picked #$FG"
T2=$(tool); key b; settle; [[ "$(tool)" != "$T2" ]] || { key v; settle; }
[[ "$(tool)" != "$T2" ]] && pass "after the in-mixer click, DRAW's keys work (tool $T2 -> $(tool))" || fail "after the in-mixer click, DRAW's keys still go to the box"
assert_window_exists
info "=== Color Mixer input Test PASSED ==="
