#!/bin/bash
# =============================================================================
# workspace-save-same-name.sh — QA test: one name, one workspace. Saving the
# layout under a name a workspace already has saves OVER it (Rick 2026-10-09:
# saving "GJ2" again made gj2-2.workspace - two menu entries named GJ2).
# Case doesn't make a new one either; Default is built in and is never written.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt WORKSPACES_DIR=QA/.tbed-ws
# =============================================================================
source "$DRAW_ROOT/QA/tbed-lib.sh"
tb_reset_ws

save_as() { # NAME
    key Escape; sleep 0.3
    key question; sleep 0.5
    type_text "save current layout"; sleep 0.4
    key Return
    tb_name_prompt "$1"
}
named() { # how many workspace files carry NAME=$1 (any case; files are CRLF)
    local f n=0
    for f in "$TB_WS_DIR"/*.workspace; do
        [[ -f "$f" ]] && tr -d '\r' < "$f" | grep -qix "NAME=$1" && n=$(( n + 1 ))
    done
    echo "$n"
}

info "=== One name, one workspace ==="
wait_for 1.0 "settle"
save_as "Dup Test"
if (( $(named "Dup Test") == 1 )); then pass "saved: one workspace named Dup Test"; else fail "expected 1 workspace named Dup Test, found $(named 'Dup Test')"; fi
save_as "Dup Test"
if (( $(named "Dup Test") == 1 )); then pass "the same name again saves over it (still one)"; else fail "the same name made another workspace ($(named 'Dup Test') named Dup Test: $(\ls "$TB_WS_DIR"))"; fi
save_as "dup test"
if (( $(named "dup test") == 1 )); then pass "a different case is the same name (still one)"; else fail "a different case made another workspace ($(\ls "$TB_WS_DIR"))"; fi
save_as "Default"
if (( $(named "Default") == 0 )); then pass "Default is built in: nothing written"; else fail "a workspace file named Default was written"; fi
info "workspaces: $(\ls "$TB_WS_DIR" 2>/dev/null | tr '\n' ' ')"
assert_no_crash
tb_reset_ws
