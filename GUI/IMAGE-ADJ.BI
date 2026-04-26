''
' DRAW - GUI/IMAGE-ADJ.BI
' =============================================================================
' IMAGE menu adjustments - declarations for modal dialogs and direct ops.
' All operations are permanently applied to the active layer with undo support.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

' ---- Lifecycle ---------------------------------------------------------------

' ---- Internal helpers --------------------------------------------------------

' ---- Direct ops (no dialog) --------------------------------------------------

' ---- Internal function -------------------------------------------------------

' ---- Live loupe preview helpers ---------------------------------------------

' Shared layer-alpha mask for preview: captures the current layer's rendered
' region at the same screen coordinates as origThumb. Used by mask_preview
' to restore original pixels where the layer is transparent.
DIM SHARED IMGADJ_LAYER_MASK AS LONG

' ---- Slider dialogs ----------------------------------------------------------
