#!/bin/bash
# =============================================================================
# workspace-all-floating.sh — QA test: a workspace saved with EVERY panel
# floating comes back floating, where it was (Rick, 2026-11-14: "i setup
# everything as a floating panel, saved as panel floats, and it docked stuff
# all over the place, resized things ... completely shifted").
#
# Cause: with nothing docked the snapshot has no column, and DOCK_load_snapshot
# took "no column" for "no arrangement" - the default tree was built and every
# panel docked again. (A layout with one panel still docked was fine, which is
# why the dock tests never saw it.)
#
# Default in stock mode (STOCK_DEFAULT_LAYOUT=1, as Rick has it): the floats go
# into CURRENT; Save Current Layout As "panel floats"; Default (the stock tree);
# then PANEL FLOATS again - and once more from a restart-like reload (Default ->
# Current -> PANEL FLOATS). Dump: WSA <active id>, TREE, P / WIN lines.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt WORKSPACES_DIR=QA/.ws-all-floating STOCK_DEFAULT_LAYOUT=1 WORKSPACE_SAVE_PROMPT=0 TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE CHARMAP_VISIBLE=1
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
WSD="$DRAW_ROOT/QA/.ws-all-floating"
mkdir -p "$WSD"; rm -f "$WSD"/panel-floats.workspace "$WSD"/current.workspace "$WSD"/*.txt
pal() { # QUERY - run a command palette entry
    local try
    for try in 1 2 3; do
        dk_park; key question; wait_for 1.0 "palette"
        grep -q '^POPUP cmdpalette' "$DK_DUMP" && break
    done
    type_text "$1"; wait_for 1.2 "filtered"; key Return; wait_for 1.5 "$1"
}
wsa() { awk '$1=="WSA" {print $2}' "$DK_DUMP"; }
state() { grep -E '^P |^WIN ' "$DK_DUMP" | grep -v '^P [a-z0-9]* 0 0 '; }
snap() { dk_park; dk_settle; state > "$WSD/$1.txt"; info "--- $1: WSA $(wsa); TREE [$(dk_tree)]"; }
same() { # A B LABEL
    if diff "$WSD/$1.txt" "$WSD/$2.txt" > "$WSD/diff.txt"; then pass "$3"
    else fail "$3"; while read -r l; do info "   $l"; done < "$WSD/diff.txt"; fi
}

info "=== Workspace: every panel floating, saved and recalled ==="
dk_begin
snap start
[[ -n "$(dk_tree)" ]] && pass "starts docked [$(dk_tree)]" || fail "no tree at the start"
# the Character Map first: docked, its wide column covers drop points on the right
dk_move charmap float 420 180; dk_settle
dk_move toolbox float 330 70; dk_settle
dk_move layers float 640 60; dk_settle
dk_move editbar float 250 300; dk_settle
dk_move advbar float 760 300; dk_settle
if dk_p organizer && (( P_SLOT > 0 )); then dk_move organizer float 480 330; dk_settle; fi
if dk_p drawer && (( P_SLOT > 0 )); then dk_move drawer float 560 330; dk_settle; fi
snap floated
T=$(dk_tree)
[[ -z "${T// /}" ]] && pass "every panel floats (no column)" || fail "still docked: [$T]"
[[ "$(wsa)" == current ]] && pass "stock Default: the change went into CURRENT" || fail "active workspace '$(wsa)' after the floats"

pal "save current layout"; type_text "panel floats"; wait_for 0.5 "typed"; key Return; wait_for 2.0 "saved"
snap saved
[[ "$(wsa)" == panel-floats ]] && pass "saved and active: panel-floats" || fail "active '$(wsa)' after Save As"
same floated saved "Save As leaves the screen as it was"
grep -q '^\[FLOAT\]' "$WSD/panel-floats.workspace" 2>/dev/null && pass "the file has its [FLOAT] rects" || fail "no [FLOAT] in panel-floats.workspace"

pal "workspace: default"; snap default
[[ "$(wsa)" == default ]] && pass "Default is active" || fail "active '$(wsa)', not default"
[[ -n "$(dk_tree)" ]] && pass "Default shows the stock tree [$(dk_tree)]" || fail "Default has no tree"

pal "workspace: panel floats"; snap recalled
[[ "$(wsa)" == panel-floats ]] && pass "PANEL FLOATS is active again" || fail "active '$(wsa)'"
T=$(dk_tree)
[[ -z "${T// /}" ]] && pass "recalled: nothing docked" || fail "recalled docked: [$T]"
same saved recalled "recalled: every panel where it was saved"
screenshot "workspace-all-floating"
assert_no_crash
info "=== Workspace: every panel floating: done ==="
