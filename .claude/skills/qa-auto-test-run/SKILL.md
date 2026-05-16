---
name: qa-auto-test-run
description: "Execute automated QA tests for DRAW via the xdotool-based test harness. Runs test scripts, reports pass/fail results, analyzes screenshots on failure, and suggests fixes."
---

# QA Auto Test — Run Automated Tests

When the user invokes this skill (e.g. "run automated tests", "qa-auto-test-run", "run QA harness"), execute automated test scripts via the `./QA/draw-qa.sh` harness. Follow these steps **in order**. Do not skip steps.

---

## Step 0 — Select tests to run

Ask the user what to run. Present three options:

> **What would you like to run?**
>
> 1. **All tests** — `./QA/draw-qa.sh`
> 2. **Single test** — `./QA/draw-qa.sh tests/{name}.sh`
> 3. **Keep DRAW open after** — append `--keep-open` for visual inspection

List available test files by scanning `QA/tests/*.sh`. For each file, parse the comment header (lines starting with `#` at the top) to extract its description:

```bash
for f in QA/tests/*.sh; do
    name=$(basename "$f" .sh)
    desc=$(sed -n '2s/^# *//p' "$f")
    echo "  $name — $desc"
done
```

Example output:

> **Available tests:**
> - `smoke` — Basic launch & sanity checks
> - `brush-draw` — Draw a stroke with the brush tool and verify no crash
> - `keyboard-shortcuts` — Verify common keyboard shortcuts don't crash
> - `new-layer` — Test adding and undoing a new layer

If the user says "all" or doesn't specify, run all tests. If they name a specific test, run only that file.

You can also list tests non-interactively with:

```bash
cd /home/grymmjack/git/DRAW/QA && ./draw-qa.sh --list
```

---

## Step 1 — Pre-flight checks

Before running, verify all prerequisites. Run these checks and report any failures:

```bash
# 1. DRAW binary exists and is executable
test -x /home/grymmjack/git/DRAW/DRAW.run && echo "✓ DRAW.run" || echo "✗ DRAW.run missing or not executable"

# 2. xdotool installed (required for all input simulation)
command -v xdotool &>/dev/null && echo "✓ xdotool" || echo "✗ xdotool not found — install with: sudo apt install xdotool"

# 3. Screenshot tool available
if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
    command -v spectacle &>/dev/null && echo "✓ spectacle (Wayland)" || echo "✗ spectacle not found — needed for Wayland screenshots"
else
    command -v scrot &>/dev/null && echo "✓ scrot (X11)" || echo "✗ scrot not found — install with: sudo apt install scrot"
fi

# 4. ImageMagick convert (for snap_region assertions and screenshot cropping)
command -v convert &>/dev/null && echo "✓ ImageMagick convert" || echo "✗ convert not found — install with: sudo apt install imagemagick"

# 5. ImageMagick compare (for assert_regions_differ / assert_regions_same)
command -v compare &>/dev/null && echo "✓ ImageMagick compare" || echo "✗ compare not found — install with: sudo apt install imagemagick"

# 6. Display environment
[[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]] && echo "✓ Display: ${DISPLAY:-}${WAYLAND_DISPLAY:-}" || echo "✗ No DISPLAY or WAYLAND_DISPLAY set"

# 7. No conflicting DRAW instances
if pgrep -f "DRAW.run" >/dev/null 2>&1; then
    echo "! WARNING: Another DRAW instance is running — this may interfere with tests"
    pgrep -af "DRAW.run"
else
    echo "✓ No conflicting DRAW instances"
fi
```

**If any critical check fails** (`DRAW.run`, `xdotool`, screenshot tool, or display), stop and tell the user what to fix before proceeding.

**If only warnings** (e.g. another DRAW instance), inform the user and ask whether to continue.

---

## Step 2 — Execute tests

Run the harness from the project root's `QA/` directory. Always use `bash` tool in **sync mode** with adequate `initial_wait` (tests typically take 15–120 seconds depending on count):

```bash
cd /home/grymmjack/git/DRAW/QA && ./draw-qa.sh [tests/file.sh ...]
```

**Examples:**

```bash
# All tests
cd /home/grymmjack/git/DRAW/QA && ./draw-qa.sh

# Single test
cd /home/grymmjack/git/DRAW/QA && ./draw-qa.sh tests/smoke.sh

# Keep DRAW open for inspection
cd /home/grymmjack/git/DRAW/QA && ./draw-qa.sh --keep-open tests/brush-draw.sh
```

Capture the **full output**. The harness produces structured output:

