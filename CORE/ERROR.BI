''
' DRAW - CORE/ERROR.BI
' =============================================================================
' Centralized error handling framework for DRAW.
' Provides error constants, error state tracking, and logging helpers.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

' -----------------------------------------------------------------------------
' Error severity levels
' -----------------------------------------------------------------------------
CONST ERR_LEVEL_INFO = 0
CONST ERR_LEVEL_WARN = 1
CONST ERR_LEVEL_ERROR = 2

' -----------------------------------------------------------------------------
' Error codes
' -----------------------------------------------------------------------------
CONST ERR_NONE = 0
CONST ERR_IMAGE_LOAD = 1
CONST ERR_IMAGE_CREATE = 2
CONST ERR_IMAGE_INVALID = 3
CONST ERR_FILE_NOT_FOUND = 10
CONST ERR_FILE_READ = 11
CONST ERR_FILE_WRITE = 12
CONST ERR_FILE_FORMAT = 13
CONST ERR_OUT_OF_MEMORY = 20
CONST ERR_INVALID_PARAM = 30
CONST ERR_CONFIG_LOAD = 40
CONST ERR_CONFIG_SAVE = 41
CONST ERR_CONFIG_VALUE = 42

' -----------------------------------------------------------------------------
' Error state tracking
' -----------------------------------------------------------------------------
TYPE ERROR_OBJ
    CODE AS INTEGER        ' Current error code (ERR_* constant)
    LEVEL AS INTEGER       ' Severity level (ERR_LEVEL_* constant)
    MSG AS STRING * 256    ' Error message
    FATAL AS INTEGER       ' TRUE if error is fatal (should exit)
    HAS_ERROR AS INTEGER   ' TRUE if an error is currently set
END TYPE

DIM SHARED ERR_STATE AS ERROR_OBJ

' Initialize error state
ERR_STATE.CODE = ERR_NONE
ERR_STATE.LEVEL = ERR_LEVEL_INFO
ERR_STATE.MSG = ""
ERR_STATE.FATAL = FALSE
ERR_STATE.HAS_ERROR = FALSE
