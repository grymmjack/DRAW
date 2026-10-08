# Toolbar editor plan: customize the toolbox, edit bar and advanced bar

Status: **built** (2026-10-08, branch `toolbar-editor`, T1-T5). Implementation notes: `.claude/instructions/draw-toolbar-editor.md`; user docs: manual Ch. 22 "Customizing toolbars", SHORTCUTS.md "Customize Toolbars"; tests: `QA/tests/tbed-*.sh`.

As built, beyond the plan: menu-only commands (Paste in Place, Flip, ...) are offered too, named by their menu label; the window's lists are `BL()` lists for the bars and a working copy of `TOOLBAR_BUTTON_ORDER` for the toolbox; `--option WORKSPACES_DIR=` keeps the QA tests out of the user's workspaces folder.

## What Rick asked for

A visual editor like the toolbar customizers in other programs (Photoshop's
Edit Toolbar, Office's Customize, GIMP): every function on the left with its icon and
name, buttons in the middle to move them (→ ← ↑ ↓), and the toolbox / bars
on the right. Buttons can also be dragged around on the real toolbox and bars
to reorder, show or hide them.

## Decisions (Rick, 2026-10-08)

| Question | Answer |
| --- | --- |
| Saving in Default (no workspace) | **Always a workspace.** Customizing in Default saves into a workspace (it asks for a name the first time; a new workspace based on Default). DRAW.cfg keeps the stock layout. |
| Dragging on the real panels | **Only while the editor is open** (edit mode). Otherwise clicks behave as always. |
| Branch | New branch after #157 merged. |
| What can be placed | **Dividers / empty cells**, **any command as a button**, **move buttons between bars** (toolbox ↔ edit bar ↔ advanced bar). |
| Font | New UI text uses Tiny5 (the panels' font), not the 16px default. |

## What exists (survey 2026-10-08)

- **Toolbox** (`GUI/TOOLBAR`): `TOOLBAR_BUTTON_ORDER(slot)` -> `TB_*` (-1 = empty cell) + `TOOLBAR_BUTTON_TO_TOOL(slot)`; clicks select a tool (special cases: Save, Open, Export Selection, Smart Shapes flyout, Crop, Code). Icons in `GUI_TB().iHnd`; workspace `[TOOLBOX] BUTTONS=` names via `TOOLBAR_button_by_name%`.
- **Edit / advanced bars** (`GUI/EDITBAR`, `GUI/ADVANCEDBAR`): fixed tables (`EDIT_BAR_ITEMS(0..31)`, `ADV_BAR_ITEMS(0..29)`) of action ids + dividers; icons positional from THEME; only **visibility** can change (`EDITBAR_SHOW()`); tooltips keyed by slot.
- **Commands**: ~380 in `CMD_LIST` (name, hotkey, category, action id). No icons outside the bars.
- **Dialogs**: `DIALOG_CTX` + `SW_*` widgets are immediate-mode; the workspace configurator is a **blocking modal** loop; no reusable scrolling list.

## Design

### 1. One button model for all three panels
Each panel becomes an **ordered list of entries** `{kind, id}`:

| kind | id | click | icon |
| --- | --- | --- | --- |
| `TOOL` | `TB_*` | select the tool (today's toolbox behaviour, flyouts included) | toolbox icon |
| `CMD` | action id | `CMD_execute_action` | its bar icon if it has one, else a **text tile**: up to 3 letters of its name in Tiny5 on a button face |
| `DIV` | - | - | a divider (bars: new row; toolbox: a full empty row) |
| `GAP` | - | - | an empty cell |

- The toolbox keeps `TOOLBAR_BUTTON_ORDER` semantics (TOOL entries), plus CMD entries.
- The bars switch from the fixed tables to lists of entries. The fixed tables become their **default lists** and their **catalog of icons** (action id → icon file), so nothing looks different by default. Tooltips are keyed by entry (tool → its toolbox tip, command → its bar tip, else its command name + hotkey).
- A TOOL entry on a bar shows the toolbox icon at the bar's icon size; a CMD entry in the toolbox shows its icon (or text tile) in a toolbox cell.
- **Names in files:** the existing names (`move`, `undo`, `preview`, ...) stay; any other command is `cmd:<action id>` (e.g. `cmd:1702`); `-` gap, `|` divider. Old workspace files load unchanged.

### 2. The editor window
**View → Customize Toolbars…** (also the command palette, and right-click a toolbox / bar → Customize…).

A **non-modal floating window** (like the Color Mixer: drawn in the main loop, Tiny5 text, snaps, can't overlap), so the real panels stay live beside it:

```
Customize Toolbars                                             [x]
[ Toolbox | Edit Bar | Advanced Bar ]        saving into: Annotate *
┌ Available ──────────────────┐       ┌ Edit Bar ─────────────────┐
│ search: [________]          │  →    │ [ic] Undo          Ctrl+Z │
│ Tools                       │  ←    │ [ic] Redo          Ctrl+Y │
│  [ic] Spray            S    │  ↑    │ ──── divider ────         │
│ Commands > Edit             │  ↓    │ [ic] Copy          Ctrl+C │
│  [ic] Paste in Place        │ + ─   │ …                         │
│  [Tx] Flatten Image         │ + □   │                           │
└─────────────────────────────┘ Reset └───────────────────────────┘
                                          Columns: [2]   [Done]
```

- **Available**: every tool and every command (grouped by category, filterable by a search field), minus what the selected panel already shows; icon or text tile, name, hotkey.
- **Middle buttons**: → add (at the selection in the right list), ← remove, ↑ ↓ move, `+ ─` divider, `+ □` empty cell (toolbox), **Reset** to the panel's default.
- **Right list**: the panel's entries in order; select, drag to reorder, drag between the two lists. The tab is the panel; Columns per panel.
- Double-click an Available item adds it; Delete removes the selected entry.

### 3. Edit mode on the real panels (while the editor is open)
- Clicks on the toolbox / bars do not run anything; a press-and-drag moves a button:
  an **insertion line** shows where it lands in the same panel or another one (toolbox ↔ edit bar ↔ advanced bar); dropping it outside every panel (or on the Available list) removes it.
- Drag from the editor's Available list onto a panel to add it there.
- The selected entry is outlined on the panel and in the list (both views in sync); the panels redraw live.

### 4. Saving: always a workspace
- In a workspace: edits go to it (a user copy of a built-in), like the dock arrangement: `[TOOLBOX] BUTTONS=`, `[EDIT_BAR] BUTTONS=`, `[ADVANCED_BAR] BUTTONS=` (now ordered, with `cmd:<id>`, `|`, `-`).
- In Default: on the first change the editor asks for a name and creates a workspace based on Default, switches to it, and keeps editing it ("saving into: <name>").
- **Done** closes; changes are already saved (each change saves, like docking). **Reset** per panel restores the default list.

### 5. Persistence / compatibility
- `WS_apply_bars` reads ordered lists (unknown names logged and skipped, as now); a list with only known names in default order behaves as today's visibility filter.
- `WS_restore` puts the default lists back.
- The workspace configurator's Toolbox and Bars tabs keep working (checkboxes add/remove), with a button that opens the editor.

## Phases

| # | Phase | Shippable alone |
| --- | --- | --- |
| T1 | Bars become ordered entry lists (catalog + defaults), tooltips by entry; workspace lists ordered; `cmd:<id>` / `|` / `-` | Yes: same look; workspaces can reorder bars |
| T2 | Any command as a button (text tiles), tools on bars, commands in the toolbox | Yes (via workspace files) |
| T3 | The editor window (lists, middle buttons, search, tabs, columns), saving into a workspace (Default asks for a name) | Yes |
| T4 | Edit mode: drag on the real panels (reorder, between panels, remove, add from the list), insertion line, sync | Yes |
| T5 | Docs (manual, SHORTCUTS, draw-toolbar-editor.md), QA (editor + edit-mode drag tests on a layout dump), report | - |

## Risks

- Bar tooltips and icons are positional today: converting to entries must keep every default pixel-identical (baseline shots + `dock-baseline.sh`).
- Click routing in edit mode must not leak a tool click / command (UI_CHROME_CLICKED discipline; `.claude/instructions/draw-mouse.md`).
- Text tiles at small toolbox scales must stay legible (Tiny5 at 1x is 5px tall; a tile shows 1-3 letters).
