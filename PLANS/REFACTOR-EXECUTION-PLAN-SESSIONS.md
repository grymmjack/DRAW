Based on both analyses, I'll create a comprehensive refactoring plan that addresses your goals of centralization, reduced cognitive load, and maintainability. 

Asked 3 questions (Approach, Priority, Mod Keys)

Deep dive sessions, all four areas, and modifier key system in Phase 1. Let me create a comprehensive plan.

---

## Plan: Input/Output Centralization & Nesting Reduction

### TL;DR
Decompose the 4 monolithic functions (~4,300 lines combined) into focused, single-responsibility subs through deep-dive sessions. Centralize scattered input handling back to INPUT/, create a modifier key state system, and establish dispatch patterns that route to extracted handlers. Each session targets one major area with test-after-commit discipline.

**Key Decisions:**
- Modifier key state struct (MOD.*) replaces 50+ _KEYDOWN checks
- Mode-first dispatch pattern (Image Import → Command Palette → Menu → Canvas)
- GUI area dispatcher returns enum, handlers live in their respective GUI/ files but are *called from* MOUSE.BM
- Tool handlers remain in TOOLS/ but implement standard interface
- macOS workarounds consolidated into helper functions

---

### Session 1: Foundation — Modifier Key State System

**Goal:** Replace scattered modifier detection with single-source-of-truth struct, reducing nesting by 2-3 levels immediately.

**Steps:**

1. Create `INPUT/MODIFIERS.BI` with:
   - TYPE `MODIFIERS_OBJ` containing `ctrl%`, `shift%`, `alt%`, `ctrlShift%`, `ctrlAlt%`, `shiftAlt%`, `ctrlShiftAlt%`
   - DIM SHARED `MOD` AS `MODIFIERS_OBJ`
   - Constants for key codes: `KEY_CTRL_L&`, `KEY_CTRL_R&`, `KEY_SHIFT_L&`, etc.

2. Create `INPUT/MODIFIERS.BM` with:
   - `MODIFIERS_update()` — polls all modifier keys once, sets flags, handles macOS `MAC_ALT_HELD%` workaround internally
   - `MODIFIERS_is_ctrl%()`, `MODIFIERS_is_shift%()`, etc. — wrapper functions for readability

3. Add include to _ALL.BI and _ALL.BM

4. Call `MODIFIERS_update()` at start of DRAW.BAS main loop (before input handlers)

5. Update MOUSE.BM to use `MOD.ctrl%` instead of `_KEYDOWN(100306) OR _KEYDOWN(100305)` — approximately 20 replacements

6. Update KEYBOARD.BM similarly — approximately 30 replacements

**Verification:**
- Compile and run
- Test CTRL+S, CTRL+Z, SHIFT+click, ALT+click on all platforms
- Verify macOS Option key still works

---

### Session 2: Mouse Input Decomposition

**Goal:** Reduce `MOUSE_input_handler()` from 1677 lines to ~200-line orchestrator calling focused subs.

**Steps:**

1. Extract **drain-and-transform** (~50 lines) to `MOUSE_drain_input()`:
   - Owns the `DO WHILE _MOUSEINPUT` loop
   - Accumulates wheel delta
   - Captures macOS button workaround
   - Returns via MOUSE.* fields

2. Extract **Image Import mode** (~200 lines) to `MOUSE_handle_image_import%()`:
   - All code inside `IF IMAGE_IMPORT.ACTIVE THEN` block
   - Returns TRUE if consumed, caller exits early

3. Extract **GUI area detection** to `MOUSE_get_area%()`:
   - Returns enum: `AREA_MENUBAR`, `AREA_TOOLBAR`, `AREA_LAYER_PANEL`, `AREA_PALETTE`, `AREA_STATUS`, `AREA_CANVAS`
   - Define constants in MOUSE.BI

4. Extract **per-area handlers** (each ~50-150 lines):
   - `MOUSE_handle_menubar%()` — wraps existing `MENUBAR_*` calls
   - `MOUSE_handle_toolbar%()` — wraps existing `TOOLBAR_*` calls
   - `MOUSE_handle_layer_panel%()` — wraps existing `LAYER_PANEL_*` calls
   - `MOUSE_handle_palette%()` — wraps existing `PALETTE_STRIP_*` calls
   - `MOUSE_handle_status%()` — wraps existing `STATUS_*` calls

5. Extract **canvas/tool dispatch** to `MOUSE_handle_canvas()`:
   - Contains the `SELECT CASE CURRENT_TOOL%` block
   - Each CASE calls tool-specific sub (already exist: `MARQUEE_*`, `BRUSH_*`, etc.)

