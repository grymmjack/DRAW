''
' DRAW - INPUT/INPUT.BI
' =============================================================================
' Unified input dispatch system. Replaces scattered IF/STATIC blocks throughout
' KEYBOARD.BM/MOUSE.BM with a declarative table mapping
' (event, region, key/button, modifiers, context) -> action_id.
'
' See PLANS/REARCHITECTURE.md for full design rationale.
'
' Key concepts:
'   - INPUT_BIND:        one row in the table; describes when an action fires
'   - REGION_BOUNDS:     screen rectangle owned by a GUI panel; updated each render
'   - INPUT_EVENT:       per-event context populated by dispatcher, read by action
'   - INPUT_CONTEXT:     64-bit bitmask of modal/held/region state, updated per frame
'   - DEV_MODE:          enables audit + inputs.log + consistency checks
'
' Phase 0 ships the infrastructure only. dispatched=FALSE bindings (legacy
' metadata) keep existing handlers in charge. dispatched=TRUE bindings fire
' through this dispatcher.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE


'==============================================================================
' DEVICE CLASSES (reserved ranges for future devices)
'==============================================================================
CONST DEVICE_NONE     = 0
CONST DEVICE_KEYBOARD = 1
CONST DEVICE_MOUSE    = 2
CONST DEVICE_GAMEPAD  = 3                           ' future
CONST DEVICE_MIDI     = 4                           ' future
CONST DEVICE_TABLET   = 5                           ' future (pressure)
CONST DEVICE_TOUCH    = 6                           ' future


'==============================================================================
' EVENT TYPES (ranges reserved per device class — DO NOT renumber)
'==============================================================================
' --- 1-9: Keyboard ---
CONST EVT_KEY_PRESS   = 1
CONST EVT_KEY_RELEASE = 2
CONST EVT_KEY_REPEAT  = 3

' --- 10-19: Mouse buttons ---
CONST EVT_MOUSE_DOWN       = 10
CONST EVT_MOUSE_UP         = 11
CONST EVT_MOUSE_CLICK      = 12
CONST EVT_MOUSE_DBLCLICK   = 13
CONST EVT_MOUSE_DRAG_START = 14
CONST EVT_MOUSE_DRAG_MOVE  = 15
CONST EVT_MOUSE_DRAG_END   = 16

' --- 20-29: Mouse cursor + wheel ---
CONST EVT_MOUSE_HOVER_ENTER = 20
CONST EVT_MOUSE_HOVER_LEAVE = 21
CONST EVT_MOUSE_MOVE        = 22
CONST EVT_MOUSE_WHEEL       = 23

' --- 30-39: Gamepad (reserved, gamepad is mouse-emulated in initial release) ---
CONST EVT_GAMEPAD_BTN_PRESS   = 30
CONST EVT_GAMEPAD_BTN_RELEASE = 31
CONST EVT_GAMEPAD_AXIS_CHANGE = 32

' --- 40-49: MIDI (reserved, not implemented) ---
CONST EVT_MIDI_NOTE_ON  = 40
CONST EVT_MIDI_NOTE_OFF = 41
CONST EVT_MIDI_CC       = 42
CONST EVT_MIDI_PITCH    = 43

' --- 50-59: Tablet (reserved) ---
CONST EVT_TABLET_DOWN     = 50
CONST EVT_TABLET_UP       = 51
CONST EVT_TABLET_MOVE     = 52
CONST EVT_TABLET_PRESSURE = 53

' --- 60-69: Touch (reserved) ---
CONST EVT_TOUCH_DOWN   = 60
CONST EVT_TOUCH_UP     = 61
CONST EVT_TOUCH_MOVE   = 62
CONST EVT_TOUCH_PINCH  = 63
CONST EVT_TOUCH_ROTATE = 64


