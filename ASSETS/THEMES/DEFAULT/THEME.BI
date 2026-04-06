''
' DRAW - THEME.BI
' =============================================================================
' Default theme for DRAW.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

THEME.STATUS_bg%                 = 8                       ' Dark gray
THEME.STATUS_fg%                 = 0                       ' Opaque black
THEME.STATUS_height%             = 11                      ' Status bar height in pixels
THEME.STATUS_bg_color~&          = _RGB32(68, 68, 68)     ' Status bar background
THEME.STATUS_fg_color~&          = _RGB32(200, 200, 200)  ' Status bar text
THEME.STATUS_swatch_fg_outline~& = _RGB32(255, 255, 255)  ' Foreground swatch outline
THEME.STATUS_swatch_bg_outline~& = _RGB32(80, 80, 80)     ' Background swatch outline
THEME.STATUS_swatch_transparent_bg~& = _RGB32(255, 255, 255) ' Transparent swatch fill
THEME.STATUS_swatch_transparent_diagonal~& = _RGB32(200, 0, 0) ' Transparent swatch slash
THEME.STATUS_swatch_transparent_border~& = _RGB32(128, 128, 128) ' Transparent swatch border
THEME.STATUS_swatch_active_outer~& = _RGB32(0, 0, 0)      ' Active transparent swatch outer border
THEME.STATUS_swatch_active_inner~& = _RGB32(255, 255, 255) ' Active transparent swatch inner border
THEME.CROSSHAIR_color_fg~&       = _RGB32(128, 128, 128)   ' Medium gray crosshair lines
THEME.CROSSHAIR_opacity%         = 128                     ' 50% opacity (alpha 0-255)
THEME.CROSSHAIR_font$            = ""                     ' Empty = use global font
THEME.CROSSHAIR_font_size%       = 8                       ' 0 = use global font size
THEME.CROSSHAIR_font_fg~&        = _RGB32(255, 255, 255)   ' White coordinate text
THEME.CROSSHAIR_font_stroke_fg~& = _RGB32(0, 0, 0)         ' Black coordinate outline
THEME.CROSSHAIR_font_stroke_width% = 2                     ' Coordinate outline width
THEME.CROSSHAIR_font_offset_x%     = 8                     ' Coordinate text X offset from cursor
THEME.CROSSHAIR_font_offset_y%     = 8                     ' Coordinate text Y offset from cursor
THEME.CROSSHAIR_pattern%         = &B1010101010101010      ' - - - - - - - -
THEME.CROSSHAIR_outline_fg~&     = _RGB32(0, 0, 0)         ' Black outline stroke
THEME.CROSSHAIR_outline_opacity% = 200                     ' Outline stroke opacity
THEME.CROSSHAIR_outline_width%   = 1                       ' Outline stroke width in pixels
THEME.PICKER_LOUPE_zoom_level%   = 8                       ' Loupe zoom factor
THEME.PICKER_LOUPE_rect_x_offset% = 24                     ' Loupe X offset from mouse
THEME.PICKER_LOUPE_rect_y_offset% = -24                    ' Loupe Y offset from mouse
THEME.PICKER_LOUPE_rect_width%   = 96                      ' Loupe rectangle width
THEME.PICKER_LOUPE_rect_height%  = 96                      ' Loupe rectangle height
THEME.PICKER_LOUPE_rgba_x%       = 108                     ' RGB label X offset inside loupe
THEME.PICKER_LOUPE_rgba_y%       = 6                       ' RGB label Y offset inside loupe
THEME.PICKER_LOUPE_font$         = ""                     ' Empty = use global font
THEME.PICKER_LOUPE_font_size%    = 16                      ' Loupe font size
THEME.PICKER_LOUPE_font_fg~&     = _RGB32(255, 255, 255)   ' Loupe label text
THEME.PICKER_LOUPE_font_bg~&     = _RGB32(0, 0, 0)         ' Loupe panel / label background
THEME.PICKER_LOUPE_font_stroke_fg~& = _RGB32(0, 0, 0)      ' Loupe label outline color
THEME.PICKER_LOUPE_font_stroke_width% = 1                  ' Loupe label outline width
THEME.PICKER_LOUPE_rect_stroke_fg~& = _RGB32(255, 255, 255) ' Loupe border color
THEME.PICKER_LOUPE_rect_stroke_width% = 2                  ' Loupe border width
THEME.PICKER_LOUPE_pixel_pickup_color~& = _RGB32(0, 255, 0) ' Loupe sample marker color
THEME.GRID_color_fg~&            = _RGB32(250, 250, 250)   ' Bright white at full opacity
THEME.GRID_opacity%              = 38                      ' ~15% opacity (alpha 0-255)
THEME.GRID_size_x%               = 10                      ' Grid cell width in pixels
THEME.GRID_size_y%               = 10                      ' Grid cell height in pixels
THEME.TRANSPARENCY_check_size_x% = 8                    ' Checkerboard square width
THEME.TRANSPARENCY_check_size_y% = 8                    ' Checkerboard square height
THEME.TOOLBAR_x$                 = "R"                     ' Screen right side (any res)
THEME.TOOLBAR_y$                 = "T"                     ' Screen top side (any res)
THEME.TOOLBAR_bg~&               = _RGBA32(0, 0, 0, 255)   ' Black background
THEME.TOOLBAR_border_fg~&        = _RGBA32(0, 0, 0, 255)   ' Black border
THEME.TOOLBAR_btn_overlay~&      = _RGBA32(0, 0, 0, 128)   ' Active button overlay: 50% black
THEME.TOOLBAR_btn_stroke~&       = _RGBA32(255, 255, 255, 255) ' Active button border: 75% white
THEME.DRAWER_PANEL_PAD_X%        = 1                        ' Drawer inner horizontal padding
THEME.DRAWER_PANEL_PAD_Y%        = 1                        ' Drawer inner vertical padding
THEME.DRAWER_PANEL_GAP_Y%        = 1                        ' Drawer shared vertical gap
THEME.DRAWER_BIN_WIDTH%          = 7                        ' Bin width in unscaled pixels
THEME.DRAWER_BIN_HEIGHT%         = 7                        ' Bin height in unscaled pixels
THEME.DRAWER_BIN_GAP_X%          = 1                        ' Horizontal gap between bins
THEME.DRAWER_BIN_GAP_Y%          = 1                        ' Vertical gap between bins
THEME.DRAWER_BIN_PREVIEW_PAD%    = 1                        ' Bin preview inset
THEME.DRAWER_SCROLLBAR_WIDTH%    = 3                        ' Drawer scrollbar width
THEME.DRAWER_SCROLLBAR_MIN_THUMB_H% = 6                     ' Drawer scrollbar minimum thumb height
THEME.DRAWER_MINI_PALETTE_COLS%  = 2                        ' Mini palette columns
THEME.DRAWER_MINI_PALETTE_ROWS%  = 8                        ' Mini palette rows
THEME.DRAWER_MINI_PALETTE_CELL_W% = 3                       ' Mini palette cell width
THEME.DRAWER_MINI_PALETTE_CELL_H% = 3                       ' Mini palette cell height
THEME.DRAWER_MINI_PALETTE_GAP_X% = 1                        ' Mini palette horizontal gap
THEME.DRAWER_MINI_PALETTE_GAP_Y% = 1                        ' Mini palette vertical gap
THEME.DRAWER_MINI_PALETTE_PAGE_BTN_W% = 3                   ' Mini palette page button width
THEME.DRAWER_MINI_PALETTE_PAGE_BTN_H% = 3                   ' Mini palette page button height
THEME.DRAWER_PANEL_BG~&          = _RGBA32(17, 17, 17, 255)   ' Drawer panel background
THEME.DRAWER_PANEL_BORDER~&      = _RGBA32(37, 37, 37, 255)   ' Drawer panel border
THEME.DRAWER_PANEL_ACCENT~&      = _RGBA32(85, 85, 85, 255) ' Drawer accent line
THEME.DRAWER_BIN_BG~&            = _RGBA32(48, 48, 48, 255) ' Filled bin background
THEME.DRAWER_BIN_BORDER~&        = _RGBA32(85, 85, 85, 255) ' Filled bin border
THEME.DRAWER_BIN_HOVER_BG~&      = _RGBA32(56, 56, 56, 255) ' Hovered bin background
THEME.DRAWER_BIN_HOVER_BORDER~&  = _RGBA32(173, 173, 173, 255) ' Hovered bin border
THEME.DRAWER_BIN_SELECTED_BG~&   = _RGBA32(48, 48, 48, 255)  ' Selected bin background
THEME.DRAWER_BIN_SELECTED_BORDER~& = _RGBA32(255, 255, 255, 255) ' Selected bin border
THEME.DRAWER_BIN_SELECTED_BORDER_BRUSH~& = _RGBA32(0, 200, 255, 255) ' Selected brush bin border
THEME.DRAWER_BIN_SELECTED_BORDER_PATTERN~& = _RGBA32(255, 200, 0, 255) ' Selected pattern bin border
THEME.DRAWER_BIN_SELECTED_BORDER_GRADIENT~& = _RGBA32(255, 100, 255, 255) ' Selected gradient bin border
THEME.DRAWER_BIN_EMPTY_BG~&      = _RGBA32(17, 17, 17, 255) ' Empty bin background
THEME.DRAWER_BIN_EMPTY_BORDER~&  = _RGBA32(48, 48, 48, 255) ' Empty bin border
THEME.DRAWER_BIN_DISABLED_FG~&   = _RGBA32(85, 85, 85, 255) ' Empty bin indicator color
THEME.DRAWER_BIN_DRAG_SWAP_BORDER~& = _RGBA32(255, 200, 80, 255) ' Drag swap drop target border
THEME.DRAWER_BIN_DRAG_INSERT_LINE~& = _RGBA32(100, 200, 255, 255) ' Drag insert edge line
THEME.DRAWER_BIN_DRAG_SOURCE_FILL~& = _RGBA32(0, 0, 0, 128) ' Drag source slot dim overlay
THEME.DRAWER_BIN_1BIT_SIGIL_BORDER~& = _RGBA32(0, 0, 0, 200) ' 1-bit sigil badge border
THEME.DRAWER_BIN_1BIT_SIGIL_FG~& = _RGBA32(255, 255, 255, 255) ' 1-bit sigil badge text
THEME.DRAWER_BIN_1BIT_SIGIL_BG~& = _RGBA32(0, 0, 0, 180) ' 1-bit sigil badge background
THEME.DRAWER_BIN_1BIT_SIGIL_PAD% = 1 ' 1-bit sigil badge inner padding (px)
THEME.DRAWER_BRUSH_CHECKER_DARK~& = _RGBA32(18, 18, 18, 255) ' Brush checker dark square
THEME.DRAWER_BRUSH_CHECKER_LIGHT~& = _RGBA32(42, 42, 42, 255) ' Brush checker light square
THEME.DRAWER_SCROLLBAR_TRACK~&   = _RGBA32(17, 17, 17, 255) ' Drawer scrollbar track
THEME.DRAWER_SCROLLBAR_THUMB~&   = _RGBA32(85, 85, 85, 255) ' Drawer scrollbar thumb
THEME.DRAWER_SCROLLBAR_THUMB_HOVER~& = _RGBA32(173, 173, 173, 255) ' Drawer scrollbar thumb hover
THEME.DRAWER_MINI_PALETTE_BORDER~& = _RGBA32(85, 85, 85, 255) ' Mini palette border
THEME.DRAWER_MINI_PALETTE_PAGE_BTN_BG~& = _RGBA32(48, 48, 48, 255) ' Page button background
THEME.DRAWER_MINI_PALETTE_PAGE_BTN_BORDER~& = _RGBA32(85, 85, 85, 255) ' Page button border
THEME.DRAWER_MINI_PALETTE_PAGE_BTN_FG~& = _RGBA32(255, 255, 255, 255) ' Page button text
THEME.DRAWER_MINI_PALETTE_PAGE_BTN_HOVER_BG~& = _RGBA32(56, 56, 56, 255) ' Page button hover background
THEME.DRAWER_LABEL_FG~&          = _RGBA32(200, 200, 200, 255) ' Drawer label text
THEME.DRAWER_LABEL_DIM_FG~&      = _RGBA32(120, 120, 120, 255) ' Drawer dim text
THEME.BINS_BG_COLOR~&            = _RGBA32(0, 0, 0, 255) ' Background behind bins section
THEME.BINS_BRUSH_WIDTH%          = 9                        ' Brush bin width in unscaled pixels
THEME.BINS_BRUSH_HEIGHT%         = 9                        ' Brush bin height in unscaled pixels
THEME.BINS_WIDE_WIDTH%           = 28                       ' Wide row width in unscaled pixels
THEME.BINS_WIDE_HEIGHT%          = 4                        ' Wide row height in unscaled pixels
THEME.COLOR_CHIP_outline~&       = _RGBA32(255, 255, 255, 255) ' Color chip outline: white
THEME.COLOR_CHIP_outline_alt~&   = _RGBA32(128, 128, 128, 255) ' Color chip outline alt: gray (when chip is near-white)
THEME.PIXEL_GRID_color1~&        = _RGBA32(80, 80, 80, 64) ' Dark gray grid lines at 25% opacity
THEME.PIXEL_GRID_color2~&        = _RGBA32(60, 60, 60, 64) ' Unused (for future checkerboard) at 25% opacity
THEME.PIXEL_GRID_color_fg~&      = _RGB32(80, 80, 80)       ' Pixel grid line color (dark gray)
THEME.PIXEL_GRID_opacity%        = 64                       ' 25% opacity (alpha 0-255)
THEME.GRID_angle!                = 0.0                      ' No grid rotation by default
THEME.CROSSHAIR_angle!           = 0.0                      ' No crosshair rotation by default
THEME.SYMMETRY_guide_fg~&        = _RGBA32(0, 255, 255, 128) ' Cyan guide lines at 50% opacity
THEME.SYMMETRY_center_fg~&       = _RGBA32(255, 255, 0, 128)  ' Yellow center crosshair at 50% opacity

