#!/bin/bash
# =============================================================================
# tbed-lib.sh — helpers for the Customize Toolbars QA tests (tests/tbed-*.sh).
#
# Tests run with
#   # QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt WORKSPACES_DIR=QA/.tbed-ws
# so DRAW appends its panels' buttons and the editor window's controls to the
# dock layout dump (GUI/TOOLBAR-EDITOR.BM TBED_dump$), and saves workspaces into
# a scratch folder (never the user's own). Dump lines used here:
#   BTN  panel idx kind id name x y w h   (panel toolbox|editbar|advbar; kind 1
#        tool, 2 command, 3 divider, 4 gap; name as in workspace files: undo,
#        brush, cmd:<id> ...; 0 size = not drawn)
#   TBED editmode tab selected entries availableRows currentTool workspace
#   TBC  control x y w h                  (tab1..3 search add remove up down div
#        gap reset colsdn colsup done close title av0 ls0; avtop/lstop: first
#        visible row, rows shown)
# Coordinates are viewport px (what click / hover use).
# =============================================================================

source "$DRAW_ROOT/QA/dock-lib.sh"

TB_WS_DIR="$DRAW_ROOT/QA/.tbed-ws"

tb_reset_ws() { rm -rf "$TB_WS_DIR"; }

# TBED line -> TB_EDIT TB_TAB TB_SEL TB_N TB_AVN TB_TOOL TB_WS
tb_state() { read -r _ TB_EDIT TB_TAB TB_SEL TB_N TB_AVN TB_TOOL TB_WS <<< "$(grep '^TBED ' "$DK_DUMP")"; }

# control NAME's center -> CX CY (1 = not in the dump: the window is closed)
tb_ctl() {
    local line x y w h
    line=$(grep "^TBC $1 " "$DK_DUMP" 2>/dev/null) || return 1
    read -r _ _ x y w h <<< "$line"
    CX=$(( x + w / 2 )); CY=$(( y + h / 2 ))
}
tb_click() { tb_ctl "$1" || { fail "no control '$1' in the dump"; return 1; }; click "$CX" "$CY"; sleep 0.35; dk_settle; }

# row n (0 = first visible) of the editor's Available (av) / panel (ls) list -> CX CY
tb_row() {
    local line x y w h
    line=$(grep "^TBC $1""0 " "$DK_DUMP") || return 1
    read -r _ _ x y w h <<< "$line"
    CX=$(( x + w / 2 )); CY=$(( y + h * $2 + h / 2 ))
}

# click entry IDX of the editor's panel list, wheel-scrolling it into view first
tb_ls_click() {
    local idx=$1 top rows n=0
    while (( n < 20 )); do
        read -r _ _ top rows _ <<< "$(grep '^TBC lstop ' "$DK_DUMP")"
        tb_row ls 0
        if (( idx < top )); then scroll_up "$CX" "$CY"; sleep 0.25; dk_settle
        elif (( idx >= top + rows )); then scroll_down "$CX" "$CY"; sleep 0.25; dk_settle
        else tb_row ls $(( idx - top )); click "$CX" "$CY"; sleep 0.35; dk_settle; return 0
        fi
        n=$(( n + 1 ))
    done
    fail "could not scroll entry $idx into view"; return 1
}

# how many entries PANEL has
tb_count() { awk -v p="$1" '$1 == "BTN" && $2 == p {n++} END{print n+0}' "$DK_DUMP"; }

# the panel's entries as a comma list of names
tb_list() { awk -v p="$1" '$1 == "BTN" && $2 == p {printf "%s%s", (n++ ? "," : ""), $6}' "$DK_DUMP"; }

# index of the first entry NAME on PANEL (-1 = none)
tb_idx() { awk -v p="$1" -v n="$2" 'BEGIN{r=-1} $1 == "BTN" && $2 == p && $6 == n && r < 0 {r=$3} END{print r}' "$DK_DUMP"; }

# entry IDX of PANEL -> BX BY BW BH (center BCX BCY); 1 = not drawn
tb_btn() {
    local line
    line=$(awk -v p="$1" -v i="$2" '$1 == "BTN" && $2 == p && $3 == i' "$DK_DUMP")
    [[ -n "$line" ]] || return 1
    read -r _ _ _ _ _ _ BX BY BW BH <<< "$line"
    (( BW > 0 )) || return 1
    BCX=$(( BX + BW / 2 )); BCY=$(( BY + BH / 2 ))
}

# open the editor with View > Customize Toolbars (through the command palette)
tb_open() {
    key question; sleep 0.5
    type_text "customize toolbars"; sleep 0.3
    key Return; sleep 0.8
    dk_settle
    tb_state
    if [[ "$TB_EDIT" == "-1" ]]; then pass "Customize Toolbars is open"; else fail "Customize Toolbars did not open"; fi
}

# answer the "name for a new workspace" prompt (Default's first change)
tb_name_prompt() { sleep 0.6; type_text "$1"; key Return; sleep 1.2; dk_settle; }

tb_expect_list() { # PANEL REGEX LABEL
    local l; l=$(tb_list "$1")
    if [[ "$l" =~ $2 ]]; then pass "$3"; else fail "$3 (the $1 is: $l)"; fi
}
tb_expect_no() { # PANEL NAME LABEL
    if [[ "$(tb_idx "$1" "$2")" == "-1" ]]; then pass "$3"; else fail "$3 ($2 is still on the $1: $(tb_list "$1"))"; fi
}
tb_ws_file() { ls "$TB_WS_DIR"/*.workspace 2>/dev/null | head -1; }
