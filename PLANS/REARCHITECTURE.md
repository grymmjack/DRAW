# DRAW Input + Event Dispatch Rearchitecture

**Branch**: `input-rearchitecture`
**Owner**: grymmjack
**Status**: SPEC — pending review before execution
**Last updated**: 2026-05-23

---

## 1. Context & Goals

### Why this exists

DRAW's input handling has grown organically. Every new feature that involves a key or mouse click requires:
1. Grepping `_KEYDOWN(<code>)` across `INPUT/KEYBOARD.BM` (4892 lines) to find conflicts
2. Grepping `MOUSE.B1` across `INPUT/MOUSE.BM` (5824 lines) to find conflicts
3. Adding boilerplate (STATIC pressed%, modifier checks, letter-case ORing) — 7-10 lines per chord
4. Manually gating other handlers with `NOT GRID_X_ARMED%` style flags
5. Shipping → user reports conflict → patch → ship → user reports next conflict → patch → ...

Recent example: adding `G+Ctrl+R` for grid reset required 4 separate fixes across 3 SUBs in 3 commits because every existing handler that touched R needed an exclusion clause.

The deeper problem is **input-driven dispatch**: the central `MOUSE_input_handler` polls inputs and consults panel-specific hit-test functions (`TOOLBAR_is_over_area%`, `LAYER_PANEL_is_over_area%`, etc.) in a giant IF cascade. Adding a new panel touches the central dispatcher.

### Goals (end state)

1. **Event-driven dispatch**: regions register their handlers; the central loop figures out what fired. Adding a panel never touches the dispatcher.
2. **Single declarative table** for every input binding (keys + mouse + wheel). Action handlers are the existing `CMD_execute_action <id>` system.
3. **Conflict detection at startup** when developer mode is enabled. Writes to `inputs.log`. No more "ship → user reports conflict" loops.
4. **DRY**: helpers for image-handle validation, _DEST/_SOURCE save-restore, pixel-doubling, scene invalidation, single-fire edge detection, letter-case-insensitive key checks.
5. **Maintainability**: a new chord or panel is ~5 lines (register), not a multi-file patch. A new event type (e.g. `EVT_MOUSE_RIGHTCLICK_LONG_PRESS`) is one place to add detection.

### Non-goals

1. **Not rewriting state machines**: continuous-paint loops, eraser hold-vs-tap, smart-shape double-tap, text-tool editing, file-dialog input — these stay as legacy SUBs because their logic doesn't fit the event-binding model. They get registered as metadata (`dispatched = FALSE`) for audit purposes only.
2. **Not changing tool semantics**: paint stroke logic, transform tool, marquee tool — same behavior.
3. **Not changing the `.draw` save format**: file format and CFG are out of scope.
4. **Not user-customizable bindings yet**: the infrastructure makes it trivial later, but no rebinding UI is built.

### Scope confirmation (user-locked decisions)

| Decision | Value |
|---|---|
| Migration approach | **Hybrid table** — register all legacy as `dispatched = FALSE`, new code uses `dispatched = TRUE` |
| Modifier representation | **Bitmask** — `MOD_CTRL | MOD_SHIFT | MOD_ALT` |
| Developer-mode detection | **CLI + CFG + env var** OR'd together |
| `inputs.log` location | **Project working directory** (next to `DRAW.run`) |
| File layout | **New `INPUT/INPUT.BI` + `INPUT/INPUT.BM`** — top-level input layer |
| Conflict policy | **Warn-only** to `inputs.log`, dev mode only |
| Context bitmask type | **`_UNSIGNED _INTEGER64`** (64 flags) |
| Event-handler context passing | **Shared state** — `INPUT_EVENT` struct populated by dispatcher, read by action handlers |

---

## 2. Architecture Overview

### Conceptual model (HTML analogy)

```
HTML:                              DRAW (new):
element.addEventListener(          INPUT_register
    'click',                           EVT_MOUSE_CLICK,
    handler);                          REGION_TOOLBAR, ...,
                                       ACT_TOOLBAR_CLICK
                                   
event.target / event.clientX       INPUT_EVENT.region / .mouseX
```

### Layer cake

```
┌─────────────────────────────────────────────────────────────┐
│  Action layer (existing)                                    │
│  CMD_execute_action <id>                                    │
│   - SELECT CASE in GUI/COMMAND.BM                           │
│   - Reads INPUT_EVENT shared state for context              │
└─────────────────────────────────────────────────────────────┘
                              ▲
                              │ fires action ID
                              │
┌─────────────────────────────────────────────────────────────┐
│  Dispatch layer (NEW: INPUT.BM)                             │
│  INPUT_dispatch_frame                                       │
│   - Iterates INPUT_BINDS table                              │
│   - For each match: populates INPUT_EVENT, calls action     │
└─────────────────────────────────────────────────────────────┘
                              ▲
                              │ "this event fired in this region"
                              │
┌─────────────────────────────────────────────────────────────┐
│  Event detection layer (NEW: INPUT.BM)                      │
│  - Keyboard: edge-detected key/chord                        │
│  - Mouse: click vs dblclick vs drag state machine           │
│  - Hover enter/leave (cursor crosses region bound)          │
│  - Wheel ticks                                              │
└─────────────────────────────────────────────────────────────┘
                              ▲
                              │ raw state
                              │
┌─────────────────────────────────────────────────────────────┐
│  Raw input layer (existing, lightly augmented)              │
│  - MODIFIERS struct (ctrl/shift/alt state)                  │
│  - MOUSE struct (B1/B2/B3 + OLD_B1/B2/B3 + X/Y + wheel)     │
│  - _KEYDOWN(<code>) for arbitrary key polling               │
│  - REGION_BOUNDS_TABLE (populated by GUI panels)            │
└─────────────────────────────────────────────────────────────┘
```

### Data flow per frame

1. **MODIFIERS_update** — read Ctrl/Shift/Alt state into `MODIFIERS` struct (existing)
2. **MOUSE_drain_update_state** — drain `_MOUSEINPUT` queue, update `MOUSE.X/Y/B1/B2/B3` (existing)
3. **GUI render pass** — each panel updates its `REGION_BOUNDS_TABLE` entry (NEW: panels need to call `REGION_set_bounds`)
4. **INPUT_update_context** — set `INPUT_CONTEXT~&&` bitmask from world state (NEW)
5. **INPUT_detect_events** — compute which events fired this frame (NEW)
6. **INPUT_dispatch_frame** — for each fired event, scan `INPUT_BINDS` table, fire matched handlers (NEW)
7. **Legacy handlers run** for `dispatched = FALSE` bindings until migrated

---

## 3. Core Types

```qb64
'==============================================================================
' INPUT_BIND — single declarative input binding
'==============================================================================
TYPE INPUT_BIND
    eventType      AS INTEGER            ' EVT_*
    region         AS INTEGER            ' REGION_*; REGION_GLOBAL for keyboard
    keycode        AS LONG               ' for EVT_KEY_*; 0 otherwise
    button         AS INTEGER            ' for EVT_MOUSE_*; 0 otherwise
    wheelDir       AS INTEGER            ' for EVT_MOUSE_WHEEL; +1 or -1
    requireMods    AS INTEGER            ' MOD_CTRL | MOD_SHIFT | MOD_ALT
    forbidMods     AS INTEGER            ' bits that must NOT be set
    requireCtx     AS _UNSIGNED _INTEGER64  ' all bits must be set
    forbidCtx      AS _UNSIGNED _INTEGER64  ' no bits may be set
    actionId       AS INTEGER            ' CMD_execute_action target
    dispatched     AS INTEGER            ' TRUE = new dispatcher fires; FALSE = legacy still owns
    label          AS STRING * 48
END TYPE

DIM SHARED INPUT_BINDS(1 TO 1024) AS INPUT_BIND
DIM SHARED INPUT_BIND_COUNT AS INTEGER

'==============================================================================
' REGION_BOUNDS — per-region screen rectangle; panels set this when they lay out
'==============================================================================
TYPE REGION_BOUNDS
    active     AS INTEGER       ' is region currently displayed?
    x          AS INTEGER
    y          AS INTEGER
    w          AS INTEGER
    h          AS INTEGER
    zOrder     AS INTEGER       ' for overlap; higher wins. Popups > panels > canvas.
END TYPE
DIM SHARED REGION_BOUNDS_TABLE(0 TO 63) AS REGION_BOUNDS

'==============================================================================
' INPUT_EVENT — context passed to action handlers during dispatch
' Read-only from the handler's perspective. Valid only inside CMD_execute_action
' for an action that was dispatched by INPUT_dispatch_frame.
'==============================================================================
TYPE INPUT_EVENT_OBJ
    eventType    AS INTEGER            ' which EVT_* fired
    region       AS INTEGER            ' which REGION_* it fired in (REGION_GLOBAL if keyboard)
    keycode      AS LONG               ' for key events
    button       AS INTEGER            ' for mouse events (1/2/3); gamepad button# / MIDI note# for those
    wheelDir     AS INTEGER            ' for wheel events
    mouseX       AS INTEGER            ' screen X at event time
    mouseY       AS INTEGER            ' screen Y at event time
    canvasX      AS INTEGER            ' canvas X (post-zoom/pan/snap)
    canvasY      AS INTEGER            ' canvas Y
    mods         AS INTEGER            ' MOD_CTRL | MOD_SHIFT | MOD_ALT bitmask snapshot
    ctx          AS _UNSIGNED _INTEGER64  ' context snapshot at event time
    value        AS SINGLE             ' continuous value: 0..1 analog, 0..127 MIDI, 0..1 tablet pressure
    value2       AS SINGLE             ' secondary axis (e.g. analog stick Y when value=X)
    device       AS INTEGER            ' DEVICE_KEYBOARD, DEVICE_MOUSE, DEVICE_GAMEPAD, DEVICE_MIDI, ...
    deviceIdx    AS INTEGER            ' 0 single-device; 0..N multi-device (gamepad 1 vs 2)
END TYPE
DIM SHARED INPUT_EVENT AS INPUT_EVENT_OBJ

'==============================================================================
' INPUT_CONTEXT — global 64-bit context mask, refreshed per frame
'==============================================================================
DIM SHARED INPUT_CONTEXT AS _UNSIGNED _INTEGER64

'==============================================================================
' DEV_MODE — true if any of: CLI --developer, CFG.DEVELOPER_MODE%, env DRAW_DEVELOPER=1
'==============================================================================
DIM SHARED DEV_MODE AS INTEGER
```

