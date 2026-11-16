#!/bin/bash
# =============================================================================
# panel-scale-grip.sh — QA test: a docked panel at its own Scale still shows
# its hover handle (Rick, 2026-11-14: "when i scale the edit bar to something
# not auto - it does not show the little handle at the top - the menu still
# works with right click around that area though" ... "any panel you touched
# has this similar behavior including organizer").
#
# A panel at a set Scale is drawn into its own surface and put onto the
# window after the presented canvas - where DOCK_overlay_render drew the grip,
# so the surface covered it. For each dock panel: Scale 1x, then the handle
# region with the pointer away vs over the handle must differ; Auto again.
#
# Dump: P name ... hx hy hw hh (dock-lib.sh); PSURF id on k ...; DMENU / DMENUR.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE WORKFLOW_BAR=1
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Panels: the hover handle at a set Scale ==="

# NAME DPID VALUE: right-click NAME's handle, pick the menu row VALUE (20 Auto, 20+k = kx)
pick_scale() {
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

dk_begin
for spec in "editbar 5" "advbar 6" "toolbox 1" "organizer 2" "drawer 3" "layers 4" "workflow 8"; do
    read -r NM ID <<< "$spec"
    if ! dk_visible "$NM"; then info "$NM: not showing in this layout - skipped"; continue; fi
    pick_scale "$NM" "$ID" 21 || continue
    read -r _ _ S_ON S_K _ <<< "$(grep -m1 "^PSURF $ID " "$DK_DUMP")"
    [[ "$S_ON" == -1 && "$S_K" == 1 ]] || { fail "$NM: not on its own surface at 1x ($(grep "^PSURF $ID " "$DK_DUMP"))"; continue; }
    dk_p "$NM"; dk_grab_point "$NM"
    HX=$P_HX; HY=$P_HY; HW=$P_HW; HH=$P_HH
    (( HH < 3 )) && HH=3
    dk_park; wait_for 0.4 "pointer away"
    snap_region "$HX" "$HY" "$HW" "$HH" "$NM-grip-away"; AWAY=$SNAP_RESULT
    hover "$GX" "$GY"; wait_for 0.5 "over the handle"
    snap_region "$HX" "$HY" "$HW" "$HH" "$NM-grip-over"; OVER=$SNAP_RESULT
    assert_regions_differ "$AWAY" "$OVER" "$NM at 1x: the handle lights up under the pointer"
    [[ "$NM" == editbar ]] && screenshot "panel-scale-grip-editbar"
    dk_park
    pick_scale "$NM" "$ID" 20
done
dk_check "all back at Auto"
assert_no_crash
info "=== Panels: the hover handle at a set Scale: done ==="
