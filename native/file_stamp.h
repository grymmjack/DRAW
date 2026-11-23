#ifndef GJ_FILE_STAMP_H
#define GJ_FILE_STAMP_H
// -----------------------------------------------------------------------------
// gj_file_stamp(path) - a number that changes whenever the file is rewritten:
// its modification time (ns where the OS has it) mixed with its size. 0 = no such file.
// QB64-PE has no file-time keyword; Theme Edit mode (CFG/THEME-EDIT.BM) polls
// this to notice an image saved from another DRAW window or a THEME.CFG saved
// from a text editor. Pass the path NUL-terminated (p$ + CHR$(0)).
// -----------------------------------------------------------------------------
#include <sys/types.h>
#include <sys/stat.h>
#ifdef _WIN32
extern "C" long long gj_file_stamp(const char *p) {
    struct _stat64 st;
    if (!p || _stat64(p, &st) != 0) return 0;
    return (long long)st.st_mtime * 1000003LL + (long long)st.st_size;
}
#else
extern "C" long long gj_file_stamp(const char *p) {
    struct stat st;
    if (!p || stat(p, &st) != 0) return 0;
#if defined(__APPLE__)
    long long ns = (long long)st.st_mtimespec.tv_sec * 1000000000LL + st.st_mtimespec.tv_nsec;
#elif defined(__linux__)
    long long ns = (long long)st.st_mtim.tv_sec * 1000000000LL + st.st_mtim.tv_nsec;
#else
    long long ns = (long long)st.st_mtime * 1000000000LL;
#endif
    return ns + (long long)st.st_size * 7LL; // two saves in one second still differ
}
#endif
#endif