| Prefix | Meaning |
|--------|---------|
| `✓ PASS` | Assertion passed |
| `✗ FAIL` | Assertion failed |
| `! WARN` | Non-fatal warning |
| `~ SKIP` | Test skipped |
| `»` | Informational message |
| `━━━ name ━━━` | Test file boundary |
| `► name: done` | Test file completed |

The harness also produces:
- **Log file**: `QA/results/run-YYYYMMDD-HHMMSS.log` (full output with ANSI stripped)
- **Screenshots**: `QA/screenshots/*.png` (captured during test execution)
- **Snap regions**: `QA/screenshots/_snap_*.png` (sub-region captures for visual assertions)

The final summary line is:

```
Results: N passed  M failed  K skipped
```

The harness exit code is `0` if all tests passed, non-zero if any failed.

---

## Step 3 — Analyze results

Parse the captured output systematically:

### 3a. Count results

Extract pass/fail/skip totals from the summary line:

```
Results: N passed  M failed  K skipped
```

### 3b. Identify failures

For each `✗ FAIL` line, extract:
- **Test file** — from the nearest preceding `━━━ name ━━━` header
- **Assertion message** — the text after `✗ FAIL —`
- **Context** — surrounding `»` info lines that show what action preceded the failure

### 3c. Analyze screenshots on failure

If any tests failed, check for screenshots captured during or near the failure:

```bash
ls -lt QA/screenshots/*.png 2>/dev/null | head -20
```

For each relevant screenshot, use the `qb64pe-analyze_qb64pe_graphics_screenshot` MCP tool to examine what DRAW was displaying at the time of failure:

```
qb64pe-analyze_qb64pe_graphics_screenshot
  screenshotPath: /home/grymmjack/git/DRAW/QA/screenshots/{file}.png
  analysisType: comprehensive
```

This reveals whether the failure was caused by:
- DRAW not rendering correctly
- Wrong tool being active
- Dialog or popup blocking the canvas
- Window focus lost to another application

### 3d. Check snap_region diffs

If the test used `snap_region` + `assert_regions_differ` / `assert_regions_same`, failed comparisons leave both snapshot files in `QA/screenshots/` for inspection. Look for `_snap_*.png` files and compare them visually.

---

## Step 4 — Report results

Present results in a clear summary table:

```
## QA Run Results — {date}

| Test | Result | Passed | Failed | Details |
|------|--------|--------|--------|---------|
| smoke | ✓ PASS | 3 | 0 | |
| brush-draw | ✗ FAIL | 2 | 1 | canvas unchanged after stroke |
| keyboard-shortcuts | ✓ PASS | 8 | 0 | |
| new-layer | ~ SKIP | 0 | 0 | xdotool focus issue |

**Total: 13 passed, 1 failed, 1 skipped**
**Log**: `QA/results/run-20250101-143022.log`
```

### For each failure, provide a detailed analysis:

> **FAILED**: `brush-draw` — "canvas unchanged after stroke — regions are identical (action had no effect?)"
>
> **Assertion**: `assert_regions_differ` on canvas centre before/after drag
>
> **Screenshot analysis**: *(from MCP tool)* Canvas appears blank at default zoom. Brush tool icon is highlighted in toolbar.
>
> **Likely cause**: Window focus was lost between `key b` and `drag` — SDL2 didn't receive the mouse events. The harness called `draw_focus` but KDE/Wayland may have delayed the focus grant.
>
> **Suggested fix**:
> - Add `wait_for 0.5 "focus settle"` after `draw_focus` in the test
> - Or increase the `sleep` in the `drag()` helper before `mousedown`
> - Or add an explicit `draw_focus` call immediately before the drag

### Common failure categories and fixes:

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| "regions are identical" | Focus lost, events not received | Add `draw_focus` + `wait_for` before action |
| "window has closed unexpectedly" | DRAW crashed | Check `DRAW.log` for error, file a bug |
| "window title: expected X got Y" | Wrong state after action | Increase `wait_for` to let DRAW process the action |
| "DRAW process has died" | Segfault or unhandled error | Run under `gdb` or check core dump |
| Assertion passes locally but fails in CI | Timing-dependent | Double `wait_for` durations, add `draw_focus` |

---

## Step 5 — Fix and re-run (optional)

If the user asks to fix failing tests:

### 5a. Edit the test script

Based on the analysis from Step 4, make targeted edits to the failing test file in `QA/tests/`. Common fixes:

- **Add wait time**: Insert `wait_for 0.3 "settle"` after actions that change state
- **Add focus call**: Insert `draw_focus` before input sequences
- **Fix coordinates**: Recalculate viewport coordinates using the harness variables (`$CANVAS_CX`, `$CANVAS_CY`, `$WORK_LEFT`, etc.)
- **Increase fuzz tolerance**: For `assert_regions_differ`, a 2% fuzz is default — anti-aliasing or theme differences may need more
- **Add screenshots**: Insert `screenshot "debug-label"` before failing assertions to capture state

