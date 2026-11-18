''
' DRAW - TOOLS/BRUSH.BI
' =============================================================================
' UDT for brush tool.
'
' @todo
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

DIM SHARED BRUSH_HISTORY_BEFORE_IMG AS LONG
DIM SHARED BRUSH_HISTORY_COLOR      AS _UNSIGNED LONG
DIM SHARED BRUSH_HISTORY_FLAGS      AS LONG
DIM SHARED BRUSH_HISTORY_LAYER      AS INTEGER
DIM SHARED BRUSH_HISTORY_LAYER_ID   AS LONG
DIM SHARED BRUSH_HISTORY_SMART      AS INTEGER

' Antialiased stamps (PAINT_stamp_size, PAINT_on's soft circles): the strongest
' coverage per pixel this frame wins, so a thick antialiased line / outline -
' a soft circle at every pixel along it - keeps soft edges instead of the
' circles building up into a hard one. One byte per pixel of the layer being
' stamped; freed at the top of each frame (PAINT_aam_end in LOOP_start).
DIM SHARED PAINT_AAM_USE AS INTEGER ' TRUE while a soft stamp draws
DIM SHARED PAINT_AAM_IMG AS LONG    ' the image the mask is for (0 = none)
DIM SHARED PAINT_AAM_W   AS LONG
DIM SHARED PAINT_AAM_H   AS LONG
DIM SHARED PAINT_AAM_MEM AS _MEM
