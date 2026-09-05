''
' DRAW - CFG/BINDINGS.BI
' =============================================================================
' User keyboard-binding OVERRIDES (Phase 3 customization engine).
'
' The compiled-in defaults live in INPUT/INPUT.BM (INPUTS_register_all). A user
' rebind is stored as a delta keyed by actionId in DRAW.bindings (config dir);
' at startup the deltas are applied ON TOP of the registered defaults by
' re-pointing the matching INPUT_BINDS entry's trigger. Only overridden rows are
' persisted (compact, forward-compatible).
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

CONST BINDINGS_MAX_OVERRIDES = 256

' One user override: re-point action `actionId`'s keyboard binding to a new trigger.
TYPE BINDING_OVERRIDE
    actionId    AS INTEGER   ' CMD action whose binding is remapped
    keycode     AS LONG      ' new physical keycode (keyboard overrides)
    requireMods AS INTEGER   ' MOD_* bits required
    forbidMods  AS INTEGER   ' MOD_* bits forbidden
    device      AS INTEGER   ' DEVICE_KEYBOARD or DEVICE_MOUSE
    button      AS INTEGER   ' new mouse button (button overrides; 0 otherwise)
    wheelDir    AS INTEGER   ' new wheel direction ±1 vertical / ±2 tilt (wheel overrides; 0 otherwise)
    eventType   AS INTEGER   ' EVT_MOUSE_DOWN (button) or EVT_MOUSE_WHEEL (wheel); 0 in legacy files = button. Lets one action carry an independent button AND wheel override.
    defWheelDir AS INTEGER   ' the TARGET wheel bind's compiled default dir — so an action with BOTH a tilt (±2) and a vertical (±1) bind rebinds the right one independently.
    active      AS INTEGER   ' TRUE = a real override row
END TYPE

DIM SHARED BINDING_OVERRIDES(1 TO BINDINGS_MAX_OVERRIDES) AS BINDING_OVERRIDE
DIM SHARED BINDING_OVERRIDE_COUNT AS INTEGER
DIM SHARED BINDINGS_FILE$          ' resolved path to DRAW.bindings (set in BINDINGS_init)
