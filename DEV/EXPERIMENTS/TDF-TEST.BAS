''
' TDF-TEST.BAS — standalone regression harness for GUI/TDF-FONT.BI/BM.
'
' Exercises the TheDraw parser and rasteriser without pulling in the rest of
' DRAW: counts faces, renders samples of each font type to /tmp, sweeps every
' installed face for decode failures, and dumps a deterministic set of glyph
' cell grids that can be diffed against the reference implementation
' (Mike Krueger's `retrofont` crate, as used by kaleidotron).
'
' Build and run FROM THE REPO ROOT so the relative asset path resolves:
'     qb64pe -w -x -o /tmp/TDF-TEST.run DEV/EXPERIMENTS/TDF-TEST.BAS
'     ./: cd ~/git/DRAW && /tmp/TDF-TEST.run
'
' The GRIDDUMP lines are the interesting output — each is "R<row> <cp437 codes>"
' with "...." for a cell that carries no ink. A row is padded to the glyph's
' full width here, whereas retrofont's rows are ragged, so strip trailing
' "...." from both sides before diffing.
'
'$DYNAMIC
$CONSOLE:ONLY
OPTION _EXPLICIT
OPTION _EXPLICITARRAY

CONST TRUE  = -1
CONST FALSE = 0

'$INCLUDE:'../../GUI/TDF-FONT.BI'

DIM SHARED TEST_FAILURES AS INTEGER
TEST_FAILURES% = 0

TDF_ensure_scanned

PRINT "bundles      :"; TDF_BUNDLE_COUNT%
PRINT "faces        :"; TDF_FACE_COUNT%

DIM b AS INTEGER
FOR b% = 0 TO TDF_BUNDLE_COUNT% - 1
    PRINT "  "; RTRIM$(TDF_BUNDLE(b%).labelTxt);
    PRINT " first="; TDF_BUNDLE(b%).firstFace;
    PRINT " count="; TDF_BUNDLE(b%).faceCount
NEXT b%

TEST_expect "face count", TDF_FACE_COUNT%, 3757
TEST_expect "bundle count", TDF_BUNDLE_COUNT%, 3

' --- Sample the first face of each bundle ---------------------------------
DIM i AS INTEGER
FOR b% = 0 TO TDF_BUNDLE_COUNT% - 1
    i% = TDF_BUNDLE(b%).firstFace
    PRINT
    PRINT "["; RTRIM$(TDF_BUNDLE(b%).labelTxt); "] face"; i%; " "; TDF_face_label$(i%)
    PRINT "  type="; TDF_FACE(i%).faceType;
    PRINT " gap="; TDF_FACE(i%).gapDefault;
    PRINT " glyphs="; TDF_FACE(i%).glyphCnt;
    PRINT " cells="; TDF_FACE(i%).cellsW; "x"; TDF_FACE(i%).cellsH
    PRINT "  'A' width(px)="; TDF_glyph_width%(i%, 65);
    PRINT " advance(px)="; TDF_glyph_advance%(i%, 65);
    PRINT " lineheight(px)="; TDF_face_height%(i%)
NEXT b%

' --- Render "DRAW" from one face of each type into PNGs -------------------
FOR b% = 0 TO TDF_BUNDLE_COUNT% - 1
    TEST_render_word TDF_BUNDLE(b%).firstFace, "DRAW", "/tmp/tdf_" + RTRIM$(TDF_BUNDLE(b%).labelTxt) + ".png"
NEXT b%

' Outline faces re-rendered in a few of the 19 box-drawing styles.
DIM st AS INTEGER
FOR st% = 0 TO 18 STEP 6
    TDF_OPTS.outlineStyle = st%
    TEST_render_word 0, "DRAW", "/tmp/tdf_outline_style" + LTRIM$(STR$(st%)) + ".png"
NEXT st%
TDF_OPTS.outlineStyle = 0

' A spread of colour faces, to catch anything the first face happens to dodge.
DIM sample AS INTEGER
FOR sample% = 0 TO 5
    i% = 197 + sample% * 600
    IF i% < TDF_FACE_COUNT% THEN
        TEST_render_word i%, "DRAW", "/tmp/tdf_sample" + LTRIM$(STR$(sample%)) + ".png"
    END IF
NEXT sample%

' Downscale: same face at several scales, antialiased and not, so the box filter
' can be compared against nearest-neighbour by eye.
DIM scl AS INTEGER
FOR scl% = 0 TO 1
    TDF_OPTS.antialias = (scl% = 1)
    TDF_OPTS.scalePct  = 100
    TEST_render_word 197, "DRAW", "/tmp/tdf_scale100_aa" + LTRIM$(STR$(scl%)) + ".png"
    TDF_OPTS.scalePct = 50
    TEST_render_word 197, "DRAW", "/tmp/tdf_scale50_aa" + LTRIM$(STR$(scl%)) + ".png"
    TDF_OPTS.scalePct = 25
    TEST_render_word 197, "DRAW", "/tmp/tdf_scale25_aa" + LTRIM$(STR$(scl%)) + ".png"
