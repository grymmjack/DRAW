' snake.bas - palette color cycling
' Exported by DRAW 2.5.1 (https://github.com/grymmjack/DRAW) on 10-06-2026
' 320x200, 129 colors, 8 cycle range(s):
'   1: 15-26 FWD 6.0/s
'   2: 27-38 FWD 6.0/s
'   3: 39-54 FWD 16.0/s
'   4: 55-70 FWD 16.0/s
'   5: 71-86 FWD 16.0/s
'   6: 87-102 FWD 16.0/s
'   7: 103-118 FWD 16.0/s
'   8: 119-128 PING 9.0/s
' Keys: SPACE pause/resume, + / - speed, R restart, ESC quit
'
' How it works: the art is drawn from a 32-bit image, then an 8-bit overlay
' holding only the cycling pixels is drawn on top (overlay index 0 is clear).
' Each step the overlay's palette entries are rotated with _PALETTECOLOR -
' the pixels never change, only the colors they point at. Speeds use the
' DeluxePaint CRNG unit: 16384 = 60 steps per second.
' Compile: qb64pe -x snake.bas

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
_TITLE "snake.bas - color cycling (SPACE pause, +/- speed, ESC quit)"

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
DATA "eJztnU2PJNd1potkk+wmRfZH9ScJcGOAao7tjRczENwL0aKa4k6rGdELLz0QJMsGIWkIeCGNf4FXs5iV14J/CHcGDHhHYDQawIB/"
DATA "Rc69EXkzn3r63MiIqqzuyspz0S+yOjPyxr3vOec9Jz7yxmc/+PIHr518/7VvTv7nyb3H76ze/+j+6vRP/2j1+NmfrT789NPVR89/"
DATA "vLr97P7qwU+erj785bPV03/8y9Wzf/6H1Y+/+d3q6ber1cnJyeqdd56ubj//aPXk75+v/vh3v1k9/9dvVr/69/9Y/ezf/mX19J++"
DATA "Xv28vP66/P/z8v6flM8/KNvd/PjO6v3PPl49/qvnq49/+YvV93/z29Wf/+qr1cOf/MXqWXn9tPz/u+X9J+Xz22W70zK2uwXPn/7f"
DATA "1ecFPyx4/t2CTwqe/r7gD6vPyns/qp+V9+89emd170nB41sF767ulO/eL/i8fPbD8p3P6/c+LvhPta/flz5/X17/UF7/sLpbvnta"
DATA "cLd8/7T28bDgg7r/W2Uct8p+y/4+KfjuH8prwdP/U/D/Vj8o+75b9nVacO9R2e+Tgkfl7ycFj28WfGd1u4zhi7LdZ2UcPyr4rIzj"
DATA "RwU/LGN5UD67U/Z7v+BO2e/9grtl36cFd8v+TwvuPSj4sMyjbH+njOWHZfyfF9wvf98p+71fcLfs+7Tgbtn/acHdMoavV9+unn3z"
DATA "v8r75fMyntM6podlfB8UPCx/f1DeL2O8eXL75IOT107++q1i2ZPBvicfnnx88t6Zd7578p9Pnpzcvbt957+cPD/55Mw7n5/815Pv"
DATA "nXnnv5389ckXZ9757ye/PvnyzDv/4+S3Jz89+d+3Tk5eX79TvTKRSCQSiUQikUgkEolEIpFIJBKJRCKRSCQSiUQikUgkEolEIpFI"
DATA "JBKJRCKRSFwf1F85VRzSmBOJRGIfSP1LJBKJRCKRSCQSiUQikUgkEolEIpFIJBKJRCKRSCQSiUQikUgkEolEIpFIJBKJRCKRSCQS"
DATA "1xL1KbkVhzTmRCKR2AdS/xLnQK5BkkgkjhWpf4lEIpFIJBKJRCKRSCQSiUQikUgkEolEIpFIJBKJROIq4+vVtwMOacyJRCKxD6T+"
DATA "JRKJRCKRSCQSiUQikUgkEolEIpFIJBKJRCKRSCQSiUQikUgkEolEIpFIHBfy9ySJROJYkfqXSCQSiUQicbWRz7hKJBLHitS/RCKR"
DATA "SCQSl4k8N55IJI4VqX+JRCKRSCQSiUQikUgkEolE4uDw8NaIQxpzIpFI7AOpf4lEIpFIJBKJxMHi9Mm7Aw5pzIlEIrEPpP4lEolE"
DATA "IpFIJBKJRCKRSCQSiUQikUgkEonEK8TDcr224pDGnEgkEvtA6l8ikUgkEolEIpFIJBKJRCKRSCQSiUTiVSPXjUskEseK1L9EIpFI"
DATA "JBKJRCKRSCQSiUQikbjyOH307oBDGnMikUjsA6l/+8HXq28HHNKYE4lEYh9I/UskEolEIpFIJBKJRCKRSCQSiUQikUgkEolEIpFI"
DATA "JBKHjtMn7w44pDEnEonEPpD6l0gkEolEIpFIJBKJRCKRSCQSiUQikUjsH7c/+3iDmx/feQHvl/eJx3/1fIOPf/mLDQ5pzolE4jjx"
DATA "pOhWRdW79hrhPBpY8f3f/HbAn//qqwGHxE0ikbh++G7RpYqmfREiPdxVD0Y62PTPOvjwJ38x4JB4SyQSh4tPi/407YvQtO9Pfveb"
DATA "M/jg75+fwe3nH53Bk/Jewx+X7St6Gtj0jxr4rPzdUMd4SJwmEomri6onEaretdfP//WbEEt0MNLAiueln4YlGkitrpp8lTmutXH0"
DATA "/o+/+d2VHncicV1BLbGuVPz63//jBexTB3sa+Kuyn4qf/du/dDXQOs3adNc5ycvmNTpXUHVuDq6SfyQS1xGsoyL8vOhOQ6SBU3p4"
DATA "kVqwp4ENT//p6wG76sC5Oti7JjNVg+7SYGKu5qUWJhKXD8awUbWu6Qv1L8IuHZyqBSP9m6uBbXwcY9t/dI6yp4G9a9ORBkbXY3rH"
DATA "4k0Hz6t3T79drU5OTobX1MFEYn9g/PJvakoPc3Vwbi0491i46V9UB/bGEe2f+z5PHbjkfORFtI/6Zw1MHUwkloNxS1BPqCtRrbVU"
DATA "Cy9bA6fqQO5/yb6n9t/TQI/hIse6c/QvNTCRmAffU9fQdMQ1VQ9NE+fq4ZJacOk1kehc4Hk1eOl16anzkRVzNO7ZP/9DF5H+TW1/"
DATA "SL6YSLxM9HRvLnbpY0//LnI+cNc1kYvUgXNqwSUaaG7m6NscUP9627zzztMrpYF3H98cMPz9wYirMK7E8cG/K2tgDDOWHdNTerjP"
DATA "2usix6I9DZxzPH5ZGnhR3Zuljf/4lyFetc81/duL7n1wa8QrmEfisDFX9+aip4HnOfe25F6YSH8iDVxSj573fORcHdynni3Fq/S5"
DATA "Vu/treZL/bu2uPvk3QH77pfXLgnrR4Qax47ruee8zqMx59G9Kd3ZpcuXeV2kjeWy9e2qamAe5yaW4DL077y6N0cXp+6/m6N9+9a9"
DATA "3rH6Ps5LXkQDKy5L1z785bOduJAPVQ2LMJzPa4AP77veS1w6vl59O+CQxrwLvn+3IdKVXajxPHW9oactU3XVPo5zpzRv6pzkPq5L"
DATA "L9XBl6FzPZwWf6iY4zd3gK72vaB/I1LzDhPXTf+mdK+nMbs+m3O/x67ab8lvPXbVU3NqvSWad55rM3PWr2lj37e21Wu8c9H0LwL1"
DATA "zhh1bg62+pcamHiVqFrntfUcp0uw616T82rfEu3Yh+7Nvf67j2szvfHvQ8sa6vce/OTpJOwbc/RvHz6YGph4FYjWFa3x6Xjl/x3P"
DATA "UU226x6T3vm0qiO71lyZWvd0H8e4c2q+8+reea4DX+Q4dpfe9XTvVSDPAyZeFgad0zrz0X10c3HR2m/XmlNTujf1+1r+NmWX5i2t"
DATA "9/Z1rDvnXsB9aFyE28/uX0n/TA1MXBaiZ2w4dh3T/H/vnJzje9f9LlVfptaa6tV9c3Uv+n1ytDbD0t8eX0T3dh2rT12DvojOUe8a"
DATA "rrqfZj2Y2Deoeb015+fiIrVftN7dRddc7uleb22uaG3CJWvPTF3b3aV7c2q+3rWYi2jeIehehJeugQ/fHfEy95m4VETrB/e0bc56"
DATA "zNE5fce3Y7q31mfVvcuY85TmeY293rqj+7y2saTmm/ObwF1ad8ia90qR+netYN2bevbGLpyn9ptab/5lc9HTvV3PZtq1/vOSc3xz"
DATA "dc/aN7U+/5kxpuYlEgOa3rGeicDjvd5x4JxjX8Z4tM5x1Z+rxM9SzYuexzn1XOKl5ynnrgfdW5f6KnGbSLxKOK57+jb3eRxzr3tE"
DATA "z7s4xGfu7noO8RLdm1r7eUr35mjfIXGaSLwMtBiZeu5aw5zrn3Ove0TP+7nuzxvfl+7N0b5D4iWReBXwua1dWjelf3OOfavuMfYZ"
DATA "64fE26vCdc8PiUTF6aN3B1zmPqx9u3Sudz/clP75eqfrnqp9lznHRCJxeHiZ+hc9d3fXM9l26Z9rv96zHi9zfolEIhGBute0b0rr"
DATA "eveazTn3599kpO4lEolXBWvfLr2L7jmbe+4v+j3uIXGVSCSuF6a0L9K76Hdpu/Qv+j3uIXGUSLwy5HNILg1V83gPxVStF60HNefc"
DATA "X7QewSFxlEi8UqT+XQqsfbv0bq7+Ufui9VgOiaNEInE9sUT7/PvTqWsfTf+i9agOiZ9EInF90bSv3ms8R/d2rUdK/fN6fIfESyKR"
DATA "uN5outfTvrnP4I30L39jmkgkrjL4O9Jdujd3Pfqqfe23pql9iUTiKqLpHp9zEWletA7dlP7xt/apfYnrjNMn7w6YtX2uiXqlMKV9"
DATA "1rze2qTWv5exJnMicVWQ+neY4HpKfO5jpHtznsvBZ3I0/TskPhKJxPFgl/b5GRRznkvEtecOiYtEInFc4NqaU9o397lsbR3O1L9E"
DATA "InGVQe2bqvl6z2ab0r9chzORSFxlNO2ra670ar7es2h3PZsta79EInGVwedMTNV8u57PVrXv0J9PlEgkjgc97XO9N+f5vNa/Q+Ih"
DATA "kUgcH5r21bWnejWfn0/Z07/2nI7Uv0QicdXRdK+hV/NVeK36Xc/oPSQeEonE8aGnfda9Xc+pjJ7Re0g8JBKJ40PVvbb2aHSsS+3b"
DATA "pX98Tu8hcZBIJI4PU9pn3es9q7Id//I5lRUfPf/x6vGzPxteK07/9I82/29/N9T33v/o/urDTz/dvFf/5vvtO/X1kDhOXE3Y36pf"
DATA "VdT36mcVzf8OaV6JLao9mw1p46ZBG+0rOtjTvrZec+9Z5dS/poG1/+pH9C/qXvOx9n7bpr3XPm/+aL9svhm93+Z3SHZK7A/V/vQD"
DATA "6lrLqcyxzUeb/9if6meHNP9jQqutmi3ba7M5a65m4+YDkfb1dG+X/vlZ5c0HOT76IcdGDWtaTR+O6r/2WaSf1E7Xl9zXIdk5sQX9"
DATA "odmVxxjNxsy51D/We86ZzLX87iHxc93AfNRsxuPKZrf2PrWQ79Ff6uftuRsV0bFuw9TzeiP94xioR1PHGszF9Evn4uaX/F6bV5tb"
DATA "e9882a+5T+pvG+ch+ch1gnOmbUdbNz/y8U37njWQ8eB+eT6m+Q/jq73H3N22OSR+rxpYq7Buop1c5/HcWLNP9B3XXG1fTffqOqRT"
DATA "NV9bs75pYKR/fFZ5079oHvQd+iPnYP/lZ/Zx6mqU711/Ogcwjny+0bwxLtr/D8nHrqLPN1sxNzI/kXvqoe1E32ef3kd0/oU6xnxL"
DATA "H2b/zL/Ozcy71t9Dss2+4XzRs4HzE2Pax6/2CfoM86S1p/Xb1p+viI5zqXu79K89s7dqH8fB/Gi/sd/5ODaaG7XOmmR/jfTQ5wPo"
DATA "867/Ip/nflyHMk4aDslH9w1y2mzh8xHWMh7jkHfXX71rZe2VcUA/8PEv++UYo1qR/UaaTD/lmKm59l8ffx/acTbrCJ+jiuq1qXMN"
DATA "/Iw2Yk5xbcLahTZ3XqSNqX11HeYp3YueWW794zPLq/5xLq5VmRNd10X+RZ6cq63proHpu9Zga6pzhOsLH4czXhnTPl7i35wb6/BD"
DATA "8vcK52XW+L3jEPJIPvh+pI/cjvpHrqmVjAlrXZRruY11ktvZdxhXtCfn7mMU+5nzp/mzntrPXev0agB/z1rgHBJpmHMU7dLjs1cH"
DATA "UxfpG6wHaWPXJPQTbuf8wvijHdqz1xqiWq/pXqR/vgeG+kfemAd9rBLZbCpOuL3ziv2GNmOMRDUB90/NjWB+rcuuwamZtG8vtzmW"
DATA "bH/XPOQq0mL7SJQLI16o01H9Q+75fdqF+47yDf2SfztWyL3zovNS5HPu23Uc5+y8TM45t5528T1qBb/HMTsPRn5rW/LvaD/kgfuj"
DATA "nagz5pRaxnn2/CCKd8Y57U27MU74Sv+Mcobf59w9P2pm+5y6V9eh36V71D9fAx6Ofdf3Dm5+PwJb0r/Is+PP+uM4ct0b6Q05dn7j"
DATA "Pti3Y5h+TF2h/R3/9FlrqG1iH+b+XNPwPY6VscRcHOU97ofx7rztmsCa2dPKKB5tB2tHs6/9mGNyTmM/jEfO1ZpkraPd7HvR961Z"
DATA "3I7xTi7sp1GuoU5QS/ld5kzXPc79tpNzB/9PP3HujjTePmNtYV+uO+gX5M9xQHtYy5hXnQ+oaRwHOePf9bU9e6Ohp3vteUXtmW1T"
DATA "x79N/yo8f8fiVI52jUTuyD/7j/Kl4yTSR+dhx5zjzDm6jYXxS9tyv7SL6w7GFPfLvl2DMcdynM4f/D/zp+PLGuIcwlzjvhlfUW6J"
DATA "tD2KZeu8505f5v5732/v0aecW2lP79M5m7Cf2Qbk13UPv8d5OVY9dnIa+TfnbZ2NchXn4c85D8/HeYd+xO9znowV52X7GO0W5XSP"
DATA "ndruHGC9rmi6V9chdX1HzZurf+36cdU+5zvaxfZw3Ua9s0657orqHmoq/T3Kz7R1FIv2Z8czx2TuOUaOx3pP/7av2Qc5R/bd9uf6"
DATA "yXmX+3K8uE6yz3nu9FvGd69WsMZbq60B5sg5hLy49uD7tH+UN20/28B2iPwhyn/UE+6LuuQ6IPIBcsC4j/KLNdOa38bnHBJxyFxi"
DATA "3+WcmdOoZ/QD2sWcM99G/kYbkkvug/5Df7HmNLRnbzTt6+ldQ3tu21z947g4d86N4yfHzk1RreF6gn07/0fxTD+hltF3e3nUvu+Y"
DATA "9/vWSe6TdrO2MRfSnvbLKHb4Xc7P+dO6RP+0H1JjPRfnb/ozfdx50eP0fKkT/Nya6xzHObgf/00/ol9wv/yedZywb5gL8kFe6A98"
DATA "n2Ohbzg2OFZv4/kxp0d+bf+k5lozyQPtQF9yfDAezPOUjzBvOx859zru29ipe3UN5im9I3bVf/XacdM/zt1a3Xwy8inOwfnKPsBY"
DATA "p+/RZ2wX2tuxEnFM23u/1jbHL8fSi2fO03O01lC3GE/0Wc6X87L+2I+j/mg31x/mkjHkXOwcYl10ruM87e8eEzWuN0duY56Z/zhm"
DATA "vmfdIb+MLWtt5Cv+3LHh/nu+5tzNMTjX03/oR/wedYs2inKh520fcn6xLjlfWMfYt/N2T4P5nm1GPtozhxp6WheB+udrv+3eGeqf"
DATA "49aabXtGGkMfdr6xLzmmyPdUrnYMOQ+7tqAvR7HgvOlcwO9FcWf95XypN45H523qHu3gfBBpt7m3xpMXaoO1kJx7LuzHGub5RfmQ"
DATA "c6PPO5dxPFHuNBccB+M5qqsc145Vjo86wPFH9ZNzkf2QfkXfaNuYK+djcsQ5Ubv8fedsxxDHFcUr9+95mpO27ygfmlPGSi8mrH11"
DATA "/eVdeufn9fb0r143pv718j79ip9FuZS1gH040gPa3X1EdnSO5WfWXPNsP7U+R9pobeEcuB3t6Pxov4g0nOM0756380zkQ9aoXq5i"
DATA "nuXf9O8ojzE2e59TE5mXnA+sn9ZH+16Un61lEa/my1ppezH2zXE0H46TnNDHub393dxx7NRn1wL8jLrMfjg2axvtQF22ZnKMnjPj"
DATA "25pKPXTtwLwb2bWtOd9gjZsC9S869m36V7XPeZGvtBNzTxRH1jzrgesg5jF/j1pqjWH88W/7Q6QHtDlt0ba3L3DbqA7gnCK7Oy6s"
DATA "RVN+Tz+b6i+K++i9Ni7mD75H/4vqF9clrq+cLzhXchrlNXJq3eV8qQHclnwxHv0dftd1hzXAeuk83foxj8xV5JN2iMZW+3HMs/5p"
DATA "57+sE9wfdZ8ckUfnR2s0dc01nO1I+9mvzS/nG9UC5N487NI7Pq9t17m/dt9g1T/m8yiPRHWKtdp5h7awfelL9PNejcT4Z+xYFx0z"
DATA "tJF9gOP0HKzXtrnHar+PNNm1ludsHaV/RrmpxzO5436pRZwfdcLccN/sj/OM8kuPJ9cK1DrXML2awv5iLbJWcb7WOcYdObGfkJtI"
DATA "I8iJ7cRYdw3R/m5rqxNRHVNhHWz3gUSa7filf5hnxi/5ZDyxT3Ln+sh90QbW0cjP6/tTfDSd62GX/lW+eOzL+OL4HdOOb/qU49Ya"
DATA "Qp+lP1N7rSOMX+cOxpLjwLnZ47VdaDf/n/PxK+3qsXp8zteuE9h3T8/4/zZn6zPHxbzNMXrurslc61FTIm6jHBfFGPu3z3js5Ni+"
DATA "41gnf9zG9qCfOJ/Tv6OcF2mm58Hxsk/7eHuPawu32OVzZx3TvbimDta4tl+bC8+fNrLG0e8iLaOf0Fcin6CtnFvoRxEvEdoa9X5W"
DATA "5dS5v8ZR0z/7fKQbro2isVsH6Zv0ceqVv0POIh7ZTy/nUFMZ385TjLco/hwPrCGcNyMN5Tg9B+dO9+0cFGkQ58g4ZYyxX887qhGc"
DATA "tyM9dJ7iq3WTvm9djz6zDtOPaEf7BuOZc7S2uRZjHFsLyAX/tm7TLhyrc84Ze67XVWLs+vncfAaFn8U9dW7L8c3cb7tzfpG/O8c4"
DATA "Pui/rosifzcf9PX6PnWvp33WvCX89LihP1FnyJPtyvlyG/NhPaNfM39YI8kTY4L9kj9+33mPfs85Ou5dd9hfIj23rzcuHJeMb9eH"
DATA "9E/nwkgbqHdR3DPPu85z/qV/k48orl3P8ZW2o52si1EeizSW3JAfaqN5s//09M2c2F6uIa2vzpcRD/zeZrx6Hm30PG4i0sIozqNj"
DATA "PMZ5O7/vnGKO7He0O+u/SBP5fdrQWtira5rmRbnB2MVLVPuxPq5gPNB3ojrCMR3lD+ZO9sN4j2oK2sK1Q7TfqP6y70Z5mX1E2uSa"
DATA "g9/h/hgXtrv7oSZZP8wB49k5k3Fu7WBsUw+tu9zOeSTKKeSe43ftw/68fVSzmjfOgfY31/RX+xd1hvPmfq2b7Jvc9OLVumg/dv34"
DATA "Qm7c8TzG3vNnHd9zj4l9j5t/3+Ccbps5duz/zivOTeTWMUo/3qwxKt2L6uFejbyr9vP5AfqIY5fxSm1j7ovmF/mcY98+7hzveI76"
DATA "9pjog/Z9a7trHudw788a6nrXOT/SNGtGLz/QJ8i/aw735/zAOVEXXZNwv1HecT4gb64n7R/OedE+7R+0b1TnMSf7e9FcaDvXe1Hd"
DATA "Q+0mx1G88//2tRd8aa05vWeR9Z67GOncnPs9XAdyjZOmg+03/s7PtAs5d+6N+HF+6uUP5ko+p9d1ca9Gbv+fUxP7OhHrg8i+nAdj"
DATA "kjHgesS1mnmzVlrDGMPUE8c+eXZ8u46bqk8jfeQ4exwxZiK+aG/3wX2R30iDOVfqIX3TOYvjdz4wn5w7fZF9Wwu8X3LrvEV7cxvO"
DATA "2zUTbeA6hDpPjqxTtJXrFO+TuT3ign1GdYHjwXNrfVWNiTTvzJpLqPmiWPb137m/d9j1W1euczes9akagXONYplx5bihv9inWy3c"
DATA "9t9ywxLMOfa19vX8l3VTVMswvqx3UT1CHbPfcN/tb+tPpFvWlqnx0M85L8aac7XnQU6Yz9k/c3+UC7wvayFzC/uNYtx653Fwn87p"
DATA "9FdqM7l03FIPo1onsrP1JRpfpFMcW1gjyI7khjmEc3K+ifIJNTuKfet2lEOt/+3/La6tedHzZlsc8znbFdG9f/7t1y7MXe+Yz7uI"
DATA "8hdtRRvQT6wTjKH2PWreXO3z+YE5tZ/vEeKYXXe5VrC/sO6hX7rWJw/WP29vf7MfWU+t2fRRaxHHRF/1vrwP1xTsm7nDvs5YJ8iL"
DATA "x8b+XX9Emup8TB+lLzrnWMdcp0U5wf4ccUBb+W/rTFRXsR/715SfOvfRpzhe13nOH/QPfu6cQ55pq6huaN/388f4vLFI+6h71GuP"
DATA "s+2PawBEaz95Dag5Guhn/vh5366P2ngcD46btj2fy9bgc59z0Kv9qH3MGU37qBWML46d29CnfZxBH3As0PesgZFPWjfMdU8LGd+u"
DATA "JaZ01PvkvJ3XXEP28gR9lHFgzYu0hXHL+o8xyH7Io23KPsmTdTyqpcmTa7f2feoUx22NsBZxH7QveSL39Bd+Rv2KtInbm//I3s7F"
DATA "UY43J/QF57e6TdM9P3vCx7t8tpj9r5e/nRen1v+cs+77ruc+Ng1s9Sjj1vYnD+1vPo+I8HMpdyGq/aJzBa1mbtpnP3IMcB6MT9qd"
DATA "Ode+SR2i9vRyPD93nUWNcIw5pswzube+0o+5z55PcfzWQtdL1g/WA1O65Zxurt2Xtd66535dF0Z1kDWKHJAT10bmkfbqaZy1kba2"
DATA "L9FfbWf6q/WHnNCXrU/OZa75WIM7pzI+7K8t3ql7vP4QaR99LsrPUd3L//PVz79gzRnp4i4NbLXV1DG5c2cF7y8xlupe7/pQVPtF"
DATA "Y+O4puKVPhnlIuZM+gx93zrozxg7rL+sB66tnIu5f+updZTaRR9mv/R7xhI1I6qnuA/WIvTlSLOs0/Rx+3rEuffPfUT9Wws8H48r"
DATA "0riodvIcmUPNm2smc+IxUHMim1D3qavRNuTD/sH/c3vrJcdvrhv43B1fe20x3M6zMU9ZT2ljI6op6L/1e1PPQVv6/G/rTO+8pH+H"
DATA "F9WkU2PpYU7tF2lzlJ+Y88m5NYDxRr90jmbtQp+NbEXNod0c31F953qNr64D7FfUGI7POsLYpR9aq12ruZ7gd5k/OAfqiusOx4Rr"
DATA "UvJqDbPWO65pL2qZbcbYJi+cI7XJtWmkS9Z78uRah3nGHDg/R/mOmm1NtM8ybzOXOg/19KfxVbWm6Z7vveO1VuZ75wdqvesFx16k"
DATA "fawj6v97zwKPngu+pNbiubZIB6Nj7SWINHmu9kV1iesg6oB1sZf/nS+pm9TGXf7M/qw59DXrhjWE8eV6lBrnObne9Ry5P+oC58Sx"
DATA "WrfNFf3ZPHP8HCvjMKpvovdYu7Evxwy3M9fkwHW76z+OlfYjd84d7NtaG3FMe7H/yDc41yj/8H3a3DofaZ1zKcfLZ475WgO1z/nR"
DATA "GupY7PHtGPDYzWd0vWEfx5tT912Tg6lnr/WexdvTvug6OfXPMUm9I6/2vyjP01+d++0j7Md65rwc1TqRxtHG1gzHKP2f+3etR04Y"
DATA "H9YI60gvdvhdxrzjxfUL58AY53hdh5MTx1LEgWuKSIdpz+hz14kcqzWWcN51nFMTyRF1jX3ZJszttg3n7JzW9uv9OPc4n9InOQfX"
DATA "fIx9/t6CWma9sp9HvhnlE/uPcy/nWz/z/SZLrrXOvd8kWmt56n6c3rMop655RNpHP2TNQR+xjR039HPnKNdErW/HqOOFPkl9ifJq"
DATA "FE/0455vOx5cb7jucxy5RuLczUGklcwRPc6Z13txyrwUcUR9ch6wHvPV23ls1ICID+c064N12TrGba1F5rpxQh/jNtQPckju7IvU"
DATA "C+cqjpv6xM+ts+21PXOMa69b+zgv5kW+sl/an2PwOOwv5Ng1gON57j13Uxro665z79Oec1/i1Dk/Xi9v+ke/Zj1Guzrf0cdpF9Zo"
DATA "jHl/n7rC/fL7fp+1hrWNPkpfob25rWsNztU+zbizn0X1g2PFdZlrOvbjWIvinrWYbed6KNJ0jp/5hhrM/VonPAdqPG1C+9EW0X45"
DATA "np4WM2c6f7oWi8bO/qyVUe6hT1vPCWu/bWi+6mvVvlbztTWI+ft6/rbUPNFfI5vR5pGm00cZU8wVtkPkN73fm0W/MYvWYVjyG71d"
DATA "z+DYddzLexKb9jF+pjSN/hVtE2mOfc1xHPXr7WjfXm3C7a2RkV4zBqk59AHnVsZrr/7geBxL1FrzRn/m9vQ11iKRLzNHOEY5Po7Z"
DATA "mu76glzZptRu8+RcwrE7D9F3aGdqEPMD45u5w/rNHOVcztwb8W0eqGXONZG/OGdxf+0z1nwtvql9XE/JeYtxw/mz/ygH2Remcp99"
DATA "xLnNuXlz/+FaB5euOdBbm2FqTYa55/z427w2TtvFuYD+w9h0PDrfkG/Xc1Pa5JxG/pl3GCOMK8+FY3QsMfY4Ro4/yvec11SN4zFG"
DATA "uSPKA9yntZYxZ/91rDLGGR+RZtPukW87J7pOMLeRvWw313gRtxwzY53+5NxnvjxX98n6zfu1v3E7zpdztvbYz9rfTfva2sMtvpv2"
DATA "cR7R+BwvnJPnH+XoyP7OVdZH5mxrbpvvkjWnpjSvdxw897d4vEfI2kde7SPOWVHuc61Hu5Ib5o3It+zb1Ab6On3fMejvRjrC70S1"
DATA "W6SbHKvH7XiyxtIPvU/GCXl2bra+klvGLHWK20VjtRZT97kt7Up9t6YyblxDRDoUvVqDOEdyZ7tH21ij6MPMD9Ry+zj1ntzTX8gj"
DATA "ObHNzVV7r97b0Wq+SPusUcwZ5JW1gXXJc7KOkh/nZMdF23ePN3NPHZy77vJ5dM/XOnpr0vg+yTYvxxZrtKhWsl3sG/xOT9tsM/Mb"
DATA "6axrPNY3Hpf9wzbjPqgvjC+Ok35jn6Jf8m/6EOsAjoX+FdVZzu8921jfrJmRj/O7tJvzX08PGPPWG2qM9YH8OU/QB8lDVPP0+I58"
DATA "kTw7x5Eb5zvOObKhczx5oR86rpr2cV369vv6qn3kkjCnUa5lTcJ5uY9I2yJtpP+6LqDf9uKsbT/13I1dz1mbU/P1nrvrNbmiXObY"
DATA "cj6znkU+HmkeY5d9c1+0XVR70Af9f8cT9c7bUKtdn0S5zTrH73K+9kXOjd+lD3lb1gfs0/pJvpynuZ3j0tu3/9u+jH1rLO3CvljT"
DATA "OA9xPFGtQo6ZCzkH29m5K5qPcxL9Jsr19jXndcYxfZH+z3ExrshV/bs9b6xpH9cWMX/0O84/8jGPgXNj7uC8aW/Plbw4/7SxsP5w"
DATA "rFuTW391/v5txdxrvNG5Pq5HTd1r90jSLx1vtHk0L383yjm2le1tPaWOcH/2q2jf9ttov7Qf/cl2574dK9ZM5zXHPXm1Zjnv+Hvc"
DATA "d5TH7UMeu/XFWmIt7MWwNZ/xwH5YV1k3e9+x7vmV++d8bTf6ibXVPsWYdp1iu3Ms5DnKQ9Z1ahznSU1u46ux3nSvnu9n3WcbuC7w"
DATA "PBiv1iju237XG7/nbJ7sb4wx+zq5j/J6ffUzKHtrcnldGq83b+2bij3nNtdCjEnyTj9y7Ji3xhH1knFBH3KsRzZ3vDlG+X/7OP2G"
DATA "Wk2toy5EuhLl2l5cMpatqz0tdIxZQyKt5KtrHvLuHGBdj/SWvu34IA9RTHAf9CHrI7exnRgztGOU48iJcyb/jvIh7UhwzI5jz50+"
DATA "MMV1fa31Dp+z085xtTVFmCuifBf5GfWH3DrezaN1yzUPx27Nc+3Dsdu+tKdrC2r4Et2z9pEj28h5mzWC4911AHmiDtE3GQOMyyjO"
DATA "aBvO3e9FcRxpBD+jfrlu6GmZv+d+aUPn5F6usG9av8iH5xJpvL9Hn2vb0ccj/yQHHCv7Y5zSl2gn1ggRT8570XdZs1gz2CdrBvoX"
DATA "44j6Y5/iGKl3vfi0blEH/J7rK3NGX23fY83X6r5a7zj/0BfIA/tmfFvnXEf0cpXjzv7vuTt3O0eay8hHzZ/1hTFhv7aPkjdz45xG"
DATA "X3Au4fzo2217c8ecw5iMcgG5dpx7X9SgyBe4LbmLNIjjdt1FW1kruL31xjHq3ML+HGeeX1RncI6cE7/nHEc9oA9HfkC9c76K9kUt"
DATA "iXyBuZQ2cr4zj+acNoxsw1zL8TF/8bWn0/4+fcV8WPO4f86LvsXt7OdV56r2tft925on/i712jmXYyL39CHrfS83WUM4F8e4tTGq"
DATA "Q5yrqXnUGvpkT6c5TvNOu1pLOV7Pmbb1vuzX9inHcJQP2V8UW1Eu6cUebWLdpS3sB/Zdjpdzsua734i/qC/nQm9HW9PHnKcdL80+"
DATA "1mHnFGsE+ejpNm3O8UWaE8VQZA9qHePE/6fdXBuQI37PPmgbO5Y4VuaZSBfto5Emuw6ir9ifzb3f53XetpaS5xTlvjZHxyltQnvT"
DATA "F6LY5BycwxlXEV+0E7XeGsSx2IdoW+dFar19wPmWnzF2nJ8jX6TPWrM8jyh/OE/zvSj/c07Or9ZC1h7UA+cR29S5z1rPebP/KA9Z"
DATA "e6J8xnkzNqK85Fi3Jjq3OG7Jp+1G+9oPOHb6dGQ/z5P2p85Yo503OH5z7HzRs5dtxPiI4pC24tisp9QF6yB9nvHOeZJf6wn7dKy2"
DATA "vpvuuV/agvO2TaIcSm20XlBvPD7mfOcn+57zu+dNX2HfziH0Cecyap81gr7LfBnZ07FDu3FckdZ4/86/jDPvk5pBXukD7M92irSV"
DATA "Y3RetR6bR8c89+Xxcj7WevpEFGfWTXJLm1oLrAH08Wi/Ebe0p7WRfDCeuS/nDvuk8xTHYN+jHa21jrUpP6XWuT5wbqWe2sfYvzU8"
DATA "imHnLc7TdrAu8zXSetrd4+vlc3IZxT81rzfvaDv7DX2V36HdbKtejo30tKfdngf/pq2iXGidjnysF+/WEmsz7cv5cR/WC+ce6xA1"
DATA "wzpm3aZem1PWH5xfFN/W1Si/0W/YLzWXMUH+puK3fcZ+zUOUP+gTHgv7t4/5O/Yx9sF5RByQK/oBx8P5cX/O59RO2ph5x1oY5Uj7"
DATA "VWSzyK88J2oBdcD29hgZA9RDftZ8K9Jh9m0tZ6xEvNlvnTvpc+yrzdvzivJ/5K+uPxhn7J9zdx7v2cGa5ljm5+bZOTDKUezbOaa9"
DATA "Z8579QO3tw9EOZpxyfk5p1DLHdPRHFynOHa8T3Ld00HnP/pONLYoFmjnqZw95b/Wj8YP8yfH7O05N/pxlOc4N+s6/c/9MpYY14yJ"
DATA "yJfok9ZdzoV52frvfM7vRHkwshP5ad8nh/Rx6kEUK8z/3GcUrxwvNZD89LTf+dJ1CLnxe9bbng84r5p782dNp7aRT46ffm0ttH05"
DATA "H/q9/YScc4y9bRhHHiNB20U291jtD9aLXv6mbZmL7L+uAcgzdY9aQW10DDpWovzgbVsfjDm+F8VKL/dxf/RDj5H+Ql0xz9Zm+mfk"
DATA "R7ZH45+8WpedR7g/8mEtYD50PeKcQT8gr1HOtqY6T9FWjHH2zViI/uY+zaf1ItJC5zvHnePJNmF+4TisCYwn+r65YT/miu+RM+ue"
DATA "50wf4P7pa9FYaR/rOW1hLbQmed72eWoH/ZA+Za2MtNnzc3y6piEP7p/xz/fso54DawFvz5hwzFpjnOeptdZsz8NaG/mDY8m8R3rh"
DATA "Pl0nMdYZg9Zf5gdqBePG3/OY7Au0CTWI8Rz5uLXHeY/zoM2sUx4r9+PYdd4xp84/9GXrGLe3TTlPc9PjglzRxtZ+xrS1gvvhGKN+"
DATA "nGetX9Y12p3ccM6sDxwL5p/2st/ZFo4d9uH50QfsE7aLddufuz/bwbnK3Fq7e7ZwLnAMMtZsA+tkZBPGsTXZekM/7e1rap/MC7Z1"
DATA "e8+523pFLWDecw6P/Mv82p/s51F9xP6tldRq50fHCnWO37EuWOtsZ++3F0vWBnLHbejTHC99xPvjPu03jiH6BbXOc7J22c72F2uw"
DATA "86k12XEc5ST6DcdhLbduRDnSsWbfsa5GeZN82i6cM7mLbO74srbZfvYf5we+3/OrKO/Zj5i/aRv6v3ONNZFxaS2hXT1X2yDyH9ZW"
DATA "Ub8ch/V+Tpw55qn9zCEcFznp6Sf3YW20Lan3tIXH6xzCuHV+5pzsn9Y6+xtj0nOOdJ+89fzcdrIvW3/s3+SH83NuoV2pH9Q5z4Xz"
DATA "t3Z4Xo4nx09Ug3h7aqb9LpoDbcs4pp8wBiPfso7SJp4rbe88Yj+mnpAf2oP5qBerUS1Gv7A/MTZcT7heoU/bn+wbnqtzAP3Yc4q0"
DATA "g/7H7TkW8sl5kVeO1z7oWLeWck62i3WE++H3aQeOy7FGe9MWnhftbfvRH3rxYNuRiygmOXbGecS9c1KUJ9mfuXI+Y5xP5XC/RhyQ"
DATA "T9uiF5/WaetwFIuRHTgm6rBjx7FgjrlP+orjieOw/f2+dYA5wjaj30/pMTXc+YsxZV9wnDnuHfvOP85ZEa+er3XBOmofoj2s3+TE"
DATA "ekB/9XztM1H+cF1BTqlzEZfOxXyPMWCt7MV55JuRlvmzyJ8dP9QS5yTy2r5DnmgT50yO2d8nN3yP3Pgzcs6YmtouyifWYvJgzslJ"
DATA "2wdBTs2V505/se/Qv+iPjLEoF7axOY74Hm3KsdsHOc7It8kZ+2Rse4zUNuuMcwDn7BzieOX8nZttM+cnfpfzpU44VhlHHrt1kPug"
DATA "3rAf7oecOO+wvyi/0JbWCL5vvmxTxq810tz6ex6rOeZcGV/M5dZqjpG+RH+PNNRxTR3mtlEusU/QruabGhnpqP3C/kA/jjjgWDhf"
DATA "5l1+znFEvmD72H/pR9TqSFOifq0njB/nL/6f20Q5wHnqJFu2bNmyZcuWLVu2bNmOsf3sZ4s2z6aW/GXLli1btmzZsmXLli1btmzn"
DATA "ar/4xaLNs6ldLf7yBMnFWvKXLVu2bNmyZcs2s/30p4s2z6aW/GXLli1btmzZsmXLlu1VtjwmuVhL/rK9rJYXri7Wkr9snZYyfrGW"
DATA "/GXLli3bkpb35V2sJX/Zjq39zd8s2jybWvKXLVu2bNmyXXL7u79btHk2teQvW7Zs2bJd+ZZn4y7Wkr9s2bJle2kt7wi6WNs/f3kj"
DATA "ycVa8pctW7Zs2bJly7a05Q0iF2vJX7Zs2bJlu57t8ePH79X2fmm3b9++c+fOoq8fdXv06PGjwt9I4ZbAO3fv3ru3qKNjbA8fPhrb"
DATA "wGHzwYHBu6Xdu3d6uqi/42oPHo7t0aN3S/tOaa+V9vrrr7/xxkjgvUrg/fv3Hyzq9jjag6E9fPDwnaGBwYHAN27cuAECC9WPZnb8"
DATA "eOZ2B90KJZWVB7dqCxgcCXzzzbdGAivTxU2bSPZ6HaRg3gAOuhWPGtrNmzcHAtccygVHAt966+23mwduGRyTzNpBG8GlLRrGgbYy"
DATA "4dpuvv124W9ojcG1Cw78bQl8u25469YglCOBY5oeCBxyzBjiD46CvZMy3/KvkDK2LYNbF9yG8JujB45bDJ+Xj894IDRy0TAOtJXZ"
DATA "llY4KawMrkUKewSuPbB8jo/Xn48E1g0WjeMwWy3q7t59863qVGN7GxzCBZlEBgk8SzCz9Foj3140kMNsI3vb1ngc+ZMGtiQiD9y4"
DATA "IAis3SwayIvtq69Ovvxy0TdeeqtHZXfulAmXKddJrzkM3EshOhK4ifGYwEVDebF99dUL7P3t3+7+2ktsW/a2bSTwjLyhhBn4GQiE"
DATA "j57VyC2Di8byQvsycL5XxN/Pfx69W9JlaZWPod2os96K1xlizrC3Zqex3MkiNy5K36KtL7eF/J1lb8Piur7b0BexN4b6CyopAm9M"
DATA "D8rte0P74osvyt+R711aO9ftULXeff/9gZXW3ljnhpGWtVe9ELlr8tYi+UKWJoM7hvDkyebPTz75ZKSv8vfFFy/X987D35q9kZj2"
DATA "gsOLkRMcejSf2rgeyDuTZjbna97Yzd/QCne1fW/zfuHviqfdk/frab06U7RWmpylD3S8wN42/76QZsbtdw1jw98Ln1xtAoezoq/V"
DATA "uRbUOQ9O1gqTUdPeaSdX1mdPXwjcjfOdZW9PGfilKuCy9l49Mz9UdNtm92snp9bsrY9ry2FKI4++92Lo7qUEvKIEDhc26nTrpAtG"
DATA "kavzbrXLzfWpqdH7tuwNx8nDaQYeHou9FurrBL1oaGpX0gcLeePJ+W2T+w3n7nxyeWRvPM01nCbE6Zl12m3sbQ/gBqrnDy1oUwS+"
DATA "kh9uD+eDR9o255gH0a/zrpMeT33G5+3W5NUTe+PZ0SBtwPk2B4Ezx7awvQr+KnvryxutnXG/9bn5qS5G9tplpnb+GcK3Za/Stz7P"
DATA "fz3O4j+qPjO0EntjBG7Ct14dGuib0Q/JG65xrq8SUym356DHs9Qzur3qrc565G17jWObPYZrF4su7rYrxGBvffp5zd6GviW9Xtn2"
DATA "8OH66tqtW5v8uc0ew7Wf814bf5G9DX2L+rnKrcpWo27N3yZ83yjTL1Nf1N9UO9x7FLo/d6v0NebGGm7NX82dw+0Z/U6PqE3wN1zd"
DATA "xVW2tfy99tp46bHfZ7ZCX61619SNpdlG/upBRrI33Sp9jbuhONvK33CMu6izI2xr+gbuhqO0xt9wjLuoqyvdLukKyf1SUKxdbzgH"
DATA "tZG/4RzBoq6udrsc/ip9jbstf4W+4RzLoq6OsoG+8faBIX28885wjmpRT8fZTk/vbdhr50gLf/Uc36J+jrSd1tuD1uyBv2tzYHrZ"
DATA "rRyRNva25+hvPUj65rV798qVi4G84Qzdmr9yaH+o9OHnly/jJOqavkreeJp0uAH3gE+NvFz+yjmlcvVxYG9zlaNc5DiOm0P30Bp9"
DATA "m3sMhssc9+ecZ85WWr1HbaRve5XtXvI3txX61s43XmZb85e/wprZ7ty5PTrf+iaX9WW2dL+ZrVyZWDtfu8725tLrRMfcRvqq722u"
DATA "81b+FvVxzO327XqfX2Vvw9+d5G92u11OLo/O9516qr5d6F3UxzG3kb7hbqv1lcrhQu+iPo65vV9vlBzpa/yVK72LujjmtqZvuN1q"
DATA "fadBrgWxoL33Xr1VcrxZbbhUXvjLa5Wz20Bfu9Vv5K9eKl/UxzG3x48fr++UbLe6VP4WdXHM7fHjeqvpcLtfu9eg3qqxqI9jbo8e"
DATA "PRpvlhxu9Vvfq5H0zW3rW3WHe9bW/JWL5cnfzDbcbdpullzfa3W9bja41FbYG+42Xd8rOdwpXn8Ps6iT423bu03bvX4lfvNmjdnt"
DATA "wYN6t+T6jr81f3mzxuyGuyXfXt+slvzNboW99XI47WdAlb9Hj/Nul1mt/nxgc6fpmZutFnVzrK2wNy4n1O41zZutlrRxNSas5jKG"
DATA "78OjoG/z26dF33IPjbt2r+R4s9qibg6wtbWUStiNvyJd9G10srnVb8vf9b9ZbVgKqK3SMMz6PLdIbRcU4r1qhb5r7n7DUjbbhUKa"
DATA "bC2c92Y9pjOL4dy8ed3pq9doxxsssMbZGHhl5rN1/86dzYpCrZd2q+S1XgiyXWMcr89ulloZQ68UbvOOG8b1mLCeUHO/Q75VckZ7"
DATA "f32JbLy6uFlnZfydRvuZxu4D/+16TNWJN3daDctBzBjFwbb3BvLKyaV2c9R2JcjN79R2/8yqrigUrCY03Ch5nel7771K3nBt9vV6"
DATA "ZXtcvBaLuW7OPdXf+fXOHY8LCq3beKPL2v0uVEpe/Vavj5VrYwN9vC9gvRTzcAJqQ2C9+BNd+96siLNdTmi8z2q4T/Ja01dcr5JT"
DATA "qPFlsfX5z83Z93b10XevjIv9B8vhDPf5Xe/bTMvVsVslPwz0BR+Pq2Ws18tYEzjcvrK5/3G9DIuWE8JtfteavnJ1p6bXd4uydbbY"
DATA "Lnazuf5dmRlVcr0OUFusXsvhjMuR7BrCIbeHt27W8q6k1omNxkvgw1VwuFZbKQir1bflXNbbDPRN7f3QW7k4VlNDoW96uyE3vBCb"
DATA "21Xo21IkZ5bTGB/WMd3xYbfqfGX65dhi56a1NuFKfZvaZLMW30gjV3O57quRPLhfl5ov9M3aelvcbRai3y7T1VYi3axGMtxidb3v"
DATA "sXpw8+233izH9bMPS8djs+HA7MyjJNo6e5vlcteLuczt9zBbcb43K31LzinV++h5cmC7Uv9mFfBKX73B5brf4XL/7TfLkenNhYel"
DATA "ODl1ZqG97SFeKYSO4f6g07fOQ19pWq6eS6jXwq+epDmC24NO3ypn6d86Pd9JkTNPm2hrPA4V9Ljc66LODrLde/PGG+W0yKLvnPl+"
DATA "PazQQzrWD8Ja1M+Btns33ni9eN+i77iLzUq44xKFwwKPR3Jp/G65snPjzQsf1YO9St+i7x5yK873+o387d552703Xnv9Rv546vyt"
DATA "ZN70vou0ZC9btmzZsmXLli1btmyX3/4/uQ0fFw=="
DATA *
