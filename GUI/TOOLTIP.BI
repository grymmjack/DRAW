''
' DRAW - GUI/TOOLTIP.BI
' =============================================================================
' Tooltip system for toolbar buttons, organizer widgets, and drawer mini palette.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

' Tooltip hover source constants
CONST TOOLTIP_SRC_NONE          = 0
CONST TOOLTIP_SRC_TOOLBAR       = 1
CONST TOOLTIP_SRC_ORGANIZER     = 2
CONST TOOLTIP_SRC_MINI_PAL      = 3
CONST TOOLTIP_SRC_DOCK_SWAP     = 4
CONST TOOLTIP_SRC_EDITBAR       = 5
CONST TOOLTIP_SRC_ADVBAR        = 6
CONST TOOLTIP_SRC_BINS          = 7
CONST TOOLTIP_SRC_LAYER_NAME    = 8
CONST TOOLTIP_SRC_LAYER_OPACITY = 9

TYPE TOOLTIP_OBJ
    ACTIVE        AS INTEGER ' TRUE when a tooltip is currently visible
    HOVER_BTN_IDX AS INTEGER ' Index into currently hovered element (-1 = none)
    HOVER_SOURCE  AS INTEGER ' Which UI area: TOOLTIP_SRC_* constant
    HOVER_START   AS DOUBLE  ' TIMER value when hover began
    FONT_HANDLE   AS LONG    ' Loaded font handle for tooltip text
    NEEDS_REDRAW  AS INTEGER ' One-shot: set on state change, cleared after render
    RENDER_X      AS INTEGER ' Last-rendered tooltip X (canvas coords; 0 if none this frame)
    RENDER_Y      AS INTEGER ' Last-rendered tooltip Y (canvas coords)
    RENDER_W      AS INTEGER ' Last-rendered tooltip width  (0 = none drawn this frame)
    RENDER_H      AS INTEGER ' Last-rendered tooltip height
    DYNAMIC_TEXT  AS STRING  ' Tooltip text for dynamic sources (e.g. layer name)
END TYPE

DIM SHARED TOOLTIP AS TOOLTIP_OBJ
TOOLTIP.HOVER_BTN_IDX% = -1
TOOLTIP.HOVER_SOURCE%  = TOOLTIP_SRC_NONE

' Tooltip text arrays — indexed by toolbar button order (0..TB_TOTAL-1)
DIM SHARED TOOLTIP_LINE1$(0 TO 27) ' First line  : hotkey + tool name + description
DIM SHARED TOOLTIP_LINE2$(0 TO 27) ' Second line : status/usage hints

' Row 0: MOVE, PAN, ZOOM, CROP
TOOLTIP_LINE1$(0) = "m - MOVE - Position current selection or selected layers on the canvas."
TOOLTIP_LINE2$(0) = "DRAG move. ALT clones. SHIFT constrains. ARROWS nudge. SHIFT+ARROWS = nudge more."
TOOLTIP_LINE1$(1) = "SPACE - PAN - Pan the canvas in the window to adjust what is in view."
TOOLTIP_LINE2$(1) = "DRAG pan. D-CLICK center / fit."
TOOLTIP_LINE1$(2) = "z - ZOOM - Magnify part of the canvas for more precise drawing."
TOOLTIP_LINE2$(2) = "DRAG zoom area. M-WHEEL zoom in/out."
TOOLTIP_LINE1$(3) = "CROP - Select a part of the canvas and trim everything outside away."
TOOLTIP_LINE2$(3) = "DRAG select. SHIFT constrain."

