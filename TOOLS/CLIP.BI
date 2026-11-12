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
CONST CLIP_CHUNK_VERSION = 2 ' 2: + the sound cues (phase 2 K7; a version-1 reader stops before them)

CONST CLIP_ACT_PLACE   = 2620 ' ANIM > Clip > Place AnimBrush as Clip (click a frame)
CONST CLIP_ACT_BAKE    = 2621 ' ANIM > Clip > Bake Clip to Pixels
CONST CLIP_ACT_MODE0   = 2622 ' 2622-2626: Loop / Ping-pong / Once / Hold / Reverse
CONST CLIP_ACT_FLIP_X  = 2627
CONST CLIP_ACT_FLIP_Y  = 2628
CONST CLIP_ACT_UPD_BIN = 2629 ' ANIM > Clip Layer > Update Clip from Bin (the Drawer bin its cels came from)
CONST CLIP_ACT_UPD_AB  = 2630 ' ANIM > Clip Layer > Update Clip from AnimBrush (the current AnimBrush's cels)
CONST CLIP_ACT_MAKE    = 2631 ' ANIM > Clip Layer > Make Clip from Selected Frames (pick up, cut, place)
CONST CLIP_ACT_SOURCES = 2632 ' ANIM > Clip Layer > Clip Sources... (every source, the layers using it)
CONST CLIP_ACT_SRC_PREV = 2633 ' the current clip: the previous / next source (Animation panel SOURCE row)
CONST CLIP_ACT_SRC_NEXT = 2634
CONST CLIP_ACT_SRC_RENAME = 2635 ' rename the current clip's source
CONST CLIP_ACT_SRC_LAYERS = 2636 ' select every layer using the current clip's source
CONST CLIP_ACT_PURGE   = 2637 ' ANIM > Clip Layer > Remove Unused Clip Sources
CONST CLIP_ACT_CUE_CEL  = 2638 ' ANIM > Clip Layer > Sound on This Cel... (the cel the current frame shows)
CONST CLIP_ACT_CUE_ONCE = 2639 ' ANIM > Clip Layer > Sound When the Clip Starts... (its In frame, once)
CONST CLIP_ACT_CUE_LOOP = 2640 ' ANIM > Clip Layer > Sound Each Time the Clip Starts Over... (In, and every loop)
CONST CLIP_ACT_CUE_CLEAR = 2641 ' ANIM > Clip Layer > Remove the Clip's Sounds (every cue of its source)

TYPE CLIP_SRC_OBJ
    nm      AS STRING * 32
    strip   AS LONG    ' n * cw x ch, 32-bit (0 = slot free)
    n       AS INTEGER
    cw      AS INTEGER
    ch      AS INTEGER
    binSlot AS INTEGER ' the Drawer slot it came from (0 = none; Update Clip from Bin)
    gone    AS INTEGER ' Remove Unused Clip Sources took it off the list (kept for undo; never saved)
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

' Sound cues (phase 2 K7): a source's sounds - one plays whenever cel k
' shows (CEL), or when the clip starts (ONCE: its In frame; LOOP: and each
' time its cels start over). Every clip on the source plays them; the clip
' layer's undo state (CLIP_state$) carries its source's cues. The paths are
' kept as picked and found the way soundtrack files are (ANIM_SND_resolve$).
CONST CLIP_CUE_MAX = 128
CONST CLIP_CUEK_CEL  = 0
CONST CLIP_CUEK_ONCE = 1
CONST CLIP_CUEK_LOOP = 2
DIM SHARED CLIP_CUE_N AS INTEGER
DIM SHARED CLIP_CUE_SRC(1 TO CLIP_CUE_MAX) AS INTEGER
DIM SHARED CLIP_CUE_KIND(1 TO CLIP_CUE_MAX) AS INTEGER
DIM SHARED CLIP_CUE_CELN(1 TO CLIP_CUE_MAX) AS INTEGER ' CEL: the cel (1-based); else 0
DIM SHARED CLIP_CUE_PATH(1 TO CLIP_CUE_MAX) AS STRING

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
