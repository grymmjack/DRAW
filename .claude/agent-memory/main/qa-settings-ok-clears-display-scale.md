---
name: qa-settings-ok-clears-display-scale
description: In QA, Settings OK/Apply clears the harness's pinned DISPLAY_SCALE / TOOLBAR_SCALE, so the window rescales and later clicks miss
metadata:
  type: reference
---

`SETTINGS_apply_shadow` (GUI/SETTINGS.BM) zeroes `CFG.DISPLAY_SCALE%` and `CFG.TOOLBAR_SCALE_OVR%`
on OK / Apply (they are legacy overrides; UI_SCALE is the master). The qa-harness DRAW adapter
pins `DISPLAY_SCALE=2 TOOLBAR_SCALE=2`, so after OK in a test DRAW auto-detects the scale on
the big Xvfb: the window rescales, `_abs()` maps clicks with the wrong scale (they land low:
a spinner's ENTER VALUE box opened instead of a dropdown) and panel widths / Autos change.
Do every click before OK; after it, only read dumps. Seen in panel-scale-set-all.sh
(2026-11-22) [Linux, Xvfb]. Related: [[one-local-qa-run-per-checkout]] (also bit that day:
a second run in the same checkout killed the first's DRAW and deleted its dump).
