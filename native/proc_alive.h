#ifndef GJ_PROC_ALIVE_H
#define GJ_PROC_ALIVE_H
// -----------------------------------------------------------------------------
// Process liveness for the multi-instance registry (CORE/INSTANCE). Rick 2026-11-18:
// "it is still showing the [2]" / "can we clean these up somehow": a slot whose DRAW
// is gone stayed "live" until its heartbeat aged past INSTANCE_STALE_SECS (60 s), so a
// relaunch inside that minute opened as [2]. The registry file now carries the owner's
// pid, and a slot whose process no longer exists is free at once.
//   gj_getpid()        this process's id
//   gj_pid_alive(pid)  -1 = a process with that id exists, 0 = none
// [Linux / macOS] kill(pid, 0): 0 or EPERM = exists. [Windows] OpenProcess +
// GetExitCodeProcess (STILL_ACTIVE); access denied = exists.
// A reused pid reads as alive - the heartbeat age still catches that one.
// -----------------------------------------------------------------------------
#include <cstdint>
#if defined(_WIN32)
#include <windows.h>
extern "C" int32_t gj_getpid(void) { return (int32_t)GetCurrentProcessId(); }
extern "C" int32_t gj_pid_alive(int32_t pid) {
    if (pid <= 0) return 0;
    HANDLE h = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, (DWORD)pid);
    if (!h) return GetLastError() == ERROR_ACCESS_DENIED ? -1 : 0;
    DWORD code = 0;
    BOOL ok = GetExitCodeProcess(h, &code);
    CloseHandle(h);
    return (ok && code != STILL_ACTIVE) ? 0 : -1;
}
#else
#include <unistd.h>
#include <signal.h>
#include <errno.h>
extern "C" int32_t gj_getpid(void) { return (int32_t)getpid(); }
extern "C" int32_t gj_pid_alive(int32_t pid) {
    if (pid <= 0) return 0;
    if (kill((pid_t)pid, 0) == 0) return -1;
    return errno == EPERM ? -1 : 0;
}
#endif
#endif
