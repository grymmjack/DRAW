#!/bin/bash
# =============================================================================
# menus-bugs-1115.sh — QA test: the menu items from PLANS/BUGS.md (2026-11-15)
#
#  - Help ends on a real item: the menu table no longer overflows its old
#    600-item cap (SHOW TOOLTIPS 1608 and the crash-log items 1610 / 1611 were
#    dropped, leaving a divider under EXAMPLES, and AUDIO lost every item)
#  - no menu ends on a divider
#  - Tools has no Code... (1704); View has no Layout (442)
#  - the color strip's size menu carries the color cycling actions, flattened:
#    16 root rows; hovering a cycling row opens no submenu; clicking one runs it
#    (the menu closes)
#
# Dump: MROOT <label> <x> <w> | MENUI <action ids, 0 = divider> | PSM ... | PSMN <rows> <hover>
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Menus: BUGS.md 2026-11-15 ==="
dk_begin

menu_items() { # ROOT_LABEL -> the open menu's MENUI ids
    local ax aw
    read -r _ _ ax aw <<< "$(grep -m1 "^MROOT $1 " "$DK_DUMP")"
    [[ -z "$ax" ]] && { echo "NOROOT"; return; }
    click $(( ax + aw / 2 )) 6 >&2; wait_for 0.6 "$1 menu open" >&2; dk_settle >&2
    grep -m1 '^MENUI' "$DK_DUMP" | cut -d' ' -f2-
    key Escape >&2; wait_for 0.4 "closed" >&2
}
has() { [[ " $1 " == *" $2 "* ]]; }

for root in file edit view select tools brush layer palette image effects anim help audio; do
    ids=$(menu_items "$root")
    [[ "$ids" == "NOROOT" ]] && { fail "$root: no such root menu"; continue; }
    [[ -n "$ids" ]] || { fail "$root: the menu has no rows"; continue; }
    last=${ids##* }
    [[ "$last" != 0 ]] && pass "$root: ends on an item ($last)" || fail "$root: ends on a divider: $ids"
    [[ "${ids%% *}" != 0 ]] || fail "$root: starts with a divider"
    case $root in
        help)
            has "$ids" 1607 && has "$ids" 1608 && has "$ids" 1610 && has "$ids" 1611 \
                && pass "help: EXAMPLES, SHOW TOOLTIPS and both crash-log items are there" \
                || fail "help: items missing: $ids" ;;
        tools) has "$ids" 1704 && fail "tools: Code... (1704) is still there" || pass "tools: no Code..." ;;
        view)  has "$ids" 442 && fail "view: Layout (442) is still there" || pass "view: no Layout flyout" ;;
        audio) has "$ids" 417 && pass "audio: its items registered (SOUND FX 417)" || fail "audio: $ids" ;;
    esac
done

# -- the color strip's size menu: + the color cycling actions --
psm() { PM_RX=""; read -r _ PM_RX PM_RY PM_RW PM_SUB PM_SX PM_SY PM_SW PM_SN <<< "$(grep -m1 '^PSM ' "$DK_DUMP")"; }
psmn() { read -r _ PN_N PN_HV <<< "$(grep -m1 '^PSMN ' "$DK_DUMP")"; }
read -r _ ST_Y _ <<< "$(grep -m1 '^PSTRIP ' "$DK_DUMP")"
right_click 1 $(( ST_Y + 2 )); wait_for 0.6 "the size menu"; dk_settle; psm; psmn
[[ -n "$PM_RX" ]] || fail "no size menu after a right-click left of the chips"
(( PN_N == 16 )) && pass "size menu: 16 rows (4 sizes, divider, COLOR CYCLING:, divider, 9 actions)" || fail "size menu rows: '$PN_N'"
screenshot "palette-strip-menu-cycling"
# row 7 (RANGE FROM MARKED CHIPS): 4 rows of 12 + divider 5 + heading 12 + divider 5
CY=$(( PM_RY + 2 + 4 * 12 + 5 + 12 + 5 + 6 ))
hover $(( PM_RX + PM_RW / 2 )) $(( PM_RY + 2 + 6 )); wait_for 0.4 "row 0"; dk_settle; psm
(( PM_SUB == 0 )) && pass "hovering MAX ROWS opens its submenu" || fail "row 0 submenu '$PM_SUB'"
hover $(( PM_RX + PM_RW / 2 )) $(( CY + 3 * 12 )); wait_for 0.4 "a cycling row"; dk_settle; psm; psmn
(( PM_SUB == -1 && PN_HV == 10 )) && pass "hovering CHANGE DIRECTION: highlighted, no submenu" || fail "cycling row: sub '$PM_SUB' hover '$PN_HV'"
hover $(( PM_RX + PM_RW / 2 )) $(( PM_RY + 2 + 4 * 12 + 5 + 6 )); wait_for 0.3 "the heading"; dk_settle; psmn
(( PN_HV == -1 )) && pass "the COLOR CYCLING: heading is not a hover row" || fail "heading hover '$PN_HV'"
click $(( PM_RX + PM_RW / 2 )) $(( CY + 8 * 12 )); wait_for 0.6 "CHECK DUPLICATE COLORS"; dk_settle; psm
[[ -z "$PM_RX" ]] && pass "clicking a cycling row runs it and closes the menu" || fail "the menu stayed open"
assert_no_crash
