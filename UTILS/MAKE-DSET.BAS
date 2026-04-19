''
' MAKE-DSET.BAS - DRAW Drawer Set Creator
' ============================================================================
' Creates .dset files from a directory of images (PNG/BMP/JPG).
' Can also process existing .dset files with filters.
'
' Usage: MAKE-DSET [-b|-p|-g] [-d] <directory>
'        MAKE-DSET -d <input.dset> [output.dset]
'
' Flags:
'   -b  Brush mode (default)
'   -p  Pattern mode
'   -g  Gradient mode
'   -d  Desaturate (convert to grayscale, preserving alpha)
'
' When given a directory:
' - Loads up to 30 images per .dset file (DRAWER_SLOT_COUNT)
' - Names the .dset file after the folder name
' - If > 30 images, creates folder1.dset, folder2.dset, folder3.dset, etc.
'
' When given an existing .dset file:
' - Reads the .dset, applies filter(s), writes to output
' - If no output specified, writes to <input>-desaturated.dset
'
' Build: qb64pe -w -x -o MAKE-DSET.run MAKE-DSET.BAS
'
$CONSOLE:ONLY
OPTION _EXPLICIT

CONST SLOT_COUNT    = 30
CONST MODE_BRUSH    = 1
CONST MODE_PATTERN  = 2
CONST MODE_GRADIENT = 3
CONST TRUE          = -1
CONST FALSE         = 0

DIM dir        AS STRING
DIM dirName    AS STRING
DIM fileCount  AS INTEGER
DIM setCount   AS INTEGER
DIM setNum     AS INTEGER
DIM slotNum    AS INTEGER
DIM i          AS INTEGER
DIM imgPath    AS STRING
DIM outFile    AS STRING
DIM imgHandle  AS LONG
DIM fh         AS INTEGER
DIM dsetMode   AS INTEGER
DIM modeName   AS STRING
DIM desaturate AS INTEGER
DIM inputDset  AS STRING
DIM outputDset AS STRING

' ---- Collect image file list ----
REDIM fileList(1 TO 1000) AS STRING
REDIM posArgList(1 TO 10) AS STRING

' Get arguments from command line using COMMAND$(n) for proper quote handling
IF COMMAND$(1) = "" THEN
    PRINT "DRAW Drawer Set Creator"
    PRINT "======================"
    PRINT
    PRINT "Usage: MAKE-DSET [-b|-p|-g] [-d] <directory>"
    PRINT "       MAKE-DSET -d <input.dset> [output.dset]"
    PRINT
    PRINT "Flags:"
    PRINT "  -b  Brush mode (default)"
    PRINT "  -p  Pattern mode"
    PRINT "  -g  Gradient mode"
    PRINT "  -d  Desaturate (convert to grayscale, preserving alpha)"
    PRINT
    PRINT "Creates .dset files from a directory of images (PNG/BMP/JPG)."
    PRINT "Each .dset holds up to 30 images. If the directory has more,"
    PRINT "multiple sets are created: name1.dset, name2.dset, etc."
    PRINT
    PRINT "Can also process an existing .dset file:"
    PRINT "  MAKE-DSET -d mypatterns.dset           -> mypatterns-desaturated.dset"
    PRINT "  MAKE-DSET -d mypatterns.dset output.dset -> output.dset"
    SYSTEM
END IF

' Parse arguments using COMMAND$(n) for proper shell quote handling
dsetMode%   = MODE_BRUSH
modeName$   = "brush"
desaturate% = FALSE

' Collect positional args (non-flag arguments)
DIM argNum  AS INTEGER
DIM argVal  AS STRING
DIM posArgs AS INTEGER
REDIM posArgList(1 TO 10) AS STRING
posArgs% = 0
argNum%  = 1
DO
    argVal$ = COMMAND$(argNum%)
    IF argVal$ = "" THEN EXIT DO
    IF LCASE$(argVal$) = "-p" THEN
        dsetMode% = MODE_PATTERN
        modeName$ = "pattern"
    ELSEIF LCASE$(argVal$) = "-g" THEN
        dsetMode% = MODE_GRADIENT
        modeName$ = "gradient"
    ELSEIF LCASE$(argVal$) = "-b" THEN
        dsetMode% = MODE_BRUSH
        modeName$ = "brush"
    ELSEIF LCASE$(argVal$) = "-d" THEN
        desaturate% = TRUE
    ELSE
        posArgs% = posArgs% + 1
        IF posArgs% <= UBOUND(posArgList) THEN posArgList(posArgs%) = argVal$
    END IF
    argNum% = argNum% + 1
LOOP

IF posArgs% = 0 THEN
    PRINT "Error: No directory or .dset file specified."
    SYSTEM 1
