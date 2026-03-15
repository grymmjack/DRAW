''
' DRAW - GUI/TOOLTIP.BI
' =============================================================================
' Tooltip system for toolbar buttons, organizer widgets, and drawer mini palette.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

' Tooltip hover source constants
CONST TOOLTIP_SRC_NONE      = 0
CONST TOOLTIP_SRC_TOOLBAR   = 1
CONST TOOLTIP_SRC_ORGANIZER = 2
CONST TOOLTIP_SRC_MINI_PAL  = 3
CONST TOOLTIP_SRC_DOCK_SWAP = 4

TYPE TOOLTIP_OBJ
    ACTIVE          AS INTEGER      ' TRUE when a tooltip is currently visible
    HOVER_BTN_IDX   AS INTEGER      ' Index into currently hovered element (-1 = none)
    HOVER_SOURCE    AS INTEGER      ' Which UI area: TOOLTIP_SRC_* constant
    HOVER_START     AS DOUBLE       ' TIMER value when hover began
    FONT_HANDLE     AS LONG         ' Loaded font handle for tooltip text
END TYPE

DIM SHARED TOOLTIP AS TOOLTIP_OBJ
TOOLTIP.HOVER_BTN_IDX% = -1
TOOLTIP.HOVER_SOURCE% = TOOLTIP_SRC_NONE

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

' Organizer widget tooltip text arrays — indexed by ORG_* constants (0..10)
DIM SHARED TOOLTIP_ORG_LINE1$(0 TO 10)
DIM SHARED TOOLTIP_ORG_LINE2$(0 TO 10)

' 0 = ORG_COLOR_OPS
TOOLTIP_ORG_LINE1$(0) = "COLOR OPS - L-CLICK to IMPORT, R-CLICK to LOAD from Lospec"
TOOLTIP_ORG_LINE2$(0) = "See the PALETTE MENU in the MENUBAR for more options."
' 1 = ORG_CANVAS_OPS
TOOLTIP_ORG_LINE1$(1) = "CANVAS OPS - L-CLICK to switch to SPARE PAGE. R-CLICK to CLEAR SPARE PAGE."
TOOLTIP_ORG_LINE2$(1) = "Use SPARE PAGE as a scratchpad, test area, assembly canvas, etc."
' 2 = ORG_BRUSH_SIZE
TOOLTIP_ORG_LINE1$(2) = "CTRL+WHEEL - Change brush size. Click width to change."
TOOLTIP_ORG_LINE2$(2) = "Make selection and use CTRL-b to create custom brush, then store it in bin for later recall."
' 3 = ORG_PATTERN_MODE
TOOLTIP_ORG_LINE1$(3) = "F3 - DRAW MODE: PATTERN"
TOOLTIP_ORG_LINE2$(3) = "All fills will use patterns. Pick color to change opaque pixels of pattern. R-CLICK on patterns for menu."
' 4 = ORG_PALETTE_OPS
TOOLTIP_ORG_LINE1$(4) = "PALETTE OPS - L-CLICK remap image to current palette."
TOOLTIP_ORG_LINE2$(4) = "Try CTRL-ALT-r to choose a RANDOM palette then remap, for inspiration!"
' 5 = ORG_TRANSFORM_OPS
TOOLTIP_ORG_LINE1$(5) = "TRANSFORM OPS - L-CLICK icon on left to flip HORIZONTALLY. right to flip VERTICALLY."
TOOLTIP_ORG_LINE2$(5) = "See the EDIT -> TRANSFORM menu in the MENUBAR for more transformations."
' 6 = ORG_GRADIENT_MODE
TOOLTIP_ORG_LINE1$(6) = "F2 - DRAW MODE: GRADIENT"
TOOLTIP_ORG_LINE2$(6) = "All fills will use gradients. R-CLICK on gradients for menu, and editor."
' 7 = ORG_SYMMETRY_MODE
TOOLTIP_ORG_LINE1$(7) = "SYMMETRY MODE - L-CLICK toggle. WHEEL over icon change SYMMETRY TYPE."
TOOLTIP_ORG_LINE2$(7) = "DRAW mirrored or kaleidoscopic patterns at once."
' 8 = ORG_GRID_VIS
TOOLTIP_ORG_LINE1$(8) = "' - GRID - Toggle show/hide of grid. WHEEL over icon to change GRID TYPE."
TOOLTIP_ORG_LINE2$(8) = ". / , to change GRID size. SHIFT+' show/hide PIXEL GRID. CTRL+SHIFT+/ make GRID brush size."
' 9 = ORG_GRID_SNAP
TOOLTIP_ORG_LINE1$(9) = "; - SNAP TO GRID - Toggle grid snapping. WHEEL over icon = change SNAP TYPE."
TOOLTIP_ORG_LINE2$(9) = "/ to change SNAP TYPE - CENTER, or CORNER."
' 10 = ORG_COLOR_MODE
TOOLTIP_ORG_LINE1$(10) = "F1 - DRAW MODE: BRUSH - L-CLICK BL = SWAP FG/BG. R-CLICK BL = DEFAULT colors."
TOOLTIP_ORG_LINE2$(10) = "All drawing tools will use custom brushes. R-CLICK on brushes for menu."

' Drawer mini palette tooltip text
DIM SHARED TOOLTIP_MINI_PAL_LINE1$
DIM SHARED TOOLTIP_MINI_PAL_LINE2$
TOOLTIP_MINI_PAL_LINE1$ = "MINI PALETTE - L-CLICK choose FG color. R-CLICK choose BG color."
TOOLTIP_MINI_PAL_LINE2$ = "You can use any image for this palette, see the documentation."

' Dock swap tooltip text (for blank panel areas)
DIM SHARED TOOLTIP_DOCK_LINE1$
DIM SHARED TOOLTIP_DOCK_LINE2$
TOOLTIP_DOCK_LINE1$ = "CTRL+SHIFT+L-CLICK LAYOUT DOCK EDGE"
TOOLTIP_DOCK_LINE2$ = "Click once while holding SHIFT and CTRL to swap this panel to dock on other side of window."

DECLARE SUB TOOLTIP_update ()
DECLARE SUB TOOLTIP_render (target&)
DECLARE SUB TOOLTIP_reset ()
DECLARE FUNCTION TOOLTIP_get_hovered_btn_idx% (mouseX%, mouseY%)
DECLARE FUNCTION TOOLTIP_get_hovered_org_idx% (mouseX%, mouseY%)
DECLARE FUNCTION TOOLTIP_get_hovered_mini_pal% (mouseX%, mouseY%)
DECLARE FUNCTION TOOLTIP_get_hovered_dock_area% (mouseX%, mouseY%)
