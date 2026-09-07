---
name: adv-color-picker-feature
description: Advanced Color Picker (Krita-style) feature — phased plan, architecture, and open requirements
metadata:
  type: project
---

Building a Krita-style **Advanced Color Selector** into DRAW (user request 2026-09-07). User pasted Krita screenshots showing the docker + its config tabs: Color Selector, Behavior, Shade Selector, Color History, Colors from Image.

**Architecture (user-directed):** a standalone library widget `QB64_GJ_ADV_COLOR_PICKER` in the `includes/QB64_GJ_LIB` submodule (sibling to the `COLOR_PICKER`/CP module), wrapped by a DRAW floating panel `GUI/ADV-COLOR-PICKER.BI/BM` — exactly how `COLOR-MIXER` wraps CP. Widget files: `ADV_COLOR_PICKER/ACP-TYPES.BI`, `ACP-CORE.BM`, leader `ADV-COLOR-PICKER.BI/BM`, plus `ACP-TEST.BAS` (interactive) and `ACP-PROBE.BAS` (headless logic checks). DRAW includes the sub-files directly (not the leaders), per the submodule convention.

**Naming:** menu + command labels are "ADVANCED COLOR PICKER" (user OK'd; distinct from "COLOR MIXER"). Action id **2023**. Region `REGION_ADV_COLOR_PICKER = 28` (20 collided with PIXEL_COACH — regions run past TOOLTIP=19 up to 27). Toggle entry points: View menu, **Ctrl+Shift+M** (INPUT.BM dispatched binding, keycode 109 + CTRL+SHIFT), and **middle-click the Color Mixer organizer button** (ORG_COLOR_MIXER in ORGANIZER_handle_middle_click%).

**Phases:** 1 = hue ring + SV triangle, HSV (DONE, submodule branch `feat/adv-color-picker`; triangle defined in (S,V) space via barycentric so pick↔marker are exact inverses). 2 = DRAW floating panel + entry points (branch `feat/adv-color-picker-panel`). 3 = color models HSV/HSL/HSI/HSY. 4 = Shade Selector (delta-shifted patch rows). 5 = Color History + Colors-from-Image. 6 = Behavior/settings + polish.

**Standing requirement:** ALL ACP configuration must live in DRAW's **Settings dialog** (mirroring Krita's config tabs), added incrementally as each phase introduces real options — NOT a separate config panel. See [[settings-three-doc-paths]] and gotcha #15 style discipline for any new state.

**FG/BG convention (standing, applies to EVERY color chip built here):** LEFT-click/drag = foreground, RIGHT-click/drag = background. On the wheel: right-drag the ring = BG hue in place, right-click the triangle = BG saturation/value. Implemented in the wrapper via `ADVCP.editTarget%` (0=FG,1=BG): a right-press loads the current BG into the widget so the ring/triangle edit BG; on right-release the wheel reverts to showing FG. `ADVCP_sync_from_paint` skips while editTarget=1. The widget (ACP) stays color-agnostic — only the DRAW wrapper knows FG vs BG. Apply the same left=FG/right=BG rule to shade-selector patches, history chips, colors-from-image, etc.

**Makefile:** already depends on every .BI/.BM via a `find` (Makefile lines ~87-103), so include-only edits DO trigger rebuilds. A stale "Nothing to be done" only happens if you edit a source WHILE a build is mid-flight (output ends up newer than the edit). No Makefile change needed.