' Smart guides defaults
THEME.SMART_GUIDES_color_fg~&    = _RGBA32(255, 0, 155, 180)  ' Magenta guide lines at 70% opacity
THEME.SMART_GUIDES_opacity%      = 180                        ' 70% opacity
THEME.SMART_GUIDES_outline_fg~&  = _RGBA32(0, 0, 0, 120)      ' Black outline at 47% opacity
THEME.SMART_GUIDES_outline_opacity% = 120
THEME.SMART_GUIDES_outline_width% = 1                         ' 1px outline
THEME.SMART_GUIDES_pattern%      = &B1111000011110000         ' Long dash pattern
THEME.SMART_GUIDES_distance%     = 4                          ' 4px detection distance

' Menu bar colors
THEME.MENU_BAR_bg~&              = _RGB32(121, 121, 121)     ' #797979 - medium gray bar
THEME.MENU_BAR_fg~&              = _RGB32(0, 0, 0)           ' Black text
THEME.MENU_BAR_border~&          = _RGB32(0, 0, 0)           ' Black border
THEME.MENU_BAR_divider~&         = _RGB32(121, 121, 121)     ' Same as bar bg
THEME.MENU_BAR_sel_bg~&          = _RGB32(85, 85, 85)        ' #555555 - darker highlight
THEME.MENU_BAR_sel_fg~&          = _RGB32(255, 255, 255)     ' White text on highlight
THEME.MENU_BAR_disabled_fg~&     = _RGB32(80, 80, 80)        ' #505050 - dimmed disabled text
THEME.MENU_SUB_bg~&              = _RGB32(121, 121, 121)     ' #797979 - medium gray submenu
THEME.MENU_SUB_fg~&              = _RGB32(0, 0, 0)           ' Black text
THEME.MENU_SUB_border~&          = _RGB32(0, 0, 0)           ' Black border
THEME.MENU_SUB_divider~&         = _RGB32(85, 85, 85)        ' #555555 - subtle divider
THEME.MENU_SUB_sel_bg~&          = _RGB32(85, 85, 85)        ' #555555 - darker highlight
THEME.MENU_SUB_disabled_fg~&     = _RGB32(80, 80, 80)        ' #505050 - dimmed disabled text
THEME.MENU_SUB_sel_fg~&          = _RGB32(255, 255, 255)     ' White text on highlight

