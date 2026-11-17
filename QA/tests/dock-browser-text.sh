#!/bin/bash
# =============================================================================
# dock-browser-text.sh — QA test: the Browser docked in a left column: its
# path field and search box take typing, and its column edge drags along the
# content (Rick 2026-11-16: "cant click to edit in browser path when docked
# left" / "can't click to search either" / "when browser is docked on
# left/right edge it doesn't resize once docked ... where the content is").
#   - click the path field: it has the typing focus (BROWSERF pathActive);
#     a letter typed goes to it, not to DRAW (the tool stays the same); Esc
#     leaves it
#   - click the search box: focused (searchFocus); typing "zz" filters to no
#     files (BROWSERS count 0) and shows in it; BackSpace twice + Esc: all back
#   - the column's inner edge, grabbed 1 px INSIDE the Browser halfway down
#     its content, drags the column wider
# Dump: WIN browser x y w h slot; BROWSERL ...; BROWSERF pathActive
# searchFocus focusPane titleBarH pathBarH toolBarH searchLen [text];
# BROWSERS visible selected lastClick rowH listTop scroll count ...; VIEW zoom ox oy tool.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt BROWSER_VISIBLE=1 TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: the Browser's path field, search box and edge in a left column ==="
dk_begin
dk_move browser edge-left
dk_p browser; dk_slot "$P_SLOT"; dk_col "$S_COL"
(( C_SIDE == 1 )) && pass "the Browser in a left column (${C_W}px)" || fail "the Browser is not in a left column [$(dk_tree)]"

bw_read() {
    read -r _ _ WX WY WW WH _ <<< "$(grep '^WIN browser ' "$DK_DUMP")"
    read -r _ NAVW LX LW PX PW PON DW _ <<< "$(grep '^BROWSERL' "$DK_DUMP")"
    read -r _ F_PATH F_SEARCH F_PANE F_TB F_PB F_TOOL F_SLEN F_STXT <<< "$(grep '^BROWSERF' "$DK_DUMP")"
    read -r _ _ _ _ _ _ _ B_COUNT _ <<< "$(grep '^BROWSERS' "$DK_DUMP")"
}
fx() { echo $(( WX + $1 * WW / DW )); }
fy() { echo $(( WY + $1 * WW / DW )); }
tool() { awk '$1=="VIEW" {print $5; exit}' "$DK_DUMP"; }
dk_park; dk_settle; bw_read
if [[ -z "$DW" || -z "$F_PB" ]]; then fail "no BROWSERL / BROWSERF line"; assert_no_crash; exit 0; fi
info "window $WX,$WY ${WW}x$WH; dialog $DW FD px; bars title $F_TB path $F_PB tool $F_TOOL; files $B_COUNT"

# --- the path field -------------------------------------------------------------
T0=$(tool)
click "$(fx $(( DW / 2 )))" "$(fy $(( F_TB + F_PB / 2 )))"; wait_for 0.5 "path field"; dk_settle; bw_read
[[ "$F_PATH" == 1 ]] && pass "click the path field: it takes the typing" || fail "the path field did not take the click (BROWSERF $F_PATH $F_SEARCH $F_PANE)"
key b; wait_for 0.4 "typed b"; dk_settle
[[ "$(tool)" == "$T0" ]] && pass "a letter typed into the path is not a DRAW shortcut (tool $T0)" || fail "typing 'b' in the path switched the tool ($T0 -> $(tool))"
key Escape; wait_for 0.4 "esc"; dk_settle; bw_read
[[ "$F_PATH" == 0 ]] && pass "Esc leaves the path field" || fail "the path field kept focus after Esc"
screenshot "browser-path"

# --- the search box ---------------------------------------------------------------
N0=$B_COUNT
SY=$(fy $(( F_TB + F_PB + F_TOOL / 2 )))
click "$(fx $(( DW - 4 - 75 )))" "$SY"; wait_for 0.5 "search box"; dk_settle; bw_read
[[ "$F_SEARCH" == 1 ]] && pass "click the search box: it takes the typing" || fail "the search box did not take the click (BROWSERF $F_PATH $F_SEARCH $F_PANE)"
type_text "zz"; wait_for 0.5 "typed zz"; dk_settle; bw_read
info "search '$F_STXT' ($F_SLEN): $B_COUNT entries (were $N0)"
[[ "$F_STXT" == zz ]] && pass "typing shows in the search box ('$F_STXT')" || fail "the search box holds '$F_STXT' (want zz)"
(( B_COUNT < N0 )) && pass "the search filters the list ($N0 -> $B_COUNT)" || fail "the list did not filter ($N0 -> $B_COUNT)"
[[ "$(tool)" == "$T0" ]] && pass "z typed into the search is not the zoom tool" || fail "typing z in the search switched the tool ($T0 -> $(tool))"
screenshot "browser-search"
key BackSpace; key BackSpace; wait_for 0.3 "backspace"; dk_settle; bw_read
[[ "$F_SLEN" == 0 && "$B_COUNT" == "$N0" ]] && pass "BackSpace twice: the search empty, all $N0 back" || fail "after BackSpace: '$F_STXT' ($F_SLEN), $B_COUNT entries"
key Escape; wait_for 0.3 "esc"; dk_settle; bw_read
[[ "$F_SEARCH" == 0 ]] && pass "Esc leaves the search box" || fail "the search box kept focus after Esc"

# --- the column edge, inside the Browser, halfway down its content -----------------
dk_p browser; dk_slot "$P_SLOT"; dk_col "$S_COL"; W0=$C_W
EX=$(( C_X + C_W - 1 )); EY=$(( C_Y + C_H / 2 ))
dk_drag "$EX" "$EY" $(( EX + 120 )) "$EY" 6; dk_park; dk_settle
dk_p browser; dk_slot "$P_SLOT"; dk_col "$S_COL"
(( C_W >= W0 + 60 )) && pass "the edge grabbed inside the Browser's content drags the column ($W0 -> $C_W)" || fail "the edge inside the content did not drag ($W0 -> $C_W)"
dk_check "the Browser column after the edge drag"
assert_window_exists
info "=== Dock: Browser path / search / edge done ==="
