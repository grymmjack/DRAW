' tunnel.bas - palette color cycling
' Exported by DRAW 2.5.1 (https://github.com/grymmjack/DRAW) on 10-06-2026
' 320x200, 25 colors, 1 cycle range(s):
'   1: 1-24 REV 12.0/s
' Keys: SPACE pause/resume, + / - speed, R restart, ESC quit
'
' How it works: the art is drawn from a 32-bit image, then an 8-bit overlay
' holding only the cycling pixels is drawn on top (overlay index 0 is clear).
' Each step the overlay's palette entries are rotated with _PALETTECOLOR -
' the pixels never change, only the colors they point at. Speeds use the
' DeluxePaint CRNG unit: 16384 = 60 steps per second.
' Compile: qb64pe -x tunnel.bas

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
_TITLE "tunnel.bas - color cycling (SPACE pause, +/- speed, ESC quit)"

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
DATA "eJztnbuOJE1WgLtn+jbd09OXmb6shIOEhIWwkDBHWgwsDCzw+iXWwoIn2AdYF4d3wGAthLRPgLT+SggJCwsVEVEZWRGRcTkn4sQ1"
DATA "I6XY/ae6Mivzq3O+PCcyq+qvfvn3vzw/+3n+72e/OGPL4efZ4fBnf3o4/OJvDoerXx0OZ79h47ds/OFwuDn8/vBHh18f/vzwy8Nf"
DATA "/9/Z4Z/+6+zwr/95dvjf/2Ar/fPT4fAPf3I4/O1fHg5/8XeHwx//4+Hw7V8O/3P2u8O/nf3+8Ouz/z58sKedn52fvbPxu69n7H/Z"
DATA "dtnCtxcz+D5QD35MFINzSRmcaewQ70XM4O9fzODvOXbwGIkZPK5iBovFlMHjmGLwXMg9eK71NLgX9jxi/ZfDgdN/0305vFfCfdN1"
DATA "03/Tf4P6r2P37dV5PTlo+o/Wgd35b7qP3H17815PzhnFf63WgNN/RP4r7L6WvTd9N/23lx54yN63VO03mPum76b/Sjpw+q/j2q+S"
DATA "+0ZzXk/+mP4brwcervcd1H0jea8nZ0z/Tf9V898g7mup5pu+28f4aRkU/muxB57+K+S/jmu+6bu+3UUxpv8q+i937zuQ+6bzpsty"
DATA "DCr/tebAIf2Xs/Yb3H3Td/vwGXZM/w3qv5y1XyH39eC9j4KeKT1+7mBQ+o/SgTV74Cbn/lqp/Tqp+abzptsgo1X/1awBd1X7Nea+"
DATA "Vr33kcFBOcfPOab/pv924749Ok/N4zna8F9LPfAw/uus9uvZex+JTqIevtydY/pv+q+t2q+U+0ZzHjRf56AdOfzXigN3578duG8E"
DATA "52FzdI58Q36n/qwBC/qvl9ovk/tq1nwfQEdRjZTcnKOM/1p24PTfdF8vzqPIxzmm/2r3wM34j7r268x9rXuPMg/nqOu/HA6c/ivk"
DATA "v0q1X4ve+7B4impQ594cY/uvhR641DWQ5v03uPs+DFdRjFw5N0eb/huxBizhv6pzf5S1X0X3teC93LnWw+C/P15itHK8pv9adWDL"
DATA "PfAQtV8l99X2Xokcox6lHDXimP4byH8Nui93zfcxoPN68sdow+a/Fh04/VfXfzVrPp/LWvddTy6Y/huzBuzOf9N9XXmvp3yfA+a/"
DATA "kWrAZvzXWu1X0H2lar7puTkww+c/agf21AN37z+C2q+G+1pxXk85PEf8KOm/nmrAav5rpPYr7b7a3uspZ+egGyH/jVID7sp/Dbgv"
DATA "l/em6+agHBD/UTpw+i/Rf6m1X6L7qGq+0t7rKSfnKDdK+6+WA3fjv4y1Xw33jeS7X/xNndEii978t7casIr/cve+Gd1H6b0enFfL"
DATA "ZdOf/fsv1YFd+q/x2q8F97XkvJ781NpozXFU/uu9BszVA3fhv0xzfjW8Rxn/PXllpNGr/1px4PTfvtw3Xbe/Mf23I/81WPvFuq8F"
DATA "7/WU53PgR03/7cWB3fivI/fl9F5P+TtHvlHCf1QOnP6r47/S7svhvFL5dPWr8qMln4w0WvNfaQd26b+CtV+M+1JrvlrOq+G16cu2"
DATA "Ror/eqwBd+O/BtxH5b3UGO/JY9OPffmvtgNz9sDF/Bfb+xL2vSXdl9N5PTmpldGyn6b/2q8BR679sO4r6b2eHNPraN1fLfivtxpw"
DATA "r/5r1X2tOO/sN+mjNX9NJ07/Dem/Cu6r5b3UfKXwWq7RquP24kUq/43qwJH9l9N9qd4byXF79uOe/EfhwOm/hN6XoPbL6T5K5/Xk"
DATA "sOnFdp3Ymv9KObAZ/zVU+6W6L8Z703fTizWdeHP4/S5rwL34r1X3ZfXdbyuO6cSufMj9N4oDa/XATfiPuO9N7XdjvNeN4zr3Yw/+"
DATA "K+VD6T9qB9bwX60aMIv/Gqv9qnuvJ8d15sQe/JfLiar/RnBgkz1wbv817L5o56X45A+EY4dO7MF9VD40/TcduB//1XAfifMo/daT"
DATA "I6cPyX2Y23+pDpz+o+l9Y+b8IO5L9l5vrmvJi9OHyT60+a/3GrC5OcCc/iOq/SjcR+a9CNe44hgzuvZhJRf27kNfPMwacAz/UfS9"
DATA "WPehnFfIb036cTAf9uI+OULvea8O7Np/CXN/OWq/ZPdFeK8F3xV34nRhc/6jdGCrNWAX/stU+2HcR+K9RN9Rno/N0ZwTB3Jhqz4s"
DATA "HXej1oBR/iPufbG1X1H3IZ2X03OlvThrw3ZdiHkfazuw5RqwRf9har9Y91F5r8T5U46aPpx1YVsu7Ml/OWvArD1wDv8l9r6+2o/E"
DATA "fYnOo/BcKTdOF/brQux7tmcHtuw/qtovyn0I78XGQkztr47WfThdWMeFMe9VbQcO0wNX8h/Efab/sO4LxUwuz+V2YxcuzOHBQV0Y"
DATA "W7v35MDu/Zc495fa91rdB6z5Qu83xfsGGTl8uFsXVvQgtQtj/UflwN5qwB78l1r7xbrPFRuQ9w7jMvM9ye1EahfOmrAdF6b4rycH"
DATA "djUHSNj7lnYf1HspNXjMoPJhbRfOeUJaD6b6bzQHZuuBO/BfjPtsceB7f6C8Id854RpUTizpwpi8mzVhugsp/FfTgd30wIX8B+l9"
DATA "Q7Uf1n2299DFnWw+QRkUXpwezDAqexDiQir/UTiwlxqwF/+l1n4Y99neDxfTWM/FjBgf5nThLj3YsAsp/VfLgS3VgKX9h+19obVf"
DATA "jPt83vNy8n0+OmZE+BDrwqE9uKOasDX/teLAYjVgAf9Ba7+N+1T/Id1n4+Rk4boOHjMQTixRE04POkYDHhTDmMPegwMpasAW/Yfp"
DATA "fVF9r8d9Ie+BnOf6vi/MwPgwwYXTgxlGZf+16MCea8BW/Yeq/Tzug9R81uO2HZ/rO/2xA+LEAh6cfXHCqOi/6cBO/Ie89hFV+yHd"
DATA "56z5IM4D/mYxH7bvfBAD4kOkC3N6EBLH04Pl/bc3BxbvgRv1n6/2C/W81prP5j1E7RoaQS/6XNiRBzF5Mj1I478RHNh9DZjov5je"
DATA "1+Y+GQtg96nHY/FeqE/HDJ8TnS701YRID7riYZdzgz170HE8e3FgrhqwVf+Baj+g+7RjNWs+ZV/V/YN+/6ptmN/d4PKh1YWZ6sHZ"
DATA "ExdyYC4XBo6pFQfW7IOL98AR/oNe+/D6z9H3qjy97lP3d9k3dZ9c+2L7rkF1mN/LZXOizYVkHpw98bgeBBxPrw5ssgYs6L/Q3B+2"
DATA "9gu6z9Lnyv1QXx/zm5nq321O9Lkw2YOzFhzfg8Bj2bsDs/bABPe/+PyXWvupfDbzfRb3md4LzjUq3vXmkOFElwtDHgzODybUgi06"
DATA "cHrQMxDHMR1YqQbM6D9f7efqe0PuM70Xciw0b7V88rgQ7UFsLbijfnh4DyKPYWQHTv+5a7+Q+2w1n+Y9h1d93E0HqHlsulD1oK0e"
DATA "RNWCA/fDu6gFMR6MOIYeHdh8DRg5BxjrP1/v6639Au7Taj5jm+q2NvcMOlyiekP1AdaDSbXgdOC4Hkw4htoOHKoGrO0/S+/rrP2M"
DATA "ntd0n9ym6T3n9WL1+MzaS3GM9Il0xcaDSsz7euJkB1aaExyuH27Bg4n7Px0YdiB5D5zgv9jed+Mti/vWbbJtyW2s3rOsa7tfR3XS"
DATA "6iLDhSAPWmrBZAcmzAm64mXWgpU9SLDvPTkwdx+crQYM+M/mkxj/QWs/9VqHVvct7uPrr97kx7Ks47oubN7bonqKv87GhYYHXQ5U"
DATA "a0HXtZHpwJ05UPUg0b6P5sAqNWDL/pP7Z8z58e2a7tNqPsV7/LlqjWh7v1V/SW9JX611Id8HpR40a0FfPzwdSO/Arj1IuN/Tgcga"
DATA "MNQDA+YAk/2nxIHNf67aT+17re7j+794cvWerTY03CEdwZ/Dnytii23f9KA4fqMWtPbDAAe2MB/YigObqQVLeZB6n4k82IMDW6sB"
DATA "qf2n9b7K3J3a98rrvHxdvo7qPr4PojZkf+fbFc4zakL1Myr831p9x15X9raqBzUHKs+1OXDNo0Av3MJ14ZzXRWYt6BgZ/DcdmFAD"
DATA "1vCf8p7J+izU+/Ltqn0vZ7n6TXUf+xvfnnycr6fWgvI9WPtWtj/SccI//LgXDwqfLX/nx2PzpelArRemuiaS8f7A6cDCHszkv14c"
DATA "WLoPRteArh44k/+cc39G77vO+y21HX++OBb2HNV94nG2Ln+Mvybfvnye9Kh0jzgedsz8dfm+8Ofzv4nH2T7wx20ONHthdT7QnFN0"
DATA "3Rtjuz+w1j3SLTlwFx6cDuy6BgzNAab4T5v7W15L633V2o/tK/87fy2+Xek+/nz+PL4tvm/8dUVNyLeteIs/xtcTzmOP8/X5enx7"
DATA "wkOLG00HavOBxjURbS7Q4kDXPdK1Pys3HVjYgY17cCQHJtWACT2wef+zbf4v5D917o+vz9dZXbbUfmudx9bj/+bP4cfB1+HbXB9b"
DATA "1uHb5o/z/eDbF//Nts2Ph/Pi+8bXFR5i2+T7JvKKPYc/vvbKynXhIn0w0fUQ7D3S04EZPdiwA2M9SOXArH1wTA1I4T/L/S8Q/216"
DATA "32V+T9R+bFtiXfZvvn2+Df58/hz+N9Gzssf4vojcYNvh+y6cyF5HrMOfuzwu3SjqQn7cslZk2+LHoc0FWvpg8howQx+8BwfOWnBs"
DATA "B9asAbFzgLbPv8X6T+19+eP8Mb4Ofx5nutZ0PAaW6yXCX2enobpE9sj8tfk+8sf48/l/i17X0gev14Q9NaB4fs4acCcOnLVgfw6E"
DATA "+q+qAzPWgJA5QMmVM4jxH//b2vuy5/PniP6VvYZ0iXgtxXvmEI5Z7reR/uTryj6YH4OvBqSeBzSvhaCuBxeYC5wOzOzAhj24OwcS"
DATA "1IDOOUDDf/wYN9d/gf4T84Fsv0QNxx4XdRf7b/7/Yt7Q4z/pSPE89v9r77xsxzcPGLofxue/1mvAlOshrTpw1oLtOhASU1VrQMR1"
DATA "YBL/Lff/mff+Oes/039s+/x5/G8+//G/y15Z9NFsfbEdtj3+N2sPbN4XbfTA/HlqD4ytAdHfo++rARt34BBzgp15sLQDoR5s0oEJ"
DATA "NSCmB5bHpn3+Q7n/T73+K69/8L/xx6W3RN3G1lXrOVHfefwn15duVf0HngNUemAK//VQA1L1wdOBwNGYB2s5sEgfjJgHNGvAlB7Y"
DATA "NQeofZcBW0f0u8u9LPL6Lz8m/jy+HXHddulH+X75/Ccdydfl+8W3IzzKXttZ/3n8h5kDjOqBY+YBpwNnLbhjB9pivVYNaLsOrPbA"
DATA "aw3o6oF9c4Bs/8T1W14Dsu0LNyn7rXpPXsuQ14f59vjzV3+y1+evw1/TdS90yH++OcDQ98PkrgFbdGBMPu3OgRk8mMpvtw4MXAtO"
DATA "rgGX1918n5VRA/LX4Nvi64l6j1/H4Pfz8T6Wrc+3Lx/n/833g68raj62Lf7ctXfm67DjkXOC4vrv8nk4vm8U/kvugRurAacDK3gw"
DATA "w35OBwL74Aw1IGfoqwHVz8G55gH5dvh6wnXsObKmk25c950dJ1+f7x9/XPiQvY58jG9T9r7i38r9LyJXlM+BhPzHt6P5j2IOsMMa"
DATA "MLcDm54TzOXAxmrBlhyYZS4wog+mnAeU3+3nuhdazgUKL8rPAbPnrbWiPAZ5L5/skXndx9YTfa/8HDBbj29P7X35vvHn8X3XPgcH"
DATA "9Z9SA8bMAaJ74MgacM8OnLXg/hyYqw92XQuBXgs2+2D1Woj1e/6U77vi25JulOvJ/VjvWWHb1uo85TsQ+PbV2s/sffk+aPf/Gdd/"
DATA "U/yX1ANXrAGnAyv5r3MPjuTALH2w5X4Y04Gi5uPPW+YL1esl6jZlXsk6TtR8y/yevCayuk/5HixZ+3m/E9XiP23+L5f/Bq0Bh3Rg"
DATA "Tv9l8OB0YMCBBHOB5vciSB4uB/q+E3X1oOFL6RXplrVuW/ym1nbqdwPy117n/djf1d7X9b343vv/GvQftgacDmzcfw3Vgtj3LNWD"
DATA "WR2Y8XqI+t1YkpvTgcZn49Za0PJ7cOt6Rv5LR6m1IN/O6rTFfWvfu9R+0n223ld6RO19qf0HmgMM9cCZa8DRHEjqQfU74DrzYAq/"
DATA "IR2YeD3E50DJW3Wgdk1Eqe9MD8rfCJHbsOWEjMXN91ktNaHNfeq8H6T3tfrPuP8lyX8N14DTgR7/qf3Ojjw4HQh0YOC68KYWVHpi"
DATA "tcaE/t6v+R0GZm0o3af2va7abzT/5a4Bd+dA8/fQS3pwOrAZB2KviZj98Ka3NVxoez3TJ9rcnVLzqddIpKs2fa+xru2+FzXvUv1H"
DATA "PgfYaQ3YvQNt/pseTPJgKL4wHmxhPhD6e5kbD5ouNPfH9INlzm6t1xZXqXWf5j5s7af4z/z8Wxb/FaoBpwMJ/depB0erBWtcF3bd"
DATA "I+373Uz1mNVjce63kuNq7mreWzyl+kn6SJvzM+pG032hax/Tf3X6YEoHRnkQ4r8deXBoBwLukfbVglAPqmxCx2rmmm1+Tva76hyh"
DATA "y32h2s/ctq33JfNfxh54pBqwqgMx/ivpwYFqwVwOLDUn6OuJbddITO7Q2LfVZeb1EW2uEOg+X+87/bdzB8b4byceHKIWRMwJYj0Y"
DATA "dGHoPVSf47kOodZ8UPcFaz9L75vdf5E98HRgRgem+G96cJx+2FILQjxoc6HqQ82JylD/HvrugY1rHO5z9b2h2i8094fyX+ocYMEa"
DATA "cDrQHpuje7B2LdhEP5zowZALbU603ffnq7c298aoPgG4j7r2a9F/rdaA3TiQ0n/Tg/3VgpEedLnQ5kTXsNVX1nrPrPkC7oup/bD+"
DATA "c97/nMl/e6sBqR3o9GAO/5VyIYEDa3uQyoGkPTFgftB0oelDzHDWVKZDVF847psJus8z16i6bxT/UdaAQzowt/868WBOBzbdE2Pq"
DATA "QcOFpg9tTvSN4GfITGcoboC6z9b3Ymq/0Nxfsv8a6IFb7oOzO7CU/6YHq/bEyR60udDiQ5cXo3zh8J7PfdY5v8C8Xy/+67UGbNqB"
DATA "pf03PZjkwCwejHGhy4cxw+U8wwOm92LcB6n9MNc+ku9/acR/u3VgLf9ND2apBck9aHOhz4nY4fKAJed97rP2vAD3QWu/1v1H0QO3"
DATA "3gfncKDr/qyhXDg9SOdCnw9jRsB50JoP4j5s7QfpfXvx3yg1ILUDzftQpwf79CC2L3Z50OnCkBNjhye3bXmLdh+g703pfbP5r1IP"
DATA "vLc+2PTfLjxI4MIePRjjwqAPE4cvh33eS3UfpvaLvvZR2H+91IAtOdDlv1kTtu/BXC4M+TDGjZicdeWiLXcw7qOo/fbgvz31wRD/"
DATA "NeXC6UFyD4ZcGONFTG6Gcs9X88W4j6r269F/I9WAFA7E+m94F1aYI8S83xQuhPgQ40TsgOScL1c23ot034j+66kGbMGBKf6bNSGt"
DATA "B2u5EOpDiCMx60LyyBXnNdyH7n2h/kNeA26xB+7VgRT+mzVhXQ9CXYjxYYoTsbkUygen9zK4j7T2a9R/I9aAsQ6k9l8zLtxpTYhx"
DATA "IdaHVAOaByaHkPeg7qOo/aJ638H916MDc/pvaBdWmCeMcSHWh5RujI17r/ci3BfT9zbhv87mAFP8V8uBpfw3XUjvwtI+TB3YmIV6"
DATA "j8J9ybVfZ/6bDqznv+nCPC6M9SG1G1Ni1MrEZEzgvuy1X2b/tdwD99QH1/ZfEy7M4cEGXEjhQ8rh289U76W4D1v77c1/I9eALfmv"
DATA "CRc2XBdS+LCEF6H74DxOG79C7iPrfTH+A34+uqceuBcHtuq/WRuWd2Lu4T0OF6cE7+VwX1Lt17H/eq0BQw7sxX/Thf05EbSvQO+V"
DATA "cF+V2m9g//XgQNvvtfY0qrkwpw8zOZHaj1Gv7TtmB2fb+451X7bar3P/tVwDlnCg67dZe/Hf8LVhIR9mHaFjS/BeLvcl1X6N+G/W"
DATA "gGEH+n6fevowYeT2YatehO63h12s92LdV6T2m/5rsgaE+m/6kGCUcmJOR6bsR4CP6z0r7b69+W/PDoz13/Qh0ajlxBIDcPy+98YV"
DATA "a027r6D/epkDbNmBVP4bxYnVfdizExHHmNN7NvfFzvllr/069N8INaB0YE7/TR9mGp04DuM8rPegNV/ztV9m/80a0D9K+m8EHzbr"
DATA "xAYHlKcvRpp03/RfNf9RO7Cm/0Zy4vQijlUoDjDey+U+tP9c7oud+2vYf6PUgK35bzQnjuxFLAfIe+3yXk73NVv7Tf9ld2Dr7hvV"
DATA "ib34MfXYoO9njPdyum+P/tujA2X8jTJadVxrvsy5f5j3q4T3qrpv+m/6r/Ko7as9DCrnNe2+6T8y/7XiwNbdNd3Yt+tKeC/GfaS1"
DATA "X2zvm3jtF+q/nHOAvdeALbup9ujJSa25DuO8kPeacF+DtV8O/+2tBmzVPT2MnjyW23Mxzkv1XhPum/6r7r8UB9piskXXjDB69xqV"
DATA "8yDei635Yt1H3vem9r4d+a/nGhAbty35ZI56Axs3UOel1HxZ3Df9N3QNGBPH0437HLFxQeW9rtzXsf/25EBK/003jjMo3vNS3ktx"
DATA "X7O13/TfUP6bjhzbdVjnDe2+6b9uHNiS/6Yj+/FcivOovBdyX7a+t0P/lZgDbKUGxDiwNb9NX7bnNyrnQb1X3X25az+iub/R/Fej"
DATA "BmzFU62OPbisFedReS+r+xqq/XL6r/ceGOrAFvNsjjZGrO9ivFfKfdlrv537r7casKd8nCP/SHVeLu+l9rvN1H7Tf03VgD3l5hy0"
DATA "g8J1sc6j9F4z7pv+a85/IQf2lK9zpA1K35XwXlPuK1n7de6/nmrAnvJ3DvjI4boU52G9V9R9rdV+jfhvDzVgTzk9R1nPUTgvV81X"
DATA "1H2N9r4j+6+UA3vK9b2OUo6r7b3pvnH810sN2JMHRhwlXVbCdzHOw3iP1H3Tf037r4QDbTnQkz9aG635rJTzYr1HXfM1677pv278"
DATA "V2tMR5UbH4Qjt/eadh917deY/2rPAeZ2YO48m6ON8ZFhlPBeNfcNVvvV8F+rNaDqwFz5Nkfd8ZFxxHpvOPd15r9ee+CcNSB13s1R"
DATA "Z3xkHinOy+k9lPtq1X7Tf83WgJQ5OEe58VFolPZeN+7LUfsN6L/We2CKXJwj7/goPFKdF+u9Id03/dd0DZiSl3PQj4+Kg8J7JWq+"
DATA "bO7rqPYr6b+Re2Bsfs5BNz4aGFTOK1XzdeW+6b/mHQjN1Tn69pw6KJ2X4r0u3Tf9N/03R/OOMwe180p7D+2+3mq/6b8qDlRzeI6+"
DATA "HVfCeane69p903/TfwOPjwFGLufV8l637svc+/bmv1Z74J8F/VJzfAw8cjqPwnvFar6c7hug9kvx36g14M8C7sk5PnY6cjuvpveK"
DATA "uK+l2m/6b/pvGb6c3/Mo4TtK7w3lvty1307816IDfxL7Sx3UDtjb6NF5Kd4bwn0Far/pv/z+a9EHo4+SvmvNe8XcN/03jP8oHNiT"
DATA "H0YbNXyXw3tVar5R3Df9N/23o1HTea15bzj3Far9evZfaz1wT+7obdR2XS7nUXivefc1XPtN/9E5sCeftD5a8V1O73XpvlZrv8K9"
DATA "b6r/RuyBe/JLa6M13+V0XnXvlXTf9F9X/ktxYE++qT1a9F0v3pvuq9/7tuK/lmrAnvwzXVfOeZTe68p903+78t+tttzZlq+b5d5Y"
DATA "vunLg7Y8asuTujxry3dt+WEsL5vl1bW8IZb3xEXnZwVIyS8W35aeE18xdG3xQ+JLg4dClMpvCxDDLwu+FHooPFh+sACk5+fDB6RX"
DATA "nl00PxNgVPq6wy8GXw12Nn42gGT8YOHnxxcDD0WEnl8wgWPSNw5fBD0Ujqb54fEBgq8eu3O+bPiBEjgfP2TwFWQncG2WzPxc6RuB"
DATA "rwI8O7IAPwjAKH6O8IvFl4kdgFl9fo7wc+MD00Oxiqbm5WcBGEhgkP7C4QcPPip4KFQJ/AIBmBB+EHwwemW5NcIvAl8SPBSbWH6A"
DATA "BMbzw4Qfkl4VcE3ww+KLgYfCQcMvDDCFXzQ+NDwUibjlC0UAuvjBw8+OLxB8ldEd+QEB0vGLxAeHhzr+Uvy8CRzmZws/DD4oPdSx"
DATA "0/CzAszHzx9+IHqtsPPwCyaw+wQC5ReLrx12C7+oAHTyC+jPEn4BfEF6qOO1LZ+cS3hdzg8GEJjA6PDz4wvRCx8hCFTUUoEfCJ8r"
DATA "+KLgoYjgF8EPBDA3v0DwIdmhIBTh5xNggF86Pjg91NFT8YsIwDA/SPh58LmDrw1yGj8bQEQCY/ltws+LLwwPdcil+CEC0M8vHH4+"
DATA "fCF6qMPNxg8fgAn8gvjs9BpDJ5aVnwUgNT8z/Ex82+Dz0UMdZrbFx88PMJ6fI/y8+CLYffYuoE1g+KUEoJefK30d+Cz0wPD8yHLw"
DATA "9PIzAaL4QcMviA8AD0WKlKXCDxuA9gQG87PLz0svPzk0SJVfGCAFv1h8hdEBQebnBwo/HV+QHurYs2LU+MUDhPND4HPQQx1xlsXJ"
DATA "bwswLz8fPis89zFd+BYQlSiMIX4+gCh+nvDT8JnB54fnpVaCpcEPFYDx/IL4tvQIyOXgaPILAXQksJufnr6W7PXgc8BDYcqMEcsv"
DATA "GICR4afi89BDoSmBccMPE4Bp/GD4wvAuzQVGjAZiWX5efH56QWr2BcwukuKWXxzASH4OfCa9CHCJHBP4bQAS8FPTdxN+DnwWeChk"
DATA "6RSJ+LkBhvkBws/Ep9GjYxdL0c/vJikA4/nB8DnYXfkXeogefniA/gQO8rNlr5m7Gj04OCxHDEIHwxsrwIQAtPKDhF+IHgodHCIG"
DATA "oQUi44cGCEpgFz8gPh2eweR6uyRBxBA0GHJ+JADj+HnxbeBZuCFAZmHo4mcCJOBnpK8mvxWfSQ+DDkCRnKHghw1AiAAd/Lbht8G3"
DATA "paehOe6xsiAZ+hFiGS77QBiAQH6b7FXxKfDc3EAcc4ehfHEcQCQ/Q3/W8DPxafSC7HwQsyJcXzg2AMH87OGn4NvQM9nZNM0WCMRs"
DATA "mezbu7gA1PjZ0lcNPw8+FZ6DnI9ioTBUXjEEEBiAIH5K+On4tvSc7+ftbYBhiShE8HMEoCOBrfzM9F3Cb4PPhLch58ZYGKH6YokA"
DATA "gfy24afhU+jpu6CFP1ugDPMi1F4qBBCfwH5+Kz7OT8Und8ZOzoURjDBGhQ6EergjAGL5mfozs1fgOwWffO3Nq62LlWEawgBBG0Kd"
DATA "3xZgRAKH+Znhp+M77sb6csap3gXRhpA+CDcIDX4IgAgBWtLXh+9EzwhwbdkyDCEkMaFB0OQXA9CewGB+Gj6xB8vrnLa9Tk4cly1E"
DATA "D8K8QbjhFwAIT2A3vzV9Zfip+MQLHre+dQJbNhSrEFwRbvltAMIDEM7PDD8Fn3iN40Z1ctqiMXQgTCIIRGjh5wcICEAfPzV9T+Gn"
DATA "4VvoLVuS10HVRWOoIowkmBCEEH5hgO4AdPI7hd9S96n4xJaOm1guQKmLAtEZhIUIXlqnhqAANwEI4qekr5K9Cz5Jb4W3XHk/LQpD"
DATA "A2EOgiGE9rm1xACE8VPCb8G3Bp9YW6y33PCmLCtEJ0HaLPYTFAVXOkAQP/X0oYWfiu8YfCu808Xil+N9CytDFaGDIPZcHEGQr5UA"
DATA "0JfAMH5L+MnkFcEn6CnhKhdJcUGIIKgcCS1BsRIWIDYATX5a+i7Ze8LH1hH0ZKYrywLxiHAJQpWg5VyMDUEkweM68QDtAQjjt4bf"
DATA "CR9blQcfeyp73ml+VSx8uuHIUCC0x2C+JLYjlCuFAQYy2JfAGr/T6WPhd8xets0FH3vuDw75+BR5Ixaf5RIQBcItwQJJbCO4roMD"
DATA "CApADz+pPzX8JD6RuW/878rFTPb/AuKC0CRIHIJwgqdVUgE6EnhTvyz8zPDjhYvEx+lJNS5X4cSuc4YcoSQoPWiEIAggEUFlDXqA"
DATA "agA6+C3hd8xeiY/Tk2BPR8uOaUGoElRDMCGHYwmqK0QCTOZ3DD+JTwQfo3ekumydA2BHzBEygiIGlRCMzOHoEFQIaiugAEIDUBeg"
DATA "zm9J3yX8JD72OH9wKQaPSBgNxkAlaIRgOsAogsYKIYARARjiJ9L3GH48eTm+yytO73guZuvx8GJgvjGEnCDb+SWJTYB+CcbkcJCg"
DATA "+XwygLYENvjp6ctpCXwXl9dfbr/yaBRljID04ztHuBIUIWgCNCToqaUJCW6ejgDoymB7ACrzBwa/U/ixUweLvusvd/cPT98ZS/4c"
DATA "XrYwUq8cISd4BMhC8HgaqQmQ7cb26TEAvQEI5Pf4xOV3zvGx4GP0zlkgitdmvC4+n7+/vnxnMchDcMnhLACRBC3PTgd4CkCZwKsA"
DATA "TX7H04eQHQs/lr0C39OP1/MLEYYcx7f7uy/Xl5zgDx6CIodXgEEHhgGGQ9BN0PbkLUEwQEgA2vix9GW6Y9l7cXVzx/C9fb76cs+D"
DATA "kPe8LO4evt4yggwg+08B8JTCwbOw4yxCE4JWfskA9QD08uOn3zV931n23t4/MnzXd48/3lkI3rJsvfr8/vL88PXL1edzwZIDtJ5E"
DATA "QBMykQAdBO384AB9GawG4DGB7fyO+uPpe87C7uvDd4bv6/Pbxe3D91cWfj+e7m8u3n883guAPIWZA49nYXFq4QD9hTQAYDRBaoCh"
DATA "AJQCNPgx/f14YenLwu/p5fzq6/P79cPr5d0Do3V39f789fr85UkAZA7kJ5GljFkK6VArlxMglGAEQCMAjQTm9bPwn+TH9Hd5c8fC"
DATA "7+L28e3m6dP9283D9+f7q9f7y5dv159eHr/eXH5652dhZwZvzyG2S0vRAAlDcAvQkcFaAG74ifpl5cfT9/HH+fX9j8uHz4/Xbw+f"
DATA "bq5ebp4vH69e7q/evz/cXV8wBYoMtgWgNYOjASaHYCTAQACqAhT9m86Ppe/nL4/vt6/315fXd2dnZwzJ6+XDxfPdxavI4PfXJQD5"
DATA "OdjTh0QApA5BL0DLSRgVgKsAWf2i8Xu9uH3+/O3y7fWK0ePLy8PT++3bt+vzJQBtBuSnEOUc7FRgLoBAgikANwF4FOBS/6n87r5f"
DATA "Pn25/PJp4fd69enq4fPTl8WAsoY5nYJBAWicQ2AAyUPQn8HaDXuWAFTOwBt+T6xY+Xx5jD/O7/r+duF3e3/95eny+61IYF5F8wS+"
DATA "lzMJigGNUwgUIFqCGII+gJabuxEBqCQw79/4hAE7/359fPn05enzA4u514XfJxaLjN9JgCyBN/zAAbjNYDKAIIJ+gM4MVgzIA9BI"
DATA "4KMA2ZTBNatfzq+/vd2+Pz28LPyuXt8uv31+Psbfwk8RoJbAmgFpAFKHIBwgIADFGVhMIBwTeBHg88XD5St7NqN3x87D96+3749f"
DATA "Ph9LaMlvEaCch3EFIAig14HJIejLYTxAeQo2A/Dpmc9Z8QB8v7p/uXq8fL55ubr59PB2/fj54fLH/fX5j0feBOv8zASGBCARQJoQ"
DATA "BAPUTiF6APIWhAcg6+COBrz+9nJ5/3p1//z94ebt/tPTzdvj7cUbq194ByL5rfOABj94ALoAAiUYH4IAgFYFahlsMeArn0HgHTCb"
DATA "QHi/umMx+XB3+fpwzTrgK94B315fsA7uxM8UoPO+jlSAySGYAtCewcdTyOkUzDOYnULEzB+bu7q5Z9OA76xYeWCRxyYQPrPwk3NY"
DATA "/Pxr8DMSOBCAZADtEYgkGAHQmsGihjnOYT2/sHMJe5B1aXzu6o7hYzNY6ySq4LdczdzyiwvAKIAOfpCJ/WiAGwXyWYTjJP46ifr1"
DATA "eAFJzD6LmT82Dfjt7uaKpe9xFn+p/0D81AAkBujkBwhBXw47ADrOIWwaa7kKImbxxUUkPqfPj59f/Lhg035P376yqyCfOFCmv+NV"
DATA "kC2/VYAygV0BGAPQQtD3tT5JIegGaJ5D1ptdlqvA/Crm+fEWBH4Q15d8zuo7m3IRF5H4hcxj+q4XMg1+wACkAcguAacQpAMoz8I8"
DATA "BJebYNZrv3zC4HgNjmXvMfxi+LkCMAWguAmhKkD1JKLeR3S69+CZz/exE8klk9+b+KeoXtjRmfxsAsQFIBbgchsMLUHLWSToQOVa"
DATA "8PEWcuXWFzFZdcWjj+FTw0+5HWvDzx2AlADXG7EwBGNC0HsWPhbS681E8lMM4sD5nVfHWxAYPnEXx9F+8vRBwc+dwRaAGkHlVsBo"
DATA "gpEAzdnoE0Hzxj8xT7DeBLOG35q+W36OBI4IwABA7WZUyhC0A3RLUN7vfLwhVb3xVN7swk4dCr4lfYn4RQM0bocuFoKKBFWC6qcx"
DATA "+cL+YzlDsOA74ZPhJ9LXxU9P4EwADX4UBJE5rN9UpHwe/XjXvZwe4GiO+I7ZK8NP6k/hZwrQE4DJADf8MASTc9gkuH4oWPnUh7xJ"
DATA "jdE74bOFH4gfLADhAC38CAjCQ1AnqH4llvzMEQcj2jLGY8GnhZ/K7/T5uC2/lAC0ATwStPJzI0Qnsb+W1m4NVL4aQf/IG89cEXzc"
DATA "fQq+09kDz88SgFEAXfzgBNOS2Ph4w+mbPddPXC4zejz4FHwie5Xwk/oz+QUTGJjBLoBufskEA0lsEtx+ubvC4khvwSfkJ+0H54cL"
DATA "QCBAHz8ygnL/bAQ1hPaPm3MISyei4VvDTzl9mPVLmF8aQD8/aoLLHlsI6r8zcFrWW1lE8K3Ju+I7hR+U3yaBoRlsBQj4Wv5sBE2E"
DATA "ju/aOB75GnwrPjX81vSF88MHoA3g+gHRYgS3l+eMr0zVluWwxdGq+NbsNdLXzs+fwCkZfPwWokiCG4Qogvp3Wy0MzWU54IWeiU8J"
DATA "P/304eMHD0AAwPWLsIiCMEDQjtD2813qwR4PURyOgm8TftH8EjJY/S62KgStP4KmHKY8vCX4NHzb8EPxiwjADUDj6wCjEHpFqLz2"
DATA "BqHlK/C0ZT245VBExarhi+KHCMAgQPP7FPMGoQWh5UeZlX+uR3Tccy8+NX1P/NQTMCiBcQA3/KiC0EXQdteq7/tN5TEc6VnxWcIP"
DATA "xi8qAHWANn5hhGlBaP8MrGU5HQHfgqR3wrcJPy19Y/mhADr4RSL0mtD18QcbRn3vF3oaPi17g/wwAjT4+QG6+WVB6GNoLurOnuht"
DATA "8Jnhh+GXDtDLLw/CwBeEaju8whM36mzwucLPxQ+YwIgMDvELIoSpMPBpOuuyPNOkZ+BTwy+FX2QAAvgFEQKjMPjBdsvbe1xRbM+N"
DATA "b5u+Cr9TH41IYDhAGD+yMIz4KZnjlgx6VnxG+CH54QJQAoTzo0OI+S2jEz0nPm/4RfIDA8T+pLMfIfyyk4Oj9tdl5eOWxaur+Ozh"
DATA "h+UHDEAnQO23EjOGYfQvuBn07PiM8AvzowhAAfD0S4QYgrEMsT8huGxOp6fjc4YfLT9XAKq/5Vgml90gjWfI7RxfzIcvhV8iQJ0f"
DATA "OcPkX01dXub0HZ4AfB5+cAECAW754SGGGMb/bK+DnsCny88Vfih+6AD84uJHzxDA0Xi23LRC7xR80PBz8SMKwC8efmiGWX6ifNkR"
DATA "EL7M/GwAA/wiICZTVDYl90ChZ8dnfrm7qT8gP3wAQvjFQIykqG5hfekjPQc+WPjR8LMABPOLggjnaK52ek2NngNfEr8kgAh4KRQd"
DATA "LB3PU17LSS+Ar2V+aRBDyxYeEF8GfmGAcGAFMOqbttPT8FnCT09f8/S7/fkugx82AMGgMmM0N7jCk/SC+EDhZ+WXEoBgQtk4WrZy"
DATA "gmfSC+LLzs8AKHYSSoeQpXs1Bd5KTw8+HZ8te830RfBDBqC6tyAqWRd1b07wjOCz4ivHTweo7XFdjPpebOkh8CH5JQC08KuAcfPi"
DATA "bnoGPlj41eBXCKTlBU/wIvGR8vMDBPDLBdL+Iiq8LT2Jz569KH5OAYYDUAEIREfJ0rNVDd6JXgifK/y2+ovh5w1AEKxknqBNuOBt"
DATA "6TnwAcLPwQ+bwCeAoCPLv+jsNHpufK7wS+WHCUDUUWZaTHh2embuhsMvI78VIOpAC6DT4VnohfEV4ScBoo42OzsnPQA+T/hh+SEC"
DATA "EHXEedEZ8FR6HnyQ8Avziw5A1GHnI7eBZw8+Dz5Y+kbycwNEHXwecCF6yfjw/OABiGJAj83KToOn0LPgK8XPCVAcAIoIDTM3PJ2e"
DATA "Lfhg+Ary8y9EoGDwnPSA+GzhB+EXEqALIOpwSRcLOw89P76Y8PPygwUgA4g65LzsTHox+DD8cAnsCEDUYedkZ8Jz0FPw+cOvCL/b"
DATA "wvxc7Pz04Pis4RfFD5rAqMPPg24LT6cXhY+enx0gikEGdDZ6zuCz40OEn4dfZAKjQJCjs8FzBx8CXzo/IEAUDVJydngGPRS+MfhB"
DATA "wLng+eip+DDhR8fPBhCFhgacE55JD4mvV34Ybh54fno4fK70xfCDJTCKVBo2L7wNPXfwOfChw8/gFxeAKGTx1ALwAvSc+ADh1wA/"
DATA "FCI8Owu9CHyu8IvnBwKYFVkkPIMeGp8z/LLxQ7EgZAeh58ZXgd8GIIoEMTsrPW/w4fH1zC8AD0IvBp87/JD8IAmMAkKHzg5vQw+K"
DATA "Dxh+BPxMgCgqVOwc9FD4YOHnS1+TX1QCo8jQsHPAC9Hz4CvJzwCIokPADk6PHh+aHyAAUYRS0TnhWegh8NXk9/+SW6xT"
DATA *
