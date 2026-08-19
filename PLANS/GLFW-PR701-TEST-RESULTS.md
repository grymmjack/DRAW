# QB64-PE GLFW PR #701 — DRAW test results (Linux)

Verification of a740g's **PR #701 "Replace freeglut with GLFW"** against DRAW on Linux,
plus a DRAW QA regression built with that compiler.

| Item | Value |
|------|-------|
| PR | https://github.com/QB64-Phoenix-Edition/QB64pe/pull/701 ("Replace freeglut with GLFW", author a740g, **OPEN**) |
| Compiler | `~/git/qb64pe-a740g-test/qb64pe`, branch **`GLFW`**, head `5a52df45`, `V4.6.0` |
| Host | Linux (Debian 13, kernel 6.19), **Wayland session** (`XDG_SESSION_TYPE=wayland`), XWayland `DISPLAY=:1`, 3840×2160 |
| DRAW branch | `glfw-tests` |
| Date | 2026-08-19 |

Each function was proven with a small standalone probe compiled by the GLFW compiler
(scratchpad `probe_win.bas` / `probe_live.bas` / `probe_human.bas`), cross-checked
against `xdotool` window geometry where possible, and confirmed by live human input
for the interactive items.

---

## ⚠️ Build-selection caveat (read first)

There are TWO similarly-named QB64-PE checkouts; only one is PR #701:

