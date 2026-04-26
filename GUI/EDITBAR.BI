''
' DRAW - GUI/EDITBAR.BI
' =============================================================================
' Edit Bar — declarations, TYPE, and shared state.
' A vertical icon bar that mirrors Edit menu actions as clickable buttons.
' Dockable LEFT (by layers panel) or RIGHT (by toolbox/drawer).
' Toggle with F5. State persists to DRAW.cfg.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

OPTION _EXPLICIT
OPTION _EXPLICITARRAY

' --- Constants ---
CONST EDITBAR_TOTAL_SLOTS  = 32 ' 25 action items + 7 dividers
CONST EDITBAR_ACTION_SLOTS = 25 ' Number of clickable icons
CONST EDITBAR_DOCK_LEFT    = 0
CONST EDITBAR_DOCK_RIGHT   = 1

TYPE EDITBAR_ITEM_OBJ
    actionID       AS INTEGER     ' CMD action ID to execute on click (0 = divider)
    iconHandle     AS LONG        ' Loaded image handle (< -1 = valid)
    disabledHandle AS LONG        ' Pre-computed dimmed copy (per-pixel alpha scaled)
    iconFile       AS STRING * 64 ' Theme filename for icon
    x              AS INTEGER     ' Screen position set during render
    y              AS INTEGER
    w              AS INTEGER
    h              AS INTEGER
    isDivider      AS INTEGER     ' TRUE = spacer, no icon
END TYPE

TYPE EDITBAR_OBJ
    visible     AS INTEGER ' TRUE when edit bar should render
    dockSide    AS INTEGER ' EDITBAR_DOCK_LEFT or EDITBAR_DOCK_RIGHT
    panelX1     AS INTEGER ' Left edge of panel (for hit testing)
    panelX2     AS INTEGER ' Right edge of panel
    panelY1     AS INTEGER ' Top (below menubar)
    panelY2     AS INTEGER ' Bottom (screen bottom)
    hoverIndex  AS INTEGER ' Index of hovered item (-1 = none)
    iconsLoaded AS INTEGER ' TRUE once icons have been loaded
END TYPE

DIM SHARED EDIT_BAR AS EDITBAR_OBJ
DIM SHARED EDIT_BAR_ITEMS(0 TO EDITBAR_TOTAL_SLOTS - 1) AS EDITBAR_ITEM_OBJ

