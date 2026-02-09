''
' DRAW - CORE/PERF.BI
' =============================================================================
' Performance profiling instrumentation for render pipeline analysis.
' Measures wall-clock time of each major section in SCREEN_render and the
' main loop, then logs average timings via _LOGINFO every N frames.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

' Section IDs (keep contiguous starting at 0)
CONST PERF_RENDER_TOTAL       = 0   ' Entire SCREEN_render call
CONST PERF_GUI_ONLY_PATH      = 1   ' GUI-only refresh path
CONST PERF_DIRTY_RECT_PATH    = 2   ' Dirty-rect fast path (partial restore+scale)
CONST PERF_FULL_CLS_GUI       = 3   ' Full render: CLS + GUI rebuild
CONST PERF_FULL_CHECKERBOARD  = 4   ' Full render: transparency checkerboard
CONST PERF_FULL_LAYERS        = 5   ' Full render: layer compositing loop
CONST PERF_FULL_GRIDS         = 6   ' Full render: regular grid + pixel grid
CONST PERF_FULL_SYMMETRY      = 7   ' Full render: symmetry guide overlay
CONST PERF_FULL_TOOL_PREVIEW  = 8   ' Full render: all tool previews
CONST PERF_FULL_GUI_OVERLAY   = 9   ' Full render: GUI layer composite + status bars
CONST PERF_FULL_CROSSHAIR_CMD = 10  ' Full render: crosshair + command palette
CONST PERF_SCENE_CACHE_SAVE   = 11  ' Scene cache save (_PUTIMAGE to cache)
CONST PERF_SELECTION_OVERLAY  = 12  ' Selection overlay (marching ants, after SkipToPointer)
CONST PERF_POINTER_RENDER     = 13  ' POINTER_update + POINTER_render
CONST PERF_FINAL_SCALE        = 14  ' Scale CANVAS -> WINDOW_IMG (_PUTIMAGE)
CONST PERF_DISPLAY_CALL       = 15  ' _DISPLAY call
CONST PERF_MOUSE_INPUT        = 16  ' MOUSE_input_handler
CONST PERF_KEYBOARD_INPUT     = 17  ' KEYBOARD_input_handler
CONST PERF_STICK_INPUT         = 18  ' STICK_input_handler
CONST PERF_IDLE_DETECT        = 19  ' Idle detection logic
CONST PERF_LIMIT_WAIT         = 20  ' _LIMIT wait time
CONST PERF_MAIN_LOOP_TOTAL    = 21  ' Entire main loop iteration
CONST PERF_POST_INPUT          = 22  ' Post-render input handler loops
CONST PERF_SECTION_COUNT      = 23  ' Total number of sections

' How often to log (frames)
CONST PERF_LOG_INTERVAL        = 120

' Master enable/disable switch for profiling
' Set to TRUE to enable profiling, FALSE to skip all PERF overhead
DIM SHARED PERF_ENABLED AS INTEGER
PERF_ENABLED% = FALSE

' Timing accumulators (sum over interval)
DIM SHARED PERF_sum(0 TO PERF_SECTION_COUNT - 1) AS DOUBLE
' Per-frame start time scratch
DIM SHARED PERF_t0(0 TO PERF_SECTION_COUNT - 1) AS DOUBLE
' Hit count per section over interval
DIM SHARED PERF_hits(0 TO PERF_SECTION_COUNT - 1) AS LONG
' Frame counter
DIM SHARED PERF_frame_count AS LONG
' Per-frame total for SCREEN_render (to compute max)
DIM SHARED PERF_frame_render_ms AS DOUBLE
DIM SHARED PERF_max_render_ms AS DOUBLE
' Section names for logging
DIM SHARED PERF_names(0 TO PERF_SECTION_COUNT - 1) AS STRING

' Render path tracking
DIM SHARED PERF_current_path AS INTEGER  ' 1=gui-only, 2=dirty-rect, 3=full

' Initialize names
PERF_names(PERF_RENDER_TOTAL)       = "RENDER TOTAL"
PERF_names(PERF_GUI_ONLY_PATH)      = "  gui-only path"
PERF_names(PERF_DIRTY_RECT_PATH)    = "  dirty-rect path"
PERF_names(PERF_FULL_CLS_GUI)       = "  full: CLS+GUI"
PERF_names(PERF_FULL_CHECKERBOARD)  = "  full: checkerboard"
PERF_names(PERF_FULL_LAYERS)        = "  full: layers"
PERF_names(PERF_FULL_GRIDS)         = "  full: grids"
PERF_names(PERF_FULL_SYMMETRY)      = "  full: symmetry"
PERF_names(PERF_FULL_TOOL_PREVIEW)  = "  full: tool previews"
PERF_names(PERF_FULL_GUI_OVERLAY)   = "  full: GUI overlay"
PERF_names(PERF_FULL_CROSSHAIR_CMD) = "  full: xhair+cmd"
PERF_names(PERF_SCENE_CACHE_SAVE)   = "  scene cache save"
PERF_names(PERF_SELECTION_OVERLAY)  = "  selection overlay"
PERF_names(PERF_POINTER_RENDER)     = "  pointer render"
PERF_names(PERF_FINAL_SCALE)        = "  final scale"
PERF_names(PERF_DISPLAY_CALL)       = "  _DISPLAY"
PERF_names(PERF_MOUSE_INPUT)        = "MOUSE input"
PERF_names(PERF_KEYBOARD_INPUT)     = "KEYBOARD input"
PERF_names(PERF_STICK_INPUT)        = "STICK input"
PERF_names(PERF_IDLE_DETECT)        = "Idle detect"
PERF_names(PERF_LIMIT_WAIT)         = "_LIMIT wait"
PERF_names(PERF_MAIN_LOOP_TOTAL)    = "MAIN LOOP TOTAL"
PERF_names(PERF_POST_INPUT)         = "Post-render input"

DECLARE SUB PERF_start (section AS INTEGER)
DECLARE SUB PERF_stop (section AS INTEGER)
DECLARE SUB PERF_frame_end ()
