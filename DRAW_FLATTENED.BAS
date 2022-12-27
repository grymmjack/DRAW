''
' DRAW - DRAW.BAS
' =============================================================================
' Main program. 
'
' @depends ./_ALL.BI
' @depends ./_ALL.BM
' @author Rick Christy <grymmjack@gmail.com>
'

$IF ALL_BI = UNDEFINED THEN 
        ''
        ' DRAW - _ALL.BI
        ' =============================================================================
        ' Includes ALL code in sequence for BI files in one spot.
        '
        ' @author Rick Christy <grymmjack@gmail.com>
        '
        
        ' COMMON ----------------------------------------------------------------------
                ''
                ' DRAW - COMMON.BI
                ' =============================================================================
                ' Common header include.
                '
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                '$DYNAMIC
                $CONSOLE
                OPTION _EXPLICIT
                OPTION _EXPLICITARRAY
                
                $IF COMMON_BI = UNDEFINED THEN
                    $LET COMMON_BI = 1
                $END IF
                
                $IF FALSE = UNDEFINED AND TRUE = UNDEFINED THEN
                    $LET TRUE = TRUE
                    CONST FALSE = 0 : CONST TRUE = NOT FALSE
                $END IF
                
                CONST KEY_CAPSLOCK& = 100301
                CONST KEY_RSHIFT&   = 100303 
                CONST KEY_LSHIFT&   = 100304
                
                DIM SHARED AS INTEGER WHEEL_COLOR, KEY_COLOR, PAINT_COLOR
                DIM SHARED AS INTEGER CONSTRAIN_X, CONSTRAIN_Y
                CONSTRAIN_X% = FALSE : CONSTRAIN_Y% = FALSE
                PAINT_COLOR% = 4 : WHEEL_COLOR% = FALSE : KEY_COLOR% = FALSE
        
        ' CONFIG ----------------------------------------------------------------------
                ''
                ' DRAW - CFG/CONFIG.BI
                ' =============================================================================
                ' UDT for configuration.
                '
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF CONFIG_BI = UNDEFINED THEN
                    $LET CONFIG_BI = 1
                $END IF
                
                TYPE DRAW_CONFIG
                    THEME              AS STRING
                    FULLSCREEN         AS INTEGER
                    NUDGE_N            AS INTEGER
                    NUM_CUSTOM_BRUSHES AS INTEGER
                    NUM_LAYERS         AS INTEGER
                    FPS_LIMIT          AS INTEGER
                END TYPE
                
                DIM SHARED CFG   AS DRAW_CONFIG
                
                CFG.FULLSCREEN%         = FALSE
                CFG.THEME$              = "DEFAULT"
                CFG.NUDGE_N%            = 10
                CFG.NUM_LAYERS%         = 1
                CFG.NUM_CUSTOM_BRUSHES% = 4
                CFG.FPS_LIMIT%          = 60
                ''
                ' DRAW - CFG/CONFIG-THEME.BI
                ' =============================================================================
                ' Theme configuration UDT for DRAW.
                '
                ' To create a custom theme, copy the ASSETS/THEMES/DEFAULT to a new directory,
                ' and change the images and THEME.BI file to your liking. 
                ' 
                ' To enable your custom theme, modify CONFIG.BI UDT value to use the name of
                ' your new directory relative to the ASSETS/THEMES which you created.
                '
                ' e.g. If your theme directory is ASSETS/THEMES/PROMASTER9000 set the CONFIG.BI
                ' THEME value to "PROMASTER9000"
                '
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF CONFIG_THEME_BI = UNDEFINED THEN
                    $LET CONFIG_THEME_BI = 1
                $END IF
                
                TYPE DRAW_THEME
                    STATUS_bg         AS INTEGER    ' Status bar background color (0-256)
                    STATUS_fg         AS INTEGER    ' Status bar foreground color (0-256)
                    CROSSHAIR_fg      AS INTEGER    ' Crosshair foreground color (0-256)
                    CROSSHAIR_pattern AS INTEGER    ' Crosshair line pattern (16 bit &B>inary)
                    TOOLBAR_x         AS STRING     ' Toolbar X position "L | R | n" (n=any #)
                    TOOLBAR_y         AS STRING     ' Toolbar Y position "T | B | n" (n=any #)
                END TYPE
                
                DIM SHARED THEME AS DRAW_THEME
                ''
                ' DRAW - CFG/KEYBOARD.BI
                ' =============================================================================
                ' UDT for keyboard bindings.
                '
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF CONFIG_KEYBOARD_BI = UNDEFINED THEN
                    $LET CONFIG_KEYBOARD_BI = 1
                $END IF
                
                TYPE DRAW_KEYBOARD_BINDINGS
                    ' TOOLS -------------------------------------------------------------------
                    BRUSH                 AS STRING
                    BRUSH_CAPTURE         AS STRING
                    DOT                   AS STRING
                    ELLIPSE               AS STRING
                    ELLIPSE_FILL_SOLID    AS STRING
                    ELLIPSE_FILL_PATTERN  AS STRING
                    FILL                  AS STRING
                    LINE                  AS STRING
                    POLYLINE              AS STRING
                    POLYLINE_FILL_SOLID   AS STRING
                    POLYLINE_FILL_PATTERN AS STRING
                    LINE_RAY              AS STRING
                    RECT                  AS STRING
                    RECT_FILLED_SOLID     AS STRING
                    RECT_FILLED_PATTERN   AS STRING
                    TEXT                  AS STRING
                    ' CLIPBOARD ---------------------------------------------------------------
                    COPY                  AS STRING
                    COPY_TO_NEW_LAYER     AS STRING
                    COPY_MERGED           AS STRING
                    CUT                   AS STRING
                    CUT_TO_NEW_LAYER      AS STRING
                    PASTE                 AS STRING
                    PASTE_IN_PLACE        AS STRING
                    ' MODIFIERS ---------------------------------------------------------------
                    PAN                   AS STRING
                    SELECT                AS STRING
                    SELECT_ADD            AS STRING
                    SELECT_SUB            AS STRING
                    TRANSFORM_FLIP_H      AS STRING
                    TRANSFORM_FLIP_V      AS STRING
                    TRANSFORM_ROTATE_L    AS STRING
                    TRANSFORM_ROTATE_R    AS STRING
                    TRANSFORM_RESIZE_U    AS STRING
                    TRANSFORM_RESIZE_D    AS STRING
                    MOVE                  AS STRING
                    MOVE_NUDGE_LEFT       AS STRING
                    MOVE_NUDGE_RIGHT      AS STRING
                    MOVE_NUDGE_UP         AS STRING
                    MOVE_NUDGE_DOWN       AS STRING
                    MOVE_NUDGE_LEFT_N     AS STRING
                    MOVE_NUDGE_RIGHT_N    AS STRING
                    MOVE_NUDGE_UP_N       AS STRING
                    MOVE_NUDGE_DOWN_N     AS STRING
                    ' BRUSH -------------------------------------------------------------------
                    BRUSH_RESET           AS STRING
                    BRUSH_SIZE_INC        AS STRING
                    BRUSH_SIZE_DEC        AS STRING
                    BRUSH_SIZE_1          AS STRING
                    BRUSH_SIZE_2          AS STRING
                    BRUSH_SIZE_3          AS STRING
                    BRUSH_SIZE_4          AS STRING
                    BRUSH_DITHER_1        AS STRING
                    BRUSH_DITHER_2        AS STRING
                    BRUSH_DITHER_3        AS STRING
                    BRUSH_DITHER_4        AS STRING
                    BRUSH_1_SET           AS STRING
                    BRUSH_2_SET           AS STRING
                    BRUSH_3_SET           AS STRING
                    BRUSH_4_SET           AS STRING
                    BRUSH_1_RECALL        AS STRING
                    BRUSH_2_RECALL        AS STRING
                    BRUSH_3_RECALL        AS STRING
                    BRUSH_4_RECALL        AS STRING
                    ' GUI TOGGLES -------------------------------------------------------------
                    GUI_TOOLBAR_TOGGLE    AS STRING
                    GUI_PALETTE_TOGGLE    AS STRING
                    GUI_LAYERS_TOGGLE     AS STRING
                    GUI_STATUS_TOGGLE     AS STRING
                    GUI_ALL_TOGGLE        AS STRING
                    ' MOUSE EMULATION ---------------------------------------------------------
                    MOUSE_L               AS STRING
                    MOUSE_R               AS STRING
                    MOUSE_U               AS STRING
                    MOUSE_D               AS STRING
                    MOUSE_L_N             AS STRING
                    MOUSE_R_N             AS STRING
                    MOUSE_U_N             AS STRING
                    MOUSE_D_N             AS STRING
                    MOUSE_CLICK_L         AS STRING
                    MOUSE_CLICK_M         AS STRING
                    MOUSE_CLICK_R         AS STRING
                    MOUSE_SCROLL_U        AS STRING
                    MOUSE_SCROLL_D        AS STRING
                    ' ASSISTANTS --------------------------------------------------------------
                    POINTER_TOGGLE        AS STRING
                    TRANSPARENCY_TOGGLE   AS STRING
                    CROSSHAIR_TOGGLE      AS STRING
                    GRID_TOGGLE           AS STRING
                    GRID_SNAP_TOGGLE      AS STRING
                    ZOOM                  AS STRING
                    ZOOM_IN               AS STRING
                    ZOOM_OUT              AS STRING
                    ZOOM_RESET            AS STRING
                    ' HISTORY -----------------------------------------------------------------
                    UNDO                  AS STRING
                    REDO                  AS STRING
                    ' GUI EDITORS -------------------------------------------------------------
                    EDITOR_GRID           AS STRING
                    EDITOR_PAL            AS STRING
                    EDITOR_COLOR          AS STRING
                    EDITOR_BRUSH          AS STRING
                    EDITOR_PATTERN        AS STRING
                    EDITOR_LINE           AS STRING
                    EDITOR_TEXT           AS STRING
                    ' PALETTE -----------------------------------------------------------------
                    PAL_SET_FG            AS STRING
                    PAL_SET_BG            AS STRING
                    PAL_SWITCH_FG_BG      AS STRING
                    PAL_NEXT              AS STRING
                    PAL_PREV              AS STRING
                    PAL_PICK_COLOR        AS STRING
                    PAL_FG_00             AS STRING
                    PAL_FG_01             AS STRING
                    PAL_FG_02             AS STRING
                    PAL_FG_03             AS STRING
                    PAL_FG_04             AS STRING
                    PAL_FG_05             AS STRING
                    PAL_FG_06             AS STRING
                    PAL_FG_07             AS STRING
                    PAL_FG_08             AS STRING
                    PAL_FG_09             AS STRING
                    PAL_FG_10             AS STRING
                    PAL_FG_11             AS STRING
                    PAL_FG_12             AS STRING
                    PAL_FG_13             AS STRING
                    PAL_FG_14             AS STRING
                    PAL_FG_15             AS STRING
                    PAL_BG_00             AS STRING
                    PAL_BG_01             AS STRING
                    PAL_BG_02             AS STRING
                    PAL_BG_03             AS STRING
                    PAL_BG_04             AS STRING
                    PAL_BG_05             AS STRING
                    PAL_BG_06             AS STRING
                    PAL_BG_07             AS STRING
                    PAL_BG_08             AS STRING
                    PAL_BG_09             AS STRING
                    PAL_BG_10             AS STRING
                    PAL_BG_11             AS STRING
                    PAL_BG_12             AS STRING
                    PAL_BG_13             AS STRING
                    PAL_BG_14             AS STRING
                    PAL_BG_15             AS STRING
                    ' LAYERS ------------------------------------------------------------------
                    LAYER_NEW             AS STRING
                    LAYER_SAVE            AS STRING
                    LAYER_DUPLICATE       AS STRING
                    LAYER_CLEAR           AS STRING
                    LAYER_SELECT          AS STRING
                    LAYER_FOCUS_INC       AS STRING
                    LAYER_FOCUS_DEC       AS STRING
                    LAYER_RENAME          AS STRING
                    LAYER_ZINDEX_INC      AS STRING
                    LAYER_ZINDEX_DEC      AS STRING
                    LAYER_ZINDEX_TOP      AS STRING
                    LAYER_ZINDEX_BOT      AS STRING
                END TYPE
                
                DIM SHARED KB AS DRAW_KEYBOARD_BINDINGS
                ''
                ' DRAW - CFG/MOUSE.BI
                ' =============================================================================
                ' UDT for mouse bindings.
                '
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF CONFIG_MOUSE_BI = UNDEFINED THEN
                    $LET CONFIG_MOUSE_BI = 1
                $END IF
                
                TYPE DRAW_MOUSE_BINDINGS
                    PAN            AS STRING
                    PAL_PICK_COLOR AS STRING
                    PAL_NEXT       AS STRING
                    PAL_PREV       AS STRING
                    PAL_SET_FG     AS STRING
                    PAL_SET_BG     AS STRING
                    ZOOM_IN        AS STRING
                    ZOOM_OUT       AS STRING
                    ZOOM_RESET     AS STRING
                    BRUSH_SIZE_INC AS STRING
                    BRUSH_SIZE_DEC AS STRING
                END TYPE
                
                DIM SHARED MB AS DRAW_MOUSE_BINDINGS
                ''
                ' DRAW - CFG/STICK.BI
                ' =============================================================================
                ' UDT for joystick bindings.
                '
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF CONFIG_STICK_BI = UNDEFINED THEN
                    $LET CONFIG_STICK_BI = 1
                $END IF
                
                TYPE DRAW_STICK_BINDINGS
                    ' MOUSE EMULATION ---------------------------------------------------------
                    MOUSE_L               AS STRING
                    MOUSE_R               AS STRING
                    MOUSE_U               AS STRING
                    MOUSE_D               AS STRING
                    MOUSE_L_N             AS STRING
                    MOUSE_R_N             AS STRING
                    MOUSE_U_N             AS STRING
                    MOUSE_D_N             AS STRING
                    MOUSE_CLICK_L         AS STRING
                    MOUSE_CLICK_M         AS STRING
                    MOUSE_CLICK_R         AS STRING
                    MOUSE_SCROLL_U        AS STRING
                    MOUSE_SCROLL_D        AS STRING
                END TYPE
                
                DIM SHARED SB AS DRAW_STICK_BINDINGS
                ''
                ' DRAW - CFG/BINDINGS-KEYBOARD.BM
                ' =============================================================================
                ' Configure custom keyboard bindings here.
                '
                ' @depends ./CONFIG-KEYBOARD.BI
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF BINDINGS_KEYBOARD_BM = UNDEFINED THEN
                    $LET BINDINGS_KEYBOARD_BM = 1
                $END IF
                $IF CONFIG_KEYBOARD_BI = UNDEFINED THEN
                $END IF
                
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
                ''
                ' DRAW - CFG/BINDINGS-MOUSE.BM
                ' =============================================================================
                ' Configure custom mouse bindings here.
                '
                ' @depends ./CONFIG-MOUSE.BI
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF BINDINGS_MOUSE_BM = UNDEFINED THEN
                    $LET BINDINGS_MOUSE_BM = 1
                $END IF
                $IF CONFIG_MOUSE_BI = UNDEFINED THEN 
                $END IF
                
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
                ''
                ' DRAW - CFG/BINDINGS-STICK.BM
                ' =============================================================================
                ' Configure custom joystick bindings here.
                '
                ' @depends ./CONFIG-STICK.BI
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF BINDINGS_STICK_BM = UNDEFINED THEN
                    $LET BINDINGS_STICK_BM = 1
                $END IF
                $IF CONFIG_STICK_BI = UNDEFINED THEN 
                $END IF
                
                ' &=STICK DPU|DPD|DPL|DPR|TSLY|TSLX|TSLC|TSRY|TSRX|TSRC|B1|B2|B3|B4|B5|B6|B7|B8
                ' DP=DPad TSL=Thumbstick L TSR=Thumbstick R UDRL=Directions C=Click B#=Button
                ' MOUSE EMULATION -------------------------------------------------------------
                SB.MOUSE_L$         = "&DPL"    'DPad left
                SB.MOUSE_R$         = "&DPR"    'DPad right
                SB.MOUSE_U$         = "&DPU"    'DPad up
                SB.MOUSE_D$         = "&DPD"    'DPad down
                SB.MOUSE_L_N$       = "&TSLX-"  'Left thumbstick X axis in negative direction
                SB.MOUSE_R_N$       = "&TSLX+"  'Left thumbstick X axis in positive direction
                SB.MOUSE_U_N$       = "&TSLY-"  'Left thumbstick Y axis in negative direction
                SB.MOUSE_D_N$       = "&TSLY+"  'Left thumbstick Y axis in positive direction
                SB.MOUSE_CLICK_L$   = "&B1"     'A button
                SB.MOUSE_CLICK_M$   = "&B2"     'B button
                SB.MOUSE_CLICK_R$   = "&B3"     'X button
                SB.MOUSE_SCROLL_U$  = "&B8"     'Left trigger button
                SB.MOUSE_SCROLL_D$  = "&B9"     'Right trigger button
                    
        
        ' GUI -------------------------------------------------------------------------
                ''
                ' DRAW - GUI/BRUSHES.BI
                ' =============================================================================
                ' Header file for brushes functions.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF BRUSHES_BI = UNDEFINED THEN
                    $LET BRUSHES_BI = 1
                $END IF
                
                TYPE DRAW_BRUSH
                    IMG AS LONG
                    W   AS INTEGER
                    H   AS INTEGER
                END TYPE
                
                TYPE DRAW_BRUSHES
                    IDX   AS INTEGER
                    BRUSH AS DRAW_BRUSH
                END TYPE
                
                DIM SHARED BRUSHES(1 TO CFG.NUM_CUSTOM_BRUSHES%) AS DRAW_BRUSHES
                
                BRUSHES_init
                ''
                ' DRAW - GUI/CROSSHAIR.BI
                ' =============================================================================
                ' UDT for crosshair assistant.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF CROSSHAIR_BI = UNDEFINED THEN
                    $LET CROSSHAIR_BI = 1
                $END IF
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
                
                DIM SHARED GRID AS DRAW_GRID
                
                GRID_init
                ''
                ' DRAW - GUI/HELP.BI
                ' =============================================================================
                ' Help system.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF HELP_BI = UNDEFINED THEN
                    $LET HELP_BI = 1
                $END IF
                ''
                ' DRAW - LAYERS.BI
                ' =============================================================================
                ' UDT for layers.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF LAYERS_BI = UNDEFINED THEN
                    $LET LAYERS_BI = 1
                $END IF
                
                
                TYPE DRAW_LAYER
                    zIndex       AS INTEGER
                    imgWidth     AS INTEGER
                    imgHeight    AS INTEGER
                    imgHandle    AS LONG
                    visible      AS INTEGER
                    isSelected   AS INTEGER
                    lastSelected AS INTEGER
                END TYPE
                
                DIM SHARED LAYERS(1 TO CFG.NUM_LAYERS%) AS DRAW_LAYER
                
                LAYERS_init
                ''
                ' DRAW - GUI/PALETTE.BI
                ' =============================================================================
                ' UDT for palette.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF PALETTE_BI = UNDEFINED THEN
                    $LET PALETTE_BI = 1
                $END IF
                ''
                ' DRAW - GUI/PICKER.BI
                ' =============================================================================
                ' UDT for picker.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF PICKER_BI = UNDEFINED THEN
                    $LET PICKER_BI = 1
                $END IF
                ''
                ' DRAW - GUI/POINTER.BI
                ' =============================================================================
                ' UDT for pointer.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF POINTER_BI = UNDEFINED THEN
                    $LET POINTER_BI = 1
                $END IF
                
                TYPE POINTER_OBJ
                    W  AS INTEGER
                    H  AS INTEGER
                    S  AS STRING
                    C  AS INTEGER
                    O  AS INTEGER 'outline
                    OC AS INTEGER
                    LC AS INTEGER
                    RC AS INTEGER
                    MC AS INTEGER
                END TYPE
                
                DIM SHARED POINTER  AS POINTER_OBJ
                
                POINTER_init
                ''
                ' DRAW - GUI/STATUS.BI
                ' =============================================================================
                ' UDT for status.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF STATUS_BI = UNDEFINED THEN
                    $LET STATUS_BI = 1
                $END IF
                ''
                ' DRAW - GUI/TOOLBAR.BI
                ' =============================================================================
                ' UDT for toolbar.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF TOOLBAR_BI = UNDEFINED THEN
                    $LET TOOLBAR_BI = 1
                $END IF
                ''
                ' DRAW - GUI/TRANSPARENCY.BI
                ' =============================================================================
                ' UDT for transparency.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF TRANSPARENCY_BI = UNDEFINED THEN
                    $LET TRANSPARENCY_BI = 1
                $END IF
        
        ' INPUT -----------------------------------------------------------------------
                ''
                ' DRAW - INPUT/KEYBOARD.BI
                ' =============================================================================
                ' UDT for keyboard input handling.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF KEYBOARD_BI = UNDEFINED THEN
                    $LET KEYBOARD_BI = 1
                $END IF
                ''
                ' DRAW - INPUT/MOUSE.BI
                ' =============================================================================
                ' UDT for mouse input handling.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF MOUSE_BI = UNDEFINED THEN
                    $LET MOUSE_BI = 1
                $END IF
                
                TYPE MOUSE_OBJ
                    X     AS INTEGER
                    Y     AS INTEGER
                    OLD_X AS INTEGER
                    OLD_Y AS INTEGER
                    CON_X AS INTEGER
                    CON_Y AS INTEGER
                    B1    AS INTEGER
                    B2    AS INTEGER
                    B3    AS INTEGER
                    OSW   AS INTEGER
                    SW    AS INTEGER
                    DRAG  AS STRING
                END TYPE
                
                DIM SHARED MOUSE AS MOUSE_OBJ
                
                MOUSE_init
                ''
                ' DRAW - INPUT/STICK.BI
                ' =============================================================================
                ' UDT for joystick input handling.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF STICK_BI = UNDEFINED THEN
                    $LET STICK_BI = 1
                $END IF
                ''
                ' DRAW - INPUT/FILE-BMP.BI
                ' =============================================================================
                ' UDT for BMP files.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF FILE_BMP_BI = UNDEFINED THEN
                    $LET FILE_BMP_BI = 1
                $END IF
                ''
                ' DRAW - INPUT/FILE-BLOAD.BI
                ' =============================================================================
                ' UDT for BLOADing files.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF FILE_BLOAD_BI = UNDEFINED THEN
                    $LET FILE_BLOAD_BI = 1
                $END IF
                ''
                ' DRAW - INPUT/FILE-PAL.BI
                ' =============================================================================
                ' UDT for PAL files.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF FILE_PAL_BI = UNDEFINED THEN
                    $LET FILE_PAL_BI = 1
                $END IF
                ''
                ' DRAW - INPUT/API-LOSPEC.BI
                ' =============================================================================
                ' UDT for LOSPEC API.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF API_LOSPEC_BI = UNDEFINED THEN
                    $LET API_LOSPEC_BI = 1
                $END IF
        
        ' OUTPUT ----------------------------------------------------------------------
                ''
                ' DRAW - OUTPUT/SCREEN.BI
                ' =============================================================================
                ' UDT for screen output.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF SCREEN_BI = UNDEFINED THEN
                    $LET SCREEN_BI = 1
                $END IF
                
                TYPE SCREEN_OBJ
                    w        AS LONG
                    h        AS LONG
                    bpp      AS INTEGER
                    CANVAS   AS LONG
                    PAINTING AS LONG
                    GUI      AS LONG
                END TYPE
                
                DIM SHARED SCRN AS SCREEN_OBJ
                
                SCREEN_init
                ''
                ' DRAW - OUTPUT/FILE-BAS.BI
                ' =============================================================================
                ' UDT for BAS files.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF FILE_BAS_BI = UNDEFINED THEN
                    $LET FILE_BAS_BI = 1
                $END IF
                ''
                ' DRAW - OUTPUT/FILE-BMP.BI
                ' =============================================================================
                ' UDT for BMP files.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF FILE_BMP_BI = UNDEFINED THEN
                    $LET FILE_BMP_BI = 1
                $END IF
                ''
                ' DRAW - OUTPUT/FILE-BSAVE.BI
                ' =============================================================================
                ' UDT for BSAVE files.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF FILE_BSAVE_BI = UNDEFINED THEN
                    $LET FILE_BSAVE_BI = 1
                $END IF
        
        ' TOOLS -----------------------------------------------------------------------
                ''
                ' DRAW - TOOLS/BRUSH.BI
                ' =============================================================================
                ' UDT for brush tool.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF BRUSH_BI = UNDEFINED THEN
                    $LET BRUSH_BI = 1
                $END IF
                ''
                ' DRAW - TOOLS/BRUSH-DITHERS.BI
                ' =============================================================================
                ' UDT for brush dither patterns.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF BRUSH_DITHERS_BI = UNDEFINED THEN
                    $LET BRUSH_DITHERS_BI = 1
                $END IF
                ''
                ' DRAW - TOOLS/BRUSH-FILL.BI
                ' =============================================================================
                ' UDT for brush fills.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF BRUSH_FILL_BI = UNDEFINED THEN
                    $LET BRUSH_FILL_BI = 1
                $END IF
                ''
                ' DRAW - TOOLS/BRUSH-FX-OUTLINE.BI
                ' =============================================================================
                ' UDT for brush effect outline.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF BRUSH_FX_OUTLINE_BI = UNDEFINED THEN
                    $LET BRUSH_FX_OUTLINE_BI = 1
                $END IF
                ''
                ' DRAW - TOOLS/BRUSH-SIZE.BI
                ' =============================================================================
                ' UDT for brush sizes.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF BRUSH_SIZE_BI = UNDEFINED THEN
                    $LET BRUSH_SIZE_BI = 1
                $END IF
                ''
                ' DRAW - TOOLS/BRUSH-TEXT.BI
                ' =============================================================================
                ' UDT for text brush.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF BRUSH_TEXT_BI = UNDEFINED THEN
                    $LET BRUSH_TEXT_BI = 1
                $END IF
                ''
                ' DRAW - TOOLS/COLOR-BG.BI
                ' =============================================================================
                ' UDT for background color tool.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF COLOR_BG_BI = UNDEFINED THEN
                    $LET COLOR_BG_BI = 1
                $END IF
                ''
                ' DRAW - TOOLS/COLOR-FG.BI
                ' =============================================================================
                ' UDT for foreground color tool.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF COLOR_FG_BI = UNDEFINED THEN
                    $LET COLOR_FG_BI = 1
                $END IF
                ''
                ' DRAW - TOOLS/COLOR-INVERT.BI
                ' =============================================================================
                ' UDT for invert color tool.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF COLOR_INVERT_BI = UNDEFINED THEN
                    $LET COLOR_INVERT_BI = 1
                $END IF
                ''
                ' DRAW - TOOLS/DOT.BI
                ' =============================================================================
                ' UDT for dot (PSET) tool.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF DOT_BI = UNDEFINED THEN
                    $LET DOT_BI = 1
                $END IF
                ''
                ' DRAW - TOOLS/ELLIPSE.BI
                ' =============================================================================
                ' UDT for ellipse (CIRCLE) tool.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF ELLIPSE_BI = UNDEFINED THEN
                    $LET ELLIPSE_BI = 1
                $END IF
                ''
                ' DRAW - TOOLS/FILL.BI
                ' =============================================================================
                ' UDT for fill (PAINT) tool.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF FILL_BI = UNDEFINED THEN
                    $LET FILL_BI = 1
                $END IF
                ''
                ' DRAW - TOOLS/LINE.BI
                ' =============================================================================
                ' UDT for line tool.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF LINE_BI = UNDEFINED THEN
                    $LET LINE_BI = 1
                $END IF
                ''
                ' DRAW - TOOLS/LOAD.BI
                ' =============================================================================
                ' UDT for load tool.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF LOAD_BI = UNDEFINED THEN
                    $LET LOAD_BI = 1
                $END IF
                ''
                ' DRAW - TOOLS/MOVE.BI
                ' =============================================================================
                ' UDT for move tool.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF MOVE_BI = UNDEFINED THEN
                    $LET MOVE_BI = 1
                $END IF
                ''
                ' DRAW - TOOLS/MOVE-NUDGE.BI
                ' =============================================================================
                ' UDT for move with nudge tool.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF MOVE_NUDGE_BI = UNDEFINED THEN
                    $LET MOVE_NUDGE_BI = 1
                $END IF
                ''
                ' DRAW - TOOLS/PAN.BI
                ' =============================================================================
                ' UDT for pan tool.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF PAN_BI = UNDEFINED THEN
                    $LET PAN_BI = 1
                $END IF
                ''
                ' DRAW - TOOLS/PICKER.BI
                ' =============================================================================
                ' UDT for color picker tool.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF PICKER_BI = UNDEFINED THEN
                    $LET PICKER_BI = 1
                $END IF
                ''
                ' DRAW - TOOLS/POLY-FILL.BI
                ' =============================================================================
                ' UDT for polygon fill tool.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF POLY_FILL_BI = UNDEFINED THEN
                    $LET POLY_FILL_BI = 1
                $END IF
                ''
                ' DRAW - TOOLS/POLY-LINE.BI
                ' =============================================================================
                ' UDT for polygon line tool.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF POLY_LINE_BI = UNDEFINED THEN
                    $LET POLY_LINE_BI = 1
                $END IF
                ''
                ' DRAW - TOOLS/RAY.BI
                ' =============================================================================
                ' UDT for ray tool.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF RAY_BI = UNDEFINED THEN
                    $LET RAY_BI = 1
                $END IF
                ''
                ' DRAW - TOOLS/SAVE.BI
                ' =============================================================================
                ' UDT for save tool.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF SAVE_BI = UNDEFINED THEN
                    $LET SAVE_BI = 1
                $END IF
                ''
                ' DRAW - TOOLS/SELECTION.BI
                ' =============================================================================
                ' UDT for selection tool.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF SELECTION_BI = UNDEFINED THEN
                    $LET SELECTION_BI = 1
                $END IF
                ''
                ' DRAW - TOOLS/ZOOM.BI
                ' =============================================================================
                ' UDT for zoom tool.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                $IF ZOOM_BI = UNDEFINED THEN
                    $LET ZOOM_BI = 1
                $END IF
