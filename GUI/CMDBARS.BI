''
' DRAW - GUI/CMDBARS.BI
' =============================================================================
' Two more icon bars that work like the edit bar and the advanced bar (Rick
' 2026-11-22: "another 2 toolbars ... one for view that has all the view ->
' toggleable panels, and another for new/open/import/export - they should act
' just like advanced and edit bars"; named "PANELS for view, and I/O for
' import/export"):
'
'   PANELS bar (DP_PANELSBAR, View > PANELS Bar, action 2770): a button for each
'              panel View shows / hides, lit while that panel shows
'   I/O bar    (DP_IOBAR, View > I/O Bar, action 2771): New / Open / Import /
'              Save / Export
'
' Each is a dock panel (dock, float, tab, its own Scale, [x]) drawing a button
' list (GUI/BUTTON-LIST: BL_PANELSBAR / BL_IOBAR), so Customize Toolbars edits
' it (tabs PANELS / I/O), workspaces keep it ([PANELS_BAR] / [IO_BAR] ORDER=,
' COLUMNS=) and the same-buttons-everywhere setting covers it (PANELS_BAR_ORDER /
' IO_BAR_ORDER). Hidden until turned on (CFG.PANELS_BAR / CFG.IO_BAR).
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

CONST CBAR_PANELS = 1 ' the PANELS bar
CONST CBAR_IO     = 2 ' the I/O bar
CONST CBAR_N      = 2

CONST CBAR_ACT_PANELS = 2770 ' View > PANELS Bar (on / off; GUI/COMMAND.BM; 2770-2779 free, checked 2026-11-22)
CONST CBAR_ACT_IO     = 2771 ' View > I/O Bar

TYPE CBAR_OBJ
    visible      AS INTEGER ' drawn this frame (wanted and live in the dock)
    slotW        AS INTEGER ' width of the rect the layout gave it (its units; 0 = its own width)
    x            AS INTEGER ' left edge (its units)
    panelX1      AS INTEGER ' its rect (its units, for hit testing)
    panelX2      AS INTEGER
    panelY1      AS INTEGER
    panelY2      AS INTEGER
    hoverIndex   AS INTEGER ' list entry under the pointer (-1 = none)
    scrollOffset AS INTEGER ' px scrolled down
    contentH     AS INTEGER ' content height (set while drawing)
END TYPE

DIM SHARED CBAR(1 TO CBAR_N) AS CBAR_OBJ
DIM SHARED CBAR_NCOLS(1 TO CBAR_N) AS INTEGER ' icon columns (0 = the cfg's; a workspace / Customize Toolbars sets it)
