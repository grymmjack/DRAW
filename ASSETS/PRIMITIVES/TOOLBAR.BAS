DIM CANVAS AS LONG : CANVAS& = _NEWIMAGE (320, 200, 32) : SCREEN CANVAS&
_SCREENMOVE 1147, 353
'ON KEY(1) get_screen_pos : KEY(1) ON

CONST SCALE%   = 1                      ' pixel scale
CONST BTN_H%   = 10                     ' height
CONST BTN_W%   = 10                     ' width
CONST BTN_P%   = 2                      ' padding between buttons
CONST BTN_FG~& = _RGB32(0, 0, 0)        ' foreground
CONST BTN_BG~& = _RGB32(120, 120, 120)  ' background
CONST BTN_HL~& = _RGB32(170, 170, 170)  ' highlight
CONST BTN_LL~& = _RGB32(85, 85, 85)     ' lowlight
CONST BTN_BL~& = _RGB32(255, 255, 255)  ' bright light
CONST BTN_ML~& = _RGB32(200, 200, 200)  ' mid light
CONST BTN_DS~& = _RGB32(48, 48, 48)     ' dark shade
CONST BTN_MS~& = _RGB32(64, 64, 64)     ' mid shade


DIM b_blank AS LONG     : btn_blank b_blank&
DIM b_select AS LONG    : b_select = _COPYIMAGE(blank&) : btn_select b_select
DIM b_move AS LONG      : b_move = _COPYIMAGE(blank&) : btn_move b_move
DIM b_polyline AS LONG  : b_polyline = _COPYIMAGE(blank&) : btn_polyline b_polyline
DIM b_text AS LONG      : b_text = _COPYIMAGE(blank&) : btn_text b_text
DIM b_save AS LONG      : b_save = _COPYIMAGE(blank&) : btn_save b_save
DIM b_open AS LONG      : b_open = _COPYIMAGE(blank&) : btn_open b_open

btn_render b_select, 0, 0, SCALE%
btn_render b_move, 0, (BTN_W% + BTN_P%) * SCALE%, SCALE%
btn_render b_polyline, 0, (BTN_W% + BTN_P%) * SCALE% * 2, SCALE%
btn_render b_text, 0, (BTN_W% + BTN_P%) * SCALE% * 3, SCALE%
btn_render b_save, 0, (BTN_W% + BTN_P%) * SCALE% * 4, SCALE%
btn_render b_open, 0, (BTN_W% + BTN_P%) * SCALE% * 5, SCALE%

DO:
LOOP UNTIL _KEYHIT=27
SYSTEM


SUB btn_open (img&)
    DIM old_dest AS LONG : old_dest& = _DEST
    DIM AS INTEGER sx, ex, sy, ey, mx, my
    sx% = 2 : ex% = BTN_W% - 2
    sy% = 2 : ey% = BTN_H% - 4
    mx% = BTN_W% \ 2 : my% = BTN_H% \ 2
    _DEST img&
    LINE (sx%, sy%)-(ex%, ey%), BTN_DS~&, BF    ' folder rect solid
    LINE (mx%, sy%)-(ex%, sy%), BTN_BG~&        ' folder top line tab
    LINE (sx%+1, my%)-(ex%, ey%), BTN_LL~&, BF  ' folder open flap
    PSET (sx%+1, my%), BTN_DS~&                 ' folder flap bit
    PSET (ex%+1, my%), BTN_DS~&                 ' folder right flap bit
    PSET (ex%, ey%), BTN_DS~&                   ' folder bot flap bit
    LINE (sx%, ey%+1)-(ex%-1, ey%+1), BTN_FG~&  ' dark shadow under
    LINE (sx%, ey%+2)-(ex%, ey%+2), BTN_LL~&    ' flap shadow under
    _DEST old_dest&
END SUB


SUB btn_save (img&)
    DIM old_dest AS LONG : old_dest& = _DEST
    DIM AS INTEGER sx, ex, sy, ey, mx, my
    sx% = 2 : ex% = BTN_W% - 2
    sy% = 2 : ey% = BTN_H% - 2
    mx% = BTN_W% \ 2 : my% = BTN_H% \ 2
    _DEST img&
    LINE (sx%, sy%)-(ex%, ey%), BTN_FG~&, BF            ' disk solid
    LINE (sx%+1, sy%)-(ex%-1, sy%), BTN_BL~&            ' disk label top white line
    LINE (sx%+1, sy%+1)-(ex%-1, my-1%), BTN_ML~&, BF    ' disk label write area
    PSET (mx%, my%+1), BTN_LL~&                         ' disk cylinder hole
    LINE (mx%-1, ey%)-(mx%+1, ey%), BTN_HL~&            ' disk slider
    PSET (ex%, sy%+1), BTN_LL~&                         ' disk write protect
    _DEST old_dest&
