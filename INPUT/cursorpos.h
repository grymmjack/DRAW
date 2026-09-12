// [macOS] Helpers for the drag-collapse fallback (see MOUSE_drain_update_state).
// macOS withholds mouseDragged from a freshly-launched window until the app
// finishes activating, freezing _MOUSEX mid-drag. CGEventGetLocation still tracks
// the true cursor, and DRAW_backing_scale gives the physical/points ratio so the
// global coords can be mapped onto DRAW's viewport at the right scale.
#include <ApplicationServices/ApplicationServices.h>
#include <stdint.h>

void DRAW_global_cursor(uintptr_t px, uintptr_t py){
    CGEventRef e = CGEventCreate(0);
    CGPoint p = CGEventGetLocation(e);
    if (e) CFRelease(e);
    *(double*)px = p.x;
    *(double*)py = p.y;
}

// Backing scale of the main display (2.0 on Retina, 1.0 otherwise).
double DRAW_backing_scale(void){
    CGDirectDisplayID d = CGMainDisplayID();
    CGDisplayModeRef m = CGDisplayCopyDisplayMode(d);
    if (!m) return 1.0;
    double px = (double)CGDisplayModeGetPixelWidth(m);
    double pt = (double)CGDisplayModeGetWidth(m);
    CGDisplayModeRelease(m);
    return (pt > 0.0) ? (px / pt) : 1.0;
}
