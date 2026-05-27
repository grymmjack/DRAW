''
' DRAW - CORE/HELPERS.BI
' =============================================================================
' Cross-cutting helper utilities. Idiom unifications identified by the input
' rearchitecture spec (PLANS/REARCHITECTURE.md §12). These collapse repeated
' patterns scattered across the codebase into single, well-tested helpers.
'
' Categories:
'   - Image handle validation:    SAFE_FREEIMAGE
'   - Render state save/restore:  DEST/SRC/FONT stack-based helpers
'   - Pixel manipulation:         PIXEL_DOUBLE_AXIS
'   - Scene invalidation:         SCENE_invalidate, SCENE_request_render
'   - Modifier checks:            MODS_only%, MODS_NOW% (snapshot)
'
' Why a stack for DEST/SRC: many SUBs need to set _DEST temporarily but may
' EXIT early on conditions. A stack with depth >= 4 lets callers nest without
' tracking restore order; dev-mode underflow/overflow checks catch bugs.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE


'==============================================================================
' Render state save/restore stacks
'==============================================================================
' Stack depth 8 is well beyond the worst-case nesting we've seen (3-4 levels
' in transform-heavy operations). Underflow/overflow logs to _LOGERROR.
CONST RENDER_STATE_STACK_DEPTH = 8

DIM SHARED DEST_STACK(1 TO RENDER_STATE_STACK_DEPTH) AS LONG
DIM SHARED DEST_STACK_TOP      AS INTEGER

DIM SHARED SOURCE_STACK(1 TO RENDER_STATE_STACK_DEPTH) AS LONG
DIM SHARED SOURCE_STACK_TOP    AS INTEGER

DIM SHARED FONT_STACK(1 TO RENDER_STATE_STACK_DEPTH) AS LONG
DIM SHARED FONT_STACK_TOP      AS INTEGER

DEST_STACK_TOP   = 0
SOURCE_STACK_TOP = 0
FONT_STACK_TOP   = 0


'==============================================================================
' Modifier bitmask constants — also used by INPUT system
' (Defined here so HELPERS doesn't depend on INPUT.BI)
'==============================================================================
CONST MOD_NONE  = 0
CONST MOD_CTRL  = 1
CONST MOD_SHIFT = 2
CONST MOD_ALT   = 4


' DECLARE SUB/FUNCTION blocks removed — QB64-PE auto-discovers SUBs and
' FUNCTIONs from the include chain. Only DECLARE LIBRARY still needs an
' explicit declaration (and DRAW has none).