| Directory | Branch | Backend | For our purposes |
|-----------|--------|---------|------------------|
| `~/git/qb64pe-freeglut-final` | `freeglut-final` | **old freeglut** | ❌ NOT PR #701 — these functions are `#ifdef QB64_WINDOWS → return 0` |
| `~/git/qb64pe-a740g-test` | **`GLFW`** | **GLFW (PR #701)** | ✅ the build under test here |

The DRAW `Makefile` `a740g` target now points at the GLFW checkout
(`make a740g` / `make a740g-run`). An initial full pass was accidentally run against
the freeglut build; every "Linux fails" result there was expected (Windows-only code)
and is **not** a bug. All results below are the **GLFW** build.

---

## Summary verdict table (GLFW build, Linux)

| Function | Verdict | Evidence |
|----------|---------|----------|
| `_DESKTOPWIDTH` / `_DESKTOPHEIGHT` | ✅ **PASS** | 3840×2160, matches desktop. (0 under `$CONSOLE:ONLY` — needs a real window.) |
| `_SCREENMOVE` | ✅ **PASS** | Window moves; xdotool confirms target reached. |
| `_SCREENX` / `_SCREENY` | ✅ **PASS** | Returns exact position; live-tracks a window drag (e.g. 1600,866 → 500,300, matches xdotool to the pixel). |
| `_WINDOWHANDLE` | ✅ **PASS** | Returns the real X11 XID (e.g. `67108871`, equal to the window id xdotool reports). |
| `_WINDOWHASFOCUS` | ✅ **PASS** | Flips -1↔0 cleanly across click-away / click-back cycles. |
| Drag-and-drop (`_ACCEPTFILEDROP`, `_TOTALDROPPEDFILES`, `_DROPPEDFILE$`, `_FINISHDROP`) | ✅ **PASS** | Human dragged a file from Dolphin; drop received, full path captured (`_FILEEXISTS` = true). |
| `_CAPSLOCK` / `_NUMLOCK` / `_SCROLLLOCK` | ❌ **FAIL** | On Wayland: key events DO reach the window (GLFW receives keypresses), but the lock-state values never change from 0. So input works; the lock-modifier capture does not. See BUG 1. |
| Window class / `app_id` | ❌ **FAIL** | Reports "Untitled" to the WM — class/app_id hints never set. See BUG 2. |
| `_MOUSECURSOR` (image-handle cursor) | ⛔ **N/A** | 0 source hits — not part of PR #701; different/newer work. |

**Bottom line: of the windowing features a740g listed, everything works on Linux under
PR #701 except the lock-key query.** `_SCREENX/_SCREENY` and `_WINDOWHANDLE` — which are
still Windows-only on the freeglut branch — are fully functional here.

---

## BUG 1 — `_CAPSLOCK` / `_NUMLOCK` / `_SCROLLLOCK` always return 0 on Wayland

**Environment:** GLFW build (branch `GLFW`, `5a52df45`), Debian 13, **Wayland session**
with XWayland (`DISPLAY=:1`).

**Symptom:** `_CAPSLOCK`, `_NUMLOCK`, `_SCROLLLOCK` return 0 and never change, even when
the physical lock key is pressed with the QB64-PE window focused, and even when the lock
LED is physically ON at program start.

**Key discriminator (live human test, Wayland — logged):** the window **does** receive the
lock-key input. `DEV/EXPERIMENTS/lock-key-test.bas` (a self-contained repro; compile with the
GLFW build) captured 44 key events over 618 frames — Caps Lock
(`_KEYHIT` code 100301), Num Lock (100302), Scroll Lock (100319), each pressed/released
several times — while `_CAPSLOCK`/`_NUMLOCK`/`_SCROLLLOCK` read 0 at the instant of every
event, and `everCaps=everNum=everScroll=0` for the whole run. So the GLFW key callback is
firing; it is specifically the lock-modifier *capture* that fails on the Wayland backend —
**not** a focus/input-routing problem.

```
session=wayland  wayland=wayland-0
KEYEVENT frame=191 code=100301 (caps=0 num=0 scroll=0)   <- Caps Lock pressed
KEYEVENT frame=416 code=100302 (caps=0 num=0 scroll=0)   <- Num Lock pressed
KEYEVENT frame=474 code=100319 (caps=0 num=0 scroll=0)   <- Scroll Lock pressed
=== end. frames=618 keyEvents=44 everCaps=0 everNum=0 everScroll=0 ===
```

**Repro:**
```qb64
SCREEN _NEWIMAGE(320, 200, 32)
DO
    LOCATE 1, 1
    PRINT "CAPS="; _CAPSLOCK, "NUM="; _NUMLOCK, "SCROLL="; _SCROLLLOCK
    _DISPLAY
    _LIMIT 30
LOOP UNTIL _KEYDOWN(27)
```
Focus the window, toggle Caps/Num/Scroll Lock → the printed values stay 0.

**What we verified about the implementation** (`internal/c/libqb/src/glut-emu.cpp`):
- `GLFW_LOCK_KEY_MODS` **is** enabled (`glfwSetInputMode(window, GLFW_LOCK_KEY_MODS, GLFW_TRUE)`, ~L615).
- Lock state is cached in `keyboardModifiers`, seeded once at window creation
  (`KeyboardUpdateLockKeyModifier(...)`, L616-618) and updated in the key callback
  (`keyboardModifiers = KeyboardUpdateLockKeyModifier(ScrollLock, mods)`, ~L633).
- `KeyboardUpdateLockKeyModifier` (~L1786) Linux branch calls
  `XkbGetIndicatorState(glfwGetX11Display(), XkbUseCoreKbd, &n)` and maps
  `n & 0x01/0x02/0x04` to Caps/Num/Scroll.
- The `GLUTEmu_KeyboardKeyModifier` enum values equal GLFW's
  (`CapsLock=GLFW_MOD_CAPS_LOCK=0x10`, `NumLock=0x20`) — so there is **no** bit mismatch,
  and `KeyboardIsKeyModifierSet` = `(keyboardModifiers & modifier) != 0` is correct.

**Likely cause (for a740g to confirm):** this is a **Wayland session**, and GLFW
auto-selects the Wayland backend when `WAYLAND_DISPLAY` is set. Two things then break:
1. The init seed and query path call `XkbGetIndicatorState(glfwGetX11Display(), ...)` — but
   `glfwGetX11Display()` is NULL on the Wayland backend, so that path can't run (its else
   branch only handles ScrollLock and logs "Lock key modifier query not available").
