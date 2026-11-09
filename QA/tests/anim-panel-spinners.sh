#!/bin/bash
# =============================================================================
# anim-panel-spinners.sh — QA test: the Animation panel's number boxes
# (field kit T-6, Rick 2026-11-08: "i also need to be able to double click or
# single click to edit all the numeric value boxes... like, w, h, fps, etc.").
#
# Every stepper row's number (W H GUTTER MARGIN FPS HOLD, onion BEFORE AFTER
# OPACITY): the wheel steps it (up = more, Shift = 10), a middle click puts it
# back to its default, a drag up / down on the number steps it (one undo step),
# and a click on the number opens a box to type it. The old build only had the
# - / + chips: the wheel, middle click, drag and click did nothing.
#
# Dump: ANIM (layout + fps), ANIMP / ANIMPL (panel geometry; ANIMPL ends with
# the onion rows' y and the onion values).
# Fixture: the 64x32 sheet of anim-panel.sh (16x16, 7 frames, current 3, 12 fps).
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Animation: the Animation panel's number boxes ==="

AS_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
AS_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
AS_DIR="/tmp/draw-qa-animspin-$$"
mkdir -p "$AS_DIR"
magick -size 64x32 xc:'#204060' -fill '#c04040' -draw 'rectangle 20,4 27,11' "$AS_DIR/plain.png"
AS_BLOB=$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,7,3,12,0,0).hex())")
python3 "$AS_PY" put "$AS_DIR/plain.png" "$AS_DIR/sheet.png" drAn "$AS_BLOB"

as_settle() { { hover 300 250; wait_for 0.2 "render"; hover 305 252; wait_for 0.3 "render"; } >&2; }
as_line() { grep -m1 "^$1 " "$AS_DUMP" 2>/dev/null; }
as_read() {
    as_settle
    read -r _ A_ON A_COUNT A_CUR A_FW A_FH A_GUT A_MAR _ _ A_FPS _ <<< "$(as_line ANIM)"
    read -r _ P_VIS P_DOCK P_X P_Y P_W P_H P_SC P_HOLD P_MODE P_PEND <<< "$(as_line ANIMP)"
    read -r _ L_NAV L_R1 L_R2 L_R3 L_R4 L_R5 L_R6 L_LOOP L_RH L_MX L_PX L_CW L_PAD L_PW L_OPS L_MODE \
        L_ON L_O1 L_O2 L_O3 O_BEF O_AFT O_OPA _ <<< "$(as_line ANIMPL)"
}
as_vx() { echo $(( P_X + $1 * P_SC / 100 )); }   # native -> viewport
as_vy() { echo $(( P_Y + $1 * P_SC / 100 )); }
as_rowy() { # ROW (1..6 layout / timing, 7..9 onion): native top
    case $1 in 7) echo "$L_O1" ;; 8) echo "$L_O2" ;; 9) echo "$L_O3" ;; *) local v="L_R$1"; echo "${!v}" ;; esac
}
as_box() { # ROW -> "x y": the middle of the row's number (between - and +)
    as_read
    echo "$(as_vx $(( (L_MX + L_CW + L_PX) / 2 ))) $(as_vy $(( $(as_rowy "$1") + L_RH / 2 )))"
}
as_label() { # ROW -> "x y": the row's label (left end)
    as_read
    echo "$(as_vx $(( L_PAD + 4 ))) $(as_vy $(( $(as_rowy "$1") + L_RH / 2 )))"
}
as_wheel() { # ROW up|down N [shift] - wheel over the row's label
    local x y i; read -r x y <<< "$(as_label "$1")"
    [[ "${4:-}" == shift ]] && { driver_input_key_hold down shift; sleep 0.15; }
    for (( i = 0; i < $3; i++ )); do
        if [[ "$2" == up ]]; then scroll_up "$x" "$y"; else scroll_down "$x" "$y"; fi
        sleep 0.12
    done
    [[ "${4:-}" == shift ]] && driver_input_key_hold up shift
    wait_for 0.3 "wheel row $1 $2 x$3"
}
as_middle() { local x y; read -r x y <<< "$(as_label "$1")"; middle_click "$x" "$y"; wait_for 0.4 "middle click row $1"; }
as_drag() { # ROW DY - press the number, move DY viewport px (negative = up) in 3 steps, release
    local x y; read -r x y <<< "$(as_box "$1")"
    mouse_down "$x" "$y"
    hover "$x" $(( y + $2 / 3 )); sleep 0.15
    hover "$x" $(( y + 2 * $2 / 3 )); sleep 0.15
    hover "$x" $(( y + $2 )); sleep 0.2
    mouse_up; wait_for 0.4 "drag row $1 by $2"
}
as_type() { # ROW TEXT - click the number, type into the box, Return
    local x y; read -r x y <<< "$(as_box "$1")"
    click "$x" "$y"; wait_for 0.8 "input box"
    type_text "$2"; wait_for 0.2 "typed"; key Return; wait_for 0.6 "row $1 = $2"
}
as_undo() { park_mouse; key ctrl+z; wait_for 0.5 "undo"; }