---

## 4. Event Catalog

```qb64
'------- Keyboard events -------
CONST EVT_KEY_PRESS          = 1   ' edge-detected key down (single-fire)
CONST EVT_KEY_RELEASE        = 2   ' edge-detected key up
CONST EVT_KEY_REPEAT         = 3   ' fires every N frames while held (for arrow-key repeat)

'------- Mouse button events -------
CONST EVT_MOUSE_DOWN         = 10  ' button down edge
CONST EVT_MOUSE_UP           = 11  ' button up edge
CONST EVT_MOUSE_CLICK        = 12  ' down + up within same region, no significant motion
CONST EVT_MOUSE_DBLCLICK     = 13  ' two CLICKs within 300ms in same region
CONST EVT_MOUSE_DRAG_START   = 14  ' button held + cursor moves > threshold
CONST EVT_MOUSE_DRAG_MOVE    = 15  ' fires per-frame while dragging
CONST EVT_MOUSE_DRAG_END     = 16  ' button up after drag

'------- Mouse cursor events -------
CONST EVT_MOUSE_HOVER_ENTER  = 17  ' cursor crosses into region (no buttons required)
CONST EVT_MOUSE_HOVER_LEAVE  = 18  ' cursor crosses out of region
CONST EVT_MOUSE_MOVE         = 19  ' fires per-frame while cursor over region (no buttons)
                                   ' — used by panel handlers to track sub-element transitions
                                   '   (e.g. toolbar button hover, layer row hover for tooltips).
                                   '   Only fires when cursor actually moved this frame
                                   '   (MOUSE.DX <> 0 OR MOUSE.DY <> 0).

'------- Wheel events -------
CONST EVT_MOUSE_WHEEL        = 20  ' wheel tick; wheelDir = +1 or -1
```

**Event lifecycle for mouse buttons** (state machine in `INPUT_detect_events`):

```
                       ┌──────────────┐
                       │    IDLE      │
                       └──────┬───────┘
                              │ button down
                              ▼
                       ┌──────────────┐
              ┌────────│   DOWN       │
              │        └──────┬───────┘
        no    │               │ cursor moves > drag threshold
        motion│               ▼
              │        ┌──────────────┐
              │        │  DRAGGING    │
              │        └──────┬───────┘
              │               │ button up
              │               ▼
              │        emit DRAG_END
              │
              │ button up (no significant move)
              ▼
        emit CLICK
              │
              │ if 2nd CLICK in <300ms over same region:
              ▼
        emit DBLCLICK
```

Each transition fires the corresponding EVT. CLICK fires only after UP confirms no drag happened. DBLCLICK fires after the 2nd click and *also* fires the underlying CLICK (handlers that care about distinguishing can check the event type).

---

## 5. Region Catalog

```qb64
'------- Logical regions (each is a screen-space hitbox) -------
CONST REGION_GLOBAL         = 0   ' fires regardless of cursor location (for keyboard)
CONST REGION_CANVAS         = 1   ' the drawing canvas (post-zoom/pan)
CONST REGION_TOOLBAR        = 2
CONST REGION_MENUBAR        = 3
CONST REGION_LAYER_PANEL    = 4
CONST REGION_PALETTE_STRIP  = 5
CONST REGION_EDIT_BAR       = 6
CONST REGION_ADV_BAR        = 7
CONST REGION_STATUS_BAR     = 8
CONST REGION_DRAWER         = 9
CONST REGION_PREVIEW        = 10
CONST REGION_COLOR_MIXER    = 11
CONST REGION_IMAGE_BROWSER  = 12
CONST REGION_CHARMAP        = 13
CONST REGION_ORGANIZER      = 14
CONST REGION_COMMAND_PALETTE = 15
CONST REGION_SETTINGS_DLG    = 16
CONST REGION_FILE_DIALOG     = 17
CONST REGION_POPUP_MENU      = 18  ' generic popup; z-order highest below modals
CONST REGION_TOOLTIP         = 19  ' rendered but doesn't consume events
CONST REGION_PIXEL_COACH     = 20
CONST REGION_TRANSPARENCY_CHECKERBOARD = 21
CONST REGION_SMART_GUIDES    = 22  ' overlay
' ... up to 63 ...

'------- Z-order convention (higher wins overlap) -------
CONST ZORDER_CANVAS     = 0    ' base
CONST ZORDER_PANEL      = 100  ' toolbar, layer panel, palette, etc.
CONST ZORDER_POPUP_MENU = 500  ' popup menus over panels
CONST ZORDER_MODAL_DIALOG = 1000 ' settings dialog, file dialog
CONST ZORDER_TOOLTIP    = 9999 ' always on top but non-blocking (never consumes input)
```

Each panel's render code calls `REGION_set_bounds REGION_<NAME>, x, y, w, h, ZORDER_PANEL` when it lays itself out. Hidden panels call `REGION_set_bounds REGION_<NAME>, 0, 0, 0, 0, ZORDER_PANEL : REGION_BOUNDS_TABLE(REGION_<NAME>).active = FALSE` (or use `REGION_set_inactive REGION_<NAME>`).

---

## 6. Context Catalog

```qb64
'------- Mode flags (subsystem state) — bits 0..19 -------
CONST CTX_TEXT_ACTIVE         = 2^0  ' text tool typing
CONST CTX_FILE_DIALOG_OPEN    = 2^1
CONST CTX_IMAGE_IMPORT_ACTIVE = 2^2
CONST CTX_REFIMG_REPOSITION   = 2^3
CONST CTX_MAGIC_WAND_ACTIVE   = 2^4
CONST CTX_MOVE_ACTIVE         = 2^5
CONST CTX_GRID_OFFSET_PICK    = 2^6
CONST CTX_SETTINGS_OPEN       = 2^7
CONST CTX_POPUP_MENU_OPEN     = 2^8
CONST CTX_COMMAND_PALETTE_OPEN = 2^9
CONST CTX_TRANSFORM_ACTIVE    = 2^10
CONST CTX_DRAWING_IN_PROGRESS = 2^11  ' tool stroke mid-drag
' (12-19 reserved)

'------- Held-key flags — bits 20..31 -------
CONST CTX_G_HELD              = 2^20  ' G chord initiator
CONST CTX_M_HELD              = 2^21  ' M marquee chord
CONST CTX_Z_HELD              = 2^22  ' Z zoom chord
CONST CTX_E_HELD              = 2^23  ' E (eraser / magic wand modifier)
CONST CTX_F_HELD              = 2^24  ' F (magic wand modifier)
CONST CTX_W_HELD              = 2^25  ' W (magic wand modifier)
CONST CTX_SPACE_HELD          = 2^26  ' Space (pan)
CONST CTX_ALT_HELD            = 2^27  ' Alt (clone/picker held-mode)
' (28-31 reserved for future chord initiators)

'------- Cursor-region flags (which region cursor is currently over) — bits 32..63 -------
' These are auto-computed by INPUT_update_context from REGION_BOUNDS_TABLE
CONST CTX_OVER_CANVAS         = 2^32
CONST CTX_OVER_TOOLBAR        = 2^33
CONST CTX_OVER_MENUBAR        = 2^34
CONST CTX_OVER_LAYER_PANEL    = 2^35
CONST CTX_OVER_PALETTE        = 2^36
CONST CTX_OVER_EDIT_BAR       = 2^37
CONST CTX_OVER_ADV_BAR        = 2^38
' ... matching the REGION_ catalog above ...
```

**`INPUT_update_context` sets all of these once per frame** before dispatch.

---

## 7. Registration API

```qb64
'==============================================================================
' Main registration entry point — used for everything.
' Returns binding index for the auditor; caller may ignore.
'==============================================================================
FUNCTION INPUT_register% ( _
    eventType   AS INTEGER, _
    region      AS INTEGER, _
    keycode     AS LONG, _
    button      AS INTEGER, _
    wheelDir    AS INTEGER, _
    requireMods AS INTEGER, _
    forbidMods  AS INTEGER, _
    requireCtx  AS _UNSIGNED _INTEGER64, _
    forbidCtx   AS _UNSIGNED _INTEGER64, _
    actionId    AS INTEGER, _
    dispatched  AS INTEGER, _
    label       AS STRING)

'==============================================================================
' Convenience wrappers (most call sites use these for readability)
'==============================================================================
FUNCTION INPUT_register_key% (keycode AS LONG, requireMods AS INTEGER, forbidMods AS INTEGER, requireCtx AS _UNSIGNED _INTEGER64, forbidCtx AS _UNSIGNED _INTEGER64, actionId AS INTEGER, dispatched AS INTEGER, label AS STRING)

FUNCTION INPUT_register_mouse% (eventType AS INTEGER, region AS INTEGER, button AS INTEGER, requireMods AS INTEGER, forbidMods AS INTEGER, requireCtx AS _UNSIGNED _INTEGER64, forbidCtx AS _UNSIGNED _INTEGER64, actionId AS INTEGER, dispatched AS INTEGER, label AS STRING)

FUNCTION INPUT_register_wheel% (region AS INTEGER, wheelDir AS INTEGER, requireMods AS INTEGER, forbidMods AS INTEGER, requireCtx AS _UNSIGNED _INTEGER64, forbidCtx AS _UNSIGNED _INTEGER64, actionId AS INTEGER, dispatched AS INTEGER, label AS STRING)

FUNCTION INPUT_register_hover% (region AS INTEGER, enter_or_leave AS INTEGER, actionId AS INTEGER, dispatched AS INTEGER, label AS STRING)

'==============================================================================
' Region bounds
'==============================================================================
SUB REGION_set_bounds (region AS INTEGER, x AS INTEGER, y AS INTEGER, w AS INTEGER, h AS INTEGER, zOrder AS INTEGER)
SUB REGION_set_inactive (region AS INTEGER)
SUB REGION_clear_all ()  ' called on display-scale change; panels re-set on next render
FUNCTION REGION_hit_test% (mouseX AS INTEGER, mouseY AS INTEGER)  ' returns topmost REGION_ at coord
```

