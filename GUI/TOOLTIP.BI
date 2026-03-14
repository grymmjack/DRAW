''
' DRAW - GUI/TOOLTIP.BI
' =============================================================================
' Tooltip system for toolbar buttons.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

TYPE TOOLTIP_OBJ
    ACTIVE          AS INTEGER      ' TRUE when a tooltip is currently visible
    HOVER_BTN_IDX   AS INTEGER      ' Toolbar button order index currently hovered (-1 = none)
    HOVER_START     AS DOUBLE       ' TIMER value when hover began
    FONT_HANDLE     AS LONG         ' Loaded font handle for tooltip text
END TYPE

DIM SHARED TOOLTIP AS TOOLTIP_OBJ
TOOLTIP.HOVER_BTN_IDX% = -1

' Tooltip text arrays — indexed by toolbar button order (0..TB_TOTAL-1)
DIM SHARED TOOLTIP_LINE1$(0 TO 27) ' First line: hotkey + tool name + description
DIM SHARED TOOLTIP_LINE2$(0 TO 27) ' Second line: status/usage hints

' Row 0: MOVE, PAN, ZOOM, CROP
TOOLTIP_LINE1$(0)  = "m - MOVE - Position current selection or selected layers on the canvas."
TOOLTIP_LINE2$(0)  = "DRAG move. ALT clones. SHIFT constrains. ARROWS nudge. SHIFT+ARROWS = nudge more."
TOOLTIP_LINE1$(1)  = "SPACE - PAN - Pan the canvas in the window to adjust what is in view."
TOOLTIP_LINE2$(1)  = "DRAG pan. D-CLICK center / fit."
TOOLTIP_LINE1$(2)  = "z - ZOOM - Magnify part of the canvas for more precise drawing."
TOOLTIP_LINE2$(2)  = "DRAG zoom area. M-WHEEL zoom in/out."
TOOLTIP_LINE1$(3)  = "CROP - Select a part of the canvas and trim everything outside away."
TOOLTIP_LINE2$(3)  = "DRAG select. SHIFT constrain."

' Row 1: MARQ RECT, MARQ FREEHAND, MARQ POLY, MARQ ELLIPSE
TOOLTIP_LINE1$(4)  = "m - RECTANGLE MARQUEE - Create rectangular selections."
TOOLTIP_LINE2$(4)  = "DRAG to select. SHIFT add. ALT subtract."
TOOLTIP_LINE1$(5)  = "FREEHAND MARQUEE - Create any shape free-form selections."
TOOLTIP_LINE2$(5)  = "DRAW to select. SHIFT+CTRL Snap. SHIFT add. ALT subtract."
TOOLTIP_LINE1$(6)  = "POLYGONAL MARQUEE - Create a selection shape using points and lines."
TOOLTIP_LINE2$(6)  = "DRAW selection shape. L-CLICK create point. R-CLICK finish."
TOOLTIP_LINE1$(7)  = "ELLIPTICAL MARQUEE - Create an elliptical shaped selection."
TOOLTIP_LINE2$(7)  = "DRAG to select. SHIFT add. ALT subtract."

' Row 2: MARQ WAND, PICKER, TEXT, ERASER
TOOLTIP_LINE1$(8)  = "w - WAND MARQUEE - Create a selection by same colors."
TOOLTIP_LINE2$(8)  = "CLICK to select on layer. SHIFT+CLICK to select on full image. SHIFT add. ALT subtract."
TOOLTIP_LINE1$(9)  = "i - COLOR PICKER - Use the color syringe to pickup a color off the canvas."
TOOLTIP_LINE2$(9)  = "L-CLICK to pick FG color. R-CLICK pick BG color. HOLD R sample reference."
TOOLTIP_LINE1$(10) = "t / SHIFT+t / CTRL+t - TEXT - Create text / small text / custom font text."
TOOLTIP_LINE2$(10) = "CLICK position cursor. TYPE to enter text. ESC done."
TOOLTIP_LINE1$(11) = "e - ERASER - Erase pixels back to transparency."
TOOLTIP_LINE2$(11) = "DRAG erase. SHIFT+DRAG erase all layers. HOLD E in other tools to temp. erase."