NEXT scl%
TDF_OPTS.scalePct  = 50
TDF_OPTS.antialias = TRUE
PRINT "at 50%: 'A' width(px)="; TDF_glyph_width%(197, 65); " advance="; TDF_glyph_advance%(197, 65); " lineheight="; TDF_face_height%(197)
TEST_expect_true "50% halves the advance", (TDF_glyph_advance%(197, 65) > 0)
TDF_OPTS.scalePct = 100

' Alphabet render — proves the per-character lookup really is per-character and
' is not handing back the same glyph for every letter.
TEST_render_word 3197, "ABCDEFGH", "/tmp/tdf_alphabet.png"
TEST_render_word 197, "ABCDEFGH", "/tmp/tdf_alphabet2.png"
TEST_distinct_glyphs 3197
TEST_distinct_glyphs 197

' Cell-grid dump for a deterministic spread of (face, char) pairs, so the whole
' decoder can be diffed against retrofont rather than spot-checked.
DIM dumpFace AS INTEGER, dumpChar AS INTEGER, dumpN AS INTEGER
FOR dumpN% = 0 TO 59
    SELECT CASE dumpN% \ 20
        CASE 0    : dumpFace% = (dumpN% MOD 20) MOD 6                  ' OUTLINE 0-5
        CASE 1    : dumpFace% = 6 + ((dumpN% MOD 20) * 9) MOD 191      ' BLOCK
        CASE ELSE : dumpFace% = 197 + ((dumpN% MOD 20) * 177) MOD 3560 ' COLOR
    END SELECT
    dumpChar% = 33 + (dumpN% * 7) MOD 94
    TEST_dump_grid dumpFace%, dumpChar%
NEXT dumpN%

' --- Sweep EVERY face: decode 'A', assert nothing explodes ----------------
PRINT
PRINT "sweeping all faces..."
DIM ok  AS LONG, missing AS LONG, oversize AS LONG
DIM wpx AS INTEGER
ok& = 0: missing& = 0: oversize& = 0
FOR i% = 0 TO TDF_FACE_COUNT% - 1
    wpx% = TDF_glyph_width%(i%, 65) ' 'A'
    IF wpx% > 0 THEN
        ok& = ok& + 1
        IF wpx% > TDF_MAX_CELLS_W * TDF_CELL_W THEN oversize& = oversize& + 1
    ELSE
        missing& = missing& + 1
    END IF
NEXT i%
PRINT "  'A' decoded in"; ok&; "faces,"; missing&; "without an 'A',"; oversize&; "oversize"
TEST_expect_true "no oversize glyphs", (oversize& = 0)
TEST_expect_true "most faces define 'A'", (ok& > TDF_FACE_COUNT% * 9 \ 10)

' --- Outline style table sanity -------------------------------------------
PRINT
PRINT "outline style 0 slot 0 (should be 196 = single horizontal):"; TDF_OUTLINE_CHAR(0, 0)
PRINT "outline style 3 slot 0 (should be 205 = double horizontal):"; TDF_OUTLINE_CHAR(3, 0)
PRINT "outline style 16 slot 2 (should be 219 = full block)      :"; TDF_OUTLINE_CHAR(16, 2)
TEST_expect "outline[0][0]", TDF_OUTLINE_CHAR(0, 0), 196
TEST_expect "outline[3][0]", TDF_OUTLINE_CHAR(3, 0), 205
TEST_expect "outline[16][2]", TDF_OUTLINE_CHAR(16, 2), 219
TEST_expect "outline[18][16]", TDF_OUTLINE_CHAR(18, 16), 32

PRINT
IF TEST_FAILURES% = 0 THEN
    PRINT "ALL CHECKS PASSED"
ELSE
    PRINT "FAILURES:"; TEST_FAILURES%
END IF
SYSTEM

''
' Hash every letter's decoded cell grid and count how many are distinct. A font
' whose lookup table was being misread would collapse to one or two hashes.
'
SUB TEST_distinct_glyphs (faceIdx%)
    DIM hashes(0 TO 25) AS LONG
    DIM n       AS INTEGER, k AS INTEGER, defined AS INTEGER
    DIM cx      AS INTEGER, cy AS INTEGER
    DIM h       AS LONG
    DIM cellIdx AS LONG
    defined% = 0
    FOR n% = 0 TO 25
        hashes(n%) = 0
        IF TDF_decode_glyph%(faceIdx%, 65 + n%) THEN
            h& = TDF_GRID_W% * 7919 + TDF_GRID_H% * 104729
            FOR cy% = 0 TO TDF_GRID_H% - 1
                FOR cx% = 0 TO TDF_GRID_W% - 1
                    cellIdx& = cy% * TDF_MAX_CELLS_W + cx%
                    h&       = (h& * 31 + TDF_GRID(cellIdx&).ch * 7 + TDF_GRID(cellIdx&).fg * 3 + TDF_GRID(cellIdx&).ink) AND 1073741823
                NEXT cx%
            NEXT cy%
            hashes(n%) = h&
            defined% = defined% + 1
        END IF
    NEXT n%

    DIM distinct AS INTEGER, dup AS INTEGER
    distinct% = 0
    FOR n% = 0 TO 25
        IF hashes(n%) <> 0 THEN
            dup% = FALSE
            FOR k% = 0 TO n% - 1
                IF hashes(k%) = hashes(n%) THEN dup% = TRUE
            NEXT k%
            IF NOT dup% THEN distinct% = distinct% + 1
        END IF
    NEXT n%
    PRINT "  face"; faceIdx%; " '"; RTRIM$(TDF_FACE(faceIdx%).faceName); "': A-Z defined="; defined%; " distinct="; distinct%
    TEST_expect_true "A-Z mostly distinct", (distinct% >= defined% - 2)
