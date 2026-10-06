#include <stdio.h>
#include <X11/Xlib.h>
#include <X11/extensions/Xfixes.h>
int main(void){
  Display *d = XOpenDisplay(NULL); if(!d){puts("no display");return 1;}
  XFixesCursorImage *c = XFixesGetCursorImage(d);
  if(!c){puts("no cursor");return 1;}
  int vis=0; for(int i=0;i<c->width*c->height;i++) if((c->pixels[i]>>24)&0xff) vis++;
  printf("cursor %dx%d hot=%d,%d visible_px=%d name=%s\n", c->width, c->height, c->xhot, c->yhot, vis, c->name?c->name:"");
  XFree(c); XCloseDisplay(d); return 0;
}
