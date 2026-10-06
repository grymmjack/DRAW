' ocean-sunset.bas - palette color cycling
' Exported by DRAW 2.5.1 (https://github.com/grymmjack/DRAW) on 10-06-2026
' 320x200, 41 colors, 2 cycle range(s):
'   1: 21-32 REV 6.0/s
'   2: 33-40 PING 7.0/s
' Keys: SPACE pause/resume, + / - speed, R restart, ESC quit
'
' How it works: the art is drawn from a 32-bit image, then an 8-bit overlay
' holding only the cycling pixels is drawn on top (overlay index 0 is clear).
' Each step the overlay's palette entries are rotated with _PALETTECOLOR -
' the pixels never change, only the colors they point at. Speeds use the
' DeluxePaint CRNG unit: 16384 = 60 steps per second.
' Compile: qb64pe -x ocean-sunset.bas

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
_TITLE "ocean-sunset.bas - color cycling (SPACE pause, +/- speed, ESC quit)"

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
DATA "eJztfT2PNUtS5tvf392nu88uzmq0g3XXQsIa4zVWwwpdnDFWV4K9OBjDCmMEJtcGCWEMAgvhgMZEuCDx8QPQeNhI2FiIv3CIyKrn"
DATA "nKiozKrMqqzz8faTV8893fWeysqMjIx8MiIq+//8yv/7lbNP//vs55/+16f15eXm8/33Nj9c/WDz9X//v5sf/Y+fbL75xT/afPvV"
DATA "zzbf/OBvNz/6+p83X//Gv25++Dv/sfn83Wbz9R9vNt/8xWbzW3+92fzkHzab736+2fz5v8vnv2w23/79ZvP5Z5vNr67vN99+/3Xz"
DATA "u7/0C5s/+Py9zZ/+2lebv/z1X978zY8/b/5KPv9Mfv9Duf578u+/Kd/7/NPN5sd/t9n89N82m3/8z81Gqtv8k3z+ifz+23L9/NN/"
DATA "+/Q/P519+v/Xn+T/m80nKd//9NWnp0+/f/Pp03l7RXtBEARBEARBEARBEARBEARBEARBEARBEARBEARBEMRpQTMYCYIgCIIgCIIg"
DATA "CIIgCIIgCIIgCIIgCIIgCOJUoad3EQRBEARBEARBEARBEARBEARBEARBEARBEARBEARxWtC/3EkQBEEQBEEQBEEQBEEQBEEQBEEQ"
DATA "BEEQBEEQp4pvfvGPCIIgCIIgCIIgCIIgCIIgCIIgCIIgCIIgCIIgCII4MXz71c8IgiAIgiAIgiAIgiAIgiAIgiAIgiAIgiAI4mTx"
DATA "zQ/+liAIgiAIgiAIgiAIgiAIgiAIgiAIgiAIgiAIgiCIE8OPvv5ngiAIgiAIgiAIgiAIgiAIgiAIgiAIgiAIgjhZfP0b/0oQBEEQ"
DATA "BEEQBEEQBEEQBEEQBEEQBEEQBEEQBEEQxInhh7/zHwRBEARBEARBEARBEARBEARBEARBEARBEARxsvj83YYgCIIgCIIgCIIgCIIg"
DATA "CIIgCIIgCIIgCIIgCIKI4WcVcEr9JU4KX/8xQdRFFZuXwCnJgSCIj4ElbR5tIUEQx4hD2D3aQYIgDoljsHu0gwRB7BvHaPtoAwmC"
DATA "WBJzbdO3f58P2kGCII4FS9u7JezhKcmXOAy++QuCGMYh7d5cO3hKciYI4rhwLHZvjh08JXkTBHEcOEa7N9UOnpLcCYI4LI7d7k2x"
DATA "g6ckf4IgDoNTs320gQRB1MCp2j7aQIIg5mBftu+7f0mDNpAgiENgKds3ZO/GsJQNPKVxIZbDb/01QSxj++bYvRp2cKxPpzQ+BEEs"
DATA "h9r2r6btm2oDaf8IghhDTdu3hN2bYwdpAwmCGMIp2b7aNvCUxokgiLqoxf32aftKbSA5IEEQMZyq7atpA09pvAiCqIdD2r8///cd"
DATA "aP+IQ+An/0B8VNTY+86xeSksYQPH+npK40YQxHzsk/vl2L2pdrAGBzylcSMIYj72xf2m2L4lbCDtH0EQAO0f7R9BfFTsw/7NsX0l"
DATA "NpD2jyCIEtD+0f4RxEcF7R/tH0F8VND+0f59dHz3c+KjgvZvh1MaN4Ig5oP2j/aPID4qaP9o/wjio2If9m+uDcx9Bu0fQRAloP2j"
DATA "/SOIj4q59m9pG1jT9tH+EQRhMWQPanPAEjtYWudc20f793Hxu7/0C5tvv//awa+u7wN+U34Gfk++B/zh5+9Ngq1DgbrxPIVth7Zt"
DATA "CmJ9Wbo/tu6P2J/PP2106cd/13z+9N82W/zjf+4g5i3cq5//JL8DfyLfA35b6rBt0bq1fVo3x+fw/fHzeKn+eLs0ty8x21Y6jrH+"
DATA "p+DvyxmnPxC5WPzpr32VBX/fvvr1JfZpar9g72wfYPOAmM3TutTmKfQZau8Afb7aPYW1qdS/5fv1JfYp1q/cvpViyH6n2vyXv/7L"
DATA "k5Hq4z77NjQep9i3lL6hLbB3+om2qs3Tz5jN0+tq8/QTNk+htk7r0U+tP2bzhvqmddfu25c8buzbrg+ptsf4Ywox7plqm33+3/z4"
DATA "cwd/Jddy4e8tHZuS/sX6mNO/OX0c6t8x9RHtU1uHT7VH2gfL8/R3tXX2U7+vNg/2DjZP64Vtxd5Z26B1a7u0Xvt5KmN4rHq673lY"
DATA "09YM8cCxPo7xwlwM2d4huf6ZfHcqhsYhNQbs57x+qk3S56o9gq1ToG3geWg7/Hn43e5tcU1tnn6m/IWWR6KfWi8+0WZ9zty+5tqE"
DATA "OePpx3TKGnfq/Syxk7X6GZujqbkzhBiPzJFfTkxkCP7eqTo1t7+5+rJkf3NtYmlfc3TG9hW2DjxP24lP7G0Rw1Doz5bn2b56m4d6"
DATA "ATwXNhWoOba5uhwbX+ry8v2trcsxfj6GIW4zJB/v4yzFkExLONMp9XksdngMfYbN0/ZZf562Pba3zeF5CvTZxoVt/cC++nys+j23"
DATA "z8c6p/et3zl7tlxZ5MQMxuDvn2oXYrKr2feh2NWUvsfuz+372B5kSt+H1n1ti9ojtMvGbNF2b/PQz7G4sELvR/3gj/gEl0Tdh+j7"
DATA "0LjP1Xc/7iX2sbTvY/q+777Pmeslfc/Nzxmyb2P+yakYklHpOjIFJfZ9CRmU6Mi+++9lYHke+q82ST/B8dAvb/Nw3efCeJ7nbarv"
DATA "P3hkrf4fuw4ceg7sww4sPQdinLRkXHN852OI1TFHD2KyGAPlMC4HtUeQg9oj/US+Mz7Rbh+z1f7hU+F5nl6DzdN7rM1L5cLgGeCS"
DATA "2jat9xD6MBaT3Ic+jHEoyqEvh5I5neM7noKxPpeuCVMxtn4dSh5DY5+7j6otD7VH2ha1RfhUW6Tttfl/+jn0noeNYaRsntZp/YUp"
DATA "WWj91I3jmytLyWJMHjmyyG3jFP9hDLF6hvo0Nr4pGzCGWD2lOvyRZQIe5ts55s9D3p8CsYuSGAmeMcUWTJFLal92CnpyTPPnWGWS"
DATA "04ah/J4S5LS/hBfORaneLiWXHNmMjWlN2cTqHpIN8v+szUO/PM/Taymep/8Gm6c/w+Zp3TGbqs9G/WgX6tY2a71L64yXzTHPpxz7"
DATA "+NHmUyrWk/J/5iBV11gbx8YuNe/HkOLOpeNRSz4pGR1KPikZ2WepLdI24BM2ycsHPE9/TsUwFJADcgDB8fRnrVfvtzbP1m15pOeT"
DATA "qF/bHOOnS8lnqv7UnGM19KfmHBvjeDkx56VtUMrHOQdjbZmyjs1FqW7m+oK/dDmBi3k52Rw92CT9ecjmKbTf2Nvqz7B7+rPfO+u1"
DATA "lL/Q169ts3vnJeWUw+n2rU85NqDUPh6DnJaec1P2/kN+1LlzfGiu52DqmjIW40r5fefIq1RWKXnVlFVKJ2P2TtuMmLC3SXot5c9T"
DATA "eeScC+NtHuTkeSQ4pPUXQlaeoy6tWznzd2m9OtZ5OEVeS8/DodybFHLqncJ3aiBnnc2R5RS5fMkys/nIkNkQz/M2T2UQs3mI20JO"
DATA "sHn6s61fn2fr1zb4GImVGfIAqWecm0NI7edTPs4cmefIOybzEkxdV3PiVik/dy5yZTeFI86VXaq+lNzUHnnZ4azTobOqVA42bqu/"
DATA "49PzPL02tLcF9Jn+LCxvU7Xtdv8MgD/W1rmcOUudy5PblDyjubLL9YFOke0QP5+LnHVhSlyzFnJ09NTkZ+OqiK3aPBjYO5sH43MA"
DATA "cfafwts8xG9j+X/WnmpbcA4WPsEjrb228sOenPp3uvq3hAynxBRzeWFKprlI1TlFJiU+2hKk6q2hj/uUoZVj7FwVtUX4hM1DXBhy"
DATA "LPXn5e6d/RkJlkMqtO2oH3LEHhpcFXLE+3n7kGNpbHSuPubqIud0nuymzOGamCqDEn/sXHzJslRbof3Bp7dJiC/YGMMUm6f3eZvn"
DATA "5ZlrU/chz1wOcki9zNXNqdzxGGU5RZ5T5u6QnEpQwkunxuOGfK8lSNV7KjLNXSdgjwC1R9pPy8PQ99hZVYgP6+dY/l/JWVjaNnuO"
DATA "tLYf9evPqN9y1TGZ2veRl5JpiY7O1dOhemut28egpzXn/ZA8hjh1DUy1aaV+1hrI1bc5HHFJucZkO6YvyEeGDNRe4GcbX/D5MGN7"
DATA "W9yH+hXe5mlb/Jmqtu327D/wU8jV7s+ps+U6e0q2IDeunEIpfy7BUN05/ciNGQ35VEswVHeOfuXaw2OVr9oM9Fdtk+0/eJjKye89"
DATA "9VquPw91D+X/WZsaO0M65905K1/790hqyHfOHDyE/tZez5fW333KtzSHJxcl693U+FBtlOhVjj6N7UmWkvMUGdtzSW081ebmeVib"
DATA "p797m4Tvje1tY/48K+PcGAlkgvfnAPBJD30Odfm4dTkm55K1Y0xOOX6FUn45RwdKfaWlSNWdq0cla+yQLh2jrGGTYrL2sQVrk/T3"
DATA "2FlVtl5r8/RazOaBR+qnP/PU2jzsnf17c5CXtan6u/VHfjS9Tun2VNu4L93el6xzcnXm2NqS8R6Kh9RCru7MXVNrYymZIz8vhtjf"
DATA "FvIxhhgP0+v2rCrYI31eTlzYcslYvjP25tamYo+Od1Ts2fm2/rkyP1UdPwU9P4RdKeWMNWPYOT77Ugw9o7Y9HNOXUiwl9xzZI67q"
DATA "Yf++kM+D0Z/t3lbrwt8Aju1trV21HNLmVWu//Jmq2EPrp987Q3bepsbka8/nPxa571vfj0nnS+W+hK2ZY0NLxnTIj1oLpToyd+2s"
DATA "jdL1awn5x/42b+xvDNn8P1yL/a1KyL8051n7HfMXpvbOsfq9fGFXa8h/bhzz0Pp/bLp/KNtTWl9JzGbMr1mKoWeU6ETpejmkG6UY"
DATA "esbcOZU7BvCHxRA7m8/+nV7EGWCTEF/wNknb4887BYe0Ng99jMVIIJfcnGdrU/V3++5c7p6/hl079bkwdX+99FwosW+5Y5B77xR/"
DATA "cW2U6EItjlgbpWvUPsbCns1nYc9UsTzMj8WU9zz83hl16/XY3tlySP1Z643JFzbV5/9hX67Qeo91LA4xL6bur7+EeTElDjPmr5yC"
DATA "oeeUjHvpmjg2/qUY26PMHbepPuSUPww/x2IMOE/Fn6uC+IK1edo2//d5/d5W+2ptHvbPPhdGr9t3PbxNBY+0n96u6ifsqZW/P5s/"
DATA "lQdTMo8+whypOU9OYY6M5c3UROmY11gHl8LQnqVkrPY5LvZv8/pxieU968+wSdpWy/PQL+Sp2L2zAnkqsfc87Nn5sEulZyTgXp8D"
DATA "OMZTLRc+lnHhfFl+vpT4IadgzOdZMr6la9/QGE/F0LNqjc0UH/EU2LOkFP5Z+HvkCnsmqeeQ3iZpn1M5zyqnKWckqOytPxLvztn6"
DATA "MQ7+7D+bUx2rH/2YOzbHMHdS82fK3Kk9f8aeVTJ/ao3PmK9zDkrHtnS9y80rqolatmyKT7gmYn9D0ufooa34m+QYI/s3z1Nn2+un"
DATA "39vafbO1eZCtz3m2iJ2R4Pfmtn7LUWGztc3Wph77GE2dR6W84hBzaagtNeZR7jhN2b+P+TJLx7F0fcsZzykYe17JGJTEtXL8wFOR"
DATA "eg5iAGiXz9FDP5Cbp8g9nw9nksZ4nrVL/mx7fA7Vj7HyZ+ejfnBUjI3NhUEfPAeOrQuQzzGM1T7n1THPqSXm1ZgvskasqNa4LYkp"
DATA "68iUeVEq7xoYGy/EVO05zEDqPQ/YDnu2/dj5fDGblLKp+O7Y+8IYI5sLY99R8e1Hn5GvjfFKnZFwTONVOsem8MZTn2Olss71eU6d"
DATA "W7m2MHfcpmDseUvG5Ev8vVNQMm72DCn0xf/9XPTd/g3dFM8DT7Lvt2H/7O2R9+fhu/5vheB67Bkl/kLtT4xHxsYNcRgbe1lyzI5p"
DATA "vtWea8c033J9klPGqebatSSG2lMq1zm+3aWQO3Z2bmsf8Y6HfdcDNgPysecwqyxhk+z+Gbl5OTbJ2lNwMW9Tbd3W5sFWw17b+tF+"
DATA "8Ejto8+3secjKPyZrZCn/TubxzR+pzj3atq0fc69WuOROzZTMfbMUllOiU3l+HOnYuyZS4whOFLsfHuVuedh1i5Zm4QxslwMNjXm"
DATA "LwQPszzV2lRto9aLT+1L7CzpWP02LgzZ2b/nafN4fGx76TEcGscvfR5OmYu15+HUMRgah31gynpQKxa1L0ydV7G+w2bAblh52bw5"
DATA "RezdNnDIHJ6XGyNB/doG+06ePfMUbUc/Yrk2CtSvsrFxEsRKEBuxOT2A/RtJNi5szzA8xFh+hDl56HlZyityxmAOxp47xfZPiT/l"
DATA "+GznYOy5U+ZSSi5D77Z5m4S9obVLsHmwTdbmeXs6xsNSMRK0NZZTHbOpkEXqXBgrS7Q/dzxT7w0fy3jmzNFDzc8p9mzO/Jw7R0u5"
DATA "+pKYYu9rx5v2hSlzqRa/8Plz9vw8uz/0Ngl2CTY1l+eNxYVT5//Zvo/9LUx8+vpV1vhMxYXtuPjzC2uN6ZRxrbG3PsRcnTJfx2S3"
DATA "1DzMlfVU5HDQ2vZrTkxkLsaePWX+TOEVliOlxsa+14ZPmy8Mf5h/T8LzMG+T9FqJzdM+Wp4HuzRkUxEfSdWPGIn1Q8Zsth07vC8M"
DATA "P2fsHK+p4zuVO47NnaXmbc7crc095sRTpmJKHk8uatuvuX7YpTHVNk7lFFPHxe8PfW6e/z64GGwGrtv8P8DmwvicanAwn2czlmsD"
DATA "2+TPSABiNhXxYH/ujI/zIMYTG0//N+dOaYw5j/NQslfO4ZNTbffU+FGO73Uucp4/xS5O5Yk588bD5ufF4P1t4GD2E/vD1N4WbY/x"
DATA "PPAx2CVrk1J/w8jWj+veH6lIxWCsT9LGevTT1r/0OO97rEsxZ16f+pyem8czp681fK1LY45trM0Tc+Hf3UKO3hDAwTwP0/bknM+X"
DATA "4mEqh9jeE7Yo9jeAbf06BmPnttj6MW7WpurviL+gfnxP68VnLMZzCuNdAx91fo/xwyn2eWp8qMS/Ogc5z59qF6dyh5L5koOhv+cR"
DATA "yxm2+0Lf7pwYRoqHWXuU8uch9mL9kbG/5+HfF07FYDDOyIPBp20/Yjw2toNxt/k2uWvh3HGvMeZT7decuT423w8918fme63+zPWl"
DATA "7gtzZDXFHubMj9qw53nanGGrx5aH2b0hONKQzUNMODf/T+VqbR7yVWycBONj8/NK8wttHkys/bHxtznPsXNnTm3sp9qwOXbslOf+"
DATA "1LyTnBhQjv+0BnL9uFPt4hyemDtH5iKnDTZf2OfCoK/WZoCLWXuEn32eirdJVu7WJqViJKU51XqvfWc4FuOxZ3ghzmPbbvsQ0wHL"
DATA "JefqwDGM/xw7NtcGHIsdyGl7DX/pvjBHJlPt4dh82DdSbUTOivYHPMn20Z55avOGYTdUfjGbpNetTUKMBPZIf0f+HHiY/pyb/6ff"
DATA "Lc0vxHinzoWJnTljcwxjOhDL5TlVXZhrx75Um5ATty3xk85FbjsOYRNL7ONc5LbD56iM6aw9VwXwOSrQB5+rgjiJP7/Ax0h8nMTb"
DATA "PP03HxfWz9jf8sAzYjbPxnrQB9g79CN27gz4Y4qn5uiD5cLHqA+lNmzMpnyp9qEkV2ZpzO37UjbxEJiz3sZkY22Gj49Ym2RjJLG9"
DATA "J2IkKZuk/156VlWK50EvvD1F+2P1w25be215qgIc1a4JVraWTw6NUWzNOaROTNGLGvHfU7YVS/okcv2yS/WzFl+ugdy2zFlfUzK0"
DATA "OXT2HCwfJ4FNsmM4tPf04z1m8/Q7YzbPxpxLbSrkkKrfrgV+b+55sH137kvWjZzYb0kM5VjsxpjtgMxKcmVq+vqX6lcJR94n5q6v"
DATA "OTrpbRJsho4JPq3N8ONmbYb+7s9IQGzY5uYB3ibhus/RszZJ2+hzANFu6Ii1edZux3ikysm/04b67TWfqw3Y8bJ7f5sbeSj9GNOR"
DATA "JWO/h8JcO5ljQ3J8D7m+1zn9mWvrc21jLeS2Z45ezonlWSB/DvDv8+K6zVXRT5s/F8uF0X+bcxYW+jGUa6NysO96gKvq51j92Dtb"
DATA "Dgw+if2/bT/GFu0Hl/RjH7OpX4KeLO3DPEZ7MtfHv1T7S7nwPpHT7jn6ONcXjvlsc1VsrgdsBv7d5s8h7ultkl63e0//zDGbB7s6"
DATA "di6M5ag5Z21ZDhmrX8fL21RwSNQPm2rbr9fQfow76q+tL3PtV63Yyb4x107WsC2l8c8l21za/lrIbdMcPZwTt8vxg8NPlfJX2b+5"
DATA "AcTOkoL/3+fCWJukv8fySWJnwlh7am2eyiSWT60/44wtRewdktzzBTG+YzEY2FXYU9Tv9cS+L6zPgr0+pO2qGTuphdw2HYOtyWnv"
DATA "nDbmtPNQyGn7XP2r6f9O+eg97BkGCsQ+Efe0OXo2FwY8ydYPmxrL/dOfY2fCxM7Cwqc9hxn7Z7svx548xSN13MZ4pH4nZvNithU5"
DATA "4bZ+Bd7LA1A/fkf7fR+OWXf2iRp2ch92p3a7prSzFnLbNFfv5sbpSv3eubC+qtT5doh/6mcsDoAcEthWn5MMe2rPSMY7GDZ/DvzR"
DATA "7j1TOuT3nnrN88ghm2e5JGyRtdnWps7VH+z9h/Qn5/zoWjq0L393aVxxrn3clw2qZasPiRrr5NLxuX3BnmVg/f+Ie6KtPv9vagzD"
DATA "55JYHqZyH9p76tjl1G9tqt+bj+1t8YwUT7V6NHZGGID1wK4JX5oezY0xLmkba9qjWly2Fko49lxdqxGXK4mJ1MRQWyxPGoudD+XP"
DATA "WR7pbRJ4pLVJGBd79jxgOWRs/2y55FiMBPVjb27tkrfZeL59Nw/2Gnt+q0+xXJiUPoFf41PlafO2p+rSselTLG46xz7O5Y41bdPc"
DATA "vKWaqLE2Lh27PQaU6LPPnfO6nHMm6diZp7G9s38Hw34O1Y99ecrm+Xc8xngq8lXse3kA+LBfD2I6Zeu38WDoVCwf/EvTqRw7uTR3"
DATA "PITNKUUJl146dyAnBlcaE6mJkrbl9NXHPfEzcuisbGO5HuAvlsfEeJhetzl0GHu/d47xJNgk/bR2yds8vz9P5Txbu+11y9vsmG6l"
DATA "cm1Unjb+rPA54R9Jt5a2jaV2sgZKc5lqcPa59ip3/Et8pIdALT3272IM6S3shv7s38Pw+2f8bm2S/g57gX+P+Qu9TUX9qDe1t7X1"
DATA "W5tk7fWYv9CuBbZ+r182Lox4cCxGgrpj+mXPLjxVHduHbcyxj4fAXK5eY93LGcfa8ZDaKGnfXL21eRgWNocupbd4ty2mv9jDgUN6"
DATA "/pgbI8E9sb0z6rc2KRbD0OuoHzwslguDXJWh/ELEgxG/tfngChtzRvzW2lS95s8Ks3pmz9v6kvQsl0OW2ItSv2QN5NqvWryqln0q"
DATA "zTk6FGrpbYmu2vyzmM7iLGOb34ZxtrbDckj7+1hcdYiHpWySz8+DXUK7S895xqe1STYurD8jPmLzFwFbP2Ivfmz9WWGI7xyzruXo"
DATA "276447Eg1f4afCpn3I7BL1nT73pMdtHaDB1TvMdr926pc55jPCnX5qF+bYO1Szbv2e4PYzYVfUTd4F8qm7EYDOK3sEe2fsScY+2P"
DATA "xWCgc7Z++CTn6NTYe8KnqnOldrI2Sv0AJfkvtWzT1PyiQ6CWfdyXjlrbYYE9nN23xfLnbFwVPGlq/p99fw45dGPnMJfUr3KN2SQb"
DATA "J0EMZqx+H9tBfMeek4DriPNYm41/Q/370LtaurfEHvvQyOnPkExyx2mJOEhtlPo+j80uWj3NOXcu9g7GEKxN8vlz/j0P/65HTs4z"
DATA "+up5nrVLpTa1RozE+iLxXq/3R/qYuT1zRpE6f8H6O1Pxo1PTvxJbWRslbczp95jspvgMjxG1bOS+1+wx2Dw6C5139vfYu22wGd4m"
DATA "2bphk/T3MZuE/aHnSD4/z8aFh2wS7JK1R9bmwR7Z2G0Oj8R3h2wqvmPrt+cWAvacRNv+ub79U9PDfaHm3jKHA5XGapdEqU+zll3M"
DATA "kdNS+5qafiWfz2v3b9izWZth9QR5vd5m2ByY1Lkq4EvWXsAeIeacGyNBbGTo3TbVFZunAl9k6qwt6+/EmmBjSIjB2PpjMaRU7Mjm"
DATA "3HxEXZxrp0ptVo4cc8ZDx67Uj7gEatrHfXLFQwF2yebz+jND7b4Neze7fwOHwWeMJ9m48JhNGrJLNkaS+26bPcMQuSrIU/E8FXUP"
DATA "xV9i9dv4EdYEq5O2/eiTjSEN6eRYHtKXppNz7VWJzZoa643FUGrt20v9lrVsY02uOHUvUxs57fN7uNi8A4cZyuu1v8Nu2Hgtzqvy"
DATA "9gIxmNgZA+BhiMOofnibF/NHxmyq/pvfO1t/J2wqnmFtKp4Rix2lzmCAbvq4NuDj5vtYr09NN5ewV3PjvCXx3yX8pPu0iaW28ZiQ"
DATA "0y/YpBTAY2xM2NskxIRLbBJySmyMBHVDH2I8EnkqyFnBM/TnsVwVXz+eEeORsbqhf7H6bQzJnw1j9dLzVMjZ88gh/bQ5SV+6fta2"
DATA "V0vETkpiKFNiSTU541L76aVQ2t5cOcRk6PN67RjA5g3ZDHuGAcbX8zDERobitoiN+Pr1eixPxZ87k6ofvk6fC2NjPLH2D9nUVFwb"
DATA "HNLKFzZP5R/LFYrpqd+b+/35R9TTKbZqyfhJCfZpE6fup48FtdeqsZgwzhjwsREft4UvGrFbxEZsfARz2vqjY+cMDMVV8Qzvb/Nx"
DATA "GFs36s/JhUFfbP24hth2Kq6NuLnnqZC1P8PLjleMS8Z01fPsL0FXa9qrJWMnNbBvmzjHRi6BKW2uuTalxgVzztol72fOidva/Lah"
DATA "XBL4e1I2Sf8tlqti48K5Oc9ou/0csqnWbufySLzjYW2q5ZDgkbB9dnyx5x/SWZt/aTkk/AofUWenxHanxE3moKZNzLWLx4raa9OU"
DATA "MfZ5tzZua3NJ4F+GTdKffR6GP/ckld82lqtiz1Wx+XOx+m0ejM+dG8ovhD31e3Mb2x6zqZZDDu3NMYZof0xvwbE917bfgU1VwJ7G"
DATA "kDpP9ZT1ttQ+TYnz7AOxfi3JG5fElHbXHOuaMbGU3zmWiwGb4WMk+pmbqwIfvbVJ9hlDuSqIO9v6EXv2NntobxvjkZarpnikjs/Q"
DATA "3hn8EbD7f+zJVX8sjwSXtPrl68f12N7c7sntp3/GR9PfQyLWrk8sLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCws"
DATA "LCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCws"
DATA "LCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsX2i5OJdydvb4+Pjw8HDfKXLh4fHx7OxMvnHRKeGW1D1yedY9TxfP"
DATA "Fy8vL6vV6vX89e3t7f39fS1febp/rvucyD3a4/g9KiV/SxCbfWK4vyn62/ZJl1KutkV/S9816abuXS8vcsPq9bUR3sV6ff709HT2"
DATA "/CxCnd++xF2Tbgp37W6zpZV38+XrbmluHLitfUbRbU3brq5erl6ur1fXQXjX79fr9frp6ukyCK+97S1228Snzb+t/XrQx6YE9Wy+"
DATA "Jv9+I+V2V/RX+xhzX7hxe5+7sb0v48abm9eb17db0bzbtfx38/Qswrt+uVqtLl8v3uS//AfmtXSohxHRtBqIG6GFu9KKt631rlva"
DATA "JzQPqH3ny83q5vX19vbt7e7ufX13J9P27u75rrGFopHXV+9X75eXa3/rTgjumfrQzsCV3mkk2b8zdLTpTluCRm7r2y4ibdFfu43y"
DATA "9+7akrh3J0R767Yxcuvb3dv7/fv9ev3w9PQgmie3qvDuZDrf3r7LdI48dtfk8Ny6Te6OQa/JQc9RWrXZrr3d0lZqlKngZiyHozff"
DATA "vz+IzXsM03areW8PD7IKy/Wnp/TNee32N+d1eqjd28m2q2K7GKDo710phOoit7fLVef28Pvu9u18treDLawfH2WxPTtT4Z2fYxV+"
DATA "P1s/Pj08PTyIUAdvb5/u294SmtjT0fah213Xze07nrNjH44d7ejOdmXvkqSu3KMVmIYM3a8ViOadX7xcrFYXFyq8iwulMKp5KlS9"
DATA "f/Xavz+3AWMdSEog1YGgpB3G0ppzz3FsCww7ajW+Rg3rs/On82dhz5eXuthevV5dqeZdrdeXIryGwqxW569nb4NtwCKZbAMUqkoN"
DATA "ptNbc+wZUYcCOFZkxmu4jvbxuxkVq+P58uXyZXUl/O+63XnIgtEI70psYVPFW4VmjHclXgXq2Fax+2LHHnY4lCVDlkbtuGKtSl6E"
DATA "PF835FmFd3v7dGsWEpGqFUGnlmaWZbckoz95lWy/4AlQayTbr+9UOEbcdiS0X8u2GqvMkVpQzavQv8D/1mshgCq8u5fV3er1Ngj1"
DATA "5l0IzNPT1XOqMR1GPNynGBEt7lPLeyzxgXW0RGU3lS0B6j6jX09T0XA9Wwa3ul3d3r5qPe/K/3TBeH54eHlYrR5e70V4clk0UnXy"
DATA "+fkm6Gm8nm57Ih3rtSfSMSjednFOCahP1LqkZzdiA6yrqXxWTatQkxC998D/guY9vrw8rlaPOp0fG1uo1+9kOidq8mwm2qatAKwc"
DATA "R2tKda4z/VuL6jveZVt+ULBwdVlTl/TtBj5WVdPIILvH9ZkKqfG2rM63XhgVnhBD0ciXB7GF93eqqKlmddbTWKvyetipK9XDHsnp"
DATA "Lu99omVHdltljy5NqEw48tl5q3kqvIsgPHEYXLyvL+T6uVwXVi0K+fjwuteWDVVmyM1uPdrW3aFIvVHdrlYdotSprqOIvrrmWlPb"
DATA "u1b3dNG6qsTbovxPNU/oXytU8aqeB408k/n8KBuVWOO6DLpK4zrMyFfXZUY7f02fG3VGobNqxllS1/+TUZ+sqs/KYFbq/lMC+H4d"
DATA "/H/XDf9rPFivwv9E1lLf077bF62wsyjutLBLiwy96nANGFrPj7pcZaRCqTF4VZ6vRfPEg3Vrbd5uOqsjQRTy7fL9/fJiLap6cf6c"
DATA "rtEuo76NuyZW6XS/wwPUyjDKCC3qLLJFVT7fPt+qkO7EVSW+KiM8cf+9CLG5Facqrifr7POYRCu7PHComZEqO3V2uusp1VZbu80x"
DATA "5jXKifIq3Y3Es9zyIm6+1b3yPKlqS2EejAvrVjzSN+v1zdOTqCoqlT1yvFLTUN/S9mp/tEdbGuk9Vu4YCeoJzVrWNK8yPGWo1g7n"
DATA "Xkmtr4+Psi4oh8G0fXxcPTyo8O7VqSpfF/ffs9Qq87xqYwtE4Gml1eceAeqSvJYDORK0Nb1dMlBQ78vZ2Uruf3s71+lpKMxZq3nK"
DATA "noNDerudk3olRtKr13VwsL2xMU+1d6DeKPOxY9ddh5J0qkuXE4yq3wq5UbyksqYKzdMiwrtQIV2I/8+QZ6l4t5DILJeK3kJ16301"
DATA "2fuFUVOM9PgGWFNqS3N51yIzsJ6bDVX9+haq1mVBhHQVXFVyVYR3GYR3rgHg5zMRXrObe5CtyrvayDmtNs4X0+pUs9NV9+lOj3nG"
DATA "CJRbtvygJrlUr/LXpqoQFtKFIWiYOKpE8662q7CoZODOqzMR6tnb+5m48+V6jKjlNzy75YNSscoYWbC3xr7HeHpLf2dq9GlUj4Ki"
DATA "+vdQp8SFlMHcyrSVAHCYtiJVUUhh1cGperEK7nzZqYhQQ73i5x+vfajtGY23tUdF4wTqlsc0d/IsNEnzuuMVrT+EeUNgSPif0j9d"
DATA "GoSq7Mhzk87RTOdwXet96dfvV8yx9uc0f1g8fUbcsZoJ3tShJ51J0WdPvU7tHvDeVBzcfBLpXd2/vooLS4R0p77TWxWe+AV1IbnW"
DATA "7VxLnkWoV5ois538PamVdqE7r1NdMHLbPcCtzym+5FapviImmVOPArhHiJtPijhVRMP0EZ2dh07n1+CRfn8P3DnU+yL/aZrHzVve"
DATA "IwZ70Z3Xxb3orDB9rrQzq+bpdhB7jMlMnSiv6D5ETFhYGF7P1KtypsILcV6dtrojkf2cuvM1GUaEKiayMZK3r/oQdfM3DMYvlVM6"
DATA "EulJdkeiJKljUv2jk2xpN2/MowaeImFefUpgz+fr9ZlonlDqR01Ve30IOw9x5993HAkNAYSmigqPP2WxvhgLGWNJ/fW9Mw1iXCny"
DATA "mI4h7hRxSb3qP70Ldb7QZTUISTYeumA8dhwJwfMswfNmm/copDpcD16YzmNGu2M9Vt1pHeuO7U//OYMMqe/bSXGkhMg6RjhSQkBS"
DATA "iV7IqpLQeeu2P9dpK7NZhCeOPs08ODsLjgSd5nJdFHV9fiFCzX1Qt0edyOV4jyxp7q4r19ed+Q6TaZ9oxy3G7pwqRzhYhEHiUW/y"
DATA "KCV6sqheifd0622R/ZwIT6SkbvtzXD8/V3e+pqSKs/XpUoKYosBhFN7GHzXQq8xORXvVJ0YdVtLV/gF61Kncmd9BFra+EQ+zek9b"
DATA "nne19fMFITVCbbZzwZ0vztYr2ajo94XbyLMaR0LGs/qUdWLHbNU749nt1k6Eu6d1Cv4tscgb2xtjYPo0cUjdhniuuE/FJdXwPBHS"
DATA "1ZUIT3cewvOE6K1WQvSCO39nC2URVmerFokLJx+W0bdY1zL6tjOSnSdFhmuQFXVqdWZ3iH7p46Tbd0/y392thHPFw3zzKvu2G80w"
DATA "aIUkMhV/vghVLod03vVtk5H6cq/cRvwID+ps1UhSzvOKuhcR2kD3+s/YPaZb8I+2ys4yFWVeOyMdfeBK922vd5rz3PC8ZjPckOdX"
DATA "oXnvms5x/3SvvFBc0uG6rMJnspKcCePRZTv1wAhPKelhp4uxHjp/U5wERdlQN6Sc5Fx95tU+UpMhpS5hc8227T4SMJLruskT5+mj"
DATA "8jylNsJtzmUlOX97vxDSozFPWbYvxGE4+MjJnRzrZYcERVmdJ0JdAumM7SDt6nCgdtumQmpSD9YPKrywGW41rM08VRVrhap0WxcS"
DATA "ZYzr3TOb3fD4M4fYnp2aA/30HbWqnkGCHBVOka006erohfI58efJPFQhSUS3k/O8WzAunuV2hDBDUuVaPIbNKixPUX9h/6E9925n"
DATA "Wg92NcJhU32Nsx+jqTF5uUVkmHB1OVBTqShS8xjZtZ2rP+/pXHcSqmEqJKF/W+EJLVSu0ghVHIPhenAXBmHL48IbD3ZBiIzdIIE1"
DATA "3U1Tl0R3c7iPixrHOVaPbUW9W92n6DxUmqc/i5dUHHrC/2RDojsSuedJmQ2oTcj/k9qDUMVdKN4ZXXmaRCLlQiUPrtdjM5W3Ohmj"
DATA "KMOszhrljhS7mtihW8LzQlHbJtNQX9tqpu1NQ2FuRUoheK7+As3/0wXmoY3CqcdQgp5yPfXkoUfb4npd2ukeo+ve2jOtIzwr4qG0"
DATA "M6stut16xy/P4tB7Wd1u/XyNht2H6anJkyqkNoSp3hbNC3zULKzXx1cNF4sjQRee7GcnmN7Ufg/QnR3hiXO6Hsly7qD+jN6WNuYR"
DATA "yLDMQv32dsFoNExk1Ng8xIU1CNd4Z8J7IfKffP9MvDDydOE2PXaSfriflAO0Jd119L1/T28FGSN1jhz0JnS/iM9TyLC0OLyR2mSY"
DATA "Ni/J7PifOlUvdCXRF0A0LrzlhcJgwvfD84U8B+9MyePdnOxKrLD7nhl6e9orO4vblaLTxBTHMlNCuLBSGFmEVcXUAajvTl+qkKR2"
DATA "EVKzkFhSrZvhsPCIw+tSk7D0ZWt9uqikb8Do853EvADGJbD9es+WpourJK6J4xRLXzFSz7M4TzUl7VK8KiFUqa+qtvHf6x3/E6K3"
DATA "44XiXghemOCcEWIYGhAoT1kTvMSmCcHQmxSdMyZ4UIhGjil6pY1VLtw0VsNq10pUrm+UqtyE/D9dSHQlabLtZRVuQh7BkfAqjoQb"
DATA "falauU2IwjWaum2DqHBWGyKMZaIcUrzGFH97XIg55KrDrkQYuo7oKwnt9LxrNeyunzwpPE9JcnNdw3CqqbLxaDLYRCfbB4XBGWmE"
DATA "2wX01pMiUSSMxM7Kxu/s63KaWPntSlOhOgyaleRJ3Qjt9NRnQ3jibNkmDFmh6tZDr8sQ6DRXDZbt3MRmGI6XInkRaew4ZpTU+BtT"
DATA "4i/hVTuaEBx3wts0z0+fFhKDxJEgfK4JDIVXFYK3pSGA4ubTl2cQhbvTTdtKc1KVaktg+Eanv9DI4XZ4TtxfTwaKl+RWIJ7P9Mic"
DATA "v8WIsV9233GtdEueFA22NdEzoSrK5wKF0cCQdWFJWL2hNpptJZQH12XbFuLC4i4MbyRpWmUr1OKWpAxmlky84Y9/P4dO2Qng2uhN"
DATA "+FqpSsiq0jy/5j1fDQyp+deomnt5RhR169oShQzXm7iwXL/X799LtP1+pVHhFLtLtiWD4xlJ9sRi18/El+33+2X3JddCt9ptLfg6"
DATA "ZPpJuE3/F1xSwvOEwoiQEDBSoQbhyc5DOLW+qhA2JDu/oFjJVlMfnkNcWIrshcUojIgrspz0y+5Lo6KJuxs7uptDpXrti9jvxtBr"
DATA "EYeB+AtW4ZyXa+F5mqnWuKqughMmuLAu1MN8LtN8u20Tst1opGzbRHhBrC8SFz6TqLDm/4of8VxvyGxOBsEbl07sW51v9kuPSPWo"
DATA "Z8x674qYqsZvp4l+ugJICFP4XAhhikYKLRTHlkzPpkHNm0e7dF7N/9Mc6Tb9z7ZnjQZt/dH53K67Kno5pgXUF/VI6Y1kap1LFz0B"
DATA "QsNFwY/gYx6aefr2riHMkOe323nIRkVfnmm/r9u88J6/bGC2TZJAsr7aUN4ivzAmxBiRUV9l+8Uodoqc5LCo3SqkgaH2vpbPhZdn"
DATA "Vnry0JsyOp3mumvT+WzOwnoPtrM5kUhf89LMA2lToDBNm17kP/WqdpuU0ybLMLxGxmZ2W1KsaYBARYLImcW0WemcNnnrJIXzNEzn"
DATA "EFLfBtWbdF7RPNl4QFODv1AYoDZqHRol12UNvg/0clKjekwtNrOTwonTuDTbjC0ikWK+tr1VV08JSmp7A/XQ+O9d0DAldOoXVIVs"
DATA "wurtXljneUOeg9/+rvVIS7MaavOo4Twl4TOalRKjlWSvDLG4JHfKZU92GUIdzeEjobUhGK4BYJnOyueEzoXtXCPU1X14bb+5vvVI"
DATA "B42UIZDr4cwTXYPDQiJhYW1X+x5JfsOSYiygvEabe6PXW2ztGhIr5nu+tc3Rc5qTFp6lp+GEl6HbIPl2IRGfahsXVvd8c5yTbvMC"
DATA "VWl54Xl4qVqD55qdr++2ajxKnFuTWtZ3pXdmdqTs5NXXqr6c0lRplDpZDqpv7mpjn8+EtzWvbYXz/Jy3pRGS8rzA/4znWRyGErQT"
DATA "bqMJRvIQuR5S2JoIcPCFZTStz0diEzuL+vZ0qrfUJq3kAG8akKIezxRSnhvPc5O1uxXeefOeR+O21+vikpLIph6e0xxhJ2Rbrgtd"
DATA "1O+HBUZfGH5TMtQp2AmXNc5KMlasBTD8pS+mNEcaJU1DDQ2R3suXy5C226yqsm9zOS8hIbXxMJvr4VBFfYc1ZGG1/kJ5fEgwkviv"
DATA "nhdz96SvwsZb129edGKPFT8j+yttZwUZJkyxKFdfitLSrXcubDDaomcbyH/BPd9mGATy3MR/4VS16Rx2IVFHgoQ2NYWteRWuTZ3R"
DATA "9ul6VNK+IfLbNV69GelYySy+FBtsFLy5EY7n1DQMFZI67oTntUK6FSfpXeB5Gp7DQhLe/w1Hm3TeC26E2rwurK3S9CzxIzqzX9LC"
DATA "dIlMy60CdWnJGFcaWuXjsyZilZTzNm8Y6XQLuZDqemq9Kg/r4DttvC3NQtIkkje50GI7G9eWRu3eZUEKceGwIDXLkZCbWU30krLC"
DATA "8ouvLL8pfhSxpwNCzONKQuhCFoa+tqUZA0L/hMMETQpZ9e0q3PpUm/NfkEgUIpVNglG7voTr6kd8lkaqDzakBTYtBEOa0kgvq8iW"
DATA "wSwo/dlurWVfjBFV7E6ZAa7UvJ8feiekt2G9glepXpPqRRaXjWPgZXWpbpgQ/m3PfwnZ+WI72wRzPUdW88uDg+FSZKrBUF3Nk2Nd"
DATA "0syorPzKa9bfQY4UDU8O8KIUU1L619ajRyQGIb1eGiEFj4GeYBc08lrPf5ZYZUtVwsl2jUaGy5p3tA1hBi+MZiQEz3bbTiFJU9sZ"
DATA "k1V0OemyvCGGZCnSMEfqPL7n8FXWKw94EecpHAY34VVViUg2C0lz/kvDVMI7b02eX6AwsvCE77dCbVbtJoT5HlzYSpAu9Pj3kKk6"
DATA "q6VJMhxnwwNCLCJIiaHCItzGeWS11bOK39V5sn4SGx08A534r64wctmc/yz+wuBJaFftGz2qSP3XsvGQZwWVDE1VzS5uakRWieUk"
DATA "zYDj5GiEHSUV2j08ZFupZd6utnrMy/acvyAkiWHoZbudE5eUvhcchKrZk1uNXN20rq2bsG/Tl3BCY/V1kV124cTGdpbdzmriSmw9"
DATA "TxKhMXoU4Uf6jOagh3CcXzgBQhcSpXOBt4GqhPhvc10YTJttr9eb/D+Tnd/4C3WaCxd6D60Vv2BIJNQXkl6bVm3zC0taa+XkeW+8"
DATA "9HjRGDFyuhx5dGQRa6xzk7enaT7Y84b3NlRIIZ2vOaqkOf+vOTuxPTw7nLbRamRwbbUnkgcaKRuVEFO51evNuTDbtJB57R0p4Vv/"
DATA "BaPPhKw="
DATA *
