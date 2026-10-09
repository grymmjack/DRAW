''
' DRAW - CFG/WORKSPACE.BI
' =============================================================================
' Workspaces: named presets that decide which UI chrome exists (panels,
' toolbox buttons, menus, bars, keys, starting options). A workspace is an
' OVERLAY on the user's config - applying one snapshots what it touches and
' leaving restores it; nothing is written into DRAW.cfg.
'
' Files are INI-style, one per workspace (<id>.workspace):
'   built-in  ASSETS/WORKSPACES/<id>.workspace
'   user      <data dir>/WORKSPACES/<id>.workspace   (same id = user wins)
'
'   [WORKSPACE]  NAME / DESCRIPTION / BASED_ON (inherit, then override)
'   [CHROME]     <PANEL>=SHOW|HIDE|KEEP, TOOLBOX_DOCK=LEFT|RIGHT ...
'   [TOOLBOX]    COLUMNS, BUTTONS (comma list), ICON.<button>
'   [MENUS]      ROOTS, HIDE_ITEMS
'   [EDIT_BAR]   BUTTONS
'   [KEYS]       <key>=<tool|action>   (key case is kept: r vs R)
'   [OPTIONS]    any DRAW.cfg key, session only
'   [START]      TOOL, FG, ZOOM
'
' "default" always exists (no overlay), even without a file.
' This module is the file layer only (scan, parse, BASED_ON, lookup);
' applying a workspace to the UI lives in WORKSPACE.BM's WS_apply/WS_restore.
' Plan: PLANS/_/WORKSPACES-AND-CAPTURE-PLAN.md
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

CONST WS_MAX       = 32  ' workspaces listed (built-in + user)
CONST WS_MAX_KV    = 256 ' resolved SECTION.KEY=VALUE pairs for one workspace
CONST WS_MAX_DEPTH = 8   ' BASED_ON chain limit (a cycle stops here)
CONST WS_DEFAULT_ID$ = "default"
CONST WS_EXT$        = ".workspace"

TYPE WS_INFO
    id       AS STRING  ' lowercase file stem ("annotate")
    title    AS STRING  ' [WORKSPACE] NAME (falls back to the id)
    desc     AS STRING  ' [WORKSPACE] DESCRIPTION
    basedOn  AS STRING  ' [WORKSPACE] BASED_ON id ("" = none)
    fpath    AS STRING  ' the file that wins ("" = virtual default)
    builtin  AS INTEGER ' a built-in with this id exists (Reset is possible)
    userFile AS INTEGER ' a user file with this id exists (it wins)
END TYPE

DIM SHARED WS_LIST(1 TO WS_MAX) AS WS_INFO
DIM SHARED WS_COUNT   AS INTEGER
DIM SHARED WS_SCANNED AS INTEGER
' WORKSPACES_DIR=<path> (--option only; never saved): the user workspaces
' folder for this run - the QA tests save workspaces into a scratch folder
' instead of the real one (WS_user_dir$).
DIM SHARED WS_DIR_OVERRIDE AS STRING

' The resolved workspace: its BASED_ON chain flattened, child wins.
' Keys are "SECTION.KEY" - upper case, except [KEYS] keys which keep case.
DIM SHARED WS_RES_ID AS STRING
DIM SHARED WS_RES_N  AS INTEGER
DIM SHARED WS_RES_KEY(1 TO WS_MAX_KV) AS STRING
DIM SHARED WS_RES_VAL(1 TO WS_MAX_KV) AS STRING

DIM SHARED WS_LAST_ERROR AS STRING ' why the last WS_resolve% failed ("" = ok)
