#!/bin/bash
# =============================================================================
# kit-export-install.sh — QA test: DRAW KITS (export / install)
#
# Two layers of coverage:
#   Part A — FUNCTIONAL round-trip, headless & deterministic. Seeds an isolated
#            data dir with one palette, exports a real .zip kit from it, then
#            installs that kit into a SECOND, empty data dir (a "clean DRAW")
#            and asserts the palette actually landed there. Exercises
#            KIT_export_write% + KIT_install_apply% end-to-end with zero
#            dependency on the user's real data or the repo's ASSETS.
#   Part B — GUI wiring. Via the launched instance, the command palette opens
#            the Export Kit dialog (custom, snap-able) and the Install Kit flow
#            (native open dialog); both must appear without crashing.
#
# The functional round-trip uses the --kit-export / --kit-install dev flags and
# its own nested xvfb display, so it never touches the harness's DRAW window.
# =============================================================================

info "=== DRAW KITS Export/Install Test ==="

# ── Part A: functional export → install round-trip (headless, isolated) ───────
info "Part A: seed → export → install into a clean data dir"

if ! command -v xvfb-run >/dev/null 2>&1; then
    skip "kit round-trip — xvfb-run not available"
else
    KIT_TMP="$(mktemp -d)"
    KIT_ZIP="$KIT_TMP/qa-kit.zip"
    KIT_A="$KIT_TMP/dataA"          # export source: an isolated data dir we control
    KIT_B="$KIT_TMP/dataB"          # install target: a clean "DRAW without the stuff"
    mkdir -p "$KIT_A/DRAW/PALETTES" "$KIT_B"

    # Seed one deterministic palette (a minimal GIMP .GPL) into source data dir.
    cat > "$KIT_A/DRAW/PALETTES/QA-Kit-Test.gpl" <<'GPL'
GIMP Palette
Name: QA Kit Test
Columns: 2
#
  0   0   0	Black
255 255 255	White
255   0   0	Red
  0 128 255	Blue
GPL

    # Export a kit FROM the seeded data dir (XDG_DATA_HOME points DRAW at KIT_A).
    ( cd "$DRAW_ROOT" && XDG_DATA_HOME="$KIT_A" xvfb-run -a "$DRAW_BIN" \
        --kit-export "$KIT_ZIP" ) >/dev/null 2>&1

    if [[ -s "$KIT_ZIP" ]] && unzip -t "$KIT_ZIP" >/dev/null 2>&1; then
        pass "kit exported and is a valid zip ($(du -h "$KIT_ZIP" | cut -f1))"
    else
        fail "kit export did not produce a valid zip at $KIT_ZIP"
    fi

    # The seeded palette must be inside the kit.
    if unzip -l "$KIT_ZIP" 2>/dev/null | grep -q "QA-Kit-Test.gpl"; then
        pass "exported kit contains the seeded palette"
    else
        fail "exported kit is missing the seeded palette"
    fi

    # Install the kit into an EMPTY data dir (skip conflicts non-interactively).
    ( cd "$DRAW_ROOT" && XDG_DATA_HOME="$KIT_B" XDG_CONFIG_HOME="$KIT_TMP/cfgB" \
        XDG_CACHE_HOME="$KIT_TMP/cacheB" xvfb-run -a "$DRAW_BIN" \
        --kit-install "$KIT_ZIP" ) >/dev/null 2>&1

    INSTALLED="$KIT_B/DRAW/PALETTES/QA-Kit-Test.gpl"
    if [[ -f "$INSTALLED" ]]; then
        pass "palette installed into the clean data dir"
        if cmp -s "$KIT_A/DRAW/PALETTES/QA-Kit-Test.gpl" "$INSTALLED"; then
            pass "installed palette is byte-identical to the source"
        else
            fail "installed palette differs from the source (corruption in the round-trip)"
        fi
    else
        fail "kit install did not place the palette into the clean data dir"
    fi

    rm -rf "$KIT_TMP"
fi

# ── Part B: GUI wiring — the dialogs open from the command palette ────────────
info "Part B: Export Kit dialog opens via command palette"
canvas_focus b
wait_for 0.3 "ready"
park_mouse
snap_region "$WORK_LEFT" "$WORK_TOP" "$WORK_W" "$WORK_H" "kit-before"
BEFORE="$SNAP_RESULT"

# Command palette (?): type "export kit", Enter — Alt+letter menus are disabled.
key shift+slash
wait_for 0.5 "Command palette opened"
type_text "export kit"
wait_for 0.4 "Typed export kit"
key Return
wait_for 1.0 "Export Kit dialog should appear"
assert_no_crash

park_mouse
snap_region "$WORK_LEFT" "$WORK_TOP" "$WORK_W" "$WORK_H" "kit-export-dialog"
AFTER="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$AFTER" "Export Kit dialog should appear"
screenshot "kit-export-dialog"

# Close the export dialog (two escapes: dialog, then any lingering focus state).
key Escape
wait_for 0.6 "Export dialog cancelled"
key Escape
wait_for 0.4 "Ensure closed"
assert_no_crash

info "Part B: Install Kit flow opens (native open dialog)"
key shift+slash
wait_for 0.5 "Command palette opened"
type_text "install kit"
wait_for 0.4 "Typed install kit"
key Return
wait_for 1.5 "Install Kit (native open) dialog should appear"
assert_no_crash
key Escape
wait_for 1.5 "Install dialog cancelled (native dialog slow to close)"
assert_no_crash

# ── Survived both dialogs and still responsive ───────────────────────────────
key b
wait_for 0.3 "Switch to brush — dispatch still works post-dialog"
assert_no_crash
assert_window_exists
info "=== DRAW KITS Export/Install Test PASSED ==="