END IF

' First positional arg is the input path (directory or .dset file)
' Second positional arg (optional) is the output path
DIM isDsetFile AS INTEGER
isDsetFile% = FALSE
inputDset$  = posArgList(1)
IF posArgs% >= 2 THEN outputDset$ = posArgList(2) ELSE outputDset$ = ""

IF LCASE$(RIGHT$(inputDset$, 5)) = ".dset" THEN
    ' Resolve path
    IF _FILEEXISTS(inputDset$) THEN
        isDsetFile% = TRUE
    ELSEIF _FILEEXISTS(_STARTDIR$ + "/" + inputDset$) THEN
        inputDset$  = _STARTDIR$ + "/" + inputDset$
        isDsetFile% = TRUE
    END IF
END IF

IF isDsetFile% THEN
    ' ---- Process existing .dset file ----
    IF NOT desaturate% THEN
        PRINT "Error: Processing a .dset file requires -d (desaturate) flag."
        SYSTEM 1
    END IF
    GOSUB ProcessExistingDset
    SYSTEM
END IF

' ---- Create from directory mode ----
dir$ = posArgList(1)

' Remove trailing slash if present
IF RIGHT$(dir$, 1) = "/" OR RIGHT$(dir$, 1) = "\" THEN
    dir$ = LEFT$(dir$, LEN(dir$) - 1)
END IF

' Verify directory exists — try as-is first, then relative to _STARTDIR$
IF NOT _DIREXISTS(dir$) THEN
    DIM tryDir AS STRING
    tryDir$ = _STARTDIR$ + "/" + dir$
    IF _DIREXISTS(tryDir$) THEN
        dir$ = tryDir$
    ELSE
        PRINT "Error: Directory not found: " + dir$
        SYSTEM 1
    END IF
END IF

' Extract folder name (last component of path)
DIM slashPos AS INTEGER
DIM tempDir  AS STRING
tempDir$ = dir$
' Find the last path separator
slashPos% = 0
FOR i% = LEN(tempDir$) TO 1 STEP -1
    IF MID$(tempDir$, i%, 1) = "/" OR MID$(tempDir$, i%, 1) = "\" THEN
        slashPos% = i%
        EXIT FOR
    END IF
NEXT i%
IF slashPos% > 0 THEN
    dirName$ = MID$(tempDir$, slashPos% + 1)
ELSE
    dirName$ = tempDir$
END IF
dirName$ = LCASE$(dirName$)

' Scan directory for image files
PRINT "Mode: " + modeName$
IF desaturate% THEN PRINT "Filter: desaturate"
PRINT "Scanning: " + dir$
fileCount% = 0

DIM entry AS STRING
entry$ = _FILES$(dir$ + "/*.png")
DO WHILE entry$ <> ""
    fileCount% = fileCount% + 1
    IF fileCount% > UBOUND(fileList) THEN REDIM _PRESERVE fileList(1 TO fileCount% + 100) AS STRING
    fileList(fileCount%) = dir$ + "/" + entry$
    entry$               = _FILES$
LOOP

entry$ = _FILES$(dir$ + "/*.bmp")
DO WHILE entry$ <> ""
    fileCount% = fileCount% + 1
    IF fileCount% > UBOUND(fileList) THEN REDIM _PRESERVE fileList(1 TO fileCount% + 100) AS STRING
    fileList(fileCount%) = dir$ + "/" + entry$
    entry$               = _FILES$
LOOP

entry$ = _FILES$(dir$ + "/*.jpg")
DO WHILE entry$ <> ""
    fileCount% = fileCount% + 1
    IF fileCount% > UBOUND(fileList) THEN REDIM _PRESERVE fileList(1 TO fileCount% + 100) AS STRING
    fileList(fileCount%) = dir$ + "/" + entry$
    entry$               = _FILES$
LOOP

entry$ = _FILES$(dir$ + "/*.jpeg")
DO WHILE entry$ <> ""
    fileCount% = fileCount% + 1
    IF fileCount% > UBOUND(fileList) THEN REDIM _PRESERVE fileList(1 TO fileCount% + 100) AS STRING
    fileList(fileCount%) = dir$ + "/" + entry$
    entry$               = _FILES$
LOOP

IF fileCount% = 0 THEN
    PRINT "Error: No image files (PNG/BMP/JPG) found in: " + dir$
    SYSTEM 1
END IF

' Sort file list alphabetically (simple bubble sort)
DIM swapped AS INTEGER
DIM tempStr AS STRING
DO
    swapped% = FALSE
    FOR i% = 1 TO fileCount% - 1
        IF fileList(i%) > fileList(i% + 1) THEN
            tempStr$         = fileList(i%)
            fileList(i%)     = fileList(i% + 1)
            fileList(i% + 1) = tempStr$
            swapped%         = TRUE
        END IF
    NEXT i%
