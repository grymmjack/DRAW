# Dock & panel fixes - hand verification, 2026-11-06

Verified by Rick on his own desktop (Linux, KDE, 3840x2160, UI_SCALE=3) in the
build of 62d18fb6, using the Field Kit checklist (one card per fix). Result:
**24 / 24 WORKS**.

| # | Check | Result | Commit | Automated test |
|---|-------|--------|--------|----------------|
| 1 | Layer rows take clicks when the layers are docked below another panel | WORKS | 764c9597 | dock-layers-row-clicks |
| 2 | Charmap under the toolbox column no longer wipes the panels above it | WORKS | 764c9597 | dock-charmap-stub |
| 3 | Dragging a layer out of the panel no longer deletes it | WORKS | 764c9597 | dock-layers-drag-below |
| 4 | Docked Browser stays inside its slot / band (also at a larger scale) | WORKS | e3b4a825 | dock-browser-min-size |
| 5 | No toolbox / organizer tooltips from a hidden panel | WORKS | e3b4a825 | dock-hidden-panel-hover |
| 6 | A hidden drawer stops answering the mouse | WORKS | e3b4a825 | dock-hidden-panel-hover |
| 7 | Edit / advanced bar scroll comes back when the bar grows | WORKS | e3b4a825 | dock-bar-scroll-grow |
| 8 | Charmap: last row reachable; page bar highlights no cell | WORKS | e3b4a825 | gui-charmap-scroll-range |
| 9 | Docked preview shows no resize cursors it can't do | WORKS | e3b4a825 | dock-preview-docked-cursor |
| 10 | Opacity bar works on layers inside a group | WORKS | e3b4a825 | (to write) |
| 11 | Nested collapsed groups: rows stay in place | WORKS | e3b4a825 | (to write) |
| 12 | Visibility swipe across groups and children | WORKS | e3b4a825 | (to write) |
| 13 | Toolbox top border when stacked under another panel | WORKS | e3b4a825 | (to write) |
| 14 | Browser wheel scroll shows at once | WORKS | 544cc834 | gui-browser-wheel-redraw |
| 15 | No growing gap under the toolbox with the charmap in its column | WORKS | 544cc834 | dock-toolbox-wide-column |
| 16 | Floating toolbox: window = its buttons; one row when wide | WORKS | 0d634b1d | dock-float-toolbox-fit |
| 17 | Each dock column resizes on its own (no ganging) | WORKS | 0d634b1d | dock-col-own-width |
| 18 | Tall 1-column drawer: more bins, no empty band | WORKS | 0d634b1d | dock-drawer-tall-stacked |
| 19 | Arrow over a floating panel's grip and frame | WORKS | 0d634b1d | dock-float-grip-cursor |
| 20 | Floating panels snap like the floating Browser | WORKS | 0d634b1d | dock-float-layers |
| 21 | Floating layers resize narrower than their docked width | WORKS | 0d634b1d | dock-float-layers |
| 22 | Floating layers: no doubled "Layers" title | WORKS | 0d634b1d | dock-float-layers |
| 23 | Docked preview drags out / right-clicks from its whole title bar | WORKS | 62d18fb6 | dock-handle-menus, user-dock-handle-menus |
| 24 | Docked layers: Float / Dock right-click menu (was not reproduced) | WORKS | - | dock-handle-menus |
