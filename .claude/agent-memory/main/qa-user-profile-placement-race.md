---
name: qa-user-profile-placement-race
description: [Linux] user-profile QA (1152x712@3) aborts "window = 3456x1944" on a 3840x2160 Xvfb - DRAW caps its startup window at 90% of the desktop; use QA_XVFB_RES=3840x2400
metadata:
  type: project
---

[Linux] With `QA_USER_PROFILE=1 QA_USER_SCREEN=1152x712@3`, a 3840x2160 Xvfb makes DRAW start
with a 1152x648 viewport (window 3456x1944), and the harness refuses to run: "window geometry
does not match ... expected = 3456x2136". This is not a race. `SCREEN_init` (OUTPUT/SCREEN.BM,
"shrinking viewport height from 712 to 648") keeps the startup window within 90% of the desktop,
and 712 x 3 = 2136 is more than 90% of 2160 (1944). The DRAW log says so.

Use **`QA_XVFB_RES=3840x2400`** for user-profile runs. 90% of 2400 is 2160, so the window fits,
and the viewport and scale are still the user's (Geometry model OK: 3456x2136). Verified
2026-11-07: smoke 2/2 and anim-frame-grid 14/14.

An earlier version of this note blamed a startup centring race and said to rerun. Earlier on
2026-11-07 some 2160-tall runs did place at 3456x2136, and from about 16:00 every run aborted,
on old builds too. What changed was not found. The cap explains the abort either way.

**Why:** cost several reruns and two wrong leads (my change, then a race).
**How to apply:** run user-profile QA with QA_XVFB_RES=3840x2400. If it still aborts, read the
DRAW log for "shrinking viewport" before suspecting anything else.
Related: [[feedback-test-like-the-user]].
