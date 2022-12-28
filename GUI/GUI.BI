''
' DRAW - GUI/GUI.BI
' =============================================================================
' UDT for GUI controls
'
' @author Rick Christy <grymmjack@gmail.com>
'

TYPE GUI_CONTROL
    iHnd AS LONG
    iSrc AS STRING
    tip  AS STRING
    w    AS INTEGER
    h    AS INTEGER
    x    AS INTEGER
    y    AS INTEGER
    evt  AS STRING
END TYPE