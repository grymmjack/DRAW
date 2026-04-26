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
CONST IMPORT_STATE_IDLE    = 0 ' Not importing
CONST IMPORT_STATE_LOADED  = 1 ' Image loaded, waiting for marquee
CONST IMPORT_STATE_PLACING = 2 ' Marquee drawn, adjusting placement
CONST IMPORT_STATE_PANNING = 3 ' Panning image within crop area

TYPE IMAGE_IMPORT_OBJ
    STATE AS INTEGER          ' Current import state (IMPORT_STATE_*)
    
    ' Source image
    IMAGE    AS LONG          ' Loaded image handle
    IMAGE_W  AS INTEGER       ' Original image width
    IMAGE_H  AS INTEGER       ' Original image height
    FILENAME AS STRING        ' Source filename
    
    ' Destination placement (where on canvas)
    DEST_X AS INTEGER         ' Destination X on canvas
    DEST_Y AS INTEGER         ' Destination Y on canvas
    DEST_W AS INTEGER         ' Destination width on canvas
    DEST_H AS INTEGER         ' Destination height on canvas
    
    ' Source crop region (what part of image to use)
    CROP_X AS SINGLE          ' Crop region X (in image coords, can be fractional)
    CROP_Y AS SINGLE          ' Crop region Y (in image coords, can be fractional)
    CROP_W AS SINGLE          ' Crop region width
    CROP_H AS SINGLE          ' Crop region height
    
    ' Zoom and pan
    ZOOM     AS SINGLE        ' Current zoom level (1.0 = fit, >1 = zoomed in)
    ZOOM_MIN AS SINGLE        ' Minimum zoom (image fits in dest)
    ZOOM_MAX AS SINGLE        ' Maximum zoom
    PAN_X    AS SINGLE        ' Pan offset X (in image coords)
    PAN_Y    AS SINGLE        ' Pan offset Y (in image coords)
    
    ' Interaction state
    DRAGGING     AS INTEGER   ' Whether dragging to create initial marquee
    DRAG_START_X AS INTEGER   ' Drag start X
    DRAG_START_Y AS INTEGER   ' Drag start Y
    DRAG_END_X   AS INTEGER   ' Current drag end X
    DRAG_END_Y   AS INTEGER   ' Current drag end Y
    
    PANNING     AS INTEGER    ' Whether panning image within crop
    PAN_START_X AS INTEGER    ' Pan drag start X (screen coords)
    PAN_START_Y AS INTEGER    ' Pan drag start Y (screen coords)
    PAN_ORIG_X  AS SINGLE     ' Original crop X when pan started
    PAN_ORIG_Y  AS SINGLE     ' Original crop Y when pan started
    
    RESIZING       AS INTEGER ' Whether resizing dest box
    RESIZE_HANDLE  AS INTEGER ' Which handle (1-8) being resized
    HOVER_HANDLE   AS INTEGER ' Which handle (1-8) is hovered
    RESIZE_START_X AS INTEGER
    RESIZE_START_Y AS INTEGER
    RESIZE_ORIG_X  AS INTEGER
    RESIZE_ORIG_Y  AS INTEGER
    RESIZE_ORIG_W  AS INTEGER
    RESIZE_ORIG_H  AS INTEGER
    
    CONSTRAIN AS INTEGER      ' Whether SHIFT is held (constrain proportions)
    
    ' Aspect ratio lock
    LOCK_ASPECT  AS INTEGER   ' Lock source aspect ratio
    ASPECT_RATIO AS SINGLE    ' Source aspect ratio (w/h)
    
    ' Transform state (for lossless rotate/flip/scale from original)
    ROTATION     AS INTEGER   ' Rotation in degrees: 0, 90, 180, 270
    FLIP_H       AS INTEGER   ' Flip horizontal flag
    FLIP_V       AS INTEGER   ' Flip vertical flag
    SCALE_FACTOR AS SINGLE    ' Cumulative scale factor (1.0 = original)
    PREVIEW_IMG  AS LONG      ' Pre-transformed preview image (rotation/flip applied)
    
    ' Previous tool (to restore on cancel/apply)
    PREV_TOOL AS INTEGER
END TYPE

DIM SHARED IMG_IMPORT AS IMAGE_IMPORT_OBJ

' Function declarations
