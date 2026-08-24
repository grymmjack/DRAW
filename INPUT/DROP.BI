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
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE
