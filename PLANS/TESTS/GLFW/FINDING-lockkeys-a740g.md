# Finding (for a740g): lock-key reader is event-driven, not live — polling sees stale state on Linux

**One-liner:** On Linux, `_CAPSLOCK` / `_NUMLOCK` / `_SCROLLLOCK` (the **read**
functions) do not reflect the current OS lock state when a program *polls* them
in a loop. The cached state is only refreshed inside input-event callbacks, so a
poller never sees a lock toggle. Verified with the correct `value% = _CAPSLOCK`
read form, a physical keyboard, and OS ground-truth (`xset` + `/sys/class/leds`).

> This is a SEPARATE issue from the setter: `_CAPSLOCK ON|OFF|_TOGGLE` being
> Windows-only is by design and is not a bug. This finding is only about the
> **read** function.

## Environment

- **[Linux]** Debian 13, X11. Compiler: a740g PR (`~/git/qb64pe-a740g-test/qb64pe`).
- Untested on macOS/Windows.

## What was observed (validated)

Using `GLFW_CAPSLOCK_TEST` (reads `st% = _CAPSLOCK` every frame, counts changes):

1. Pressing the **physical Caps Lock** key (repeatedly) → the `value%` reading
   never changes; the change counter stays `0`. Same for Num Lock and Scroll Lock.
2. The OS lock state IS changing — independent ground truth on the same machine:
   - `xset q` → `Caps Lock: on/off` flips with the physical key.
   - `cat /sys/class/leds/input*::capslock/brightness` → flips `0`↔`1`.
3. Tapping other keys (e.g. spacebar) in the focused window does **not** refresh
   the reading either.

So the OS state changes, but the QB64 read function does not follow it while polling.

## Why (from a740g's own source)

`internal/c/libqb/src/glut-emu.cpp`, `KeyboardUpdateLockKeyModifier()` (the
function that calls `XkbGetIndicatorState(glfwGetX11Display(), XkbUseCoreKbd, &n)`
and folds bits `0x01`/`0x02`/`0x04` into `keyboardModifiers`, which is what the
`_CAPSLOCK` read returns). Its only call sites:

- **~line 1180** — window init (queries all three once at startup).
- **~line 1195** — inside the GLFW **key** callback (`glfwSetKeyCallback`).
- **~line 1519** — inside the GLFW **mouse-button** callback.

All post-init refreshes are **inside input-event callbacks** — there is no
per-frame / on-read refresh. So:

- A program that **polls** `_CAPSLOCK` (like `GLFW_CAPSLOCK_TEST`, and like DRAW)
  reads `keyboardModifiers`, which is only updated when an input event fires.
- Toggling a lock key changes the OS indicator state, but the cached
  `keyboardModifiers` is not re-queried, so the poll returns stale data.
- (Open sub-question for a740g: in this build even non-lock key events didn't
  refresh the Caps/Num reading — worth checking whether `GLFW_LOCK_KEY_MODS` is
  enabled so GLFW's `mods` actually carry the caps/num bits into the key callback.)

## Suggested fix direction

Make the read live: re-query `XkbGetIndicatorState` when `_CAPSLOCK`/`_NUMLOCK`/
`_SCROLLLOCK` is read (or refresh `keyboardModifiers` once per frame in the
display/idle pump), rather than only inside input-event callbacks. That way a
polling program reflects the current lock state without needing an input event.

## Reproduce

```bash
cd PLANS/TESTS/GLFW
make a740g-run TEST=CAPSLOCK     # press physical Caps Lock; value% never flips, counter stays 0
# meanwhile, in another terminal, confirm the OS state IS changing:
watch -n0.2 'xset q | grep -i "caps lock"; cat /sys/class/leds/input*::capslock/brightness'
```

## DRAW impact

DRAW does not read `_CAPSLOCK` at runtime, so no DRAW change is needed — this is
a QB64-PE keyword behavior question for the PR.
