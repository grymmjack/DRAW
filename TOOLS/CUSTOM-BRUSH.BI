''
' DRAW - TOOLS/CUSTOM-BRUSH.BI
' =============================================================================
' Custom brush tool - Deluxe Paint style custom brush capture and painting.
'
' Captures a rectangular area from the canvas and turns it into a reusable
' brush that can be:
' - Stamped down with a single click
' - Painted with by dragging
' - Used with any drawing tool (line, rect, ellipse, etc.)
' - Flipped horizontally or vertically
' - Made transparent based on background color matching
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

TYPE CUSTOM_BRUSH_OBJ
    ACTIVE                AS INTEGER        ' Whether a custom brush is loaded
    WIDTH                 AS INTEGER        ' Current brush width in pixels
    HEIGHT                AS INTEGER        ' Current brush height in pixels
    ORIG_WIDTH            AS INTEGER        ' Original brush width (for reset)
    ORIG_HEIGHT           AS INTEGER        ' Original brush height (for reset)
    IMAGE                 AS LONG           ' Image handle for the brush
    FLIP_H                AS INTEGER        ' Horizontal flip flag (-1 or 0)
    FLIP_V                AS INTEGER        ' Vertical flip flag (-1 or 0)
    HAS_TRANSPARENCY      AS INTEGER        ' Whether brush uses transparency
    BG_COLOR              AS _UNSIGNED LONG ' Background color used for transparency
    SCALE                 AS SINGLE         ' Current scale factor (1.0 = 100%)
    RECOLOR_MODE          AS INTEGER        ' Whether to recolor non-transparent pixels to FG color
    SHOW_OUTLINE          AS INTEGER        ' Whether to show outline in cursor preview
    PREVIEW_CACHE         AS LONG           ' Cached recolored/opacity-adjusted image for cursor preview
    PREVIEW_CACHE_COLOR   AS _UNSIGNED LONG ' Paint color when cache was built
    PREVIEW_CACHE_OPACITY AS INTEGER        ' Paint opacity when cache was built
    PREVIEW_CACHE_RECOLOR AS INTEGER        ' Recolor mode when cache was built
END TYPE

DIM SHARED CUSTOM_BRUSH AS CUSTOM_BRUSH_OBJ

' Stashed custom brush state — saved when switching to non-brush paint modes
TYPE CUSTOM_BRUSH_STASH_OBJ
    VALID            AS INTEGER ' Whether a stashed brush exists
    WIDTH            AS INTEGER
    HEIGHT           AS INTEGER
    ORIG_WIDTH       AS INTEGER
    ORIG_HEIGHT      AS INTEGER
    IMAGE            AS LONG
    FLIP_H           AS INTEGER
    FLIP_V           AS INTEGER
    HAS_TRANSPARENCY AS INTEGER
    BG_COLOR         AS _UNSIGNED LONG
    SCALE            AS SINGLE
    RECOLOR_MODE     AS INTEGER
    SHOW_OUTLINE     AS INTEGER
END TYPE

DIM SHARED CUSTOM_BRUSH_SAVED AS CUSTOM_BRUSH_STASH_OBJ

' Public interface
