#!/bin/bash
# draw-qa.sh — xdotool-based automated QA harness for DRAW
#
# Usage:
#   ./draw-qa.sh                  Run all tests in QA/tests/
#   ./draw-qa.sh tests/smoke.sh   Run a single test file
#   ./draw-qa.sh --list           List available tests
#   ./draw-qa.sh --keep-open      Don't close DRAW after tests (for debugging)
#   ./draw-qa.sh --fail-fast      Stop on first failure (for tuning tests)
#   ./draw-qa.sh --verbose        Show every mouse/key action for debugging
#   ./draw-qa.sh --rerun-passed   Re-run tests that previously passed
#   ./draw-qa.sh --reset          Clear the passed-test cache
#   ./draw-qa.sh --reset-cfg      Rebuild QA/DRAW.qa.cfg from DRAW.cfg.default
#   ./draw-qa.sh --developer      Launch DRAW with --developer (input audit)
#   ./draw-qa.sh --probe          Launch DRAW and print cursor position in
#                                 viewport pixels — hover a target, hold still
#                                 ~1.5s and it prints MARK <x>,<y> for use as a
#                                 click coordinate. PROBE_SECS=60 to run longer.
#
# DRAW is always launched with --config QA/DRAW.qa.cfg, so runs are
# deterministic and never read or write the user's own DRAW.cfg.
#
# Each test is ATOMIC: DRAW is launched fresh and closed after every test
# to prevent state from one test tainting the next.
#
# Each test file in QA/tests/ is a plain bash script that calls the
# helper functions defined here (click, type_text, key, screenshot, etc.)

# NOTE: no set -e — (( N++ )) returns 1 when N=0 and would kill the script.

# When sourced as a library, stop here before touching any variables.
[[ "${1:-}" == "--lib" ]] && return 0 2>/dev/null

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DRAW_ROOT="$(dirname "$SCRIPT_DIR")"
DRAW_BIN="$DRAW_ROOT/DRAW.run"

# ── QA config isolation ───────────────────────────────────────────────────────
# QA runs against its OWN config, passed to DRAW via --config, for two reasons:
#
#   1. Determinism. The shipped default is DISPLAY_SCALE=0 / SCREEN_WIDTH=0
#      ("auto-detect"), so the geometry maths below had nothing usable to work
#      with — every click landed at the window origin (x * 0) and every capture
#      cropped to 0x0, silently falling back to a full-desktop screenshot.
#   2. Isolation. DRAW's CONFIG_save writes back to whichever config it loaded,
#      so tests that touch settings were mutating the user's real DRAW.cfg.
#
# Regenerate the QA config from factory defaults with: ./draw-qa.sh --reset-cfg
QA_CFG="$SCRIPT_DIR/DRAW.qa.cfg"

# Deterministic geometry — every value the coordinate maths below depends on
# must be explicit here; a 0 means "auto-detect" to DRAW and breaks the model.
#
# UI_SCALE MUST stay 0. SCREEN_init only honors an explicit SCREEN_WIDTH/HEIGHT
# in pure Auto mode (`IF CFG.UI_SCALE% = 0 AND CFG.SCREEN_WIDTH% > 0` —
# OUTPUT/SCREEN.BM). With a UI_SCALE master set, DRAW deliberately discards the
# configured viewport and re-derives it from desktop/scale, so the window size
# becomes desktop-dependent and the coordinate model below stops matching.
_qa_cfg_overrides() {
    cat <<'OVERRIDES'
UI_SCALE=0
DISPLAY_SCALE=2
TOOLBAR_SCALE=2
SCREEN_WIDTH=958
SCREEN_HEIGHT=514
LAYER_PANEL_WIDTH=100
LAYERS_PANEL_DOCK_EDGE=LEFT
TOOLBOX_DOCK_EDGE=RIGHT
DEFAULT_CANVAS_SIZE_W=320
DEFAULT_CANVAS_SIZE_H=200
DEFAULT_PALETTE=ANSI32 (32)
PALETTE_CHIP_WIDTH=16
PALETTE_CHIP_HEIGHT=8
PALETTE_MAX_CHIPS_PER_ROW=32
PALETTE_MAX_ROWS=3
PALETTE_MIN_ROWS=1
SOUNDS_ENABLED=FALSE
MUSIC_ENABLED=FALSE
OVERRIDES
}

