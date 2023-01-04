DIM CANVAS AS LONG : CANVAS& = _NEWIMAGE (320, 200, 32) : SCREEN CANVAS&
_SCREENMOVE 1147, 353
'ON KEY(1) get_screen_pos : KEY(1) ON

CONST BTN_H%   = 10
CONST BTN_W%   = 10
CONST BTN_FG~& = _RGB32(0, 0, 0)
CONST BTN_BG~& = _RGB32(120, 120, 120)
CONST BTN_HL~& = _RGB32(170, 170, 170)
CONST BTN_LL~& = _RGB32(85, 85, 85)

DIM b_blank AS LONG     : btn_blank b_blank&
DIM b_select AS LONG    : b_select = _COPYIMAGE(blank&) : btn_select b_select
DIM b_move AS LONG      : b_move = _COPYIMAGE(blank&) : btn_move b_move

btn_render b_select, 0, 0, 1
btn_render b_move, 0, 12, 1

DO:
LOOP UNTIL _KEYHIT=27

SUB btn_move (img&)
    DIM old_dest AS LONG : old_dest& = _DEST
    DIM AS INTEGER sx, ex, sy, ey, mx, my
    sx% = 1 : ex% = BTN_W% - 1
    sy% = 1 : ey% = BTN_H% - 1
    mx% = BTN_W% \ 2 : my% = BTN_H% \ 2
    _DEST img&    
    LINE (mx%, sy%)-(mx%, ey%), BTN_FG~&            ' vertical line of cross
    LINE (sx%, my%)-(ex%, my%), BTN_FG~&            ' horizontal line of cross
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
