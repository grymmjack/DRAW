'======================================================================
' GLFW_DRAGDROP_TEST.BAS — verify file drag & drop cross-platform (a740g)
'
' The drop pipeline (4 keywords that only mean anything together):
'   _ACCEPTFILEDROP      enable the window as a drop target (call once)
'   _TOTALDROPPEDFILES   count of items dropped this batch
'   _DROPPEDFILE$(i)     full path of the i-th dropped item
'   _FINISHDROP          clear the buffer for the next drop
' Pre-a740g this whole block was wrapped in $IF WIN in DRAW.BAS (Win-only).
'
' Build/run: make a740g-run TEST=DRAGDROP
' Wiki: https://qb64phoenix.com/qb64wiki/index.php/_ACCEPTFILEDROP
'
' PASS when, on Linux/macOS/Windows: dragging files from the OS file manager
' onto this window lists their full paths and the count.
'======================================================================
$CONSOLE
OPTION _EXPLICIT

CONST TRUE = -1
CONST FALSE = 0

SCREEN _NEWIMAGE(760, 460, 32)
_TITLE "GLFW Test: drag & drop  (_ACCEPTFILEDROP)"

_ACCEPTFILEDROP ' enable this window as a file drop target

DIM k AS LONG
DIM total AS LONG
DIM i AS LONG
DIM lastCount AS LONG
DIM dropLn(1 TO 12) AS STRING
DIM nLines AS INTEGER
DIM j AS INTEGER

DO
    IF _EXIT THEN SYSTEM
    k = _KEYHIT
    IF k = 27 THEN SYSTEM

    total = _TOTALDROPPEDFILES
    IF total > 0 THEN
        lastCount = total
        nLines = 0
        FOR i = 1 TO total
            IF nLines < 12 THEN
                nLines = nLines + 1
                dropLn(nLines) = LTRIM$(STR$(i)) + ": " + _DROPPEDFILE$(i)
            END IF
            _ECHO "dropped: " + _DROPPEDFILE$(i)
        NEXT
        _FINISHDROP ' clear so the next drop starts fresh
    END IF

    CLS , _RGB32(12, 14, 22)
    COLOR _RGB32(255, 255, 255), _RGB32(12, 14, 22)
    LOCATE 2, 3: PRINT "Drag & drop test  —  drag files onto this window"
    LOCATE 3, 3: PRINT STRING$(56, "-")
    LOCATE 5, 3: PRINT "Last drop count: "; lastCount
    IF nLines = 0 THEN
        COLOR _RGB32(180, 180, 180), _RGB32(12, 14, 22)
        LOCATE 7, 5: PRINT "(waiting for a drop...)"
    ELSE
        COLOR _RGB32(150, 230, 255), _RGB32(12, 14, 22)
        FOR j = 1 TO nLines
            LOCATE 6 + j, 5: PRINT LEFT$(dropLn(j), 86)
        NEXT
    END IF
    COLOR _RGB32(200, 200, 200), _RGB32(12, 14, 22)
    LOCATE 24, 3: PRINT "ESC or close window = quit"
    _DISPLAY
    _LIMIT 60
LOOP
