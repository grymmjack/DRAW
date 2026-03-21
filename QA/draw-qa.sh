#!/bin/bash
# draw-qa.sh — xdotool-based automated QA harness for DRAW
#
# Usage:
#   ./draw-qa.sh                  Run all tests in QA/tests/
#   ./draw-qa.sh tests/smoke.sh   Run a single test file
#   ./draw-qa.sh --list           List available tests
#   ./draw-qa.sh --keep-open      Don't close DRAW after tests (for debugging)
#
# Each test file in QA/tests/ is a plain bash script that calls the
# helper functions defined here (click, type_text, key, screenshot, etc.)

# NOTE: no set -e — (( N++ )) returns 1 when N=0 and would kill the script.

# When sourced as a library, stop here before touching any variables.
[[ "${1:-}" == "--lib" ]] && return 0 2>/dev/null

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DRAW_ROOT="$(dirname "$SCRIPT_DIR")"
DRAW_BIN="$DRAW_ROOT/DRAW.run"
DRAW_CFG="$DRAW_ROOT/DRAW.cfg"
RESULTS_DIR="$SCRIPT_DIR/results"
SCREENSHOTS_DIR="$SCRIPT_DIR/screenshots"
TESTS_DIR="$SCRIPT_DIR/tests"
WINDOW_TITLE="DRAW v"

DRAW_PID=""
DRAW_WID=""
PASS=0
FAIL=0
SKIP=0
KEEP_OPEN=0
LOG_FILE=""

# ── parse DRAW.cfg ────────────────────────────────────────────────────────────
_cfg() { grep -m1 "^${1}=" "$DRAW_CFG" 2>/dev/null | cut -d= -f2 | tr -d '[:space:]'; }

DISPLAY_SCALE=$(_cfg DISPLAY_SCALE)
DISPLAY_SCALE=${DISPLAY_SCALE:-1}
VIEWPORT_W=$(_cfg SCREEN_WIDTH);   VIEWPORT_W=${VIEWPORT_W:-904}
VIEWPORT_H=$(_cfg SCREEN_HEIGHT);  VIEWPORT_H=${VIEWPORT_H:-510}
LAYER_PANEL_W=$(_cfg LAYER_PANEL_WIDTH); LAYER_PANEL_W=${LAYER_PANEL_W:-100}
LAYERS_DOCK=$(_cfg LAYERS_PANEL_DOCK_EDGE); LAYERS_DOCK=${LAYERS_DOCK:-LEFT}
TOOLBOX_DOCK=$(_cfg TOOLBOX_DOCK_EDGE);    TOOLBOX_DOCK=${TOOLBOX_DOCK:-RIGHT}
TOOLBAR_SCALE=$(_cfg TOOLBAR_SCALE);       TOOLBAR_SCALE=${TOOLBAR_SCALE:-2}
CANVAS_W=$(_cfg DEFAULT_CANVAS_SIZE_W);    CANVAS_W=${CANVAS_W:-320}
CANVAS_H=$(_cfg DEFAULT_CANVAS_SIZE_H);    CANVAS_H=${CANVAS_H:-200}

# Derived chrome sizes (internal viewport pixels, matching DRAW's layout constants)
MENU_BAR_H=12
STATUS_H=11
PALETTE_H=30    # 3 rows × 9px + 3px padding
TOOLBAR_W=$(( 47 * TOOLBAR_SCALE + 2 ))   # TB_COLS*TB_BTN_W*TB + gaps + 2

# Canvas work area in viewport pixels
if [[ "$LAYERS_DOCK" == "LEFT" ]]; then
    WORK_LEFT=$LAYER_PANEL_W
    WORK_RIGHT=$(( VIEWPORT_W - TOOLBAR_W ))
else
    WORK_LEFT=$TOOLBAR_W
    WORK_RIGHT=$(( VIEWPORT_W - LAYER_PANEL_W ))