### **Invariant (every panel must honor)**

> **Every visible panel MUST call `REGION_set_bounds` in its render SUB.**
> **Every hidden panel MUST call `REGION_set_inactive` when hiding (or first frame after hiding).**

Violations cause stale-bounds hit-test bugs. Dev mode's `REGION_check_consistency` audits this every frame and logs warnings to `inputs.log` (see §13d).

### Example call sites (these are what panels would write)

```qb64
' --- At INPUTS_init time (once at startup) ---

' Keyboard: Ctrl+Z = undo (REGION_GLOBAL so it fires regardless of cursor)
INPUT_register_key 122, MOD_CTRL, MOD_SHIFT OR MOD_ALT, 0, CTX_TEXT_ACTIVE OR CTX_FILE_DIALOG_OPEN, ACT_UNDO, TRUE, "Undo"

' Keyboard chord: G+Ctrl+R = full grid reset
INPUT_register_key 114, MOD_CTRL, MOD_SHIFT OR MOD_ALT, CTX_G_HELD, CTX_TEXT_ACTIVE, ACT_GRID_RESET_ALL, TRUE, "Reset grid (offset + size)"

' Mouse click on toolbar
INPUT_register_mouse EVT_MOUSE_CLICK, REGION_TOOLBAR, 1, 0, MOD_CTRL OR MOD_SHIFT OR MOD_ALT, 0, 0, ACT_TOOLBAR_CLICK, TRUE, "Toolbar click"

' Mouse drag on canvas (left button)
INPUT_register_mouse EVT_MOUSE_DRAG_START, REGION_CANVAS, 1, 0, 0, 0, CTX_TEXT_ACTIVE OR CTX_FILE_DIALOG_OPEN, ACT_TOOL_BEGIN_STROKE, TRUE, "Begin tool stroke"

' Mouse wheel zoom (Ctrl + wheel-up on canvas)
INPUT_register_wheel REGION_CANVAS, 1, MOD_CTRL, MOD_SHIFT OR MOD_ALT, 0, 0, ACT_ZOOM_IN, TRUE, "Zoom in"

' Hover effect on layer panel
INPUT_register_hover REGION_LAYER_PANEL, EVT_MOUSE_HOVER_ENTER, ACT_LAYER_PANEL_HOVER_ON, TRUE, "Layer panel hover"

' --- During panel render (every frame they're visible) ---

SUB TOOLBAR_render ()
    ' ... compute toolbar layout ...
    REGION_set_bounds REGION_TOOLBAR, tx, ty, tw, th, ZORDER_PANEL
    ' ... draw toolbar ...
END SUB

SUB TOOLBAR_hide ()
    REGION_set_inactive REGION_TOOLBAR
END SUB

' --- Inside action handlers (read INPUT_EVENT for context) ---

' In GUI/COMMAND.BM CMD_execute_action:
CASE ACT_TOOLBAR_CLICK
    DIM tbButton AS INTEGER
    tbButton% = TOOLBAR_button_at%(INPUT_EVENT.mouseX, INPUT_EVENT.mouseY)
    IF tbButton% > 0 THEN TOOLBAR_dispatch_button tbButton%
```

---

## 8. Event Detection — per-frame algorithm

`SUB INPUT_detect_events` runs once per frame, populates a per-frame `DETECTED_EVENTS` queue that `INPUT_dispatch_frame` then consumes.

### Pseudocode

```
SUB INPUT_detect_events
    ' --- Keyboard ---
    FOR each registered EVT_KEY_PRESS binding b:
        kc = b.keycode
        ' Letter case insensitivity: if lowercase, also check uppercase
        keyDown = _KEYDOWN(kc) OR (kc >= 97 AND kc <= 122 AND _KEYDOWN(kc - 32))
        edge = keyDown AND NOT KEY_DOWN_LAST(b.index)
        KEY_DOWN_LAST(b.index) = keyDown
        IF edge THEN enqueue_event EVT_KEY_PRESS, REGION_GLOBAL, b.keycode, ...
    NEXT
    
    ' --- Mouse buttons ---
    FOR btn = 1 TO 3:
        bDown = MOUSE.B<btn>%
        bDownLast = MOUSE.OLD_B<btn>%
        region = REGION_hit_test%(MOUSE.RAW_X%, MOUSE.RAW_Y%)
        
        IF bDown AND NOT bDownLast THEN
            ' DOWN edge
            MOUSE_DOWN_REGION(btn) = region
            MOUSE_DOWN_X(btn) = MOUSE.RAW_X%
            MOUSE_DOWN_Y(btn) = MOUSE.RAW_Y%
            MOUSE_DOWN_TIME(btn) = TIMER
            MOUSE_DRAG_STARTED(btn) = FALSE
            enqueue_event EVT_MOUSE_DOWN, region, 0, btn, ...
        ELSEIF bDown AND bDownLast THEN
            ' Held: check for drag start
            IF NOT MOUSE_DRAG_STARTED(btn) THEN
                dx = ABS(MOUSE.RAW_X% - MOUSE_DOWN_X(btn))
                dy = ABS(MOUSE.RAW_Y% - MOUSE_DOWN_Y(btn))
                IF dx > DRAG_THRESHOLD OR dy > DRAG_THRESHOLD THEN
                    MOUSE_DRAG_STARTED(btn) = TRUE
                    enqueue_event EVT_MOUSE_DRAG_START, MOUSE_DOWN_REGION(btn), 0, btn, ...
                END IF
            END IF
            IF MOUSE_DRAG_STARTED(btn) THEN
                enqueue_event EVT_MOUSE_DRAG_MOVE, MOUSE_DOWN_REGION(btn), 0, btn, ...
            END IF
        ELSEIF NOT bDown AND bDownLast THEN
            ' UP edge
            IF MOUSE_DRAG_STARTED(btn) THEN
                enqueue_event EVT_MOUSE_DRAG_END, MOUSE_DOWN_REGION(btn), 0, btn, ...
            ELSE
                ' Click (no significant motion)
                IF region = MOUSE_DOWN_REGION(btn) THEN
                    enqueue_event EVT_MOUSE_CLICK, region, 0, btn, ...
                    ' Double-click check
                    IF (TIMER - MOUSE_LAST_CLICK_TIME(btn)) < DBLCLICK_WINDOW AND _
                       MOUSE_LAST_CLICK_REGION(btn) = region THEN
                        enqueue_event EVT_MOUSE_DBLCLICK, region, 0, btn, ...
                        MOUSE_LAST_CLICK_TIME(btn) = 0  ' prevent triple-click being read as another dbl
                    ELSE
                        MOUSE_LAST_CLICK_TIME(btn) = TIMER
                        MOUSE_LAST_CLICK_REGION(btn) = region
                    END IF
                END IF
            END IF
            enqueue_event EVT_MOUSE_UP, region, 0, btn, ...
        END IF
    NEXT
    
    ' --- Hover enter/leave ---
    currentHoverRegion = REGION_hit_test%(MOUSE.RAW_X%, MOUSE.RAW_Y%)
    IF currentHoverRegion <> HOVER_REGION_LAST THEN
        IF HOVER_REGION_LAST <> 0 THEN enqueue_event EVT_MOUSE_HOVER_LEAVE, HOVER_REGION_LAST, ...
        IF currentHoverRegion <> 0 THEN enqueue_event EVT_MOUSE_HOVER_ENTER, currentHoverRegion, ...
        HOVER_REGION_LAST = currentHoverRegion
    END IF
    
    ' --- Wheel ---
    IF MOUSE.WHEEL <> 0 THEN
        region = REGION_hit_test%(MOUSE.RAW_X%, MOUSE.RAW_Y%)
        wheelDir = SGN(MOUSE.WHEEL)
        enqueue_event EVT_MOUSE_WHEEL, region, 0, 0, wheelDir, ...
    END IF
END SUB
```

### Constants

```qb64
CONST DRAG_THRESHOLD = 3      ' pixels — must move this far before DRAG_START fires
CONST DBLCLICK_WINDOW = 0.3   ' seconds — max gap for double-click
```

---

## 9. Region Hit-Test + Z-Order

```qb64
FUNCTION REGION_hit_test% (mouseX AS INTEGER, mouseY AS INTEGER)
    DIM i AS INTEGER
    DIM bestZ AS INTEGER
    DIM bestRegion AS INTEGER
    bestZ = -1
    bestRegion = REGION_GLOBAL  ' fallback
    FOR i = 1 TO 63
        IF REGION_BOUNDS_TABLE(i).active% THEN
            IF mouseX >= REGION_BOUNDS_TABLE(i).x AND _
               mouseX <  REGION_BOUNDS_TABLE(i).x + REGION_BOUNDS_TABLE(i).w AND _
               mouseY >= REGION_BOUNDS_TABLE(i).y AND _
               mouseY <  REGION_BOUNDS_TABLE(i).y + REGION_BOUNDS_TABLE(i).h THEN
                IF REGION_BOUNDS_TABLE(i).zOrder > bestZ THEN
                    bestZ = REGION_BOUNDS_TABLE(i).zOrder
                    bestRegion = i
                END IF
            END IF
        END IF
    NEXT
    REGION_hit_test% = bestRegion
END FUNCTION
```

Higher z-order wins. REGION_TOOLTIP has z=9999 but **its `active` is always FALSE for hit-testing** — tooltips render but don't consume events.

For 30-50 regions × 10 hit-tests per frame (per event), that's ~300-500 simple comparisons per frame. At 60 FPS = 30k ops/sec. Trivial.

---

## 10. Dispatcher

