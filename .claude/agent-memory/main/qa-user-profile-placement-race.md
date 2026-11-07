---
name: qa-user-profile-placement-race
description: [Linux] user-profile QA runs (1152x712@3 on 3840x2160 Xvfb) sometimes abort on the geometry check - window at 384,216, 3456x1944; a startup race, rerun
metadata:
  type: project
---

[Linux] With `QA_USER_PROFILE=1 QA_USER_SCREEN=1152x712@3 QA_XVFB_RES=3840x2160`, a test can
abort before its first check: "window geometry does not match ... window = 3456x1944,
expected = 3456x2136", window position 384,216. DRAW's `_SCREENMOVE _MIDDLE` centred the
window at an earlier size (1024x576 @3) before the final resize landed, so the bottom ran
off the 2160-row screen and got cut. A good run places at 192,24. Seen 2026-11-07 on
dock-seams-left, on both the old and the new build (3 bad of 5), so it is not from a
change under test - rerun until it places. Not fixed (SCREEN.BM / DRAW.BAS startup order).

**Why:** cost a few reruns and a false "my change moved the window" lead.
**How to apply:** on that abort, rerun; only investigate if it happens on every run.
Related: [[feedback-test-like-the-user]].