' --- Layer panel ---
THEME.LAYER_PANEL_header_height% = 16                          ' Header bar height in pixels
THEME.LAYER_PANEL_btn_bar_height% = 16                         ' Button bar height in pixels
THEME.LAYER_PANEL_bg~&           = _RGB32(40, 40, 40)          ' Panel background
THEME.LAYER_PANEL_border~&       = _RGB32(60, 60, 60)          ' Right border
THEME.LAYER_PANEL_header_bg~&    = _RGB32(50, 50, 50)          ' Header background
THEME.LAYER_PANEL_header_fg~&    = _RGB32(200, 200, 200)       ' Header "LAYERS" text
THEME.LAYER_PANEL_header_fg_dim~& = _RGB32(150, 150, 150)      ' Header layer count (dimmed)
THEME.LAYER_PANEL_row_bg~&       = _RGB32(45, 45, 45)          ' Row normal background
THEME.LAYER_PANEL_row_hover_bg~& = _RGB32(55, 55, 55)          ' Row hover background
THEME.LAYER_PANEL_row_sel_bg~&   = _RGB32(70, 100, 140)        ' Row selected background
THEME.LAYER_PANEL_row_fg~&       = _RGB32(220, 220, 220)       ' Layer name text
THEME.LAYER_PANEL_row_fg_blend~& = _RGB32(180, 140, 255)       ' Blend mode short text
THEME.LAYER_PANEL_opacity_bar_bg~& = _RGB32(30, 30, 30)        ' Opacity bar background
THEME.LAYER_PANEL_opacity_bar_fg~& = _RGB32(100, 150, 200)     ' Opacity bar fill
THEME.LAYER_PANEL_scrollbar_track~& = _RGB32(30, 30, 30)       ' Scrollbar track
THEME.LAYER_PANEL_scrollbar_thumb~& = _RGB32(80, 80, 80)       ' Scrollbar thumb
THEME.LAYER_PANEL_sep~&          = _RGB32(60, 60, 60)          ' Separator above button bar
THEME.LAYER_PANEL_btn_bar_bg~&   = _RGB32(112, 112, 112)       ' Button bar background (#707070)
THEME.LAYER_PANEL_drop_line~&    = _RGB32(100, 200, 255)       ' Drop indicator (primary)
THEME.LAYER_PANEL_drop_line2~&   = _RGB32(50, 150, 200)        ' Drop indicator (shadow)
THEME.LAYER_PANEL_drag_fill~&    = _RGBA32(60, 120, 180, 180)  ' Drag preview fill
THEME.LAYER_PANEL_drag_border~&      = _RGB32(100, 200, 255)       ' Drag preview border
THEME.LAYER_PANEL_row_master_bg~&    = _RGB32(70, 100, 140)        ' Master layer row background
THEME.LAYER_PANEL_row_multi_sel_bg~& = _RGB32(50, 75, 110)         ' Multi-selected row background
THEME.LAYER_PANEL_row_master_accent~& = _RGB32(100, 180, 255)      ' Left-edge accent bar on master row
THEME.LAYER_PANEL_btn_drag_delete~&  = _RGBA32(200, 80, 80, 220)   ' Drag-over Delete button highlight
THEME.LAYER_PANEL_btn_drag_new~&     = _RGBA32(80, 200, 80, 220)   ' Drag-over New Layer button highlight

' --- Transform overlay frame ---
THEME.TRANSFORM_FRAME_COLOR~&        = _RGB32(180, 220, 255)       ' Quad outline
THEME.TRANSFORM_FRAME_HANDLE_COLOR~& = _RGB32(200, 230, 255)       ' Unselected handle fill
THEME.TRANSFORM_FRAME_HANDLE_SIZE%   = 5                           ' Handle half-size (screen px)

' --- Fill adjustment L-handle ---
THEME.FILL_ADJ_CORNER_COLOR~&        = _RGBA32(255, 255, 255, 255)  ' Corner box (white)
THEME.FILL_ADJ_CORNER_ACTIVE_COLOR~& = _RGBA32(255, 255, 100, 255)  ' Corner box active (yellow)
THEME.FILL_ADJ_ARM_X_COLOR~&         = _RGBA32(255, 80, 80, 255)    ' Horiz arm (red)
THEME.FILL_ADJ_ARM_X_ACTIVE_COLOR~&  = _RGBA32(255, 140, 140, 255)  ' Horiz arm active (bright red)
THEME.FILL_ADJ_ARM_Y_COLOR~&         = _RGBA32(80, 200, 80, 255)    ' Vert arm (green)
THEME.FILL_ADJ_ARM_Y_ACTIVE_COLOR~&  = _RGBA32(140, 255, 140, 255)  ' Vert arm active (bright green)
THEME.FILL_ADJ_SHADOW_COLOR~&        = _RGBA32(0, 0, 0, 140)        ' Shadow/outline
THEME.FILL_ADJ_DASH_COLOR1~&         = _RGBA32(255, 255, 255, 255)  ' Dash color 1
THEME.FILL_ADJ_DASH_COLOR2~&         = _RGBA32(0, 0, 0, 255)        ' Dash color 2
THEME.FILL_ADJ_INFO_BG_COLOR~&       = _RGBA32(0, 0, 0, 180)        ' Info text bg
THEME.FILL_ADJ_INFO_FG_COLOR~&       = _RGBA32(255, 255, 255, 255)  ' Info text fg
THEME.FILL_ADJ_HANDLE_SIZE%          = 7                            ' Corner half-size (px)
THEME.FILL_ADJ_ARM_LENGTH%           = 40                           ' Arm length (px)
THEME.FILL_ADJ_ARM_THICKNESS%        = 5                            ' Arm half-thickness (px)
THEME.FILL_ADJ_ROTATE_COLOR~&        = _RGBA32(100, 160, 255, 255)   ' Rotation handle (blue)
THEME.FILL_ADJ_ROTATE_ACTIVE_COLOR~& = _RGBA32(160, 210, 255, 255)  ' Rotation handle active (bright blue)
THEME.FILL_ADJ_ROTATE_RADIUS%        = 28                           ' Rotation arc radius (px)
THEME.FILL_ADJ_ICON_FILE$            = ""                            ' PNG widget (empty=procedural)

