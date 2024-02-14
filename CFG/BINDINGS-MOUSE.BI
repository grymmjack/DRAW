''
' DRAW - CFG/BINDINGS-MOUSE.BM
' =============================================================================
' Configure custom mouse bindings here.
'
' @depends ./CONFIG-MOUSE.BI
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

' +=SHIFT @=ALT ^=CTRL #=NUMPAD %=FKEY [stuff]=Special key  *=MOUSE L|M|R|WU|WD
' MODIFIERS -------------------------------------------------------------------
MB.PAN$                   = "*M"    'Middle click and hold
' BRUSH -----------------------------------------------------------------------
MB.BRUSH_SIZE_INC$        = "^*WU"  'CTRL-Wheel up
MB.BRUSH_SIZE_DEC$        = "^*WD"  'CTRL-Wheel down
' ASSISTANTS ------------------------------------------------------------------
MB.ZOOM_IN$               = "*WU"   'Wheel up
MB.ZOOM_OUT$              = "*WD"   'Wheel down
MB.ZOOM_RESET$            = "+*M"   'SHIFT-Middle click
' PALETTE ---------------------------------------------------------------------
MB.PAL_SET_FG$            = "*L"    'Left click
MB.PAL_SET_BG$            = "*R"    'Right click
MB.PAL_NEXT$              = "+WU"   'SHIFT-Wheel up
MB.PAL_PREV$              = "+WD"   'SHIFT-Wheel down
MB.PAL_PICK_COLOR$        = "@*L"   'ALT-Left click
