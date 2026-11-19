#!/bin/bash
# =============================================================================
# toolbar-universal-buttons.sh — QA test: the same toolbox / edit bar / advanced
# bar buttons in every workspace (Rick 2026-11-18: "can you make the toolbox, edit
# bar, and advanced bar have the same button content (not the same layout/width/
# height/scale) just ... which buttons where on those - universal for me across
# all the workspaces?").
#   1. workspace UNIV A (toolbox 2 columns: brush line rect fill MyPaint AA; edit
#      bar undo redo | copy paste) shows its own lists
#   2. View > Same Buttons in Every Workspace (2461): BUTTONS_UNIVERSAL=TRUE and
#      A's lists saved into DRAW.cfg (TOOLBOX_BUTTONS / EDIT_BAR_ORDER)
#   3. switch to UNIV B (its own lists: move marquee picker text / cut clear, 1
#      column): A's buttons show, in B's single column
#   4. per-workspace opt-out (Rick: "yes add a per workspace opt-out"): View > Keep This
#      Workspace's Own Buttons in B -> B's own lists, OWN_BUTTONS=TRUE saved into it; A
#      still shows the shared ones; back in B, its own again; opt-out off -> shared
#   5. UNIV C (OWN_BUTTONS=TRUE, names no buttons): the stock toolbox / edit bar, not
#      the shared ones
#   6. the setting off again: B's own buttons are back
# Dump: BTN panel idx kind id name x y w h; TBED ... workspace.
# QA-OPTIONS: WORKSPACE=univa DOCK_DUMP=QA/.dock-dump.txt WORKSPACES_DIR=/tmp/draw-qa-ws-univ TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
WS_DIR="/tmp/draw-qa-ws-univ"
mkdir -p "$WS_DIR"; rm -f "$WS_DIR"/*.workspace
mkws() { # ID NAME TOOLBOX_COLS TOOLBOX_BUTTONS EDIT_ORDER
    cat > "$WS_DIR/$1.workspace" <<WS
[WORKSPACE]
NAME=$2
DESCRIPTION=QA: universal buttons

[CHROME]
TOOLBOX=SHOW
EDIT_BAR=SHOW
ADVANCED_BAR=SHOW
TOOLBOX_DOCK=LEFT
EDIT_BAR_DOCK=LEFT

[TOOLBOX]
COLUMNS=$3
BUTTONS=$4

[EDIT_BAR]
COLUMNS=1
ORDER=$5
WS
}
A_TB="brush,line,rect,fill,cmd:2680,cmd:958"; A_EB="undo,redo,|,copy,paste"
B_TB="move,marquee,picker,text";            B_EB="cut,clear"
mkws univa "UNIV A" 2 "$A_TB" "$A_EB"
mkws univb "UNIV B" 1 "$B_TB" "$B_EB"
mkws univc "UNIV C" 1 "" ""
sed -i '/^BUTTONS=$/d; /^ORDER=$/d; /^\[TOOLBOX\]/a OWN_BUTTONS=TRUE' "$WS_DIR/univc.workspace"
draw_quit; draw_settle; draw_launch 15; wait_for 1.5 "DRAW up (workspace univa)"

# the names on panel P (toolbox | editbar), in order -> comma list
names() { awk -v p="$1" '$1=="BTN" && $2==p {printf "%s%s", (n++ ? "," : ""), $6}' "$DK_DUMP"; }
# distinct x of the toolbox's drawn cells = its columns
tb_cols() { awk '$1=="BTN" && $2=="toolbox" && $9 > 0 {x[$7]=1} END {n=0; for (k in x) n++; print n}' "$DK_DUMP"; }
ws_now() { awk '$1=="TBED" {print $NF; exit}' "$DK_DUMP"; }
saved() { grep -q "^$1=$2[[:space:]]*\$" "$QA_CFG" && pass "$1=$2 saved" || fail "$1: saved '$(grep "^$1=" "$QA_CFG" | tr -d '\r')', want $2"; }
pcmd() { dk_park; key question; wait_for 1.0 "command palette"; type_text "$1"; wait_for 0.6 "filtered"; key Return; wait_for 1.2 "$1"; dk_park; dk_settle; }
switch_to() { dk_park; key ctrl+shift+w; wait_for 0.6 "switcher"; type_text "$1"; wait_for 0.4 "filtered"; key Return; wait_for 1.5 "workspace $1"; dk_park; dk_settle; }
same() { [[ "$2" == "$3" ]] && pass "$1 ($2)" || fail "$1: '$2', want '$3'"; }

info "=== The same toolbar buttons in every workspace ==="
dk_begin
same "UNIV A: its own toolbox" "$(names toolbox)" "$A_TB"
same "UNIV A: its own edit bar" "$(names editbar)" "$A_EB"
info "UNIV A toolbox: $(tb_cols) columns"

# --- 2. on ---------------------------------------------------------------------------
pcmd "Same Toolbar Buttons in Every"
saved BUTTONS_UNIVERSAL TRUE
saved TOOLBOX_BUTTONS "$A_TB"
saved EDIT_BAR_ORDER "$A_EB"
same "on: UNIV A keeps its buttons" "$(names toolbox)" "$A_TB"

# --- 3. UNIV B shows A's buttons in its own columns -----------------------------------
switch_to "univ b"
[[ "$(ws_now)" == univb ]] && pass "switched to UNIV B" || fail "workspace is '$(ws_now)', want univb"
same "UNIV B: the shared toolbox, not its own" "$(names toolbox)" "$A_TB"
same "UNIV B: the shared edit bar" "$(names editbar)" "$A_EB"
C=$(tb_cols)
(( C == 1 )) && pass "UNIV B: its own 1 toolbox column" || fail "UNIV B toolbox: $C columns, want its own 1"
screenshot "toolbar-universal-univb"

# --- 4. B opts out --------------------------------------------------------------------
pcmd "Keep This Workspace's Own"
same "B opted out: its own toolbox" "$(names toolbox)" "$B_TB"
same "B opted out: its own edit bar" "$(names editbar)" "$B_EB"
grep -q "^OWN_BUTTONS=TRUE" "$WS_DIR/univb.workspace" && pass "OWN_BUTTONS=TRUE saved into univb.workspace" || fail "univb.workspace: no OWN_BUTTONS=TRUE [$(grep -A3 '^\[TOOLBOX\]' "$WS_DIR/univb.workspace" | tr '\n' ' ')]"
switch_to "univ a"
same "UNIV A: still the shared toolbox" "$(names toolbox)" "$A_TB"
switch_to "univ b"
same "back in B: its own toolbox (from the file)" "$(names toolbox)" "$B_TB"
pcmd "Keep This Workspace's Own"
same "B opt-out off: the shared toolbox again" "$(names toolbox)" "$A_TB"

# --- 5. C: opted out, no lists: stock ----------------------------------------------------
switch_to "univ c"
[[ "$(ws_now)" == univc ]] && pass "switched to UNIV C" || fail "workspace is '$(ws_now)', want univc"
T=$(names toolbox); E=$(names editbar)
[[ "$T" != "$A_TB" && "$T" == *zoom* ]] && pass "UNIV C: the stock toolbox, not the shared one" || fail "UNIV C toolbox: '$T'"
[[ "$E" != "$A_EB" && "$E" == *cut* ]] && pass "UNIV C: the stock edit bar" || fail "UNIV C edit bar: '$E'"
switch_to "univ b"

# --- 6. off ----------------------------------------------------------------------------
pcmd "Same Toolbar Buttons in Every"
saved BUTTONS_UNIVERSAL FALSE
same "off: UNIV B's own toolbox again" "$(names toolbox)" "$B_TB"
same "off: UNIV B's own edit bar again" "$(names editbar)" "$B_EB"
assert_no_crash
info "=== The same toolbar buttons in every workspace: done ==="