' --- Dialog chrome ---
THEME.DIALOG_bg~&                 = _RGB32(72, 72, 72)             ' Dialog body background
THEME.DIALOG_border_outer~&       = _RGB32(160, 160, 160)          ' Dialog outer border
THEME.DIALOG_border_inner~&       = _RGB32(48, 48, 48)             ' Dialog inner border / dividers
THEME.DIALOG_title_bg~&           = _RGB32(40, 40, 40)             ' Dialog title bar
THEME.DIALOG_title_hover_bg~&     = _RGB32(55, 55, 65)             ' Dialog title bar hover
THEME.DIALOG_title_drag_bg~&      = _RGB32(30, 35, 90)             ' Dialog title bar drag
THEME.DIALOG_title_fg~&           = _RGB32(255, 255, 255)          ' Dialog title text
THEME.DIALOG_title_grip~&         = _RGB32(90, 90, 90)             ' Dialog title grip dots
THEME.DIALOG_title_grip_active~&  = _RGB32(140, 140, 220)          ' Dialog title grip dots while dragging
THEME.DIALOG_button_fg~&          = _RGB32(255, 255, 255)          ' Dialog button text
THEME.DIALOG_toggle_sel_bg~&      = _RGB32(40, 80, 160)            ' Selected toggle background
THEME.DIALOG_toggle_sel_fg~&      = _RGB32(255, 255, 255)          ' Selected toggle text
THEME.DIALOG_toggle_sel_border~&  = _RGB32(100, 160, 255)          ' Selected toggle border
THEME.DIALOG_toggle_bg~&          = _RGB32(55, 55, 55)             ' Unselected toggle background
THEME.DIALOG_toggle_fg~&          = _RGB32(170, 170, 170)          ' Unselected toggle text
THEME.DIALOG_toggle_border~&      = _RGB32(90, 90, 90)             ' Unselected toggle border
THEME.DIALOG_label_fg~&           = _RGB32(200, 200, 200)          ' Dialog labels
THEME.DIALOG_slider_track_bg~&    = _RGB32(38, 38, 38)             ' Dialog slider track
THEME.DIALOG_slider_track_border~& = _RGB32(90, 90, 90)            ' Dialog slider track border
THEME.DIALOG_slider_fill~&        = _RGB32(40, 100, 180)           ' Dialog slider fill
THEME.DIALOG_slider_value_fg~&    = _RGB32(255, 255, 255)          ' Dialog slider value text
THEME.DIALOG_preview_bg~&         = _RGB32(18, 18, 18)             ' Dialog preview pane background
THEME.DIALOG_preview_split~&      = _RGB32(255, 200, 0)            ' Dialog preview split line / handle
THEME.DIALOG_preview_label_fg~&   = _RGB32(110, 110, 110)          ' Dialog preview labels
THEME.DIALOG_title_height%        = 17                              ' Dialog title bar bottom Y
THEME.DIALOG_slider_height%       = 14                              ' Dialog slider height
THEME.DIALOG_preview_handle_size% = 5                               ' Dialog preview handle half-size

' --- Command palette ---
THEME.CMD_PALETTE_width_ratio!      = 0.55                         ' Palette width ratio vs screen width
THEME.CMD_PALETTE_min_width%        = 280                          ' Palette minimum width
THEME.CMD_PALETTE_max_width%        = 500                          ' Palette maximum width
THEME.CMD_PALETTE_top%              = 40                           ' Palette top Y position
THEME.CMD_PALETTE_frame_outer~&     = _RGB32(0, 0, 0)             ' Palette outer frame
THEME.CMD_PALETTE_frame_mid~&       = _RGB32(80, 80, 80)          ' Palette mid frame
THEME.CMD_PALETTE_bg~&              = _RGB32(40, 40, 50)          ' Palette background
THEME.CMD_PALETTE_header_fg~&       = _RGB32(200, 200, 255)       ' Palette header text
THEME.CMD_PALETTE_hint_fg~&         = _RGB32(128, 128, 128)       ' Palette close hint
THEME.CMD_PALETTE_search_bg~&       = _RGB32(30, 30, 40)          ' Palette search box bg
THEME.CMD_PALETTE_search_border~&   = _RGB32(100, 100, 120)       ' Palette search box border
THEME.CMD_PALETTE_search_fg~&       = _RGB32(255, 255, 255)       ' Palette search text
THEME.CMD_PALETTE_search_placeholder_fg~& = _RGB32(100, 100, 100) ' Palette search placeholder
THEME.CMD_PALETTE_cursor_fg~&       = _RGB32(255, 255, 255)       ' Palette search cursor
THEME.CMD_PALETTE_hover_bg~&        = _RGB32(60, 80, 120)         ' Palette hovered row
THEME.CMD_PALETTE_category_fg~&     = _RGB32(100, 100, 140)       ' Palette category text
THEME.CMD_PALETTE_name_fg~&         = _RGB32(220, 220, 220)       ' Palette command name
THEME.CMD_PALETTE_hotkey_fg~&       = _RGB32(180, 180, 100)       ' Palette hotkey text
THEME.CMD_PALETTE_scroll_fg~&       = _RGB32(100, 100, 100)       ' Palette scroll summary

' --- Palette strip / palette menu ---
THEME.PALETTE_STRIP_bg~&             = _RGB32(68, 68, 68)          ' Palette strip background
THEME.PALETTE_STRIP_fg~&             = _RGB32(200, 200, 200)       ' Palette strip text
THEME.PALETTE_STRIP_arrow_fg~&       = _RGB32(180, 180, 180)       ' Palette strip arrows
THEME.PALETTE_STRIP_hover_fg~&       = _RGB32(255, 255, 255)       ' Palette strip hover text/arrows
THEME.PALETTE_STRIP_separator~&      = _RGB32(80, 80, 80)          ' Palette strip separator
THEME.PALETTE_STRIP_button_hover_bg~& = _RGB32(60, 60, 60)         ' Palette strip hover background
THEME.PALETTE_STRIP_sel_border_outer~&   = _RGB32(255, 255, 255)   ' Selected swatch outer border
THEME.PALETTE_STRIP_sel_border_inner~&   = _RGB32(0, 0, 0)         ' Selected swatch inner border
THEME.PALETTE_STRIP_inact_border_outer~& = _RGB32(80, 80, 80)      ' Inactive swatch outer border
THEME.PALETTE_STRIP_inact_border_inner~& = _RGB32(0, 0, 0)         ' Inactive swatch inner border
THEME.PALETTE_MENU_bg~&              = _RGB32(40, 40, 40)          ' Palette menu background
THEME.PALETTE_MENU_fg~&              = _RGB32(200, 200, 200)       ' Palette menu text
THEME.PALETTE_MENU_hover_bg~&        = _RGB32(70, 70, 70)          ' Palette menu hover background
THEME.PALETTE_MENU_selected_bg~&     = _RGB32(80, 100, 120)        ' Palette menu selected background
THEME.PALETTE_MENU_border~&          = _RGB32(100, 100, 100)       ' Palette menu border
THEME.PALETTE_MENU_current_fg~&      = _RGB32(255, 255, 255)       ' Palette menu current item text
THEME.PALETTE_MENU_scroll_fg~&       = _RGB32(150, 150, 150)       ' Palette menu scroll indicator
THEME.PALETTE_MENU_item_height%      = 12                           ' Palette menu item height

