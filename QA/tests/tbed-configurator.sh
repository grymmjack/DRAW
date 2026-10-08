#!/bin/bash
# =============================================================================
# tbed-configurator.sh — QA test: Configure Workspaces -> Toolbox tab ->
# "Customize Toolbars..." closes the configurator and opens the editor on the
# toolbox tab, in the selected workspace (Annotate). Nothing is changed, so
# nothing is saved (and WORKSPACES_DIR keeps any save out of the user's folder).
# Geometry at 958x514: Toolbox tab (VIEWPORT_W/2-60, VIEWPORT_H/2-153), the
# Editor row's button about (597,163).
# QA-OPTIONS: WORKSPACE=annotate DOCK_DUMP=QA/.dock-dump.txt WORKSPACES_DIR=QA/.tbed-ws
# =============================================================================

source "$DRAW_ROOT/QA/tbed-lib.sh"
tb_reset_ws

info "=== Customize Toolbars from the workspace configurator ==="
wait_for 0.8 "settle"
key Escape
park_mouse
wait_for 0.3 "settle"
canvas_focus
key ctrl+p; wait_for 0.5 "palette"
type_text "configure work"; wait_for 0.4 "filtered"
key Return; wait_for 1.0 "configurator open"
click $(( VIEWPORT_W / 2 - 60 )) $(( VIEWPORT_H / 2 - 153 )); wait_for 0.5 "Toolbox tab"
click 597 163; wait_for 1.2 "Customize Toolbars..."
dk_settle
tb_state
if [[ "$TB_EDIT" == "-1" && "$TB_TAB" == "toolbox" ]]; then pass "the editor opened on the Toolbox tab"; else fail "editor: open=$TB_EDIT tab=$TB_TAB"; fi
if [[ "$TB_WS" == "annotate" ]]; then pass "in the selected workspace (Annotate)"; else fail "workspace is $TB_WS"; fi
tb_expect_list toolbox '^move,marquee,rect,' "the list is Annotate's toolbox"
if [[ -z "$(tb_ws_file)" ]]; then pass "nothing saved (nothing changed)"; else fail "a workspace was saved: $(tb_ws_file)"; fi
tb_click close
assert_no_crash
tb_reset_ws
