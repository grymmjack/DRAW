''
' DRAW - AI/AI.BI
' =============================================================================
' AI image-generation integration: external generator tools, argument macro
' expansion, and the AI layer data pool.
'
' DRAW does not talk to any model directly. It shells out to a user-configured
' command-line tool (pixelmon, or a test script) whose arguments are a template
' expanded by DRAW_InfoParser$. The tool writes PNG(s) into a per-run temp
' directory that DRAW supplies via {outdir}; DRAW imports the newest PNG found
' there when the run finishes. See AI/AI-JOB.BM for the async runner.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE
OPTION _EXPLICIT
OPTION _EXPLICITARRAY
'$DYNAMIC

CONST AI_MAX_TOOLS       = 16   ' Configured generator tools
CONST AI_MAX_STYLES      = 48   ' Configured style guides
CONST AI_MAX_PROMPTS     = 64   ' Saved prompt presets
CONST AI_LAYER_POOL_SIZE = 64   ' Concurrent AI layers per project

' Position presets for placing a generated layer (3x3 grid + explicit)
CONST AI_POS_TL     = 0
CONST AI_POS_T      = 1
CONST AI_POS_TR     = 2
CONST AI_POS_L      = 3
CONST AI_POS_M      = 4
CONST AI_POS_R      = 5
CONST AI_POS_BL     = 6
CONST AI_POS_B      = 7
CONST AI_POS_BR     = 8
CONST AI_POS_CUSTOM = 9

' Job states (AI_JOB.state)
CONST AI_JOB_IDLE      = 0
CONST AI_JOB_RUNNING   = 1
CONST AI_JOB_IMPORTING = 2
CONST AI_JOB_DONE      = 3
CONST AI_JOB_FAILED    = 4
CONST AI_JOB_CANCELLED = 5

' Where the generated image lands
CONST AI_TARGET_NEW_LAYER = 0   ' Create a new AI layer
CONST AI_TARGET_REGEN     = 1   ' Replace the pixels of an existing AI layer

' A configured external generator
TYPE AI_TOOL_OBJ
    used     AS INTEGER
    toolName AS STRING * 48     ' Display name, e.g. "pixelmon"
    exePath  AS STRING * 256    ' Executable (absolute, or on PATH)
    workDir  AS STRING * 256    ' Working directory ("" = DRAW's own)
    argsTmpl AS STRING * 512    ' Argument template, expanded by DRAW_InfoParser$
END TYPE

' Per-AI-layer generation metadata. Embedded in the .draw file so a layer can
' be regenerated (or reproduced exactly, via the stored seed) after reload.
TYPE AI_LAYER_OBJ
    used      AS INTEGER
    prompt    AS STRING * 512
    styleName AS STRING * 48
    toolName  AS STRING * 48    ' Tool NAME, not index — indices shift between sessions
    seedVal   AS LONG           ' 0 = random / not recorded
    modelName AS STRING * 64    ' Reported by the tool, informational
    genW      AS INTEGER        ' Requested generation size
    genH      AS INTEGER
END TYPE

' The single in-flight generation job. One at a time: a second request while
' one is running is refused rather than queued.
TYPE AI_JOB_OBJ
    state      AS INTEGER
    toolIdx    AS INTEGER
    layerIdx   AS INTEGER       ' Target layer (created up-front so the panel can show progress)
    target     AS INTEGER       ' AI_TARGET_*
    outDir     AS STRING * 256  ' Temp dir handed to the tool as {outdir}
    outName    AS STRING * 64   ' Filename base handed to the tool as {outname}
    doneFile   AS STRING * 256  ' Sentinel written by the wrapper when the run exits
    startTime  AS DOUBLE
    timeoutSec AS DOUBLE
    lastPoll   AS DOUBLE
    statusMsg  AS STRING * 128
    destX      AS INTEGER       ' Where the result lands on the canvas
    destY      AS INTEGER
    destW      AS INTEGER       ' Requested generation size
    destH      AS INTEGER
