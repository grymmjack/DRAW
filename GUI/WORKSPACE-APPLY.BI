''
' DRAW - GUI/WORKSPACE-APPLY.BI
' =============================================================================
' Applying a workspace (CFG/WORKSPACE) to the live UI as an OVERLAY:
'
'   WS_apply% id  snapshot every element the workspace names -> apply
'   WS_restore    put every touched element back exactly as it was
'
' Nothing a workspace sets reaches DRAW.cfg: CONFIG_save brackets its write
' with WS_cfg_guard_begin/_end, which swap the user's own values back in for
' the fields the overlay touched (panel *_VISIBLE, dock edges, [OPTIONS]
' keys) and re-apply the workspace's afterwards. So toggles made inside a
' workspace last for the session; only CFG.WORKSPACE (the last workspace) is
' remembered.
'
' Hidden elements get ManuallyHidden = TRUE, so the draw-over auto-hide
' restore (MOUSE_handle_ui_autohide_restore) never brings them back. F11 is
' the escape hatch: while a workspace hides something, F11 reveals what it
' hid and a second F11 hides it again (WS_f11%).
'
' [START] (tool, FG, zoom) runs once after the next render, when the layout
' reflects the new chrome (WS_tick); it is a starting state, not undone on
' leaving.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

' Chrome elements with an on/off state ([CHROME] <NAME>=SHOW|HIDE|KEEP)
CONST WS_EL_MENUBAR          = 1
CONST WS_EL_TOOLBOX          = 2
CONST WS_EL_LAYER_PANEL      = 3
CONST WS_EL_EDIT_BAR         = 4
CONST WS_EL_ADVANCED_BAR     = 5
CONST WS_EL_STATUS_BAR       = 6
CONST WS_EL_PREVIEW          = 7
CONST WS_EL_COLOR_MIXER      = 8
CONST WS_EL_CHARMAP          = 9
CONST WS_EL_COLOR_SPACE_3D   = 10
CONST WS_EL_ADV_COLOR_PICKER = 11
CONST WS_EL_PEN_PANEL        = 12
CONST WS_EL_BROWSER          = 13
CONST WS_EL_COUNT            = 13

' Dock edges ([CHROME] <NAME>_DOCK=LEFT|RIGHT)
CONST WS_DK_TOOLBOX      = 1
CONST WS_DK_LAYER_PANEL  = 2
CONST WS_DK_EDIT_BAR     = 3
CONST WS_DK_ADVANCED_BAR = 4
CONST WS_DK_CHARMAP      = 5
CONST WS_DK_COUNT        = 5

CONST WS_MAX_OPTS = 64 ' [OPTIONS] keys per workspace

DIM SHARED WS_EL_NAME(1 TO WS_EL_COUNT) AS STRING
DIM SHARED WS_DK_NAME(1 TO WS_DK_COUNT) AS STRING
WS_EL_NAME(WS_EL_MENUBAR) = "MENUBAR"
WS_EL_NAME(WS_EL_TOOLBOX) = "TOOLBOX"
WS_EL_NAME(WS_EL_LAYER_PANEL) = "LAYER_PANEL"
WS_EL_NAME(WS_EL_EDIT_BAR) = "EDIT_BAR"
WS_EL_NAME(WS_EL_ADVANCED_BAR) = "ADVANCED_BAR"
WS_EL_NAME(WS_EL_STATUS_BAR) = "STATUS_BAR"
WS_EL_NAME(WS_EL_PREVIEW) = "PREVIEW"
WS_EL_NAME(WS_EL_COLOR_MIXER) = "COLOR_MIXER"
WS_EL_NAME(WS_EL_CHARMAP) = "CHARMAP"
WS_EL_NAME(WS_EL_COLOR_SPACE_3D) = "COLOR_SPACE_3D"
WS_EL_NAME(WS_EL_ADV_COLOR_PICKER) = "ADV_COLOR_PICKER"
WS_EL_NAME(WS_EL_PEN_PANEL) = "PEN_PANEL"
WS_EL_NAME(WS_EL_BROWSER) = "BROWSER"
WS_DK_NAME(WS_DK_TOOLBOX) = "TOOLBOX_DOCK"
WS_DK_NAME(WS_DK_LAYER_PANEL) = "LAYER_PANEL_DOCK"
WS_DK_NAME(WS_DK_EDIT_BAR) = "EDIT_BAR_DOCK"
WS_DK_NAME(WS_DK_ADVANCED_BAR) = "ADVANCED_BAR_DOCK"
WS_DK_NAME(WS_DK_CHARMAP) = "CHARMAP_DOCK"

