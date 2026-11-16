---
name: qa-toolbar-scale-pin-hides-ratios
description: QA (and the user-profile mode) pins TOOLBAR_SCALE, an override that bypasses the SCALE_RATIO_* values real users run with - scale bugs under default ratios never show in QA
metadata:
  type: project
---

The qa-harness DRAW adapter writes `TOOLBAR_SCALE=<scale>` into DRAW.qa.cfg (both the default profile and `QA_USER_SCREEN=WxH@S`). That becomes `CFG.TOOLBAR_SCALE_OVR%`, which `SCALE_resolve_one%` uses instead of `ROUND(master * SCALE_RATIO_*)`. Real users have `TOOLBAR_SCALE=0`, so their toolbar, preview, mixer-family scales come from the 0.5 ratios.

Shipped once (2026-11-10): the floating panels (Animation, Mixer, Pen, ADVCP, CS3D) drew at `ROUND(UI * 0.5)` window px - half the menus' size at UI 2, and no change between UI 1 and 2 - while every QA test saw them at full size. Fixed by doubling the mixer ratio in `SCALE_resolve_widgets`; test `QA/tests/dock-display-scale-ratios.sh` clears the pin with `TOOLBAR_SCALE=0` in QA-OPTIONS.

**Why:** a scale/size bug report from Rick that QA can't reproduce is likely this.
**How to apply:** for any scale-related test or repro, add `TOOLBAR_SCALE=0` to QA-OPTIONS (it beats the cfg pin; the geometry model only checks window/viewport). See [[qa-harness-toolkit]].
