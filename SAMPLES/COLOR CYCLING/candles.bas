' candles.bas - palette color cycling
' Exported by DRAW 2.5.1 (https://github.com/grymmjack/DRAW) on 10-06-2026
' 320x200, 71 colors, 4 cycle range(s):
'   1: 25-36 FWD 12.0/s
'   2: 37-48 FWD 18.0/s
'   3: 49-60 FWD 24.0/s
'   4: 61-70 PING 9.0/s
' Keys: SPACE pause/resume, + / - speed, R restart, ESC quit
'
' How it works: the art is drawn from a 32-bit image, then an 8-bit overlay
' holding only the cycling pixels is drawn on top (overlay index 0 is clear).
' Each step the overlay's palette entries are rotated with _PALETTECOLOR -
' the pixels never change, only the colors they point at. Speeds use the
' DeluxePaint CRNG unit: 16384 = 60 steps per second.
' Compile: qb64pe -x candles.bas

OPTION _EXPLICIT
OPTION _EXPLICITARRAY
CONST CRNG_UNIT = 16384

' --- unpack the DATA blob (deflate + base64) ---
DIM blob AS STRING, b64 AS STRING, chunk AS STRING
DO
    READ chunk
    IF chunk = "*" THEN EXIT DO
    b64 = b64 + chunk
LOOP
blob = _INFLATE$(_BASE64DECODE$(b64))
IF LEFT$(blob, 4) <> "DCYC" THEN PRINT "Bad cycling data": END

DIM p AS LONG, i AS INTEGER, j AS INTEGER, rate AS LONG
DIM imgW AS INTEGER, imgH AS INTEGER, nCol AS INTEGER, nRng AS INTEGER
p = 7 ' after magic + version
imgW = CVI(MID$(blob, p, 2)): p = p + 2
imgH = CVI(MID$(blob, p, 2)): p = p + 2
nCol = CVI(MID$(blob, p, 2)): p = p + 2
DIM pal(0 TO 255) AS _UNSIGNED LONG
FOR i = 0 TO nCol - 1
    pal(i) = _CV(_UNSIGNED LONG, MID$(blob, p, 4)): p = p + 4
NEXT
nRng = CVI(MID$(blob, p, 2)): p = p + 2
DIM rLo(1 TO 16) AS INTEGER, rHi(1 TO 16) AS INTEGER, rOvl(1 TO 16) AS INTEGER
DIM rSps(1 TO 16) AS SINGLE, rMode(1 TO 16) AS INTEGER, rOn(1 TO 16) AS INTEGER
DIM rPhase(1 TO 16) AS DOUBLE, rShift(1 TO 16) AS INTEGER
FOR i = 1 TO nRng
    rLo(i) = CVI(MID$(blob, p, 2)): p = p + 2
    rHi(i) = CVI(MID$(blob, p, 2)): p = p + 2
    rOvl(i) = CVI(MID$(blob, p, 2)): p = p + 2
    rate = CVL(MID$(blob, p, 4)): p = p + 4
    rSps(i) = rate * 60 / CRNG_UNIT ' steps per second
    rMode(i) = CVI(MID$(blob, p, 2)): p = p + 2 ' 0 forward, 1 reverse, 2 ping-pong
    rOn(i) = CVI(MID$(blob, p, 2)): p = p + 2 ' 0 = paused
    rPhase(i) = CVL(MID$(blob, p, 4)): p = p + 4
    rShift(i) = -1
NEXT

' --- the art (32-bit) and the cycling overlay (8-bit, index 0 clear) ---
DIM art AS LONG, ovl AS LONG, frame AS LONG, m AS _MEM, px AS STRING
art = _NEWIMAGE(imgW, imgH, 32)
px = MID$(blob, p, imgW * imgH * 4): p = p + imgW * imgH * 4
m = _MEMIMAGE(art): _MEMPUT m, m.OFFSET, px: _MEMFREE m
ovl = _NEWIMAGE(imgW, imgH, 256)
px = MID$(blob, p, imgW * imgH)
m = _MEMIMAGE(ovl): _MEMPUT m, m.OFFSET, px: _MEMFREE m
_CLEARCOLOR 0, ovl
frame = _NEWIMAGE(imgW, imgH, 32)

' --- window: the largest whole-number zoom that fits the desktop ---
DIM zoom AS INTEGER: zoom = 1
DO WHILE imgW * (zoom + 1) <= _DESKTOPWIDTH * 0.9 AND imgH * (zoom + 1) <= _DESKTOPHEIGHT * 0.85
    zoom = zoom + 1
LOOP
SCREEN _NEWIMAGE(imgW * zoom, imgH * zoom, 32)
_TITLE "candles.bas - color cycling (SPACE pause, +/- speed, ESC quit)"

