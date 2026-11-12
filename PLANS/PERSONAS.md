# Personas: workflow buttons, Sprite / Scene workspaces, the ANIM menu split

PLANS/ANIMATION.md round 3, item 6 (2026-11-12). Rick's decision there: **workspaces are the
personas** (no rename). Workspaces already switch menus (ROOTS= / HIDE_ITEMS=), keys,
toolbars, panels and options; they ship Default, Current, Animate, Annotate and Simple; the
switcher is action 2400 (Ctrl+Shift+W) and the status bar shows a badge.

What is new:

1. **Workflow buttons** - one click to a persona.
2. **Sprite** and **Scene** workspaces.
3. **The ANIM menu split** - it is ~50 rows plus three flyouts that scroll.

## 1. Workflow buttons

Rick's note: "Put workflow buttons at the top of the toolbox (e.g. SPRITE | ANIMATE | EXPORT |
ANNOTATE), each slot set by the user to the workspace it switches to."

- **Where:** a strip at the top of the toolbox panel, above the tool buttons, inside the
  toolbox's dock rect (docked left / right or floating, it moves with the toolbox). The tool
  buttons start below it: `TB_RECT_Y` moves down by the strip's height (`WF_height%`), so every
  existing hit test (they read `TB_SLOT_Y`) is unchanged.
- **Look:** text buttons in Tiny5 (the toolbox's command-tile font), two per row, as many rows
  as slots. The label is the workspace's `SHORT=` (new optional `[WORKSPACE]` key), else its
  NAME, upper case, cut to fit. The active workspace's button is lit (the active-tool colours).
- **Slots:** `WORKFLOW_BUTTONS=` in DRAW.cfg, a comma list of workspace ids, up to 8. Default
  `sprite,animate,scene,annotate`. A missing id draws a dim `?` button (its file was removed)
  and does nothing. `WORKFLOW_BUTTONS=` empty (or `NONE`) = no strip, no height.
- **Click:** switch to that workspace (`WS_switch_to`, same as the switcher). Click the lit
  one again = back to Default (Leave Workspace, 2404) - the strip is a toggle row, so Default
  never needs a slot of its own.
- **Right-click a button:** a popup - every workspace (the slot's one checked) to set the slot,
  then *Add a button*, *Remove this button*, *Hide workflow buttons*. Each change writes
  `WORKFLOW_BUTTONS` with `CONFIG_save` (global, not per workspace: the strip is how you leave a
  workspace, so a workspace must not be able to change it under you).
- **Workspaces can hide it:** `[OPTIONS] WORKFLOW_BUTTONS=NONE` (any cfg key works there and the
  overlay never saves it). None of the shipped ones do.
- **Commands:** *View > Workflow Buttons* (checkbox; hides / shows the strip, keeps the list)
  and *Workflow Button 1..8* palette commands (switch like a click) so keys can be bound.
- **QA dump:** `WF n y h active ids` + `WFB i x y w h id label` per button.

Why not a dock panel of its own: the toolbox column already reflows around the organizer and
drawer; a separate panel would need a DP_ id, layout rules, a handle and its own move / float.
Inside the toolbox it docks, floats and hides with the tools, which is where Rick asked for it.

## 2. Sprite and Scene workspaces

| | Sprite | Animate (ships) | Scene |
| --- | --- | --- | --- |
| For | one small character / object, its frames | frame-by-frame drawing | putting clips together over time |
| View | sheet view, frame grid, Preview shows the frame | lightbox 3 panes, onion skin | Big Frame + X-sheet (1 pane), no onion skin |
| Panels | Preview, Animation panel, Drawer (AnimBrush bins), layers | Animation panel, layers | Animation panel, layers, Drawer |
| Hidden | char map, 3D colour, browser, Swatches | char map, 3D colour, browser | char map, 3D colour, browser, Swatches |
| Menus | all but AI / AUDIO / EFFECTS | all | all |
| Start | Brush tool | - | Move tool |

Scene's options: `LIGHTBOX=1`, `LIGHTBOX_PANES=1`, `XSHEET=1`, `ONION_SKIN=0`, `FRAME_GRID=1`.
Sprite's: `LIGHTBOX=0`, `FRAME_GRID=1`, `PREVIEW_SHOWS_FRAME=1`, `ONION_SKIN=0`.

Fix found while planning: `[MENUS] ROOTS=` does not know `ANIM` (WS_apply_menus' list of roots
predates the ANIM menu), so a ROOTS list naming only ANIM is ignored as "names no menu".

## 3. The ANIM menu split

Today: Animation Panel, frame navigation + Play, 6 frame ops, 3 reorder, 5 copy / paste rows,
the frame grid / detect / import rows, 9 view toggles, 8 reference / link / tag / note rows,
AnimBrush ›, Move Brush ›, Clip Layer › (~35 rows, scrolls), AnimPaint, Soundtrack, Full-Screen
Preview, 7 export rows. About 50 rows at the top level.

After (top level ~14 rows, every flyout fits a 768 px window):

```
ANIMATION PANEL
---
FIRST / PREVIOUS / NEXT / LAST FRAME, PLAY        (unchanged: the most used)
---
FRAMES ›        add, add blank, insert before / after, duplicate, delete | earlier, later,
                reverse | copy, cut, paste as new, paste over, replace FG with BG
SET UP ›        frame grid, detect frames, create frames from grid, import PNG sequence |
                reference layer, layer same on every frame, link / unlink cells |
                tag frames, delete tag, frame note, clear note
VIEW ›          lightbox, panes, X-sheet, Big Frame + X-sheet, onion skin, onion tint,
                clip strokes (lightbox / sheet), preview shows frame
---
ANIMBRUSH ›     (unchanged)
MOVE BRUSH ›    (unchanged)
CLIP LAYER ›    place, make, bake, update x2, edit cels x3 | sources, remove unused |
                mode / flip rows
CLIP LANES ›    key, delete key, clear lane, clear all, copy, paste, tint toward FG
CLIP SOUNDS ›   on this cel, at start, each start over, remove
ANIMPAINT
SOUNDTRACK...
REMOVE SOUNDTRACK
---
FULL-SCREEN PREVIEW
EXPORT ›        GIF, APNG, PNG sequence, BAS player x2, sprite sheet, export scale
```

Every command keeps its action id, its palette name and its hotkey. Only `anim-menu.sh` clicks
ANIM rows by position; it moves to the new rows.

## Questions (answered as recommended, for the field kit)

- **Q1** Clicking the lit button goes back to Default. (Or: does nothing.)
- **Q2** The strip is global (DRAW.cfg), not per workspace.
- **Q3** Default buttons: SPRITE, ANIMATE, SCENE, ANNOTATE. Rick's example had EXPORT: there is
  no Export workspace; one could show the Preview and put the export commands on the edit bar.
- **Q4** Sprite and Scene contents (the table above).
- **Q5** The ANIM menu groups and names above.
