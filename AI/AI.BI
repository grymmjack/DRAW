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
CONST AI_LAYER_POOL_SIZE = 64   ' Concurrent AI layers per project

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

DIM SHARED AI_TOOLS(1 TO AI_MAX_TOOLS) AS AI_TOOL_OBJ
DIM SHARED AI_TOOL_COUNT%
DIM SHARED AI_LAYER_DATA(1 TO AI_LAYER_POOL_SIZE) AS AI_LAYER_OBJ
DIM SHARED AI_JOB AS AI_JOB_OBJ

' Last prompt / style / seed used, so the dialog can pre-fill on reopen
DIM SHARED AI_LAST_PROMPT$
DIM SHARED AI_LAST_STYLE$
DIM SHARED AI_LAST_SEED&
DIM SHARED AI_LAST_TOOL%

' Poll interval for the running job, in seconds. Generation takes tens of
' seconds to minutes, so checking every frame would be pure syscall waste.
CONST AI_POLL_INTERVAL# = 0.5
CONST AI_DEFAULT_TIMEOUT# = 600 ' 10 minutes

AI_init
