'$INCLUDEONCE

' ============================================================================
' FD-PLATFORM.BI — C interop declarations for filedialog_platform.h
'
' Compiled inline by QB64-PE. Cross-platform directory enumeration, file
' metadata, and system path discovery.
'
' (c) 2026 grymmjack — MIT License
' ============================================================================

DECLARE LIBRARY "filedialog_platform"
    ' Directory enumeration
    FUNCTION fd_open_dir% (path AS STRING)
    FUNCTION fd_read_entry% (BYVAL slot AS INTEGER, buf AS STRING, BYVAL buf_len AS INTEGER)
    SUB fd_close_dir (BYVAL slot AS INTEGER)

    ' File metadata
    FUNCTION fd_is_directory% (path AS STRING)
    FUNCTION fd_file_size&& (path AS STRING)
    FUNCTION fd_file_mtime&& (path AS STRING)
    FUNCTION fd_is_hidden% (path AS STRING)

    ' System paths
    FUNCTION fd_home_dir% (buf AS STRING, BYVAL buf_len AS INTEGER)
    FUNCTION fd_path_separator% ()
    FUNCTION fd_get_xdg_dir% (BYVAL dirType AS INTEGER, buf AS STRING, BYVAL buf_len AS INTEGER)

    ' Date formatting
    FUNCTION fd_format_mtime% (BYVAL epoch AS _INTEGER64, buf AS STRING, BYVAL buf_len AS INTEGER)

    ' Drive / volume enumeration
    FUNCTION fd_get_drive_count% ()
    FUNCTION fd_get_drive% (BYVAL index AS INTEGER, buf AS STRING, BYVAL buf_len AS INTEGER)
END DECLARE