' Row 1: MARQ RECT, MARQ FREEHAND, MARQ POLY, MARQ ELLIPSE
TOOLTIP_LINE1$(4) = "m - RECTANGLE MARQUEE - Create rectangular selections."
TOOLTIP_LINE2$(4) = "DRAG to select. SHIFT add. ALT subtract."
TOOLTIP_LINE1$(5) = "FREEHAND MARQUEE - Create any shape free-form selections."
TOOLTIP_LINE2$(5) = "DRAW to select. SHIFT+CTRL Snap. SHIFT add. ALT subtract."
TOOLTIP_LINE1$(6) = "POLYGONAL MARQUEE - Create a selection shape using points and lines."
TOOLTIP_LINE2$(6) = "DRAW selection shape. L-CLICK create point. R-CLICK finish."
TOOLTIP_LINE1$(7) = "ELLIPTICAL MARQUEE - Create an elliptical shaped selection."
TOOLTIP_LINE2$(7) = "DRAG to select. SHIFT add. ALT subtract."

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
TOOLTIP_LINE1$(27) = "Open Browser - Browse and open images from disk."
TOOLTIP_LINE2$(27) = "Drag and drop images onto layers, bins, and canvas."

' Organizer widget tooltip text arrays — indexed by ORG_* constants (0..10)
DIM SHARED TOOLTIP_ORG_LINE1$(0 TO 10)
DIM SHARED TOOLTIP_ORG_LINE2$(0 TO 10)

' 0 = ORG_COLOR_MIXER
TOOLTIP_ORG_LINE1$(0) = "COLOR MIXER - L-CLICK to show/hide color mixer panel."
TOOLTIP_ORG_LINE2$(0) = "Mix and pick colors with HSV square, hue bar, and RGB/HSL sliders."
' 1 = ORG_CANVAS_OPS (now Opacity Slider)
TOOLTIP_ORG_LINE1$(1) = "OPACITY - Use 1-9 keys to set 10%-90% and 0 for 100% opacity."
TOOLTIP_ORG_LINE2$(1) = "MWHEEL to adjust by 1%. SHIFT+MWHEEL to adjust by 10% increments."
' 2 = ORG_BRUSH_SIZE
TOOLTIP_ORG_LINE1$(2) = "CTRL+WHEEL - Change brush size. Click width to change."
TOOLTIP_ORG_LINE2$(2) = "Make selection and use CTRL-b to create custom brush, then store it in bin for later recall."
' 3 = ORG_PATTERN_MODE
TOOLTIP_ORG_LINE1$(3) = "F3 - DRAW MODE: PATTERN"
TOOLTIP_ORG_LINE2$(3) = "All fills will use patterns. Pick color to change opaque pixels of pattern. R-CLICK on patterns for menu."
' 4 = ORG_PALETTE_OPS
TOOLTIP_ORG_LINE1$(4) = "PALETTE OPS - L-CLICK remap image to current palette. R-CLICK to exit."
TOOLTIP_ORG_LINE2$(4) = "Try CTRL-ALT-r to choose a RANDOM palette then remap, for inspiration!"
' 5 = ORG_TRANSFORM_OPS (now part of opacity slider — no separate tooltip)
TOOLTIP_ORG_LINE1$(5) = "OPACITY - Use 1-9 keys to set 10%-90% and 0 for 100% opacity."
TOOLTIP_ORG_LINE2$(5) = "MWHEEL to adjust by 1%. SHIFT+MWHEEL to adjust by 10% increments."
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

DIM SHARED TOOLTIP_BINS_LINE1$
DIM SHARED TOOLTIP_BINS_LINE2$
TOOLTIP_BINS_LINE1$ = "BIN - L-CLICK Select/Use. SHIFT+L-CLICK Store into bin. R-CLICK for Menu."
TOOLTIP_BINS_LINE2$ = "Use M-WHEEL UP and M-WHEEL DOWN to navigate through drawer sets for current drawing mode."


' --- Edit Bar tooltip text arrays (indexed by EDITBAR slot 0..31) ---
DIM SHARED TOOLTIP_EB_LINE1$(0 TO 31)
DIM SHARED TOOLTIP_EB_LINE2$(0 TO 31)