'==============================================================================
' REGIONS (logical hitbox owners — one per visible GUI element)
'==============================================================================
CONST REGION_GLOBAL               = 0
CONST REGION_CANVAS               = 1
CONST REGION_TOOLBAR              = 2
CONST REGION_MENUBAR              = 3
CONST REGION_LAYER_PANEL          = 4
CONST REGION_PALETTE_STRIP        = 5
CONST REGION_EDIT_BAR             = 6
CONST REGION_ADV_BAR              = 7
CONST REGION_STATUS_BAR           = 8
CONST REGION_DRAWER               = 9
CONST REGION_PREVIEW              = 10
CONST REGION_COLOR_MIXER          = 11
CONST REGION_IMAGE_BROWSER        = 12
CONST REGION_CHARMAP              = 13
CONST REGION_ORGANIZER            = 14
CONST REGION_COMMAND_PALETTE      = 15
CONST REGION_SETTINGS_DLG         = 16
CONST REGION_FILE_DIALOG          = 17
CONST REGION_POPUP_MENU           = 18
CONST REGION_TOOLTIP              = 19              ' rendered but doesn't consume events
CONST REGION_PIXEL_COACH          = 20
CONST REGION_TRANSPARENCY_CHECKER = 21
CONST REGION_SMART_GUIDES         = 22
CONST REGION_SUBTOOL_FLYOUT       = 23
CONST REGION_TEXT_BAR             = 24
CONST REGION_PALETTE_PICKER       = 25
CONST REGION_FILL_ADJ             = 26
CONST REGION_DIALOG_GENERIC       = 27              ' generic modal dialogs
' --- 28-63 reserved ---

CONST REGION_TABLE_SIZE = 64                        ' max regions; bumps require type fitness check


'==============================================================================
' Z-ORDER (higher wins in hit-test)
'==============================================================================
CONST ZORDER_CANVAS          = 0
CONST ZORDER_PANEL           = 100
CONST ZORDER_FLOATING        = 200                  ' floating windows (preview/mixer/browser) — above docked panels, below flyouts. Renders on top AND wins the click.
CONST ZORDER_FLYOUT          = 300                  ' subtool flyout, dropdowns
CONST ZORDER_POPUP_MENU      = 500
CONST ZORDER_MODAL_DIALOG    = 1000
CONST ZORDER_COMMAND_PALETTE = 1500
CONST ZORDER_TOOLTIP         = 9999                 ' renders on top but inactive for hit-test


'==============================================================================
' CONTEXT BITMASK SLOTS (64 total available)
'   - bits 0..19:  modal/subsystem state
'   - bits 20..31: held-key chord initiators
'   - bits 32..63: cursor-region flags (auto-set by INPUT_update_context)
'==============================================================================
' Mode/subsystem flags
CONST CTX_TEXT_ACTIVE          = &H0000000000000001 ' bit 0
CONST CTX_FILE_DIALOG_OPEN     = &H0000000000000002
CONST CTX_IMAGE_IMPORT_ACTIVE  = &H0000000000000004
CONST CTX_REFIMG_REPOSITION    = &H0000000000000008
CONST CTX_MAGIC_WAND_ACTIVE    = &H0000000000000010
CONST CTX_MOVE_ACTIVE          = &H0000000000000020
CONST CTX_GRID_OFFSET_PICK     = &H0000000000000040
CONST CTX_SETTINGS_OPEN        = &H0000000000000080
CONST CTX_POPUP_MENU_OPEN      = &H0000000000000100
CONST CTX_COMMAND_PALETTE_OPEN = &H0000000000000200
CONST CTX_TRANSFORM_ACTIVE     = &H0000000000000400
CONST CTX_DRAWING_IN_PROGRESS  = &H0000000000000800
CONST CTX_CUSTOM_BRUSH_ACTIVE  = &H0000000000001000 ' bit 12 — a custom brush is loaded; Home/End/PgUp/PgDn/`/` transform the brush, not the layer
' bits 12-19 reserved

