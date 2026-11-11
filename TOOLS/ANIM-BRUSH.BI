$INCLUDEONCE
' =============================================================================
' ANIM-BRUSH.BI — AnimBrush: a custom brush with one picture (cel) per frame.
'
' ANIM > AnimBrush > Pick Up takes the marquee's area from several frames of
' the sprite sheet: the same spot in each frame's cell, so a walk cycle
' becomes a brush that walks. The cels live here; CUSTOM_BRUSH.IMAGE is a copy
' of the current cel (AB_show), so every custom-brush routine (render, stamp,
' cursor preview) works unchanged. CUSTOM_BRUSH_reset drops the cels, so the
' plain Ctrl+B brush and a Drawer brush stay one picture; the brush stash
' (pattern / gradient modes) keeps them.
' =============================================================================

CONST AB_MAX_CELS = 256

CONST AB_ACT_PICKUP        = 2563 ' ANIM > AnimBrush > Pick Up (the current layer)
CONST AB_ACT_PICKUP_MERGED = 2564 ' ANIM > AnimBrush > Pick Up Merged (every visible layer)

TYPE AB_OBJ
    n      AS INTEGER ' cels (0 = no AnimBrush: the custom brush is one picture)
    cur    AS INTEGER ' the cel CUSTOM_BRUSH.IMAGE shows (1-based)
    w      AS INTEGER ' cel size (every cel is the same size)
    h      AS INTEGER
    merged AS INTEGER ' picked up from every visible layer
    srcF   AS INTEGER ' the frame the selection was in
END TYPE
DIM SHARED AB AS AB_OBJ
DIM SHARED AB_CEL(1 TO AB_MAX_CELS) AS LONG      ' cel images (32-bit, w x h)
DIM SHARED AB_FROM(1 TO AB_MAX_CELS) AS INTEGER  ' the frame each cel came from

' the brush stash (CUSTOM_BRUSH_stash / _unstash) keeps the cels here
DIM SHARED AB_SV AS AB_OBJ
DIM SHARED AB_SV_CEL(1 TO AB_MAX_CELS) AS LONG
DIM SHARED AB_SV_FROM(1 TO AB_MAX_CELS) AS INTEGER
