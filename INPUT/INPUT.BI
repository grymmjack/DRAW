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
CONST DEVICE_GAMEPAD  = 3   ' future
CONST DEVICE_MIDI     = 4   ' future
CONST DEVICE_TABLET   = 5   ' future (pressure)
CONST DEVICE_TOUCH    = 6   ' future


'==============================================================================
' EVENT TYPES (ranges reserved per device class — DO NOT renumber)
'==============================================================================
' --- 1-9: Keyboard ---
CONST EVT_KEY_PRESS          = 1
CONST EVT_KEY_RELEASE        = 2
CONST EVT_KEY_REPEAT         = 3

' --- 10-19: Mouse buttons ---
CONST EVT_MOUSE_DOWN         = 10
CONST EVT_MOUSE_UP           = 11
CONST EVT_MOUSE_CLICK        = 12
CONST EVT_MOUSE_DBLCLICK     = 13
CONST EVT_MOUSE_DRAG_START   = 14
CONST EVT_MOUSE_DRAG_MOVE    = 15
CONST EVT_MOUSE_DRAG_END     = 16

' --- 20-29: Mouse cursor + wheel ---
CONST EVT_MOUSE_HOVER_ENTER  = 20
CONST EVT_MOUSE_HOVER_LEAVE  = 21
CONST EVT_MOUSE_MOVE         = 22
CONST EVT_MOUSE_WHEEL        = 23

' --- 30-39: Gamepad (reserved, gamepad is mouse-emulated in initial release) ---
CONST EVT_GAMEPAD_BTN_PRESS    = 30
CONST EVT_GAMEPAD_BTN_RELEASE  = 31
CONST EVT_GAMEPAD_AXIS_CHANGE  = 32

' --- 40-49: MIDI (reserved, not implemented) ---
CONST EVT_MIDI_NOTE_ON   = 40
CONST EVT_MIDI_NOTE_OFF  = 41
CONST EVT_MIDI_CC        = 42
CONST EVT_MIDI_PITCH     = 43

' --- 50-59: Tablet (reserved) ---
CONST EVT_TABLET_DOWN     = 50
CONST EVT_TABLET_UP       = 51
CONST EVT_TABLET_MOVE     = 52
CONST EVT_TABLET_PRESSURE = 53

' --- 60-69: Touch (reserved) ---
CONST EVT_TOUCH_DOWN      = 60
CONST EVT_TOUCH_UP        = 61
CONST EVT_TOUCH_MOVE      = 62
CONST EVT_TOUCH_PINCH     = 63
CONST EVT_TOUCH_ROTATE    = 64


'==============================================================================
' REGIONS (logical hitbox owners — one per visible GUI element)
'==============================================================================
CONST REGION_GLOBAL                 = 0
CONST REGION_CANVAS                 = 1
CONST REGION_TOOLBAR                = 2
CONST REGION_MENUBAR                = 3
CONST REGION_LAYER_PANEL            = 4
CONST REGION_PALETTE_STRIP          = 5
CONST REGION_EDIT_BAR               = 6
CONST REGION_ADV_BAR                = 7
CONST REGION_STATUS_BAR             = 8
CONST REGION_DRAWER                 = 9
CONST REGION_PREVIEW                = 10
CONST REGION_COLOR_MIXER            = 11
CONST REGION_IMAGE_BROWSER          = 12
CONST REGION_CHARMAP                = 13
CONST REGION_ORGANIZER              = 14
CONST REGION_COMMAND_PALETTE        = 15
CONST REGION_SETTINGS_DLG           = 16
CONST REGION_FILE_DIALOG            = 17
CONST REGION_POPUP_MENU             = 18
CONST REGION_TOOLTIP                = 19  ' rendered but doesn't consume events
CONST REGION_PIXEL_COACH            = 20
CONST REGION_TRANSPARENCY_CHECKER   = 21
CONST REGION_SMART_GUIDES           = 22
CONST REGION_SUBTOOL_FLYOUT         = 23
CONST REGION_TEXT_BAR               = 24
CONST REGION_PALETTE_PICKER         = 25
CONST REGION_FILL_ADJ               = 26
CONST REGION_DIALOG_GENERIC         = 27  ' generic modal dialogs
' --- 28-63 reserved ---

