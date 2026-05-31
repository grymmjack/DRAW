# GLFW cross-platform keyword tests

Standalone QB64-PE verifiers for the windowing/input keywords that **a740g's
GLFW-backend PR** makes work on **Linux / macOS / Windows**. Several of these
were Windows-only (or unsupported on Linux/macOS) before the PR — see the
"Pre-a740g" column. Each `.BAS` isolates one keyword so a failure points
straight at the keyword and platform that broke.

> Built and run with the **a740g** compiler (`~/git/qb64pe-a740g-test/qb64pe`).
> The `Makefile` here mirrors the root project's `a740g` / `a740g-run` targets.

## How to run

```bash
cd PLANS/TESTS/GLFW

make a740g                       # build all tests with the a740g compiler
make a740g-run TEST=CAPSLOCK     # build & run one test
make list                        # list valid TEST= names
make clean                       # remove built binaries

# A/B comparison against the stable SDL2 build (v450):
make a740g-run TEST=KEYCODE QB64PE=$HOME/git/qb64pe-450/qb64pe
```

Every test quits on **ESC** or the window close button — **except**
`GLFW_KEYCODE_TEST`, which quits only on window-close so it can observe ESC as
data.

| `TEST=` | Program | Keyword(s) | Pre-a740g | How to verify |
|---------|---------|------------|-----------|---------------|
| `CAPSLOCK` | `GLFW_CAPSLOCK_TEST.BAS` | `_CAPSLOCK` (read) | read: all platforms; set: Win-only | press the PHYSICAL Caps Lock key; the `value%` reading flips |
| `NUMLOCK` | `GLFW_NUMLOCK_TEST.BAS` | `_NUMLOCK` (read) | read: all platforms; set: Win-only | press the PHYSICAL Num Lock key; reading flips |
| `SCROLLLOCK` | `GLFW_SCROLLLOCK_TEST.BAS` | `_SCROLLLOCK` (read) | read: all platforms; set: Win-only | press the PHYSICAL Scroll Lock key; reading flips |
| `DRAGDROP` | `GLFW_DRAGDROP_TEST.BAS` | `_ACCEPTFILEDROP`, `_TOTALDROPPEDFILES`, `_DROPPEDFILE$`, `_FINISHDROP` | Win-only | drag files onto the window; paths + count appear |
| `DESKTOPWIDTH` | `GLFW_DESKTOPWIDTH_TEST.BAS` | `_DESKTOPWIDTH` | partial | non-zero, matches real screen width |
| `DESKTOPHEIGHT` | `GLFW_DESKTOPHEIGHT_TEST.BAS` | `_DESKTOPHEIGHT` | partial | non-zero, matches real screen height |
| `SCREENMOVE` | `GLFW_SCREENMOVE_TEST.BAS` | `_SCREENMOVE x,y` / `_MIDDLE` | no Linux | 1/2/3/M move the window; X,Y read back match |
| `SCREENXY` | `GLFW_SCREENXY_TEST.BAS` | `_SCREENX`, `_SCREENY` | Win-only | drag window; live X,Y update |
| `WINDOWHASFOCUS` | `GLFW_WINDOWHASFOCUS_TEST.BAS` | `_WINDOWHASFOCUS` | not macOS | click away → FALSE, click back → TRUE |
| `WINDOWHANDLE` | `GLFW_WINDOWHANDLE_TEST.BAS` | `_WINDOWHANDLE` (`_INTEGER64`) | Win-only | handle is non-zero |
| `KEYCODE` | `GLFW_KEYCODE_TEST.BAS` | `_KEYDOWN` / `_KEYHIT` scanner | — | diagnostic: see which physical codes the backend reports |

## Why the `KEYCODE` scanner is here

Built to diagnose a reported "Ctrl+Alt+O doesn't fire in DRAW under a740g". It
shows, live, exactly which physical codes the active backend reports for Ctrl,
Alt and O. **Outcome:** on a real keyboard, Ctrl+Alt+O works fine on a740g
(`O 111=Y`, FIRES=ON) — see [KNOWN-xdotool-ctrl-alt-letter.md](KNOWN-xdotool-ctrl-alt-letter.md).
The only failure was with `xdotool` synthetic input (an automation artifact, not
a real bug). Run it under a740g vs v450 to compare:

