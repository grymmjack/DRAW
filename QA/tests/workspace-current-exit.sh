#!/bin/bash
# =============================================================================
# workspace-current-exit.sh — QA test: the CURRENT workspace's exit prompt
# (Rick, 2026-10-11). A change in stock Default goes into CURRENT without a name
# prompt; exiting while CURRENT has changes asks for a name instead:
#   change   float the edit bar in Default -> CURRENT, no prompt
#   prompt   Alt+X -> the "Save Your Workspace" prompt keeps DRAW open
#   save     type a name + Enter -> DRAW exits; <name>.workspace holds the layout
#            and ("Make this my default workspace", on by default) DRAW.cfg's
#            WORKSPACE= is the new one
#   reopen   DRAW starts in it, edit bar floating
# The prompt is off for every other test (harness override
# WORKSPACE_SAVE_PROMPT=0); this one turns it on.
# QA-OPTIONS: DOCK_DUMP=QA/.dock-dump.txt STOCK_DEFAULT_LAYOUT=1 WORKSPACE_SAVE_PROMPT=1 WORKSPACES_DIR=QA/.tbed-ws
# =============================================================================

source "$DRAW_ROOT/QA/tbed-lib.sh"
tb_reset_ws

info "=== CURRENT workspace + exit prompt ==="
wait_for 1.0 "settle"
key Escape
dk_park; dk_settle

# --- change: Default -> CURRENT, no prompt ------------------------------------------------
dk_move editbar float
sleep 1.2; dk_park; dk_settle
tb_state
if [[ "$TB_WS" == "current" ]] && dk_floating editbar; then pass "the change in Default went into CURRENT (no name asked)"; else fail "workspace '$TB_WS', floating: $(dk_floating editbar && echo yes || echo no)"; fi

# --- prompt on exit ------------------------------------------------------------------------
info "Alt+X: exit asks to keep CURRENT under a name"
key alt+x
sleep 1.2
screenshot "current-exit-prompt"
if kill -0 "$DRAW_PID" 2>/dev/null; then pass "the exit prompt holds DRAW open"; else fail "DRAW exited without the prompt"; fi

type_text "My Panels"
sleep 0.3
key Return
for _w in $(seq 1 50); do kill -0 "$DRAW_PID" 2>/dev/null || break; sleep 0.2; done
if kill -0 "$DRAW_PID" 2>/dev/null; then fail "DRAW is still running after OK"; draw_quit; else pass "OK exits DRAW"; fi

F="$TB_WS_DIR/my-panels.workspace"
if [[ -f "$F" ]] && grep -q '^NAME=My Panels' "$F"; then pass "saved as my-panels.workspace (NAME=My Panels)"; else fail "no my-panels.workspace: $(ls "$TB_WS_DIR" 2>/dev/null | tr '\n' ' ')"; fi
if grep -qi '^editbar=' "$F" 2>/dev/null; then pass "it keeps the floating edit bar"; else fail "no [FLOAT] editbar in $F"; fi
if grep -q '^WORKSPACE=my-panels' "$QA_CFG"; then pass "'Make this my default workspace': DRAW.cfg WORKSPACE=my-panels"; else fail "DRAW.cfg: $(grep '^WORKSPACE=' "$QA_CFG")"; fi

# --- reopen in it -------------------------------------------------------------------------
draw_launch 15
wait_for 1.5 "relaunched"
dk_park; dk_settle
tb_state
if [[ "$TB_WS" == "my-panels" ]] && dk_floating editbar; then pass "DRAW starts in My Panels, edit bar floating"; else fail "started in '$TB_WS', floating: $(dk_floating editbar && echo yes || echo no)"; fi
assert_no_crash

# --- cleanup: a plain instance for the next test -------------------------------------------
draw_quit
tb_reset_ws
draw_launch 15
wait_for 0.8 "Default instance restored"
assert_window_exists
