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
$INCLUDEONCE

TYPE DRAW_THEME
    STATUS_bg         AS INTEGER ' Status bar bg palette color index (0-255)
    STATUS_fg         AS INTEGER ' Status bar fg palette color index (0-255)
    CROSSHAIR_fg      AS INTEGER ' Crosshair fg palette color index (0-255)
    CROSSHAIR_pattern AS INTEGER ' Crosshair line pattern (16 bit &B>inary)
    GRID_fg           AS INTEGER ' Grid fg palette color index (0-255)
    TOOLBAR_x         AS STRING  ' Toolbar X position "L | R | n" (n=any #)
    TOOLBAR_y         AS STRING  ' Toolbar Y position "T | B | n" (n=any #)
END TYPE

DIM SHARED THEME AS DRAW_THEME
