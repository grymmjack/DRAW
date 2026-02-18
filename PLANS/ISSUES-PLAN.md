## Plan: Fix All DRAW ISSUES.md Items (Phased)

**TL;DR**: 46 issues across 7 categories, organized into 4 phases by priority (BUG → CHANGE → NEW FEATURE). Three critical action ID collision sets were discovered (319/320, 1501-1504) that make Rotate 90, Copy Merged, and Palette menu items broken or cross-wired. Phase 1 fixes show-stopper bugs, Phase 2 fixes remaining bugs, Phase 3 applies UI/UX changes, and Phase 4 implements new features. All required PNG assets already exist in DEFAULT. DRW format version bump (5→6) needed for grid type persistence.

---

### Phase 1: Critical Bugs (Action ID Collisions & Broken Dispatch)
*Difficulty: Medium | Files: 2 | Risk: High if not done first — multiple menu items silently do the wrong thing*

**Step 1.1** — Fix action ID collision 319/320 (Rotate 90 vs Copy Merged / Cut to New Layer)

The root cause: "COPY MERGED" (line 106) and "ROTATE 90 CW" (line 122) in MENUBAR.BM both register actionId 319. In COMMAND.BM, `CASE 319` maps to `CLIPBOARD_copy_merged`, making the Rotate 90 CW handler at COMMAND.BM unreachable. Same for 320.

- Assign new unique actionIds for Copy Merged and Cut to New Layer (e.g., **322** and **323**) in MENUBAR.BM
- Move the `CASE 319` handler at COMMAND.BM to `CASE 322` for `CLIPBOARD_copy_merged`
- Move the `CASE 320` handler at COMMAND.BM to `CASE 323` for Cut to New Layer
- Remove the duplicate `CASE 319` at COMMAND.BM and `CASE 320` at COMMAND.BM — consolidate rotate logic into the now-freed CASE 319/320
- Update `CMD_register` at COMMAND.BM to keep 319/320 for Rotate
- Add `CMD_register` entries for 322 ("Copy Merged") and 323 ("Cut to New Layer")
- Verify `COPY TO NEW LAYER` at MENUBAR.BM stays at 321 (no collision)

**Step 1.2** — Fix action ID collision 1501-1504 (Reference Image vs Palette menu)

Both MENUBAR.BM (Reference Image) and MENUBAR.BM use IDs 1501-1504. Palette CASE handlers at COMMAND.BM are unreachable.

- Reassign Palette menu items to new IDs (e.g., **1510** Import, **1511** Export, **1512** Random, **1513** Swap FG/BG)
- Update MENUBAR.BM with new IDs  
- Move unreachable CASE handlers in COMMAND.BM to new CASE numbers
- Add `CMD_register` entries for the new palette action IDs

**Step 1.3** — Fix Tools → Spray selects wrong tool

In COMMAND.BM, action 1702 dispatches to `KEYBOARD_tools "b"` (brush). Change to `KEYBOARD_tools "k"` (spray) or directly set `CURRENT_TOOL% = TOOL_SPRAY`.

**Step 1.4** — Fix Edit → Rotate 90 CW/CCW actual logic

After fixing IDs, verify the rotate implementation at COMMAND.BM (CW) and COMMAND.BM (CCW) actually works. Currently these handlers:
- Check for custom brush active → delegate to brush rotate
- Otherwise operate on layer/selection
- Need to confirm `IMG_rotate_90_cw`/`IMG_rotate_90_ccw` functions exist and work correctly for both with and without selection

**Step 1.5** — Fix Edit → Cut clears to BG color instead of transparent

In SELECTION.BM: change `LINE (...), PAINT_BG_COLOR~&, BF` to use `_RGBA32(0, 0, 0, 0)` with `_DONTBLEND` / `_BLEND` bracketing (same as the no-marquee path at SELECTION.BM). Also fix `CLIPBOARD_clear_selection` at SELECTION.BM which has the same issue.