# Build QA/DRAW.qa.cfg from DRAW.cfg.default with the overrides above applied.
_ensure_qa_cfg() {
    [[ -f "$QA_CFG" ]] && return 0
    if [[ ! -f "$DRAW_ROOT/DRAW.cfg.default" ]]; then
        echo "ERROR: $DRAW_ROOT/DRAW.cfg.default not found — cannot build QA config" >&2
        exit 1
    fi
    cp "$DRAW_ROOT/DRAW.cfg.default" "$QA_CFG"
    local line key val
    while IFS= read -r line; do
        key=${line%%=*}
        val=${line#*=}
        if grep -q "^${key}=" "$QA_CFG"; then
            sed -i "s|^${key}=.*|${key}=${val}|" "$QA_CFG"
        else
            echo "$line" >> "$QA_CFG"
        fi
    done < <(_qa_cfg_overrides)
    echo "Created QA config: $QA_CFG"
}
_ensure_qa_cfg
DRAW_CFG="$QA_CFG"

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
FAIL_FAST=0
VERBOSE=0
RERUN_PASSED=0
LOG_FILE=""
PASSED_CACHE="$RESULTS_DIR/passed.txt"

# ── parse DRAW.cfg ────────────────────────────────────────────────────────────
_cfg() { [[ -n "$DRAW_CFG" ]] && grep -m1 "^${1}=" "$DRAW_CFG" 2>/dev/null | cut -d= -f2 | tr -d '[:space:]'; }

# NOTE: ${x:-1} is NOT enough here — it only substitutes when x is unset or
# empty, and DRAW writes a literal 0 to mean "auto-detect". A zero scale makes
# _abs() collapse every click onto the window origin and _capture_client_area
# crop to 0x0, which convert silently ignores (you get the whole desktop).
_num_or() {
    local v=$1 fallback=$2
    [[ "$v" =~ ^[0-9]+$ ]] && [[ "$v" -gt 0 ]] && { echo "$v"; return; }
    echo "$fallback"
}
DISPLAY_SCALE=$(_num_or "$(_cfg DISPLAY_SCALE)" 1)

# Window decoration height (KDE title bar).  Detected from _NET_FRAME_EXTENTS
# after window creation; override with DECORATION_H=22 ./draw-qa.sh
DECORATION_H=${DECORATION_H:-0}
_detect_decoration_height() {
    local extents
    extents=$(xprop _NET_FRAME_EXTENTS -id "$DRAW_WID" 2>/dev/null \
              | grep -oP '\d+' | tr '\n' ' ')
    [[ -z "$extents" ]] && { echo 0; return; }
    local left right top bottom
    read -r left right top bottom <<< "$extents"
    # KDE Breeze: side extents are shadow-only; top = shadow + title bar.
    # Visible title bar ≈ top - 3×side_shadow.
    local visible=$(( top - left * 3 ))
    [[ $visible -lt 0 ]] && visible=0
    echo "$visible"
}

VIEWPORT_W=$(_num_or "$(_cfg SCREEN_WIDTH)" 904)
VIEWPORT_H=$(_num_or "$(_cfg SCREEN_HEIGHT)" 510)
LAYER_PANEL_W=$(_num_or "$(_cfg LAYER_PANEL_WIDTH)" 100)
LAYERS_DOCK=$(_cfg LAYERS_PANEL_DOCK_EDGE); LAYERS_DOCK=${LAYERS_DOCK:-LEFT}
TOOLBOX_DOCK=$(_cfg TOOLBOX_DOCK_EDGE);    TOOLBOX_DOCK=${TOOLBOX_DOCK:-RIGHT}
TOOLBAR_SCALE=$(_num_or "$(_cfg TOOLBAR_SCALE)" 2)
CANVAS_W=$(_num_or "$(_cfg DEFAULT_CANVAS_SIZE_W)" 320)
CANVAS_H=$(_num_or "$(_cfg DEFAULT_CANVAS_SIZE_H)" 200)

# Derived chrome sizes (internal viewport pixels, matching DRAW's layout constants)
MENU_BAR_H=12
STATUS_H=11

# Bottom chrome band below the canvas. VERIFIED empirically against a capture
# on the pinned QA config (--probe + per-row colour sampling), do not "derive"
# these from PALETTE_STRIP_get_height% — that returns just the chip rows, while
# this band also covers the palette-name line, and shrinking it moves CANVAS_CY
# for every test in the suite.
#   474..485  palette chip row(s)
#   486..495  palette name / dropdown button (right-aligned)
#   498..514  status bar
PALETTE_H=30

# Palette-name dropdown button — the click target that opens the palette menu.
# Probed with `./draw-qa.sh --probe` on the pinned QA config; re-probe if the
# QA config's viewport or theme changes.
PAL_NAME_X_OFFSET=80   # from the right edge
PAL_NAME_Y=484
TOOLBAR_W=$(( 47 * TOOLBAR_SCALE + 2 ))   # TB_COLS*TB_BTN_W*TB + gaps + 2
TOOLBAR_H=$(( 83 * TOOLBAR_SCALE ))        # TB_ROWS*TB_BTN_H*TB + gaps
ORGANIZER_H=$(( 32 * TOOLBAR_SCALE ))      # 3 rows × 10 × TB + 2 gaps × TB

# Convenience aliases used by tests
VP_W=$VIEWPORT_W
VP_H=$VIEWPORT_H

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

# ── panel geometry (viewport pixels) for test snap regions ────────────────────

# Toolbar panel position & size
if [[ "$TOOLBOX_DOCK" == "RIGHT" ]]; then
    TB_X=$(( VIEWPORT_W - TOOLBAR_W ))
else
    TB_X=0
fi
TB_Y=$MENU_BAR_H
TB_W=$TOOLBAR_W
TB_H=$TOOLBAR_H

# Layer panel position & size
if [[ "$LAYERS_DOCK" == "LEFT" ]]; then
    LP_X=0
else
    LP_X=$(( VIEWPORT_W - LAYER_PANEL_W ))
fi
LP_Y=$MENU_BAR_H
LP_W=$LAYER_PANEL_W
LP_H=$(( VIEWPORT_H - MENU_BAR_H - STATUS_H - PALETTE_H ))

# Aliases used by new-layer.sh
LAYER_PANEL_X=$LP_X
LAYER_PANEL_Y=$LP_Y
LAYER_PANEL_H=$LP_H

# Palette strip position & size
PAL_X=0
PAL_Y=$(( VIEWPORT_H - STATUS_H - PALETTE_H ))
PAL_W=$VIEWPORT_W
PAL_H=$PALETTE_H

# Absolute click target for the palette-name dropdown button
PAL_NAME_X=$(( VIEWPORT_W - PAL_NAME_X_OFFSET ))

# ── colours ──────────────────────────────────────────────────────────────────
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
CYAN="\033[0;36m"
RESET="\033[0m"

# ── logging ───────────────────────────────────────────────────────────────────
log()  { echo -e "$*"; [[ -n "$LOG_FILE" ]] && echo -e "$*" >> "$LOG_FILE"; }
info() { log "${CYAN}  »${RESET} $*"; }
dbg()  { [[ $VERBOSE -eq 1 ]] && { echo -e "${YELLOW}  ◦${RESET} $*" >&2; [[ -n "$LOG_FILE" ]] && echo -e "${YELLOW}  ◦${RESET} $*" >> "$LOG_FILE"; }; }
pass() { log "${GREEN}  ✓ PASS${RESET} — $*"; PASS=$(( PASS + 1 )); }
fail() {
    log "${RED}  ✗ FAIL${RESET} — $*"; FAIL=$(( FAIL + 1 ))
    if [[ $FAIL_FAST -eq 1 ]]; then
        log "${RED}  ✗ --fail-fast: stopping on first failure${RESET}"
        draw_quit
        exit 1
    fi
}
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

# Capture the DRAW client area (excluding window decorations) and save to $1.
# Uses fullscreen capture + crop to avoid spectacle's active-window mode
# stealing keyboard focus from DRAW (which breaks subsequent key events).
# The crop uses WIN_ABS_X/Y (cached on launch) + DECORATION_Y to locate the
# client area within the fullscreen capture.
_capture_client_area() {
    local outfile=$1
    local tmp="/tmp/draw-qa-capture-$$-${RANDOM}.png"
    local client_w=$(( VIEWPORT_W * DISPLAY_SCALE ))
    local client_h=$(( VIEWPORT_H * DISPLAY_SCALE ))

    # Always refresh window position — KDE/Wayland may reposition the window
    # after launch (e.g. spectacle capture, window activation, tiling).
    _update_win_pos
    local crop_y=$(( WIN_ABS_Y + DECORATION_H ))

    dbg "capture: crop=${client_w}x${client_h}+${WIN_ABS_X}+${crop_y} deco=$DECORATION_H"

    if [[ -n "${WAYLAND_DISPLAY:-}" ]] && command -v spectacle &>/dev/null; then
        # setsid runs spectacle in its own session so the Wayland compositor
        # doesn't steal keyboard focus from DRAW.  No --fork: we block until
        # the capture completes to avoid races between overlapping captures.
        rm -f "$tmp"
        setsid spectacle -b -n -f -o "$tmp" 2>/dev/null
    else
        scrot "$tmp" 2>/dev/null
    fi

    if [[ -s "$tmp" ]]; then
        dbg "capture: fullscreen=$(identify -format '%wx%h' "$tmp" 2>/dev/null)"
        convert "$tmp" \
            -crop "${client_w}x${client_h}+${WIN_ABS_X}+${crop_y}" +repage \
            "$outfile" 2>/dev/null
        rm -f "$tmp"
    else
        rm -f "$tmp"
        return 1
    fi
    [[ -f "$outfile" ]]
}

# Launch DRAW and wait for its window to appear (up to $1 seconds, default 15)
draw_launch() {
    local timeout=${1:-15}
    if [ ! -x "$DRAW_BIN" ]; then
        echo "ERROR: $DRAW_BIN not found or not executable" >&2
        exit 1
    fi
    info "Launching DRAW (--config $(basename "$QA_CFG"))..."
    # Launch from DRAW_ROOT, not QA/. DRAW never CHDIRs, and several subsystems
    # resolve assets against the CURRENT directory ("./ASSETS/..."), so running
    # from QA/ silently breaks them — palette .GPL previews, for one.
    ( cd "$DRAW_ROOT" && exec "$DRAW_BIN" --config "$QA_CFG" $DRAW_EXTRA_ARGS ) &
    DRAW_PID=$!

    info "Waiting for window (up to ${timeout}s) — PID=$DRAW_PID"
    local i=0
    while [[ $i -lt $(( timeout * 2 )) ]]; do
        # Match by PID so other DRAW instances don't interfere
        DRAW_WID=$(xdotool search --pid "$DRAW_PID" --name "$WINDOW_TITLE" 2>/dev/null | head -1)
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
    info "Positioning window (Meta+Home)..."
    xdotool windowactivate --sync "$DRAW_WID" 2>/dev/null
    xdotool windowfocus --sync "$DRAW_WID" 2>/dev/null
    sleep 0.2
    xdotool key --delay 50 super+Home
    sleep 0.5   # let KDE finish the window animation
    _update_win_pos
    info "Window position: ${WIN_ABS_X},${WIN_ABS_Y}"
    if [[ "$DECORATION_H" -eq 0 ]]; then
        DECORATION_H=$(_detect_decoration_height)
    fi
    info "Decoration height: ${DECORATION_H}px"
    _verify_geometry_model
    sleep 0.3
}

# Cross-check the cfg-derived coordinate model against the real window.
# Everything downstream (clicks, crops, snap regions) assumes
# client size == VIEWPORT × DISPLAY_SCALE; if the window disagrees, every
# assertion silently degrades into "compare two full-desktop screenshots",
# which passes for the wrong reason. Fail loudly instead.
_verify_geometry_model() {
    eval "$(xdotool getwindowgeometry --shell "$DRAW_WID" 2>/dev/null)"
    local win_w=${WIDTH:-0} win_h=${HEIGHT:-0}
    local want_w=$(( VIEWPORT_W * DISPLAY_SCALE ))
    local want_h=$(( VIEWPORT_H * DISPLAY_SCALE ))
    dbg "geometry: window=${win_w}x${win_h} model=${want_w}x${want_h} (viewport ${VIEWPORT_W}x${VIEWPORT_H} @ ${DISPLAY_SCALE}x)"

    # Tolerate a few px of WM rounding, but not a wholesale mismatch
    local dw=$(( win_w - want_w )); [[ $dw -lt 0 ]] && dw=$(( -dw ))
    local dh=$(( win_h - want_h )); [[ $dh -lt 0 ]] && dh=$(( -dh ))
    if [[ $dw -le 4 && $dh -le 4 ]]; then
        info "Geometry model OK: ${win_w}x${win_h} (viewport ${VIEWPORT_W}x${VIEWPORT_H} @ ${DISPLAY_SCALE}x)"
        return 0
    fi

    echo "ERROR: window geometry does not match the QA coordinate model." >&2
    echo "       window   = ${win_w}x${win_h}" >&2
    echo "       expected = ${want_w}x${want_h} (${VIEWPORT_W}x${VIEWPORT_H} @ ${DISPLAY_SCALE}x)" >&2
    echo "       config   = $DRAW_CFG" >&2
    echo "       Clicks and screenshot crops would be wrong; refusing to run." >&2
    echo "       Fix the geometry keys in the QA config, or regenerate it:" >&2
    echo "         ./draw-qa.sh --reset-cfg" >&2
    draw_quit
    exit 1
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

# Focus the DRAW window — uses both windowactivate and windowfocus.
# With setsid --fork on spectacle, focus stealing is prevented, so this is
# lightweight (no real mouse click needed).
draw_focus() {
    [[ -z "$DRAW_WID" ]] && return
    dbg "draw_focus WID=$DRAW_WID"
    # Verify WID is still valid
    if ! xdotool getwindowname "$DRAW_WID" &>/dev/null; then
        local new_wid
        new_wid=$(xdotool search --pid "$DRAW_PID" --name "$WINDOW_TITLE" 2>/dev/null | head -1)
        if [[ -n "$new_wid" ]]; then
            DRAW_WID="$new_wid"
            dbg "draw_focus WID refreshed → $DRAW_WID"
        fi
    fi
    xdotool windowactivate --sync "$DRAW_WID" 2>/dev/null
    xdotool windowfocus --sync "$DRAW_WID" 2>/dev/null
    sleep 0.05
}

# ── input helpers ─────────────────────────────────────────────────────────────

# Focus the canvas without drawing on it.  Temporarily switches to Move tool
# (which doesn't paint on click), clicks the canvas centre, then restores the
# previously-active tool via the hotkey passed as $1 (default: none).
canvas_focus() {
    local restore_key=${1:-""}
    dbg "canvas_focus → move tool, click canvas ($CANVAS_CX,$CANVAS_CY), restore='$restore_key'"
    key v            # Move tool — non-destructive click
    sleep 0.05
    click "$CANVAS_CX" "$CANVAS_CY"
    sleep 0.1
    if [[ -n "$restore_key" ]]; then
        key "$restore_key"
        sleep 0.05
    fi
}

# Move the mouse cursor to the layers panel (inert area) so the DRAW
# crosshair overlay doesn't appear in canvas snap regions.
park_mouse() {
    local ax ay
    read -r ax ay <<< "$(_abs 50 60)"
    dbg "park_mouse → abs ($ax,$ay)"
    xdotool mousemove "$ax" "$ay"
    sleep 0.05
}

# Wake DRAW from idle mode (13fps) to active mode (59fps) by jiggling
# the mouse.  After snap_region's 1-second sleep, DRAW enters idle and
# re-enters idle between the Ctrl-keydown and the base-key tap of a
# modifier combo, causing some combos (Ctrl+Z, Ctrl+B, etc.) to be
# missed.  A mouse movement generates mouseMoved% = TRUE which sets
# FRAME_IDLE% = FALSE for the whole frame, keeping DRAW at 59fps long
# enough for the subsequent key combo to register reliably.
#
# IMPORTANT: Call wake_draw immediately before `key` — no wait_for between.
wake_draw() {
    draw_focus
    # Move to park position and jiggle ±1px to generate mouseMoved%
    local ax ay
    read -r ax ay <<< "$(_abs 50 60)"
    xdotool mousemove "$ax" "$ay"
    xdotool mousemove_relative -- 1 0
    sleep 0.03
    xdotool mousemove_relative -- -1 0
    sleep 0.03
    # Do NOT sleep long here — caller should invoke `key` immediately so
    # the key event arrives while DRAW is still in the active-fps window.
    dbg "wake_draw → mouse jiggled at park position"
}

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
# DECORATION_H skips the KDE title bar so (0,0) maps to client area origin.
_abs() {
    [[ -z "$WIN_ABS_X" ]] && _update_win_pos
    echo $(( WIN_ABS_X + $1 * DISPLAY_SCALE )) $(( WIN_ABS_Y + DECORATION_H + $2 * DISPLAY_SCALE ))
}

# click X Y [button=1]  — viewport-pixel coords
# Implemented as a 1px drag (mousedown → move 1px → mouseup) because SDL2
# reliably processes XTEST pointer events that include motion.
click() {
    local x=$1 y=$2 btn=${3:-1}
    local ax ay
    _update_win_pos
    read -r ax ay <<< "$(_abs "$x" "$y")"
    dbg "click vp=($x,$y) abs=($ax,$ay) btn=$btn win=($WIN_ABS_X,$WIN_ABS_Y) deco=$DECORATION_H"
    draw_focus
    xdotool mousemove "$ax" "$ay"
    sleep 0.08
    xdotool mousedown "$btn"
    sleep 0.05
    xdotool mousemove $(( ax + 1 )) "$ay"
    sleep 0.05
    xdotool mouseup "$btn"
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
    xdotool mousedown 1; sleep 0.05
    xdotool mousemove $(( ax + 1 )) "$ay"; sleep 0.05
    xdotool mouseup 1; sleep 0.1
    xdotool mousedown 1; sleep 0.05
    xdotool mousemove $(( ax + 2 )) "$ay"; sleep 0.05
    xdotool mouseup 1; sleep 0.1
}

# drag from_x from_y to_x to_y [button=1]
drag() {
    local x1=$1 y1=$2 x2=$3 y2=$4 btn=${5:-1}
    local ax1 ay1 ax2 ay2
    read -r ax1 ay1 <<< "$(_abs "$x1" "$y1")"
    read -r ax2 ay2 <<< "$(_abs "$x2" "$y2")"
    dbg "drag vp=($x1,$y1)→($x2,$y2) abs=($ax1,$ay1)→($ax2,$ay2) btn=$btn"
    draw_focus
    xdotool mousemove "$ax1" "$ay1"
    sleep 0.1
    xdotool mousedown "$btn" mousemove $(( ax1 + 1 )) "$ay1"
    sleep 0.05
    xdotool mousemove "$ax2" "$ay2"
    sleep 0.15
    xdotool mouseup "$btn"
    sleep 0.1
}

# scroll_up / scroll_down at viewport-pixel coords
scroll_up() {
    local ax ay; read -r ax ay <<< "$(_abs "$1" "$2")"
    draw_focus; xdotool mousemove "$ax" "$ay"; sleep 0.05
    xdotool click 4; sleep 0.05
}
scroll_down() {
    local ax ay; read -r ax ay <<< "$(_abs "$1" "$2")"
    draw_focus; xdotool mousemove "$ax" "$ay"; sleep 0.05
    xdotool click 5; sleep 0.05
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
# Does NOT use --window. xdotool without --window uses XTEST extension which
# generates real key events that SDL2's SDL_GetKeyboardState (and _KEYDOWN)
# can see. With --window it uses XSendEvent which doesn't update physical
# keyboard state — breaking all modifier combos (ctrl+shift+n etc.).
#
# For combos with modifiers (ctrl+, shift+, alt+, super+), we hold modifiers
# via keydown, sleep so DRAW's _KEYDOWN polling (60fps = 16.7ms) registers
# them, tap the base key, then release. Without this, xdotool's microsecond
# press/release cycle finishes before DRAW's next frame poll.
key() {
    draw_focus
    dbg "key $*"
    local combo
    for combo in "$@"; do
        if [[ "$combo" == *"+"* ]]; then
            # Split modifier combo: ctrl+shift+n → mods=(ctrl shift) base=n
            local IFS='+' parts=($combo)
            local base="${parts[-1]}"
            local mods=("${parts[@]:0:${#parts[@]}-1}")
            # Hold modifiers one at a time so DRAW's polling loop registers each
            local m
            for m in "${mods[@]}"; do
                xdotool keydown "$m"
                sleep 0.06   # hold each modifier ~3-4 frames at 59fps
            done
            sleep 0.06   # let DRAW poll the full modifier state
            # Press and release the base key while modifiers are held
            # Hold 200ms so that even at 13fps idle (~77ms/frame) the key spans 2+ frames
            xdotool keydown "$base"
            sleep 0.20   # hold base key 200ms — spans ~2.6 idle frames at 13fps
            xdotool keyup "$base"
            sleep 0.04
            # Release modifiers in reverse order
            local i
            for (( i=${#mods[@]}-1; i>=0; i-- )); do
                xdotool keyup "${mods[$i]}"
            done
        else
            # Use keydown/sleep/keyup instead of 'xdotool key' so that
            # _KEYDOWN-polling in DRAW sees the key held for at least 2 idle frames
            xdotool keydown "$combo"
            sleep 0.10
            xdotool keyup "$combo"
        fi
        sleep 0.05
    done
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
# Sets SNAP_RESULT to the saved PNG path.
screenshot() {
    local label=${1:-"shot"}
    local ts; ts=$(date '+%H%M%S%3N')
    SNAP_RESULT="$SCREENSHOTS_DIR/${label}-${ts}.png"

    draw_focus
    sleep 0.15   # let compositor finish compositing the frame

    if _capture_client_area "$SNAP_RESULT"; then
        info "Screenshot → $(basename "$SNAP_RESULT")"
    else
        warn "screenshot failed for '$label'"
        SNAP_RESULT=""
    fi
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
    # First try the cached WID
    if xdotool getwindowname "$DRAW_WID" &>/dev/null; then
        pass "DRAW window exists"
        return
    fi
    # WID may have gone stale (e.g. after spectacle); re-search by PID
    local new_wid
    new_wid=$(xdotool search --pid "$DRAW_PID" --name "$WINDOW_TITLE" 2>/dev/null | head -1)
    if [[ -n "$new_wid" ]]; then
        DRAW_WID="$new_wid"
        pass "DRAW window exists (WID refreshed to $DRAW_WID)"
    elif kill -0 "$DRAW_PID" 2>/dev/null; then
        pass "DRAW process alive (PID $DRAW_PID) — window temporarily unavailable"
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
# Two-step crop: fullscreen → client area → sub-region.
# Sets SNAP_RESULT to the saved PNG path. Use with assert_regions_differ / assert_regions_same.
snap_region() {
    local vx=$1 vy=$2 vw=$3 vh=$4 label=${5:-"snap"}
    SNAP_RESULT="$SCREENSHOTS_DIR/_snap_${label}_$$.png"
    local wintmp="/tmp/draw-qa-win-$$.png"

    # Sub-region offsets (viewport pixels → physical pixels within client area)
    local rx=$(( vx * DISPLAY_SCALE ))
    local ry=$(( vy * DISPLAY_SCALE ))
    local rw=$(( vw * DISPLAY_SCALE ))
    local rh=$(( vh * DISPLAY_SCALE ))

    dbg "snap_region vp=($vx,$vy ${vw}x${vh}) → px=($rx,$ry ${rw}x${rh}) label=$label"

    # Ensure DRAW is in the foreground and has rendered before capturing
    draw_focus
    sleep 1

    # Capture the client area (decorations stripped) and sub-crop the region
    if _capture_client_area "$wintmp"; then
        dbg "snap_region client_area=$(identify -format '%wx%h' "$wintmp" 2>/dev/null) sub-crop=${rw}x${rh}+${rx}+${ry}"
        convert "$wintmp" -crop "${rw}x${rh}+${rx}+${ry}" +repage "$SNAP_RESULT" 2>/dev/null
        rm -f "$wintmp"
    else
        dbg "snap_region _capture_client_area FAILED"
        SNAP_RESULT=""
    fi
}

# Raw AE units per differing pixel — calibrated at startup by _calibrate_ae.
AE_UNIT=1

# _ae_number "compare output" — first numeric token, scientific notation aware.
# ImageMagick prints large counts as "1.47491e+09"; the old ^[0-9]+ grep
# truncated that to "1", turning a whole-image difference into a 1-pixel result.
_ae_number() {
    awk '{
        for (i = 1; i <= NF; i++) {
            gsub(/[()]/, "", $i)
            if ($i ~ /^[0-9]+(\.[0-9]+)?([eE][+-]?[0-9]+)?$/) { printf "%.0f", $i + 0; exit }
        }
        print "0"
    }' <<< "$1"
}

# Measure what one differing pixel reports as. ImageMagick 7 HDRI builds scale
# the AE metric by QuantumRange (a 1-pixel difference reads as 65535), so the
# raw number is not a pixel count and every tolerance in every test would be
# meaningless. Calibrate instead of hardcoding — Q8/Q16/HDRI builds differ.
_calibrate_ae() {
    local t; t=$(mktemp -d)
    if magick -size 4x4 xc:black "$t/a.png" 2>/dev/null && \
       magick "$t/a.png" -fill white -draw 'point 1,1' "$t/b.png" 2>/dev/null; then
        local raw n
        raw=$(compare -metric AE "$t/a.png" "$t/b.png" /dev/null 2>&1 || true)
        n=$(_ae_number "$raw")
        [[ "$n" -ge 1 ]] 2>/dev/null && AE_UNIT=$n
    fi
    rm -rf "$t"
    dbg "AE calibration: 1 differing pixel reports as $AE_UNIT"
    [[ "$AE_UNIT" -ne 1 ]] && info "AE metric scaled by ${AE_UNIT}× on this ImageMagick build — normalising"
    return 0
}

# _parse_ae "compare output" — differing pixels as a plain integer.
_parse_ae() {
    local n; n=$(_ae_number "$1")
    echo $(( n / AE_UNIT ))
}

# assert_regions_differ file1 file2 msg
# Fail if two region snapshots are pixel-identical (action had no visual effect).
assert_regions_differ() {
    local f1=$1 f2=$2 msg=${3:-"region changed"}
    if [[ ! -f "$f1" ]] || [[ ! -f "$f2" ]]; then
        fail "$msg — snapshot file missing (f1=$(basename $f1) f2=$(basename $f2))"
        return
    fi
    local diff_output diff_count
    diff_output=$(compare -metric AE -fuzz 2% "$f1" "$f2" /dev/null 2>&1 || true)
    diff_count=$(_parse_ae "$diff_output")
    info "  [diff] raw='$diff_output' count='${diff_count:-?}' f1=$(basename $f1) f2=$(basename $f2)"
    if [[ "${diff_count:-0}" -gt 0 ]] 2>/dev/null; then
        pass "$msg (${diff_count} pixels differ)"
    else
        fail "$msg — regions are identical (action had no effect?)"
    fi
}

# assert_regions_same file1 file2 msg [tolerance]
# Fail if two region snapshots differ beyond tolerance (default 1500 pixels).
# Tolerance accounts for cursor/crosshair position changes between snaps.
assert_regions_same() {
    local f1=$1 f2=$2 msg=${3:-"region unchanged"} tolerance=${4:-1500}
    # Guard against missing files (e.g. prior assert cleaned them)
    if [[ ! -f "$f1" ]] || [[ ! -f "$f2" ]]; then
        fail "$msg — snapshot file missing (f1=$(basename $f1) f2=$(basename $f2))"
        return
    fi
    local diff_output diff_count
    diff_output=$(compare -metric AE -fuzz 2% "$f1" "$f2" /dev/null 2>&1 || true)
    diff_count=$(_parse_ae "$diff_output")
    info "  [diff] raw='$diff_output' count='${diff_count:-?}' tol=$tolerance f1=$(basename $f1) f2=$(basename $f2)"
    if [[ "${diff_count:-0}" -le "$tolerance" ]] 2>/dev/null; then
        pass "$msg (${diff_count:-0} pixels differ, within tolerance $tolerance)"
    else
        fail "$msg — regions differ by ${diff_count} pixels (unexpected change?)"
    fi
}

# ── test runner ───────────────────────────────────────────────────────────────

run_test_file() {
    local test_file=$1
    local name; name=$(basename "$test_file" .sh)
    log ""
    log "${CYAN}━━━ $name ━━━${RESET}"

    # Check passed-test cache (skip unless --rerun-passed)
    if [[ $RERUN_PASSED -eq 0 ]] && grep -qxF "$name" "$PASSED_CACHE" 2>/dev/null; then
        skip "$name — already passed (use --rerun-passed to re-run)"
        return
    fi

    # Check for SKIP marker: first non-shebang comment starting with "# SKIP:"
    local skip_reason
    skip_reason=$(sed -n '2,5{ s/^# SKIP: *//p; }' "$test_file" | head -1)
    if [[ -n "$skip_reason" ]]; then
        skip "$name — $skip_reason"
        log "  ${YELLOW}  Run manually: ./draw-qa.sh tests/$name.sh${RESET}"
        return
    fi

    # Track failures before this test
    local fail_before=$FAIL

    # Each test is atomic: fresh DRAW instance
    draw_launch 15
    # Source directly in the current shell — DRAW_PID/WID/counters all shared.
    # shellcheck disable=SC1090
    source "$test_file"
    log "${GREEN}  ► $name: done${RESET}"
    draw_quit

    # Record in passed cache if no new failures
    if [[ $FAIL -eq $fail_before ]]; then
        mkdir -p "$RESULTS_DIR"
        echo "$name" >> "$PASSED_CACHE"
    fi
}

# ── entrypoint ────────────────────────────────────────────────────────────────

# Parse flags
for arg in "$@"; do
    [[ "$arg" == "--keep-open" ]]    && KEEP_OPEN=1
    [[ "$arg" == "--fail-fast" ]]    && FAIL_FAST=1
    [[ "$arg" == "--verbose" ]]      && VERBOSE=1
    [[ "$arg" == "--rerun-passed" ]] && RERUN_PASSED=1
    # Pass DRAW's own developer mode through (input conflict audit → inputs.log)
    [[ "$arg" == "--developer" ]]    && DRAW_EXTRA_ARGS="--developer"
done

mkdir -p "$RESULTS_DIR" "$SCREENSHOTS_DIR"
# Clean slate: remove old screenshots and snap files
rm -f "$SCREENSHOTS_DIR"/*.png
LOG_FILE="$RESULTS_DIR/run-$(date '+%Y%m%d-%H%M%S').log"

case "${1:-}" in
    --list)
        echo "Available tests:"
        for f in "$TESTS_DIR"/*.sh; do echo "  $(basename "$f" .sh)"; done
        exit 0 ;;
    --reset)
        rm -f "$RESULTS_DIR/passed.txt"
        echo "Passed-test cache cleared."
        exit 0 ;;
    --reset-cfg)
        rm -f "$QA_CFG"
        _ensure_qa_cfg
        exit 0 ;;
    --probe)
        # Interactive coordinate finder. Launches DRAW with the QA config and
        # prints the cursor position in VIEWPORT pixels — the same units every
        # test helper takes — so target coordinates can be read off the real UI
        # instead of being derived from layout constants that drift.
        check_deps
        draw_launch 15
        PROBE_SECS=${PROBE_SECS:-30}
        log ""
        log "${CYAN}━━━ COORDINATE PROBE (${PROBE_SECS}s) ━━━${RESET}"
        log " Hover the UI element you want a test to click."
        log " Viewport coords are printed live; click to mark one."
        log " Window ${WIN_ABS_X},${WIN_ABS_Y}  scale ${DISPLAY_SCALE}x  deco ${DECORATION_H}px"
        log ""
        _probe_vp() {
            eval "$(xdotool getmouselocation --shell 2>/dev/null)"
            local vx=$(( (X - WIN_ABS_X) / DISPLAY_SCALE ))
            local vy=$(( (Y - WIN_ABS_Y - DECORATION_H) / DISPLAY_SCALE ))
            echo "$vx $vy"
        }
        # "Park protocol": hold the cursor still on a target for ~1.5s and the
        # probe marks it. Avoids needing global click capture, and a parked
        # cursor is exactly what a test's click coordinate should be.
        _probe_end=$(( SECONDS + PROBE_SECS ))
        _probe_last=""
        _probe_still=0
        _probe_marked=""
        while [[ $SECONDS -lt $_probe_end ]]; do
            read -r pvx pvy <<< "$(_probe_vp)"
            if [[ "$pvx $pvy" == "$_probe_last" ]]; then
                _probe_still=$(( _probe_still + 1 ))
                if [[ $_probe_still -eq 15 && "$pvx $pvy" != "$_probe_marked" ]]; then
                    printf "\r%-60s\r" ""
                    log "  ${GREEN}MARK${RESET}  viewport ${pvx},${pvy}"
                    _probe_marked="$pvx $pvy"
                fi
            else
                _probe_still=0
                printf "\r  viewport: %4s,%-4s   (hold still ~1.5s to mark)" "$pvx" "$pvy"
            fi
            _probe_last="$pvx $pvy"
            sleep 0.1
        done
        printf "\r%-60s\r" ""
        log "Probe finished."
        draw_quit
        exit 0 ;;
    --help|-h)
        sed -n '2,14p' "$0"; exit 0 ;;
esac

check_deps
_calibrate_ae
trap 'draw_quit' EXIT INT TERM

# Count cached passes for banner
_CACHED_COUNT=0
[[ -f "$PASSED_CACHE" ]] && _CACHED_COUNT=$(wc -l < "$PASSED_CACHE")

log "═══════════════════════════════════════════════════"
log " DRAW QA — $(date '+%Y-%m-%d %H:%M:%S')"
log " DRAW: $DRAW_BIN"
log " Config: $DRAW_CFG${DRAW_EXTRA_ARGS:+  Args: $DRAW_EXTRA_ARGS}"
log " Scale: ${DISPLAY_SCALE}x  Viewport: ${VIEWPORT_W}×${VIEWPORT_H}"
log " Canvas: ${CANVAS_W}×${CANVAS_H}  Centre: (${CANVAS_CX},${CANVAS_CY}) viewport px"
if [[ $_CACHED_COUNT -gt 0 ]]; then
    if [[ $RERUN_PASSED -eq 1 ]]; then
        log " Cache: ${_CACHED_COUNT} passed (re-running all)"
    else
        log " Cache: ${_CACHED_COUNT} already passed (--rerun-passed to redo)"
    fi
fi
log "═══════════════════════════════════════════════════"

# Collect test files (skip flags)
TEST_FILES=()
for arg in "$@"; do
    [[ "$arg" == --* ]] && continue
    [[ -f "$arg" ]] && TEST_FILES+=("$arg")
done

if [[ ${#TEST_FILES[@]} -eq 0 ]]; then
    for f in "$TESTS_DIR"/*.sh; do
        [[ -f "$f" ]] && TEST_FILES+=("$f")
    done
fi

LAST_TEST_FILE=""
for f in "${TEST_FILES[@]}"; do
    LAST_TEST_FILE="$f"
done

ORIG_KEEP_OPEN=$KEEP_OPEN
for f in "${TEST_FILES[@]}"; do
    # Only honour --keep-open on the last test
    if [[ "$f" == "$LAST_TEST_FILE" ]]; then
        KEEP_OPEN=$ORIG_KEEP_OPEN
    else
        KEEP_OPEN=0
    fi
    run_test_file "$f"
    sleep 0.5   # settle between tests
done
KEEP_OPEN=$ORIG_KEEP_OPEN

log ""
log "═══════════════════════════════════════════════════"
log " Results: ${GREEN}${PASS} passed${RESET}  ${RED}${FAIL} failed${RESET}  ${YELLOW}${SKIP} skipped${RESET}"
log " Log → $LOG_FILE"
log "═══════════════════════════════════════════════════"

[[ $FAIL -eq 0 ]]