$END IF



' Main Loop
DIM k AS LONG
DO:   
    k& = _KEYHIT
    LOOP_start

    MOUSE_input_handler
    KEYBOARD_input_handler
    STICK_input_handler

    _LIMIT CFG.FPS_LIMIT%

    SCREEN_render

    MOUSE_input_handler_loop
    KEYBOARD_input_handler_loop
    STICK_input_handler_loop

    LOOP_end
LOOP UNTIL k&=27
MAIN_shutdown



''
' Runs at the start of the loop before any other code
' 
SUB LOOP_start ()
END SUB


''
' Runs at the end of the loop just before next iteration
' 
SUB LOOP_end ()
    IF PAINT_COLOR% > 15 THEN PAINT_COLOR% = 15
    IF PAINT_COLOR% < 0  THEN PAINT_COLOR% = 0
END SUB


''
' Runs at shutdown of main prorgam
' 
SUB MAIN_shutdown ()
    _MOUSESHOW
    SYSTEM
END SUB



$IF ALL_BM = UNDEFINED THEN 
        ''
        ' DRAW - _ALL.BM
        ' =============================================================================
        ' Includes ALL code in sequence for BM files in one spot.
        '
        ' @author Rick Christy <grymmjack@gmail.com>
        '
        
        ' COMMON ----------------------------------------------------------------------
                ''
                ' DRAW - COMMON.BM
                ' =============================================================================
                ' Common subs and functions
                '
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                ''
                ' Returns an integer as a trimmed string
                ' @param INTEGER v% integer to return as string
                '  
                FUNCTION n$ (v%)
                    n$ = _TRIM$(STR$(v%))
                END FUNCTION
        
        ' GUI -------------------------------------------------------------------------
                ''
                ' DRAW - GUI/BRUSHES.BM
                ' =============================================================================
                ' Module file for brushes functions.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                ''
                ' Initialize the brushes
                ' 
                SUB BRUSHES_init ()
                    DIM AS INTEGER l, u, i
                    l% = LBOUND(BRUSHES) : u% = UBOUND(BRUSHES)
                    FOR i% = l% TO u%
                        BRUSHES(i%).IDX%       = i%
                        BRUSHES(i%).BRUSH.IMG& = 0
                        BRUSHES(i%).BRUSH.W%   = 0
                        BRUSHES(i%).BRUSH.H%   = 0
                    NEXT i%
                END SUB
                ''
                ' DRAW - GUI/CROSSHAIR.BM
                ' =============================================================================
                ' Crosshair assistant related subs and functions for DRAW.
                '
                ' The crosshair assistant serves three functions:
                ' 1. It allows precise and constrained drawing on the X or Y axis
                ' 2. It provides pointer position
                ' 3. It draws guide lines on the X and Y access to assist precise drawing
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                ''
                ' Renders the crosshair assistant
                ' @param INTEGER kolor% used for crosshair lines
                ' 
                SUB CROSSHAIR_render (kolor%)
                    DIM s AS STRING
                    DIM AS INTEGER px, py, pw, ph
                    s$ = " " + _TRIM$(STR$(MOUSE.X%)) + "," + _TRIM$(STR$(MOUSE.Y%)) + " "
                    IF CONSTRAIN_X% THEN
                        ' Draw Y bar - top to bottom
                        LINE (MOUSE.CON_X%, 1)-(MOUSE.CON_X%, SCRN.h&), kolor%, , &B0101010101010101
                        s$ = " " + _TRIM$(STR$(MOUSE.CON_X%)) + "," + _TRIM$(STR$(MOUSE.Y%)) + " "
                    ELSE
                        LINE (MOUSE.X%, 1)-(MOUSE.X%, SCRN.h&), kolor%, , &B0101010101010101
                        s$ = " " + _TRIM$(STR$(MOUSE.X%)) + "," + _TRIM$(STR$(MOUSE.Y%)) + " "
                    END IF
                    IF CONSTRAIN_Y% THEN
                        ' Draw X bar - left to right
                        LINE (1, MOUSE.CON_Y%)-(SCRN.w&, MOUSE.CON_Y%), kolor%, , &B0101010101010101
                        s$ = " " + _TRIM$(STR$(MOUSE.X%)) + "," + _TRIM$(STR$(MOUSE.CON_Y%)) + " "
                    ELSE
                        LINE (1, MOUSE.Y%)-(SCRN.w&, MOUSE.Y%), kolor%, , &B0101010101010101
                    END IF
                    pw% = _PRINTWIDTH(s$)
                    ph% = _FONTHEIGHT
                    IF MOUSE.X% > (SCRN.w& - pw%) THEN px% = SCRN.w& - pw% ELSE px% = MOUSE.X%
                    IF MOUSE.Y% > (SCRN.h& - ph%) THEN py% = SCRN.h& - ph% ELSE py% = MOUSE.Y%
                    _PRINTSTRING(px%, py%), s$
                END SUB
                ''
                ' DRAW - GUI/GRID.BM
                ' =============================================================================
                ' Grid assistant subs and functions.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                ''
                ' Initialize the grid assistant
                ' 
                SUB GRID_init ()
                    ' Setup the grid object
                    GRID.imgWidth%   = _WIDTH             ' Width of the screen
                    GRID.imgHeight%  = _HEIGHT            ' Height of the screen
                    GRID.fgColor&    = 8                  ' Bright black
                    GRID.xPos%       = 0                  ' Left-most pixel of screen
                    GRID.yPos%       = 0                  ' Top-most pixel of screen
                    GRID.gridWidth%  = 10                 ' Grid width of 10 divides evenly
                    GRID.gridHeight% = 10                 ' Grid height of 10 divides evenly
                    GRID.hStyle%     = &B1111111111111111 ' Solid
                    GRID.vStyle%     = &B1111111111111111 ' Solid
                    GRID.imgHandle&  = _NEWIMAGE(GRID.imgWidth%, GRID.imgHeight%, 13)
                END SUB
                
                
                ''
                ' Draw grid
                ' 
                SUB GRID_draw ()
                    DIM AS INTEGER x, y
                    DIM oldDest AS LONG
                    oldDest& = _DEST
                    _DEST GRID.imgHandle&
                    COLOR GRID.fgColor&
                    FOR x% = GRID.xPos% to GRID.imgWidth% STEP GRID.gridWidth%
                        LINE (x%, GRID.yPos%)-(x%, GRID.yPos% + GRID.gridHeight%), _
                            GRID.fgColor&, , GRID.hStyle%
                    NEXT x%
                    FOR y% = GRID.yPos% to GRID.imgHeight% STEP GRID.gridHeight%
                        LINE (GRID.xPos%, y%)-(GRID.xPos% + GRID.gridWidth, y%), _
                            GRID.fgColor&, , GRID.vStyle%
                    NEXT y%
                    _DEST oldDest&
                END SUB
                
                
                ''
                ' Put the grid onto the screen
                ' description
                ' 
                SUB GRID_put ()
                    _PUTIMAGE (GRID.xPos%, GRID.yPos%), GRID.imgHandle
                END SUB
                ''
                ' DRAW - GUI/HELP.BM
                ' =============================================================================
                ' Help system subs and functions.
                ' 
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                ''
                ' DRAW - GUI/LAYERS.BM
                ' =============================================================================
                ' Layers subs and functions.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                ''
                ' Initialize the layers
                ' 
                SUB LAYERS_init ()
                    DIM AS INTEGER l, u, i
                    l% = LBOUND(LAYERS) : u% = UBOUND(LAYERS)
                    FOR i% = l% TO u%
                        LAYERS(i%).zIndex%       = i%
                        LAYERS(i%).imgWidth%     = 0
                        LAYERS(i%).imgHeight%    = 0
                        LAYERS(i%).imgHandle&    = 0
                        LAYERS(i%).visible%      = TRUE
                        LAYERS(i%).isSelected%   = FALSE
                        LAYERS(i%).lastSelected% = FALSE
                    NEXT i%
                END SUB
                ''
                ' DRAW - GUI/PALETTE.BM
                ' =============================================================================
                ' Palette subs and functions.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                ''
                ' DRAW - GUI/PICKER.BM
                ' =============================================================================
                ' Picker subs and functions.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                ''
                ' DRAW - GUI/POINTER.BM
                ' =============================================================================
                ' Pointer subs and functions.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                ''
                ' Initializes the pointer
                ' 
                SUB POINTER_init ()
                    _MOUSEHIDE
                    POINTER.W%  = 4
                    POINTER.H%  = 4
                    POINTER.C%  = 15
                    POINTER.O%  = 7
                    POINTER.LC% = 12
                    POINTER.RC% = 9
                    POINTER.MC% = 11
                    POINTER.OC% = POINTER.C%
                    IF SCRN.w& > 640 THEN 
                        POINTER.W% = POINTER.W% * 2
                        POINTER.H% = POINTER.H% * 2
                    END IF
                END SUB
                
                
                ''
                ' Render the pointer
                ' 
                SUB POINTER_render ()
                    POINTER_build
                    POINTER_draw
                END SUB
                
                
                ''
                ' Builds the pointer
                ' 
                SUB POINTER_build ()
                    POINTER.S$ = "C"  + _TRIM$(STR$(POINTER.O%)) _
                              + "D"  + _TRIM$(STR$(POINTER.H%)) _ 
                              + "R"  + _TRIM$(STR$(POINTER.W%)) _ 
                              + "H"  + _TRIM$(STR$(POINTER.H%)) _ 
                              + "B" _
                              + "M+" + _TRIM$(STR$(POINTER.W%\2)) _
                              + ",+" + _TRIM$(STR$(POINTER.H%)) _
                              + "F"  + _TRIM$(STR$(POINTER.W%\2))
                    IF POINTER.C% <> 0 THEN 'fill POINTER 0 else color is black keep outline
                        POINTER.S$ = POINTER.S$ _
                                  + "B" _
                                  + "M-" + _TRIM$(STR$(POINTER.W%\2)) _
                                  + ",-" + _TRIM$(STR$(POINTER.H% - 1)) _
                                  + "P"  + _TRIM$(STR$(POINTER.C%)) _
                                  + ","  + _TRIM$(STR$(POINTER.O%))
                    END IF
                END SUB
                
                
                ''
                ' Draws the pointer
                ' 
                SUB POINTER_draw ()
                    DIM s AS STRING
                    IF MOUSE.B1% THEN 
                        POINTER.C% = POINTER.LC%
                    ELSEIF MOUSE.B2% THEN 
                        POINTER.C% = POINTER.RC%
                    ELSEIF MOUSE.B3% THEN 
                        POINTER.C% = POINTER.MC%
                    ELSE 
                        POINTER.C% = POINTER.OC%
                    END IF
                
                    s$ = "B" _
                       + "M" _
                       + _TRIM$(STR$(_MOUSEX)) _
                       + "," _
                       + _TRIM$(STR$(_MOUSEY)) _
                       + POINTER.S$
                    DRAW s$
                END SUB
                
                
                ''
                ' Updates the pointer
                ' 
                SUB POINTER_update ()
                    POINTER.C% = PAINT_COLOR%
                END SUB
                ''
                ' DRAW - GUI/STATUS.BM
                ' =============================================================================
                ' Status subs and functions.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                ''
                ' Renders the status
                ' 
                SUB STATUS_render ()
                    DIM s AS STRING
                    DIM AS INTEGER px, py, pw, ph
                    s$ = " COLOR "
                    pw% = _PRINTWIDTH(s$)
                    ph% = _FONTHEIGHT + 1
                    px% = 0 : py% = SCRN.h& - ph%+1
                    s$ = s$ + "  " + n$(MOUSE.X%) + "," + n$(MOUSE.Y%)
                    IF MOUSE.B1% THEN s$ = s$ + " B1"
                    IF MOUSE.B2% THEN s$ = s$ + " B2"
                    IF MOUSE.B3% THEN s$ = s$ + " B3"
                    IF _KEYDOWN(KEY_CAPSLOCK&) THEN s$ = s$ + " " + CHR$(30)
                    ' IF MOUSE.DRAG$ <> "" THEN s$ = s$ + " D" + MOUSE.DRAG$
                    ' s$ = s$ + " " + n$(MOUSE.CON_X%) + "," + n$(MOUSE.CON_Y%)
                    IF CONSTRAIN_X% THEN s$ = s$ + " CX"
                    IF CONSTRAIN_Y% THEN s$ = s$ + " CY"
                    _DEST SCRN.GUI&
                    _PALETTECOLOR 17, _RGB(0, 0, 0)
                    _CLEARCOLOR 0
                    LINE (0, SCRN.h& - ph%)-(SCRN.w&, SCRN.h&), 8, BF
                    COLOR 17, 8
                    _PRINTSTRING(px%, py%), s$
                    LINE (px% + pw%, py%)-(px% + pw% + 4, py% + 6), 17, B
                    LINE (px% + pw%+1, py%+1)-(px% + pw% + 3, py% + 5), PAINT_COLOR%, BF
                END SUB
                ''
                ' DRAW - GUI/TOOLBAR.BM
                ' =============================================================================
                ' Toolbar subs and functions.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                ''
                ' DRAW - GUI/TRANSPARENCY.BM
                ' =============================================================================
                ' Transparency subs and functions.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
        
        ' INPUT -----------------------------------------------------------------------
                ''
                ' DRAW - INPUT/KEYBOARD.BM
                ' =============================================================================
                ' Keyboard input handling subs and functions.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                ''
                ' Handles changing colors with keyboard
                ' @todo
                ' 
                SUB KEYBOARD_colors ()
                    DIM keypress AS STRING
                    keypress$ = INKEY$
                    SELECT CASE keypress$
                        CASE "0": PAINT_COLOR% = 0
                        CASE "1": PAINT_COLOR% = 1
                        CASE "2": PAINT_COLOR% = 2
                        CASE "3": PAINT_COLOR% = 3
                        CASE "4": PAINT_COLOR% = 4
                        CASE "5": PAINT_COLOR% = 5
                        CASE "6": PAINT_COLOR% = 6
                        CASE "7": PAINT_COLOR% = 7
                        CASE "8": PAINT_COLOR% = 8
                        CASE "9": PAINT_COLOR% = 9
                        CASE "!": PAINT_COLOR% = 9
                        CASE "@": PAINT_COLOR% = 10
                        CASE "#": PAINT_COLOR% = 11
                        CASE "$": PAINT_COLOR% = 12
                        CASE "%": PAINT_COLOR% = 13
                        CASE "^": PAINT_COLOR% = 14
                        CASE "&": PAINT_COLOR% = 15
                        EVERYCASE:
                            KEY_COLOR%   = TRUE 
                            WHEEL_COLOR% = FALSE
                    END SELECT
                END SUB
                
                
                ''
                ' Handle keyboard input
                ' 
                SUB KEYBOARD_input_handler ()
                    DIM k as LONG
                    k& = _KEYHIT
                    KEYBOARD_colors
                END SUB
                
                
                ''
                ' Finishing stuff in the keyboard input loop
                ' 
                SUB KEYBOARD_input_handler_loop ()
                END SUB
                ''
                ' DRAW - INPUT/MOUSE.BM
                ' =============================================================================
                ' Mouse input handling subs and functions.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                ''
                ' Initializes the mouse
                ' 
                SUB MOUSE_init ()
                    MOUSE.X%     = 1
                    MOUSE.Y%     = 1
                    MOUSE.OLD_X% = 1
                    MOUSE.OLD_Y% = 1
                    MOUSE.CON_X% = 0
                    MOUSE.CON_Y% = 0
                    MOUSE.OSW%   = 0
                    MOUSE.B1%    = FALSE
                    MOUSE.B2%    = FALSE
                    MOUSE.B3%    = FALSE
                    MOUSE.DRAG$  = ""
                END SUB
                
                
                ''
                ' Handles mouse input
                ' 
                SUB MOUSE_input_handler ()
                    WHILE _MOUSEINPUT:
                        MOUSE.X%  = _MOUSEX
                        MOUSE.Y%  = _MOUSEY
                        MOUSE.B1% = _MOUSEBUTTON(1)
                        MOUSE.B2% = _MOUSEBUTTON(2)
                        MOUSE.B3% = _MOUSEBUTTON(3)
                        IF MOUSE.B1% THEN
                            IF MOUSE.X% < MOUSE.OLD_X% THEN MOUSE.DRAG$ = "L"
                            IF MOUSE.X% > MOUSE.OLD_X% THEN MOUSE.DRAG$ = "R"
                            IF MOUSE.Y% < MOUSE.OLD_Y% THEN MOUSE.DRAG$ = "U"
                            IF MOUSE.Y% > MOUSE.OLD_Y% THEN MOUSE.DRAG$ = "D"
                            PAINT_on
                        ELSE
                            MOUSE.DRAG$ = ""
                            MOUSE.CON_X% = 0 : MOUSE.CON_Y% = 0
                            CONSTRAIN_X% = FALSE : CONSTRAIN_Y% = FALSE
                        END IF
                        IF MOUSE.B2% THEN PAINT_clear
                        IF MOUSE.SW% <> MOUSE.OSW% THEN
                            IF NOT KEY_COLOR% THEN
                                PAINT_COLOR% = PAINT_COLOR% + -MOUSE.SW%
                                WHEEL_COLOR% = TRUE
                                KEY_COLOR%   = FALSE
                                MOUSE.OSW% = MOUSE.SW%
                            END IF
                        END IF
                        MOUSE.SW% = _MOUSEWHEEL
                
                        ' DO: LOOP UNTIL _MOUSEINPUT = 0
                
                        IF _KEYDOWN(KEY_CAPSLOCK&) AND NOT CONSTRAIN_X% AND NOT CONSTRAIN_Y% THEN
                            IF MOUSE.DRAG$ = "L" OR MOUSE.DRAG$ = "R" THEN
                                MOUSE.CON_Y% = MOUSE.Y%
                                CONSTRAIN_X% = FALSE
                                CONSTRAIN_Y% = TRUE
                            ELSEIF MOUSE.DRAG$ = "U" OR MOUSE.DRAG$ = "D" THEN
                                MOUSE.CON_X% = MOUSE.X%
                                CONSTRAIN_X% = TRUE
                                CONSTRAIN_Y% = FALSE
                            END IF
                        END IF
                    WEND
                END SUB
                
                
                ''
                ' Finishing stuff in the mouse input loop
                ' 
                SUB MOUSE_input_handler_loop ()
                    MOUSE.OLD_X% = MOUSE.X% : MOUSE.OLD_Y% = MOUSE.Y%
                END SUB
                ''
                ' DRAW - INPUT/STICK.BM
                ' =============================================================================
                ' Joystick input handling subs and functions.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                ''
                ' Joystick input handler
                ' 
                SUB STICK_input_handler ()
                END SUB
                
                
                ''
                ' Finishing stuff in the joystick input loop
                ' 
                SUB STICK_input_handler_loop ()
                END SUB
                ''
                ' DRAW - INPUT/FILE-BMP.BM
                ' =============================================================================
                ' BMP files subs and functions.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                ''
                ' DRAW - INPUT/FILE-BLOAD.BM
                ' =============================================================================
                ' BLOADing files subs and functions.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                ''
                ' DRAW - INPUT/FILE-PAL.BM
                ' =============================================================================
                ' PAL files subs and functions.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                ''
                ' DRAW - INPUT/API-LOSPEC.BM
                ' =============================================================================
                ' LOSPEC API subs and functions.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
        
        ' OUTPUT ----------------------------------------------------------------------
                ''
                ' DRAW - OUTPUT/SCREEN.BM
                ' =============================================================================
                ' Screen output files subs and functions.
                '
                ' @todo
                ' @depends ./SCREEN.BI
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                ''
                ' Detects the resolution of the desktop and sets the width and height to It
                ' 
                SUB SCREEN_detect_desktop_resolution()
                    DO: _LIMIT CFG.FPS_LIMIT% : LOOP UNTIL _SCREENEXISTS
                    SCRN.w& = _DESKTOPWIDTH : SCRN.h& = _DESKTOPHEIGHT
                END SUB
                
                
                ''
                ' Initialize the screen and various images we will use
                ' 
                SUB SCREEN_init ()
                    SCRN.w&   = 0
                    SCRN.h&   = 0
                    SCRN.bpp% = 0
                    SCREEN_detect_desktop_resolution
                    'override for 320x200
                    SCRN.w& = 320
                    SCRN.h& = 200 
                    SCRN.CANVAS&   = _NEWIMAGE(SCRN.w&, SCRN.h&, 13)
                    SCRN.PAINTING& = _NEWIMAGE(SCRN.w&, SCRN.h&, 13)
                    SCRN.GUI&      = _NEWIMAGE(SCRN.w&, SCRN.h&, 13)
                    SCREEN SCRN.CANVAS&
                    IF CFG.FULLSCREEN% THEN _FULLSCREEN _SQUAREPIXELS
                END SUB
                
                
                ''
                ' Draws screen
                ' 
                SUB SCREEN_render ()
                    ' todo get status to hide when painting 
                    CLS
                    STATUS_render
                    _DEST SCRN.CANVAS& :_SOURCE SCRN.PAINTING& : _PUTIMAGE
                    IF _KEYDOWN(KEY_CAPSLOCK&) THEN CROSSHAIR_render 8
                    _DEST SCRN.CANVAS& :_SOURCE SCRN.GUI& : _PUTIMAGE
                    POINTER_update
                    POINTER_render
                    _DISPLAY
                END SUB
                ''
                ' DRAW - OUTPUT/FILE-BAS.BM
                ' =============================================================================
                ' BAS format files subs and functions.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                ''
                ' DRAW - OUTPUT/FILE-BMP.BM
                ' =============================================================================
                ' BMP format files subs and functions.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                ''
                ' DRAW - OUTPUT/FILE-BSAVE.BM
                ' =============================================================================
                ' BSAVE format files subs and functions.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
        
        ' TOOLS -----------------------------------------------------------------------
                ''
                ' DRAW - TOOLS/BRUSH.BM
                ' =============================================================================
                ' Brush tool subs and functions.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                
                ''
                ' Turns painting on
                ' @todo
                ' 
                SUB PAINT_on ()
                    _DEST SCRN.PAINTING&
                    IF CONSTRAIN_X% THEN
                        LINE (MOUSE.CON_X%, MOUSE.OLD_Y%)-(MOUSE.CON_X%, MOUSE.Y%), PAINT_COLOR%
                    ELSEIF CONSTRAIN_Y% THEN
                        LINE (MOUSE.OLD_X%, MOUSE.CON_Y%)-(MOUSE.X%, MOUSE.CON_Y%), PAINT_COLOR%
                    ELSE
                        LINE (MOUSE.OLD_X%, MOUSE.OLD_Y%)-(MOUSE.X%, MOUSE.Y%), PAINT_COLOR%
                    END IF
                    _DEST SCRN.CANVAS&
                END SUB
                
                
                ''
                ' Clears the canvas
                ' @todo
                ' 
                SUB PAINT_clear ()
                    _DEST SCRN.PAINTING&
                    CLS
                    _DEST SCRN.CANVAS&
                END SUB
                ''
                ' DRAW - TOOLS/BRUSH-DITHERS.BM
                ' =============================================================================
                ' Brush dither patterns subs and functions.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                ''
                ' DRAW - TOOLS/BRUSH-FILL.BM
                ' =============================================================================
                ' Brush fills subs and functions.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                ''
                ' DRAW - TOOLS/BRUSH-FX-OUTLINE.BM
                ' =============================================================================
                ' Brush outline effect subs and functions.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                ''
                ' DRAW - TOOLS/BRUSH-SIZE.BM
                ' =============================================================================
                ' Brush sizes subs and functions.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                ''
                ' DRAW - TOOLS/BRUSH-TEXT.BM
                ' =============================================================================
                ' Brush sizes subs and functions.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                ''
                ' DRAW - TOOLS/COLOR_BG.BM
                ' =============================================================================
                ' Background color tool subs and functions.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                ''
                ' DRAW - TOOLS/COLOR_FG.BM
                ' =============================================================================
                ' Foreground color tool subs and functions.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                ''
                ' DRAW - TOOLS/COLOR_INVERT.BM
                ' =============================================================================
                ' Invert color tool subs and functions.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                ''
                ' DRAW - TOOLS/DOT.BM
                ' =============================================================================
                ' Dot (PSET) tool subs and functions.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                ''
                ' DRAW - TOOLS/ELLIPSE.BM
                ' =============================================================================
                ' Ellipse (CIRCLE) tool subs and functions.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                ''
                ' DRAW - TOOLS/FILL.BM
                ' =============================================================================
                ' Fill (PAINT) tool subs and functions.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                ''
                ' DRAW - TOOLS/LINE.BM
                ' =============================================================================
                ' Line tool subs and functions.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                ''
                ' DRAW - TOOLS/LOAD.BM
                ' =============================================================================
                ' Load tool subs and functions.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                ''
                ' DRAW - TOOLS/MOVE.BM
                ' =============================================================================
                ' Move tool subs and functions.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                ''
                ' DRAW - TOOLS/MOVE-NUDGE.BM
                ' =============================================================================
                ' Move with nudge tool subs and functions.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                ''
                ' DRAW - TOOLS/PAN.BM
                ' =============================================================================
                ' Pan tool subs and functions.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                ''
                ' DRAW - TOOLS/PICKER.BM
                ' =============================================================================
                ' Color picker tool subs and functions.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                ''
                ' DRAW - TOOLS/POLY-FILL.BM
                ' =============================================================================
                ' Polygon fill tool subs and functions.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                ''
                ' DRAW - TOOLS/POLY-LINE.BM
                ' =============================================================================
                ' Polygon line tool subs and functions.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                ''
                ' DRAW - TOOLS/RAY.BM
                ' =============================================================================
                ' Ray tool subs and functions.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                ''
                ' DRAW - TOOLS/SAVE.BM
                ' =============================================================================
                ' Save tool subs and functions.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                ''
                ' DRAW - TOOLS/SELECTION.BM
                ' =============================================================================
                ' Selection tool subs and functions.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
                ''
                ' DRAW - TOOLS/ZOOM.BM
                ' =============================================================================
                ' Zoom tool subs and functions.
                '
                ' @todo
                ' @author Rick Christy <grymmjack@gmail.com>
                '
$END IF