' Held-key chord initiators (set by INPUT_update_context from raw key state)
CONST CTX_G_HELD      = &H0000000000100000          ' bit 20
CONST CTX_M_HELD      = &H0000000000200000
CONST CTX_Z_HELD      = &H0000000000400000
CONST CTX_E_HELD      = &H0000000000800000
CONST CTX_F_HELD      = &H0000000001000000
CONST CTX_W_HELD      = &H0000000002000000
CONST CTX_SPACE_HELD  = &H0000000004000000
CONST CTX_ALT_HELD    = &H0000000008000000
CONST CTX_SS_DRAGGING = &H0000000010000000          ' SS 3D dice or SS polygon currently dragging — digit keys reserved
' bits 29-31 reserved for future chord initiators

' Cursor-region flags (auto-set from REGION_hit_test result)
CONST CTX_OVER_CANVAS        = &H0000000100000000   ' bit 32
CONST CTX_OVER_TOOLBAR       = &H0000000200000000
CONST CTX_OVER_MENUBAR       = &H0000000400000000
CONST CTX_OVER_LAYER_PANEL   = &H0000000800000000
CONST CTX_OVER_PALETTE       = &H0000001000000000
CONST CTX_OVER_EDIT_BAR      = &H0000002000000000
CONST CTX_OVER_ADV_BAR       = &H0000004000000000
CONST CTX_OVER_STATUS_BAR    = &H0000008000000000
CONST CTX_OVER_DRAWER        = &H0000010000000000
CONST CTX_OVER_PREVIEW       = &H0000020000000000
CONST CTX_OVER_COLOR_MIXER   = &H0000040000000000
CONST CTX_OVER_IMAGE_BROWSER = &H0000080000000000
CONST CTX_OVER_CHARMAP       = &H0000100000000000
CONST CTX_OVER_ORGANIZER     = &H0000200000000000
CONST CTX_OVER_DIALOG        = &H0000400000000000   ' any modal dialog
CONST CTX_OVER_POPUP_MENU    = &H0000800000000000
' bits 48-63 reserved for additional regions


'==============================================================================
' DRAG / DOUBLE-CLICK CONSTANTS
'==============================================================================
CONST DRAG_THRESHOLD_PX = 3                         ' must move this far before DRAG_START fires
CONST DBLCLICK_WINDOW_S = 0.3                       ' seconds for double-click


'==============================================================================
' BINDING CATEGORIES (for SHORTCUTS.md grouping + the rebind UI)
'==============================================================================
CONST CAT_NONE      = 0
CONST CAT_GLOBAL    = 1
CONST CAT_FILE      = 2
CONST CAT_EDIT      = 3
CONST CAT_VIEW      = 4
CONST CAT_TOOLS     = 5
CONST CAT_SELECTION = 6
CONST CAT_LAYERS    = 7
CONST CAT_COLOR     = 8
CONST CAT_GRID      = 9                             ' grid + symmetry
CONST CAT_TEXT      = 10
CONST CAT_BRUSH     = 11                            ' brush + custom brush
CONST CAT_TRANSFORM = 12
CONST CAT_IMAGE     = 13                            ' image adjustments + effects
CONST CAT_PANELS    = 14
CONST CAT_AUDIO     = 15
CONST CAT_MOUSE     = 16                            ' any mouse/wheel binding (assigned by device, not id)

' Rebindable MOUSE BEHAVIOR ids (3001-3099). These are metadata-only mouse binds
' (dispatched=FALSE): MOUSE.BM QUERIES them for which button drives each behavior,
' rather than the dispatcher firing an action. They appear in Customize Controls
' like any mouse bind and rebind via the same button-capture path.
CONST MB_PAINT_FG   = 3001                          ' paint with the foreground color
CONST MB_PAINT_BG   = 3002                          ' paint with the background color
CONST MB_PAN        = 3003                          ' pan the canvas (B2)
CONST MB_PICK_FG    = 3004                          ' eyedrop -> foreground (B2)
CONST MB_PICK_BG    = 3005                          ' eyedrop -> background (B2)
CONST MB_SYM_CENTER = 3006                          ' set symmetry center (B2)


'==============================================================================
' TYPES
'==============================================================================

