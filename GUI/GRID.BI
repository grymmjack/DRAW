''
' DRAW - GUI/GRID.BI
' =============================================================================
' UDT for grid assistant.
'
' @todo
' @author Rick Christy <grymmjack@gmail.com>
'

$IF GRID_BI = UNDEFINED THEN
    $LET GRID_BI = 1
$END IF

TYPE DRAW_GRID
    imgWidth   AS INTEGER   ' Width of the full grid image
    imgHeight  AS INTEGER   ' Height of the full grid image
    fgColor    AS LONG      ' Foreground color of the grid lines
    xPos       AS INTEGER   ' X position of the grid in the image
    yPos       AS INTEGER   ' Y position of the grid in the image
    gridWidth  AS INTEGER   ' Width of a grid square
    gridHeight AS INTEGER   ' Height of a grid square
    hStyle     AS INTEGER   ' Horizontal style &B0000111100001111 (16 bits)
    vStyle     AS INTEGER   ' Vertical style &B0000111100001111 (16 bits)
    imgHandle  AS LONG      ' Grid image handle
END TYPE