```qb64
SUB INPUT_dispatch_frame ()
    DIM i AS INTEGER
    DIM e AS INTEGER
    FOR e = 1 TO DETECTED_EVENT_COUNT
        ' Populate INPUT_EVENT shared state for handler context
        INPUT_EVENT.eventType = DETECTED_EVENTS(e).eventType
        INPUT_EVENT.region    = DETECTED_EVENTS(e).region
        INPUT_EVENT.keycode   = DETECTED_EVENTS(e).keycode
        INPUT_EVENT.button    = DETECTED_EVENTS(e).button
        INPUT_EVENT.wheelDir  = DETECTED_EVENTS(e).wheelDir
        INPUT_EVENT.mouseX    = DETECTED_EVENTS(e).mouseX
        INPUT_EVENT.mouseY    = DETECTED_EVENTS(e).mouseY
        INPUT_EVENT.canvasX   = DETECTED_EVENTS(e).canvasX
        INPUT_EVENT.canvasY   = DETECTED_EVENTS(e).canvasY
        INPUT_EVENT.mods      = MOUSE_MODS_NOW%  ' snapshot
        INPUT_EVENT.ctx       = INPUT_CONTEXT
        
        ' Find first matching dispatched binding (registration order)
        FOR i = 1 TO INPUT_BIND_COUNT
            IF NOT INPUT_BINDS(i).dispatched THEN _CONTINUE  ' skip legacy metadata
            IF INPUT_BIND_matches%(i, DETECTED_EVENTS(e)) THEN
                CMD_execute_action INPUT_BINDS(i).actionId
                EXIT FOR   ' first match wins (registration order = priority)
            END IF
        NEXT i
    NEXT e
    DETECTED_EVENT_COUNT = 0
END SUB

FUNCTION INPUT_BIND_matches% (bindIdx AS INTEGER, evt AS DETECTED_EVENT)
    DIM b AS INPUT_BIND
    b = INPUT_BINDS(bindIdx)
    
    IF b.eventType <> evt.eventType THEN INPUT_BIND_matches% = FALSE : EXIT FUNCTION
    IF b.region <> REGION_GLOBAL AND b.region <> evt.region THEN INPUT_BIND_matches% = FALSE : EXIT FUNCTION
    IF b.keycode <> 0 AND b.keycode <> evt.keycode AND b.keycode <> (evt.keycode + 32) THEN INPUT_BIND_matches% = FALSE : EXIT FUNCTION
    IF b.button <> 0 AND b.button <> evt.button THEN INPUT_BIND_matches% = FALSE : EXIT FUNCTION
    IF b.wheelDir <> 0 AND b.wheelDir <> evt.wheelDir THEN INPUT_BIND_matches% = FALSE : EXIT FUNCTION
    IF (MOUSE_MODS_NOW% AND b.requireMods) <> b.requireMods THEN INPUT_BIND_matches% = FALSE : EXIT FUNCTION
    IF (MOUSE_MODS_NOW% AND b.forbidMods) <> 0 THEN INPUT_BIND_matches% = FALSE : EXIT FUNCTION
    IF (INPUT_CONTEXT AND b.requireCtx) <> b.requireCtx THEN INPUT_BIND_matches% = FALSE : EXIT FUNCTION
    IF (INPUT_CONTEXT AND b.forbidCtx) <> 0 THEN INPUT_BIND_matches% = FALSE : EXIT FUNCTION
    
    INPUT_BIND_matches% = TRUE
END FUNCTION
```

**First-match-wins** via registration order. Panels register first; canvas last. This means popup → panel → canvas priority falls out naturally if we register in z-order top-down.

---

## 11. Audit + Dev Mode + `inputs.log`

```qb64
'==============================================================================
' Developer mode detection
'==============================================================================
SUB INPUTS_init ()
    ' OR together every source
    DEV_MODE% = FALSE
    IF CFG.DEVELOPER_MODE% THEN DEV_MODE% = TRUE
    IF ENVIRON$("DRAW_DEVELOPER") = "1" THEN DEV_MODE% = TRUE
    DIM i AS INTEGER
    FOR i = 1 TO _COMMANDCOUNT
        IF COMMAND$(i) = "--developer" THEN DEV_MODE% = TRUE
    NEXT
    
    INPUTS_LOG_PATH$ = "./inputs.log"  ' working directory
    
    ' Clear log on each startup
    IF DEV_MODE% THEN
        DIM fh AS INTEGER : fh = FREEFILE
        OPEN INPUTS_LOG_PATH$ FOR OUTPUT AS #fh : CLOSE #fh
        INPUTS_log "[INIT] DRAW " + APP_VERSION$ + " developer mode active, pid " + STR$(_PID)
    END IF
END SUB

SUB INPUTS_log (msg AS STRING)
    IF NOT DEV_MODE% THEN EXIT SUB
    DIM fh AS INTEGER : fh = FREEFILE
    OPEN INPUTS_LOG_PATH$ FOR APPEND AS #fh
    PRINT #fh, "[" + STR$(TIMER) + "] " + msg
    CLOSE #fh
END SUB

SUB INPUT_audit ()
    IF NOT DEV_MODE% THEN EXIT SUB
    INPUTS_log "[AUDIT] Scanning " + STR$(INPUT_BIND_COUNT) + " bindings for conflicts"
    DIM i AS INTEGER, j AS INTEGER, conflicts AS INTEGER
    conflicts = 0
    FOR i = 1 TO INPUT_BIND_COUNT
        FOR j = i + 1 TO INPUT_BIND_COUNT
            IF INPUT_BINDS_could_collide%(i, j) THEN
                INPUTS_log "[CONFLICT] " + _
                    "(" + STR$(i) + ") " + RTRIM$(INPUT_BINDS(i).label) + _
                    " <-> " + _
                    "(" + STR$(j) + ") " + RTRIM$(INPUT_BINDS(j).label)
                conflicts = conflicts + 1
            END IF
        NEXT j
    NEXT i
    INPUTS_log "[AUDIT] Complete: " + STR$(conflicts) + " conflicts found"
END SUB

FUNCTION INPUT_BINDS_could_collide% (a AS INTEGER, b AS INTEGER)
    ' Two bindings can collide if there exists any input + context state
    ' that would match both at the same time.
    
    IF INPUT_BINDS(a).eventType <> INPUT_BINDS(b).eventType THEN
        INPUT_BINDS_could_collide% = FALSE : EXIT FUNCTION
    END IF
    
    ' Region: collide if same region, OR one is REGION_GLOBAL (matches all)
    IF INPUT_BINDS(a).region <> REGION_GLOBAL AND _
       INPUT_BINDS(b).region <> REGION_GLOBAL AND _
       INPUT_BINDS(a).region <> INPUT_BINDS(b).region THEN
        INPUT_BINDS_could_collide% = FALSE : EXIT FUNCTION
    END IF
    
    ' Keycode: collide if same code OR either is 0 (any)
    IF INPUT_BINDS(a).keycode <> 0 AND INPUT_BINDS(b).keycode <> 0 AND _
       INPUT_BINDS(a).keycode <> INPUT_BINDS(b).keycode THEN
        INPUT_BINDS_could_collide% = FALSE : EXIT FUNCTION
    END IF
    
    ' Button: same logic
    IF INPUT_BINDS(a).button <> 0 AND INPUT_BINDS(b).button <> 0 AND _
       INPUT_BINDS(a).button <> INPUT_BINDS(b).button THEN
        INPUT_BINDS_could_collide% = FALSE : EXIT FUNCTION
    END IF
    
    ' Modifiers: collide if there's no modifier state that one requires/forbids
    ' that the other forbids/requires. (intersection of accepting sets is non-empty)
    IF (INPUT_BINDS(a).requireMods AND INPUT_BINDS(b).forbidMods) <> 0 THEN
        INPUT_BINDS_could_collide% = FALSE : EXIT FUNCTION
    END IF
    IF (INPUT_BINDS(b).requireMods AND INPUT_BINDS(a).forbidMods) <> 0 THEN
        INPUT_BINDS_could_collide% = FALSE : EXIT FUNCTION
    END IF
    
    ' Context: same logic
    IF (INPUT_BINDS(a).requireCtx AND INPUT_BINDS(b).forbidCtx) <> 0 THEN
        INPUT_BINDS_could_collide% = FALSE : EXIT FUNCTION
    END IF
    IF (INPUT_BINDS(b).requireCtx AND INPUT_BINDS(a).forbidCtx) <> 0 THEN
        INPUT_BINDS_could_collide% = FALSE : EXIT FUNCTION
    END IF
    
    INPUT_BINDS_could_collide% = TRUE
END FUNCTION
```

`inputs.log` location: **project working directory** (`./inputs.log`), per user decision. Cleared on each startup so the audit + runtime events are fresh.

Runtime event logging (optional but useful in dev mode): every dispatched event writes a one-line entry. With CFG.LOG_LEVEL filtering so it doesn't fill the disk.

---

## 12. Helper Utilities (idiom unifications from discovery agents)

These were identified by the 5 idiom-discovery agents as high-payoff DRY wins. They land in this branch alongside the input refactor because the input code uses several of them.

### 12.1 `SAFE_FREEIMAGE`

The discovery agents found **216 unguarded `_FREEIMAGE` calls** vs 413 properly guarded. Single helper eliminates the inconsistency:

```qb64
SUB SAFE_FREEIMAGE (handle AS LONG)
    IF handle < -1 THEN _FREEIMAGE handle
END SUB
```

Migration: replace 216 sites with `SAFE_FREEIMAGE h&`. Saves a guard line and prevents wrong-pattern variants.

### 12.2 `DEST_SAVE` / `DEST_RESTORE` (and `SRC_SAVE` / `SRC_RESTORE`, `FONT_SAVE` / `FONT_RESTORE`)

Found `_DEST` set without restore in 8+ places, including `ABOUT.BM` (saves `_SOURCE` but never restores it). Helper pattern:

```qb64
' Stack-based save/restore (4-level stack — sufficient for nesting depth)
DIM SHARED DEST_STACK(4) AS LONG : DIM SHARED DEST_STACK_DEPTH AS INTEGER

SUB DEST_SAVE ()
    IF DEST_STACK_DEPTH >= 4 THEN _LOGERROR "DEST_SAVE stack overflow" : EXIT SUB
    DEST_STACK_DEPTH = DEST_STACK_DEPTH + 1
    DEST_STACK(DEST_STACK_DEPTH) = _DEST
END SUB

SUB DEST_RESTORE ()
    IF DEST_STACK_DEPTH <= 0 THEN _LOGERROR "DEST_RESTORE stack underflow" : EXIT SUB
    _DEST DEST_STACK(DEST_STACK_DEPTH)
    DEST_STACK_DEPTH = DEST_STACK_DEPTH - 1
END SUB

' Same for SOURCE_SAVE/RESTORE and FONT_SAVE/RESTORE.
```

Usage:
```qb64
DEST_SAVE : _DEST tmpImg& : ... : DEST_RESTORE
```

