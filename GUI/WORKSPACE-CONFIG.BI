''
' DRAW - GUI/WORKSPACE-CONFIG.BI
' =============================================================================
' Workspace configurator (View > Workspace > Configure Workspaces..., action
' 2401). A modal dialog on the Settings widget framework (DIALOG_* + SW_*):
'
'   left   the workspace list (built-in + yours)
'   tabs   PANELS | TOOLBOX | MENUS | BARS | KEYS | OPTIONS
'   bar    NEW  DUPLICATE  RENAME  DELETE/RESET     SAVE  USE  CLOSE
'
' The selected workspace is edited as a flat SECTION.KEY store (its BASED_ON
' chain resolved) and SAVE writes it as a complete file into the user
' workspaces folder - so editing a built-in makes your own copy, which RESET
' removes again. USE saves and switches to it; CLOSE discards unsaved edits.
' Default is the no-overlay workspace and is not editable (DUPLICATE it).
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

CONST WSC_W        = 640
CONST WSC_H        = 400
CONST WSC_LIST_W   = 130
CONST WSC_TITLE_H  = 16
CONST WSC_BAR_H    = 28
CONST WSC_TABS_H   = 46 ' workspace header line + tab button row
CONST WSC_PAD      = 8
CONST WSC_SCROLL_W = 10
CONST WSC_ROW_H    = 16 ' workspace list row

CONST WSC_TAB_PANELS  = 0
CONST WSC_TAB_TOOLBOX = 1
CONST WSC_TAB_MENUS   = 2
CONST WSC_TAB_BARS    = 3
CONST WSC_TAB_KEYS    = 4
CONST WSC_TAB_OPTIONS = 5
CONST WSC_TAB_ITEMS$  = "Panels|Toolbox|Menus|Bars|Keys|Options"

TYPE WSC_STATE
    ctx         AS DIALOG_CTX
    sel         AS INTEGER ' WS_LIST index being edited
    tabIdx      AS INTEGER
    scrollY     AS INTEGER
    contentH    AS INTEGER
    viewportH   AS INTEGER
    contentX    AS INTEGER
    contentY    AS INTEGER
    contentW    AS INTEGER
    dirty       AS INTEGER ' unsaved edits
    needsRedraw AS INTEGER
    applyId     AS STRING  ' switch to this workspace after closing ("" = none)
    reapply     AS INTEGER ' the active workspace was saved: re-apply it after closing
END TYPE
DIM SHARED WSC AS WSC_STATE

' The workspace being edited: SECTION.KEY -> value ("" = unset)
CONST WSC_MAX_KV = 256
DIM SHARED WSC_N AS INTEGER
DIM SHARED WSC_K(1 TO WSC_MAX_KV) AS STRING
DIM SHARED WSC_V(1 TO WSC_MAX_KV) AS STRING
DIM SHARED WSC_ID AS STRING ' file id being edited

' Every toolbox button name, in the default grid order
CONST WSC_TB_NAMES$ = "move,hand,zoom,crop,marquee,marquee-free,marquee-poly,marquee-ellipse,wand,picker,text,eraser,dot,brush,spray,fill,line,polygon,polygon-filled,save,bezier,rect,rect-filled,export-sel,smart-shapes,ellipse,ellipse-filled,open"
CONST WSC_ROOT_NAMES$ = "FILE,EDIT,VIEW,SELECT,TOOLS,BRUSH,LAYER,PALETTE,IMAGE,EFFECTS,AI,HELP,AUDIO"
