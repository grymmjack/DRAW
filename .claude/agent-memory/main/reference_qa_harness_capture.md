---
name: reference-qa-harness-capture
description: QA/draw-qa.sh is the xdotool automation + screenshot harness for DRAW. On grymmjack's Linux/KDE Wayland box it is also the ONLY working capture path — ImageMagick `import -window` has no X11 delegate and `scrot -u` returns an all-black frame.
metadata:
  type: reference
---

[Linux — grymmjack's KDE/Wayland box; untested on macOS/Windows]

`QA/draw-qa.sh` drives DRAW with `xdotool` and captures screenshots. Use it
instead of hand-rolling an xdotool + screenshot pipeline.

**Capture on this machine is Wayland-only, and both obvious tools are broken:**

- `import -window <wid> out.png` fails with
  `delegate library support not built-in '' (X11)` — this ImageMagick 7.1.2
  build has no X11 delegate at all. Every `import` invocation dies.
- `scrot -u -o out.png` "succeeds" and writes a correctly-sized PNG that is
  **entirely black** — the compositor doesn't hand the window contents to an
  X11 screen grab.
- The **qb64pe MCP `screenshot` / `run_and_screenshot` tools go through
  `import`**, so they cannot capture here either. They return the ImageMagick
  usage dump plus "Capture failed or produced a zero-byte image". This is an
  environment limitation, NOT the program failing to launch.

**What works** — `_capture_client_area()` in `QA/draw-qa.sh`: full-screen
capture with `setsid spectacle -b -n -f -o "$tmp"` when `$WAYLAND_DISPLAY` is
set, then `convert -crop` down to the client area using the cached window
position and `_NET_FRAME_EXTENTS`-derived decoration height. `setsid` matters:
without it the compositor gives spectacle keyboard focus and DRAW misses every
subsequent key event.

**Finding click coordinates — don't derive them, probe them.** DRAW's bottom
chrome does not decompose the way the cfg suggests (`THEME.STATUS_height` is 11
and the chip rows are 12px, yet the band below the canvas is 41px and the
palette-name button sits at viewport y≈484, not the 497 the arithmetic gives).
Run `./draw-qa.sh --probe`, hover the target, hold still ~1.5s, and it prints
`MARK <x>,<y>` in viewport pixels. Ask the user to do the hovering — they can
see the screen and you cannot. `PROBE_SECS=60` for a longer window.

**Harness invariants that were silently broken before 2026-08-01** (fixed, but
worth knowing the failure signatures):
- `DISPLAY_SCALE=0` in cfg means auto-detect. `${x:-1}` does NOT substitute a
  literal `0`, so clicks became `x*0` (window origin) and crops became `0x0`
  (which `convert` ignores → full-desktop screenshot, assertions pass on noise).
- QA now launches with `--config QA/DRAW.qa.cfg` (generated, gitignored) from
  `DRAW_ROOT` as cwd. Both matter: tests used to mutate the user's real
  `~/.config/DRAW/DRAW.cfg` via `CONFIG_save`, and DRAW never `CHDIR`s, so
  running from `QA/` breaks every `"./ASSETS/..."` relative path.
- `UI_SCALE` must stay **0** in the QA config — `SCREEN_init` only honors an
  explicit `SCREEN_WIDTH/HEIGHT` in pure Auto mode, otherwise it re-derives the
  viewport from the desktop and the window comes up desktop-sized.
- ImageMagick Q16 HDRI scales `compare -metric AE` by QuantumRange: **one**
  differing pixel reports as `65535`, and large counts print as `4.54281e+08`.
  The harness now self-calibrates at startup and normalises. Any tolerance
  tuned before this fix was compared against a meaningless number.
- `_verify_geometry_model` aborts the run if the real window doesn't match
  `VIEWPORT × DISPLAY_SCALE`. If it fires, fix the config — don't bypass it.

**How to apply:**
- To verify a change visually, write a test in `QA/tests/<area>.sh` and run
  `./QA/draw-qa.sh tests/<name>.sh`; use the `screenshot` / `snap_region` +
  `assert_regions_differ` / `assert_regions_same` helpers rather than shelling
  out to a screenshot tool yourself.
- `./draw-qa.sh --keep-open` leaves DRAW running after the last test for
  interactive poking; `--verbose` logs every mouse/key action.
- Sourcing with `--lib` returns at line 23 *before* any function is defined —
  it is not a usable library import. Put reusable logic in a test file.
- Tests are atomic: the harness launches a fresh DRAW per test file and
  `ctrl+q`s it after, so state can't leak between tests.
- Coordinates in tests are **viewport pixels**, converted by `_abs()` using
  `DISPLAY_SCALE` from `DRAW.cfg` — never pass raw screen coordinates.
- If you must capture outside the harness, copy its spectacle recipe. Don't
  reach for `import` or `scrot`.

Related: [[feedback_screenshot_timing]] (sleep ≥1.0s before capturing; never
judge "did it change" by PNG file size), [[feedback_pkill_f_self_match_hang]]
(kill DRAW by exact PID, never `pkill -f`).