The stack catches caller errors with explicit log lines instead of silent corruption.

### 12.3 `PIXEL_DOUBLE_AXIS`

Four identical loops (CASE 331, CASE 333, CUSTOM_BRUSH_scale_2x_horizontal, CUSTOM_BRUSH_scale_2x_vertical). Unify:

```qb64
' axis: 0 = horizontal (double width), 1 = vertical (double height)
SUB PIXEL_DOUBLE_AXIS (srcImg AS LONG, dstImg AS LONG, axis AS INTEGER)
    DIM sw AS INTEGER, sh AS INTEGER, px AS INTEGER, py AS INTEGER
    DIM p AS _UNSIGNED LONG
    sw = _WIDTH(srcImg) : sh = _HEIGHT(srcImg)
    SOURCE_SAVE : DEST_SAVE
    _SOURCE srcImg : _DEST dstImg
    _DONTBLEND dstImg
    CLS , _RGBA32(0, 0, 0, 0)
    FOR py = 0 TO sh - 1
        FOR px = 0 TO sw - 1
            p = POINT(px, py)
            IF axis = 0 THEN
                PSET (px * 2,     py), p
                PSET (px * 2 + 1, py), p
            ELSE
                PSET (px,     py * 2),     p
                PSET (px, py * 2 + 1), p
            END IF
        NEXT
    NEXT
    _BLEND dstImg
    SOURCE_RESTORE : DEST_RESTORE
END SUB
```

Removes ~80 LOC of duplication.

### 12.4 `SCENE_invalidate` / `SCENE_request_render`

Discovery agent found ~50 inconsistent `SCENE_DIRTY% = TRUE` / `FRAME_IDLE% = FALSE` pairings. Helper documents and enforces the pairing rule:

```qb64
' Visual content changed; full re-render required.
SUB SCENE_invalidate ()
    SCENE_DIRTY% = TRUE
    FRAME_IDLE% = FALSE
END SUB

' Scene cache invalidated but no visual change yet (e.g. blend cache flush).
SUB SCENE_request_render ()
    SCENE_DIRTY% = TRUE
END SUB
```

### 12.5 `MODS_only%` precomputed modifier-combo check

Discovery agent found 15+ manual `MODIFIERS.ctrl% AND NOT MODIFIERS.shift% AND NOT MODIFIERS.alt%` chains. Replace with:

```qb64
FUNCTION MODS_only% (wantMods AS INTEGER)
    DIM now AS INTEGER
    now = 0
    IF MODIFIERS.ctrl%  THEN now = now OR MOD_CTRL
    IF MODIFIERS.shift% THEN now = now OR MOD_SHIFT
    IF MODIFIERS.alt%   THEN now = now OR MOD_ALT
    MODS_only% = (now = wantMods)
END FUNCTION
```

Usage:
```qb64
IF MODS_only%(MOD_CTRL) THEN ...  ' only Ctrl, no other mods
```

### 12.6 Settings dialog runtime-sync (already fixed inline, document the pattern)

The bar-visibility bug we fixed (`fix(settings): don't clobber runtime bar visibility on Apply`) is the canonical pattern for any settings-change side effect:
1. Snapshot OLD CFG values BEFORE `CFG = SETTINGS_CFG`
2. After assignment, IF CFG.X <> oldX THEN trigger side effect

Document this in CLAUDE.md as a required pattern for new settings.

### 12.7 Pattern documentation (no code, just CLAUDE.md updates)

These don't get helpers but should be elevated to CLAUDE.md gotchas:
- HISTORY_record_* coverage in MOUSE handlers (trace + document where each tool records)
- Selection staging for Marquee + Magic Wand tool activation
- Apron coord offset access pattern (`LAYER_POINT` accessor helper, post-input-refactor)

---

## 13. Migration Plan

### Phase 0 — Infrastructure (~1 commit, ~800 LOC added)
- `INPUT/INPUT.BI` — all TYPEs and CONSTs (Sections 3-6)
- `INPUT/INPUT.BM` — registration API, event detection, region hit-test, dispatcher, audit, log helpers
- `CFG/CONFIG.BI` + `CONFIG.BM` — add `DEVELOPER_MODE%` CFG field
- `_ALL.BI` / `_ALL.BM` — wire in
- `DRAW.BAS` main loop — add `INPUT_update_context` / `INPUT_detect_events` / `INPUT_dispatch_frame` calls ABOVE existing `KEYBOARD_input_handler` / `MOUSE_input_handler` calls (legacy still runs for `dispatched = FALSE` bindings)
- `INPUTS_init` called at startup, runs `INPUT_audit` if `DEV_MODE%`
- Helper utilities from §12 (SAFE_FREEIMAGE, DEST/SOURCE/FONT save-restore, PIXEL_DOUBLE_AXIS, SCENE_invalidate, MODS_only)

**Behavior change**: zero. Empty binding table.

### Phase 1 — Register all keyboard bindings as metadata (~1 commit, ~150 registrations)
Walk every `_KEYDOWN(...)` site in KEYBOARD.BM, add `INPUT_register_key` calls with `dispatched = FALSE`. Group by area:
- `KEYBOARD_tools` cases (B, F, D, L, P, R, C, E, M, W, V, T, Z) — ~15 registrations
- `KEYBOARD_layers` Ctrl+letter ops — ~25 registrations
- `KEYBOARD_input_handler` inline blocks — ~50 registrations (Ctrl+R, Ctrl+Alt+R, Ctrl+Shift+Q, G-chord, M-chord, Z-chord, eraser hold, smart shape, etc.)
- `KEYBOARD_colors` (1-0 opacity) — ~10 registrations
- Special context handlers (text-tool, image-import, file-dialog) — ~30 registrations
- Function keys, brush-size keys, view toggles — ~20 registrations

After this commit: `INPUT_audit` first runs, dumps every existing conflict to `inputs.log`. Expected: 10-30 surprises.

### Phase 2 — Migrate every GUI panel to REGION system (~5-8 commits, one per panel cluster)
Each panel:
1. Add `REGION_set_bounds REGION_<NAME>, x, y, w, h, ZORDER_PANEL` call in its render SUB
2. Add `REGION_set_inactive REGION_<NAME>` in its hide path
3. Replace `<PANEL>_is_over_area%` callers — central dispatcher uses `REGION_hit_test%` instead

Panel order (simplest to most complex):
- **2a**: Status bar, edit bar, adv bar (single-rect panels)
- **2b**: Toolbar, palette strip (multi-button regions; click handler reads `INPUT_EVENT.mouseX/Y` to find which button)
- **2c**: Layer panel, drawer, preview (complex internal hit-testing)
- **2d**: Menubar + popup menus (multi-region with z-order)
- **2e**: Modal dialogs (settings, file dialog, image browser, charmap) — highest z-order

### Phase 3 — Register all mouse event bindings (~3-5 commits)
Now that panels have regions, register mouse events:
- Click handlers for each panel button cluster
- Drag handlers for canvas (tool strokes)
- Wheel handlers for canvas (zoom) and panels (scroll)
- Hover enter/leave for tooltips, button highlight
- Right-click context menus (REGION_LAYER_PANEL, REGION_PALETTE_STRIP, etc.)

All `dispatched = FALSE` initially. Audit dumps conflicts.

### Phase 4 — Resolve all audit-reported conflicts (~2-3 commits)
For each conflict in `inputs.log`:
- Tighten `forbidCtx` on one binding
- Tighten `forbidMods` on one binding
- Fix genuine bugs (where two handlers genuinely race)

### Phase 5 — Idiom helper migration (~2-3 commits)
Apply helpers from §12 to existing code:
- Replace 216 unguarded `_FREEIMAGE` with `SAFE_FREEIMAGE`
- Replace 8+ unbalanced _DEST/_SOURCE patterns with stack helpers
- Consolidate 4 pixel-doubling loops to `PIXEL_DOUBLE_AXIS`
- Replace ~50 inconsistent dirty-flag pairs with `SCENE_invalidate` / `SCENE_request_render`
- Replace 15+ manual modifier chains with `MODS_only%`

### Phase 6 — Opportunistic dispatch migration (~ongoing)
Convert legacy `dispatched = FALSE` bindings to `dispatched = TRUE`, deleting inline handler code. Easy candidates first (simple Ctrl+letter actions). State machines stay legacy indefinitely.

### Phase 7 — Documentation (~1 commit)
- Update `CLAUDE.md`: replace stale BINDINGS.B[IM] mention; add input-system overview; cross-reference idiom helpers
- Create `.claude/instructions/input-system.md`: full implementation guide for future contributors
- Update `CHEATSHEET.md` if any hotkey changes (none expected; this refactor is behavior-preserving)
- Save memories:
  - `feedback_input_registration_first.md` — "before adding a chord or click handler, write the `INPUT_register` line first"
  - `feedback_region_bounds_must_be_set.md` — "every visible panel must call `REGION_set_bounds` in its render SUB"

### Phase 8 — Manual QA (~1 commit if fixes needed)
Run `PLANS/TESTS/` checklists in dev mode. Every panel, every keyboard chord, every drag operation. Verify `inputs.log` is empty of warnings post-audit. Fix any regressions found.

### Phase 9 — Merge to main

---

## 13b. Performance Guarantee (must be cheaper than current, never slower)

**Required**: net per-frame CPU cost MUST decrease or stay flat.

### Current cost (baseline to beat)

Per frame in `KEYBOARD_input_handler` + `MOUSE_input_handler`:
- ~50+ `_KEYDOWN(<code>)` polls — each inline handler block evaluates its IF even when no key is pressed
- ~20+ `MODIFIERS.*` reads per frame across all handlers
- For each mouse event: ~15 `<PANEL>_is_over_area%` linear-cascade tests
- ~10 `STATIC pressed%` edge-detection blocks always evaluating
- Mouse drag-state machine duplicated in every tool's per-frame handler

Rough estimate: 200-400 ops per frame even when **nothing is happening**.

### New design cost

