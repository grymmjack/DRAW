''
' DRAW - TOOLS/ANIM-CANVAS.BI
' =============================================================================
' In the lightbox the current frame is the canvas (Rick 2026-11-09: "anything
' that uses the canvas needs to consider lightbox mode"): its cell gives the
' bounds, centre and size that align / distribute, smart guides, the
' transform and the other canvas-wide commands use. ANIM_CV_rect% is the one
' question they ask. See .claude/instructions/draw-animation.md.
'
$INCLUDEONCE

' The frame a transform began on in the lightbox (0 = not in one): its
' commit is clipped to that frame's cell.
DIM SHARED ANIM_CV_TF_F AS INTEGER
' The pane Move tool's drawing (the current layer in the current frame's cell
' at the press, canvas pixels) for smart guides; ANIM_CV_MV_W = 0: none.
DIM SHARED ANIM_CV_MV_X AS INTEGER
DIM SHARED ANIM_CV_MV_Y AS INTEGER
DIM SHARED ANIM_CV_MV_W AS INTEGER
DIM SHARED ANIM_CV_MV_H AS INTEGER
' QA: the last pane-move guide step (ANIMCV: offset in, guides v / h, snap, offset out)
DIM SHARED ANIM_CV_LAST AS STRING
' A centred effect running per frame cell (ANIM_CV_fx_*): the layer it splits
' (0 = none - also the re-entry guard) and that buffer's apron.
DIM SHARED ANIM_CV_FX_L AS INTEGER
DIM SHARED ANIM_CV_FX_AW AS INTEGER
DIM SHARED ANIM_CV_FX_AH AS INTEGER
