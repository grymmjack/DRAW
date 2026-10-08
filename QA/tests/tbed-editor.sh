#!/bin/bash
# =============================================================================
# tbed-editor.sh — QA test: the Customize Toolbars window (GUI/TOOLBAR-EDITOR).
#   cancel   Default: the first change asks for a workspace name; Cancel puts
#            the panel back and saves nothing
#   add      search "flip brush", select the row, -> adds it after the selected
#            entry on the edit bar; the name prompt makes workspace "QA Bars"
#   arrows   up / down move the selected entry
#   divider  + DIV inserts a divider after the selection
#   remove   <- removes the selection; Delete removes too
#   tabs     the Advanced Bar tab lists the advanced bar
#   columns  + raises the bar's columns (saved)
#   reset    Reset puts the edit bar's default buttons back (saved)
#   dblclick double-clicking an Available row adds it
#   panel    the Toolbox tab: a command added to the toolbox shows in a cell
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt WORKSPACES_DIR=QA/.tbed-ws
# =============================================================================

source "$DRAW_ROOT/QA/tbed-lib.sh"
tb_reset_ws

info "=== Customize Toolbars: the editor window ==="
wait_for 1.0 "settle"
key Escape
dk_park
dk_settle
tb_open
DEFAULT_EB=$(tb_list editbar)
TB0=$(tb_count toolbox)

tb_click tab2
tb_state
if [[ "$TB_TAB" == "editbar" ]]; then pass "Edit Bar tab"; else fail "tab is $TB_TAB"; fi

# --- cancel: nothing saved, the bar is put back ------------------------------------
tb_click search
type_text "flip brush"; sleep 0.5; dk_settle
tb_row av 1; click "$CX" "$CY"; sleep 0.3
tb_click add
sleep 0.6; key Escape; sleep 1.0; dk_settle
if [[ "$(tb_list editbar)" == "$DEFAULT_EB" ]]; then pass "Cancel at the name prompt puts the edit bar back"; else fail "edit bar changed after Cancel: $(tb_list editbar)"; fi
if [[ -z "$(tb_ws_file)" ]]; then pass "nothing was saved"; else fail "a workspace was saved: $(tb_ws_file)"; fi

# --- add -----------------------------------------------------------------------------
tb_ls_click 1                                       # select Redo (the list scrolled to the end for the cancelled add)
tb_state
if [[ "$TB_SEL" == "1" ]]; then pass "the wheel scrolls the list back; Redo selected"; else fail "selection is $TB_SEL"; fi
tb_row av 1; click "$CX" "$CY"; sleep 0.3          # the first match
tb_click add
tb_name_prompt "QA Bars"
tb_state
tb_expect_list editbar '^undo,redo,cmd:[0-9]+,' "-> adds the command after the selected Redo"
NEW=$(tb_list editbar | cut -d, -f3)
if [[ "$TB_WS" == "qa-bars" && -n "$(tb_ws_file)" ]]; then pass "workspace 'QA Bars' made and in use"; else fail "workspace '$TB_WS' file '$(tb_ws_file)'"; fi
if grep -q "^ORDER=undo,redo,$NEW," "$(tb_ws_file)"; then pass "saved as [EDIT_BAR] ORDER"; else fail "ORDER not saved"; fi

# --- arrows ---------------------------------------------------------------------------
tb_click up; tb_expect_list editbar "^undo,$NEW,redo," "up moves it above Redo"
tb_click down; tb_expect_list editbar "^undo,redo,$NEW," "down moves it back"

# --- divider ----------------------------------------------------------------------------
tb_click div; tb_expect_list editbar "^undo,redo,$NEW,\\|," "+ DIV inserts a divider after it"

# --- remove -------------------------------------------------------------------------------
tb_click remove; tb_expect_list editbar "^undo,redo,$NEW,\\|,cut" "<- removes the selected divider"
tb_ls_click 2
key Delete; sleep 0.5; dk_settle
tb_expect_list editbar "^undo,redo,\\|,cut" "Delete removes the selected command"
if grep -q "^ORDER=undo,redo,|,cut" "$(tb_ws_file)"; then pass "removals saved"; else fail "removals not saved"; fi

# --- columns ------------------------------------------------------------------------------
tb_click colsup
if grep -q '^COLUMNS=2' "$(tb_ws_file)"; then pass "+ columns saved (COLUMNS=2)"; else fail "columns not saved"; grep -A3 EDIT_BAR "$(tb_ws_file)"; fi
tb_click colsdn

# --- tabs ----------------------------------------------------------------------------------
tb_click tab3; tb_state
if [[ "$TB_TAB" == "advbar" && "$TB_N" == "$(tb_count advbar)" ]]; then pass "Advanced Bar tab lists the advanced bar ($TB_N)"; else fail "advbar tab: tab=$TB_TAB n=$TB_N"; fi

# --- reset --------------------------------------------------------------------------------
tb_click tab2
tb_click reset
if [[ "$(tb_list editbar)" == "$DEFAULT_EB" ]]; then pass "Reset puts the default edit bar back"; else fail "after Reset: $(tb_list editbar)"; fi

# --- double-click adds; the toolbox shows a command in a cell -----------------------------------
tb_click tab1
tb_click search
key Escape; sleep 0.2                               # clears the old search text
type_text "new layer"; sleep 0.5; dk_settle
tb_row av 1; double_click "$CX" "$CY"; sleep 0.8; dk_settle
N=$(tb_count toolbox)
if (( N == TB0 + 1 )); then pass "double-click added a command to the toolbox ($(tb_list toolbox | awk -F, '{print $NF}'))"; else fail "toolbox has $N: $(tb_list toolbox)"; fi
if tb_btn toolbox $(( N - 1 )); then pass "the command has a toolbox cell at $BX,$BY"; else fail "the command is not drawn"; fi
if grep -q '^BUTTONS=.*cmd:' "$(tb_ws_file)"; then pass "[TOOLBOX] BUTTONS saved with the command"; else fail "toolbox not saved"; fi
dk_park; sleep 0.3
screenshot "tbed-editor"

tb_click close
tb_state
if [[ "$TB_EDIT" == "0" ]]; then pass "the close box closes it"; else fail "still open"; fi
tb_reset_ws
