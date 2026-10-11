#ifndef GJ_DISPLAY_PROBE_H
#define GJ_DISPLAY_PROBE_H
// -----------------------------------------------------------------------------
// gj_x11_display_reachable() - [Linux X11] can we actually connect to $DISPLAY?
//   1 = yes, 0 = no (a DISPLAY that names a dead / missing X server),
//  -1 = can't tell (libX11 not loadable, or not an X11 build) -> treat as OK.
// DRAW's headless guard (OUTPUT/SCREEN.BM SCREEN_init) calls it before the
// window exists: QB64-PE's GUI thread pops a blocking "Failed to initialize
// window" alert and exit()s when GLFW can't open the window, which BASIC
// cannot trap. libX11 is loaded at run time (dlopen), so the build gains no
// link dependency.
// -----------------------------------------------------------------------------
#if defined(__linux__)
#include <dlfcn.h>
extern "C" int gj_x11_display_reachable(void) {
    void *lib = dlopen("libX11.so.6", RTLD_LAZY | RTLD_LOCAL);
    if (!lib) return -1;
    typedef void *(*open_fn)(const char *);
    typedef int (*close_fn)(void *);
    open_fn xopen = (open_fn)dlsym(lib, "XOpenDisplay");
    close_fn xclose = (close_fn)dlsym(lib, "XCloseDisplay");
    int r = -1;
    if (xopen && xclose) {
        void *d = xopen(nullptr);
        if (d) { xclose(d); r = 1; } else r = 0;
    }
    dlclose(lib);
    return r;
}
#else
extern "C" int gj_x11_display_reachable(void) { return -1; }
#endif
#endif
