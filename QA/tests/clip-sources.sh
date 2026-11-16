#!/bin/bash
# =============================================================================
# clip-sources.sh — QA test: clip sources (TOOLS/CLIP, phase 2 K6) - the
# document's table of cels behind the clip layers.
#
#   - Duplicate Layer: two clip layers on source 1 (CLIPSU 1:2)
#   - a 2-cel AnimBrush (Update from AnimBrush): both clips on source 2
#   - the panel's LAYERS chip: both clip layers selected
#   - Next Clip Source on the duplicate: source 1 (.12341); Ctrl+Z: source 2;
#     Previous Clip Source: source 1
#   - Clip Sources...: the overview alert (screenshot), Return closes it
#   - Remove Unused Clip Sources: the unused source off the list; Ctrl+Z of a
#     source change brings it back (a layer uses it again)
#   - Rename Clip Source: the new name in CLIPS, the other source keeps its own
#
# Dump: CLIP / CLIPC / CLIPS (clip-lib.sh), CLIPSU src:users ..., LPANEL
# (multi-select count), ANIMPM / ANIMPL (the panel rows).
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 LIGHTBOX_PANES=3 LIGHTBOX_STRIP_FLOW=ROW
# =============================================================================
info "=== Clip layers: clip sources ==="
source "$DRAW_ROOT/QA/clip-lib.sh"
cs_users() { cl_line CLIPSU | cut -d' ' -f2-; }
cs_listed() { grep '^CLIPS ' "$CL_DUMPF" | awk '{print $2}' | tr '\n' ' ' | sed 's/ $//'; }
cs_name() { grep -m1 "^CLIPS $1 " "$CL_DUMPF" | cut -d' ' -f7-; }
cs_nsel() { read -r _ _ _ n _ <<< "$(cl_line LPANEL)"; echo "${n:-?}"; }
cs_cur() { # the current layer's clip: CUR_SRC, CUR_CELS
    local cur; read -r _ _ cur _ <<< "$(cl_line LPANEL)"
    read -r _ _ CUR_SRC _ <<< "$(grep -m1 "^CLIP $cur " "$CL_DUMPF")"
    CUR_CELS=$(grep -m1 "^CLIPC $cur " "$CL_DUMPF" | cut -d' ' -f3)
}
cs_s() { cs_cur; echo "current layer's clip: source ${CUR_SRC:-?} cels [${CUR_CELS:-}]; CLIPSU [$(cs_users)] listed [$(cs_listed)]"; }
cs_cmd() { cl_cmd "$1"; cl_read; cs_cur; }

