// glut_reshape.h - Expose glutReshapeWindow for QB64-PE DECLARE LIBRARY
// FreeGLUT is statically linked into QB64-PE, so we just need the declaration.
// glutReshapeWindow sets the window size while leaving the SCREEN buffer size unchanged.
// Combined with $RESIZE:STRETCH, this gives GPU-accelerated scaling for free.
void glutReshapeWindow(int width, int height);
