#!/bin/bash
# =============================================================================
# cmd-palette-dump.sh — QA test: the command palette's CMDPAL dump line.
#
# Drivers (DEV/animscenes) type a query and must not press Enter on a half query:
# under load DRAW dropped typed keys, and a shorter query can run ANOTHER command
# ("clip layer: mode on" is Mode Ping-Pong). CMDPAL lets them check first:
#   CMDPAL searchLen results hover <the highlighted command's name>
#   - no CMDPAL line while the palette is closed
#   - open + a typed query: searchLen = the query's length, the highlighted name
#     is the first match, results counts the matches
#   - BackSpace shortens searchLen; Escape closes it and the line goes
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Command palette: the CMDPAL dump line ==="
dk_begin

cp_line() { grep -m1 '^CMDPAL ' "$DK_DUMP"; }

[[ -z "$(cp_line)" ]] && pass "closed: no CMDPAL line" || fail "closed: [$(cp_line)]"

park_mouse; key question; wait_for 1.0 "Command palette"; dk_settle
Q="layer same on every frame"
xdotool type --clearmodifiers --delay 80 -- "$Q"; wait_for 1.2 "typed"; dk_settle
read -r _ CP_LEN CP_N CP_HOV CP_NAME <<< "$(cp_line)"
[[ "$CP_LEN" == "${#Q}" ]] && pass "searchLen $CP_LEN = the query" || fail "searchLen '$CP_LEN', typed ${#Q} [$(cp_line)]"
[[ "$CP_HOV" == 0 && "$CP_NAME" == "Layer Same on Every Frame"* ]] && pass "highlighted: $CP_NAME" || fail "highlight [$(cp_line)]"
(( ${CP_N:-0} >= 1 )) && pass "results $CP_N" || fail "results [$(cp_line)]"

key BackSpace BackSpace BackSpace BackSpace BackSpace BackSpace; wait_for 0.6 "erased"; dk_settle
read -r _ CP_LEN2 _ <<< "$(cp_line)"
[[ "$CP_LEN2" == $(( ${#Q} - 6 )) ]] && pass "BackSpace: searchLen $CP_LEN2" || fail "after BackSpace [$(cp_line)]"

key Escape; wait_for 0.5 "clear"; dk_settle
if [[ -n "$(cp_line)" ]]; then key Escape; wait_for 0.5 "close"; dk_settle; fi
[[ -z "$(cp_line)" ]] && pass "Escape: the line is gone" || fail "after Escape [$(cp_line)]"
assert_no_crash
