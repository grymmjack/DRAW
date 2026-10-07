' =============================================================================
' QA/unit/dock-unit.bas - headless unit test for GUI/DOCK-TREE.BM: the dock
' tree (columns, slots, tabs) and its [DOCK] / [FLOAT] grammar. Run from the
' repo root:
'   ~/git/qb64pe/qb64pe -w -x -o QA/unit/dock-unit.run QA/unit/dock-unit.bas && QA/unit/dock-unit.run
' Exit code 0 = all pass.
' =============================================================================
$CONSOLE:ONLY
OPTION _EXPLICIT
CONST TRUE = -1, FALSE = 0
DIM SHARED PATHS_DATA_DIR AS STRING
DIM SHARED FAILS AS INTEGER, PASSES AS INTEGER
'$INCLUDE:'../../CFG/WORKSPACE.BI'
'$INCLUDE:'../../GUI/DOCK.BI'

DIM c AS INTEGER, c2 AS INTEGER, s AS INTEGER, d AS STRING, spec AS STRING, id AS INTEGER

DOCK_init_panels
CHECK DOCK_panel_by_name%("Layers") = DP_LAYERS, "panel names are case-insensitive"
CHECK DOCK_panel_by_name%("nope") = 0, "unknown panel name"

' --- parse a column -----------------------------------------------------------
DOCK_clear
c = DOCK_parse_col%(DOCK_LEFT, "WIDTH:150; layers@3 | browser")
CHECK c > 0, "column parsed"
CHECK DOCK_COL(c).wpx = 150, "WIDTH:150"
CHECK DOCK_COL(c).ord = 1, "outermost"
s = DOCK_slot_at%(c, 1)
CHECK DOCK_TAB(s, 1) = DP_LAYERS _ANDALSO DOCK_SLOT(s).share = 3, "layers@3"
s = DOCK_slot_at%(c, 2)
CHECK DOCK_TAB(s, 1) = DP_BROWSER _ANDALSO DOCK_SLOT(s).share = 1, "browser, share 1"
CHECK DPANEL(DP_LAYERS).slot = DOCK_slot_at%(c, 1), "panel knows its slot"

' tabs, active tab, collapsed, AUTO width, second column order
c2 = DOCK_parse_col%(DOCK_LEFT, "AUTO; !*preview+colormixer@2 | editbar")
CHECK c2 > 0 _ANDALSO DOCK_COL(c2).ord = 2 _ANDALSO DOCK_COL(c2).wpx = 0, "AUTO, second column"
s = DOCK_slot_at%(c2, 1)
CHECK DOCK_SLOT(s).ntabs = 2, "two tabs"
CHECK DOCK_SLOT(s).act = 1, "active = preview (first, starred)"
CHECK DOCK_SLOT(s).collapsed, "! collapsed"
CHECK DOCK_SLOT(s).share = 2, "@2 on a tabbed slot"

' --- round trip ---------------------------------------------------------------
CHECK DOCK_col_spec$(c) = "WIDTH:150; layers@3 | browser", "write column 1, got [" + DOCK_col_spec$(c) + "]"
CHECK DOCK_col_spec$(c2) = "AUTO; !*preview+colormixer@2 | editbar", "write column 2, got [" + DOCK_col_spec$(c2) + "]"
d = DOCK_describe$
CHECK d = "LEFT.1: layers | browser" + CHR$(10) + "LEFT.2: preview+colormixer | editbar" + CHR$(10), "describe, got [" + d + "]"

' a non-first active tab survives a round trip
DOCK_clear
c = DOCK_parse_col%(DOCK_RIGHT, "AUTO; preview+*colormixer+advcolorpicker")
s = DOCK_slot_at%(c, 1)
CHECK DOCK_SLOT(s).act = 2, "active = second tab"
spec = DOCK_col_spec$(c)
CHECK spec = "AUTO; preview+*colormixer+advcolorpicker", "active tab written, got [" + spec + "]"
DOCK_clear
c = DOCK_parse_col%(DOCK_RIGHT, spec)
CHECK DOCK_SLOT(DOCK_slot_at%(c, 1)).act = 2, "re-parsed active tab"