' Slot 0: Undo
TOOLTIP_EB_LINE1$(0) = "CTRL+z - Undo"
TOOLTIP_EB_LINE2$(0) = "L-CLICK undo last action."
' Slot 1: Redo
TOOLTIP_EB_LINE1$(1) = "CTRL+y - Redo"
TOOLTIP_EB_LINE2$(1) = "L-CLICK redo last undone action."
' Slot 2: divider
' Slot 3: Cut
TOOLTIP_EB_LINE1$(3) = "CTRL+x - Cut"
TOOLTIP_EB_LINE2$(3) = "L-CLICK cut selection to clipboard."
' Slot 4: Copy
TOOLTIP_EB_LINE1$(4) = "CTRL+c - Copy"
TOOLTIP_EB_LINE2$(4) = "L-CLICK copy selection to clipboard."
' Slot 5: Copy Merged
TOOLTIP_EB_LINE1$(5) = "CTRL+SHIFT+c - Copy Merged"
TOOLTIP_EB_LINE2$(5) = "L-CLICK copy merged (all visible layers) to clipboard."
' Slot 6: Paste
TOOLTIP_EB_LINE1$(6) = "CTRL+v - Paste"
TOOLTIP_EB_LINE2$(6) = "L-CLICK paste clipboard contents at cursor."
' Slot 7: Paste in Place
TOOLTIP_EB_LINE1$(7) = "CTRL+SHIFT+v - Paste in Place"
TOOLTIP_EB_LINE2$(7) = "L-CLICK paste clipboard contents at original position."
' Slot 8: divider
' Slot 9: Cut to New Layer
TOOLTIP_EB_LINE1$(9) = "Cut to New Layer"
TOOLTIP_EB_LINE2$(9) = "L-CLICK cut selection to a new layer."
' Slot 10: Copy to New Layer
TOOLTIP_EB_LINE1$(10) = "Copy to New Layer"
TOOLTIP_EB_LINE2$(10) = "L-CLICK copy selection to a new layer."
' Slot 11: divider
' Slot 12: Clear
TOOLTIP_EB_LINE1$(12) = "DEL - Clear"
TOOLTIP_EB_LINE2$(12) = "L-CLICK clear selection or layer."
' Slot 13: divider
' Slot 14: Fill with FG
TOOLTIP_EB_LINE1$(14) = "Fill with Foreground Color"
TOOLTIP_EB_LINE2$(14) = "L-CLICK fill selection or layer with FG color."
' Slot 15: Fill with BG
TOOLTIP_EB_LINE1$(15) = "Fill with Background Color"
TOOLTIP_EB_LINE2$(15) = "L-CLICK fill selection or layer with BG color."
' Slot 16: Stroke Selection
TOOLTIP_EB_LINE1$(16) = "Stroke Selection"
TOOLTIP_EB_LINE2$(16) = "L-CLICK stroke the selection outline with FG color."
' Slot 17: divider
' Slot 18: Flip Horizontal
TOOLTIP_EB_LINE1$(18) = "Flip Horizontal"
TOOLTIP_EB_LINE2$(18) = "L-CLICK flip layer or selection horizontally."
' Slot 19: Flip Vertical
TOOLTIP_EB_LINE1$(19) = "Flip Vertical"
TOOLTIP_EB_LINE2$(19) = "L-CLICK flip layer or selection vertically."
' Slot 20: Scale Down
TOOLTIP_EB_LINE1$(20) = "Scale Down 50%"
TOOLTIP_EB_LINE2$(20) = "L-CLICK shrink layer or selection by half."
' Slot 21: Scale Up
TOOLTIP_EB_LINE1$(21) = "Scale Up 200%"
TOOLTIP_EB_LINE2$(21) = "L-CLICK enlarge layer or selection by double."
' Slot 22: Rotate CW
TOOLTIP_EB_LINE1$(22) = "Rotate 90 CW"
TOOLTIP_EB_LINE2$(22) = "L-CLICK rotate layer or selection 90 degrees clockwise."
' Slot 23: Rotate CCW
TOOLTIP_EB_LINE1$(23) = "Rotate 90 CCW"
TOOLTIP_EB_LINE2$(23) = "L-CLICK rotate layer or selection 90 degrees counter-clockwise."
' Slot 24: divider
' Slot 25: Smart Guides
TOOLTIP_EB_LINE1$(25) = "Smart Guides ON/OFF"
TOOLTIP_EB_LINE2$(25) = "Dynamically show guides related to geometric boundaries of neighboring layers."
' Slot 26: Snap Smart Guides
TOOLTIP_EB_LINE1$(26) = "Snap to Smart Guides ON/OFF"
TOOLTIP_EB_LINE2$(26) = "Snap to Smart Guides related to geometric boundaries of neighboring layers."
' Slot 27: divider
' Slot 28: Pixel Perfect
TOOLTIP_EB_LINE1$(28) = "F6 - Pixel Perfect ON/OFF"
TOOLTIP_EB_LINE2$(28) = "Remove corner pixels from brush strokes for clean pixel art lines."
' Slot 29: divider
' Slot 30: Flip Canvas Horizontal
TOOLTIP_EB_LINE1$(30) = "Flip Canvas Horizontal"
TOOLTIP_EB_LINE2$(30) = "L-CLICK flip all layers horizontally."
' Slot 31: Flip Canvas Vertical
TOOLTIP_EB_LINE1$(31) = "Flip Canvas Vertical"
TOOLTIP_EB_LINE2$(31) = "L-CLICK flip all layers vertically."

