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
    STATUS_bg              AS INTEGER ' Status bar bg palette color index (0-255)
    STATUS_fg              AS INTEGER ' Status bar fg palette color index (0-255)
    STATUS_height          AS INTEGER ' Status bar height in pixels
    CROSSHAIR_fg           AS INTEGER ' Crosshair fg palette color index (0-255)
    CROSSHAIR_pattern      AS INTEGER ' Crosshair line pattern (16 bit &B>inary)
    GRID_fg                AS INTEGER ' Grid fg palette color index (0-255)
    TOOLBAR_x              AS STRING  ' Toolbar X position "L | R | n" (n=any #)
    TOOLBAR_y              AS STRING  ' Toolbar Y position "T | B | n" (n=any #)
    TOOLBAR_bg             AS INTEGER ' Toolbar background palette color (0-255)
    TOOLBAR_border_fg      AS INTEGER ' Toolbar border palette color (0-255)
    PIXEL_GRID_color1      AS _UNSIGNED LONG ' Pixel grid checker color 1 (RGBA)
    PIXEL_GRID_color2      AS _UNSIGNED LONG ' Pixel grid checker color 2 (RGBA)
    SYMMETRY_guide_fg      AS _UNSIGNED LONG ' Symmetry guide line color (RGBA)
    SYMMETRY_center_fg     AS _UNSIGNED LONG ' Symmetry center crosshair color (RGBA)
    ' Menu bar theme colors
    MENU_BAR_bg            AS _UNSIGNED LONG ' Menu bar background color
    MENU_BAR_fg            AS _UNSIGNED LONG ' Menu bar foreground (text) color
    MENU_BAR_border        AS _UNSIGNED LONG ' Menu bar border color
    MENU_BAR_divider       AS _UNSIGNED LONG ' Menu bar divider color
    MENU_BAR_sel_bg        AS _UNSIGNED LONG ' Menu bar selected item bg
    MENU_BAR_sel_fg        AS _UNSIGNED LONG ' Menu bar selected item fg
    MENU_SUB_bg            AS _UNSIGNED LONG ' Submenu background color
    MENU_SUB_fg            AS _UNSIGNED LONG ' Submenu foreground (text) color
    MENU_SUB_border        AS _UNSIGNED LONG ' Submenu border color
    MENU_SUB_divider       AS _UNSIGNED LONG ' Submenu divider color
    MENU_SUB_sel_bg        AS _UNSIGNED LONG ' Submenu selected item bg
    MENU_SUB_sel_fg        AS _UNSIGNED LONG ' Submenu selected item fg
END TYPE

DIM SHARED THEME AS DRAW_THEME
