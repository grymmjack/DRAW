''
' DRAW - TOOLS/ACTIONS.BI
' =============================================================================
' Actions (macros), like Photoshop's Actions panel (Rick 2026-11-22: "are we able to
' accommodate macros? where i can record actions stop then replay? like photoshop
' actions" / "need a new macro palette"; plan PLANS/HISTORY-ACTIONS-PALETTES.md).
' The engine; the palette is GUI/ACTIONS-PANEL.
'
' One tree, kept flat in display order (ACTS_*(1 .. ACTS_N)): a node's depth says what it is
'   0  a set      (a folder: one file <data>/ACTIONS/<name>.dact)
'   1  an action  (what PLAY runs)
'   2  a step     (one command: CMD_execute_action ACTS_CMD)
' A node's children are the nodes after it that are deeper, up to the next node as shallow.
'
' Recording: every top-level command (CMD_execute_action, not one a command runs) is a
' step - those of the kinds that change the picture (ACTS_recordable%): Edit, Layer,
' Canvas, Select, Image, Color. Not undo / redo, tool picks, View, File, Help, the
' panels' own. Playing: the enabled steps in order as ONE undo step; a step that cannot
' run (a command DRAW no longer has) is skipped and counted (Rick 2026-11-22: "Skip is
' fine"). A step keeps the dialog values it was recorded with (PARAM lines; Rick: "Yes
' record dialog with per step toggle like photoshop") - its DIALOG toggle shows the
' dialog instead (wired dialog by dialog: ACTS_PRM).
'
' File (.dact, text, saved on every change):
'   SET <on> <open> <name>
'   ACTION <on> <open> <name>
'   STEP <command id> <on> <dialog> <name>
'   PARAM <text>                (the step's dialog values, after its STEP line)
'
$INCLUDEONCE

CONST ACTS_MAX = 2000           ' nodes in all
CONST ACTS_EXT = ".dact"
CONST ACTS_DIRNAME = "ACTIONS"  ' under the data dir (PATHS_data$)
CONST ACTS_SEEDED = ".seeded"   ' in that dir once the starter set was written (deleting it does not bring it back)

TYPE ACTS_OBJ
    loaded    AS INTEGER ' the files were read (ACTS_load: on first use)
    recording AS INTEGER ' the action node steps go into (0 = not recording)
    recAfter  AS INTEGER ' the step node new steps go after (0 = the action's end)
    playing   AS INTEGER ' a play is running (nothing is recorded meanwhile)
    depth     AS INTEGER ' CMD_execute_action nesting (1 = a top-level command)
    lastRun   AS INTEGER ' steps the last play ran / skipped
    lastSkip  AS INTEGER
    gen       AS LONG    ' bumped on every change (the palette redraws)
END TYPE
DIM SHARED ACTS AS ACTS_OBJ
DIM SHARED ACTS_N AS INTEGER
DIM SHARED ACTS_D(1 TO ACTS_MAX) AS INTEGER    ' depth: 0 set, 1 action, 2 step
DIM SHARED ACTS_CMD(1 TO ACTS_MAX) AS INTEGER  ' a step's command (action id)
DIM SHARED ACTS_ON(1 TO ACTS_MAX) AS INTEGER   ' enabled (off = skipped on play)
DIM SHARED ACTS_DLG(1 TO ACTS_MAX) AS INTEGER  ' a step: show its dialog on play
DIM SHARED ACTS_OPEN(1 TO ACTS_MAX) AS INTEGER ' a set / action: its children listed
DIM SHARED ACTS_NM(1 TO ACTS_MAX) AS STRING    ' its name (stored case)
DIM SHARED ACTS_PRM(1 TO ACTS_MAX) AS STRING   ' a step's dialog values (PARAM lines, CHR$(10) between)
DIM SHARED ACTS_FILE(1 TO ACTS_MAX) AS STRING  ' a set: the file it was read from / last saved to
DIM SHARED ACTS_REC_PRM AS STRING  ' recording: the dialog values the command running now gave (a wired dialog sets it)
DIM SHARED ACTS_PLAY_PRM AS STRING ' playing: the step's dialog values (a wired dialog uses them)
DIM SHARED ACTS_PLAY_DLG AS INTEGER ' playing: the step's DIALOG toggle (show the dialog, filled with them)
DIM SHARED ACTS_REC_SKIP AS INTEGER ' recording: the command running now was cancelled (its dialog) - no step
DIM SHARED ACTS_DIR_OVERRIDE AS STRING ' --option ACTIONS_DIR=<folder>: the sets' folder for this run (QA), never saved