LOOP WHILE swapped%

PRINT "Found" + STR$(fileCount%) + " image(s)."

' Calculate number of sets needed
setCount% = (fileCount% + SLOT_COUNT - 1) \ SLOT_COUNT

' ---- Generate .dset files ----
FOR setNum% = 1 TO setCount%
    ' Determine output filename
    IF setCount% = 1 THEN
        outFile$ = dir$ + "/" + dirName$ + ".dset"
    ELSE
        outFile$ = dir$ + "/" + dirName$ + LTRIM$(STR$(setNum%)) + ".dset"
    END IF

    PRINT "Creating: " + outFile$

    fh% = FREEFILE
    OPEN outFile$ FOR BINARY AS #fh%

    ' Write header
    DIM magic        AS STRING * 4
    DIM version      AS INTEGER
    DIM mode         AS INTEGER
    DIM selectedSlot AS INTEGER
    magic$        = "DST1"
    version%      = 1
    mode%         = dsetMode%
    selectedSlot% = 1
    PUT #fh%, , magic$
    PUT #fh%, , version%
    PUT #fh%, , mode%
    PUT #fh%, , selectedSlot%

    ' Write slots
    DIM startIdx AS INTEGER
    DIM endIdx   AS INTEGER
    startIdx% = (setNum% - 1) * SLOT_COUNT + 1
    endIdx%   = startIdx% + SLOT_COUNT - 1
    IF endIdx% > fileCount% THEN endIdx% = fileCount%

    FOR slotNum% = 1 TO SLOT_COUNT
        DIM fileIdx AS INTEGER
        fileIdx% = startIdx% + slotNum% - 1

        IF fileIdx% <= endIdx% THEN
            imgPath$   = fileList(fileIdx%)
            imgHandle& = _LOADIMAGE(imgPath$, 32)

            IF imgHandle& < -1 THEN
                ' Write slot with image
                DIM hasImage    AS INTEGER
                DIM imgW        AS INTEGER
                DIM imgH        AS INTEGER
                DIM x           AS INTEGER
                DIM y           AS INTEGER
                DIM c           AS _UNSIGNED LONG
                DIM m           AS _MEM
                DIM pixelOffset AS _OFFSET

                hasImage% = TRUE
                PUT #fh%, , hasImage%

                imgW% = _WIDTH(imgHandle&)
                imgH% = _HEIGHT(imgHandle&)
                PUT #fh%, , imgW%
                PUT #fh%, , imgH%

                m = _MEMIMAGE(imgHandle&)
                FOR y% = 0 TO imgH% - 1
                    FOR x% = 0 TO imgW% - 1
                        pixelOffset%& = (y% * imgW% + x%) * 4
                        c~&           = _MEMGET(m, m.OFFSET + pixelOffset%&, _UNSIGNED LONG)
                        IF desaturate% THEN c~& = DesaturatePixel~&(c~&)
                        PUT #fh%, , c~&
                    NEXT x%
                NEXT y%
                _MEMFREE m

                _FREEIMAGE imgHandle&

                ' Extract just the filename for display
                DIM dispName AS STRING
                DIM dp       AS INTEGER
                dp% = 0
                FOR i% = LEN(imgPath$) TO 1 STEP -1
                    IF MID$(imgPath$, i%, 1) = "/" OR MID$(imgPath$, i%, 1) = "\" THEN
                        dp% = i%
                        EXIT FOR
                    END IF
                NEXT i%
                IF dp% > 0 THEN
                    dispName$ = MID$(imgPath$, dp% + 1)
                ELSE
                    dispName$ = imgPath$
                END IF
                PRINT "  Slot" + STR$(slotNum%) + ": " + dispName$ + " (" + LTRIM$(STR$(imgW%)) + "x" + LTRIM$(STR$(imgH%)) + ")"
            ELSE
                PRINT "  Slot" + STR$(slotNum%) + ": FAILED to load " + imgPath$
                ' Write empty slot
                DIM noImage  AS INTEGER
                noImage% = FALSE
                PUT #fh%, , noImage%
            END IF
        ELSE
            ' Empty slot (no more images)
            DIM emptySlot AS INTEGER
            emptySlot% = FALSE
            PUT #fh%, , emptySlot%
        END IF
    NEXT slotNum%

    CLOSE #fh%
    PRINT "  Done. (" + LTRIM$(STR$(endIdx% - startIdx% + 1)) + " images)"
NEXT setNum%

PRINT
PRINT "Created" + STR$(setCount%) + " drawer set file(s)."
SYSTEM