CONST REGION_TABLE_SIZE = 64  ' max regions; bumps require type fitness check


'==============================================================================
' Z-ORDER (higher wins in hit-test)
'==============================================================================
CONST ZORDER_CANVAS         = 0
CONST ZORDER_PANEL          = 100
CONST ZORDER_FLYOUT         = 300  ' subtool flyout, dropdowns
CONST ZORDER_POPUP_MENU     = 500
CONST ZORDER_MODAL_DIALOG   = 1000
CONST ZORDER_COMMAND_PALETTE = 1500
CONST ZORDER_TOOLTIP        = 9999 ' renders on top but inactive for hit-test


'==============================================================================
' CONTEXT BITMASK SLOTS (64 total available)
'   - bits 0..19:  modal/subsystem state
'   - bits 20..31: held-key chord initiators
'   - bits 32..63: cursor-region flags (auto-set by INPUT_update_context)
'==============================================================================
' Mode/subsystem flags
CONST CTX_TEXT_ACTIVE           = &H0000000000000001  ' bit 0
CONST CTX_FILE_DIALOG_OPEN      = &H0000000000000002
CONST CTX_IMAGE_IMPORT_ACTIVE   = &H0000000000000004
CONST CTX_REFIMG_REPOSITION     = &H0000000000000008
CONST CTX_MAGIC_WAND_ACTIVE     = &H0000000000000010
CONST CTX_MOVE_ACTIVE           = &H0000000000000020
CONST CTX_GRID_OFFSET_PICK      = &H0000000000000040
CONST CTX_SETTINGS_OPEN         = &H0000000000000080
CONST CTX_POPUP_MENU_OPEN       = &H0000000000000100
CONST CTX_COMMAND_PALETTE_OPEN  = &H0000000000000200
CONST CTX_TRANSFORM_ACTIVE      = &H0000000000000400
CONST CTX_DRAWING_IN_PROGRESS   = &H0000000000000800
' bits 12-19 reserved

' Held-key chord initiators (set by INPUT_update_context from raw key state)
CONST CTX_G_HELD                = &H0000000000100000  ' bit 20
CONST CTX_M_HELD                = &H0000000000200000
CONST CTX_Z_HELD                = &H0000000000400000
CONST CTX_E_HELD                = &H0000000000800000
CONST CTX_F_HELD                = &H0000000001000000
CONST CTX_W_HELD                = &H0000000002000000
CONST CTX_SPACE_HELD            = &H0000000004000000
CONST CTX_ALT_HELD              = &H0000000008000000
' bits 28-31 reserved for future chord initiators

' Cursor-region flags (auto-set from REGION_hit_test result)
CONST CTX_OVER_CANVAS           = &H0000000100000000  ' bit 32
CONST CTX_OVER_TOOLBAR          = &H0000000200000000
CONST CTX_OVER_MENUBAR          = &H0000000400000000
CONST CTX_OVER_LAYER_PANEL      = &H0000000800000000
CONST CTX_OVER_PALETTE          = &H0000001000000000
CONST CTX_OVER_EDIT_BAR         = &H0000002000000000
CONST CTX_OVER_ADV_BAR          = &H0000004000000000
CONST CTX_OVER_STATUS_BAR       = &H0000008000000000
CONST CTX_OVER_DRAWER           = &H0000010000000000
CONST CTX_OVER_PREVIEW          = &H0000020000000000
CONST CTX_OVER_COLOR_MIXER      = &H0000040000000000
CONST CTX_OVER_IMAGE_BROWSER    = &H0000080000000000
CONST CTX_OVER_CHARMAP          = &H0000100000000000
CONST CTX_OVER_ORGANIZER        = &H0000200000000000
CONST CTX_OVER_DIALOG           = &H0000400000000000  ' any modal dialog
CONST CTX_OVER_POPUP_MENU       = &H0000800000000000
' bits 48-63 reserved for additional regions


