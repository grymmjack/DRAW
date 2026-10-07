' hanukkah.bas - palette color cycling
' Exported by DRAW 2.5.1 (https://github.com/grymmjack/DRAW) on 10-06-2026
' 320x200, 74 colors, 5 cycle range(s):
'   1: 24-33 FWD 10.0/s
'   2: 34-43 FWD 15.0/s
'   3: 44-53 FWD 20.0/s
'   4: 54-63 PING 9.0/s
'   5: 64-73 PING 9.0/s
' Keys: SPACE pause/resume, + / - speed, R restart, ESC quit
'
' How it works: the art is drawn from a 32-bit image, then an 8-bit overlay
' holding only the cycling pixels is drawn on top (overlay index 0 is clear).
' Each step the overlay's palette entries are rotated with _PALETTECOLOR -
' the pixels never change, only the colors they point at. Speeds use the
' DeluxePaint CRNG unit: 16384 = 60 steps per second.
' Compile: qb64pe -x hanukkah.bas

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
_TITLE "hanukkah.bas - color cycling (SPACE pause, +/- speed, ESC quit)"

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
DATA "eJztnbvvJUeVx+/YzNMez8v2eDyeYWZYwPOwGVvaFSshYWEYm5UwEtIirSUMAcEGaGMnYMl/wUYTbAKIjBWPgGijjXYtR2DjxAER"
DATA "mdeSEycWmt6ue7vura5b7z5Vdaru90jf+f1+1bdPVZ2u87nV1Y/55sv/8vKR1UtH3ln90+rJE8eGp0Z9/tGTwxfPnB7uXDg7vHjx"
DATA "8eEfL18cvn718nDvxtXh1NdeHx5//a3h6pu/Gp69/85w7/cfDj9+9+Ph7b8Ow69/fG/44/03h0/f+fXw2V/eHYZPPxoeO39pGP5w"
DATA "f/job8Owunp/OPbaB8P5nw3Drd8OwxvvDcMvPhmGH44/b49/XxjLj4/bj4yfOzr+PDf+fXMs/8G4/Zfj597407jfb4bh/E+H4dh3"
DATA "PhhWV0Z/3x39vTWW/27c/v4w/Fx87r0Ho/8HYz0Pxvr+PLwytvuV5+4Or371G8O9b31/ePl7Pxle+tHbwzfHn6+Mf397LH913P6L"
DATA "e88O//Nvrw7/d/9fh+G//n0YPvzvYfjsk+HB+PPB+PfHY/n/jtuPrp5aXV8dWf3nqdVoY79Gu7G6vXpktTq7K7mz+vvVE6t/fmJX"
DATA "8g+rr68+v/qPk6vVQ1PJS6tvr27OSkT8l0ocP2qJ8cBJYmz2LpF7h6KWjkuquOVQDk5Q8IsT+2ofo5bGN4VaYhZYSKPaOdYDA3vg"
DATA "XktjllItsQksLKMa+dcqB1vmXktjklotcai2Wjqu1Cqdk60wkJrXJWLb0rjLpZa4w00tHedcKpGn1Gw55DlfS2Mrp1riDHe1dNxz"
DATA "KnfucmQguNeWanJC3LuRWzX719I4yKncucyFgdzZ19KYya3SLCjBOq5MbGlc5FavDAT32lGJnOfEOw48bGl8lBBnDvYy52tpPJRQ"
DATA "7hxviXm1WNjSeCkhrgwM4SC4V481XNQS27ixkIs45AtXDrbEvhrHraVxTqmWOAYOpqlGPrXAQG7sK3l8UseSeH5byLZ9/Uz3qL3y"
DATA "zz7Zav2s9yT9c+L5b/kMuJSs01SveI58+yy5lHimfJL+eVmvjRGyzlCmyDqt26f+6uXyWXe9v/rnxLPyQs76Ff8yxrbPy3plPGS9"
DATA "tuMpn9X3HV/1OJuOq62/pvqEnOPL4J8rD7ky8BC5t2TMqPzzjk8H/1T2iZww8c/GPlO9LvaJ+tTPrvN/qrcU/2y8NbEgiX9TX0P5"
DATA "J+vU+2s7nvL7xXd89e8X2/ea3t9o/lm+17izkBsHD4V9VOMkeHxq388yH635Umg+os5/fPwTrI3in2M+qfNP9tf2ecl6lX+SQUIh"
DATA "/HPNb038M82r9Tjbjq8eZ9/x1aXP62315uJfSRb2wMAWuJdjbATzTxufPv7JfAzlX+p8JJR/On+8/NP4Y+SfUp/OH1P96nxPZZ9p"
DATA "ninnuTbemvinzjPV/rribDu+epx9x9fEP3U82eqd1e8YT1RqgYMtsi9XTHOPB5V/Md/PtnmBi3+u9UUj/wz+fTywzYNCuafzT7y7"
DATA "0yTJW/m3rNf2efn9Iv/W532+9b7Y9U3bfDPX8TWNpyj+eb5Pc4gzBw+dfSXHQdD41L6fbfMCNT/U+Z7v+oqcB9ny0Tf/CpkHhUjy"
DATA "SfY3hn+i3hj+if7O6vPxL2J90zbf1OeDVMc3hH++9YzS/MvJwRYYyJF9NY6/yj/XNQdTfkgO+K4Dqtc6pNRzQGM+KvXq11h8HAud"
DATA "99l4ZatX76/8vOvajtrfrf8pxr56t/yLXN/U69U/b+OPb94nFdrfrX/PuAqttyUOcmYguLfPv5AxOuOfh306/2zsM15XdrDPxYGQ"
DATA "eZ+NeSYOudhn4p+LBTH8k3Xq883Q/ur1mvYx8c8379P55+vvHv8c7KvNP64c7Jl9NY/zbL0r8n631PmIj1u2879YmfgXwj2VQyp/"
DATA "dJn4J+qzfd7IP9f6ooF/KdeXSx1fXb71TV22eX3N/OiRgVzYV/pYenkTeb9b6nzE1w5K/sn6Yrhn44+Jf+p6n+yvi3+m9T5n/Y7r"
DATA "K67+WvmT8fia+KfWF3s93aXSudMLAw+JfbG8KHW/Wwz/Qtb5bNKvN1DzT57/hfJPP9+lur6s99fGPx+HQq+n246vcTzF8M/D29o8"
DATA "bJ2BHNiX+xiljJ3g8Ul0v1toe0Kvc5gkuEDCP8P6nIt/rvqM/MtwfVmNd8h9hbbjqx5n0/Mr+vEN4p/n+b1U/pVkYYsM7HnOt3S8"
DATA "BPNPG58+/oXORyj5p/NAXW+L5p/GHxP/1Pmej7f6ep88v3fVb5rv2a456PPB2uu5qc8vxxzvWiykYkIJBtZmH3fuzfgX8f1smxe4"
DATA "+OfKRyP/Ij6vc0K/3kDNP/1818s/7XzXxz/b+a7teqv6mRD+5V7PXfr8MqU4czAnA3tjX46x0bpS+RarezeukqlUm1s6jqV0SAzs"
DATA "hX0tja+SyskOSt7V5GFLx7OkemEgN/aBe2XUMu9K87Cl41panDhIxcAl80mwj7d65h44WEdcGLiEW72wr/Sxp86xVsSZe7k52IpK"
DATA "50IPDGyVfaWOcUvjP4da4h44OFepHGmZgWAfeGdSS5wDB8MEBoJ9YJ5fLbENDEwTGNgW+8C9/GqJZ+AgjThykCsDe2FfS+OzlFpi"
DATA "GBhIr14YCPaBe7HKxZlXn7u7WLna1tLxKSkwsD/2tTT+Sosj80qxsKXjVFpgYF3+gXv5VZJ53/7qN4JVkoUtHa8aqs3A2vwD+/pU"
DATA "bu7F8G4JD8HA/DpUBrbIvlJjgvpcrDXlZl4MC1uKWw6VGvOHxkCwD7zTFcu9V771/WSBg2kCA5fzr/Tcjxv7WhrvpRTKvSXMi2Uh"
DATA "GOhXLwxMZRL3uR+4x18h7PMx7Jvf+4lXKRwEA8PEiYMlGQj2gXupCjnfXcK7VB7ifDhdYCAP/nFgX0vjtoZS5nwU3AvhoG8u2FKc"
DATA "a6hVBubkXwtzP3CvjGLnfDZ2vfSjt6O1hINgYJxqMpDbHJD73A/sK6MY9lFyL5WDYOAytcbAHPzrnX0tjceacq33hbDPxrKXx22q"
DATA "fvDesFcWw0EXA7EWmKZDZmDP/GtpDNZWKvtCmKfq5m/3+edjYSoDW4p/bR0i/8C+ZZxIFTc/oee9S9kndO5nbv6lMDDkunBPxwsM"
DATA "pGEgZ/5xYh/FmG1FqewzcezeuJ8qwb6jr32w/qlvC+FgKANbivdStc7AWvwD+5Yzb+kzrNz8hM79fOzT2SYl2Hfk6v31T9tnYhgY"
DATA "Owfs7XjlYuEhMLBH/uXmXsx4bV2hc78Q9r0q8neUYN+x72wYKMtiGRhzHtyzcnMQ/AP7Do15IfyLYZ9knMq+8z8d9hho4mAoAw+V"
DATA "f6rAwDj+9Tb3K8290Of3fffttuAndO7nYp+QZN+t3wxbBuqfcTEw5npwi3FO8VOCgz3OAUvwr1X25WBey0qZ++lce2WMq2TfG3/a"
DATA "MVCUuxiYMgc8JIVysFcGluJfr3O/EPbF8CHm+a0W/YTM/UzsE5Ls++UnOwbKbaEMjL03+lCOV24G9jQHLME/7uyLvfYZO15DxnOL"
DATA "fmL5J/kmuffR33aSHDQxMJV/vcQ5xE8IBynPh3uaA4J/8XM+inHbulL5J1gnnntT+Sf+FuU5+de7UuaC4F9e9qXwjwv7YrhH9Vx/"
DATA "q35i+CdYZ+KfUCr/DiXOPj+hHGyFgSm8wdyPnn2U3DON49b9xPBPSDz3q/JP/K1up+RfT3G2+QnhIDUDD3EO2Mvcz7XeF7v2b+OA"
DATA "0BsR7zdx+Yl5T4qzPe8T+TG0J4Z/4pm34Q/3txJ/x/KvVL9aOV6xDKRYC+Q4BwT/0ud+PvaFjFlVtyLeb+L6XMx7Upzt+R2RH0d7"
DATA "Qq7/Sgn26WUx98CU7Bf342XjYCgDwT9a9pXgX87z3qXsEzof+H4T32dC35Pibc9bRH487Qll4GPnLy1mX8l+cT1eMQysfR6cm3+5"
DATA "GJibfbX5F8M+X84LiVw69toH65++57lcfmLfk2Jtz5hLx747tmf8uchPQL/0cp1rUoJ/tm2hvkv2i/PxSmUgd/5xmQNym/ul8C9l"
DATA "7udjnz42pUQurcRzroHvN7F9JvY9Kdb2jLm0ujK2Z/y5yE9gv2wM/Owv7w7Dpx+tJfgnfn76zq+HP95/08k+Lv3ierx8DMw1B0zJ"
DATA "W/CvzblfCPtkDotcOj7llO/9Ji4/Me9JcbZH5NJrf17/XORnYb9U/klJ/rXcr5rHy8bAXuaA4F/9uZ+Pfeq5m8ylC+M5kJ5TtnFs"
DATA "8hP7nhRre6ZcOv+zB3s5FeUnsl+mOMXwzxvnSv3idrxCGchlDgj+8eFfytzPNXaFZC7dHq8DypzSP+PLAaGU96QY/Uy5dOu3D7Y5"
DATA "leInpV96zEL4Fxrnmv3idrxqzgHBv/74Fzr308eluI4pc+mH7+1yynd90+Qn5T0pRj9TLr3x3i6nUvyk9EuPnYt/sXGu2S9ux2vp"
DATA "HBD8A/9i536msSskc+kXn+xyynWPh81P7HtSrH6mXPq58DPlVIqf2H6ZcjOUfyFxrtUvbscrZg4I/oF/Ofgnx6fMI/X5LplXtucb"
DATA "TH5S3pNi9DPlkepH5lWMn5R+5eAfh35xO17gH/jHhX8id8RzVOr4FX+L8pg8SHlPisnPOnfe19oz/i3KY/yk9Csn/2r2i9vxAv/A"
DATA "Py78E7ljyiehmDxIeU+KsT1j7pjySShuXhLfr6zzv4r94na8wD/wjwv/Nus38/Er/la3h+SBUOx7Uqzt+Z3WnvHvJD+R/crJv5r9"
DATA "4na8wD/wjxP/xDNU6vtNxN8peRD7nhRre97S2jP+neQnsl+5+VerX9yOF/gH/tXmnz6GhULfb9Krnxz8Q5zD4gz+gX85+BeTmzHv"
DATA "N+nVT877/xBn3P8H/uXh35LnP6Ri3m/Sqx89J138Q5zp4oznP8C/EP5RP/+b8n6TXv2Y5iQx/EOc0+OM53/Bv5xzQFNuClG936QH"
DATA "P6ac9PEPcaaJM97/0jf/aswBQ3Iz9v0mvfvRczKEf4jz8jhznfuBf23PAU25qY7jmPebHIIfPXah/EOcl8W5l7lfq/xr7Rw4loG2"
DATA "/Iy5vinHba9+TDnp8oM408W5xNyP47lvLv71cg4cOgdMZWDM+D0EP3pO+viHONPE2cS+2nO/Vs99e+ZfLANt+SnHsm/82vbt1Y+M"
DATA "2eOvvzWc+trrVontUohzepxT2Af+8eAfhzlgKANt+RmzviXHba9+VKXwD3GOj3MI+1qZ+7XOP85zwFgGhnIwdPwekh+hUPZdffNX"
DATA "iPOCOJvGLTX7uM79cvOvtzmgj4GxHAxd3wpRL35kzELZJ4Q4p8fZxb2W2Fdi7vfFM6fBP20dJHQuaMvP2PHbsx9VKfxDnOPjHDLn"
DATA "A//K8a8FBpo4GDoX1PPUN359Pnr1I2PoYh/iTBdn6msd3NlXin89zgFjGOjLT9f4DcmB3vzosXPN+xBnujjnYF9Pc7+S/GuZgS4O"
DATA "mnI0Zvwegp8l/EOc0+NMeb7b49xP8q+3c2AKBqZwUMo1fkP279WPjKGNfc/efwdxJowzJfdS2cf93DeVf4fMQF+OIi/duWhjn8o/"
DATA "xHl5nMG+w+YfFQN9HNTzNGT8HqKfVP4hzmlxphr7S/KvFf6BgXQsdI3fkHHbox81fjb23fv9h4gzYZzBvnD2cecfNwa6cjR2/Pbs"
DATA "xyQr+zT+Ic7L4twa+2rzDwykkfP9bfCTxD/EOd7PEh0i+3rnX24GmvL5x+9+vNXbfx22cvoa95N+JCeE5Hmjev+wrz2hbXL5EZ+T"
DATA "++rtUtfyfO0JaVfI/mr7fe1y+XFdh45pl4yh3iZTu3zt0e8NovieiNXSHGuZf4fAwFwcDGVfCv90zpTknyuf9TaFxMmYzwn8C2Gy"
DATA "y08o+0L4F8rkEP6FtItivFJzrwf2leSfUE8MDGWfjzeh7AvhH9V8NJTJqfwL4YzKv1Amh/DPypjAdnGbjx4C+4Ry8a+FOSAVAyk5"
DATA "SMk/33lvCG+4zUdD2hWyP9X5eOjcL5R/IUwO5Z+PyRTjlYp7S9jHbe7X0hyQkoEkHAxkXwz/XHM/DvyLaY/aLtMcy9sOLc5L56Oh"
DATA "7AtZH+V0Pl6SezXYV4J/h8pAqvlgNGM8ORHLGFuOBq/5WRQ7x/LxL4YzNl8xc6yQNi2ZY8Wu+bninGPNjzpXemVfKv9qMZAbByn5"
DATA "lzLHMrUnas3P0Z6UNb+ZHPPRFE7EzLFc3KKYY1Hxz3Tem+JHihP3SrMvlX+l54AcGZjKw9hzXhdvOPHP1KbYPDSd90rFxpmCfWsl"
DATA "rkWauEU1H11yzSNnHtRiX8m5X605IHcGhvKQin+xa34xbUr1E8M/Y9wca5GxcY653hvDv1Q/teajpcZ8a+xbyr9WGViSgyaZ+Jfq"
DATA "S+cfVZuo2hPbJtd1mBg/prXI1D7pTE71o/NvSXt0/qX6ohBFPrbIPjAwXeCfWa5r4zF+TGuRqX3SmZzqR2dyqh+wjw/7avGPioG1"
DATA "OKjm9ZIxzI1/S9tEzb+lcTG1KdUPt/noElHl3lIGcOBfDwwszcEc/Fsyp9BZQ8nkmHa57osM9ZFz7kfBv6Vt0q8PpfpJEWW+9cK+"
DATA "nhhYioMqZ3rmX+z5no19oXluuyc8tS+h12Fi2sblfDxG1DnWG/uW8I8jA3NzUGUfBWso1pWomLykXVT8o2CfZE0O9lEyeUn/fMqR"
DATA "V7XYl5t/tRnYEgdVzsj17BQ/pufiKdok27Wkj6ZntkLaYFIIjynPe02cWco/irVayja5xJF73NnXMwOpWahzZglrcvBvaZvUdunP"
DATA "q/raYGKfj3/U573yGKXMQW3t43Y+ritn3rTIvs8/ehIMzMRD03PxS3IrZo4V064lvmTbbM/rmz4fyz/XOxeWtp2KfUJU1+kpmVwq"
DATA "R1pk31L+cWBgSQ6m8FB/JwglY5bkF1W7VEbZ3lWi56GNfUJ6nF3vdlnaZkrOLL0nUtWSNpXOBaocrsE+yb8eGFiDgyHSOZPqx8S/"
DATA "pW2iaJcq13utpHT+6WsE0o/vvVYU7TXNQ1N9mfhH1S6KvlKLMm9rs28pA5e0v3cGmt4Hl+pLn2NxaZfuN/QdiKa1yJB3DVK0k5J9"
DATA "QrnYx5F/XNi39LzXpFoM7JWDei4v4Yzp/JKqXYIvlP2OYZ/pfNw096NsXytzP07848S9HOyreR6cg4FcOEjFGUr+mdpVgjG9sU+o"
DATA "93Nf6pysyT4f/3pkYG0WUjJGP7+kbJc8x6Tsuy2vQ857S7SD07mvqX3U/Q9Vrhzkzj4uDOyJg6Z1rFRfprW1JW3LdW3BJdfcL3fd"
DATA "Lc39avCPM/dKsY+CgdzngiVZSDnHouafkOm5Bcr+63Kd9+asNwdfeuBf7hyrzb0U9nFiYAkO5mYh5RzLdl/JkrZR5nFI+23nvbnq"
DATA "LHHe29K5b4l8osr9Wuw7RAbm4iHlHMt0XXVp+0y5nIuBrmseueprbe63dG1XV+nc6YV93BhYg4MUTKQ+xyyRz9TXXmUMXdd7qb97"
DATA "WmCf6Xgu4V/N/KDMcy7s48jA2hxMkZ4vS3yZcpq6jeqaJYVvqRD+UcjGvhzHcmnbdfZRxqGEqHObG/uoGHjIHDTNGZb4M80ZqNpp"
DATA "eq8VhW8h171+VHXY7r/mfhxlu6nikFvcuJeTfZwZ2AIHW+GfiX2SVxT+Xfc5U/h3PXuS4zhSz/1a4F+O/G2BfdwZyJ2DpvNLitxR"
DATA "74mhaqvrvVZL/Lqe713i1/bOBSru6cfvENmXK2dbYh8lA3NykCMLqdfWdPZR8EmV671WqT5d73ZJ9el65wJVLEzzd87fX1TKmZ9U"
DATA "DCnNPmoG5uYgJxZSX1swPUtG2V7fe61i/bneaxXry/e+Gco4ULNPiOvcL3cuUnJjCb+eOnHsoBjIgYU5ri2Y7qmjbHPIe61Cfbne"
DATA "5xzqI+Rdg5T9L8G+2vwrlXtc2Cf5R8HAVjlYi4X62tpSf7Z7SqjbHfpeK5cP29zPxz/bWqTOZOo+5zjvFeLAvpJ5xol7Kvu4MrA0"
DATA "B0vyMMe11RL31Mm8dbHPtxZpY5+Jf7br0D2wT40X9ZqFTTXyiZoJOdjHmYG1OJibi9TXVYVy3lNny2ET/2Le52xjjI99FNdifGr1"
DATA "vJdDvuTgQE72UTKwZw5SyTSXofBrOr/M2Q/X3C/k//JI5R9VvGwytYsqXnqscvajtLhyL4R9LcwFe+Kg6VxuqU/bHKtEf0qwr0Q/"
DATA "bO1a6tc0Ty7RnxLKleuludfKXLAHDprWsSj82jhTsm+U570l252LfUI9zv04c28J+1phYOssNN1TQuHXxpha/fS1i3PbKHz3xL7c"
DATA "ucyFfdQMBAf3ZbunjsJ3zrkMZZs4t4vCt+36UK2+pip37lJyhop9ORhYgoMtsdB0Tx2Vb9c5Zo2+us57ubSHej7a8tyvRJ5Ss4Wa"
DATA "fa3OBVvioel+EirfrvW10v3kxD+wb1+lc7IV7rU+F+TOQts9xVT+XddVS/aTy3zUdS2Gqo5Wzntr5B81Q0qxrzcOcmKi7X5iKv++"
DATA "e+pK9NF1vbdE/b7r0NTHktvcr3aO9cC9nAzkwMGaXDTlDXUdrmfJcvevJv9c7KOuqzb7uOVQDk7UZl9uDnJkYQmZzpmo6/C9QyVX"
DATA "31xrkbnq9N1/neP46ccwV984KxcTOHGvBAMPjYO2Z8mo6wl5rxV1na77nKnrCnn2hLpO23kvdT2clZMDXNkHDtLK9ixZrrp877Wi"
DATA "qqsE/0KePaGqS9Whsy9n3rfAvVIMPBQW2p6lzVFX6Hutltbjug5NEa+Q545zx++Q2Fciz1viXg0O9sxCWz7H+glVzHutUvy7rkGn"
DATA "+It550KJmFF+V3BVqZxuiXNcONgjC0vns1Dse61C/VLwL/ZdgyXi1Dv7SuZvS1zjzMGeeFhyHUtV6jv9bP5c9x/a9gl5z/QSJqfK"
DATA "1q7c9ZZQjTxtiWMtcrB1Hpa6hmlSyfc5x75jv8T6qK7e2FczH1viVk8cbJGJNsaUbEOu9znH8I9iLTJVrbOPS861xKlD4WALXLQx"
DATA "pkZbarCv5rVVW7tqtMUnrjnVEpdqiOtx4yQXZ7i0i/q8t2a/uLarFbXEHy5q6fjWkIszHNsbMvfj2G6wL10t8YazWjrmJeWaY3Fs"
DATA "by/s49peDmqJKy2qpbFQQr5zTE5tdZ33cmqn73ycU1s5qCV+9KSWxkhuuc4vubTRdc2DSxtd7OPSRg5qiROHoJbGTi75ri3Ubp/r"
DATA "em/ttvmuQ9duHwe1xINDV0vjilIh95XUbBvnNoF9c7WU7xB4qMp3X0nNNnHhn+8enBptqqmW8hlarpbGZopC7icu2R4uc6yQ+69L"
DATA "tqeGWspTqLxaGss+ufinrhfmbkfN+Wjosye521FSLeUbBOWWzj7bewRy1e/iX646Q589yVU/BEG8FPNeK8p6XefjlPXEPHdMWS8E"
DATA "Qe0o9r1WS+tzrUUu9R37zoXcsYUgqA2FvNPU9M6F2Hoo+ed754yNfbVjDUEQT1G808/l33Udpma7IAiCVHF5n/MS9rUUbwiCeKr0"
DATA "+5xj37GvtquluEIQ1J5yvM85de7XUtwgCOpDHM57W4oXBEHti+N5b0vxgyCoPeX6f4wor3m0FE8Igvirpeu9uNcFgiAKtXK918Xk"
DATA "luINQVB95b7XJffcz9SuluIPQVB5tXyfcyiTWzoeEATlVw7O1D7v9bWppeMDQRC9cs2xuM79TO1q6XhBEARBEARBEARBEARBEARB"
DATA "EARBEARBEARBEARBEARBEARBEARBEARBEARBEARBEARBEARBUA9awWAwGAwGg8FgMBgMBou1mzc3P+/cEf8+//zzX/nKV8RvL7zw"
DATA "4osv3txsvX37zp07zz33nPh9s3W1evHFnY/NvuPe6213XxD7it9u3Zq2j3s+//zm97sv7Pa9dTtsX852U7Zzit8Yvrvityl8661T"
DATA "+NYR2Gw1x09GXuwrfpMxEJGX8XtBid9tJX6ufTlb7Bi5K+M3jVu5rzARA7GvMDFyb90WEZriN43bdfzW+wrPcl85+tR9N7+3Er/Q"
DATA "MSLjJ/Ne7rvePm4T+663j37H8K33FCNX5v0Lo19Jhd2+cvSp+06+pzZxNfU474+RKX7K+Jpv3e0rTMRWxkAcF7mvOC4qN/Xxpdar"
DATA "7itMHlOuph7n/TEi2DcfX/Otu32FreMn817EYNp3HT+Fm/r4UutV9xXGP37Tl8O6H3fvym/A8avj1o5fu+9lYfPRJ7+1xb4iPuuv"
DATA "nXFf9Tt9zs3N1t2+W7+zfTet2m3ladvwrcfIFL71GFmHb+LX7ntZ2Hz0yW9tsa+IwRQCJX46Nzdbd/vK3+f7TuFjHj/bd6v8Xllv"
DATA "03JoL34B3NS/W13f6fvM5Wu271Zn/JRtcl9hLm7q362u7/R95vI11xiRpjNIja3cV5j8bl37VWJg+l42zVxs+3I21xiRpufQXvy0"
DATA "71Zh6xg4vpfl1t13un1fzuYeIxvbi5+yTe4rTOWmfj4jtoovh/U2D3P39+Vr7jGyMZ1BamzlvsJUburnM2Kr+G4Vv/mYu78vDAaD"
DATA "wWAwGAwGg8HI7FndovY+cNsLHkIYbttwfXlnCGGo7cdOi2GUt4MzW/CUEEb5OyxTo/eluSGCfttFTwueGkIE0Gbb8MmAfVHaLIII"
DATA "oNG2uavFbh5D5LDNZoNvL3rbCMohGOX7AEwdfJtw/Z1qWgQRQM2U8BmiN48gArhnE/u24duE7AujnRH/KBGcAggEzmwevm3wRnts"
DATA "+rmN4C6AUTW0Yvsn/QElu+zVw/eF0/IXNYCzU+LIuqJ6U9gMXQq1efjWEbsx2ulHT4sf2wjuAhjlvYUQqqHQzvn9JbvhJ8Mnwnbj"
DATA "xqOPPLr5RQmgOgBT6mIZwv22xtpu+G3Dd/36I48/cv26GkAlgxONZQSXBm8bPyV810X4LogAriO4C+Cy+MkQRvUvr6nR2z/pDy7Z"
DATA "Db8pfNcfv3D+wuPilymAyndwlOdZCbsI7qKnNTbSZsNPRO3ahfPnzl+4NgVwNgAX2C6CUb3MZtvwKXGYr5uEl2yH3zp8186fO3vu"
DATA "/DUlgOo0Or0uTgFUvz7Vtm7bHFWixu/atXNnxwrOnlsHcB6/eM/zGPLJ4dng22ttrM3jd/bMWMGZs5b4pdpsCEb1NYOpg28bAu2s"
DATA "P65Eid+ZdfzOzOOX7lmWMFrHUcJniN66xbElSvyuPTZW8dj40xC/BM9aBBkEcGKfiv9NBL5wdLduMpUoKylTyaW9kvVeSvxOj3Wc"
DATA "VuNn3yu8LjWAlRE4D9+2saN9bnfav7+SMv321F7JtNf2+/fatZX4R5nAOPYKrYvPOs7sxHW+bvKw/MWwkiJ/ubhXIvfaBVDEbxY+"
DATA "x15hdSkBrJ3B2+Enwyc7f+Phhx7erpvsr6RsSi4+eVEr2e4lzz+uX19tfuyKHXsF1jUPYMX4OdZNHjry0HbdZH8lZfPLk088qZXs"
DATA "9toEcKpnCp9/r7C69tdxYjpNHr/d8NuG7/r1I6eOyHWTqURZSZlKnrj6hFai7zXVE7mXp65NABkMQH34yfCN6Xbk1EnRqU2L91ZS"
DATA "NiVPXL0iOqWUqHutPU0VKSPSs1dIXbsAVh6AhuE3Nff6qZMnTp6S3NpfSVmXXL3yzJWrs5LZXsLZVJFKRM9eIXVxGYBq/HbDb/29"
DATA "efLE8RMn5ffm/krKuuTKM5efuTIrme0l3E0VqZ49e4XUpQ9APvGTzb124vix4yemicf+Ssqm5JnLT19+Zlai7rXu5lSR6tm9V0hd"
DATA "ygDkGb9r144fGzcfO745b1iXzFZS1iWXnx5Lnr6slMz2MsbPu1dIXQ3E79jRcfPRY0oPZisp65KnL40ll55WSmZ7WeLn2Sukrgbi"
DATA "d3Tdp6NKD2YrKeuSS+s+XVJKZntZ4ufZK6SuBuJ37XPj5s9N5/2bEnUlZVPy1Fjy1KxE3csSP89eIXW1EL+Hx80Pz3qgrqRsSi6O"
DATA "JRdnJepetvi59wqpi338tHWTtBLb9y+RZ57xM6+bpJVY5n9EnrnFTzv/mK2bpJWITk4VZfDM5/zDdP47fUA5A40uWQ+SqSSDZxYL"
DATA "MNb1l2n7+vfEknUnp5IMnlksAFrX/6btU3PTSkQnp5IMnlms/1nXn6fNygpwfIlwN5Vk8Mxi/dl6/WPavGltWsm6k1NJBs88rn/Y"
DATA "rr9NW6fmppWITk4lGTwzuY/acv132qpcgY0v2UZPGLFnNtd/LfcfTBs3rU0rGU2phtgzo+dIjPe/TNtka9NK9PgReuZz/4v5/qtp"
DATA "0/RXWsmXvqRUQuyZ0f1Xxvv/pk2b1qaVjKZUQuyZ13Oc+/efThuUO0BTSr785akkg2c+95+Otnf/81S+7UBKiXA3lWTwzOsJOv3+"
DATA "+6l4amxaiRY/Ys+s7r8fbf78x1S4/TutZNvBDJ55RW+0zUM9U0ensiW9VLuYwTPfJ7hET6cS5Qm0lJJ5/LJ4Zma2fieVFPLMzPba"
DATA "m1hS0jMMBoPBYDAYDAaDwWAwGAwGg8FgMBgMBoPBYDAYDAaDwWAwGAwGg8FgMBgMBoPBYDAYDAaDwWAwGAwGg8FgMBgMBoPBYDAY"
DATA "DAaDwWAwGAwGg8FgMBgMBoPBYDAYDAaDwWAwGAwGg8FgMBgMBoPB6tv/A8IQW90="
DATA *