' --- Screen overlays ---
THEME.ZOOM_BOX_fill~&                = _RGBA32(255, 255, 255, 40)  ' Zoom drag fill
THEME.ZOOM_BOX_border~&              = _RGB32(255, 255, 255)       ' Zoom drag border
THEME.ZOOM_BOX_outer_border~&        = _RGB32(0, 0, 0)             ' Zoom drag outer border
THEME.TOOL_PREVIEW_transparent_fg~&  = _RGB32(255, 255, 255)       ' Transparent tool preview fill
THEME.TOOL_PREVIEW_transparent_outline~& = _RGB32(0, 0, 0)         ' Transparent tool preview outline
THEME.CANVAS_border~&                = _RGB32(51, 51, 51)          ' Canvas border

' --- Preview Window ---
THEME.PREVIEW_bg~&               = _RGB32(30, 30, 30)            ' Window background
THEME.PREVIEW_border~&           = _RGB32(80, 80, 80)            ' Outer border
THEME.PREVIEW_title_bg~&         = _RGB32(45, 45, 45)            ' Title bar background
THEME.PREVIEW_title_hover_bg~&   = _RGB32(60, 60, 60)            ' Title bar hover
THEME.PREVIEW_title_drag_bg~&    = _RGB32(35, 35, 100)           ' Title bar drag
THEME.PREVIEW_title_fg~&         = _RGB32(200, 200, 200)         ' Title text color
THEME.PREVIEW_close_fg~&         = _RGB32(220, 80, 80)           ' X button color
THEME.PREVIEW_close_hover_bg~&   = _RGB32(180, 40, 40)           ' X button hover bg
THEME.PREVIEW_minimize_fg~&      = _RGB32(200, 200, 80)          ' _ button color
THEME.PREVIEW_minimize_hover_bg~& = _RGB32(100, 100, 40)         ' _ button hover bg
THEME.PREVIEW_checkbox_fg~&      = _RGB32(180, 180, 180)         ' Checkbox text/check
THEME.PREVIEW_checkbox_bg~&      = _RGB32(40, 40, 40)            ' Checkbox box fill
THEME.PREVIEW_checkbox_border~&  = _RGB32(100, 100, 100)         ' Checkbox box border
THEME.PREVIEW_resize_handle_fg~& = _RGB32(100, 100, 100)         ' Resize handle color
THEME.PREVIEW_content_border~&   = _RGB32(60, 60, 60)            ' Preview image border
THEME.PREVIEW_center_dot_color~& = _RGB32(0, 255, 0)             ' Center dot in follow mode
THEME.PREVIEW_title_height%      = 14                            ' Title bar height px
THEME.PREVIEW_border_width%      = 1                             ' Border stroke width
THEME.PREVIEW_resize_handle_size% = 6                            ' Resize handle hit area
THEME.PREVIEW_button_width%      = 12                            ' X / _ button width
THEME.PREVIEW_button_height%     = 10                            ' X / _ button height
THEME.PREVIEW_checkbox_size%     = 8                             ' Checkbox square size
THEME.PREVIEW_padding%           = 2                             ' Content padding px
THEME.PREVIEW_initial_padding%   = 8                             ' Edge padding on first open
THEME.PREVIEW_font$              = ""                            ' Font (empty = global)
THEME.PREVIEW_font_size%         = 8                             ' Font point size

' --- Fonts ---
THEME.GLOBAL_FONT_FILE$          = "Tiny5-Regular.ttf"       ' Primary UI font
THEME.GLOBAL_FONT_SIZE%          = 8                         ' Primary UI font size
THEME.ALT_FONT_FILE$             = "PICO-8.ttf"              ' Alternate font (reserved)

' --- Sounds ---
THEME.SOUND_MENU_OPEN_FILE$   = "menu-open.wav"    ' Open root menu
THEME.SOUND_MENU_SELECT_FILE$ = "menu-select.wav"   ' Select menu item
THEME.SOUND_NEW_FILE_FILE$    = "new-file.wav"       ' New file / startup
THEME.SOUND_NEW_LAYER_FILE$   = "new-layer.wav"      ' New layer
THEME.SOUND_LAYER_OP_FILE$    = "layer-op.wav"       ' Delete/arrange/merge/duplicate layer
THEME.SOUND_CLIPBOARD_FILE$   = "clipboard.wav"      ' Copy/Cut/Paste
THEME.SOUND_FILL_FILE$        = "fill.wav"           ' Flood fill
THEME.SOUND_SELECTION_FILE$   = "selections.wav"     ' Selection operations
THEME.SOUND_DRAW_FILE$        = "draw.wav"           ' Brush/dot/spray drag
THEME.SOUND_TRANSFORM_FILE$   = "transform.wav"      ' Flip/scale/rotate/About
THEME.SOUND_TEXT_ENTER_FILE$  = "text-enter.wav"     ' Text tool Enter key
THEME.SOUND_MENU_HOVER_FILE$  = "menu-hover.wav"     ' Hovering a new menu item
THEME.SOUND_TOOL_SELECT_FILE$ = "tool-select.wav"    ' Toolbox button click
THEME.SOUND_TEXT_CHAR_FILE$   = "text-char.wav"      ' Text tool character typed
THEME.SOUND_ERASER_FILE$      = "eraser.wav"         ' Eraser stroke drag
THEME.SOUND_DRAW_PITCH_MIN!   = 0.8                  ' Draw pitch range minimum
THEME.SOUND_DRAW_PITCH_MAX!   = 1.2                  ' Draw pitch range maximum
THEME.SOUND_ERASER_PITCH_MIN! = 0.8                  ' Eraser pitch range minimum
THEME.SOUND_ERASER_PITCH_MAX! = 1.2                  ' Eraser pitch range maximum
THEME.SOUND_DRAW_REVERSE_FILE$   = "draw-reversed.wav"  ' Reversed draw for direction change
THEME.SOUND_ERASER_REVERSE_FILE$ = "draw-reversed.wav"  ' Reversed eraser for direction change
THEME.SOUND_DRAW_LENGTH_DYNAMICS_MIN! = 0.2             ' Volume at short drag distance
THEME.SOUND_DRAW_LENGTH_DYNAMICS_MAX! = 1.0             ' Volume at long drag distance
THEME.SOUND_SLIDER_FILE$    = "slider.wav"              ' Opacity/value slider drag
THEME.SOUND_DRAG_DROP_FILE$ = "drag-drop.wav"           ' Layer drag-and-drop reorder
THEME.SOUND_POINT_FILE$     = "point.wav"               ' Click to place a point (line/shape/poly)
THEME.SOUND_ORGANIZER_FILE$ = "text-char.wav"           ' Organizer/drawer widget click or mousewheel
THEME.MUSIC_FILE$ = "music.it"                         ' Background music (tracker module)

' --- Lospec dialog ---
THEME.LOSPEC_SWATCH_COLS%   = 16                         ' Lospec preview swatch columns

' --- Dialog chrome ---
THEME.DIALOG_font_size%             = 8

