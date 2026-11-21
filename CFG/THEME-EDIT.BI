''
' DRAW - CFG/THEME-EDIT.BI
' =============================================================================
' Theme Edit mode (THEMEED_): DRAW's adapter over the UIKIT property registry
' and inspector (GUI/UIKIT). Started with --theme-edit; see PLANS/THEME-EDIT.md.
'
'   ./DRAW.run --theme-edit --theme-name MYTHEME --theme-edit-base DARK \
'              --theme-edit-autosave-mins 5 --theme-edit-keep-num-backups 3 \
'              --theme-edit-start-inspector
'   ./DRAW.run --theme-edit-inspect TOOLBOX      (print KEY=VALUE lines, exit)
'
' Included in the CFG group (before OUTPUT/SCREEN.BI): CONFIG_load and the first
' THEME_load run at include time from SCREEN_init, and the theme to edit has to
' exist - and CFG.THEME$ point at it - before then.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

DECLARE LIBRARY "../native/file_stamp"
    FUNCTION gj_file_stamp&& (p AS STRING)
END DECLARE

CONST THEMEED_MAX_WATCH = 32

TYPE THEMEED_OBJ
    active        AS INTEGER ' --theme-edit given: the session runs
    cliDone       AS INTEGER ' THEMEED_cli_apply ran
    started       AS INTEGER ' THEMEED_session_start ran
    themeName     AS STRING
    baseName      AS STRING
    created       AS INTEGER ' the theme was copied from the base this run
    askedName     AS STRING  ' --theme-name, when another theme was edited instead
    askedBase     AS STRING  ' what that theme was made from ("" = not known)
    replacedTo    AS STRING  ' R at the question: where the old theme was moved
    autosaveMins  AS INTEGER ' 0 = off, 1-60
    keepBackups   AS INTEGER ' 0 = none, 1-10
    startInspect  AS INTEGER ' --theme-edit-start-inspector
    unattended    AS INTEGER ' --theme-edit-unattended (an AI / script drives it)
    root          AS STRING  ' ASSETS/THEMES/<name>/
    cfgPath       AS STRING  ' <root>THEME.CFG
    cfgStamp      AS _INTEGER64
    dirtySince    AS DOUBLE  ' TIMER when the first unsaved change was made (0 = clean)
    lastSaveTime  AS STRING  ' TIME$ of the last save
    lastPoll      AS DOUBLE
    needReload    AS INTEGER ' images / cursors / icons must reload
    needLayout    AS INTEGER ' a size changed: relayout
    applying      AS INTEGER ' UIP_host_set% while re-applying (no refresh requests)
    capture       AS INTEGER ' a press the inspector took is still held
    pickRegion    AS INTEGER ' region under the pointer while picking
    pickX         AS INTEGER ' its rect
    pickY         AS INTEGER
    pickW         AS INTEGER
    pickH         AS INTEGER
    pickLabel     AS STRING
    keyWasDown    AS INTEGER ' Ctrl+Alt+` edge
    escWasDown    AS INTEGER
    treeSig       AS STRING  ' UIP_node_sig$ of the last tree handed to the inspector
    statePath     AS STRING  ' the inspector's dock / scale / split, beside the DRAW config
    stateSaved    AS STRING
    lastHover     AS INTEGER ' tree row under the pointer last frame (its outline)
    dlgDepth      AS INTEGER ' modal dialogs open (DIALOG_init .. DIALOG_cleanup)
    dlgOB1        AS INTEGER ' the buttons last dialog frame (THEMEED_dialog_input%)
    dlgOB2        AS INTEGER
    openAction    AS INTEGER ' a DIALOGS menu pick: the action that opens it, run at the next tick
END TYPE

' The region table as of the last GUI render (REGION_BOUNDS_TABLE is cleared
' every render and only GUI renders fill it all in; INPUT.BI comes after this
' file, hence a type of its own)
CONST THEMEED_RG_N = 64 ' = REGION_TABLE_SIZE
TYPE THEMEED_RG_OBJ
    active AS INTEGER
    x      AS INTEGER
    y      AS INTEGER
    w      AS INTEGER
    h      AS INTEGER
    z      AS INTEGER
