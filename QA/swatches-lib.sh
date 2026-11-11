#!/bin/bash
# Helpers for the Swatches panel tests (GUI/SWATCHES.BM dump lines: SWAT,
# SWATS, SWATG, SWATC, SWATM*). Source after dock-lib.sh.
sw_read() { read -r _ SW_N SW_COLORS SW_COLS SW_CW SW_CH SW_GAP SW_ROWS SW_SCROLL SW_MAXS SW_FG SW_BG SW_MENU SW_MROWS SW_KEY <<< "$(grep '^SWAT ' "$DK_DUMP")"; }
sw_geo()  { read -r _ G_X G_Y G_W G_H B_X B_Y B_W B_H E_X E_Y E_W E_H <<< "$(grep '^SWATG ' "$DK_DUMP")"; }
sw_cell() { C_X=; read -r _ _ C_X C_Y C_W C_H C_KIND C_HEX <<< "$(grep "^SWATC $1 " "$DK_DUMP")"; }
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
# an empty place in the grid: column 6 of row 1 in swatches-edit.gpl (right of
# the row break) - entry 12's cell (row 1, column 3) + 3 cells
sw_empty_xy() { sw_pitch; sw_cell 12; EX=$(( C_X + C_W / 2 + 3 * SW_PITCH )); EY=$(( C_Y + C_H / 2 )); }