' --- Lospec dialog colors ---
THEME.LOSPEC_status_error_fg~&      = _RGB32(255, 100, 100)
THEME.LOSPEC_status_ok_fg~&         = _RGB32(100, 255, 150)
THEME.LOSPEC_status_info_fg~&       = _RGB32(150, 200, 255)
THEME.LOSPEC_search_bg~&            = _RGB32(30, 30, 40)
THEME.LOSPEC_search_border~&        = _RGB32(90, 90, 120)
THEME.LOSPEC_search_cursor~&        = _RGB32(200, 200, 220)
THEME.LOSPEC_col_header_fg~&        = _RGB32(140, 180, 220)
THEME.LOSPEC_col_divider~&          = _RGB32(80, 80, 100)
THEME.LOSPEC_result_sel_bg~&        = _RGB32(30, 80, 40)
THEME.LOSPEC_result_hover_bg~&      = _RGB32(50, 70, 110)
THEME.LOSPEC_result_fg~&            = _RGB32(220, 220, 220)
THEME.LOSPEC_result_count_fg~&      = _RGB32(130, 160, 190)
THEME.LOSPEC_batch_hover_bg~&       = _RGB32(80, 50, 50)
THEME.LOSPEC_count_fg~&             = _RGB32(130, 130, 130)
THEME.LOSPEC_preview_panel_bg~&     = _RGB32(25, 25, 35)
THEME.LOSPEC_preview_name_fg~&      = _RGB32(230, 230, 240)
THEME.LOSPEC_preview_author_fg~&    = _RGB32(160, 180, 200)
THEME.LOSPEC_preview_link_fg~&      = _RGB32(80, 140, 220)
THEME.LOSPEC_preview_link_hov~&     = _RGB32(130, 190, 255)
THEME.LOSPEC_tooltip_sep~&          = _RGB32(60, 60, 60)
THEME.LOSPEC_tooltip_bg~&           = _RGB32(20, 20, 25)
THEME.LOSPEC_tooltip_fg~&           = _RGB32(200, 200, 220)
THEME.LOSPEC_tooltip_hint_fg~&      = _RGB32(100, 100, 110)
THEME.LOSPEC_empty_fg~&             = _RGB32(70, 70, 80)
THEME.LOSPEC_btn_dl_bg~&            = _RGB32(40, 60, 90)
THEME.LOSPEC_btn_dl_hover~&         = _RGB32(60, 90, 130)
THEME.LOSPEC_btn_dl_border~&        = _RGB32(100, 130, 180)
THEME.LOSPEC_btn_close_bg~&         = _RGB32(50, 40, 40)
THEME.LOSPEC_btn_close_hover~&      = _RGB32(80, 60, 60)
THEME.LOSPEC_btn_close_border~&     = _RGB32(130, 100, 100)
THEME.LOSPEC_checkbox_border~&      = _RGB32(90, 90, 90)
THEME.LOSPEC_checkbox_fill~&        = _RGB32(40, 80, 160)
THEME.LOSPEC_checkbox_dl_fill~&     = _RGB32(40, 120, 60)
THEME.LOSPEC_downloaded_fg~&        = _RGB32(100, 190, 120)
THEME.PALETTE_MENU_SEP_fg~&         = _RGB32(110, 110, 120)
THEME.PALETTE_MENU_SEP_bg~&         = _RGB32(22, 22, 34)

' =============================================================================
' EDIT BAR - Vertical icon quick-action panel
' =============================================================================
THEME.EDIT_BAR_LEFT_BORDER_COLOR~&  = _RGB32(64, 64, 64)
THEME.EDIT_BAR_RIGHT_BORDER_COLOR~& = _RGB32(64, 64, 64)
THEME.EDIT_BAR_LEFT_BORDER_WIDTH%   = 1
THEME.EDIT_BAR_RIGHT_BORDER_WIDTH%  = 1
THEME.EDIT_BAR_WIDTH%               = 18
THEME.EDIT_BAR_ICON_PADDING%        = 0
THEME.EDIT_BAR_BG_COLOR~&           = _RGBA32(0, 0, 0, 255)
THEME.EDIT_BAR_ICON_MOUSE_OUTLINE_COLOR~& = _RGBA32(255, 255, 255, 200)
THEME.EDIT_BAR_ICON_DISABLED_ALPHA%       = 160
THEME.EDIT_BAR_DIVIDER_VERT_MARGIN% = 4
THEME.EDIT_BAR_ICON_UNDO$           = "eb-undo.png"
THEME.EDIT_BAR_ICON_REDO$           = "eb-redo.png"
THEME.EDIT_BAR_ICON_CUT$            = "eb-cut.png"
THEME.EDIT_BAR_ICON_COPY$           = "eb-copy.png"
THEME.EDIT_BAR_ICON_COPY_MERGED$    = "eb-copy-merged.png"
THEME.EDIT_BAR_ICON_PASTE$          = "eb-paste.png"
THEME.EDIT_BAR_ICON_PASTE_IN_PLACE$ = "eb-paste-in-place.png"
THEME.EDIT_BAR_ICON_CUT_TO_LAYER$   = "eb-cut-to-new-layer.png"
THEME.EDIT_BAR_ICON_COPY_TO_LAYER$  = "eb-copy-to-new-layer.png"
THEME.EDIT_BAR_ICON_CLEAR$          = "eb-clear.png"
THEME.EDIT_BAR_ICON_FILL_WITH_FG$   = "eb-fill-with-fg-color.png"
THEME.EDIT_BAR_ICON_FILL_WITH_BG$   = "eb-fill-with-bg-color.png"
THEME.EDIT_BAR_ICON_STROKE_SELECTION$ = "eb-stroke-selection.png"
THEME.EDIT_BAR_ICON_FLIP_HORIZONTAL$ = "eb-flip-horizontal.png"
THEME.EDIT_BAR_ICON_FLIP_VERTICAL$  = "eb-flip-vertical.png"
THEME.EDIT_BAR_ICON_SCALE_DOWN$     = "eb-scale-down.png"
THEME.EDIT_BAR_ICON_SCALE_UP$       = "eb-scale-up.png"
THEME.EDIT_BAR_ICON_ROTATE_CW$      = "eb-rotate-cw.png"
THEME.EDIT_BAR_ICON_ROTATE_CCW$     = "eb-rotate-ccw.png"
THEME.EDIT_BAR_ICON_SMART_GUIDES$   = "eb-smart-guides.png"
THEME.EDIT_BAR_ICON_SMART_GUIDES_SNAP$ = "eb-smart-guides-snap.png"

' =============================================================================
' ADVANCED BAR - Dockable vertical icon bar for advanced features
' =============================================================================
THEME.ADV_BAR_LEFT_BORDER_COLOR~&   = _RGB32(64, 64, 64)
THEME.ADV_BAR_RIGHT_BORDER_COLOR~&  = _RGB32(64, 64, 64)
THEME.ADV_BAR_LEFT_BORDER_WIDTH%    = 1
THEME.ADV_BAR_RIGHT_BORDER_WIDTH%   = 1
THEME.ADV_BAR_WIDTH%                = 18
THEME.ADV_BAR_ICON_PADDING%         = 0
THEME.ADV_BAR_BG_COLOR~&            = _RGBA32(0, 0, 0, 255)
THEME.ADV_BAR_ICON_MOUSE_OUTLINE_COLOR~& = _RGBA32(255, 255, 255, 200)
THEME.ADV_BAR_ICON_DISABLED_ALPHA%  = 160
THEME.ADV_BAR_DIVIDER_VERT_MARGIN%  = 4
THEME.ADV_BAR_ICON_PREVIEW_WINDOW$  = "preview-window.png"
THEME.ADV_BAR_ICON_EDIT_BAR$        = "edit-bar.png"
THEME.ADV_BAR_ICON_CHAR_MAP$        = "char-map.png"
THEME.ADV_BAR_ICON_CHAR_GRID$       = "char-grid.png"
THEME.ADV_BAR_ICON_CHAR_GRID_SNAP$  = "char-grid-snap.png"
THEME.ADV_BAR_ICON_TILE_MODE$       = "tile-mode.png"
THEME.ADV_BAR_ICON_FILL_GRID_MODE$  = "fill-grid-mode.png"
THEME.ADV_BAR_ICON_GRID_BRUSH_SIZE$ = "grid-tile-mode.png"
THEME.ADV_BAR_ICON_FILL_ADJUST$     = "fill-adjust.png"
THEME.ADV_BAR_ICON_BRUSH_EDGES$     = "brush-grid-size.png"
THEME.ADV_BAR_ICON_ANGLE_SNAP$      = "angle-snap.png"
THEME.ADV_BAR_ICON_GRAYSCALE$       = "grayscale.png"
THEME.ADV_BAR_ICON_REF_ON$          = "reference-on.png"
THEME.ADV_BAR_ICON_REF_LOAD$        = "reference-load.png"
THEME.ADV_BAR_ICON_REF_CLEAR$       = "reference-clear.png"
THEME.ADV_BAR_ICON_REF_ADJUST$      = "reference-adjust.png"
THEME.ADV_BAR_ICON_ALIGN_LEFT$      = "align-left.png"
THEME.ADV_BAR_ICON_ALIGN_CENTER$    = "align-center.png"
THEME.ADV_BAR_ICON_ALIGN_RIGHT$     = "align-right.png"
THEME.ADV_BAR_ICON_ALIGN_TOP$       = "align-top.png"
THEME.ADV_BAR_ICON_ALIGN_MIDDLE$    = "align-middle.png"
THEME.ADV_BAR_ICON_ALIGN_BOTTOM$    = "align-bottom.png"
THEME.ADV_BAR_ICON_DIST_H$          = "distribute-horizontal.png"
THEME.ADV_BAR_ICON_DIST_V$          = "distribute-vertical.png"
THEME.ADV_BAR_ICON_FLIP_CANVAS_H$   = "flip-canvas-horizontal.png"
THEME.ADV_BAR_ICON_FLIP_CANVAS_V$   = "flip-canvas-vertical.png"