END SUB


SUB btn_text (img&)
    DIM old_dest AS LONG : old_dest& = _DEST
    DIM AS INTEGER sx, ex, sy, ey, mx, my
    sx% = 3 : ex% = BTN_W% - 3
    sy% = 3 : ey% = BTN_H% - 3
    mx% = BTN_W% \ 2 : my% = BTN_H% \ 2
    _DEST img&
    LINE (sx%, sy%)-(ex%, sy%), BTN_FG~&        ' top line of t
    LINE (sx%, sy%)-(sx%, sy%+1), BTN_FG~&      ' left side of top line serif
    LINE (ex%, sy%)-(ex%, sy%+1), BTN_FG~&      ' right side of top line serif
    LINE (mx%, sy%)-(mx%, ey%), BTN_FG~&        ' middle bar of t
    LINE (mx%-1, ey%)-(mx%+1, ey%), BTN_FG~&    ' bottom line of t
    _DEST old_dest&
END SUB


SUB btn_polyline (img&)
    DIM old_dest AS LONG : old_dest& = _DEST
    DIM AS INTEGER sx, ex, sy, ey, mx, my
    sx% = 2 : ex% = BTN_W% - 2
    sy% = 2 : ey% = BTN_H% - 2
    mx% = BTN_W% \ 2 : my% = BTN_H% \ 2
    _DEST img&
    LINE (sx%, sy%)-(ex%, my%), BTN_FG~&, B ' half rectangle
    LINE (mx%, my%)-(sx%-1, my%), BTN_BG~&  ' erase bottom left line
    LINE (sx%, my%)-(mx%, ey%), BTN_FG~&    ' diagonal down line
    _DEST old_dest&
END SUB

SUB btn_move (img&)
    DIM old_dest AS LONG : old_dest& = _DEST
    DIM AS INTEGER sx, ex, sy, ey, mx, my
    sx% = 1 : ex% = BTN_W% - 1
    sy% = 1 : ey% = BTN_H% - 1
    mx% = BTN_W% \ 2 : my% = BTN_H% \ 2
    _DEST img&
    LINE (mx%, sy%)-(mx%, ey%), BTN_FG~&    ' vertical line of cross
    LINE (sx%, my%)-(ex%, my%), BTN_FG~&    ' horizontal line of cross
    LINE (sx%+1, sy%+1)-(ex%-1, ey%-1), BTN_FG~&, B, &B0011101110111000
    PSET (sx%+1, sy%+1), BTN_BG~&           ' erase top left corner
    PSET (ex%-1, sy%+1), BTN_BG~&           ' erase top right corner
    PSET (sx%+1, ey%-1), BTN_BG~&           ' erase bottom left corner
    PSET (ex%-1, ey%-1), BTN_BG~&           ' erase bottom right corner
    _DEST old_dest&
END SUB


SUB btn_select (img&)
    DIM old_dest AS LONG : old_dest& = _DEST
    _DEST img&
    LINE (2, 2)-(BTN_W% - 2, BTN_H% - 2), BTN_FG~&, B, &B1010101010101010
    _DEST old_dest&
END SUB


SUB btn_render (img&, x%, y%, scale%)
    DIM old_dest AS LONG : old_dest& = _DEST
    IF scale% > 1 THEN
        DIM img_s AS LONG
        img_s& = _NEWIMAGE(_WIDTH(img&) * scale%, _HEIGHT(img&) * scale%, 32)
        _DEST img_s& : _SOURCE img& : _PUTIMAGE
        img& = img_s&
    END IF
    _DEST CANVAS& : _SOURCE img& : _PUTIMAGE (x%, y%)
    _DEST old_dest&
END SUB


SUB btn_blank (img AS LONG)
    DIM old_dest AS LONG : old_dest& = _DEST
    _DEST img&
    LINE (0, 0)-(BTN_W%, BTN_H%), BTN_BG~&, BF      ' background rectangle
    LINE (0, 0)-(BTN_W%, 0), BTN_HL~&               ' top highlight line
    LINE (BTN_W%, 0)-(BTN_W%, BTN_H%), BTN_HL~&     ' right highlight line
    LINE (0, BTN_H%)-(BTN_W%, BTN_H%), BTN_LL~&     ' bottom lowlight line
    LINE (0, 0)-(0, BTN_H%), BTN_LL~&               ' left lowlight line
    _DEST old_dest&
END SUB