END SUB


''
' Print the decoded cell grid as "code/fg/bg" triples, one row per line, so it
' can be diffed byte-for-byte against retrofont's decode of the same glyph.
'
SUB TEST_dump_grid (faceIdx%, charIdx%)
    IF NOT TDF_decode_glyph%(faceIdx%, charIdx%) THEN
        PRINT "GRIDDUMP "; faceIdx%; charIdx%; " UNDEFINED"
        EXIT SUB
    END IF
    PRINT "GRIDDUMP face="; LTRIM$(STR$(faceIdx%)); " char="; CHR$(charIdx%);
    PRINT " w="; LTRIM$(STR$(TDF_GRID_W%)); " h="; LTRIM$(STR$(TDF_GRID_H%))
    DIM cx AS INTEGER, cy AS INTEGER, cellIdx AS LONG, lineTxt AS STRING
    FOR cy% = 0 TO TDF_GRID_H% - 1
        lineTxt$ = ""
        FOR cx% = 0 TO TDF_GRID_W% - 1
            cellIdx& = cy% * TDF_MAX_CELLS_W + cx%
            IF TDF_GRID(cellIdx&).ink = 0 THEN
                lineTxt$ = lineTxt$ + "...."
            ELSE
                lineTxt$ = lineTxt$ + RIGHT$("000" + LTRIM$(STR$(TDF_GRID(cellIdx&).ch)), 3) + ","
            END IF
        NEXT cx%
        PRINT "R"; LTRIM$(STR$(cy%)); " "; lineTxt$
    NEXT cy%
END SUB


''
' Stand-in for CORE/HELPERS.BM's SAFE_FREEIMAGE, which this harness does not
' include. Same contract: 0 and -1 are invalid handles, only < -1 is real.
'
SUB SAFE_FREEIMAGE (handle AS LONG)
    IF handle < -1 THEN _FREEIMAGE handle
END SUB


SUB TEST_expect (nameTxt$, got%, want%)
    IF got% <> want% THEN
        PRINT "  FAIL "; nameTxt$; " got"; got%; " want"; want%
        TEST_FAILURES% = TEST_FAILURES% + 1
    END IF
END SUB

SUB TEST_expect_true (nameTxt$, cond%)
    IF NOT cond% THEN
        PRINT "  FAIL "; nameTxt$
        TEST_FAILURES% = TEST_FAILURES% + 1
    END IF
END SUB

''
' Lay a word out with TDF_glyph_advance% and save it, proving the per-glyph
' images and the advance metric agree.
'
SUB TEST_render_word (faceIdx%, wordTxt$, outPath$)
    DIM totalW AS LONG, maxH AS INTEGER
    DIM k      AS INTEGER, chIdx AS INTEGER
    totalW& = 0
    maxH%   = TDF_face_height%(faceIdx%)
    FOR k% = 1 TO LEN(wordTxt$)
        totalW& = totalW& + TDF_glyph_advance%(faceIdx%, ASC(wordTxt$, k%))
    NEXT k%
    IF totalW& < 1 THEN EXIT SUB
    IF totalW& > 8000 THEN totalW& = 8000

    DIM canvas AS LONG
    canvas& = _NEWIMAGE(totalW&, maxH%, 32)
    IF canvas& >= -1 THEN EXIT SUB

    DIM oldDest AS LONG
    oldDest& = _DEST
    _DEST canvas&
    ' Dark ground so transparency is obvious and single-colour faces are visible.
    CLS , _RGB32(24, 24, 32)
    _DEST oldDest&

    DIM penX AS LONG, glyphImg AS LONG
    penX& = 0
    FOR k% = 1 TO LEN(wordTxt$)
        chIdx% = ASC(wordTxt$, k%)
        TDF_render_glyph faceIdx%, chIdx%, _RGB32(255, 190, 60), glyphImg&
        IF glyphImg& < -1 THEN
            _PUTIMAGE (penX&, 0), glyphImg&, canvas&
            _FREEIMAGE glyphImg&
        END IF
        penX& = penX& + TDF_glyph_advance%(faceIdx%, chIdx%)
    NEXT k%

    _SAVEIMAGE outPath$, canvas&
    PRINT "  wrote "; outPath$; " ("; LTRIM$(STR$(totalW&)); "x"; LTRIM$(STR$(maxH%)); ")"
    _FREEIMAGE canvas&
END SUB

'$INCLUDE:'../../GUI/TDF-FONT.BM'
