#!/bin/bash
# =============================================================================
# workspace-stock-default.sh — QA test: with STOCK_DEFAULT_LAYOUT=1 the Default
# workspace keeps the stock panel layout (Rick, 2026-10-08):
#   current  float the edit bar in Default -> no name asked (2026-10-11): the
#            CURRENT workspace (current.workspace) holds the layout and is
#            switched to
#   back     switch to Default: the stock layout again; DRAW.cfg never got the
#            arrangement
#   again    switch to Current: the floating edit bar is back
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt STOCK_DEFAULT_LAYOUT=1 WORKSPACES_DIR=QA/.tbed-ws
# =============================================================================

source "$DRAW_ROOT/QA/tbed-lib.sh"
tb_reset_ws

switch_to() {
    key ctrl+shift+w; sleep 0.5
    type_text "$1"; sleep 0.3
    key Return; sleep 1.0
    dk_park; dk_settle
}

info "=== Default keeps the stock layout ==="
wait_for 1.0 "settle"
key Escape
dk_park
dk_settle
T0=$(dk_tree)
info "stock tree: $T0"

# --- current ---------------------------------------------------------------------------
dk_move editbar float
sleep 1.2; dk_park; dk_settle
tb_state
if [[ "$TB_WS" == "current" ]]; then pass "floating a panel in Default switched to CURRENT - no name asked"; else fail "workspace is '$TB_WS'"; fi
if dk_floating editbar; then pass "it shows the floating edit bar"; else fail "the edit bar is not floating in CURRENT"; fi
if [[ "$(basename "$(tb_ws_file)")" == "current.workspace" ]]; then pass "kept in current.workspace"; else fail "workspace file: '$(tb_ws_file)'"; fi
if grep -qi '^editbar=' "$(tb_ws_file)" 2>/dev/null; then pass "its file keeps the floating edit bar ([FLOAT] editbar=)"; else fail "no [FLOAT] editbar in $(tb_ws_file)"; cat "$(tb_ws_file)" 2>/dev/null | tail -12; fi

# --- back to Default ------------------------------------------------------------------
switch_to def
tb_state
if [[ "$TB_WS" == "default" ]]; then pass "switched back to Default"; else fail "workspace is '$TB_WS'"; fi
if [[ "$(dk_tree)" == "$T0" ]] && ! dk_floating editbar; then pass "Default shows the stock layout again"; else fail "Default: $(dk_tree)"; fi
if grep -q '^DOCK_' "$QA_CFG"; then fail "the arrangement was written to the config: $(grep '^DOCK_' "$QA_CFG" | head -3)"; else pass "DRAW.cfg has no arrangement of its own"; fi

# --- and to Current again ---------------------------------------------------------------
switch_to current
tb_state
if [[ "$TB_WS" == "current" ]] && dk_floating editbar; then pass "CURRENT still has the floating edit bar"; else fail "CURRENT: workspace '$TB_WS', floating: $(dk_floating editbar && echo yes || echo no)"; fi
assert_no_crash
tb_reset_ws
