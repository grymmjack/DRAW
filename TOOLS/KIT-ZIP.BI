$INCLUDEONCE
'==============================================================================
' KIT-ZIP.BI - Minimal PKZIP archive writer/reader for DRAW KITS.
'
' A hand-rolled ZIP container over QB64-PE's built-in _DEFLATE$/_INFLATE$
' (QB64-PE has raw DEFLATE but no zip container). Produces standard .zip files
' openable by OS zip tools, and reads .zip files produced by them.
'
' Self-contained: no DRAW globals. One archive is written at a time via the
' shared writer state below (export builds one kit at a time).
'==============================================================================

' CRC-32 (IEEE 802.3) lookup table, built lazily on first use.
DIM SHARED ZIP_CRC_TABLE(0 TO 255) AS _UNSIGNED LONG
DIM SHARED ZIP_CRC_READY% ' TRUE once the table is built

' Writer state (one archive at a time).
DIM SHARED ZIP_CD$          ' accumulated central-directory records
DIM SHARED ZIP_ENTRY_COUNT% ' number of entries added so far
DIM SHARED ZIP_OFFSET&      ' current byte offset in the output file (0-based)

' A single entry read back out of an archive (see ZIP_read_open%).
TYPE ZIP_DIR_ENTRY
    name         AS STRING
    method       AS INTEGER  ' 0 = STORE, 8 = DEFLATE
    crc32        AS _UNSIGNED LONG
    compSize     AS _UNSIGNED LONG
    uncompSize   AS _UNSIGNED LONG
    localOffset  AS _UNSIGNED LONG
END TYPE
