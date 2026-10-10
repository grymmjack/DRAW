# QA harness on macOS and Windows

Status: **built; first full runs in progress** (2026-10-09 evening).

| Step | State |
| --- | --- |
| 1. Everything through the driver | Done (harness 1e79b56, DRAW ac2bbdbd; guard test `qa-no-os-tools-in-tests`) |
| 2. `qa-io` | Done, but **compiled per OS, not Python**: a Python call per input cost ~0.3s, and thinkpad has no Python. macOS `qa-io.c` (CoreGraphics), Windows `qa-io.cs` (.NET Framework `csc`) |
| 3. macOS | Done: smoke + view-pan + dock-combine-layers 77/77. Two input faults found and fixed (see below) |
| 4. Windows | Done on thinkpad: smoke / brush-size / view-pan 18/18, dock tests 75/75 |
| 5. Farm | `farm-check.sh qa mac\|thinkpad\|titan`, dashboard panels for every host, per-OS known failures |
| Full suites | titan done; thinkpad and mac running (each ~2x titan's 3h) |

**What the plan didn't foresee:**
- [macOS] An app launched by the runner gets no mouse-moved events until it has been switched away from and back (Cmd+Tab round trip after launch), and a drag split across processes is dropped (one long-lived `qa-io serve` posts all input).
- [Windows] QB64-PE v4.7.0-GLFW shrinks every window by the monitor content scale (250%: an 800x600 `SCREEN` opens 320x240). QA renders at 2 x content scale to compensate. Not reported upstream yet.
- [Windows] SSH sessions have no desktop; jobs run through a Scheduled Task from `C:\qa-runner`, because the desktop user can't read the SSH user's profile.
- Waiting for DRAW to be painted before a test means tests now start on an idle DRAW (15 fps): a press needs its own frame before the pointer moves.

## Why

Rick, 2026-10-09: *"can we make the qa-harness work on both mac and windows?"*

The build farm has macOS (`mac`, Apple Silicon, Retina) and Windows (`thinkpad`, 4K at 200%; `daw`) machines. Today they can only *build* DRAW, because the harness (`~/git/qa-harness`) drives Linux/X11 only: Xvfb, xdotool, scrot, xwininfo. DRAW's platform-specific behaviour (window, input, DPI, cursor) goes untested there.

## What exists

- **Core** (`core/`): the runner, asserts, input verbs (`click`, `hover`, `drag`, `key`, `type_text`, …). It's OS-neutral, calls the driver, and crops and compares screenshots with ImageMagick.
- **Driver** (`drivers/linux-x11/driver.sh`): the only OS layer, 13 functions.

  | Area | Functions |
  | --- | --- |
  | Input | `driver_input_move`, `_button`, `_button_move`, `_key`, `_type`, `_scroll`, `_key_hold` |
  | Capture | `driver_capture_full` |
  | Window | `driver_window_bounds_by_title`, `driver_detect_decoration_height` |
  | Offscreen | `driver_offscreen_available`, `driver_run_offscreen` |
  | Dependencies | `driver_check_deps` |
- **Leaks around the driver:**
  - The DRAW adapter calls `xdotool` directly 24 times: window search, title, activate/focus, relative nudges, keys to the window, geometry.
  - 22 DRAW test files call `xdotool` directly: key down/up holds, mouse down/move/up at screen coordinates, window titles, window-relative moves, and one timing-critical chained call.

## Plan

### Step 1: everything through the driver (Linux only, no behaviour change)

**New driver functions:**

| Function | What it does |
| --- | --- |
| `driver_window_find PID TITLE` | Returns a handle |
| `driver_window_title H` | The window's title |
| `driver_window_activate H` | Activate + focus |
| `driver_window_bounds H` | `X Y W H` |
| `driver_input_move_rel DX DY` | Relative mouse move |
| `driver_input_seq …` | An atomic input sequence in a neutral mini-language: `move X Y`, `down B`, `up B`, `key K`, `keydown K`, `keyup K`. X11 sends it as one `xdotool` call; other drivers run it in order. |

**New core verbs** for tests that work in screen coordinates:
- `raw_move SX SY`
- `raw_button down|up N`
- `raw_key down|up K`
- `raw_seq …`
- `app_window_title`

**Then:**
- The DRAW adapter and the 22 DRAW tests use those verbs; no `xdotool` is left outside `drivers/linux-x11/`.
- A guard test fails if any appears again.

**Exit check:** the 22 tests plus a smoke set pass on Linux. The dock baseline is unaffected (it's not input-driven).

### Step 2: `qa-io`, one small cross-platform helper (Python)

It covers input (move, button, key down/up, type, scroll), a full-screen capture to PNG, and window find/bounds/title/activate. It has one backend per OS:

| OS | Input | Capture | Windows |
| --- | --- | --- | --- |
| Linux | xdotool (as today) | scrot | xwininfo / xdotool |
| macOS | Quartz `CGEvent` (pyobjc) | `screencapture` | `CGWindowListCopyWindowInfo` |
| Windows | `SendInput` (ctypes) | `mss` / GDI | `EnumWindows` / `GetWindowRect` |

`drivers/macos/driver.sh` and `drivers/windows/driver.sh` are thin wrappers over it. The core runs unchanged under bash: Homebrew bash 5 on macOS (the system bash is 3.2), Git Bash on Windows. ImageMagick comes from brew / winget.

### Step 3: macOS (`mac`)

**One-time, needs Rick:**
- grant Accessibility + Screen Recording to the runner (System Settings);
- `brew install bash imagemagick`;
- `pip install pyobjc-framework-Quartz`.

**Running:** a run must happen in Rick's logged-in GUI session, not the SSH session. `farm-check.sh qa mac` starts it through a LaunchAgent / `launchctl asuser`.

**Geometry:** Retina, so per-host coordinates: `DISPLAY_SCALE`, the geometry check, and a capture scale (screencapture works in physical pixels).

**No offscreen mode:** the tests drive the real screen, mouse and keyboard, so the Mac is unusable during a run.

### Step 4: Windows (`thinkpad`, then `daw`)

**Running:** in the interactive desktop session, through a Scheduled Task ("run only when the user is logged on") or `PsExec -i`, because SSH has no desktop.

**Tools:** Git Bash for the core; Python + `mss` + ctypes for `qa-io`; ImageMagick from winget.

**Geometry:** 4K at 200%, so per-host geometry, and DPI awareness in `qa-io` so coordinates are physical.

**Same as the Mac:** no offscreen mode, the machine is unusable during a run.

### Step 5: the farm

- `DEV/farm-check.sh qa mac|thinkpad|daw` builds, then starts the suite in the right session.
- The dashboard shows a live panel per host, as for titan.
- `QA/known-failures.txt` gets per-OS entries (`name  [macOS] reason`).

## Risks

- **Platform differences in the tests themselves:** key names (super vs cmd), fonts, timing at different frame rates. The first runs will mix real DRAW bugs with test assumptions, and each needs sorting.
- **Permissions and sessions** are the fiddliest part (macOS TCC, Windows session 0). Rick has to click a few things once.
- **Machine time:** a full run takes about 1½–2 hours, and the machine can't be used meanwhile.

## Decisions

| Question | Answer |
| --- | --- |
| Do it | **Yes** (Rick, 2026-10-09) |
| Order | Linux refactor → macOS → Windows |
