# DRAW Codebase Analysis: Nesting Levels & Function Sizes

*Generated analysis of SUB/FUNCTION definitions across the QB64-PE codebase.*

---

## Summary Statistics

| Metric | Value |
|--------|-------|
| Total SUB/FUNCTION definitions | ~150+ |
| Functions >500 lines | 4 |
| Functions 200-500 lines | 12 |
| Functions 100-200 lines | ~15 |
| Functions 50-100 lines | ~25 |
| Estimated deepest nesting | 7-8 levels |

---

## HUGE FUNCTIONS (>500 lines) — CRITICAL REFACTORING TARGETS

| File | Line | Name | Lines | Est. Max Nest |
|------|------|------|-------|---------------|
| INPUT/MOUSE.BM | 85 | `MOUSE_input_handler()` | **~1677** | 7+ |
| INPUT/KEYBOARD.BM | 397 | `KEYBOARD_input_handler()` | **~1195** | 6+ |
| OUTPUT/SCREEN.BM | 244 | `SCREEN_render()` | **~888** | 5+ |
| GUI/POINTER.BM | 347 | `POINTER_draw()` | **~536** | 5+ |

### Analysis of Critical Functions

#### 1. `MOUSE_input_handler()` — 1677 lines
**Location:** [INPUT/MOUSE.BM](../INPUT/MOUSE.BM#L85)

This is the single largest function in the codebase. Contains:
- Image import mode handling (~200 lines)
- Drain-then-process mouse input pattern
- Tool-specific SELECT CASE with 20+ cases
- Nested IF blocks for:
  - Button states (B1, B2, OLD_B1, OLD_B2)
  - Modifier keys (Ctrl, Shift, Alt)
  - GUI area detection (toolbar, layer panel, status bar, palette)
  - Tool states (DRAGGING, RESIZING, TRANSFORMING)

**Nesting pattern example:**
```
IF IMAGE_IMPORT.ACTIVE THEN
    IF MOUSE.B1% THEN
        IF handle% > 0 THEN
            SELECT CASE handle%
                CASE 1 TO 4
                    IF NOT IMAGE_IMPORT.RESIZING THEN
                        ...
```
**Max observed nesting: 7 levels**

#### 2. `KEYBOARD_input_handler()` — 1195 lines
**Location:** [INPUT/KEYBOARD.BM](../INPUT/KEYBOARD.BM#L397)

Contains:
- Command palette handling
- Image import mode keyboard controls
- Menu bar keyboard navigation
- Modifier key detection (40+ combinations)
- Tool-specific key bindings
- File operations (Ctrl+S, Ctrl+O, etc.)
- Undo/Redo (Ctrl+Z, Ctrl+Y)

**Nesting pattern example:**
```
IF CMD_PALETTE.visible THEN
    SELECT CASE k&
        CASE 18432  ' Up arrow
            CMD_navigate_up
        CASE ...
ELSEIF IMAGE_IMPORT.ACTIVE THEN
    IF _KEYDOWN(100306) OR _KEYDOWN(100305) THEN  ' Ctrl
        SELECT CASE k&
            CASE 43  ' +
                IF _KEYDOWN(100304) OR _KEYDOWN(100303) THEN  ' Shift
                    ...
```
**Max observed nesting: 6 levels**

#### 3. `SCREEN_render()` — 888 lines
**Location:** [OUTPUT/SCREEN.BM](../OUTPUT/SCREEN.BM#L244)

Contains:
- 17-step rendering pipeline
- Three render paths (GUI-only, dirty-rect cache, full render)
- Layer compositing with blend modes
- Grid overlay rendering
- Tool preview rendering for all tools
- Scene cache management

**Nesting pattern example:**
```
IF NOT SCENE_DIRTY% THEN
    IF SCENE_CACHE& < -1 THEN
        _PUTIMAGE , SCENE_CACHE&, SCRN.CANVAS&
        GOTO SkipToPointer
    END IF
END IF
FOR layerZ% = 1 TO LAYER_COUNT%
    IF LAYERS(i%).visible% THEN
        IF LAYERS(i%).blendMode% = BLEND_NORMAL THEN
            IF LAYERS(i%).opacity% = 255 THEN
                ...
```
**Max observed nesting: 5 levels**

#### 4. `POINTER_draw()` — 536 lines
**Location:** [GUI/POINTER.BM](../GUI/POINTER.BM#L347)

Contains:
- Panning mode cursor
- UI area cursor detection
- Custom brush rendering
- Tool-specific cursor rendering (Brush, Pick, Line, Rect, etc.)
- Procedural cursor drawing with fallbacks

---

## VERY LARGE FUNCTIONS (200-500 lines)

| File | Line | Name | Lines | Est. Max Nest |
|------|------|------|-------|---------------|
| GUI/COMMAND.BM | 543 | `CMD_execute_action()` | ~453 | 4 |
| GUI/LAYERS.BM | 784 | `LAYER_PANEL_render()` | ~374 | 4 |
| INPUT/KEYBOARD.BM | 55 | `KEYBOARD_tools()` | ~298 | 3 |
| TOOLS/DRW.BM | 135 | `DRW_load()` | ~292 | 4 |
| GUI/POINTER.BM | 74 | `POINTER_build()` | ~273 | 4 |
| GUI/LAYERS.BM | 1183 | `LAYER_PANEL_handle_click%()` | ~236 | 5 |
| TOOLS/BRUSH.BM | - | `PAINT_on()` | ~216 | 5 |
| GUI/PALETTE-STRIP.BM | - | `PALETTE_STRIP_render()` | ~200 | 4 |
| INPUT/KEYBOARD.BM | 1592 | `KEYBOARD_layers()` | ~196 | 3 |
| GUI/MENUBAR.BM | 80 | `MENUBAR_register_all()` | ~180 | 2 |
| TOOLS/IMAGE-IMPORT.BM | 763 | `IMAGE_IMPORT_draw_box()` | ~136 | 4 |
| GUI/MENUBAR.BM | - | `MENUBAR_handle_key%()` | ~132 | 4 |

---

## LARGE FUNCTIONS (100-200 lines)

| File | Line | Name | Lines | Est. Max Nest |
|------|------|------|-------|---------------|
| GUI/TOOLBAR.BM | - | `TOOLBAR_handle_click%()` | ~121 | 4 |
| GUI/TOOLBAR.BM | - | `TOOLBAR_render()` | ~112 | 3 |
| TOOLS/IMAGE-IMPORT.BM | 414 | `IMAGE_IMPORT_update_resize()` | ~109 | 4 |
| OUTPUT/SCREEN.BM | 142 | `SCREEN_init()` | ~100 | 3 |
| TOOLS/IMAGE-IMPORT.BM | 59 | `IMAGE_IMPORT_load_file%()` | ~99 | 4 |
| TOOLS/DRW.BM | 45 | `DRW_save()` | ~90 | 3 |
| TOOLS/SELECTION.BM | 114 | `CLIPBOARD_paste()` | ~89 | 4 |
| TOOLS/UNDO.BM | - | `UNDO_undo()` | ~87 | 4 |
| TOOLS/SELECTION.BM | 203 | `CLIPBOARD_copy_merged()` | ~72 | 3 |
| GUI/LAYERS.BM | 653 | `LAYERS_merge_visible()` | ~68 | 3 |
| TOOLS/BRUSH.BM | - | `BRUSH_draw_custom()` | ~63 | 4 |

---

## DEEP NESTING (>=4 levels)

| File | Line | Name | Max Nest | Description |
|------|------|------|----------|-------------|
| INPUT/MOUSE.BM | 85 | `MOUSE_input_handler()` | **7+** | Tool SELECT within IF button/mode/area checks |
| INPUT/KEYBOARD.BM | 397 | `KEYBOARD_input_handler()` | **6+** | Modifier key combinations in mode checks |
| TOOLS/BRUSH.BM | - | `PAINT_on()` | **5** | Symmetry loops within dither within brush shape |
| GUI/POINTER.BM | 347 | `POINTER_draw()` | **5** | Tool-specific cursors within UI checks |
| OUTPUT/SCREEN.BM | 244 | `SCREEN_render()` | **5** | Layer loop within blend mode/opacity checks |
| GUI/LAYERS.BM | 1183 | `LAYER_PANEL_handle_click%()` | **5** | Button area IF within scroll check within panel |
| TOOLS/IMAGE-IMPORT.BM | 763 | `IMAGE_IMPORT_draw_box()` | **4** | Handle rendering within transform checks |
| TOOLS/MARQUEE.BM | 110 | `MARQUEE_draw()` | **4** | Marching ants within selection check |

---

## WORST OFFENDERS (Large AND Deeply Nested)

These functions require the most urgent refactoring attention:

### 1. `MOUSE_input_handler()` — **CRITICAL**
- **Lines:** ~1677
- **Max Nesting:** 7+
- **Why it's problematic:** Single god-function handling ALL mouse input for the entire application. Every tool, every GUI area, every mouse state is processed here.
- **Refactoring suggestion:** 
  - Extract tool-specific handlers: `MOUSE_handle_brush()`, `MOUSE_handle_marquee()`, etc.
  - Extract GUI area handlers: `MOUSE_handle_toolbar()`, `MOUSE_handle_layer_panel()`, etc.
  - Extract mode handlers: `MOUSE_handle_image_import()`, `MOUSE_handle_panning()`, etc.
  - Use a dispatch table or SELECT CASE at top level calling extracted subs

### 2. `KEYBOARD_input_handler()` — **CRITICAL**
- **Lines:** ~1195
- **Max Nesting:** 6+
- **Why it's problematic:** All keyboard input in one function. Modifier key combinations create deep nesting.
- **Refactoring suggestion:**
  - Extract: `KEYBOARD_handle_command_palette()`, `KEYBOARD_handle_image_import()`, `KEYBOARD_handle_menu()`
  - Create modifier state struct to reduce nesting: `IF ctrl% AND shift% THEN` vs nested IF blocks
  - Use action command IDs like CMD_execute_action() already does

### 3. `SCREEN_render()` — **HIGH**
- **Lines:** ~888
- **Max Nesting:** 5+
- **Why it's problematic:** Contains entire 17-step render pipeline in one function with 3 different paths.
- **Refactoring suggestion:**
  - Already well-structured with numbered steps; extract each step to a sub
  - `RENDER_layers()`, `RENDER_grid()`, `RENDER_tool_previews()`, `RENDER_gui()`, `RENDER_pointer()`
  - Keep SCREEN_render() as orchestrator calling sub-routines

### 4. `POINTER_draw()` — **MEDIUM-HIGH**
- **Lines:** ~536
- **Max Nesting:** 5+
- **Why it's problematic:** Every tool's cursor rendering in one function.
- **Refactoring suggestion:**
  - Extract per-tool cursor rendering: `POINTER_draw_brush()`, `POINTER_draw_marquee()`, etc.
  - Use CURSOR_ID-based dispatch

---

## NESTING PATTERNS OBSERVED

### Pattern 1: Mode-within-Tool-within-State
```qb64
IF IMAGE_IMPORT.ACTIVE THEN          ' Mode check
    IF MOUSE.B1% THEN                 ' Button state
        IF handle% > 0 THEN           ' Sub-state
            SELECT CASE handle%        ' Tool-specific
                CASE 1: ...
```
**Problem:** Each new mode/state multiplies nesting depth.
**Solution:** Early returns or extract mode-specific handlers.

### Pattern 2: Modifier Key Cascades
```qb64
IF _KEYDOWN(100306) THEN              ' Ctrl
    IF _KEYDOWN(100304) THEN          ' Shift
        IF _KEYDOWN(100308) THEN      ' Alt
            ' Handle Ctrl+Shift+Alt+Key
```
**Problem:** 3+ levels just for modifier detection.
**Solution:** Precompute modifier flags before main SELECT CASE.

### Pattern 3: GUI Area Waterfall
```qb64
IF TOOLBAR_is_over_area%(mx%, my%) THEN
    ' toolbar handling
ELSEIF LAYER_PANEL.visible% AND mx% < CFG.LAYER_PANEL_WIDTH% THEN
    ' layer panel handling
ELSEIF my% >= strip_top% THEN
    ' palette strip handling
ELSE
    ' canvas handling
```
**Problem:** Linear IF-ELSEIF chain that grows with GUI elements.
**Solution:** GUI hit-test dispatcher function returning area ID.

### Pattern 4: Tool State Machine Inline
```qb64
IF MARQUEE.ACTIVE% THEN
    IF MARQUEE.RESIZING% THEN
        SELECT CASE MARQUEE.RESIZE_HANDLE%
            CASE 1  ' TL
                IF MOUSE.B1% THEN
```
**Problem:** Tool state machines embedded inline.
**Solution:** Each tool manages its own state in dedicated handler.

---

## RECOMMENDATIONS

### Immediate Actions (High Impact, Lower Risk)

1. **Extract Image Import Mode Handlers**
   - `MOUSE_handle_image_import_input()` from MOUSE_input_handler
   - `KEYBOARD_handle_image_import()` from KEYBOARD_input_handler
   - ~400 lines easily extractable with clear boundaries

2. **Extract Command Palette Handlers**
   - Already partially done with CMD_handle_key(), but still embedded in KEYBOARD_input_handler
   - ~100 lines

3. **Create Modifier Key State Struct**
   ```qb64
   TYPE MODIFIERS_OBJ
       ctrl AS INTEGER
       shift AS INTEGER
       alt AS INTEGER
       ctrlShift AS INTEGER
       ctrlAlt AS INTEGER
       shiftAlt AS INTEGER
       ctrlShiftAlt AS INTEGER
   END TYPE
   DIM SHARED MOD AS MODIFIERS_OBJ
   ```
   Populate once at start of input handler, use in SELECT CASE.

### Medium-Term Refactoring

4. **Tool Handler Dispatch Pattern**
   ```qb64
   SUB MOUSE_input_handler()
       ' Common preprocessing
       MOUSE_drain_and_transform
       
       ' Mode dispatch
       IF IMAGE_IMPORT.ACTIVE THEN
           MOUSE_handle_image_import: EXIT SUB
       END IF
       IF CMD_PALETTE.visible THEN
           MOUSE_handle_command_palette: EXIT SUB
       END IF
       
       ' GUI area dispatch
       SELECT CASE MOUSE_get_area%()
           CASE AREA_TOOLBAR: MOUSE_handle_toolbar
           CASE AREA_LAYER_PANEL: MOUSE_handle_layer_panel
           CASE AREA_PALETTE: MOUSE_handle_palette
           CASE AREA_MENUBAR: MOUSE_handle_menubar
           CASE AREA_CANVAS: MOUSE_handle_canvas
       END SELECT
   END SUB
   ```

5. **Render Pipeline Extraction**
   - SCREEN_render() becomes orchestrator
   - Each numbered step becomes a sub: `RENDER_step_01_checkerboard()`, etc.

### Long-Term Architecture

6. **Event/Action System**
   - Already have CMD_execute_action() with action IDs
   - Expand to cover ALL input → action mappings
   - Input handlers only translate input to action IDs
   - Single action dispatcher handles all side effects

7. **Tool Interface Pattern**
   ```qb64
   ' Each tool implements:
   SUB TOOL_NAME_activate()
   SUB TOOL_NAME_deactivate()
   SUB TOOL_NAME_handle_mouse(event%)
   SUB TOOL_NAME_handle_key(k&)
   SUB TOOL_NAME_render_preview()
   SUB TOOL_NAME_reset()
   ```

---

## FILE SIZE OVERVIEW

| File | Total Lines | Largest Function | Lines |
|------|-------------|------------------|-------|
| INPUT/MOUSE.BM | 1784 | MOUSE_input_handler | 1677 |
| INPUT/KEYBOARD.BM | 1789 | KEYBOARD_input_handler | 1195 |
| GUI/LAYERS.BM | 2281 | LAYER_PANEL_render | 374 |
| OUTPUT/SCREEN.BM | 1132 | SCREEN_render | 888 |
| GUI/POINTER.BM | 1128 | POINTER_draw | 536 |
| GUI/COMMAND.BM | 1087 | CMD_execute_action | 453 |
| GUI/MENUBAR.BM | 987 | MENUBAR_register_all | 180 |
| TOOLS/IMAGE-IMPORT.BM | ~950 | IMAGE_IMPORT_draw_box | 136 |
| TOOLS/DRW.BM | ~550 | DRW_load | 292 |
| TOOLS/MARQUEE.BM | ~700 | MARQUEE_draw | 134 |

---

## Conclusion

The codebase has **four critical monolithic functions** that together account for over **4,000 lines of deeply nested code**:

1. MOUSE_input_handler (1677 lines, 7+ nesting)
2. KEYBOARD_input_handler (1195 lines, 6+ nesting)
3. SCREEN_render (888 lines, 5+ nesting)
4. POINTER_draw (536 lines, 5+ nesting)

These functions violate the single responsibility principle and make the codebase difficult to maintain, test, and extend. Each new feature (tool, GUI element, mode) adds complexity to these already-overloaded functions.

**Recommended priority:**
1. Extract IMAGE_IMPORT handlers first (clearest boundaries)
2. Create modifier key state computation helper
3. Extract SCREEN_render steps to sub-routines
4. Gradually decompose MOUSE/KEYBOARD handlers using tool dispatch pattern