6. Refactor `MOUSE_input_handler()` to orchestrator pattern:
   ```
   SUB MOUSE_input_handler()
       MOUSE_drain_input
       IF MOUSE.SUPPRESS_FRAMES% > 0 THEN MOUSE.SUPPRESS_FRAMES% = MOUSE.SUPPRESS_FRAMES% - 1: EXIT SUB
       IF IMAGE_IMPORT.ACTIVE THEN IF MOUSE_handle_image_import%() THEN EXIT SUB
       IF CMD_PALETTE.visible THEN IF MOUSE_handle_command_palette%() THEN EXIT SUB
       SELECT CASE MOUSE_get_area%()
           CASE AREA_MENUBAR: MOUSE_handle_menubar
           CASE AREA_TOOLBAR: MOUSE_handle_toolbar
           CASE AREA_LAYER_PANEL: MOUSE_handle_layer_panel
           CASE AREA_PALETTE: MOUSE_handle_palette
           CASE AREA_STATUS: MOUSE_handle_status
           CASE AREA_CANVAS: MOUSE_handle_canvas
       END SELECT
   END SUB
   ```

**Verification:**
- All existing mouse interactions work identically
- Test: tool switching, layer panel, palette, panning, zoom wheel, marquee resize

---

### Session 3: Keyboard Input Decomposition

**Goal:** Reduce `KEYBOARD_input_handler()` from 1195 lines to ~150-line orchestrator.

**Steps:**

1. Extract **Command Palette handling** (~100 lines) to `KEYBOARD_handle_command_palette%()`:
   - Already partially exists as `CMD_handle_key()` but still embedded
   - Returns TRUE if consumed

2. Extract **Image Import keys** (~80 lines) to `KEYBOARD_handle_image_import%()`:
   - Arrow keys, Enter, ESC, +/- sizing
   - Returns TRUE if consumed

3. Extract **Menu Bar navigation** (~60 lines) to `KEYBOARD_handle_menubar%()`:
   - ALT tap, arrow keys, Enter, ESC
   - Returns TRUE if consumed

4. Consolidate **file operations** in `KEYBOARD_handle_file()`:
   - CTRL+N, CTRL+O, CTRL+S, CTRL+SHIFT+S, CTRL+Q
   - Already have individual handlers, just route here

5. Consolidate **edit operations** in `KEYBOARD_handle_edit()`:
   - CTRL+Z, CTRL+Y, CTRL+X, CTRL+C, CTRL+V, CTRL+A, DEL
   - Exists but scattered

6. Keep existing modular subs: `KEYBOARD_tools()`, `KEYBOARD_colors()`, `KEYBOARD_brush_size()`, `KEYBOARD_assistants()`, `KEYBOARD_layers()`

7. Refactor `KEYBOARD_input_handler()` to orchestrator:
   ```
   SUB KEYBOARD_input_handler(k&)
       IF k& = 0 THEN EXIT SUB
       IF CMD_PALETTE.visible THEN IF KEYBOARD_handle_command_palette%(k&) THEN EXIT SUB
       IF IMAGE_IMPORT.ACTIVE THEN IF KEYBOARD_handle_image_import%(k&) THEN EXIT SUB
       IF MENU_BAR.ACTIVE THEN IF KEYBOARD_handle_menubar%(k&) THEN EXIT SUB
       IF KEYBOARD_handle_file%(k&) THEN EXIT SUB
       IF KEYBOARD_handle_edit%(k&) THEN EXIT SUB
       KEYBOARD_tools k&
       KEYBOARD_colors k&
       KEYBOARD_brush_size k&
       KEYBOARD_assistants k&
       KEYBOARD_layers k&
   END SUB
   ```

**Verification:**
- All hotkeys work
- Test: ESC in various modes, CTRL+Z undo, tool switching, layer shortcuts

---

### Session 4: Post-Dialog Cleanup Consolidation

**Goal:** Replace 15+ scattered `DO WHILE _MOUSEINPUT: LOOP` + `MOUSE_force_buttons_up` patterns with single helper.

**Steps:**

1. Create `INPUT_post_dialog_cleanup()` in MOUSE.BM:
   ```qb64
   SUB INPUT_post_dialog_cleanup()
       DO WHILE _MOUSEINPUT: LOOP
       MOUSE_force_buttons_up
       _KEYCLEAR
       _MOUSEMOVE _WIDTH \ 2, _HEIGHT \ 2
   END SUB
   ```

2. Replace all instances in:
   - BRUSH.BM line 391
   - SAVE.BM lines 43, 83, 142, 179, 196, 224, 263
   - LOAD.BM lines 39, 67, 82, 114, 179
   - DRW.BM lines 173, 185, 451, 486, 520, 543
   - LAYERS.BM line 354
   - TOOLBAR.BM line 356
   - SCREEN.BM line 127

**Verification:**
- Open/Save dialogs work without phantom clicks
- Custom brush dialog works
- Layer rename dialog works

---

### Session 5: macOS Workaround Consolidation

**Goal:** Replace 33 `$IF MAC THEN` blocks with centralized helpers.

**Steps:**

1. Move `MAC_ALT_HELD%` tracking from DRAW.BAS into `MODIFIERS_update()` (Session 1 already handles this)

