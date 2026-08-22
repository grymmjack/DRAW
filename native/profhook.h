#ifndef GJ_PROFHOOK_H
#define GJ_PROFHOOK_H
// Profiling aid ONLY: gprof (-pg) writes gmon.out via an atexit handler that runs on a
// clean exit(), NOT on a signal. The QA harness terminates DRAW with SIGTERM (then -9),
// so without this the profile is never flushed. Installing a SIGTERM handler that calls
// exit(0) lets gprof flush before the harness's kill -9. Gated behind the DRAW_GMON env
// var so it only affects instrumented profiling runs — never normal use.
#include <signal.h>
#include <stdlib.h>
static void gj_term_to_exit(int sig) { (void)sig; exit(0); }
extern "C" void gj_install_exit_on_sigterm(void) { signal(SIGTERM, gj_term_to_exit); }
#endif
