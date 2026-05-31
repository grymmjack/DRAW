# NOT a bug: xdotool can't test Ctrl+Alt+letter on a740g GLFW builds

> **Correction.** An earlier version of this file claimed a740g had a regression
> where `Ctrl+Alt+O` was broken. **That was wrong — it was an automation
> artifact.** Physical-keyboard testing (human + screenshot) shows `Ctrl+Alt+O`
> works correctly on a740g. The "swallow" only happens with `xdotool` synthetic
> input. **Do not report this to a740g as a bug.** Kept here so the dead end is
> documented and the QA harness limitation is recorded.

## What's actually true

**On a real keyboard, `Ctrl+Alt+O` works on a740g/GLFW.** With `GLFW_KEYCODE_TEST`
open, physically holding Ctrl+Alt and tapping O shows:

```
CTRL  = ON   [100305=n 100306=Y]
ALT   = ON   [100307=n 100308=Y]
O key : 111(o)=Y   79(O)=n   15(^O)=n
Ctrl+Alt+O FIRES (DRAW logic) = ON
```

i.e. the letter `o` is detected (`111=Y`) and the hotkey fires. So DRAW's
`Ctrl+Alt+O` (and the sibling Ctrl+Alt hotkeys) are fine on a740g with real input.

## The automation artifact

Driving the SAME scanner with `xdotool keydown ctrl alt o` (XTEST synthetic
input) gives a DIFFERENT result depending on the backend:

| Input method | Backend | `O` 111 detected? | Ctrl+Alt+O fires? |
|--------------|---------|:-----------------:|:-----------------:|
| **physical keyboard** | a740g (GLFW) | **Y** ✅ | **ON** ✅ |
| xdotool / XTEST | a740g (GLFW) | n ❌ | off ❌ |
| xdotool / XTEST | v450 (SDL2) | Y ✅ | ON ✅ |

So a740g's GLFW backend drops the *synthetic* (XTEST) letter event while Ctrl+Alt
are held, but handles *real* hardware scancodes correctly. SDL2 (v450) accepts
even the synthetic combo. Screenshots in `evidence/`:
- `a740g_ctrl-alt-o_XDOTOOL-ONLY-swallowed.png` — synthetic, `o` swallowed (misleading)
- `v450_ctrl-alt-o_WORKS.png` — synthetic on SDL2, `o` present
- `a740g_ctrl-o_works.png` — plain Ctrl+O fine under a740g

## Why it matters (QA harness limitation)

DRAW's automated QA harness (`QA/`) drives input with `xdotool` (XTEST). This
result means **the harness can produce false negatives for `Ctrl+Alt+letter`
hotkeys when DRAW is built with a740g/GLFW** — the synthetic letter never reaches
the program even though a real user's would. When testing Ctrl+Alt hotkeys on a
GLFW build, verify by hand (or note the harness can't cover them there). Plain
`Ctrl+letter` (Ctrl+Z/B/S) is unaffected even under xdotool.

## Open item (the original report)

The original symptom was "`Ctrl+Alt+O` doesn't trigger in DRAW built with a740g."
Since the scanner uses DRAW's exact detection logic and fires on a real keyboard,
either it's already working in DRAW now, or there's a DRAW-specific factor
(idle-frame timing, modifier latch, window focus). **Re-verify `Ctrl+Alt+O` in
DRAW itself with a real keyboard** before concluding anything.
