# Plan: Symbol Layers

## TL;DR
Add a symbol/instance layer system to DRAW. A **Symbol Parent** is a regular editable layer designated as a reusable source (color-coded row in layer panel). **Symbol Children** are non-editable instances linked to the parent. Syncing is explicit via Layer → Sync Symbols. Each child has independent visibility, opacity, opacity lock, position, scale, flip, and blend mode. v1: position + scale + flip H/V; rotation deferred.

## Architecture

### Two new layer types
- `LAYER_TYPE_SYMBOL_PARENT = 3`
- `LAYER_TYPE_SYMBOL_CHILD = 4`

### New DRAW_LAYER fields
- `symbolParentId AS LONG` — child: `historyId&` of parent; parent/other: 0
- `symbolParentDirty AS INTEGER` — parent: TRUE when content edited since last sync (set when contentDirty% set on a parent; cleared by SYMBOL_sync_children)
- `symbolScaleX AS SINGLE` — child: X scale factor (default 1.0; negative = flip H)
- `symbolScaleY AS SINGLE` — child: Y scale factor (default 1.0; negative = flip V)
- `symbolOffsetX AS INTEGER` — child: canvas X for top-left of scaled content
- `symbolOffsetY AS INTEGER` — child: canvas Y for top-left of scaled content

### Explicit sync model (NOT auto-sync)
- **No render pipeline hooks.** User explicitly triggers Layer → Sync Symbols (or hotkey).
- `SYMBOL_sync_all` walks all parents where `symbolParentDirty% = TRUE`, calls `SYMBOL_sync_children`.
- Also triggered after undo/redo and file load for correctness.

### Scale + Flip via PgUp/PgDn and H/V keys
- **PgUp/PgDn** on a symbol child: increment/decrement scale (±1× integer steps for pixel art)
- **H key** on a symbol child: toggle `symbolScaleX!` sign (flip horizontal)
- **V key** on a symbol child: toggle `symbolScaleY!` sign (flip vertical)
- After any change: call `SYMBOL_render_child` + mark child `contentDirty%`
- H/V only intercepted when CURRENT_LAYER% is LAYER_TYPE_SYMBOL_CHILD; otherwise fall through to normal behavior

### Flip implementation
Negative scale factors = flip. `_PUTIMAGE` with swapped source coordinates handles this natively:
- `scaleX! = -1.0` → horizontal flip (swap x1,x2 in _PUTIMAGE source rect)
- `scaleY! = -1.0` → vertical flip (swap y1,y2)
- Combined `-1.0, -1.0` → 180° rotation equivalent

### Layer panel: color-coded rows (no text badges)
- **Symbol parent rows**: use `THEME.LAYER_PANEL_symbol_parent_bg~&` / `_fg~&`
- **Symbol child rows**: use `THEME.LAYER_PANEL_symbol_child_bg~&` / `_fg~&`
- Follows existing pattern: `group_header_bg/fg`, `row_master_bg`, etc.
- Row color precedence: master > multi-selected > **symbol_parent/child** > hover > normal

---

## Steps

### Phase 1: Data Model (blocks all other phases)

1. Add constants to `GUI/LAYERS.BI`:
   - `CONST LAYER_TYPE_SYMBOL_PARENT = 3`
   - `CONST LAYER_TYPE_SYMBOL_CHILD = 4`

2. Add fields to `DRAW_LAYER` TYPE in `GUI/LAYERS.BI`:
   - `symbolParentId AS LONG`
   - `symbolParentDirty AS INTEGER`
   - `symbolScaleX AS SINGLE`
   - `symbolScaleY AS SINGLE`
   - `symbolOffsetX AS INTEGER`
   - `symbolOffsetY AS INTEGER`

3. Add theme color fields to `THEME_OBJ` in `CFG/CONFIG-THEME.BI`:
   - `LAYER_PANEL_symbol_parent_bg AS _UNSIGNED LONG`
   - `LAYER_PANEL_symbol_parent_fg AS _UNSIGNED LONG`
   - `LAYER_PANEL_symbol_child_bg AS _UNSIGNED LONG`
   - `LAYER_PANEL_symbol_child_fg AS _UNSIGNED LONG`

