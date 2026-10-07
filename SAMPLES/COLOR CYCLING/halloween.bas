' halloween.bas - palette color cycling
' Exported by DRAW 2.5.1 (https://github.com/grymmjack/DRAW) on 10-06-2026
' 320x200, 64 colors, 4 cycle range(s):
'   1: 22-33 PING 11.0/s
'   2: 34-45 FWD 6.0/s
'   3: 46-55 FWD 10.0/s
'   4: 56-63 FWD 8.0/s
' Keys: SPACE pause/resume, + / - speed, R restart, ESC quit
'
' How it works: the art is drawn from a 32-bit image, then an 8-bit overlay
' holding only the cycling pixels is drawn on top (overlay index 0 is clear).
' Each step the overlay's palette entries are rotated with _PALETTECOLOR -
' the pixels never change, only the colors they point at. Speeds use the
' DeluxePaint CRNG unit: 16384 = 60 steps per second.
' Compile: qb64pe -x halloween.bas

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
_TITLE "halloween.bas - color cycling (SPACE pause, +/- speed, ESC quit)"

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
DATA "eJztnTuTJUeVx69m+t3AgkYjJIRGCAmYlmANIGAN0BIrwAGHh7OyhLOBw2CAMQZfgC+AjSNHa+CsuSFnHdZYB5eINccjgsDawLmb"
DATA "p25n37x583FOviqz6n9m/t1161ZlZZ06+auTWY/+7rv/+u5zm+8898fNdzZvXb24ffr7D7e/+6//2f7Hs79u//uv/7f9379vt//y"
DATA "2S9vv/H857bPPvrj9vdPnm6v7p1tX7r85PbFi09sHz//aLt5/GR78s7vthc//Wj7qV/8efvab/+y/coH2+0L3//q9tGT97abR0+3"
DATA "pz/4w/bq6bPtGx/8bfutP223v3q23X6oyv61+v1t9flNNf9afX+mlrtRZX7j1Zvtd2++tv3x19/Zvv/uD7dPfvTe9jfv/3z7S/X7"
DATA "Z+rzT9T876nvv6mW22w227dV3W+U3rpUula6eqj06e1jNe/L9J2a/xwtp37fqO/fpmUulD5G6z1U6z/cnmxe3Ly+eW7zn9ebzb3N"
DATA "lsrdfH7zlc3HN/92RtO7Of+4+ebm5c2/X+3n/NPmnzdvbH57sZ9DnoQgCIIgCIIgCIIgCBpVNAI0Un2hfkSjiLkaaX8hCFqvSvAO"
DATA "PIQgaCS14B44CEFQT5qDe+AgBEFzqgfugYMQBLVUj9wDByEIqq1UHtHTJKkCAyFo3aKn0ObcfkvelebhnH6DIGhs9cK9HA6O5G8I"
DATA "gvpQj9xL5eBIfocgaF71zr0UDo7kfwjqVXOPx9XWaOwDA6FSwrO+61YN9tFbBTmiNxDaAgPbaenndQgKaS7uzcHBkY4LBK1Vrc7J"
DATA "pdiXyjwOA6UsXBIDkZtBUD31xL5WDBzp+EAQVEe57HOxi/6KiK3SDORyEAyESgvXSZah3H5vjHk+lWIg/eWmNfWDIQgqpxLsk3Av"
DATA "hYOxHDCXgb0dE+QWEFRfc7OvFAOJf0tjYI7ATwiKqwf2cRnIyQFzGDjScYMgKE+puV8N9pVgoOZfjIEYB4QgqDf2cRjI5V8qA0c6"
DATA "fhCUpk9XXr5/9Zj75eaAJfgHBkLLF/GMyzTJsuOoV/YhB4SgHD20frukmWZyTU/b85bHv5TcL/Uev7n5F2IgcsAxhGvZXBHzbPmW"
DATA "NdkWk3+bj63fIygn90vh39Pff9gl/5ADQsuQi3scDuazz9a8fuCpRd+XmOdTDgNpffAPgrQ47IvlgiR+X9fFvZE4WLvva7LO5JCU"
DATA "gTb3bHH5l9IH7vn4QdBOLrZx57lUhn09M7DF2J+LfTYDU/hnl1OTf2Ag1L98TPPNi/EvLBfbuPN6UQ77JPzzcUizS8K/UC7J5R9y"
DATA "QKhbXacuL+VZGf655nOXnVu1+RfK/aQ5YMn8D/wbV5vNpurys4t4xmWgZNnCkvJsifzjMjA3/3Nd98gZ/wP/xhXxjMs0ybLdSDPN"
DATA "5JqetufNyL9Ufbny8hK14l/u+J/v3peU67/g39jSTDO5pqfteUPyj2SyLaaR9kuJeMZlmmTZFLXkX87135L3/+ltg3/jymRbTKW3"
DATA "3ezvrlRgH/fe8Zr3mGummVzT0/a8EfgnZaD0/r9Sz/+Cf8vSHOybTQPney6ZbIupZj1a8c9moWT50rkf+Lc8LZJ5thbCPq252Ucq"
DATA "xb+U5+By2Qf+QaZS2Pe29bu6Lq3f0KSWzDNVkn+lGZjDPvAPiomYZ6vqNol5tmpvcyClsO/m1of6t1Sl+VeKgZzt5LAP/FuvXNwL"
DATA "cfBGWP7R8i7ugYPZIubZkpYh5R+xpTYDc9kH/kE+cdhnM5B4xmXg0bIc9oGBIrm4l8rBWvxL4aCk3FT2gX/rlYttnHmaaSbX9LQ9"
DATA "72A5F9u48yCnOOyTMDCFf1IGhliYUk6J3A/8W598Y3y+ea4ckKO7cnxM880D/4JysY07z6dU/qUyMEexZz0kuR/4tz5Jr2+4xgHZ"
DATA "7CNJeQb+BeVjmm9ebf61YiD3WV9J7gf+yYX3zu/lZR5Uz+fC80MO/3phYKl3XeXmfuAfZAvsW4Zy+VeTg6H3JqSyD7lfuq7unQ1V"
DATA "XwiKScq/EAOlHDSZZF/j4Lw3hsM+bu43Kv9ymCRdF/yDlqbS/ONy0OSbr08by/+k7AP/yq0LQUtQiTFAicz8LtSn9eWAnHdK+9hX"
DATA "c+wv9/pAKota8w/MhJamWjlgSJz8z1zO9x7BEuzrIferwb9YmSX5R/PBRmhEpeSAJRnIubdP0uct1e8dkX86D+WUV4pX4B40uubg"
DATA "n0Rc7o2Y+5FSGELvInatxy0rNWcz15GUAU5CvSo1ByTe9MK9kuwrzb8YJ0rlf5JycvmH68fQkpTCP83A0hyUci+FfXPkfj7mlOCf"
DATA "i4WmuHVJ3QdJXSGoN6XmgCYDTdXmXYh7Oexr0ffNydvs9bg8ci3bkmMtxyQhKEWlGVhbI7JPy2RRLv9S12udx+H6MdSzQlzojYE1"
DATA "2Nf6ugcpp+3nMkO67VxOlez7Q1AN5fCvBQN93OOwr5fcz6WU6wkl2CHlX8ltgX1Qj8plYA0O5nKvZ/aRUvhXaruS8UNJ2fZzMWZ/"
DATA "H+zLU7O/xb5C5faDSzIwxL1S7OuBf6Ta9+7llFcy3wT7oN5VioEpLCzFvJHYR5LkYi23XZJZYB80imLcKMHBGOtqcq8n9mlx7pUe"
DATA "lX/I/aDRVIOBLTQi+0hz8S9UNnI/aM0ajYGjsk+r9DMbOdvupe8LdkJzisOUuTnIreMI/nZxp1X/0b43u4e+L/gHzS0uX1pzUFKv"
DATA "kfxdg0OS7ZbO/ea6zxuCSknCmtoclNZlJD+TbA615EAN/rVcD4JqSsqeEjxM3eZIfrU1B/vsbc9Vzlz7XUu4Z3lZSuVRS43kT5/W"
DATA "zL+S+wOtVzXPPeBeXS2Bfy3WgaA5Be7V0cj8kz5fHFLt/YWgEgL3ymqJ/APjoKUL3CujUfmHnA6C9gLv0rQ0/rXeDwhas1rfd1C6"
DATA "jUu4Yb9zr9V2feuCeRC0LpVu83Pnf9Jtg3sQ1FYl855crZl/YB8EQaWfHZuDKZLtor8LQZBWSRb0zj+wD4IgrdI86Jl/YB8EQaZK"
DATA "3+/WK//AvoF0catRy4eGVS4He+Qf2DeYwD9oZqXmhD3xr1ROCzH1sVv5PnOl+VSaU7XKhRYrKQd74R/YN4MWzr+3r3fyfYaWKy4H"
DATA "e+Af2NdYmnMxccuzOeXjlT0/thz4B2Uqxpce+deyHqvUwvmnORdTcb9C3SqWb/XCv5Z1WI24vMvloY9buRLur4R/PT3bBdVV7/xr"
DATA "uf1VaeH84/IO+SBE6pF/LbfdWjdXDyc1L78U9+biIHP/wT8oRXMxcG15H/iXqMh2SnEPHFy3WvJojX1ezafSHPSWy+VW6eViyszz"
DATA "bLXi342aR0qtZ/Q4Vi4fCqtlHgj+gX+1rm/UWg78W75acGmt1ztsTvk4aM+PLcfmX6yO0uVS+adVKe+rtZzmU2lO1SoXSlNtPoF/"
DATA "ffDv6J6PwfnHXT61XPBvHarZDx6RfW8rppB8n6XycStXR9vK5VNMtcuPHZeZ+efjlT0/tlwv/Htus5k0avklVYNTc11nzhX451En"
DATA "/GtVfq/8e/tyJ99nrsC/vWqwajT2ac7FlFp+Ne6tRK35d3fcPNzKVXI9C/OvNKdqlVtbJRk4Yu4H/kHO49YJ/zTnYuKWB/4dqxS3"
DATA "RmAfl3e1eKgFzo2hXvK+Wvzz8cqeH1tu7fwbJfcD/yDRcWrMPy7vUnkI/rmVw68R2FeKe7U42Ju/oMhxK5znadXmn5aPW7ma41iU"
DATA "UM57EsC/dIF/Y2qufm7tPHCt/COlcKwk+5599Mfi+8TlVunlelQN/65dveV9c+WBLX1eU1KeuZbvqZ2Bf1BN1cr7ai+nBf4dStIP"
DATA "HrHfy12+dLkQ5NLc/PNp6ZwLicPAnPHCXEneYw7+QT1LyinpcuCfXKn863FfavMJ/INy1Cv/tNbEPVMhBs6Z+0kF/kE9K5dPtctf"
DATA "K/9IPs6NxD8I6lm982/NWiL78DcQIQjiCrkfBEFrFdgHQTKhj7EsgX8QBPWs2uccsA+CoLUK/IMgaK0C+yAIWqvAPwiC1irwD4Kg"
DATA "tQr8gyBojcK1DwiC1irwD4KgtQr8g6D+hedO6gj8g3JVo23i75lALQT+rUuPnrw36YXvf/VOI9UfgkoK/FuXwD8I2gv8W5dG5t9L"
DATA "l58cpq7QGAL/1qWR+Ee8i6nXukP9C++9Wp9G4B+He+AglCvwb33qnX8p7AMDoRSBf+katb1p/l389KPu+JfDPjAQkgr842uUtvfa"
DATA "b/8S1Kd+8WenQuv05GPwDyol8I+nntufyamvfLA9Eod/MWba687tYzCwvtbgR/CPFwe9tT+bWS7uSRjI5Z+9LvWh5/Qz+FdWa/Mp"
DATA "+BdWb23Qx6sc/knY52NgCQ6Cf/Nprb4F/8rERO1YCeVrMfa5GFiDf7kcBP/m0Vr9G2If+NcH/zjMqsU/X+7o6j9r9pnzWvsaDEwT"
DATA "+Af+lYqLUnESYo6075vCv1j/2ZcDuq6ttPI1+CfXmv0L/tWLjZwYiTEnhX0t+Oe7r4bDQPBvvBgfaT9dAv/qxEVOnHCuW9TmX2zd"
DATA "FP7FGAj+jRfnI+2nS+BfnbhIiRMOs+bkn68uEv6F7pcB/8aM8ZH21xb4Vzc2uDEi5dbI/PMxsAb/Xrz4BEu9x2LPMT7S/toC/+rG"
DATA "BidGOAxbGv9cDJyTf2tlYu3Y7l1gX93Y8MWIbmNcftXgn8mvOfin19G+6I1/a+BhjdgeRcj96seGGSOuNgX+jcO/JbIQ/AP/asZG"
DATA "qB1K2LVk/mkGjsS/pbBwbv7N6Ufwr35s+NqhlF0h/v362XZSSjmp/Pv2n3bbLMU/Ug3+PX7+EUtrZWFP/Gvtx7n4N0q8jMS/D//O"
DATA "Y2AJ/mn20TZz+WcycE7+lWZiz3FdOsZHza9L8q+2D+aIqVr8S+m7+vinuad51IJ/elskYmEp/tVgYA7/SvGwddy2jvEWbb+GP1P4"
DATA "13pfW/ukJv90OyrFP5N9pF8xGJjLP9qGmW9qDq6Bf0tk4Yj8K+XTGP/m3q+5fKTXqdEOU69d+Pjn0rdUTpbLP1fdiH2asfq3Zm8p"
DATA "/p2887sh+FeChTltN1clYzxn/0v5MUVr4l+Keuafzr1sHmn++fLAVP5RmSTNQDMP1NNr5V/JNlyTdbViPGd/a/kxphj7avJvDua7"
DATA "/t5jbJ3S7dDFmhT+2bmeZp/mnp5Xkn9vfPC3O9aZ29Ps0/NK8K8kA1vzr3ZcS/nWIsZH9GVp/vUeU0vhn93XtVlEnNKMoukS/KOy"
DATA "dbl6O2Y+aPeHwb/67beURvRxif1O5V8P8ZTik5H5Zy5v9nNNBprMI2k+2WOBEv6RdBlmuXra3K5mH02Df3Xbbkktwce1+NdDvJSS"
DATA "hH96nd74p1lj5mDEHc0lPU/zyeRVCv+unj47KNtkrD0eaHMY/KvXdkuoZIzn7P83Xr050HdvvubUj7/+jlPvv/tDp5786D2nfvP+"
DATA "zydx+PdLtfzPVFku/URt26Xvqbq69E21b6Zax5mLfy23T77J4Z+ZY2nWmDme2ffVfDL5ZbNPwj+SOW2y1uQw/dY5ILcfbP/dJM0/"
DATA "X/wsPV5qsi5VNfijZfOvFQe5/NMqzcEWsTR3PNv+KdH/1dwKXauQlMPpA/vkYllO3zfEP1Lt4zV3vNix42pfLr6F8gytG1WmS3Px"
DATA "R/NvrnpI+VeKgy1jyBXP1MZaxLPtH5MNOdzy8SqVf5tHT4vyL+UdgC7+kcz4qR0fvfCvVn+rVw62qIvP10sd+7N5wO3vkUrVwXWu"
DATA "8G17Lv6d/uAPU79WM7An/lHbnjOG5uBf6VxjBBb66lCqLjGfL4V9Zvv1tXtuX0+3y9KxnMK/EHNyOErc02N6+ncO/0yGleDf3PE0"
DATA "B/+oP+jqc43GQsk+x/jXsi4jymZBrO1z+We2zVKxPCf/7GU1/0y15p/NPvDv8NrASCxM3efYNnNZWPuYzSW7HUr452KGj39me82N"
DATA "5ZS+aw3+mXmfvk6s+8Ip7HOxLCf364l/rcaLSa7ro6OwMHWfudtL5WDtYzaHQkxL5Z8rR3S1Y24dXTEsZVeMO67vY/tv3s9iSt8n"
DATA "SL9b8C+U+7Xmn+9cGPO19JzI4Z/vPpHeOZi6z5JttcxLexSHaSX4p5cLteOUGPZdA/bVm96tV4J/HH5xxgVS+ed6LrgH/oXixhcv"
DATA "Lj/kjhW7Ymc0Bqbus3RbUga2iKMW4sZoK/7Rdyn3e3LZpecRA7W4vKrNP04+53o/ai/sM/chds5wxYvLFzpWpHWRxk+vDEw9FrX4"
DATA "15JNLeKVG6Ot+GczUMo/LmvMd82b73mWcpTDPm69fDyjulF9Nfvo85uqTx1jXyv++fyREi8xX9Z6XmJp/IPWxb9YDhhioE/ccmrw"
DATA "z3wHtJnz6TqbPvSxr8V139A5ISW2OL5cC/9648WSJIlR3e5y+Cd5n7Fuu9K4lfKPRHkUSedXZq5lvouUVJN/Zi5qv4tG+47qqdnH"
DATA "Ue3czxcLtflnMhDcg1L5x8npzDbpevcnh3/ms/uc9xn7+MeJXSkDda6l2WL//Q2bSzaf9LTdZn37aG/f9Iud45nT+jOXfbVzP1f8"
DATA "tOSfPU6cy77e2idUTzr2OPzTbc98J5SEf/a7TCT8o7YrPV+n8M9koM0f87f595Bc/WX7nX0mI30MtHNMHwepbinsq8G/GNu0XH8r"
DATA "gMM/zjtu9H6Wyvd6bKdQHXH5Z78H1HxHE4d/rnc6cd7l6eMft48iYaC5Xc0ZnQu6OKjZ5MoP7b8bZ/8dI5fMfre9LbNv3gv7SBz+"
DATA "6bhJ5R/nnf8pYyS++OmtjUL15Is9Mwbt97/b7yr29VfMNqCfhzDfL2q+253Dv5RxGb2PMQa6tuvK+VxcNBnouo5ij92F+GeO7+my"
DATA "zWkJ+2r3e0PnTpt/er8k/QUzh+bwj/azxLheb210bWo51srhn5n7aW6Z7/2k57pC/DOfAzPfa2z+PSEp/7j+MfnnY6BvuyaXbJnr"
DATA "m+OF9r00mo12f9ru19q805/1d1Lutcj9OPwzxwLsceMQ/+xzJKef4BojST1nQsvmHkm38Rj/Qn0U13LEQ26+JRn/I0n8Y7dVFwND"
DATA "23XlZ9eK48Qj33658jfzs8k1k6cm88zPLqZJ2VcrfmL8s3N98x3aIf6Z78E2y4idJ03+5VzDHYUXS9Jcz9SU5h/3XU8c/tntWeIf"
DATA "l49jfSh7u67vqO6uZ+b0Ppn9YhfT7P6sOU1sNZ9DCXGNwz39jr9a8RPin/3OfjP3p/iI8c9kpf03ULh9hJT7VkbhxZL51/K9EiGu"
DATA "2W3bNUZjL0u5nz53c/nnY42PfzkxK+Ef974Vc390fujK5WzRspp5ej1fPVx8k7KvZPyYfQff+dD0V+icGesvxM6V9v6De+Pyr/U7"
DATA "dUJcc/URY/yLccJehsO/GmNYHPbF+uYumfwz+WZ+PlPtXfORWw8X33ya+9xpH+dQzOh3Y4feCyaJkx7bNhTXnPxzxShN6+sePqb5"
DATA "8kRurmS2bfvaaItrmFzuSBkYKotTJrdvy2Vfj/yzx0soB8ztJ4B/42ou/rlyQFP2PWmhPq2Uf/ZzXb72XzOuQ4zK4V9KuaFlOezr"
DATA "ZexEwj/puTLkM/BvXM01/hfjH8m+B87HQzMmXXHteo4/dn9Hq/c1lWQgh30Scbg3R/z4uGXe3+PqM0jOl6ZPdZl6nHSOOFmiSv2t"
DATA "Oel2536fIoeBOv7sZ7DMZx98XHPxz/VsQ6ztt4yFEgxsxb4e4scXN/a9jvo+QEl/wXx+0LxfqIc4GVmSv+229HeKxc7lZpvW5177"
DATA "GX0zPs37eu3Ytp+ZiN3XO+c5PXSPiZR73Hv2OOzbPH7SVfyEzpv2exvs+8Pt9z2YMUjfmfdHhs6VyP1k7Ev9O5dLZ6HNQLtt62m6"
DATA "hmn3fV1sM2XmfLR+jA29xHQqu1z7ksM+4l6v8RM6b5r3e9sMNJ8btK+zuZ59DvmqB7a4FBt7b8EfV33mqkvvLAzlNr5+io5X+15e"
DATA "1z1vrnGb3s/n5vMyuTmcNN8bJX585017/MQeJ3Q9V23fJx7zWS9xYko6/lSTPz4ej8bClsfP168LjXuZ973p37F+oqvN9xC/nFiW"
DATA "soyjHuOHy0LfcfadM817IzXr9D2SOnZ858re+7y592SU5E+Mf6OwsPUxdLXrlLF/33cjsK9ELNN+zRU/rX0V4h8nXkY+T5oqdV2y"
DATA "BH/MesX41zML5zqWXAbm9AvnjtdRYlkaP3P5jBMzS4wVO2ZK3qORGj+6TrHt9c7BuY+pJK/jxvPc+5QSyyNxcG7fcXO7pcSKVu1n"
DATA "FiTxQ/Xhbgvncnlch87Vru962o+YeonhEtf+eowXMy6WwD2t2vfrSuJHuq1eGTjKsS8Zs3Plya2ePawdP6WOwyjx0oNaPrvKiZ8l"
DATA "8G+k45+jWteOerrXHPyrFzs148e1zRHiZ2T+jRJ7I8Tv2vg30rHPjZmS4+xLi58U9o0UA0uKY8RuPvtGOu4lYgbs44//gXt9avS4"
DATA "HcnXS9HSuBfb39TzpqSPO8JxX6JGPleP5OelxgzOmX5tYDAYDAaDwWAwGAwGg8FgMBgMBoPBYDAYDAaDwVZjr3mmYTx7be80YxIW"
DATA "sUfq32Svkddeo9CbpmAse0S2m1Ru03b75efUP1jAJu/defDIfWT8wtZnd+7TIWg23cl78GDAJrftf0x27D440Gc7p+1+aP9pm9y2"
DATA "/wGb7NWDadNnx/6bfu4nF2Uve6Zj9uregcakyz7nmV6Gvbx3mjEZt1fJa69SGE5TbHvdMz2qvUxee5lCb5rim3KbNslqr++dZkwO"
DATA "bMpt2kTr7R0oWut18trrFHrT1AIs0X1kUueRKbdpE63XsyU5j0zuPsOBorX6tgP3fUb989ln1b98W5bzLPsMmee7z5KFVmbagfs+"
DATA "r/4txibv3XrwFWM+TU/eK+TBvX2eTLRGx3bnPnLgK3sH0uSd+0o6cPLeYjw4ue3uxyvktVco9Ghqctv+Rxm7c98yHLgD3+7HFIB3"
DATA "Rl6j2bsfpfw3uW3/Y3gzzxsTAffuOzjxlvPf9HM/uTzbOa+SmT5bqP8OzsIwGAwGg8FgMBgMBoPBYDAYDAaDwWAwGAwGg8FgMBgM"
DATA "BoPBYDAYDLYY+9KXZPNhhwb/Sezx45329iVlx8u558JS/ffFL+60bnt8Z/t55Kmdr+innoL/XJbqvy/eGWszi7S972wf7rxlm7ku"
DATA "/Jfuv73vlu3Dm5vQ/GPvhT24Xx/+o5+p/jv23lI9eKPMN3fvLdeUtmPuhfz3hS84q+Gd37vV8N/eW8dTS/TfzoP0U0/t/aeXM6cO"
DATA "/XfcZwv7z+Up99wRrJb/9tOHc8f231tv7WTazlu20Te2n7T55muL+W/nK/qpp+L+e+MN2fw61sp//vk8/7355k5768F/b93Z4Xy3"
DATA "99It5D/tLdsOl3T5z+Up99xa1sp/YYv7780728+b239737l9aJ5Jals8+tz+2/mKfuop+M/23953hz6c13/H3nN7kF1gAXNFnt9/"
DATA "2lu2xbdTwkbx37H37Aicw397b7mm5jNO9IUjMLKBQjaK//beck3N67/9tGtuHxbz385aem5nI/lvP+2aSzaH/2Tz5zKe/1r3eUfy"
DATA "H29+a/+NYlz/wWAwGAwGg8FgMBgMBoPBYDAYDAaDwWAwGAwGg8FgMBgMBoPBYDAYrI5dXAS+vAx9CSO7OPf76PLi3PsdbLLzi4CP"
DATA "Ls7PL/2rwib3XZz5HHimYvMcERiy88lOnd+dnZ2fKf/GilizXSgPnSn/uYLs9PTsTEXgGRzoNQq9M+W90zPHlyfnKgBPz/zNe/VG"
DATA "TZdcdHJ2dnL05enJ2emZikFqw8zy1maq5SoHKuednJ7aCDw9VXNPlGeV+1zRCVPnBxVg5yfqxwn56uC7+2q2ciwxkDzML7S2fULZ"
DATA "P0z2yck+Ndnzkz14cLfYCw8ne3GyT0/2kjLBho7sReuzCqxz1UCp+Z6cKn8dfHn/5ET9V65VHj69ODqH7Orj31YBc/rnwQPyn9+D"
DATA "d2u/8ILTg4LtHxqVI1ohbFN1RGsc2m6/dFEUGS+99PHJwv558CC8xN0GlP+OPciv33F9Hz7kLfkcbzFVH96CLnO3LZ4HvYuIaiC1"
DATA "6VBwFrx3n+XArFh2hQbbhbsFjhcR1SCtyozl7t9X2GMsl2UPpsYlcaGxsvZfYJFaVWYsd5+MsVxeZZQJXHi4sv7SdiF76+lVji+m"
DATA "ou/0/r3aDpzOo3wXHq68/+7Qg+ytJ9lU4ehSKmdRdmqlMsXtNhPhevBwZeOrQJRWqbA5Sz6sV64XrFM5pgMPVza/Mh3I3rrMDnJP"
DATA "84vLS4kLy42jmvXhOfBwfbf/2JvPqq85Xw3Nh0aeTbu4PD+/uGIt6jN3XyLFf63toL7mF5dq5Jkssr4agFbBl30dKd1/os0k2VFL"
DATA "PHCKWduDpa6uLs9VaKkhUl8YqhClIZqLi6v8EaxuvacuYVjjI6q7b+zvQXUPl7uarm+Ql8hP9jipKoUCT/2/KAE/h/tE61eziws1"
DATA "CGV8piETM17MY22teUX+Uf/UNaSpLdNgn3Lk7lsKzJ0HRew7PApGRY5jL1xQI6MRUDXQdPd5GnQyhzwPGsrhupdXV5P/Ls/pFEH/"
DATA "VMzp4FWtm75SzTxSg8PqWG1h787jhhspqonR+DsNFd/NuK/GjGnY/W7GAWWstafgm7yoHDidUQh3+juKT/U/XAHLDi/YqYDefzii"
DATA "Xry0PAug9W4ZFX6nNPp57/az6oGpUWPzitoBoo+2ofLAyUOKhZTSXJ5Tm6ZWS767Ur8C9XOYQoBBYzqQ+09HpwxmmYkWOjG519A+"
DATA "tMwox/X15fWtj6Z4U1JeUz5VzlM6LixYHwp9NaB9+0mNYKsZd0fy6ITrrG0pk3RqduYZejLK8WzqtoWqVjw5jdqs+n/tarnhHJcG"
DATA "+1X46wGI+8qVdAHl9qOdrXhqU8jCoxKuNe6dePzHrOz1LuTIrq/vovLA+EfT1RYaek/vNm9Qp4wp/ym/KX3Mc8oVHM77z1UfRowY"
DATA "y3+Bu3vK37giaQ4n9z0wbmaRcdnbpShJc6xMvS7GNmQVEuJkZmOOylICd+jDqcefOV7irE50jFPlPY41z2X9F6YdX5ozvxUMa1MH"
DATA "S3Ufdl6b9mLqNnDrwTPmIDGljgd3e9D9b8IEnGGBy8MJw9qXV9TRV/VUWS99ps5E2SPOH6Sj0QbKw2nsQX08U3lk6UO5u4WjgAv3"
DATA "BV5T3E1uU6aC71pQmbjx6nO7sMq9yYGqN0j+m7rPkm3R5cnoHRrxmxREVb61KeWdkjd2ZXcVDn7Nr89dPSjeiCGqJqpOwdJtY1w/"
DATA "n6oc9bJ/zMlvKnu7kkee61DcGqs+exeac1UaeXV5fS2tjp1kOPyjljIvfDBcKKqB2I7yonB9RGWLjXEXh1rq7soRz4WiGtSoslkf"
DATA "UdkJlXGlugf18d+B4POgqAZJVRZ4UFS22Bi3EnlvQJjnkMcr7LlBsYox7sUyv+I5UFQD28KR7O8e+urD3W6SBbqrd/UR+09UgwNL"
DATA "Ts3r+M+XYUxfsusj9J+kgsz65vhPVIHDygQyNEl9DtwnqoK4xsXdJ9q+VZlC7iP/tfCe83p1sLaiwqWW4j297uHRNBquYPsJJjzU"
DATA "orJTKlPoYP4/Sc4OqQ=="
DATA *