**Step 1.6** — Fix View → Hide/Show All missing Layer Panel and Menu Bar

In COMMAND.BM: add `LAYER_PANEL.visible%` and `MENU_BAR.visible%` toggles to match the KEYBOARD.BM. Unify by extracting a shared `TOGGLE_all_ui` SUB called from both locations.

---

### Phase 2: Remaining Bugs
*Difficulty: Easy–Medium | Files: 8–10 | Risk: Low–Medium*

**Step 2.1** — Fix false-dirty `CANVAS_DIRTY%` on color changes (File → New/Open bugs)

Remove `CANVAS_DIRTY% = TRUE` from:
- STATUS.BM (FG color picker change)
- STATUS.BM (BG color picker change)
- COMMAND.BM (color picker dialog)

These set the dirty flag when only the palette selection changes, not canvas pixels.

**Step 2.2** — Fix Grid type not saved/loaded in DRW format

- Bump `DRW_VERSION%` from 5 to 6 in DRW.BI
- In `DRW_save_binary` (DRW.BM): after existing tool state section, write `GRID.GRID_MODE%`, `GRID.CELL_FILL%`, `GRID.SNAP%`, `GRID.ALIGN_MODE%` as 4 integers
- In `DRW_load_binary` (DRW.BM): add `IF version% >= 6 THEN` block to read those 4 integers and apply them to `GRID` state

**Step 2.3** — Fix Text tool showing NULL cursor on top of I-beam

In POINTER.BM `POINTER_build`: where `CASE TOOL_TEXT` sets `cursor_id% = CURSOR_NULL`, either skip the cursor overlay draw entirely, or set a flag to suppress the custom cursor image when text tool is active.

**Step 2.4** — Fix Grid Fill Mode doesn't honor symmetry

In MOUSE.BM: after calling `GRID_fill_cell` at the primary position, check if symmetry is active. If so, call `SYMMETRY_get_mirrored_points` to get mirrored coordinates and run `GRID_fill_cell` for each mirrored point.

**Step 2.5** — Fix Organizer mousewheel zooms canvas

Add `ORGANIZER_handle_wheel%` function to ORGANIZER.BM. In `MOUSE_input_handler` (MOUSE.BM), check if mouse is over organizer area before processing zoom. If over organizer, consume the wheel event and return TRUE to prevent zoom dispatch.

**Step 2.6** — Fix Edit → Copy Merged doesn't apply blend modes

In SELECTION.BM `CLIPBOARD_copy_merged`: use the same per-pixel blend-mode compositing logic from `RENDER_layers` in SCREEN.BM for non-Normal blend modes, not just plain `_PUTIMAGE`.

**Step 2.7** — Fix Edit → Flip H/V with selection active engages Move tool

In COMMAND.BM (Flip H) and COMMAND.BM (Flip V): when marquee is active but move tool is NOT active, flip the selected region in-place on the layer without switching to the move tool. Keep `CURRENT_TOOL%` unchanged.

**Step 2.8** — Fix Edit → Cut to New Layer leaves empty layer + undo layer count

In COMMAND.BM CASE 323 (formerly 320): review the cut→new layer→paste sequence. Ensure the new layer is properly populated. Check that `WORKSPACE_UNDO` properly tracks layer count changes during undo/redo of layer add/delete operations.

**Step 2.9** — Fix Edit → Cut then Paste in Place idempotency

Trace the cut→paste-in-place→cut→paste-in-place flow. The likely issue is that after cut clears the selection region, the second paste-in-place finds nothing to paste (clipboard was overwritten by the second cut of empty pixels). May need to preserve the clipboard across the second cut.

**Step 2.10** — Fix Status bar not visible during Import/Move/Selection

Check if import mode, move transform, or active selection suppress `STATUS_render`. Ensure `SCRN.showStatus%` is respected in all render paths, and that status bar z-order is above tool overlays.