Per frame:
1. **`INPUT_update_context`** — ~30 IF/OR ops (write the 64-bit mask). Always runs. **Cost: ~30 ops**.
2. **`INPUT_detect_events`** — only polls keys/buttons that have ≥1 registered binding (the "interesting" set, built once at `INPUTS_init`). If a binding registers keycode 114, edge-detection runs for 114; otherwise it's skipped. **Cost: ~N ops where N = unique bound keys (~30) + 3 mouse buttons + wheel = ~35 ops**.
3. **`REGION_hit_test`** — runs ONCE per frame, result cached in `INPUT_CONTEXT` as `CTX_OVER_*` bits. Linear scan over ~30 active regions = **~150 comparisons** (only when cursor moves; cached otherwise via `MOUSE_DX/DY = 0` check).
4. **`INPUT_dispatch_frame`** — if `DETECTED_EVENT_COUNT = 0`, early-exit. **Idle frame cost: ~5 ops** (just the count check).
5. For each detected event (rare — ~0-3 events/sec under normal use): scan binding bucket for that event type. With per-event-type buckets (built at init), each event scans ~10-30 bindings = **~50 ops per event**.

### Idle-frame fast path

```qb64
SUB INPUT_dispatch_frame ()
    IF DETECTED_EVENT_COUNT = 0 AND INPUT_CONTEXT = INPUT_CONTEXT_PREV THEN EXIT SUB
    INPUT_CONTEXT_PREV = INPUT_CONTEXT
    ' ... dispatch loop ...
END SUB
```

**Idle frame total: ~70 ops** (30 context + 35 detect + 5 dispatch). vs current **~200-400 ops**.

### Active frame (1 click + cursor moving) total: ~70 + 150 hit-test + 50 dispatch = ~270 ops. vs current ~300-500 ops with comparable activity.

### Bucketing optimization (apply if profiling shows hot path)

At `INPUTS_init`, after all `INPUT_register` calls complete, build per-event-type index arrays:
```qb64
DIM SHARED INPUT_BIND_INDEX_KEY_PRESS(1 TO 128) AS INTEGER   ' indices into INPUT_BINDS
DIM SHARED INPUT_BIND_INDEX_KEY_PRESS_COUNT AS INTEGER
DIM SHARED INPUT_BIND_INDEX_MOUSE_CLICK(1 TO 64) AS INTEGER
DIM SHARED INPUT_BIND_INDEX_MOUSE_CLICK_COUNT AS INTEGER
' ... one bucket per EVT_* ...

SUB INPUT_buckets_build ()
    DIM i AS INTEGER
    FOR i = 1 TO INPUT_BIND_COUNT
        SELECT CASE INPUT_BINDS(i).eventType
            CASE EVT_KEY_PRESS
                INPUT_BIND_INDEX_KEY_PRESS_COUNT = INPUT_BIND_INDEX_KEY_PRESS_COUNT + 1
                INPUT_BIND_INDEX_KEY_PRESS(INPUT_BIND_INDEX_KEY_PRESS_COUNT) = i
            ' ... etc ...
        END SELECT
    NEXT
END SUB
```

Dispatch becomes: `FOR each event → look up bucket → scan only that bucket`. Cuts per-event scan from 300 → ~30 average.

### Interesting-keys set

```qb64
DIM SHARED INPUT_INTERESTING_KEYS(0 TO 65535) AS _BYTE  ' 64KB, ~negligible
SUB INPUT_interesting_keys_build ()
    DIM i AS INTEGER
    FOR i = 1 TO INPUT_BIND_COUNT
        IF INPUT_BINDS(i).keycode > 0 THEN
            INPUT_INTERESTING_KEYS(INPUT_BINDS(i).keycode) = 1
            ' Letter case: register both ASCII codes
            IF INPUT_BINDS(i).keycode >= 97 AND INPUT_BINDS(i).keycode <= 122 THEN
                INPUT_INTERESTING_KEYS(INPUT_BINDS(i).keycode - 32) = 1
            END IF
        END IF
    NEXT
END SUB
```

`INPUT_detect_events` only polls `_KEYDOWN(k)` for k where `INPUT_INTERESTING_KEYS(k) = 1`. ~30 polls instead of "every possible key code".

### Performance acceptance criterion

After Phase 0, write `DEV/EXPERIMENTS/input_perf.bas`: synthetic loop running `INPUT_update_context + INPUT_detect_events + INPUT_dispatch_frame` 100,000 times with no inputs. Measure wall-clock. Acceptance: **idle path completes < 50ms total** (i.e. < 0.5μs per frame at 60FPS = 0.003% of frame budget).

Also: run DRAW with both old and new dispatchers active in parallel for one week (legacy `dispatched = FALSE`, new infrastructure runs alongside but no bindings dispatched yet). Compare profiler output before/after. Acceptance: **no measurable FPS drop on idle or under normal use**.

---

## 13c. Sub-Element Hit-Testing (tooltips, button hover, layer-row selection)

**Concern**: tooltips fire on specific toolbar buttons, specific layer rows, specific palette cells — not whole panels.

### How the design handles it (already supported, now explicit)

Regions are **container-level granularity**. Sub-element detection happens in the **handler**, which reads `INPUT_EVENT.mouseX/Y` and walks its own data structures. This mirrors HTML's `event.target` model exactly: the browser tells you which container element received the event; your handler walks down to the specific child.

### Pattern: tooltip on toolbar button

```qb64
' --- At registration time ---
INPUT_register_hover REGION_TOOLBAR, EVT_MOUSE_MOVE, ACT_TOOLBAR_HOVER_TICK, TRUE, "Toolbar hover (sub-element tracking)"

' --- In action handler ---
CASE ACT_TOOLBAR_HOVER_TICK
    DIM btnId AS INTEGER
    btnId = TOOLBAR_button_at%(INPUT_EVENT.mouseX, INPUT_EVENT.mouseY)
    IF btnId <> TOOLBAR_LAST_HOVERED_BTN% THEN
        ' Sub-element changed — tell tooltip subsystem
        IF TOOLBAR_LAST_HOVERED_BTN% > 0 THEN TOOLTIP_clear_for_element TOOLBAR_LAST_HOVERED_BTN%
        IF btnId > 0 THEN TOOLTIP_register_hover_start REGION_TOOLBAR, btnId, TOOLBAR_button_tooltip$(btnId)
        TOOLBAR_LAST_HOVERED_BTN% = btnId
    END IF
```

### Pattern: tooltip on individual layer row

```qb64
' --- Registration ---
INPUT_register_hover REGION_LAYER_PANEL, EVT_MOUSE_MOVE, ACT_LAYER_PANEL_HOVER_TICK, TRUE, "Layer panel hover"

' --- Handler ---
CASE ACT_LAYER_PANEL_HOVER_TICK
    DIM layerIdx AS INTEGER
    layerIdx = LAYER_PANEL_row_at%(INPUT_EVENT.mouseX, INPUT_EVENT.mouseY)
    ' ... track sub-element change, fire tooltip ...
```

### Why we don't make sub-elements first-class regions

- Toolbar has ~30 buttons. Palette has 256 cells. Charmap has 256 chars. Layer panel can have unlimited rows. Each as a `REGION_*` would explode the table to thousands of entries.
- Sub-elements are intrinsically owned by their container; the container already knows their layout. Making the input system re-learn that layout is duplicating knowledge.
- Sub-element events are *rare* (hover, click) — the per-event cost of one container-handler call + one `*_button_at%` lookup is trivial.

### What gets added to the spec

- **`EVT_MOUSE_MOVE`** fires per-frame while cursor is over a region (no button required). Container handlers use it to track sub-element transitions.
- **`TOOLTIP_register_hover_start(region, elementId, text$)`** — tooltip subsystem accepts (region, sub-element-id) as a composite key. The tooltip subsystem already tracks per-element hover-start time; we just feed it the composite key.
- **Each panel implements `<PANEL>_element_at%(x, y) AS INTEGER`** — returns the sub-element ID under the cursor (0 = none). Already exists in most panels (e.g., `TOOLBAR_button_at%`); just standardize the naming.

### Tradeoff acknowledged

Container handler runs every frame the cursor is over the region (typically 1-10 frames/sec of hover). Each call does its own hit-test internally. **Net cost**: ~50 ops per frame when hovering a panel, ~0 when not. Negligible.

---

## 13d. Dynamic GUI Bounds (movable panels, resizable dialogs, display-scale changes)

**Concern**: GUI is dynamic — toolbars can move, dialogs/browsers resize, display scale can change. Hitboxes must always be correct, but updates should be cheap.

### Invariant (the contract every panel must honor)

> **Every visible panel MUST call `REGION_set_bounds` in its render SUB.**
> **Every hidden panel MUST call `REGION_set_inactive` when hiding.**

If a panel renders without updating bounds, hit-testing uses stale bounds → mouse events go to the wrong region. This is the single discipline that makes the system reliable.

### Why update every frame is fine (not wasteful)

`REGION_set_bounds` writes 6 INTEGERs into a SHARED array. With ~30 visible panels, that's **180 integer writes per frame** = ~1μs. Compared to the rendering pipeline (~16ms budget), this is 0.006% — completely negligible.

We do NOT need a "bounds dirty" flag or change-detection. The naive every-frame write is faster than the conditional logic to skip.

### Resize / move flows

| Trigger | Existing flow | Region update |
|---|---|---|
| User drags panel corner to resize | Panel re-lays out next frame | Render SUB calls `REGION_set_bounds` with new dims |
| User drags panel title to move | Same | Same |
| User toggles panel visibility | `SCRN.show<panel>% = FALSE`, render skipped | Hide path calls `REGION_set_inactive REGION_<NAME>` |
| Display scale change | `SCREEN_set_display_scale` triggers full re-layout | All panels re-render → bounds set with new screen coords |
| Window resize | Same as display scale | Same |
| Dialog close | Dialog render skipped | Dialog close handler calls `REGION_set_inactive` |
| Settings dialog field change | Apply handler triggers re-layout if needed | Affected panels re-render |

### Display scale is transparent

`REGION_BOUNDS` stores **screen pixels** (post-scale). `MOUSE.RAW_X/Y` is also **screen pixels** (post-scale). They're in the same coordinate space by construction. Display scale changes flow through normally: panels re-render at new sizes, write new bounds, hit-test still works.

The only thing to watch: panel render code must compute its bounds in screen pixels (post-scale), not in pre-scale logical units. This is already true for current panels (they use `SCRN.w&`, `SCRN.h&` which are post-scale).

