# Docking plan: Photoshop/GIMP-style panels

Status: **plan, design decided** (Rick answered the open questions on
2026-10-07, below). Not built yet. Written 2026-10-07 on branch
`workspace-flexible-chrome`, which ships the first step:
side docks with flexible widths and content that reflows.

## Goal

Panels you can arrange the way Photoshop, GIMP or Krita allow:
- dock a panel to the left or right edge, or between two docked panels;
- stack panels in one column, top to bottom, and drag the divider between them;
- put panels in the same spot as **tabs**;
- tear a panel off into a floating window, and dock a floating window back;
- save the whole arrangement in a workspace.

## Fixed rules (Rick, 2026-10-07)

- Only the **left and right** screen edges dock.
- The **menu bar** (and the text bar under it) is always on top.
- The **status bar and color strip** are always at the bottom.
- The everyday path is **arrange, then save** (View → Workspace → Save Current
  Layout As…). The configurator is for what can't be arranged by hand: toolbox
  buttons, menus, keys and starting options.

## Decisions (Rick, 2026-10-07)

| Question | Answer | What it means for the build |
| --- | --- | --- |
| Are the organizer and drawer separate panels? | **Yes** | The toolbox column becomes three panels (toolbox, organizer, drawer) in one column. Each can move, tab, float or hide on its own. Default keeps them stacked in today's order. |
| Can the thin edit and advanced bars share a column with wide panels? | **Yes** | A bar is an ordinary panel. In a wide column it reflows into more icon columns to fill the width (the column flow from this branch). A column's width is its own setting, not its narrowest panel's. |
| Do floating windows keep their look and gain a way to dock? | **Yes** | Title bar, snapping and no-overlap (`FPANEL_place`) stay as they are. Add a dock button to the title bar, and dragging the title bar over a dock target shows the drop preview. Docked, the window draws without its frame, under its slot's title or tab. |
| Collapsible panels that shrink to their title, like GIMP's? | **Yes** | A slot can collapse to its title strip: a chevron on the title, or double-click it. Its height share goes to the other slots in the column. Saved in `[DOCK]` as a `!` before the panel name (`!browser`). |

### Consequences

- **Title strips:** moving, tabbing and collapsing all need a handle. Docked slots get a thin title strip with the panel's name, a collapse chevron and a float button.
- **Default stays identical:** toolbox, organizer, drawer and the two bars render **chromeless** (no title strip) in the built-in Default layout, as today. Their handle appears only while the pointer is over the panel's top edge: a few pixels tall, drawn after `SkipToPointer:` so it doesn't dirty the scene cache. Their right-click menu also has Float, Collapse and Move to Left/Right.
- **P1 grows:** splitting the toolbox column into three panels is part of the panel contract. The organizer and drawer stop positioning themselves under the toolbar (`ORGANIZER_render tbPanelY2`, `DRAWER_layout` reading `ORGANIZER.panelY2%`).
- **The `[DOCK]` grammar** gains `!` for collapsed slots. Its width rule: `COLUMNS:n` snaps to toolbox button columns when the column holds the toolbox; otherwise it's `WIDTH:px`.

## Where things stand after this branch

| Piece | Today |
| --- | --- |
| Side docks | A fixed order on each side, outermost first: layers, toolbox, advanced bar, edit bar, character map. Each one's side is set by a `*_DOCK_EDGE` key. |
| Widths | Flexible. Drag a panel's inner edge (`GUI/DOCK-RESIZE`): toolbox and bar **columns**, layers **px**. Saved in the workspace, or in `DRAW.cfg` in Default. |
| Toolbox column | Toolbar, organizer and drawer reflow to the column width (`TOOLBAR_reflow`, `ORGANIZER_layout%`, `DRAWER_layout`). |
| Floating windows | A separate system: Preview, Color Mixer, Advanced Color Picker, 3D Color Space, Pen Pressure and Browser drag by their title bars. Their edges snap and they don't overlap (`GUI/FLOAT-PANEL`, `FPANEL_place`). They can't dock. |
| Layout code | `SCREEN_compute_layout` places the docks by hand, in a fixed order. |
| Hit testing | `REGION_set_bounds` / `REGION_hit_test%` (z-ordered), plus many `*_is_over_area%` checks spread through `INPUT/MOUSE.BM` and `GUI/POINTER.BM`. |

## Target model

```
 LEFT EDGE                                                   RIGHT EDGE
┌──────────┬────────┬───────────────────────────────┬────────┬──────────┐
│ column 1 │ col 2  │                               │ col 1  │ column 2 │
│┌────────┐│┌──────┐│                               │┌──────┐│┌────────┐│
││Layers  │││tools ││          canvas               ││edit  │││Preview ││
││        │││      ││                               ││bar   ││├────────┤│
│├────────┤││organ.││                               ││      │││Mixer|AC││ ← tabs
││Browser ││├──────┤│                               ││      ││└────────┘│
│└────────┘│││drawer│                               │└──────┘│          │
└──────────┴────────┴───────────────────────────────┴────────┴──────────┘
                     floating windows sit above all of this
```

- **Dock column:** a vertical strip on one edge. It has a width (columns or
  px, as now) and a list of **slots** from top to bottom.
