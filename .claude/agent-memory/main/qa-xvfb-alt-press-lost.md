---
name: qa-xvfb-alt-press-lost
description: [Linux, Xvfb] a mouse PRESS made while Alt is held never reaches DRAW (alt_drag / with_mods alt do nothing); press first, then Alt, hold through the release
metadata:
  type: project
---

[Linux, observed 2026-11-15, Xvfb QA run, default profile 958x514@2x] `alt_drag` (= `with_mods alt
drag`) and `driver_input_key_hold down alt` + `drag` did NOTHING in DRAW: a log at the top of
MOUSE_process_frame showed MODIFIERS.alt% = -1 while Alt was held, but no B1 press at all - the
button-down was never delivered while Alt was down. A press made first, with Alt pressed mid-drag
and held through the release, arrives fine (the release is seen with alt = -1). Untested on the
user's real KDE desktop (there Alt+drag works - the user's own repro uses it) and on macOS/Windows.

**Why:** cost a debug round on move-tool-bugs-1115 (Alt+drag clone "did nothing"), and it looks
exactly like a DRAW bug.

**How to apply:** for an Alt+drag gesture under Xvfb use `mouse_down X Y; hover ...; raw_key down
alt; mouse_up; raw_key up alt` (as apron-multilayer-ops / move-tool-bugs-1115 do). For Alt+arrow
holds use `raw_key down alt` + `raw_key down Down; raw_key up Down` - not `key Down`. See
[[qa-driving-draw-reliably]], [[qa-harness-toolkit]].
