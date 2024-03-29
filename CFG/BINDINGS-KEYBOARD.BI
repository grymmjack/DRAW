''
' DRAW - CFG/BINDINGS-KEYBOARD.BM
' =============================================================================
' Configure custom keyboard bindings here.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

' +=SHIFT @=ALT ^=CTRL #=NUMPAD %=FKEY [stuff]=Special key
' TOOLS -----------------------------------------------------------------------
KB.BRUSH$                 = "b"
KB.BRUSH_CAPTURE$         = "+b"         'SHIFT-B
KB.DOT$                   = "d"
KB.ELLIPSE$               = "e"
KB.ELLIPSE_FILL_SOLID$    = "+e"         'SHIFT-e
KB.ELLIPSE_FILL_PATTERN$  = "^e"         'CTRL-e
KB.FILL$                  = "f"      
KB.LINE$                  = "l"      
KB.POLYLINE$              = "p"      
KB.POLYLINE_FILL_SOLID$   = "+p"         'SHIFT-p
KB.POLYLINE_FILL_PATTERN$ = "^p"         'CTRL-p
KB.LINE_RAY$              = "+l"         'SHIFT-l
KB.RECT$                  = "r"      
KB.RECT_FILLED_SOLID$     = "+r"         'SHIFT-r
KB.RECT_FILLED_PATTERN$   = "^r"         'CTRL-r
KB.TEXT$                  = "t"
' CLIPBOARD -------------------------------------------------------------------
KB.COPY$                  = "^c"         'CTRL-c
KB.COPY_TO_NEW_LAYER$     = "@+c"        'ALT-SHIFT-c
KB.COPY_MERGED$           = "^+c"        'CTRL-SHIFT-c
KB.CUT$                   = "^x"         'CTRL-x
KB.CUT_TO_NEW_LAYER$      = "^+x"        'CTRL-SHIFT-x
KB.PASTE$                 = "^v"         'CTRL-v
KB.PASTE_IN_PLACE$        = "^+v"        'CTRL-SHIFT-v
' MODIFIERS -------------------------------------------------------------------
KB.PAN$                   = "[SPACE]"    'SPACEBAR
KB.SELECT$                = "m"          
KB.SELECT_ADD$            = "+"          'SHIFT
KB.SELECT_SUB$            = "@"          'ALT
KB.TRANSFORM_FLIP_H$      = "@h"         'ALT-h
KB.TRANSFORM_FLIP_V$      = "@v"         'ALT-v
KB.TRANSFORM_ROTATE_L$    = "@]"         'ALT-[
KB.TRANSFORM_ROTATE_R$    = "@["         'ALT-]
KB.TRANSFORM_RESIZE_U$    = "@="         'ALT-= (PLUS)
KB.TRANSFORM_RESIZE_D$    = "@-"         'ALT-- (MINUS)
KB.MOVE$                  = "v"
KB.MOVE_NUDGE_LEFT$       = "^#6"        'CTRL-NUMPAD6
KB.MOVE_NUDGE_RIGHT$      = "^#4"        'CTRL-NUMPAD4
KB.MOVE_NUDGE_UP$         = "^#8"        'CTRL-NUMPAD8
KB.MOVE_NUDGE_DOWN$       = "^#2"        'CTRL-NUMPAD2
KB.MOVE_NUDGE_LEFT_N$     = "^+#6"       'CTRL-SHIFT-NUMPAD6
KB.MOVE_NUDGE_RIGHT_N$    = "^+#4"       'CTRL-SHIFT-NUMPAD4
KB.MOVE_NUDGE_UP_N$       = "^+#8"       'CTRL-SHIFT-NUMPAD8
KB.MOVE_NUDGE_DOWN_N$     = "^+#2"       'CTRL-SHIFT-NUMPAD2
' BRUSH -----------------------------------------------------------------------
KB.BRUSH_RESET$           = "."
KB.BRUSH_SIZE_INC$        = "]"
KB.BRUSH_SIZE_DEC$        = "["
KB.BRUSH_SIZE_1$          = "%1"         'F1
KB.BRUSH_SIZE_2$          = "%2"         'F2
KB.BRUSH_SIZE_3$          = "%3"         'F3
KB.BRUSH_SIZE_4$          = "%4"         'F4
KB.BRUSH_DITHER_1$        = "+%1"        'SHIFT+F1
KB.BRUSH_DITHER_2$        = "+%2"        'SHIFT+F2
KB.BRUSH_DITHER_3$        = "+%3"        'SHIFT+F3
KB.BRUSH_DITHER_4$        = "+%4"        'SHIFT+F4
KB.BRUSH_1_SET$           = "^@#1"       'CTRL-ALT-NUMPAD1
KB.BRUSH_2_SET$           = "^@#2"       'CTRL-ALT-NUMPAD2
KB.BRUSH_3_SET$           = "^@#3"       'CTRL-ALT-NUMPAD3
KB.BRUSH_4_SET$           = "^@#4"       'CTRL-ALT-NUMPAD4
KB.BRUSH_1_RECALL$        = "#1"         'NUMPAD1
KB.BRUSH_2_RECALL$        = "#2"         'NUMPAD2
KB.BRUSH_3_RECALL$        = "#3"         'NUMPAD3
KB.BRUSH_4_RECALL$        = "#4"         'NUMPAD4
' GUI TOGGLES -----------------------------------------------------------------
KB.GUI_TOOLBAR_TOGGLE$    = "[TAB]"      'TAB
KB.GUI_PALETTE_TOGGLE$    = "+[TAB]"     'SHIFT-TAB
KB.GUI_LAYERS_TOGGLE$     = "^[TAB]"     'CTRL-TAB
KB.GUI_STATUS_TOGGLE$     = "%10"        'F10
KB.GUI_ALL_TOGGLE$        = "%11"        'F11
' MOUSE EMULATION ---------------------------------------------------------
KB.MOUSE_L$               = "[LEFT]"     
KB.MOUSE_R$               = "[RIGHT]"
KB.MOUSE_U$               = "[UP]"
KB.MOUSE_D$               = "[DOWN]"
KB.MOUSE_L_N$             = "+[LEFT]"    'SHIFT-LEFT
KB.MOUSE_R_N$             = "+[RIGHT]"   'SHIFT-RIGHT
KB.MOUSE_U_N$             = "+[UP]"      'SHIFT-UP
KB.MOUSE_D_N$             = "+[DOWN]"    'SHIFT-DOWN
KB.MOUSE_CLICK_L$         = "+[SPACE]"   'SHIFT-SPACE
KB.MOUSE_CLICK_M$         = "[INS]"      
KB.MOUSE_CLICK_R$         = "^+[SPACE]"  'CTRL-SHIFT-SPACE
KB.MOUSE_SCROLL_U$        = "[PAGEUP]"
KB.MOUSE_SCROLL_D$        = "[PAGEDOWN]"
' ASSISTANTS ------------------------------------------------------------------
KB.POINTER_TOGGLE$        = "[SCROLL]"   'SCROLL-LOCK
KB.TRANSPARENCY_TOGGLE$   = "%5"         'F5
KB.CROSSHAIR_TOGGLE$      = "[CAPS]"     'CAPS-LOCK
KB.GRID_TOGGLE$           = "'"
KB.GRID_SNAP_TOGGLE$      = "^'"
KB.ZOOM$                  = "z"
KB.ZOOM_IN$               = "+"
KB.ZOOM_OUT$              = "-"
KB.ZOOM_RESET$            = "^@0"        'CTRL-ALT-0
' HISTORY ---------------------------------------------------------------------
KB.UNDO                   = "^z"         'CTRL-z
KB.REDO                   = "^y"         'CTRL-y
' GUI EDITORS -----------------------------------------------------------------
KB.EDITOR_GRID$           = "^@g"        'CTRL-ALT-g
KB.EDITOR_PAL$            = "^@p"        'CTRL-ALT-p
KB.EDITOR_COLOR$          = "^@c"        'CTRL-ALT-c
KB.EDITOR_BRUSH$          = "^@b"        'CTRL-ALT-b
KB.EDITOR_PATTERN$        = "^@n"        'CTRL-ALT-n
KB.EDITOR_LINE$           = "^@l"        'CTRL-ALT-l
KB.EDITOR_TEXT$           = "^@t"        'CTRL-ALT-t
' PALETTE ---------------------------------------------------------------------
KB.PAL_SET_FG$            = "^@f"        'CTRL-ALT-f
KB.PAL_SET_BG$            = "^@b"        'CTRL-ALT-b
KB.PAL_SWITCH_FG_BG$      = "x"
KB.PAL_NEXT$              = ";"
KB.PAL_PREV$              = "'"
KB.PAL_PICK_COLOR$        = "`"
KB.PAL_FG_00$             = "0"
KB.PAL_FG_01$             = "1"
KB.PAL_FG_02$             = "2"
KB.PAL_FG_03$             = "3"
KB.PAL_FG_04$             = "4"
KB.PAL_FG_05$             = "5"
KB.PAL_FG_06$             = "6"
KB.PAL_FG_07$             = "7"
KB.PAL_FG_08$             = "8"
KB.PAL_FG_09$             = "9"
KB.PAL_FG_10$             = "+2"         'SHIFT-2
KB.PAL_FG_11$             = "+3"         'SHIFT-3
KB.PAL_FG_12$             = "+4"         'SHIFT-4
KB.PAL_FG_13$             = "+5"         'SHIFT-5
KB.PAL_FG_14$             = "+6"         'SHIFT-6
KB.PAL_FG_15$             = "+7"         'SHIFT-7
KB.PAL_BG_00$             = "^0"         'CTRL-0
KB.PAL_BG_01$             = "^1"         'CTRL-1
KB.PAL_BG_02$             = "^2"         'CTRL-2
KB.PAL_BG_03$             = "^3"         'CTRL-3
KB.PAL_BG_04$             = "^4"         'CTRL-4
KB.PAL_BG_05$             = "^5"         'CTRL-5
KB.PAL_BG_06$             = "^6"         'CTRL-6
KB.PAL_BG_07$             = "^7"         'CTRL-7
KB.PAL_BG_08$             = "^8"         'CTRL-8
KB.PAL_BG_09$             = "^9"         'CTRL-9
KB.PAL_BG_10$             = "^+2"        'CTRL-SHIFT-2
KB.PAL_BG_11$             = "^+3"        'CTRL-SHIFT-3
KB.PAL_BG_12$             = "^+4"        'CTRL-SHIFT-4
KB.PAL_BG_13$             = "^+5"        'CTRL-SHIFT-5
KB.PAL_BG_14$             = "^+6"        'CTRL-SHIFT-6
KB.PAL_BG_15$             = "^+7"        'CTRL-SHIFT-7
' LAYERS ----------------------------------------------------------------------
KB.LAYER_NEW$             = "^+n"        'CTRL-SHIFT-n
KB.LAYER_SAVE$            = "^+s"        'CTRL-SHIFT-s
KB.LAYER_DUPLICATE$       = "^j"         'CTRL-j
KB.LAYER_CLEAR$           = "[DEL]"
KB.LAYER_SELECT$          = "^[SPACE]"
KB.LAYER_FOCUS_INC$       = "+]"         'SHIFT-]
KB.LAYER_FOCUS_DEC$       = "+["         'SHIFT-[
KB.LAYER_RENAME$          = "^+r"        'CTRL-SHIFT-r
KB.LAYER_ZINDEX_INC$      = "^]"         'CTRL-]
KB.LAYER_ZINDEX_DEC$      = "^["         'CTRL-[
KB.LAYER_ZINDEX_TOP$      = "^+]"        'CTRL-SHIFT-]
KB.LAYER_ZINDEX_BOT$      = "^+["        'CTRL-SHIFT-[