fi
WORK_TOP=$MENU_BAR_H
WORK_BOTTOM=$(( VIEWPORT_H - STATUS_H - PALETTE_H ))
WORK_W=$(( WORK_RIGHT - WORK_LEFT ))
WORK_H=$(( WORK_BOTTOM - WORK_TOP ))

# Canvas top-left within work area (centred)
CANVAS_OFFSET_X=$(( WORK_LEFT + (WORK_W - CANVAS_W) / 2 ))
CANVAS_OFFSET_Y=$(( WORK_TOP  + (WORK_H - CANVAS_H) / 2 ))

# Centre of the canvas in viewport pixels
CANVAS_CX=$(( CANVAS_OFFSET_X + CANVAS_W / 2 ))
CANVAS_CY=$(( CANVAS_OFFSET_Y + CANVAS_H / 2 ))

# ── colours ──────────────────────────────────────────────────────────────────
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
CYAN="\033[0;36m"
RESET="\033[0m"

# ── logging ───────────────────────────────────────────────────────────────────
log()  { echo -e "$*"; [[ -n "$LOG_FILE" ]] && echo -e "$*" >> "$LOG_FILE"; }
info() { log "${CYAN}  »${RESET} $*"; }
pass() { log "${GREEN}  ✓ PASS${RESET} — $*"; PASS=$(( PASS + 1 )); }
fail() { log "${RED}  ✗ FAIL${RESET} — $*"; FAIL=$(( FAIL + 1 )); }
warn() { log "${YELLOW}  ! WARN${RESET} — $*"; }
skip() { log "${YELLOW}  ~ SKIP${RESET} — $*"; SKIP=$(( SKIP + 1 )); }

# ── prerequisite check ────────────────────────────────────────────────────────
check_deps() {
    local missing=()
    for cmd in xdotool scrot; do
        command -v "$cmd" &>/dev/null || missing+=("$cmd")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "Missing dependencies: ${missing[*]}"
        echo "Install with: sudo apt install ${missing[*]}"
        exit 1
    fi
}

# ── DRAW lifecycle ────────────────────────────────────────────────────────────

# Launch DRAW and wait for its window to appear (up to $1 seconds, default 15)
draw_launch() {
    local timeout=${1:-15}
    if [ ! -x "$DRAW_BIN" ]; then
        echo "ERROR: $DRAW_BIN not found or not executable" >&2
        exit 1
    fi
    info "Launching DRAW..."
    "$DRAW_BIN" &
    DRAW_PID=$!

    info "Waiting for window (up to ${timeout}s) — PID=$DRAW_PID"
    local i=0
    while [[ $i -lt $(( timeout * 2 )) ]]; do
        DRAW_WID=$(xdotool search --name "$WINDOW_TITLE" 2>/dev/null | head -1)
        [[ -n "$DRAW_WID" ]] && break
        sleep 0.5
        i=$(( i + 1 ))
    done

    if [[ -z "$DRAW_WID" ]]; then
        echo "ERROR: DRAW window never appeared after ${timeout}s" >&2
        exit 1
    fi
    info "Window found: WID=$DRAW_WID"
    draw_focus
    sleep 0.3
    info "Positioning window (Shift+Home)..."
    xdotool key shift+Home
    sleep 0.4   # let KDE finish the window animation
    _update_win_pos
    info "Window position: ${WIN_ABS_X},${WIN_ABS_Y}"
    sleep 0.3
}

# Kill DRAW cleanly
draw_quit() {
    if [[ $KEEP_OPEN -eq 1 ]]; then
        info "Keeping DRAW open (--keep-open). Close it manually."
        return
    fi
    if [[ -n "$DRAW_PID" ]] && kill -0 "$DRAW_PID" 2>/dev/null; then
        info "Closing DRAW (PID $DRAW_PID)..."
        xdotool key --window "$DRAW_WID" ctrl+q 2>/dev/null || true
        sleep 0.5
        if kill -0 "$DRAW_PID" 2>/dev/null; then
            kill "$DRAW_PID" 2>/dev/null || true
        fi
        DRAW_PID=""
        DRAW_WID=""
    fi
}

