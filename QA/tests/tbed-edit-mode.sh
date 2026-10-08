#!/bin/bash
# =============================================================================
# tbed-edit-mode.sh — QA test: while Customize Toolbars is open, the real
# toolbox / bars are edited by dragging (GUI/TOOLBAR-EDITOR edit mode).
#   click     a toolbox button selects it in the editor, does not pick the tool
#   between   drag Zoom from the toolbox onto the edit bar (after Redo); Default
#             asks for a workspace name -> moved, saved into the new workspace
#   reorder   drag Undo below Redo on the edit bar
#   remove    drag Cut off the edit bar onto the canvas -> gone
#   add       drag an Available row onto the advanced bar -> added there
#   closed    Done: clicks run buttons again (Zoom on the edit bar picks Zoom)
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt WORKSPACES_DIR=QA/.tbed-ws
# =============================================================================

source "$DRAW_ROOT/QA/tbed-lib.sh"
tb_reset_ws

info "=== Customize Toolbars: edit mode on the real panels ==="
wait_for 1.0 "settle"
key Escape
dk_park
dk_settle
tb_open

# --- click: selects, does not run --------------------------------------------
tb_state; TOOL0=$TB_TOOL
i=$(tb_idx toolbox zoom)
tb_btn toolbox "$i" || fail "zoom is not drawn on the toolbox"
click "$BCX" "$BCY"; sleep 0.4; dk_settle; tb_state
if [[ "$TB_TOOL" == "$TOOL0" ]]; then pass "the click did not pick the Zoom tool"; else fail "the click picked a tool ($TOOL0 -> $TB_TOOL)"; fi
if [[ "$TB_TAB" == "toolbox" && "$TB_SEL" == "$i" ]]; then pass "a click on Zoom selects it in the editor"; else fail "click did not select Zoom (tab=$TB_TAB sel=$TB_SEL)"; fi

# --- between panels ----------------------------------------------------------
r=$(tb_idx editbar redo)
tb_btn editbar "$r" || fail "redo is not drawn on the edit bar"
tx=$BCX; ty=$(( BY + BH - 2 ))
tb_btn toolbox "$i"
dk_drag "$BCX" "$BCY" "$tx" "$ty"
tb_name_prompt "QA Moves"
tb_state
tb_expect_list editbar '^undo,redo,zoom,' "Zoom moved onto the edit bar after Redo"
tb_expect_no toolbox zoom "Zoom left the toolbox"
if [[ "$TB_WS" == "qa-moves" ]]; then pass "the change made the workspace 'QA Moves' and switched to it"; else fail "workspace is '$TB_WS'"; fi
F=$(tb_ws_file)
if [[ -n "$F" ]] && grep -q '^ORDER=undo,redo,zoom,' "$F" && grep -q '^BUTTONS=' "$F"; then pass "saved: [EDIT_BAR] ORDER and [TOOLBOX] BUTTONS in $(basename "$F")"; else fail "workspace file missing the lists: $F"; cat "$F" 2>/dev/null; fi

# --- reorder within a bar ------------------------------------------------------
u=$(tb_idx editbar undo); r=$(tb_idx editbar redo)
tb_btn editbar "$r"; tx=$BCX; ty=$(( BY + BH - 2 ))
tb_btn editbar "$u"
dk_drag "$BCX" "$BCY" "$tx" "$ty"
dk_settle
tb_expect_list editbar '^redo,undo,zoom,' "Undo dragged below Redo"
if grep -q '^ORDER=redo,undo,zoom,' "$(tb_ws_file)"; then pass "the new order is saved"; else fail "the new order was not saved"; fi

# --- remove: dropped off every panel ---------------------------------------------
c=$(tb_idx editbar cut)
tb_btn editbar "$c"
dk_scr
dk_drag "$BCX" "$BCY" $(( (CAN_LX + CAN_RX) / 2 )) 200
dk_settle
tb_expect_no editbar cut "Cut dragged onto the canvas is removed"

# --- add from the Available list: drag a row onto the advanced bar -------------------
tb_click tab3
tb_click search
type_text "new layer"; sleep 0.5; dk_settle
A0=$(tb_count advbar)
tb_row av 1; ax=$CX; ay=$CY
tb_btn advbar 0; tx=$BCX; ty=$(( BY + BH - 2 ))
dk_drag "$ax" "$ay" "$tx" "$ty"
dk_settle
A1=$(tb_count advbar)
if (( A1 == A0 + 1 )); then pass "an Available row dragged onto the advanced bar is added ($(tb_list advbar | cut -d, -f1-3))"; else fail "advanced bar has $A1 (was $A0)"; fi
tb_state
if [[ "$TB_TAB" == "advbar" && "$TB_SEL" == "1" ]]; then pass "it is selected in the editor, after the first button"; else fail "tab=$TB_TAB sel=$TB_SEL"; fi
if grep -q '^\[ADVANCED_BAR\]' "$(tb_ws_file)" && grep -A3 '^\[ADVANCED_BAR\]' "$(tb_ws_file)" | grep -q '^ORDER='; then pass "saved as [ADVANCED_BAR] ORDER"; else fail "advanced bar not saved"; fi

# --- closed: clicks run buttons again ----------------------------------------------
tb_click done
tb_state
if [[ "$TB_EDIT" == "0" ]]; then pass "Done closes the editor"; else fail "editor still open"; fi
z=$(tb_idx editbar zoom)
tb_btn editbar "$z"
click "$BCX" "$BCY"; sleep 0.5
dk_park; dk_settle; tb_state
if [[ "$TB_TOOL" != "$TOOL0" ]]; then pass "with the editor closed, Zoom on the edit bar picks the Zoom tool (tool $TB_TOOL)"; else fail "Zoom on the edit bar did nothing"; fi
screenshot "tbed-edit-mode"

tb_reset_ws
