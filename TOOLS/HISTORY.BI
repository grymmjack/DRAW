''
' DRAW - TOOLS/HISTORY.BI
' =============================================================================
' Unified chronological history scaffolding.
'
' This module is the replacement target for split pixel and workspace undo.
' It is intentionally introduced first as a compiled foundation before producers
' are rerouted to it.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

CONST HISTORY_MAX_RECORDS = 1024

CONST HISTORY_KIND_NONE = 0
CONST HISTORY_KIND_LAYER_ADD = 1
CONST HISTORY_KIND_LAYER_DELETE = 2
CONST HISTORY_KIND_LAYER_REORDER = 3
CONST HISTORY_KIND_SELECTION_CHANGE = 4
CONST HISTORY_KIND_LINE = 5
CONST HISTORY_KIND_RECT = 6
CONST HISTORY_KIND_ELLIPSE = 7
CONST HISTORY_KIND_FILL = 8
CONST HISTORY_KIND_BRUSH = 9
CONST HISTORY_KIND_TRANSFORM = 10
CONST HISTORY_KIND_LAYER_RENAME = 11
CONST HISTORY_KIND_POLYLINE = 12
CONST HISTORY_KIND_LAYER_MERGE = 13
CONST HISTORY_KIND_LAYER_MERGE_VISIBLE = 14
CONST HISTORY_KIND_RASTERIZE = 15

CONST HISTORY_FLAG_FILLED = 1
CONST HISTORY_FLAG_CUSTOM_BRUSH = 2
CONST HISTORY_FLAG_THICK_BRUSH = 4
CONST HISTORY_FLAG_CLIPPED = 8
CONST HISTORY_FLAG_SYMMETRY = 16

CONST HISTORY_EXPORT_NONE = 0
CONST HISTORY_EXPORT_DIRECT = 1
CONST HISTORY_EXPORT_EXPANDED = 2
CONST HISTORY_EXPORT_RASTER = 3

TYPE HISTORY_RECORD
    kind AS INTEGER
    exportKind AS INTEGER
    sequence AS LONG
    primaryLayerId AS LONG
    secondaryLayerId AS LONG
    slotIndex AS INTEGER
    oldZIndex AS INTEGER
    newZIndex AS INTEGER
    img AS LONG
    img2 AS LONG
    oldName AS STRING * 64
    newName AS STRING * 64
    oldOpacity AS INTEGER
    oldVisible AS INTEGER
    oldOpacityLock AS INTEGER
    oldBlendMode AS INTEGER
    layerType AS INTEGER
    toolId AS INTEGER
    flags AS LONG
    x1 AS INTEGER
    y1 AS INTEGER
    x2 AS INTEGER
    y2 AS INTEGER
    w AS INTEGER
    h AS INTEGER
    colorFG AS _UNSIGNED LONG
    colorBG AS _UNSIGNED LONG
    payloadOffset AS LONG
    payloadLength AS LONG
    label AS STRING * 32
END TYPE

TYPE HISTORY_SYSTEM
    current AS INTEGER
    count AS INTEGER
    maxRecords AS INTEGER
    nextSequence AS LONG
    recording AS INTEGER
END TYPE

DIM SHARED HISTORY AS HISTORY_SYSTEM
DIM SHARED HISTORY_RECORDS(1 TO HISTORY_MAX_RECORDS) AS HISTORY_RECORD
DIM SHARED HISTORY_PAYLOADS(1 TO HISTORY_MAX_RECORDS) AS STRING
DIM SHARED HISTORY_IN_PROGRESS AS INTEGER
DIM SHARED HISTORY_GROUP_ACTIVE AS INTEGER
DIM SHARED HISTORY_GROUP_SEQUENCE AS LONG
DIM SHARED HISTORY_saved_this_frame AS INTEGER ' Prevent double-saves in same frame
DIM SHARED UNDO_SEQ AS LONG ' Monotonic sequence counter for history records