cl_setup
if (( CL_OK )); then
    [[ "$(cs_users)" == "1:1" && "$(cs_listed)" == 1 ]] && pass "one source, one clip layer on it" || fail "start: $(cs_s)"

    cl_cmd "duplicate layer"; cl_read
    [[ "$(cs_users)" == "1:2" ]] && pass "Duplicate Layer: source 1 used by 2 layers" || fail "after duplicate: $(cs_s)"

    # -- a 2-cel AnimBrush from Layer 1 (row 3); Update repoints both clips --
    click 60 "$(cl_row_y 3)"; wait_for 0.5 "Layer 1"
    cl_strip 4; cl_strip 3 shift; cl_read
    cl_key m
    mouse_down "$(cl_px 6)" "$(cl_py 6)"; hover "$(cl_px 8)" "$(cl_py 8)"; sleep 0.2; hover "$(cl_px 9)" "$(cl_py 9)"; sleep 0.3
    mouse_up; wait_for 0.6 "marquee"
    cl_cmd "animbrush: pick up (the"; cl_key ctrl+d; cl_read
    [[ "$AB_N" == 2 ]] || fail "2-cel pick up: brush n $AB_N"
    click 60 "$(cl_row_y 1)"; wait_for 0.5 "the duplicate"
    cs_cmd "clip layer: update clip from animbrush"
    [[ "$CUR_SRC" == 2 && "$CUR_CELS" == ".12121" && "$(cs_users)" == "1:0 2:2" ]] && pass "Update from AnimBrush: both clips on source 2 (2 cels), source 1 unused" \
        || fail "update: $(cs_s)"

    # -- the panel's LAYERS chip (the last chip of the SOURCE row) --
    if [[ -n "$PM_Y7" && -n "$L_PW" ]]; then
        cl_hclick "$(( P_X + (L_PW - L_PAD - 8) * P_SC / 100 ))" "$(( P_Y + (PM_Y7 + L_RH / 2) * P_SC / 100 ))"; cl_read
        [[ "$(cs_nsel)" == 2 ]] && pass "the SOURCE row's LAYERS chip: both layers on source 2 selected" || fail "LAYERS chip: $(cs_nsel) selected | $(cl_line LPANEL)"
        screenshot "clip-sources-panel"
    else
        fail "no panel rows: $(cl_line ANIMPM) | $(cl_line ANIMPL)"
    fi
    click 60 "$(cl_row_y 1)"; wait_for 0.5 "one layer again"

    # -- step the source --
    cs_cmd "clip layer: next clip source"
    [[ "$CUR_SRC" == 1 && "$CUR_CELS" == ".12341" && "$(cs_users)" == "1:1 2:1" ]] && pass "Next Clip Source: the duplicate on source 1, its 4 cels" || fail "next source: $(cs_s)"
    cl_key ctrl+z; cl_read; cs_cur
    [[ "$CUR_SRC" == 2 && "$CUR_CELS" == ".12121" ]] && pass "Ctrl+Z: source 2 again" || fail "undo the source step: $(cs_s)"
    cs_cmd "clip layer: previous clip source"
    [[ "$CUR_SRC" == 1 && "$CUR_CELS" == ".12341" ]] && pass "Previous Clip Source: source 1" || fail "previous source: $(cs_s)"

    # -- the overview --
    park_mouse; key question; wait_for 1.0 "Command palette"
    type_text "clip layer: clip sources"; wait_for 3.0 "Filtered"; key Return; wait_for 1.5 "the overview"
    screenshot "clip-sources-overview"
    key Return; wait_for 0.8 "closed"
    assert_no_crash
    cl_read; cs_cur
    [[ "$CUR_SRC" == 1 && "$(cs_users)" == "1:1 2:1" ]] && pass "Clip Sources...: shown and closed, nothing changed" || fail "after the overview: $(cs_s)"

    # -- Remove Unused --
    cs_cmd "clip layer: next clip source"
    [[ "$CUR_SRC" == 2 && "$(cs_users)" == "1:0 2:2" ]] || fail "back to source 2: $(cs_s)"
    cs_cmd "clip layer: remove unused"
    [[ "$(cs_listed)" == 2 && "$(cs_users)" == "2:2" ]] && pass "Remove Unused Clip Sources: source 1 off the list" || fail "purge: $(cs_s)"
    cs_cmd "clip layer: next clip source"
    [[ "$CUR_SRC" == 2 ]] && pass "Next Clip Source with one source listed: stays on source 2" || fail "next with one source: $(cs_s)"
    for u in 1 2 3; do # (the purge is no undo step)
        cl_key ctrl+z; cl_read; cs_cur
        [[ "$CUR_SRC" == 1 ]] && break
    done
    [[ "$CUR_SRC" == 1 && "$CUR_CELS" == ".12341" && "$(cs_listed)" == "1 2" ]] && pass "Ctrl+Z: the duplicate on source 1, which is listed again" \
        || fail "undo after the purge: $(cs_s)"

    # -- Rename --
    cl_cmd "clip layer: rename clip source"; wait_for 0.6 "input box"
    type_text "walker"; wait_for 0.3 "typed"; key Return; wait_for 0.8 "renamed"
    cl_read
    [[ "$(cs_name 1)" == [Ww][Aa][Ll][Kk][Ee][Rr]* ]] && pass "Rename Clip Source: source 1 is 'walker'" || fail "rename: CLIPS 1 [$(cs_name 1)]"
    [[ "$(cs_name 2)" != [Ww][Aa][Ll][Kk][Ee][Rr]* ]] && pass "source 2 keeps its name" || fail "source 2 renamed too [$(cs_name 2)]"
fi
cl_done
info "=== Clip layers: clip sources: done ==="