4. Set default theme colors in `ASSETS/THEMES/DEFAULT/THEME.BI`:
   - Parent bg: a muted teal/green tint (visually distinct from group headers)
   - Parent fg: light text
   - Child bg: a muted blue/purple tint (distinct from parent and group)
   - Child fg: light text

5. Add THEME.cfg key parsing in `CFG/CONFIG-THEME.BM` for the 4 new color keys

6. Create `GUI/SYMBOL.BI` — declarations for all SYMBOL_* SUBs/FUNCTIONs

7. Create `GUI/SYMBOL.BM` — implementation

8. Add includes to `_ALL.BI` (after LAYERS.BI) and `_ALL.BM` (after LAYERS.BM)

### Phase 2: Core Symbol Operations (*depends on Phase 1*)

9. `FUNCTION SYMBOL_find_parent_slot%(childIdx%)` — scan LAYERS() for matching historyId&

10. `SUB SYMBOL_find_children(parentIdx%, children%(), count%)` — scan LAYERS() for all children of a parent

11. `SUB SYMBOL_render_child(childIdx%)` — Core re-render:
    - Find parent via `SYMBOL_find_parent_slot%`
    - If parent not found or parent imgHandle invalid, exit
    - Get parent content bounds via `LAYER_get_content_bounds`
    - Clear child `imgHandle&` to transparent
    - Compute dest size: `abs(scaleX!) * bw`, `abs(scaleY!) * bh`
    - Build `_PUTIMAGE` source rect; if scaleX! < 0 swap src x1/x2; if scaleY! < 0 swap src y1/y2
    - `_PUTIMAGE` from parent img to child img at `symbolOffsetX/Y%` with computed dest size
    - Use `_DONTBLEND` for pixel-perfect transparency
    - Set child `contentDirty% = TRUE`

12. `SUB SYMBOL_sync_children(parentIdx%)` — find all children, call `SYMBOL_render_child` for each, clear parent's `symbolParentDirty%`

13. `SUB SYMBOL_sync_all()` — walk all layers: if `layerType% = LAYER_TYPE_SYMBOL_PARENT AND symbolParentDirty%` → call `SYMBOL_sync_children`. Also `BLEND_invalidate_cache`.

14. `SUB SYMBOL_create_parent(layerIdx%)` — Convert existing layer to symbol parent:
    - Set `layerType% = LAYER_TYPE_SYMBOL_PARENT`
    - Set `symbolParentDirty% = FALSE`
    - Record history

15. `SUB SYMBOL_create_parent_empty%()` — Create new blank symbol parent layer:
    - Call `LAYERS_new%`, set `layerType% = LAYER_TYPE_SYMBOL_PARENT`
    - Name: "Symbol N"

16. `SUB SYMBOL_create_child(parentIdx%)` — Create child instance:
    - Allocate new layer slot
    - Set `layerType% = LAYER_TYPE_SYMBOL_CHILD`
    - Set `symbolParentId& = LAYERS(parentIdx%).historyId&`
    - Set `symbolScaleX! = 1.0`, `symbolScaleY! = 1.0`
    - Get parent content bounds → set `symbolOffsetX/Y%` to parent content origin
    - Name: base name of parent + " instance"
    - Copy visibility, opacity, opacityLock, blendMode from parent
    - Call `SYMBOL_render_child`
    - Record `HISTORY_record_layer_add`

17. `SUB SYMBOL_rasterize_parent(idx%)`:
    - Change `layerType%` to `LAYER_TYPE_IMAGE`
    - For ALL children: call `SYMBOL_detach_child`
    - Clear symbol fields
    - Record history