' --- main loop: rotate each range on its own clock ---
DIM lastT AS DOUBLE, nowT AS DOUBLE, dt AS DOUBLE, speed AS SINGLE
DIM paused AS INTEGER, changed AS INTEGER, n AS INTEGER, s AS INTEGER, k AS LONG, kh AS LONG
speed = 1: lastT = TIMER(.001): changed = -1
DO
    nowT = TIMER(.001): dt = nowT - lastT: lastT = nowT
    IF dt < 0 OR dt > 1 THEN dt = 0 ' midnight wrap / stall
    FOR i = 1 TO nRng
        n = rHi(i) - rLo(i) + 1
        IF rOn(i) <> 0 AND paused = 0 THEN rPhase(i) = rPhase(i) + dt * rSps(i) * speed
        k = INT(rPhase(i))
        SELECT CASE rMode(i)
            CASE 1 ' reverse
                s = (n - (k MOD n)) MOD n
            CASE 2 ' ping-pong: 0, 1 .. n-1 .. 1, 0
                s = k MOD (2 * (n - 1))
                IF s > n - 1 THEN s = 2 * (n - 1) - s
            CASE ELSE ' forward
                s = k MOD n
        END SELECT
        IF s <> rShift(i) THEN
            rShift(i) = s: changed = -1
            FOR j = 0 TO n - 1 ' overlay color j shows palette color (j - s) of the range
                _PALETTECOLOR rOvl(i) + j, pal(rLo(i) + ((j - s) MOD n + n) MOD n), ovl
            NEXT
        END IF
    NEXT
    IF changed THEN
        _DEST frame: CLS , _RGB32(0, 0, 0)
        _PUTIMAGE , art, frame
        _PUTIMAGE , ovl, frame
        _DEST 0
        _PUTIMAGE , frame, 0
        _DISPLAY
        changed = 0
    END IF
    kh = _KEYHIT
    SELECT CASE kh
        CASE 27: SYSTEM
        CASE 32: paused = NOT paused
        CASE 43, 61: IF speed < 8 THEN speed = speed * 1.25
        CASE 45, 95: IF speed > 0.1 THEN speed = speed / 1.25
        CASE 82, 114
            FOR i = 1 TO nRng: rPhase(i) = 0: NEXT
    END SELECT
    _LIMIT 120
LOOP

