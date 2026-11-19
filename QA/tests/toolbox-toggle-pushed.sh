#!/bin/bash
# =============================================================================
# toolbox-toggle-pushed.sh — QA test: a toggle command on the toolbox looks pushed while
# it is on, like the current tool (Rick 2026-11-18: "the AA antialiasing button in the
# toolbox needs a state - it's a push button if anti aliasing is on, it should look pushed
# like the current tool choice does in the theme"), and Customize Toolbars draws toolbox
# commands as the toolbox does ("showing non theme based toolbox images - just the symbols").
#   1. a workspace puts Toggle Anti-Aliasing (cmd:958) on the toolbox
#   2. AA on: its cell changes (the pushed overlay); AA off: back as it was
#   3. a screenshot of Customize Toolbars (TOOLBOX tab) for the eye
# Dump: BTN panel idx kind id name x y w h.
# QA-OPTIONS: WORKSPACE=aapush DOCK_DUMP=QA/.dock-dump.txt WORKSPACES_DIR=/tmp/draw-qa-ws-aapush TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE ANTIALIAS=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
WS_DIR="/tmp/draw-qa-ws-aapush"
mkdir -p "$WS_DIR"; rm -f "$WS_DIR"/*.workspace
cat > "$WS_DIR/aapush.workspace" <<'WS'
[WORKSPACE]
NAME=aapush
DESCRIPTION=QA: Toggle Anti-Aliasing on the toolbox

[CHROME]
TOOLBOX=SHOW
TOOLBOX_DOCK=LEFT

[TOOLBOX]
COLUMNS=2
BUTTONS=brush,dot,line,rect,ellipse,fill,cmd:958,cmd:2680
WS
draw_quit; draw_settle; draw_launch 15; wait_for 1.5 "DRAW up (workspace aapush)"
pcmd() { dk_park; key question; wait_for 1.0 "command palette"; type_text "$1"; wait_for 0.6 "filtered"; key Return; wait_for 1.0 "$1"; dk_park; dk_settle; }

info "=== A toggle on the toolbox looks pushed while on ==="
dk_begin
L=$(grep -m1 "^BTN toolbox [0-9]* 2 958 " "$DK_DUMP")
if [[ -z "$L" ]]; then fail "no Toggle Anti-Aliasing (cmd:958) on the toolbox [$(grep -c '^BTN toolbox' "$DK_DUMP") toolbox entries]"; assert_no_crash; return 0 2>/dev/null || exit 0; fi
read -r _ _ _ _ _ _ X Y W H <<< "$L"
info "the AA cell: ${W}x$H at $X,$Y"
pass "the workspace put Toggle Anti-Aliasing on the toolbox"
snap_region "$X" "$Y" "$W" "$H" "aa-off"; OFF="$SNAP_RESULT"
pcmd "Toggle Anti-Aliasing"
snap_region "$X" "$Y" "$W" "$H" "aa-on"; ON="$SNAP_RESULT"
assert_regions_differ "$OFF" "$ON" "AA on: the toolbox cell looks pushed"
screenshot "toolbox-toggle-pushed-on"
pcmd "Toggle Anti-Aliasing"
snap_region "$X" "$Y" "$W" "$H" "aa-off2"
assert_regions_same "$OFF" "$SNAP_RESULT" "AA off: the cell is back as it was"
pcmd "Customize Toolbars"
wait_for 1.0 "the editor"
screenshot "toolbox-toggle-editor"
key Escape; wait_for 0.5 "close"
assert_no_crash
