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
    STATUS_bg_color        AS _UNSIGNED LONG ' Status bar background color (RGBA)
    STATUS_fg_color        AS _UNSIGNED LONG ' Status bar foreground color (RGBA)
    STATUS_swatch_fg_outline AS _UNSIGNED LONG ' Foreground swatch outline color
    STATUS_swatch_bg_outline AS _UNSIGNED LONG ' Background swatch outline color
    STATUS_swatch_transparent_bg AS _UNSIGNED LONG ' Transparent swatch fill color
    STATUS_swatch_transparent_diagonal AS _UNSIGNED LONG ' Transparent swatch diagonal slash
    STATUS_swatch_transparent_border AS _UNSIGNED LONG ' Transparent swatch border color
    STATUS_swatch_active_outer AS _UNSIGNED LONG ' Active transparent swatch outer border
    STATUS_swatch_active_inner AS _UNSIGNED LONG ' Active transparent swatch inner border
    CROSSHAIR_color_fg      AS _UNSIGNED LONG ' Crosshair line color (RGBA)
    CROSSHAIR_opacity       AS INTEGER ' Crosshair line opacity (0-255)
    CROSSHAIR_font          AS STRING ' Crosshair coordinate font filename override
    CROSSHAIR_font_size     AS INTEGER ' Crosshair coordinate font size in pixels
    CROSSHAIR_font_fg       AS _UNSIGNED LONG ' Crosshair coordinate text color (RGBA)
    CROSSHAIR_font_stroke_fg AS _UNSIGNED LONG ' Crosshair coordinate outline color (RGBA)
    CROSSHAIR_font_stroke_width AS INTEGER ' Crosshair coordinate outline width in pixels
    CROSSHAIR_pattern       AS INTEGER ' Crosshair line pattern (16 bit &B>inary)
    PICKER_LOUPE_zoom_level AS INTEGER ' Loupe zoom factor
    PICKER_LOUPE_rect_x_offset AS INTEGER ' Loupe X offset from mouse in screen pixels
    PICKER_LOUPE_rect_y_offset AS INTEGER ' Loupe Y offset from mouse in screen pixels
    PICKER_LOUPE_rect_width AS INTEGER ' Loupe rectangle width in screen pixels
    PICKER_LOUPE_rect_height AS INTEGER ' Loupe rectangle height in screen pixels
    PICKER_LOUPE_rgba_x AS INTEGER ' RGB text X offset relative to loupe rectangle
    PICKER_LOUPE_rgba_y AS INTEGER ' RGB text Y offset relative to loupe rectangle
    PICKER_LOUPE_font AS STRING ' Loupe font filename override
    PICKER_LOUPE_font_size AS INTEGER ' Loupe font size in pixels
    PICKER_LOUPE_font_fg AS _UNSIGNED LONG ' Loupe label foreground color
    PICKER_LOUPE_font_bg AS _UNSIGNED LONG ' Loupe label background / panel fill color
    PICKER_LOUPE_font_stroke_fg AS _UNSIGNED LONG ' Loupe label outline color
    PICKER_LOUPE_font_stroke_width AS INTEGER ' Loupe label outline width in pixels
    PICKER_LOUPE_rect_stroke_fg AS _UNSIGNED LONG ' Loupe border color
    PICKER_LOUPE_rect_stroke_width AS INTEGER ' Loupe border width in pixels
    PICKER_LOUPE_pixel_pickup_color AS _UNSIGNED LONG ' Loupe sampled-pixel marker color
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
    DRAWER_PANEL_PAD_X     AS INTEGER        ' Drawer panel inner horizontal padding
    DRAWER_PANEL_PAD_Y     AS INTEGER        ' Drawer panel inner vertical padding
    DRAWER_PANEL_GAP_Y     AS INTEGER        ' Shared vertical gap inside drawer panel
    DRAWER_BIN_WIDTH       AS INTEGER        ' Bin width in unscaled pixels
    DRAWER_BIN_HEIGHT      AS INTEGER        ' Bin height in unscaled pixels
    DRAWER_BIN_GAP_X       AS INTEGER        ' Horizontal gap between bins
    DRAWER_BIN_GAP_Y       AS INTEGER        ' Vertical gap between bins
    DRAWER_BIN_PREVIEW_PAD AS INTEGER        ' Preview inset inside each bin
    DRAWER_SCROLLBAR_WIDTH AS INTEGER        ' Drawer scrollbar width
    DRAWER_SCROLLBAR_MIN_THUMB_H AS INTEGER  ' Minimum drawer scrollbar thumb height
    DRAWER_MINI_PALETTE_COLS AS INTEGER      ' Mini palette column count
    DRAWER_MINI_PALETTE_ROWS AS INTEGER      ' Mini palette row count
    DRAWER_MINI_PALETTE_CELL_W AS INTEGER    ' Mini palette cell width
    DRAWER_MINI_PALETTE_CELL_H AS INTEGER    ' Mini palette cell height
    DRAWER_MINI_PALETTE_GAP_X AS INTEGER     ' Mini palette horizontal gap
    DRAWER_MINI_PALETTE_GAP_Y AS INTEGER     ' Mini palette vertical gap
    DRAWER_MINI_PALETTE_PAGE_BTN_W AS INTEGER ' Mini palette page button width
    DRAWER_MINI_PALETTE_PAGE_BTN_H AS INTEGER ' Mini palette page button height
    DRAWER_PANEL_BG        AS _UNSIGNED LONG ' Drawer panel background
    DRAWER_PANEL_BORDER    AS _UNSIGNED LONG ' Drawer panel border
    DRAWER_PANEL_ACCENT    AS _UNSIGNED LONG ' Drawer panel accent line
    DRAWER_BIN_BG          AS _UNSIGNED LONG ' Filled bin background
    DRAWER_BIN_BORDER      AS _UNSIGNED LONG ' Filled bin border
    DRAWER_BIN_HOVER_BG    AS _UNSIGNED LONG ' Hovered bin background
    DRAWER_BIN_HOVER_BORDER AS _UNSIGNED LONG ' Hovered bin border
    DRAWER_BIN_SELECTED_BG AS _UNSIGNED LONG ' Selected bin background
    DRAWER_BIN_SELECTED_BORDER AS _UNSIGNED LONG ' Selected bin border
    DRAWER_BIN_EMPTY_BG    AS _UNSIGNED LONG ' Empty bin background
    DRAWER_BIN_EMPTY_BORDER AS _UNSIGNED LONG ' Empty bin border
    DRAWER_BIN_DISABLED_FG AS _UNSIGNED LONG ' Empty/disabled bin indicator color
    DRAWER_BRUSH_CHECKER_DARK AS _UNSIGNED LONG ' Brush bin checker dark color
    DRAWER_BRUSH_CHECKER_LIGHT AS _UNSIGNED LONG ' Brush bin checker light color
    DRAWER_SCROLLBAR_TRACK AS _UNSIGNED LONG ' Drawer scrollbar track
    DRAWER_SCROLLBAR_THUMB AS _UNSIGNED LONG ' Drawer scrollbar thumb
    DRAWER_SCROLLBAR_THUMB_HOVER AS _UNSIGNED LONG ' Drawer scrollbar thumb hover
    DRAWER_MINI_PALETTE_BORDER AS _UNSIGNED LONG ' Mini palette cell border
    DRAWER_MINI_PALETTE_PAGE_BTN_BG AS _UNSIGNED LONG ' Mini palette page button bg
    DRAWER_MINI_PALETTE_PAGE_BTN_BORDER AS _UNSIGNED LONG ' Mini palette page button border
    DRAWER_MINI_PALETTE_PAGE_BTN_FG AS _UNSIGNED LONG ' Mini palette page button fg
    DRAWER_MINI_PALETTE_PAGE_BTN_HOVER_BG AS _UNSIGNED LONG ' Mini palette page button hover bg
    DRAWER_LABEL_FG        AS _UNSIGNED LONG ' Drawer label text
    DRAWER_LABEL_DIM_FG    AS _UNSIGNED LONG ' Drawer dim label text
    BINS_BG_COLOR          AS _UNSIGNED LONG ' Background behind the entire bins section
    BINS_BRUSH_WIDTH       AS INTEGER        ' Brush bin width in unscaled pixels
    BINS_BRUSH_HEIGHT      AS INTEGER        ' Brush bin height in unscaled pixels
    BINS_WIDE_WIDTH        AS INTEGER        ' Wide bin width in unscaled pixels
    BINS_WIDE_HEIGHT       AS INTEGER        ' Wide bin height in unscaled pixels
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
    LAYER_PANEL_btn_drag_delete   AS _UNSIGNED LONG  ' Drag-over Delete button highlight (RGBA)
    LAYER_PANEL_btn_drag_new      AS _UNSIGNED LONG  ' Drag-over New Layer button highlight (RGBA)
    ' --- Transform overlay frame ---
    TRANSFORM_FRAME_COLOR        AS _UNSIGNED LONG  ' Quad outline color (RGBA)
    TRANSFORM_FRAME_HANDLE_COLOR AS _UNSIGNED LONG  ' Unselected handle fill color (RGBA)
    TRANSFORM_FRAME_HANDLE_SIZE  AS INTEGER         ' Handle half-size in screen pixels (draw + hit test)
    ' --- Dialog chrome ---
    DIALOG_bg                 AS _UNSIGNED LONG  ' Dialog background fill
    DIALOG_border_outer       AS _UNSIGNED LONG  ' Dialog outer border
    DIALOG_border_inner       AS _UNSIGNED LONG  ' Dialog inner border / dividers
    DIALOG_title_bg           AS _UNSIGNED LONG  ' Dialog title bar background
    DIALOG_title_hover_bg     AS _UNSIGNED LONG  ' Dialog title bar hover background
    DIALOG_title_drag_bg      AS _UNSIGNED LONG  ' Dialog title bar drag background
    DIALOG_title_fg           AS _UNSIGNED LONG  ' Dialog title text color
    DIALOG_title_grip         AS _UNSIGNED LONG  ' Dialog title grip dot color
    DIALOG_title_grip_active  AS _UNSIGNED LONG  ' Dialog title grip dot color while dragging
    DIALOG_button_fg          AS _UNSIGNED LONG  ' Dialog button label color
    DIALOG_toggle_sel_bg      AS _UNSIGNED LONG  ' Selected toggle background
    DIALOG_toggle_sel_fg      AS _UNSIGNED LONG  ' Selected toggle text
    DIALOG_toggle_sel_border  AS _UNSIGNED LONG  ' Selected toggle border
    DIALOG_toggle_bg          AS _UNSIGNED LONG  ' Unselected toggle background
    DIALOG_toggle_fg          AS _UNSIGNED LONG  ' Unselected toggle text
    DIALOG_toggle_border      AS _UNSIGNED LONG  ' Unselected toggle border
    DIALOG_label_fg           AS _UNSIGNED LONG  ' Dialog label text color
    DIALOG_slider_track_bg    AS _UNSIGNED LONG  ' Dialog slider track background
    DIALOG_slider_track_border AS _UNSIGNED LONG ' Dialog slider track border
    DIALOG_slider_fill        AS _UNSIGNED LONG  ' Dialog slider fill
    DIALOG_slider_value_fg    AS _UNSIGNED LONG  ' Dialog slider value text color
    DIALOG_preview_bg         AS _UNSIGNED LONG  ' Dialog preview pane background
    DIALOG_preview_split      AS _UNSIGNED LONG  ' Dialog preview split line / handle
    DIALOG_preview_label_fg   AS _UNSIGNED LONG  ' Dialog preview ORIG/ADJ labels
    DIALOG_title_height       AS INTEGER         ' Dialog title bar bottom Y
    DIALOG_slider_height      AS INTEGER         ' Dialog slider track height
    DIALOG_preview_handle_size AS INTEGER        ' Dialog preview split handle half-size
    DIALOG_font_size          AS INTEGER         ' Font point size for dialogs (default 8)
    ' --- Command palette ---
    CMD_PALETTE_width_ratio      AS SINGLE          ' Palette width as a fraction of screen width
    CMD_PALETTE_min_width        AS INTEGER         ' Palette minimum width
    CMD_PALETTE_max_width        AS INTEGER         ' Palette maximum width
    CMD_PALETTE_top              AS INTEGER         ' Palette top Y position
    CMD_PALETTE_frame_outer      AS _UNSIGNED LONG  ' Palette outer frame color
    CMD_PALETTE_frame_mid        AS _UNSIGNED LONG  ' Palette middle frame color
    CMD_PALETTE_bg               AS _UNSIGNED LONG  ' Palette background color
    CMD_PALETTE_header_fg        AS _UNSIGNED LONG  ' Palette header text color
    CMD_PALETTE_hint_fg          AS _UNSIGNED LONG  ' Palette hint text color
    CMD_PALETTE_search_bg        AS _UNSIGNED LONG  ' Palette search box background
    CMD_PALETTE_search_border    AS _UNSIGNED LONG  ' Palette search box border
    CMD_PALETTE_search_fg        AS _UNSIGNED LONG  ' Palette search text
    CMD_PALETTE_search_placeholder_fg AS _UNSIGNED LONG ' Palette search placeholder text
    CMD_PALETTE_cursor_fg        AS _UNSIGNED LONG  ' Palette search cursor
    CMD_PALETTE_hover_bg         AS _UNSIGNED LONG  ' Palette hovered row background
    CMD_PALETTE_category_fg      AS _UNSIGNED LONG  ' Palette category text
    CMD_PALETTE_name_fg          AS _UNSIGNED LONG  ' Palette command name text
    CMD_PALETTE_hotkey_fg        AS _UNSIGNED LONG  ' Palette hotkey text
    CMD_PALETTE_scroll_fg        AS _UNSIGNED LONG  ' Palette scroll summary text
    ' --- Palette strip / palette menu ---
    PALETTE_STRIP_bg             AS _UNSIGNED LONG  ' Palette strip background
    PALETTE_STRIP_fg             AS _UNSIGNED LONG  ' Palette strip text color
    PALETTE_STRIP_arrow_fg       AS _UNSIGNED LONG  ' Palette strip arrow color
    PALETTE_STRIP_hover_fg       AS _UNSIGNED LONG  ' Palette strip hover text/arrow color
    PALETTE_STRIP_separator      AS _UNSIGNED LONG  ' Palette strip separator line
    PALETTE_STRIP_button_hover_bg AS _UNSIGNED LONG ' Palette strip hover background for buttons
    PALETTE_STRIP_sel_border_outer AS _UNSIGNED LONG   ' Selected palette swatch outer border
    PALETTE_STRIP_sel_border_inner AS _UNSIGNED LONG   ' Selected palette swatch inner border
    PALETTE_STRIP_inact_border_outer AS _UNSIGNED LONG ' Inactive palette swatch outer border
    PALETTE_STRIP_inact_border_inner AS _UNSIGNED LONG ' Inactive palette swatch inner border
    PALETTE_MENU_bg              AS _UNSIGNED LONG  ' Palette menu background
    PALETTE_MENU_fg              AS _UNSIGNED LONG  ' Palette menu text
    PALETTE_MENU_hover_bg        AS _UNSIGNED LONG  ' Palette menu hover background
    PALETTE_MENU_selected_bg     AS _UNSIGNED LONG  ' Palette menu selected/current background
    PALETTE_MENU_border          AS _UNSIGNED LONG  ' Palette menu border
    PALETTE_MENU_current_fg      AS _UNSIGNED LONG  ' Palette menu current item text
    PALETTE_MENU_scroll_fg       AS _UNSIGNED LONG  ' Palette menu scroll indicator text
    PALETTE_MENU_item_height     AS INTEGER         ' Palette menu item height
    ' --- Screen overlays ---
    ZOOM_BOX_fill                AS _UNSIGNED LONG  ' Zoom drag fill overlay
    ZOOM_BOX_border              AS _UNSIGNED LONG  ' Zoom drag inner border
    ZOOM_BOX_outer_border        AS _UNSIGNED LONG  ' Zoom drag outer border
    TOOL_PREVIEW_transparent_fg  AS _UNSIGNED LONG  ' Tool preview color when paint is transparent
    TOOL_PREVIEW_transparent_outline AS _UNSIGNED LONG ' Tool preview outline when paint is transparent
    CANVAS_border                AS _UNSIGNED LONG  ' Canvas border color
    ' --- Preview Window ---
    PREVIEW_bg                   AS _UNSIGNED LONG  ' Window background fill
    PREVIEW_border               AS _UNSIGNED LONG  ' Outer border/stroke color
    PREVIEW_title_bg             AS _UNSIGNED LONG  ' Title bar background (normal)
    PREVIEW_title_hover_bg       AS _UNSIGNED LONG  ' Title bar background (hovered)
    PREVIEW_title_drag_bg        AS _UNSIGNED LONG  ' Title bar background (dragging)
    PREVIEW_title_fg             AS _UNSIGNED LONG  ' Title bar text color
    PREVIEW_close_fg             AS _UNSIGNED LONG  ' X button foreground color
    PREVIEW_close_hover_bg       AS _UNSIGNED LONG  ' X button hover background
    PREVIEW_minimize_fg          AS _UNSIGNED LONG  ' _ button foreground color
    PREVIEW_minimize_hover_bg    AS _UNSIGNED LONG  ' _ button hover background
    PREVIEW_checkbox_fg          AS _UNSIGNED LONG  ' Checkbox text/check color
    PREVIEW_checkbox_bg          AS _UNSIGNED LONG  ' Checkbox box fill
    PREVIEW_checkbox_border      AS _UNSIGNED LONG  ' Checkbox box border
    PREVIEW_resize_handle_fg     AS _UNSIGNED LONG  ' Resize handle dot/line color
    PREVIEW_content_border       AS _UNSIGNED LONG  ' 1px border around the preview image area
    PREVIEW_center_dot_color     AS _UNSIGNED LONG  ' Center tracking dot color in follow mode
    PREVIEW_title_height         AS INTEGER         ' Title bar height in pixels
    PREVIEW_border_width         AS INTEGER         ' Outer border stroke width
    PREVIEW_resize_handle_size   AS INTEGER         ' Resize handle hit area in pixels
    PREVIEW_button_width         AS INTEGER         ' X and _ button width
    PREVIEW_button_height        AS INTEGER         ' X and _ button height
    PREVIEW_checkbox_size        AS INTEGER         ' Checkbox square size
    PREVIEW_padding              AS INTEGER         ' Internal padding around content
    PREVIEW_initial_padding      AS INTEGER         ' Padding from screen edges on first open
    PREVIEW_font                 AS STRING          ' Font filename (empty = global fallback)
    PREVIEW_font_size            AS INTEGER         ' Font point size
    ' --- Fonts ---
    GLOBAL_FONT_FILE       AS STRING          ' Primary UI font filename (e.g. Tiny5-Regular.ttf)
    GLOBAL_FONT_SIZE       AS INTEGER         ' Primary UI font size in points/pixels
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
    MUSIC_FILE           AS STRING          ' Filename for background music (IT/XM/MOD/S3M; empty=none)
    ' --- Lospec dialog ---
    LOSPEC_SWATCH_COLS       AS INTEGER         ' Lospec preview swatch columns per row (default 16)
    ' --- Lospec dialog colors ---
    LOSPEC_status_error_fg   AS _UNSIGNED LONG
    LOSPEC_status_ok_fg      AS _UNSIGNED LONG
    LOSPEC_status_info_fg    AS _UNSIGNED LONG
    LOSPEC_search_bg         AS _UNSIGNED LONG
    LOSPEC_search_border     AS _UNSIGNED LONG
    LOSPEC_search_cursor     AS _UNSIGNED LONG
    LOSPEC_col_header_fg     AS _UNSIGNED LONG
    LOSPEC_col_divider       AS _UNSIGNED LONG
    LOSPEC_result_sel_bg     AS _UNSIGNED LONG
    LOSPEC_result_hover_bg   AS _UNSIGNED LONG
    LOSPEC_result_fg         AS _UNSIGNED LONG
    LOSPEC_result_count_fg   AS _UNSIGNED LONG
    LOSPEC_batch_hover_bg    AS _UNSIGNED LONG
    LOSPEC_count_fg          AS _UNSIGNED LONG
    LOSPEC_preview_panel_bg  AS _UNSIGNED LONG
    LOSPEC_preview_name_fg   AS _UNSIGNED LONG
    LOSPEC_preview_author_fg AS _UNSIGNED LONG
    LOSPEC_preview_link_fg   AS _UNSIGNED LONG
    LOSPEC_preview_link_hov  AS _UNSIGNED LONG
    LOSPEC_tooltip_sep       AS _UNSIGNED LONG
    LOSPEC_tooltip_bg        AS _UNSIGNED LONG
    LOSPEC_tooltip_fg        AS _UNSIGNED LONG
    LOSPEC_tooltip_hint_fg   AS _UNSIGNED LONG
    LOSPEC_empty_fg          AS _UNSIGNED LONG
    LOSPEC_btn_dl_bg         AS _UNSIGNED LONG
    LOSPEC_btn_dl_hover      AS _UNSIGNED LONG
    LOSPEC_btn_dl_border     AS _UNSIGNED LONG
    LOSPEC_btn_close_bg      AS _UNSIGNED LONG
    LOSPEC_btn_close_hover   AS _UNSIGNED LONG
    LOSPEC_btn_close_border  AS _UNSIGNED LONG
    LOSPEC_checkbox_border   AS _UNSIGNED LONG
    LOSPEC_checkbox_fill     AS _UNSIGNED LONG
    LOSPEC_checkbox_dl_fill  AS _UNSIGNED LONG  ' Downloaded-state checkbox fill (green tint)
    LOSPEC_downloaded_fg     AS _UNSIGNED LONG  ' Download date text in results list
    PALETTE_MENU_SEP_fg      AS _UNSIGNED LONG  ' Palette menu separator label text color
    PALETTE_MENU_SEP_bg      AS _UNSIGNED LONG  ' Palette menu separator label background box color
    ' Edit Bar
    EDIT_BAR_LEFT_BORDER_COLOR  AS _UNSIGNED LONG
    EDIT_BAR_RIGHT_BORDER_COLOR AS _UNSIGNED LONG
    EDIT_BAR_LEFT_BORDER_WIDTH  AS INTEGER
    EDIT_BAR_RIGHT_BORDER_WIDTH AS INTEGER
    EDIT_BAR_WIDTH              AS INTEGER
    EDIT_BAR_ICON_PADDING       AS INTEGER
    EDIT_BAR_BG_COLOR           AS _UNSIGNED LONG
    EDIT_BAR_ICON_MOUSE_OUTLINE_COLOR AS _UNSIGNED LONG
    EDIT_BAR_DIVIDER_VERT_MARGIN AS INTEGER
    EDIT_BAR_ICON_UNDO          AS STRING * 64
    EDIT_BAR_ICON_REDO          AS STRING * 64
    EDIT_BAR_ICON_CUT           AS STRING * 64
    EDIT_BAR_ICON_COPY          AS STRING * 64
    EDIT_BAR_ICON_COPY_MERGED   AS STRING * 64
    EDIT_BAR_ICON_PASTE         AS STRING * 64
    EDIT_BAR_ICON_PASTE_IN_PLACE AS STRING * 64
    EDIT_BAR_ICON_CUT_TO_LAYER  AS STRING * 64
    EDIT_BAR_ICON_COPY_TO_LAYER AS STRING * 64
    EDIT_BAR_ICON_CLEAR         AS STRING * 64
    EDIT_BAR_ICON_FILL_WITH_FG  AS STRING * 64
    EDIT_BAR_ICON_FILL_WITH_BG  AS STRING * 64
    EDIT_BAR_ICON_STROKE_SELECTION AS STRING * 64
    EDIT_BAR_ICON_FLIP_HORIZONTAL AS STRING * 64
    EDIT_BAR_ICON_FLIP_VERTICAL AS STRING * 64
    EDIT_BAR_ICON_SCALE_DOWN    AS STRING * 64
    EDIT_BAR_ICON_SCALE_UP      AS STRING * 64
    EDIT_BAR_ICON_ROTATE_CW     AS STRING * 64
    EDIT_BAR_ICON_ROTATE_CCW    AS STRING * 64
END TYPE

' Runtime theme loader — populates THEME from ASSETS/THEMES/{CFG.THEME$}/THEME.CFG
DECLARE SUB THEME_load ()
DECLARE FUNCTION THEME_parse_rgba~& (val$)
DECLARE FUNCTION THEME_font_path$ (filename AS STRING)

DIM SHARED THEME AS DRAW_THEME
DIM SHARED PALETTE_SEP_LOSPEC_LBL$   ' Section header label: Lospec downloaded palettes
DIM SHARED PALETTE_SEP_CREATED_LBL$  ' Section header label: created palettes
