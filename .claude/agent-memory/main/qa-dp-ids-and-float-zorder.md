---
name: qa-dp-ids-and-float-zorder
description: QA tests must not hardcode DP_ panel ids (text bar then selection bar each shifted natives +1); dk_grab_point uses the WZ line for floating z-order
metadata:
  type: project
---
[Linux, 2026-11-17] Two QA-harness traps found in the xsheet-holds-lanes dock suite:

1. **DP_ ids shift.** DP_TEXTBAR = 9 was inserted before the native windows, so DP_PREVIEW went 9 -> 10
   (MIXER 11 ... SWATCH 17). Tests that hardcoded `DP_PREVIEW=9` / `pick_scale preview 9` failed with
   "DMENU open '-1' panel '10'" - DRAW was right. [2026-11-18] DP_SELBAR = 10 shifted them again:
   PREVIEW 11 ... SWATCH 18, DP_COUNT 18, WZ_TBED / WZ_COUNT 19, PSURF_N 10. [2026-11-18] DP_MYPAINT = 11
   shifted them once more: PREVIEW 12 ... SWATCH 19, DP_COUNT 19, WZ 20, PSURF_N 11 (workspace-recall-all.sh
   still had `pick_scale preview 10` - now read from DOCK.BI). [2026-11-22] DP_HISTORY = 14 (History palette) shifted them again:
   PREVIEW 15 ... SWATCH 22, DP_COUNT 22, WZ_TBED / WZ_COUNT 23, PSURF_N 14, REGION_HISTORY 39. A new dock panel
   must also be placed in DOCK_build_default (stock layout), not only DOCK_adopt_new_panels (custom trees) - it
   showed as P shown=-1 slot 0 until it was. Same day DP_ACTIONS = 15 (Actions palette): PREVIEW 16 ... SWATCH 23,
   DP_COUNT 23, WZ 24, PSURF_N 15, REGION_ACTIONS 40. Read the id from GUI/DOCK.BI instead:
   `awk '$1=="CONST" && $2=="DP_PREVIEW" {print $4; exit}' "$DRAW_ROOT/GUI/DOCK.BI"`.
2. **Floating windows at one spot.** Native windows floated to the same default rect (140,12) cover
   each other's title bars; dk_grab_point's coverage check used to count every other window and so
   said "has no handle to grab". It now (QA/dock-lib.sh dk_float_rects FLOATONLY + dk_wz_front) counts,
   for a floating panel, only windows IN FRONT of it per the dump's `WZ` line (front to back, WZ
   names: mixer / advcp / cs3d / anim map to colormixer / advcolorpicker / colorspace3d / animation).
   A test that grabs several floating windows should spread them (cfg *_X / *_Y keys) - see
   dock-windows-combine.sh.

**Why:** both looked like DRAW regressions and cost a suite cycle each.
**How to apply:** a "no handle to grab" / wrong-panel-menu failure: check the dump's WZ / P / WIN lines
and the DP_ constants before touching DRAW. Related: [[qa-harness-toolkit]].
