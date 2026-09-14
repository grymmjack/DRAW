#!/bin/bash
# =============================================================================
# linux-display-scale.sh — QA test: LINUX_HIDPI_SCALE display-scale detection.
#
# Guards the opt-in Linux/KDE fractional-scale correction (SCREEN_init +
# SCREEN_detect_linux_dpi_scale! in OUTPUT/SCREEN.BM). On X11 the server reports
# the full PHYSICAL pixel grid, so a 150%/200% desktop must fold its scale into
# SCREEN_DPI_DIVISOR! or DRAW sizes its UI off the raw resolution (the Kubuntu
# bug). On Wayland the compositor pre-scales, no scale env is present, and the
# detector must return 1.0 so nothing is double-scaled.
#
# Each case runs a SUBPROCESS with DRAW_HEADLESS=1: SCREEN_init runs the HIDPI
# block (which _LOGINFOs "detected display-scale=X -> divisor=Y") and then exits
# cleanly (code 3) at the no-display guard, BEFORE opening a window — so this
# never spawns a second GUI and needs no teardown. The scale is injected through
# the env-var detection paths (QT_SCALE_FACTOR / GDK_SCALE / QT_SCREEN_SCALE_
# FACTORS), which are what KDE/Qt-on-X11 export; the xrdb/Xft.dpi fallback is
# skipped under headless by design and is not exercised here.
#
# Isolated HOME per case so DRAW never reads or writes the user's real config,
# and file logging is enabled locally (the QA main instance has no log file).
# =============================================================================

info "=== Linux display-scale (LINUX_HIDPI_SCALE) detection test ==="

# run_scale_case "<label>" "<expected display-scale>" "<expected divisor>" ENV=VAL [ENV=VAL...]
# Returns the detection log line via the global REPLY.
run_scale_case() {
    local label="$1" want_scale="$2" want_div="$3"; shift 3
    local home log
    home="$(mktemp -d)"
    log="$home/DRAW.log"
    # DRAW_HEADLESS=1 → run SCREEN_init (logs detection) then clean-exit before GUI.
    ( cd "$DRAW_ROOT" && env HOME="$home" DRAW_HEADLESS=1 "$@" \
        QB64PE_LOG_HANDLERS=file QB64PE_LOG_SCOPES=qb64 QB64PE_LOG_LEVEL=1 \
        QB64PE_LOG_FILE_PATH="$log" \
        timeout 20 "$DRAW_BIN" --option LINUX_HIDPI_SCALE=TRUE >/dev/null 2>&1 )

    local line
    line="$(grep -i 'LINUX_HIDPI_SCALE on' "$log" 2>/dev/null | head -1)"
    rm -rf "$home"

    if [[ -z "$line" ]]; then
        fail "$label: no HIDPI detection line logged (block did not run?)"
        return
    fi
    # Line form: "...detected display-scale=1.5 -> divisor=1.5 raw=3840x2160"
    if grep -qE "detected display-scale=${want_scale//./\\.}( |[^0-9.])" <<<"$line" \
       && grep -qE "divisor=${want_div//./\\.}( |[^0-9.])" <<<"$line"; then
        pass "$label: display-scale=$want_scale -> divisor=$want_div"
    else
        fail "$label: expected scale=$want_scale divisor=$want_div, got: ${line##*657: }"
    fi
}

# Wayland / no-scale desktop: no scale env present -> detector must return 1.0
# (compositor already handed DRAW logical pixels; a divisor here would halve the UI).
run_scale_case "control (no scale env)"        1   1

# KDE/Qt-on-X11 150%: the classic Kubuntu case — physical pixels + QT_SCALE_FACTOR.
run_scale_case "QT_SCALE_FACTOR 150%"          1.5 1.5   QT_SCALE_FACTOR=1.5

# GTK/GDK integer scaling (200%).
run_scale_case "GDK_SCALE 200%"                2   2     GDK_SCALE=2

# Per-monitor Qt string "DP-1=1.5;HDMI-1=1;" — first factor wins.
run_scale_case "QT_SCREEN_SCALE_FACTORS 1.5"   1.5 1.5   "QT_SCREEN_SCALE_FACTORS=DP-1=1.5;HDMI-1=1;"

# A scale <= 1.0 must be ignored (no shrink, no upscale) — e.g. GDK_SCALE=1.
run_scale_case "GDK_SCALE 1 (ignored)"         1   1     GDK_SCALE=1

info "=== Linux display-scale detection test PASSED ==="
