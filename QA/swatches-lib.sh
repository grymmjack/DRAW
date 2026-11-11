#!/bin/bash
# Helpers for the Swatches panel tests (GUI/SWATCHES.BM dump lines: SWAT,
# SWATS, SWATG, SWATC, SWATM*). Source after dock-lib.sh.
sw_read() { read -r _ SW_N SW_COLORS SW_COLS SW_CW SW_CH SW_GAP SW_ROWS SW_SCROLL SW_MAXS SW_FG SW_BG SW_MENU SW_MROWS SW_KEY <<< "$(grep '^SWAT ' "$DK_DUMP")"; }
sw_geo()  { read -r _ G_X G_Y G_W G_H B_X B_Y B_W B_H E_X E_Y E_W E_H M_X M_Y M_W M_H <<< "$(grep '^SWATG ' "$DK_DUMP")"; }
sw_cell() { C_X=; read -r _ _ C_X C_Y C_W C_H C_KIND C_HEX C_FLAGS <<< "$(grep "^SWATC $1 " "$DK_DUMP")"; }
# the selection: SS_N, SS_ANCHOR, SS_LIST ("3 4 5")
sw_sel()  { local a; read -r _ SS_N SS_ANCHOR a <<< "$(grep '^SWATS ' "$DK_DUMP")"; SS_LIST="$a"; }
sw_expect() { if [[ "$2" == "$3" ]]; then pass "$1 = $3"; else fail "$1 = '$2', want '$3'"; fi; }
# click entry $1; $2 = shift / ctrl / right / "" (plain)
sw_click() {
    sw_cell "$1"
    if [[ -z "$C_X" ]]; then fail "entry $1 has no cell in the dump"; return 1; fi
    local x=$(( C_X + C_W / 2 )) y=$(( C_Y + C_H / 2 ))
    case "${2:-}" in
        shift) with_mods shift click "$x" "$y" ;;
        ctrl)  with_mods ctrl click "$x" "$y" ;;
        right) right_click "$x" "$y" ;;
        *)     click "$x" "$y" ;;
    esac
    dk_settle
}
# the cell pitch (viewport px): entry 2's x - entry 1's x (both on row 0)
sw_pitch() { local x1; sw_cell 1; x1=$C_X; sw_cell 2; SW_PITCH=$(( C_X - x1 )); }
# an empty place in the grid: 3 cells right of the last swatch before the
# first row break (the fixture's green row is half empty)
sw_empty_xy() {
    local k; sw_pitch
    # a row break has no cell, so SWATC skips its number
    k=$(awk '$1=="SWATC" { if (p && $2 > p + 1) {print p; exit} p = $2 }' "$DK_DUMP")
    sw_cell "${k:-12}"; EX=$(( C_X + C_W / 2 + 3 * SW_PITCH )); EY=$(( C_Y + C_H / 2 ))
}

