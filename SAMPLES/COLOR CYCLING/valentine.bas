' valentine.bas - palette color cycling
' Exported by DRAW 2.5.1 (https://github.com/grymmjack/DRAW) on 10-06-2026
' 320x200, 49 colors, 4 cycle range(s):
'   1: 1-16 FWD 8.0/s
'   2: 17-28 FWD 12.0/s
'   3: 31-38 PING 7.0/s
'   4: 39-48 PING 9.0/s
' Keys: SPACE pause/resume, + / - speed, R restart, ESC quit
'
' How it works: the art is drawn from a 32-bit image, then an 8-bit overlay
' holding only the cycling pixels is drawn on top (overlay index 0 is clear).
' Each step the overlay's palette entries are rotated with _PALETTECOLOR -
' the pixels never change, only the colors they point at. Speeds use the
' DeluxePaint CRNG unit: 16384 = 60 steps per second.
' Compile: qb64pe -x valentine.bas

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
_TITLE "valentine.bas - color cycling (SPACE pause, +/- speed, ESC quit)"

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
DATA "eJztnTvMLEeVgP9rY64v1xhYvC8WYxvf9wPtIyFwsBJgAiScgZYEYpAuGRCQQLboRgS2tBEJOYK10UrIKU4AyQkJOADLIbaQNkFI"
DATA "Q9V0V3d1dT3OqTpVdaq6Sjr3MdMzU/31qa9Pdff0fPYz//WZSxf/eemNi3+7eOrihdMLTz04fe5j3z198dkfnL5085XTV+//+PT1"
DATA "T//k9K3P/uL0vZd+eXr4lTdP3xd/f1v8/xvi8a+J578slntJLP+ieN0nLh6e/v1D/3d68RPvnB584c+nl79zOr32o9Ppt2+cTj8X"
DATA "f78i/v9N8fjnxfP/IZb7//dOp1+9/p543zdO//vw7dPvXj+d/vTW6dzeFX//Xvz/VfH4yw9Op5/+8HT69Wun0x/eFM+9czr99S+n"
DATA "03vi7z+K//9GPP4z8fz7Li5dfFjEfz9+IdrpJP/8yMXHRfzqifWRZy5uXDx98e3LFxePzI/cvPjXi+sX/3NlfUSuPUVIgpxCbs2c"
DATA "ITOFMmTWxYbM1piQGY4JORqgIUcNJOTIgoYcgdCQIxUTclTHhDRJbEgDUYU0We6gcgUn53Ds0xEdmOK/WAcO/6X5L8V9lP47mvso"
DATA "HdFCH4cDh/96899wHw+ntNhnbh48igN79d9w3/G8V8p/w4HlHMipBqzpv9y1nzxaP9xXJnI7oad16cWBPdSArfgvpvar7b8juK+U"
DATA "D3pet+HA4T9K/0nvmTHc17YbjrSupTxY24EtHQNs7dif9FhM/cfdfTU9UNMFR13v4UAeNWBLc1/lst7qviM7oPa6c2DA2YHDf/z8"
DATA "V7r269V9Ncc8N//16kFODpTfQIqNFv2Xsr69u++oY5y7/2oz6smBKeM/FLH+k3PHXP7Lub7Dfe2O6Rb9NxwY50DX+JXfQKcIjAtL"
DATA "+K/0ukJdONzHYyy37L/ePJjTgTEekHfwCAXWES7/2a4difUfh/X0eZCj+442dnvyX02W3BwY8l6KAzAB9SBF/Qf1Xu51dK0rpf96"
DATA "cR8Xv/Xkv+HA1YEQ71H7IMaFFP4r6TyMC20eHO5rx30yatbGLTHm5MDSdVCsJ1wOxPjPto5c1s/mwCO7j4vTsP6rvb9oiXltB3L1"
DATA "XqwHW/EexoO13df7GKQcw1wYtrQNajjQV/OljmV5N/NQpHrC5UCI+ziul8/zGA+27D4uPksZt9z2Ja1sj5IOpKz5IE7ARIwjfP6L"
DATA "cXuNdaKoBYf76o9VrnyP5kGs+2o6L9YbNge63NfKOkFqwdzu63VslRiX3Hm3sK1yOTDVfaUcgXGG6UCs+ziuE9aBLbqPk9sox2JL"
DATA "+54a207+Sl8O7hAHxrqvliOwHpTrpruv9XXyObBV99XyWE7nUfqvFQ/m9h+lB2u5T/5SKySonCHXSfrPt25c1oHCga2NtRouKz3W"
DATA "KPdHPXlQes+MUtvFNu/N4T2oK6hc4qoBbevHdR0wHrTNg1sYXxzcltt7ufzXigsxHiy5jXK7j8oXsR6xOQK7PrXXoZYDuYyJ1p1X"
DATA "yn89eDDWf7HbDTvv5eI9jEd8/muh/xgHUsyDa4+BHr1X0n/cXchlG+ZwXw1vxHiwxf6XcGDruc/ReTX9d1QPxvivlvs+/4l3QJHq"
DATA "kND61O5zDgdi/Ndqrrfgvdr+4+zCGtuX0n25fEfhFpszYvpfss8YD1I5sLXcbsl53PzH0YOltzmV/0o7L8YrPv9x7TPUgan+azWn"
DATA "W/MeR/8dyYO13JfbIVCnYPrPpc+5HdhaDrfsPc7+4+jCnLkA9V9r7gs5JdR/bv2lcKDLf63kbA/Oa8l/vXuQovbL5b1vfuHPoEjx"
DATA "iq3/tfuI8SBFDcg9R3v0Xmv+4+TCGv6Lrf1yuCTVNT7/cekj1IEUNSDX3OzVea37rycPQvyX231UTsF4BtPfGv3L6cAc/hveO57/"
DATA "Wvdgau2X6r6cXoF4JtTf2v2jcGDuGnB4b/iPiwtz+C+m9uPmvpADOfcP6sDSNeBw3vAfRw+W8l9s7RfjhVe+cwJFjGfM/tbqE9SD"
DATA "VDVgiv+G94b/uLsQ6r+YuW8J90H9EusebP9y9yenAyFzYK7ea8llMVHid0iHB8vUfqnuo3AMxjuQ/pXuU6oDc9SAw3u0od9jvfRv"
DATA "Mh/RhbX9V9N9Iee4+lerP1AHlvLfcB6986D+O4IPa3kw1n/UtV8Jz/i8Y/avdn9y1YBY/w3v5fFdiv969mFpD+r+q1X7YT3x8x/B"
DATA "ItY5pfuQ6kCqGlD33/BeXt9R+q9XH5ZwIKX/croP6psYD0H7k7MPORwY67/hvPy+y+m/3lyY23+5574p7kt1DtRDrv6U+nyoA0vM"
DATA "gYf3yjivhP968yFX/+Wo/XK4x+UgW39Kfn7JGrC0/1pyWynf1fJfLz5s3X+1vAfxUO3Pp6wBa/qvJceV9h0X/7XuQ87+y+2+374B"
DATA "C4yDSn1mDgdy8V9LrqvlO67+O5oLff4rXftRew/jJd/n5/g8qANL1YCp/uPuONm4OY+7/1r1IQf/5aj9UjwU8pLt83N+HrcaMNZ/"
DATA "3L2n+4+b81rzX4s+bMV/pbwH8VLpz6OsAUv4rwXfKa/Y2vDf8XzIwX/c3GdzUunPS3Fgaf+14DtXjPpvuNDmQc7+wzjlNbF8KEJO"
DATA "yvn+UAdy9F+rzhv+Gz4MuTCH/zBz35TaD+IkqKtsn0f5/qk1IHQOTOW/1n3XWrTksp58mOq/WrVfipsgjsr9/iVrQKz/hu+G/47i"
DATA "wpr+i3EfhZd8nsr9/ikOPIL/WnLW8F/7PmzJfzncpDsq9/sP/w3fDf/x8qHv/i81/Jda+70s3jcUGP/Fvl9qDVjDfyoXOPju4Vfe"
DATA "YO+s4b/2fYi9/1Ut/1F4D+Mt6vfD1oA5/ef6/lsO/8X6YPhvRAkX1vIfZu5L7Smft6jfD+JA6By4Ff+leEB6zwyuzqKMF556UNQb"
DATA "v3v9xMZhlOuU+xhgTv9haz8KV+nOon4/6howl/9Sj/3l8MHR6j/pv1BQu4Kjw6jXKbf/INf/pcx9c9d+pf2HqQEhc+CY6/9S/VfC"
DATA "B73573sv/dIbEP9RuFE6wgxuHovxHnSdavgvpf6Ldd8D8Zm+gDgs9T2o/Qep/3L4ryXPcHZcTv9h/XiU+s8Xuc4B5/ZfqrdCDkt9"
DATA "fciBJf0Xe+63Je+kxp/egn03LsVvtf1nhnRFjnl1S/5T0Yv/MN6yeSz19T34j5OXavgvp+M4+S+lduwxKM+BUPkPW/tx9B/UgaX8"
DATA "55v7tuKrlNCdI71nxvDfMf2Y+xxwbv+luIsqSvuP+txvSx6D+A0aNb3Xg/96cCNmDszNfyEvvSj64wqK5UMO5O6/1ua+1O4Z/ht+"
DATA "zH0MsIb/fB6zeQ27PDf/9XLsr7aLhv94RA0H5joGCLkGcPiP9to/znPfltw0/AeLVx++XfTzataAOc6BxPiPwn2xAXUghf9ynfvI"
DATA "Vfu15B4OUdIbvfiP2o8p/qOYA1P5r4T7fA4s4T+q655j/deSW1oITt6I8Z4Z3PvMYQ4cc/1fqv9s3/3HPE/hP8j1fxzmvi35o/Xg"
DATA "7guoB1vqry1yzoEpzoGk+M/mNt1xoedz+a/EuQ9f7deSJ3qNlhzRs/+UA7nOgWP953MbNEr5r+TctyVH9Bwt+aH34DQHjjn/W9N/"
DATA "kPO/nOa+LTmi52jJD0fwX605MMU5kBzuczmQ47mPMfdtL1ryw1Ec2EoNGOs/0xE+Z1D5b9R+I4b/2vAf1xqQYv5r+25EyB0x899R"
DATA "+40Y/mvXgb3WgBT+G7XfCKpoyQtH8l8vNeDw36j9OEdLXjiaA49YA/Zc+z38ypsjmMWLH/vuCIZx1Bqw59qvJS8cJVpywhEdeKQa"
DATA "cNR+I0pHSz44ov+Oci6493O+LTnhSNGSD47qwF5qQOg10b24b9R+/KMlFxzVfz19JyTmfgetf9ejJR8cLVpywZEdeITvBff4Pd+W"
DATA "XHDEaMkDw4Ft3BsG6kDlQddzHN2Hqf1a8sBRoyUHHCFeevYH1mjt/oAYB5ZyX+l57/df+qU1WvJD79GSG3r2GyRau0e0zYEhD9qW"
DATA "j3Ff7Xmvy32QaMkfrUdL7sgZslG9V4rjoA7kMA+mdiBn92FqvxT3DTeWjVJ+6cl/Of0G8R+n34pLcaDyoOu5Uu4rNe8tES25h0Nw"
DATA "8U9N75mtpt+4zYMpHejzYMh7VO7jPO8dfhz+KxWmU1rwHmQezMmB2FoQWvNxcl+peS9nN8rG2XFH9B/WJ63478s3XzlH6d8Mpnag"
DATA "6UFozVfSfdh577c/+4tztOQ8Cj8O/7XhuFZDOc+MlHkwJwe27D7lP+U+M1ryGzZsrSX3cfdfS44q4TtqB5oOyO1AnwdD3svpvtRj"
DATA "fi73HcWHsoWWGf4bfqPwHVcHUtSCKTVfC+7r1YcQ/3H143Bce76z+Y/yfEgJB5oeTKn5SrrPdcyPKkq7q4Xg7L+WvNOT8zAONMd0"
DATA "DQf6akGo90q7D3q+I1e05KhW/Tgclydy+07F1+7/eIlWHdii+77x6Z8skduDw4f53Dj81pbvbN4zHQg9FkjpQAoPpnovt/uU/3T3"
DATA "1fDg8CFdtOQYTlHadz7n1XAgdS1IXfOVdl9tFw4fDv/16DyM9zg70HduBOq9VtxX24PDhcN/LfsuxXtcHIitBanmu5zcx8GDw4fD"
DATA "f634jsJ5MvRxV8qBFLVgas2Xy30utq26cPhw+I+L73J5j9KBJWrBEjVfqvt69ODRfdiSr4bz8O5rwYGtuY/SgcOFw39H8V0N79Vy"
DATA "INaDMd6r6b4jePAIPmzJZa36jtp5sWNO5nIuB1LUgqk1H5X7YrcXpQe5urA3H7bkttacl8N7MePMzF+fA0vWgjnPcUC9Z3Nfyvaj"
DATA "diBnD/bgwpY814LvOHnPN3ZyOhB7rWCtmi/kvpRteTQPturDlnz36sO3D+e8lLEUylUqB1IdF6So+ajdl7ptc3iwFRe24EPOvjOD"
DATA "q/9a857pQMy9s3LWgjlqPp/71Lpj5hTDg335kLvzlPfM6NV5Jd2nckB3YK35cI35rnIfJAc5O3C4sD3/xThneI/efTkciPEg9J4t"
DATA "1PNd032lHDg8yMuHnH3HyX+cvZfqPtODWAdS1IIl5rvKfVS5Wnub9+rBkj7k7Lvakdt5pb0HySl5T8jQMcFc50Zy1HzmsT7o/S5L"
DATA "5kluD/bgwlw+HM6r4z2u7lMROx+OvVYwd82n3Ie5p3lvDuzFg5QuHL4r6zyqXM+RL+a9wakdaPOgzX2Ymi/GfT7/yVbLgSU92JML"
DATA "U3x4VN8dxXux7nN5EDMfxh4XpKj5bPNdzO/amP6LyfvhwXZ8eDTfteq9Wu6T8T2xTIn5MHXN98JTD8C/7WVrtR04PJjfh8N5w30h"
DATA "96mAOBDjQZ/7Ymo+030qML9vaKv/juTAo7mQs6+G9+LzEFr/Y/yH8SDGgdQ1nxlU/outD4YH+QZnb7XmPOoc5eg+ilrQdX4j5rqW"
DATA "kPtiHBiK2vlYw4O9upCzw1ryXm/uC/nvW+KzZFB+byS25vuc8JeMFP8NBx7Tg5xd1oLzcuRibvf9/vUTifswDrR50Oc+aM2n3HdE"
DATA "B9b2YA8u5Oy14T1690m3hfznc5/Nfym1INR9Ie9B/MfFgcODw3/De+XdJ71nBqX/UubDFO6r4T9ODhwe7Nd/tZ3Xuvv0Y36++i/F"
DATA "fV8X66Ii5EGI+0zvfVG4RsVwIF8HtuRCzs4b3qN3Xyn/YR2IcV8J/5V04PDg8B9H5+XMoVruy3Hcz+U/3YM+B/rcZ3oP4r/hQJ4e"
DATA "5OjC4b3yOVPSfRTXuqT6z6wFXed2ze/uutxH4b9c82CuDhwe5Os/Tt7jXPPlch+F/3zuk/FVwTXkQN19XxJ54fNf6hw4Zw2Y6sCj"
DATA "1IIcPDic10bNx9l9If9J9+lhc6Byn/SeHhxqwN4cyNGDtVw4vNfGfchzua+G/0wHutxXy3+/E+eHjuDA4cEy/uPkuiO4j1Pt5/Kf"
DATA "7kCX+1LnwLEOpPTfcCBvFw7v8d5uOd1X238ypP9c7ivtP+k9M7g4cHiwDf9xclytbXwk96X6z1f7UfgvpgZ01X9HcCB3D1K7cHhv"
DATA "uK+m/2Rw8J9ZB+Y4H9KSA4/iwd69V2o7Uu6TcruP0n8h9+X2H9UcGHMumIMDRy1IM/Z6dV7JbVfbfS3XfiH/1aoBc/qvNQe24sGY"
DATA "sTi8dyz3Df/xqAFbdGCPHuzFeS17r1X3teS/Hhwoj0sOD9KO1R68N9zHs/Yr5b/aNWApB4b8NxyIH7fDe226L2ftd3T/la4BQw60"
DATA "XZfIxYE1xiDlGG7ReT14r3X3tei/lh0Irf+GB3HBxWecGbfuvuG/Mv4rUQdi/FertuHitt78V4PPcF+8+0r67ygOjImjjNVe/VeL"
DATA "jXTVqw/fZuO+Hms/iP+OVgP24sCaY7cH/9ViovuK0n/c3Tf817cDhwfb8V8tHrr3zGjNfS3MfSn9B3Xgu2+dsvtvOJDPmG7JfzVZ"
DATA "2LxFUf+14L7hv+HAI4xxrv6rycDnriPUfRj3tew/6T0zjuzA4cH6/qu9/qm1XU73Df/lq/9KHQek8l+vDqztgOG+4b4c7qvlP4gD"
DATA "lf+GA4cDh/f6cl9rtR/Uf9Q1YGn/teDAI3rwSN4b7hv+S/XfcGBfruhpXXpwX8l5L9Z9PfqvtAOp/HcEB5ZwR+v9H+7jV/vV9t9R"
DATA "asDhQL7+O4r3juK+nv03HHhcD7bQx+G+4b/e/DccyMMxHPt0NPfVqP2G/9L9x6kGPJoDqZzDpR8teY+T+zjWfhz8d8QasIQDe6sF"
DATA "a372cF8d93Gq/TD+67EGHA6s68EevDfcl9d9R/HfcGDbDoxxU+vuK+U9avdB/feb106b+NkPt/Hyg224nPdr8VoZf3hzG+++s42/"
DATA "/mUb74nHUua+et8g/tP7pj/u658K3X1/FK+XIZlBvKf6+FPBVPea4hbDr6b/Sjmw9VqwVe8dwX2m/0Luk2PX578Y93Hyn899Nv8p"
DATA "blD/SX4+/2H51a4Bj+xAqLNa9N5R3Kf7D+I+n/9i3UflP9k3jP9kn/THQ+6TvtP9p+83IP5T/Fz+i+HHYR58dAeGHNaa947kPuU/"
DATA "5TzIcT85ftWYdfmv5Llf3c0qZN/0ZVxucR3/c9V8Lv/p+40Y/6l+lTgOOBxY1oOj5uPrPhn62IX4T5+v2fwnvZLTfab/bO7z+U+v"
DATA "qSj8Z9bNIf/JvunnQfS+lfJf6w5sqRZswXs9uI/Kf6Fzuz7/Ka/U8p/eN5v/zDllyH/mnNf0n+2Ygc9/qm8p/uNcAw4H7l3H3XtH"
DATA "dp/uP9+5Xdd5Xv1x3Sul5r66/3w1n+s8r+saGOU+n/9cNZ9+PFJ/XHezfi2M7uaS18MMB5b14PAeP/cp/4WubXGd5+Xiv9Cc13We"
DATA "1+U/5b5Y/yknQ/2nuJX2Xy8ObGk+PNzHx30yINf2uc5z2PwnvVJq7isDMud1neel8J/kpl8Lrc/Hbf6TfdL9p+83Sl8TPRx4TP/1"
DATA "4j5q/7nOJbjmvPr3PSDXz+leKeE/23E+jP/kMT6f/xQ313dBXNc268tArxFS/Cj9J397MKf/hgOPee+CVtyn+w/iPp//MO7L4T/Z"
DATA "N/1x13kOvX8+/6nzuy7/6fsNiP/0utnmPyg/yhpQ+a83B3Ly4HCfy11vVHef8h/UfTb/qbksxn3SK5T+U32D+k/1y+U//do+Cv+Z"
DATA "1x+a/sPsOyjmwdJ7ZgwH9us/bu5L9R+V+2To3oMc/9O9YvOfHK+5jv3Z/Kd7BfL9D90rFP6T3CD3Q9CPR+qP697DHv9LrQH1+m/U"
DATA "gf35r5b3QnWfGbX8p77PEes/3Wd63VLq3Edu/8ljfD7/KW5Q/ylu1P6LdWBp/9VyYE0PDvfR1n+UtZ/uP/N65pD/zPO8uldq+E/2"
DATA "CeM/OZf0+U+d33X5T99vQPyn7zds/pN9Ku0/V+T0n3TukRw43EfnP2r3+b7P6/OfGrOx/qOa+5rneaH+U8fSXP7Tr+3D+M/nQJ//"
DATA "FLcU/7XiQOm/VupAOUZb818L7qtd9+n+c32fzRX6fM3mP3Vut5T/dK9A/KefS6Dwn+SG8Z/kpj+u7zc4+Y/agbZzLtwd2JL/anqv"
DATA "VfdR+0+/tqUH/6lzuy7/KW5Q/yluufzH3YF6/Vf7eKDPg7Zj9Jz917P7cs17bd/nhdx/Tj/nq4ftGhfovVUp/Cf7hvGf7JOr5nPd"
DATA "/1D3nL7fgPhP32/Y/BfDr8V5sOk/rg5spf4b7kv3H+bemxD/Ye+pn+o/1Teo/1S/XP5z3fsV4j+XA33+i913tFoD2oKjAzn7r7b3"
DATA "enCf+X1eyH2HQ/7Duk96JcV/et8g/tP75przur4TaPOfZIbxn/Sd/nhK3dzyPJibA0O1ICf/DffR+Q8bkGtbSh37g4brOF8oXMf+"
DATA "QuG7DgYSHI8DDgfy8N8R3Feq9hv+69d/rdaAvTmwJ++16r7Wa7/W/DdqwPYdSOXB4b4+3Df8N2rA4cDy/hvu4+G+4b82/TccWNeB"
DATA "w32j9kt1X4v+GzXgcGCs/7h4b7hv+G/UgMOBKR4c7qvjPk61X825b4r/as+BudeAw4G0/hvu67P2G/7rtwYcDkz3Hyfv9eC+nmq/"
DATA "lv13lBrwqA6EeHC4b9R+w3+jBjyqA9+3a48B2vsd7bKlPb5tVzbtA1q7urYnlvbBtT25tg9p7cObdmnbHtm3R11tjwIAB7RQEkCD"
DATA "3xYgNT8Dn4VfCj4LCPCCZABL8iPFZ+WAWhhCMB5gHD8afJH03PwyAgQkYICfK/2eL47PzQ9AEAwQnYBwfpv0C/GLxudmEPkyOoB0"
DATA "/J6XLQc+H4KEl7oJYkZwQIAY/V3a5B8UXwq9IL9aAL38XPg2/MrgC/ILvgEQYBF+vvSLwxdYeQi/OIIAgBfbhuJnvDYWX9qKQ/mF"
DATA "3igCoLH+qm35PW/n53gtOT4APSg/WoAOADpCJz/va8vjg/KLIegAuFnjv1PNQCjpybblF3zlTBCEL2V1I/gF3hICcEtvAaC1leAu"
DATA "/1Z6vhdOBJPxQcih+REA9MLbkNjxg75QECyI7zHQUS/QGwMAhumtJIz9L/h1oiXiA3Fb+IW2RRpBG74AhS1BOD2NYAhf7ApaVhiQ"
DATA "zfAP8AJ00PuIansSC7/96xyv2hNE4gNh09cWsklIAFrwLRC0ZgLc4fO+aAcwH7559YBZnUBQxxeAt6VxBjjhg79oIejCF7dazrWE"
DATA "vjf4o+wATXxuEBoMCVDHB3qRDhCFDwRut4qIzeP9uGf9ALf4/CA2BAU+7ItmgDh8EG621cNsId8nrvwsBP34Pr60PQzBb/8a+wt2"
DATA "AHMk327VLNsoguCzsrk/ZYPPwW6PZAaxfY3vBRpBK0DAiiDp2fnBEdrzz/wgF749iy2RMwj9NaEX+AGGVwILz80PTXDLb/tpOr8w"
DATA "PY3IzA+8vAZwxy+0AlH0PPygCMMfaMXnpbEhiFreCRDbfRC8AL80ght+fnz/sjQTiHpNaGEHwNCKpNIL8QMi9H6uBZ+d3Q7LGcZm"
DATA "ec/CGsE9QEy3EfAg/GIvrFk+fM/PB29DZeYHW3gFaPLDdRpDD8QvgaAfnwvICkVbPrywCyCmw0h6QH4ghI4urPww+BQUtTxk2R3A"
DATA "iR+8s2h4CH6xBHfpZ6f3saUZVM7LhxbUCO4SENrRKHoYfgCEXn7b9LMiMdHM/MILrgB3CQjrZhw8LL8Iggs/F749FI2Mtqx3OQdA"
DATA "Kz9Kemh+WIJm+pn4HFQWMmrZ0HI7gK4EpKUXwS+MMJx+EHwKIHC5FaAvAYnhRfJDnHs2+G3Tb0Phn5e2ISOX9S+0EtwnoMGPnF4s"
DATA "vxBCnZ82fJ34Vi5bPPpyrmUcAJcBDKOHgqY15xlSEoLW9DPx7cBodJblfAuZAK0JmIOeOLDuO8mchDDEL4BPwZmW8y+zAnTzywJv"
DATA "5RfN0E9wy8+Wfk4yMx25XGgZewLq/KjpqZOyG36RDH0Eg+mnk/inpW3h+BYwAdoSkJjeys7CL46hE6CFnwPfymZDaF3GsYAV4JYf"
DATA "IbwtOwe/GIQQfvv0c9JbCU3LuJ9fAToHMBW9PTwnvxiGMH7W9LPimQCdl/E870lAHz8UOBc7Pz88Qyw/P72FUOh5SwIG+KHQudmF"
DATA "+WEZAvm58P3j0jRA7ietAMP8yNjB+KUg1E9/O9LPRk+jND9vfW4F6E5Akx8U3HMQeFB+OIZBftb0MwgpSufnHc9BEnDLD0pP8IPA"
DATA "w/BDMYTzc9NbKPmesySgkx+Y3eXLz8lGzw/BMMgPgu8MyfecAdDHD8xualnyD4UQwU+D8g+qKUiOx1eAIH44eJn5gRna+WnD10i/"
DATA "BdKK6vyc5XEzAdcBvOeHZYdpKGhohiY/f/oZmBZQrsc9Cajzy8YulV8YYYDfBt+O0kzK9bgBMJofChc1vwBDBD8rJgHK9TgJPxSq"
DATA "XPw8DCH8zPT7e9U0ftvHzASM47cyeBrBKxM/B0N9/ubnt6On0bI9piegg5+avwXzjgk/C0I/P2342kjNtGyPLQDXAQznZxB4WjYw"
DATA "L7PZ7rCl2jMgZuaLXAPYwU9Pvx0qAcv2mC0B7fxMfFYGKfnnvl9FLD/5h4vfUv8Zw9eVfj5+WgIuA3hT/5n8nAxi+Knv0m/vuqBj"
DATA "fEY2MLb9i7z8jPzb4ntqbgsw8wEbv339rPNDsQGBc/DTOcbn39zsO2AXP5OWAmb+XwH08NvuflF8tu1ZF7cQP9mesY5qBL9HHsHz"
DATA "02idiZn/R/ODonLxc4AD8LMOa2Sz7ED2/PT0A/FbAbr5peITcM5fqyLhF83RtQN28TNw7ZuPn233i2I2c1tbgB6aHxojkp+i9NGp"
DATA "7f6tAObgZ8OTiR+co0uAXn4zsTM1/d8Qfnj9hRBl5AfA6BDgUgAS8NuVf0B8KFBU/K4hOYZ2IBt+O3zbtgLc8cPsPlCASvKzcfTN"
DATA "QOz8nPhmgE5+tuo5F7dIftdkgy4cHMCb+s/kd57+a3/v+C31X3D4oohk5QfLv00L8FsS0OB3xibAqb/t/Jy7j5kfigVPfgIgaABv"
DATA "+c3Y1ubm5xm+KBRl+OEbYABv9r8Bfsv+FzB8USga57ckoBXfBBC0++iNHyYBt/wkCHUgecePBT6u/M4Az9MIhWMzfo/FLzYBd/z4"
DATA "4Rv8WuCXCDAS3/aXbjK17a/f5GqDX0WAnPEx5qcAxu58URi484sGuJ97sMLHjZ8V4A7fAflhEtAAGDXzRUFogZ8AqPMDAvyoduAq"
DATA "iE/jh2LAnd/0UyeY44AaQDc+X/pNv8eCIsGPn/4zY2GAmwPRmyPR29NGkMPO+q+i5eWIAmJtzwXBrQCDI9gGEIhP42fgy4kxAAfH"
DATA "z8EtkIA+gE+ZJy13+ADpl5MjEJKbnmwBbpARbAG4Xssx/XeHDzh6s3JEwdo1CQVMbxnBAICbqzm2Z8z9+NyjF4jxOTC6BH46Ezi/"
DATA "80/IOBVoAygJrsnnwaen39WrKHwGx7z8wKws8Oaff0ICjMAnG4rc2s46ysAPhcrBzgZwcz2WAdD81ocdnyk/7UcgUeQWgtt0TOSH"
DATA "whRiBwO4v6J3Sw+ML47hwg/GMR84CzuNHwygJGgknwefjV/CWAZhzMLNCc9IQC/AOQVXej58rvQjRWjjmAGch92TT66/JwMEiML3"
DATA "xBNPuAhSMtQw0nLzszvTCwLcETTpefF5CRIzlA2FJondDM8L0JaCtuTz4QshpGWIwpMAT6MHBDjvRlZ6cHwhgoQIUYRi2Rn0wgA3"
DATA "3wzejV0AviBBKoYoSnHsdvA+KNbODXCXgmby2fFNb4tDSMAQRSqCnZ2eBaAzBZ3JZ+KLIpjKEEWLAN66jkCAGHwWgLkRooDh2Hnp"
DATA "+QFu706k0QvgiyYYzRAFDcPOBm+7cld9d2fTAJrJt8e3/SwLQRjCGIYocHB4VnqbNZP9Dd8e0LHj2N7gz/w8G0AgQTTCHOwA9ObV"
DATA "8d6fcgLoTz6Fz/jIFII4hgh211LgGaukuroHaLlFoJl8Nnzmx1oJwhGCGQLZyQbjh6FnArSnoDX5FnzaoKAlCGMIhffk+ZtbcfA8"
DATA "+D7wAYHAP4a9Y/di7SAQIDFCEDtg/sHobfFZAWoE14Mt1nuzG730f3AUwQBDIDsAPyA9E99E0DOGfWN319XQh8cR9DAEsotNPR+9"
DATA "pVNXFED7bsSafBLfeuzS0xMXQTRCO0MKeG56MHxXJEB7Cu6LvnXs6gfNYwDiCVoQJrPzwPNP55cuyMPgNoDTyWEj+Tb4Zn7yDL6v"
DATA "Q26CEQgNhmns4ult8U0EtTG8+dVBk9557Gpnbc5XQHg7RUtQZ5jCDkfPj+/K484xbEu+S+tpL3UFk79f1ATVGuSBF4Hv8RWgRlA/"
DATA "UKr9ptulSxpAdQVONMAUhHBchPS0/Nf4aQQ1gLbkk23Pb5sHZQhehQMDwwsfgnPg26XgtN8wqpYJ3wag1eCwjqUihDOD0ovBp/hd"
DATA "vmyZjWyT75FHDH50AGMIwqnB4AGOXq74nt/h0wCqK2S2ySfviJIAMEQQjRAOjoienn2Kn/oy7XS3lk0Kbi4OOtNb+IUBFiAIJhdL"
DATA "z43vedks/IwxvMPn5QcASEoQzC4ID4tPyG/OPwPf+9cf/V7wyQceffTRQgARCMvS2+Jz89MBavic/DwAMxMkggc82rvFZ7XfxO9M"
DATA "8AxwxjfdDlndlCwdIIAgCGFOej58u9LF5KcA6vh2/OwjGAaQhiAFPeipBiu+HT91u+vlxzPF3+9T9+N28vMCjE/BIMF0eNDkA+JT"
DATA "/OSv7pwBTj9AG0zAGIAggn6EuehB8Xn5SYDz7/d6+T0TDTCZYBq8SHyA9Jv4yTE8/ZKXMYC3AC38aAG6ERai58IX4veY+vlyD7/z"
DATA "PffDAPMQTICHOTUDxgflt0nAKf+iAUIJ2hBmoBeDz8nvsSA/mYHWfQgCYDzBWHqo84IufBZ+y691OPjtB7C2Cw4CTE9Bc/Xi4OFO"
DATA "Cm7wIdNP8fMnoIMfBiCc4GYViemh8GXglwIwiiAeHvZUFgofgh8a4DOUBNWqounR4fOln5tfKAHdABU/IoDT2hLSA+BzpF8qP18C"
DATA "KoDnKhEw2EDo1hVGwUPTw+JD8UMCXPOPkOATIGyQN8biy8fPmYEaP+zpawp+JfF5+MUDhO6HMQAh4ABvefVaGF9U+i38UhIQDxBM"
DATA "EIIuTO+qjR8UHwm/CIAkBCHwwvjOF5dj8IGHr4XfCvCTLn7lAKbTm9S3yz8wPiJ+GQBCCNLQ2/OLwYfk90nZEgEmE0yk5zoua+LL"
DATA "wU8QdBvQcl+MKIAhADzx+fktAD/p2YUUApiDXggfJv1WftYK0MMPDDCJYAI9EnyU/LIB9KCIpwfH5xm9Or4ofj6Ae37RAJ04sMun"
DATA "4wOkX4hffAKSA0QtDKAXjy+SHxHAWILgBanwFeVHC9AGBrRQCj5v+pHzAyRgCsA9nPASCHoAfKD0C/JLSkD394UiAOLpEeIDpJ/G"
DATA "LyoByQEaiND0cuGL51ca4AYTFp+bnvX7xQu4+6J9SrTrok3wbt68Jdpt0e6IdtcYvmKxhZ9YTPw5L3f3rsB37979hd716zcEtZui"
DATA "ae8X4Oe/QSYGII5eND7JT+G7MfPb4APwm/Gd+d3X+N2Y+envF0rARIArLBS9eHyC34Jv5rfFt+d3Q+N3W/yp8N0T/MTWWPjdmPlt"
DATA "3i84glMBKmAYegn4rgh8i/1u3Lw58fPsfgXmGzduin9MWCb/Tck38RNbY8Pv1i2nAfMAnKDRJF8Q3xWxugs/MdbO/G478El+Z3wz"
DATA "P5FUO34ymxW/m2IPIhZz88MCRKQgmB7+trY7fmq3O/O7HeAnFjvzk4NS8ZODV/I7y2Dmd9PkB0zAdIACXcq1lwh8gt+82532vOJP"
DATA "QcU9fAW/OfmmPe9UwNy9N/Obkk84UvwpMIsSRmD21DDZAFIkHwTfFbHrWPndAvBTg3fa80787hn8bmj8bnv54QHidiO58V1Zyr5p"
DATA "z3Hmd8c9fB9bBu+0593xuy5KaDHGz/xuCX5ia/iK6GwAM+Gz8Zt2CdPgFXOPpZ4TVJz8zubT+N2f+V2X/KbkE9ks/rEWQnfvWfhd"
DATA "c91nPRVgKj0gPsFvwTfz0/BZ+d0Sf057DrHczO/+zE9sjYWfyOYzv/X9LAl4zXmDfx/AhOPSOHxPh/Bd0fCd+V2W/BS++xZ+tzR+"
DATA "d2d+ouzb8ZP1oeSnbY7dCD5fHpEHIAk+k98e3xVBb/GfoHLmd9euvzM/QWWZfwgqO343lmMIwpHiT0HPdxhB5F+eDEyip7JPNj+/"
DATA "xw1+gpnIFvfuw8XvUzO/Gxq/21Z+W4A+fpgb9yP5gfDt8s+SfoKfrJkVP7nnFVS8/G5r/O7N/D418xNbY+EntsaZ310fP98++EOR"
DATA "NzYM84Pi2/Kz4ZvnvDO/Owa//fCVe96V372Znyj7NH4zwJnfXZMfHOA1eAY+jeEHxhfKPsFvmrNNTYy1M797Hn6CysJP7BJ2/G5q"
DATA "/O6IP8XWAPCzAQTc2DWKX4AeDp+Nnyhb0Pyuz/xuavzuOPhBAYr8C95DbaYnG5BfJD776N0ebZ6O258Ll/Ww6o7fHY3f/Sn5puOH"
DATA "gpzYGgs/sTXO/DbvhxrBkh8MIDz/CPFN/LTDmws//aC+ye+Oxu/+zG86/LrwmwDO/LabA5eAgL2wykAYvxA9NL7N0WbFT8d3w+An"
DATA "Flv4icWmwTtNAs/8bmn87oo/jWxGjmAIQMSNZEjxGefcznOPbbPoz3r+bXsKzjwLtzsR5+BHC5AUnzv9KvHDJWAMwAh6OHzY9MPw"
DATA "o07AuJ9yKoyvKL/sAMvjK8svN0A6fETph+JHn4BYgEh66fhK86MH6PytIHp8gPQLDF+DX2gAQxOQDGBpfOX55QWIoYfGF5F+SH7x"
DATA "CZgGcCFIg48u/TLwwycgAuDfAMPvFeo="
DATA *
