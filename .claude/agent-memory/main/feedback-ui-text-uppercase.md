---
name: feedback-ui-text-uppercase
description: Every UI string DRAW shows (panels, popup/dropdown menus, settings, sliders, checkboxes, buttons, titles, tabs) is UPPERCASE - never Proper Case; user data / file names keep their case
metadata:
  type: feedback
---

All text DRAW draws in its own UI is UPPERCASE: panel titles + dock tab strips, floating
window titles, popup menus (POPUP_MENU), dropdowns, Settings tabs / labels / sliders /
checkboxes / buttons / text-box captions, dialog titles. Never Proper Case.
Exception: user data where case matters - file names / paths, layer names, preset names
the user typed? (display only is fine), typed text values, hex values.

**Why:** Rick 2026-11-17: "it looks a LOT better that way"; the menu bar was already all caps
and the docked strips / popups / Settings in Proper Case looked inconsistent.

**How to apply:** uppercase at DRAW's draw site (`UCASE$(label)` in the renderer AND in
the matching width measurement), not in the stored strings - QA dumps and tests match the
stored labels (dk_menu_has, DMENUR, command palette names). New UI text: write it in caps
or route it through a renderer that applies UCASE$. Related: [[dock-close-boxes]].
