$INCLUDEONCE
'
' PEN-PRESETS.BI — Pen Control presets (Rick 2026-11-17: "pen control presets
' that i can choose from ... quickly whip around for different tablet
' configurations"). Right-click the Pen Control panel: the presets, then
' Save / Rename / Delete / Open Presets. A preset is a text file of the Pen
' Control keys (CONFIG_pen_lines$) in <data>/PEN-PRESETS/<name>.pen.
'
CONST PENPR_MAX = 40
CONST PENPR_EXT = ".pen"
CONST PENPR_DIRNAME = "PEN-PRESETS"
' Example presets shipped with DRAW (Rick 2026-11-17: "examples with a guide"):
' copied into the presets folder the first time it is listed, each name once -
' an example you delete stays deleted (the names copied are kept in PENPR_SEEDED)
CONST PENPR_EXAMPLES_DIR = "ASSETS/PRESETS/PEN/"
CONST PENPR_SEEDED = ".examples-copied"
' dock-menu row values (the menu borrows the dock's handle menu: DOCK_UI.menuPen)
CONST PENPR_ACT_SAVE = 1
CONST PENPR_ACT_RENAME = 2
CONST PENPR_ACT_DELETE = 3
CONST PENPR_ACT_OPEN = 4
CONST PENPR_ACT_PRESET = 100 ' + 1..PENPR_MAX: apply that preset

DIM SHARED PENPR_NAMES(1 TO PENPR_MAX) AS STRING ' the presets, A-Z (PENPR_scan)
DIM SHARED PENPR_N AS INTEGER
DIM SHARED PENPR_CUR AS INTEGER     ' the preset the settings are now (0 = none / changed since)
DIM SHARED PENPR_LAST AS STRING     ' name last applied / saved this session (wins a tie)
DIM SHARED PENPR_MENU_NEXT AS INTEGER ' set before DOCK_menu_open: the next menu is the presets menu