18. `SUB SYMBOL_detach_child(idx%)`:
    - Change `layerType%` to `LAYER_TYPE_IMAGE`
    - Clear `symbolParentId& = 0`, clear scale/offset fields
    - Pixel data stays frozen
    - Record history

19. `SUB SYMBOL_mark_parent_dirty(layerIdx%)`:
    - If `LAYERS(layerIdx%).layerType% = LAYER_TYPE_SYMBOL_PARENT` then set `symbolParentDirty% = TRUE`
    - Called from places that set `contentDirty%` on layers (brush ops, undo apply, etc.)

### Phase 3: Edit Blocking (*depends on Phase 2*)

20. In `MOUSE_dispatch_tool_hold` (INPUT/MOUSE.BM ~line 3621):
    - Mirror text layer guard: if `LAYER_TYPE_SYMBOL_CHILD` → block drawing tools
    - Alert: "Symbol instances cannot be edited directly. Edit the parent layer, or Layer → Detach Instance."
    - Set `MOUSE.UI_CHROME_CLICKED% = TRUE`

### Phase 4: Move Tool Override (*depends on Phase 2*)

21. In `TOOLS/MOVE.BM` — when active layer is `LAYER_TYPE_SYMBOL_CHILD`:
    - On drag: update `symbolOffsetX/Y%` by delta, NOT `LAYER_translate_content`
    - Call `SYMBOL_render_child` to regenerate at new position
    - History record on release

### Phase 5: Scale & Flip Keys (*depends on Phase 2*)

22. In `INPUT/KEYBOARD.BM`:
    - When `CURRENT_LAYER%` is `LAYER_TYPE_SYMBOL_CHILD` AND Command Palette NOT visible:
      - **PgUp** (18688): increment scale by 1.0 (preserving sign for flip): `IF symbolScaleX! > 0 THEN symbolScaleX! = symbolScaleX! + 1.0 ELSE symbolScaleX! = symbolScaleX! - 1.0` (same for Y). Clamp range ±1.0 to ±10.0
      - **PgDn** (20736): decrement scale by 1.0 (min magnitude 1.0)
      - After change: call `SYMBOL_render_child`, set `FRAME_IDLE% = FALSE`
    - Use `STATIC` pressed guards per Gotcha #20

23. In `GUI/COMMAND.BM` action 315 (Flip H / H key) and 316 (Flip V / V key):
    - Add guard at top: if `CURRENT_LAYER%` is `LAYER_TYPE_SYMBOL_CHILD`:
      - 315: negate `symbolScaleX!`
      - 316: negate `symbolScaleY!`
      - Call `SYMBOL_render_child`, `BLEND_invalidate_cache`, `FRAME_IDLE% = FALSE`
      - Skip the normal destructive pixel flip logic

### Phase 6: Duplicate Override (*parallel with Phase 5*)

24. In `LAYERS_duplicate` (GUI/LAYERS.BM ~line 464):
    - If source `layerType% = LAYER_TYPE_SYMBOL_PARENT` → call `SYMBOL_create_child` instead of normal copy
    - If source `layerType% = LAYER_TYPE_SYMBOL_CHILD` → call `SYMBOL_create_child(SYMBOL_find_parent_slot%(source))` — creates a sibling child sharing the same parent

### Phase 7: Layer Panel UI (*parallel with Phase 3+*)

25. In `LAYER_PANEL_render` (GUI/LAYERS.BM ~line 2092) row bg color selection:
    - Before the hover/normal fallback, add symbol type check:
    ```
    ELSEIF LAYERS(layerIdx%).layerType% = LAYER_TYPE_SYMBOL_PARENT THEN
        rowBg~& = THEME.LAYER_PANEL_symbol_parent_bg~&
    ELSEIF LAYERS(layerIdx%).layerType% = LAYER_TYPE_SYMBOL_CHILD THEN
        rowBg~& = THEME.LAYER_PANEL_symbol_child_bg~&
    ```
    - Same approach for text color (use `_fg~&` variants for name rendering)
    - Master/multi-select colors still take precedence (existing behavior)

