#!/usr/bin/env bash
# gui-scale-probe.sh — visual probe for the GUI-scale work.
#
# Not a pass/fail test: it drives DRAW into the states that are hard to assert
# on (popup compositing, chrome at 2x, the Settings control) and leaves PNGs to
# look at. The popup case specifically needs the mouse to MOVE while the menu is
# open — that is what makes a dirty-rect compositing bug visible, and a single
# static capture would miss it entirely.
#
# Usage: QA/gui-scale-probe.sh [outdir]
set -uo pipefail

DRAW=~/git/DRAW/DRAW.run
OUT="${1:-/tmp/gui-scale-probe}"
mkdir -p "$OUT"
export DISPLAY=:1 XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-0

shot() { # shot <name> — full screen, cropped to the DRAW window
    local name="$1" tmp="$OUT/.raw.png"
    setsid spectacle -b -n -f -o "$tmp" >/dev/null 2>&1
    sleep 0.4
    [[ -s "$tmp" ]] || { echo "  !! capture failed for $name"; return 1; }
    magick "$tmp" -crop "${W}x${H}+${X}+${Y}" "$OUT/$name.png" 2>/dev/null
    echo "  → $OUT/$name.png"
}

launch() { # launch <cfg>
    "$DRAW" --config "$1" >/dev/null 2>&1 &
    DRAW_PID=$!
    sleep 8
    WID=$(wmctrl -l | grep -i 'DRAW v' | awk '{print $1}' | tail -1)
    WD=$(printf '%d' "$WID")
    eval "$(xdotool getwindowgeometry --shell "$WD")"
    W=$WIDTH; H=$HEIGHT
    xdotool windowactivate "$WD"; sleep 1
    echo "  DRAW pid=$DRAW_PID window=${W}x${H}+${X}+${Y}"
}

kill_draw() { kill -- -"$(ps -o pgid= "$DRAW_PID" | tr -d ' ')" 2>/dev/null; pkill -f 'DRAW.run' 2>/dev/null; sleep 2; }

palette() { # palette <query> — run a command via the command palette
    xdotool key question; sleep 1.2
    xdotool type --delay 60 "$1"; sleep 1.2
    xdotool key Return; sleep 2.5
}

# ---------------------------------------------------------------- cfg variants
BASE=~/git/DRAW/QA/DRAW.qa.cfg
for g in 1 2; do
    sed "/^GUI_SCALE=/d" "$BASE" > "$OUT/gui$g.cfg"
    echo "GUI_SCALE=$g" >> "$OUT/gui$g.cfg"
done

# ============================================================ 1. POPUP @ 1x
echo "[1] popup compositing at GUI_SCALE=1 (the reported artifact)"
launch "$OUT/gui1.cfg"
palette "New Layer"                     # need 2 layers for a meaningful panel
shot "01-two-layers"

# Right-click a layer row to open the context menu. Layer panel is docked left
# in the QA config; row 0 sits just under the 16px header.
xdotool mousemove $((X+70)) $((Y+45)); sleep 0.5
xdotool click 3; sleep 1.5
shot "02-ctxmenu-open"

# THE CRITICAL PART: move the mouse while the menu is open. A dirty-rect
# compositing bug only tears on the frames a redraw is triggered.
for dx in 90 130 90 60; do
    xdotool mousemove $((X+dx)) $((Y+120)); sleep 0.35
done
shot "03-ctxmenu-after-mousemove"
xdotool mousemove $((X+110)) $((Y+200)); sleep 0.5
shot "04-ctxmenu-moved-down"
xdotool key Escape; sleep 0.8
shot "05-ctxmenu-closed"
kill_draw

# ============================================================ 2. CHROME @ 2x
echo "[2] chrome at GUI_SCALE=2 (canvas must NOT change)"
launch "$OUT/gui2.cfg"
shot "06-chrome-2x"
xdotool mousemove $((X+140)) $((Y+90)); sleep 0.5
xdotool click 3; sleep 1.5
shot "07-ctxmenu-2x"
for dx in 200 260 200; do
    xdotool mousemove $((X+dx)) $((Y+240)); sleep 0.35
done
shot "08-ctxmenu-2x-after-mousemove"
xdotool key Escape; sleep 0.8
kill_draw

# ============================================================ 3. SETTINGS
echo "[3] Settings shows UI Scale and GUI Scale as separate controls"
launch "$OUT/gui1.cfg"
palette "Settings"
shot "09-settings"
kill_draw

echo "done — $OUT"
ls -1 "$OUT"/*.png 2>/dev/null | wc -l | xargs echo "captures:"
