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
DIM SHARED EFFECT_CLIP_TO_SEL  AS INTEGER
DIM SHARED EFFECT_SEL_AS_SHAPE AS INTEGER
EFFECT_CLIP_TO_SEL  = -1 ' TRUE
EFFECT_SEL_AS_SHAPE = 0  ' FALSE

' Native canvas-space top-left of the loupe preview crop, published by
' IMAGE_ADJ_update_loupe so the shared preview/clip code can map loupe pixels
' back to canvas (and thus selection) coordinates.
DIM SHARED IMGADJ_LOUPE_CROPX AS LONG
DIM SHARED IMGADJ_LOUPE_CROPY AS LONG

' Padding (native px) added around the visible loupe window when capturing the
' crop, so edge effects (glow/shadow/outline/bevel) see real neighbouring canvas
' pixels instead of treating the crop's rectangular border as the shape edge.
' The engine runs on the padded thumb; only the central window is displayed.
CONST IMGADJ_LOUPE_PAD = 40

' Mosaic / Extrude cell shapes (shared cell-SHAPE picker). SQUARE keeps the classic
' behaviour; RECT/TRIANGLE use direct formulas; HEX/VORONOI/RANDOM use nearest-seed
' assignment (a seed lattice, odd rows offset for hex, hashed jitter for the others).
CONST MOSAIC_SHAPE_SQUARE   = 0
CONST MOSAIC_SHAPE_RECT     = 1
CONST MOSAIC_SHAPE_TRIANGLE = 2
CONST MOSAIC_SHAPE_HEX      = 3
CONST MOSAIC_SHAPE_VORONOI  = 4
CONST MOSAIC_SHAPE_RANDOM   = 5
CONST MOSAIC_SHAPE_COUNT    = 6

' Click-to-set-CENTER (Pinch/Bulge, Kaleidoscope, Lens Flare, …): the user clicks
' inside the loupe preview pane to place the effect's centre. Stored in CANVAS
' pixels so it maps cleanly to both the preview thumb (subtract IMGADJ_LOUPE_CROPX/Y)
' and the full layer buffer (add the layer apron). IMGADJ_CENTER_SET is FALSE until
' the first pick, in which case each effect falls back to its own default (image
' centre / flare corner). Reset at the top of each center-using dialog.
DIM SHARED IMGADJ_CENTER_SET%
DIM SHARED IMGADJ_CENTER_CX AS LONG
DIM SHARED IMGADJ_CENTER_CY AS LONG

' Silhouette version of the loupe crop (same padded size as ctx.origThumb; alpha =
' selection coverage, RGB = layer) built by IMAGE_ADJ_update_loupe when a selection
' is active AND framed on the selection. Edge-effect dialogs run the engine on THIS
' instead of origThumb so the preview radiates from the selection edge, matching the
' sel-as-shape apply. 0 when no selection.
DIM SHARED IMGADJ_SHAPE_THUMB AS LONG

' ---- Last-effect memory: Redo / Recall / Blend (Photoshop-style) -------------
' FX_PENDING_ACTION is set at the top of the effect dispatch in CMD_execute_action
' so the shared apply funcs know WHICH effect is committing. On commit they snapshot
' the layer BEFORE/AFTER (for Blend/Fade) and remember the action id + undo label.
DIM SHARED FX_PENDING_ACTION  AS INTEGER
DIM SHARED LAST_FX_ACTION     AS INTEGER
DIM SHARED LAST_FX_LABEL      AS STRING
DIM SHARED LAST_FX_BEFORE     AS LONG
DIM SHARED LAST_FX_AFTER      AS LONG
DIM SHARED LAST_FX_LAYER      AS INTEGER
' Instant-Redo replay blob: Layer-FX dialogs stash their final int params here (and
' set LAST_FX_REPLAYABLE = TRUE) so IMAGE_ADJ_redo_last can re-run the engine with no
' dialog; effects that don't stash fall back to re-opening the dialog (Recall). The
' effect COLOURS come from the current FG/BG at replay time, like a fresh apply.
DIM SHARED LAST_FX_REPLAYABLE AS INTEGER
DIM SHARED LAST_FX_P(0 TO 7) AS INTEGER
' TRUE while IMAGE_ADJ_blend_last is recompositing, so the apply hook doesn't treat
' the blend itself as a new "last effect".
DIM SHARED FX_IN_BLEND        AS INTEGER

' ---- Slider dialogs ----------------------------------------------------------