2. Create `MODIFIERS_is_alt_held%()` that internally handles the macOS workaround:
   ```qb64
   FUNCTION MODIFIERS_is_alt_held%()
       $IF MAC THEN
           MODIFIERS_is_alt_held% = MAC_ALT_HELD%
       $ELSE
           MODIFIERS_is_alt_held% = _KEYDOWN(100308) OR _KEYDOWN(100307)
       $END IF
   END FUNCTION
   ```

3. Replace all 33 scattered `$IF MAC THEN ... MAC_ALT_HELD% ... $ELSE ... _KEYDOWN(100308) ...` blocks with `MODIFIERS_is_alt_held%()`

4. Document in MODIFIERS.BI why this workaround exists

**Verification:**
- Test on macOS: Option key works for clone, constrain, etc.
- Test on Linux/Windows: ALT key works identically

---

### Session 6: Render Pipeline Extraction

**Goal:** Reduce `SCREEN_render()` from 888 lines to ~100-line orchestrator with numbered step subs.

**Steps:**

1. Already has numbered comments (Step 1 through ~17). Extract each to sub:
   - `RENDER_checkerboard()`
   - `RENDER_layers()` — the layer compositing loop
   - `RENDER_grid()`
   - `RENDER_symmetry_guides()`
   - `RENDER_canvas_border()`
   - `RENDER_import_preview()`
   - `RENDER_tool_previews()` — contains tool-specific SELECT CASE
   - `RENDER_gui()` — toolbar, status, palette, layer panel
   - `RENDER_crosshair()`
   - `RENDER_command_palette()`
   - `RENDER_scene_cache_save()`
   - `RENDER_selection_overlay()` — marching ants
   - `RENDER_pointer()` — cursor/brush preview
   - `RENDER_scale_and_display()`

2. Keep `SCREEN_render()` as orchestrator:
   ```qb64
   SUB SCREEN_render()
       IF GUI_ONLY_REDRAW% THEN RENDER_gui: GOTO SkipLayerComp
       IF NOT SCENE_DIRTY% AND SCENE_CACHE& < -1 THEN
           _PUTIMAGE , SCENE_CACHE&, SCRN.CANVAS&
           GOTO SkipToPointer
       END IF
       RENDER_checkerboard
       RENDER_layers
       RENDER_grid
       ' ... etc
   SkipToPointer:
       RENDER_selection_overlay
       RENDER_pointer
       RENDER_scale_and_display
   END SUB
   ```

**Verification:**
- Visual rendering identical
- Scene caching still works (observe idle CPU drop)
- All tool previews render correctly

---

### Session 7: POINTER_draw Decomposition

**Goal:** Reduce from 536 lines to ~80-line dispatcher.

**Steps:**

1. Extract per-tool cursor rendering:
   - `POINTER_draw_brush()`
   - `POINTER_draw_pick()`
   - `POINTER_draw_marquee()`
   - `POINTER_draw_move()`
   - `POINTER_draw_text()`
   - `POINTER_draw_zoom()`
   - `POINTER_draw_pan()`
   - `POINTER_draw_default()`

2. Keep `POINTER_draw()` as dispatcher:
   ```qb64
   SUB POINTER_draw()
       IF MOUSE_is_panning%() THEN POINTER_draw_pan: EXIT SUB
       IF POINTER_is_over_gui%() THEN POINTER_draw_default: EXIT SUB
       SELECT CASE CURRENT_TOOL%
           CASE TOOL_BRUSH, TOOL_DOT: POINTER_draw_brush
           CASE TOOL_PICK: POINTER_draw_pick
           ' ... etc
       END SELECT
   END SUB
   ```

**Verification:**
- All cursor shapes appear correctly
- Custom brush preview works
- Hover states work

---

### Session 8: Documentation & Future-Proofing

**Steps:**

1. Update copilot-instructions.md:
   - Add "Adding New Tools" section with handler interface
   - Add "Adding New GUI Areas" section
   - Document MODIFIERS system
   - Document dispatch patterns

2. Create `PLANS/ARCHITECTURE.md`:
   - Call flow diagram
   - Module responsibilities
   - Handler interface contracts

3. Delete or archive superseded analysis files:
   - INPUT-HANDLING-ANALYSIS.md
   - CODE-ANALYSIS-NESTING-SIZE.md

---

### Decisions Made
- **Modifier key state:** Single MOD struct updated once per frame
- **Dispatch pattern:** Mode-first early exit, then area dispatcher, then tool handler
- **Handler location:** Helpers live in their domain (GUI/, TOOLS/) but are called from central INPUT/
- **macOS workarounds:** Consolidated into MODIFIERS helper functions
- **Naming convention:** `MODULE_handle_*%()` returns TRUE if consumed

---

### Risk Mitigation
- Each session compiles and tests before next session begins
- Keep old function bodies commented out for first week after replacement
- Git branch per session for easy rollback

---

Ready to start **Session 1** (Modifier Key State System) when you are.