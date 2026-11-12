#!/bin/bash
# =============================================================================
# clip-edit-cels.sh — QA test: Edit Clip Cels / Apply / Discard (TOOLS/CLIP,
# phase 2 K10a).
#
#   - two clip layers on source 1 (Duplicate Layer)
#   - Edit Clip Cels: a new layer with cel k on frame k at the clip's place
#     (6, 6), the clips on the source hidden (CLIPE / CLIPEX / CLIPV)
#   - paint cel 1's top right pixel on that layer (sheet view, brush)
#   - Apply Cel Edits: both clips on a new source 2 showing the painted cel
#     (frames 2 and 6 show cel 1), the clips shown again, the layer gone
#   - one Ctrl+Z: the layer back, the clips on source 1; Ctrl+Y: applied again
#   - Edit again + Discard: the layer gone, nothing else changes
#   - Edit Clip Cels on a pixel layer: refused
#
# Dump: CLIP / CLIPC / CLIPX (clip-lib.sh), CLIPE slot src px py, CLIPEX (the
# cels layer's pixels per frame), CLIPV slot:shown, LPANEL.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt DRAWER_MINI_PALETTE=0 ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 LIGHTBOX_PANES=3 LIGHTBOX_STRIP_FLOW=ROW
# =============================================================================
info "=== Clip layers: edit clip cels ==="
source "$DRAW_ROOT/QA/clip-lib.sh"
ce_read() {
    cl_read
    read -r _ E_SLOT E_SRC E_PX E_PY _ <<< "$(cl_line CLIPE)"
    E_PIX=$(cl_line CLIPEX | cut -d' ' -f2-)
    E_VIS=$(cl_line CLIPV | cut -d' ' -f2-)
    E_SRCS=$(grep '^CLIP ' "$CL_DUMPF" | awk '{print $3}' | tr '\n' ' ' | sed 's/ $//')
    read -r _ _ E_CUR _ <<< "$(cl_line LPANEL)"
}
ce_s() { echo "CLIPE [${E_SLOT:-} ${E_SRC:-} ${E_PX:-} ${E_PY:-}] cels layer [${E_PIX:-}] shown [${E_VIS:-}] clip sources [${E_SRCS:-}] current ${E_CUR:-?}; $(cl_s) px [$C_PIX]"; }
ce_f() { # PIXELS FRAME -> that frame's entry
    local e
    for e in $1; do [[ "${e%%:*}" == "$2" ]] && { echo "$e"; return; }; done
}

cl_setup
if (( CL_OK )); then
    cl_cmd "duplicate layer"; ce_read
    [[ "$E_SRCS" == "1 1" && "$E_SLOT" == 0 ]] && pass "two clip layers on source 1, no cels being edited" || fail "start: $(ce_s)"
    P0="$C_PIX"
    F1=$(ce_f "$P0" 2) # frame 2 shows cel 1

    # -- open --
    cl_cmd "clip layer: edit clip cels"; ce_read
    WANT=$(cl_want_px "1234.." 6 6 0)
    [[ "$E_SLOT" != 0 && "$E_SLOT" == "$E_CUR" && "$E_SRC $E_PX $E_PY" == "1 6 6" ]] && pass "Edit Clip Cels: a new current layer for source 1 at (6, 6)" || fail "open: $(ce_s)"
    [[ "$E_PIX" == "$WANT" ]] && pass "the cels layer: cel k on frame k" || fail "cels layer pixels [$E_PIX] want [$WANT]"
    [[ "$E_VIS" == *:0*:0 && "$E_VIS" != *:1* ]] && pass "both clips on the source hidden while editing" || fail "hidden: [$E_VIS]"
    screenshot "clip-edit-cels-open"

    # -- paint cel 1's top right pixel (frame 1, canvas 9,6) --
    cl_key KP_0; cl_key b
    cl_read; (( ${AB_N:-0} > 0 )) && { cl_key ctrl+b; cl_read; info "AnimBrush dropped for a plain dot: ABR n ${AB_N:-?}"; }
    cl_hclick "$(cl_cx 9)" "$(cl_cy 6)"; ce_read
    E1=$(ce_f "$E_PIX" 1)
    [[ -n "$E1" && "$E1" != "$(ce_f "$WANT" 1)" && "$(ce_f "$E_PIX" 2)" == "$(ce_f "$WANT" 2)" ]] && pass "painted cel 1 on frame 1 ($E1)" || fail "paint: frame 1 [$E1] want a change from [$(ce_f "$WANT" 1)]; $(ce_s)"

    # -- apply --
    cl_cmd "clip layer: apply cel edits"; ce_read
    [[ "$E_SLOT" == 0 && "$E_SRCS" == "2 2" && "$E_VIS" != *:0* && "$C_CELS" == ".12341" ]] && pass "Apply Cel Edits: both clips on source 2, shown again, the layer gone" || fail "apply: $(ce_s)"
    A2=$(ce_f "$C_PIX" 2); A6=$(ce_f "$C_PIX" 6)
    [[ -n "$A2" && "$A2" != "$F1" && "$A6" == "${A2/#2:/6:}" && "$(ce_f "$C_PIX" 3)" == "$(ce_f "$P0" 3)" ]] \
        && pass "the clips show the painted cel 1 (frames 2 and 6: $A2), the other cels unchanged" || fail "applied pixels: [$C_PIX] (were [$P0])"
    screenshot "clip-edit-cels-applied"

    cl_key ctrl+z; ce_read
    [[ "$E_SLOT" != 0 && "$E_SRCS" == "1 1" && "$(ce_f "$C_PIX" 2)" == "$F1" ]] && pass "one Ctrl+Z: the cels layer back, the clips on source 1 with the old cel" || fail "undo apply: $(ce_s)"
    cl_key ctrl+y; ce_read
    [[ "$E_SLOT" == 0 && "$E_SRCS" == "2 2" && "$(ce_f "$C_PIX" 2)" == "$A2" ]] && pass "Ctrl+Y: applied again" || fail "redo apply: $(ce_s)"

    # -- edit again, discard --
    click 60 "$(cl_row_y 1)"; wait_for 0.5 "the duplicate"
    cl_cmd "clip layer: edit clip cels"; ce_read
    [[ "$E_SLOT" != 0 && "$E_SRC" == 2 && "$(ce_f "$E_PIX" 1)" == "${A2/#2:/1:}" ]] && pass "Edit Clip Cels again: source 2, with the painted cel" || fail "open again: $(ce_s)"
    cl_cmd "clip layer: discard cel edits"; ce_read
    [[ "$E_SLOT" == 0 && "$E_SRCS" == "2 2" && "$E_VIS" != *:0* ]] && pass "Discard Cel Edits: the layer gone, the clips shown, still on source 2" || fail "discard: $(ce_s)"

    # -- a pixel layer: refused --
    click 60 "$(cl_row_y 3)"; wait_for 0.5 "Layer 1"
    cl_cmd "clip layer: edit clip cels"; ce_read
    [[ "$E_SLOT" == 0 ]] && pass "Edit Clip Cels on a pixel layer: refused" || fail "edit on Layer 1: $(ce_s)"
    assert_no_crash
fi
cl_done
info "=== Clip layers: edit clip cels: done ==="