PALETTE_SEP_LOSPEC_LBL$             = "-- USER : LOSPEC --"
PALETTE_SEP_CREATED_LBL$            = "-- USER : CREATED --"

' =============================================================================
' CHARACTER MAP - Dockable glyph grid panel
' =============================================================================
THEME.CHARMAP_BG~&                  = _RGB32(20, 20, 32)
THEME.CHARMAP_FG~&                  = _RGB32(180, 180, 180)
THEME.CHARMAP_SELECTED_FG~&         = _RGB32(0, 0, 0)
THEME.CHARMAP_SELECTED_BG~&         = _RGB32(255, 255, 255)
THEME.CHARMAP_HOVER_FG~&            = _RGB32(220, 220, 220)
THEME.CHARMAP_HOVER_BG~&            = _RGB32(50, 50, 80)
THEME.CHARMAP_GRID_FG~&             = _RGB32(40, 40, 60)
THEME.CHARMAP_FLASH_FG~&            = _RGB32(255, 200, 60)
THEME.CHARMAP_SCROLLBAR_BG~&        = _RGB32(40, 40, 60)
THEME.CHARMAP_SCROLLBAR_FG~&        = _RGB32(255, 255, 255)
THEME.CHARMAP_SCROLLBAR_OPACITY%    = 255
THEME.CHARMAP_SCROLLBAR_WIDTH%      = 2
THEME.CHAR_GRID_COLOR_FG~&          = _RGBA32(100, 100, 200, 80)

' =============================================================================
' TEXT BAR - Rich text formatting bar (below menu bar when text tool active)
' =============================================================================
THEME.TEXT_BAR_BG~&                  = _RGB32(28, 28, 42)
THEME.TEXT_BAR_FG~&                  = _RGB32(200, 200, 200)
THEME.TEXT_BAR_BORDER~&              = _RGB32(64, 64, 64)
THEME.TEXT_BAR_BTN_ACTIVE~&          = _RGB32(80, 80, 160)
THEME.TEXT_BAR_BTN_HOVER~&           = _RGB32(60, 60, 90)
THEME.TEXT_BAR_BTN_BG~&              = _RGB32(38, 38, 52)
THEME.TEXT_BAR_BTN_FG~&              = _RGB32(200, 200, 200)
THEME.TEXT_BAR_BTN_BORDER~&          = _RGB32(64, 64, 80)
THEME.TEXT_BAR_ICON_SELECTED_OPACITY%   = 255
THEME.TEXT_BAR_ICON_DESELECTED_OPACITY% = 100
THEME.TEXT_BAR_DROPDOWN_BG~&         = _RGB32(32, 32, 48)
THEME.TEXT_BAR_DROPDOWN_FG~&         = _RGB32(200, 200, 200)
THEME.TEXT_BAR_DROPDOWN_HIGHLIGHT~&  = _RGB32(60, 80, 160)
THEME.TEXT_BAR_DROPDOWN_HOVER_BG~&  = _RGB32(45, 55, 110)
THEME.TEXT_BAR_DROPDOWN_HOVER_FG~&  = _RGB32(230, 230, 255)
' Icon filenames (from ASSETS/THEMES/{theme}/IMAGES/TEXTBAR/)
THEME.TEXT_BAR_ICON_BOLD$            = "IMAGES/TEXTBAR/tb-bold.png"
THEME.TEXT_BAR_ICON_ITALIC$          = "IMAGES/TEXTBAR/tb-italic.png"
THEME.TEXT_BAR_ICON_UNDERLINE$       = "IMAGES/TEXTBAR/tb-underline.png"
THEME.TEXT_BAR_ICON_STRIKE$          = "IMAGES/TEXTBAR/tb-strikethrough.png"
THEME.TEXT_BAR_ICON_MONO$            = "IMAGES/TEXTBAR/tb-monospace.png"
THEME.TEXT_BAR_ICON_LINE_HEIGHT$     = "IMAGES/TEXTBAR/tb-line-height.png"
' --- Text Bar: Layout ---
THEME.TEXT_BAR_ROW1_ORDER$           = "FONT,SIZE,BIUS,COLORS,MONO,LH,CHAR"
THEME.TEXT_BAR_ROW2_ORDER$           = "STYLE,ALIGN,SHADOW,OUTLINE,AA"
' --- Text Bar: Geometry ---
THEME.TEXT_BAR_ROW_HEIGHT%           = 14
THEME.TEXT_BAR_PADDING_H%            = 4
THEME.TEXT_BAR_PADDING_V%            = 2
THEME.TEXT_BAR_GROUP_GAP%            = 6
THEME.TEXT_BAR_BORDER_WIDTH%         = 1
' --- Text Bar: Button Geometry ---
THEME.TEXT_BAR_BTN_WIDTH%            = 12
THEME.TEXT_BAR_BTN_GAP%              = 2
THEME.TEXT_BAR_BTN_PADDING%          = 3
' --- Text Bar: Icon Geometry ---
THEME.TEXT_BAR_ICON_WIDTH%           = 10
THEME.TEXT_BAR_ICON_HEIGHT%          = 10
THEME.TEXT_BAR_ICON_OFFSET_X%        = 1
THEME.TEXT_BAR_ICON_OFFSET_Y%        = 2
' --- Text Bar: Swatch Geometry ---
THEME.TEXT_BAR_SWATCH_WIDTH%         = 10
THEME.TEXT_BAR_SWATCH_GAP%           = 4
' --- Text Bar: Dropdown Geometry ---
THEME.TEXT_BAR_DROPDOWN_ARROW_W%     = 6
THEME.TEXT_BAR_DROPDOWN_ITEM_H%      = 12
THEME.TEXT_BAR_DROPDOWN_PAD%         = 4
THEME.TEXT_BAR_DROPDOWN_MIN_W%       = 40
' --- Text Bar: Label ---
THEME.TEXT_BAR_LABEL_OFFSET_Y%       = 3
' --- Text Bar: Row 2 Icons ---
THEME.TEXT_BAR_ICON_OUTLINE$         = "IMAGES/TEXTBAR/tb-outline.png"
THEME.TEXT_BAR_ICON_SHADOW$          = "IMAGES/TEXTBAR/tb-shadow.png"
THEME.TEXT_BAR_ICON_ALIGN_LEFT$      = "IMAGES/TEXTBAR/tb-align-left.png"
THEME.TEXT_BAR_ICON_ALIGN_CENTER$    = "IMAGES/TEXTBAR/tb-align-center.png"
THEME.TEXT_BAR_ICON_ALIGN_RIGHT$     = "IMAGES/TEXTBAR/tb-align-right.png"
THEME.TEXT_BAR_ICON_STYLE_UPDATE$    = "IMAGES/TEXTBAR/tb-style-update.png"
THEME.TEXT_BAR_ICON_STYLE_SAVE$      = "IMAGES/TEXTBAR/tb-style-save.png"
THEME.TEXT_BAR_ICON_STYLE_DELETE$    = "IMAGES/TEXTBAR/tb-style-delete.png"
THEME.TEXT_BAR_ICON_AUTO$            = "IMAGES/TEXTBAR/tb-auto.png"
THEME.TEXT_BAR_ICON_CHAR$            = "IMAGES/TEXTBAR/tb-char.png"
THEME.TEXT_BAR_ICON_AA$              = "IMAGES/TEXTBAR/tb-aa.png"
' --- Text Bar: Transparency ---
THEME.TEXT_BAR_TRANSPARENT_CHECK_DARK~&   = _RGBA32(192, 192, 192, 255)
THEME.TEXT_BAR_TRANSPARENT_CHECK_LIGHT~&  = _RGBA32(255, 255, 255, 255)
THEME.LAYER_PANEL_TEXT_ACCENT~&      = _RGB32(80, 120, 200)
THEME.TEXT_LAYER_HOVER_OUTLINE~&     = _RGBA32(100, 200, 255, 180)
THEME.TEXT_LAYER_HOVER_OUTLINE_WIDTH% = 2

