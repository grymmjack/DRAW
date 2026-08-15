---
name: effects-last-effect-and-menu-geometry
description: Redo/Recall/Blend Last Effect feature, and how EFFECTS-menu layout changes break the QA open_effect helper
metadata:
  type: project
---

[Linux] Added 2026-08-15 (branch more-image-effects).

**Redo / Recall / Blend Last Effect** (Photoshop-style), pinned to the TOP of the
EFFECTS menu + a divider. Action ids **2350 (Redo), 2351 (Recall), 2352 (Blend)**.

⚠️ **Action-id collision the standard audit MISSES.** First shipped with ids
2300/2301/2302, which are `ANS_ACT_EXPORT` / `ANS_ACT_IMPORT` / `ANS_ACT_EXPORT_QUICK`
(`OUTPUT/FILE-ANS.BI`) — so Redo fired Export-ANSI, Recall fired Import-ANSI. Gotcha
#17's `grep '^        CASE [0-9]'` only catches LITERAL duplicates; export/ANSI/QB64
actions dispatch by **named CONSTANT** (`CASE ANS_ACT_EXPORT`), so a literal-vs-const
clash is invisible to it. Before allocating an effect id, ALSO grep the number across
`OUTPUT/*.BI` (`EXPORT_ACT_*`=2201-2216, `ANS_ACT_*`=2300-2302, `EXPORT_QB64_ACTION`
etc.). 2350-2359 were clear.
Hotkeys — the Photoshop F-scheme, in `INPUT/KEYBOARD.BM` next to the CRT Ctrl+Alt+O
block (direct `_KEYDOWN`, gotcha #6): **Ctrl+F = Redo, Ctrl+Alt+F = Recall,
Ctrl+Shift+F = Blend**. (Ctrl+Alt+E was already Merge Down — do not reuse.)

Mechanism (`GUI/IMAGE-ADJ.BM`, state in the .BI): `CMD_execute_action` sets
`FX_PENDING_ACTION` for effect ids 2001–2281; the three shared apply funcs call
`IMGADJ_capture_last_fx` (stores action id + label + layer + BEFORE/AFTER snapshots).
- **Recall** = `CMD_execute_action LAST_FX_ACTION` (re-opens the dialog).
- **Redo** = instant re-run for effects that stashed params via `IMGADJ_stash_fx`
  (Drop Shadow / Long Shadow / Outline / Grow — set `LAST_FX_REPLAYABLE`); any other
  effect falls back to re-opening its dialog. Add a `CASE` in `IMAGE_ADJ_redo_last`
  + an `IMGADJ_stash_fx` call in a dialog's OK branch to make it instant-replayable.
- **Blend/Fade** = `IMAGE_ADJ_blend_last`: opacity + 6 blend modes recomposite
  BEFORE↔AFTER live on the canvas (`SCREEN_render` inside the modal loop).
Test: `QA/tests/effect-redo-last.sh`.

⚠️ **QA menu-geometry coupling (bit me here).** `qa-harness` `adapters/draw/manifest.sh`
`open_effect <cat> <child>` clicks category/child rows by HARDCODED geometry. Adding
the 3 items + divider to the EFFECTS-menu top shifted every category down
**3*MENU_ITEM_HEIGHT(12) + MENU_DIVIDER_HEIGHT(5) = 41px** (added `top=41` to caty/childy),
AND the wide labels ("RECALL LAST EFFECT" + hotkeys) **widened the dropdown**, moving
each flyout RIGHT so the child click had to go from **x=490 → x=560**. Both constants
(`MENU_ITEM_HEIGHT`, `MENU_DIVIDER_HEIGHT`) live in `GUI/MENUBAR.BI`; dropdown width =
`MENU_SUB_PAD_LEFT + maxLabelW + MENU_SUB_HOTKEY_GAP + maxHotkeyW + MENU_SUB_PAD_RIGHT`
(font `_PRINTWIDTH`, MENUBAR.BM ~1071). Any future EFFECTS-menu row/label change needs
`open_effect` recalibrated. See [[effects-selection-as-shape]].