' --- Advanced Bar tooltip text arrays (indexed by ADVBAR slot 0..32) ---
DIM SHARED TOOLTIP_AB_LINE1$(0 TO 32)
DIM SHARED TOOLTIP_AB_LINE2$(0 TO 32)

' Slot 0: Preview Window
TOOLTIP_AB_LINE1$(0) = "Preview Window / Floating Image Window"
TOOLTIP_AB_LINE2$(0) = "L-CLICK Toggle Preview Window ON / OFF"
' Slot 1: Edit Bar
TOOLTIP_AB_LINE1$(1) = "Edit Bar"
TOOLTIP_AB_LINE2$(1) = "L-CLICK Toggle Edit Bar ON / OFF"
' Slot 2: divider
' Slot 3: Character Map
TOOLTIP_AB_LINE1$(3) = "Character Map"
TOOLTIP_AB_LINE2$(3) = "L-CLICK Toggle Character Map ON / OFF"
' Slot 4: Character Grid
TOOLTIP_AB_LINE1$(4) = "Character Grid"
TOOLTIP_AB_LINE2$(4) = "L-CLICK Toggle Character Grid ON / OFF"
' Slot 5: Snap to Character Grid
TOOLTIP_AB_LINE1$(5) = "Character Grid Snap"
TOOLTIP_AB_LINE2$(5) = "L-CLICK Toggle Snap to Character Grid ON / OFF"
' Slot 6: divider
' Slot 7: Tile Preview Mode
TOOLTIP_AB_LINE1$(7) = "Tile Preview Mode"
TOOLTIP_AB_LINE2$(7) = "L-CLICK Toggle Tile Preview Mode ON / OFF"
' Slot 8: Grid Cell Fill Mode
TOOLTIP_AB_LINE1$(8) = "Fill Grid Cell Mode"
TOOLTIP_AB_LINE2$(8) = "L-CLICK Toggle Fill Grid Cell Mode ON / OFF"
' Slot 9: Resize Grid to Brush Size
TOOLTIP_AB_LINE1$(9) = "Resize Grid to Brush Size"
TOOLTIP_AB_LINE2$(9) = "L-CLICK Resize Grid to Brush Size"
' Slot 10: Fill Adjustment Mode
TOOLTIP_AB_LINE1$(10) = "Fill Adjustment Mode"
TOOLTIP_AB_LINE2$(10) = "L-CLICK Toggle Fill Adjustment Mode ON / OFF"
' Slot 11: divider
' Slot 12: Brush Edges
TOOLTIP_AB_LINE1$(12) = "Brush Edges"
TOOLTIP_AB_LINE2$(12) = "L-CLICK Toggle Brush Edges ON / OFF"
' Slot 13: Angle Snap
TOOLTIP_AB_LINE1$(13) = "Angle Snap"
TOOLTIP_AB_LINE2$(13) = "L-CLICK Toggle Snap to Angles ON / OFF"
' Slot 14: Grayscale Preview
TOOLTIP_AB_LINE1$(14) = "Gray Scale Preview"
TOOLTIP_AB_LINE2$(14) = "L-CLICK Toggle Gray Scale Preview ON / OFF"
' Slot 15: divider
' Slot 16: Reference Image
TOOLTIP_AB_LINE1$(16) = "CTRL+r - Reference Image - Use CTRL+SHIFT+M-WHEEL to adjust opacity."
TOOLTIP_AB_LINE2$(16) = "L-CLICK Toggle Reference Image ON / OFF"
' Slot 17: Load Reference Image
TOOLTIP_AB_LINE1$(17) = "Load Reference Image"
TOOLTIP_AB_LINE2$(17) = "L-CLICK Load a Reference Image"
' Slot 18: Clear Reference Image
TOOLTIP_AB_LINE1$(18) = "Clear Reference Image"
TOOLTIP_AB_LINE2$(18) = "L-CLICK Clear Reference Image"
' Slot 19: Adjust Reference Image
TOOLTIP_AB_LINE1$(19) = "Adjust Reference Image - Reposition, Zoom, Change Opacity"
TOOLTIP_AB_LINE2$(19) = "L-CLICK Adjust Reference Image"
' Slot 20: divider
' Slot 21: Align Left
TOOLTIP_AB_LINE1$(21) = "Align Selected Layers to Left"
TOOLTIP_AB_LINE2$(21) = "L-CLICK Align Selected Layers to Left"
' Slot 22: Align Center
TOOLTIP_AB_LINE1$(22) = "Align Selected Layers to Center"
TOOLTIP_AB_LINE2$(22) = "L-CLICK Align Selected Layers to Center"
' Slot 23: Align Right
TOOLTIP_AB_LINE1$(23) = "Align Selected Layers to Right"
TOOLTIP_AB_LINE2$(23) = "L-CLICK Align Selected Layers to Right"
' Slot 24: Align Top
TOOLTIP_AB_LINE1$(24) = "Align Selected Layers to Top"
TOOLTIP_AB_LINE2$(24) = "L-CLICK Align Selected Layers to Top"
' Slot 25: Align Middle
TOOLTIP_AB_LINE1$(25) = "Align Selected Layers to Middle"
TOOLTIP_AB_LINE2$(25) = "L-CLICK Align Selected Layers to Middle"
' Slot 26: Align Bottom
TOOLTIP_AB_LINE1$(26) = "Align Selected Layers to Bottom"
TOOLTIP_AB_LINE2$(26) = "L-CLICK Align Selected Layers to Bottom"
' Slot 27: divider
' Slot 28: Distribute Horizontal
TOOLTIP_AB_LINE1$(28) = "Distribute Selected Layers Equally Horizontally"
TOOLTIP_AB_LINE2$(28) = "L-CLICK Distribute Selected Layers Equally Horizontally"
' Slot 29: Distribute Vertical
TOOLTIP_AB_LINE1$(29) = "Distribute Selected Layers Equally Vertically"
TOOLTIP_AB_LINE2$(29) = "L-CLICK Distribute Selected Layers Equally Vertically"
' Slot 30: divider
' Slot 31: Flip Canvas Horizontal
TOOLTIP_AB_LINE1$(31) = "Flip Canvas Horizontally"
TOOLTIP_AB_LINE2$(31) = "L-CLICK Flip Canvas Horizontally"
' Slot 32: Flip Canvas Vertical
TOOLTIP_AB_LINE1$(32) = "Flip Canvas Vertically"
TOOLTIP_AB_LINE2$(32) = "L-CLICK Flip Canvas Vertically"
