#!/usr/bin/env bash
# Pixel regression shots for the docking refactor (PLANS/_/DOCKING-PLAN.md).
#
#   DEV/tools/dock-baseline.sh shoot DIR          # shoot every layout into DIR/*.png
#   DEV/tools/dock-baseline.sh compare BASE NEW   # AE per shot; exit 1 if any differ
#   DEV/tools/dock-baseline.sh shoot DIR NAME...  # only these shots
#
# Each shot is one fresh DRAW launch through the QA harness (Xvfb, QA/DRAW.qa.cfg)
# with --option overrides, the mouse parked on the canvas. Workspaces come from
# QA/fixtures/workspaces/ through a scratch XDG_DATA_HOME, so the user's own
# workspaces folder is never read or written.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 1
ROOT=$(pwd)
DOCKS="TOOLBOX_DOCK_EDGE=LEFT LAYERS_PANEL_DOCK_EDGE=RIGHT"

# name | QA-OPTIONS | extra test lines (before the shot)
SHOTS=(
  "default-left|WORKSPACE=default $DOCKS|"
  "default-qa|WORKSPACE=default|"
  "onecol|WORKSPACE=onecol $DOCKS|"
  "annotate|WORKSPACE=annotate $DOCKS|"
  "narrow|WORKSPACE=narrow $DOCKS|canvas_focus; key F1; wait_for 0.4 mode"
  "bars|WORKSPACE=default $DOCKS EDIT_BAR_COLUMNS=2 ADV_BAR_COLUMNS=3 LAYER_PANEL_WIDTH=220|"
  "layers70|WORKSPACE=default $DOCKS LAYER_PANEL_WIDTH=70|"
  "cols6|WORKSPACE=default $DOCKS TOOLBOX_COLUMNS=6|"
  "charmap|WORKSPACE=default CHARMAP_VISIBLE=1|"
  "nostatus|WORKSPACE=default $DOCKS|key F10; wait_for 0.5 status"
  "stacked|WORKSPACE=stacked|"
  "tabs|WORKSPACE=tabs|"
)

shoot() {
    local out=$1; shift
    local want=" $* " tmp data name opts extra t
    mkdir -p "$out"
    tmp=$(mktemp -d); data="$tmp/data"; mkdir -p "$data/DRAW/WORKSPACES"
    cp QA/fixtures/workspaces/*.workspace "$data/DRAW/WORKSPACES/"
    for s in "${SHOTS[@]}"; do
        IFS='|' read -r name opts extra <<< "$s"
        [[ "$want" != "  " && "$want" != *" $name "* ]] && continue
        t="$tmp/$name.sh"
        cat > "$t" <<T
#!/bin/bash
# QA-OPTIONS: $opts
wait_for 1.0 "settle"
key Escape
$extra
hover \$(( VIEWPORT_W / 2 )) \$(( VIEWPORT_H / 2 ))
wait_for 1.2 "tooltips gone"
screenshot "$name"
T
        rm -rf "$tmp/res-$name"
        (cd QA && XDG_DATA_HOME="$data" QA_RESULTS_DIR="$tmp/res-$name" timeout 150 ./draw-qa.sh --rerun-passed "$t" >/dev/null 2>&1)
        if cp "$tmp/res-$name"/screenshots/"$name"-*.png "$out/$name.png" 2>/dev/null; then
            echo "shot $name"
        else
            echo "FAILED $name (no screenshot)"
        fi
    done
    rm -rf "$tmp"
}

compare() {
    local base=$1 new=$2 bad=0 f n ae
    for f in "$base"/*.png; do
        n=$(basename "$f")
        if [[ ! -f "$new/$n" ]]; then echo "MISSING $n"; bad=1; continue; fi
        ae=$(magick compare -metric AE "$f" "$new/$n" null: 2>&1 | awk '{print $1}')
        if [[ "$ae" == "0" ]]; then echo "same    $n"; else echo "DIFFER  $n  ($ae px)"; bad=1; fi
    done
    return $bad
}

case "${1:-}" in
    shoot)   shift; shoot "$@" ;;
    compare) compare "$2" "$3" ;;
    *) sed -n '2,12p' "$0"; exit 2 ;;
esac