'==============================================================================
' DRAG / DOUBLE-CLICK CONSTANTS
'==============================================================================
CONST DRAG_THRESHOLD_PX = 3      ' must move this far before DRAG_START fires
CONST DBLCLICK_WINDOW_S = 0.3    ' seconds for double-click


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
    eventType      AS INTEGER                   ' EVT_*
    region         AS INTEGER                   ' REGION_*; REGION_GLOBAL = any region
    keycode        AS LONG                      ' for EVT_KEY_*; 0 = any/unused
    button         AS INTEGER                   ' for EVT_MOUSE_* / gamepad / MIDI; 0 = any
    wheelDir       AS INTEGER                   ' for EVT_MOUSE_WHEEL: +1 / -1; 0 = any
    requireMods    AS INTEGER                   ' all these bits must be in MODS_NOW%
    forbidMods     AS INTEGER                   ' none of these bits may be in MODS_NOW%
    requireCtx     AS _UNSIGNED _INTEGER64      ' all these bits must be in INPUT_CONTEXT
    forbidCtx      AS _UNSIGNED _INTEGER64      ' none of these bits may be in INPUT_CONTEXT
    actionId       AS INTEGER                   ' CMD_execute_action target
    dispatched     AS INTEGER                   ' TRUE = new dispatcher fires; FALSE = legacy
    device         AS INTEGER                   ' DEVICE_* (filled at registration)
    label          AS STRING * 48               ' for cheatsheet / audit / inputs.log
END TYPE


''
' Screen rectangle for one region. Updated each frame by the owning panel's
' render SUB via REGION_set_bounds. Hidden panels call REGION_set_inactive.
'
TYPE REGION_BOUNDS
    active         AS INTEGER       ' is region currently displayed + hit-testable?
    x              AS INTEGER
    y              AS INTEGER
    w              AS INTEGER
    h              AS INTEGER
    zOrder         AS INTEGER       ' higher wins on overlap
END TYPE


''
' Per-event context populated by INPUT_dispatch_frame, read by action handlers.
' Read-only from the handler's POV. Valid only during action dispatch.
'
TYPE INPUT_EVENT_OBJ
    eventType      AS INTEGER
    region         AS INTEGER
    keycode        AS LONG
    button         AS INTEGER
    wheelDir       AS INTEGER
    mouseX         AS INTEGER                   ' screen X
    mouseY         AS INTEGER                   ' screen Y
    canvasX        AS INTEGER                   ' canvas X (post-zoom/pan/snap)
    canvasY        AS INTEGER                   ' canvas Y
    mods           AS INTEGER                   ' MOD_* bitmask snapshot
    ctx            AS _UNSIGNED _INTEGER64      ' INPUT_CONTEXT snapshot
    value          AS SINGLE                    ' continuous value: analog 0..1, MIDI 0..127, tablet pressure 0..1
    value2         AS SINGLE                    ' secondary axis (analog stick Y when value=X)
    device         AS INTEGER                   ' DEVICE_*
    deviceIdx      AS INTEGER                   ' for multi-device disambiguation
END TYPE


''
' Internal: one detected event awaiting dispatch (queued each frame by
' INPUT_detect_events, drained by INPUT_dispatch_frame).
'
TYPE DETECTED_EVENT
    eventType      AS INTEGER
    region         AS INTEGER
    keycode        AS LONG
    button         AS INTEGER
    wheelDir       AS INTEGER
    mouseX         AS INTEGER
    mouseY         AS INTEGER
    canvasX        AS INTEGER
    canvasY        AS INTEGER
    value          AS SINGLE
    value2         AS SINGLE
    device         AS INTEGER
    deviceIdx      AS INTEGER
END TYPE


'==============================================================================
' SHARED STATE
'==============================================================================
CONST INPUT_MAX_BINDS  = 1024
CONST INPUT_MAX_EVENTS = 64       ' per-frame event queue cap

