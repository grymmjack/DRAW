'$INCLUDEONCE

' ============================================================================
' FD-THEME.BI — Self-contained theme constants for QB64_GJ_FILE_DIALOG
'
' No dependency on DRAW's THEME system. Flat dark theme.
'
' (c) 2026 grymmjack — MIT License
' ============================================================================

' --- Layout Constants --------------------------------------------------------

CONST FD_TITLE_BAR_H = 24           ' Title bar height
CONST FD_PATH_BAR_H = 28            ' Path bar height
CONST FD_TOOLBAR_H = 28             ' Toolbar height
CONST FD_COL_HEADER_H = 22          ' Column header height
CONST FD_STATUS_BAR_H = 22          ' Status bar height
CONST FD_BUTTON_BAR_H = 36          ' OK/Cancel button bar height
CONST FD_ROW_HEIGHT = 20            ' Row height in list/details mode
CONST FD_PLACES_DEFAULT_W = 160     ' Default places bar width
CONST FD_PREVIEW_DEFAULT_W = 200    ' Default preview pane width
CONST FD_SCROLLBAR_W = 12           ' Scrollbar width
CONST FD_THUMB_DEFAULT_SIZE = 64    ' Default thumbnail size
CONST FD_SPLITTER_W = 4             ' Splitter handle width
CONST FD_PADDING = 4                ' General padding
CONST FD_ICON_SIZE = 16             ' Small file-type icon size
CONST FD_RESIZE_GRIP = 6            ' Resize handle detection zone
CONST FD_BUTTON_W = 80              ' Standard button width
CONST FD_BUTTON_H = 24              ' Standard button height
CONST FD_MIN_DIALOG_W = 500         ' Minimum dialog width
CONST FD_MIN_DIALOG_H = 350         ' Minimum dialog height
CONST FD_DOUBLE_CLICK_MS = 0.4      ' Double-click threshold in seconds
CONST FD_CURSOR_BLINK_MS = 0.5      ' Cursor blink interval in seconds

' --- Color Palette (Dark Flat Theme) -----------------------------------------

' Background colors
CONST FD_CLR_BG~& = &HFF2D2D30              ' Main dialog background
CONST FD_CLR_TITLE_BG~& = &HFF3C3C3C        ' Title bar background
CONST FD_CLR_TITLE_BG_ACTIVE~& = &HFF007ACC ' Title bar when focused
CONST FD_CLR_TOOLBAR_BG~& = &HFF333337      ' Toolbar background
CONST FD_CLR_PLACES_BG~& = &HFF252526       ' Places bar background
CONST FD_CLR_CONTENT_BG~& = &HFF1E1E1E      ' Content area background
CONST FD_CLR_PREVIEW_BG~& = &HFF1E1E1E      ' Preview pane background
CONST FD_CLR_STATUS_BG~& = &HFF007ACC       ' Status bar background
CONST FD_CLR_BUTTON_BAR_BG~& = &HFF2D2D30   ' Button bar background
CONST FD_CLR_COL_HEADER_BG~& = &HFF333337   ' Column header background
CONST FD_CLR_PATH_BG~& = &HFF3C3C3C         ' Path bar background

' Text colors
CONST FD_CLR_TEXT~& = &HFFCCCCCC            ' Normal text
CONST FD_CLR_TEXT_DIM~& = &HFF808080        ' Dimmed / secondary text
CONST FD_CLR_TEXT_BRIGHT~& = &HFFFFFFFF     ' Bright text (titles, selected)
CONST FD_CLR_TEXT_DISABLED~& = &HFF5A5A5A   ' Disabled text
CONST FD_CLR_TEXT_ACCENT~& = &HFF3794FF     ' Accent text (links, active filter)

' Interactive element colors
CONST FD_CLR_HOVER~& = &HFF2A2D2E          ' Row/item hover highlight
CONST FD_CLR_SELECTED~& = &HFF094771       ' Selected item background
CONST FD_CLR_SELECTED_UNFOCUSED~& = &HFF37373D ' Selected when pane unfocused
CONST FD_CLR_BUTTON_BG~& = &HFF0E639C      ' Button background
CONST FD_CLR_BUTTON_HOVER~& = &HFF1177BB    ' Button hover
CONST FD_CLR_BUTTON_TEXT~& = &HFFFFFFFF     ' Button text

' Border / separator colors
CONST FD_CLR_BORDER~& = &HFF3C3C3C         ' Panel borders
CONST FD_CLR_BORDER_FOCUS~& = &HFF007ACC   ' Focused input border
CONST FD_CLR_SPLITTER~& = &HFF3C3C3C       ' Splitter line
CONST FD_CLR_DIVIDER~& = &HFF404040        ' Horizontal dividers
CONST FD_CLR_COL_RESIZE~& = &HFF007ACC     ' Column resize line

' Input field colors
CONST FD_CLR_INPUT_BG~& = &HFF3C3C3C       ' Text input background
CONST FD_CLR_INPUT_BORDER~& = &HFF555555    ' Text input border
CONST FD_CLR_INPUT_FOCUS_BG~& = &HFF1E1E1E ' Text input focused background
CONST FD_CLR_INPUT_CURSOR~& = &HFFAEAFAD   ' Text cursor color

' Scrollbar colors
CONST FD_CLR_SCROLLBAR_BG~& = &HFF1E1E1E   ' Scrollbar track
CONST FD_CLR_SCROLLBAR_THUMB~& = &HFF424242 ' Scrollbar thumb
CONST FD_CLR_SCROLLBAR_HOVER~& = &HFF4F4F4F ' Scrollbar thumb hover

' File type icon colors
CONST FD_CLR_ICON_FOLDER~& = &HFFDCB67A    ' Folder icon color (gold)
CONST FD_CLR_ICON_IMAGE~& = &HFF6A9955     ' Image file icon color (green)
CONST FD_CLR_ICON_DOC~& = &HFF569CD6       ' Document icon color (blue)
CONST FD_CLR_ICON_DEFAULT~& = &HFF808080   ' Default file icon color (gray)

' Checkerboard for preview transparency
CONST FD_CLR_CHECK_A~& = &HFF404040        ' Checker dark
CONST FD_CLR_CHECK_B~& = &HFF606060        ' Checker light

' Sort indicator
CONST FD_CLR_SORT_ARROW~& = &HFFCCCCCC     ' Sort direction arrow
