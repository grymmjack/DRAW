''
' DRAW - GUI/TDF-BROWSER.BI
' =============================================================================
' TheDraw font browser — the picker for TDF faces.
'
' TDF faces get their own browser rather than entries in the font dropdown for
' one blunt reason: the shipped corpus holds 3757 faces and FONT_LIST_MAX is
' 512. A flat dropdown could neither hold them nor be navigated. The browser
' filters by name, groups by bundle, and previews the face live; picking one
' registers just that face in the font list (FONT_LIST_add_tdf_font%).
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE
OPTION _EXPLICIT
OPTION _EXPLICITARRAY
'$DYNAMIC

CONST TDFB_W = 700                                   ' dialog size (logical px)
CONST TDFB_H = 490

CONST TDFB_LIST_X    = 10                            ' face list pane
CONST TDFB_LIST_Y    = 56
CONST TDFB_LIST_W    = 200
CONST TDFB_ROW_H     = 13
CONST TDFB_ROWS      = 18                            ' visible rows

CONST TDFB_PREV_X    = 220                           ' preview pane
CONST TDFB_PREV_Y    = 56
CONST TDFB_PREV_W    = 466
CONST TDFB_PREV_H    = 250
' Widest surface the live preview will compose before trimming the sample.
' Bounded so a wide face cannot allocate tens of megabytes on every keystroke.
CONST TDFB_PREV_MAX_W = 2048

' Which text field has keyboard focus (Tab cycles)
CONST TDFB_FOCUS_SEARCH = 0
CONST TDFB_FOCUS_SAMPLE = 1
CONST TDFB_FOCUS_PRESET = 2
CONST TDFB_FOCUS_COUNT  = 3

' Preset list, in the otherwise-empty left column below the face list.
CONST TDFB_PRE_X    = 10
CONST TDFB_PRE_Y    = 320
CONST TDFB_PRE_ROWS = 6

' Bundle filter (matches TDF_TYPE_* plus these pseudo-filters)
CONST TDFB_FILTER_ALL     = -1
CONST TDFB_FILTER_FAV     = -2                       ' starred faces only

TYPE TDFB_OBJ
    searchTxt    AS STRING * 32
    searchLen    AS INTEGER
    sampleTxt    AS STRING * 32
    sampleLen    AS INTEGER
    focusField   AS INTEGER
    typeFilter   AS INTEGER                          ' TDFB_FILTER_ALL or TDF_TYPE_*
    selRow       AS INTEGER                          ' index into the filtered list
    scrollTop    AS INTEGER
    matchCount   AS INTEGER
    listDirty    AS INTEGER                          ' re-run the filter
    previewDirty AS INTEGER                          ' re-render the sample
    previewImg   AS LONG
    previewDiv   AS INTEGER                          ' 1 = shown 1:1, N = reduced 1/N
    chosenFace   AS INTEGER                          ' -1 until the user accepts
    presetTxt    AS STRING * 24                      ' name field for save
    presetLen    AS INTEGER
    presetSel    AS INTEGER                          ' highlighted preset row, -1 = none
    presetTop    AS INTEGER                          ' scroll offset in the preset list
END TYPE
DIM SHARED TDFB AS TDFB_OBJ

' Filtered face indices. Sized for the whole corpus so "no filter" is valid.
DIM SHARED TDFB_MATCH(0 TO TDF_FACE_MAX - 1) AS INTEGER