' --- palette, ranges, art and overlay: deflate + base64 ---
DATA "eJzt3T2MXbeVB/CRNDOyJHskjSzrc0aS7Z3xer2Ltd1sgPVigWzklGkDpEwRZRGndbNV2rRRgABBkjpFmrRx4G5jYBsXcbo0QRoD"
DATA "gbukCHyXfPM4j/c+8l7y8pzDc3gPAVrjmfvmXf5J/oa87+u/vvrNr17Y+c8L/7vz/s7u3gvd3v7V7vKVg+7KtVvdtYM73Ys3HnQH"
DATA "tx51N26/3h3efaPbf/Fud+2VN7sbT97rbr/1je7+V77dPX76Yff0Wx92z37w0+6Hv/y4+9Wnf+4+/uNfuk8//2v3p7913cHhva77"
DATA "9fPu87933c7x827v6Sfd1Q+6znzZvfNR1z37rOt+/kXXfdf8+675/0fm+9fMz/fNcRfMQbvm3yvm/4/M9982P/+OOe4X5vhnvze3"
DATA "/435PT/quqvf67q9r33S7ZiD9t43v//75vs/Nj//rTnuD133M3v8Z1+a+/vS3O+X5v6/NOfxu+6WadPLT/6tu/Pm17v7736zO/qP"
DATA "/+4ef/1/umPz7wPz/3fN92+bn+/u3Nt5fefCzv+9uGOKaYcp/7Dzrzsv7bx7a/Odt3f+3Rz3k3ub77y389Qc95MrOzsX19+xyUJV"
DATA "20MY1fZ6jWpHGsdqRz9WtbOq9YqZH2Q/Q4xhrDnpV0hDxqr9SwBdOdun5tHZJ8kv7g5yMpDCP8kOqn38zcO0T5JXkhzk4h+1gVQO"
DATA "cvFPqnscfaN0T+3DNxDKQYkGSnFwafZxNY7SPkkuteAgBwNr+EflYA3/pNnH1TdK+yQ51JqDSzcQ20FK/9Q9ef5JsqdFA6HGBMSc"
DATA "aNVBCv+k2MfRsyXZZ5+lBV1rtIObgdDzpDUDcx1szT6unmHZxsU9DO84ediygTUtrG2g2ifXt9r21TCvpoVLMLCWhbUMbME+9Y7O"
DATA "Pk7m1bCQi4HY/tWwsIaBVPZh9It6R2ffHIfsqzWhKicHl2igZAfn+qf2yTAP075a3kF6yNVAaf5ROki1FpRmn5rHyz5K80osVAPl"
DATA "OUhhIKZ/Eu3j6hulfVLc4+BgbQNr+ifVwSn/lmgfV9so7YM2z75jG1SFtpCTgaVjl4OB2A5iGbh0+7i6JtU+SPNKLVySgUtwEMNA"
DATA "zvapezT+lbpHYV6JhRQGQvQn9Bhv0UAMBzn6p+7VtY+7e5AOcjEQ8+99aw6qfWpfLftyXLKf3FBaIR1csoE1LeRsYOv2cXUs1TIu"
DATA "9lGaV2qhVAMp/KtlIUcDW7ZPim/UFcM+TPPmWljLwNIxQ20gtYWcDFT72rau1D6O7kE5yNXAWv5ROsjFQLWvffMw7MvxyX6C69wK"
DATA "5SC1gaXjqraBFA5yMLC2fxLd4+obF/tKvCv1sBUDOfgn0UEq/5ZmH1fXKO2r6R6Ug5QGtuIfhYO1DFT72nVvzD9I+yjdy3EQwsDS"
DATA "7FszENPBGgbW8A+yL9Q9/vYdmePmVukGQo9LNRDWQMlrP3Uv376Yf7n2YZo310IIA7ntg7l7KN1AifZhjSWujkH6h21frmlvf9SB"
DATA "OohlIFf/uHjI2UEu/nG1j6tfFPbF/KOwb65/kAZK3QdztFCigUu2j6tdlP5B2Jfi1X3ze0P16HkX/1mBg6UGtuBfLQslGSjFPmj/"
DATA "uLpV276Yf3Pti9lm62rtZ/yz/44dB2lgrX1wbf+oLeRooGT/pNsXu65eUjH8g7JvzDN/7XflgzMDk45HNHAJa0BqByUYuCT7pHuX"
DATA "6iHFvrfEvbn+TTlIsQ9uyT8KB7kbiOnf0uyrYV5KhV77zbXvjrlfV519u08/OTfQ/zm2gUvfA0t2ENJAzms/CfZxNS/Xv9J9b6p7"
DATA "rjr7Lhw/PzcwdFyugSX74KX7h+3gkvxr3T4oh+ZWTmu/HPdcteb5/tk6dnypgboHVgNDBra89qvtHqR3cz2c61/pvnfMMueftW/v"
DATA "axsDp24DvQ+u9TiIJBNbN7DVtV8t+yjNS7EwxT/otd+YYS+bc/Ltc9UZaH8OYSDXPbBUH5dkYOk5tWafFPdC83bO2i/Vv5x9r3XN"
DATA "Vd++q9/regb6x5XsgyH3wLX942LiUgyUvPajdC/Xo9hzb+fUuSbO9a9k7eebZqtvn6vue8NjIdeALflXy8IlGFjLvxbtgzQPwkLI"
DATA "a3+p+96Qf8694x/1DUzxL2Qg9TVATv7VsJCbgUu3D9K/UvcozJtrIebeN8U+3z1b3/nN5mv3M6g1IOY1QI72UVvYooFS/cO2j7t7"
DATA "qQ5y8M+3z1XfQPVPjoMtGaj2zbMvx6XY67FyaomDlP4NHbN1aN+z328bGLqd+sfXQU4GLs2/mvZRmldqIRf//DWftc9V//vqnzwH"
DATA "W1gDLnXth2EfpnlzLeTin+/eL77YdlD9k2kglIM1DCy5r1r+1bCPo3tz14TU1/98+z7/+3aNGajX/2Q5yMFACf6V5szJvhyfQvMy"
DATA "tUI7SOmfv+YL+eevBdU/2Q5KM3Bpaz9K+0q8K/VwjoEp/s15/p/1zdWYf67q8/9kGwjhH5WBJb9fon9Q9tV0D9LBlHOHeP2Hde07"
DATA "n53VkH/uZ1P+cXz9x9Tz5edUNbBd/7it/SDto3Qvx0GKPfCYgc43+3kfIf/s990xOfZB7n1T/atRJToowcClr/2o7QutVVIrhoFz"
DATA "/ctZA9rq7BvzzxmYuu8t2fvOvfa3FAtbMZCbf5zsi/mXax+meXMtLDEwpw2pBjrf7Hvdh/xznwVna4l92Nf+lmQhFwOx1oAlv7PV"
DATA "tR+kfbmmvTPj88AhDIReA4YMdPaN+ecMnLvvhd775vg39nzR3MrJwRYMbGHvS2FfzD8K++b6B2FgTttyDBw66D73qPu1+WJQcz8H"
DATA "KScHjL0vpHeQHnI1kOMaUP2Dty/Fq9icPh75LMgSByENzG2T76A1ztWhfa5OuVe67y1Z+1GaV2KhGsjTv5LsatgHsTZKNcKu/ax/"
DATA "9t85c790DZTj/FwDbXWf/eb75z4DLuX2pfbN8Y+DexwcrG0g9BpQin+c1n5z7EuZ19a+q8aAsTVgqoOQBmK111ZrX+qxGO0dsy+3"
DATA "xv5+zqnQFnIykNMacIn+ldiHsR6a6x/WeohqvWvrweG9Ivcg7CvxD9K80nNbioG1/Ss5d2r/KNZ+JdfDXHX27Zl9oDMw9XEA6Oth"
DATA "Oe6nGDiWxZh/Kb83xz6otR+FeSUWUhgoeR9cy7+SrKj9K53/qe656uzbsZ+NtjYw5/UPMS8g98FjGfg5/OrTP3cf//Ev3Z/+1k1W"
DATA "61/Kcc9+8NPu6bc+nGwXpn013YN0UNeAsvwr6aMaa78c91y15vn+2Tp2fKmBKT7MNdD55wz89PO/JhnnH2tva3+PrT/85cc9/6Ds"
DATA "S3Ukx6XY/edUSAfVwHEDW/YPcu9buu8ds8z5Z+3b9wycug30PjhnPo8ZhOkfpX2U5pVaKNVA9U/u3hfCvtXnQXr2ueoMHHsPKIrX"
DATA "w07Nbw7+zfGj1D5M8+ZaWMtAiWtA9Q9+75uz7/Xf39O375q57ucbOOd9QEMGlviXayClf9D2cXQPykGuBtZcA6p/8/wrWfsNP9vC"
DATA "t89V9z2oz4IMGZg7t6bmJaV/c42Ya1+OT2N79KkK5SC1gbXWgOpfun/Y1/5S970h/5x7j573DUzxL2Qg5DXAXAsw/cMwodS+Eu9K"
DATA "PWzFwFp7YPUPb++bYp/vnq3vfrT52v0Mag1YugdONaGWf9D21XQPykFKA6X5N7eqf7D++fa56hvI0b+xvKj9mzpHaPso3ctxEMJA"
DATA "iWtA9U+Gf6HPtR3a993Ptg0M3Y7Sv6n94TA3Kv9K3MO0L+V1KznPU5Jk4BLWgOofnH/+ms/a56r/fS6fB566JsT0L/UcoO3DNG+u"
DATA "hRAGtrIPVv/k+ue79/Mvth3k4l+qg75/1jNK/6bcg7Yv17R3flvn/b1zDVT/1D9o/4YG+vaF3g8+ZiD19b9cR2r4l+Le2HlT2DfX"
DATA "P0gDue+DJeyB1T8Y//w1X8g/fy3I0b9YhpT+5bgHZV+KV7HnpR//uN77e0tYA6p/df0LzYfUOZD7/D/rm6sx/1yt+fy/XF+w/cs1"
DATA "b2q9CmlfzDZb7drP+mf/HTsO0sCc9TKkgS3vgaX6x+31H9a1Z2ZtZ2vIP/ezKf9S59Dc+ZLrDKZ/c+0r6esU+8Y889d+V79/ZmDK"
DATA "8ZgGtrgGVP/o/EvdA48Z6Hyzn/cR8s9+3x2TYx/k3jc0V2Jr6dr+la7zc9f7qe7N9W/KQYp9sPrXtn+huVEyJ1L9s9XZN+afMzB1"
DATA "31uy90299jeVZ6l/tub4B3WdA9o+v5+cfXvvf3JuYMrfMSgDJe2B5/pCZWDr/pVcA8wx0Plm3+s+5J/7LDhbS+yDvvYXe84YpX+x"
DATA "c4D+G5fzd26sr519O0fPzw3MWc/n/F2D+tum1wBl+xcykGJtkDovnH1j/jkD5+57qdYIfsX0b+q+OfWvX615vn+2jh3PqX9L5p/6"
DATA "V+4f5z1w6frAfe6R/1m4ruZ+DlKt9UEL/mGs74f+rex7+rtzA6duw2l9r/6V+yd9D4xxfcga5+rQPle5Xx+S5h/02m/MsNX7e3v2"
DATA "ueoMrP3+3uqfjDUglz0wtIG2us9+8/1znwGXcvtS+yD2Rlz9g/y7lrPv7b2/t2ff1Q++7BnI4f291b9l+YexBhwzMNVBW619qceO"
DATA "3V/Jvrd0XYDpX26/zu3TkrXf8LXavn2uuu9BvbdZqM/Vv3b8q7UHhjQwxcGxzwNPcQ/CPqn+zf2bNnfvO7bnHfrn3Dt+3jeQw/t7"
DATA "56zz1b8y/1pZA5YYOObgmH8pvzfHPoy1H3f/IPe+Kfb57tn6zkebr93PoNaAc//mqX/qH7SB/hxyHqTMf+tfynH+54GPuQdhn/pX"
DATA "5p9vn6u+geqfPP+k7YFL14AlBmK+HyikfRBrvyX7F3qfxqF9zz7bNjB0O/WPxr+5n4HUin8UBlJ/Hji2fepfun/+ms/a56r/ffVv"
DATA "Wf5JWAPOMTA2l6j9Gzu/HPvmrP3Uv23/fPd+tnrPn76D6p9M/ySuAWsYSOlfbfuW7N/QQN++8PubhQ3U63/t+ydlHzzXQH9eUfg3"
DATA "dS4Q9ql/ef75a76Qf/5aUP2r59/S9sCQBqY4SPV5kDnuYdnH3b9Qf6X4N+f5f9Y3V2P+uarP/5PpX609sCQDa/lXw76a/oX6LrWv"
DATA "5vg3tQZcre/+cFaD+9/1z6b8S30u6Jy1X2gslPa/+idjDQhtYGxuUfs3dY6Y9rXiX+oeeMxA55v9vI/g+9ua77tjcuyD3Puqf2f+"
DATA "SdwD1zIw10Eq/+a6B2kfN/8grwHmrAFtdfaN+ecMTN33lux95177U//aXgNiGegqpn+p50BlnwT/Sq4B5hjofLPvdR98f9v1Z8HZ"
DATA "WmIf9rU/9a/9NeBcA1McrOnf1LlD20fpX6jP5vpXugYMGejsG/PPGTh33wu994V87EOaf2rgfAPHHKzhX8r5YthX2z/oPXCugUMH"
DATA "3eceBd/fO/NzkFLtk773Vf94GjjXQUr/StyDsE+Kf6VrwCkDnYPWOFeH9rk65V7pvncpe18I/3QNOG1gqoNu3mH7l3ouU22Cyo7S"
DATA "v1BflfgHbaCt7rPfeu/vvf4MuJTbl9qne18Z/rVqYK3PA69hHwf/MNaAYwamOmhrC+/vrf4tYx+c6uCUhbX8Szlv6Kxs/pL8gzQw"
DATA "xcEW3t8b0z4O/klfA2IYWOIgpgdc3PPHPLV/GGvAEgPHHGzh/b0x/Stxg4t/SzdwOP8o/Ms5L0z7uPsHZaDv4NLe33sJ/rWwBsQy"
DATA "MNdBTA9quxca6zX8yzEwZx+cYuDS3t8byz7qvS+mf0swMNXB2v5htj+UNyf/KAykfn9bbPvUPx5rQCkGTs2/Gv5RtDeWdS3/Yn2Q"
DATA "sw8eMzDmILV/Y+eXY18raz+u/i3RwNA8pPKPsn1jOdf0r4aBlP5xtq+WfyU+TfnXmoHUDtpa2wMq9zj7B22g7yCFf1PnAmHf0tZ+"
DATA "kvyTbGAr/qVmy6G9UAamOEj1/mY57lHbJ9G/FPtaXQNSGtiCfzm5cmkvlYG1/GvFvhL/sNd+rRtI4aBk/+bkyam9kAbGHKT2b+oc"
DATA "qe0r9a/EA0n+cTYQ00GJ/pXkyK29uQbmOkjl31z3ONtXy79c+7gZKGktKM2/0gw5thfDQFcx/Us9h1r2lY4XKWs/jo+HSFkLSvEP"
DATA "Kjuu7Z1jYIqDNf2bOnfO9i3VPykGQjnI3T/ozDi3d66BYw7W8C/lfNU+ePuWaGCpg1w9wMqKu/cxF+Y6SOlfiXuc7JPu3xINnGsh"
DATA "Jw8o8pGw3x8zItVBZyG2f6nnMtUmqOyWvvaD9A/aQEoHUy2s7QFlHjZ/Kdc7oQzE9E/t4+ufGphmYQ0ParTfZY/Z3tS/OZAOTllY"
DATA "6t9Ye0vMg3YPalzVsg/DPzVw2kRs/zi0088d2z8MA0scpPavhnsc7MNY+125dqtpAzk4SOEBB/co/atp4NBCCv9yzkvty/NvCQbW"
DATA "dLBF/8ZypmwvxlzPdRCzvbXdg7Kvtn8xs5x/aqD6BzWOqduLNe9THaztH2b7qcZMjbUfZ/8wDaR2sBX/UrOt0V5MA6YsrOEfRXup"
DATA "xw312m/oH0cDW3BQun+5mdZqL4UJIQup/KNsX62xA21frn9LNBDbQan+zc2ydnspnbC1xvObuLsnwb6Yf0s1EMtBaf6VZsihveqf"
DATA "fPuk+yfVQGgLJfgHmRuX9qp/deyDGk/Y9o35x9lAagdLLeTqH1ZW3Nqr/tG5J8m+Kf/UQBgLOXlAkQ9X79U/XPe42AfpH6SBrTmY"
DATA "6mFND2rkwXm/r/7xXfNR25fqnwQDOTgY85DSAw7tl3C9c4n+YbgHPeYo7cvxTw3k6cHS2gs9d5fgH5Z73OzD9k+KgdwcXIp/LnuJ"
DATA "z3ds0T9M91qwb45/kgzk4mDr/g0zl/p877kWcvKPIp9W7JvrH7SBrTvYqn+xrLHbSzXHUy2s7R9lHlRjiLt/Eg2s5WBr/k1lTNFe"
DATA "yjk/ZWEN/2q0n3ocYdtX6p9UA6kdbMW/1Gyp2lvDgJCJ2P5xaGetsYRpH4R/GAZSOkhhoWT/5uRJ3d7aNki/3knpHif7oPxrwUBM"
DATA "C6X5V5phrfaqf7zda9U+TANrOQhpoQT/IHOr2V71T+3Lse/ylQMRBtZ0sNRCrv5hZcWhveofH/egxxq0f9AGtrgWLPGQi39U2XDy"
DATA "Xv1rxz1o+3z/JBnIycEUE2t4UDMHjutd9Y/WPQn2Df2TZiBXByk9WFp7S+ek+kfzHhnQYwrDvpB/GAYu3UH1j+fj3Uvyj8I8zvbF"
DATA "/Hv89EOtWrVqXWS9/5Vva9WqVesi6+23vqFVq1ati6z7L949r9deeVProPr5SKw3nrxXpUrKKFQljVGdC/PngqT8ta9h+35Jng2r"
DATA "pLFYs0rq0znzADIriHWD9rVWqFpzLOlcaGOMYO+Tave7pL7Smjd2IWuNeaBzAb/W6tea/S2pf5ZeKcYDtzmgc4GuLqW/JfXJkir2"
DATA "/OY0vnUu8Kva11qxK2b/chi/EuaCpPFCWbWvtZZWrH7k4JHOg7ar9rXWlIrRZ1z8qVV1LtSvkvtaUs7cK9Zc5OQNl6pzgU/Vfl5O"
DATA "xegPbrZwrToXeM4F7ef2+rQV3yAyqXn+OhfqVerxrX3Nq1+5GlcjM8r2YfSPzgW8ecCtryX1Aed+pfaNc6YU7de5AF85zgWMc1pS"
DATA "X2Plhzm3JeXrV4nm6VzgNxewzrPFvpbSpy34FquYWWH1r6R8W54LFOZJ7W/sTLD6UlLGJRUrP8w+l5Rvi3OB0jzu/Y3ddqo+XVrF"
DATA "yHTJc4Gi7VzmAkVba/c3ZRs59OkSKkbOlOOkVm6UbZQwFyjzgOr7GucsqU9brRjZ1xxLEJnUPP8W5kLN/LjWFvoVuo9rnj9Gf3Ad"
DATA "e9yqzgXtU259Wis3yjZi9BGHscet6lzQPuXUr1wzpWg7Vr9xzZSiYmVKMR4k5ax92m5/YmaC1ZeS8i2pWPnpXGivT7H7VVLGKRUr"
DATA "J8z+lZRvq3NBUr7ap9qnfsXKD7PPJbuHmQlWX0rKt6X+xOxXSRljVKy5gj0WOGeqc6GdStGXmH2q/RquGDlTjpUamVG2T+dBO32p"
DATA "/cqjYmRfaxxBGVjz/HUu1Kvap3Q51Tx/jP6oaYakqnOB71xYcr/WmAuU7cPoH3WPZh7oXKCZC9T9StHW2vOhdp9j9BvnTCmqzgXY"
DATA "StF2jD6r3a9c+7N2f2P1paSMSypWfph9Lilfqrmgvmlfq3nbFSsrzP6VlG9rcwHrPCX1F8e+xvy7Jilfv2JmonOhvGLlx7FvJfWL"
DATA "lL7Gnt+c7aNoO9b85JopRcXKtHbfS+oDyX1NMe9r20fZRow+4jD2uFVpc0H7dBn9TGFgzfPH6A+uY49blTwXqLOSeM6t9LX0ipF9"
DATA "zbFUmkfNc29lHtTuw1rnvcS+5l4xcqYcJ7Vyo2xja3OBY39y6G+Mfl66e1iZUowHrplStF3nwTL6G2t+Ssq3pGLlhz2/JWVMMQ90"
DATA "Liynv7H6ucW+xswKq38l5VtzHuhcWE5fY/az5L7GzASrLyXlW1Kx8tO5oH29hL7GbjuWcZwzpagS54GkucDpvKT2dc0sKduH0T9c"
DATA "xh6nipGzzgU+54nd15T9jJFnzfPH6I/aY0xK1blAPxd2tGjRokWLFi1atACUfwmVrN+w3BLMTjNMK6PhaYTjJSE8jTBaegn983bR"
DATA "BMfKeHaBDLN+e/MlJbxBhFm/v+2Snp4muF1C4b21XUIRZt1Po2U7vkB4wwg1QFeG6UXDG0SoAa5KXnqBBLPurbnSj89L6Z+GJZCg"
DATA "BtiLbyS8YYQa4KoE44uE149QAzTFjy8pve0ElxxgID4vpzf7ZTvBpQc4Et8gu2GGGqAp2/FNpLed4KIDjMU3kp6X4FaAWffdQJmM"
DATA "7x/7RQPsFW/2+vFFwutHuBXgAmfwaHx+aDcDCYYDzLp/4WU4e6Px9fMLBLjMGTwYfn5851m9sSo3zv4ZJDgMcGH5BWdvP76z2N64"
DATA "eePm+qtAgG3P4PUFun7xfjQYfr341pmZ4Xd9PQA3CQ4DbDG/YHabDKOzd5BePz+XYHQGZ50i3zIa3nkJDb9+fKenpzeuH1y/Yf6N"
DATA "BdjeAEwLz89vOHs36Z2eXj946eD66is/wMEMbii/7YT6JWH4eemdnh6Y/A7WXw8DbG8Cj2fXz7Cf33D2riM7PXjp7ksuv7MABzO4"
DATA "pQmcEt55hIHpuxXfiYnvrgnwZCvABidwenqr1kamrzd7T05OTHx3TIDmq8EMDkxg2fmFwltf5vRLP8R+foPhZ0I7MfHdMQHaLwMD"
DATA "sKH8tuMLhLcVYYC/zexd5XfnzismwPP8VgGOAZh10nzKML1oeP0II9P3PD6T3iu3XzEJbg/ACIBZZ82m5KW3SXAyPxPfbRtg2/n1"
DATA "4/NSWl8q3pRBgiP52cRObHwv2wBX/9dqfr34RsIbRjidnxl8L79sArzdcn7B+CLh9SOczs+kd8sm2HB+fnxJ6fUH4Zh/Jr7VXZwF"
DATA "2KZ/gfi8nNaX210JJTiSnxl8q/swQ7DV/EbiG2Q3zLAXYHj9d+vWOr9btxpd/23HN5FeIMHzw7f2H7cOD1f3cnjo8kvaf3hXMTYl"
DATA "p1V0JRbfSHpegtEJvA7w8PDm6l5uHh6m7n9HS07LSMpkfO4xn94jF4MA+/n5118Ob67zu3mYev1FVITe7PXji4TXj3AQoHeDTYA3"
DATA "b95Y3c+NmzdTr/+JinA0Pj+0vUCCmwBDA3AV4M0b6/xurPJLuP7s9Wi/cExwOHuj8fXz2wrQu5kX4NmjR6s78h9B8n5DcPoGsgtk"
DATA "mNNMtDIYfn5851mdNXrXa/ug/f0A/RuZBK9ftwGa/yY+/jYS3iDCrIbilODs7ce3bvTe7l6v+cMB5CXfD/CN6wfmjg6un///ML5e"
DATA "fpPp8UowNPx68Z23evfSegBuEgwEGL7tGzubL4O3HV7TPu/PXglFmNVanPyCs3eYQC+/8BiKj91NfuGxu5VfILzhYSwCjA6/gWGn"
DATA "p7uXLl7a3fwFCBk2Yuc6v5id/fii4Q0iZBBgP7/439DT00sXL1y85O0fQn9DB3+7I/cZf/5fSnqBBNOailJGh5+X3unpRZPfRf8R"
DATA "3NAarh9g5D6jzz8dpHf2c68EEqwcYGD6DmfvOrLTixdevODyi+8hegFG7nQkvpHwhhGyCDA2fbfiOzHxvWgCnHoOQW/vHLlTL71I"
DATA "fJHw+hFyCPA8v8D09Wavue5p4rtmApx8DoEfYOROY/ElpbedYM0AI/kNhp992MLEd80EOPkcAv/aYeROw68/EvnauTH+NrN3ld+1"
DATA "a1dNgJPPIfAjiNxpMASZr50b4a8//Ex6V69cNQlOPQbuhxC505H4JtLbTrBygOn5mfiu2ACT8lv/rsidBgyT+tq5lPxWj9ra+F6w"
DATA "AU4+huslGLnT7fTEvnYuOT8z+F54wQR4Zfox8M0gjNzp5oBQfJHw+hFuBVhpBqfnZ9K7bBNMeQ5BYn4uvanr3keBBMMBpjUasKT6"
DATA "Z+JbHX8W4Jh/fiKROx2kN3ndu5cfr9fOpeZnBt/qeDMEk/I7+4WROx2kN3nd+2HStZv6+Y2s/y5fXud3+XLKcwjWuUTuNHipLxDf"
DATA "+jrP0cMj/4pPP8DKMzh1/3F5f391/P6+yy+2//CTidxpP77J694PH6wH4CbBYYDc8tva/+7v762O39vfT3kOQVJ+qde9/fy4vXYu"
DATA "9frL/t46v7398esvriGT+SVf93744P6Dh+c9xuy1c6nX//b2dlfH7+7tjV//2zTE/NrInfYf5Q3N3k16p6cP7t+7/8Ab87xeOzc6"
DATA "DDat2Ntd57e7ym/YkNBAiLfF/Tjhfk25b/K77191ZPXaudRxsHtpdbj/CNL4OMjOLzjubX73Xr/n8uP32rnxgbBx6NIlG6D5b6pD"
DATA "OfnF3T09MfG9bgJk+9q5QH7Bv4OXLpqDL15K/zuYlt/E3/2TExPfayZAtq+diw7A2c8hSGlF6rrz5MTE95oJkO1r5wb5ATyHIDW/"
DATA "GH+b2bvK77XXXjUB8n3tXGgAljyHIGkQjPDXH34mvVefvGoSZPvar01+wesgkVsVXgdJz8/E98QGyDa/ieefRm5UeB0uJb/VlUYb"
DATA "32MbIN/XLg0XY0XPIRhduPTvMyk/M/gePzYBPmH82q/hDC55DkHin8D0/Ex6j2yCnF87NxZg5CZl8SX7Z+JbHX8WIE//xl9/FLlJ"
DATA "4eOwqfmZwbc63gxBzq+d2w5w1nMIkuNLXv89erTO79Ej1q+diwcYuUFZfMn7j0fHx6vjj49dftz2H36DQq//jRzvpzfjSRSR/Lb2"
DATA "v8fHR6vjj46Pmb93jB/grOcQ5MSXfN37+Gid39Ex0+sv/SZtv/9B5OjNAXPiS77ufXT0cHX8w6Mjntf/hm3aev+NyMGD9LKfP7Gd"
DATA "X/D689HDdX4PV/l5G/DA9K390ut+gFnPIciNL/m698MHq8P9R5BCl34YDD/XqEGCkUMD6WWdemACB697P3hgAzT/5fn4W6hVfoIp"
DATA "zyFwN0q7C/+uBvkFr3s/uG8Ovv/g/P+H8fGZvq5V/QAjB5bGV+m6N35xcaQ+h2BeerWue1OUfoKRgwrTc3cTnMGI171JynksKc8h"
DATA "mH3W3iDfChDtujdRmc6mND33K4YzGPm6N1lJzm/i90zeRSzAyI1G4+P4viZzfphzB94MJrjuTVxG8xu5XfqvJ77u3VbxZjDRde/G"
DATA "ynaAyNe9WyvxACM30Pj6JRAg5nXv9oofIP517wZLMECs694tll6A2Ne9Wyz9AHGvezdZ1lvBXoKRQwPpLT4+0uvebZbtACMHanyR"
DATA "4uLAvu7dbuknGDlI04uX81hQr3u3XKaz0fTGS3J+E79nwSUhv9Hba8G+7q1FixYtWrRo0aJFixYtWrRo0aJFixYtWrRo0aJFixYt"
DATA "WrRo0aJFixYtWrRo0aJFixYtWrRo0aJFixYtWrRo0aJFixYtWrRo0aJFixYtWrRo0aJFixYtWrRo0aJFixYtWrRo0ZJQ/h/TqXhc"
DATA *