' ============================================================================
' Process existing .dset file — read, desaturate pixels, write new file
' ============================================================================
ProcessExistingDset:
    DIM pFhIn      AS INTEGER
    DIM pFhOut     AS INTEGER
    DIM pMagic     AS STRING * 4
    DIM pVersion   AS INTEGER
    DIM pMode      AS INTEGER
    DIM pSelected  AS INTEGER
    DIM pHasImage  AS INTEGER
    DIM pImgW      AS INTEGER
    DIM pImgH      AS INTEGER
    DIM pPixel     AS _UNSIGNED LONG
    DIM pX         AS INTEGER
    DIM pY         AS INTEGER
    DIM pSlot      AS INTEGER
    DIM pSlotCount AS INTEGER

    ' Build output path if not specified
    IF outputDset$ = "" THEN
        outputDset$ = LEFT$(inputDset$, LEN(inputDset$) - 5) + "-desaturated.dset"
    ELSEIF _STARTDIR$ + "/" <> LEFT$(outputDset$, LEN(_STARTDIR$) + 1) THEN
        IF MID$(outputDset$, 2, 1) <> ":" AND LEFT$(outputDset$, 1) <> "/" THEN
            outputDset$ = _STARTDIR$ + "/" + outputDset$
        END IF
    END IF

    PRINT "Processing: " + inputDset$
    PRINT "Output:     " + outputDset$
    PRINT "Filter:     desaturate"

    ' Open input
    pFhIn% = FREEFILE
    OPEN inputDset$ FOR BINARY AS #pFhIn%

    ' Read and validate header
    GET #pFhIn%, , pMagic$
    IF pMagic$ <> "DST1" THEN
        CLOSE #pFhIn%
        PRINT "Error: Not a valid .dset file (bad magic)"
        SYSTEM 1
    END IF
    GET #pFhIn%, , pVersion%
    GET #pFhIn%, , pMode%
    GET #pFhIn%, , pSelected%

    IF pVersion% <> 1 OR pMode% < MODE_BRUSH OR pMode% > MODE_GRADIENT THEN
        CLOSE #pFhIn%
        PRINT "Error: Unsupported .dset version or mode"
        SYSTEM 1
    END IF

    ' Open output
    pFhOut% = FREEFILE
    OPEN outputDset$ FOR BINARY AS #pFhOut%

    ' Write header (unchanged)
    PUT #pFhOut%, , pMagic$
    PUT #pFhOut%, , pVersion%
    PUT #pFhOut%, , pMode%
    PUT #pFhOut%, , pSelected%

    ' Process each slot
    pSlotCount% = 0
    FOR pSlot% = 1 TO SLOT_COUNT
        GET #pFhIn%, , pHasImage%
        PUT #pFhOut%, , pHasImage%

        IF pHasImage% THEN
            GET #pFhIn%, , pImgW%
            GET #pFhIn%, , pImgH%
            PUT #pFhOut%, , pImgW%
            PUT #pFhOut%, , pImgH%

            FOR pY% = 0 TO pImgH% - 1
                FOR pX% = 0 TO pImgW% - 1
                    GET #pFhIn%, , pPixel~&
                    pPixel~& = DesaturatePixel~&(pPixel~&)
                    PUT #pFhOut%, , pPixel~&
                NEXT pX%
            NEXT pY%

            pSlotCount% = pSlotCount% + 1
            PRINT "  Slot" + STR$(pSlot%) + ": " + LTRIM$(STR$(pImgW%)) + "x" + LTRIM$(STR$(pImgH%)) + " -> desaturated"
        END IF
    NEXT pSlot%

    CLOSE #pFhIn%
    CLOSE #pFhOut%

    PRINT "Done. (" + LTRIM$(STR$(pSlotCount%)) + " slots processed)"
RETURN

' ============================================================================
' Desaturate a single BGRA pixel using luminance weights
' Preserves alpha channel
' ============================================================================
FUNCTION DesaturatePixel~& (c AS _UNSIGNED LONG)
    DIM r    AS INTEGER
    DIM g    AS INTEGER
    DIM b    AS INTEGER
    DIM a    AS INTEGER
    DIM gray AS INTEGER

    a% = _ALPHA32(c~&)
    IF a% = 0 THEN
        DesaturatePixel~& = c~&
        EXIT FUNCTION
    END IF

    r% = _RED32(c~&)
    g% = _GREEN32(c~&)
    b% = _BLUE32(c~&)

    ' ITU-R BT.601 luminance
    gray% = INT(0.299 * r% + 0.587 * g% + 0.114 * b% + 0.5)
    IF gray% > 255 THEN gray% = 255

    DesaturatePixel~& = _RGBA32(gray%, gray%, gray%, a%)
END FUNCTION
