''
' DRAW - GUI/HELP-CARD.BI
' =============================================================================
' Help card: a gesture reference that pops up while you hover a control whose
' mouse/keyboard vocabulary is too big for a tooltip. Distinct from tooltips:
' it is docked to an EDGE of the canvas work area (Settings > General >
' Help card edge: bottom / top / left / right), never on top of the control
' being hovered, with a colored header and a table of gestures drawn as
' mouse glyphs (pressed button, wheel, drag, double-click) plus keycaps.
'
' Cards today:
'   Palette Ops  - hovering the palette strip in Palette Ops mode
'   Color cycling - the same, while color cycling is on (Shift+Tab / action
'                  2060's current binding): the Ctrl gestures, a live readout
'                  of the hovered swatch's range, and the range-band legend
'
' Config: HELP_CARD_ENABLED, HELP_CARD_EDGE, HELP_CARD_DELAY ([TOOLTIPS]).
' Rendered onto SCRN.CANVAS& right before each TOOLTIP_render and re-blitted
' to screen 0 next to TOOLTIP_reblit_to_screen0 (above the floating panels).
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

CONST HCARD_NONE   = 0
CONST HCARD_PALOPS = 1
CONST HCARD_CYCLE  = 2

CONST HCARD_EDGE_BOTTOM = 0
CONST HCARD_EDGE_TOP    = 1
CONST HCARD_EDGE_LEFT   = 2
CONST HCARD_EDGE_RIGHT  = 3

' Gesture glyph kinds (column 1 of a row)
CONST HCARD_G_L     = 1  ' left click
CONST HCARD_G_R     = 2  ' right click
CONST HCARD_G_M     = 3  ' middle click
CONST HCARD_G_LDRAG = 4
CONST HCARD_G_RDRAG = 5
CONST HCARD_G_MDRAG = 6
CONST HCARD_G_LDBL  = 7  ' double left click
CONST HCARD_G_WHEEL = 8
CONST HCARD_G_KEY   = 9  ' keyboard only (keycaps)

TYPE HCARD_ROW
    glyph AS INTEGER     ' HCARD_G_*
    mods  AS STRING * 24 ' keycaps before the glyph, "+"-separated (e.g. "CTRL+SHIFT"); key name for HCARD_G_KEY
    desc  AS STRING * 96
END TYPE

TYPE HCARD_OBJ
    WANT      AS INTEGER ' card the hover asks for this frame
    SHOWN     AS INTEGER ' card on screen (after the delay)
    HOVER_T   AS DOUBLE  ' TIMER when WANT last changed
    RX        AS INTEGER ' last rendered rect (for the screen-0 reblit; W = 0 = none)
    RY        AS INTEGER
    RW        AS INTEGER
    RH        AS INTEGER
    LAST_INFO AS STRING  ' live-line text last drawn (repaint when it changes)
END TYPE

DIM SHARED HCARD             AS HCARD_OBJ
DIM SHARED HCARD_ROWS(1 TO 16) AS HCARD_ROW
DIM SHARED HCARD_ROW_N       AS INTEGER
