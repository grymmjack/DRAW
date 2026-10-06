' pinwheel.bas - palette color cycling
' Exported by DRAW 2.5.1 (https://github.com/grymmjack/DRAW) on 10-06-2026
' 320x200, 34 colors, 2 cycle range(s):
'   1: 6-29 FWD 12.0/s
'   2: 30-33 FWD 3.0/s
' Keys: SPACE pause/resume, + / - speed, R restart, ESC quit
'
' How it works: the art is drawn from a 32-bit image, then an 8-bit overlay
' holding only the cycling pixels is drawn on top (overlay index 0 is clear).
' Each step the overlay's palette entries are rotated with _PALETTECOLOR -
' the pixels never change, only the colors they point at. Speeds use the
' DeluxePaint CRNG unit: 16384 = 60 steps per second.
' Compile: qb64pe -x pinwheel.bas

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
_TITLE "pinwheel.bas - color cycling (SPACE pause, +/- speed, ESC quit)"

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
DATA "eJztnTuSLMUVQBsJ9AUk4OmBfi8kWWPgyZCDoQgUYg2wCdy3Ae1AgYPztsAucBTsAPOtAL9VNdNNV1VnVuXN772Z50YcDGJed9WZ"
DATA "rDNZPTM9//r080/fOP3zjW9Pfzt99Pbb54dnz87/ePHi/O+Hh/Pr16/Pr7766nw6nc+nTyf+M/HtxPmHiW8mvpz4+Px8+u/nE19P"
DATA "fD9x/n7i64nPJ57P//jjiS8nvpn44fzd9L/+O/HFxF8m5nn18uX5i08+OX82Pe9PTj87/fn0xul/b5+mmf7JNC9Ofz39/vT3n97+"
DATA "z3ykAAAAAAAAAEvmO0tLxwsAAAAAAAAAAAAAAAD6mMfS8QLAOPA9cQAAAAAdzL8BZ+l4+VzZOmYX829uxjL/xqeEUR0DQHtSWper"
DATA "galNBAA4okTrSjWQJoIV5nersXS8IzG/E9EWqw18fCelCUv+AaTQ0zRczfNhqYHX/i2x9HkBgDJImle7g6UbSAvBKvxcdBqp3bO4"
DATA "F9xrIB0E6JuczavZwVr9o4UA/VG6ezU62KKBPXeQ39sqC/en7andvV4byH4QwA4tu1e6g636RwcB9KOpfTQQAGow//VUHz12sGX/"
DATA "rn+Z1tL6AOiRve5pbGI3DZz/MvcFS+sFoBdi29e6hT3tAWkgQF1yda9lC3vbA9JBgPKUbF/tFmpoYO7+0UCAMtRsX60O0kAA2KNV"
DATA "9yx1UFv/6CBAOlraV6ODJht40D8aOAb8PmF+NLavZAd73QPSQAAZ2ttXqoO97gFpoB7Yq+nFUvd6a2Dp/tFBAD+Wele6gz33jwYC"
DATA "rLHUOBpIAwFysWzH6fxxNDTQVv9oIIxOSu8stNHaHrB2/86f00AYk1rta93DIfaACf2jgTAaLdvXooWWGtiifzQQRkFT+2q2sOv+"
DATA "0UCAIDT3r3QLazeQ/oFGPnt4MHW8ubDSvpId7LaBGfpHA6FXLDWvdAfpn79/NBB6w1LnanWwVgMt9o8GQi9YapuFBtbYA2roHw2E"
DATA "HrDUtdod1LoHpH8A6VhqmaUGqrwHLtA/GghWsdSw1h0s3UDL/aOBYA1L3bLaQHX3wAX7V6uBo/5cGuQlviFfFkJ/A+lf+/7VgPdf"
DATA "7pv2rWvfRI0NtN6/kAa+evnSxDUCfaK7d3VbWKOBo/WP1wJBM7aaV76F9I/+wRjYbl65DlptoNb+0UDQiK221e0g/cvXPvqnD+n3"
DATA "zXv7HpCtnrXpYKkGjti/83MaCDqw1bC2HaR/+fpHA0EDttrVvoMtG0j/APJhq1c6Gkj/8vWPBkJLbLXKXgPpH/0DndhqlL4O5mzg"
DATA "UP1btI8GQivq9+WbDOhpYFf9a7T3o3/QAhuta9XEvA2kf8f9672BvGeCLmz3rkYL6+4Bc/fPymt/7AGhBX01r1QL6+0B6R/9czGP"
DATA "peO1QN/Ny91BXffAavqXuX00MI5/vHjRJfP7oJV67HG6l6uD6Q1U3T8Fe78rpdY8wMyY3cvRwfb96/l7HzQQajB291I6mLYH5N43"
DATA "rH30D0pC98o1MGUPyL0v/YOy0L0cHaR/pftHA6EEdC9HA8vcA+fqn/V7X/oHpdDdvh8i0dXAUv0bae9H/+KYf8fE0vHWRFf3YltX"
DATA "q4n0r3X/aCDkpG37SveuRAvjGtiyfz21j/5BTsZqXq4W5t0DxvZvxL0f/YNcjN281A7m2wOy9xNy+tjUdQY6oXupHaR/9A+sQvdS"
DATA "OyjbA+bs38jto3+QA7pXsoFh/WPvR/+gDbQvVwfr9m/Y9tG/rIz8c4Hddu/b6fK4Uq2Bg/Uvtn2Z9n40EFIx271l31Kp3MDQ/rH3"
DATA "o38QR+j7o5ppX87eZWthaAPr909t+zLv/egfpKC6fbWal9TC9P413fsZbx/9gxTUda9186I6eNTAfP3jvpf+QR5UtU9j90QdzNc/"
DATA "7nvD20cDIRYV7bPQveAOht0Dl9r7dds++gcFaNo+S70LbmDYHjBm70f76B/kZaj2/SeQ5A7u94/25W8f/avLPJaO10f19mnqnITo"
DATA "Bqb3z3T76F+X9N8/Y3u+Es2TtvBwD7juH+3L1z76BzFU6V8PzQvt4OWcX331lRdX/6TtE3VvgPbRP4jBZPtad2+ng3vd21KlfTHd"
DATA "09A++gcVMNU+bd3bIGnfFXV7PqPto38Qg4n2lW7Xp5Ec9O/169d37PWv+Z7PcPvoH8QwZPtie7dDSPt8Deyie43bR/8ghqzt09y9"
DATA "As3z9W+vfa4GNrvP7ah99A9i6L59JXo3X6obUvsnbp6W7ilp37Z/vfx8GpRFXf+0dc/Rutz9q9Y7jd3L1D72fxCDmvZp6V5g75b8"
DATA "pUT/crWuRPdyto/+QUO6aV/l7s3NW5LUvxKtK9U9pe07n740dd2BDoZvX0LzfP2Tfv/XRPPUdu+pfVb6x+uSujDdPgXd+2JBzM//"
DATA "3TVGU+8MtY/9n35C/x5RTYZrn6B7kva5+hdC8W5p6l7B9tE/iIH2pXdv5r8XRO1bdqH37hVuH/2DGKr3r0X7BN1Lad/Mdxd2u3e9"
DATA "hl2N6LF7FdpH/yAG2hfWvZD2Lft3Pv1w4ZsLy2t1cS37etFD87J3j/5BXmhf/va5+7ds4OZ6PmqIteYVa5+7e/QPYjHRP4XtS+tf"
DATA "RANjm1ijcw33fPQPUqB9Jdu31z9HA2M6qI1G7aN/EAPtS29feP8O9oCWG1ike+Hty90/fk55DIr2r8P2He397vsXsQe01MFi3ZO1"
DATA "j/0fxKJu79e4fSl7P3n/DhqotYNFu0f7oB4j7f1S2penf5EN1NDB4s2Td4/+QSrc9+ZrX3z/AhtYu4VVmpfWvlb9++zhQc01DPFw"
DATA "31u7f5kaWKKFVXuXp33s/yAFs3u/xu0L71+FBob2sVrP6nSP/kEO2Ptp6l+BBnbaPdoHOWi691PevnL9O2pgrx3M1z5r/eM1Q53Q"
DATA "vzztk/dvpAbm7R77P8gF7Svdv5Q9oPUOluke/YNc0L+W/ZM00FIHy3aP/kFORmxf7L1vXP9yNlBrB+s0j/ZBbtj75elf/B4wpoEa"
DATA "Wli3eU88+bJ0fYFu2PvV6F/JBtZqYYve3beP/kFu6J+G/uVoYK4mtm6du3u0D0qgtn+C9uW69y3Xv1YNtMy9H0vXFdiAvV+e/uXZ"
DATA "A9LAPTeWriuwA/2r0T9JA0fs4L4PS9cT2GKEe98c/Uu/B6aB0u7RPyjNCHu/1O99tNkD9txBmQNL1xPYg3vfWv2LbWAvHZSft6Xr"
DATA "SAP/fngAIdz75ulf+QZa7WD8+Vq6jsAu1vZ+ufuX+vqfrH+pDbTQwdTzo31QD/qXp391G6ithbnOp2z/5vfl03b9QVtG/t5Hm3vg"
DATA "3A1s0cLcx87+D9pB/1rsAUs0sEQTSx8j7YO2ZOufontfG/2r0UBbWLpuoB96e+0vd//KNpAO0j5oCf3L1z8aSP/AHvSvdf/GbaCl"
DATA "6wT6ZNT+6WvgeB0MXaNffPKJ+usI7EL/8vUvvYFjdNDS9QH9Q/+0NbDfDlq6LmAMqrVvkP7la2BPHXw6H0vXBYxDD/3rt4FWO7g+"
DATA "B0vXA4wF/cvfv/wNtNBC/3Fbuh5gPOifpQZqaWHYcVq6DmBcRupfPw2s1cS447G0/mFs6F+Z/tVvoB4srX8Ay/0rfQ9MA2kf9M8o"
DATA "/WvRwFE6aGm9A2zR0L+YBtboHw2kfRCOxd9jHKV/rfaAPXfQ0joH8GGxf5b2gD020NL6BjhihP5paGAPHbS0rgFCoX/1Gmi1g5bW"
DATA "M4CUVv0btYGWOmhpHQPEMEL/NDbQQguP1g7vYwo90Ps9cGr/SjdQYwstrV+AVKz0r/cGamihpXULkIve74GtNbBFDy2tV+A1iNxY"
DATA "6F/LPWDrDuZu4/JxLK1TgFL03L9eG5iKpfUJUBoaOE4DLa1LgFr03L+cDbTcQUvrEaAFWvtHA+keQA1K9q+nBlrooKV1B6AF9oD2"
DATA "O2hpvQFogz2g3Q5aWmcAmumtfz130NK6ArACDdTfQUvryTqvXr40dbyQjqb+WWpgjRZaWkejMo+l4wU3ufo3YgNzt9DSugHohd72"
DATA "gC0amNpCS+sFoEd62gO2bKCkiZbWB8AItOxf7gZq6uASS+sBYDRoIO0DGJ1W/SvRwNYdtPR5B4AbNJDuAYxOLw2s0UFLn1cAkGG9"
DATA "fyU6aOnzBwDp1Ghg6Q7SPQBIxXIDpR209HkBgLqU6F+NBu610JJ/ANCB1QbOWPIMADbQ2EBL/gCgL2o20JIXAAAAAAAAAAAAAADI"
DATA "x2eGjhUAwAr83S0AAAAA6BleSwAAgFyU/prCazRQAtYV9MKJYRgN80fRRzMMwzBMhfm96KPHHb6IM+XnT6KPrvxUv17P24tJe+D+"
DATA "Z6PuXuBWInMdpzq3QEMS/yD66Oj51Twyge+8I3oGRZPb6aO8pxEIfGce0fN0OQt5ewZ9Ao0pzL2L3toTLcGLwGEXoUPejkG/vzEV"
DATA "+ux5De4KjDRY6m6r+N3unr04gSOtwQN7PoP7/sYxGKAPgd755dNEGTzw9867oiOxOBd7QRLlAt99t3ODa31HCiMWYNcC7+0dKIxZ"
DATA "gP0a9OjbU3go0OWvU4E7+vwGEXiZfXsCgyH++jN4rM9rUCTw6q+dwCL3hEH6PAbjFmBXKzBUn9tg3AKsILDSN3sF9mIE+vz1sgRF"
DATA "9twGI/11IVCkDoHbmXT8Yj0ZBAb7My9w4y5Yo2QB7vn7jeho1Y1f35HD6AW48Wda4IG+XYUCgbv+DAsM0LejMNJfRwID/fkU7gm0"
DATA "4S/tZ8TC9XkMxgm882d0AYr0uQ1m8mdSoMidz6BfoMifQYEicYECvQvw0J89gSJvfoNhC7A/fyJpwQKDLmCnP2MCRcr2DfoECv2Z"
DATA "EijyJREYcgF7/PkF6vtJ/rWPnzsnWGBxf95p9ctER+oOJQYJlPr7UWClH4qPnkB3ewq9AlP8WUmgQJ5X4cD+hPI8BmUCw/zZECgS"
DATA "5zeYx99KXxV/y6/mMV+ARNb2DLoFJvn7rehMmoxI2b7BAv70CxQJOzB4ILBHfyJbRwIL+NMuUCRLIHAQfyJVAQYdAhP8TfqUC9zz"
DATA "8rPtBAiM8Le//HT7C1a3L9ElMJu/WIE1XkwQuvMq3FuALn/h+dO9ACPkuRXuLEAd/or8hmWkPJfBkAv42J9Ln4YF6HkFLd7evcE7"
DATA "gYH+Dpef3gs4yd6dwUN/kV8+9ApMtLcxuF2A2S5f9f5Exo4FbhZg8uWr1V8Ge2uDxfzpFJjF3lKg+wK+9ye9fBX7C9Dz1mpCBLr9"
DATA "JSy/vP4y3ZgE2Fur80ss7k/jAjzQ53PnVLgWeOAvQp9Gfwny7hW6FuDaX9LyU+gvUd7WoGMBZlx+v31PdG41Jt3e2iD+5PaWBpcL"
DATA "0OEvUZ8NfyJxboE3f1mXnwl/Im33Bvf8pekr4S9xFxhn78033/QLTPG31ne//NQtQJm9ydt29gTe/OVafkr83V5HDdfncHev8CZw"
DATA "11+YPtfy073+IuRtFN75O1h+Un2a/cXKWxm8CnT4y3D1avMXoC/I3sKgw1++q1ebwEN9wfZuBm8XsHv5xenT7i/d3lXgbQGull8m"
DATA "fUr9yfX99MfZGrz6K6KvpD/5N9f39AWYW8xa4J0/oT5b/iSLzylvqfC6AGd/BfRpvH6D7e3Iuxl8663Lgz/6W+pb2IvWp9BfqL4j"
DATA "exeDi4f36lvZO9Sn21+gvhB786weP2TxyfSp8xemz2frJ6tx+TtafEJ92vwl6Fu7u8zmCcT2jvQp8xdtzynP7c9/5Ubo0+UvVp9T"
DATA "3RvzbJ5g7y0iHPaO9c3+9PxRyhB/IfYe1bn8+d0F2bvXp3z9Rdi7uZvmo80TeNQ57Tn0WfN3rG/P3kfTbJ7Aqc5tL0zf+8HnVmNS"
DATA "9W3kBfpzyQuz99774f5qVFKo79Dehx9+uHr8WUyAO4G+ausv6N0qUvRtr9wnfff+QsZhz6NP7/Ubr29h78PnzxcPP1mItefTZ8ff"
DATA "rj7P4pv0Pf/d7y4P/t57jyKi7Hn1qfUXq+9i70d9k79nzz74YDrT6ZSfXIjluewp95dR36O/SeB8zlchEnlufU/2rPoL0rfxtxK4"
DATA "lug1d7D41PrLq+/i71HgymDI7OvT6S+bvpu/6wIUCnTaW+hz+Wv3eoLHX5S+6/Kb/a0WoMCg295Sn671dxG4v/yO9G2W39LfVWCY"
DATA "QY89xfrc/sKW30bfnb+1wEODPnkrezr9Zbt6H/Wt/d0E7in0ytvq2/dX/x09s129Dn/3Ap0Kd9zd69O4/sKX35G+mz+vwJvHfW9u"
DATA "e+r8TQIzLj+3P6fAOHvq9N37i9Pn9ncVGGfQoU/ir04MM/lb6Fv6SxDosqdx/WVffk/+NgtQatBtbzx/C4ECgz57Cv2dkvStL9+V"
DATA "P4fAMIN+eRr1pflbL7+Lv/UCXAk8VLgn7/0PPhCdWZ3Jsfyc/jwC/Qp33T3q0+hvJbCIvzuB9xKP1D3ZU6kv0N9C3/3l6/a3L1A4"
DATA "j48jOq9ak2H5bfzdLcBkgZeHEZ1XtSnmbyEwyeD1MURnVW+iL987f9sLOIvA20OIzqreRC+/7ZeP3QUYaXD5AKKzqji5Lt97f2uB"
DATA "coOrfy06p5qT7fL90Z9PoMzg5t+KzqnqSJafy9+2fwt/W4HBBrf/TrG+Av52BIYovP83Pn8q/ohZ4peP3QvYJXBXoevDla+/J4FZ"
DATA "/R0JdEr0faB2fQ5/AZdvsD+vQMmIzqf6xOTP5c8jMN2g6GzqTwF/eQWKzqbBlPaXKFB0Li0mzV+IwCSDtwNt9cdBj6aAv63AeIOi"
DATA "M2k0mfztCow0KDqPVuPXF+/vXmCEwWfPROfRbMT+4gTKDM7/QHQW7aaIP5fAYIWXjxadRcPJ5C9E4LHC20eKzqHpJPiTC/RLXH+M"
DATA "6AzaThl/ewIDRnQGjUfoz3cB5xQoOv7mE+9vV2C8QdHRK5hDf0EXcDaBomMvNKI7xnh/+wsw0qDk0HWMyJ9gAUYJFB25kon2dyhQ"
DATA "bFB03Gomkz+XQJlB0VErmn1/aQIFBkXHrGmi/QUJDFZ4PRytr5j6J/YC3vrzCQxSKDpiZRPuL1bgoULR8aqb2AtYInDXoehoE6dE"
DATA "IIL9HSzAI4MujdP/ER2ryon0FydwO6IjVToNBYqOU+1E+nMIFBoUHaXmCfOXWaDoCJWPx1+EwGCDouNTP9kWYKhB0dEZmHwLMMig"
DATA "6NhsTIy/SIOi4zIzWQXuGRQdlWyC3g221AT4Ewj0KhQdU8rUf7+2e39JAl0KRcdjbmIW4K7ArULR0ViciAV4IHAhUXQkVufAn0tg"
DATA "gMFpREdheAoJFB2D7dn35xR4ZFD0/PYns0DRc/cxcoFeg6Ln7Wik/pwGRc/Y23gF+gxibztCgUuDoufpeJz+vAIvCkXP0P3IBK7/"
DATA "Og1zmSCBokcccHYEih6HYRiG6W9UvNtPf9P0u1sMkzAkQeH4Pik6Q2Mwf/8HFX4FVw=="
DATA *