# Focus the DRAW window
draw_focus() {
    [[ -z "$DRAW_WID" ]] && return
    xdotool windowactivate --sync "$DRAW_WID"
    sleep 0.1
}

# ── input helpers ─────────────────────────────────────────────────────────────

# Cache window position so we don't call xdotool on every click
WIN_ABS_X=""
WIN_ABS_Y=""

# Refresh cached window position (call after draw_launch and if window moves)
_update_win_pos() {
    eval "$(xdotool getwindowgeometry --shell "$DRAW_WID" 2>/dev/null)"
    WIN_ABS_X=${X:-0}
    WIN_ABS_Y=${Y:-0}
}

# Convert viewport-pixel coords to absolute screen coords.
# Test files use internal viewport pixels; multiply by DISPLAY_SCALE for real screen pixels.
_abs() {
    [[ -z "$WIN_ABS_X" ]] && _update_win_pos
    echo $(( WIN_ABS_X + $1 * DISPLAY_SCALE )) $(( WIN_ABS_Y + $2 * DISPLAY_SCALE ))
}

# click X Y [button=1]  — window-relative coords
# Uses real X11 pointer movement (not XSendEvent) so SDL2 sees the events.
click() {
    local x=$1 y=$2 btn=${3:-1}
    local ax ay
    read -r ax ay <<< "$(_abs "$x" "$y")"
    draw_focus
    xdotool mousemove "$ax" "$ay"
    sleep 0.05
    xdotool click "$btn"
    sleep 0.1
}

# right_click X Y
right_click() { click "$1" "$2" 3; }

# double_click X Y
double_click() {
    local ax ay
    read -r ax ay <<< "$(_abs "$1" "$2")"
    draw_focus
    xdotool mousemove "$ax" "$ay"
    sleep 0.05
    xdotool click --repeat 2 --delay 100 1
    sleep 0.1
}

# drag from_x from_y to_x to_y [button=1]
drag() {
    local x1=$1 y1=$2 x2=$3 y2=$4 btn=${5:-1}
    local ax1 ay1 ax2 ay2
    read -r ax1 ay1 <<< "$(_abs "$x1" "$y1")"
    read -r ax2 ay2 <<< "$(_abs "$x2" "$y2")"
    draw_focus
    xdotool mousemove "$ax1" "$ay1"
    sleep 0.1
    xdotool mousedown "$btn"
    sleep 0.1
    xdotool mousemove "$ax2" "$ay2"
    sleep 0.15
    xdotool mouseup "$btn"
    sleep 0.1
}

# scroll_up / scroll_down at window-relative coords
scroll_up() {
    local ax ay; read -r ax ay <<< "$(_abs "$1" "$2")"
    draw_focus; xdotool mousemove "$ax" "$ay"; sleep 0.05; xdotool click 4
}
scroll_down() {
    local ax ay; read -r ax ay <<< "$(_abs "$1" "$2")"
    draw_focus; xdotool mousemove "$ax" "$ay"; sleep 0.05; xdotool click 5
}

# type text (printable chars only)
type_text() {
    draw_focus
    xdotool type --clearmodifiers --window "$DRAW_WID" --delay 30 "$1"
    sleep 0.1
}

# key — send one or more key combos (space-separated)
# Examples: key Return   key ctrl+z   key Escape F1
#
# Does NOT use --window; sends via real X11 focus path so SDL2's
# SDL_GetKeyboardState (used by _KEYDOWN) sees the events correctly.
# draw_focus ensures DRAW is the active window before sending.
key() {
    draw_focus
    xdotool key "$@"
    sleep 0.1
}

# wait N seconds with a message
wait_for() {
    local secs=$1 msg=${2:-"settling..."}
    info "Waiting ${secs}s — $msg"
    sleep "$secs"
}

# ── screenshot / assertion helpers ───────────────────────────────────────────

