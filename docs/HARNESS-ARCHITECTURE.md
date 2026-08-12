# QA Harness Architecture — seam map & driver contract

Goal: split `QA/draw-qa.sh` (1163 lines, DRAW/QB64-specific in places) into a
**portable core** + a thin **driver** (platform input/capture) + a tiny
**adapter** (per-project). DRAW becomes adapter #1; a Rust/X11 GUI is adapter #2.
Linux (X11 + Xvfb) is homebase; the driver seam lets Win/Mac/CI plug in later.

## The three layers + one narrow seam

```
CORE  (portable; knows nothing about the app or the OS)
  runner · assert(diff) · mark · report · config-lock · consent/mode · eta · logging
        │ needs 3 things from a DRIVER          │ needs a few facts from an ADAPTER
        ▼                                        ▼
DRIVER (per platform)                     ADAPTER (per project — tiny)
  input:   move/click/drag/key/type/scroll   launch/quit · window match
  capture: full-frame → PNG                   logical→screen geometry
  target:  find window · bounds · offscreen   blessed config · hooks(wait/wake/alive)
  linux-x11 = xdotool + spectacle/scrot + Xvfb   DRAW / Rust-GUI / web = adapters
```

**The crux is coordinates.** Tests speak **logical** coords; the adapter maps
logical→screen. Default logical = window-relative pixels (`window_origin + scale`).
DRAW needs a *viewport* model only because of display scaling, so that whole
`_abs`/`VIEWPORT×DISPLAY_SCALE` machinery lives in the DRAW adapter and never
touches the core. Web adapters skip pixels and resolve selectors instead.

## Classification of every `draw-qa.sh` symbol

### CORE — keep, de-DRAW, move to the toolkit
| Symbol(s) | Role |
|-----------|------|
| `log` `info` `dbg` `pass` `fail` `warn` `skip` + `PASS/FAIL/SKIP` counters | logging + tally |
| `wait_for` | timed wait (input timing/sync) |
| `snap_region` (crop logic), `screenshot` | region/full capture *orchestration* (calls driver for the pixels) |
| `assert_regions_differ` `assert_regions_same` | **the core value** — visual assertions |
| `_ae_number` `_calibrate_ae` `_parse_ae` | ImageMagick AE-diff normalization (QuantumRange-safe) |
| `assert_no_crash*` `_crash_snapshot` | liveness/crash detection *(crash-log path → adapter hook)* |
| `assert_window_exists` `assert_window_title` | still-alive checks *(via driver window-find)* |
| `run_test_file` | test isolation + passed-cache + per-file tally |
| `check_deps` | dependency preflight *(the dep list is driver-informed)* |
| input **verb API** (`click` `right_click` `double_click` `drag` `scroll_*` `type_text` `key` `park_mouse`) | the *signatures* are core; the *bodies* are driver (see below) |
| entrypoint flags (`--list` `--rerun-passed` `--fail-fast` `--stop` `--reset*`) | runner CLI |

### DRIVER — swap per platform (today: linux-x11)
| Symbol(s) | Platform dependency |
|-----------|---------------------|
| `_capture_client_area` | `spectacle` (Wayland) / `scrot` (X) + `convert` crop |
| bodies of `click/drag/key/type_text/scroll_*` | `xdotool` (XTEST) |
| `draw_focus` | `xdotool windowactivate` |
| `_update_win_pos` | `xwininfo` window geometry |
| `_detect_decoration_height` | WM/`_NET_FRAME_EXTENTS` |
| offscreen launch | `Xvfb` + unset `WAYLAND_DISPLAY` (so spectacle→X11 / scrot works) |

### ADAPTER — DRAW-specific, extract to a `draw` adapter
| Symbol(s) | Why it's DRAW-only |
|-----------|--------------------|
| `_qa_cfg_overrides` `_ensure_qa_cfg` | blessed `DRAW.qa.cfg` + re-assert-each-run *(mechanism = core; values = adapter)* |
| `_cfg` `_num_or` | read DRAW cfg keys |
| `draw_launch` `draw_quit` | launch/stop the DRAW binary |
| `_verify_geometry_model` | asserts window == `VIEWPORT × DISPLAY_SCALE` |
| `_abs` + geometry constants (`VIEWPORT_*` `DISPLAY_SCALE` `TOOLBAR_W`, panel rects) | DRAW's logical→screen viewport map |
| `wake_draw` | DRAW's 13-fps idle drops Ctrl-combos; a pre-key jiggle hook |
| `canvas_focus` | DRAW-specific "click the canvas non-destructively" |
| `WINDOW_TITLE="DRAW v"` | window match string |
| crash-log dir (`~/Desktop/DRAW-log/...`) | DRAW's crash-report location |

