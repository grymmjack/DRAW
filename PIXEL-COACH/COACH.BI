'$INCLUDEONCE
' PIXEL-COACH/COACH.BI — Core types, constants, and shared state
' Standalone pixel art analysis engine

OPTION _EXPLICIT
OPTION _EXPLICITARRAY
'$DYNAMIC

' ============================================================================
' Issue type constants
' ============================================================================
CONST COACH_JAGGY = 1
CONST COACH_ISLAND = 2
CONST COACH_BANDING = 3
CONST COACH_FAT_PIXEL = 4
CONST COACH_OVER_DITHER = 5
CONST COACH_CONTRAST = 6
CONST COACH_VALUE = 7
CONST COACH_PILLOW = 8
CONST COACH_LIGHT = 9
CONST COACH_NOISE = 10

CONST COACH_MAX_ISSUES = 512
CONST COACH_MAX_COMPONENTS = 4096

' Overlay colors per issue type (semi-transparent)
CONST COACH_COLOR_JAGGY~& = &HCCFF3333 ' red
CONST COACH_COLOR_ISLAND~& = &HCCFFFF00 ' yellow
CONST COACH_COLOR_BANDING~& = &HCC3399FF ' blue
CONST COACH_COLOR_FAT~& = &HCCFF33FF ' magenta
CONST COACH_COLOR_DITHER~& = &HCC00FFFF ' cyan
CONST COACH_COLOR_VALUE~& = &HCCFF9933 ' orange
CONST COACH_COLOR_NOISE~& = &HCCFFFF00 ' yellow (same as island)
CONST COACH_COLOR_PILLOW~& = &HCC9933FF ' purple
CONST COACH_COLOR_LIGHT~& = &HCCFF6699 ' pink

' ============================================================================
' Issue data type
' ============================================================================
TYPE COACH_ISSUE_T
    issueType AS INTEGER '  COACH_JAGGY .. COACH_NOISE
    confidence AS SINGLE '  0.0 .. 1.0
    x1 AS INTEGER '         Bounding box
    y1 AS INTEGER
    x2 AS INTEGER
    y2 AS INTEGER
    pixelCount AS INTEGER
    message AS STRING * 128
    hint AS STRING * 128
    suppressed AS INTEGER ' TRUE if user dismissed this issue
END TYPE

' ============================================================================
' Component (connected region) stats
' ============================================================================
TYPE COACH_COMPONENT_T
    area AS LONG
    bboxX1 AS INTEGER
    bboxY1 AS INTEGER
    bboxX2 AS INTEGER
    bboxY2 AS INTEGER
    color AS _UNSIGNED LONG
    avgLum AS SINGLE
    isBoundary AS INTEGER '  TRUE if this component touches image edge
    perimeterLen AS LONG '   Number of boundary pixels in this component
END TYPE

' ============================================================================
' Master analysis state
' ============================================================================
TYPE COACH_STATE_T
    imgW AS INTEGER
    imgH AS INTEGER
    srcImg AS LONG '          Source image handle
    overlayImg AS LONG '      Overlay highlight image handle
    issueCount AS INTEGER
    componentCount AS LONG
    analyzing AS INTEGER '    TRUE while analysis is running
    ' Detector enable flags
    detectJaggies AS INTEGER
    detectIslands AS INTEGER
    detectBanding AS INTEGER
    detectFatPixels AS INTEGER
    detectDithering AS INTEGER
    detectContrast AS INTEGER
    detectValue AS INTEGER
    detectPillow AS INTEGER
    detectNoise AS INTEGER
    ' Filter / UI state
    activeFilter AS INTEGER ' 0 = show all, else filter by type
    confidenceThreshold AS SINGLE
    selectedIssue AS INTEGER
    scrollOffset AS INTEGER
    showOverlay AS INTEGER
    showGrayscale AS INTEGER
END TYPE

DIM SHARED COACH AS COACH_STATE_T
DIM SHARED COACH_ISSUES(0 TO COACH_MAX_ISSUES - 1) AS COACH_ISSUE_T

' Per-type overlay visibility toggles (shared between analyzer UI and overlay builder)
DIM SHARED chkJaggies AS INTEGER
DIM SHARED chkIslands AS INTEGER
DIM SHARED chkBanding AS INTEGER
DIM SHARED chkFatPixels AS INTEGER
DIM SHARED chkDithering AS INTEGER
DIM SHARED chkContrast AS INTEGER
DIM SHARED chkValue AS INTEGER
DIM SHARED chkNoise AS INTEGER

' Precompute arrays — REDIM'd when image is loaded
REDIM SHARED COACH_LABELS(0) AS LONG '          Component label per pixel (w*h)
REDIM SHARED COACH_BOUNDARY(0) AS INTEGER '      1 = boundary pixel
REDIM SHARED COACH_LUMINANCE(0) AS SINGLE '      Per-pixel luminance 0..255
REDIM SHARED COACH_COMPONENTS(0) AS COACH_COMPONENT_T

' Pixel grid cache (flat array, index = y * w + x)
REDIM SHARED COACH_PIXELS(0) AS _UNSIGNED LONG

' ============================================================================
' Forward declarations
' ============================================================================
DECLARE SUB COACH_init ()
DECLARE SUB COACH_load_image (filepath$)
DECLARE SUB COACH_run_analysis ()
DECLARE SUB COACH_precompute ()
DECLARE SUB COACH_clear_issues ()
DECLARE SUB COACH_add_issue (issueType%, confidence!, x1%, y1%, x2%, y2%, pixCount%, msg$, hint$)
DECLARE SUB COACH_build_overlay ()
DECLARE FUNCTION COACH_pixel_luminance! (c~&)
DECLARE FUNCTION COACH_issue_type_name$ (t%)
DECLARE FUNCTION COACH_issue_color~& (t%)

' Detectors
DECLARE SUB COACH_detect_jaggies ()
DECLARE SUB COACH_detect_islands ()
DECLARE SUB COACH_detect_banding ()
DECLARE SUB COACH_detect_fat_pixels ()
DECLARE SUB COACH_detect_over_dithering ()
DECLARE SUB COACH_detect_contrast ()
DECLARE SUB COACH_detect_value ()
DECLARE SUB COACH_detect_noise ()

' Precompute
DECLARE SUB COACH_precompute_pixels ()
DECLARE SUB COACH_precompute_labels ()
DECLARE SUB COACH_precompute_boundary ()
DECLARE SUB COACH_precompute_luminance ()
DECLARE SUB COACH_precompute_components ()