# screenshot "label"
# Captures the compositor's view of the DRAW window.
# On Wayland: uses spectacle (KDE) which reads the compositor buffer.
# On X11: scrot root + ImageMagick crop (SDL2/OpenGL X11 buffer stays black).
screenshot() {
    local label=${1:-"shot"}
    local ts; ts=$(date '+%H%M%S%3N')
    local file="$SCREENSHOTS_DIR/${label}-${ts}.png"
    local tmp="/tmp/draw-qa-full-$$.png"

    # Refresh window position in case it moved
    _update_win_pos
    eval "$(xdotool getwindowgeometry --shell "$DRAW_WID" 2>/dev/null)"
    local win_w=${WIDTH:-0} win_h=${HEIGHT:-0}

    draw_focus
    sleep 0.15   # let compositor finish compositing the frame

    if [[ -n "${WAYLAND_DISPLAY:-}" ]] && command -v spectacle &>/dev/null; then
        # Wayland: spectacle reads the KWin compositor — correct for SDL2/OpenGL apps
        if spectacle -b -n -f -o "$tmp" 2>/dev/null && \
           convert "$tmp" -crop "${win_w}x${win_h}+${WIN_ABS_X}+${WIN_ABS_Y}" +repage "$file" 2>/dev/null; then
            rm -f "$tmp"
            info "Screenshot → $(basename "$file")"
        else
            rm -f "$tmp"
            warn "spectacle/convert failed for screenshot '$label'"
        fi
    else
        # X11: scrot root capture + crop
        if scrot "$tmp" 2>/dev/null && \
           convert "$tmp" -crop "${win_w}x${win_h}+${WIN_ABS_X}+${WIN_ABS_Y}" +repage "$file" 2>/dev/null; then
            rm -f "$tmp"
            info "Screenshot → $(basename "$file")"
        else
            rm -f "$tmp"
            warn "screenshot failed (scrot or ImageMagick missing?)"
        fi
    fi
    echo "$file"
}

# assert_window_title EXPECTED_SUBSTR
assert_window_title() {
    local expected=$1
    local actual
    actual=$(xdotool getwindowname "$DRAW_WID" 2>/dev/null || echo "")
    if [[ "$actual" == *"$expected"* ]]; then
        pass "window title contains '$expected'"
    else
        fail "window title: expected substring '$expected', got '$actual'"
    fi
}

# assert_window_exists — fail if DRAW is no longer running
assert_window_exists() {
    if xdotool getwindowname "$DRAW_WID" &>/dev/null; then
        pass "DRAW window exists"
    else
        fail "DRAW window has closed unexpectedly"
    fi
}

# assert_no_crash — check DRAW process is still alive
assert_no_crash() {
    if kill -0 "$DRAW_PID" 2>/dev/null; then
        pass "DRAW process alive (PID $DRAW_PID)"
    else
        fail "DRAW process has died (PID $DRAW_PID)"
    fi
}

# snap_region X Y W H label
# Capture a specific viewport-pixel region of the DRAW window.
# Prints the path to the saved PNG. Use with assert_regions_differ / assert_regions_same.
# Automatically restores DRAW focus after spectacle (which steals it on Wayland).
snap_region() {
    local vx=$1 vy=$2 vw=$3 vh=$4 label=${5:-"snap"}
    local out="$SCREENSHOTS_DIR/_snap_${label}_$$.png"
    local fulltmp="/tmp/draw-qa-snap-$$.png"
    _update_win_pos
    local ax=$(( WIN_ABS_X + vx * DISPLAY_SCALE ))
    local ay=$(( WIN_ABS_Y + vy * DISPLAY_SCALE ))
    local aw=$(( vw * DISPLAY_SCALE ))
    local ah=$(( vh * DISPLAY_SCALE ))
    if [[ -n "${WAYLAND_DISPLAY:-}" ]] && command -v spectacle &>/dev/null; then
        spectacle -b -n -f -o "$fulltmp" 2>/dev/null
        # Spectacle steals focus on Wayland — restore DRAW immediately
        xdotool windowactivate --sync "$DRAW_WID" 2>/dev/null; sleep 0.1
    else
        scrot "$fulltmp" 2>/dev/null
    fi
    convert "$fulltmp" -crop "${aw}x${ah}+${ax}+${ay}" +repage "$out" 2>/dev/null
    rm -f "$fulltmp"
    echo "$out"
}