- **Slot:** one rectangle in a column. It has a height share and one or more
  **panels**; with more than one, they show as tabs and one is active.
- **Panel:** anything that can live in a slot or float: layers, toolbox, organizer, drawer, edit bar, advanced bar, character map, preview, color mixer, advanced color picker, 3D color space, pen panel, browser.

### The panel contract (the real work)

Every panel must:
1. **Render into a rectangle it's given:** x, y, w, h.
2. **Hit-test inside that rectangle.**
3. **Report its sizes:** minimum, preferred, and a width step (column panels snap, px panels don't).
4. **Draw its own title or tab strip only when floating or tabbed.**

This branch already gives width freedom to the toolbox column and both bars.
Still to do:

| Panel | Missing for the contract |
| --- | --- |
| Layers | Assumes the full window height (`panelY% = 0` to the bottom bars). Needs a height. |
| Edit / advanced bar | Assume full height; already scroll, so a height is easy. |
| Organizer, drawer | Sit under the toolbar by position; must become panels in their own right, or stay part of a "Toolbox" panel (open question 1). |
| Character map | Width comes from its font cache; needs a rectangle. |
| Floating windows | Draw their own title bar and frame; need a "frameless" mode for docking. |

## Interaction

| Gesture | Result |
| --- | --- |
| Drag a column's inner edge | Resize, as now |
| Drag the divider between two slots | Move height between them |
| Drag a panel's title or tab | A drop preview shows where it will land |
| Drop on a screen edge | New column on that edge |
| Drop between two columns | New column there |
| Drop on a slot's top or bottom third | Split the slot (new slot above / below) |
| Drop on a slot's middle | Add it as a tab |
| Drop anywhere else | Float it |
| Double-click a floating title bar | Dock it back where it last docked |

The drop preview is a translucent rectangle drawn after `SkipToPointer:`, like
the other per-frame overlays, so it doesn't dirty the scene cache.

## Saving it

A `[DOCK]` section in workspace files replaces the `*_DOCK` keys. One line per
column, outermost first; slots separated by `|`, tabs by `+`, a `*` on the
active tab, and `@n` for a slot's height share:

```ini
[DOCK]
LEFT.1=WIDTH:150; layers@3 | browser@1
LEFT.2=COLUMNS:4; toolbox
RIGHT.1=COLUMNS:1; editbar
RIGHT.2=WIDTH:180; preview@1 | *colormixer+advcolorpicker@2

[FLOAT]
pen=640,120,220,300           ; x,y,w,h (viewport px)
```

- **Default** gets a built-in description that reproduces today's fixed order exactly, so nothing moves for anyone who never drags a panel.
- The existing `*_DOCK_EDGE`, `*_COLUMNS` and `LAYER_PANEL_WIDTH` keys are read as a fallback, so old configs and workspaces keep working.
- The workspace overlay's snapshot/restore covers the whole dock tree: leaving a workspace puts your own tree back.

## Code shape

- **New `GUI/DOCK` (layout engine):** the column/slot/panel tree, layout (`DOCK_layout` replaces the hand placement in `SCREEN_compute_layout`), and the `[DOCK]` parser and writer.
- **Panel registry:** per panel, a render, a hit test, sizes and a name. Dispatch through one `SELECT CASE` (QB64 has no function pointers).
- **Input:** each slot registers its own region (`REGION_TABLE_SIZE` is 64; enough, but count). The `*_is_over_area%` checks scattered through `MOUSE.BM` / `POINTER.BM` become "which panel is under the mouse" lookups. This is the riskiest part: those checks encode years of precedence fixes (`.claude/instructions/draw-zorder.md`, `draw-mouse.md`).
- **Rendering:** QB64 has no clip rectangle for `LINE` / `_PUTIMAGE` / `_PRINTSTRING`. Panels must stay inside their rectangle. A panel that can't is rendered into its own image, which is then `_PUTIMAGE`d into place (costs memory, but is the simplest to make correct).

## Phases

| # | Phase | Shippable alone |
| --- | --- | --- |
| P1 | Panel contract for layers, bars, character map, **organizer and drawer as their own panels** (render into a rect, hit-test inside it) | Yes: no visible change |
| P2 | Layout engine + `[DOCK]` reproducing today's layout exactly; old keys as fallback | Yes: same look, new engine |
| P3 | Slot dividers, and moving whole docked panels between columns / sides by drag | Yes |
| P4 | Tabs, and collapsing a slot to its title | Yes |
| P5 | Dock floating windows (dock button + drag the title onto a target; they keep their look while floating); float docked ones | Yes |
| P6 | Configurator Dock tab, Save Current Layout writes `[DOCK]`, manual, QA | With P3+ |

## Risks

- Hit-test precedence regressions: the biggest risk. Mitigate with `zorder-hit-targets.sh` and new region tests per phase.
- Auto-hide restore (`MOUSE_handle_ui_autohide_restore`), F11 and `Ctrl+Shift+Left/Right` all assume today's fixed panels.
- The workspace overlay snapshot (`WS_EL_*`, `WS_DK_*`) must grow into a tree snapshot.
- Small windows: the layout needs a "doesn't fit" rule (collapse slots to tabs, then hide the outermost column).