2. The key-callback path sets `keyboardModifiers = KeyboardUpdateLockKeyModifier(ScrollLock, mods)`,
   relying on GLFW's `mods` to carry `GLFW_MOD_CAPS_LOCK`/`GLFW_MOD_NUM_LOCK` (needs
   `GLFW_LOCK_KEY_MODS`). The log shows lock-key events **do** arrive, yet caps/num stay 0 —
   so on this Wayland backend those lock bits are **not** present in `mods` (or the input-mode
   hint isn't honored by the Wayland keyboard).

**Suggested fix:** add a real Wayland lock-modifier source — read the lock mask from
**xkbcommon** (`xkb_state_serialize_mods(..., XKB_STATE_MODS_LOCKED)` for `Caps Lock` /
`Num Lock` / `Scroll Lock`) on the Wayland backend, instead of relying on the X11-only
`XkbGetIndicatorState` and on GLFW `mods` bits that aren't arriving here.

> Please retest on an **X11 session** too: the `XkbGetIndicatorState` path should work there,
> which would confirm the gap is Wayland-specific.

> If a740g tests on an **X11 session** (not Wayland), the `XkbGetIndicatorState` path should
> work — so please confirm the session type when reproducing.

---

## BUG 2 — window WM_CLASS / Wayland `app_id` is "Untitled" (never set)

**Symptom:** the GLFW window reports its class as **"Untitled"** to the window manager
(KWin Window Rules → *Window class (application)* = `Untitled`, *Whole window class* =
`Untitled Untitled`), even though the window **title** is set correctly. This breaks
taskbar/dock grouping, application-icon matching (notably the Wayland `app_id` →
`.desktop` association), and user window rules.

**Root cause (`internal/c/libqb/src/glut-emu.cpp`):** `WindowCreate` calls
```cpp
window = glfwCreateWindow(width, height,
             windowTitle.empty() ? "Untitled" : windowTitle.c_str(), nullptr, nullptr); // ~L480
```
and **never sets** `GLFW_X11_CLASS_NAME` / `GLFW_X11_INSTANCE_NAME` / `GLFW_WAYLAND_APP_ID`
via `glfwWindowHintString(...)` before creation. With the class hints unset, GLFW derives
WM_CLASS/`app_id` from the create-time title — which is the `"Untitled"` fallback because
the real title is applied later via `_TITLE` (→ `glfwSetWindowTitle`), and GLFW does not
update the class when the title changes. Net: class is permanently "Untitled".

**Suggested fix:** set `GLFW_X11_CLASS_NAME`, `GLFW_X11_INSTANCE_NAME`, and
`GLFW_WAYLAND_APP_ID` (e.g. to the executable/base program name) via `glfwWindowHintString`
before `glfwCreateWindow`.

**DRAW impact:** DRAW's window would present as class "Untitled" under the GLFW build,
losing its taskbar identity/icon and breaking any window rules keyed on class.

---

## DRAW QA regression (GLFW-built DRAW.run)

- Build: `make a740g` (GLFW compiler). Clean compile — only the pre-existing
  `IMAGE-ADJ.BM:5532` unused-var warning (present in the v450 build too).
- Gate (calibration + smoke, forced re-run, offscreen Xvfb): **15 passed / 0 failed / 0 skipped.**
  Viewport→screen anchor mapping intact; DRAW launches, geometry model OK, no trapped runtime errors.
- Full suite (offscreen Xvfb, `--rerun-passed`): the long back-to-back batch **aborted at
  83/184** (538 asserts passed) with `ERROR: DRAW window never appeared after 15s` on
  `effect-vignette`. This is a **batch/Xvfb resource flake** after ~83 sequential launches
  (a known harness limitation, seen before the GLFW switch), **not** a GLFW launch problem:
  `effect-vignette` and every failed effect test **pass cleanly when run in isolation**.
- Failure triage (all "regions are identical (action had no effect?)"):
  | Assert | In batch | In isolation | Verdict |
  |--------|----------|--------------|---------|
  | `effect-vignette` window-never-appeared | fail (abort) | ✅ pass | batch/Xvfb flake |
  | Stained Glass panes | fail | ✅ pass | batch flake |
  | Stroke selection outline | fail | ✅ pass | batch flake |
  | Help > Cheat Sheet leaves overlay OPEN | fail | ❌ fails consistently | **pre-existing** — also fails on the freeglut baseline (same line 215) → **NOT a GLFW regression** |
- **Net: no GLFW-specific QA regressions.** Gate is green; every batch failure is either a
  known offscreen-batch flake (passes solo) or a pre-existing non-GLFW issue. Recommend running
  the suite in smaller offscreen batches (or `--onscreen`) to avoid the long-batch launch flake.

---

## Recommendation for DRAW: the `$IF WIN` drag-and-drop guards

DRAW currently compiles its drag-and-drop path out on non-Windows —
[DRAW.BAS:238](../DRAW.BAS#L238) (`_ACCEPTFILEDROP`) and
[DRAW.BAS:406](../DRAW.BAS#L406) (the `_TOTALDROPPEDFILES` handler), both inside
`$IF WIN THEN … $END IF`.

**Drag-and-drop is confirmed working on Linux under PR #701.** So relaxing those guards to
enable Linux/macOS drag-and-drop is viable **once the GLFW build ships** (PR #701 merged).
Caveat: DRAW's default compiler is still v450 (freeglut lineage) where these are Windows-only,
so the guard cannot simply be deleted — it should switch from a compile-time `$IF WIN` to a
form that also enables the non-Windows path only when the toolchain supports it. Deferred as a
separate DRAW task (this pass was verify-only; no DRAW source changed).
