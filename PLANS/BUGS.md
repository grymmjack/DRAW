# BUGS


## AUTO-SIZE WINDOWS too SMALL

A friend of mine tried DRAW on a 1920x1080 screen, and it made the GUI scale to
4x, which cut off the menu bar, and other sections of the GUI.

### GOAL

Modify DRAW auto-size / auto-detection for GUI scale to be better, and favor
showing MORE of the GUI, decreasing canvas by known sizes if necessary to fit.

#### IF 1920x1080 ...
- 320x200 default canvas
- Size up to 640x200 if possible
- Size up to 800x600 if possible etc.
- DISPLAY_SCALE=3
- TOOLBAR_SCALE=2
etc.


### MEASURE:

- Minimum width required at scale ratios
- Minimum height required at scale ratios
- Find largest min width and min height vs. screen-size, and use that as default.
- The largest size should fit comfortably IN the screen, not go outside it.

### IDEA: We can come up with configurations 
that are optimized for the [TOP-SCREEN-RESOLUTIONS_WORLDWIDE.md](TOP-SCREEN-RESOLUTIONS_WORLDWIDE)



## ERASE with CUSTOM BRUSH not working

- When erasing with custom brush, it should erase in the brush opaque-shape.
