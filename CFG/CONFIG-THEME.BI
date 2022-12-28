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

TYPE DRAW_THEME
    STATUS_bg         AS LONG    ' Status bar background color (0-256)
    STATUS_fg         AS LONG    ' Status bar foreground color (0-256)
    CROSSHAIR_fg      AS LONG    ' Crosshair foreground color (0-256)
    CROSSHAIR_pattern AS LONG    ' Crosshair line pattern (16 bit &B>inary)
    TOOLBAR_x         AS STRING  ' Toolbar X position "L | R | n" (n=any #)
    TOOLBAR_y         AS STRING  ' Toolbar Y position "T | B | n" (n=any #)
END TYPE

DIM SHARED THEME AS DRAW_THEME