' --- bad input ----------------------------------------------------------------
DOCK_clear
DOCK_PARSE_NOTE = ""
c = DOCK_parse_col%(DOCK_LEFT, "AUTO; ghost | toolbox | toolbox+organizer")
CHECK c > 0, "column with a bad name still parses"
CHECK DOCK_slot_at%(c, 1) > 0 _ANDALSO DOCK_TAB(DOCK_slot_at%(c, 1), 1) = DP_TOOLBOX, "empty slot (ghost) dropped"
CHECK DOCK_SLOT(DOCK_slot_at%(c, 2)).ntabs = 1 _ANDALSO DOCK_TAB(DOCK_slot_at%(c, 2), 1) = DP_ORGANIZER, "repeated toolbox skipped"
CHECK INSTR(DOCK_PARSE_NOTE, "unknown:ghost") > 0 _ANDALSO INSTR(DOCK_PARSE_NOTE, "repeated:toolbox") > 0, "notes, got [" + DOCK_PARSE_NOTE + "]"
c2 = DOCK_parse_col%(DOCK_LEFT, "AUTO; ghost")
CHECK c2 = 0, "a column with nothing usable is dropped"
CHECK DOCK_col_at%(DOCK_LEFT, 2) = 0, "dropped column not counted"
c2 = DOCK_parse_col%(DOCK_LEFT, "layers")
CHECK c2 > 0 _ANDALSO DOCK_COL(c2).ord = 2, "no width part = AUTO, order continues"
CHECK DOCK_field$("a | b|c", "|", 2) = "b" _ANDALSO DOCK_fields%("a | b|c", "|") = 3 _ANDALSO DOCK_fields%("  ", "|") = 0, "tokenizer"

' --- [FLOAT] ------------------------------------------------------------------
id = DOCK_parse_float%("pen", "640, 120,220,300")
CHECK id = DP_PEN _ANDALSO DPANEL(DP_PEN).fl _ANDALSO DPANEL(DP_PEN).fy = 120, "float parsed"
CHECK DOCK_float_spec$(DP_PEN) = "640,120,220,300", "float written"
CHECK DOCK_parse_float%("pen", "1,2,3") = 0, "float needs 4 numbers"

' --- editing helpers ----------------------------------------------------------
DOCK_clear
DOCK_add_stack DOCK_RIGHT, "1,2,3"
CHECK DOCK_describe$ = "RIGHT.1: toolbox | organizer | drawer" + CHR$(10), "add_stack"

' --- snapshots ----------------------------------------------------------------
DIM snap AS STRING, snap2 AS STRING
DOCK_clear
c = DOCK_parse_col%(DOCK_RIGHT, "WIDTH:120; layers | *preview+colormixer@2")
c = DOCK_parse_col%(DOCK_LEFT, "toolbox | organizer")
id = DOCK_parse_float%("pen", "10,20,30,40")
DOCK_CUSTOM = TRUE
snap = DOCK_snapshot$
CHECK INSTR(snap, "CUSTOM=1") = 1, "snapshot starts with CUSTOM"
CHECK INSTR(snap, "LEFT.1=AUTO; toolbox | organizer") > 0 _ANDALSO INSTR(snap, "RIGHT.1=WIDTH:120;") > 0 _ANDALSO INSTR(snap, "FLOAT.pen=10,20,30,40") > 0, "snapshot lines, got [" + snap + "]"
DOCK_clear: DPANEL(DP_PEN).fl = FALSE: DOCK_CUSTOM = FALSE
DOCK_load_snapshot snap
CHECK DOCK_CUSTOM, "loaded snapshot is custom"
snap2 = DOCK_snapshot$
CHECK snap2 = snap, "snapshot round trip, got [" + snap2 + "]"
CHECK DPANEL(DP_PEN).fl _ANDALSO DPANEL(DP_PEN).fw = 30, "float restored"
DOCK_load_snapshot "CUSTOM=0" + CHR$(10)
CHECK DOCK_CUSTOM = FALSE _ANDALSO DOCK_col_at%(DOCK_LEFT, 1) = 0, "CUSTOM=0 = default tree"
CHECK DPANEL(DP_PEN).fl = FALSE, "floats cleared"
snap = DOCK_snap_set$("CUSTOM=1" + CHR$(10) + "LEFT.1=toolbox" + CHR$(10), "LEFT.1", "layers")
CHECK DOCK_snap_get$(snap, "left.1") = "layers", "snap_set replaces, get is case-insensitive"
snap = DOCK_snap_set$(snap, "RIGHT.1", "editbar")
snap = DOCK_snap_set$(snap, "LEFT.1", "")
CHECK DOCK_snap_get$(snap, "LEFT.1") = "" _ANDALSO DOCK_snap_get$(snap, "RIGHT.1") = "editbar", "snap_set adds and removes"