DIM SHARED INPUT_BINDS(1 TO INPUT_MAX_BINDS)         AS INPUT_BIND
DIM SHARED INPUT_BIND_COUNT                          AS INTEGER
DIM SHARED REGION_BOUNDS_TABLE(0 TO REGION_TABLE_SIZE - 1) AS REGION_BOUNDS
DIM SHARED INPUT_EVENT                               AS INPUT_EVENT_OBJ
DIM SHARED INPUT_CONTEXT                             AS _UNSIGNED _INTEGER64
DIM SHARED INPUT_CONTEXT_PREV                        AS _UNSIGNED _INTEGER64
DIM SHARED DETECTED_EVENTS(1 TO INPUT_MAX_EVENTS)    AS DETECTED_EVENT
DIM SHARED DETECTED_EVENT_COUNT                      AS INTEGER

' Edge-detection state for keys (indexed by binding index)
DIM SHARED KEY_DOWN_LAST(1 TO INPUT_MAX_BINDS)       AS INTEGER

' Edge-detection state for mouse buttons + drag state machine
DIM SHARED MOUSE_BTN_DOWN_LAST(1 TO 3)               AS INTEGER
DIM SHARED MOUSE_DOWN_REGION(1 TO 3)                 AS INTEGER
DIM SHARED MOUSE_DOWN_X(1 TO 3)                      AS INTEGER
DIM SHARED MOUSE_DOWN_Y(1 TO 3)                      AS INTEGER
DIM SHARED MOUSE_DOWN_TIME(1 TO 3)                   AS DOUBLE
DIM SHARED MOUSE_DRAG_STARTED(1 TO 3)                AS INTEGER
DIM SHARED MOUSE_LAST_CLICK_TIME(1 TO 3)             AS DOUBLE
DIM SHARED MOUSE_LAST_CLICK_REGION(1 TO 3)           AS INTEGER

' Hover state for enter/leave detection
DIM SHARED HOVER_REGION_LAST                         AS INTEGER

' Performance optimization: interesting-keys set built at init
DIM SHARED INPUT_INTERESTING_KEYS(0 TO 65535)        AS _BYTE

' Developer mode + log path
DIM SHARED DEV_MODE                                  AS INTEGER
DIM SHARED INPUTS_LOG_PATH                           AS STRING


'==============================================================================
' DECLARES
'==============================================================================
DECLARE SUB      INPUTS_init ()
DECLARE SUB      INPUTS_log (msg AS STRING)
DECLARE SUB      INPUT_update_context ()
DECLARE SUB      INPUT_detect_events ()
DECLARE SUB      INPUT_dispatch_frame ()
DECLARE SUB      INPUT_audit ()
DECLARE SUB      INPUT_interesting_keys_build ()
DECLARE SUB      REGION_set_bounds (region AS INTEGER, x AS INTEGER, y AS INTEGER, w AS INTEGER, h AS INTEGER, zOrder AS INTEGER)
DECLARE SUB      REGION_set_inactive (region AS INTEGER)
DECLARE SUB      REGION_clear_all ()
DECLARE SUB      REGION_check_consistency ()
DECLARE FUNCTION REGION_hit_test% (mouseX AS INTEGER, mouseY AS INTEGER)
DECLARE FUNCTION INPUT_register% ( _
    eventType AS INTEGER, region AS INTEGER, keycode AS LONG, button AS INTEGER, _
    wheelDir AS INTEGER, requireMods AS INTEGER, forbidMods AS INTEGER, _
    requireCtx AS _UNSIGNED _INTEGER64, forbidCtx AS _UNSIGNED _INTEGER64, _
    actionId AS INTEGER, dispatched AS INTEGER, label AS STRING)
DECLARE FUNCTION INPUT_BIND_matches% (bindIdx AS INTEGER, evtIdx AS INTEGER)
DECLARE FUNCTION INPUT_BINDS_could_collide% (a AS INTEGER, b AS INTEGER)
