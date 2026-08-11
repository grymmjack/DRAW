''
' DRAW - CORE/CRASH.BI
' =============================================================================
' Crash handling / crash logging / crash reporting.
'
' DRAW arms ON ERROR GOTO FatalError in DRAW.BAS before the include chain, so
' every trappable QB64 runtime error lands in one place. This module turns that
' trap into something a user can actually send us: a timestamped crash report
' written to the DESKTOP (the one folder every user can find), carrying the
' error, the machine, the display setup, the document state, and the last few
' actions taken before it blew up.
'
' Report path:
'   <Desktop>/DRAW-log/DRAW-crash-logs/DRAW-MMDDYY@HHMMSS-crash.log
'
' One file per SESSION, not per error: the first trapped error creates the file
' with the full header, and any further errors in the same run APPEND a short
' block. A cascade is far more useful read as one timeline, and it stops a
' runaway loop from carpet-bombing the desktop with hundreds of files.
'
' === WHY REPORTING IS DEFERRED, NOT DONE IN THE HANDLER =======================
' While a QB64 error handler is running, error trapping is OFF. A second error
' raised inside it is UNHANDLED — which pops the modal "Unhandled Error #n /
' Continue?" dialog and hangs anything automated. Writing files, creating
' directories and shelling out are all things that can fail, so the handler does
' the one thing that cannot fail (stash the error fields into CRASH.P_*) and sets
' CRASH.PENDING. The main loop calls CRASH_flush_pending on the next iteration,
' with trapping armed again, so a failure inside the reporter is just another
' trapped error instead of a hang.
'
' The abort paths in FatalError (no window / too many errors) have no next
' iteration to reach, so they report inline and accept the risk.
'
' Capture is user-controllable via Help > Capture Crash Logs
' (CFG.CRASH_LOGS_ENABLED / DRAW.cfg CRASH_LOGS_ENABLED).
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

' Last N user actions kept for the report ("what were you doing?").
CONST CRASH_MAX_BREADCRUMBS = 32

' Hard cap on error blocks per session. An error inside the render loop would
' otherwise grow the file without bound.
CONST CRASH_MAX_APPENDS = 100

TYPE CRASH_OBJ
    ENABLED       AS INTEGER ' TRUE = write crash reports (mirrors CFG.CRASH_LOGS_ENABLED)
    INITIALIZED   AS INTEGER ' TRUE after CRASH_init has run
    IN_HANDLER    AS INTEGER ' Re-entrancy guard — an error while reporting must not recurse
    ' --- Expected-failure probe ---
    ' QB64 forbids ON ERROR GOTO a label inside a SUB ("Common label within a
    ' SUB/FUNCTION"), so a routine that WANTS to attempt a failing operation
    ' cannot trap locally. Instead it raises PROBE_ACTIVE, runs the statement,
    ' and lowers it: FatalError then skips the statement without stashing or
    ' reporting anything. Keep the window to the guarded statements only — a
    ' genuine unrelated error inside it would be swallowed.
    PROBE_ACTIVE  AS INTEGER ' TRUE = errors are expected; do not report them
    PROBE_TRIPPED AS INTEGER ' TRUE = an error fired while PROBE_ACTIVE
    REPORT_COUNT  AS INTEGER ' Error blocks written to the report this session
    NOTIFIED      AS INTEGER ' TRUE once the user has been told a report exists
    DIR_READY     AS INTEGER ' TRUE once LOG_DIR exists on disk
    LOG_DIR       AS STRING  ' <Desktop>/DRAW-log/DRAW-crash-logs/ (trailing separator)
    LOG_PATH      AS STRING  ' Full path of THIS session's report ("" until first error)
    SESSION_START AS DOUBLE  ' TIMER(.001) at include time (for uptime)
    SYS_CACHED    AS INTEGER ' TRUE once SYS_TEXT has been collected
    SYS_TEXT      AS STRING  ' Platform hardware/OS block, CHR$(10)-separated
    BC_HEAD       AS INTEGER ' Breadcrumb ring write cursor (0-based)
    BC_COUNT      AS INTEGER ' Breadcrumbs recorded (saturates at CRASH_MAX_BREADCRUMBS)
    ' --- Deferred report payload, filled by CRASH_stash_error in the handler ---
    PENDING       AS INTEGER ' TRUE = main loop owes us a CRASH_flush_pending
    P_CODE        AS INTEGER ' ERR
    P_LINE        AS LONG    ' _ERRORLINE
    P_INCL        AS STRING  ' _INCLERRORFILE$
    P_ILINE       AS LONG    ' _INCLERRORLINE
    P_MSG         AS STRING  ' _ERRORMESSAGE$
    ' --- Non-blocking on-screen notice (replaces the old blocking _MESSAGEBOX) ---
    NOTIFY_UNTIL  AS DOUBLE  ' TIMER(.001) at which the crash banner self-dismisses; 0 = inactive
    NOTIFY_MSG    AS STRING  ' Text shown in the banner
END TYPE

DIM SHARED CRASH AS CRASH_OBJ

' Breadcrumb ring buffer (text + seconds since session start)
DIM SHARED CRASH_BC_TEXT(0 TO CRASH_MAX_BREADCRUMBS - 1) AS STRING
DIM SHARED CRASH_BC_TIME(0 TO CRASH_MAX_BREADCRUMBS - 1) AS SINGLE

' Defaults. ENABLED starts TRUE so a crash during startup — before CONFIG_load
' has told us the user's preference — still produces a report. CRASH_init syncs
' it to CFG afterwards. Literal -1/0 rather than TRUE/FALSE: this file is
' included before those CONSTs are guaranteed visible.
CRASH.ENABLED      = -1
CRASH.INITIALIZED  = 0
CRASH.IN_HANDLER   = 0
CRASH.REPORT_COUNT = 0
CRASH.NOTIFIED     = 0
CRASH.DIR_READY    = 0
CRASH.LOG_DIR      = ""
CRASH.LOG_PATH     = ""
CRASH.SYS_CACHED   = 0
CRASH.SYS_TEXT     = ""
CRASH.BC_HEAD      = 0
CRASH.BC_COUNT     = 0
CRASH.PENDING      = 0
CRASH.P_CODE       = 0
CRASH.P_LINE       = 0
CRASH.P_INCL       = ""
CRASH.P_ILINE      = 0
CRASH.P_MSG        = ""
CRASH.NOTIFY_UNTIL = 0
CRASH.NOTIFY_MSG   = ""

' Stamped at include time (a few statements into startup) so "Uptime" in the
' report means "how long had DRAW been running", not "since CRASH_init".
CRASH.SESSION_START = TIMER(.001)