---

### Phase 3: UI/UX Changes
*Difficulty: Easy | Files: 5–8 | Risk: Low*

**Step 3.1** — Append "..." to menu items that open dialogs

In MENUBAR.BM, update the following `MENUBAR_register_item` label strings:
- `"OPEN"` → `"OPEN..."`
- `"SAVE AS..."` already has it ✓
- `"NEW FROM TEMPLATE"` → `"NEW FROM TEMPLATE..."`
- `"EXPORT LAYER"` → `"EXPORT LAYER..."`
- `"EXPORT BRUSH"` → `"EXPORT BRUSH..."`  (under File AND Brush menus — note: Brush menu label is `"EXPORT AS PNG"`)
- `"IMPORT IMAGE"` → `"IMPORT IMAGE..."`
- `"LOAD REFERENCE"` → `"LOAD REFERENCE..."`
- `"COMMAND HELP"` → `"COMMAND HELP..."`
- `"CHEAT SHEET"` → `"CHEAT SHEET..."`
- `"CODE"` → `"CODE..."`
- Palette menu: `"IMPORT"` → `"IMPORT..."`, `"EXPORT"` → `"EXPORT..."`

**Step 3.2** — Rename View → "CURSORS" to "BRUSH CURSORS"

In MENUBAR.BM: change label from `"CURSORS"` to `"BRUSH CURSORS"`. Also in COMMAND.BM: ensure spray cursor is hidden along with brush cursors (check `POINTER_build` spray cursor path).

**Step 3.3** — Tools → Code: gray out and disable

In MENUBAR.BM: set the CODE menu item as disabled. Add it to `MENUBAR_update_checkboxes` to keep it grayed out.

**Step 3.4** — Brush root menu: grayed but still openable

In MENUBAR.BM: change `MENU_ROOT_ENABLED(5) = CUSTOM_BRUSH_is_active%` to `MENU_ROOT_ENABLED(5) = TRUE` (always openable). Instead, disable individual sub-items that require a custom brush (CLEAR, EXPORT, FLIP, ROTATE, SCALE, RESET, OUTLINE, RECOLOR).

**Step 3.5** — File → Export Brush: gray out without custom brush

Add check in `MENUBAR_update_checkboxes` for the Export Brush action (1110) — disable when `NOT CUSTOM_BRUSH_is_active%`.

**Step 3.6** — File → Import Image: fix cursor

In POINTER.BM `POINTER_build`: detect `IMAGE_IMPORT.ACTIVE` state. Show `CURSOR_HAND` when over import image interior, resize cursors when over edges/corners (use same edge detection as move tool bounding box).

**Step 3.7** — Tools → Command Help: show with filter search box

In COMMAND.BM: change from showing quick ref to showing the full command palette with search (same as `?` hotkey). Verify it calls `CMD_show_palette` or equivalent.

**Step 3.8** — Poly Line/Fill: keep tool selected after finishing

Remove `CURRENT_TOOL% = TOOL_NULL` from:
- MOUSE.BM (right-click finish)
- KEYBOARD.BM (Enter finish)

The tool should stay selected so the user can immediately start a new polygon.

**Step 3.9** — Move tool: CTRL-Z during active transform aborts

In KEYBOARD.BM undo handler: check `IF MOVE.ACTIVE AND MOVE.TRANSFORMING THEN` → call `MOVE_cancel_transform` + `MOVE_reset` + restore previous tool (same as ESC path at KEYBOARD.BM). Skip the normal undo operation — no undo step should be created.

**Step 3.10** — Spacebar: immediately change cursor to HAND + temp tool switch

In KEYBOARD.BM: on spacebar down (not already held), save `PREVIOUS_TOOL%`, set `CURRENT_TOOL% = TOOL_PAN`, mark `GUI_NEEDS_REDRAW%`. On spacebar up: restore `CURRENT_TOOL% = PREVIOUS_TOOL%`. This mirrors the ALT→picker temporary tool pattern. Text tool exception already handled by `allowSpacePan%` at MOUSE.BM.

