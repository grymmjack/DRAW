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
DECLARE SUB IMAGE_ADJ_init ()

' ---- Internal helpers --------------------------------------------------------
DECLARE SUB IMAGE_ADJ_apply_to_layer (adjResult AS LONG)

' ---- Direct ops (no dialog) --------------------------------------------------
DECLARE SUB IMAGE_ADJ_invert ()
DECLARE SUB IMAGE_ADJ_desaturate ()

' ---- Internal function -------------------------------------------------------
DECLARE FUNCTION IMAGE_ADJ_apply_sharpen& (sourceImg AS LONG, amt AS INTEGER)

' ---- Live loupe preview helpers ---------------------------------------------
DECLARE SUB IMAGE_ADJ_setup_preview (ctx AS DIALOG_CTX, layerImg AS LONG)
DECLARE SUB IMAGE_ADJ_update_loupe (ctx AS DIALOG_CTX)

' ---- Slider dialogs ----------------------------------------------------------
DECLARE SUB IMAGE_ADJ_brightness_contrast_dialog ()
DECLARE SUB IMAGE_ADJ_hue_saturation_dialog ()
DECLARE SUB IMAGE_ADJ_levels_dialog ()
DECLARE SUB IMAGE_ADJ_color_balance_dialog ()
DECLARE SUB IMAGE_ADJ_blur_dialog ()
DECLARE SUB IMAGE_ADJ_sharpen_dialog ()
DECLARE SUB IMAGE_ADJ_posterize_dialog ()
DECLARE SUB IMAGE_ADJ_pixelate_dialog ()
