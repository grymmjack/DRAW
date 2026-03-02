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
THEME.CROSSHAIR_color_fg~&       = _RGB32(128, 128, 128)   ' Medium gray crosshair lines
THEME.CROSSHAIR_opacity%         = 128                     ' 50% opacity (alpha 0-255)
THEME.CROSSHAIR_font_fg~&        = _RGB32(255, 255, 255)   ' White coordinate text
THEME.CROSSHAIR_pattern%         = &B1010101010101010      ' - - - - - - - -
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

' --- Fonts ---
THEME.GLOBAL_FONT_FILE$          = "Tiny5-Regular.ttf"       ' Primary UI font
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