''
' One binding row in the global table.
' Match conditions: eventType + region + keycode/button/wheelDir +
' (mods include requireMods, no forbidMods set) +
' (ctx includes requireCtx, no forbidCtx set).
'
TYPE INPUT_BIND
    eventType      AS INTEGER              ' EVT_*
    region         AS INTEGER              ' REGION_*; REGION_GLOBAL = any region
    keycode        AS LONG                 ' for EVT_KEY_*; 0 = any/unused
    button         AS INTEGER              ' for EVT_MOUSE_* / gamepad / MIDI; 0 = any
    wheelDir       AS INTEGER              ' for EVT_MOUSE_WHEEL: +1 / -1; 0 = any
    requireMods    AS INTEGER              ' all these bits must be in MODS_NOW%
    forbidMods     AS INTEGER              ' none of these bits may be in MODS_NOW%
    requireCtx     AS _UNSIGNED _INTEGER64 ' all these bits must be in INPUT_CONTEXT
    forbidCtx      AS _UNSIGNED _INTEGER64 ' none of these bits may be in INPUT_CONTEXT
    actionId       AS INTEGER              ' CMD_execute_action target
    dispatched     AS INTEGER              ' TRUE = new dispatcher fires; FALSE = legacy
    device         AS INTEGER              ' DEVICE_* (filled at registration)
    category       AS INTEGER              ' CAT_* — for SHORTCUTS.md grouping + rebind UI (filled at registration)
    userOverridden AS INTEGER              ' TRUE once a user rebind replaces the default (drives DRAW.bindings persistence)
    defKeycode     AS LONG                 ' compiled-in default keycode (snapshot at registration; for reset + skip-list retention)
    defRequireMods AS INTEGER              ' compiled-in default requireMods
    defForbidMods  AS INTEGER              ' compiled-in default forbidMods
    defButton      AS INTEGER              ' compiled-in default mouse button (snapshot at registration; for mouse-bind reset)
    defWheelDir    AS INTEGER              ' compiled-in default wheel direction (snapshot; for wheel/tilt-bind reset)
    label          AS STRING * 48          ' for cheatsheet / audit / inputs.log
END TYPE


''
' Screen rectangle for one region. Updated each frame by the owning panel's
' render SUB via REGION_set_bounds. Hidden panels call REGION_set_inactive.
'
TYPE REGION_BOUNDS
    active AS INTEGER ' is region currently displayed + hit-testable?
    x      AS INTEGER
    y      AS INTEGER
    w      AS INTEGER
    h      AS INTEGER
    zOrder AS INTEGER ' higher wins on overlap
END TYPE


''
' Per-event context populated by INPUT_dispatch_frame, read by action handlers.
' Read-only from the handler's POV. Valid only during action dispatch.
'
TYPE INPUT_EVENT_OBJ
    eventType AS INTEGER
    region    AS INTEGER
    keycode   AS LONG
    button    AS INTEGER
    wheelDir  AS INTEGER
    mouseX    AS INTEGER              ' screen X
    mouseY    AS INTEGER              ' screen Y
    canvasX   AS INTEGER              ' canvas X (post-zoom/pan/snap)
    canvasY   AS INTEGER              ' canvas Y
    mods      AS INTEGER              ' MOD_* bitmask snapshot
    ctx       AS _UNSIGNED _INTEGER64 ' INPUT_CONTEXT snapshot
    value     AS SINGLE               ' continuous value: analog 0..1, MIDI 0..127, tablet pressure 0..1
    value2    AS SINGLE               ' secondary axis (analog stick Y when value=X)
    device    AS INTEGER              ' DEVICE_*
    deviceIdx AS INTEGER              ' for multi-device disambiguation
END TYPE


''
' Internal: one detected event awaiting dispatch (queued each frame by
' INPUT_detect_events, drained by INPUT_dispatch_frame).
'
TYPE DETECTED_EVENT
    eventType AS INTEGER
    region    AS INTEGER
    keycode   AS LONG
    button    AS INTEGER
    wheelDir  AS INTEGER
    mouseX    AS INTEGER
    mouseY    AS INTEGER
    canvasX   AS INTEGER
    canvasY   AS INTEGER
    value     AS SINGLE
    value2    AS SINGLE
    device    AS INTEGER
    deviceIdx AS INTEGER