' ---- Selection snapshot (for HISTORY_KIND_SELECTION_CHANGE records) ----
TYPE HISTORY_SEL_SNAP
    sel_active      AS INTEGER
    sel_initialized AS INTEGER
    sel_user_created AS INTEGER
    sel_box_x       AS INTEGER
    sel_box_y       AS INTEGER
    sel_box_w       AS INTEGER
    sel_box_h       AS INTEGER
    sel_box_state   AS INTEGER
    sel_wand_has    AS INTEGER
    sel_wand_min_x  AS INTEGER
    sel_wand_min_y  AS INTEGER
    sel_wand_max_x  AS INTEGER
    sel_wand_max_y  AS INTEGER
    sel_variant     AS INTEGER
    sel_mode        AS INTEGER
    sel_cfg_init_x  AS INTEGER
    sel_cfg_init_y  AS INTEGER
    sel_cfg_init_w  AS INTEGER
    sel_cfg_init_h  AS INTEGER
    sel_mask        AS LONG
END TYPE

DIM SHARED HISTORY_SEL_DATA(1 TO HISTORY_MAX_RECORDS) AS HISTORY_SEL_SNAP

' ---- Merge-visible per-layer backup (for HISTORY_KIND_LAYER_MERGE_VISIBLE) ----
CONST HISTORY_MAX_MV_SLOTS = 64

TYPE HISTORY_MV_ENTRY
    slotIndex   AS INTEGER
    layerId     AS LONG
    zIndex      AS INTEGER
    opacity     AS INTEGER
    visible     AS INTEGER
    opacityLock AS INTEGER
    blendMode   AS INTEGER
    img         AS LONG
    name        AS STRING * 64
END TYPE

' HISTORY_MV_DATA(mvSlot, layerEntry) — first dim is the MV slot (1..HISTORY_MAX_MV_SLOTS),
' second dim is the per-source-layer backup (1..64).
' HISTORY_MV_SLOT(recordIdx) maps a history record index to its MV slot.
' HISTORY_MV_COUNT(mvSlot) tracks how many layers are stored in that slot.
DIM SHARED HISTORY_MV_COUNT(1 TO HISTORY_MAX_MV_SLOTS) AS INTEGER
DIM SHARED HISTORY_MV_DATA(1 TO HISTORY_MAX_MV_SLOTS, 1 TO 64) AS HISTORY_MV_ENTRY
DIM SHARED HISTORY_MV_SLOT(1 TO HISTORY_MAX_RECORDS) AS INTEGER

' ---- Staged selection pending commit ----
DIM SHARED HISTORY_SEL_PENDING AS HISTORY_SEL_SNAP
DIM SHARED HISTORY_HAS_PENDING_SEL AS INTEGER

