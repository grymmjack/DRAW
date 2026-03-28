'$INCLUDEONCE

' ============================================================================
' MB-THEME.BI — Self-contained theme constants for QB64_GJ_MSG_BOX
'
' No dependency on DRAW's THEME system. Flat dark theme matching FILE-DIALOG.
'
' (c) 2026 grymmjack — MIT License
' ============================================================================

' --- Layout Constants --------------------------------------------------------

CONST MB_TITLE_BAR_H = 24               ' Title bar height
CONST MB_BUTTON_BAR_H = 44              ' Button bar height (with padding)
CONST MB_BUTTON_W = 80                  ' Standard button width
CONST MB_BUTTON_H = 26                  ' Standard button height
CONST MB_BUTTON_GAP = 8                 ' Gap between buttons
CONST MB_PADDING = 16                   ' General padding around content
CONST MB_ICON_SIZE = 32                 ' Icon area width/height
CONST MB_ICON_GAP = 12                  ' Gap between icon and message text
CONST MB_INPUT_H = 24                   ' Input field height
CONST MB_INPUT_GAP = 8                  ' Gap between message and input field
CONST MB_MIN_DIALOG_W = 300             ' Minimum dialog width
CONST MB_MAX_DIALOG_W = 600             ' Maximum dialog width (for text wrapping)
CONST MB_MIN_DIALOG_H = 120             ' Minimum dialog height
CONST MB_LINE_HEIGHT = 18               ' Line height for message text
CONST MB_CHAR_W = 8                     ' Character width (default font)

' --- Color Palette (Dark Flat Theme — matches FILE-DIALOG) -------------------

' Background colors
CONST MB_CLR_BG~& = &HFF2D2D30                  ' Main dialog background
CONST MB_CLR_TITLE_BG~& = &HFF007ACC            ' Title bar background
CONST MB_CLR_BUTTON_BAR_BG~& = &HFF252526       ' Button bar background
CONST MB_CLR_CONTENT_BG~& = &HFF2D2D30          ' Content area background

' Text colors
CONST MB_CLR_TEXT~& = &HFFCCCCCC                 ' Normal text
CONST MB_CLR_TEXT_BRIGHT~& = &HFFFFFFFF          ' Bright text (titles)
CONST MB_CLR_TEXT_DIM~& = &HFF808080             ' Dimmed text

' Button colors
CONST MB_CLR_BUTTON_BG~& = &HFF0E639C           ' Primary button background
CONST MB_CLR_BUTTON_HOVER~& = &HFF1177BB         ' Button hover
CONST MB_CLR_BUTTON_TEXT~& = &HFFFFFFFF          ' Button text
CONST MB_CLR_BUTTON_SECONDARY~& = &HFF3C3C3C    ' Secondary button background
CONST MB_CLR_BUTTON_SEC_HOVER~& = &HFF505050     ' Secondary button hover
CONST MB_CLR_BUTTON_SEC_TEXT~& = &HFFCCCCCC      ' Secondary button text
CONST MB_CLR_BUTTON_FOCUS~& = &HFF007ACC         ' Focused button outline

' Border colors
CONST MB_CLR_BORDER~& = &HFF3C3C3C              ' Dialog border
CONST MB_CLR_DIVIDER~& = &HFF404040             ' Divider line

' Icon colors
CONST MB_CLR_ICON_INFO~& = &HFF3794FF           ' Info icon (blue)
CONST MB_CLR_ICON_WARNING~& = &HFFDCB67A        ' Warning icon (yellow/gold)
CONST MB_CLR_ICON_ERROR~& = &HFFFF6B68          ' Error icon (red)
CONST MB_CLR_ICON_QUESTION~& = &HFF3794FF       ' Question icon (blue)

' Shadow / overlay
CONST MB_CLR_OVERLAY~& = &H80000000             ' Screen overlay (50% black)