END TYPE


'==============================================================================
' SHARED STATE
'==============================================================================
CONST INPUT_MAX_BINDS  = 1024
CONST INPUT_MAX_EVENTS = 64           ' per-frame event queue cap

DIM SHARED INPUT_BINDS(1 TO INPUT_MAX_BINDS)         AS INPUT_BIND
DIM SHARED INPUT_BIND_COUNT     AS INTEGER
DIM SHARED REGION_BOUNDS_TABLE(0 TO REGION_TABLE_SIZE - 1) AS REGION_BOUNDS
DIM SHARED INPUT_EVENT          AS INPUT_EVENT_OBJ
DIM SHARED INPUT_CONTEXT        AS _UNSIGNED _INTEGER64
DIM SHARED INPUT_CONTEXT_PREV   AS _UNSIGNED _INTEGER64
DIM SHARED DETECTED_EVENTS(1 TO INPUT_MAX_EVENTS)    AS DETECTED_EVENT
DIM SHARED DETECTED_EVENT_COUNT AS INTEGER

' Edge-detection state for keys (indexed by binding index)
DIM SHARED KEY_DOWN_LAST(1 TO INPUT_MAX_BINDS)       AS INTEGER

' Highest mouse button DRAW samples + can bind. 1=L 2=R 3=M 4=back 5=forward
' 6-8=extra. _MOUSEBUTTON(n) on an absent button returns 0, so oversampling is safe.
CONST MOUSE_MAX_BTN = 8

' Per-frame physical state of every button (1..MOUSE_MAX_BTN). Buttons 1-3 mirror
' MOUSE.B1/B2/B3; 4+ are sampled straight from _MOUSEBUTTON in MOUSE_update_state.
' The central dispatcher reads this so extra buttons can drive bound actions.
DIM SHARED MOUSE_BTN(1 TO MOUSE_MAX_BTN)             AS INTEGER
DIM SHARED MOUSE_BTN_AVAIL AS INTEGER ' buttons the device reports (_LASTBUTTON, clamped); for the rebind UI

' Horizontal wheel TILT support. Read via _MOUSEWHEEL(axis) INSIDE DRAW's normal
' _MOUSEINPUT drain: axis 0 = vertical (the classic _MOUSEWHEEL), axis 1 = horizontal
' tilt. This replaced the _DEVICEINPUT/_WHEEL(n) device API, which read one event per
' call and lost the tilt behind mouse-movement events. wheelDir in the bind table
' encodes tilt as ±2 (WHEEL_TILT_* below) so one INTEGER carries vertical AND tilt.
DIM SHARED MOUSE_TILT_AXIS AS INTEGER ' _MOUSEWHEEL axis for horizontal tilt (config MOUSE_TILT_AXIS, default 1; 0 = disable)
DIM SHARED MOUSE_TILT      AS INTEGER ' this frame's tilt: -1 = RIGHT, +1 = LEFT, 0 = none
' wheelDir sign follows the PHYSICAL gesture as reported by _MOUSEWHEEL / _MOUSEWHEEL(axis):
' vertical  — physical UP reads -1, physical DOWN reads +1 (per QB64 wiki; confirmed by
'             zoom-in being bound to -1 and firing on a real wheel-up).
' horizontal — physical RIGHT reads NEGATIVE, physical LEFT reads POSITIVE (confirmed on
'             real hardware). Keep these constants matched to the physical direction so the
'             on-screen labels (CTRL_wheel_dir_name$) and the default binds stay truthful.
CONST WHEEL_UP         = -1           ' vertical wheel up   (physical up)
CONST WHEEL_DOWN       = 1            ' vertical wheel down (physical down)
CONST WHEEL_TILT_RIGHT = -2           ' horizontal tilt right (physical-right reads negative)
CONST WHEEL_TILT_LEFT  = 2            ' horizontal tilt left  (physical-left reads positive)

