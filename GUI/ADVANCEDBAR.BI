''
' DRAW - GUI/ADVANCEDBAR.BI
' =============================================================================
' Advanced Bar — declarations, TYPE, and shared state.
' A vertical icon bar with advanced feature toggles and quick actions:
'   Panels | Char tools | Grid/Fill | Assists | Reference | Align | Distribute
' Dockable LEFT or RIGHT (independent of Edit Bar).
' Toggle with Shift+F5. State persists to DRAW.cfg.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

OPTION _EXPLICIT
OPTION _EXPLICITARRAY

' --- Constants ---
CONST ADVBAR_TOTAL_SLOTS  = 30 ' 24 action items + 6 dividers
CONST ADVBAR_ACTION_SLOTS = 24 ' Number of clickable icons
CONST ADVBAR_DOCK_LEFT    = 0
CONST ADVBAR_DOCK_RIGHT   = 1

TYPE ADVBAR_ITEM_OBJ
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

TYPE ADVBAR_OBJ
    visible     AS INTEGER ' TRUE when advanced bar should render
    dockSide    AS INTEGER ' ADVBAR_DOCK_LEFT or ADVBAR_DOCK_RIGHT
    panelX1     AS INTEGER ' Left edge of panel (for hit testing)
    panelX2     AS INTEGER ' Right edge of panel
    panelY1     AS INTEGER ' Top (below menubar)
    panelY2     AS INTEGER ' Bottom (screen bottom)
    hoverIndex  AS INTEGER ' Index of hovered item (-1 = none)
    iconsLoaded AS INTEGER ' TRUE once icons have been loaded
END TYPE

DIM SHARED ADV_BAR AS ADVBAR_OBJ
DIM SHARED ADV_BAR_ITEMS(0 TO ADVBAR_TOTAL_SLOTS - 1) AS ADVBAR_ITEM_OBJ

