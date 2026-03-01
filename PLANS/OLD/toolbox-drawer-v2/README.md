I am rearranging the toolbox to be 4 buttons wide, and 7 down.

adding new tools as documented.

1 - Crop - crop.png - uses same function already built, just has a button to engage it now too.
2 - Marquee Rect - marquee-rect.png - this is the existing marquee (it may be called select - or use select.png - change the png)
3 - Marquee Freehand - marquee-freehand.png - this allows user to draw freehand selection like painting a marquee
4 - Marquee Poly - marquee-poly.png - this allows user to draw like poly line for building a selection
5 - Marquee Ellipse - marquee-ellipse.png - this allows user to select elliptical selections
6 - Marquee Wand - marquee-wand.png - this is the same as magic wand/select color just has button now.

All selection tools should work just like rect / select already does - with ability to add, subtract, and drag/adjust/etc. with the bounding box, as normal.

Also I am rearranging and modifying the drawer:

4 wide, and 3 down. (except the brush width slider that stays same)

1 - Color Operations - color-ops.png - This will allow the user to do things with colors - TBD just add button
2 - Palette Operations - palette-ops.png - This will allow the user to do things with palette - TBD just add button
3 - Pattern Mode - pattern-mode-off/on.png - this already exists, just documenting where it is
4 - Gradient Mode - gradient-mode-off/on.png - this is new, and TBD just add button and allow it to be selected/on - if it's on for now just use color mode though internally
5 - Color Mode - color-mode-off/on.png - this already exists, just documenting where it is now

Everything else stays the same.

Adjust the width of the area where the toolbox and drawer are auto-hidden/reshown on mouse up, and the cursor hitbox for null pointer, etc. as it is now needs to also be adjusted.