''
' DRAW - TOOLS/WORKSPACE-UNDO.BI
' =============================================================================
' Workspace undo system for layer operations (create, delete, rename, reorder, merge)
' Uses timestamps to integrate with pixel undo for intelligent Ctrl+Z handling
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

' Workspace undo action types
CONST WUNDO_TYPE_LAYER_ADD = 1      ' Layer created
CONST WUNDO_TYPE_LAYER_DELETE = 2   ' Layer deleted
CONST WUNDO_TYPE_LAYER_RENAME = 3   ' Layer renamed
CONST WUNDO_TYPE_LAYER_REORDER = 4  ' Layer moved in stack (up/down)
CONST WUNDO_TYPE_LAYER_MERGE = 5    ' Layers merged

TYPE WORKSPACE_UNDO_STATE
    action_type AS INTEGER           ' WUNDO_TYPE_* constant
    timestamp AS DOUBLE              ' TIMER value when state was saved
    layer_index AS INTEGER           ' Affected layer index
    img AS LONG                      ' Image handle (for delete/merge - copy of deleted content)
    img2 AS LONG                     ' Second image (for merge - stores bottom layer before merge)
    old_zIndex AS INTEGER            ' Previous zIndex (for reorder)
    new_zIndex AS INTEGER            ' New zIndex (for reorder)
    old_name AS STRING * 16          ' Previous name (for rename)
    new_name AS STRING * 16          ' New name (for rename)
    old_layer_count AS INTEGER       ' Layer count before operation
    merge_top_index AS INTEGER       ' For merge: top layer index
    merge_bottom_index AS INTEGER    ' For merge: bottom layer index
    old_opacity AS INTEGER           ' Layer opacity before operation
    old_visible AS INTEGER           ' Layer visibility before operation
    old_opacityLock AS INTEGER       ' Opacity lock state before operation
END TYPE

TYPE WORKSPACE_UNDO_SYSTEM
    current AS INTEGER               ' Current position in undo history
    count AS INTEGER                 ' Number of states stored
    max_states AS INTEGER            ' Maximum number of states (from CFG)
END TYPE

DIM SHARED WORKSPACE_UNDO AS WORKSPACE_UNDO_SYSTEM
REDIM SHARED WORKSPACE_UNDO_STATES(1 TO 50) AS WORKSPACE_UNDO_STATE

' Flag to track if workspace undo system is ready (prevents saves during init)
DIM SHARED WORKSPACE_UNDO_READY AS INTEGER

' Timestamp of last pixel undo save (for comparing with workspace undo)
DIM SHARED PIXEL_UNDO_LAST_TIMESTAMP AS DOUBLE

DECLARE SUB WORKSPACE_UNDO_init ()
DECLARE SUB WORKSPACE_UNDO_clear ()
DECLARE SUB WORKSPACE_UNDO_save_layer_add (layerIndex AS INTEGER)
DECLARE SUB WORKSPACE_UNDO_save_layer_delete (layerIndex AS INTEGER)
DECLARE SUB WORKSPACE_UNDO_save_layer_rename (layerIndex AS INTEGER, oldName AS STRING, newName AS STRING)
DECLARE SUB WORKSPACE_UNDO_save_layer_reorder (layerIndex AS INTEGER, oldZIndex AS INTEGER, newZIndex AS INTEGER)
DECLARE SUB WORKSPACE_UNDO_save_layer_merge (topIndex AS INTEGER, bottomIndex AS INTEGER)
DECLARE SUB WORKSPACE_UNDO_undo ()
DECLARE SUB WORKSPACE_UNDO_redo ()
DECLARE FUNCTION WORKSPACE_UNDO_can_undo% ()
DECLARE FUNCTION WORKSPACE_UNDO_can_redo% ()
DECLARE FUNCTION WORKSPACE_UNDO_get_last_timestamp# ()

' NOTE: WORKSPACE_UNDO_init must be called AFTER config is loaded
' It is called from DRAW.BAS main initialization sequence
