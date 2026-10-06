' waterfall.bas - palette color cycling
' Exported by DRAW 2.5.1 (https://github.com/grymmjack/DRAW) on 10-06-2026
' 320x200, 51 colors, 2 cycle range(s):
'   1: 27-42 FWD 16.0/s
'   2: 43-50 FWD 8.0/s
' Keys: SPACE pause/resume, + / - speed, R restart, ESC quit
'
' How it works: the art is drawn from a 32-bit image, then an 8-bit overlay
' holding only the cycling pixels is drawn on top (overlay index 0 is clear).
' Each step the overlay's palette entries are rotated with _PALETTECOLOR -
' the pixels never change, only the colors they point at. Speeds use the
' DeluxePaint CRNG unit: 16384 = 60 steps per second.
' Compile: qb64pe -x waterfall.bas

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
_TITLE "waterfall.bas - color cycling (SPACE pause, +/- speed, ESC quit)"

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
DATA "eJztnU2IrVt61++595x7z/2+ra0GDE7MoFFQiAFBetDgx6BxEEEUwYkaHPpBEDIQQR0JnYlOHGTQEyeCtANRkTgUghBRB5kYREGC"
DATA "IKSbBELohC7fVbeeuv/61e9Z7961d9WpOrVezlO193rf9fWs//Nba737rbP/zJ/+K3/6xTvfevFL7/yJd754/friO9/8xsUv/PSf"
DATA "vPhXP/NnL/7jz/3Fi1/+zl+/+J/f/bsX//d7//Di//2Hf3bx/f/0Ly5+87/++4vf+h//+eKHv/arFz/+h75x8Y0//s2Ln/rWT198"
DATA "6y/8zMWf/2t/7+Iv/+1/fPE3/sE/vfhb3/nuxde/+fWLH/+rP3HxE3//py7+2D//9sWf+td/8+LP/dI/uvjulv5v/9Ifvvjlv/OT"
DATA "F//r57998evf+9mL3/lvv3Bx8X9+8eLi+79ycfHDH1z8aPv9o+39727p39/O/+/tuv+yXf/vtny/9m9+7uI3/vu/vLj4wa9eXPz2"
DATA "r1+M40fb7x9t739zS3/3nT/4zh9558U7X/vaO9txcTF+/tF3fvKdr73zT15/lTJ6u2zZsmXLli1btmzZsmXLli1btmzZsmXLli1b"
DATA "tmzZsmXLli1btmzZsmXLli17WjaedFy2bNmyZcuWLVu2bNmyZcuWLVu2bNmyZcuWLVu2bNmyZcuWLVu27Kna+F++li1btmzZsmXL"
DATA "li1btmzZsmXLli1btmzZsmXLli1btmzZsmXLli1btmzZsmVPy8Y3fC5btmzZsmXLli1btmzZsmXLli1btmzZsmXLli1btmzZsmXL"
DATA "li1b9lTtl7/z15ctW7Zs2bJly5YtW7Zs2bJly5YtW7Zs2bJly5YtW7Zs2bJly5Y9Afv6N79+8eN/9Scu/twv/aOLP/bPv31tf+pf"
DATA "/80n1Y9lyw6xn/j7P3Wp7aH5p9TuZee3wbmhh/F78K9sMHFoZJx7Sv05p/3P7/7dZW+R1bw+tD00Pvg33j+lPiw7nw221ZpvvB56"
DATA "KBbWuZE29PKU+rVsGa30XOyr32OOf0r9WHYeK+6N8a+1XvJvpC0GLnvqNrRb93aGxsfv2v/Wnucp9WfZ6VZ73Br/uv9XDCyN1PlK"
DATA "G7+fUj+XPW8rPdd9nPG7GFiaH+lPqU/LTrPiWI39pUb+0DcufupbP33xjT/+zUur98NKO3XvZM2Xy56CDb7VHrfu7Vzf5wm9r/3v"
DATA "87H8rKN+F+/KShf5O/cO657xssdu+fxCrf/G+5rTS9fDhuafUt+W3d3y893Bv9RArvnG62TgJSOv1os1pz6lfi97Xpb7levPeq/0"
DATA "XVpPBj6lvi27m9V8WHve4prNiWmVfqmbuDf4HO6b/N/v/cNlT8zyWYbxmvuaYl/O90+pf8uOt9JDfaabe95iW+qjNJJ6yfsl+XnI"
DATA "U/LDsoexa/Zc7RnyXvN91lvzct2n5n2cnPNT1w/hk2Vvxop59ZxLjj0t2ZfzI3VU+4phT8kXy+7XinV1vy3n3bznfB/zZj3DVZ/r"
DATA "5rze3ecp3b9Jny27Xyv+1brPPuflWtDmSa4Di39Dz0/JH8vux+reSn7mWvMu/56o7s2dq+58jn/UYfdx7J7O2v++3VbPO9V+JDmW"
DATA "ZrogA5meOl774Odt+VxAPitQTKp5st7zs7RT6s7n+GpO5nqP93mo58fq12V3t2Lf9d92hBY6Bs7uk9i9wlwDrnXg87Qa//z/M/LZ"
DATA "u9Jf/p1lPktaGr1r3Vxvcs/bzfmp9cfs32V3s9wP2PMsHeP02Rewk88GnmMeX/Y0LefAvWdKx+tkFv+/oUM1lM+i5v9lYM/x81kX"
DATA "+3zvsft42fGaLI3YZxlkHO/9ce8wWwPW/e7S81Py07LTLNd6fNbEnifg3qH4xb817+6n5N/y1p73ek8t+xrTsX0m8lT8vewwTebc"
DATA "yjWefe4x+zzEnpu6dV8lnm94m/bB/+8//LNljeX/k1afrfF+8d69Fj6rl3+jW2ml59rfJiOvP+81Tco9607TT8nvT9Xy/xeocTt3"
DATA "HfmMc2qSewDybLYW7PbOt+4Txnw8Xt+H/zJWRj33MU7LDrO878f9pe0/bV1Wv0uv+X9S5bqyXue+uc6Zlrn2m+2FF//u12qNX2Oa"
DATA "/+dUzXnnqieff+J+w1hI7vF+jfGOGiMDqw3n4FPGWD5Hlv67D9Yum1s+38c9Jtda1J29rvuC+Rluvc/Pi7Pe+nveLMPqMzZSv0/J"
DATA "909NJ7Uey/VLpdW6vph113rymYO8F9M9A2DaSP3Y+m92f+V6Po0+Fq9O6VOuBXJPn3uj8udjGO/nYHkPLj9vtXt83G909wTzfMVC"
DATA "rvtSU/W3m11+zsndXibb8pT8/1Qs96F5fyP/Tz0+D1pjfUw9+f8ZVDlc73VzM58TsH2DpXMNeGM/E89B1Hx9TH9S+/wukvz/K4uJ"
DATA "uT449xjexz2Kp2z592V8zi51xM/I+HlDNxenrvKZwuvPe8E63qe2+302T7MtT2kMHrvxb39yfZe8q/MVz/b/0FfMp9n/YVXl5N88"
DATA "Uns31mmyx+X+1vRM7Zreh1V8VD/KB8mxmtvz/yLMe9v5+SD7mL7LvzU9dR1NW/vrm1aa5HN2tr6iXrq9quWx9eLefZzZPRzjXr5/"
DATA "SmPwmC33bMWq+m33zvI5lYzvfKYk1/25Fsr7YsXO2ZpO79eBdZ1OZ3rt9Me+5N9DJRv5/5PXdcVM/n81WX/5Ia8rO8d41vzyWPX2"
DATA "0NrO+cvmTZpxZ5an42m3p7Y53vYnzEcdPaVxeKyW65lc33R70Btz3lX8c82Un/vnc568xzbSbV6z+yScQ2dtM+11+2ib6/ldSvnd"
DATA "C5WWnOf/UZ7t4tx9o+2xhqw6z8HA/PuZ7/+nf/FsLe9H8FkX0xbnS67rqEMaWWn7ZOqSaz2rz9Z/I/0pjcVjtIq9fP4kP58ybtja"
DATA "K9dGyT4ykM9FdeNr+5JDNWdtN/bMri8G5t6Xz69m2o3nYMFk20dlXTnnlJ9OHdfi8OLfV98TQw1z/rM5tFujcXz3NMbr9taT3bqS"
DATA "7X9KY/EYLT+fzO/UmLHH5sSMZdvv5t9Z1OtD13rdfEyeGMfIVfaDDGU78v+gyeez8+/ia53VxVfHvkzn5yajvlPGdZSff6f6kJrK"
DATA "+5kPWS8t97zdOs7WaqbL2dga+3i+09kstphOHS/+na6PfCbX/Gvc4TzGudIYxLEnn2y+zXzd2inzdfq18qlJq499tn5Qp1YH66NP"
DATA "svxcH5+yDqx68nOp+9ZT3T/huvhca9q76LvmlNn42tzZ6a2bo7v5lEyjLrp13mxdkNc+tE/fFstnAfj/jpEbHBtjGeOZ13XxbvOm"
DATA "cZVaIJvZnm4O7rhmeTvdMhaMwabvGadv6Do+F7rr+FYb8jOt+9IS7wvk/Y3827BaS99XO9JyLW1jznmPY0bd2dxtGqCuyauufFtb"
DATA "mFbYjofw5dto+ZxHN5Y29pyX7DpytGPdjF3dvEidkqtsX9cX4w7XAMY5m49nvOvWHWwz9Z2fKd1lfHNs8v92OreO8nMW/n9RtQ7k"
DATA "/eX7XovmfWwyy8aRerB1FsdoTy/Uv8UKy7C5nm2hXu7Tj2+r5f372XxnMWu86Lhl+trTXVfmjMHGM+NKp1P2p9PoLO+M1TaP0Aes"
DATA "n88aHjvGWW/e5zgXA/PzGv5NC58B4j3Uuu6+9J3PmnfzC5kzYxv11o1xx03qk+Nv2mCdTKvX9+XDt9ny/zKwOcyY163T9jRgeuE4"
DATA "dmwih6191Ac1OmOY6dn6YWXO5vVZWYwBi8v6neuYY8eY7cpntE/ZVw/Lvwvn31XU/2WXHM/PjPJ+833shet5otz32rjR/52OOV7U"
DATA "rY25xUiOv+nf5kS+tpjJZ7L4fwvmPQf+/SWf1c9xyvsv+SxbpeX6vurJ53rzbzvzHlv+nxB87j//TiA/N819Q8ZD3dfJfmSe/L9l"
DATA "s678O23GIWOYuqDvjZOmFWOZzbHGV3LLNMfX1BnbyLVWxyTjMzXOPsxem8a7surafJboGA5Y+/PziN/8r//+TsbnN+s1/98Km6NK"
DATA "v/lM0fh917bQuA5Nn3ZcMv3PtN7NYVl+F08sd8bcWbyYT/n8Wf6NVf49Us5bucdITvDv+/O5Nf7dQtXD58GSpcWr5Gy2lfdL+Exs"
DATA "tjk1nPdVkn3Z/3wOLP8Pg27syIXZ/GlzqTGk05Plt3nRGNrNn9S58Wg2P++VZTzNtCx/FgOzPue1OV+NcTyUBTa2qeehgWPYwr9x"
DATA "ybk/fWDjxFi3v7M8B/+qvPp/9cgr0yc1NuPdjIddfR17Z3PgjKE8l3u5jPVkE3mSDMk5LP8WiZ9fJW9ucETmwVyrJbvy76mSe+QZ"
DATA "14nJbf7dbfUp14DZLt77qTYag8zPXRwbLzMtedNxxNJmTCYjMs+3/sLPXKaN36bXrl1Wj+UjO42XZCD7uFdOF0c5Tx+8FmrGxp5n"
DATA "PIR9/Nvlak/HPcbpLf3g7yRPWZMOy/WOsYptMn3bPGk+pL6ybJtjTQdWr2mk00TpPdlX3Bs+/fXv/ezFxf/5xYv/9fPfvrZKY/qw"
DATA "Sh/2O//tFy5tXF+vh41zI63KytfMX+eGVd4sM6+tcnk+y6g2Mm/WlenFzJoHkqfdeHAsTC82thwrm/M5xryOLOnKsTzJQeNoF5Pk"
DATA "In1CDpsWqdmsxxjQvTeNZ7157+MY/tk45bya92hsP5lrtJzr9+YNe0//5d7q2PVtWvomP9PrNE0GpVm+TmOdf61sjsce70xDxr+c"
DATA "k3Jt99z5x7Vu7u05T9sYGLPS/8xvHDFO8XfGBTVELbBdqYXSQ72v63I9ONMo9d71j223vnLdYCyd+Y9+GZZ7zkMY2MVnlV+64N8q"
DATA "5tqOe5Lre9zBEY6P9d/msmutxH4p708fvM692tvY/23Qzdkdk9LfNt9R2xyrvIZ97/pv84JpLvXN8ljveH3Jie//yjWnrrmypTH9"
DATA "kl9X6ZcGNl3bdo5cZLmVv85dszHSr99XXVfl8nyWcd1G5o26Mn3GGnKP42XjzPnJ5iuyw2Lf5k4bd7Ivy0m+ZXnFwdTL9T4B8WrM"
DATA "M590et7zk8VH5w9ri117zGcGtn5If9a6wf42kffR877LXn/Mb+wTOcPPDg/dlyeXbd3Huru5y7REhts54ybH0PjXxZ35tSzn+Hzd"
DATA "+Xjxz/dVHZ/IBMvfzWXUs/HVrutY0XHQNJK8S/4l+5KZVrdp29pmfetio9O+tcF8wni6Lj8+M9tb/zG2bvUP/98PnxPI++TGNc4l"
DATA "fJ++mvV1XFcM47MaxcRc7yWj8577TNcd5zg3WNtMf13ZFiczBrL+SuN9bGrb8uU4XLLhhz+4tX8daUy/PHeVfmlg07WNc7IHzXKv"
DATA "88f+9DpvlpnXXpV763yUcd1G5k2uRnoXxxxXGxNeZ3zsmGaMmOXvGEF9Zf7i2sysX6mfjvvW505jjG/jODnWsaDzG/1RcV/71b39"
DATA "r7GYPuCzC/lZ4qiPPjVG00fdfEU95vV8fovPV1cb+Vle3dNhv8ierv2cK7ox7bRqTGI/OU90MUe9ch+TfDR9lD13/jFWu/mti0lj"
DATA "BPnQjXenkdTPjJ+Mo455rKfbI/C1tWMvji0WjAnZZvPL7Br2uTvP/1fgt/7Hf75l3Xia7+tcPkvRPUPCNh3Cb/Mv+1jX83mGfL6M"
DATA "r6v/M/93zJ9pdKZniw2LA2qLvsv2cW7PPQ3byPvZ7FuVNxjwo9gjFldG2q30zSr98hzZdGWX52wPGnmv82cdlTfKzGuvy8X5G2Vc"
DATA "tZF5s65Mn+ncYtu4ZlrPsbD501g3Yx7HzThJDVIDufdN3qVeUkvG85kfjJdWjsWK8cGYaXqmto2BtV4j/2xsur5YDHVtJN867rGf"
DATA "Nld0/b0sLz5r5rO4yUDr58zve9qiFhkLs/G0fjB9dl2eSw2TfXmu68/i323dz+bgbk7seGBzHxm5FzfWBl5nY0+tUBNkJK/h/G0x"
DATA "PmM9Y37GVPMxmcA6M5/NDbVOyjVSsSLXf8zLsrsY7eYEXmPjQF2YDi1uzX/8e+G895n3+0x/3XyUvt9jfRc7nU+7cevaRf/YmJCD"
DATA "2fbcA9N/l5yQ/etIu5U+uHGVfmlg07XVPlcYyfy5P628N8rMusDIW3VlG5k36sp0+p1+6tI5ZlaG8cuYSLM6GVuMgdlzLeRJd729"
DATA "Nv7s8eEQts9Yzzi0OYBm/qw8ec+Of5fZcYWx342bcZCcs/hlWda3GY/Nr8Ou7/+hD+wjGTMbT+tPaYs6Yn02dvTh7FrrP+u1tsy4"
DATA "mHU/d/6ZXnOMOE52jvG6F+/dHGdpWafpgxpN5mVbut/MZ8Z6u/YZt9j/Gds4j1jMsqwuH9vHvyXL51S6MWB/6Xcbb2OT9cfGr9Oc"
DATA "jbf1kfWaRmf93Ctzxh5jY8dye8++0keMC5vjqXfbA7HcwYDfxecalcb0YZU+jGwquzzX7F9v5Q9GXueNMvPaKpfnb+xxr9rIvFlX"
DATA "pqc/cqyoWzIw/U1dW9xSR3tMsLiiHrP85Jedn82Jlca2ma47/tA/2VZjOq81bRqDbAyMH8YLfidJ/n/HZhzTzg8dKzptMJ1ldHOD"
DATA "nZ+Ni/me7TD/M0+m2b0Ramz2fo95po+sO7Xe6dbSOa6Lf1+mdywyfZFfxjXq3eKomwvtt40buWGfXXT7WF7Pz0C6+4HZBotP8xHZ"
DATA "3vW/484eWzvWdemXZeDeGPnStT/b3o0Lx5uxb6zsfMNryItuXuA5vu543Ok8NZBasLWV6SnzWH0z39IfXZtSu9YeG6O6bjDg+9/7"
DATA "2Vv715F2K32zSh9GNpVd5rM9aJRb+XN/WnmzzLy2yuX5LKPayLxZV6bbHMwYMI3a3NzpxzjHWLXyrYy8plvHmUaZZkxk+/fuBe7x"
DATA "zPpLPVt8GnNYn80pOVYcA45XPRfDdtr4k+82zsa0GbONR/SbzQnH+p7M6PzYtZkanN1bIf/IS2OttYP96TTdtYPptkasOp87/0zT"
DATA "NMaxaYv62dNbV94s7rtyyCfjlPHPzpuerZ/GCov39Af9bIwne7r+ZBtmHOnijWyzGGI/bdy6/tAn9FNn1p6OpdSs9Yfa7fyb13Za"
DATA "ThbZZ2Yz3WR+8y/9mmVkucnh1GzWm9dYTGSfBgP+989/+9b+daQxfVilDyObysY524NmuZU/96eVN8vMa6tcnr+xx71qI/NmXZnO"
DATA "cac+jVmme2q0SzO9znRg+ckrjn9a6qDTUmq420On5sgDcpvpnc+MO8Y9ixWOB7lGTprv6T8bo7zeeMJ2WfvJJfaDZbIM+s7YRe3S"
DATA "p3bO/GR5qRnb1/J6MocapS+rburamNutQa0tNn+nDxf/bq/DTFMWL11sGysZg3l+VgevJ6Nm+uh4xvx5re0V7H5hx+gZOyyWGQNp"
DATA "szgypszmoc7XNkYWJ5Y322RtsbHseJuvO6ZRRzPed22b+dK0Rg5R49QF5107n5xLm+l377e1Kdtt+hxpgwH/5e/85K3960hj+rBK"
DATA "H0Y2lY1ztgfNcit/7k8rb5aZ11a5PJ9lVBuZN+vK9I5fFjeMJ8aC+Z8x1THN9G/zY45pdy8k9dVpqmOdaZoxmPUaG8x3/G3ssTbQ"
DATA "N52Puvg29tn8lGnGMNZrsTTjCH1FHRhzMt8en/NaYxu1Oks3bncsJ4foY+5TTac836WZ/ozDbG9eSx0s/s33R+bHveuoC673jXem"
DATA "PeNLtwdI3ZgeyDpbL1rZXXmdDrtYogbzXKfnjmeM9Y65WTevY1uy7exHN17kTVcW22pt63xEBs58yfpY70y75CHXatRzxyJjUpdm"
DATA "bLWyuHY0Hnb6Tg3bPDIY8O/+0h++tX8daUwfVunDyKaycc72oFlu5c/9aeXNMvPaKpfns4xqI/NmXZlu8zU1z3nSOJW/uzU667F4"
DATA "prZTw9SCadSYRo51baa2WCcZbNYxjGwxvpjfjEHGMTLKGDZjDdnAOWiPKVmvcWY2n3I+6Lhndcz6bW0xbdFHxjxrN/Vj+wqux6gv"
DATA "ao3sYhmztqU2rc22zln8u73/nOm54xw51OmO40IeWHxmPlrXDtMaNXlo3o67HeO4DrJ5wzhNnTPOxnnOEcaA2W/Ge5U5m9PIWzLG"
DATA "riMj00emMfqR/KP2Ok7O5gS2nfmtLbbuYjs4RjONZB02/mQYtWjzONNtLcg21/vBgO9+8+u39q8jjenDKn0Y2VQ2ztkeNMut/Lk/"
DATA "rbxZZl5b5fJ8llFtZN6sK9NNk53mU0uzOSjPz9ZjNjfmteSfjWvHEeMHNUCtWj0dk4yppm+2qYuTbPMh8cJ4tfmKaYx3i3/jddf3"
DATA "rryuXdTT7DfZzXqYh2xn/7prOp/buJh22F/jDNOpWere6iULTcvGQmqXflz8uz03W2xx/Ds2ddzpmJJc6NZbppUc526uJdeoc+Ov"
DATA "lc+Y6PrMayyN8dOxxfKZrjlGHEPyKrVPjpB7ZIWxya437XRr446R5JWVneXPuNn1M6/vGEWedLoxFlLz1DnHeaZVG3PTEWMi+8mY"
DATA "HDYY8G9jj1hcGWlMH1bpw8imsnHO9qBZbuXP/WnlzTLz2iqX57OMaiPzZl2Z3q0jbC6nny1uD1nHWKxbvFv5HQsyzfjKc6YT6nLW"
DATA "RpbL9pGRLNPaNZv/09gGMi3j3Paf3IeTo11/bN/Y1UO+GJc7RuV70wLz81zHYeqFDDLtcB6mTzjeLKPTsI0j653FwV75jNVOC8+d"
DATA "f6Y323NQJ3m+Y4tpxLjS6YDlc8xtLdbN1caU7nrO2117TG9WFvVu+mSdbF/X326PN1sv5XV2zpiXGuEazdhjdZOZZFCWzbp5nbGo"
DATA "4+lsjq/rjEHsQzd21Khpycozbhl3Ow0bp1k/x4LvBwN+WfavI43pwyp9GNlUNs7ZHjTLrfy5P628WWZeW+XyfJZRbWTerCvTqefU"
DATA "EfXXrVGYxvmPnGMa86YuUhM2tsaorp6OsdYGWwcY/9h/a/teHV0sMHbYXzIq2dftUY0rVm7HLpsbOx6yDmsfyzeWz9pkrGQb6SNy"
DATA "0MbYdGYcMa13v0037I+1gxroYop6tLHjOvy586+Lo25+sXmOY7mnpY5L5JvNffneuMa2moaNjaZTMpZxQh9YLHVzgTHceNqZsXW2"
DATA "XjIG7I0buWoxnpzq9t/cp9LX9Jexm+WQYVm+cZ485bU2vuR3NyceMnapBRsf1tu1x1jaaYO+MD0MBozvBOf+tb5LPNOH5feMk01l"
DATA "45ztQbPcyp/708qbZea1VS7PZxnVRubNujKdGsr3nENsTE3PxgPqiLFv42fjaSwwdplejFt717FfXV+tvVYOuZta7/TN8sx/e/tQ"
DATA "siBjgnFMfnXsov9meU1DpheOQbLP4pjstfUu29fNEx17TG/si+nEyu3K4bh2msy2Ue9sh3GWPlz8u702yfmXzLDxt/iw8elYQ72R"
DATA "mdRGN/bGk47V1Bzzdhq19pB1xi1rg/HU2jVjB8ua7X+NZVZf8tTyG2dSN8km8of+nnHD+DXjOBlpbcsyOvaSXdRM105jlPFpdi7T"
DATA "eN0eb7NPLLNbOw8GjO8E5/61vks804fl94yTTWXjnO1Bs9zKn/vTyptl5rVVLs9nGdVG5s26Mt00lOsC45rxg+NKjRgrjWXUtsWK"
DATA "xXDHTONMp3djIftg/DKmWmyQcx3/92Ks03jqOuPe2Gh+4dh0e8U8z72D6YVj0o1n13crN9ONbzPuZ99m/aevO8Z1/uny5znOaRYz"
DATA "ne5Yx961Nn7PnX/pI9NKatLmK9MnWUNWkXcceyuHPNtjAcv/83/t7924fryv3xZ/xjJ7zfZ32rM6unhgGYw5q7/O2TyWXCQjOT4s"
DATA "M9the1o7xxg2P2R8UxemLeN210db/5GTVr+N40wH2UZeS93ucc3aY/yiBsx/dX1qvvPzYMD4TnDuX+u7xDN9WH7PONlUNs7ZHjTL"
DATA "rfy5P628WWZeW+XyfJZRbWTerCvTqXnGg8Umx6HjnF1j4zczlmlMMP1YW4p5ZaWPjjFkVsenmc5n/O78RaZ2+u1iwlhF3rH93bix"
DATA "rbPPJJJRHEdjYTe+5veOsx13rU1c81ldbAfHtONeltGVm+NlY8ZxmPmpi7HSNLXd6e658y/Hoxt708chOjiGgxbbpqVOm6azSh9a"
DATA "KEsWcn5MP5gvsn98n7qyOKDWeT3rJ9s6rs8YWnzg72Sh+Z6+NNZ0XLQ4zjJsnIxF7BPZbn2zsuxeAMfFxsE0x3Hv2sd2dONq6Z2G"
DATA "OU6Mr3xd2t5j7Xg9GDC+E5z71/ou8Uwflt8zTjaVjXO2B81yK3/uTytvlpnXVrk8n2VUG5k368r02RxEXhlzGKed7u16G0tqoGOR"
DATA "acSYW8Z5MV+Tg4zFGYctLqhbu95YaeywcehiiNczxm0dRC5ZPyqdnz3Yftj6kv20frAN9EvnO/KPZvt9+oltMz9Y+1KTnc+MreRj"
DATA "55dOa+afZF3q3XRCvz53/nHuMvZ0fDF/Wjx26cbLji/kYF5j+s37e9RFzpGsp+4HUqvGGMYTz83aOYsN456V28Wv+Zf7VbbBzPph"
DATA "7WLcz9hi2pnFP/1MBuV6NsuxfS99bjxhm2bnrW92rXHUfGBjT91b28i+fE+dc+wuOfH9X7m1f63vEs/0S37l96GDTde2nbM9aJZb"
DATA "+XN/WnlvlJl1XZXL81nGdRuZN+rKdPLHNNCxy8a5Y4fVY+dM9+Sk1UE25h4g06gJXmPxT31n29l+lkHdmw8snqwM41q2m/7j9ayT"
DATA "n/Pv+de0MGtbx3T6mizI/nRjXDbb+1YfrX7TMPVGXjDNGNXFz55vTMPGyU5/1HjpvH6Tu/V+8e+2ZhhDxjLTbRdDHNPUhZ03tlCr"
DATA "poF6bWv/5CH5Z8wqzezFeebdi10rr+PerK9WhpWdjOBesH7PYjPLNVbQ9xb7ZIfV0fWj003XP37GY/c6O6bYGNnY29hS/53PeO6Q"
DATA "+jj+mW77l3rPz/qs7yP9kg0//MGt/Wt9l3imX57L70MHm65tnJM9aJZ7nT/2p9d5s8y89qrcW+ejjOs2Mm9yNdJn42cs7DTeaZMx"
DATA "m2PZxUWODzVmsWPvbS5kTHWcZDwYp62PbIuxgbG8FydkUecz9p2x0+0FrZ3WHuujMaxjBPtgfup83emy6wfXtXttm3G38yu5Y37s"
DATA "4iKvYznWVmo/dWplmM47/Sz+3Y7zLiaMQ3tj1rGt4+hePGXdMxbWuKdOuCemXrhGtLayv8Yntn9vfqCfZvq3+GI7O9/Ys9BdvcYY"
DATA "452NCftIfxtXzVfst7WFerSxMQ5aHp7ndcaQztfsm2mY40lNdjyr61Krdm3ucUwrwwYDxneCc/9a3yV+I318v2SeI5uu7PKc7UHx"
DATA "Xeo3WHfFxhvpV+8r7bpcnL9RxlUbmTfrynRqif6f6dH0TJ0xhjlfmYayjBkPjcW838t1X7Iwr+/y8PMQK8tYkGnWvxk3Z6ywMvfG"
DATA "pcyYZ+Nu49jxjHFn3CCruuusLOOCcYP+7a4xvXdao3V+s+eMuzHorunq6/yQuu3u7Rg7GWPPnX/mH5u77Dxjt+Mo455MZZwxjRq2"
DATA "1zn2ppHUane9xQVjaMY78w99w7QuPi2eZ7FkLLTrujVfl8f80fHPmMexNZ0YJ7N8aoO+tHPUnLGE9Xc+sRgw/u09c2f97fxk8WKf"
DATA "53XPuZCHrOOaf4MTsn+t7xK/kT64cZV+aWDTtdU+VxjJ/Lk/rbw3ysy6wMhbdWUbmTfqynT6pYtJjp/xi6yw8TRNUXMdY2Z6Nx0w"
DATA "Tm2e7ObUep+/Z/FAjVtf2K6OqzNekDWz+O9iif6djRv71/Xd2kuGZf86LVBLM92R+fQ9y7M2df6xWKAe8rUxyeKo0wVZxz53+k39"
DATA "cy1IPWTZZYt/t/VA/XTx2WmS+jWtUfvUwYypbBPZRU1S98Yru+9HvhrLGCMd+7u+dbFg/qR+O//Qz/RBxwxjYLaB9ds4mH5YRsco"
DATA "9r/Tpo1fx1yr2/o963Nel8yze8ndfsNYy9/dmFCX7Ce5xzTTc9lgwPhOcO5f67vEM31Yfs842VR2ea7Zv97KH4y8zhtl5rVVLs/f"
DATA "2ONetZF5s65M53hbLOW48HpqfE+vZtSdaaNjLLVv8WGfe3Ta3dOxxYvNFYw3i2n22fxn/bN2dL7cYw7L6fhm/SFLeJ7lHqIZG2/q"
DATA "4pR6qG3jOt+TK8lAY1P3nmNOtpo+bD2X702/xsoutp87/8g307dx0HRExpGbxlDGkF1n8ZdasHjlPMh2kYOdtvbaYTGUdaW/LDbN"
DATA "18Y41m1xz3pmnLYxsHHj+JAnNuZ83bWLeup8y/Z12qQ2Om3RdzY+Nv627jNG0h9k4YzTpkOrm7yzulmG6WQwYHwnOPev9V3iN9I3"
DATA "y+8ZJ5vKLvPZHjTKrfy5P628WWZeW+XyfJZRbWTerCvTqaXUGrVibKLG7Lxxk/k5LowlY6Lpgeu2ThNdvHY6T5YyNmwOMZ/atfTB"
DATA "Hjt4jmzgWFhbZmWyX0zL8qxf3Xh1LGObTGddH6zd1BK5wnbu6dfu9XWaSY10+w3mZf3UJuOou8fHtR/rJHPLN8+df9Ta3jzcsY0x"
DATA "YVwzDdp8m2lsU2rA4oBzc+qPbe+0YtfzcxGLSWq5i13GfccYlkMmcTwYQ5mPrLWyZ+c6XVjZ1k/2j0w0RlEb9p5+p4+MK+YT8rDK"
DATA "4GcOqSfOhcko1kGOkl3GR9M1NW3t6fY8NkcNBozvBOf+tb5L/MbnFZvl94yTTWXjnO1Bs9zKn/vTyptl5rVVLs/f2ONetZF5s65M"
DATA "N010scX5g9fbWsx0R91aeYwzlsOxtvsxpjnTkGm3K5P6YRwxrjue0KeMNdbZjQ39w/ZZXHfzjWnA2JjXsp82thxP4xnr7NrDecPq"
DATA "Zds6/+3NJdRCXme6oQ7ov+46to8aYExR913MZZr5abx/7vzbW/tRg3lt6qRjERlj6waLa9bDcjiHml469tm8PdOQcZV9Iru7PpID"
DATA "s/Zzvcl1Ed8bs4xFe2xi3q5ultf5ouOSsTvH3OY9nqMfqJ3OR7P35JVprZs3bewsJoyJ7KvtoTm3W1wYG+mD+j0YML4TnPvX+i7x"
DATA "TB+W3zNONpWNc7YHzXIrf+5PK2+WmddWuTyfZVQbmTfrynRqkzoyvVn8GsM4FmQO+UE9G586HZBLxjLuIWyN160ZySLeWzH98jzj"
DATA "sWuvvWbsd2ztGMkxtHjo2Gb5O35aG7q4N3ax3mSS6SbPsz2mU9OwaZ++Nx4aAzv9dPqgvrItXVxl2Xl+Fhemy8W/m/yjFqkV6pZc"
DATA "MR9Tt5bWxQ7Hntozvlp9XFPN9Mi87KOtz9g3azu5R82y/TOWG3fY5o4bHMdZjFoMzrhiXDLW5nXG4W48smzztfWPefZ+U1/UrLGR"
DATA "mrC1F8eROpydZ3yZpm1dmOfotyprMGB8Jzj3r/Vd4pk+LL9nnGwqG+dsD5rlVv7cn1beLDOvrXJ5PsuoNjJv1pXp1DY1ar+7MSUn"
DATA "Oq1wfGYsIcPMuGZK3TKWqaGuDrLV2pV178WJtavzI/PzPdlncZ99JVOMceRlx09jDevN62bzGteRnW/I2xnvrW30FevJtti8ynG2"
DATA "OdD0Td10+p/N6xwn5mHcUd+mmax/8e/23oQ8NL11fs8x5LxG3xsnjC/UVMe3TkszvrC9XbvZZ865xntjGcsyhnbnGGO2D03G2FqK"
DATA "64AuPjjmabM1F68x9hqvuRbs1oTknPWbbaOGu/ZTv2QWebSnG9MFdcy6smybEzptzuro5orxezBgfCc496/1XeKZPiy/Z5xsKhvn"
DATA "bA+a5Vb+3J9W3iwzr61yeT7LqDYyb9aV6VwrkH2pkY4N9tvGtptTjaHGVNMCY4F1zPRADpn+ZwykJqnHbLe1mfXPtG7ty9hn/CRT"
DATA "zE9dm1mvtcd4Y+f3mEwOdf3lPrZb+858SAZmeeQHx5dj3dXT6St9RO1bGSzLdGns7dpIP6Rfnzv/Ou2m5b0RjqPpppsDGXcc41mZ"
DATA "ppdOb6axWRnGyUPaxBgj76yOjrfWn66tZAPHzPaYHFvrE8edZeU1ZJDxiGWZxhiPM25bGWxTx0KW37Gvmw9SWzTTNeOl4xjr5Gvj"
DATA "IeufjWmet/liMGB8Jzj3r/Vd4pk+LL9nnGwqG+dsD5rlVv7cn1beLDOvrXJ5PsuoNjJv1pXpna5sz0EtW6x2vKNGyAWb31gmx7Or"
DATA "19plOtzjD+ujPrMu6tbq2vMRY6qLj1lfOVbdPtKYkunGIaaTNyzT9qqdjtheYxzr4nou83ftr3xZfjd29LHNefaaGjEdmQ46v3Qa"
DATA "oW4ZGxYznHueO/+4fqCm67WxwcZyNh/ZnGfjb2ObOrC5d8bFTpuH6MW0eWh/9urK6w6JMeNflt3dL+P+MV9bjHWsI2MtZq0dlo++"
DATA "Sx+SU2xftodruY6LbJu1h6/p92Qv0238bB6jXkwL7Kv5mXqwmOu0l74bDBjfCc79a32XeKYPy+8ZJ5vKxjnbg2a5lT/3p5U3y8xr"
DATA "q1yezzKqjcybdWX6IVplnJrPTTccY1sX8T3H1dpALfGctZk66/RGLZtOTYfd+ZkvujnA6jU/shyyZ8aRXPt0ben21h2HyB/GMOPf"
DATA "GM42ksXsG6+dtc/atafLzvdpM51auTbGpkeLDyvTzlP/3d7/ufOP8WA6oy/Jle58jrX9tnG268iSma7IDOrMrqVuLH/WZ9zo9Gf9"
DATA "tTq6eGNZ5u8uJtgnsqGum/XDyiSDeC192/nNxsXOV32dXti/rg3UOOuiP03vqU3jXaf9TrOsI8/PtGtjaPrN6zhXjdeDAeM7wbl/"
DATA "re8Sz/Rh+T3jZFPZOGd70Cy38uf+tPJmmXltlcvzWUa1kXmzrkzf0w19OtNLx0CbQ/Ncl0ZdURsdB2w+numC76k7q2d2PrVs/uoY"
DATA "lD7K15nW+aXec+7i+s3Gl/6xuOU9NfOdsYg+o7/ytXGB8Ut+cF3Hc9ZO2/dSN7MxNM4YsywO6Afyja9NM53eZnFJLZQPnjv/qIvU"
DATA "04x7Nn/ZXESNU9t5nrHI8evG2/THev/y3/7Hl+/H73pfaaaZ7j37T812/LB4YByZb61cmwPYnm4sO+bNxpOcMR5aHRwr9ivbSway"
DATA "PLunyfPkHe8Dduymn40dxj6OQcczps00T32YrmcxUpY6Z7+yrYMB4zvBuX+t7xLP9GH5PeNkU9k4Z3vQLLfy5/608maZeW2Vy/NZ"
DATA "RrWRebOuTLfxYEwyvnhuNu5749WxZxbf3ViSq11/kofUv2ltVrZplZyiL7pzFhOd7i2u2B67T5asmHHV2sO6yERyi/4z1rAfXTnH"
DATA "1JvXdHyxeYT8MW5Rlxwb1kV2Wlut37zO+Gm6yDk95/yOw8+dfxxLjoX5fe9a6sW0zjQyxvjHtE5vM60Y9xirFpNWV6f/jiXkmXG3"
DATA "K4P56Tf2o/NH8a9+M44PKa/7rMHqIgO6/ud42Pxivk+Wcx/cfQ7ScZCvuzZTI/QTdWB64jnrf/qHr00X433taWrtR/9ZfwYDxneC"
DATA "c/9a3yWe6cPye8bJprJxzvagWW7lz/1p5c0y89oql+ezjGoj82ZdmW7xTJZ1fs9xM93YGBljTAscs2zLjHHGta4McrBrT1fuTLNd"
DATA "n+kf+pFtMB7Mysn6bU9odXZjz7q6PXXXB2qlq8NYbaxLn9jettufJxPZNuOKvWfbTLPGGPLLYsDiidyiDru6ynL/a+2v/M+df6Y7"
DATA "m7eoQ2qXOqB2OEas1+LByqd2Lf7rd67/835f1cP7f8Y2i88ZjyxeOr7NWMO+mI+7Mo2tFf/5m7FAH3C8yCb6i+NtDGQ+WqdD833X"
DATA "J55PXlof2E7WRd/TTzYm1Krpxnho2s4004Ct+TKNvMy2DQaM7wTn/rW+SzzTh+X3jJNNZeOc7UGz3Mqf+9PKm2XmtVUuz2cZ1Ubm"
DATA "zboynRrm+DM++Np0v1dm5rOYtzzUCxmT1yb3yDOLP86b3f0SartjpOnWrp3F+oxBHRfS8vqybt874ynbyjJnjDJfzfxgbJqVTa5l"
DATA "WfbsFjlnHLNx6drY9bHjTadBG4uOiWwjP88zHWS7Wdbi3+37C52/jE1dDJmWOvakxo05Vg5ZkeyzdV231su1YZfX2mJ+sTZ1/SID"
DATA "9lhn9VhMdP4uJsyeBza2dWy2eti/Gcu6+uiHzkf5m/1inzoeZLr5wcZizy/WT17LsqgFctLYSvbZb/bP2nfJie//yq39a32XeKZf"
DATA "8iu/Dx1surbtnO1Bs9zKn/vTynujzKzrqlyezzKu28i8UVemU8uzODNOmeZt7upiKvMYK4yrjA8rlzHS3RdODiYPTXfsv2mafrG2"
DATA "MDaY/xA+MFbNlx2L+Z6/zc+MPxtre2966Nps7+nXrjz6lm3s+sixZB9nZTON42G+Juf4m2WYr6l/G6fUdeme/V38+8VbOurGvosT"
DATA "0zXjneNj9XQ8ZLld7CTDKp1rOrsnTP2Th2TVrJ15DZlscUH/dHFiZc1YZOnjd/c8IPMbH7q28hrqovPhnj+NtyyHHJzxkq/ZV+Nf"
DATA "x5xOw6ZP5s/28n3HRF6fTJvd22a6lXXJhh/+4Nb+tb5LPNMvz+X3oYNN1zbOyR40y73OH/vT67xZZl57Ve6t81HGdRuZN7ka6caY"
DATA "PTYwzmea7OKB+sr8Fssz1tR4G/dmDOR6kOWQC3vxZn7guRlPu7IZD+QHfdL5ls//7/GU51mHxS3r7jhpeppxxc6bT6gZtpd9mzGo"
DATA "G3fmz/2mxQzfUxumCfala78Z7+HU/WzG43j93PnHmLM4ZEx1cWxja1owtnXxYHFlsc3nPmdc65hIDXHvYL5g3w6JaZZDnpivOs6Q"
DATA "r4yLjoF8Hs5ikT608jsuZTrHyxhj7TVNsZwZg9k26po+N96wPGqF94y7z9zoP2v/rP+mc+qZ8WA6oj8GA8Z3gnP/Wt8lfiN9fL9k"
DATA "niObruzynO1B8V3qN1h3xcYb6VfvK+26XJy/UcZVG5k368p0mz8zjTFqejIeWRzONJt5TM+mi7qWn/fytXGR7aOmjWFdnyyu9+Kc"
DATA "sWpstP5afLI/5iPjhvmcY2jjlPFEsz4Z+2zcu7JYn7HRxoH67fze9ZvXzvYQqRvTXjd+5jf6uONvp/lsDzVHvz13/qVPqFnGPM91"
DATA "/GAc7+mbOjd9zjRpmuCcPPtsl/rt+pM6tHjqmG0xzzbM4sPis4vdLo5N+xwr5uc5csXedz4yXVjs01c25tSWtYOvjYedjy2vzYnW"
DATA "R67/7Fq2n5phemrY6uvue1MH1PH4fckJ2b/Wd4nfSB/cuEq/NLDp2mqfK4xk/tyfVt4bZWZdYOSturKNzBt1ZboxznQ103PHL+NB"
DATA "p22WTV3muOVr0yX3rtQd52nqKXloGjMN0w/mG8ZcNx8wzXxPP5BTxkzy2OK+Y/CMXR0zyEJqwXx4KNuoWRvnbm6wfmQ+tjfLtc8Z"
DATA "7DzLs3psvujMODe7Lush87Jvz51/1AY1z3mX2km/znhFvXaatljp4jzZlEyzPQnZRq6xvLzG8pqWTNcWo+Y7lmUxuzc23ZxifDNf"
DATA "k3+sM6+xuGb7svyOMza21i/zG8vuruvablo1zdn+IX9zDu4+e9sbp0xP3VHXVv5My7O+DgaM7wTn/rW+SzzTh+X3jJNNZZfnmv3r"
DATA "rfzByOu8UWZeW+Xy/I097lUbmTfrynTTsMVdF8ezmOj4wDjIsWceG7fUA5k445ixsotNW0NSTxYzbEc3B1hsd77s4tjWLx0byFUb"
DATA "dyuTcTrrC9ljsU0zXxhT6RubT1hOtpvjRQ6ablM7ZBL51LE99UNW2njkebKv0/Se5jlu2d7nzj/qquMSdd5dM9NxjnUXb13cpnZN"
DATA "f8a1TKcWmZf6IPd4njFkTDI22hqmYxB9anMDuWgxTQaw7m7Os7jmOHKsLM66MTU/mZY6brLsLp/528aFfjCNUTt2rWkyr+vmXdOn"
DATA "7TvISbKyayvnskv+bQwY3wnO/Wt9l/iN9M3ye8bJprLLfLYHjXIrf+5PK2+WmddWuTyfZVQbmTfrynTqnvqxuKZWujHLsbN4s1g2"
DATA "3mU9nbbILl5jLMw2Z37qyuZR+sq4aHHKPpr+uUbgdcZH8yPZmmXaeZaZ40pGGUPIX2NPx3j+pq/YJ/Mt6+Rv60OnP9ZHHSTPOv5R"
DATA "X2QgWWnnmWYM7DhKfhoDnzv/TLv0KWOZ+iM/GMPjNdcee3N4cq/y2ZqMbU4tsW+2h7A+2z6C7LV6jTfUXReD1oZ8Td/ZeNBfxqeZ"
DATA "cWw6fhv7OgbZdXmu4+KMuca9LLfzN/ub9c54a/Oo8Y9sJDfNj6bLWR67ruNvtz5IPw0GjO8E5/61vkv8xucVm+X3jJNNZeOc7UGz"
DATA "3Mqf+9PKm2XmtVUuz9/Y4161kXmzrky3eXoWG918w3jtxoX8pBa6mLZ1mK0z+ZrjbzrhOdNclkfdG3PYr0xn+6xeW6cytjkudp51"
DATA "W5zbGFt+4x7zdLy19Z2xiH4i89kHY/fMH9SVzSnGM2p1jzMWE9ROxz72savLYsLK5BhkO587/7p4oSYsRjj32fy1NybUPevMdR/r"
DATA "YF3ksrGa7SHHuzxWJ7nJOLM4tTSLG+rdxifjnGNo45VpVkZeR3aQDzaGbOdsfDnnJjvZxq4elpP1ZruzvK6OTKeuUzMcc5v3O53R"
DATA "P6YDxpbpsDufbbf2mw8GA8Z3gnP/Wt8lnunD8nvGyaaycc72oFlu5c/9aeXNMvPaKpfns4xqI/NmXZnO8UidWfxwnunigdro0rNs"
DATA "00qe45iSG9bGmUaSNaZn40mnxY6TbBO5ZtewTza/Gzcy9mdrUMZAcqU7b+Wz3I5Ps9cds8ilQ66xtrF/VtZsPE0npkOyjmWlvjuW"
DATA "zox65u/ZnFnvs7/lp8U/n/8tbjrfdrHbzYd7POtY2J03zXXsY90sy8on05jWMdj40bWJvKOfZnHSxURq3RjIuLE8XRr5Ya+NWWS2"
DATA "cZhl0GfdmtTWfGRHGttsvjNNdHOmxY+NZRcDHdc6TRrj+Jo64Rw4GDC+E5z71/ou8Uwflt8zTjaVjXO2B81yK3/uTytvlpnXVrk8"
DATA "n2VUG5k368r09KNpIHXCWKQ+bT6k5jp+UUuztNl76rXjz2z+Zj9NWyyT+Y1TbEtXFvvMvBYH9rriOo11Zf9sPUQdkDnUTfc628J2"
DATA "kWvUHcuhr2ztusdqtj/9YHN25++Oi7Qsi2PIGMl0ao/nupjJ89Rdjs9z55/tIyxOLGZt3iN3zO/d+sbG3Lhk85vNreQv67K2k9Ud"
DATA "s/e4addY7FhcWDuoc/M/Y994YunMT/6QpcaR7reVbXsNcpDt7NaLLIP12Hv2h+NLdlBHZB7nJhtvzomHaILa5Vw8iw/TNuedYYMB"
DATA "4zvBuX+t7xLP9GH5PeNkU9k4Z3vQLLfy5/608maZeW2Vy/NZRrWRebOuTKfmGU82FrM5r2MJmbf3nmyYnbPrOo1Z+6mTvWuMsTOt"
DATA "s12m+2w/yyEjycQZ/9gnxoIx2vhrHCIjySLTAttl9R2rSWMn+8j6O99z/DpdcyyNh51mjFHkV+f/PRZaXekX+ve5828vNnhutk6h"
DATA "hpg/89gY2hyZ56j7jjWpIWOL6fuQ9llbrJ1kgdVBbpNBXbxYXuOK+crW9+YX4yjXfVxbkXvcUxg3OhZY7DOGjWfU7GwtaG3p2tjp"
DATA "yrRh48gyO+2Ylrp6Z3qn5bjSZ4MB4zvBuX+t7xLP9GH5PeNkU9k4Z3vQLLfy5/608maZeW2Vy/NZRrWRebOuTE+d0EccT451xxUy"
DATA "keNpY0SGZpk2r5peuzKMo9mOTsOmcWsX37NsiyHzA+vsOG59yRgnK6r8bn1oviI7WAaZR85YfBsHTGc8RyZ2XKOWLR/bbeNvfLLx"
DATA "5djkWNjYcRzpE9MC67eYod9oHadH/xf/bscFtWHrI8aN8WOPA4wFK8fiI9tCXVKfXVuYRr6a9rLfzGflZ9s7/Vrc23VkHfufPLP9"
DATA "r42P+bnK7vjXcdB4yzaYz43tjHdbh2b7TbeVznjnPGFzEttiejf/GXtmfbf4memU7Zjx2Mq2uXEwYHwnOPev9V3imT4sv2ecbCob"
DATA "52wPmuVW/tyfVt4sM6+tcnk+y6g2Mm/Wlem23kudMS5t3ULd2nnTF7lnY0YtZV6O9+x6XsP6Zmw3LlmcGqfoA4t38rPTuvmV11os"
DATA "dntUG798z30l28d1lu11bSzNrzP/dv2wfjK+yTsbO+MINdb5yK7t2t/xck8bnebpU9Myr+X88Nz5R71yXrd4NA2SA3uMpNYsbqyu"
DATA "bu7sOFTn/8Y/+KfX14zXVVa+prFOaopctX7Rb6bJjp0WQx0fqW++zvFNljBuujaQh919NY65cWKmJ/b5kHZ0bbDrf/O//8tr+9EP"
DATA "ftXtt3+9tekxzne2lWv2G1s7Ovu1f/NzrWU/aG2/dvp2Uv8O6OtZ7NA2TI49H8z8N/P7bLxm43ynvt61fzv9MiYln+29ccjWVbM5"
DATA "gVyfraPIDVsX2N6UbLS2say8visn583cV9Jf3TqvmyON3eaLrg3W91MZcU723ZV/98G+3eNNMu+uLNw5HpKBd+LfHRl4Sr9snWr8"
DATA "YpqtW2w/krHPNY8xyPJYfeSxMcB4Rcaw/EPWklxPWt/Yz9l6k3MB/cF+WDrngEo7hRN35sMZ2Xdn/k1i4r65N+vnnt03B09ZKz3J"
DATA "NeAO/4xj5JLt6Xid7cP21m0d5+waY0eWz3UQmcfyrS3Zf+tT9o335qws86GtEWe+75jK/XC3NnxwTtyRCw+19rsz++6ReXdm4QOz"
DATA "4o2vAe/Spx2uH8KAjlkdx+x6qyP5YXxkfpZh68Fu7cY1X1eW9cU+P2G/unWfMZw8ToZav6sN7F/mt3Mj373w746ceLJrvxO5d9c1"
DATA "0mNjxTnXgOfm+l37VJ+H2PpqFuPGytk+jrHf8YeM6daa5MyMK9buWf+M2cZc65Nxkn0zvnX1s15+nsN7gPW66n5b+Xf2+34P2Ken"
DATA "yIoZA586/4wDZJqtt4x1XP8Zp7p1Wcej2bqR77vPSq0cY21yzbjU1c+5YOanbr3IOiydHC3mdbx/LKy46/roMe9979qns+4X78CK"
DATA "KS8eiH/n7tNdmT5iphjIuGbsMw5t7cUyurUU10HG344z3X4x02xd1LG8Wwt2TDZmdkzr+t+ZzT1WhrXf5qu1/lvrv3Ox4m1e/+Xz"
DATA "gskjxjfXTNzT2d6NbNhbK1qMGzONiZXOfWK9tvVT1x+uXW2NZ2u1bl1L3xi3O9ab32Z+r/fr/t8Z1oB36NO6//c0+FexkvtgW6PZ"
DATA "WqNbGyYnGc/dOohrQLKJ+Y1dbD/3v/Y8HXkyW2t160dy3NpujDLOk73Gv47htq5dn//e7x74GA4ea3t1Poa971P//Ldipz4HGb8t"
DATA "1pJtFrPGlI4vZKtx1PZ3e2V3a7BcBxrPmJ/cJsNszWfrvmy7MZXnWT7nA/LVxobXvA33yx7FGvBADp7KwkPK323jPXDiMd/7m/Zr"
DATA "h+mDd/wMuFtX8BrGqXGn4xTzd3zsONDxx1hWNvs7R/K4W/t1a9E9pu4xvFtTkof0lZWReZ/K/bKHXAPuMvBMHDy7ncC9u7Lv0az9"
DATA "Jv07pV+5/kvu5P3AjLGOiYzHbq3C9Y9ds7f2snYYq3iObc7zbNOMR+Qm28jymd98NCuvm1e6NuW5N7ZWOiP/7ouBJ68FH4KFh7Zh"
DATA "cuz54NzsezRrv0nfqg8VJ/wcJP+fBPLP1j+zdaPxLPOZdeu0GWNmzOjWl7ZWs3VWx1XzC1lNzpHBxnxbF858ZGvG3P8+9TXgG2Pg"
DATA "IX09Jw+PqeeA48mw7w2s/erzDzIw+bcX57ZGmvGhi3mLc1tf0jreWvl8zbx23q7lWo7XkJeH8LTrG/3a+YZtq2vPwYk7c+ExMfBc"
DATA "HNzr833bgccp3Hsq7Jv288C+5XqvLBnIWLX1G2PO1ocWm7buMgZ2DJtxreMO10zG8MzTMdvmgdkalH3q2mEcN7Z2cwPzn2uddGce"
DATA "PDADz8HBo1i41/8H4t2UBWfi3pNh3xH843rDYo3PR3NPR1Z1PCBXbD3Z7UMt7g9hBNeJZKRxxJhKHlofujJn/WBd5BfbZddZvd36"
DATA "721h4ENx8GgWPvBxaB/uk3tPlX25/ss4s7WgrU+MZ4esl7r9IO85dhzKumkzPnft5RqN9bFccqiro8trbLR1JH1Azlke+uVObHhE"
DATA "DDx1LXgQB49g4Zvm4THtPKTfh/jvrtx77Oyrzz/ys1/bDxsjO45xrUL2kXPJvqxrxoM9Fma93drL1nWzNasxxvhs88KMex1vzdfd"
DATA "GnQ2V9yZCw/MwPteCx7MwSNZeF9cvGsbDu3jqdw7ac33SNhX+19jWFk+G8j/K4H8sLVVcrL7v/dnf3uS+ZnWMYprKnIvWcF8Vrat"
DATA "BbO//N0x2a4xPnO+4Fxi/bN+Dbuvz02nx0zb97gWPJSDR7HwBB4+iB3Rj0N9cwr3TlrzPTD7av/LZ/9yPUbuGQdt7ZJxyX10t87p"
DATA "1mqzfSfXXd2aq+Ma17HkcFd2t/7qeGX9NWYzT8d2K4d1jbT7fHbkvhh4Dg7eGwvfJBPv0M5zMe9k7j1C9o0+2d6z1mT8LDiN67lM"
DATA "Iz9pdq3Fte2Hba1la0Susbj35vqNrCS/Ou7N2G3rYr7v1obGec4FrMfWqofy4F4Y+Eg4eAwL78zDR2LH9PNQ371J7t0n+4p/ZB7X"
DATA "eeRTtx60dR33vHnOyiNL2SbbW3d8NLZUfVaO8YzGc7b+s/52TGSfjH/Wl+4123sMB05Z75zEwb34OYCD98XCx8zEu/TjXMw7iHt7"
DATA "7DuFe2dgX/HPYjuZQ27Zeo5rOmMA15D2vHX3d3jGG67tjIXkC1ne7X/Jndk6i23jGrJb7zFft5a0vTv7Zdfl/vcsDNzh4EkMPCMH"
DATA "j2HhXXn4EHw8R7uO8cOhvj2Ze/e45juGfcOMd+QReWVrRPIt43uPiVwfGQPIixkbyD/yiM8zGlO69dtsjdftb7Pd9rrjsN3z47W2"
DATA "92edd4n5uzLwLBx8gyw8Fw/flB3b1wdl3htc83W+mcU114CZ3t0vTN6RpbaGsbVksrRbZxr7urWVcbHK4nrSuLS3BpyxK8/b59/G"
DATA "6Kx7tvazenhN5n/IteBDcvAYFt6Fh4+Njae0/xg/Her7N829Y9d8te4j88gecs3WbeSd7XF5PmM0udDdfzT+2jqtW1NxPcg6D2WN"
DATA "MbVbdyZXyXPrr+3rbQ1r/GRdbFueO/ta8KE4eE8sPJWHj92O9cVZmfeGuXcI+/gZrq3hbK1HhnXXce9rzOR5lk0ecg1o66ZkCrln"
DATA "bbL1H61jjHGWjLJ1rc0v2QZbb7KNxsXkHrk9ft9lbXPQPatTOXgPLLwLD58iF+/ax2P8eC7mnYN7d1nzJfu4HiGLjHXkpO1PuX5k"
DATA "fVZersdsPWocIY9sTcS1Gfm3x1/yhmspMorrR84th/ixY1/ylfOOrfVYho3nsQx8UA7eEwtP4eGbYuQ523usr87JvIfg3mzNR9aQ"
DATA "c1xfcX1iaz3jHMtjnbPymDZrJ9c1h/DL+Edmsk7+tnrJ527da9zt+m/7Yd73s89CrF7bs79pDt4LC+/Aw/vg4pu2u/rgKD+fi3n3"
DATA "yL2h8b/1ne9eWmqeDMr3tp4ii7ie4L26jptd7NuaqGMmjZ8B2GcC/AzC1qwsk+uubq1HvpKF5CH3u51f7DMUMtf6yzK7+5rJ3TfN"
DATA "wXtj4Qk8fOxsPEe/jvblOZl3j9yz2CsWMtZsnWWcY2wb4yzd1jezNWZ3j65bIxoTjAG2P+3mA3Lb1mGZRm5nn7o5gn40Btv6bs84"
DATA "h81ep1Ub7sLBN8bCu/DwTEx8cnYXPx1xPCTz9tZ7FUu19hvvi331nvHQ7d3IUq5vDon5TJutK1mnsbLjdq7PuE7r9obkjnE0y0o2"
DATA "kWm2huvamX6yMiqd69hqC9vBds/mOLaH43vKevBgDt4XC+/Kw7eFjaf2/cjjnMw7lXu5vkv+JPeKfZnO9chsHZYxa2sPW3fauW4d"
DATA "RnZanbZmSzbYfpix3q2VbF3JdePsPtuMNazDmN4x2fb3vAfIdSM5zHnIuJfXzDj4plh4Jx6eg4lvmpP30f47HMeM030zLz/PTb7l"
DATA "+o/pXA8O4zrEGMR1y8wY2zN2dWXbdbZuy352+8XkBPnOMtmeKt/2nlxf5fU2d9g60XhjPjOeWz/z2s7vszUf25lpp3Dwvlh4Zx7e"
DATA "Jxcfm51wHDsW52TejHs2V6eWcx2YrMs1IVlpbMhYsHUNz83We+QV45zlcd1iZRqPjBfMk6wx3ht7D2G3td36y/rpd16b++FknfHV"
DATA "zmX783c351BT7MuDsfAOPDyZiXk8Jo7dA9/yuIufjxnHU5nXrU24r03GMf7q+tS47ZkZJ4zfjK9D1jPGhhl32JcuZo1hs2dEuC7j"
DATA "WijL6fjY+WivvG6NNbt25uP8bX015ls/ur5w3GyOmz23di8svCMPz87FJ3yc4r9jx+pU5tW9Pa59knHGC67xMl+XZusA8qx7z/i0"
DATA "9RXjmyw8lHEdf9lme06FcWwsIDP4mjwgs9kO5qHfuvNsX5ZnjDO+sn6WYUyjrzkWHN96fw4W3omHJzLxbWTjOfxxl3E4Zpzvwjzq"
DATA "kxzLmOH6sF7Xb2OkxXm3Zum41XEx48vSuni0dQk5azGZ9fPzAOMPmWgc6+YhY/Ih66puTujGYjY2Mx6SgfzNcjpudkxnnnOx8M48"
DATA "PBMTHxMr77M/d/XxsWM504XFZhfz+bu7l5frw0rjPrlbZxwauxaXmWaxPstPHsxi1DhGnvIzEHIj1zkzbtA/xsOOE1mH+X2PZ12/"
DATA "O99YXmsb28S+8zXbzr1HN3YzzT8oDx+IjY/WzuC3c/LO7ulR37M1B7lXaYyvTEtmUsP8PHgvzqn72VqCsU2uM0/HzS7+yY/Mn+x7"
DATA "Zx3rWMc61rGOdaxjHetYxzrWsY51rGMd61jHOtaxjnWsYx3rWMc61rGOdaxjHetYxzrWsY51rGMd61jHOtaxjnWsYx3rWMc61rGO"
DATA "daxjHetYxzrWsY51rGMd61jHOtaxjnWsYx3rWMc61rGOdaxjHetYxzrWsY51nP149cHLly9ffTB+vvzggw/ef//V+++//8Grl6+2"
DATA "f+P9q5cv399+vr+9/ODV+L0lvNxejyu3DO8fVdlbeCz/nXa8//rVq1fvvx4/X71+/Xq46YMPXg8vjtTXm+tefbD9/GB7+Xpz5Di1"
DATA "XTjebqe2n0dV9hYey3+nHR98OOL1w/Hz/Q8//HC46fXrDy8DdEv9cHPd+6+3n6+3lx9ujhyntgvH2+3U9vOoyt7CY/nvtOP1RyNe"
DATA "Pxo/P/joo4+Gmz788KPLAN1SP9pc98GH288Pt5cfbY4cp7YLx9vt1PbzqMrewmP577Tjw49HvH48fr7++OOPh5s++ujjywDdUj/e"
DATA "XPf6o+3nR9vLjzdHjlPbhePtdmr7eVRlb+Gx/Hfa8dEnI14/GT8//OSTT4abPv74k8sA3VI/2Vz34cfbz4+3l59sjhyntgvH2+3U"
DATA "9vOoyt7CY/nvtOPjT0e8fjp+fvTpp58ON33yyaeXAbqlfrq57qNPtp+fbC8/3Rw5Tm0Xjrfbqe3nUZW9hcfy32nHJ5+NeP1s/Pz4"
DATA "s88+G2769NPPLgN0S/1sc93Hn24/P91efrY5cpzaLhxvt1Pbz6MqewuP5b/Tjk8/H/H6+fj5yeeffz7c9Nlnn18G6Jb6+ea6Tz7b"
DATA "fn62vfx8c+Q4tV043m6ntp9HVfYWHst/px2ffTHi9Yvx89MvvvhiuOnzz7+4DNAt9YvNdZ9+vv38fHv5xebIcWq7cLzdTm0/j6rs"
DATA "LTyW/047Pn8x4vXF+PnZixcvhpu++OLFZYBuqS821332xfbzi+3li82R49R24Xi7ndp+HlXZW3gs/512fPHuiNd3x8/P33333eGm"
DATA "Fy/evQzQLfXdzXWfv9h+vthevrs5cpzaLhxvt1Pbz6MqewuP5b/TjhfvjXh9b/z84r333htuevfd9y4DdEt9b3PdF+9uP9/dXr63"
DATA "OXKc2i4cb7dT28+jKnsLj+W/0453X454fTl+vtg+GR9ueu+9l5cBuqW+3Fz34r3t53vby5ebI8ep7cLxdju1/TyqsrfwWP477Xjv"
DATA "1YjXV+Pnu9sn48NNL1++ugzQLfXV5rp3X24/L5/n2Bw5Tm0Xjrfbqe3nUZW9hcfy32nHy/dHvL4/fr63fTI+3PTq1fuXAbqlvr+5"
DATA "7r1X28/L5zk2R45T24Xj7XZq+3lUZW/hsfx32rGeXzvtWP477VjPr512LP+ddqzn1047lv9OO9bza6cdy3+nHev5tdOO5b/TjvX8"
DATA "2mnH8t9px3p+7bRj+e+0Yz2/dtqx/HfasZ5fO+1Y/jvtWM+vnXYs/512rOfXTjuW/0471vNrpx3Lf6cd6/m1047lv9OO9fzaacfy"
DATA "32nHen7ttGP577RjPb922rH8d9qxnl877Vj+O+1Yz6+ddiz/nXas59dOO5b/TjvW82unHct/px3r+bXTjuW/0471/Nppx/Lfacd6"
DATA "fu20Y/nvtGM9v3basfx32rGeXzvtWP477VjPr512LP+ddqzn1047lv9OO9bza6cdy3+nHev5tdOO5+y/H/uxH/sDl8fv//L4fV8e"
DATA "X//y+L2Xx+/58vjal8eWYxxf5qpsyHed9dbx1QVXOaqAq/KuSr+q66rmG1lv5qtcR3X6rP676Qhx303/qfuu+nTtvsZ5N11YmSYO"
DATA "vOG/mw5ErqM6fX/+O1J+Lr5rT13lrKPzIKR0lAAfi//ME4fKz5x+y3k3XThzxZ4A1etHdfq+/Wfhe6j86L2bQjrEFSLA3QB+Yv47"
DATA "lJlXmY5yxZUDn4r/dl1h+DuSmUey7DAA3nT6UZ0+p/+W/t6A/xb/pv5b8+/R/lvrv7P4b+0/jvbf2v+exX8HC3DuwHQhfRhnrq8+"
DATA "3H3zKfuoTp/XfwdMBjMH3vZgutCOry6E9w53360p56hO36f/jnDgLQ+GCzsfxhXXueC9w933SPx3vAN7D6YLZ8dXGRrvHee+N+u/"
DATA "IxxICV57MFy458O48jr3dXlYbx/ovjfsv0Mc2EnwKw+mC92LNy/4KiO9B/Htu++N+W+6nitouQS/8mC4ED5sj8jxVTHwHsQ3c9+b"
DATA "898xDrzlQXfhjhNvXHnbefTeQe772lGdPqv/jttR3PJguPCmD/ePyPlVcTve63YrR3X6vP7bWRDDgbfurNx04YFOvJHjtvNubZUJ"
DATA "ULrvjfqvWRB3EozbAl/1/KYPWz/euipK+KpYeq8RXy63j+r0fTlwR4J7Lrztw/mRWSfO2xHfl8Uc1ef78yAkOPFg3pxKRxziRlwf"
DATA "JX1V/J73buz1jurvvTpw34PuQvrw0COLEOftee8xuO/KgZTg7M7KVz3FPdI7ei59J8675b2bNxqO6uv9HCrB6Z2V6LDdqj/QbfSd"
DATA "Oa/13uMQ39Ux96DfnMqONx94zI+bBUTJt533uL03jh0PNvf3brrgUDfeypVFivMev/fGccODcxfevL93yx3HHDdKihomznuU3htH"
DATA "48Hm/t6Nnh/vRmbPosV5j99747gxFzc3p7KjfqP5CK/dcp3eH+QtrqP69LAHPNjc37vR492PPPoD5WQV4rzH773Lo3fhzVtT6Pwx"
DATA "fryd9UbJUeNTc97lcbVaUxfy9t5tVxx5oLysis57Gt67PG65cOce6VEuU8e191afnvO+PG67ELelbjngAFc2eW4WnFU+Ued9edS+"
DATA "q/dh78bDjlulie/u1Xn/H7CF/L4="
DATA *
