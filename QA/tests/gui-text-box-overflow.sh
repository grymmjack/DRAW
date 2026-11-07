#!/bin/bash
# =============================================================================
# gui-text-box-overflow.sh — QA test: text typed past the end of a one-line
# text box stays inside the box, and deleting it slides the text back.
#   (also: one BackSpace repaints the box at once - Rick: "it doesn't update ... i have to type another key")
# Rick, 2026-11-07 (docked Color Mixer): "put my cursor into the box, and
# started typing crap, and then backspace" - the hex text was drawn over the
# "HEX:" label to the left of the box.
# Cause (QB64_GJ_LIB TEXT_INPUT, TTF/proportional path): the text was printed
# as one string shifted left by the scroll amount, with nothing clipping it;
# the scroll never came back when text was deleted; and the scroll measured
# fixed cells while the glyphs were drawn at their real widths.
#   A) Color Mixer docked: type a long run into the hex box, BackSpace a few:
#      the "HEX:" label is unchanged and the box holds at most "#RRGGBB"
#   B) Customize Controls FIND box (the same widget, proportional): type far
#      past the box, the "FIND:" label is unchanged; BackSpace back to
#      "abcde" and the box's left end shows the same as typing "abcde" fresh
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE COLOR_MIXER_VISIBLE=1 DOCK_CUSTOM=1 DOCK_LEFT_1=AUTO;toolbox|organizer|drawer DOCK_LEFT_2=AUTO;advbar|editbar DOCK_LEFT_3=AUTO;colormixer DOCK_RIGHT_1=AUTO;layers
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Text box overflow Test ==="
wait_for 1.2 "settle"
key Escape
dk_park; dk_settle
cmix() { read -r _ SVX SVY SVW SVH HX HY HW HH TX TY TW TH FOC FG BG SFG SBG HEXT <<< "$(grep '^CMIX' "$DK_DUMP")"; }
settle() { sleep 0.4; }

# ---- A) the docked Color Mixer's hex box ----
cmix
[[ -n "$TX" ]] || { fail "no CMIX line (Color Mixer not showing?)"; exit 1; }
LBLW=$(( TX - SVX ))
info "hex box $TX,$TY ${TW}x$TH; label strip $SVX..$TX"
(( LBLW > 8 )) || { fail "no room for the HEX: label left of the box ($SVX..$TX)"; exit 1; }
park_mouse
snap_region "$SVX" "$TY" "$LBLW" "$TH" "hex-label-before"; LBL0="$SNAP_RESULT"
click $(( TX + TW / 2 )) $(( TY + TH / 2 )); settle
key End
type_text "ffffffqwertyuiopasdfghjklzxcvbnm"; settle
park_mouse; settle
snap_region "$SVX" "$TY" "$LBLW" "$TH" "hex-label-typed"; LBL1="$SNAP_RESULT"
assert_regions_same "$LBL0" "$LBL1" "text typed past the hex box must not draw over the HEX: label" 3
# one BackSpace must repaint the box at once (it showed only with the next
# letter: BackSpace leaves _KEYHIT empty, so the frame stayed idle)
snap_region "$TX" "$TY" "$TW" "$TH" "hex-box-before-bs"; HB0="$SNAP_RESULT"
key BackSpace; settle
snap_region "$TX" "$TY" "$TW" "$TH" "hex-box-after-bs"; HB1="$SNAP_RESULT"
assert_regions_differ "$HB0" "$HB1" "one BackSpace repaints the hex box straight away"
key BackSpace; key BackSpace; settle
park_mouse; settle
snap_region "$SVX" "$TY" "$LBLW" "$TH" "hex-label-backspaced"; LBL2="$SNAP_RESULT"
assert_regions_same "$LBL0" "$LBL2" "after BackSpace the hex text must not sit over the HEX: label" 3
cmix
T="${HEXT#[}"; T="${T%]}"
info "hex box text [$T]"
(( ${#T} <= 7 )) && pass "the hex box holds at most #RRGGBB ([$T])" || fail "the hex box took ${#T} characters ([$T])"
key Escape; settle

# ---- B) the Customize Controls FIND box ----
key question
wait_for 0.5 "Command palette"
type_text "customize controls"
wait_for 0.3 "Filter"
key Return
wait_for 0.8 "Customize Controls dialog opened"
assert_no_crash
DW=560; DH=420
(( DW > VIEWPORT_W - 8 )) && DW=$(( VIEWPORT_W - 8 ))
(( DH > VIEWPORT_H - 8 )) && DH=$(( VIEWPORT_H - 8 ))
DX=$(( (VIEWPORT_W - DW) / 2 )); DY=$(( (VIEWPORT_H - DH) / 2 ))
info "Controls dialog at $DX,$DY ${DW}x$DH"
# FIND: label column (x 10..49) and the box's left end (box x 50), top rows
park_mouse; settle
snap_region $(( DX + 2 )) $(( DY + 1 )) 46 47 "find-label-before"; FL0="$SNAP_RESULT"
type_text "abcde"; settle
park_mouse; settle
snap_region $(( DX + 51 )) $(( DY + 1 )) 14 47 "find-box-fresh"; FB0="$SNAP_RESULT"
key Escape; settle
LONG="abcde"; for _ in $(seq 1 12); do LONG+="qwxzvkqwxz"; done
type_text "$LONG"; settle
park_mouse; settle
snap_region $(( DX + 2 )) $(( DY + 1 )) 46 47 "find-label-typed"; FL1="$SNAP_RESULT"
assert_regions_same "$FL0" "$FL1" "text typed past the FIND box must not draw over the FIND: label" 3
for _ in $(seq 1 $(( ${#LONG} - 5 ))); do key BackSpace; done; settle
park_mouse; settle
snap_region $(( DX + 51 )) $(( DY + 1 )) 14 47 "find-box-backspaced"; FB1="$SNAP_RESULT"
assert_regions_same "$FB0" "$FB1" "BackSpace back to 'abcde' must show it from the box's left end, as typed fresh" 3
snap_region $(( DX + 2 )) $(( DY + 1 )) 46 47 "find-label-backspaced"; FL2="$SNAP_RESULT"
assert_regions_same "$FL0" "$FL2" "after BackSpace the FIND text must not sit over the FIND: label" 3
key Escape; key Escape; settle
assert_no_crash
assert_window_exists
info "=== Text box overflow Test PASSED ==="