' =============================================================================
' CURSORS - PNG cursor configuration
' =============================================================================
' Each cursor has a filename, hotspot, and optional overlays.
' Hotspot expressions: left, right, top, bottom/bot, center, or number.
' Arithmetic: center+5, bottom-1, left-20, right+20, etc.
' Overlay text templates: %mx %my %ow %oh %ox %oy %nw %nh %nx %ny
' =============================================================================

' --- Null cursor (default arrow for UI areas) ---
CURSORS(CURSOR_NULL).filename$        = "cursor-null.png"
CURSORS(CURSOR_NULL).hotspot_x_expr$  = "left"
CURSORS(CURSOR_NULL).hotspot_y_expr$  = "top"

' --- Brush cursor ---
CURSORS(CURSOR_BRUSH).filename$       = "cursor-brush.png"
CURSORS(CURSOR_BRUSH).hotspot_x_expr$ = "left"
CURSORS(CURSOR_BRUSH).hotspot_y_expr$ = "top"

' --- Dropper / Picker cursor ---
CURSORS(CURSOR_DROPPER).filename$       = "cursor-dropper.png"
CURSORS(CURSOR_DROPPER).hotspot_x_expr$ = "2"
CURSORS(CURSOR_DROPPER).hotspot_y_expr$ = "bottom"

' --- Fill cursor ---
CURSORS(CURSOR_FILL).filename$       = "cursor-fill.png"
CURSORS(CURSOR_FILL).hotspot_x_expr$ = "4"
CURSORS(CURSOR_FILL).hotspot_y_expr$ = "bottom-1"

' --- Hand / Pan cursor ---
CURSORS(CURSOR_HAND).filename$       = "cursor-hand.png"
CURSORS(CURSOR_HAND).hotspot_x_expr$ = "center"
CURSORS(CURSOR_HAND).hotspot_y_expr$ = "center"

' --- Marquee cursor (generic fallback, also used by crop) ---
CURSORS(CURSOR_MARQUEE).filename$       = "cursor-marquee.png"
CURSORS(CURSOR_MARQUEE).hotspot_x_expr$ = "center"
CURSORS(CURSOR_MARQUEE).hotspot_y_expr$ = "center"

' --- Marquee variant cursors ---
CURSORS(CURSOR_MARQUEE_RECT).filename$       = "cursor-crosshair-rect.png"
CURSORS(CURSOR_MARQUEE_RECT).hotspot_x_expr$ = "5"
CURSORS(CURSOR_MARQUEE_RECT).hotspot_y_expr$ = "11"

CURSORS(CURSOR_MARQUEE_FREE).filename$       = "cursor-crosshair-freehand.png"
CURSORS(CURSOR_MARQUEE_FREE).hotspot_x_expr$ = "5"
CURSORS(CURSOR_MARQUEE_FREE).hotspot_y_expr$ = "9"

CURSORS(CURSOR_MARQUEE_POLY).filename$       = "cursor-crosshair-poly.png"
CURSORS(CURSOR_MARQUEE_POLY).hotspot_x_expr$ = "5"
CURSORS(CURSOR_MARQUEE_POLY).hotspot_y_expr$ = "10"

CURSORS(CURSOR_MARQUEE_ELLIP).filename$       = "cursor-crosshair-ellipse.png"
CURSORS(CURSOR_MARQUEE_ELLIP).hotspot_x_expr$ = "5"
CURSORS(CURSOR_MARQUEE_ELLIP).hotspot_y_expr$ = "11"

' --- Move cursor ---
CURSORS(CURSOR_MOVE).filename$       = "cursor-move.png"
CURSORS(CURSOR_MOVE).hotspot_x_expr$ = "center"
CURSORS(CURSOR_MOVE).hotspot_y_expr$ = "center"

' --- Resize corner cursor ---
CURSORS(CURSOR_RESIZE_CORNER).filename$       = "cursor-resize-corner.png"
CURSORS(CURSOR_RESIZE_CORNER).hotspot_x_expr$ = "center"
CURSORS(CURSOR_RESIZE_CORNER).hotspot_y_expr$ = "center"

' --- Resize horizontal cursor ---
CURSORS(CURSOR_RESIZE_HORIZ).filename$       = "cursor-resize-horizontal.png"
CURSORS(CURSOR_RESIZE_HORIZ).hotspot_x_expr$ = "center"
CURSORS(CURSOR_RESIZE_HORIZ).hotspot_y_expr$ = "center"

' --- Resize vertical cursor ---
CURSORS(CURSOR_RESIZE_VERT).filename$       = "cursor-resize-vertical.png"
CURSORS(CURSOR_RESIZE_VERT).hotspot_x_expr$ = "center"
CURSORS(CURSOR_RESIZE_VERT).hotspot_y_expr$ = "center"

' --- Spray cursor ---
CURSORS(CURSOR_SPRAY).filename$       = "cursor-spray.png"
CURSORS(CURSOR_SPRAY).hotspot_x_expr$ = "left"
CURSORS(CURSOR_SPRAY).hotspot_y_expr$ = "top"

' --- Wand cursor (magic wand / right-click marquee) ---
CURSORS(CURSOR_WAND).filename$       = "cursor-crosshair-wand.png"
CURSORS(CURSOR_WAND).hotspot_x_expr$ = "5"
CURSORS(CURSOR_WAND).hotspot_y_expr$ = "9"

' --- Zoom cursor ---
CURSORS(CURSOR_ZOOM).filename$       = "cursor-zoom.png"
CURSORS(CURSOR_ZOOM).hotspot_x_expr$ = "center"
CURSORS(CURSOR_ZOOM).hotspot_y_expr$ = "center"
