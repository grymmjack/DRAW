''
' DRAW - CORE/IMAGE.BI
' =============================================================================
' Image handle utilities for safe image management.
' Valid QB64-PE image handles are always < -1.
' A handle of -1 indicates a failed _NEWIMAGE or _LOADIMAGE.
' A handle of 0 is the default screen.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

' No declarations needed - functions defined in IMAGE.BM