26. In context menu (`LAYER_PANEL_ctx_menu_build`):
    - SYMBOL_PARENT: "Create Instance", "Sync Symbols", "Rasterize Symbol"
    - SYMBOL_CHILD: "Detach Instance", "Select Parent"

### Phase 8: Menu & Command System (*parallel with Phase 3+*)

27. Add action IDs in `GUI/COMMAND.BM` `CMD_init`:
    - 730 = Convert to Symbol Parent
    - 731 = New Symbol Layer (empty)
    - 732 = Create Symbol Instance (when parent selected)
    - 733 = Sync Symbols (calls SYMBOL_sync_all)
    - 734 = Rasterize Symbol
    - 735 = Detach Instance

28. Add handlers in `CMD_execute_action`

29. Add Layer menu items in `GUI/MENUBAR.BM`:
    - Separator after existing text/group items
    - "Convert to Symbol" (730)
    - "New Symbol Layer" (731)
    - "Create Instance" (732) — enabled when SYMBOL_PARENT selected
    - "Sync Symbols" (733) — always enabled
    - "Rasterize Symbol" (734) — enabled when SYMBOL_PARENT selected
    - "Detach Instance" (735) — enabled when SYMBOL_CHILD selected

### Phase 9: DRW Serialization (*depends on Phase 1*)

30. Bump `DRW_VERSION%` to 25 in `TOOLS/DRW.BI`

31. In `DRW_save_binary` (TOOLS/DRW.BM):
    - After v24 group fields, write symbol fields:
    - `symbolParentId&` (remapped via slotToSeq% like parentGroupIdx%)
    - `symbolParentDirty%` (saved as FALSE — no point persisting dirty state)
    - `symbolScaleX!`, `symbolScaleY!`
    - `symbolOffsetX%`, `symbolOffsetY%`

32. In `DRW_load_binary` (TOOLS/DRW.BM):
    - If version >= 25: read symbol fields, remap symbolParentId&
    - If version < 25: default all to 0/1.0
    - After all layers loaded: call `SYMBOL_sync_all` to regenerate all children

