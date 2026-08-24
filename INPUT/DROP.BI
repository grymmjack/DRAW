''
' DRAW - INPUT/DROP.BI
' =============================================================================
' Improved drag-and-drop dispatch. QB64-PE's OS file-drop exposes only the file
' list (no drop coordinates), so at drop time we read MOUSE.RAW_X/Y (the cursor
' sits at the drop point) and hit-test UI regions with REGION_hit_test% to decide
' what a dropped image should do:
'   - menu bar    -> open the file in a new isolated instance
'   - brush bin   -> add the image as a custom brush (drawer slot)
'   - layer panel -> new layer holding the image
'   - canvas      -> stamp onto the current layer (destructive, undoable)
'   - elsewhere   -> interactive Import Image placement (the safe default)
' Images larger than the canvas fall back to the interactive Import workflow.
'
' Full design + code anchors: PLANS/DRAG-DROP-PLAN.md
'
' IMPORTANT: QB64-PE/GLFW does not report the cursor position during an external OS
' drag, and _MOUSEX is not synced until the drag releases. So a dropped file is QUEUED
' when _TOTALDROPPEDFILES fires and DISPATCHED a couple of frames later (DROP_tick, run
' after MOUSE_input_handler), by which time MOUSE.RAW_X/Y holds the cursor's resting
' position = the drop point. Dispatching immediately misroutes every non-canvas drop.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

' Deferred-drop queue (see note above)
DIM SHARED DROP_PENDING_FILE   AS STRING
DIM SHARED DROP_PENDING_FRAMES AS INTEGER