# Edits save into My Swatches (PATHS_data$("SWATCHES/")). A normal QA run
# shares the real ~/.local/share/DRAW, so an editing test relaunches DRAW on a
# scratch XDG_DATA_HOME first ([Linux]). In a user-profile run the scratch
# folder starts as a copy of the profile's data, and the harness's re-copy on
# every launch is switched off for this test (it would wipe what the test
# saved before a restart). SW_MINE = the My Swatches folder DRAW now uses.
#   sw_isolate [KEY=VALUE ...]   the pairs go into the QA cfg while DRAW is
#                                closed (sw_cfg_set), so DRAW saves them later
sw_isolate() {
    local kv src="${XDG_DATA_HOME:-}"
    sw_quit_wait
    export XDG_DATA_HOME="${RESULTS_DIR:-/tmp}/sw-data-$RANDOM$RANDOM"
    rm -rf "$XDG_DATA_HOME"; mkdir -p "$XDG_DATA_HOME"
    if [[ "${QA_USER_PROFILE:-0}" == 1 ]]; then
        [[ -n "$src" && -n "${RESULTS_DIR:-}" && "$src" == "$RESULTS_DIR"/* && -d "$src/DRAW" ]] && cp -a "$src/DRAW" "$XDG_DATA_HOME/DRAW"
        QA_USER_PROFILE=0 # this test's subshell only
    fi
    SW_MINE="$XDG_DATA_HOME/DRAW/SWATCHES"
    for kv in "$@"; do sw_cfg_set "${kv%%=*}" "${kv#*=}"; done
    draw_launch 15
    wait_for 1.0 "relaunched (My Swatches: $SW_MINE)"
}
# draw_quit, then wait until that DRAW is really gone: draw_quit does not wait,
# and the window search can otherwise grab the closing window (0x0 -> the
# harness refuses the run)
sw_quit_wait() {
    local pid=$DRAW_PID n=0
    draw_quit
    while [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null && (( n < 50 )); do sleep 0.1; n=$((n + 1)); done
    sleep 0.4
}
# set KEY=VALUE in the QA config itself (rebuilt for every test). Unlike a
# QA-OPTIONS --option, which "beats the .cfg, never saved", DRAW then saves
# the key itself - what a test of a saved setting needs.
sw_cfg_set() {
    if grep -q "^$1=" "$QA_CFG"; then sed -i "s|^$1=.*|$1=$2|" "$QA_CFG"; else echo "$1=$2" >> "$QA_CFG"; fi
}
# quit and start again (the config DRAW saved is kept)
sw_relaunch_saved() {
    sw_quit_wait
    draw_launch 15
    wait_for 1.0 "relaunched"
}
# SWATE: undo steps, redo steps, saves, in My Swatches
sw_edit_state() { read -r _ SE_UNDO SE_REDO SE_SAVES SE_MINE <<< "$(grep '^SWATE ' "$DK_DUMP")"; }
# hover the panel's first cell (the keys work only with the pointer on it)
sw_hover_panel() { sw_cell 1; hover $(( C_X + C_W / 2 )) $(( C_Y + C_H / 2 )); sleep 0.2; }
# the open menu's item with id $1: click it (SWATMI row kind id chk x y w h label)
sw_menu_click() {
    local r mx my mw mh
    r=$(awk -v id="$1" '$1=="SWATMI" && $4==id {print; exit}' "$DK_DUMP")
    read -r _ _ _ _ _ mx my mw mh _ <<< "$r"
    if [[ -z "$mx" ]]; then fail "no menu item $1 in the open menu"; return 1; fi
    click $(( mx + mw / 2 )) $(( my + mh / 2 )); dk_settle
}
# open the edit menu with its button
sw_menu_edit() { sw_geo; click $(( M_X + M_W / 2 )) $(( M_Y + M_H / 2 )); dk_settle; }
# the hex of every entry in order ("-" = empty cell, "|" = row break), from SWATC
sw_hexes() { awk '$1=="SWATC" { for (k = p + 1; p && k < $2; k++) printf " |"; printf "%s%s", (n++ ? " " : ""), ($7==1 ? "-" : $8); p = $2 } END {print ""}' "$DK_DUMP"; }
# SWATD: a swatch drag - on 0/1, the entry it would drop before (0 = none), the pointer's row
sw_dragstate() { read -r _ SD_ON SD_DROP SD_ROW <<< "$(grep '^SWATD ' "$DK_DUMP")"; }
# the left / right half of entry $1's cell (where a drop goes before / after it)
sw_left_of()  { sw_cell "$1"; TX=$(( C_X + 1 )); TY=$(( C_Y + C_H / 2 )); }
sw_right_of() { sw_cell "$1"; TX=$(( C_X + C_W - 2 )); TY=$(( C_Y + C_H / 2 )); }
# sw_drag_hold X1 Y1 X2 Y2 [SHOT] - press, travel, hold still (SWATD read into
# SD_* while the button is down; SHOT = a screenshot then), release. Wrap it in
# `with_mods ctrl` for a copy.
sw_drag_hold() {
    local x1=$1 y1=$2 x2=$3 y2=$4 i
    mouse_down "$x1" "$y1"; sleep 0.2
    for (( i = 1; i <= 6; i++ )); do
        hover $(( x1 + (x2 - x1) * i / 6 )) $(( y1 + (y2 - y1) * i / 6 )); sleep 0.1
    done
    hover "$x2" "$y2"; dk_settle; sw_dragstate
    [[ -n "${5:-}" ]] && screenshot "$5"
    mouse_up; dk_settle
}
# drag entry $1 to (TX, TY)
sw_drag_entry() { local fx fy; sw_cell "$1"; fx=$(( C_X + C_W / 2 )); fy=$(( C_Y + C_H / 2 )); sw_drag_hold "$fx" "$fy" "$TX" "$TY" "${2:-}"; }