' Row 3: DOT, BRUSH, SPRAY, FILL
TOOLTIP_LINE1$(12) = "d - DOT - Paint once at brush size, or place a single custom brush."
TOOLTIP_LINE2$(12) = "CLICK draw. D-CLICK reset brush. L-CLICK FG color. R-CLICK BG color. HOLD E erase."
TOOLTIP_LINE1$(13) = "b - BRUSH - Paint continuously."
TOOLTIP_LINE2$(13) = "DRAG draw. L-CLICK FG color. R-CLICK BG color. HOLD E erase. CTRL+WHEEL brush size."
TOOLTIP_LINE1$(14) = "k - SPRAY - Paint with randomly distributed points at brush size."
TOOLTIP_LINE2$(14) = "DRAG draw. L-CLICK FG color. R-CLICK BG color. HOLD E erase. CTRL+WHEEL spray size."
TOOLTIP_LINE1$(15) = "f - FILL - Color in contiguous areas of canvas with borders or same colors."
TOOLTIP_LINE2$(15) = "L-CLICK fill FG color. R-CLICK fill BG color. SHIFT+CLICK canvas area."

' Row 4: LINE, POLYLINE, POLYFILL, SAVE
TOOLTIP_LINE1$(16) = "l - LINE - Create straight lines at any angle."
TOOLTIP_LINE2$(16) = "DRAG draw. L-CLICK FG color. R-CLICK BG color. CTRL+SHIFT snap."
TOOLTIP_LINE1$(17) = "p - POLYGONAL LINE - Create polygonal shapes using connected lines."
TOOLTIP_LINE2$(17) = "DRAW shape. L-CLICK create point. R-CLICK finish."
TOOLTIP_LINE1$(18) = "SHIFT+p - FILLED POLYGON - Create filled polygonal shapes using connected lines."
TOOLTIP_LINE2$(18) = "DRAW filled shape. L-CLICK create point. R-CLICK finish."
TOOLTIP_LINE1$(19) = "CTRL+s - SAVE IMAGE to disk."
TOOLTIP_LINE2$(19) = "CTRL+SHIFT+s SAVE AS NEW image to disk."

' Row 5: QB64/CODE, RECT, RECT FILLED, EXPORT SEL
TOOLTIP_LINE1$(20) = "EXPORT QB64PE Source Code."
TOOLTIP_LINE2$(20) = "Save as .BAS for learning and dissection and usage in your own programs."
TOOLTIP_LINE1$(21) = "r - RECTANGLE - Create rectangle shapes on the canvas."
TOOLTIP_LINE2$(21) = "DRAW rectangle. L-CLICK FG color. R-CLICK BG color. CTRL+SHIFT snap."
TOOLTIP_LINE1$(22) = "SHIFT+r - FILLED RECTANGLE - Create filled rectangle shapes on the canvas."
TOOLTIP_LINE2$(22) = "DRAW filled rectangle. L-CLICK FG color. R-CLICK BG color. CTRL+SHIFT snap."
TOOLTIP_LINE1$(23) = "CTRL+SHIFT+ALT+s - EXPORT SELECTION."
TOOLTIP_LINE2$(23) = "Saves the selected area to disk."

' Row 6: HELP, ELLIPSE, ELLIPSE FILLED, OPEN
TOOLTIP_LINE1$(24) = "? - COMMAND PALETTE."
TOOLTIP_LINE2$(24) = "Show a searchable cheat sheet of commands and keyboard shortcuts."
TOOLTIP_LINE1$(25) = "c - ELLIPSE/CIRCLE - Create ellipses and circles on the canvas."
TOOLTIP_LINE2$(25) = "DRAW ellipse. L-CLICK FG color. R-CLICK BG color. CTRL+SHIFT snap."
TOOLTIP_LINE1$(26) = "SHIFT+c - FILLED ELLIPSE/CIRCLE - Create filled ellipses and filled circles on the canvas."
TOOLTIP_LINE2$(26) = "DRAW filled ellipse. L-CLICK FG color. R-CLICK BG color. CTRL+SHIFT snap."
TOOLTIP_LINE1$(27) = "CTRL+o - LOAD IMAGE from disk."
TOOLTIP_LINE2$(27) = "SHIFT+CTRL+o - IMPORT and PLACE image from disk."

DECLARE SUB TOOLTIP_update ()
DECLARE SUB TOOLTIP_render (target&)
DECLARE SUB TOOLTIP_reset ()
DECLARE FUNCTION TOOLTIP_get_hovered_btn_idx% (mouseX%, mouseY%)
