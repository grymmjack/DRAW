''
' DRAW - TOOLS/EXTRACT-IMAGES.BI
' =============================================================================
' Extract Images — finds contiguous opaque pixel groups (8-connected components)
' and exports each as an individual PNG file.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE
OPTION _EXPLICIT
OPTION _EXPLICITARRAY
'$DYNAMIC

' Background mode constants for extracted images
CONST EXTRACT_BG_TRANSPARENT = 0
CONST EXTRACT_BG_FG_COLOR    = 1
CONST EXTRACT_BG_BG_COLOR    = 2

' Naming method constants
CONST EXTRACT_NAME_NUMBERS    = 0
CONST EXTRACT_NAME_LAYER_NAME = 1

' Configuration for extraction dialog result
TYPE EXTRACT_CONFIG_OBJ
    bgMode         AS INTEGER     ' EXTRACT_BG_* constant
    destDir        AS STRING      ' Output directory path
    baseFilename   AS STRING      ' Base filename prefix (e.g. "Image-")
    namingMethod   AS INTEGER     ' EXTRACT_NAME_* constant
    startNumber    AS INTEGER     ' Starting number for sequential naming (0-999)
    appendDims     AS INTEGER     ' TRUE = append WxH@XxY to filename
    mergeLayers    AS INTEGER     ' TRUE = merge all visible layers before extraction
    cancelled      AS INTEGER     ' TRUE = user cancelled dialog
END TYPE

' Per-component bounding box result
TYPE EXTRACT_COMPONENT_OBJ
    minX AS INTEGER
    minY AS INTEGER
    maxX AS INTEGER
    maxY AS INTEGER
END TYPE

' Maximum components (INTEGER label limit)
CONST EXTRACT_MAX_COMPONENTS = 32767

DIM SHARED EXTRACT_CONFIG AS EXTRACT_CONFIG_OBJ

' Component results - populated by EXTRACT_find_components
DIM SHARED EXTRACT_COMP_COUNT AS INTEGER
REDIM SHARED EXTRACT_COMPS(0) AS EXTRACT_COMPONENT_OBJ

' Label array - populated by EXTRACT_find_components, used by EXTRACT_save_component
REDIM SHARED EXTRACT_LABELS(0, 0) AS INTEGER

' Per-layer mode state
DIM SHARED EXTRACT_MERGED_MODE AS INTEGER    ' TRUE = merged flatten, FALSE = per-layer raw
DIM SHARED EXTRACT_FLOOD_FILL_MODE AS INTEGER ' TRUE = connected-component flood fill used
REDIM SHARED EXTRACT_LAYER_NAMES(0) AS STRING
REDIM SHARED EXTRACT_SRC_IMGS(0) AS LONG      ' Per-component source image handle
REDIM SHARED EXTRACT_BLEND_MODES(0) AS INTEGER ' Per-component blend mode

' Declarations
DECLARE SUB EXTRACT_IMAGES_dialog ()
DECLARE SUB EXTRACT_find_components (srcImg AS LONG, bgMode AS INTEGER)
DECLARE SUB EXTRACT_save_component (srcImg AS LONG, compIdx AS INTEGER, labelArr() AS INTEGER, outputPath AS STRING, bgMode AS INTEGER)
DECLARE SUB EXTRACT_progress_dialog (srcImg AS LONG, labelArr() AS INTEGER)
DECLARE SUB EXTRACT_open_folder (folderPath AS STRING)
