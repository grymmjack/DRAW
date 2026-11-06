#!/bin/bash
# =============================================================================
# dock-hidden-panel-hover.sh — QA test: a panel that is not on screen (here an
# inactive tab behind the layers) answers no hover. The toolbox's / organizer's
# tooltips and the drawer's bins were hit-tested at where the panel was LAST
# drawn, so hovering the layers there popped the hidden panel's tooltips (and
# suppressed the layers' own).
# Reads the TIP line of the QA dump: TIP <active> <source> <idx>.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: hidden panels answer no hover Test ==="
dk_begin
tip_src() { awk '$1 == "TIP" {print $3}' "$DK_DUMP"; }
src_at() { hover "$1" "$2"; wait_for 1.3 "hover"; hover $(( $1 + 1 )) "$2"; sleep 0.4; dk_settle; TS=$(tip_src); }

# name, its TOOLTIP_SRC_* id(s), a hover point on it (set per panel below)
for name in toolbox organizer drawer; do
    case $name in
        toolbox)   want=1 ;;   # TOOLTIP_SRC_TOOLBAR
        organizer) want=2 ;;   # TOOLTIP_SRC_ORGANIZER
        drawer)    want=7 ;;   # TOOLTIP_SRC_BINS
    esac
    dk_move $name tab layers && dk_expect_tabs layers $name
    dk_park; dk_settle
    # the point to hover, while it is the active tab
    case $name in
        toolbox) read -r _ _ _ _ _ _ BX BY BW BH <<< "$(grep '^BTN toolbox 0 ' "$DK_DUMP")"; HX=$(( BX + BW / 2 )); HY=$(( BY + BH / 2 )) ;;
        organizer) dk_p organizer; HX=$(( P_X + 12 )); HY=$(( P_Y + 8 )) ;;
        drawer)    dk_p drawer;    HX=$(( P_X + 12 )); HY=$(( P_Y + 16 )) ;;
    esac
    src_at "$HX" "$HY"
    if [[ "$TS" == "$want" ]]; then
        pass "$name (active tab): hovering it at $HX,$HY gives its own tooltip (source $TS)"
    else
        fail "$name (active tab): expected tooltip source $want at $HX,$HY, got $TS - the hover point is off"
    fi
    # make the layers the active tab: the panel is hidden now
    dk_park; dk_settle
    dk_p layers
    click $(( P_TX + P_TW / 2 )) $(( P_HY + 5 )); wait_for 0.5 "layers tab"
    dk_park; dk_settle
    dk_p $name
    if (( P_LIVE != 0 )); then fail "$name is still live after switching to the layers tab"; fi
    src_at "$HX" "$HY"
    if [[ "$TS" != "$want" ]]; then
        pass "$name hidden behind the layers: no $name tooltip there (source $TS)"
    else
        fail "$name hidden behind the layers: its tooltip still fires at $HX,$HY"
    fi
    dk_park
    # out again, to the edge across
    if [[ "$(dk_side_of layers)" == 1 ]]; then dk_move $name edge-right; else dk_move $name edge-left; fi
    dk_expect_docked $name
    dk_park; dk_settle
done
assert_window_exists
info "=== Dock: hidden panels answer no hover Test PASSED ==="
