' =============================================================================
' QA/unit/ws-unit.bas - headless unit test for CFG/WORKSPACE.BM (scan, user
' override, BASED_ON inheritance + cycles, key normalization, lists). Run from
' the repo root so ASSETS/WORKSPACES resolves:
'   ~/git/qb64pe/qb64pe -w -x -o QA/unit/ws-unit.run QA/unit/ws-unit.bas && QA/unit/ws-unit.run
' Exit code 0 = all pass.
' =============================================================================
$CONSOLE:ONLY
OPTION _EXPLICIT
CONST TRUE = -1, FALSE = 0
DIM SHARED PATHS_DATA_DIR AS STRING
DIM SHARED FAILS AS INTEGER, PASSES AS INTEGER
'$INCLUDE:'../../CFG/WORKSPACE.BI'

DIM tmpRoot AS STRING, ud AS STRING, fh AS INTEGER, i AS INTEGER
CHDIR _STARTDIR$ ' QB64 starts in the exe's folder; ASSETS/ is relative to the repo root
tmpRoot = _CWD$ + "/QA/unit/ws-unit-tmp"
IF _DIREXISTS(tmpRoot) = 0 THEN MKDIR tmpRoot
ud = tmpRoot + "/WORKSPACES"
IF _DIREXISTS(ud) = 0 THEN MKDIR ud
PATHS_DATA_DIR = tmpRoot + "/"

' user override of a built-in + a child + a cycle pair
fh = FREEFILE: OPEN ud + "/simple.workspace" FOR OUTPUT AS #fh
PRINT #fh, "[WORKSPACE]": PRINT #fh, "NAME=My Simple": PRINT #fh, "[CHROME]": PRINT #fh, "MENUBAR=HIDE   ; inline note"
CLOSE #fh
fh = FREEFILE: OPEN ud + "/child.workspace" FOR OUTPUT AS #fh
PRINT #fh, "[WORKSPACE]": PRINT #fh, "NAME=Child": PRINT #fh, "BASED_ON=Annotate"
PRINT #fh, "[CHROME]": PRINT #fh, "LAYER_PANEL=SHOW"
PRINT #fh, "[KEYS]": PRINT #fh, "q=rect"
PRINT #fh, "[START]": PRINT #fh, "FG=#00FF00"
CLOSE #fh
fh = FREEFILE: OPEN ud + "/loopa.workspace" FOR OUTPUT AS #fh
PRINT #fh, "[WORKSPACE]": PRINT #fh, "BASED_ON=loopb": PRINT #fh, "[CHROME]": PRINT #fh, "PREVIEW=SHOW"
CLOSE #fh
fh = FREEFILE: OPEN ud + "/loopb.workspace" FOR OUTPUT AS #fh
PRINT #fh, "[WORKSPACE]": PRINT #fh, "BASED_ON=loopa": PRINT #fh, "[CHROME]": PRINT #fh, "DRAWER=SHOW"
CLOSE #fh

WS_scan
CHECK WS_COUNT = 6, "6 workspaces (default annotate simple child loopa loopb), got" + STR$(WS_COUNT)
CHECK WS_LIST(1).id = "default", "default listed first"
FOR i = 3 TO WS_COUNT
    CHECK UCASE$(WS_LIST(i - 1).title) <= UCASE$(WS_LIST(i).title), "sorted by title at" + STR$(i)
NEXT i
CHECK WS_find%("ANNOTATE") > 0, "find by id, any case"
CHECK WS_find%("annotate.workspace") = WS_find%("annotate"), "find tolerates the extension"
CHECK WS_find%("My Simple") = WS_find%("simple"), "find by title"
CHECK WS_find%("nope") = 0, "missing -> 0"
CHECK WS_LIST(WS_find%("simple")).userFile AND WS_LIST(WS_find%("simple")).builtin, "simple: user overrides built-in"
CHECK WS_LIST(WS_find%("simple")).title = "My Simple", "user header wins"
CHECK WS_is_default%("Default"), "is_default"

' default resolves to an empty overlay
CHECK WS_resolve%("default"), "resolve default"
CHECK WS_next_in_section%("CHROME", 0) = 0, "default has no CHROME keys"

' user simple: only its own file (the built-in is replaced, not merged)
CHECK WS_resolve%("simple"), "resolve simple"
CHECK WS_get$("chrome.menubar", "?") = "HIDE", "inline comment stripped"
CHECK WS_has%("TOOLBOX.BUTTONS") = FALSE, "user file replaces built-in wholesale"

' child of annotate inherits and overrides
CHECK WS_resolve%("child"), "resolve child"
CHECK WS_RES_ID = "child", "res id"
CHECK WS_get$("CHROME.LAYER_PANEL", "?") = "SHOW", "child overrides parent"
CHECK WS_get$("CHROME.ORGANIZER", "?") = "HIDE", "child inherits parent"
CHECK WS_get$("START.FG", "?") = "#00FF00", "# value not treated as comment"
CHECK WS_get$("KEYS.q", "?") = "rect", "child key"
CHECK WS_get$("KEYS.r", "?") = "rect", "inherited key r"
CHECK WS_get$("KEYS.R", "?") = "rect-filled", "KEYS keep case: R"
CHECK WS_get$("WORKSPACE.NAME", "?") = "Child", "name from child"
CHECK WS_list_count%(WS_get$("TOOLBOX.BUTTONS", "")) = 12, "12 annotate buttons"
CHECK WS_list_item$(WS_get$("TOOLBOX.BUTTONS", ""), 6) = "arrow", "6th button arrow"
CHECK WS_list_item$("a, b ,c", 2) = "b", "list item trimmed"
CHECK WS_list_item$("a,b", 3) = "", "past end"
CHECK WS_list_count%("") = 0, "empty list"
DIM n AS INTEGER: n = 0: i = 0
DO
    i = WS_next_in_section%("KEYS", i)
    IF i = 0 THEN EXIT DO
    n = n + 1
LOOP
CHECK n = 12, "12 keys (11 annotate + q), got" + STR$(n)

' cycle terminates and still resolves both files
CHECK WS_resolve%("loopa"), "cycle resolves"
CHECK WS_get$("CHROME.PREVIEW", "?") = "SHOW" AND WS_get$("CHROME.DRAWER", "?") = "SHOW", "cycle merged both"
CHECK WS_resolve%("ghost") = FALSE, "missing fails"
CHECK LEN(WS_LAST_ERROR) > 0, "error set"

KILL ud + "/*.workspace": RMDIR ud: RMDIR tmpRoot
PRINT "ws-unit:"; PASSES; "passed,"; FAILS; "failed"
IF FAILS THEN SYSTEM 1
SYSTEM 0

SUB CHECK (ok AS INTEGER, msg AS STRING)
    IF ok THEN PASSES = PASSES + 1 ELSE FAILS = FAILS + 1: PRINT "FAIL: "; msg
END SUB

FUNCTION PATHS_sep$ ()
    PATHS_sep$ = "/"
END FUNCTION

'$INCLUDE:'../../CFG/WORKSPACE.BM'
