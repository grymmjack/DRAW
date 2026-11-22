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
    STATUS_bg                             AS INTEGER        ' Status bar bg palette color index (0-255)
    STATUS_fg                             AS INTEGER        ' Status bar fg palette color index (0-255)
    STATUS_height                         AS INTEGER        ' Status bar height in pixels
    STATUS_bg_color                       AS _UNSIGNED LONG ' Status bar background color (RGBA)
    STATUS_fg_color                       AS _UNSIGNED LONG ' Status bar foreground color (RGBA)
    STATUS_swatch_fg_outline              AS _UNSIGNED LONG ' Foreground swatch outline color
    STATUS_swatch_bg_outline              AS _UNSIGNED LONG ' Background swatch outline color
    STATUS_swatch_transparent_bg          AS _UNSIGNED LONG ' Transparent swatch fill color
    STATUS_swatch_transparent_diagonal    AS _UNSIGNED LONG ' Transparent swatch diagonal slash
    STATUS_swatch_transparent_border      AS _UNSIGNED LONG ' Transparent swatch border color
    STATUS_swatch_active_outer            AS _UNSIGNED LONG ' Active transparent swatch outer border
    STATUS_swatch_active_inner            AS _UNSIGNED LONG ' Active transparent swatch inner border
    CROSSHAIR_color_fg                    AS _UNSIGNED LONG ' Crosshair line color (RGBA)
    CROSSHAIR_opacity                     AS INTEGER        ' Crosshair line opacity (0-255)
    CROSSHAIR_font                        AS STRING         ' Crosshair coordinate font filename override
    CROSSHAIR_font_size                   AS INTEGER        ' Crosshair coordinate font size in pixels
    CROSSHAIR_font_fg                     AS _UNSIGNED LONG ' Crosshair coordinate text color (RGBA)
    CROSSHAIR_font_stroke_fg              AS _UNSIGNED LONG ' Crosshair coordinate outline color (RGBA)
    CROSSHAIR_font_stroke_width           AS INTEGER        ' Crosshair coordinate outline width in pixels
    CROSSHAIR_font_offset_x               AS INTEGER        ' Crosshair coordinate text X offset from cursor
    CROSSHAIR_font_offset_y               AS INTEGER        ' Crosshair coordinate text Y offset from cursor
    CROSSHAIR_pattern                     AS INTEGER        ' Crosshair line pattern (16 bit &B>inary)
    CROSSHAIR_outline_fg                  AS _UNSIGNED LONG ' Crosshair outline stroke color (RGBA)
    CROSSHAIR_outline_opacity             AS INTEGER        ' Crosshair outline stroke opacity (0-255)
    CROSSHAIR_outline_width               AS INTEGER        ' Crosshair outline stroke width in pixels
    PICKER_LOUPE_zoom_level               AS INTEGER        ' Loupe zoom factor
    PICKER_LOUPE_rect_x_offset            AS INTEGER        ' Loupe X offset from mouse in screen pixels
    PICKER_LOUPE_rect_y_offset            AS INTEGER        ' Loupe Y offset from mouse in screen pixels
    PICKER_LOUPE_rect_width               AS INTEGER        ' Loupe rectangle width in screen pixels
    PICKER_LOUPE_rect_height              AS INTEGER        ' Loupe rectangle height in screen pixels
    PICKER_LOUPE_rgba_x                   AS INTEGER        ' RGB text X offset relative to loupe rectangle
    PICKER_LOUPE_rgba_y                   AS INTEGER        ' RGB text Y offset relative to loupe rectangle
    PICKER_LOUPE_font                     AS STRING         ' Loupe font filename override
    PICKER_LOUPE_font_size                AS INTEGER        ' Loupe font size in pixels
    PICKER_LOUPE_font_fg                  AS _UNSIGNED LONG ' Loupe label foreground color
    PICKER_LOUPE_font_bg                  AS _UNSIGNED LONG ' Loupe label background / panel fill color
    PICKER_LOUPE_font_stroke_fg           AS _UNSIGNED LONG ' Loupe label outline color
    PICKER_LOUPE_font_stroke_width        AS INTEGER        ' Loupe label outline width in pixels
    PICKER_LOUPE_rect_stroke_fg           AS _UNSIGNED LONG ' Loupe border color
    PICKER_LOUPE_rect_stroke_width        AS INTEGER        ' Loupe border width in pixels
    PICKER_LOUPE_pixel_pickup_color       AS _UNSIGNED LONG ' Loupe sampled-pixel marker color
    GRID_color_fg                         AS _UNSIGNED LONG ' Grid foreground color (RGBA)
    GRID_opacity                          AS INTEGER        ' Grid line opacity (0-255, default 38 ~15%)
    GRID_size_x                           AS INTEGER        ' Grid cell width in pixels (default 10)
    GRID_size_y                           AS INTEGER        ' Grid cell height in pixels (default 10)
    TRANSPARENCY_check_size_x             AS INTEGER        ' Checkerboard square width (default 8)
    TRANSPARENCY_check_size_y             AS INTEGER        ' Checkerboard square height (default 8)
    TOOLBAR_x                             AS STRING         ' Toolbar X position "L | R | n" (n = any #)
    TOOLBAR_y                             AS STRING         ' Toolbar Y position "T | B | n" (n = any #)
    TOOLBAR_bg                            AS _UNSIGNED LONG ' Toolbar background color (RGB32)
    TOOLBAR_border_fg                     AS _UNSIGNED LONG ' Toolbar border color (RGB32)
    TOOLBAR_btn_overlay                   AS _UNSIGNED LONG ' Active button dark overlay (RGBA)
    TOOLBAR_btn_stroke                    AS _UNSIGNED LONG ' Active button border stroke (RGBA)
    DRAWER_PANEL_PAD_X                    AS INTEGER        ' Drawer panel inner horizontal padding
    DRAWER_PANEL_PAD_Y                    AS INTEGER        ' Drawer panel inner vertical padding
    DRAWER_PANEL_GAP_Y                    AS INTEGER        ' Shared vertical gap inside drawer panel
    DRAWER_BIN_WIDTH                      AS INTEGER        ' Bin width in unscaled pixels
    DRAWER_BIN_HEIGHT                     AS INTEGER        ' Bin height in unscaled pixels
    DRAWER_BIN_GAP_X                      AS INTEGER        ' Horizontal gap between bins
    DRAWER_BIN_GAP_Y                      AS INTEGER        ' Vertical gap between bins
    DRAWER_BIN_PREVIEW_PAD                AS INTEGER        ' Preview inset inside each bin
    DRAWER_SCROLLBAR_WIDTH                AS INTEGER        ' Drawer scrollbar width
    DRAWER_SCROLLBAR_MIN_THUMB_H          AS INTEGER        ' Minimum drawer scrollbar thumb height
    DRAWER_MINI_PALETTE_COLS              AS INTEGER        ' Mini palette column count
    DRAWER_MINI_PALETTE_ROWS              AS INTEGER        ' Mini palette row count
    DRAWER_MINI_PALETTE_CELL_W            AS INTEGER        ' Mini palette cell width
    DRAWER_MINI_PALETTE_CELL_H            AS INTEGER        ' Mini palette cell height
    DRAWER_MINI_PALETTE_GAP_X             AS INTEGER        ' Mini palette horizontal gap
    DRAWER_MINI_PALETTE_GAP_Y             AS INTEGER        ' Mini palette vertical gap
    DRAWER_MINI_PALETTE_PAGE_BTN_W        AS INTEGER        ' Mini palette page button width
    DRAWER_MINI_PALETTE_PAGE_BTN_H        AS INTEGER        ' Mini palette page button height
    DRAWER_PANEL_BG                       AS _UNSIGNED LONG ' Drawer panel background
    DRAWER_PANEL_BORDER                   AS _UNSIGNED LONG ' Drawer panel border
    DRAWER_PANEL_ACCENT                   AS _UNSIGNED LONG ' Drawer panel accent line
    DRAWER_BIN_BG                         AS _UNSIGNED LONG ' Filled bin background
    DRAWER_BIN_BORDER                     AS _UNSIGNED LONG ' Filled bin border
    DRAWER_BIN_HOVER_BG                   AS _UNSIGNED LONG ' Hovered bin background
    DRAWER_BIN_HOVER_BORDER               AS _UNSIGNED LONG ' Hovered bin border
    DRAWER_BIN_SELECTED_BG                AS _UNSIGNED LONG ' Selected bin background
    DRAWER_BIN_SELECTED_BORDER            AS _UNSIGNED LONG ' Selected bin border
    DRAWER_BIN_SELECTED_BORDER_BRUSH      AS _UNSIGNED LONG ' Selected brush bin border
    DRAWER_BIN_SELECTED_BORDER_PATTERN    AS _UNSIGNED LONG ' Selected pattern bin border
    DRAWER_BIN_SELECTED_BORDER_GRADIENT   AS _UNSIGNED LONG ' Selected gradient bin border
    DRAWER_BIN_EMPTY_BG                   AS _UNSIGNED LONG ' Empty bin background
    DRAWER_BIN_EMPTY_BORDER               AS _UNSIGNED LONG ' Empty bin border
    DRAWER_BIN_DISABLED_FG                AS _UNSIGNED LONG ' Empty/disabled bin indicator color
    DRAWER_BIN_DRAG_SWAP_BORDER           AS _UNSIGNED LONG ' Drag swap mode drop target border
    DRAWER_BIN_DRAG_INSERT_LINE           AS _UNSIGNED LONG ' Drag insert mode edge line
    DRAWER_BIN_DRAG_SOURCE_FILL           AS _UNSIGNED LONG ' Drag source slot dim overlay
    DRAWER_BIN_1BIT_SIGIL_BORDER          AS _UNSIGNED LONG ' 1-bit sigil badge border color
    DRAWER_BIN_1BIT_SIGIL_FG              AS _UNSIGNED LONG ' 1-bit sigil badge text color
    DRAWER_BIN_1BIT_SIGIL_BG              AS _UNSIGNED LONG ' 1-bit sigil badge background color
    DRAWER_BIN_1BIT_SIGIL_PAD             AS INTEGER        ' 1-bit sigil badge inner padding (px)
    DRAWER_BRUSH_CHECKER_DARK             AS _UNSIGNED LONG ' Brush bin checker dark color
    DRAWER_BRUSH_CHECKER_LIGHT            AS _UNSIGNED LONG ' Brush bin checker light color
    DRAWER_SCROLLBAR_TRACK                AS _UNSIGNED LONG ' Drawer scrollbar track
    DRAWER_SCROLLBAR_THUMB                AS _UNSIGNED LONG ' Drawer scrollbar thumb
    DRAWER_SCROLLBAR_THUMB_HOVER          AS _UNSIGNED LONG ' Drawer scrollbar thumb hover
    DRAWER_MINI_PALETTE_BORDER            AS _UNSIGNED LONG ' Mini palette cell border
    DRAWER_MINI_PALETTE_PAGE_BTN_BG       AS _UNSIGNED LONG ' Mini palette page button bg
    DRAWER_MINI_PALETTE_PAGE_BTN_BORDER   AS _UNSIGNED LONG ' Mini palette page button border
    DRAWER_MINI_PALETTE_PAGE_BTN_FG       AS _UNSIGNED LONG ' Mini palette page button fg
    DRAWER_MINI_PALETTE_PAGE_BTN_HOVER_BG AS _UNSIGNED LONG ' Mini palette page button hover bg
    DRAWER_LABEL_FG                       AS _UNSIGNED LONG ' Drawer label text
    DRAWER_LABEL_DIM_FG                   AS _UNSIGNED LONG ' Drawer dim label text
    BINS_BG_COLOR                         AS _UNSIGNED LONG ' Background behind the entire bins section
    BINS_BRUSH_WIDTH                      AS INTEGER        ' Brush bin width in unscaled pixels
    BINS_BRUSH_HEIGHT                     AS INTEGER        ' Brush bin height in unscaled pixels
    BINS_WIDE_WIDTH                       AS INTEGER        ' Wide bin width in unscaled pixels
    BINS_WIDE_HEIGHT                      AS INTEGER        ' Wide bin height in unscaled pixels
    COLOR_CHIP_outline                    AS _UNSIGNED LONG ' Color chip outline color (RGBA)
    COLOR_CHIP_outline_alt                AS _UNSIGNED LONG ' Color chip outline when color matches outline (RGBA)
    PIXEL_GRID_color1                     AS _UNSIGNED LONG ' Pixel grid checker color 1 (RGBA)
    PIXEL_GRID_color2                     AS _UNSIGNED LONG ' Pixel grid checker color 2 (RGBA)
    PIXEL_GRID_color_fg                   AS _UNSIGNED LONG ' Pixel grid line color (RGB, opacity separate)
    PIXEL_GRID_opacity                    AS INTEGER        ' Pixel grid line opacity (0-255, default 64)
    GRID_angle                            AS SINGLE         ' Grid rotation angle in degrees (default 0)
    CROSSHAIR_angle                       AS SINGLE         ' Crosshair rotation angle in degrees (default 0)
    SYMMETRY_guide_fg                     AS _UNSIGNED LONG ' Symmetry guide line color (RGBA)
    SYMMETRY_center_fg                    AS _UNSIGNED LONG ' Symmetry center crosshair color (RGBA)
    ' Menu bar theme colors
    MENU_BAR_bg                           AS _UNSIGNED LONG ' Menu bar background color
    MENU_BAR_fg                           AS _UNSIGNED LONG ' Menu bar foreground (text) color
    MENU_BAR_border                       AS _UNSIGNED LONG ' Menu bar border color
    MENU_BAR_divider                      AS _UNSIGNED LONG ' Menu bar divider color
    MENU_BAR_sel_bg                       AS _UNSIGNED LONG ' Menu bar selected item bg
    MENU_BAR_sel_fg                       AS _UNSIGNED LONG ' Menu bar selected item fg
    MENU_BAR_disabled_fg                  AS _UNSIGNED LONG ' Menu bar disabled item text
    MENU_SUB_bg                           AS _UNSIGNED LONG ' Submenu background color
    MENU_SUB_fg                           AS _UNSIGNED LONG ' Submenu foreground (text) color
    MENU_SUB_border                       AS _UNSIGNED LONG ' Submenu border color
    MENU_SUB_divider                      AS _UNSIGNED LONG ' Submenu divider color
    MENU_SUB_sel_bg                       AS _UNSIGNED LONG ' Submenu selected item bg
    MENU_SUB_disabled_fg                  AS _UNSIGNED LONG ' Submenu disabled item text
    MENU_SUB_sel_fg                       AS _UNSIGNED LONG ' Submenu selected item fg
    ' --- Layer panel ---
    LAYER_PANEL_header_height             AS INTEGER        ' Header bar height in pixels
    LAYER_PANEL_btn_bar_height            AS INTEGER        ' Button bar height in pixels
    LAYER_PANEL_bg                        AS _UNSIGNED LONG ' Panel background
    LAYER_PANEL_border                    AS _UNSIGNED LONG ' Right border
    LAYER_PANEL_header_bg                 AS _UNSIGNED LONG ' Header background
    LAYER_PANEL_header_fg                 AS _UNSIGNED LONG ' Header title text
    LAYER_PANEL_header_fg_dim             AS _UNSIGNED LONG ' Header layer count (dimmed)
    LAYER_PANEL_row_bg                    AS _UNSIGNED LONG ' Row normal background
    LAYER_PANEL_row_hover_bg              AS _UNSIGNED LONG ' Row hover background
    LAYER_PANEL_row_sel_bg                AS _UNSIGNED LONG ' Row selected background
    LAYER_PANEL_row_fg                    AS _UNSIGNED LONG ' Layer name text
    LAYER_PANEL_row_fg_blend              AS _UNSIGNED LONG ' Blend mode short text
    LAYER_PANEL_opacity_bar_bg            AS _UNSIGNED LONG ' Opacity bar background
    LAYER_PANEL_opacity_bar_fg            AS _UNSIGNED LONG ' Opacity bar fill
    LAYER_PANEL_scrollbar_track           AS _UNSIGNED LONG ' Scrollbar track
    LAYER_PANEL_scrollbar_thumb           AS _UNSIGNED LONG ' Scrollbar thumb
    LAYER_PANEL_sep                       AS _UNSIGNED LONG ' Separator line above button bar
    LAYER_PANEL_btn_bar_bg                AS _UNSIGNED LONG ' Button bar background
    LAYER_PANEL_drop_line                 AS _UNSIGNED LONG ' Drop target indicator (primary)
    LAYER_PANEL_drop_line2                AS _UNSIGNED LONG ' Drop target indicator (shadow/secondary)
    LAYER_PANEL_drag_fill                 AS _UNSIGNED LONG ' Drag preview row fill (RGBA)
    LAYER_PANEL_drag_border               AS _UNSIGNED LONG ' Drag preview row border
    LAYER_PANEL_row_master_bg             AS _UNSIGNED LONG ' Master (CURRENT) layer row background
    LAYER_PANEL_row_multi_sel_bg          AS _UNSIGNED LONG ' Multi-selected (secondary) row background
    LAYER_PANEL_row_master_accent         AS _UNSIGNED LONG ' Left-edge accent bar color for master row
    LAYER_PANEL_btn_drag_delete           AS _UNSIGNED LONG ' Drag-over Delete button highlight (RGBA)
    LAYER_PANEL_btn_drag_new              AS _UNSIGNED LONG ' Drag-over New Layer button highlight (RGBA)
    LAYER_PANEL_btn_drag_group            AS _UNSIGNED LONG ' Drag-over New Group button highlight (RGBA)
    LAYER_PANEL_group_header_bg           AS _UNSIGNED LONG ' Group header row background
    LAYER_PANEL_group_header_fg           AS _UNSIGNED LONG ' Group header name text
    LAYER_PANEL_group_indent              AS INTEGER        ' Child indentation in pixels (per level)
    LAYER_PANEL_group_collapse_fg         AS _UNSIGNED LONG ' Collapse triangle color
    LAYER_PANEL_group_count_fg            AS _UNSIGNED LONG ' A group row's child count (a theme without it: LAYER_PANEL_HEADER_FG_DIM)
    ' --- Transform overlay frame ---
    ' --- Marquee selection handles ---
    MARQUEE_HANDLE_SIZE                   AS INTEGER        ' Marquee corner/edge handle half-size in screen pixels
    ' --- Transform overlay frame ---
    TRANSFORM_FRAME_COLOR                 AS _UNSIGNED LONG ' Quad outline color (RGBA)
    TRANSFORM_FRAME_HANDLE_COLOR          AS _UNSIGNED LONG ' Unselected handle fill color (RGBA)
    TRANSFORM_FRAME_HANDLE_SIZE           AS INTEGER        ' Handle half-size in screen pixels (draw + hit test)
    ' --- Fill adjustment L-handle ---
    FILL_ADJ_CORNER_COLOR                 AS _UNSIGNED LONG ' L-handle corner box color (RGBA)
    FILL_ADJ_CORNER_ACTIVE_COLOR          AS _UNSIGNED LONG ' L-handle corner box active/drag highlight (RGBA)
    FILL_ADJ_ARM_X_COLOR                  AS _UNSIGNED LONG ' L-handle horizontal arm color (RGBA)
    FILL_ADJ_ARM_X_ACTIVE_COLOR           AS _UNSIGNED LONG ' L-handle horizontal arm active (RGBA)
    FILL_ADJ_ARM_Y_COLOR                  AS _UNSIGNED LONG ' L-handle vertical arm color (RGBA)
    FILL_ADJ_ARM_Y_ACTIVE_COLOR           AS _UNSIGNED LONG ' L-handle vertical arm active (RGBA)
    FILL_ADJ_SHADOW_COLOR                 AS _UNSIGNED LONG ' L-handle shadow/outline (RGBA)
    FILL_ADJ_DASH_COLOR1                  AS _UNSIGNED LONG ' Bounding box dash color 1 (RGBA)
    FILL_ADJ_DASH_COLOR2                  AS _UNSIGNED LONG ' Bounding box dash color 2 (RGBA)
    FILL_ADJ_INFO_BG_COLOR                AS _UNSIGNED LONG ' Info text background (RGBA)
    FILL_ADJ_INFO_FG_COLOR                AS _UNSIGNED LONG ' Info text foreground (RGBA)
    FILL_ADJ_HANDLE_SIZE                  AS INTEGER        ' Corner box half-size in screen px (default 7)
    FILL_ADJ_ARM_LENGTH                   AS INTEGER        ' Arm length in screen px (default 40)
    FILL_ADJ_ARM_THICKNESS                AS INTEGER        ' Arm half-thickness in screen px (default 5)
    FILL_ADJ_ROTATE_COLOR                 AS _UNSIGNED LONG ' Rotation handle color (RGBA)
    FILL_ADJ_ROTATE_ACTIVE_COLOR          AS _UNSIGNED LONG ' Rotation handle active/drag (RGBA)
    FILL_ADJ_ROTATE_RADIUS                AS INTEGER        ' Rotation arc radius in screen px (default 28)
    FILL_ADJ_ICON_FILE                    AS STRING * 64    ' PNG widget for L-handle (empty = procedural)
    ' --- Dialog chrome ---
    DIALOG_bg                             AS _UNSIGNED LONG ' Dialog background fill
    DIALOG_border_outer                   AS _UNSIGNED LONG ' Dialog outer border
    DIALOG_border_inner                   AS _UNSIGNED LONG ' Dialog inner border / dividers
    DIALOG_title_bg                       AS _UNSIGNED LONG ' Dialog title bar background
    DIALOG_title_hover_bg                 AS _UNSIGNED LONG ' Dialog title bar hover background
    DIALOG_title_drag_bg                  AS _UNSIGNED LONG ' Dialog title bar drag background
    DIALOG_title_fg                       AS _UNSIGNED LONG ' Dialog title text color
    DIALOG_title_grip                     AS _UNSIGNED LONG ' Dialog title grip dot color
    DIALOG_title_grip_active              AS _UNSIGNED LONG ' Dialog title grip dot color while dragging
    DIALOG_button_fg                      AS _UNSIGNED LONG ' Dialog button label color
    DIALOG_toggle_sel_bg                  AS _UNSIGNED LONG ' Selected toggle background
    DIALOG_toggle_sel_fg                  AS _UNSIGNED LONG ' Selected toggle text
    DIALOG_toggle_sel_border              AS _UNSIGNED LONG ' Selected toggle border
    DIALOG_toggle_bg                      AS _UNSIGNED LONG ' Unselected toggle background
    DIALOG_toggle_fg                      AS _UNSIGNED LONG ' Unselected toggle text
    DIALOG_toggle_border                  AS _UNSIGNED LONG ' Unselected toggle border
    DIALOG_checkbox_bg                    AS _UNSIGNED LONG ' Unchecked checkbox fill (a theme without it: DIALOG_BG)
    DIALOG_button_bg                      AS _UNSIGNED LONG ' Button background (a theme without it: DIALOG_TOGGLE_BG)
    DIALOG_button_hover_bg                AS _UNSIGNED LONG ' Button background under the pointer (a theme without it: DIALOG_TOGGLE_SEL_BG)
    DIALOG_button_border                  AS _UNSIGNED LONG ' Button border (a theme without it: DIALOG_TOGGLE_BORDER)
    DIALOG_button_disabled_fg             AS _UNSIGNED LONG ' Disabled button text (a theme without it: DIALOG_PREVIEW_LABEL_FG)
    DIALOG_button_primary_bg              AS _UNSIGNED LONG ' Primary button background (OK / confirm)
    DIALOG_button_primary_hover_bg        AS _UNSIGNED LONG ' Primary button background under the pointer
    DIALOG_button_primary_border          AS _UNSIGNED LONG ' Primary button border
    DIALOG_button_primary_fg              AS _UNSIGNED LONG ' Primary button text (a theme without it: DIALOG_BUTTON_FG)
    DIALOG_button_cancel_bg               AS _UNSIGNED LONG ' Cancel button background
    DIALOG_button_cancel_hover_bg         AS _UNSIGNED LONG ' Cancel button background under the pointer
    DIALOG_button_cancel_border           AS _UNSIGNED LONG ' Cancel button border
    DIALOG_button_cancel_fg               AS _UNSIGNED LONG ' Cancel button text (a theme without it: DIALOG_BUTTON_FG)
    DIALOG_button_danger_bg               AS _UNSIGNED LONG ' Danger button background (delete)
    DIALOG_button_danger_hover_bg         AS _UNSIGNED LONG ' Danger button background under the pointer
    DIALOG_button_danger_border           AS _UNSIGNED LONG ' Danger button border
    DIALOG_button_danger_fg               AS _UNSIGNED LONG ' Danger button text (a theme without it: DIALOG_BUTTON_FG)
    DIALOG_button_warn_bg                 AS _UNSIGNED LONG ' Warn button background (reset / overwrite)
    DIALOG_button_warn_hover_bg           AS _UNSIGNED LONG ' Warn button background under the pointer
    DIALOG_button_warn_border             AS _UNSIGNED LONG ' Warn button border
    DIALOG_button_warn_fg                 AS _UNSIGNED LONG ' Warn button text (a theme without it: DIALOG_BUTTON_FG)
    DIALOG_button_accent_bg               AS _UNSIGNED LONG ' Accent button background (pick / browse / open)
    DIALOG_button_accent_hover_bg         AS _UNSIGNED LONG ' Accent button background under the pointer
    DIALOG_button_accent_border           AS _UNSIGNED LONG ' Accent button border
    DIALOG_button_accent_fg               AS _UNSIGNED LONG ' Accent button text (a theme without it: DIALOG_BUTTON_FG)
    DIALOG_toggle_hover_bg                AS _UNSIGNED LONG ' Unselected toggle background under the pointer (a theme without it: DIALOG_TITLE_HOVER_BG)
    DIALOG_checkbox_border                AS _UNSIGNED LONG ' Checkbox / radio border (a theme without it: DIALOG_TOGGLE_BORDER)
    DIALOG_checkbox_hover_border          AS _UNSIGNED LONG ' Checkbox / radio border under the pointer (a theme without it: DIALOG_TOGGLE_SEL_BORDER)
    DIALOG_checkbox_checked_bg            AS _UNSIGNED LONG ' Checked checkbox fill / radio dot (a theme without it: DIALOG_TOGGLE_SEL_BG)
    DIALOG_checkbox_mark                  AS _UNSIGNED LONG ' Checkbox check mark (a theme without it: DIALOG_TOGGLE_SEL_FG)
    DIALOG_field_bg                       AS _UNSIGNED LONG ' Field background (a theme without it: DIALOG_SLIDER_TRACK_BG)
    DIALOG_field_border                   AS _UNSIGNED LONG ' Field border (a theme without it: DIALOG_SLIDER_TRACK_BORDER)
    DIALOG_field_fg                       AS _UNSIGNED LONG ' Field text (a theme without it: DIALOG_SLIDER_VALUE_FG)
    DIALOG_field_hint_fg                  AS _UNSIGNED LONG ' Field text for AUTO / OFF / placeholders (a theme without it: DIALOG_TOGGLE_SEL_BG)
    DIALOG_field_hover_bg                 AS _UNSIGNED LONG ' Field background under the pointer (a theme without it: DIALOG_TOGGLE_SEL_BG)
    DIALOG_field_active_bg                AS _UNSIGNED LONG ' Field background while typing / capturing (a theme without it: DIALOG_TOGGLE_SEL_BG)
    DIALOG_field_active_fg                AS _UNSIGNED LONG ' Field text while typing / capturing (a theme without it: DIALOG_TOGGLE_SEL_FG)
    DIALOG_field_active_border            AS _UNSIGNED LONG ' Field border while typing / capturing (a theme without it: DIALOG_TOGGLE_SEL_BORDER)
    DIALOG_list_bg                        AS _UNSIGNED LONG ' List background (a theme without it: DIALOG_BG)
    DIALOG_list_border                    AS _UNSIGNED LONG ' List border (a theme without it: DIALOG_TOGGLE_BORDER)
    DIALOG_list_fg                        AS _UNSIGNED LONG ' List item text (a theme without it: DIALOG_LABEL_FG)
    DIALOG_list_hover_bg                  AS _UNSIGNED LONG ' List item background under the pointer (a theme without it: DIALOG_TITLE_HOVER_BG)
    DIALOG_list_hover_fg                  AS _UNSIGNED LONG ' List item text under the pointer (a theme without it: DIALOG_LABEL_FG)
    DIALOG_list_sel_bg                    AS _UNSIGNED LONG ' Selected list item background (a theme without it: DIALOG_TOGGLE_SEL_BG)
    DIALOG_list_sel_fg                    AS _UNSIGNED LONG ' Selected list item text (a theme without it: DIALOG_TOGGLE_SEL_FG)
    DIALOG_list_header_bg                 AS _UNSIGNED LONG ' List / table column header background (a theme without it: DIALOG_TITLE_BG)
    DIALOG_list_header_fg                 AS _UNSIGNED LONG ' List / table column header text (a theme without it: DIALOG_TITLE_FG)
    DIALOG_tab_fg                         AS _UNSIGNED LONG ' Tab text (a theme without it: DIALOG_LABEL_FG)
    DIALOG_tab_hover_bg                   AS _UNSIGNED LONG ' Tab background under the pointer (a theme without it: DIALOG_TOGGLE_BG)
    DIALOG_tab_hover_fg                   AS _UNSIGNED LONG ' Tab text under the pointer (a theme without it: DIALOG_TOGGLE_FG)
    DIALOG_tab_sel_bg                     AS _UNSIGNED LONG ' Current tab background (a theme without it: DIALOG_TOGGLE_SEL_BG)
    DIALOG_tab_sel_fg                     AS _UNSIGNED LONG ' Current tab text (a theme without it: DIALOG_TOGGLE_SEL_FG)
    DIALOG_section_fg                     AS _UNSIGNED LONG ' Section heading text (a theme without it: DIALOG_TITLE_FG)
    DIALOG_divider                        AS _UNSIGNED LONG ' Divider lines (section rules, tab / bar separators) (a theme without it: DIALOG_BORDER_INNER)
    DIALOG_swatch_border                  AS _UNSIGNED LONG ' Colour swatch border (a theme without it: DIALOG_TOGGLE_BORDER)
    DIALOG_swatch_hover_border            AS _UNSIGNED LONG ' Colour swatch border under the pointer (a theme without it: DIALOG_TOGGLE_SEL_BORDER)
    DIALOG_field_selection_bg             AS _UNSIGNED LONG ' Selected text in a field (a theme without it: DIALOG_TOGGLE_SEL_BG)
    DIALOG_bar_bg                         AS _UNSIGNED LONG ' Footer button bar background (a theme without it: DIALOG_BG)
    DIALOG_tab_bar_bg                     AS _UNSIGNED LONG ' Tab strip background
    DIALOG_scrollbar_track                AS _UNSIGNED LONG ' Scrollbar track
    DIALOG_scrollbar_thumb                AS _UNSIGNED LONG ' Scrollbar thumb
    DIALOG_status_fg                      AS _UNSIGNED LONG ' Status / result message text (a theme without it: DIALOG_TOGGLE_SEL_FG)
    DIALOG_warning_fg                     AS _UNSIGNED LONG ' Warning / error message text
    DIALOG_changed_bg                     AS _UNSIGNED LONG ' Marks a value changed from its default (row stripe, legend) (a theme without it: DIALOG_TOGGLE_SEL_BG)
    DIALOG_changed_fg                     AS _UNSIGNED LONG ' Text of a value changed from its default (a theme without it: DIALOG_TOGGLE_SEL_FG)
    DIALOG_label_fg                       AS _UNSIGNED LONG ' Dialog label text color
    DIALOG_slider_track_bg                AS _UNSIGNED LONG ' Dialog slider track background
    DIALOG_slider_track_border            AS _UNSIGNED LONG ' Dialog slider track border
    DIALOG_slider_fill                    AS _UNSIGNED LONG ' Dialog slider fill
    DIALOG_slider_value_fg                AS _UNSIGNED LONG ' Dialog slider value text color
    DIALOG_preview_bg                     AS _UNSIGNED LONG ' Dialog preview pane background
    DIALOG_preview_split                  AS _UNSIGNED LONG ' Dialog preview split line / handle
    DIALOG_preview_label_fg               AS _UNSIGNED LONG ' Dialog preview ORIG/ADJ labels
    DIALOG_title_height                   AS INTEGER        ' Dialog title bar bottom Y
    DIALOG_slider_height                  AS INTEGER        ' Dialog slider track height
    DIALOG_preview_handle_size            AS INTEGER        ' Dialog preview split handle half-size
    DIALOG_font_size                      AS INTEGER        ' Font point size for dialogs (default 8)
    ' --- Command palette ---
    CMD_PALETTE_width_ratio               AS SINGLE         ' Palette width as a fraction of screen width
    CMD_PALETTE_min_width                 AS INTEGER        ' Palette minimum width
    CMD_PALETTE_max_width                 AS INTEGER        ' Palette maximum width
    CMD_PALETTE_top                       AS INTEGER        ' Palette top Y position
    CMD_PALETTE_frame_outer               AS _UNSIGNED LONG ' Palette outer frame color
    CMD_PALETTE_frame_mid                 AS _UNSIGNED LONG ' Palette middle frame color
    CMD_PALETTE_bg                        AS _UNSIGNED LONG ' Palette background color
    CMD_PALETTE_header_fg                 AS _UNSIGNED LONG ' Palette header text color
    CMD_PALETTE_hint_fg                   AS _UNSIGNED LONG ' Palette hint text color
    CMD_PALETTE_search_bg                 AS _UNSIGNED LONG ' Palette search box background
    CMD_PALETTE_search_border             AS _UNSIGNED LONG ' Palette search box border
    CMD_PALETTE_search_fg                 AS _UNSIGNED LONG ' Palette search text
    CMD_PALETTE_search_placeholder_fg     AS _UNSIGNED LONG ' Palette search placeholder text
    CMD_PALETTE_cursor_fg                 AS _UNSIGNED LONG ' Palette search cursor
    CMD_PALETTE_hover_bg                  AS _UNSIGNED LONG ' Palette hovered row background
    CMD_PALETTE_category_fg               AS _UNSIGNED LONG ' Palette category text
    CMD_PALETTE_name_fg                   AS _UNSIGNED LONG ' Palette command name text
    CMD_PALETTE_hotkey_fg                 AS _UNSIGNED LONG ' Palette hotkey text
    CMD_PALETTE_scroll_fg                 AS _UNSIGNED LONG ' Palette scroll summary text
    ' --- Palette strip / palette menu ---
    PALETTE_STRIP_bg                      AS _UNSIGNED LONG ' Palette strip background
    PALETTE_STRIP_fg                      AS _UNSIGNED LONG ' Palette strip text color
    PALETTE_STRIP_arrow_fg                AS _UNSIGNED LONG ' Palette strip arrow color
    PALETTE_STRIP_hover_fg                AS _UNSIGNED LONG ' Palette strip hover text/arrow color
    PALETTE_STRIP_separator               AS _UNSIGNED LONG ' Palette strip separator line
    PALETTE_STRIP_button_hover_bg         AS _UNSIGNED LONG ' Palette strip hover background for buttons
    PALETTE_STRIP_sel_border_outer        AS _UNSIGNED LONG ' Selected palette swatch outer border
    PALETTE_STRIP_sel_border_inner        AS _UNSIGNED LONG ' Selected palette swatch inner border
    PALETTE_STRIP_inact_border_outer      AS _UNSIGNED LONG ' Inactive palette swatch outer border
    PALETTE_STRIP_inact_border_inner      AS _UNSIGNED LONG ' Inactive palette swatch inner border
    PALETTE_MENU_bg                       AS _UNSIGNED LONG ' Palette menu background
    PALETTE_MENU_fg                       AS _UNSIGNED LONG ' Palette menu text
    PALETTE_MENU_hover_bg                 AS _UNSIGNED LONG ' Palette menu hover background
    PALETTE_MENU_selected_bg              AS _UNSIGNED LONG ' Palette menu selected/current background
    PALETTE_MENU_border                   AS _UNSIGNED LONG ' Palette menu border
    PALETTE_MENU_current_fg               AS _UNSIGNED LONG ' Palette menu current item text
    PALETTE_MENU_scroll_fg                AS _UNSIGNED LONG ' Palette menu scroll indicator text
    PALETTE_MENU_item_height              AS INTEGER        ' Palette menu item height
    ' --- Screen overlays ---
    ZOOM_BOX_fill                         AS _UNSIGNED LONG ' Zoom drag fill overlay
    ZOOM_BOX_border                       AS _UNSIGNED LONG ' Zoom drag inner border
    ZOOM_BOX_outer_border                 AS _UNSIGNED LONG ' Zoom drag outer border
    TOOL_PREVIEW_transparent_fg           AS _UNSIGNED LONG ' Tool preview color when paint is transparent
    TOOL_PREVIEW_transparent_outline      AS _UNSIGNED LONG ' Tool preview outline when paint is transparent
    BEZIER_anchor_color                   AS _UNSIGNED LONG ' Bezier anchor point dot color
    BEZIER_handle_color                   AS _UNSIGNED LONG ' Bezier handle arm and endpoint color
    CANVAS_border                         AS _UNSIGNED LONG ' Canvas border color
    ANIM_FRAME_border                     AS _UNSIGNED LONG ' Animation frame grid: frame cell border
    ANIM_FRAME_spare                      AS _UNSIGNED LONG ' Animation frame grid: spare cell border (past the last frame)
    ANIM_FRAME_current                    AS _UNSIGNED LONG ' Animation frame grid: current frame outline
    ANIM_FRAME_drawing                    AS _UNSIGNED LONG ' Lightbox: the pane a stroke goes into (under the pointer)
    ANIM_FRAME_label_fg                   AS _UNSIGNED LONG ' Animation frame grid: frame number text
    ANIM_FRAME_label_bg                   AS _UNSIGNED LONG ' Animation frame grid: frame number backing
    ' --- Preview Window ---
    PREVIEW_bg                            AS _UNSIGNED LONG ' Window background fill
    PREVIEW_border                        AS _UNSIGNED LONG ' Outer border/stroke color
    PREVIEW_title_bg                      AS _UNSIGNED LONG ' Title bar background (normal)
    PREVIEW_title_hover_bg                AS _UNSIGNED LONG ' Title bar background (hovered)
    PREVIEW_title_drag_bg                 AS _UNSIGNED LONG ' Title bar background (dragging)
    PREVIEW_title_fg                      AS _UNSIGNED LONG ' Title bar text color
    PREVIEW_close_fg                      AS _UNSIGNED LONG ' X button foreground color
    PREVIEW_close_hover_bg                AS _UNSIGNED LONG ' X button hover background
    PREVIEW_minimize_fg                   AS _UNSIGNED LONG ' _ button foreground color
    PREVIEW_minimize_hover_bg             AS _UNSIGNED LONG ' _ button hover background
    PREVIEW_checkbox_fg                   AS _UNSIGNED LONG ' Checkbox text/check color
    PREVIEW_checkbox_bg                   AS _UNSIGNED LONG ' Checkbox box fill
    PREVIEW_checkbox_border               AS _UNSIGNED LONG ' Checkbox box border
    PREVIEW_resize_handle_fg              AS _UNSIGNED LONG ' Resize handle dot/line color
    PREVIEW_content_border                AS _UNSIGNED LONG ' 1px border around the preview image area
    PREVIEW_center_dot_color              AS _UNSIGNED LONG ' Center tracking dot color in follow mode
    PREVIEW_title_height                  AS INTEGER        ' Title bar height in pixels
    PREVIEW_border_width                  AS INTEGER        ' Outer border stroke width
    PREVIEW_resize_handle_size            AS INTEGER        ' Resize handle hit area in pixels
    PREVIEW_button_width                  AS INTEGER        ' X and _ button width
    PREVIEW_button_height                 AS INTEGER        ' X and _ button height
    PREVIEW_checkbox_size                 AS INTEGER        ' Checkbox square size
    PREVIEW_padding                       AS INTEGER        ' Internal padding around content
    PREVIEW_initial_padding               AS INTEGER        ' Padding from screen edges on first open
    PREVIEW_font                          AS STRING         ' Font filename (empty = global fallback)
    PREVIEW_font_size                     AS INTEGER        ' Font point size
    ' --- Color Picker / Mixer ---
    CP_bg                                 AS _UNSIGNED LONG ' Dialog background fill
    CP_border                             AS _UNSIGNED LONG ' Outer border
    CP_title_bg                           AS _UNSIGNED LONG ' Title bar background (normal)
    CP_title_hover_bg                     AS _UNSIGNED LONG ' Title bar background (hovered)
    CP_title_drag_bg                      AS _UNSIGNED LONG ' Title bar background (dragging)
    CP_title_fg                           AS _UNSIGNED LONG ' Title bar text color
    CP_close_fg                           AS _UNSIGNED LONG ' Close X text color
    CP_close_hover_bg                     AS _UNSIGNED LONG ' Close X hover background
    CP_text                               AS _UNSIGNED LONG ' Normal text
    CP_text_bright                        AS _UNSIGNED LONG ' Bright/white text
    CP_text_dim                           AS _UNSIGNED LONG ' Dim/gray text
    CP_button_bg                          AS _UNSIGNED LONG ' Primary button background
    CP_button_hover                       AS _UNSIGNED LONG ' Primary button hover
    CP_button_text                        AS _UNSIGNED LONG ' Primary button text
    CP_button_secondary                   AS _UNSIGNED LONG ' Secondary button background
    CP_button_sec_hover                   AS _UNSIGNED LONG ' Secondary button hover
    CP_button_sec_text                    AS _UNSIGNED LONG ' Secondary button text
    CP_button_focus                       AS _UNSIGNED LONG ' Button focus ring
    CP_button_bar_bg                      AS _UNSIGNED LONG ' Button bar background
    CP_divider                            AS _UNSIGNED LONG ' Section divider line
    CP_slider_bg                          AS _UNSIGNED LONG ' Slider track background
    CP_slider_border                      AS _UNSIGNED LONG ' Slider track border
    CP_overlay                            AS _UNSIGNED LONG ' Modal dimming overlay
    CP_check_a                            AS _UNSIGNED LONG ' Checkerboard color A
    CP_check_b                            AS _UNSIGNED LONG ' Checkerboard color B
    ' --- Panels: one set of keys per kind of control (.claude/instructions/draw-theme-edit.md) ---
    PANEL_bg                              AS _UNSIGNED LONG ' Panel background (a theme without it: CP_BG)
    PANEL_border                          AS _UNSIGNED LONG ' Panel outline (a theme without it: CP_BORDER)
    PANEL_title_bg                        AS _UNSIGNED LONG ' Title bar background (a theme without it: LAYER_PANEL_HEADER_BG)
    PANEL_title_fg                        AS _UNSIGNED LONG ' Title text and the collapse arrow (a theme without it: LAYER_PANEL_HEADER_FG)
    PANEL_title_hint_fg                   AS _UNSIGNED LONG ' Secondary text in a title bar (the Layers count) (a theme without it: LAYER_PANEL_HEADER_FG_DIM)
    PANEL_title_border                    AS _UNSIGNED LONG ' Line under a title bar, floating frame outline (a theme without it: LAYER_PANEL_BORDER)
    PANEL_tab_fg                          AS _UNSIGNED LONG ' Title-bar tab text (a tab not shown) (a theme without it: LAYER_PANEL_HEADER_FG_DIM)
    PANEL_tab_sel_bg                      AS _UNSIGNED LONG ' The shown tab's background (a theme without it: LAYER_PANEL_BG)
    PANEL_tab_sel_fg                      AS _UNSIGNED LONG ' The shown tab's text (a theme without it: LAYER_PANEL_HEADER_FG)
    PANEL_close_fg                        AS _UNSIGNED LONG ' Close cross (a theme without it: CP_CLOSE_HOVER_BG)
    PANEL_close_hover_bg                  AS _UNSIGNED LONG ' Close box under the pointer (a theme without it: CP_CLOSE_HOVER_BG)
    PANEL_close_hover_fg                  AS _UNSIGNED LONG ' Close cross under the pointer (a theme without it: CP_CLOSE_FG)
    PANEL_grip                            AS _UNSIGNED LONG ' Drag grip dots, resize corner (a theme without it: LAYER_PANEL_HEADER_FG)
    PANEL_label_fg                        AS _UNSIGNED LONG ' Labels (a theme without it: CP_TEXT)
    PANEL_value_fg                        AS _UNSIGNED LONG ' Values, the current item, emphasis (a theme without it: CP_TEXT_BRIGHT)
    PANEL_hint_fg                         AS _UNSIGNED LONG ' Hints, units, secondary information (a theme without it: CP_TEXT_DIM)
    PANEL_disabled_fg                     AS _UNSIGNED LONG ' A control that is off: its text and marks (a theme without it: CP_TEXT_DIM)
    PANEL_warning_fg                      AS _UNSIGNED LONG ' Warning text and marks (a theme without it: CP_CLOSE_FG)
    PANEL_section_fg                      AS _UNSIGNED LONG ' Section heading (a disclosure row) (a theme without it: CP_TEXT_DIM)
    PANEL_section_hover_fg                AS _UNSIGNED LONG ' Section heading under the pointer (a theme without it: CP_TEXT)
    PANEL_divider                         AS _UNSIGNED LONG ' Rules between sections and rows (a theme without it: CP_BORDER)
    PANEL_button_bg                       AS _UNSIGNED LONG ' Button background (a theme without it: CP_BUTTON_SECONDARY)
    PANEL_button_fg                       AS _UNSIGNED LONG ' Button text and icon (a theme without it: CP_BUTTON_SEC_TEXT)
    PANEL_button_border                   AS _UNSIGNED LONG ' Button outline (a theme without it: CP_SLIDER_BORDER)
    PANEL_button_hover_bg                 AS _UNSIGNED LONG ' Button under the pointer (a theme without it: CP_BUTTON_SEC_HOVER)
    PANEL_button_hover_fg                 AS _UNSIGNED LONG ' Button text under the pointer (a theme without it: CP_TEXT_BRIGHT)
    PANEL_button_on_bg                    AS _UNSIGNED LONG ' A button that is on (chosen chip, active mode) (a theme without it: CP_BUTTON_BG)
    PANEL_button_on_fg                    AS _UNSIGNED LONG ' Text of a button that is on (a theme without it: CP_BUTTON_TEXT)
    PANEL_button_disabled_bg              AS _UNSIGNED LONG ' A button that does nothing now (its text: PANEL_DISABLED_FG) (a theme without it: CP_SLIDER_BG)
    PANEL_icon_fg                         AS _UNSIGNED LONG ' Bare icon button (a theme without it: CP_TEXT_DIM)
    PANEL_icon_hover_fg                   AS _UNSIGNED LONG ' Bare icon button under the pointer or with its menu open (a theme without it: CP_TEXT_BRIGHT)
    PANEL_checkbox_bg                     AS _UNSIGNED LONG ' Checkbox box (a theme without it: CP_SLIDER_BG)
    PANEL_checkbox_border                 AS _UNSIGNED LONG ' Checkbox outline (a theme without it: CP_SLIDER_BORDER)
    PANEL_checkbox_hover_border           AS _UNSIGNED LONG ' Checkbox outline under the pointer (a theme without it: CP_TEXT)
    PANEL_checkbox_mark                   AS _UNSIGNED LONG ' Check mark (a theme without it: CP_TEXT_BRIGHT)
    PANEL_slider_bg                       AS _UNSIGNED LONG ' Slider track (a theme without it: CP_SLIDER_BG)
    PANEL_slider_border                   AS _UNSIGNED LONG ' Slider track outline (a theme without it: CP_SLIDER_BORDER)
    PANEL_slider_fill                     AS _UNSIGNED LONG ' Slider fill (a value with no colour of its own) (a theme without it: CP_TEXT)
    PANEL_slider_thumb                    AS _UNSIGNED LONG ' Slider thumb (a theme without it: CP_TEXT_BRIGHT)
    PANEL_slider_active_thumb             AS _UNSIGNED LONG ' Slider thumb while it is dragged (a theme without it: ANIM_FRAME_CURRENT)
    PANEL_slider_disabled                 AS _UNSIGNED LONG ' Fill and thumb of a slider that is off (a theme without it: CP_TEXT_DIM)
    PANEL_field_bg                        AS _UNSIGNED LONG ' Field background (a theme without it: CP_SLIDER_BG)
    PANEL_field_border                    AS _UNSIGNED LONG ' Field outline (a theme without it: CP_SLIDER_BORDER)
    PANEL_field_fg                        AS _UNSIGNED LONG ' Field text (a theme without it: CP_TEXT_BRIGHT)
    PANEL_field_active_border             AS _UNSIGNED LONG ' Outline of the field being edited / dragged (a theme without it: CP_TEXT_BRIGHT)
    PANEL_field_hover_border              AS _UNSIGNED LONG ' Outline of a field under the pointer (a theme without it: ANIM_FRAME_CURRENT)
    PANEL_field_sel_bg                    AS _UNSIGNED LONG ' A field's selected text (a theme without it: CP_BUTTON_BG)
    PANEL_field_caret                     AS _UNSIGNED LONG ' A field's text caret (a theme without it: CP_TEXT_BRIGHT)
    PANEL_list_fg                         AS _UNSIGNED LONG ' Row text (a theme without it: CP_TEXT)
    PANEL_list_hover_bg                   AS _UNSIGNED LONG ' Row under the pointer (a theme without it: CP_BUTTON_SEC_HOVER)
    PANEL_list_sel_bg                     AS _UNSIGNED LONG ' Selected row (a theme without it: CP_BUTTON_BG)
    PANEL_list_sel_fg                     AS _UNSIGNED LONG ' Selected row text (a theme without it: CP_TEXT_BRIGHT)
    PANEL_list_bg                         AS _UNSIGNED LONG ' List / item grid background (a theme without it: CP_SLIDER_BG)
    PANEL_list_border                     AS _UNSIGNED LONG ' List outline (a theme without it: CP_SLIDER_BORDER)
    PANEL_list_hover_fg                   AS _UNSIGNED LONG ' Row text under the pointer (a theme without it: CP_TEXT_BRIGHT)
    PANEL_list_header_fg                  AS _UNSIGNED LONG ' Group header row text in a list (a theme without it: CP_TITLE_FG)
    PANEL_scrollbar_track                 AS _UNSIGNED LONG ' Scrollbar track (a theme without it: CP_SLIDER_BG)
    PANEL_scrollbar_thumb                 AS _UNSIGNED LONG ' Scrollbar thumb (a theme without it: CP_TEXT_DIM)
    PANEL_swatch_border                   AS _UNSIGNED LONG ' Swatch outline (a theme without it: CP_SLIDER_BORDER)
    PANEL_swatch_hover_border             AS _UNSIGNED LONG ' Swatch outline under the pointer (a theme without it: CP_TEXT)
    PANEL_swatch_sel_border               AS _UNSIGNED LONG ' Selected swatch outline (a theme without it: CP_TEXT_BRIGHT)
    ' --- Dock: the columns panels sit in (titles and tabs are PANEL_ keys) ---
    DOCK_bg                               AS _UNSIGNED LONG ' Dock column / row background, behind panels (a theme without it: EDIT_BAR_BG_COLOR)
    DOCK_seam                             AS _UNSIGNED LONG ' Seam between panels, and between a left / top / bottom dock and the canvas (a theme without it: EDIT_BAR_RIGHT_BORDER_COLOR)
    DOCK_seam_right                       AS _UNSIGNED LONG ' Seam between the right dock and the canvas (a theme without it: EDIT_BAR_LEFT_BORDER_COLOR)
    DOCK_handle_hover_bg                  AS _UNSIGNED LONG ' Drag handle under the pointer (a theme without it: EDIT_BAR_ICON_MOUSE_OUTLINE_COLOR)
    DOCK_handle_hover_fg                  AS _UNSIGNED LONG ' Grip dots on a drag handle under the pointer (a theme without it: EDIT_BAR_BG_COLOR)
    ' --- Pen Control panel parts ---
    PEN_METER_bg                          AS _UNSIGNED LONG ' Meter well (a theme without it: CP_SLIDER_BG)
    PEN_METER_border                      AS _UNSIGNED LONG ' Meter outline (a theme without it: CP_SLIDER_BORDER)
    PEN_METER_fill                        AS _UNSIGNED LONG ' Level fill (a theme without it: CP_TEXT_DIM)
    PEN_METER_fill_active                 AS _UNSIGNED LONG ' Mouse meter fill while mouse expression is pressing (a theme without it: CP_TEXT_BRIGHT)
    PEN_METER_value                       AS _UNSIGNED LONG ' Tick for the value after the curve (a theme without it: CP_TEXT_BRIGHT)
    PEN_METER_mark                        AS _UNSIGNED LONG ' Tip-threshold mark (a theme without it: CP_CLOSE_FG)
    PEN_METER_fg                          AS _UNSIGNED LONG ' The meter's % readout (a theme without it: CP_TEXT)
    PEN_GRAPH_bg                          AS _UNSIGNED LONG ' Graph background (a theme without it: CP_SLIDER_BG)
    PEN_GRAPH_border                      AS _UNSIGNED LONG ' Graph outline (a theme without it: CP_SLIDER_BORDER)
    PEN_GRAPH_guide                       AS _UNSIGNED LONG ' Dashed reference lines (a theme without it: CP_TEXT_DIM)
    PEN_GRAPH_curve                       AS _UNSIGNED LONG ' The curve (a theme without it: CP_TEXT)
    PEN_GRAPH_curve_off                   AS _UNSIGNED LONG ' The speed curve while speed scaling is off (a theme without it: CP_TEXT_DIM)
    PEN_GRAPH_point                       AS _UNSIGNED LONG ' Live point (a theme without it: CP_TEXT_BRIGHT)
    PEN_GRAPH_avg                         AS _UNSIGNED LONG ' Last stroke's average speed (dashed) (a theme without it: CP_TEXT_BRIGHT)
    PEN_GRAPH_top                         AS _UNSIGNED LONG ' Last stroke's top speed line (a theme without it: CP_CLOSE_FG)
    PEN_GRAPH_top_fg                      AS _UNSIGNED LONG ' TOP readout text, the legend of that line (a theme without it: CP_CLOSE_FG)
    PEN_GRAPH_label                       AS _UNSIGNED LONG ' Caption inside a graph (a theme without it: CP_TEXT_DIM)
    PEN_HINT_bg                           AS _UNSIGNED LONG ' Hint box background (a theme without it: CP_SLIDER_BG)
    PEN_HINT_border                       AS _UNSIGNED LONG ' Hint box outline (a theme without it: CP_SLIDER_BORDER)
    PEN_HINT_fg                           AS _UNSIGNED LONG ' Hint text (a theme without it: CP_TEXT_DIM)
    ' --- Swatches panel parts ---
    SWATCHES_space_border                 AS _UNSIGNED LONG ' Outline of an empty slot (hovered or selected; the list view's box) (a theme without it: CP_TEXT_DIM)
    SWATCHES_space_sel_bg                 AS _UNSIGNED LONG ' Fill of a selected empty slot (a theme without it: CP_SLIDER_BORDER)
    SWATCHES_fg_mark                      AS _UNSIGNED LONG ' Frame on the FG colour (grid and recent row) (a theme without it: CP_TEXT_BRIGHT)
    SWATCHES_bg_mark                      AS _UNSIGNED LONG ' Frame on the BG colour (a theme without it: CP_TEXT)
    SWATCHES_drag                         AS _UNSIGNED LONG ' Rubber-band selection box and the drop mark (a theme without it: CP_TEXT_BRIGHT)
    ' --- Customize Toolbars parts ---
    TOOLBAR_EDITOR_divider                AS _UNSIGNED LONG ' Icon of a divider entry (a theme without it: CP_TEXT)
    TOOLBAR_EDITOR_gap                    AS _UNSIGNED LONG ' Dotted box of a gap entry (a theme without it: CP_TEXT_DIM)
    TOOLBAR_EDITOR_drop                   AS _UNSIGNED LONG ' Where a dragged entry lands (insertion line, target list outline) (a theme without it: CP_TEXT_BRIGHT)
    TOOLBAR_EDITOR_sel_border             AS _UNSIGNED LONG ' Selected entry's outer outline on the real panel (a theme without it: CP_TEXT_BRIGHT)
    TOOLBAR_EDITOR_sel_inner              AS _UNSIGNED LONG ' Selected entry's inner outline (a theme without it: CP_BUTTON_BG)
    TOOLBAR_EDITOR_ghost_bg               AS _UNSIGNED LONG ' Entry following the pointer while dragging (a theme without it: CP_BG)
    TOOLBAR_EDITOR_ghost_border           AS _UNSIGNED LONG ' Its outline (a theme without it: CP_TEXT_BRIGHT)
    ' --- Animation panel parts (X-sheet, lanes, sound, lightbox, canvas widget) ---
    ANIM_SHEET_grid                       AS _UNSIGNED LONG ' Frame boundaries, header line and ticks, name-column edge, row separators, row rules (drawn at several alphas) (a theme without it: CP_BORDER)
    ANIM_SHEET_names_bg                   AS _UNSIGNED LONG ' The layer-name column (a theme without it: CP_SLIDER_BG)
    ANIM_SHEET_multi_bg                   AS _UNSIGNED LONG ' Name cell of the other layers in a multi-selection (a theme without it: LAYER_PANEL_ROW_MULTI_SEL_BG)
    ANIM_SHEET_cur_row                    AS _UNSIGNED LONG ' Current layer's row tint across the frames (faint) (a theme without it: CP_TEXT_BRIGHT)
    ANIM_SHEET_hold_bg                    AS _UNSIGNED LONG ' Tint behind a held run (faint) (a theme without it: CP_TEXT)
    ANIM_SHEET_hold                       AS _UNSIGNED LONG ' Hold line, its ticks and end handle (a theme without it: CP_TEXT)
    ANIM_SHEET_hold_cur                   AS _UNSIGNED LONG ' Hold line on the current layer (a theme without it: CP_TEXT_BRIGHT)
    ANIM_SHEET_cell_mark                  AS _UNSIGNED LONG ' Drawn-cell bar when zoomed out too far for a thumbnail (a theme without it: CP_TEXT)
    ANIM_SHEET_more                       AS _UNSIGNED LONG ' Marks at the names' edge: more rows above / below (a theme without it: CP_TEXT_BRIGHT)
    ANIM_SHEET_dim                        AS _UNSIGNED LONG ' Veil over cells a hold drag lets go (a theme without it: CP_BG)
    ANIM_SHEET_contrast                   AS _UNSIGNED LONG ' What the grey lines lighten toward as XSHEET_CONTRAST goes up (a theme without it: CP_TEXT_BRIGHT)
    ANIM_SHEET_zoom_notch                 AS _UNSIGNED LONG ' The default-zoom notch on the zoom slider (a theme without it: CP_TEXT)
    ANIM_SHEET_item                       AS _UNSIGNED LONG ' Things placed on the sheet: tag bars, sound clips, clip-layer bars + grips, note marks, link hatching (fill = a fainter copy) (a theme without it: ANIM_FRAME_CURRENT)
    ANIM_SHEET_item_sel                   AS _UNSIGNED LONG ' Outline of the picked sound clip (a theme without it: ANIM_FRAME_DRAWING)
    ANIM_SHEET_drop                       AS _UNSIGNED LONG ' Drag-drop feedback: drop outlines, a hold drag's new run, the frame-drop marker (a theme without it: ANIM_FRAME_CURRENT)
    ANIM_LANE_color                       AS _UNSIGNED LONG ' A lane's colour when Settings leaves it unset (label and curve) (a theme without it: CP_TEXT)
    ANIM_LANE_arrow                       AS _UNSIGNED LONG ' Lanes disclosure arrow before a layer name (a theme without it: CP_TEXT_DIM)
    ANIM_LANE_arrow_cur                   AS _UNSIGNED LONG ' That arrow on the current layer (a theme without it: CP_TEXT_BRIGHT)
    ANIM_LANE_guide                       AS _UNSIGNED LONG ' Dotted default-value guide on a lane row (a theme without it: CP_BORDER)
    ANIM_LANE_key_cur                     AS _UNSIGNED LONG ' Key glyph at the current frame on the picked lane (a theme without it: CP_TEXT_BRIGHT)
    ANIM_LANE_key_bg                      AS _UNSIGNED LONG ' Inside of a hollow key glyph (a theme without it: CP_BG)
    ANIM_LANE_key_off                     AS _UNSIGNED LONG ' Key button glyph on a frame with no key (a theme without it: CP_TEXT_DIM)
    ANIM_LANE_key                         AS _UNSIGNED LONG ' Key glyphs (lane diamonds, the key button on a keyed frame) (a theme without it: ANIM_FRAME_CURRENT)
    ANIM_LANE_key_sel                     AS _UNSIGNED LONG ' Lane key selection: shade, outline, the keys inside it (a theme without it: ANIM_FRAME_CURRENT)
    ANIM_LANE_dot                         AS _UNSIGNED LONG ' Centre of an envelope-phase dot on a curve (a theme without it: CP_TEXT_BRIGHT)
    ANIM_LANE_rec_idle                    AS _UNSIGNED LONG ' Record dot, not keyed and not armed (faint ring) (a theme without it: CP_TEXT)
    ANIM_SOUND_wave                       AS _UNSIGNED LONG ' Clip waveform (a theme without it: CP_TEXT)
    ANIM_SOUND_wave_cur                   AS _UNSIGNED LONG ' Waveform of the picked clip, or under the current frame (a theme without it: CP_TEXT_BRIGHT)
    ANIM_SEEK_bg                          AS _UNSIGNED LONG ' Track (a theme without it: CP_SLIDER_BG)
    ANIM_SEEK_border                      AS _UNSIGNED LONG ' Track outline, the ring round the handle (a theme without it: CP_SLIDER_BORDER)
    ANIM_SEEK_fill                        AS _UNSIGNED LONG ' The part played so far (a theme without it: CP_BUTTON_BG)
    ANIM_SEEK_thumb                       AS _UNSIGNED LONG ' Handle (a theme without it: CP_TEXT_BRIGHT)
    ANIM_SEEK_disabled                    AS _UNSIGNED LONG ' Fill and handle with one frame or none (a theme without it: CP_TEXT_DIM)
    ANIM_WIDGET_bg                        AS _UNSIGNED LONG ' OPACITY / TINT bar and drag-tip box (a theme without it: CP_BUTTON_BG)
    ANIM_WIDGET_border                    AS _UNSIGNED LONG ' Outline of the bar and the tip box (a theme without it: CP_BORDER)
    ANIM_WIDGET_tip_fg                    AS _UNSIGNED LONG ' Drag / hover tip text (a theme without it: CP_TEXT_BRIGHT)
    ANIM_WIDGET_line                      AS _UNSIGNED LONG ' The widget's box, rotate stem, the hovered / dragged handle (a theme without it: ANIM_FRAME_CURRENT)
    ' --- Fonts ---
    GLOBAL_FONT_FILE                      AS STRING         ' Primary UI font filename (e.g. Tiny5-Regular.ttf)
    GLOBAL_FONT_SIZE                      AS INTEGER        ' Primary UI font size in points/pixels
    ALT_FONT_FILE                         AS STRING         ' Alternate font filename (e.g. PICO-8.ttf) — reserved
    FILE_DIALOG_FONT_FILE                 AS STRING         ' File dialog font filename (overrides GLOBAL if set)
    FILE_DIALOG_FONT_SIZE                 AS INTEGER        ' File dialog font size in points/pixels
    ' --- File browser (File dialogs + the Image Browser panel) - QB64_GJ_LIB FILE_DIALOG ---
    FILE_DIALOG_bg                        AS _UNSIGNED LONG ' Background, toolbar (a theme without it: CP_BG)
    FILE_DIALOG_title_bg                  AS _UNSIGNED LONG ' Title bar (a theme without it: CP_TITLE_BG)
    FILE_DIALOG_title_active_bg           AS _UNSIGNED LONG ' Title bar while dragged (a theme without it: CP_TITLE_DRAG_BG)
    FILE_DIALOG_places_bg                 AS _UNSIGNED LONG ' Places sidebar (a theme without it: CP_BG)
    FILE_DIALOG_list_bg                   AS _UNSIGNED LONG ' File list (a theme without it: CP_BG)
    FILE_DIALOG_preview_bg                AS _UNSIGNED LONG ' Preview pane (a theme without it: CP_BG)
    FILE_DIALOG_path_bg                   AS _UNSIGNED LONG ' Path bar (a theme without it: CP_TITLE_BG)
    FILE_DIALOG_header_bg                 AS _UNSIGNED LONG ' File list column headers (a theme without it: CP_BUTTON_BAR_BG)
    FILE_DIALOG_bar_bg                    AS _UNSIGNED LONG ' Status bar and button bar (a theme without it: CP_BUTTON_BAR_BG)
    FILE_DIALOG_border                    AS _UNSIGNED LONG ' Outlines (a theme without it: CP_BORDER)
    FILE_DIALOG_focus_border              AS _UNSIGNED LONG ' Outline of the focused pane / field (a theme without it: CP_BUTTON_FOCUS)
    FILE_DIALOG_divider                   AS _UNSIGNED LONG ' Pane splitters and divider lines (a theme without it: CP_DIVIDER)
    FILE_DIALOG_fg                        AS _UNSIGNED LONG ' Text (a theme without it: CP_TEXT)
    FILE_DIALOG_value_fg                  AS _UNSIGNED LONG ' Bright text: the selected file, values (a theme without it: CP_TEXT_BRIGHT)
    FILE_DIALOG_hint_fg                   AS _UNSIGNED LONG ' Dim text: sizes, dates, hints (a theme without it: CP_TEXT_DIM)
    FILE_DIALOG_disabled_fg               AS _UNSIGNED LONG ' Text of something that is off (a theme without it: CP_TEXT_DIM)
    FILE_DIALOG_accent_fg                 AS _UNSIGNED LONG ' Accent text (a theme without it: CP_BUTTON_FOCUS)
    FILE_DIALOG_hover_bg                  AS _UNSIGNED LONG ' Row under the pointer (a theme without it: CP_BUTTON_HOVER)
    FILE_DIALOG_sel_bg                    AS _UNSIGNED LONG ' Selected row (a theme without it: CP_BUTTON_BG)
    FILE_DIALOG_sel_unfocused_bg          AS _UNSIGNED LONG ' Selected row of a pane without the focus (a theme without it: CP_BUTTON_SECONDARY)
    FILE_DIALOG_button_bg                 AS _UNSIGNED LONG ' Button (a theme without it: CP_BUTTON_BG)
    FILE_DIALOG_button_hover_bg           AS _UNSIGNED LONG ' Button under the pointer (a theme without it: CP_BUTTON_HOVER)
    FILE_DIALOG_button_fg                 AS _UNSIGNED LONG ' Button text (a theme without it: CP_BUTTON_TEXT)
    ' --- Sounds ---
    SOUND_MENU_OPEN_FILE                  AS STRING         ' Filename for menu-open sound
    SOUND_MENU_SELECT_FILE                AS STRING         ' Filename for menu-item-selected sound
    SOUND_NEW_FILE_FILE                   AS STRING         ' Filename for new file / startup sound
    SOUND_NEW_LAYER_FILE                  AS STRING         ' Filename for new layer sound
    SOUND_LAYER_OP_FILE                   AS STRING         ' Filename for layer delete/arrange/merge/duplicate
    SOUND_CLIPBOARD_FILE                  AS STRING         ' Filename for copy/cut/paste sound
    SOUND_FILL_FILE                       AS STRING         ' Filename for flood fill sound
    SOUND_SELECTION_FILE                  AS STRING         ' Filename for selection operation sound
    SOUND_DRAW_FILE                       AS STRING         ' Filename for draw click (brush/dot/spray)
    SOUND_TRANSFORM_FILE                  AS STRING         ' Filename for transform (flip/scale/rotate/about)
    SOUND_TEXT_ENTER_FILE                 AS STRING         ' Filename for text tool Enter (commit line)
    SOUND_MENU_HOVER_FILE                 AS STRING         ' Filename for hovering a new menu item
    SOUND_TOOL_SELECT_FILE                AS STRING         ' Filename for toolbox button click
    SOUND_TEXT_CHAR_FILE                  AS STRING         ' Filename for text tool character typed
    SOUND_ERASER_FILE                     AS STRING         ' Filename for eraser stroke initial click
    SOUND_DRAW_PITCH_MIN                  AS SINGLE         ' Min playback speed for draw pitch randomisation
    SOUND_DRAW_PITCH_MAX                  AS SINGLE         ' Max playback speed for draw pitch randomisation
    SOUND_ERASER_PITCH_MIN                AS SINGLE         ' Min playback speed for eraser pitch randomisation
    SOUND_ERASER_PITCH_MAX                AS SINGLE         ' Max playback speed for eraser pitch randomisation
    SOUND_DRAW_REVERSE_FILE               AS STRING         ' Reversed draw WAV for direction-change sound
    SOUND_ERASER_REVERSE_FILE             AS STRING         ' Reversed eraser WAV for direction-change sound
    SOUND_DRAW_LENGTH_DYNAMICS_MIN        AS SINGLE         ' Volume at short drag (0.0-1.0)
    SOUND_DRAW_LENGTH_DYNAMICS_MAX        AS SINGLE         ' Volume at long drag (0.0-1.0)
    SOUND_SLIDER_FILE                     AS STRING         ' Filename for opacity/value slider drag sound
    SOUND_DRAG_DROP_FILE                  AS STRING         ' Filename for layer drag-and-drop sound
    SOUND_POINT_FILE                      AS STRING         ' Filename for click-to-place-point (line/shape/poly tools)
    SOUND_ORGANIZER_FILE                  AS STRING         ' Filename for organizer/drawer widget click or mousewheel
    MUSIC_FILE                            AS STRING         ' Filename for background music (IT/XM/MOD/S3M; empty = none)
    ' --- Lospec dialog ---
    LOSPEC_SWATCH_COLS                    AS INTEGER        ' Lospec preview swatch columns per row (default 16)
    ' --- Lospec dialog colors ---
    LOSPEC_status_error_fg                AS _UNSIGNED LONG ' Lospec error status text color
    LOSPEC_status_ok_fg                   AS _UNSIGNED LONG ' Lospec success status text color
    LOSPEC_status_info_fg                 AS _UNSIGNED LONG ' Lospec info status text color
    LOSPEC_search_bg                      AS _UNSIGNED LONG ' Lospec search input background
    LOSPEC_search_border                  AS _UNSIGNED LONG ' Lospec search input border
    LOSPEC_search_cursor                  AS _UNSIGNED LONG ' Lospec search input cursor color
    LOSPEC_col_header_fg                  AS _UNSIGNED LONG ' Lospec column header text color
    LOSPEC_col_divider                    AS _UNSIGNED LONG ' Lospec column divider line color
    LOSPEC_result_sel_bg                  AS _UNSIGNED LONG ' Lospec selected result row background
    LOSPEC_result_hover_bg                AS _UNSIGNED LONG ' Lospec hovered result row background
    LOSPEC_result_fg                      AS _UNSIGNED LONG ' Lospec result row text color
    LOSPEC_result_count_fg                AS _UNSIGNED LONG ' Lospec result color count text
    LOSPEC_batch_hover_bg                 AS _UNSIGNED LONG ' Lospec batch download hover background
    LOSPEC_count_fg                       AS _UNSIGNED LONG ' Lospec total results count text
    LOSPEC_preview_panel_bg               AS _UNSIGNED LONG ' Lospec preview panel background
    LOSPEC_preview_name_fg                AS _UNSIGNED LONG ' Lospec preview palette name text
    LOSPEC_preview_author_fg              AS _UNSIGNED LONG ' Lospec preview author text
    LOSPEC_preview_link_fg                AS _UNSIGNED LONG ' Lospec preview link text color
    LOSPEC_preview_link_hov               AS _UNSIGNED LONG ' Lospec preview link hover color
    LOSPEC_tooltip_sep                    AS _UNSIGNED LONG ' Lospec tooltip separator color
    LOSPEC_tooltip_bg                     AS _UNSIGNED LONG ' Lospec tooltip background
    LOSPEC_tooltip_fg                     AS _UNSIGNED LONG ' Lospec tooltip text color
    LOSPEC_tooltip_hint_fg                AS _UNSIGNED LONG ' Lospec tooltip hint text color
    LOSPEC_empty_fg                       AS _UNSIGNED LONG ' Lospec empty state text color
    LOSPEC_btn_dl_bg                      AS _UNSIGNED LONG ' Lospec download button background
    LOSPEC_btn_dl_hover                   AS _UNSIGNED LONG ' Lospec download button hover background
    LOSPEC_btn_dl_border                  AS _UNSIGNED LONG ' Lospec download button border
    LOSPEC_btn_close_bg                   AS _UNSIGNED LONG ' Lospec close button background
    LOSPEC_btn_close_hover                AS _UNSIGNED LONG ' Lospec close button hover background
    LOSPEC_btn_close_border               AS _UNSIGNED LONG ' Lospec close button border
    LOSPEC_checkbox_border                AS _UNSIGNED LONG ' Lospec checkbox border color
    LOSPEC_checkbox_fill                  AS _UNSIGNED LONG ' Lospec checkbox fill color
    LOSPEC_checkbox_dl_fill               AS _UNSIGNED LONG ' Downloaded-state checkbox fill (green tint)
    LOSPEC_downloaded_fg                  AS _UNSIGNED LONG ' Download date text in results list
    PALETTE_MENU_SEP_fg                   AS _UNSIGNED LONG ' Palette menu separator label text color
    PALETTE_MENU_SEP_bg                   AS _UNSIGNED LONG ' Palette menu separator label background box color
    ' Edit Bar
    EDIT_BAR_LEFT_BORDER_COLOR            AS _UNSIGNED LONG ' Edit bar left border color
    EDIT_BAR_RIGHT_BORDER_COLOR           AS _UNSIGNED LONG ' Edit bar right border color
    EDIT_BAR_LEFT_BORDER_WIDTH            AS INTEGER        ' Edit bar left border width in pixels
    EDIT_BAR_RIGHT_BORDER_WIDTH           AS INTEGER        ' Edit bar right border width in pixels
    ' --- Icon bars: the edit / advanced bar, toolbox and workflow buttons, every button list - a key per kind of control ---
    ICON_BAR_bg                           AS _UNSIGNED LONG ' Icon bar background (edit / advanced bar), a workflow button's face, a command cell in the toolbox (a theme without it: EDIT_BAR_BG_COLOR)
    ICON_BAR_button_fg                    AS _UNSIGNED LONG ' Text on an icon button: command text tiles, workflow button labels
    ICON_BAR_button_on_fg                 AS _UNSIGNED LONG ' Text of an icon button that is on
    ICON_BAR_button_disabled_fg           AS _UNSIGNED LONG ' Text of an icon button that does nothing now (a workflow button whose workspace is gone)
    ICON_BAR_button_on_bg                 AS _UNSIGNED LONG ' Overlay on an icon button that is on (the tool in use, a lit toggle) - toolbox, bars, workflow (a theme without it: TOOLBAR_BTN_OVERLAY)
    ICON_BAR_button_on_border             AS _UNSIGNED LONG ' Outline of an icon button that is on (a theme without it: TOOLBAR_BTN_STROKE)
    ICON_BAR_button_hover_border          AS _UNSIGNED LONG ' Outline of an icon button under the pointer (a theme without it: EDIT_BAR_ICON_MOUSE_OUTLINE_COLOR)
    ICON_BAR_button_disabled_alpha        AS INTEGER        ' How much a disabled icon fades (0 = not at all, 255 = gone) (a theme without it: EDIT_BAR_ICON_DISABLED_ALPHA)
    ICON_BAR_width                        AS INTEGER        ' Width of an icon bar's column in px (a theme without it: EDIT_BAR_WIDTH)
    ICON_BAR_padding                      AS INTEGER        ' Space around an icon bar's buttons in px (a theme without it: EDIT_BAR_ICON_PADDING)
    ICON_BAR_divider_margin               AS INTEGER        ' Space a divider entry takes in px (a theme without it: EDIT_BAR_DIVIDER_VERT_MARGIN)
    ICON_BAR_border_left_width            AS INTEGER        ' Left edge of an icon bar in px (a theme without it: EDIT_BAR_LEFT_BORDER_WIDTH)
    ICON_BAR_border_right_width           AS INTEGER        ' Right edge of an icon bar in px (a theme without it: EDIT_BAR_RIGHT_BORDER_WIDTH)
    EDIT_BAR_WIDTH                        AS INTEGER        ' Edit bar content width in pixels
    EDIT_BAR_ICON_PADDING                 AS INTEGER        ' Padding around each icon in pixels
    EDIT_BAR_BG_COLOR                     AS _UNSIGNED LONG ' Edit bar background fill color
    EDIT_BAR_ICON_MOUSE_OUTLINE_COLOR     AS _UNSIGNED LONG ' Icon hover outline color
    EDIT_BAR_ICON_DISABLED_ALPHA          AS INTEGER        ' How much to dim disabled icons (0 = no dim, 255 = fully transparent)
    EDIT_BAR_DIVIDER_VERT_MARGIN          AS INTEGER        ' Vertical margin around divider lines
    EDIT_BAR_ICON_UNDO                    AS STRING * 64    ' Undo icon PNG filename
    EDIT_BAR_ICON_REDO                    AS STRING * 64    ' Redo icon PNG filename
    EDIT_BAR_ICON_CUT                     AS STRING * 64    ' Cut icon PNG filename
    EDIT_BAR_ICON_COPY                    AS STRING * 64    ' Copy icon PNG filename
    EDIT_BAR_ICON_COPY_MERGED             AS STRING * 64    ' Copy merged icon PNG filename
    EDIT_BAR_ICON_PASTE                   AS STRING * 64    ' Paste icon PNG filename
    EDIT_BAR_ICON_PASTE_IN_PLACE          AS STRING * 64    ' Paste in place icon PNG filename
    EDIT_BAR_ICON_CUT_TO_LAYER            AS STRING * 64    ' Cut to layer icon PNG filename
    EDIT_BAR_ICON_COPY_TO_LAYER           AS STRING * 64    ' Copy to layer icon PNG filename
    EDIT_BAR_ICON_CLEAR                   AS STRING * 64    ' Clear icon PNG filename
    EDIT_BAR_ICON_FILL_WITH_FG            AS STRING * 64    ' Fill with FG icon PNG filename
    EDIT_BAR_ICON_FILL_WITH_BG            AS STRING * 64    ' Fill with BG icon PNG filename
    EDIT_BAR_ICON_STROKE_SELECTION        AS STRING * 64    ' Stroke selection icon PNG filename
    EDIT_BAR_ICON_FLIP_HORIZONTAL         AS STRING * 64    ' Flip horizontal icon PNG filename
    EDIT_BAR_ICON_FLIP_VERTICAL           AS STRING * 64    ' Flip vertical icon PNG filename
    EDIT_BAR_ICON_SCALE_DOWN              AS STRING * 64    ' Scale down icon PNG filename
    EDIT_BAR_ICON_SCALE_UP                AS STRING * 64    ' Scale up icon PNG filename
    EDIT_BAR_ICON_ROTATE_CW               AS STRING * 64    ' Rotate clockwise icon PNG filename
    EDIT_BAR_ICON_ROTATE_CCW              AS STRING * 64    ' Rotate counter-clockwise icon PNG filename
    EDIT_BAR_ICON_SMART_GUIDES            AS STRING * 64    ' Smart Guides toggle icon PNG filename
    EDIT_BAR_ICON_SMART_GUIDES_SNAP       AS STRING * 64    ' Snap Smart Guides toggle icon PNG filename
    EDIT_BAR_ICON_PIXEL_PERFECT           AS STRING * 64    ' Pixel Perfect toggle icon PNG filename
    EDIT_BAR_ICON_FLIP_CANVAS_H           AS STRING * 64    ' Flip Canvas Horizontal icon PNG filename
    EDIT_BAR_ICON_FLIP_CANVAS_V           AS STRING * 64    ' Flip Canvas Vertical icon PNG filename
    ' --- Advanced Bar ---
    ADV_BAR_LEFT_BORDER_COLOR             AS _UNSIGNED LONG ' Advanced bar left border color
    ADV_BAR_RIGHT_BORDER_COLOR            AS _UNSIGNED LONG ' Advanced bar right border color
    ADV_BAR_LEFT_BORDER_WIDTH             AS INTEGER        ' Advanced bar left border width (pixels)
    ADV_BAR_RIGHT_BORDER_WIDTH            AS INTEGER        ' Advanced bar right border width (pixels)
    ADV_BAR_WIDTH                         AS INTEGER        ' Advanced bar content width (pixels)
    ADV_BAR_ICON_PADDING                  AS INTEGER        ' Advanced bar vertical icon spacing (pixels)
    ADV_BAR_BG_COLOR                      AS _UNSIGNED LONG ' Advanced bar background fill
    ADV_BAR_ICON_MOUSE_OUTLINE_COLOR      AS _UNSIGNED LONG ' Advanced bar hover outline color
    ADV_BAR_ICON_DISABLED_ALPHA           AS INTEGER        ' Disabled icon dim (0-255)
    ADV_BAR_DIVIDER_VERT_MARGIN           AS INTEGER        ' Divider spacing (pixels)
    ADV_BAR_ICON_PREVIEW_WINDOW           AS STRING * 64    ' Preview Window icon
    ADV_BAR_ICON_EDIT_BAR                 AS STRING * 64    ' Edit Bar icon
    ADV_BAR_ICON_CHAR_MAP                 AS STRING * 64    ' Character Map icon
    ADV_BAR_ICON_CHAR_GRID                AS STRING * 64    ' Character Grid icon
    ADV_BAR_ICON_CHAR_GRID_SNAP           AS STRING * 64    ' Char Grid Snap icon
    ADV_BAR_ICON_TILE_MODE                AS STRING * 64    ' Tile Preview Mode icon
    ADV_BAR_ICON_FILL_GRID_MODE           AS STRING * 64    ' Grid Cell Fill icon
    ADV_BAR_ICON_GRID_BRUSH_SIZE          AS STRING * 64    ' Resize Grid to Brush Size icon
    ADV_BAR_ICON_FILL_ADJUST              AS STRING * 64    ' Fill Adjustment Mode icon
    ADV_BAR_ICON_BRUSH_EDGES              AS STRING * 64    ' Brush Edges icon
    ADV_BAR_ICON_ANGLE_SNAP               AS STRING * 64    ' Angle Snap icon
    ADV_BAR_ICON_GRAYSCALE                AS STRING * 64    ' Grayscale icon
    ADV_BAR_ICON_REF_ON                   AS STRING * 64    ' Reference Image toggle icon
    ADV_BAR_ICON_REF_LOAD                 AS STRING * 64    ' Load Reference Image icon
    ADV_BAR_ICON_REF_CLEAR                AS STRING * 64    ' Clear Reference Image icon
    ADV_BAR_ICON_REF_ADJUST               AS STRING * 64    ' Adjust Reference Image icon
    ADV_BAR_ICON_ALIGN_LEFT               AS STRING * 64    ' Align Left icon
    ADV_BAR_ICON_ALIGN_CENTER             AS STRING * 64    ' Align Center icon
    ADV_BAR_ICON_ALIGN_RIGHT              AS STRING * 64    ' Align Right icon
    ADV_BAR_ICON_ALIGN_TOP                AS STRING * 64    ' Align Top icon
    ADV_BAR_ICON_ALIGN_MIDDLE             AS STRING * 64    ' Align Middle icon
    ADV_BAR_ICON_ALIGN_BOTTOM             AS STRING * 64    ' Align Bottom icon
    ADV_BAR_ICON_DIST_H                   AS STRING * 64    ' Distribute Horizontal icon
    ADV_BAR_ICON_DIST_V                   AS STRING * 64    ' Distribute Vertical icon
    ADV_BAR_ICON_FLIP_CANVAS_H            AS STRING * 64    ' Flip Canvas Horizontal icon
    ADV_BAR_ICON_FLIP_CANVAS_V            AS STRING * 64    ' Flip Canvas Vertical icon
    ' --- Tooltips ---
    TOOLTIP_FONT                          AS STRING         ' Tooltip font filename (empty = use global font)
    TOOLTIP_FONT_SIZE                     AS INTEGER        ' Tooltip font size in pixels (default 8)
    TOOLTIP_BG_COLOR                      AS _UNSIGNED LONG ' Tooltip background color (RGBA)
    TOOLTIP_FG_COLOR                      AS _UNSIGNED LONG ' Tooltip text color (RGBA)
    TOOLTIP_BOLD_FG_COLOR                 AS _UNSIGNED LONG ' Tooltip bold/hotkey text color (RGBA)
    TOOLTIP_PADDING                       AS INTEGER        ' Tooltip inner padding in pixels (default 3)
    TOOLTIP_BORDER_COLOR                  AS _UNSIGNED LONG ' Tooltip border color (RGBA)
    TOOLTIP_BORDER_WIDTH                  AS INTEGER        ' Tooltip border width in pixels (default 1)
    ' --- Text Formatting Bar ---
    TEXT_BAR_BG                           AS _UNSIGNED LONG ' Text bar background color
    TEXT_BAR_FG                           AS _UNSIGNED LONG ' Text bar text/label color
    TEXT_BAR_BORDER                       AS _UNSIGNED LONG ' Text bar border color
    TEXT_BAR_BTN_ACTIVE                   AS _UNSIGNED LONG ' Active toggle button highlight
    TEXT_BAR_BTN_HOVER                    AS _UNSIGNED LONG ' Hovered button highlight
    TEXT_BAR_BTN_BG                       AS _UNSIGNED LONG ' Toggle button default background
    TEXT_BAR_BTN_FG                       AS _UNSIGNED LONG ' Toggle button default text color
    TEXT_BAR_BTN_BORDER                   AS _UNSIGNED LONG ' Toggle button border color
    TEXT_BAR_ICON_SELECTED_OPACITY        AS INTEGER        ' Icon alpha when style is active (0-255)
    TEXT_BAR_ICON_DESELECTED_OPACITY      AS INTEGER        ' Icon alpha when style is off (0-255)
    TEXT_BAR_DROPDOWN_BG                  AS _UNSIGNED LONG ' Dropdown background color
    TEXT_BAR_DROPDOWN_FG                  AS _UNSIGNED LONG ' Dropdown text color
    TEXT_BAR_DROPDOWN_HIGHLIGHT           AS _UNSIGNED LONG ' Dropdown selected item highlight
    TEXT_BAR_DROPDOWN_HOVER_BG            AS _UNSIGNED LONG ' Dropdown hover item background
    TEXT_BAR_DROPDOWN_HOVER_FG            AS _UNSIGNED LONG ' Dropdown hover item text color
    ' --- Bars: the tool option bars (text, selection, MyPaint, brush) - a key per kind of control ---
    BAR_bg                                AS _UNSIGNED LONG ' Bar background (a theme without it: TEXT_BAR_BG_COLOR)
    BAR_border                            AS _UNSIGNED LONG ' Line under a bar (a theme without it: TEXT_BAR_BORDER_COLOR)
    BAR_divider                           AS _UNSIGNED LONG ' Lines between a bar's rows and groups (a theme without it: TEXT_BAR_BORDER_COLOR)
    BAR_label_fg                          AS _UNSIGNED LONG ' Labels (SIZE:, LH:, OPACITY) (a theme without it: TEXT_BAR_FG_COLOR)
    BAR_value_fg                          AS _UNSIGNED LONG ' Values: font name, size, line height, slider readouts (a theme without it: TEXT_BAR_FG_COLOR)
    BAR_button_bg                         AS _UNSIGNED LONG ' Button background (a theme without it: TEXT_BAR_BUTTON_BG_COLOR)
    BAR_button_fg                         AS _UNSIGNED LONG ' Button text and icon (a theme without it: TEXT_BAR_BUTTON_FG_COLOR)
    BAR_button_border                     AS _UNSIGNED LONG ' Button outline (a theme without it: TEXT_BAR_BUTTON_BORDER_COLOR)
    BAR_button_hover_bg                   AS _UNSIGNED LONG ' Button under the pointer (a theme without it: TEXT_BAR_BTN_HOVER_COLOR)
    BAR_button_hover_fg                   AS _UNSIGNED LONG ' Button text under the pointer (a theme without it: TEXT_BAR_FG_COLOR)
    BAR_button_on_bg                      AS _UNSIGNED LONG ' A button that is on (B / I / U / S, align, MONO, AA, the chosen chip) (a theme without it: TEXT_BAR_BTN_ACTIVE_COLOR)
    BAR_button_on_fg                      AS _UNSIGNED LONG ' Text of a button that is on (a theme without it: TEXT_BAR_FG_COLOR)
    BAR_dropdown_button_hover_bg          AS _UNSIGNED LONG ' A dropdown box (font, size, style) under the pointer or open (a theme without it: TEXT_BAR_BTN_HOVER_COLOR)
    BAR_field_border                      AS _UNSIGNED LONG ' Outline of a value box (line height, shadow X / Y, outline size) (a theme without it: TEXT_BAR_BTN_HOVER_COLOR)
    BAR_swatch_border                     AS _UNSIGNED LONG ' Colour swatch outline (a theme without it: TEXT_BAR_FG_COLOR)
    BAR_swatch_check_dark                 AS _UNSIGNED LONG ' Transparent swatch: dark checks (a theme without it: TEXT_BAR_TRANSPARENT_CHECK_DARK)
    BAR_swatch_check_light                AS _UNSIGNED LONG ' Transparent swatch: light checks (a theme without it: TEXT_BAR_TRANSPARENT_CHECK_LIGHT)
    BAR_slider_bg                         AS _UNSIGNED LONG ' Slider track (a theme without it: TEXT_BAR_BUTTON_BG_COLOR)
    BAR_slider_border                     AS _UNSIGNED LONG ' Slider track outline (a theme without it: TEXT_BAR_BUTTON_BORDER_COLOR)
    BAR_slider_hover_border               AS _UNSIGNED LONG ' Slider outline under the pointer or while dragged (a theme without it: TEXT_BAR_FG_COLOR)
    BAR_slider_fill                       AS _UNSIGNED LONG ' Slider fill (the value) (a theme without it: TEXT_BAR_BTN_ACTIVE_COLOR)
    BAR_item_bg                           AS _UNSIGNED LONG ' Grid cell background, the cell's badge (a theme without it: TEXT_BAR_BUTTON_BG_COLOR)
    BAR_item_fg                           AS _UNSIGNED LONG ' Cell text (names, badges) and the brush dab previews (a theme without it: TEXT_BAR_BUTTON_FG_COLOR)
    BAR_item_border                       AS _UNSIGNED LONG ' Cell outline (a theme without it: TEXT_BAR_BUTTON_BORDER_COLOR)
    BAR_item_hover_border                 AS _UNSIGNED LONG ' Cell outline under the pointer (a theme without it: TEXT_BAR_FG_COLOR)
    BAR_item_sel_border                   AS _UNSIGNED LONG ' Outline of the chosen cell (a theme without it: TEXT_BAR_BTN_ACTIVE_COLOR)
    BAR_scrollbar_track                   AS _UNSIGNED LONG ' Grid scrollbar track (a theme without it: TEXT_BAR_BUTTON_BG_COLOR)
    BAR_scrollbar_thumb                   AS _UNSIGNED LONG ' Grid scrollbar thumb (a theme without it: TEXT_BAR_FG_COLOR)
    BAR_dropdown_bg                       AS _UNSIGNED LONG ' List background (a theme without it: TEXT_BAR_DROPDOWN_BG)
    BAR_dropdown_fg                       AS _UNSIGNED LONG ' Item text, the list's arrows and scroll marks (a theme without it: TEXT_BAR_DROPDOWN_FG)
    BAR_dropdown_border                   AS _UNSIGNED LONG ' List outline (a theme without it: TEXT_BAR_BORDER_COLOR)
    BAR_dropdown_divider                  AS _UNSIGNED LONG ' Lines between groups of items (a theme without it: TEXT_BAR_BORDER_COLOR)
    BAR_dropdown_hover_bg                 AS _UNSIGNED LONG ' Item under the pointer (a theme without it: TEXT_BAR_DROPDOWN_HOVER_BG)
    BAR_dropdown_hover_fg                 AS _UNSIGNED LONG ' Item text under the pointer (a theme without it: TEXT_BAR_DROPDOWN_HOVER_FG)
    BAR_dropdown_preview_fg               AS _UNSIGNED LONG ' Font preview strip text in the font list (Settings' FONT_PREVIEW_FG wins when set)
    BAR_dropdown_preview_bg               AS _UNSIGNED LONG ' Font preview strip background (Settings' FONT_PREVIEW_BG wins when set)
    BAR_row_height                        AS INTEGER         ' Row height of every bar in px (a theme without it: TEXT_BAR_ROW_HEIGHT)
    BAR_dropdown_sel_bg                   AS _UNSIGNED LONG ' The current item (a theme without it: TEXT_BAR_DROPDOWN_HIGHLIGHT)
    TEXT_BAR_ICON_BOLD                    AS STRING * 64    ' Bold button icon PNG filename
    TEXT_BAR_ICON_ITALIC                  AS STRING * 64    ' Italic button icon PNG filename
    TEXT_BAR_ICON_UNDERLINE               AS STRING * 64    ' Underline button icon PNG filename
    TEXT_BAR_ICON_STRIKE                  AS STRING * 64    ' Strikethrough button icon PNG filename
    TEXT_BAR_ICON_MONO                    AS STRING * 64    ' Monospace button icon PNG filename
    TEXT_BAR_ICON_LINE_HEIGHT             AS STRING * 64    ' Line height button icon PNG filename
    ' --- Text Formatting Bar: Layout ---
    TEXT_BAR_ROW1_ORDER                   AS STRING * 64    ' Row 1 group order (csv : FONT,SIZE,BIUS,COLORS,MONO,LH,CHAR)
    TEXT_BAR_ROW2_ORDER                   AS STRING * 64    ' Row 2 group order (csv : STYLE,ALIGN,SHADOW,OUTLINE,AA)
    ' --- Text Formatting Bar: Geometry ---
    TEXT_BAR_ROW_HEIGHT                   AS INTEGER        ' Height of each row in px (default 14)
    TEXT_BAR_PADDING_H                    AS INTEGER        ' Horizontal padding from bar edges (default 4)
    TEXT_BAR_PADDING_V                    AS INTEGER        ' Vertical padding from row top (default 2)
    TEXT_BAR_GROUP_GAP                    AS INTEGER        ' Horizontal gap between groups (default 6)
    TEXT_BAR_BORDER_WIDTH                 AS INTEGER        ' Border stroke width (default 1)
    ' --- Text Formatting Bar: Button Geometry ---
    TEXT_BAR_BTN_WIDTH                    AS INTEGER        ' Width of square toggle buttons (default 12)
    TEXT_BAR_BTN_GAP                      AS INTEGER        ' Gap between buttons within group (default 2)
    TEXT_BAR_BTN_PADDING                  AS INTEGER        ' Text/icon inset inside button (default 3)
    ' --- Text Formatting Bar: Icon Geometry ---
    TEXT_BAR_ICON_WIDTH                   AS INTEGER        ' Icon image width (default 10)
    TEXT_BAR_ICON_HEIGHT                  AS INTEGER        ' Icon image height (default 10)
    TEXT_BAR_ICON_OFFSET_X                AS INTEGER        ' X offset of icon within button (default 1)
    TEXT_BAR_ICON_OFFSET_Y                AS INTEGER        ' Y offset of icon from row top (default 2)
    ' --- Text Formatting Bar: Swatch Geometry ---
    TEXT_BAR_SWATCH_WIDTH                 AS INTEGER        ' Color swatch width (default 10)
    TEXT_BAR_SWATCH_GAP                   AS INTEGER        ' Gap between FG and BG swatches (default 4)
    ' --- Text Formatting Bar: Dropdown Geometry ---
    TEXT_BAR_DROPDOWN_ARROW_W             AS INTEGER        ' Width for dropdown arrow glyph (default 6)
    TEXT_BAR_DROPDOWN_ITEM_H              AS INTEGER        ' Height of each dropdown list item (default 12)
    TEXT_BAR_DROPDOWN_PAD                 AS INTEGER        ' Inner padding of dropdown popup (default 4)
    TEXT_BAR_DROPDOWN_MIN_W               AS INTEGER        ' Minimum dropdown popup width (default 40)
    ' --- Text Formatting Bar: Label ---
    TEXT_BAR_LABEL_OFFSET_Y               AS INTEGER        ' Y offset of text labels from row top (default 3)
    ' --- Text Formatting Bar: Row 2 Icon Filenames ---
    TEXT_BAR_ICON_OUTLINE                 AS STRING * 64    ' Outline toggle icon PNG
    TEXT_BAR_ICON_SHADOW                  AS STRING * 64    ' Shadow toggle icon PNG
    TEXT_BAR_ICON_ALIGN_LEFT              AS STRING * 64    ' Align left icon PNG
    TEXT_BAR_ICON_ALIGN_CENTER            AS STRING * 64    ' Align center icon PNG
    TEXT_BAR_ICON_ALIGN_RIGHT             AS STRING * 64    ' Align right icon PNG
    TEXT_BAR_ICON_STYLE_UPDATE            AS STRING * 64    ' Style update icon PNG
    TEXT_BAR_ICON_STYLE_SAVE              AS STRING * 64    ' Style save/export icon PNG
    TEXT_BAR_ICON_STYLE_DELETE            AS STRING * 64    ' Style delete icon PNG
    TEXT_BAR_ICON_AUTO                    AS STRING * 64    ' Auto line-height icon PNG
    TEXT_BAR_ICON_CHAR                    AS STRING * 64    ' Char mode icon PNG
    TEXT_BAR_ICON_AA                      AS STRING * 64    ' Antialias toggle icon PNG
    ' --- Text Formatting Bar: Transparency Indicator ---
    TEXT_BAR_TRANSPARENT_CHECK_DARK       AS _UNSIGNED LONG ' Checkerboard dark square
    TEXT_BAR_TRANSPARENT_CHECK_LIGHT      AS _UNSIGNED LONG ' Checkerboard light square
    ' --- Text Layers ---
    LAYER_PANEL_TEXT_ACCENT               AS _UNSIGNED LONG ' Accent color for [T] text layer rows
    LAYER_PANEL_symbol_parent_bg          AS _UNSIGNED LONG ' Symbol parent row background
    LAYER_PANEL_symbol_parent_fg          AS _UNSIGNED LONG ' Symbol parent row name text
    LAYER_PANEL_symbol_child_bg           AS _UNSIGNED LONG ' Symbol child row background
    LAYER_PANEL_symbol_child_fg           AS _UNSIGNED LONG ' Symbol child row name text
    TEXT_LAYER_HOVER_OUTLINE              AS _UNSIGNED LONG ' Outline color when hovering editable text layer
    TEXT_LAYER_HOVER_OUTLINE_WIDTH        AS INTEGER        ' Stroke width in pixels for hover outline
    ' --- Character Map panel ---
    CHARMAP_BG                            AS _UNSIGNED LONG ' Panel background color
    CHARMAP_FG                            AS _UNSIGNED LONG ' Default glyph/text color
    CHARMAP_SELECTED_FG                   AS _UNSIGNED LONG ' Selected cell glyph color
    CHARMAP_SELECTED_BG                   AS _UNSIGNED LONG ' Selected cell background
    CHARMAP_HOVER_FG                      AS _UNSIGNED LONG ' Hovered cell glyph color
    CHARMAP_HOVER_BG                      AS _UNSIGNED LONG ' Hovered cell background
    CHARMAP_GRID_FG                       AS _UNSIGNED LONG ' Grid line color between cells
    CHARMAP_FLASH_FG                      AS _UNSIGNED LONG ' Typed character flash highlight color
    CHARMAP_SCROLLBAR_BG                  AS _UNSIGNED LONG ' Character map scrollbar track color
    CHARMAP_SCROLLBAR_FG                  AS _UNSIGNED LONG ' Character map scrollbar thumb color
    CHARMAP_SCROLLBAR_OPACITY             AS INTEGER        ' Character map scrollbar opacity (0-255)
    CHARMAP_SCROLLBAR_WIDTH               AS INTEGER        ' Character map scrollbar width in px (1-8)
    CHAR_GRID_COLOR_FG                    AS _UNSIGNED LONG ' Character grid overlay color on canvas
    ' --- Smart Guides ---
    SMART_GUIDES_color_fg                 AS _UNSIGNED LONG ' Guide line color (default magenta)
    SMART_GUIDES_opacity                  AS INTEGER        ' Guide line opacity 0-255 (default 180)
    SMART_GUIDES_outline_fg               AS _UNSIGNED LONG ' Guide line outline color (default black)
    SMART_GUIDES_outline_opacity          AS INTEGER        ' Outline opacity 0-255 (default 120)
    SMART_GUIDES_outline_width            AS INTEGER        ' Outline width in px (0 = none, default 1)
    SMART_GUIDES_pattern                  AS INTEGER        ' 16-bit LINE pattern (default &B1111000011110000)
    SMART_GUIDES_distance                 AS INTEGER        ' Detection distance in canvas px (default 4)
    ' --- Splash screen ---
    SPLASH_HOLD_TIME                      AS SINGLE         ' Seconds splash stays visible after fade-in (default 1.0)
    SPLASH_BG_COLOR                       AS _UNSIGNED LONG ' Splash background fill color (default black)
    SPLASH_VERSION_SHOW                   AS INTEGER        ' TRUE = render version string on splash (default TRUE)
    SPLASH_VERSION_PREFIX                 AS STRING         ' String prepended to APP_VERSION$ (default "v")
    SPLASH_VERSION_FONT                   AS STRING         ' Font filename, looked up via THEME_font_path$ (default "Tiny5-Regular.ttf")
    SPLASH_VERSION_FONT_SIZE              AS INTEGER        ' Font size in image-space pixels (default 8)
    SPLASH_VERSION_COLOR                  AS _UNSIGNED LONG ' Version text color (default RGB 145,164,240)
    SPLASH_VERSION_X                      AS INTEGER        ' X offset in image-space pixels from splash image top-left (default 45)
    SPLASH_VERSION_Y                      AS INTEGER        ' Y offset in image-space pixels from splash image top-left (default 32)
    ' --- Window ---
    WINDOW_BG_COLOR                       AS _UNSIGNED LONG ' Default window background color (default black)
    ' --- Opacity Slider (organizer col 1, rows 0+1) ---
    OPACITY_SLIDER_BG                     AS _UNSIGNED LONG ' Slider track fill (inactive / low-fill area)
    OPACITY_SLIDER_FG                     AS _UNSIGNED LONG ' Slider fill (active / high-fill area)
    OPACITY_SLIDER_BORDER_FG              AS _UNSIGNED LONG ' Slider outer border color
    OPACITY_SLIDER_BORDER_WIDTH           AS INTEGER        ' Slider border width in pixels
    OPACITY_SLIDER_PADDING                AS INTEGER        ' Pixels between border and track body (filled with BG color)
    OPACITY_SLIDER_HANDLE_HEIGHT          AS INTEGER        ' Height of handle bar in pixels
    OPACITY_SLIDER_TEXT_FG                AS _UNSIGNED LONG ' Percentage text color (normal)
    OPACITY_SLIDER_TEXT_BG                AS _UNSIGNED LONG ' Percentage text shadow/bg color (0 = none)
    OPACITY_SLIDER_HANDLE_FG              AS _UNSIGNED LONG ' Handle line color
    OPACITY_SLIDER_TEXT_WARN_FG           AS _UNSIGNED LONG ' Percentage text color when <= warn threshold
    OPACITY_SLIDER_TEXT_OUTLINE_FG        AS _UNSIGNED LONG ' Text stroke/outline color
    OPACITY_SLIDER_TEXT_OUTLINE_WIDTH     AS INTEGER        ' Text outline width in pixels (0 = off)
    OPACITY_SLIDER_WARN_FG                AS _UNSIGNED LONG ' Slider fill color when <= warn threshold
    OPACITY_SLIDER_WARN_BORDER_FG         AS _UNSIGNED LONG ' Border color when <= warn threshold
    ' --- CRT Overlay Effect ---
    CRT_SCANLINE_COLOR                    AS _UNSIGNED LONG ' Color of horizontal scanlines (alpha = base opacity)
    CRT_PHOSPHOR_R                        AS _UNSIGNED LONG ' R-channel phosphor strip color (RGBA)
    CRT_PHOSPHOR_G                        AS _UNSIGNED LONG ' G-channel phosphor strip color (RGBA)
    CRT_PHOSPHOR_B                        AS _UNSIGNED LONG ' B-channel phosphor strip color (RGBA)
    CRT_VIGNETTE_COLOR                    AS _UNSIGNED LONG ' Vignette edge color (alpha = edge opacity)
    CRT_TINT_AMBER                        AS _UNSIGNED LONG ' Amber monochrome tint (RGBA)
    CRT_TINT_GREEN                        AS _UNSIGNED LONG ' Green monochrome tint (RGBA)
    CRT_TINT_COOL                         AS _UNSIGNED LONG ' Cool blue monochrome tint (RGBA)
    CRT_ROLLING_BAR_COLOR                 AS _UNSIGNED LONG ' Rolling brightness band color (RGBA)
END TYPE

' Runtime theme loader — populates THEME from ASSETS/THEMES/{CFG.THEME$}/THEME.CFG

DIM SHARED THEME AS DRAW_THEME
DIM SHARED PALETTE_SEP_LOSPEC_LBL$  ' Section header label : Lospec downloaded palettes
DIM SHARED PALETTE_SEP_CREATED_LBL$ ' Section header label : created palettes
