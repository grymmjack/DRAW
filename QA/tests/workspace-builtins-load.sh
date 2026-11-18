#!/bin/bash
# =============================================================================
# workspace-builtins-load.sh — QA test: every built-in workspace in
# ASSETS/WORKSPACES starts cleanly (Rick 2026-11-17 shipped GRAFX2, GRAFX2
# Tall, Tablet, VH and Only Menu, and refreshed the others from his own
# copies).
#   - for each one: DRAW started with --workspace <id>: that workspace is the
#     active one, the dock tree passes the invariants and seam checks
#     (dk_check), no runtime error is trapped
# Dump: TBED ... <active workspace id> (the last field) | the dock lines.
# QA-OPTIONS: DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Every built-in workspace loads ==="

for f in "$DRAW_ROOT"/ASSETS/WORKSPACES/*.workspace; do
    id=$(basename "$f" .workspace)
    info "--- $id ---"
    draw_quit
    draw_settle
    rm -f "$DK_DUMP"
    DRAW_EXTRA_ARGS="--workspace $id"
    draw_launch 15
    wait_for 1.5 "$id loaded"
    dk_begin
    act=$(grep -m1 '^TBED ' "$DK_DUMP" | awk '{print $NF}')
    [[ "${act,,}" == "${id,,}" ]] && pass "$id: the active workspace" || fail "$id: started with --workspace $id, active '$act'"
    dk_check "$id"
    screenshot "workspace-builtin-$id"
    assert_no_crash
done
DRAW_EXTRA_ARGS=""
info "=== Built-in workspaces done ==="