**Step 3.11** — Toolbar image renames

In TOOLBAR.BI:
- Change `GUI_TB(TB_PSET).iSrc$ = "pset.png"` → `"dot.png"` at TOOLBAR.BI
- Change `GUI_TB(TB_PAINT).iSrc$ = "paint.png"` → `"fill.png"` at TOOLBAR.BI

Both `dot.png` and `fill.png` already exist in DEFAULT.

**Step 3.12** — Toolbar: show `fill-grid-cell.png` when Grid Cell Fill is ON

In TOOLBAR.BM: when rendering the fill tool button, check `GRID.CELL_FILL% AND GRID.SHOW%`. If true, use `fill-grid-cell.png` image instead of `fill.png`. Add this swap to `TOOLBAR_render` or wherever button images are selected.

**Step 3.13** — Organizer: mousewheel over brush size cycles presets

In the new `ORGANIZER_handle_wheel%` (created in Step 2.5): detect if mouse is over `ORG_BRUSH_SIZE` widget. Wheel up → cycle to next brush preset (1→3→5→8), wheel down → cycle to previous.

**Step 3.14** — Organizer: mousewheel over grid visibility cycles grid types

In `ORGANIZER_handle_wheel%`: detect if mouse is over `ORG_GRID_VIS` widget. Cycle `GRID.GRID_MODE%` through `GRID_MODE_SQUARE`→`GRID_MODE_DIAGONAL`→`GRID_MODE_ISOMETRIC`→`GRID_MODE_HEX`. Update icon to matching images: `grid-off-rect.png`/`grid-on-rect.png`, `grid-off-45.png`/`grid-on-45.png`, `grid-off-isometric.png`/`grid-on-isometric.png`, `grid-off-hex.png`/`grid-on-hex.png` (all exist in assets).

**Step 3.15** — Organizer: mousewheel over grid snap cycles align types

In `ORGANIZER_handle_wheel%`: detect if mouse is over `ORG_GRID_SNAP` widget. Toggle `GRID.ALIGN_MODE%` between `GRID_ALIGN_CORNER` and `GRID_ALIGN_CENTER`. Update icon: `grid-snap-edge-off/on.png` vs `grid-snap-on-center.png`/`grid-snap-off-center.png` (exist in assets).

**Step 3.16** — Unify menu commands with hotkey code (refactor audit)

Audit all `CMD_execute_action` CASE handlers against their corresponding keyboard shortcut implementations in KEYBOARD.BM. Extract shared SUBs where menu and hotkey currently have divergent implementations (like Hide/Show All fixed in Step 1.6). Key candidates: any toggle operation, tool switches, canvas operations.

---

### Phase 4: New Features
*Difficulty: Medium–Hard | Files: 4–8 | New files: 0 | Risk: Medium*

**Step 4.1** — Last directory persistence per operation type

- Add to `DRAW_CONFIG` type in CONFIG.BI: `LAST_DIR_OPEN$`, `LAST_DIR_SAVE$`, `LAST_DIR_IMPORT$`, `LAST_DIR_EXPORT_BRUSH$`, `LAST_DIR_EXPORT_LAYER$`
- Add read/write for these keys in CONFIG.BM (`CONFIG_load`/`CONFIG_save`)
- Replace `LAST_DIRECTORY$` usage in DRW.BM (open/save dialogs), LOAD.BM (import), SAVE.BM (export), and brush export with the appropriate per-operation directory variable
- Persist to DRAW.cfg on each dialog use

**Step 4.2** — File → Revert