DECLARE SUB HISTORY_init ()
DECLARE SUB HISTORY_clear ()
DECLARE FUNCTION HISTORY_can_undo% ()
DECLARE FUNCTION HISTORY_can_redo% ()
DECLARE FUNCTION HISTORY_get_last_timestamp# ()
DECLARE FUNCTION HISTORY_get_next_timestamp# ()
DECLARE SUB HISTORY_begin_group ()
DECLARE SUB HISTORY_end_group ()
DECLARE FUNCTION HISTORY_begin_record% (kind AS INTEGER, exportKind AS INTEGER, label AS STRING)
DECLARE SUB HISTORY_commit_record (recordIndex AS INTEGER)
DECLARE SUB HISTORY_cancel_record (recordIndex AS INTEGER)
DECLARE FUNCTION HISTORY_text_payload$ (lineCount AS INTEGER, fontMode AS INTEGER, fontPath AS STRING, fontSize AS INTEGER)
DECLARE FUNCTION HISTORY_polyline_payload$ (pointCount AS INTEGER, pointsX() AS INTEGER, pointsY() AS INTEGER)
DECLARE SUB HISTORY_set_payload (recordIndex AS INTEGER, payload AS STRING, payloadMeta AS LONG)
DECLARE SUB HISTORY_record_layer_add (layerId AS LONG, layerSlot AS INTEGER, zIndex AS INTEGER, label AS STRING)
DECLARE SUB HISTORY_record_layer_delete (layerId AS LONG, layerSlot AS INTEGER, zIndex AS INTEGER, label AS STRING)
DECLARE SUB HISTORY_record_layer_reorder (layerId AS LONG, layerSlot AS INTEGER, oldZIndex AS INTEGER, newZIndex AS INTEGER, label AS STRING)
DECLARE SUB HISTORY_record_layer_rename (layerId AS LONG, oldName AS STRING, newName AS STRING, label AS STRING)
DECLARE SUB HISTORY_record_line (layerId AS LONG, layerSlot AS INTEGER, x1 AS INTEGER, y1 AS INTEGER, x2 AS INTEGER, y2 AS INTEGER, drawColor AS _UNSIGNED LONG, flags AS LONG, beforeImg AS LONG, label AS STRING)
DECLARE SUB HISTORY_record_rect (layerId AS LONG, layerSlot AS INTEGER, x1 AS INTEGER, y1 AS INTEGER, x2 AS INTEGER, y2 AS INTEGER, drawColor AS _UNSIGNED LONG, flags AS LONG, beforeImg AS LONG, label AS STRING)
DECLARE SUB HISTORY_record_ellipse (layerId AS LONG, layerSlot AS INTEGER, x1 AS INTEGER, y1 AS INTEGER, x2 AS INTEGER, y2 AS INTEGER, drawColor AS _UNSIGNED LONG, flags AS LONG, beforeImg AS LONG, label AS STRING)
DECLARE SUB HISTORY_record_polyline (layerId AS LONG, layerSlot AS INTEGER, drawColor AS _UNSIGNED LONG, flags AS LONG, beforeImg AS LONG, pointCount AS INTEGER, pointsX() AS INTEGER, pointsY() AS INTEGER, label AS STRING)
DECLARE SUB HISTORY_record_fill (layerId AS LONG, layerSlot AS INTEGER, drawColor AS _UNSIGNED LONG, flags AS LONG, beforeImg AS LONG, seedX AS INTEGER, seedY AS INTEGER, label AS STRING)
DECLARE SUB HISTORY_record_brush (layerId AS LONG, layerSlot AS INTEGER, drawColor AS _UNSIGNED LONG, flags AS LONG, beforeImg AS LONG, label AS STRING)
DECLARE SUB HISTORY_record_transform (layerId AS LONG, layerSlot AS INTEGER, flags AS LONG, beforeImg AS LONG, label AS STRING)
DECLARE SUB HISTORY_record_layer_merge (topIndex AS INTEGER, bottomIndex AS INTEGER)
DECLARE SUB HISTORY_record_layer_merge_visible (sortedLayers() AS INTEGER, sortCount AS INTEGER, mergedResultSlot AS INTEGER)
DECLARE SUB HISTORY_selection_stage ()
DECLARE SUB HISTORY_selection_commit ()
DECLARE FUNCTION HISTORY_MV_alloc_slot% ()
DECLARE SUB HISTORY_MV_free_slot (mvSlot AS INTEGER)
DECLARE FUNCTION HISTORY_create_layer_at_slot% (slotIndex AS INTEGER, targetZ AS INTEGER)
DECLARE SUB HISTORY_refresh_layer_add_snapshot (layerId AS LONG)
DECLARE SUB HISTORY_save_binary (fh AS INTEGER, canvasW AS LONG, canvasH AS LONG)
DECLARE SUB HISTORY_load_binary (fh AS INTEGER, canvasW AS LONG, canvasH AS LONG, formatVersion AS INTEGER)
DECLARE SUB HISTORY_undo ()
DECLARE SUB HISTORY_redo ()