```bash
make a740g-run TEST=KEYCODE                                       # GLFW backend
make a740g-run TEST=KEYCODE QB64PE=$HOME/git/qb64pe-450/qb64pe    # SDL2 backend
```

## Results matrix

Fill in as each keyword is verified per OS: ✅ pass · ❌ fail · ⬜ untested ·
`n/c` = did not compile on that OS pre-a740g. Note the build/compiler in the
"Notes" column when relevant.

| Keyword | Linux | macOS | Windows | Notes |
|---------|:-----:|:-----:|:-------:|-------|
| `_CAPSLOCK` (read) | ⬜ | ⬜ | ⬜ | press physical key + watch counter; setter is Windows-only |
| `_NUMLOCK` (read) | ⬜ | ⬜ | ⬜ | press physical key + watch counter; setter is Windows-only |
| `_SCROLLLOCK` (read) | ⬜ | ⬜ | ⬜ | press physical key + watch counter; setter is Windows-only |
| drag & drop | ✅ | ⬜ | ⬜ | a740g/Linux: works (manual) |
| `_DESKTOPWIDTH` | ✅ | ⬜ | ⬜ | a740g/Linux: 3840 (non-zero) |
| `_DESKTOPHEIGHT` | ✅ | ⬜ | ⬜ | a740g/Linux: works (manual) |
| `_SCREENMOVE` | ✅ | ⬜ | ⬜ | a740g/Linux: works (manual) |
| `_SCREENX/_SCREENY` | ✅ | ⬜ | ⬜ | a740g/Linux: works (manual) |
| `_WINDOWHASFOCUS` | ✅ | ⬜ | ⬜ | a740g/Linux: works (manual); macOS still open |
| `_WINDOWHANDLE` | ✅ | ⬜ | ⬜ | a740g/Linux: returns X11 window id (non-zero) |

**Lock keys — read vs set (important):** per a740g, the lock-key **function**
(`value% = _CAPSLOCK`) reads state on **all platforms** (on Linux via
`XkbGetIndicatorState`, no window focus required); the lock-key **statement**
(`_CAPSLOCK ON|OFF|_TOGGLE`) is **Windows-only** by design. So on Linux/macOS the
correct test is the **reader**: press the *physical* lock key and watch the
`value%` reading flip (the test counts the changes). Note: this **cannot be
automated** here — synthetic `xdotool Caps_Lock` does NOT move the real
`XkbGetIndicatorState`/`/sys/class/leds` state, so only a physical keypress
exercises it. Ground-truth cross-checks on Linux: `xset q` and
`cat /sys/class/leds/input*::capslock/brightness`.

### Ctrl+Alt+O on a740g — NOT a regression (it works on a real keyboard)

Full write-up: [KNOWN-xdotool-ctrl-alt-letter.md](KNOWN-xdotool-ctrl-alt-letter.md).
Holding Ctrl+Alt+O in `GLFW_KEYCODE_TEST`:

| Input on a740g (GLFW) | CTRL | ALT | O: 111 | O in `_KEYHIT`? | Ctrl+Alt+O fires? |
|-----------------------|:----:|:---:|:------:|:---------------:|:-----------------:|
| **physical keyboard** | ON | ON | **Y** | **yes** | **ON** ✅ |
| `xdotool` (XTEST) | ON | ON | n | no | off ❌ |

**Conclusion:** with a **real keyboard**, Ctrl+Alt+O works on a740g. The `xdotool`
"swallow" is a **synthetic-input artifact** (XTEST letter dropped under Ctrl+Alt by
the GLFW backend), NOT a user-facing bug — **don't report it to a740g.** Side
effect: DRAW's `xdotool`-based `QA/` harness can't reliably test `Ctrl+Alt+letter`
hotkeys on a GLFW build; verify those by hand.
