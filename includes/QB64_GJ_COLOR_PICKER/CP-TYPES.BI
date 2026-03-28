'$INCLUDEONCE

' ============================================================================
' CP-TYPES.BI — Type definitions for QB64_GJ_COLOR_PICKER
'
' Standalone color picker dialog for QB64-PE (Photoshop/Krita style).
' HSV square + hue bar, RGB sliders, HSL sliders, hex input.
' No dependency on DRAW project types.
'
' (c) 2026 grymmjack — MIT License
' ============================================================================

' --- Result Codes ------------------------------------------------------------

CONST CP_RESULT_NONE = -1               ' Cancelled / closed
CONST CP_RESULT_OK = 0                  ' Color confirmed

' --- Drag Targets ------------------------------------------------------------

CONST CP_DRAG_NONE = 0
CONST CP_DRAG_SV_SQUARE = 1             ' Picking saturation + value in square
CONST CP_DRAG_HUE_BAR = 2               ' Picking hue from vertical bar
CONST CP_DRAG_SLIDER_R = 3              ' Red slider
CONST CP_DRAG_SLIDER_G = 4              ' Green slider
CONST CP_DRAG_SLIDER_B = 5              ' Blue slider
CONST CP_DRAG_SLIDER_H = 6              ' Hue slider
CONST CP_DRAG_SLIDER_S = 7              ' Saturation slider
CONST CP_DRAG_SLIDER_L = 8              ' Lightness slider
CONST CP_DRAG_TITLE_BAR = 9             ' Dragging dialog

' --- Layout Constants (used for pre-rendering) -------------------------------

CONST CP_SV_SIZE = 200                  ' SV square width & height
CONST CP_HUE_BAR_W = 20                 ' Hue bar width
CONST CP_HUE_GAP = 8                    ' Gap between SV square and hue bar

' --- Type Definitions --------------------------------------------------------

TYPE CP_STATE_OBJ
    ' Color values (canonical representation is HSV)
    hue AS SINGLE                       ' 0..360
    sat AS SINGLE                       ' 0..1
    val AS SINGLE                       ' 0..1 (brightness)

    ' RGB representation (derived from HSV)
    cR AS INTEGER                       ' 0..255
    cG AS INTEGER                       ' 0..255
    cB AS INTEGER                       ' 0..255

    ' HSL representation (derived from HSV)
    hslH AS SINGLE                      ' 0..360
    hslS AS SINGLE                      ' 0..100
    hslL AS SINGLE                      ' 0..100

    ' Original color (for old/new preview)
    origColor AS _UNSIGNED LONG         ' Original color passed in

    ' Hex input
    tiHexId AS INTEGER                  ' TI widget ID for hex input field

    ' Dialog geometry
    dialogX AS INTEGER
    dialogY AS INTEGER
    dialogW AS INTEGER
    dialogH AS INTEGER

    ' SV square layout (relative to dialog)
    svX AS INTEGER
    svY AS INTEGER
    svW AS INTEGER
    svH AS INTEGER

    ' Hue bar layout
    hueBarX AS INTEGER
    hueBarY AS INTEGER
    hueBarW AS INTEGER
    hueBarH AS INTEGER

    ' Slider area layout
    sliderX AS INTEGER
    sliderY AS INTEGER
    sliderW AS INTEGER
    sliderLabelW AS INTEGER             ' Width of "R:" / "H:" labels
    sliderValueW AS INTEGER             ' Width of value text area

    ' Preview area layout
    previewY AS INTEGER
    previewOldX AS INTEGER
    previewNewX AS INTEGER
    previewW AS INTEGER
    previewH AS INTEGER

    ' Hex input layout
    hexY AS INTEGER
    hexInputX AS INTEGER
    hexInputW AS INTEGER

    ' Button bar layout
    buttonBarY AS INTEGER

    ' Interaction
    dragging AS INTEGER                 ' CP_DRAG_* constant
    dragStartX AS INTEGER
    dragStartY AS INTEGER
    dragOrigX AS INTEGER
    dragOrigY AS INTEGER
    hoverButton AS INTEGER              ' -1=none, -2=close, 0=OK, 1=Cancel, 2=copy, 3=paste

    ' Mouse state (dialog-relative)
    mouseX AS INTEGER
    mouseY AS INTEGER
    mouseB1 AS INTEGER
    oldMouseB1 AS INTEGER
    mouseWheel AS INTEGER                ' Accumulated wheel delta this frame

    ' Posterize / snap mode (for pixel art)
    posterize AS INTEGER                 ' 0=off, 2-16 = number of levels
    posterizeY AS INTEGER                ' Y position of posterize row
    hoverPosterize AS INTEGER            ' -1=none, 0-7 = which option is hovered

    ' Pre-rendered images
    svImage AS LONG                     ' SV square image (re-rendered on hue change)
    hueBarImage AS LONG                 ' Hue bar image (rendered once)

    ' Result
    done AS INTEGER
    result AS INTEGER                   ' CP_RESULT_*

    ' Rendering
    imgHandle AS LONG                   ' Offscreen dialog buffer
    screenShot AS LONG                  ' Background screen capture
    dirty AS INTEGER
    svDirty AS INTEGER                  ' TRUE = SV square needs re-render
    scale AS INTEGER
END TYPE

' --- Options (set before calling CP_pick_color&) -----------------------------

TYPE CP_OPTIONS_OBJ
    posterize AS INTEGER                ' 0=off, 2/3/4/6/8/12/16 snap levels
END TYPE

' --- Shared State ------------------------------------------------------------

DIM SHARED CP_OPTIONS AS CP_OPTIONS_OBJ
DIM SHARED CP_STATE AS CP_STATE_OBJ