**Rule of thumb:** ~70% of `draw-qa.sh` is CORE, ~15% DRIVER, ~15% ADAPTER.

## The driver interface (what CORE calls)

```
# INPUT (screen coords already resolved by the target)
input.move  sx sy
input.button down|up|click  1|2|3
input.key   <combo>            # e.g. ctrl+s ; holds mods, taps base (SDL2/_KEYDOWN-safe)
input.type  <text>
input.scroll up|down [ticks]

# CAPTURE
capture.full  <outfile.png>    # whole display; CORE crops regions itself

# TARGET / lifecycle
target.launch          -> pid          # from the adapter's launch spec
target.window_id                        # find by adapter's match (see note below)
target.window_bounds   -> x y w h scale # screen rect + DPI scale
target.is_alive        -> 0|1           # adapter hook (pid / health)
target.focus
target.quit
target.offscreen?      -> 0|1           # Xvfb present & usable
target.run_offscreen <cmd...>           # Xvfb @ native res, WAYLAND_DISPLAY unset
```

**No window ID assumed.** Some toolkits don't expose a usable window id —
**QB64-PE currently does not** (fix in flight). So `window_id` must degrade: match
by **title** (DRAW: `xdotool search --name "DRAW v"`), then by **pid**, then by
**geometry** (the single fullscreen-ish window on the display). Everything
downstream works from `window_bounds` (a rect), never from a stable WID — capture
crops a rect, input targets logical coords. Adapters for other apps supply
whatever match they can; the core never dereferences a WID directly.

**Positioning trick — deterministic coords without any id.** Even with *no* window
id, you can make coordinates deterministic by positioning the **active** window to
a known place + size via a WM hotkey (DRAW binds **Meta+Home** to center & resize).
The window then sits at a fixed desktop rect, so screen coords are stable and
"window-relative" is just a fixed offset — and this is precisely what enables
**window size / resize tests**. So the adapter exposes a `park_window` hook (the
hotkey), and the core reads the resulting bounds; the WID never enters the picture.

**Capture backend by display type** (learned the hard way — it drew FAIL boxes on
the user's editor): the *right* screenshot tool depends on the display, not the
machine.
- **Real Wayland session** (`WAYLAND_DISPLAY` set): `scrot` returns all-black →
  use **spectacle** (Wayland backend).
- **Pure X11 / offscreen Xvfb** (`WAYLAND_DISPLAY` unset): **scrot** captures the
  actual `$DISPLAY`. spectacle here reaches the *real* desktop through the xdg
  portal and grabs the WRONG screen — so never use it offscreen.
Selector: `WAYLAND_DISPLAY set → spectacle, else → scrot`; overridable via
`QA_CAPTURE=<tool>`; last-ditch scrot fallback. This is the CI-safe path.

## The logical-coordinate rule (the seam)

- Tests pass **logical** coords to `input.*` and **logical rects** to `snap`/`mark`.
- CORE converts logical→screen via the target: `screen = origin + logical*scale`
  (default). An adapter may override the mapping (DRAW: viewport pixels ×
  `DISPLAY_SCALE`, panels anchored per its layout).
- CORE never hard-codes a platform or an app coordinate — only the driver +
  adapter do. This is what lets one test file run against DRAW, a Rust GUI, or
  a web page.

## Offscreen / CI mode

`target.run_offscreen` wraps the launch in `Xvfb -screen 0 <W>x<H>x24` with
`WAYLAND_DISPLAY` **unset** (forces spectacle→X11 / scrot onto the virtual
display instead of grabbing the real Wayland screen). Two invariants, learned the
hard way:
1. Xvfb screen size must match what the app expects (DRAW re-derives its viewport
   from the screen at `UI_SCALE=0`, so a 4K homebase needs a 4K Xvfb).
2. `WAYLAND_DISPLAY` unset, or spectacle captures the real desktop → every region
   diff compares a static wrong frame ("regions are identical").

This is also the **GitHub Actions Linux** path: no real display, Xvfb + headless,
JUnit/exit-code output (Phase 3).

## Extraction plan (later phases)

1. Toolkit repo: `core/` (bash) · `report/` (python + junit) · `drivers/linux-x11/`
   · `adapters/<name>.manifest`.
2. `draw-qa.sh` → thin DRAW adapter: manifest (launch/window/blessed-cfg) + a
   `geometry.sh` (the viewport map) + `hooks.sh` (`wake_draw`, `canvas_focus`,
   `is_alive`, crash-log dir).
3. Same core, `rust-x11` adapter: reuse `linux-x11` driver, window-relative coords,
   no viewport model — the proof that the seam holds.
