---
name: theme-edit-everything-editable
description: Theme Edit rule from Rick - anything visible on screen must be inspectable and editable, whatever state / customization produced it
metadata:
  type: feedback
---

In Theme Edit mode **everything Rick can see on screen must be pickable, in the tree, and
editable** - including things that only exist because of a customization (Customize Toolbars
command slots, workspace layouts) and art the theme does not have a file for yet. Rick
2026-11-21: "remember we need to be able to edit anything we see on the screen my man", after the
toolbox's command slots (camera / plus / AA) were not inspectable.

**Why:** the inspector is only useful if it never has blind spots; a theme author hits exactly
the customized / fallback cases first.

**How to apply:**
- A new on-screen part gets a UIP node - picking, reveal, screen-order IMAGES and hover outline
  all come from the tree (`THEMEED_node_at%`), never from a per-panel hit test. Either compute it
  in `THEMEED_tree_extra` (`THEMEED_kid%`) or have its draw code call
  `IF THEMEED.started THEN THEMEED_seen _DEST, pkey, nkey, label, x, y, w, h, fls` - the box is
  mapped to the window from the image it was drawn into. Details: .claude/instructions/draw-theme-edit.md.
- Art that falls back (DEFAULT's, a bar icon, a text tile) still lists the theme-path file; EDIT
  on a missing file makes it (`THEMEED_seed_make%`: DEFAULT copy, else what is drawn now).
- Covered 2026-11-21 (Rick: "status bar and color strip too all of it"): menus + popups and their
  items, status bar parts, colour chips, layer rows + icons, organizer, drawer bins, workflow /
  selection / text bars, flyouts, floating-panel widgets. Same day (Rick: "a button to EDIT
  DIALOGS"): every DIALOG_CTX modal, via hooks in the DIALOG_* helpers + the inspector's DIALOGS
  button. Still blind: GJ_LIB message / input boxes + file dialog, GJ_LIB-rendered window bodies (Mixer / ACP / 3D / Browser), Swatches
  grid, Pen graph, Customize Toolbars rows, dock tabs, command palette rows, menu flyouts.
  See [[theme-edit-uikit]].