END TYPE

' A style guide: text wrapped around the user's prompt, plus an optional seed
' lock. Styles may be scoped to one tool (a pixelmon --style name means nothing
' to another generator) or left global.
TYPE AI_STYLE_OBJ
    used       AS INTEGER
    styleName  AS STRING * 48
    toolName   AS STRING * 48   ' "" = applies to any tool
    prefixText AS STRING * 256  ' Prepended to the prompt text
    suffixText AS STRING * 256  ' Appended to the prompt text
    argsExtra  AS STRING * 256  ' Extra CLI arguments, appended to the tool's
                                ' template (e.g. pixelmon's --style ega). These
                                ' are NOT prompt text — putting a flag in
                                ' prefix/suffix would bury it inside the quoted
                                ' prompt where the tool never sees it.
    descText   AS STRING * 128  ' Shown in the editor / picker
    seedVal    AS LONG          ' 0 = don't force a seed
END TYPE

' A saved prompt preset — plain text for steering, picked from the dialog.
TYPE AI_PROMPT_OBJ
    used     AS INTEGER
    label    AS STRING * 48
    textBody AS STRING * 512
END TYPE

DIM SHARED AI_TOOLS(1 TO AI_MAX_TOOLS) AS AI_TOOL_OBJ
DIM SHARED AI_TOOL_COUNT%
DIM SHARED AI_STYLES(1 TO AI_MAX_STYLES) AS AI_STYLE_OBJ
DIM SHARED AI_STYLE_COUNT%
DIM SHARED AI_PROMPTS(1 TO AI_MAX_PROMPTS) AS AI_PROMPT_OBJ
DIM SHARED AI_PROMPT_COUNT%
DIM SHARED AI_LAYER_DATA(1 TO AI_LAYER_POOL_SIZE) AS AI_LAYER_OBJ
DIM SHARED AI_JOB AS AI_JOB_OBJ
' Raised when a run fails; the main loop shows the dialog, so a modal is never
' opened from inside AI_JOB_tick (which runs mid-frame, before render).
DIM SHARED AI_FAIL_PENDING%

' Last prompt / style / seed used, so the dialog can pre-fill on reopen.
' AI_LAST_PROMPT$ is the COMPOSED prompt handed to the generator (style prefix +
' raw + suffix); AI_LAST_PROMPT_RAW$ is what the user typed, and is what gets
' stored on the layer so editing later shows their words, not the style's.
DIM SHARED AI_LAST_PROMPT$
DIM SHARED AI_LAST_PROMPT_RAW$
DIM SHARED AI_LAST_STYLE$
DIM SHARED AI_LAST_SEED&
DIM SHARED AI_LAST_TOOL%
DIM SHARED AI_LAST_STYLE_IDX%
' Remembered-by-name choices read from [LAST]; resolved to indices after load
DIM SHARED AI_LAST_TOOL_NAME$
DIM SHARED AI_LAST_STYLE_NAME$

' Results of the generate dialog (AI_DLG_generate%). Shared rather than BYREF
' params because QB64 passes by reference and the dialog calls into code that
' touches the same globals — copying out once, here, keeps that unambiguous.
DIM SHARED AI_DLG_TOOL%
DIM SHARED AI_DLG_STYLE%
DIM SHARED AI_DLG_PROMPT$
DIM SHARED AI_DLG_W%
DIM SHARED AI_DLG_H%
DIM SHARED AI_DLG_X%
DIM SHARED AI_DLG_Y%
DIM SHARED AI_DLG_SEED&

' Poll interval for the running job, in seconds. Generation takes tens of
' seconds to minutes, so checking every frame would be pure syscall waste.
CONST AI_POLL_INTERVAL# = 0.5
CONST AI_DEFAULT_TIMEOUT# = 600 ' 10 minutes

AI_init
