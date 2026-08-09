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
position. `setsid` matters: without it the compositor gives spectacle keyboard
focus and DRAW misses every subsequent key event.

**The client-area origin comes from `xwininfo`, and `DECORATION_H` is 0.**
`_update_win_pos` reads `xwininfo`'s "Absolute upper-left", which is already
the client area on a reparenting WM — there is no title bar left to skip.

This is a correction. The harness used to *infer* the title bar from
`_NET_FRAME_EXTENTS` as `top - 3×left_shadow`; on KDE Breeze
(`extents = 1, 1, 36, 1`) that is `36 - 3 = 33` physical px of pure error,
added to an origin that was already correct. Consequences, fixed 2026-08-09:
- every click landed **16.5 viewport px too low** (20px layer rows: "click row
  0" hit row 1, which is empty on a fresh document);
- every capture was cropped 16.5 px too low, so a `VIEWPORT_H - STATUS_H`
  status-bar snap fell past the window's bottom edge and contained **desktop**,
  never changing no matter what DRAW did.

It hid for months because the error was **self-consistent** — clicks and
captures shifted together, so the harness agreed with itself and ~780
assertions passed. Only targets smaller than the error could detect it, and
when they did the message was "regions are identical (action had no effect?)",
which reads like a product bug. `QA/tests/harness-calibration.sh` now pins the
mapping at three heights (menu bar 12px, layer row 20px, status bar 11px) with
failure text that names `DECORATION_H`.

**Derive click coordinates from the render constants; the arithmetic is right.**
The older advice here — "don't derive them, probe them", citing a palette-name
button at viewport y≈484 "not the 497 the arithmetic gives" — was measuring the
33px bug. `--probe` reported through the same broken `_abs`, so every probed
figure was ~16.5px high. Verified against a real 958×514 window:
- status bar `503..513` = `SCRN.h - THEME.STATUS_height%` — exactly as computed;
- palette strip `491..502`, height `rows*(chipH+1)+3` = `1*9+3` = 12;
- layer panel `panelY% = 0` (NOT below the menu bar), 16px header, 20px rows, so
  row N's centre is `26 + N*20`;
- toolbar `TB_TOP = 0`, height `TB_ROWS*scaled_h + (TB_ROWS-1)*scaled_pad` = 166.

Two harness constants that are still off, deliberately left alone: `PALETTE_H`
is 30 against a real strip of 12 (it feeds `WORK_BOTTOM` → `CANVAS_CY`, so
retuning it moves the drawing origin for every test) — never use `PAL_Y` to
click a chip, derive it as `image-adj-full.sh` does.

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
- **If several unrelated tests fail at once with "regions are identical (action
  had no effect?)", suspect the harness before the product.** Run
  `./draw-qa.sh tests/harness-calibration.sh` first: it fails loudly and names
  `DECORATION_H` when the viewport→screen mapping has drifted. Confirm which
  side is wrong with `./draw-qa.sh --developer <test>` and read `./inputs.log`
  — the dispatcher logs `[FIRE] ... action=<id> label=<name>` for every
  dispatched binding, so "did DRAW receive it?" is answerable directly instead
  of inferred from pixels.
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