' --- moves --------------------------------------------------------------------
DOCK_clear
c = DOCK_parse_col%(DOCK_LEFT, "toolbox | organizer | drawer")
c = DOCK_parse_col%(DOCK_RIGHT, "layers")
c = DOCK_parse_col%(DOCK_RIGHT, "editbar")
' organizer to a new innermost right column
c = DOCK_move_to_new_col%(DP_ORGANIZER, DOCK_RIGHT, 99)
CHECK c > 0, "move to new column"
CHECK DOCK_describe$ = "LEFT.1: toolbox | drawer" + CHR$(10) + "RIGHT.1: layers" + CHR$(10) + "RIGHT.2: editbar" + CHR$(10) + "RIGHT.3: organizer" + CHR$(10), "organizer moved, got [" + DOCK_describe$ + "]"
' editbar under the layers (split)
s = DOCK_move_to_slot%(DP_EDITBAR, DOCK_col_at%(DOCK_RIGHT, 1), 2)
CHECK s > 0, "move into column"
CHECK DOCK_describe$ = "LEFT.1: toolbox | drawer" + CHR$(10) + "RIGHT.1: layers | editbar" + CHR$(10) + "RIGHT.2: organizer" + CHR$(10), "editbar column emptied and removed, got [" + DOCK_describe$ + "]"
' drawer as a tab of the layers
s = DOCK_move_to_tab%(DP_DRAWER, DPANEL(DP_LAYERS).slot)
CHECK DOCK_SLOT(s).ntabs = 2 _ANDALSO DOCK_SLOT(s).act = 2, "tab added and active"
CHECK DOCK_describe$ = "LEFT.1: toolbox" + CHR$(10) + "RIGHT.1: layers+drawer | editbar" + CHR$(10) + "RIGHT.2: organizer" + CHR$(10), "tabbed, got [" + DOCK_describe$ + "]"
' a new outermost left column pushes the toolbox inward
c = DOCK_move_to_new_col%(DP_EDITBAR, DOCK_LEFT, 1)
CHECK DOCK_describe$ = "LEFT.1: editbar" + CHR$(10) + "LEFT.2: toolbox" + CHR$(10) + "RIGHT.1: layers+drawer" + CHR$(10) + "RIGHT.2: organizer" + CHR$(10), "outermost insert, got [" + DOCK_describe$ + "]"
' detaching the active tab leaves the other active
DOCK_detach_panel DP_DRAWER
s = DPANEL(DP_LAYERS).slot
CHECK DOCK_SLOT(s).ntabs = 1 _ANDALSO DOCK_SLOT(s).act = 1, "tab removed"
' moving a panel into its own lone column keeps the tree valid
s = DOCK_move_to_slot%(DP_ORGANIZER, DOCK_col_at%(DOCK_RIGHT, 2), 1)
CHECK s = 0, "into a column that vanished when the panel left it: no move"

' a slot inserted into a column gets the column's average share (px shares
' after a divider drag would leave a share of 1 a sliver)
DOCK_clear
c = DOCK_parse_col%(DOCK_RIGHT, "layers@200 | editbar@300")
s = DOCK_insert_slot%(c, 1)
CHECK DOCK_SLOT(s).share = 250, "inserted slot share = column average, got" + STR$(DOCK_SLOT(s).share)
DOCK_clear
c = DOCK_parse_col%(DOCK_LEFT, "toolbox | organizer | drawer")
c = DOCK_parse_col%(DOCK_RIGHT, "layers")
c = DOCK_parse_col%(DOCK_RIGHT, "editbar")
c = DOCK_move_to_new_col%(DP_ORGANIZER, DOCK_RIGHT, 99)
s = DOCK_move_to_slot%(DP_EDITBAR, DOCK_col_at%(DOCK_RIGHT, 1), 2)
s = DOCK_move_to_tab%(DP_DRAWER, DPANEL(DP_LAYERS).slot)
c = DOCK_move_to_new_col%(DP_EDITBAR, DOCK_LEFT, 1)
DOCK_detach_panel DP_DRAWER

' a panel's side, and a whole column moving edges (legacy dock-edge actions)
CHECK DOCK_panel_side%(DP_EDITBAR) = DOCK_LEFT _ANDALSO DOCK_panel_side%(DP_LAYERS) = DOCK_RIGHT, "panel sides"
DOCK_detach_panel DP_ORGANIZER
CHECK DOCK_panel_side%(DP_ORGANIZER) = 0, "undocked panel has no side"
DOCK_move_col_side DOCK_col_at%(DOCK_LEFT, 2), DOCK_RIGHT
CHECK DOCK_describe$ = "LEFT.1: editbar" + CHR$(10) + "RIGHT.1: layers" + CHR$(10) + "RIGHT.2: toolbox" + CHR$(10), "toolbox column to the right edge, innermost, got [" + DOCK_describe$ + "]"
CHECK DOCK_panel_side%(DP_TOOLBOX) = DOCK_RIGHT, "toolbox now right"

PRINT "dock-unit:"; PASSES; "passed,"; FAILS; "failed"
IF FAILS THEN SYSTEM 1
SYSTEM 0

SUB CHECK (ok AS INTEGER, msg AS STRING)
    IF ok THEN PASSES = PASSES + 1 ELSE FAILS = FAILS + 1: PRINT "FAIL: "; msg
END SUB

FUNCTION PATHS_sep$ ()
    PATHS_sep$ = "/"
END FUNCTION

'$INCLUDE:'../../CFG/WORKSPACE.BM'
'$INCLUDE:'../../GUI/DOCK-TREE.BM'
