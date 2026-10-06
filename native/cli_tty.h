#ifndef GJ_CLI_TTY_H
#define GJ_CLI_TTY_H
// -----------------------------------------------------------------------------
// Console helpers for DRAW's command-line output (CORE/CLI.BM):
//   gj_stdout_isatty() - 1 when stdout is a terminal (so --help colors switch off
//                        when piped / captured: `vim $(DRAW --cfg)`, `| grep`)
//   gj_console_prepare() - Windows: enable ANSI escape processing + UTF-8 output
//                        on the console; no-op elsewhere. Returns 1 when ANSI is OK.
// -----------------------------------------------------------------------------
#ifdef _WIN32
#include <io.h>
#include <stdio.h>
#include <windows.h>
extern "C" int gj_stdout_isatty(void) { return _isatty(_fileno(stdout)) ? 1 : 0; }
extern "C" int gj_console_prepare(void) {
    HANDLE h = GetStdHandle(STD_OUTPUT_HANDLE);
    DWORD m = 0;
    SetConsoleOutputCP(65001); // UTF-8 (CP437 logo glyphs are converted to UTF-8)
    if (h == INVALID_HANDLE_VALUE || !GetConsoleMode(h, &m)) return 0;
    return SetConsoleMode(h, m | 0x0004 /* ENABLE_VIRTUAL_TERMINAL_PROCESSING */) ? 1 : 0;
}
#else
#include <unistd.h>
extern "C" int gj_stdout_isatty(void) { return isatty(1) ? 1 : 0; }
extern "C" int gj_console_prepare(void) { return 1; }
#endif
#endif
