' marquee.bas - palette color cycling
' Exported by DRAW 2.5.1 (https://github.com/grymmjack/DRAW) on 10-06-2026
' 320x200, 21 colors, 2 cycle range(s):
'   1: 7-10 FWD 8.0/s
'   2: 11-20 PING 9.0/s
' Keys: SPACE pause/resume, + / - speed, R restart, ESC quit
'
' How it works: the art is drawn from a 32-bit image, then an 8-bit overlay
' holding only the cycling pixels is drawn on top (overlay index 0 is clear).
' Each step the overlay's palette entries are rotated with _PALETTECOLOR -
' the pixels never change, only the colors they point at. Speeds use the
' DeluxePaint CRNG unit: 16384 = 60 steps per second.
' Compile: qb64pe -x marquee.bas

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
_TITLE "marquee.bas - color cycling (SPACE pause, +/- speed, ESC quit)"

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
DATA "eJztnbGOHDcWRVuyLVny7howtBusAUUO7NRw4GAAL+CNDCygzNgB/AsOjfmFBZQZVrD/4Ewfodhfoj8odzWmWd3DKvZl1WvyFetc"
DATA "4ApCT80l57Hrsvge2f3v7//7/aPdvx692/199+LJ8+7rz1523/3jy+4///y6u315092+etW9ef26u3vfdS9/ftO9uLntPv3ypnu5"
DATA "u+u+evam++azt913n//R/fDF++6nb7vu7seu+/WXrvv9t65797brHu+e7p7vHu3+9/Fuj67r//1k92L30e7/z3a7x/ev9K0q7Hum"
DATA "ED300EMPPfTQQw899NBDDz300EMPPfTQQw899NBDr7YecUEPPfTQQw899NBDDz300EMPPfTQQw899NBDDz30WtMjLuihhx566KGH"
DATA "HnrooYceeuihhx566KGHHnrooYdea3rEBT300EMPPfTQQw899NBDDz300EMPPfTQQw899NBrTY+4oIceeuihhx566KGHHnrooYce"
DATA "euihhx566KGHHnqt6REX9NBDDz300EMPPfTQQw899NBDDz300EMPPfTQQ681PeKCHnrooYceeuihhx566KGHHnrooYceeuihhx56"
DATA "6LWmR1zQQw899NBDDz300EMPPfTQQw899NBDDz300EMPvdb0arX75vVrCCE8cGu+u6axgRBel/gfhHCr3LL/3b56deDd+y7w+NoY"
DATA "X/78JjB13Yub28DUdZ9+eROYuo7+0T/6t7x/R+J/g/+dxi4Vw9OxTY3x6dimxvh0bFNjTP/oH/1b3r9TevC/Wu2e/u1jsRuL4djY"
DATA "jo3x2NiOjfHY2I6NMf2jf/Rvef9S/tfKcx3+R//oH/3D//A/+kf/6B/+d8n/pmI4FrNLY5sa47HrLo1taozpH/2jf3n9OyX+R/2X"
DATA "/tG/rfXvSA/+V6vdMf+DEG6H7H95jf9BuFHif7r/vXjyHEK4EuJ/+B+EW+XD+3csJ4n/4X8Qtsgp7zv1QM5/4H8QtsiU9x3J/hf8"
DATA "D8IWif/hfxBulfgf/gfhVpmb/8P/8D8IW2Fu/beWX9VqF/+DsF0q9zT7X879L3XOcE1jD+HWif/l+d+lz5lY09hDuHXif7r/KZ8z"
DATA "tqaxh3DrjNZvI581g//hfxC2yCnvO/VAzn/gfxC2yJT3Hcn+F/J/ELZI/C/P/6j/QtgO8b98/0txTWMP4daZm//D/3z53w9fvO9+"
DATA "+rY7492P5/z1l3P+/ts5370958vd3Rm/evbmQKs+X6t/R37z2dvAkmMxp389v/v8jzNa9UeJX8n4KONbsj89c+u/tfyqVrve/a+U"
DATA "913L/67pfTX8b6n39fOZVX+U+JWMjzK+JfvTU7mn2f9y7n+p76MqPX6lvO8a/ndt77N8llJo4X2W/qfEr2R8lPEt2Z+e+F+e/136"
DATA "PtLS41fK+yyfpUp5X03/m+t91/K/a+c0FCrjW7I/PfE/3f9SNaKa/lcqn2bV51LeV8v/lnjfNfyvRE5Dobd8ZM+HXje2twP/8+t/"
DATA "a6wllPK+Gv631Pv6+cyqPyVzGgq95SN7TnnfqQdy/mMd/reWWkIp77N8llJo4X2W/lcyp6HQWz6yZ8r7jmT/i9/83xprCaW8r6b/"
DATA "zfW+a/nftXMaCr3lI3vif3n+563+u8ZaQinvq+V/S7zvGv5XIqeh0Fs+sif+l+9/nvb/Kd5n1ZbVvVuyDqjsj1R0vO2PVHRK5jTU"
DATA "GHrKR/bMzf/hf379b+q5yqqtS97X36+KTsk6oLI/UtHxtj9S0SmZ01DoLR/ZM7f+W8uvarW7Fv8rcabokvfl+F+pOqCyP1LRKXnv"
DATA "KjkNRadkTiM3hh7ykT2Ve5r9L+f+N/YdUTX971I+zaqtS96n+l/JOqCyP1LRKXnvWuU0lHykVZ9zYuglH9kT/8vzv6nvCK3lfyXP"
DATA "FCmftaDolKwDKvsjFZ2S965VTkOpxVj1WY2hp3xkT/xP97/Ud8R78D9qCTHXWEuwymkodWirPiv0lo/s+dDr7t7v3yv3xP/W43/U"
DATA "Esa5xlqCVU5jjfsjS/an55T3nXog5z98+x+1hGmusZZgldNY4/7Ikv3pmfK+I9n/4jf/Ry0hzTXWEqxyGsrea6s+qzH0lI/sif/l"
DATA "+Z+3+i+1hDTXWEuwymko506s+qzQWz6yJ/6X73+e9v9RS0hzjbUEq5yGcubOqs+5MfSQj+yZm//D//z5H7WEaa6xlmCV0yj5WQs5"
DATA "MfSSj+yZW/+t5Ve12vXuf9QS0lxjLcEqp1HysxbUGHrKR/ZU7mn2v5z739gc4cH/qCXEXGMtwSqnYXVe24re8pE98b88/5vKEdT2"
DATA "P2oJ41xjLcEqp2F1XtuK3vKRPfE/3f9SNaKa/kctYZprrCVY5TSszmtb0Vs+sudDrxvb24H/+fU/aglprrGWYJXTsDqvbUVv+cie"
DATA "U9536oGc/1iH/1FLiLnGWoJVTsPqvLYVveUje6a870j2v/jN/7VaS1DuXW+f/Tqnf0qtY25OQ+mfotNqPrIn/pfnf97qv63WEqy8"
DATA "xepv9+R96pgq/VN0Ws1H9sT/8v3P0/6/VmsJVt5i9bd78r4c/7vUP0Wn1Xxkz9z8H/7n1/9aqiVYeYvV3+7J+1T/U/qn6LSaj+yZ"
DATA "W/+t5Ve12l2L/7VWS7DyFqu/3ZP3zfE/D+e1rfKRllTuafa/nPvf2HdE1fS/S/k0q7aUe1fRKVlLsPrbPXmfOqZK/xQdb/lIS+J/"
DATA "ef439R2htfxPqSVYtVWyDmjlLVZ/uyfvy/G/S/1TdLzlIy2J/+n+l/qOeA/+N/VcZdWWcu8qOiVrCVZ/uyfvU/1P6Z+i4y0faclo"
DATA "/XZzG4j/rcf/UmtKq7aUe1fRKVlLsPrbPXnfHP+b6p+i4y0fackp7zv1QM5/+Pa/S/k0q7aUe1fRsaoDWuUjvd27VjkNxZsVHW/5"
DATA "SEumvO9I9r/4zf8ptQSrtrzVAa3ykd7uXauchvJcquh4y0daEv/L8z9v9V+llmDVlrc6oFU+0tu9a5XTUNbkio63fKQl8b98/0ux"
DATA "9PgptQSrtrzVAa3ykd7uXauchpKPVHS85SMtmZv/w//8+d+lfJpVW97qgFb5SG/3rlVOQ6nFKDre8pGWzK3/1vKrWu169z+rWoJC"
DATA "b3VAq3ykt3vXKqeh1KEVHW/5SEsq9zT7X879b2yO8OB/S2oJCls9l+Dt3rXKaVjtj/SWj7Qk/pfnf1M5gtr+t7SWoLDVcwne7l2r"
DATA "nIbV/khv+UhL4n+6/6VqRDX9z6KWoLDVcwne7l1v+yO95SMt+dDrxvZ24H9+/c+qlqBwjXXANd67JfdHlsxpWOUjLTnlfaceyPmP"
DATA "dfjfklqCwjXWAb3VEhSW3B9ZMqdhlY+0ZMr7jmT/i9/8n1UtQeEa64DeagkKS+6PLJnTsMpHWhL/y/M/b/Vfq1qCwjXWAb3VEtQx"
DATA "LbU/smROwyofaUn8L9//PO3/U+Zdq7bWWAf0VktQWHJ/ZMmchpKPtIqhytz8H/7n1/+oJcQsWUuw6nPJ/ZElcxpKPtIqhipz67+1"
DATA "/KpWu2vxP2oJ4yxZS7Dqc8n9kSVzGko+0iqGKpV7mv0v5/439h1RNf3v0nvPqi1qCev6rAUL77PMaSj5SKsYqsT/8vxv6jtCa/mf"
DATA "Mu9atUUtYV2ftWDhfZY5DSUfaRVDlfif7n+p74j34H9L33sWdUCFrdYSrPpsldOw2ttsReX9V7I/PR963d37/Xvlnvjfevzv2t6n"
DATA "roMUtlpLsOqzVU5DGV+rPufGcOr9V7I/Pae879QDOf/h2/9KeJ+l/7VaS7AcU4uchjK+Vn3OiWHq/VeyPz1T3nck+1/85v9Ked+1"
DATA "/K+lWoJVn5WchqJTMqehxvDS+69kf3rif3n+563+W8r7ruF/rdUSrPqs5DQUHWV8rfqsUHn/lexPT/wv3/887f8r5X1qHVAhtYQ0"
DATA "lZyGoqOMr1Wfc2M49f4r2Z+eufk//M+f/5XwPkv/o5ZweUwvPdcrOsr4WvU5J4ap91/J/vTMrf/W8qta7Xr3v1Ledy3/o5YQU8lp"
DATA "KDolcxpqDC+9/0r2p6dyT7P/5dz/xuYID/53Te+7hv9RSxinktNQdJTxteqzQuX9V7I/PfG/PP+byhHU8j8I4Xzif7r/pWpE+B+E"
DATA "6+NDrxvb24H/4X8Qtsgp7zv1QM5/4H8QtsiU9x3J/hfyfxC2SPwvz/+81X8hhPOJ/+X7n6f9fxDC+czN/+F/+B+ErTC3/lvLr2q1"
DATA "i/9B2C6Ve5r9L+f+N/YdUfgfhOsj/pfnf1PfEYr/Qbg+4n+6/6W+Ix7/g3B9jNZvN7eB+B/+B2HLnPK+Uw/k/Af+B2GLTHnfkex/"
DATA "If8HYYvE//L8j/ovhO0Q/8v3Pwhhe1Tyf/gfhLBVXqr/1vKrWu3O8b+xGI4x9T2ap0x93sIpU+ty+kf/6J/Wv4dk/0vG+beJZ+jU"
DATA "2KbG+NLnbY2NbWqM6R/9o395Hoj/af6XyqFeGtuxMVY+b3VqbEdr0/SP/tG/bA/E//A/+kf/8D/8L0Xef/SP/uF/1/CrWu2S/6N/"
DATA "9G87/Rsj+1+o/9I/+reV/j0k/gchhPgfhHC7xP8ghFtlLb/amu+ihx566KGHHnrooYceeuihhx566KGHHnrooYceeu3rERf00EMP"
DATA "PfTQQw899NBDDz300EMPPfTQQw899NBDrzU94oIeeuihhx566KGHHnrooYceeuihhx566KGHHnrotaZHXNBDDz300EMPPfTQQw89"
DATA "9NBDDz300EMPPfTQQw+91vSIC3rooYceeuihhx566KGHHnrooYceeuihhx566KHXmh5xQQ899NBDDz300EMPPfTQQw899NBDDz30"
DATA "0EMPPfRa0yMu6KGHHnrooYceeuihhx566KGHHnrooYceeuihh15resQFPfTQQw899NBDDz300EMPPfTQQw899NBDDz300GtNbwcA"
DATA "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAKAWHj16dP+/x48f3//vgw8+uP/fhx9+2Ox1JtjL3Qvum71veN/sfcP7Zu8b"
DATA "bu86ExzkDoKHZg8NH5o9NHxo9tBwe9cRP+K3/vjhf0sxyB2bZf4FAICGMZgkmIFhkgYzMDwkgjkgfstA/BaC8C0E4XOCYWUIZmDI"
DATA "TIAZGDJjG8OQmlmErcZvSA0uw0bjN6Sml2LDbz+zOzjr+iZgGL9tomj4nj3f45M9/rLHX/f42x4f7fHkSXzx+HVPnjx9+jTRxNl1"
DATA "Tz/eI74m6CV0QruJaw4o+e6bDt94/CbCl4zfw/A9i68Jegmd0G7iGlsIAzEdvtH4TYVv5C0VEIVvJH5BL6ET2k1cYwrFCKbDN/KW"
DATA "mg7fhfidh288flOmERDaTVxjCWkimg7fSPymw5eO34PwjcZv0jQCFI88wOixQ4pf1pQwHb5k/B6G73l8TcI0AhSP7GH12KvGT58S"
DATA "psM38pYKiMI3Er+EaQQoHrmH3bJL8b+sKWE6fBfidx6+8fhNmUaA4pF7GC5bhfk3a0qYDl86fg/CNxq/jOfIxDV7lF32h/DFP4r/"
DATA "3MQMGJ4jwyvKc2R4Jes5MnFNj6LL/vDui390DN8n4ZXEDBieI8MrynNkeCXrOTJxzQEll/2JRdExfCfxm54Bw3NkeEV5jgyvZD1H"
DATA "Jq6xhVCISiyKjuEb4peYAcNzZHhFeY4Mr2Q9RyauMYVSCE0sikJqIbyipBbCK8pzZHgl6zkycY0lpEJ8lSkhNo2s58jENQcYbUMV"
DATA "41dhSohNI+s5MnFND6tt0Fr8akwJsWlkPUcmrtnDbhu+4n9VpoTYNBKphUFQ8Mg9DI8xCPNvlSkhNo1EaiFA8cg9zI+BJFFlSohN"
DATA "I5FaOBW86JE9SoavzpQQm0YitXAieNkjDyh5DKTKlBCbRiK1MAgKHmkLYSCqTAmxacRr7RiKR5pCMYIqU0JsGvFaO4bikZaQJqIq"
DATA "U0JsGvFaO4bikQcY7T+V4ldlSohNI15rx1A8sofV/mc1fuWnhNg04rV2DMUj97Dbf6/437wpId61EP/6+HUTJSplra145B6G5xeE"
DATA "+XfelBCHJf51IXxDo8paW/HIPcqe/5g3JcRhiX9dCN9J/IS1tuKRPYqe/5g3JcRhiX9dCN8QP2WtrXjkASXPf8ybEuKwxL8uhO8s"
DATA "fhfX2rFHXhtCIWreKiEOS/zrQviGRpW1duyRV4ZSCJ23SojDEv+6EL6T+Alr7dgjrwupED9vlRCHJf51IXxD/JS1duyREyh5/mPe"
DATA "KiEOS/zrQvjO4ndxrR175DiKnv9YuErISr8OjUamoay1Y48cRdnzH4lF0bxVQkDiz41NQ1lrxx45irLnPxKLonmrhIDEnxubhrLW"
DATA "jj1yFGXPfyQWRfNWCQELd3YpHjmOOuc/4h/NWyUELNzZpXjkBKqc/4h/NG+VELBwZ5fikddGzvmP+EfzVgkBC3d2KR55ZWSd/4h/"
DATA "NG+VELBwZ1fW7terIO/8R/yjeauEgIU7uxSPnECV8x/xj7JmQKvNvgnTSKy1z1Dn/Ef8o6wZUJkSAhLPkQnTSKy1T1Hp/Ef8o6wZ"
DATA "0Gqzb8I0EmvtU1Q6/xH/KGsGtNrsmzANzn8ckXiOTJgG5z+OSDxHJkwjsdY+x5bPfyRMI7HWvhJWeP4jYRqc/zgikW1OmIbv8x+J"
DATA "GTCA8x8RpsOXd0p88+c/EjNgwLwpYaRRIdscw/f5j8QMGDBvSogvVrLNMXyf/0jMgAGc/4gwHT6pIhew+fMfUfikilzA5s9/ROGT"
DATA "KnIBWVOCkm2O4fv8RxQ+qSIXkDUlNHT+A0yi7ETkCCXPfzSIouc/2kPZ8x/toez5j/ZQ9vxHgyB8C0H4nGCTnz9uh21+/r0Zyhbi"
DATA "HaHk+Y8GUfT8R3soe/6jPZQ9/9Eeyp7/aBCEbyHMwzcIDkubIbcw3OWtXGeM4Q09LK2H3NYwy7RynTEGQx1SO0NudXjKaeU64kf8"
DATA "Woof/rcUx2aZfwEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFwdfwI8pQnz"
DATA *
