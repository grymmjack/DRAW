''
' DRAW - GUI/GRID.BI
' =============================================================================
' UDT for grid assistant.
'
' @todo
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

' Grid alignment modes (affects snap behavior, NOT grid line positions)
CONST GRID_ALIGN_CORNER = 0      ' Snap to grid line intersections (0, 8, 16...)
CONST GRID_ALIGN_CENTER = 1      ' Snap to cell centers (4, 12, 20... for 8px grid)

' Grid geometry modes
CONST GRID_MODE_SQUARE = 0       ' Standard rectangular grid
CONST GRID_MODE_DIAGONAL = 1     ' 45-degree diagonal diamond grid
CONST GRID_MODE_ISOMETRIC = 2    ' 2:1 pixel isometric grid (26.565° diagonals + vertical)
CONST GRID_MODE_HEX = 3          ' Hexagonal grid
CONST GRID_MODE_COUNT = 4        ' Total number of modes (for cycling)

TYPE DRAW_GRID
    imgWidth   AS INTEGER        ' Width of the full grid image
    imgHeight  AS INTEGER        ' Height of the full grid image
    fgColor    AS _UNSIGNED LONG ' Foreground color of the grid lines
    xPos       AS INTEGER        ' X position of the grid in the image
    yPos       AS INTEGER        ' Y position of the grid in the image
    gridWidth  AS INTEGER        ' Width of a grid square
    gridHeight AS INTEGER        ' Height of a grid square
    hStyle     AS INTEGER        ' Horizontal style &B0000111100001111 (16 bits)
    vStyle     AS INTEGER        ' Vertical style &B0000111100001111 (16 bits)
    imgHandle  AS LONG           ' Grid image handle
    SHOW       AS INTEGER        ' Whether grid is visible (TRUE/FALSE)
    SNAP       AS INTEGER        ' Whether snap-to-grid is enabled (TRUE/FALSE)
    ALIGN_MODE AS INTEGER        ' Alignment mode: GRID_ALIGN_CORNER or GRID_ALIGN_CENTER
    GRID_MODE  AS INTEGER        ' Geometry mode: GRID_MODE_SQUARE/DIAGONAL/ISOMETRIC/HEX
    CELL_FILL  AS INTEGER        ' Cell fill mode: fill tool fills grid cells instead of flood fill
END TYPE

' Pixel grid (checkerboard) for high zoom levels
TYPE DRAW_PIXEL_GRID
    imgHandle  AS LONG           ' Pixel grid image handle
    SHOW       AS INTEGER        ' Whether pixel grid is enabled (TRUE/FALSE)
    color1     AS _UNSIGNED LONG ' First checker color (with alpha)
    color2     AS _UNSIGNED LONG ' Second checker color (with alpha)
END TYPE

DIM SHARED GRID AS DRAW_GRID
DIM SHARED PIXEL_GRID AS DRAW_PIXEL_GRID

DECLARE FUNCTION GRID_snap% (value AS INTEGER)
DECLARE SUB GRID_snap_xy (snapX AS INTEGER, snapY AS INTEGER)
DECLARE SUB GRID_fill_tri (x1 AS SINGLE, y1 AS SINGLE, x2 AS SINGLE, y2 AS SINGLE, x3 AS SINGLE, y3 AS SINGLE, c AS _UNSIGNED LONG)
DECLARE SUB GRID_fill_poly (n AS INTEGER, vx() AS SINGLE, vy() AS SINGLE, c AS _UNSIGNED LONG)
DECLARE SUB GRID_fill_cell (px AS INTEGER, py AS INTEGER, fillColor AS _UNSIGNED LONG)
DECLARE SUB PIXEL_GRID_init ()
DECLARE SUB PIXEL_GRID_draw ()
