' new-year.bas - palette color cycling
' Exported by DRAW 2.5.1 (https://github.com/grymmjack/DRAW) on 10-06-2026
' 320x200, 215 colors, 7 cycle range(s):
'   1: 6-25 FWD 10.0/s
'   2: 27-36 PING 9.0/s
'   3: 37-74 FWD 19.0/s
'   4: 75-114 FWD 20.0/s
'   5: 115-144 FWD 15.0/s
'   6: 145-184 FWD 20.0/s
'   7: 185-214 FWD 15.0/s
' Keys: SPACE pause/resume, + / - speed, R restart, ESC quit
'
' How it works: the art is drawn from a 32-bit image, then an 8-bit overlay
' holding only the cycling pixels is drawn on top (overlay index 0 is clear).
' Each step the overlay's palette entries are rotated with _PALETTECOLOR -
' the pixels never change, only the colors they point at. Speeds use the
' DeluxePaint CRNG unit: 16384 = 60 steps per second.
' Compile: qb64pe -x new-year.bas

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
_TITLE "new-year.bas - color cycling (SPACE pause, +/- speed, ESC quit)"

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
DATA "eJztfVu0JVd13YF+3G7ZCGz3vbfPvUImQcSEOLyCRKslMbCxnQQSQiBOoAmokRoN/GESQ3iEZyPsLxNiQyISh4ACUiOJMfxjQuzE"
DATA "IpL15M+DDzL86w8+zA8//mEMc7LW3ntV7dq19queu85Z695Zp07Vrtestede+1F1fuUN73jDc1avf86zq/+3On/69ObZ++/f3Hvp"
DATA "0ubG66/fvOzcweaWG27cvPr9920ufura5pc//+3NG7/y9Oatf/j9zaXv/GDzvmd+uPnwn/9o89t/8debL/zljzf3/3Cz+SJ8/g58"
DATA "/wgs/w1Y/05I9zZI/ybY7g2w/W2wn3PXXbc5d+W+zU2fe2zzmm/91ebS9zab+36w2Xzvx5vNl+DznfD9Zlj+EliPtobzOgScPwXY"
DATA "A5w+BdjbHMCyI1wHy9eAQ1i3xvUnAWdwm1Ow7Sn43IPPPdgettsDnIL5PcDpk4Azm33YxzHgAPZxBDiAfRwBDmE/a8Ah7Ovc8y9s"
DATA "brrhns3Fl1/bXPo1OCdYdv4E4Cykh2McAQ7gGEeAQzjOGnAIx1oDDuF4a8AhHHONxz0J53AGcBLmz8ByOI+jC+c2r7znps2br13c"
DATA "fHRzafMTdd0nYd0Z+DwD5wznugc4BfN7gNMnAGc3+3C+x4B9ON9jwAGc7xHgAM7vCHDhxQebe17/0s219/3SZnP/lQ3u+BDOew04"
DATA "hHNfA/bh3I8B+3Dux8grnPsR4ADO/QhwAOd+BDiAcz8CHML5rwGHcA1rwCFcxxpwCNeyBpw/Add2FnAC5s/ifYLrAxzAdRwBDuFa"
DATA "1oBDuJ414BCuaQ04hOta47WdhOs8AzgJ82dgOVzrGnAI17sGnD8F174HOHV287xfvLA5/5Z7Nr9w77XN7c+it/wE1gEvwMExYB84"
DATA "OAYcwPUeAQ7geo/wmuH6jgH7cH3HgH24vmPAhXM3b+656fLm2sUvbzaXfrT5G9jjPlzzMeAArvkIcADXfAQ4gGs+AhzANR/hfYTr"
DATA "XgMO4drXgEO4/jXgEDjYW51erVfPWX3zuhXYZoPT49VNq/3VH5xdrZ5rlrxk9cbVz69+5Vyd5k2rD6x+dfXr+/WSD65+b/Wbq9UL"
DATA "6iW/v/rj1e820vzJ6vurP2qkwbwtEAgEAoFAIBAIBAKBQCAQCAQhYN/Aks5XIBCUB9ERgWA4SH4SCAQCgUAgEAgEAoFAIBAIygQ+"
DATA "c7Ok8xUIBGVD+gMEAoFAIBAIdhn4roAlna9AIJgby6lDor6FNK7rOoFAIFgA1DuhctfFdFMgEAhKQUCrfBrXSRcFAoGgNOB7LwM6"
DATA "h+8GdZdzyyh9UP8kLtxFqPenLuh8BTsGj26pMXQ5+udbriD14qUhp606pHFd1wkEwyBBd7wxHb7PPmEZbh+JC2VM8vYipGP4Dv0u"
DATA "2wkEwyESf/n0K1X/uGW0X2kT3ArENM6nc7nLU443NKRs3gHE2udQw1wdU78P5Cxzv1M6d1koJhQsDuqHnjrEefg7Sjnp6VhjX8/S"
DATA "Ic9jdUSwrsrpWET/OD307auFeLuglM3lIKRZPp3jluOyLrooEAwCVS/11Vkz9S41Hmysl3rxUpGtgW+5Jy1dwv4FgkGREO+p38r1"
DATA "fHfXcds310mdeBvg1S9G65KXhfZrQerGAj+oPhkY1+eC0StX43ya19K/UF04qT4smBuxdr4Kibqmfk89tl1oee55CQQIqmPGYi7U"
DATA "LCbms7XtMGHe3aax/zl5EHRCqE+3QoLexb779pN9LgJBCJEYzNWumObZy7jtOV1Nh4yVLgGoOaG+CtStXL1jvwfqwyl1YoEgGTSm"
DATA "JVLvzdE/TgvZWNAFjQ+s+kPkOZESoTTIo1GteO7U2azvbDyIgOOJ9o2Lw5Pd1m0FQP84jWrWabVG2p/uMlcHo7pHcaj0hSwPvnpq"
DATA "SON889z32HEEg2Kn9c+Ai9VI2+x5TvvceTcOrEDxpvSBFAXqU8jpV8B4LRrz7VkxvG+e0T523x5g3bzL+e8aQjp2tNdtXVnaaPX3"
DATA "un0eoXF+7jV5NJA+ydO4dfjpqwMn1YMFs4P6GFLqnEqjumiebx4B+4tpH7UHSl9IOrroX0z7FhcbVnVODZ8m6fprO7arS9kmKI0b"
DATA "A3rjQMEiUPU7xOqhKRrofrrz3H5s4DlIW2Av+PTsIHM57iekjUsCxWacXqXonj1P29g6KNgSmD5eb2zmrd+aefcztI2F6pjSFhhF"
DATA "LB5DzeI0DZf5lnP78S1PPY+iOTSxH8HVuo9uLjVg66Gre6SpjTowtQFSO6DbD+LtC5b+4FLA1nsRKboX00G1DvadUA8WtIHaE4rN"
DATA "vDHdqbRluH3onQuLrBcHYOubq322BlJaWzul/rvlQJ1qaRd8tzUOsD59tgK3vrE97i9UDxZEEaqfon6lal3qspTjTg6738Np96O2"
DATA "P7fu64v9Qtpnx4BFXLcgCXZLBvV5pPZ7tICapXSrGdspvTOflf5ZyxvpaR8px7PaAqkfhCB9wTVyYr0DZ5n73bdd7Fjjw9PvO9D+"
DATA "Of1787WLwTqwHf+5deBpOJkeR3t7ndaViKrPw4Da4Kp6ry8+s+I5W/N8cLdp7sscx9SDpR2wGzhdQh2L6R2nf9wy3zGmwbBtYlz8"
DATA "h8td/XvlPTd59S92DG8b4Cj8TIdt0r8kUN3Xjf3UPW7q3KEFVgPV/qx9pcaBO4zUdjbUui7xXooe0v5zzjn3OscCV/9trm/2ffj0"
DATA "D9dx42Cy2//cPpBCeKruM2hYSMcOPOt8y+39Tn0to8Fq69O+0NQ+WwNpfdUmuJRrLAwpbW6+eO/Y+m7Pc9+57VO0D8+tmD4RO+7y"
DATA "pHHHr3BtgKR/7ngYbtyLXf/NOtdWH/CMvNE9H1j/tkb7mDqsT/s4Day2lxiwM2gMi3fMCqOBIc0LaSPtL3YuRfSF2P0fkbSp4/+O"
DATA "LpxjxwHSNr7xf/3aAMsYA+PTs6NTectD+5odsbY/t+5L2zl9vU29O8HWg4PnEWoDlPHQHn8Lx2Uhzdv3zMdiQ/f487UHkt/k1SOp"
DATA "Dlx/bz7ji7+9YeucrX+0jNLSPoLPfyTEobP5T6y+mqlzvuWlaJ/d79vrPVPMWJdmzMfrX2tMTAdw/cBcul36DRmuzotA7Yppnk8H"
DATA "aXvueKn14VGR+XsaXDwWeu8L6Zyrf773IND+gjFfgf0fqIHBeiujaQeeZVzaUExIxx+zbmyPe+m8n+y+j1r/pugDkXEwdZ3X1SxX"
DATA "01zd8+mfu519jPmu0xr/krqNJ/ZyYzbu/Qb4ifrnW0f7cfed9D6sgvo9UP+8bXoZ+sdtH6sTj619nbe367/s+rYOan+o9c9d526X"
DATA "dbwdAcat1IdA/R2+Z9l8CGsg5TvfJ699oXpwCHQt/ftEtN8k/wYo9zu+Br44kIvtOP1z570aGKvzFtT/izrlrb9ycd3eqeB333bV"
DATA "ukjcOQca7W6+dM7YZ27cM+ofOw7aHQPd5zx2EFVfQ0L9EzUsT/faOkj7SdE+agukvpDZng8J1DFjdWBOBw89sV87fgy0/0XPOa8u"
DATA "n4vUGAv1L0XruGXu95D2xerEk4P6GIL3qN3/Ud/7pgba+mevd7dLqvta/R+T81I4qD7K1XsJfg2kfEmfaXGge9wULZ4EKb955CyL"
DATA "vftej+ur9c6XjttfA6ltfiOOf6F2tljMhbrVJd5LiQdp/2NcXy6y3nfFvfMq8Pzb+TNYzkaef4sdI3TOA3OxLUANbGsW5ilX9wi4"
DATA "zP5up+PjwK714FERq0NGtA/h+70P0j9f2tBvBTeQ1fcx3vgXqneGYjC2LuvGd9Z3d52vLpyqfWP2ifR636m6j3wM2OjXBf1rLEt5"
DATA "D4xan/YeGHkfahh13dfOi7b24Xdb99zl9TbtenRBSKk3Mu2AIc1yddCN/9x5bn/R30Mfg4tMUHuft98iooGheU4PffFgvZ3W5bHa"
DATA "BHN+T7L3e/9s/bM/uX30eCe+/R6EVB52DxTLOVqHfkZoaWA7/uuC5L6KLkhpL/PFWxE9JPj0LynmW4AGEnwa6GqZPX90ip/n4sSQ"
DATA "9pEOj9UmmDUuhPlty/qeBd77HNM/ZrtG3hjgN5G2YfyLr9/X7feg8X7U7kegWK2O/dx8ZvKkrX2VBtJ6N9/WMaBdB0Zw7YCN8x2l"
DATA "/yOxbthR++zvav6M5iaqeZzeheq79O7T7OsfB74YzdU80jqf/oW0sLHfjPpwV+ToXlBrcn/3g/Qv43dAOp/blmC8Z2ad2I/TPjYO"
DATA "HCYGJB0fZhxMYpuYL77iNCqgh7b+setS9h9r8xtBA6n9LKW/o7ldu+6qljP6lrKM3VdCXTgHfZ9ziLUFJv/um61pJ617yq1n9pPy"
DATA "O0hdr3E3QfoV0D8sf4P6t6TrNQjVLY0WhfJMqv7pYzna5qvzzqCBBLu/I9bmV2/T1C477jvwfLrzthZy+ywBof5UbxucrVu+sSu2"
DATA "/jXus11nzm/3Ew1sw1//dcHFf+CPrP7RNlo/ufovpRm1jS8XIR3hNChFvyz9S0rPHidF38bp7/VBPa8WiMVszdPpw/pnf6bEgdHz"
DATA "I922MOT1B/tCuvzmeSz+i22fcvzYeW853La/+LNodvyH3532P/TTVvsffYbrv27731ycVMjVPkRMz/C7rX9J5+E7VnkaWPmVic18"
DATA "dV+f1h2f3lPg1tG2bhzYOq6JR+n54SH6QmJlclRDGP2JxoL2vK1/Ec3zxnsRDdwVHbT7PlLS82NfEEwduKF/dt3X3k7Hf7HjNvpm"
DATA "pn7uI1Z/5LQnNR48mRn/+fbtOw+Dvu1YQ73vQ/XXunVXSwNtzaN5+7ubntt/rE94LCS9B8GjO9F2wAn1z76eWJqhMcV7Zbo+88vr"
DATA "lCcGxE/lo+54QHubej92/TflfKZ7L2AkZvJpTspY5Jj+hfbjPW5Z/b4+UNxn65hP+zgNtPdDmLP9L0UrQm2BwWWuxp1xy8l6fXRf"
DATA "CeeTe11LgD32JXUbe/yLu44f/4yfVpxX6Z+rffU2vnch5DwHMt6zwANqn2+ZrX9cui7vsxr5WV97LLHb71HVNU0MFqr71n52qqV1"
DATA "+xZ88Z8vBiRM9Y66PtqXUhdu6Zejf9H0nuPQecV0cBvG/eWkD7W58e89cJ/t5fTPXt+O/XLOIXSdw70fP6J9IY1JrQ8jYvrnWxZt"
DATA "7xu2rW+IPoJGrBaI/2ztszXQjgNDmLMO7CL6PNzM+mefZ99r3QaE3jeQ+96rtfJVTh/d+fC7EIp4/4FB1fbt07/cmNDVv5x9TqyB"
DATA "Y8EX94U00NbPUB24ikE9/SBjvycrux84ZSyyW/8dYN+7rn+xPhCuTpquf9z69PdBI4p5DwwiN/bzLUf9O+PEKDntfUn13HI00Bf/"
DATA "+eu9pzrHgNnnNsI4mJCm9KkPx+I/336Cx42c77Yi9DtHVRpGd/zvco7pX/yd+Cm/h9TnmvuNKRxQT1DTXP3LfXa3wL4Oru0v1P7n"
DATA "j//a+lf5gSf+K4WDWJtZ1lhjV8tSYztm2ba39aUipc/A9ztvvjjQ1TKtf+11KXFfrO1vvt+EC+hfbp04R/+Cz53Mq4Fu30fKNm77"
DATA "nx3X+fTPThcb/zJn+19n7UvVtZNMHSHjGd5d18AU3ejSBujOo/6F1vv2SUhp+5tWAzv2iYS0K1X/gho38bMdTt9v6na+OM3f/1vr"
DATA "H1f3teM/v3802//G5iamHdl14h7616euu40amNo36tMc32/A0byrb4cB/eN+B9MX86Vo4Oy/iR58PiQj/ut6jJE1sMv7Diq/8dR/"
DATA "3fiPPgnrs+3l7na1j6TVf+3+jzF4isGnO1n1YU7/PPDtd9fa+lL0IdQHEtM+Tgdd/Uv57V/uOKn9HsONfekCj/7EdPEkk2d928xU"
DATA "z+3SJ2C3/7HrnWd/KQbUflHrn/2d0trbNXwn8x0I1P/bh5scdOkPYZcz+pe1fcL5LBV92vZ9/Qox7XO/0zzqX0q62LHo3Gb/LXQv"
DATA "OsZeufo31nkMCBr77Fvve++BPc/pn70+9gxwbtuf/S6EMbnx1SlzdXHt8Y8usZ6825l8wL+Oi7+4fhF3HvXPXRfbj+94KedZJGJa"
DATA "lq1/ZY7pi7Wvse+tj7z/BfXPruty+ufup7G8Qx/IWL8N0kVnfHom+jccYv3AKdrnIqR/Q9R55+n3DSGkSZF6Mad/nY+VjqHeK5bS"
DATA "lhZ756n2Ab/+cetbcWSg7jtV30dX+PTJt9ynf13rs6Vp4FTPLcZ0JLUt0KeHa+i/67P9sjSQQ4IusvrXQU9nQEofAheDue+Acd99"
DATA "SvOHpv5rr3N1k6v7+s6F+j6G5iGGPn3CHHz6N+Qxth2xfgJfPTMlHqTvpH8pesfuN6bPJfT79sSarWuV/dxa6jNjKb9z6fttDwTq"
DATA "H6d7sd8AidV75+z/dRHSxiHjP2nns/wqsS/YXZZaFx5K/3znkXo98787Oh7H8foX23YepLaN+eqbub/9gfoX+j2Q0H71+YbbFqbs"
DATA "+/Whi/4dBuI/0cAwumofgtOokCb69C9nX6Hzybmm8hDTv7KQ2icQamfj6sH1vW/P2/rnpgn9XnrKudTbTTsGJhUhrQrpn2hcP/ja"
DATA "1bpoIulfsm6G+mGW1u+biKXoXwyxOmXO75379M+XPniMxL6Psce+cG36XbUqpH8h7Ko2pvanhDQmtT5sLzv09H90gehfuQjpnm88"
DATA "YCh+o/n1iUh/BvOuqy7nWG8//hjAVEj8Nz1yY78YSP+GqutuowYeLlz/YnVHLvYK1YPt767+pcR8fTWwFIj+DYtYDNilDS0WE4b0"
DATA "z7f9drb1Ba5nwfoXazvz1TtjmhWK/1JivmAb5II00Id17jvSBEHENCUnLrSXkf55n6vztSkyy+2+3G3SwKXqX6ye6NOZnOcxUP9S"
DATA "tm/pZ/RZlDL7PJJ5Ef0bDENqn7vcbv/LjfVCdV3Rv3nRVfvUPXfWhWJB1L+U+q03zoxoILd8/jFTcYj+TYPgc3EpbXFnxjn2NmFp"
DATA "+jek9un9+fXtkNE/bpuu51NKX0cuRP+mQe82QUv/cuq6fY6/NKy3oD2qef/56/HFaKF40Kd/7NjqDjGgPt7y+Bf9Gx9d68WN5Zb+"
DATA "JaXfQWyT/oXa1DgdiukY6p8vXcq+Us5LndvCNPBQ9G9WJNeLe+rf3PHfFG1B26J/udqntknUv5TtQseJnd/SIPo3AccB7UnWpR7t"
DATA "f9nHWiiG0L+p3hfkQ5c2wZRxKKH4j21L3LK2BC8von9FohXLWdpVcpx3cMZpg3K+j4m54r8hY9uQ/uXGXbaubX6in+XP0TpvrCnx"
DATA "n2AI7nPiQuv7IPHkAEBta+ndSes3xZj1o/K58Jilq/alxISkfznxY/CYW6KBon8zcr8w/eNiOVvvEAe2/rnrRtbDpetfCGPqX+fj"
DATA "boEGrvfSf/9NMCMKabtD/Qpp3pH5DUr8dLXQ3W5obLP+ee9HogaR/vnQtb1v6Roo+lcmusZ/U4HTPHueW9bY3sSCQ7YPbqv+dakX"
DATA "58Z/3rGGW9TWx0H0byn3aZ7jVjrFxG4NjTO/veF+HjjaR3HgGLHgLuqf974522zuv8Iu96Xve/ylQPRvKfdp/nNQ2uXomU/3Wp+w"
DATA "HRcHDsvRuPufA137RHL1L7ZuWzVQ9G8p96mcc1Fte6hnFOPBJ4KbV+lxGVcHNnHgUHXhbdS/4H3I0CTSvymOtSQciv4tAlPqH41r"
DATA "oXoq6hTFfm6d19a6Y8gjBHs5piMNpH24fcPDcLQd+pc6njAnNkyJ/7a5nuuD6N8yUEr8R3GfrX227rlQ25j043O0W/FfCK6Wkf6F"
DATA "NE70T1DufSrzvOy4b9+CLw50Y8Ah+kMoXtol/cvVsWvv+6Xe+91GiP4t5T5Nd6xQ3deO/Xza59PAlOP2aQc8lPjPC9K/XYzxQhD9"
DATA "W8p9Gv8Y3PNsrTQR/fubzYbVP64dcHiORP/UPQrEf6J/TaxPif4tAXPWf6v6amssX1v/Npd+5NU/br8UXw7DkeifD6n1312D6N8y"
DATA "MLX+2XXf5vJ2/IfLSQOvXfxyQ/vs+q8d/3HHo7Ew3TkS/fNB9I+H6N9S7tM0xwk962HrljvuBefxE/XP/u72f9j789WBu7YBiv75"
DATA "cc/rXzrZsZbwu0cE0b+l3Kdx9+9r+/M98+Eb+0f652qfva27/6Hqv+tTon8+TKl/S4Lo31Lu0/TH5HSJYkD72Q/6RKD++Z4BoX1w"
DATA "cd8QzwOL/vkh+sfjUPRvEZhS/7jxeNyzH64GIlD/aJmrfXbbn08D+7T/if75IfrHQ/RPY+7ffYhhyva/1rLWe0w973qBz3tuulyl"
DATA "c9er+UYbIl/37aqBon9+iP7xEP1byn0a/xgp2kf65dNA0r/Qe7Da7Ylcf0u+Bs6hf6WXm4QLLz5YxHlODdG/pdyncfef8m770Jhl"
DATA "n/75dK89rqZ/+9+hxH9eiP7xEP1byn2a9nihd9yr9U4cSJ+kf9wYP3s7bp99fxtE9M8P0T8eR6fl94+WgCn1z9Uhn/a584hG+x/T"
DATA "1xGL+3qNfxb980L0j4fo3zIwlf5x+tP4TcvI735cOHdze/vIs77tenbH9x+I/nkh+sdD9G8p92mCY/T4fUtO/3xx39D1XoLoX+je"
DATA "Lut8J+NF9G8h92n6Y4Z+27yRzlpu619I88b4/aOj0/JuEy83on88L6J/C7lP0x4vFpP5nlnj6r/s9YwQA4r+BbgR/WNxIPq3CMwR"
DATA "/zWOH4jfUuI/bh+t+LKnBor+BbgR/WMh+rcMTKl/nA6F4jNb146d3+C1141R521yNN7+lzLO2X9Pl3W+U0H0byn3acZjJ7YDIlz9"
DATA "y913Hywt/pvyPVEHhevfXO/MEv1bBubUv9a5BPQwFP+x2w6ofwdS/w3cs2Wd72S8iP4t5D7Nc9wUfbI1zdW/1ljqAfWuzZHon/8e"
DATA "Let8p8LS2zV2BaXEfzH9yq3/DsuR6J//vtXzS3o/89g4Oi3P/y4BpeifGw+6ergfif+4fQzHkeiflxuJ/1iE9E9iw5KwjLzt6h9i"
DATA "LL1zsav697JzB4NgSdc8FCT+WwrKzNuutnH6N9m5nN7N599E//r4jOjfMrDc+G8qiP6J/uXiQPRvIRD9i0H0T/QvF6J/S8Ey9O94"
DATA "xt/gFf0T/cuF6N9SsIy8Lfo3PYbSvxuvv74XlsQZQfRvKRD9i+FA9E/0L9tnRP+WAdG/GET/RP+ycVbGjC4Don8xiP6J/mVjS/Xv"
DATA "lhtuHA3zXNMy8va+6N/kEP3rAdG/Zejf3nxc5kD0b3p00bp3fucHCqJ/on+if8NhTv07f3am484M0b8+PiP6J/o3HET/pofoXw+c"
DATA "2E39+52/+GuFWLov/uWPFUT/0iD6Nz2k/a8HRP9E/wbE8Zy/wSv6J/qXC9G/Zejfqfm4zIHo3/QYQ/8uQd0YIfq3TOS05+ViKH8L"
DATA "oXVNon9xnJjpuDMj1q7H4beh7EeI/on+if4Nh1L0r29drg+mvm7Rvx44u51jpkT/5oHo33bo3xKuexDsgP694fPfVrCXve+ZHyqI"
DATA "/g2LfdG/ya97KJ9b2nUPAtG/2fTvTV95WiFF/w4Xwrvo3/QQ/esB0T/RvwExp/6trd8465J/P/znP1Kwl1F90l5GYwfm1r2p9Y/8"
DATA "VfSvH6bwiS66JvrXH6J/y9A/igl2Xv9OiP7NpX8huJyJ/sUh+if6lw3RP9G/AXE04xjkvvo3Bn4D2lgQXbb9ZdAnhL2M+m3n0L8Y"
DATA "5rrvvbAD+kc+uGT9W098j7pC9G8Z+seh77XOdd97YWb9o+fL7GVv/cPvK8SWLUn/aDzprutf3zy2NIj+if6F8oDon+jfHOC0hUOs"
DATA "zasEjKF/XFtoDCX6YwzrM9M//za1/g0N0T/Rv5LQxR/v/+FGQfRvb1St4DCFT4x5/kOVt9uofweif5ND9E/0b9v1D20J/pSjfzQG"
DATA "PXYv+7ShzQ3u3Lk2vLdB3QZhL3sj6C4idowx9K8LSvRH0T8eVK7by2771DUFe9mr33+fguif6N826R+Hvtdaoj8uUf84X8hFafr3"
DATA "BWjjRMTKYNG/NA0R/RP9czGlhnH6Ifon+ldi+99FuKcIe9lHoG0LYS9Lfecd90zInJhK/4bIl2NC9G8aLrZZ/8bkLeXej4Fd1z+6"
DATA "ftG/Zehf6VwMVd6WiDF5m+reuxD9E/0rCUvnohStWrr+cbqUqkGl50UCtamMeYyp9K90TK1jQ+SBKbjg2vVSf/9N9E/0rw9K0L9U"
DATA "DHlOfd6RQ23uudvNoWV98wAHahfrw/+c+kf7jqXLfSakBP2jemMsHV2b6J/oXy7m1D9q24ilG7P9T/RvONDzhSXq35zgxt5wy7jn"
DATA "IEp7JmQoXxnynET/ytG/oSH6J/on+lcehsjbJehfKVx01b+SMLT+9UUpeUX0T/RvLiydi6k1bEos5d6nPhtRIri2S64tNBVD3fs5"
DATA "ORkCMd8jn5lK58bOA6lcpNbZOFD8JPon+jcUdkH/uFiangGIbcuNr+TaxNz9bbP+cf7BvTuQ42JM/eOe6+DGW9H7lkrRua7614dL"
DATA "0T/Rv9L1j2vX496fTO0i9rLU52e78LnL+ke8dtl2rv6PsfWvL1Lb8Did7aNVY6CLX3TRv9T3VfjSzq1/KdhG/Rsaon+if6XqXx8/"
DATA "ix0nR//mwDbr3xxcpOjfFChJ//qilLwi+if6NxeWzkVfPSsZU9577h0EHFLrTUtGn2ucSv9Kx9Q6NkQeKJ0L8kvRP9G/MTGU/vXB"
DATA "3Bz05WJqHRsiD3Dg2vXo9+rtZaHnRKbSPzqv0nRsCP3r84wg1z4i+jfONQ517+fmoC8XU+mXD6lt47HrEP1rgtqqYum45+649j9q"
DATA "z51b/0oD98xqqkbPiaH8rJTrEf0rR/84iP6J/pUE+/5Rf2PMV2iMSYn61xVj5vkp9a90LsbUupL0bwyUlF9ciP6Ve40pGNt3l5QH"
DATA "xjz/sfVuTsx975fyXr9UcO9yGvrZFdG/tDzPjcWbAyVwwYEb5yj6J/rXB1PrXx8Med1c3Exjc+xlqe+7TXmf4BL1r+u7DmOYU/9C"
DATA "v+u2JP3j3uFH7Z2xdDRGWPRP9I+wBP2jMd4xXSA/je2fe59gzD+GgOifH+SbJerfGOjThtfnPcZTYSi/GJvzufUvBbusf6kQ/RP9"
DATA "KwlD+UXJ15iCJepfyVx01b/Skap/Y2COfCH6J/pXEpbORQkaNha24d7vGoa690u6Zg5T61jJeWDM8y9Rt0T/dhdD3fslXTOHqXWs"
DATA "5Dww5vmXqFuif7uLoe79kq6Zw9Q6VnIeOHfddQKBQCAQCAQCgSADN3/rrxR862/63GMK7vJL39tUuO8HNdx0X4JliHdCOgIdkz3u"
DATA "lfsU6LiI10A6gpved1wCHTOVD9/12tdtH+97P95UoGvlrpfSvwT2jQgdn7tOH+i4qfdXHdtw3IVn93o5vu37S9dbHTfxugSCKUA+"
DATA "6lsf0z9b+zBPuOlC2sceN5An8Xhuet9xCUPrn6u3KdqXo38+/fGBjpl8fxO0L8Sze73c8bzaJ/onKAy58Qjpni+9GxfE9MeNC7rG"
DATA "X770bvwVQ268GYu/YtfrYmj9a93fTB3Kja+71icEgjmQG4/E9M/Nj9H4y8mPXeMvX/pYfvRdb2q8GdOf2PVyxw/xy/EdK19c/cvR"
DATA "n9z4umt9QiCYA7nxiBt/ueD0L6g/jP6F4p9YO2PycTter6u3Q+tfrHzxIbWdMVd/cuProds3BYJRkRmPxOpDbjwSjb+ceCRW/4u1"
DATA "MyYft+P1cvqX074Yi7+66l9qO+PQ+jd2+6ZAMCoS2sI5PYj1e1L6YFs4o7vucWP9yy66xn0En/74+j1DfTsp+pMbX8eQGn/5eOau"
DATA "O9a3k9O/3PW6BIJRkKB9rv6ljPmg9CHt4+KQkPaF4hD7eGPqn69909vv6eyH07+c+DqG1PjLx7ObPkX7cvqXu16XQDAGxu5vjeVH"
DATA "7nhd6n+EIfRv0PZNhu9Qf9IQ+ldS/7LEfYKSMXZ/6xz6l3O82PW66NvOGOtPT41zvSisf1niPkHJyO1v7fy8QeL5jN3+FcPQ491c"
DATA "pLardj3/ofuXhxq/2bdcEwjGQG5/a+fnDRLPZ+z2r5TjDznejeM7pV216/kP3b881PhN0T9BiYjpX+54t7GfN4ih73OmXds3U/s9"
DATA "c5+fyUVqe26sH993vS0MNH5TIJgDsfag3PFuYz9vEEXP50w7t28m9nvmPj+Ti9T23Fg/vu96Ob6HGL8pEAgEAoFAIBAIwliJiYmJ"
DATA "iYmJiYmJiYmJiYmNbe/NSi1G9l5DXPNDLNmu2B/EpljcDFWauAaLYin2XsPc3ThVk9UVw9+8XvjNrNTzmWHL4k9PZ8vFhrjmR3lW"
DATA "saPpuqua3N30wsnNMPZI41uBRv6l+ar5U5PV3dPTR8Rp5uxpmTSSh92FjN31HpggGk44qX2z4XkPW/OleqFhSTFG/CkOjROCTamC"
DATA "hizNnJo+3GCxPLtb82RzV/sg2MQiaBP4UDVXMH+W713WwA/jgzNkYs2Xoq6eEIvFZOP3vtdEfWiKq8vwj9D8mSxc5eHRjZTPZu0b"
DATA "NGOmdqr57coVcq73KOe7vFrdSf/4pfLBicwUuhZ3hIq+KkkpRg52GUDkwUS7YJO+8QuRR0xR8ZDNnYLJw1UmLsju0jRdbvCnKIRF"
DATA "2u6+cuXKNGXww5oo5OyaBeWDq4fGou91jY9se89lnAJl78Y/nCCDaiHYXXdNWoRoAg1x+l+hzsPDW0/+jKu9WxGI9OE/eiBm4SkK"
DATA "kG/apcI3yPkepH9Fn1qs7ZFG+j5mGLuj8ZFAI5S9WHiYyA8N6ULq3vUu7YU6A1+O72oge+SRKnN+o0Ge/l9dI/oefnjAIqTBH9GX"
DATA "44Z3gfpdVnN3Krd7lzL0wtWd2gOns4eN+Fneh3+aPr3ioaElUHN2uzW9w9CYYZcvK64q9uBfMTi9PWRyqWbtAfVHFGIWHkwCycfu"
DATA "UKTdrqdqiZ5mi+Gd7373u5G6fw0GHCJ7d94JGfg9oIBYgugieIIyWOXemj1icHWtysGD2OuMm2m6bqsmFX0dChPgDekDAlfvAjqn"
DATA "zr9k15CuB4C4B77+9a+rT/j+oMnBg5nJp7fX1NWTpFwMpQeq33vAye68U7ufoQ8cMLr1cAaF6SNW6YH24IPodl9fAX8whfkHdQZG"
DATA "Awl8GNIPUARbrnfRgOgjL+RNl77t5Yq/d5oMDP6HGTi4I699tvGRZA8/9BCo3zeuaT8DnwPytGkHhAx8DdYPGQQqlm4j7hR/ahKj"
DATA "j1mm/E+p3yXNH63QAhjaHWcd+Kvs2oPofoq+r33ta4pAdMDaA3tarWy3NXyv4pCcUCUO7kqZyr/wicWH5k8FgQ39wwIkvicgzDB2"
DATA "rzXtRCNI3wrpAwKBSeV/w1klbtr3bl2t4F9Bfa/ouyNeiIB36RmMV5QAXkLvU+UvFsBWUiyAY7sjyhr85dOnMqymTxH4wANDOiDY"
DATA "7TpiWV1Ewgx5hkbjg5AkWoRA+UGzdfz3DhUBUvznCGA8gNGcfcaaVm4YNpI/zL7K/5C//6FysElhBHCYGFrn3Yq8C+qf3BDXhzUQ"
DATA "i986R17GtgNVe1shf0hfVf+oPDRs5GQ2c3oapw9KX6dlSoUuwN39WgF1AVKbKoGju42YyryrW4k8zaChr87DHrP7NJSPmdaXd62Q"
DATA "P92CUDXBJJUfnzU8KdKuqomaNU5YSaNrEL00F9jFB/DnLUB6RzAXUfkUacie5g+/6VwdMLvl3jSSorOpdoPVO/SHbn+5bBLdlVB6"
DATA "3KsJvNqcVJnYR1/zK+RR9akYXAF/+IHfrHU97HWvu+MOXWXTZgh8rfnT9JkcXG3iFiK2hqkeX2p9Vm6n+KsJpMybUP5+RlN1FSef"
DATA "NjAkErlhA3XTMxg+q+j5fhVBYwDtpOhlt99O6re6YLGnGFxdqOi7DYqQcD3EZEzKwIrBtyv3Q3/EpVYXiK8bs3asz1zFqaKN+FNL"
DATA "6kwcsocoNFblB/gfEAj8waeqAlP2hfIjYWdRu6hzL7nfLatbLA/EtRXFXqs6j3BymRh8u9WAr1bX4ueJXz5L0re6ehWnxF3lg8Ri"
DATA "wKy2K9V4ZepvX6X6G60wiaP7S7JbkazXInu3AH+33AJz2gObOdhjlCGJPtP38Xb8arwP0Sg+PPHLvfcaB1N0fUoDP3QWvlol9BQi"
DATA "Ttupbn3BKPCrMKlaYOo21NVQbagXLgBhQB+yh1P4gjk6warcqBTwsgYyiP5X98DpNCnad1V9EoHmX3GofRBZ5kXQCkXc1j/gj1oA"
DATA "nUZ8aEFgd5Ztr0Xvu+Xmm29GApX/pVilZfXYjctqTvOH8+p7MoGUSZEy+P+k+leeaOj7jCleXLOiENVtWbU+E3/6G9OJlB2/6NIX"
DATA "S4/bQP1uvfUCuB8SdssK6Lv5ZnBC+AIOCBn4VqWAkJYtP+ps2KQPcPlfVeTZg2BSRrJpR0PyPmn4MxSCWXm4aRZ7hhq79+Ordg9I"
DATA "M1m+8ZVZdD9Fn/LAtgPeAbVgZ8taxLRfKaIMh8BfcwRMNYrI3THaZ+uyA+zTiizFWzVRi6osHDCSwLr3DUj7ivm0OoGtkTAD2GtV"
DATA "9gXuXmP4y9raZMuqfLhc8ceMYvN4IJQdJH4694L3fUL94T9QqFUwZqZM1QIHbOlwBfgDc7swByFQ51+cU/z9A8UfEqryb9IuaOgk"
DATA "Tiq+gD9nFCUlD7UdXDUuBuQZ9tRf5YFk994LLstsb4qQRuc5+V+7C71n6YvyR1U08D+lf69G/VtV+Rf1L7Ybm7565B/wV5kZxUtf"
DATA "w40vn9Z+9klN3cc/rn0QCVVrr1696itCakKqgUNm5AHw5wzhMOm7MwjFRzWvwheMXRR/WABj+UFroZgJNcJQfqxHPiv+/mU77yY1"
DATA "naJ9Csn6hCLv4wicV8upEOatakFoDX7x8dd1FGCz8quY0g54y6sxBjTxc12FC7QCkjNZo3fRiL8GdekjUD+JjGn6FIHogM0c3LaK"
DATA "CiOBZoKk/XcAfNKiKo29VbJB+FJ/gfgFP1T8jB74ahX+kfvZAshXgRn69AT4U3ONNitf1RdCYiw9roL8mewL/ofUfexjH9P+px0w"
DATA "ZA59jbF/yJ8zBrCqvGVHf9a8ETfVeoDVXsUfNSBYCcyW7XZ8os8QU+fhFfHXLDw46WsVBOBqijBFHxAIHmgskoHRqA4X42+IgdCm"
DATA "bcBuvXqV4rEmMN6Eqsx67sjyP2thiEDetPcZAoFPk4E/bUoQX0uWXQJXKof8tRb35Y8KEJVJa/7q9hdqwo8zaLufccJfx0n9vcq5"
DATA "CQRq/9P8/fumA9rGRjCNxxYqHyT/a44h70Wg6Tky/US6yZn4qxrxqz6k8L4YTu5G/uwCN6noUPJn9E/z91GlgCiAwGp8ByRmVmiM"
DATA "lDmD8LtKX21VYaB73rQHImWvqslTq02ycCdc47lV44Q1f4bFGIFYfFRfUP/A6zR/MEfxS0T/mvTVhH25mrPXdyewYqMhgPj/qqr/"
DATA "w+lBChDYLEQMXTV/CU+wYvFbf9Oepstf4E9lX/A/vRL1z7cboqP16EzNn5N1OxFojTxQU90Bp3l7pdWD2RyFcEesE73xwLTyv+YK"
DATA "H4GNtgOq5qL/YRb+CE51/FznXyg/PPvSZj/0pkzxp63/Q1wVD6YAIfoUg8hf1f1rDyXCDcMMan6IxX9Rfwnn3EYhAPqnPrH6+wmk"
DATA "7iO6Bof/jQaEzwQ6ktqPvin+rO/DPMVlxh7gpBp78Mp6FEI1iijWha6t6V42f3wKxq4addOtB6r2C/xZFWBb/qAJwbMbnSltFv9b"
DATA "PTvcU5iGlmrwkOaPopb0YWxNI8ps/tKCPtI15WbU/vIRyLqKP9WE5TQB8t0gDWY0ZyPwRyVwRR+a4a+VeVPGQjdeV3JF89dcFbRK"
DATA "0qjxlPhTn+h9Jvv6i4+m2c9Ma/6aebYfgdXQKzWtx6y9wvmeQaCyikXFX4PToFUFgnIwbIDB5tPVJz6MPCKbKvvqJHpAh8+cQliZ"
DATA "5o9Z0dWoJGiNPX2FMwaVsm609HXtbThJra3VlbGq51J3e6w+rNijDhDKvZHyF63x/HnD/wbocKuLYJzUWbjNX619aQRWHqf4SyOw"
DATA "ljGdN+3ujw9TH5JxvqoTM7LPJn9/YH/pT2CTPmvAOPFnjyHv9CAD8ZdidSFwVX+oHGwYBP6qHkwrSeJIGKLK8Df0M7/2UzOGsVe0"
DATA "n2FI1r6GpfNHRpnS6jvX/JlBCO4oBF/4oqxJleGPXdfd7Ec/iLWXe5NlWjZ/hj0dA1ZjNz5kyoxqFIdV1PiGAlo2qv/Z7kf2cibr"
DATA "diLwrVmpa0G7ihOTgw1/lfO5BMZtTP4agkZOaPjT3zs+w6Uskz+Ss6tqSmQZ/6uHEOlEGQRq+69ZqdOsevRNTYmvlzcfInTSZlge"
DATA "f81hz1Yd40PVdzUM8KpemlZ41DYCfwx9mr+G66U/CuxaFn9N+pSbGRf8kDMCNWssfmVj+J+25iPTq9XfZ1d3sBz+GPqIv39X+V4z"
DATA "TbzosG08/lwRBP4aWbeL9Cn751mptVkjx8kHNX9qkV5ejcMP7ci10fhr5mKYAn/VfC/rwF/7yQXgr46YzUyXp7n+S0baLlbnYpe/"
DATA "Cf3Pps/ir/rWUfvQRuOv9cYNR/+6E5jNX0MEqwjF+J+aZIctlY3tf9rQ5X4x2fOeBXzXv7orf7Z3XV2tPmhTl/ogV8tG5s/yQuCv"
DATA "5ZMt+y5y9wxQiJ8ee4t/FWtN+ion/KDtj50fxCyIP+VywN3qafXv5TCXP2Me/pprswn8UlbqPgb8RexZQ95Tq6eQQvzGWUf+tNVZ"
DATA "9IPms6l9uQROw1/T//ymyEP+1Ce6IKOD3fhr5GLb/5pPoufadP7394Jrn1XOh6w9of6ehC9PP8O6YC/+tCFbH+j7DLqyUvgDexpd"
DATA "TrOHf08pD2Tsn8V2xFmzELH560dgQfyB9z35xOrP/kz9r55ADwQXbGfhTvwZs0j6gH9Vht2XlbqPBfj77rPPPPP00+hwTwB1jz/+"
DATA "OEyfeOLJp7AYadsA/DX8r2PO1VYEf8aefALoA/bQgEBfsj78GUPKPtDrHTBk0/H3sqRU4H2PPfaY9kB0QKYM6cGfzdhvuUs7WRH8"
DATA "mewL7qfp0wRWax0FfLN/Rzn2W/0cz1gB/Kk6Gxrx938Vf0oBufT9+TP+NwR//zkrdR+L5N+nnsICV/H3Hc2fWvp0uwgZzP+GsDL4"
DATA "g+wLU+V/q8cfexTog/wL/qfWPePUg3eUv7/rXWOqHsAWRi+rxx8FYPmBTqkTNARwIP7+bVZqn83Pn5Y/XfnQ4d+jqvjFuggsb+ff"
DATA "f+rZUaZtC3/KFEtPAmNY+3hUV0BMG0IrfimKv/+UlbqPBfhTMZ6qfiCBq0exBgdV4CcNgY7+CX+O6QwMQAcEBv9UNyMgezr7Ngnc"
DATA "Uf5e6ltR0feUIfBPqQUL3U9l30b5MRB//yYrtc/m569qtjfBsuZPs4estvTvn3h2lGnbwh+aabhXHvgk8KcCPyLQ7QYpir8vZqXu"
DATA "YwH+kCFNn3JC0D/VhE/e5xAo/Dmm+AGiqPfj/+B3qvoigc32gx3l7xd8K5x+S8Wf9j4u9w7G3/uzUvusAP7QTLc5GHAG/Bny2P6j"
DATA "N4V2lG7bxB85ma6sqfyrjFG/wvj7QlbqPhb0PzDkSoug9r+KPLf/SPhzTTFk/AxY+9/6wzf+YEf5+zvh1bUCKv7sxY4NxN9vZqX2"
DATA "WTH8oRkOjf/5xrG9Mb6jFNsu/iqegDTkD7nzjL8qir/pLO5/xJedfxkrir/fz0rdx+L8oQ8ih39iPj2DUHeUv5ckp0T+AgN4B+Jv"
DATA "GCuNP6RN8ee3fxxePa0V639+K4q/38tK3ceEv36Wzt8fh1fvKH83JacU/jgbjL9/FF49rQl//ew/ZqXuY8JfP0vn73+FV+8ofy9O"
DATA "Tjkdfy94QVZyxhbI3z8Mr84x4a+f9efv81mpXXve82jup386lrZE/vpbifx9O7x6R/n727EElU3P3+nTWckt68dfjg3G36+FV8et"
DATA "Vr2zZ/Wn8JdjQ/L3H7JS97GS+etunfn7uZ+Dyd5e+gbp/P3P8Ore/A1pI/P3sz9bzf6tSNLahL/KxuDvV53vZ87AROXJOhzoYta5"
DATA "ptvI+lc4f8oJyDrx97ms1H1M+Otn6fx9K7za5Y+15z+/8fXECZi0S9sGf52sM3/OCcbtRckpp+Ovv8X4U/WyU6doUluUPzcmfVEk"
DATA "fW0R/pJM+EsxRYuyTuJVmZLQTva7kfVe/qK2BP5+6qf053j8DWcvSk75R8kpd4m/n09OafFXB+iZ5ZVKrgTvZ34GJidPsqmIv+7W"
DATA "jz9118+dg8lznhNLWyJ//S2JP3UKnIX4u+46mFg3eDv5a5pHRebjz2/PfS5Mrr8eJnVB1a87yHuV6ZbLX8i685dkfflT2zdsPP5K"
DATA "tCL5K87UVdYEpV+iEpXonmc0dYL9GtwSbDz+guZcVzy4CBsXJoX4qxdndcyo3NjcbBH81bLh0b8R+OP6ixn+IqbCGzVRNYjB5HsC"
DATA "/tIOv1D+8izK3wgWH6+QYmXwtxzLrEYouRytoO1Xp6kzm7Jh/ClmU/GnXFpVAJSpDKpErF6WfTLqPGqaPPypA6ikddtSqjm7ZKxM"
DATA "/pRsqAq3UhFPfbYnf05AES4/Uq0WPHUx/bKq1ZmdxF/zLHL589gS+PPkjJzBKO2ziPLX0xL4y7cy+CvYapdkc06KtTfMV+bxrfPl"
DATA "hW0U/ibfhcpsqq/eWxOhQ3Ts0XcqTFV/zhL5a8v4EPzVUqW4Urus2+R9/KWY2ja/7MmwCfgjWwJ/ddnY//kPxsa5lWH++lhp/BVn"
DATA "XRrWFUee6spA/A0V4g3jRQEbmr+4KW9WYU7dktZq60ziLyFRm7/8bn11mko71VwzEC6dPxV4KxbUmarl5Nmj8uc0mPr4i2yrbNie"
DATA "mCT+KuvJX9sWz1+ehfgb1fqU9AXxJyYmJiYmtlB74Qv158EBTs+fP79er3Hu+PiGG254oV67v39wcHB4eIjzeu1qdcMN9T70trA1"
DATA "rDs6OjrW265WN95o1qsttR0d18e9cb+5Z9xW7RuOe+ONN+43z7RMeyFdo+EP6DvCOUOfWmsu8jzO67U8f8htRZ/Fn+ZH2zHxB+sq"
DATA "+syecVu1TtO3CP5sHzmvrkP7CPGDXtD0Lz2P/kVm+yb5F22LxvGHx7UZsv26mSfKNttHiD+8RuIPr7HpX3qerlFvW/sm8UPbqvVm"
DATA "v2rfdF+QP4sf26+beaJss30E/QtN8Wf4UfwZ/yFlbHpfvS1yy/FH90VbrYw2P7Zfc7pZqtk+QnkIfYT8C32E8h8pY9P76m0Vf5Yu"
DATA "kn81+auVkePPp5ulWiXhigMqPfE6lIQrdnEtlctoTe8jfnTpaYqdih/br8lq/9J7VltTsWOVy55TLsoq+pC/KvhADVL0KQ8x9BkP"
DATA "cb2v5k/rpi49cYniz/Jrstq/9J5xvqLPKpc9p1yU+cpWuka1rpH/GP4Y3VT7NmVSi7+EcnkZ3ucvW4P8WetoWzRXGalMrz1XW0q5"
DATA "vAzva5atzbpBncanX2Rc7IZWq2ozPVcut+NN966VaXbZ2qwb1Gl8+lWtZ2I3te9KVZvpuXK5HW8uiz87dvPVDcjcmmlTN+vS067P"
DATA "2FZrLpX4oXizbCMNsmM3X92AzK2ZNnWzLj3t+oxtteZSiR+KN8XEtsb+Pw8FXqQ="
DATA *
