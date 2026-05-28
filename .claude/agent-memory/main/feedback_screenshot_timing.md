---
name: feedback-screenshot-timing
description: When taking screenshots of DRAW after sending xdotool keystrokes, wait long enough for the next render frame AND beware that file size alone is a misleading change-indicator. Compare visible content (or status-bar text) rather than `ls -l` file sizes.
metadata:
  type: feedback
---

When using `xdotool` to send keys + `import -window` (ImageMagick) to
screenshot DRAW for verification, two failure modes are easy to fall into:

1. **Race against the render frame.** DRAW idles at ~15 FPS (~67ms/frame)
   when nothing is happening. After `xdotool keyup`, the keystroke goes
   through detection → dispatch → action → SCENE_DIRTY → next render.
   That can take 2–3 frames (~200ms). A `sleep 0.3` after the last keyup
   is too tight; the screenshot can capture the pre-action frame. Use at
   least `sleep 1.0`, ideally `sleep 1.5`, before `import -window`.

2. **File size is a noisy proxy for "did anything change."** PNG file
   size is dominated by compressibility of the pixel data. A canvas at
   500% (showing a tile of high-detail pixel art) and a canvas at
   fit-zoom (showing the whole image at small scale) can both compress
   to roughly the same size — purely by coincidence of detail density.
   Two zoom screenshots both reading "441k" is NOT proof that zoom
   didn't fire; it just means PNG-zlib hit similar ratios.

**Why:** Burned ~30 minutes during the render-coord overflow fix
chasing "Z+9 isn't working" because the post-fix screenshots were 441k
matching the pre-fix baseline. They were actually correct — just
happened to compress similarly. User confirmed the fix was working
audibly (zoom beep) before I would have noticed by reading file sizes.

**How to apply:**
- Sleep ≥1.0s after the final `keyup` before `import -window`.
- Don't `pkill` until at least 1s after the last screenshot.
- For zoom/pan verification, look for status-bar text differences
  (e.g. `Z:1600%`) or visible content differences in the screenshot
  itself — NOT the file size. Read the screenshot with the Read tool
  to inspect it visually.
- If the user mentions they can hear DRAW responding (beep, audio cue)
  but you see no visual change, trust the user's ears over your
  screenshot pipeline; the bug is most likely in the screenshot tooling,
  not the app.
- DRAW does not use QB64-PE's `_SAVEIMAGE` for the screenshot path;
  this guidance is about the external `xdotool` + `import` shell
  pipeline only. (If we ever add in-process screenshot, `_DISPLAY`
  before `_SAVEIMAGE` would be the in-process equivalent.)
