#!/bin/bash
# =============================================================================
# workspace-home-default2.sh — QA test: Default 2 is home (Rick 2026-11-20: "DEFAULT
# workspace should be replaced with DEFAULT 2 - everywhere it's referenced").
#   - a remembered workspace that is gone opens home (WORKSPACE_HOME = default-2)
#   - the plain Default is left out of the switcher: "workspace: default" in the
#     command palette lands in Default 2, never the no-overlay base
#   - WORKSPACE_HOME=default (the suite's pin) is covered by every other test
#   - Default 2 is TITLED Default: its workflow button reads DEFAULT (Rick: "rename
#     default 2 to default in the menu ... and its workspace label")
# Dump: WSA <active workspace id>, WFB <n> x y w h lit id label shown.
# QA-OPTIONS: WORKSPACE=no-such-workspace WORKSPACE_HOME=default-2 WORKFLOW_BUTTONS=default-2,animate DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"

wsa() { dk_park; dk_settle; grep -m1 '^WSA ' "$DK_DUMP" | cut -d' ' -f2; }
pal() { # QUERY - run a command palette entry
    local try
    for try in 1 2 3; do
        dk_park; key question; wait_for 1.0 "palette"
        grep -q '^POPUP cmdpalette' "$DK_DUMP" && break
    done
    type_text "$1"; wait_for 1.2 "filtered"; key Return; wait_for 1.5 "$1"; dk_settle
}

info "=== Default 2 is home ==="
dk_begin

W=$(wsa)
[[ "$W" == "default-2" ]] && pass "a remembered workspace that is gone opens home: default-2" || fail "started in '$W', not default-2"

L=$(grep -m1 '^WFB .* default-2 ' "$DK_DUMP" | awk '{print $9}')
[[ "$L" == "DEFAULT" ]] && pass "the default-2 workflow button is labelled DEFAULT" || fail "default-2 workflow button label '$L' (want DEFAULT): $(grep '^WFB' "$DK_DUMP" | head -3)"

pal "workspace: animate"
W=$(wsa)
[[ "$W" == "animate" ]] && pass "switched to animate" || fail "after 'workspace: animate': '$W'"

pal "workspace: default"
W=$(wsa)
if [[ "$W" == "default-2" ]]; then
    pass "'workspace: default' finds Default 2 - the plain Default is not listed"
elif [[ "$W" == "default" ]]; then
    fail "the plain Default is still in the switcher"
else
    fail "after 'workspace: default': '$W'"
fi

assert_no_crash