info "Launching DRAW with a 64x32 sheet of 16x16 frames (current 3, 12 fps)"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$AS_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
park_mouse
key ctrl+0
wait_for 0.5 "Zoom 100%"

for try in 1 2; do
    park_mouse; key question; wait_for 1.0 "Command palette"
    type_text "animation panel"; wait_for 0.4 "Filtered"; key Return; wait_for 0.6 "Panel toggled"
    as_read; [[ "$P_VIS" == -1 ]] && break
    info "the panel did not open (the palette was slow?) - again"
    key Escape; wait_for 0.3 "Escape"
done
as_read
if [[ "$P_VIS" != -1 || -z "$L_R1" || -z "$L_O3" ]]; then
    fail "the Animation panel did not open (visible=$P_VIS, rows '$L_R1' onion '$L_O3')"
else
    pass "panel open: fps $A_FPS, hold $P_HOLD, onion $O_BEF/$O_AFT/$O_OPA%"
    FPS0=$A_FPS; OB0=${O_BEF:-1}

    # -- the wheel: up = more, one undo step for a run of ticks; Shift = 10 --
    as_wheel 5 up 3; as_read
    [[ "$A_FPS" == $(( FPS0 + 3 )) ]] && pass "wheel up x3 over FPS: $FPS0 -> $A_FPS" || fail "wheel up x3 over FPS: $A_FPS, wanted $(( FPS0 + 3 ))"
    as_undo; as_read
    [[ "$A_FPS" == "$FPS0" ]] && pass "one undo puts the three wheel ticks back ($A_FPS)" || fail "undo after the wheel: fps $A_FPS, wanted $FPS0"
    as_wheel 5 up 1 shift; as_read
    [[ "$A_FPS" == $(( FPS0 + 10 )) ]] && pass "Shift+wheel up over FPS: +10 ($A_FPS)" || fail "Shift+wheel over FPS: $A_FPS, wanted $(( FPS0 + 10 ))"

    # -- a middle click: the default (15 fps; onion 1 / 1 / 40 %) --
    as_middle 5; as_read
    [[ "$A_FPS" == 15 ]] && pass "middle click on FPS: back to 15" || fail "middle click on FPS: $A_FPS, wanted 15"

    # -- a drag on the number: 3 px a step, up = more, one undo step --
    as_drag 6 -15; as_read
    [[ "$P_HOLD" == 6 ]] && pass "drag HOLD's number up 15 px: hold 1 -> 6" || fail "drag HOLD up 15 px: hold $P_HOLD, wanted 6"
    as_drag 6 9; as_read
    [[ "$P_HOLD" == 3 ]] && pass "drag it down 9 px: hold 3" || fail "drag HOLD down 9 px: hold $P_HOLD, wanted 3"
    as_undo; as_read
    [[ "$P_HOLD" == 6 ]] && pass "undo: the down drag is one step (hold 6)" || fail "undo the down drag: hold $P_HOLD, wanted 6"

    # -- a click on the number: type it --
    as_type 9 70; as_read
    [[ "$O_OPA" == 70 ]] && pass "click ONION OPACITY's number, type 70: 70%" || fail "typed onion opacity: $O_OPA, wanted 70"
    as_wheel 7 up 2; as_read
    [[ "$O_BEF" == $(( OB0 + 2 )) ]] && pass "wheel up x2 over ONION BEFORE: $OB0 -> $O_BEF" || fail "wheel over ONION BEFORE: $O_BEF, wanted $(( OB0 + 2 ))"
    as_middle 9; as_middle 7; as_read
    [[ "$O_OPA" == 40 && "$O_BEF" == 1 ]] && pass "middle click: onion opacity 40%, before 1" || fail "middle click onion: opacity $O_OPA before $O_BEF, wanted 40 / 1"
    as_type 5 24; as_read
    [[ "$A_FPS" == 24 ]] && pass "click FPS's number, type 24: 24 fps" || fail "typed fps: $A_FPS, wanted 24"

    # -- W on a drawn sheet: typed, it waits for RE-SLICE / RESIZE like the + does --
    as_type 1 32; as_read
    if [[ "$P_PEND" == 1 ]]; then
        span=$(( L_PW - 2 * L_PAD )); cw=$(( (span - 2) / 2 ))
        click "$(as_vx $(( L_PAD + cw / 2 )))" "$(as_vy $(( L_MODE + L_RH / 2 )))"; wait_for 0.5 "RE-SLICE"
        as_read
        [[ "$A_FW" == 32 ]] && pass "type W 32, RE-SLICE: frames 32 wide" || fail "typed W 32 then RE-SLICE: frame W $A_FW"
    else
        [[ "$A_FW" == 32 ]] && pass "type W 32: frames 32 wide" || fail "typed W 32: frame W $A_FW, pending '$P_PEND'"
    fi
    screenshot "anim-panel-spinners"
fi
assert_no_crash

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$AS_DIR"
assert_window_exists
