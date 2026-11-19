#!/bin/bash
# =============================================================================
# toolbox-toggle-pushed.sh — QA test: a toggle command on the toolbox looks pushed while
# it is on, like the current tool (Rick 2026-11-18: "the AA antialiasing button in the
# toolbox needs a state - it's a push button if anti aliasing is on, it should look pushed
# like the current tool choice does in the theme"), and Customize Toolbars draws toolbox
# commands as the toolbox does ("showing non theme based toolbox images - just the symbols").
#   1. a workspace puts Toggle Anti-Aliasing (cmd:958) on the toolbox
#   2. AA on: its cell changes (the pushed overlay); AA off: back as it was
#   3. a command that picks a tool looks pushed while that is the tool (Rick: "the mypaint
#      brush in the toolbox ... doesn't show selected" / "this should be true of any tool
#      that's in the toolbox"): MyPaint Brush Tool (cmd:2680) and Magic Wand (cmd:117) -
#      pushed once picked, back when another tool is (CMD_tool_on%)
#   4. a screenshot of Customize Toolbars (TOOLBOX tab) for the eye
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
BUTTONS=brush,dot,line,rect,ellipse,fill,cmd:958,cmd:2680,cmd:117
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
# --- tool commands --------------------------------------------------------------------
key b; wait_for 0.6 "brush"; dk_park; dk_settle
for spec in "2680|MyPaint Brush Tool|mypaint" "117|Magic Wand|wand"; do
    IFS='|' read -r CID CNAME TAG <<< "$spec"
    L=$(grep -m1 "^BTN toolbox [0-9]* 2 $CID " "$DK_DUMP")
    if [[ -z "$L" ]]; then fail "no $CNAME (cmd:$CID) on the toolbox"; continue; fi
    read -r _ _ _ _ _ _ X Y W H <<< "$L"
    snap_region "$X" "$Y" "$W" "$H" "$TAG-idle"; IDLE="$SNAP_RESULT"
    pcmd "$CNAME"
    snap_region "$X" "$Y" "$W" "$H" "$TAG-on"
    assert_regions_differ "$IDLE" "$SNAP_RESULT" "$CNAME picked: its toolbox command looks pushed"
    screenshot "toolbox-tool-cmd-$TAG-on"
    key Escape; wait_for 0.3 "esc"; key b; wait_for 0.6 "brush again"; dk_park; dk_settle
    snap_region "$X" "$Y" "$W" "$H" "$TAG-off"
    assert_regions_same "$IDLE" "$SNAP_RESULT" "Brush picked: $CNAME's command is back as it was"
done
pcmd "Customize Toolbars"
wait_for 1.0 "the editor"
screenshot "toolbox-toggle-editor"
key Escape; wait_for 0.5 "close"
assert_no_crash