### 5b. Re-run only the fixed test

```bash
cd /home/grymmjack/git/DRAW/QA && ./draw-qa.sh tests/{name}.sh
```

### 5c. Report updated results

Present the same summary table from Step 4 with the updated results. If all tests now pass, confirm success. If failures persist, loop back to analysis.

---

## Important Notes

### Harness architecture
- The harness launches DRAW **once** and runs all test files sequentially in the same shell
- Test files are **sourced** (not subprocesses) — all helper functions and variables (`DRAW_PID`, `DRAW_WID`, `PASS`, `FAIL`, `CANVAS_CX`, etc.) are shared
- Tests must be independent — don't rely on state from a previous test file

### Coordinate system
- All coordinates in test files are **internal viewport pixels** (not physical screen pixels)
- The harness multiplies by `DISPLAY_SCALE` when converting to absolute screen coordinates
- Canvas centre is pre-computed as `$CANVAS_CX` / `$CANVAS_CY` from `DRAW.cfg`
- Work area bounds: `$WORK_LEFT`, `$WORK_RIGHT`, `$WORK_TOP`, `$WORK_BOTTOM`

### Harness-provided variables
| Variable | Source | Example |
|----------|--------|---------|
| `CANVAS_CX` | Computed from DRAW.cfg | 300 |
| `CANVAS_CY` | Computed from DRAW.cfg | 250 |
| `CANVAS_W` / `CANVAS_H` | DRAW.cfg `DEFAULT_CANVAS_SIZE_W/H` | 320 / 200 |
| `DISPLAY_SCALE` | DRAW.cfg `DISPLAY_SCALE` | 2 |
| `TOOLBAR_SCALE` | DRAW.cfg `TOOLBAR_SCALE` | 2 |
| `VIEWPORT_W` / `VIEWPORT_H` | DRAW.cfg `SCREEN_WIDTH/HEIGHT` | 904 / 510 |
| `WORK_LEFT` / `WORK_RIGHT` | Computed from dock config | 100 / 808 |
| `WORK_TOP` / `WORK_BOTTOM` | Computed from chrome sizes | 12 / 469 |
| `DRAW_PID` / `DRAW_WID` | Set by `draw_launch` | 12345 / 0x2c00003 |

### Helper function reference
| Helper | Arguments | Description |
|--------|-----------|-------------|
| `click` | `X Y [btn=1]` | Click at viewport-pixel coords |
| `right_click` | `X Y` | Right-click |
| `double_click` | `X Y` | Double-click |
| `drag` | `X1 Y1 X2 Y2 [btn=1]` | Click-drag between two points |
| `scroll_up` / `scroll_down` | `X Y` | Mouse wheel at position |
| `type_text` | `"string"` | Type printable characters |
| `key` | `combo...` | Send key combos (e.g. `key ctrl+z`, `key Escape F1`) |
| `wait_for` | `N "msg"` | Sleep N seconds with log message |
| `draw_focus` | | Re-focus the DRAW window |
| `draw_launch` | `[timeout=15]` | Launch DRAW and wait for window |
| `draw_quit` | | Close DRAW (skipped with `--keep-open`) |
| `screenshot` | `"label"` | Capture full DRAW window to PNG |
| `snap_region` | `X Y W H "label"` | Capture a viewport sub-region to PNG |
| `assert_no_crash` | | Verify DRAW process is alive |
| `assert_window_exists` | | Verify DRAW window is open |
| `assert_window_title` | `"substr"` | Check window title contains substring |
| `assert_regions_differ` | `file1 file2 "msg"` | Fail if two snapshots are identical |
| `assert_regions_same` | `file1 file2 "msg"` | Fail if two snapshots differ |
| `info` / `pass` / `fail` / `warn` / `skip` | `"msg"` | Structured log output |

### Wayland / KDE considerations
- Under Wayland, `spectacle` is used for screenshots (handles SDL2/OpenGL compositor buffers)
- Under X11, `scrot` captures the root window and `convert` crops to the DRAW window region
- The harness auto-detects window decoration offset (`DECORATION_Y`) for precise region cropping
- `draw_focus` uses both `windowactivate` and `windowfocus` for reliable KDE Wayland refocusing

### Output locations (gitignored)
- **Logs**: `QA/results/run-YYYYMMDD-HHMMSS.log`
- **Screenshots**: `QA/screenshots/*.png`
- **Snap regions**: `QA/screenshots/_snap_*.png` (kept on failure, cleaned on pass)
