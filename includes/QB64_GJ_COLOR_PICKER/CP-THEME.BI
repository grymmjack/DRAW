'$INCLUDEONCE

' ============================================================================
' CP-THEME.BI — Self-contained theme constants for QB64_GJ_COLOR_PICKER
'
' No dependency on DRAW's THEME system. Flat dark theme.
'
' (c) 2026 grymmjack — MIT License
' ============================================================================

' --- Layout Constants --------------------------------------------------------

CONST CP_TITLE_BAR_H = 24               ' Title bar height
CONST CP_BUTTON_BAR_H = 44              ' Button bar height
CONST CP_BUTTON_W = 80                  ' Standard button width
CONST CP_BUTTON_H = 26                  ' Standard button height
CONST CP_BUTTON_GAP = 8                 ' Gap between buttons
CONST CP_PADDING = 12                   ' General padding
CONST CP_SLIDER_H = 16                  ' Slider track height
CONST CP_SLIDER_GAP = 6                 ' Gap between sliders
CONST CP_PREVIEW_H = 32                 ' Color preview swatch height
CONST CP_PREVIEW_W = 60                 ' Each preview swatch width
CONST CP_HEX_INPUT_H = 22              ' Hex input field height
CONST CP_SECTION_GAP = 10               ' Gap between major sections
CONST CP_LABEL_W = 24                   ' Width of slider labels ("R:", etc.)
CONST CP_VALUE_W = 32                   ' Width of slider value numbers
CONST CP_CHAR_W = 8                     ' Character width (default font)
CONST CP_COPY_BTN_W = 40                ' Copy button width
CONST CP_PASTE_BTN_W = 44               ' Paste button width
CONST CP_POSTERIZE_ROW_H = 20           ' Posterize option row height
CONST CP_SNAP_CHIP_W = 20               ' Width of each snap level chip
CONST CP_SNAP_CHIP_GAP = 2              ' Gap between snap chips

' --- Color Palette (Dark Flat Theme) -----------------------------------------

' Background colors
CONST CP_CLR_BG~& = &HFF2D2D30
CONST CP_CLR_TITLE_BG~& = &HFF007ACC
CONST CP_CLR_BUTTON_BAR_BG~& = &HFF252526
CONST CP_CLR_CONTENT_BG~& = &HFF2D2D30

' Text colors
CONST CP_CLR_TEXT~& = &HFFCCCCCC
CONST CP_CLR_TEXT_BRIGHT~& = &HFFFFFFFF
CONST CP_CLR_TEXT_DIM~& = &HFF808080

' Button colors
CONST CP_CLR_BUTTON_BG~& = &HFF0E639C
CONST CP_CLR_BUTTON_HOVER~& = &HFF1177BB
CONST CP_CLR_BUTTON_TEXT~& = &HFFFFFFFF
CONST CP_CLR_BUTTON_SECONDARY~& = &HFF3C3C3C
CONST CP_CLR_BUTTON_SEC_HOVER~& = &HFF505050
CONST CP_CLR_BUTTON_SEC_TEXT~& = &HFFCCCCCC
CONST CP_CLR_BUTTON_FOCUS~& = &HFF007ACC

' Border / structural
CONST CP_CLR_BORDER~& = &HFF3C3C3C
CONST CP_CLR_DIVIDER~& = &HFF404040
CONST CP_CLR_SLIDER_BG~& = &HFF1E1E1E
CONST CP_CLR_SLIDER_BORDER~& = &HFF555555

' Overlay
CONST CP_CLR_OVERLAY~& = &H80000000

' Checkerboard (for transparency preview)
CONST CP_CLR_CHECK_A~& = &HFF404040
CONST CP_CLR_CHECK_B~& = &HFF606060