# assert_regions_differ file1 file2 msg
# Fail if two region snapshots are pixel-identical (action had no visual effect).
assert_regions_differ() {
    local f1=$1 f2=$2 msg=${3:-"region changed"}
    local diff_count
    diff_count=$(compare -metric AE -fuzz 5% "$f1" "$f2" /dev/null 2>&1 || true)
    if [[ "${diff_count:-0}" -gt 0 ]] 2>/dev/null; then
        pass "$msg (${diff_count} pixels differ)"
    else
        fail "$msg — regions are identical (action had no effect?)"
    fi
    rm -f "$f1" "$f2"
}

# assert_regions_same file1 file2 msg
# Fail if two region snapshots differ (unexpected visual change).
assert_regions_same() {
    local f1=$1 f2=$2 msg=${3:-"region unchanged"}
    local diff_count
    diff_count=$(compare -metric AE -fuzz 5% "$f1" "$f2" /dev/null 2>&1 || true)
    if [[ "${diff_count:-0}" -eq 0 ]] 2>/dev/null; then
        pass "$msg (regions match)"
    else
        fail "$msg — regions differ by ${diff_count} pixels (unexpected change?)"
    fi
    rm -f "$f1" "$f2"
}

# ── test runner ───────────────────────────────────────────────────────────────

run_test_file() {
    local test_file=$1
    local name; name=$(basename "$test_file" .sh)
    log ""
    log "${CYAN}━━━ $name ━━━${RESET}"
    # Source directly in the current shell — DRAW_PID/WID/counters all shared.
    # shellcheck disable=SC1090
    source "$test_file"
    log "${GREEN}  ► $name: done${RESET}"
}

# ── entrypoint ────────────────────────────────────────────────────────────────

# Parse flags
for arg in "$@"; do
    [[ "$arg" == "--keep-open" ]] && KEEP_OPEN=1
done

mkdir -p "$RESULTS_DIR" "$SCREENSHOTS_DIR"
LOG_FILE="$RESULTS_DIR/run-$(date '+%Y%m%d-%H%M%S').log"

case "${1:-}" in
    --list)
        echo "Available tests:"
        for f in "$TESTS_DIR"/*.sh; do echo "  $(basename "$f" .sh)"; done
        exit 0 ;;
    --help|-h)
        sed -n '2,9p' "$0"; exit 0 ;;
esac

check_deps
trap 'draw_quit' EXIT INT TERM

log "═══════════════════════════════════════════════════"
log " DRAW QA — $(date '+%Y-%m-%d %H:%M:%S')"
log " DRAW: $DRAW_BIN"
log " Scale: ${DISPLAY_SCALE}x  Viewport: ${VIEWPORT_W}×${VIEWPORT_H}"
log " Canvas: ${CANVAS_W}×${CANVAS_H}  Centre: (${CANVAS_CX},${CANVAS_CY}) viewport px"
log "═══════════════════════════════════════════════════"

if [[ $# -ge 1 && -f "${1}" ]]; then
    draw_launch 15
    run_test_file "$1"
else
    draw_launch 15
    for f in "$TESTS_DIR"/*.sh; do
        [[ -f "$f" ]] || continue
        run_test_file "$f"
    done
fi

log ""
log "═══════════════════════════════════════════════════"
log " Results: ${GREEN}${PASS} passed${RESET}  ${RED}${FAIL} failed${RESET}  ${YELLOW}${SKIP} skipped${RESET}"
log " Log → $LOG_FILE"
log "═══════════════════════════════════════════════════"

[[ $FAIL -eq 0 ]]
