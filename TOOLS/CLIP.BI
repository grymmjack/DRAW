$INCLUDEONCE
' =============================================================================
' CLIP.BI - clip layers (PLANS/CLIP-LAYERS.md, phase 1).
'
' A clip layer (LAYER_TYPE_CLIP) plays an AnimBrush across the frames: cel
' CLIP_cel_for%(f) (TOOLS/CLIP-MATH) is drawn into frame f's cell. The layer
' keeps an ordinary sheet image that CLIP_rebuild redraws from the clip, the
' way a symbol copy is rebuilt from its parent, so the render, onion skin,
' playback and every exporter (LAYERS_flatten&) read it unchanged.
'
'   Sources: the cels, copied into the document (Rick, 2026-11-12: Q1), one
'            strip image n * cw wide; shared by the clips made from them.
'   Instances: one per clip layer, found by the layer's historyId (they stay
'            when the layer is deleted, so undo brings the clip back; a save
'            writes only the ones whose layer is there).
'
' Saved in the "drCl" PNG chunk; drAw holds the layer as a plain IMAGE layer
' with its pixels, so an older DRAW sees the clip baked.
' =============================================================================
CONST CLIP_MODE_LOOP = 0
CONST CLIP_MODE_PING = 1
CONST CLIP_MODE_ONCE = 2 ' gone after the last cel (Q2)
CONST CLIP_MODE_HOLD = 3 ' stays on the last cel
CONST CLIP_MODE_REV  = 4

CONST CLIP_SRC_MAX  = 64
CONST CLIP_INST_MAX = 256
CONST CLIP_CHUNK_VERSION = 1

CONST CLIP_ACT_PLACE   = 2620 ' ANIM > Clip > Place AnimBrush as Clip (click a frame)
CONST CLIP_ACT_BAKE    = 2621 ' ANIM > Clip > Bake Clip to Pixels
CONST CLIP_ACT_MODE0   = 2622 ' 2622-2626: Loop / Ping-pong / Once / Hold / Reverse
CONST CLIP_ACT_FLIP_X  = 2627
CONST CLIP_ACT_FLIP_Y  = 2628
CONST CLIP_ACT_UPD_BIN = 2629 ' ANIM > Clip Layer > Update Clip from Bin (the Drawer bin its cels came from)
CONST CLIP_ACT_UPD_AB  = 2630 ' ANIM > Clip Layer > Update Clip from AnimBrush (the current AnimBrush's cels)
CONST CLIP_ACT_MAKE    = 2631 ' ANIM > Clip Layer > Make Clip from Selected Frames (pick up, cut, place)

TYPE CLIP_SRC_OBJ
    nm      AS STRING * 32
    strip   AS LONG    ' n * cw x ch, 32-bit (0 = slot free)
    n       AS INTEGER
    cw      AS INTEGER
    ch      AS INTEGER
    binSlot AS INTEGER ' the Drawer slot it came from (0 = none; for Update from Bin, phase 2)
END TYPE

TYPE CLIP_INST_OBJ
    layerId  AS LONG    ' the clip layer's historyId (0 = slot free)
    src      AS INTEGER
    inF      AS INTEGER ' the first frame it shows in
    outF     AS INTEGER ' the last (0 = to the end)
    startCel AS INTEGER ' the cel on frame In
    every    AS INTEGER ' a new cel every N frames
    mode     AS INTEGER ' CLIP_MODE_*
    flipX    AS INTEGER
    flipY    AS INTEGER
    px       AS INTEGER ' the cel's top left, relative to each frame's cell
    py       AS INTEGER
    dirty    AS INTEGER ' rebuild at the next CLIP_tick%
END TYPE

DIM SHARED CLIP_SRC(1 TO CLIP_SRC_MAX) AS CLIP_SRC_OBJ
DIM SHARED CLIP_INST(1 TO CLIP_INST_MAX) AS CLIP_INST_OBJ
DIM SHARED CLIP_SRC_N AS INTEGER  ' highest source slot in use
DIM SHARED CLIP_INST_N AS INTEGER ' highest instance slot in use
DIM SHARED CLIP_SIG AS STRING     ' the frame layout the clip layers were last built for
DIM SHARED CLIP_KEY AS LONG       ' the panel press CLIP_set belongs to (0 = none): a held drag is one undo step
DIM SHARED CLIP_LAST_KEY AS LONG, CLIP_LAST_REC AS INTEGER
DIM SHARED CLIP_DRAG_SLOT AS INTEGER ' a lightbox pane drag of a clip layer (the Move tool): its slot, 0 = none
DIM SHARED CLIP_DRAG_BEFORE AS STRING, CLIP_DRAG_X0 AS INTEGER, CLIP_DRAG_Y0 AS INTEGER
DIM SHARED CLIP_XS_KEY AS LONG ' the X-sheet bar's press keys (negative: never an Animation panel press's)
DIM SHARED CLIP_PLACING AS INTEGER ' 1 = Place as Clip waits for a click, 2 = placed, waiting for the release
