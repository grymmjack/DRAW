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
| `CAPSLOCK` | `GLFW_CAPSLOCK_TEST.BAS` | `_CAPSLOCK` (read + `ON/OFF/_TOGGLE`) | Win-only | O/F/T set it; state tracks the keyboard LED |
| `NUMLOCK` | `GLFW_NUMLOCK_TEST.BAS` | `_NUMLOCK` | Win-only | same as Caps |
| `SCROLLLOCK` | `GLFW_SCROLLLOCK_TEST.BAS` | `_SCROLLLOCK` | Win-only | same as Caps |
| `DRAGDROP` | `GLFW_DRAGDROP_TEST.BAS` | `_ACCEPTFILEDROP`, `_TOTALDROPPEDFILES`, `_DROPPEDFILE$`, `_FINISHDROP` | Win-only | drag files onto the window; paths + count appear |
| `DESKTOPWIDTH` | `GLFW_DESKTOPWIDTH_TEST.BAS` | `_DESKTOPWIDTH` | partial | non-zero, matches real screen width |
| `DESKTOPHEIGHT` | `GLFW_DESKTOPHEIGHT_TEST.BAS` | `_DESKTOPHEIGHT` | partial | non-zero, matches real screen height |
| `SCREENMOVE` | `GLFW_SCREENMOVE_TEST.BAS` | `_SCREENMOVE x,y` / `_MIDDLE` | no Linux | 1/2/3/M move the window; X,Y read back match |
| `SCREENXY` | `GLFW_SCREENXY_TEST.BAS` | `_SCREENX`, `_SCREENY` | Win-only | drag window; live X,Y update |
| `WINDOWHASFOCUS` | `GLFW_WINDOWHASFOCUS_TEST.BAS` | `_WINDOWHASFOCUS` | not macOS | click away → FALSE, click back → TRUE |
| `WINDOWHANDLE` | `GLFW_WINDOWHANDLE_TEST.BAS` | `_WINDOWHANDLE` (`_INTEGER64`) | Win-only | handle is non-zero |
| `KEYCODE` | `GLFW_KEYCODE_TEST.BAS` | `_KEYDOWN` / `_KEYHIT` scanner | — | diagnostic: see which physical codes the backend reports |

## Why the `KEYCODE` scanner is here

When DRAW is built with a740g, **Ctrl+Alt+O stops firing**. DRAW detects that
hotkey with `_KEYDOWN(111) OR _KEYDOWN(79)` plus the modifier codes
`100305..100308`, and `_KEYDOWN` physical codes are **backend-specific**. The
scanner shows, live, exactly which codes the active backend reports for Ctrl,
Alt and O — so we can tell whether the modifier codes or the letter code shifted
under GLFW. Run it under a740g vs v450 and compare:

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
| `_CAPSLOCK` | ⬜ | ⬜ | ⬜ | |
| `_NUMLOCK` | ⬜ | ⬜ | ⬜ | |
| `_SCROLLLOCK` | ⬜ | ⬜ | ⬜ | |
| drag & drop | ⬜ | ⬜ | ⬜ | |
| `_DESKTOPWIDTH` | ✅ | ⬜ | ⬜ | a740g/Linux: 3840 (non-zero) |
| `_DESKTOPHEIGHT` | ⬜ | ⬜ | ⬜ | |
| `_SCREENMOVE` | ⬜ | ⬜ | ⬜ | |
| `_SCREENX/_SCREENY` | ⬜ | ⬜ | ⬜ | |
| `_WINDOWHASFOCUS` | ⬜ | ⬜ | ⬜ | macOS is the open question |
| `_WINDOWHANDLE` | ✅ | ⬜ | ⬜ | a740g/Linux: returns X11 window id (non-zero) |

### Ctrl+Alt+O regression (DRAW, built with a740g) — CONFIRMED

Measured with `GLFW_KEYCODE_TEST` holding Ctrl+Alt+O (identical synthetic input
to both builds). Full write-up + screenshots: [REGRESSION-ctrl-alt-letter.md](REGRESSION-ctrl-alt-letter.md).

| Backend | CTRL reads | ALT reads | O: 111 / 79 / 15 | O in `_KEYHIT`? | Ctrl+Alt+O fires? |
|---------|:----------:|:---------:|:----------------:|:---------------:|:-----------------:|
| a740g (GLFW) | ON | ON | **n** / n / n | **no** | **off** ❌ |
| v450 (SDL2) | ON | ON | **Y** / n / n | **yes (111)** | **ON** ✅ |

**Conclusion:** a740g's GLFW backend **swallows the letter key while Ctrl+Alt are
held** — the modifiers are fine, but the letter event never arrives (no code, not
even in `_KEYHIT`). Plain `Ctrl+letter` (e.g. `Ctrl+O`) works under a740g, so
`Ctrl+Z`/`Ctrl+B`/`Ctrl+S` are unaffected. This is a **PR/backend regression, not
a DRAW bug** — DRAW needs no change; report it to a740g.