- Add `CMD_register "Revert", "Ctrl+Shift+R", CMD_CAT_FILE, 213` in COMMAND.BM
- Add `MENUBAR_register_item "REVERT", "Ctrl+Shift+R", 0, 213, FALSE, FALSE` in MENUBAR.BM (after SAVE AS)
- Handler: prompt "Revert to last saved state?", if yes call `DRW_load` with `CURRENT_DRW_FILENAME$` (or `CURRENT_FILENAME$`). If no saved file exists, disabled/grayed out.
- Add enabled state tracking in `MENUBAR_update_checkboxes`: enabled only when `CURRENT_DRW_FILENAME$ <> "" OR CURRENT_FILENAME$ <> ""`

**Step 4.3** — Marquee SHIFT snap to grid

In MOUSE.BM marquee resize/drag handling: when SHIFT is held and marquee is active, apply `GRID_snap_xy` to coordinates being set. This is separate from the MOVE tool's SHIFT=constrain behavior. Also apply during image import resize/drag when SHIFT is held.

**Step 4.4** — File → Recent files (10 items with submenu)

- Add `RECENT_FILE_COUNT%`, `RECENT_FILES$(1 TO 10)` to config type in CONFIG.BI
- Add read/write in CONFIG.BM: keys `RECENT_FILE_1` through `RECENT_FILE_10`
- Implement submenu support in MENUBAR.BM: `MENUBAR_register_item "RECENT...", "", 0, 0, FALSE, FALSE` as parent, then child items for each recent file
- This requires **submenu rendering** in `MENUBAR_render` — currently menus are flat (no nested submenus). Need to add right-arrow indicator, hover-to-open, arrow key navigation for submenus
- Add `RECENT_add_file filename$` SUB to push files onto the list (called after save/open)
- Add "CLEAR" option at bottom with divider
- Reserve action IDs 214-224 (10 recent files + clear)
- **This is the hardest feature** — submenu rendering is new UI infrastructure

**Step 4.5** — New from Template

- Handler for action 210 in COMMAND.BM: replace stub with:
  1. Open file dialog using `TEMPLATE_DIR` from config (or `LAST_DIR_OPEN$` if unset)
  2. Load the chosen file via appropriate loader (DRW, PNG, BMP)
  3. Clear `CURRENT_DRW_FILENAME$` and `CURRENT_FILENAME$` — this makes CTRL+S prompt for save location
  4. Set `CANVAS_DIRTY% = FALSE` initially
- Add `TEMPLATE_DIR$` to config type and persistence
- Append `"..."` to menu label (done in Step 3.1)

---

### Verification

- **Phase 1**: Menu → Edit → Rotate 90 CW/CCW should rotate. Menu → Edit → Copy Merged should copy. Palette → Import/Export/Random should work. Tools → Spray should select spray. Cut should clear to transparency. F11 should hide/show all panels including layers and menu bar.
- **Phase 2**: Change FG/BG color → title bar should NOT show `*`. Save .draw → reopen → grid type/mode preserved. Text tool cursor clean. Grid fill + symmetry mirrors fills. Mousewheel over organizer doesn't zoom. Flip H/V with selection doesn't switch tool.
- **Phase 3**: Menu items with dialogs show `...`. Poly line stays selected after finishing. Spacebar shows hand cursor immediately. Toolbar shows correct icons.
- **Phase 4**: Directories remembered per operation. Revert reloads last save. Recent files tracked and clearable. Templates open without overwriting source.
- **Build**: `qb64pe -w -x -o DRAW.run DRAW.BAS` — must compile clean with no warnings.

### Decisions
- **Action ID reassignment**: Copy Merged → 322, Cut to New Layer → 323, Palette Import/Export/Random/Swap → 1510-1513. Rotate 90 CW/CCW keep 319/320.
- **DRW format**: Bump to version 6 for grid state persistence. Backward-compatible read with `IF version% >= 6`.
- **Submenu infrastructure** (Recent files) is the largest single piece of new work — estimated ~200-300 lines of new rendering and input handling code in MENUBAR.BM.
- **Toolbar image swap** for fill/grid-cell-fill is dynamic at render time, not a file rename.