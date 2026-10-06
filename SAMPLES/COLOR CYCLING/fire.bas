' fire.bas - palette color cycling
' Exported by DRAW 2.5.1 (https://github.com/grymmjack/DRAW) on 10-06-2026
' 320x200, 45 colors, 2 cycle range(s):
'   1: 13-36 FWD 24.0/s
'   2: 37-44 PING 7.0/s
' Keys: SPACE pause/resume, + / - speed, R restart, ESC quit
'
' How it works: the art is drawn from a 32-bit image, then an 8-bit overlay
' holding only the cycling pixels is drawn on top (overlay index 0 is clear).
' Each step the overlay's palette entries are rotated with _PALETTECOLOR -
' the pixels never change, only the colors they point at. Speeds use the
' DeluxePaint CRNG unit: 16384 = 60 steps per second.
' Compile: qb64pe -x fire.bas

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
_TITLE "fire.bas - color cycling (SPACE pause, +/- speed, ESC quit)"

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
DATA "eJztXT3TNDeVnce7GNZeG/PaBs/31C5LOWA3oLAjB1sFiTMgW0fkriLd0PwAEtINSMiogt/x/gYXMZlJCWfvVfdVH2nU3VJ/zFef"
DATA "W8jvMzPdOtLRvUdXas3w85/9z89eVv/98nr1n6s33njz/O57H51ffXg8f3/zo/Pm8F/nw79/cv63jz87f+eDj89v7z49v/vDn59f"
DATA "/fhX5w9/+uvzR5/95rxafXFevfPVebX943n18evz6vOvz6svvzmvfnc+b/90Pn/y+nz+xd/O56/+fj7/+R/n81/P5/Nf5N/fyutf"
DATA "yvufyuc7ue5Frn+R+17k/hep50Xqe9F63/rsvPrJH84Ccz78/nz+TK4/yr8v8vpF3n9j9c7qh6uX1f+tV2Jnac9q9R+rH6/Wq//9"
DATA "9mr1Rv2O9mhMUSbGFOITn/jEvyW+KvvQonXojDC0EJ/4xCc+8YlPfOITn/jEJz7xiU984hOf+MQnPvGJT3ziE5/4xCc+8YlPfOIT"
DATA "n/hj8Kc4P3Pr8zvEJz7xiT8Un/MH8YlPfOITn/jEJz7xiU984hOf+MQnPvGJT3ziE5/4xCc+8YlPfOITn/jEJz7xHxV/ivMztz6/"
DATA "Q3ziE5/4Q/E5fxCf+MQnPvGJT3ziE5/4xCc+8YlPfOITn/jEJz7xiU984hOf+MQnPvGJT3ziE/9R8ac4P3Pr8zvEJz7xiT8Un/MH"
DATA "8YlPfOITn/jEJz7xiU984hOf+MQnPvGJT3ziE5/4xCc+8YlPfOITn/jEJz7xHxV/ivMztz6/Q3ziE5/4Q/E5fxCf+MQnPvGJT3zi"
DATA "E5/4xCc+8YlPfOITn/jEJz7xiU984hOf+MQnPvGJT3ziE/9R8ac4P3Pr8zvEJz7xiT8Un/MH8YlPfOITn/jEJz7xiU984hOf+MQn"
DATA "PvGJT3ziE5/4xCc+8YlPfOITn/jEJz7xHxV/ivMztz6/Q3ziE5/4Q/E5fxCf+MQnPvGJT3ziE5/4xCc+8YlPfOITn/jEJz7xiU98"
DATA "4hOf+MQnPvGJT3ziE/9R8ac4P3Pr8zvEJz7xiT8Un/MH8YlPfOITn/jEJz7xiU984hOf+MQnPvGJT3ziE5/4xCc+8YlPfOITn/jE"
DATA "Jz7xHxV/ivMztz6/Q3ziE5/4Q/E5fxCf+MQnPvGJT3ziE5/4xCc+8YlPfOITn/jEJz7xiU984hOf+MQnPvGJT/xb4b/87kz+iT8K"
DATA "f4rzM7c+v0P85eGr9u3+1BTyT/yh+Jw/iB+Xly+/udv+m+Z9+ropv/zbmeNPfOITfzS+ap8rn399d/1HvbPy279X5Vn4Jz7xiX8b"
DATA "fK99tf71aeA1+5/SPC1/+UdTHp1/4hOf+LfBT2lfnwZes/9tmvfXc1MemX/iE5/4t8Pv0r82DbxW/1HvYs37s7zGwvEnPvGJX4If"
DATA "aF9BDnit/qPepTTvK8kJrXD8iU984pfgJ/UvUW7R/z69w/IL2RvUwvEnfk6Z4vzMrc/vEH8cfq72ablF/9v0zrQuVR6Jf+LfFp/z"
DATA "x7Lx9Sxxbrl2/3P1LlU4/sQnPvH78HO1z84dX7P/saZ98jq/cPyJT3zid5UunUsVPXt8zf6X6B31j/jEJ35J6dO6uNj542v0H7Vs"
DATA "K+3pKkM1kP5HfOIvFz9X79q+azZn//s0L0cDOf7EJz7xU6VE79q+azZX/0u1r03/+p6D0P+IT/xl4qf0ruu7tanvms3V/5XsQ3aV"
DATA "HP3LeQ5M/1s2/hTnZ259fof4w0pOjtf2nQs7kzJH//u0L0f/8Jkxx5/4XficP5aHn5vjtX3nArVlyv6vvvymKQX616Z9fd+Jo/8R"
DATA "n/jLw2/TuxzNi8/hTdn/QP9aNLBU+6h/xCc+8bGM0bv4PMpU/b/QvhYNLNU+6h/xiU98K0M0DzXnIicTjRrb/9XnX4/Svi796/pd"
DATA "LPof8Ym/LPzRmpfSKdGvof132pehf0PWvX2/C0j/Iz7xl4U/NMeL9S4uQ/of1DHxuhe1r+33oel/xCf+svAH5XgJvVt9/DpZctqQ"
DATA "rG8m7aP+Eb+tTHF+5tbnd4ifX7I1r0Dv2griXnzepX0d694h2of6p4X+R3zE5/yxHPyiHC+la9s/lpU2fZxJ+3L0j/5HfOIvE79I"
DATA "70q1LlcDM9e9U2lflwbS/4hP/GXgX2heid6981V3uYH2leofFvof8Ym/MP2LNW+IzpVqYO66dwLtG6KB9D/iE38Z+EnNG6N3ffo3"
DATA "ofaV6F9uof8Rn/jLwO/Uu9UXZWWI/k2sfWP1b67fb6D/EZ/494c/Su9yNHBC7cvVv1wNbLtX66X/8ff/Hv38DvH7S0rDXkS3uspg"
DATA "/ZtY+7r0r6S0/YYD/W/Z+Jw/nhs/R+uKNHBC7ZtL/9r+/5Dazn7T/4hP/OfEH6p9WfpXqn0Dcr8xJa6/6/supdwjJ/Q/4hP/PvFf"
DATA "RJuySo7+zah9Y/UvVV/n7zgkzkL28d21f0D/Iz7x7ws/W/ty9K9U+wrXvSUa2HZv0e/WtJ2FlP616d4FRxGH9D/iE/+O9E9i+6Jk"
DATA "6t+ce35d+ldSUvUO0bu25+N9eucL8Ev/Iz7xb4+f1L4uDbzSuneo/iW1bkSON1jvunil/hGf+I+nf3NqX4v+DS4lv1tTqnkD9G6M"
DATA "BtL/+ft/xJ8H/0W0oFT7Jt/zG6t/qbpG6l2v5qU4Uy5LitxD/38MfM4fz4ePcTg495tK+3I1sOveOXO8sVrXUuj/xCf+nenflNpX"
DATA "qn+5Ja6zS++GaF6J3kl7Ogv1j/jEvyv8eB3Wqn9Ta99QDezTu6lzvCE6V6qBNRb9n/jEv5H+Tal9Jfo3pHTp3Rw53hi9o/4Rn/h3"
DATA "id+a+02tfWP1L1XfkDN5uTleSrdkz7G45OhfxDv9n/jEv7L+jdG+XP3L0cC2++bO8abSuz7969E+6h/xiX8d/KtrX2np0rs5crwW"
DATA "Ddv9qbsM1r8W3un/94s/xfmZW5/fIf5xuPb1rXuHamCqjg69G6R5GXrXp3VFGjhA+6w/9P/7xef88fj4k2hfl/4NKXHdU+d4E2ld"
DATA "tgYO1L6u34ah/xOf+OPwc2Owd907Vv969G50jpepd5++LiujtI/6R3zi3wx/sPa16V+uBrbd26V3IzVvCq0bpH8j1r3IO/2f+MSf"
DATA "Dr8z/lpiMEv/SsqMepfSvDYN++Xf+kuu/k257kVu6P/EJ/40+CXnmyfTv1QdM+d4Q7WuRAPn0j7qH/GJPy3+2BicomTr3QDNm1rv"
DATA "+vQve907gPcU9/R/4hO/DL8oBifWv1RMX+BNnOOldOu3fy8rOfo3qfZR/x4Sf4rzM7c+v/Os+FPFYK4Ott7bpXcT5HhjtS5X/7LX"
DATA "vTPyTv+/P3zOH/eFPzgGe+Iwu6TqHXAmr03zcvXuL//oL7n6N6n2FepfXOj/xCd+Gn9UDA7Vvz69mzjHG6p1JRqYu+6dRPsKuaf/"
DATA "E5/4l/hFMdgVh0NKl97NkOON0bs+/ZtU+0r0L7PQ/4lP/BC/OAbHxmGqvszv1uZoXo7e/fVcVobo3+TaNxHv9H/iE7/+/tqQGMyN"
DATA "xa57J8zx5tC7HA2cVPtKuB86x9S80/+JT/wfjYvB0tKldyM1r0Tr/iyfd5Wh+je59k3FfYJ3+j/xiQ9n+7picEgcpurI1LupNK9P"
DATA "50o1cFLtm0v/2sYvwTv9n7//t2T87BgcWuK6Z87xxuhdqf5dRfum5D7B+9L9/17wOX/cBj+pTzPq3VjNy9W7r+S+kpKjf2O0r3fd"
DATA "eyPel+7/xF8ufmsc5sZi270D9C5X86bQuiH6V6p9xbnfzLx3cc/4I/7S8HvjsKQMjLuhOV6bhv1C6uwrufpXqn1F696ZeB+aWzP+"
DATA "iL80/MFxmIrljrgbonk5epejdSUamKN9k6x7Z+R96FzD+CP+kvDbYqmkzJnjTal1Ofo3555fq/7NwPuYuYbxR3zqX17MzZ3jtenW"
DATA "J4JTUkq1b+o9v7H6d03eGX/EXwL+kJjri7shsdeX45Vq3RD9u4b25WpgLu9jNa+Nd8bf7fCnOD9z6/M7j4LfFaNzxl1fjtemYVtp"
DATA "S1/J1b8he365zzv69G8O3odoXhfvjL/b4XP+mB+/JOamzvFy9C5H60o0MDf3m0L7hmrg3LzH3Hfxzvgj/jPjt8VsTtyN1byp9a5P"
DATA "/6bUvhL9G1Lm5D3FfRePjD/iL0H/4pibIu76NC8VbyvZ+yopQ/Rvau0bq3993Hd9x2/IXFPCO+OP+M+In4q5uXO8sVqXq4FTal+u"
DATA "/uVoYNt9c+d4Y+cZxh/xn1H/4pjrirshmlcUc19+010G6t+1tK+0dPE+dq4p0rsM3hl/xH8m/GutrQbFW6EGTql9feveoRrYN89c"
DATA "ba4ZwTvjj/jPgn/VuBujd4X6N6X2denfkBLXPXWONyvvUhh/18Of4vzM0s8PtZWuuBsSe1lx9/nX5SVD/8ZoX9+6d6z+9endWM3L"
DATA "1rsJeWf8XQ+f88f0+LPkGlPpXV8czqh9bfqXq4Ft9+bq3SDNuxbvEfeMP+I/Kv5suUZbLH38ursM1L9S7etb93bpX0np0ru74r2L"
DATA "+x7eGX/Ef0T8SXONoTGXG4czat9U+peqY3LNm5P3HO5bcm7GH/EfDX9UrjFlzOXE4QjtK133ji1Dv9OcpXm35L2He8Yf8R8Ff7a4"
DATA "2/6xrIzQvjlzv6FaN8s+3rV4j7kfkHMz/oh/7/iDNG+KmBuifzOve0s0sO3eLr2bJce7Bu8jcm7GH/HvGX/yuHvnq/6SG4cTrntj"
DATA "XerSv5KSqnfQ+e/cuebBeE9pIOOPv/93D/ij4y4n5kpi8Up7fkP1L1XH7DnetXnvyrlH8M74mxaf88c4/F7Nmzru+uJwxhhs07+h"
DATA "pUvvZsnxHoT3nHmH8Uf8W+OPirvVF2UlJw5njsGx+peqb/Rz8nvgvSvnnpl3xj/xb4FfFHelMZcbh1eOwVwN7Lp30hxvDr3L4X5C"
DATA "3ku47+Kc8U/8a+AnY2+OmLvTGCwpcZ2x3o3WvGvw3sf9xLyP5Z7xT/y58Ftjb664u2EMDonDWfTuVpo3A+99OffUvDP+iT8F/k3i"
DATA "7kox2BWHQ0qn3t1zjpfD/QPxHnPP+Cd+KX5p3L3IdSXlHmJwbBz2xV329y5G5tazcD+G956ce3beO+Yaxn9VnuH8ztT4XXH34U9/"
DATA "fVE++uw3veU7H3zcW97efdpb3v3hzy9KSQy2xWFuLLbde+0cr1TrBukftGfK8YrLqx//qrek/K6X9wzuGf/MH7WetrhL+d296V8q"
DATA "ntq0r0v/SsrYuCvN8Vp1TOrpLYX6d4vxGqJ/KT8cw/uS439p+H2xV+p396Z/cRmjfykN7czxJtC8wVqXqYGx3t3beA3Vv7gM4Z36"
DATA "8zz4Q+PukbRtSKy0alpXmTHHm1TrevTvWbStxA+HzjPUn8fBHxJ7bWP/7Pp3kSf0ad3EOV623kndRSVRx7PmdkP1L4v7BLfUn/vC"
DATA "H7qHnjP2S9O/Cz3s07s5NK9U61r0b4nj1devOXin/l0P/9pxt+RYaevX6HVtbtyJ1vaWaJw4Xt39yta7TN678m7q33T4vd/xnCru"
DATA "onFmPOX3a0re28qSc/FJ9G8g79ka2LLfeu/68wznd+bAZzyxX8/Ur0eLv2viP3P+OBSfGsB+PVO/lrp+JD71jzrBfjH+iT+n/l2r"
DATA "/9SJ++rXNfyf+kf8a+O3+tQd9p/aNn+/7tL/C/r1aPFH/DvRvwftP/VveL/uwf+G4lP/iE/8fj2k/g3Tu0cbf+of8YnfHhdLXNty"
DATA "/IlvZYrzM7c+vzOkrH7yh/Pqi7Ov5/D76m98z8pRPnvR69/6zL+2a/U+/VeLvm/16/UpXH3/Ra7Vv/VefW31uc+kWFtS5bPXzWda"
DATA "j16LuPi366O0Wa/BNmgd9p5+rvfov3a99kV1wvVLX0tRrbNrrJ36OtY6a4/+rfdrG/W141D+jnXPYdR91vpU51zdNS96j77v/q3f"
DATA "x+uNT32t+mftNa3Ta62f9rfVqzzYmBom9tHG3fEDbcLxwHE27u2+2Be0jQ7TsGpf07a0jbXWpf9aH9HvDM/GCf/W683P0Cf0Pud3"
DATA "9Wfod0uKf8Rf2vzhYiXCN7+wmDUfMxyLD/3b62Ht13a9+ZHWa7HlY1Pe02vQp917FsvymWEZrsWK1oG4WtxnoKNWl/7r4lU+079R"
DATA "f9r4Nwyt0/fVeKj10OpxcSWfqx56HuQ90zvTVi36nl4T6J21vcY0DTON0b8t3zMs0wqrP9Zs48Q02YqNtdVhn1vfTXe0z1a/6z/0"
DATA "Vf9FH9Bi15v/mZ4Y51YQy3QJX7s21PXZ+Lq6YcxtTPzY1GNhPmP+j35nr+093/ca0+twzaPVzfxxGfjeL8DnTdvMF8xH0DfN72J/"
DATA "jP3N+aZh1Bpouhf4pcUq+LPhWXtQM7Et5rfWf8s/MfYD7a193f62dpruWAybflk8+3prLUJ9NB6QW3tt/CFeHJ8ur4k0RbFw3jE8"
DATA "1CXUK+MyqLvuB+qQ5W7Ggf1r+TaOv8835d94TsI5ALXe6vP5FcxR2MbYD3H+tXH3f0O7UeeRF2uv+Y+1Cftur+Oxsn4jp9Sf58Y3"
DATA "vbKYjMcc/cv8N9ajGN98PsbyOoR6W/+N6xmvefXnpgHWFotbrQ9jDud/qz/Ar/Me1OFYK2xtZfmG6YzPyer7kAPjBnXexxPMB/gZ"
DATA "6rLxGo+/aaa1CXND5By5sPU8cob1Y//jMcL5IvYr3A/A8bmYp+rr0AfwPY8frQNsPR/ndzjnYj6K/OP8gPXbvOTnNZg7Y90zn7T8"
DATA "H3NO6s/z6x/iY04Xa15bbJgf2j4bzq2Y+6Aumd9ZTGNcYr2oxSmfDPwf1qlYn/Ujte7F67H/qP2oe7EuWlwhR5jjYbxjXmSag2sx"
DATA "3Gsw/m1vz+o3XK83UV5m9WJ+Z3oQ5N0w/1g+Zf6H63/kArXH9zmBj7kuri2tbTg2tp7H9TeuaeM2pMbdPjf/D+aNRE6M2m+c2P6j"
DATA "5eHxPEP9eT78eB8G13ro71rQH+y62AfNr2wdZf5uGmF+b9dgOywObS2L+2Kxxvk2RDmDxRLua6PfB5jROszWcjGntk8Wvx/oiOlC"
DATA "tMY2rcLnFoE+WJxD/o15Leq+tcOutzZ5DIh/1Dzrt9cEyG/ituAYY35lGmY6GY+5jYE930CdsbzSzzeg96hBhoF+Z75gnOC+c5Ab"
DATA "1vf5Zx7Q93g/GOcCm68QA/dTnz3+l45v2oJ75qgnwXOASBtszsZ7Yk1p05q4WBvs+Ztfa8L+j+mZj3loj/my+S/GVbI9CQ22/CPO"
DATA "teL1ldfExDoY9zLtX3z+eKGNkO/Z+Mexh3uNqAnGCeqQ3/+EtXVqv83GzTiwnAzzX+TBXps+m/an/C94NgR5bYyPz2Bw39CwUmvg"
DATA "lPbanGf4OHea3tn8Zu/Z/GI+bp+b/2H/qT/Pix/rg3/+H2md33ODfRycZy1GbP1rPp7aa4l1Bz+LzzigBqAOmkZYuyw22nK+eL1j"
DATA "/o5rX9M/fO4dxxq2wbcNcjGrK7XOjvuOehiPv8V8fNbEuLD+4mt7/u7jGnBS+RY+I7W++Zwz0lx839oVaxE+C0GtQT5Ml2Ltwf03"
DATA "uxd5sP7FezCp5x/x3ovpsGmtaaL1we8JwJhjTrsk/Zni/Mytz++UFtyDs/ixdQTWjfuBpnN2nspyJatTX2P9tq+Czx3tfbvW1m8+"
DATA "Z6pfGzY+WzH8eN/f49fn2Ow9n9vBPpN/z/JG1PM6JzHM4Cwj8OLP/ERcxH0P+Aae8BqLybbzi23FdMTGH5+rI7/GSTCP1XmoXWd5"
DATA "OJ5Vsj4az7hfhz7hzweBpuAeJrYBzxj5Z7l1HxDT81yf5zOebY4y3TKubF5Efm1NEHOPGmxtXmL8x/iPrN9D8HE+xf0TfF6AzxDj"
DATA "gnlevB7D+RSfE1guYXoT70m5OTp6Run3Z3DNajkB5BHYr/jcGOZL8fuYb+GzDavf79vX7cU2eY7sDI/tIQGPmKvi2TbMZz0PdRvs"
DATA "fszbLG4vnjWA3vlcGHLzOGe1McDxMP5NgzBH9Htx0b6a5XemcZaLWR99OxK845rXeMG6ff4GPOEeAuL7uQ72cjA3tPwRdd/nqvUY"
DATA "mdba9UuI/6Xj2xyI60Q8K4L72ag7cczjM0WvJZHmGV5bO8wP2/btgrUr+Dm2xeLbP1sFTcHP8LxjnEcghtdf0CJ8loH8WL5hMRc/"
DATA "x0ANtlwJP7N2xs+AUHv9Ohr28PA5LmoJjs/F+8AHrqmx313neRAfx8f65+e9mgfcu8U5EbXX55fIO8yL8Zj4dtSfW36L2hv7GWpz"
DATA "oI+Q09oYLyH+l4yPucFFvgV5h827/jlclJfg/Iv7N7hXH58ZjPOR+MwG6mz8t4+FWm8x/mxvy/62+MJzJJiP+PwL8si+uR+13s8f"
DATA "ljNCzuVz3MReImoh6iXyi7lOvFdo7+NrzG1MN4MzJLZOBQ1A7m2di2OK3MZaZzzhmRY/B9Xtx301myetLYEGQY5tehavw/3+HexR"
DATA "oF75/LPuo2HFcy6OlZ8n4TnMUuKf+KHvmS5YDOL6A/dycA1mGmD4mE+iD+L5kou1Cbx/Mb9DfpfSZozVi2eWUT5lMR/nZRgLdh3q"
DATA "qfXT2oS6g9qEz069DkGcm85arhvPEba/GGgtaEGgPZH24TNmnFeSewB1X3Guwr3MQE/j9tTtR65w3zPwq5or6ydqf5Cf1j6HeW5q"
DATA "rDEXjucinH/Np9v8HedFn/PW+WeMT/15bnycj32sRTpksYBr5PgZn2kl5nm4rjPfx7wjuBZ0F3ExJzId8HN+dC1i4voK49ziJY6F"
DATA "+JyaaUq834VzheWaqf3HeI3l+wxtsveMI3wu6/Wn5ineC0ytBW2PH/tkXAQaXPONe1/4TNTqt/4at6ncCP0AnxPjWGMellqTmg9Y"
DATA "Xod+aGOOa1M/3rbPUX+GWh6vuYMzRfXfcXvw+fBS4n/p+Linjusf3HfBfUGvC7hXYrlenOtEZ8ZiH7Q4jPf0cV8an8nG7cL3TTu8"
DATA "rkd7S3GsWRvwenymbH2L1/o+9qI9Kr9vXueDXmshB8K+2OemOTb+8d6atd/ag8894ucg8ZmONo3B9zA/TPlfKt/yz62i+RL9z3Jc"
DATA "XDMgLuq/fYb4dh/mmTb/mhbj81vPVd1/7Fvs79gGnCNs/zF+zkb9eV58PFMV515BvNd+6nORKD5xrRXHOsZ4aj/MCp7f8zh1/oP5"
DATA "n/m+td30yZ5/xjFu11r7vf5G52yN/9Tefpx7YR4a8x8864jwcC8rNf7WZ+sr9jnWW9wTs3Zjnm79wr1QG+eAi2ic4rHHZzGmwVZS"
DATA "ewHY53ivBPH9vnLd59j/cd8BMUyH430W3O/EfYcU1zg23pcG5n2PHP8BHzQajUaj0Wg0Go1Go9FoNBqNRqPRaDQajUaj0Wg0Go1G"
DATA "o9FoNBqNRqPRaDQajUaj0Wg0Go1Go9FoNBqNRqPRaDQajUaj0Wg0Go1Go9Foj23vF11Ni+z9V69eFd2wEPsg77JXr773ve+9l3ft"
DATA "kuyDDz7MuUy4e++9734359JF2QfCXwaBjrzvvvvuu/2XLsocfRkEVuS98847vVcuy2r++ggU7pS8fxXruXJZJvRlOaBw58h7++23"
DATA "e65cljn+nHVeZtyJvfVW55XLsoa+bv4q7t6qrPPKZdn7jXVd1nBHAgNr6OtcWihp/9JYZ5VLspo5Z9/ruA64I39gRp3ae+1LM6Hs"
DATA "O7WRQLSGu86lmZHnCeyrdyEG3HUtzZC+ij/OIM4cd/WytmNp9u3aPH+cgSvzjlctLlqWFkaf548ZTGWN41WLizQtb775JvBX0cdF"
DATA "nFrFnSdPM7zEVcJfRSDSR/7EIu40R7m8SOmrCET6yF+1J+DJE3KUozfji74V0Vfzx12sak8AyXNMfSu85luevyB6uQsoFjqecqcW"
DATA "XCKvU9Er9HEful6VIXf/7Mxf4N5L00f+Vg15wJ1nUP+p6aujN6BP+Fs6geB4jrR/AqtoTNNH/ioD7pC6hsAmei/pI4FKHnD3Rm2d"
DATA "9CF/S5+ClbyAOSSwid4L+khgZY68iDvjL0Ef8NdYEeBzWc3dC1jAX4q+mL8lb8NE3HkCE/Q1/DUEVi8XvA/tCPuotpC/FH01f2DV"
DATA "hkMR5hOZpw4ITNCX5q96hlSl30Woz2MhfZ4/pC9wv8j0/XrtgrVKJflNeGj7gTfPXwt9MX/uvXrHwaWQVmWtBwWNeFxr6PP8IX0Y"
DATA "vUBg9RJ2a6oU8g2tsSJPKyxqyIPa99Ua/lrEr+YPzL0bcFfN48bdD34g9Ra15CHN0VcT2B69IX/VI6TQ8ULu6lqXxV8LffbIDQ12"
DATA "a5C8gLtlEPgh0pcSv5i/ams/4s7Ic5W5M8C1PTuB0sPQ/S7pawisX7Y4XkxdZUWteTyr+EvQh/w1ZtvT9YaDJw+4szOsi+BPI6zi"
DATA "L0VfSKDf2k84XsAcEvjkCpikD/gLzLZYU44XcbcQ/ir3S9EX82ePRZokr3E8xxacnn7/fc+f1l7UoseyC/oa/jyB9XO4Fse75M74"
DATA "M/qemL8u+tBsezrleHbivLKQv6r2oiY9koX0WfSGBPrHIk2S1zheQB0QGND3vNsIF/TV/AVmW/ux411S1xAY0ves/DUdtOiN+fOP"
DATA "RSLHa7hzp6Zri+h7dv5C+uCJETzJtI39iLwL6gL+ouiV2ova9SBW98+it+YPrIU7R15FmDtxrtbwl4je59yIhrz5kr/qEVKL44XU"
DATA "AYFp+p6Sv7iDF9ZwF5CX4s74a6I3qN1VX9S4ezfoYIo/1+lmWRs6nn1JxJvnL0HfU/J32cGGweoV7EUFjhdT1/DXRG9L7UUtvGcL"
DATA "O2g9bMw2kJskryKv4U6/JeKs4S9BH/L3RE/iog6G/PnN94TjhdQBgU30XtCH1Re18m4NOlj3MDDYi7pwvIg74y9BH/DXWFEz79Ww"
DATA "g3EP7cFFvaz15Hnu9NtJZgF/Kfouay9q6H1a0MGmi/XLhOMlufMEJuiD6sOB+f4TbONHHUSDvSgkD6izU6Yhfyn6Lqt3tRc19S6t"
DATA "eaYTdw64uySvOaHbEJigL82ff6LU/ZMej2BNB0OzDeQM7pC/VvoS1ff9osdDWPNI55K7mLyGOzyi6/mL6LPo7a69qLH3Z1UPmy5W"
DATA "LwPuGvIuqAv4Q/rQ/dpqr6svau69mfUQLOxd6Hh4sDn4rgLSB9Gbrj1066L23puFPfTPfJrVReN4IXVAoKfvInpbag+Hpqi9d2bx"
DATA "88U2x0tQ5/lrET975JaoPRqaohbfl8Wda3M8PBNeGdKXEr+Yv47ai1p8VxZ0Dvei8Bc3HHkXp8ONv1b6GgLhiVKy9qIm35U1TxdT"
DATA "vTPHw4PN/qhzGL3B3GH8JWsPyKtrL2rzHRl0LuV4nrvogDPyl6IvJLCtdvtBjwf+go09YIS9qPjnSmLu8KtaEX3AX2AttduvoagV"
DATA "tfp+DJ9bpFwDzoTDjzMFv1AS0RfzF/12VvxLMlZ7UavvxqpHPC2OF1MX/DpTTF/DnyewfgDX4njxyBS1+17Mb77HP9AEnbMzpiF/"
DATA "7fSh2TZhonb4poOrvajdd2LtYRX0DQlM0GfRGxLoH4u0Dk1Ue1HL78M6endxPLzhL0FfzV9gtj2dWfvFT0Ldv4VJXuN4zZFwM89f"
DATA "RJ9Fb8yf39pvqz2ovq69qO13YEnXuOQOfh4nRR88MWqoixbNnrz22rX6otbf3tKuEZxstpPOdQeRPovemj8w2OnqqR2+CaG1F7X+"
DATA "5pZwjbBzTQ9b6Lvkr3milFe7r75y7qL239oi10h0zvcwog+jN7Zw0ezJ66ndqi/qwG0t3Ts8ohvR1+J+IXVJxWuv/eK3s4q6cEsL"
DATA "yLvoXMBfW/QCgc0TpTbHa609cu6iTtzQUr0Lflyo88fB4MeZarOt/Sb/boampPYHITDuXXTA2XrYIn4hf80TpYTjddWe/u2son7c"
DATA "yODb9SW/bgVP3AKDvagLx8uv3Y9OUVduYVHv8Iiu72FbBy9/3SpO8pqhaa+957ezinpzdYPeXZwO7+1gQ2D9MuF4Se589YnaL387"
DATA "q6hDVzX8ruml9XcQzG9PR+S11l7y21lFnbqeVd1L966ng5e/bhVz101e629ntdVe1LGrWGfv2juY+nUr2IvKcDxffUHtd/fDY9g7"
DATA "PB7e28G2X7dqVhexWyerj2rP/O2soi7OZ3Xvsq7Fnxdqnhg1net0vItvPgB9WegXv52VddesVvWu6BZJEv2OfWBx79Dx4OsOzbcU"
DATA "qo+KsN2vmmPtRfdOa9a9optqi/jzz3ya1UVDXkhdQ+Dw3ge1F905jYW9K7oVrH7w5rlLOV6COuOvCCu2cGSKbh1nQfcq+KL7Iwse"
DATA "i0TkNdzh+fBpvhuD1btqi+4eaKGge/iiOhKGuzUX5F18NWEaZ0nWXlRDmXX1rqiiNoujFr4HYzZlB8Mv8QTfwSmqJ8/gl2yi3ily"
DATA "UVXdlqi9sqJaMiysvSGw0taiqmg0Go1Go9FotCzbbFer3Ur+s1odTuvVYbXdbbeH1erkPj0dV7vTYXU67aqr96vVcSefyv82a31v"
DATA "v1utD+vNervarter9eYkdYjJNdvj4XDUv7eb3Xp12hyO6+NmI3+fjnKPXLWRy1eH414/lBsPp8NmI/Uq8kHaon/s9htpn6tltT/s"
DATA "5cat1ryW/x2P2ojdTj48VW29iTledrvtcSt/naQ/Uo5badF+ra2VRq82O0fxfiMtPp32W/lbrpNuHbS3YpvjfnXaHtfC2PEk1wiX"
DATA "+91Ou7fayF1rIeYkvJ822+1eyT4JyULg7rRRsoWArVZ21EE76Ujujjqc8pEQJa/l3oNgyNjtV8ejNkZap5duBGknNcqg3sykwVuh"
DATA "Yy8NkWYKZdJGbdtOvOO4F77EVcQj1VuETLlEW7s9SPfViw7Sy91hszvupc/bw/YkPKqPVvVJ76WfeyXloON0EpYE7qRvC+XifjIC"
DATA "4tyCJaMlVwvnx5NQf5ARlYGSC91dOmACtpFhkBen/Xon4yO3a2PlQ3FaFz63sKN0UsFP0ifl0TVEfEdMwkpCT2nSEDzsxLMOa+mc"
DATA "XqJlowwrFXsJJfGug7zaaEDLf+Qi8WONUqlVa9zv1Q3lL6lCIlHZ0fjVunUsFG6jzqa1rzfSAPmPtEYi4LhRv9NBk8ZuNF7k/ZOE"
DATA "sRtOcWJtSRXhNzAHLOOo3am6oYMtrVV3lOg4Saell/qRSKG7VrokQrfbq0hKBc5tTnKjfnw8bSXeHSEqVOJP4o8iDfu9SOBGgls/"
DATA "knfF77Yn8e7jRoJQbhMwcU4Fdp/LPxKW4prr3Warg1MFbaU28q+Mho6UvtyLkOzdyNzEVGFUbqSRqsbO2YQO6aIQoR4oJG4Oe1Ex"
DATA "JU74FFfYbFW1JTLVFTTotaJq2hBGRPyE7+NJZgu5Ziu8bcVrhf3TeqdR78ReA32/PzlR03EQv9qLLiq4UinMHKQ+4V65kptWh/1a"
DATA "Llc3VC+V21WDZQg2QrRqanaHJ7ajeJhyIh6gNGxFfhwpFTVqEiASmsKocKaBut9Ih5zwVCHuJMDRu9EOy23iZeJnovRCo5uWtHsq"
DATA "ZiKd8kqVS1zGoWvd+o7UsFpv1zrp6tsHAXLuLBOMqqHGfO2Ami7IcMpYHoTO3V5nYQW8kTkeXGQeZBqQCVJlS0TPSUuVw+w0cdB4"
DATA "VKeQwDtVzqexI76nziGzt14nFzjJ0ySovt35s7tQUxOdSpXhnbDnplj5VwR1pzzK5Tq9a0NESqURBxkppUfeUqZU5dQl1TtVXo7i"
DATA "z+K6IgLCtTrtjUwFrkr/nAZKW4UL50R7mR0lR9DRXZ+c2kjMVJ4g/iO9FdZUsoRzUUhNCt2dMs2428WUVZ17q3yxMh0KndXF3+TC"
DATA "nc45u5OkSkqRaJ004rjeyIhpXqmJ0UYzUI0F9fXdVsRCZjGtRwdOiNPp5ZbmpF4T5mqiVM/TGFOn0lxZMkElVCfKtUSNzKouH3Pa"
DATA "pqxr44Xy03YjVYiAKb+S2x2kRpebbMRnJc2T5EZnZiFF5WFzktSvimOdHJQgGa6D1K/BrnmoNELFT3VQuVfxOO3kE2mtiIBIjrZE"
DATA "2T8dBFcQCno8re2lYZqKiO45pxNfk7lNZw8TOZlo6z/UcfQSyfuk9UKW0KTTR7VakL+FVq1Hkz4X/FtZYGiaqxOQcqmBKvQpCToR"
DATA "K2OycJGVh76nOY8Gsk4pwqg4qg6i0ivN0/zZLUlUgmVknC64aVcSdzdr38ZkyNW3ZKwPu/VeRUnIkgDUZYd2Q3xEHcnpjlx+cHnD"
DATA "XiXoqIsyueIgHmnDL9RLMijciuM6SXTLB8k2dEquk0p5V9ZxknUIM0KqKqogOtZ1ctKkRYRN9E3cqppEDjpFSYRLPEvapFXIvOIu"
DATA "FyhZc1bp6q3sKCmaLCxl4hUpl+RXeyLtEhlz2i0UuWhxDdYQF9dxIXiQ9FW9TLqgf2narDmMSqHOvjoSoo2OGceCW40ofTox1wIg"
DATA "CqvuKPW7rFwmg72+o3/qJCRZ1H6tabK8pSsg527ibUqoMxnFk6ZPtwtfnSMlQE7y106zPo0j8THJNsQzxRXkz6NKvqasKm5u8aFC"
DATA "rpfqvC29caSodslQ7JXverqQ0NT13UZzld1a5nadORyiUqBSJwtmWfTJm8qIZjpurpWKBFqnZtfC7cYtbGQ1qXXKfoNQrsGtg+Wu"
DATA "qVZQNzIRddV0kRpNW3T1oPPFQZMxbeD2qKIvKi2TrF4l/1U6qlRQ2u2Caa3h7PqgQrXW6Vi3YfQW1TYna0fpvq5zpGjSoRfL4lBr"
DATA "qsS1kjIZETeWe7cBoe9WYb/fiWeedrKQkYHSHNU5oK7YdSBkkyKzt9ObqEodDLpWksbpukG7Lh13GuYm443MBOJ/sp0kTuX0XLMz"
DATA "cYoqn3Gyr+4lL9XkpX6mkqUmixxd8SmYviM5uzLptsLEl+qsWZNiyQWdBOjKWAVB/HCnKyTNm7WFOhKiHLLEqZRUYWQ5lNXRdvt/"
DATA "aAhKKw=="
DATA *