' Edge-detection state for mouse buttons + drag state machine
DIM SHARED MOUSE_BTN_DOWN_LAST(1 TO MOUSE_MAX_BTN)   AS INTEGER
DIM SHARED MOUSE_DOWN_REGION(1 TO MOUSE_MAX_BTN)     AS INTEGER
DIM SHARED MOUSE_DOWN_X(1 TO MOUSE_MAX_BTN)          AS INTEGER
DIM SHARED MOUSE_DOWN_Y(1 TO MOUSE_MAX_BTN)          AS INTEGER
DIM SHARED MOUSE_DOWN_TIME(1 TO MOUSE_MAX_BTN)       AS DOUBLE
DIM SHARED MOUSE_DRAG_STARTED(1 TO MOUSE_MAX_BTN)    AS INTEGER
DIM SHARED MOUSE_LAST_CLICK_TIME(1 TO MOUSE_MAX_BTN) AS DOUBLE
DIM SHARED MOUSE_LAST_CLICK_REGION(1 TO MOUSE_MAX_BTN) AS INTEGER

' Hover state for enter/leave detection
DIM SHARED HOVER_REGION_LAST AS INTEGER

' Performance optimization: interesting-keys set built at init
DIM SHARED INPUT_INTERESTING_KEYS(0 TO 65535)        AS _BYTE

' Per-frame "keycode already enqueued" tracker used by INPUT_detect_events
' to prevent double-fire when multiple bindings share the same keycode
' (e.g. plain M binding + Ctrl+M binding both on keycode 109). Uses a
' version-counter pattern: INPUT_KC_FRAME increments each frame; a key
' is "enqueued this frame" iff INPUT_KC_ENQUEUED(kc) == INPUT_KC_FRAME.
' Avoids any per-frame ERASE (which would deallocate the SHARED array
' under $DYNAMIC and cause "Subscript out of range" on next access).
DIM SHARED INPUT_KC_ENQUEUED(0 TO 65535)             AS LONG
DIM SHARED INPUT_KC_FRAME AS LONG

' Phase 6 migration: skip-list indexed by lowercase printable ASCII (0-127).
' Set to TRUE by INPUT_register% whenever a dispatched=TRUE key binding
' uses a keycode in 0-127 range. Legacy INKEY$-driven SUBs (KEYBOARD_tools,
' KEYBOARD_colors, KEYBOARD_brush_size) early-exit for any character whose
' lowercase ASCII is flagged here, preventing double-fire while migration
' is in flight. Lookup: INPUT_LETTER_DISPATCHED(ASC(LCASE$(keypress$))).
DIM SHARED INPUT_LETTER_DISPATCHED(0 TO 127)         AS INTEGER

' Phase 6 migration: nesting counter. Incremented at start of every
' CMD_execute_action call, decremented at end. Whenever > 0, we're
' executing a command (from dispatcher, menubar, command palette, or
' nested CMD_execute_action). The skip-list guard in KEYBOARD_tools
' bypasses itself when this is > 0 so the action body (which often
' calls back into KEYBOARD_tools "<letter>") actually runs.
DIM SHARED INPUT_DISPATCH_DEPTH AS INTEGER

' Developer mode + log path
DIM SHARED DEV_MODE        AS INTEGER
DIM SHARED INPUTS_LOG_PATH AS STRING


' DECLARE SUB/FUNCTION blocks removed — QB64-PE auto-discovers SUBs and
' FUNCTIONs from the include chain. Only DECLARE LIBRARY still needs an
' explicit declaration (and DRAW has none).
'
' The SUBs/FUNCTIONs themselves live in INPUT.BM:
'   INPUTS_init, INPUTS_log, INPUT_update_context, INPUT_detect_events,
'   INPUT_dispatch_frame, INPUT_audit, INPUT_interesting_keys_build,
'   REGION_set_bounds, REGION_set_inactive, REGION_clear_all,
'   REGION_check_consistency, REGION_hit_test%, INPUT_register%,
'   INPUT_BIND_matches%, INPUT_BINDS_could_collide%, INPUT_register_key%,
'   INPUT_register_mouse%, INPUT_register_wheel%, INPUT_register_hover%,
'   INPUTS_register_all.
