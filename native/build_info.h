#ifndef DRAW_BUILD_INFO_H
#define DRAW_BUILD_INFO_H
// -----------------------------------------------------------------------------
// The build's git info for interim (non-release) builds: "sha branch", shown
// after the version as "2.7.0 (d0d27fa8 animation)" in the title bar, About box
// and --version. DEV/build-info.sh writes native/build_info_gen.h before each
// build (make, CI); a release build (HEAD on a v* tag) or a plain qb64pe compile
// without the generated file gets "" and shows the bare version.
// -----------------------------------------------------------------------------
#if defined(__has_include)
#  if __has_include("build_info_gen.h")
#    include "build_info_gen.h"
#  endif
#endif
#ifndef DRAW_BUILD_INFO
#define DRAW_BUILD_INFO ""
#endif
static const char *draw_build_info(void) { return DRAW_BUILD_INFO; }
#endif
