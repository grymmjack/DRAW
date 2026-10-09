#!/bin/bash
# =============================================================================
# workspace-stock-default.sh — QA test: with STOCK_DEFAULT_LAYOUT=1 the Default
# workspace keeps the stock panel layout (Rick, 2026-10-08):
#   cancel   float the edit bar in Default -> asked for a workspace name ->
#            Esc: the layout goes back to stock, nothing is saved
#   name     float it again -> name "Panels": a workspace based on Default
#            holds the layout and is switched to
#   back     switch to Default: the stock layout again; DRAW.cfg never got the
#            arrangement
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

# --- cancel ----------------------------------------------------------------------
dk_move editbar float
sleep 0.8; key Escape; sleep 1.0; dk_park; dk_settle
if [[ "$(dk_tree)" == "$T0" ]] && ! dk_floating editbar; then pass "Esc at the name prompt puts the stock layout back"; else fail "after Esc: $(dk_tree) (floating: $(dk_floating editbar && echo yes || echo no))"; fi
if [[ -z "$(tb_ws_file)" ]]; then pass "nothing was saved"; else fail "a workspace was saved: $(tb_ws_file)"; fi

# --- name ------------------------------------------------------------------------------
dk_move editbar float
tb_name_prompt "Panels"
dk_park; dk_settle
tb_state
if [[ "$TB_WS" == "panels" ]]; then pass "the workspace 'Panels' was made and switched to"; else fail "workspace is '$TB_WS'"; fi
if dk_floating editbar; then pass "it shows the floating edit bar"; else fail "the edit bar is not floating in the new workspace"; fi
if grep -qi '^editbar=' "$(tb_ws_file)" 2>/dev/null; then pass "its file keeps the floating edit bar ([FLOAT] editbar=)"; else fail "no [FLOAT] editbar in $(tb_ws_file)"; cat "$(tb_ws_file)" 2>/dev/null | tail -12; fi

# --- back to Default ------------------------------------------------------------------
switch_to def
tb_state
if [[ "$TB_WS" == "default" ]]; then pass "switched back to Default"; else fail "workspace is '$TB_WS'"; fi
if [[ "$(dk_tree)" == "$T0" ]] && ! dk_floating editbar; then pass "Default shows the stock layout again"; else fail "Default: $(dk_tree)"; fi
if grep -q '^DOCK_' "$QA_CFG"; then fail "the arrangement was written to the config: $(grep '^DOCK_' "$QA_CFG" | head -3)"; else pass "DRAW.cfg has no arrangement of its own"; fi
assert_no_crash
tb_reset_ws
