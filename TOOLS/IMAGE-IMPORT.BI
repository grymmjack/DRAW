''
' DRAW - TOOLS/IMAGE-IMPORT.BI
' =============================================================================
' Image Import tool - allows loading oversized images with interactive
' placement, zoom, pan, and cropping before placing on canvas.
'
' Workflow:
' 1. User loads an image larger than canvas
' 2. Enters "placement mode" with image preview
' 3. User draws a marquee box defining where image will be placed
' 4. Mouse wheel zooms the image within the placement area
' 5. Dragging inside the box pans the image (changes crop region)
' 6. Handles on the box resize the destination area
' 7. Enter commits the image, Escape cancels
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

' Import states
CONST IMPORT_STATE_IDLE = 0           ' Not importing
CONST IMPORT_STATE_LOADED = 1         ' Image loaded, waiting for marquee
CONST IMPORT_STATE_PLACING = 2        ' Marquee drawn, adjusting placement
CONST IMPORT_STATE_PANNING = 3        ' Panning image within crop area

TYPE IMAGE_IMPORT_OBJ
    STATE       AS INTEGER  ' Current import state (IMPORT_STATE_*)
    
    ' Source image
    IMAGE       AS LONG     ' Loaded image handle
    IMAGE_W     AS INTEGER  ' Original image width
    IMAGE_H     AS INTEGER  ' Original image height
    FILENAME    AS STRING   ' Source filename
    
    ' Destination placement (where on canvas)
    DEST_X      AS INTEGER  ' Destination X on canvas
    DEST_Y      AS INTEGER  ' Destination Y on canvas
    DEST_W      AS INTEGER  ' Destination width on canvas
    DEST_H      AS INTEGER  ' Destination height on canvas
    
    ' Source crop region (what part of image to use)
    CROP_X      AS SINGLE   ' Crop region X (in image coords, can be fractional)
    CROP_Y      AS SINGLE   ' Crop region Y (in image coords, can be fractional)
    CROP_W      AS SINGLE   ' Crop region width
    CROP_H      AS SINGLE   ' Crop region height
    
    ' Zoom and pan
    ZOOM        AS SINGLE   ' Current zoom level (1.0 = fit, >1 = zoomed in)
    ZOOM_MIN    AS SINGLE   ' Minimum zoom (image fits in dest)
    ZOOM_MAX    AS SINGLE   ' Maximum zoom
    PAN_X       AS SINGLE   ' Pan offset X (in image coords)
    PAN_Y       AS SINGLE   ' Pan offset Y (in image coords)
    
    ' Interaction state
    DRAGGING    AS INTEGER  ' Whether dragging to create initial marquee
    DRAG_START_X AS INTEGER ' Drag start X
    DRAG_START_Y AS INTEGER ' Drag start Y
    DRAG_END_X  AS INTEGER  ' Current drag end X
    DRAG_END_Y  AS INTEGER  ' Current drag end Y
    
    PANNING     AS INTEGER  ' Whether panning image within crop
    PAN_START_X AS INTEGER  ' Pan drag start X (screen coords)
    PAN_START_Y AS INTEGER  ' Pan drag start Y (screen coords)
    PAN_ORIG_X  AS SINGLE   ' Original crop X when pan started
    PAN_ORIG_Y  AS SINGLE   ' Original crop Y when pan started
    
    RESIZING    AS INTEGER  ' Whether resizing dest box
    RESIZE_HANDLE AS INTEGER ' Which handle (1-8)
    RESIZE_START_X AS INTEGER
    RESIZE_START_Y AS INTEGER
    RESIZE_ORIG_X AS INTEGER
    RESIZE_ORIG_Y AS INTEGER
    RESIZE_ORIG_W AS INTEGER
    RESIZE_ORIG_H AS INTEGER
    
    CONSTRAIN   AS INTEGER  ' Whether SHIFT is held (constrain proportions)
    
    ' Aspect ratio lock
    LOCK_ASPECT AS INTEGER  ' Lock source aspect ratio
    ASPECT_RATIO AS SINGLE  ' Source aspect ratio (w/h)
    
    ' Previous tool (to restore on cancel/apply)
    PREV_TOOL   AS INTEGER
END TYPE

DIM SHARED IMG_IMPORT AS IMAGE_IMPORT_OBJ

' Function declarations
DECLARE SUB IMAGE_IMPORT_init ()
DECLARE SUB IMAGE_IMPORT_reset ()
DECLARE FUNCTION IMAGE_IMPORT_load_file% (filename AS STRING)
DECLARE SUB IMAGE_IMPORT_start_placement (x AS INTEGER, y AS INTEGER)
DECLARE SUB IMAGE_IMPORT_update_placement (x AS INTEGER, y AS INTEGER)
DECLARE SUB IMAGE_IMPORT_finish_placement ()
DECLARE SUB IMAGE_IMPORT_zoom (delta AS SINGLE)
DECLARE SUB IMAGE_IMPORT_start_pan (x AS INTEGER, y AS INTEGER)
DECLARE SUB IMAGE_IMPORT_update_pan (x AS INTEGER, y AS INTEGER)
DECLARE SUB IMAGE_IMPORT_finish_pan ()
DECLARE SUB IMAGE_IMPORT_start_resize (handle AS INTEGER, x AS INTEGER, y AS INTEGER)
DECLARE SUB IMAGE_IMPORT_update_resize (x AS INTEGER, y AS INTEGER)
DECLARE SUB IMAGE_IMPORT_finish_resize ()
DECLARE SUB IMAGE_IMPORT_apply ()
DECLARE SUB IMAGE_IMPORT_cancel ()
DECLARE SUB IMAGE_IMPORT_draw (dest AS LONG)
DECLARE SUB IMAGE_IMPORT_draw_box (dest AS LONG)
DECLARE FUNCTION IMAGE_IMPORT_is_point_inside% (x AS INTEGER, y AS INTEGER)
DECLARE FUNCTION IMAGE_IMPORT_get_handle_at% (x AS INTEGER, y AS INTEGER)
DECLARE SUB IMAGE_IMPORT_update_crop_from_zoom ()
DECLARE SUB IMAGE_IMPORT_clamp_pan ()
