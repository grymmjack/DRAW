''
' DRAW - TOOLS/SMART-SHAPES.BI
' =============================================================================
' Registration of the Smart Shapes flyout group + per-shape constants.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

DIM SHARED SMART_SHAPES_GROUP_IDX AS INTEGER
SMART_SHAPES_GROUP_IDX = -1

' TRUE once the user has actually picked a smart-shape from the flyout this
' session. Until then the parent toolbar button retains the default smartshape
' icon AND the default tooltip text (not a per-shape one). Reset on app start /
' file new / file open via DRW_load_binary.
DIM SHARED SMART_SHAPES_CHOSEN AS INTEGER
SMART_SHAPES_CHOSEN = 0
