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

' Set TRUE for one frame when the shared RESET-to-default button is clicked in an
' effect dialog; each dialog consumes it via IMGDLG_reset2/3/4 to restore defaults.
DIM SHARED IMGDLG_RESET_CLICKED AS INTEGER

' ---- Effect / selection interaction -----------------------------------------
' When a marquee/lasso selection is active, effects can either CLIP to it (only
' pixels inside the selection change) or use it as the SHAPE (edge effects like
' glow/shadow/outline radiate from the selection edge, drawing inside AND outside
' it). CLIP is on by default; SEL_AS_SHAPE flips edge effects to selection-as-base.
DIM SHARED EFFECT_CLIP_TO_SEL AS INTEGER
DIM SHARED EFFECT_SEL_AS_SHAPE AS INTEGER
EFFECT_CLIP_TO_SEL = -1   ' TRUE
EFFECT_SEL_AS_SHAPE = 0   ' FALSE

' Native canvas-space top-left of the loupe preview crop, published by
' IMAGE_ADJ_update_loupe so the shared preview/clip code can map loupe pixels
' back to canvas (and thus selection) coordinates.
DIM SHARED IMGADJ_LOUPE_CROPX AS LONG
DIM SHARED IMGADJ_LOUPE_CROPY AS LONG

' ---- Slider dialogs ----------------------------------------------------------