' Overlay state
DIM SHARED WS_ACTIVE       AS INTEGER ' TRUE while a non-default workspace is applied
DIM SHARED WS_ACTIVE_ID    AS STRING  ' its id ("annotate"); "default" when none
DIM SHARED WS_ACTIVE_TITLE AS STRING  ' its display name ("Annotate")
DIM SHARED WS_REVEALED     AS INTEGER ' TRUE after F11 showed what the workspace hid
DIM SHARED WS_START_PENDING AS INTEGER ' [START] waits for the next render (WS_tick)
DIM SHARED WS_GUARD_BYPASS AS INTEGER ' CONFIG_save writes raw (snapshot capture)
DIM SHARED WS_GUARD_ON     AS INTEGER ' inside a guarded CONFIG_save
WS_ACTIVE_ID = "default"
WS_ACTIVE_TITLE = "Default"

' Per element: touched by the overlay, the workspace's value, and the
' user's own state captured before applying (live visibility,
' ManuallyHidden, and the persisted CFG *_VISIBLE field where one exists).
DIM SHARED WS_EL_TOUCHED(1 TO WS_EL_COUNT) AS INTEGER
DIM SHARED WS_EL_WANT(1 TO WS_EL_COUNT)    AS INTEGER
DIM SHARED WS_EL_SNAP_VIS(1 TO WS_EL_COUNT) AS INTEGER
DIM SHARED WS_EL_SNAP_MH(1 TO WS_EL_COUNT)  AS INTEGER
DIM SHARED WS_EL_SNAP_CFG(1 TO WS_EL_COUNT) AS INTEGER
DIM SHARED WS_EL_HOLD_CFG(1 TO WS_EL_COUNT) AS INTEGER ' guard scratch

DIM SHARED WS_DK_TOUCHED(1 TO WS_DK_COUNT) AS INTEGER
DIM SHARED WS_DK_WANT(1 TO WS_DK_COUNT)    AS STRING
DIM SHARED WS_DK_SNAP(1 TO WS_DK_COUNT)    AS STRING
DIM SHARED WS_DK_HOLD(1 TO WS_DK_COUNT)    AS STRING ' guard scratch

' [OPTIONS]: key, the workspace's value, the user's value before applying
DIM SHARED WS_OPT_N AS INTEGER
DIM SHARED WS_OPT_KEY(1 TO WS_MAX_OPTS)  AS STRING
DIM SHARED WS_OPT_VAL(1 TO WS_MAX_OPTS)  AS STRING
DIM SHARED WS_OPT_ORIG(1 TO WS_MAX_OPTS) AS STRING
DIM SHARED WS_OPT_HAD(1 TO WS_MAX_OPTS)  AS INTEGER ' the user's config had the key

' Actions 2400-2449 (CMD_execute_action -> WS_action)
CONST WS_ACT_SWITCHER  = 2400 ' Ctrl+Shift+W: command palette filtered to workspaces
CONST WS_ACT_CONFIGURE = 2401 ' Configure Workspaces... (configurator: W6)
CONST WS_ACT_FOLDER    = 2402 ' Open the user workspaces folder
CONST WS_ACT_RELOAD    = 2403 ' Rescan workspace files (menu + palette rebuilt)
CONST WS_ACT_LEAVE     = 2404 ' Back to Default
CONST WS_ACT_SLOT0     = 2409 ' + n = switch to WS_LIST(n), n = 1..WS_MAX (2410-2441)
CONST WS_CMD_PREFIX$   = "Workspace: "

DIM SHARED WS_NO_REMEMBER AS INTEGER ' --workspace NAME: apply without changing CFG.WORKSPACE
DIM SHARED WS_CLI_NAME    AS STRING  ' --workspace NAME from the command line ("" = none)
