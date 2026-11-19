#!/bin/bash
# =============================================================================
# workspace-recall-all.sh — QA test: a workspace remembers its WHOLE layout
# and gives it back exactly (Rick, 2026-11-14: "EVERY SINGLE PANEL that
# exists, with EVERY SINGLE CONFIGURATION ... MUST BE REMEMBERED in a
# workspace layout, then when they switch they must be RECALLED just the way
# they were REMEMBERED").
#
# Before: a panel shown / hidden in a workspace was never saved; the dock
# sides in [CHROME] came from stale side keys, not the tree (the file said
# LAYER_PANEL_DOCK=LEFT with layers on the right); hidden windows lost their
# places; changes made by a command (no click after) could be missed; and a
# panel shown / docked in a workspace leaked into DRAW.cfg (Default).
#
# The whole live layout (WS_layout_state$: every [CHROME] visibility + dock
# side, columns, layers width, [DOCK]/[FLOAT], [WINDOWS], [PANELS]) is
# compared, not a few keys:
#  1. Default's layout recorded (S0) and DRAW.cfg's values for the keys below
#  2. RECALL A: strip Max Rows 2, layers 1x, preview 1x, swatches 16 columns,
#     layers docked left, Snap Panel Edges toggled, Color Mixer shown (the
#     last two by command, then switched away at once) -> SA
#  3. RECALL A's file has each of them; RECALL B's file none of them
#  4. RECALL B: none of A's changes are live
#  5. Default: exactly S0 again, and DRAW.cfg still has its own values
#  6. back to RECALL A: exactly SA
#  7. restart DRAW: it comes back in RECALL A, exactly SA
#  8. F11 in A, quit, restart: exactly SA (F11's hiding is not remembered)
#
# Dump: <dump>.wsreq -> <dump>.ws (dk_ws_state: sorted SECTION.KEY=value + WSA=)
# QA-OPTIONS: DOCK_DUMP=QA/.dock-dump.txt WORKSPACES_DIR=/tmp/draw-qa-ws-recall STOCK_DEFAULT_LAYOUT=1 WORKSPACE_SAVE_PROMPT=0 TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
source "$DRAW_ROOT/QA/swatches-lib.sh"
WSD="/tmp/draw-qa-ws-recall"
OUT="${RESULTS_DIR:-/tmp}/ws-recall"; mkdir -p "$OUT"; rm -f "$OUT"/*
mkdir -p "$WSD"; rm -f "$WSD"/*.workspace
cat > "$WSD/recall-a.workspace" <<'EOF'
; QA fixture
[WORKSPACE]
NAME=Recall A
[CHROME]
PREVIEW=SHOW
SWATCHES=SHOW
LAYER_PANEL=SHOW
COLOR_MIXER=HIDE
[DOCK]
LEFT.1=AUTO; toolbox | organizer | drawer
RIGHT.1=AUTO; preview@67 | swatches@85 | layers@300
EOF
cat > "$WSD/recall-b.workspace" <<'EOF'
; QA fixture
[WORKSPACE]
NAME=Recall B
[CHROME]
PREVIEW=HIDE
EOF
cp "$WSD/recall-b.workspace" "$OUT/recall-b.orig"

pal() { # QUERY - run a command palette entry
    local try
    for try in 1 2 3; do
        dk_park; key question; wait_for 1.0 "palette"
        grep -q '^POPUP cmdpalette' "$DK_DUMP" && break
    done
    type_text "$1"; wait_for 1.2 "filtered"; key Return; wait_for 1.5 "$1"; dk_settle
}
psm() { PM_RX=""; read -r _ PM_RX PM_RY PM_RW PM_SUB PM_SX PM_SY PM_SW PM_SN <<< "$(grep -m1 '^PSM ' "$DK_DUMP")"; }
row_y() { echo $(( $1 + 2 + $2 * 12 + 6 )); }
strip_pick() { # ROOT SUBROW: the color strip's size menu
    local sy; sy=$(awk '$1=="PSTRIP" {print $2}' "$DK_DUMP")
    right_click 1 $(( sy + 2 )); wait_for 0.6 "strip menu"; dk_settle; psm
    [[ -n "$PM_RX" ]] || { fail "no strip menu"; return 1; }
    hover $(( PM_RX + PM_RW / 2 )) "$(row_y "$PM_RY" "$1")"; wait_for 0.5 "root $1"; dk_settle; psm
    click $(( PM_SX + PM_SW / 2 )) "$(row_y "$PM_SY" "$2")"; wait_for 0.8 "picked"; dk_park; dk_settle
}
pick_scale() { # NAME DPID VALUE (20 Auto, 20+k = kx)
    local ry rh
    dk_settle
    if ! dk_grab_point "$1"; then fail "$1 has no handle"; return 1; fi
    right_click "$GX" "$GY"; wait_for 0.6 "the handle menu"; dk_settle
    read -r _ MO MP _ MX _ <<< "$(grep -m1 '^DMENU ' "$DK_DUMP")"
    if [[ "$MO" != -1 || "$MP" != "$2" ]]; then fail "$1: no handle menu (open '$MO' panel '$MP')"; key Escape; return 1; fi
    read -r ry rh _ <<< "$(awk -v v="$3" '$1=="DMENUR" && $3==v {print $4" "$5; exit}' "$DK_DUMP")"
    if [[ -z "$ry" ]]; then fail "$1: no Scale row $3 in its menu"; key Escape; return 1; fi
    click $(( MX + 12 )) $(( ry + rh / 2 )); wait_for 0.8 "scale row $3"; dk_park; dk_settle
}
sw_chip() { K_X=""; read -r _ _ _ K_X K_Y K_W K_H _ <<< "$(awk -v id="$1" -v lb="$2" '$1=="SWATMC" && $2==id && $8==lb' "$DK_DUMP" | head -1)"; }
fileval() { tr -d '\r' < "$WSD/$1.workspace" | awk -v s="[$2]" -v k="$3" '/^\[/{sec=$0} sec==s && index($0, k"=")==1 {print substr($0, length(k)+2)}'; }
stval() { grep "^$2=" "$1" | head -1 | cut -d= -f2-; }
cfgval() { tr -d '\r' < "$QA_CFG" | grep -m1 "^$1=" | cut -d= -f2-; }
same_state() { # LABEL WANT GOT
    if diff "$2" "$3" > "$OUT/diff.txt"; then pass "$1"; else fail "$1: $(tr '\n' ' ' < "$OUT/diff.txt" | cut -c1-600)"; fi
}
CFG_KEYS="PALETTE_MAX_ROWS LAYER_PANEL_SCALE PREVIEW_SCALE SWATCHES_COLS LAYERS_PANEL_DOCK_EDGE SNAP_PANEL_EDGES COLOR_MIXER_VISIBLE PREVIEW_VISIBLE SWATCHES_VISIBLE"
cfg_snapshot() { local k; for k in $CFG_KEYS; do echo "$k=$(cfgval $k)"; done; }

info "=== Workspace: remember / recall the whole layout ==="
dk_begin
pal "reload workspaces"
pal "workspace: default"
dk_ws_state "$OUT/s0.txt"
cfg_snapshot > "$OUT/cfg0.txt"
info "Default: $(grep -c . "$OUT/s0.txt") layout keys; DRAW.cfg: $(tr '\n' ' ' < "$OUT/cfg0.txt")"

# --- 2. changes in RECALL A -----------------------------------------------------------
pal "workspace: recall a"
[[ "$(stval "$OUT/s0.txt" WSA)" == default ]] || fail "did not start in Default"
dk_ws_state "$OUT/sa0.txt"
[[ "$(stval "$OUT/sa0.txt" WSA)" == recall-a ]] && pass "RECALL A is active" || fail "active '$(stval "$OUT/sa0.txt" WSA)'"
[[ "$(stval "$OUT/sa0.txt" CHROME.LAYER_PANEL_DOCK)" == RIGHT ]] && pass "[CHROME] dock side read from the tree (layers on the right)" || fail "LAYER_PANEL_DOCK '$(stval "$OUT/sa0.txt" CHROME.LAYER_PANEL_DOCK)' with layers in RIGHT.1"

strip_pick 0 1                 # Max Rows 2
pick_scale layers 4 21         # layers 1x
pick_scale preview "$(awk '$1=="CONST" && $2=="DP_PREVIEW" {print $4; exit}' "$DRAW_ROOT/GUI/DOCK.BI")" 21 # preview 1x (its id from GUI/DOCK.BI: it moves as dock panels are added)
sw_geo
if [[ -n "$E_X" && "$E_W" -gt 0 ]]; then
    click $(( E_X + E_W / 2 )) $(( E_Y + E_H / 2 )); dk_settle
    sw_chip 10 16
    if [[ -n "$K_X" ]]; then click $(( K_X + K_W / 2 )) $(( K_Y + K_H / 2 )); dk_settle; else fail "no COLUMNS 16 chip"; fi
    key Escape; dk_settle
else
    fail "no swatches gear (SWATG: $(grep '^SWATG' "$DK_DUMP"))"
fi
pal "layer panel dock left"
wait_for 1.0 "remembered"
pal "snap panel edges"
pal "toggle color mixer"       # by command, no click after
dk_ws_state "$OUT/sa.txt"; screenshot "ws-recall-a-changed"
diff "$OUT/sa0.txt" "$OUT/sa.txt" > "$OUT/d-a.txt"; info "changes made in A: $(grep -c '^>' "$OUT/d-a.txt") keys"
expect_state() { local v; v=$(stval "$OUT/sa.txt" "$1"); [[ "$v" == "$2" ]] && pass "live in A: $1 = $2" || fail "live in A: $1 = '$v', want '$2'"; }
expect_state PANELS.PALETTE_MAX_ROWS 2
expect_state PANELS.LAYER_PANEL_SCALE 1
expect_state PANELS.PREVIEW_SCALE 1
expect_state PANELS.SWATCHES_COLS 16
expect_state CHROME.LAYER_PANEL_DOCK LEFT
expect_state CHROME.COLOR_MIXER SHOW
SNAP_A=$(stval "$OUT/sa.txt" PANELS.SNAP_PANEL_EDGES); SNAP_0=$(stval "$OUT/s0.txt" PANELS.SNAP_PANEL_EDGES)
[[ -n "$SNAP_A" && "$SNAP_A" != "$SNAP_0" ]] && pass "live in A: Snap Panel Edges toggled ($SNAP_0 -> $SNAP_A)" || fail "Snap Panel Edges in A '$SNAP_A', Default '$SNAP_0'"

# --- 4. RECALL B ------------------------------------------------------------------------
pal "workspace: recall b"
dk_ws_state "$OUT/sb.txt"
[[ "$(stval "$OUT/sb.txt" WSA)" == recall-b ]] && pass "RECALL B is active" || fail "active '$(stval "$OUT/sb.txt" WSA)'"
BAD=""
for k in PANELS.PALETTE_MAX_ROWS PANELS.LAYER_PANEL_SCALE PANELS.PREVIEW_SCALE PANELS.SWATCHES_COLS PANELS.SNAP_PANEL_EDGES CHROME.LAYER_PANEL_DOCK CHROME.COLOR_MIXER; do
    [[ "$(stval "$OUT/sb.txt" $k)" == "$(stval "$OUT/s0.txt" $k)" ]] || BAD+=" $k=$(stval "$OUT/sb.txt" $k)"
done
[[ -z "$BAD" ]] && pass "RECALL B has none of A's changes (Default's values where it names none)" || fail "A's changes in B:$BAD"
[[ "$(stval "$OUT/sb.txt" CHROME.PREVIEW)" == HIDE ]] && pass "B hides the preview, as its file says" || fail "B: CHROME.PREVIEW '$(stval "$OUT/sb.txt" CHROME.PREVIEW)'"

# --- 3. the files -------------------------------------------------------------------------
cp "$WSD/recall-a.workspace" "$OUT/recall-a.saved"
expect_file() { local v; v=$(fileval recall-a "$1" "$2"); [[ "$v" == "$3" ]] && pass "A's file [$1] $2 = $3" || fail "A's file [$1] $2 = '$v', want '$3'"; }
expect_file PANELS PALETTE_MAX_ROWS 2
expect_file PANELS LAYER_PANEL_SCALE 1
expect_file PANELS PREVIEW_SCALE 1
expect_file PANELS SWATCHES_COLS 16
expect_file CHROME LAYER_PANEL_DOCK LEFT
expect_file CHROME COLOR_MIXER SHOW
[[ -n "$(fileval recall-a WINDOWS COLOR_SPACE_3D_X)" && -n "$(fileval recall-a WINDOWS BROWSER_POS_X)" ]] \
    && pass "A's file has the places of windows not on screen too ([WINDOWS] COLOR_SPACE_3D_X / BROWSER_POS_X)" || fail "A's [WINDOWS]: $(tr -d '\r' < "$WSD/recall-a.workspace" | awk '/^\[WINDOWS\]/{f=1;next} /^\[/{f=0} f' | tr '\n' ' ')"
tr -d '\r' < "$WSD/recall-a.workspace" | awk '/^\[DOCK\]/{f=1;next} /^\[/{f=0} f' | grep -q 'layers' \
    && tr -d '\r' < "$WSD/recall-a.workspace" | grep -E '^LEFT\.[0-9]=.*layers' >/dev/null && pass "A's [DOCK] has layers on the left" || fail "A's [DOCK]: $(tr -d '\r' < "$WSD/recall-a.workspace" | awk '/^\[DOCK\]/{f=1;next} /^\[/{f=0} f' | tr '\n' '|')"
[[ -z "$(fileval recall-a WINDOWS SWATCHES_X)" ]] && pass "no floating place for the docked swatches (the dock has it)" || fail "[WINDOWS] SWATCHES_X kept for a docked panel"
cmp -s "$WSD/recall-b.workspace" "$OUT/recall-b.orig" && pass "B's file was not written (nothing changed there)" || info "B's file now: $(tr '\r\n' '  ' < "$WSD/recall-b.workspace" | cut -c1-300)"
grep -qE '^(PALETTE_MAX_ROWS=2|SWATCHES_COLS=16)\b' <(tr -d '\r' < "$WSD/recall-b.workspace") && fail "A's values in B's file" || pass "no A values in B's file"

# --- 5. Default ---------------------------------------------------------------------------
pal "workspace: default"
dk_ws_state "$OUT/s0b.txt"
same_state "Default: exactly its own layout again" "$OUT/s0.txt" "$OUT/s0b.txt"
cfg_snapshot > "$OUT/cfg1.txt"
same_state "DRAW.cfg kept Default's values (nothing leaked from A / B)" "$OUT/cfg0.txt" "$OUT/cfg1.txt"

# --- 6. back to A -------------------------------------------------------------------------
pal "workspace: recall a"
wait_for 0.8 "settle"
dk_ws_state "$OUT/sa2.txt"; screenshot "ws-recall-a-back"
same_state "RECALL A after B and Default: exactly as it was left" "$OUT/sa.txt" "$OUT/sa2.txt"

# --- 7. restart ---------------------------------------------------------------------------
sw_quit_wait
draw_launch 15
wait_for 2 "relaunched"
dk_begin
wait_for 1.5 "settle"
dk_ws_state "$OUT/sa3.txt"; screenshot "ws-recall-a-restarted"
same_state "after a restart: RECALL A, exactly as it was left" "$OUT/sa.txt" "$OUT/sa3.txt"

# --- 8. F11, quit, restart -------------------------------------------------------------------
dk_park; key F11; wait_for 0.8 "F11"; dk_settle
dk_ws_state "$OUT/sa4.txt"
same_state "F11-hidden: the layout a workspace keeps is unchanged" "$OUT/sa.txt" "$OUT/sa4.txt"
sw_quit_wait
draw_launch 15
wait_for 2 "relaunched"
dk_begin
wait_for 1.5 "settle"
dk_ws_state "$OUT/sa5.txt"
same_state "quit while F11-hidden, restart: RECALL A exactly (F11 not remembered)" "$OUT/sa.txt" "$OUT/sa5.txt"
pal "workspace: default"
dk_ws_state "$OUT/s0c.txt"
same_state "and Default is still its own" "$OUT/s0.txt" "$OUT/s0c.txt"
assert_no_crash
rm -rf "$WSD"
info "=== Workspace: remember / recall the whole layout: done ==="