END TYPE

DIM SHARED THEMEED AS THEMEED_OBJ
DIM SHARED THEMEED_RG(0 TO THEMEED_RG_N - 1) AS THEMEED_RG_OBJ
' Files a node shows that the theme does not have yet - EDIT makes them, seeded
' from DEFAULT or from what is drawn now (THEMEED_seed_make%). Refilled by every
' THEMEED_tree_build.
CONST THEMEED_SEED_MAX = 128
DIM SHARED THEMEED_SEED_N AS INTEGER
DIM SHARED THEMEED_SEED_PATH(1 TO THEMEED_SEED_MAX) AS STRING
DIM SHARED THEMEED_SEED_ACT(1 TO THEMEED_SEED_MAX) AS INTEGER ' the command whose art it is
DIM SHARED THEMEED_SEED_TB(1 TO THEMEED_SEED_MAX) AS INTEGER  ' toolbox-size art (11x11), else bar art
' What the draw code says it drew (THEMEED_seen, kept in THEMEED_PART): a part, its box in the image it
' was drawn into (dst), the node it goes under (pkey: another part's key, "R:<rg>",
' "OVER"; "" = the region it lies in). A dst's parts are replaced the first time
' it is drawn into again after a new SCREEN_render began (THEMEED_GEN), so each
' image keeps what its last draw put there. The tree turns them into window px:
' SCRN.GUI& / SCRN.CANVAS& are viewport px, any other image through the last
' HSC_put of it (THEMEED_hsc_note: a panel or native window at its own Scale).
TYPE THEMEED_SEEN_OBJ
    dst   AS LONG
    pkey  AS STRING
    nkey  AS STRING
    label AS STRING
    x     AS INTEGER
    y     AS INTEGER
    w     AS INTEGER
    h     AS INTEGER
    fls   AS STRING
END TYPE
TYPE THEMEED_MAP_OBJ
    src AS LONG
    rg  AS INTEGER ' the REGION_* it shows (0 = where it lands)
    sx  AS LONG
    sy  AS LONG
    sw  AS LONG
    sh  AS LONG
    dx  AS LONG    ' window px
    dy  AS LONG
    dw  AS LONG
    dh  AS LONG
END TYPE
CONST THEMEED_MAP_MAX = 48
CONST THEMEED_DG_MAX = 64
DIM SHARED THEMEED_GEN AS LONG
DIM SHARED THEMEED_SN AS INTEGER
DIM SHARED THEMEED_PART(1 TO 1) AS THEMEED_SEEN_OBJ
DIM SHARED THEMEED_MAP_N AS INTEGER
DIM SHARED THEMEED_MAP(1 TO THEMEED_MAP_MAX) AS THEMEED_MAP_OBJ
DIM SHARED THEMEED_DG_N AS INTEGER
DIM SHARED THEMEED_DG_DST(1 TO THEMEED_DG_MAX) AS LONG
DIM SHARED THEMEED_DG_GEN(1 TO THEMEED_DG_MAX) AS LONG
' resolved per tree build: window-px box, parent record (0 = top level), region
' (-1 = OVERLAYS, -2 = under the node named by pkey), usable
DIM SHARED THEMEED_RS_X(1 TO 1) AS INTEGER, THEMEED_RS_Y(1 TO 1) AS INTEGER
DIM SHARED THEMEED_RS_W(1 TO 1) AS INTEGER, THEMEED_RS_H(1 TO 1) AS INTEGER
DIM SHARED THEMEED_RS_PAR(1 TO 1) AS INTEGER, THEMEED_RS_RG(1 TO 1) AS INTEGER
DIM SHARED THEMEED_RS_OK(1 TO 1) AS INTEGER
DIM SHARED THEMEED_WATCH_N AS INTEGER
DIM SHARED THEMEED_WATCH_PATH(1 TO THEMEED_MAX_WATCH) AS STRING
DIM SHARED THEMEED_WATCH_STAMP(1 TO THEMEED_MAX_WATCH) AS _INTEGER64
