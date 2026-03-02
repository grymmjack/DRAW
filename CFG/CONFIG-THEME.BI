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
    CROSSHAIR_color_fg      AS _UNSIGNED LONG ' Crosshair line color (RGBA)
    CROSSHAIR_opacity       AS INTEGER ' Crosshair line opacity (0-255)
    CROSSHAIR_font_fg       AS _UNSIGNED LONG ' Crosshair coordinate text color (RGBA)
    CROSSHAIR_pattern       AS INTEGER ' Crosshair line pattern (16 bit &B>inary)
    GRID_color_fg           AS _UNSIGNED LONG ' Grid foreground color (RGBA)
    GRID_opacity            AS INTEGER ' Grid line opacity (0-255, default 38 ~15%)
    GRID_size_x             AS INTEGER ' Grid cell width in pixels (default 10)
    GRID_size_y             AS INTEGER ' Grid cell height in pixels (default 10)
    TRANSPARENCY_check_size_x AS INTEGER ' Checkerboard square width (default 8)
    TRANSPARENCY_check_size_y AS INTEGER ' Checkerboard square height (default 8)
    TOOLBAR_x              AS STRING  ' Toolbar X position "L | R | n" (n=any #)
    TOOLBAR_y              AS STRING  ' Toolbar Y position "T | B | n" (n=any #)
    TOOLBAR_bg             AS _UNSIGNED LONG ' Toolbar background color (RGB32)
    TOOLBAR_border_fg      AS _UNSIGNED LONG ' Toolbar border color (RGB32)
    TOOLBAR_btn_overlay    AS _UNSIGNED LONG ' Active button dark overlay (RGBA)
    TOOLBAR_btn_stroke     AS _UNSIGNED LONG ' Active button border stroke (RGBA)
    COLOR_CHIP_outline     AS _UNSIGNED LONG ' Color chip outline color (RGBA)
    COLOR_CHIP_outline_alt AS _UNSIGNED LONG ' Color chip outline when color matches outline (RGBA)
    PIXEL_GRID_color1      AS _UNSIGNED LONG ' Pixel grid checker color 1 (RGBA)
    PIXEL_GRID_color2      AS _UNSIGNED LONG ' Pixel grid checker color 2 (RGBA)
    PIXEL_GRID_color_fg    AS _UNSIGNED LONG ' Pixel grid line color (RGB, opacity separate)
    PIXEL_GRID_opacity     AS INTEGER ' Pixel grid line opacity (0-255, default 64)
    GRID_angle             AS SINGLE  ' Grid rotation angle in degrees (default 0)
    CROSSHAIR_angle        AS SINGLE  ' Crosshair rotation angle in degrees (default 0)
    SYMMETRY_guide_fg      AS _UNSIGNED LONG ' Symmetry guide line color (RGBA)
    SYMMETRY_center_fg     AS _UNSIGNED LONG ' Symmetry center crosshair color (RGBA)
    ' Menu bar theme colors
    MENU_BAR_bg            AS _UNSIGNED LONG ' Menu bar background color
    MENU_BAR_fg            AS _UNSIGNED LONG ' Menu bar foreground (text) color
    MENU_BAR_border        AS _UNSIGNED LONG ' Menu bar border color
    MENU_BAR_divider       AS _UNSIGNED LONG ' Menu bar divider color
    MENU_BAR_sel_bg        AS _UNSIGNED LONG ' Menu bar selected item bg
    MENU_BAR_sel_fg        AS _UNSIGNED LONG ' Menu bar selected item fg
    MENU_BAR_disabled_fg   AS _UNSIGNED LONG ' Menu bar disabled item text
    MENU_SUB_bg            AS _UNSIGNED LONG ' Submenu background color
    MENU_SUB_fg            AS _UNSIGNED LONG ' Submenu foreground (text) color
    MENU_SUB_border        AS _UNSIGNED LONG ' Submenu border color
    MENU_SUB_divider       AS _UNSIGNED LONG ' Submenu divider color
    MENU_SUB_sel_bg        AS _UNSIGNED LONG ' Submenu selected item bg
    MENU_SUB_disabled_fg   AS _UNSIGNED LONG ' Submenu disabled item text
    MENU_SUB_sel_fg        AS _UNSIGNED LONG ' Submenu selected item fg
    ' --- Layer panel ---
    LAYER_PANEL_header_height    AS INTEGER         ' Header bar height in pixels
    LAYER_PANEL_btn_bar_height   AS INTEGER         ' Button bar height in pixels
    LAYER_PANEL_bg               AS _UNSIGNED LONG  ' Panel background
    LAYER_PANEL_border           AS _UNSIGNED LONG  ' Right border
    LAYER_PANEL_header_bg        AS _UNSIGNED LONG  ' Header background
    LAYER_PANEL_header_fg        AS _UNSIGNED LONG  ' Header title text
    LAYER_PANEL_header_fg_dim    AS _UNSIGNED LONG  ' Header layer count (dimmed)
    LAYER_PANEL_row_bg           AS _UNSIGNED LONG  ' Row normal background
    LAYER_PANEL_row_hover_bg     AS _UNSIGNED LONG  ' Row hover background
    LAYER_PANEL_row_sel_bg       AS _UNSIGNED LONG  ' Row selected background
    LAYER_PANEL_row_fg           AS _UNSIGNED LONG  ' Layer name text
    LAYER_PANEL_row_fg_blend     AS _UNSIGNED LONG  ' Blend mode short text
    LAYER_PANEL_opacity_bar_bg   AS _UNSIGNED LONG  ' Opacity bar background
    LAYER_PANEL_opacity_bar_fg   AS _UNSIGNED LONG  ' Opacity bar fill
    LAYER_PANEL_scrollbar_track  AS _UNSIGNED LONG  ' Scrollbar track
    LAYER_PANEL_scrollbar_thumb  AS _UNSIGNED LONG  ' Scrollbar thumb
    LAYER_PANEL_sep              AS _UNSIGNED LONG  ' Separator line above button bar
    LAYER_PANEL_btn_bar_bg       AS _UNSIGNED LONG  ' Button bar background
    LAYER_PANEL_drop_line        AS _UNSIGNED LONG  ' Drop target indicator (primary)
    LAYER_PANEL_drop_line2       AS _UNSIGNED LONG  ' Drop target indicator (shadow/secondary)
    LAYER_PANEL_drag_fill        AS _UNSIGNED LONG  ' Drag preview row fill (RGBA)
    LAYER_PANEL_drag_border      AS _UNSIGNED LONG  ' Drag preview row border
    LAYER_PANEL_row_master_bg     AS _UNSIGNED LONG  ' Master (CURRENT) layer row background
    LAYER_PANEL_row_multi_sel_bg  AS _UNSIGNED LONG  ' Multi-selected (secondary) row background
    LAYER_PANEL_row_master_accent AS _UNSIGNED LONG  ' Left-edge accent bar color for master row
    ' --- Fonts ---
    GLOBAL_FONT_FILE       AS STRING          ' Primary UI font filename (e.g. Tiny5-Regular.ttf)
    ALT_FONT_FILE          AS STRING          ' Alternate font filename (e.g. PICO-8.ttf) — reserved
    ' --- Sounds ---
    SOUND_MENU_OPEN_FILE   AS STRING          ' Filename for menu-open sound
    SOUND_MENU_SELECT_FILE AS STRING          ' Filename for menu-item-selected sound
    SOUND_NEW_FILE_FILE    AS STRING          ' Filename for new file / startup sound
    SOUND_NEW_LAYER_FILE   AS STRING          ' Filename for new layer sound
    SOUND_LAYER_OP_FILE    AS STRING          ' Filename for layer delete/arrange/merge/duplicate
    SOUND_CLIPBOARD_FILE   AS STRING          ' Filename for copy/cut/paste sound
    SOUND_FILL_FILE        AS STRING          ' Filename for flood fill sound
    SOUND_SELECTION_FILE   AS STRING          ' Filename for selection operation sound
    SOUND_DRAW_FILE        AS STRING          ' Filename for draw click (brush/dot/spray)
    SOUND_TRANSFORM_FILE   AS STRING          ' Filename for transform (flip/scale/rotate/about)
    SOUND_TEXT_ENTER_FILE  AS STRING          ' Filename for text tool Enter (commit line)
    SOUND_MENU_HOVER_FILE  AS STRING          ' Filename for hovering a new menu item
    SOUND_TOOL_SELECT_FILE AS STRING          ' Filename for toolbox button click
    SOUND_TEXT_CHAR_FILE   AS STRING          ' Filename for text tool character typed
    SOUND_ERASER_FILE      AS STRING          ' Filename for eraser stroke initial click
    SOUND_DRAW_PITCH_MIN   AS SINGLE          ' Min playback speed for draw pitch randomisation
    SOUND_DRAW_PITCH_MAX   AS SINGLE          ' Max playback speed for draw pitch randomisation
    SOUND_ERASER_PITCH_MIN AS SINGLE          ' Min playback speed for eraser pitch randomisation
    SOUND_ERASER_PITCH_MAX    AS SINGLE          ' Max playback speed for eraser pitch randomisation
    SOUND_DRAW_REVERSE_FILE   AS STRING          ' Reversed draw WAV for direction-change sound
    SOUND_ERASER_REVERSE_FILE         AS STRING          ' Reversed eraser WAV for direction-change sound
    SOUND_DRAW_LENGTH_DYNAMICS_MIN     AS SINGLE          ' Volume at short drag (0.0-1.0)
    SOUND_DRAW_LENGTH_DYNAMICS_MAX     AS SINGLE          ' Volume at long drag (0.0-1.0)
    SOUND_SLIDER_FILE    AS STRING          ' Filename for opacity/value slider drag sound
    SOUND_DRAG_DROP_FILE AS STRING          ' Filename for layer drag-and-drop sound
    SOUND_POINT_FILE     AS STRING          ' Filename for click-to-place-point (line/shape/poly tools)
    SOUND_ORGANIZER_FILE AS STRING          ' Filename for organizer/drawer widget click or mousewheel
END TYPE

' Runtime theme loader — populates THEME from ASSETS/THEMES/{CFG.THEME$}/THEME.CFG
DECLARE SUB THEME_load ()
DECLARE FUNCTION THEME_parse_rgba~& (val$)
DECLARE FUNCTION THEME_font_path$ (filename AS STRING)

DIM SHARED THEME AS DRAW_THEME