### Consistency-checking mechanism (dev mode)

Add a per-frame consistency check that runs when `DEV_MODE%`:

```qb64
SUB REGION_check_consistency ()
    IF NOT DEV_MODE% THEN EXIT SUB
    DIM i AS INTEGER
    FOR i = 1 TO 63
        ' If a region is marked active but its bounds are degenerate, log warning
        IF REGION_BOUNDS_TABLE(i).active% AND _
           (REGION_BOUNDS_TABLE(i).w <= 0 OR REGION_BOUNDS_TABLE(i).h <= 0) THEN
            INPUTS_log "[CONSISTENCY] REGION_" + STR$(i) + " is active but has degenerate bounds"
        END IF
        ' If a region's bounds extend beyond screen, log warning
        IF REGION_BOUNDS_TABLE(i).active% AND _
           (REGION_BOUNDS_TABLE(i).x + REGION_BOUNDS_TABLE(i).w > SCRN.w& OR _
            REGION_BOUNDS_TABLE(i).y + REGION_BOUNDS_TABLE(i).h > SCRN.h&) THEN
            INPUTS_log "[CONSISTENCY] REGION_" + STR$(i) + " bounds extend off-screen"
        END IF
    NEXT
END SUB
```

Catches: panel render forgot to set bounds, panel didn't account for display scale, panel left stale active flag after hiding.

### Auto-invalidation on display-scale change (belt + suspenders)

```qb64
SUB SCREEN_set_display_scale (newScale AS INTEGER)
    ' ... existing scale logic ...
    
    ' Defensive: clear all region bounds. Panels will re-set them on next render.
    REGION_clear_all
END SUB

SUB REGION_clear_all ()
    DIM i AS INTEGER
    FOR i = 0 TO 63
        REGION_BOUNDS_TABLE(i).active% = FALSE
        REGION_BOUNDS_TABLE(i).x = 0 : REGION_BOUNDS_TABLE(i).y = 0
        REGION_BOUNDS_TABLE(i).w = 0 : REGION_BOUNDS_TABLE(i).h = 0
    NEXT
END SUB
```

For ONE frame after a display-scale change, no hit-testing matches. Next frame, panels re-render and bounds are fresh. Worst case: one frame of dead clicks during a rare event (scale change is not in the hot path).

### What changes in spec

- Add the invariant statement explicitly to §7 (Registration API)
- Add `REGION_check_consistency` to §11 (Audit + Dev Mode)
- Add `REGION_clear_all` to §10 (Dispatcher) as the display-scale hook
- Add `EVT_MOUSE_MOVE` to §4 (Event Catalog) for sub-element hover tracking
- Add `TOOLTIP_register_hover_start(region, elementId, text$)` API note to §12 (Helper Utilities) — tooltip subsystem migration

---

## 13e. Future Device Extensions (gamepad, MIDI, tablet, etc.)

**Concern**: does this architecture scale to input devices not yet implemented — gamepad (D-pad for precision, analog sticks, face buttons), MIDI controllers (knobs/sliders mapped to parameters), pressure-sensitive tablets (Wacom-style), touch?

**Answer**: yes, by design — but two small additions need to land in Phase 0 so future devices don't require breaking changes to the types.

### Additions to lock in now

#### 1. `value` field in `INPUT_EVENT` (for continuous-value devices)

```qb64
TYPE INPUT_EVENT_OBJ
    eventType    AS INTEGER
    region       AS INTEGER
    keycode      AS LONG
    button       AS INTEGER
    wheelDir     AS INTEGER
    mouseX       AS INTEGER
    mouseY       AS INTEGER
    canvasX      AS INTEGER
    canvasY      AS INTEGER
    mods         AS INTEGER
    ctx          AS _UNSIGNED _INTEGER64
    value        AS SINGLE      ' NEW — 0.0..1.0 for analog, 0..127 for MIDI CC, 0..255 for tablet pressure
    value2       AS SINGLE      ' NEW — secondary axis (analog stick Y when value=X; or unused)
    device       AS INTEGER     ' NEW — DEVICE_KEYBOARD, DEVICE_MOUSE, DEVICE_GAMEPAD, DEVICE_MIDI, ...
    deviceIdx    AS INTEGER     ' NEW — 0 for single-device classes; 0..N for multi (gamepad 1 vs gamepad 2)
END TYPE
```

Keyboard/mouse events leave `value = 0` and `device = DEVICE_KEYBOARD / DEVICE_MOUSE`. Existing handlers ignore the field — no impact on the initial implementation.

#### 2. Device-class constants (reserved ranges)

```qb64
CONST DEVICE_KEYBOARD = 1
CONST DEVICE_MOUSE    = 2
CONST DEVICE_GAMEPAD  = 3   ' future
CONST DEVICE_MIDI     = 4   ' future
CONST DEVICE_TABLET   = 5   ' future (Wacom-style pressure)
CONST DEVICE_TOUCH    = 6   ' future
' 7-15 reserved
```

#### 3. Event-type CONST range allocation (reserve now to avoid renumbering)

```qb64
' 1-9   = keyboard
' 10-19 = mouse buttons
' 20-29 = mouse cursor + wheel
' 30-39 = gamepad     (reserved — not implemented in initial release)
' 40-49 = MIDI        (reserved)
' 50-59 = tablet/pressure (reserved)
' 60-99 = future device classes
' 100+  = synthetic / cross-device composite events
```

This costs zero today and prevents a painful renumbering when gamepad lands.

### How each future device plugs in

#### Gamepad (locked design: pure mouse emulation)

**Decision (grymmjack)**: gamepad in DRAW is **mouse emulation only**. D-pad and analog sticks move the mouse cursor; gamepad buttons map (via user-configurable mapping dialog) to mouse buttons + wheel. There is no separate "gamepad focus" model — focus IS mouse cursor position. There are no native `EVT_GAMEPAD_*` actions in the binding table for the initial release; every gamepad input flows through the existing mouse event pipeline.

This means the gamepad raw-input layer is trivial:

```qb64
SUB GAMEPAD_poll ()
    ' Poll _DEVICEINPUT for gamepad state, translate to mouse updates:
    '   D-pad / left stick → MOUSE.RAW_X / RAW_Y delta (with deadzone + step rate)
    '   A button           → MOUSE.B1 (per user mapping)
    '   B button           → MOUSE.B2
    '   Y button           → MOUSE.B3
    '   LB/RB              → MOUSE.WHEEL +/- 1
    '   ... (mapping is user-configurable via stub dialog)
END SUB
```

Called once per frame BEFORE `MOUSE_drain_update_state`, so subsequent mouse processing sees gamepad-driven state as if it were a real mouse. No changes to dispatcher, regions, or bindings — gamepad becomes a pure input alternative for users who prefer D-pad precision over a mouse.

**Mapping dialog**: stub only for the initial release (a placeholder dialog showing default mapping, no edit UI). Real mapping UI is a future feature.

The `EVT_GAMEPAD_*` event types stay reserved in case a future need emerges for native gamepad bindings (e.g., a Start button that should ONLY toggle menus, never click), but they're not implemented or used initially.

Two complementary modes that the future-event-type reservation supports (NOT initial scope):

**A) D-pad as precise cursor** (your "more precise than mouse" use case)

A raw-input layer (`INPUT/GAMEPAD.BM`) polls `_DEVICES` / `_DEVICEINPUT` for gamepad button transitions. When D-pad is held, it nudges `MOUSE.RAW_X / RAW_Y` by 1 pixel per frame (or 1 pixel per N frames for held-step-rate control). The hit-test and existing mouse bindings work unchanged — gamepad just becomes a sub-pixel-precise mouse alternative.

**B) Face buttons as discrete events** (menu navigation, tool selection)

Register via the table like keys:

```qb64
CONST EVT_GAMEPAD_BTN_PRESS   = 30
CONST EVT_GAMEPAD_BTN_RELEASE = 31

CONST GAMEPAD_BTN_A      = 1     ' "code" field for the binding
CONST GAMEPAD_BTN_B      = 2
CONST GAMEPAD_BTN_X      = 3
CONST GAMEPAD_BTN_Y      = 4
CONST GAMEPAD_BTN_LB     = 5
CONST GAMEPAD_BTN_RB     = 6
CONST GAMEPAD_BTN_LT     = 7     ' analog trigger; uses value for pressure
CONST GAMEPAD_BTN_RT     = 8
CONST GAMEPAD_BTN_DPAD_U = 9
CONST GAMEPAD_BTN_DPAD_D = 10
CONST GAMEPAD_BTN_DPAD_L = 11
CONST GAMEPAD_BTN_DPAD_R = 12
CONST GAMEPAD_BTN_START  = 13
CONST GAMEPAD_BTN_SELECT = 14

' Example bindings:
INPUT_register EVT_GAMEPAD_BTN_PRESS, REGION_GLOBAL, GAMEPAD_BTN_START, 0, 0, 0, 0, 0, 0, ACT_TOGGLE_MENU, TRUE, "Gamepad Start = menu"
INPUT_register EVT_GAMEPAD_BTN_PRESS, REGION_CANVAS, GAMEPAD_BTN_A, 0, 0, 0, 0, 0, 0, ACT_TOOL_STAMP, TRUE, "Gamepad A = stamp on canvas"
```

The `region` field still works because gamepad cursor mode populates `INPUT_EVENT.mouseX/Y` from gamepad-driven mouse position, which feeds the region hit-test.

**C) Analog sticks** (zoom, pan, parameter modulation)

```qb64
CONST EVT_GAMEPAD_AXIS_CHANGE = 32

CONST GAMEPAD_AXIS_LX = 1
CONST GAMEPAD_AXIS_LY = 2
CONST GAMEPAD_AXIS_RX = 3
CONST GAMEPAD_AXIS_RY = 4

' Bind right-stick X to zoom (read value in handler)
INPUT_register EVT_GAMEPAD_AXIS_CHANGE, REGION_GLOBAL, GAMEPAD_AXIS_RX, 0, 0, 0, 0, 0, 0, ACT_GAMEPAD_ZOOM_AXIS, TRUE, "Right stick X = zoom"

' In handler:
CASE ACT_GAMEPAD_ZOOM_AXIS
    IF ABS(INPUT_EVENT.value) > 0.1 THEN  ' deadzone
        SCRN.zoom! = SCRN.zoom! * (1.0 + INPUT_EVENT.value * 0.05)  ' modulate
        SCENE_invalidate
    END IF
```