33. Ensure `DRW_load_binary` initializes all symbol fields to defaults (Gotcha #15)

### Phase 10: History Integration (*depends on Phase 2*)

34. `SYMBOL_mark_parent_dirty` calls inserted at existing `contentDirty% = TRUE` sites:
    - In `HISTORY_apply_undo` / `HISTORY_apply_redo` when restoring layer pixels
    - In `_COMMON.BM` paint helpers (brush commit paths)
    - Anywhere `contentDirty%` is set on a layer that might be a parent

35. Structure changes (create/detach/rasterize) use existing `HISTORY_record_layer_add` / `_delete` / structure patterns

---

## Relevant Files

**New files:**
- `GUI/SYMBOL.BI` — Declarations
- `GUI/SYMBOL.BM` — Implementation (~200-300 lines estimated)

**Modified files:**
- `GUI/LAYERS.BI` — New LAYER_TYPE constants (after line 46), new DRAW_LAYER fields (after line 73)
- `GUI/LAYERS.BM` — Row bg color in `LAYER_PANEL_render` (~line 2092), context menu (~line 5893), `LAYERS_duplicate` override (~line 464)
- `CFG/CONFIG-THEME.BI` — 4 new color fields in THEME_OBJ (after existing LAYER_PANEL fields ~line 176)
- `CFG/CONFIG-THEME.BM` — Parse 4 new THEME.cfg keys
- `ASSETS/THEMES/DEFAULT/THEME.BI` — Default color values for 4 new fields
- `INPUT/MOUSE.BM` — Edit blocking guard (~line 3621)
- `INPUT/KEYBOARD.BM` — PgUp/PgDn scale handler for symbol children
- `TOOLS/MOVE.BM` — Symbol child offset-based move
- `TOOLS/DRW.BI` — Bump DRW_VERSION to 25
- `TOOLS/DRW.BM` — Save/load symbol fields
- `GUI/COMMAND.BM` — Action IDs 730-735 in CMD_init and CMD_execute_action; flip guards in actions 315/316
- `GUI/MENUBAR.BM` — Layer menu items for symbol operations
- `_ALL.BI` / `_ALL.BM` — Include SYMBOL.BI/BM
- `_COMMON.BM` — Add `SYMBOL_mark_parent_dirty` calls at contentDirty% sites
- `TOOLS/HISTORY.BM` — Add `SYMBOL_mark_parent_dirty` in undo/redo apply

**Reference patterns (read, don't modify):**
- `GUI/TEXT-LAYER.BI/BM` — Re-render model reference
- `LAYER_get_content_bounds` in LAYERS.BM (~line 871) — Content extent calculation
- `LAYER_PANEL_render` row bg logic (~line 2092) — Color precedence template

---

## Verification

1. **Compile**: `cd /home/grymmjack/git/DRAW && qb64pe -w -x DRAW.BAS -o DRAW.run 2>&1 | tail -10`
2. **Convert layer → symbol parent**: Layer row turns parent theme color
3. **New Symbol Layer**: Creates empty parent with correct theme color
4. **Duplicate parent → child created**: Child row shows child theme color, renders parent content
5. **Edit parent + Sync Symbols**: Edit parent, Layer → Sync Symbols → children update
6. **symbolParentDirty flag**: After editing parent, `symbolParentDirty%` is TRUE; after Sync Symbols, it's FALSE
7. **Move child**: Move tool drags child independently via offset
8. **PgUp/PgDn scale**: Select child → PgUp → content scales up by 1× step; PgDn → scales down (min 1×)
9. **Flip H/V**: Select child → H → child flips horizontally; V → vertically; both → 180°
10. **Edit blocking**: Select child → draw tool → blocked with alert
11. **Detach Instance**: Child becomes regular IMAGE, editable, unlinked, row color returns to normal
12. **Rasterize Symbol**: Parent becomes IMAGE, all children detached
13. **Save/Load DRW v25**: Relationships + scale/flip/offset preserved
14. **Undo/Redo**: Parent edit undo sets symbolParentDirty%; Sync Symbols updates children
15. **Hide parent / show child**: Child still renders on canvas
16. **Group compat**: Parent in one group, child in another → both work
17. **Load v24 DRW**: No crash, layers default to IMAGE, symbol fields zeroed
18. **Theme colors**: Customize THEME.cfg symbol parent/child colors → layer panel reflects changes
19. **Duplicate child**: Duplicate a child → creates sibling child sharing same parent (not a regular copy)

---

## Decisions

- **Two explicit layer types** (3, 4) for clean SELECT CASE guards
- **Explicit sync** — Layer → Sync Symbols (not auto-sync in render pipeline); workflow-first approach
- **symbolParentDirty%** flag avoids scanning all layers on sync — only dirty parents rebuild children
- **Color-coded rows** instead of text badges — no [SYM]/(SYM@) clutter; visually distinct via theme colors
- **Flip via negative scale** — `scaleX! = -1.0` = flip H, `scaleY! = -1.0` = flip V; no rotation math needed
- **H/V keys for flip** — uses existing Flip H (315) / Flip V (316) action IDs; symbol child guard intercepts to negate scale sign instead of destructive pixel flip
- **PgUp/PgDn integer scale steps** — pixel art friendly: 1×, 2×, 3× etc. (preserves crispness)
- **Duplicating child creates sibling** — shares same parent, never creates a regular copy
- **historyId& as stable parent reference** — survives slot reordering, remapped in DRW save/load
- **Nearest-neighbor scaling** — `_PUTIMAGE` with `_DONTBLEND` for pixel art fidelity
- **Rotation deferred** to v2
- **Single-layer symbols only** — group-as-symbol excluded
- **symbolParentDirty% NOT persisted** — always saved as FALSE; DRW load triggers SYMBOL_sync_all anyway