#### Gamepad focus model (the open design choice — defer decision until implementation)

For menu navigation, two approaches both work with the table:

- **Cursor mode** (mode A above): D-pad nudges mouse cursor; A button = click. Reuses everything as-is. Slower for menu navigation, perfect for canvas precision.
- **Focus mode**: track `GAMEPAD_FOCUS_REGION` + `GAMEPAD_FOCUS_ELEMENT` globally. D-pad changes focus to neighbor element; A button fires that element's action. Add `CTX_GAMEPAD_FOCUS_MODE` so the same bindings can be gated to one mode or the other.

Defer this choice to the gamepad-implementation phase. The architecture supports either or both (toggled via shoulder button maybe).

#### MIDI controllers

```qb64
CONST EVT_MIDI_NOTE_ON  = 40
CONST EVT_MIDI_NOTE_OFF = 41
CONST EVT_MIDI_CC       = 42   ' control change (knobs, sliders)
CONST EVT_MIDI_PITCH    = 43   ' pitch bend

' code = MIDI note number (0-127) for NOTE; CC number (0-127) for CC
' value = velocity (0-127) for NOTE; CC value (0-127) for CC
' channel = MIDI channel; folded into upper bits of `code` or stored in `value2`
' deviceIdx = which MIDI device (when multiple connected)

' Example: knob #7 controls brush opacity
INPUT_register EVT_MIDI_CC, REGION_GLOBAL, 7, 0, 0, 0, 0, 0, 0, ACT_MIDI_SET_OPACITY, TRUE, "MIDI CC#7 = brush opacity"

' Handler:
CASE ACT_MIDI_SET_OPACITY
    PAINT_OPACITY% = INT(INPUT_EVENT.value * 100 / 127)  ' 0-127 → 0-100
    GUI_NEEDS_REDRAW% = TRUE
```

**QB64-PE implementation note**: QB64-PE has no built-in MIDI input. To actually use MIDI input we'd need:
- Linux: ALSA `snd_seq_*` via DECLARE LIBRARY
- macOS: CoreMIDI framework
- Windows: WinMM `midiInOpen` / `midiInProc`

That's significant cross-platform glue. **For now**: spec reserves the event codes; actual MIDI raw-input layer is a future project. Workaround for users: external MIDI-to-keyboard mapper (e.g. `midi2key` on Linux) — DRAW sees those as keyboard events and they go through the table.

#### Pressure-sensitive tablet (Wacom-style)

```qb64
CONST EVT_TABLET_DOWN     = 50
CONST EVT_TABLET_UP       = 51
CONST EVT_TABLET_MOVE     = 52
CONST EVT_TABLET_PRESSURE = 53   ' separate event for pure pressure-change

' value = pressure 0.0..1.0
' Tablet appears as mouse to OS for position; pressure comes via _DEVICEINPUT
```

Brush handlers read `INPUT_EVENT.value` (0.0 to 1.0) to modulate stroke opacity/width. Mouse handlers reading the same events get value = 1.0 (full pressure) for compatibility.

#### Touch (mobile / touchscreen)

```qb64
CONST EVT_TOUCH_DOWN     = 60
CONST EVT_TOUCH_UP       = 61
CONST EVT_TOUCH_MOVE     = 62
CONST EVT_TOUCH_PINCH    = 63   ' two-finger pinch; value = scale delta
CONST EVT_TOUCH_ROTATE   = 64   ' two-finger rotate; value = angle delta

' deviceIdx = touch contact ID (multi-touch tracking)
```

Single-touch maps to mouse events automatically (most touch frameworks do this). Multi-touch / pinch / rotate become distinct events that gesture-aware handlers register for.

### What this future-proofing costs today

- `INPUT_EVENT` gets 4 extra fields (`value`, `value2`, `device`, `deviceIdx`). Mouse/keyboard set them to defaults. Memory: ~12 bytes per event. Per-frame perf impact: negligible (a few extra stores).
- `INPUT_BINDS` table needs no extra fields (binding-time filtering on value can be deferred — handlers filter by reading `INPUT_EVENT.value` themselves).
- Event-type CONST numbering reserves ranges that don't collide.

**Zero impact on the initial keyboard/mouse rearchitecture.** All future devices add to the table the same way: register events, populate `INPUT_EVENT`, handlers read what they need.

### Acceptance criteria for "extensible"

After Phase 0 lands, adding gamepad button support should be:
1. New `INPUT/GAMEPAD.BM` raw-input layer (~200 LOC) polls `_DEVICES`/`_DEVICEINPUT` and enqueues `EVT_GAMEPAD_*` events into `DETECTED_EVENTS`
2. Action handlers added to `CMD_execute_action` for new gamepad actions (~5 cases for menu nav)
3. ~20 `INPUT_register` calls binding gamepad buttons to actions
4. **Zero changes to the dispatcher, region system, or audit code**

If extending requires touching `INPUT_dispatch_frame` or `INPUT_BIND_matches%`, the extensibility design failed.

---

## 14. Risk Register

| Risk | Likelihood | Severity | Mitigation |
|---|---|---|---|
| `_UNSIGNED _INTEGER64` bitwise operators behave unexpectedly in QB64-PE | Medium | High | Prototype in `DEV/EXPERIMENTS/` before committing TYPE (per existing memory) |
| Phase 2 region migration breaks panel hit-testing | Medium | High | Migrate one panel at a time; legacy `*_is_over_area%` still works during transition. Manual smoke test after each panel. |
| Event detection state machines have edge cases (click-then-drag-back-then-up = click? dblclick across panel boundaries?) | High | Medium | Document each state-machine case explicitly. Add `INPUTS_log` traces in dev mode for unexpected sequences. |
| First-match-wins registration order creates non-obvious priority bugs | Medium | Medium | Auditor must report registration order for each binding. Convention: register panels in z-order from top (modal → popup → panel → canvas) so first match = top-most region. |
| Migration takes longer than estimated | High | Low | Phase 0 alone delivers value (audit + discoverability). Later phases ship incrementally on same branch. No deadline pressure. |
| Adding `DEVELOPER_MODE%` CFG field bumps file format requiring migration | Low | Low | CFG already has a soft migration system (CONFIG-upgrade); new fields default to 0 (false) on old configs. |
| Region z-order conflicts with existing render-order assumptions | Medium | Medium | Render order is fixed (back-to-front per OUTPUT/SCREEN.BM); region z-order is for hit-testing only. They're separate concerns; document this distinction. |

---

## 15. Open Questions (resolve before merge, OK to defer if not blocking)

1. **`requireMods = 0`** — does this mean "any mods OK" or "no mods allowed"? The dispatcher logic treats it as "any mods" (no required bits). The cleaner semantic would be "no mods required" matched by `forbidMods` covering the rest. **Resolution**: documented as "no required mods; use forbidMods to exclude specific mods". This matches the example registrations above.

2. **Stick (joystick) input** — `INPUT/STICK.BM` exists. Should it be part of this rearchitecture? **Resolution**: out of scope. Stick handler is small, stable, and doesn't conflict with keyboard/mouse. Register stick events later if it grows.

3. **What about `_KEYHIT` for buffered character input** (text tool typing)? **Resolution**: out of scope. Text editing is a state machine that stays legacy. The text tool registers `dispatched = FALSE` metadata for its key bindings.

4. **Mouse coord systems** — `INPUT_EVENT` has both `mouseX/Y` (screen) and `canvasX/Y` (post-zoom/pan/snap). Computing canvas coords from screen is non-trivial (already handled in MOUSE.BM). **Resolution**: dispatcher reads `MOUSE.X%` / `MOUSE.Y%` for canvas coords, `MOUSE.RAW_X%` / `MOUSE.RAW_Y%` for screen. Pre-populated by existing `MOUSE_drain_update_state`.

5. **Action ID namespace cleanup** — discovery agent recommended named constants (`ACT_BRUSH_TOOL = 101`). Should this happen in Phase 0 or as a separate commit? **Resolution**: defer to Phase 5. Not blocking the rearchitecture; can be done incrementally.

---

## 16. Estimated Total Effort

| Phase | Approx. LOC | Approx. Effort |
|---|---|---|
| 0. Infrastructure + helpers | +800 / -0 | 4-6 hours |
| 1. KB binding registration metadata | +500 / -0 | 2-3 hours |
| 2. Panel REGION migration | +400 / -300 | 6-10 hours |
| 3. Mouse binding registration metadata | +600 / -0 | 3-4 hours |
| 4. Audit conflict resolution | +50 / -50 | 1-2 hours |
| 5. Idiom helper migration | +50 / -400 | 3-5 hours |
| 6. Opportunistic dispatch migration | varies | ongoing (out of scope for initial merge) |
| 7. Documentation | +200 / -50 | 2 hours |
| 8. Manual QA + bugfixes | +50 / -50 | 4-6 hours |
| **Initial merge total** | **+2650 / -850** | **25-40 hours** |

This is ~3-5 focused work sessions. Realistic spread over 1-2 weeks of evening/weekend work.

---

## 17. Success Criteria

This rearchitecture is **done** when:

1. ✅ Adding a new keyboard chord is 1 `INPUT_register_key` line + 1 SELECT CASE in `CMD_execute_action`. No new STATIC pressed%, no manual modifier checks, no manual letter-case ORing, no gating other handlers.
2. ✅ Adding a new panel is 2 lines per render (set bounds, set inactive on hide) + `INPUT_register_mouse` for each handler.
3. ✅ In dev mode, every conflict between input bindings is reported in `inputs.log` before user testing.
4. ✅ All 216 `_FREEIMAGE` sites use `SAFE_FREEIMAGE`. All `_DEST`/`_SOURCE` uses save-restore stack. No dirty-flag inconsistencies.
5. ✅ No regression in existing behavior (PLANS/TESTS/ all pass).
6. ✅ CLAUDE.md + `.claude/instructions/input-system.md` document the new patterns; memories captured.
7. ✅ The branch merges cleanly to main as a single coherent unit.

---

**END SPEC** — pending grymmjack review and approval to proceed.
