' st-patricks.bas - palette color cycling
' Exported by DRAW 2.5.1 (https://github.com/grymmjack/DRAW) on 10-06-2026
' 320x200, 73 colors, 3 cycle range(s):
'   1: 33-52 FWD 10.0/s
'   2: 53-62 PING 9.0/s
'   3: 63-72 PING 9.0/s
' Keys: SPACE pause/resume, + / - speed, R restart, ESC quit
'
' How it works: the art is drawn from a 32-bit image, then an 8-bit overlay
' holding only the cycling pixels is drawn on top (overlay index 0 is clear).
' Each step the overlay's palette entries are rotated with _PALETTECOLOR -
' the pixels never change, only the colors they point at. Speeds use the
' DeluxePaint CRNG unit: 16384 = 60 steps per second.
' Compile: qb64pe -x st-patricks.bas

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
_TITLE "st-patricks.bas - color cycling (SPACE pause, +/- speed, ESC quit)"

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
DATA "eJztnU/IZUeZxm80ziQ9mTHGzvwxk+5Oujv5FoLQTjZDnBkwNBniIiBZTJiAyxmETpYBmYVZz0IhZjGKq0GhZ+MiIGYhAyK0GQ3q"
DATA "JiM0SsBAJMYJKAhuzty699Q9b9V563/Vqapznhceu/s7954656m3fvVWnfPFJz79T5++Y/cPd9za/ePu3x8/P7z67Nnw3zf+dvjh"
DATA "S58ZfvbKc8PbN58f3nvti8P73395+O1Pvjn8/vZrwx/e+dEg4v1f3h7e/N53hvPXzw0fe/ajw8UbDwxXX7oyfPwr14bHvnF9+NS3"
DATA "nx2u37ox3HPu3HB2+fLwzFNPDbunXxw+/G83hws3bw/Xf/Cb4cY7w3DvtbuGx2+eDTfeenG4cGEYzj8xDHd/fhh2X97r1b3eHIY7"
DATA "f/2r4b6ff3249OPPDk++dja8/NWz4RdfOBt+97lrw1tPPjG88YlnhtfPXhjeOPvS8NOzbw1fu/r68NzDbw/nX7k1XNy3de277+7P"
DATA "v7/m/XU/v//zk/t/P7j/+f374+deenV4+tbjwz//7wvDv7zzn8ON//uf4cZ7bw833t1/dv/n8/t//+v+58/tj39w99Dub3Z37P7r"
DATA "3G4f+2vbx2O7v9vdv/uPu3e7D4w/+fvdk7uLyk+ErxAEQRAEQRAEQRAEQRAEQRAEQRAEQRAEQRAEQRAEQaUk3ncUMh0X70GK9yX1"
DATA "n8v3J6UO71Ey5xHvVUod3q+UMrQr2pMS7UqJ9oRm5ze0S9sX7YX6orer36/Svnh/VMpwv7nb9fVZ/5x4t1W+3+rjs96/+v3O8knr"
DATA "X/k+rSmvSvWvbNd0v7794epf0/d825X9a2zf4DOURzJHxXvp3HGZn/pxjn1C+uds7OPatY1Jodn5De2e7m9s03TcJBuDaHs+7LP5"
DATA "G9uuLt92fdhHfbaxT7Snn59jn5D+udL9a2Mfl88mufrXdB7fdmXfGvvV4DOURzJHfflH5yvxM136fCVzhfuskMxR+XmZK6bPm+qv"
DATA "XPyT92u6Pyr5HeX+Lffr0z7lAOvveL/UXyHT9XL1Fz1O+5e7Xsof9nqYOoi2q5+P1kEp/Uvbpeen9+vbfzbJfDadQ1/H0HzmPm+q"
DATA "r13zmu/1QmEyzc9Scn6m9UDIfOU7T8rjrvnZVH9Z+RdRf8XmW2y9KWWqgxR/yfld4yO0f2ftJdZfprovtX9D242Vq/7S1zF6Prv6"
DATA "17euB//KyJUvXH+FzFcuHsj1gS//uPEo6xBZB9F25fGY+ivGzxz8c84vGv9c80tI/7J+R9TXsfzT+8t0v/rnfO83VC7+6OsnPZ99"
DATA "+te3rs9xP5Cq0vOVq/7i+BdTj4S2a1IW/kW0K1W6vg6939j62tRuaH2d+35DFVpfu/hn6t/Quh7KI5+9cNpftr1wujdM92P0vXC6"
DATA "Nyw+Q+c3296/fA5omg8P+zGRdZ9+HtNzT9d3Xc+TXPJ53krvy/S8Vfc5pB6h8nmuzflsajd0ftHb9elXccz3+bJP+yH1tWsc2eY3"
DATA "fR3Ta90n/ptivciHfbK/xOd92CfzRXzeNibl+KDXY2OfrPts90PrkRRfTAxytk/4l7NdWgdx9xvqM22P9q8un+fatrwy9a+vP6a8"
DATA "csn2fDmkP1zt0nrT1i73HN92v6n5C/nJ93mrwr8xHzhx/NOfA+qi10PrEZ/Pz/I1kT9UXNsyP23ty/uNadP1vHXGP3K/nGj/cu05"
DATA "+UfGo96/tv4wtUv71+WFCFp/Hdof7ze2/+T9+vaHi386523P0w/545jH6f2G5g4ULtpf3HF9vnLVQXpdQNcHPtfjGo8u5eQfJ9f8"
DATA "HHq/s/N71rm+9xvav6779a2vTe2a+tcUlD+Hf2eqr739Daxz6f5mTP+G1rlQmlzjQ+8vJ/+0/KzBvxT+uOSan7PwLyD/Xfcb2r8+"
DATA "9yvrMNFuaF7p/auH5K2JfyLE36XPUf5mnF/0Ote1znb1L/i3rELnK9M+lClf9P0Rl0LnZ12p/HEpdD8oVL77jL73W6oeiW2X9i8X"
DATA "tN488Y/5fKzPpetrJ/8C109QWYXOV671n16PuPbf2fYq8s/1bEd8xrXv1RL/StYjcn9RSP7MtPevf8/ks6zvuPWuHnR/U79f0zM0"
DATA "V/+Z8tn0u3T6+Vz7m6HrJ6isQuer0P2vGvzLwR/Xc22TsvAv4Pmf635L1yOm/S/T+wNChzrP4LPOORv/RJjqr9j3B0z5bPt9Xvp5"
DATA "3+fp4F87cs2H+vHcnw+9nqW+b1Jr1x/aH6WP23zT6zdOXJ1n4h89nqv/UvOhtN8QBPWnJUJvrxdvIAhalzge1Y4efIMgqD/1FD35"
DATA "CkFQu/KJ9395u4jAQAiCask3WmMfGAhBUIpCokX2gYEQBMUqJHriH/czyF8/fOkzELRqhUTL7POJnvoFgqDyKrGfV0PgIARBoeqJ"
DATA "cTnYBwZCECTVE+fAPwiCcqknxuVkHxgIQZBQT6zLrZ76CYKg/Hrze9/ZrHrqJwiC8qsnXoGBEATlVE+sAvsgCMqtnpgF/kGlhGdi"
DATA "21RPzAL/oBzCewIQBG1NKdHTfUIQBFHliJ7uF4IgSChn9HTfEATF6WevPLcKlYie7h+CoG2qZPTkAwRB29ISobfXizcQBK1LHI9q"
DATA "Rw++QRDUn3qKnnyFIKhd+USp/2YQGAhBUC35RmvsAwMhCEpRSLTIPjAQgqBYhURP/ON+BkEQJBUSLbPPJ3rqFwiCyqvEfl4NgYMQ"
DATA "BIWqJ8blYB8YCEGQVE+cA/8gCMqlnhiXk31gIARBQj2xLrd66icIWovevvl8M+rp/1cht1rqBwiClldPvAIDIQjKqZ5YBfZBEJRb"
DATA "PTEL/IMgKKd6Yhb4B0EQBEEQBEEQBEF968KFobp68guCoL7UAuPARgiCSiuUL889/HZ1gYkQBMWoJ86V4mJP/QVBULxys+5rV1+v"
DATA "rtxM7Kk/IQiyKwfrWuBcKS6ChRC0LqUwL5QzPz37VjXlZiJYCEF9qiTvajKuJBtjedhTXkDpeu+1L0INKoZ5uVn3xtmXqik3E2NY"
DATA "2FO+QNAaFMK8HLyrybiSbIzlITgIQcsqpNZL4V0oZ14/e6GacjMxlIWoCSGorHLUeqm8q8m4kmyMYSFqQggqr9RaL5Z3wZz5xDPV"
DATA "lJuJOVgIDkJQvFK4F8O8HjhXiou5WAgOQlCaWmJeCGveevKJasrJxCVZ2FNeQlBJ5eReSd7V5FwJLsbyEByEoHSV5l4K70JY87vP"
DATA "XaumnEwMZSE4CEHh8tnfK1HrpfKuJudKcDGGhSk1IfYHoa2rFPdCmZeTdb/4wlk15WRiDhbm4GBP+QxBPlqSezHMa51zJbiYi4Xg"
DATA "IATxKsG9kFovlnkhrHn5q/WUi4mhLPStCcFBaKtKZV9srVeKdzU5V4KLMTyMrQnBQGgraol7KcwL4c2Try2vnDwMZSE4uC29//2X"
DATA "IQ/Z2NcC91J4V4NxpdgYw8JaHNRzqqfxAG1HvjVfDu7lYF5O3l368WcX1xI8TGFhKgdttWBP4wJat0rWfLHci2Feq5wrwcVcLIzh"
DATA "IGpBaC0qVfPl5F4s70KYc9/Pv764cjIxhIU1OIhaEGpNMTVfCe6F1HqpvKvBuRJcDGWhb02Ym4O+tWBP4wbqW77r3ZCaLxf3Qmu9"
DATA "XKy789e/Wly5mFiiJgzlYGwtiPUwtKRi1rupNV8s90KZ1yrnSnAxBwtjOJirFsR6GFpaqevdmtyLYV4Ic3ZvDosrFxNDWFiDg1gP"
DATA "Q7WVut61sS8H95ZiXg3O5eZiKRamctCXgb7r4Z7GF9SmYvb6Yvf5SnKvOO9eraDCPFyKg7H7gtgThEqq5Ho3tObLyb0k3tXgXGYu"
DATA "hrIwFwdL1IJYD0MllHO9m1LzxXAvtNbLwrsvV1AGHqbWhLk56FsLYj0MlVKp9a6t5ivFvWDmtcq6nEzMwMLcHPStBVPXw7nHCrQu"
DATA "pbDPd72bWvPFci+KeQHsufvzyykbEwNYGMPBXLVgzHoYDIRClIt9vuvdqtxLYN6SnMvOxUAW1uBg6noYDMyv3/7km6tWCfb5rndT"
DATA "uZfMvEysO//EcsrGxMwsTOFg6no4lIE9jU+onEqzz7betbEvpt7z5l4C85bkXG4uBrPQg4Oh9aAvA33Xw2AgFKsQ9qXu9dnWu6k1"
DATA "Xyr3cvBOf++spHLwsDQHQ2rBmPWwz54gGAiZlIN9ude7ydzLwLyWOJebiyVYmMLBJdbDYCCky8W+Jda7tpqvFPdimOfLnlr9F8vD"
DATA "IBZm5qBvLVhiPQwGbltLsc93vRtS83mtcz25F8u7Xvo2hIfRHHSsi2NrwdT1MBgIcSq55k1d7ybXfAm1Xq+8C+lvHxZ614SFasGY"
DATA "9TDWwpCParPPd71bgntbYp5P/8eyMCcHU9fDYCAUolbYZ1vvWtlXmHs99WWuXFiCg74M9F0PL8HAnvoS8s/3ltgXtM8XuL/ny72e"
DATA "+rB0boRy0Lk/GLkvCAZCpfK7RfblrPnAvHy5YmLhErVgTQYiV9aZz76/1xHLvtT1bkjNB+4tlzdZOOhZC4auh2MZ6Po9EeTNunK4"
DATA "BPuKrXctNR+4Vy+HojjoWQvmWg+DgZCeu77v+C3FPu/1bmLN11Nf9ZJLuWvBEuvhVAZiL3A9+RrzfvNS7PNd74J77eVVci0YsR7O"
DATA "ycCY96N76qfc+v3t17pRyvOO3Pt9Ode7Lu711Ee9K4SDqevhUvuBMc9DeuqjredlyrPeKuyzrHdt7Oupf9acb94M9FwPl2Jg6jPh"
DATA "nvpnq/mYsudXm3229S5qvnZzjuNgzHq4FgN918E99c0W83At7EPN12f+Ra+HwUAoQ+7l2PNzvdsczb6IvT7UfH3moa0W9NkTjGWg"
DATA "6x1p7AWuN+daY1/O9W5PfYKczL8eBgMhW67lXvcuzT6sd9eZlznXw6kMxDp4vTlWmn2UfyXZh/XuOvMzaj0cwcCYdwNDGYj8bCu3"
DATA "Sq17a7Kvp76A/HO1FgOxDl5nTtnWvUuzz/isA+xDvmZgYMgzkVIMxDq4rVyqsecH9kGpeVuKgUvuBSJv6+aRz7oX7INazN0eGWhb"
DATA "B/fUB2vIn9rrXrAPSs3h3AxcYh28e/pFRWBgnbxJXfdmZx/lXwD7evIfyqsoBjp+TyQHA7kaULDuxlv7dsWf7wzD/a/cOvwpJe5D"
DATA "Z2NPfdFTvsTWfrnXvWAflKpcDMyxDqbsklwTfxdj6foPfnOQ+Lf8O5X47PN7PlImroWBf3jnR9UVW/vZ1r3Z2Uf452JfC55Cbcib"
DATA "gRHvxfgyULDqk99998Stcy+9euLYtfHn8pjOPhMThXrqhx5yJPWZxxJ7fmAfFKoUBsasgynTKNdsLNOZp9eJUvpnqHrqk9Zyw1b7"
DATA "xa57wT6oFS3FQBPjKL/kfh9lpPy5rBOlLt68PWOpTeJexZ/6HiL4aM+LkNpv0XUvs+dnes7bk++t6+KNB5pXTJ6bGJiyF6jzTK/T"
DATA "Qmo4nZM2lup7gnqtqX8fDORzIvWZR+i6F+yrqx7YVoKPJRho45nOPVrr6c95uTUvZRfdMzTtFcpreJCpGcG/uZZ85pF73Qv22dUT"
DATA "p2qIMjBlHXziFvN81rR+pc9CdO5JPkpeXdh/37ZPSJ8RC0bS86H2Myuk9ot95mFb94J9edQTc3pQCAP19aprr47WiHo9p3PPtIbV"
DATA "mSb4aGMw+McrpfaLfeaRe93bk9851BNH1iYlT5m9N+79PPosg/sOZRxlp/wZ/b0QwTldIic4xnJ7hT3leWnlrv2yrnvBPrCucfm8"
DATA "w6LXcdwxrl6kx+nvBkuOvT+o62vXviH9Dp4F8/yrXvttfN3b09iH0vlnW9Oa3oPR9/rkO4Zc7SfrQ9fauacxkpt9Pu/7laz9bOve"
DATA "tbOvp7EOzaWvR03rU3mMPo/V9wK5d6WFzmvv73FM5d5/oWte0zs54F+52i/6mcdK1709jWuqqy9daV4t+HRYx2pMpD8z1V62Y7aa"
DATA "zad2tJ2b7h1ulX1L1n6x695e2dfCmFwD29bARxfLYvmXwsgt7/2l/K5HrtpvbeveFni2ZcYtxcZnnnoqWKZ1sfi5OG46ZvsOlekz"
DATA "Iefg1OI4K8m/qrVfZ+tecG6bXIzhn2SR/p4ed9z35zFth56jlbFWkn0+/Gul9qvlGVgHSZ1dvrwZtcCr0vxL+T3fJWq/GutesA4C"
DATA "/9bHv5jnHj6/55u79lt63QvWQeDfdviX8s5LTO0X+75LKfaBd9DSEv1N2XLPuXOLSM+5FrnUCv9inntE1X4Lvu9Sil1bYd3Hv3Kt"
DATA "ebXuIVdbLcU/Ewe3xsMczz18/hsvMft+uZ55tMK6XnjXA9t65qNtbbk0/1wcXDsTSzz38Pk935jaz+eZR0usa5l3PXGqhmqwryb/"
DATA "fBm4NibGPvcIeeelVO3XGuta5F1PzFkzF32fLdTkXwoHe2Rijt/3SHnu4fvMt0XOgXWQLxdDnq22wL8cDOyBi761373X7mJF+Wf6"
DATA "jNd/42XPvdbY1jrvemLDlnkY+m5JK/wrxcBQNpZkqg//BMNuvPUiK3FMss/2GcG+WsxaA+96GvfQpJh361ri39IMbE02rlG++Xym"
DATA "h/sF76Bcin23uDX+bZmBPmzzUYv8A+vS9Ng3rjevmv6Af+BfK/xrhXW98K4HtrXMx1j2tco/IZG7NcdwLf49fvPMKMo42+eW5F9L"
DATA "rGuZdz1xqjc2rpV/nGqxCfxr891icK6MuHcLQo4vxcUU9rXMPxsD18rEVvjXIufAumXZZ9pX8Tm+hMC/9XFxSf61yrhWebfUuG6Z"
DATA "f5JxtmNLXyv4l5eNtZlqY6AP/yT7arOrZ94tPYZ7YZ/vs7clrxf8W5dy8K+XewXvwD/wD/zzZaCLfy2zD6zrh3+uPRjX3stS15rK"
DATA "vtb5hxqwT/61wDnbM8mSzyvBP9R/YF8ZBtr4V4t9LbCO4x5dj9HnlqZjtfSpbz/blMC/dsTld40x3goDTfxbin2tsY5bz9rezaix"
DATA "X9Ua31IZ6Np7XpJ9W+RfaSZyHi/BFhsDZT7q/JPHcrfZIuc41vmyb4k9+574Bv6ti385uejr+xLs0zmoj9k1Mi6EdzX41xPHSjDQ"
DATA "tvdsOx/4tzz/YtiY0hehNZ1NNgbajrvUGuNSeMfxL2fd0gOneuFfSSaukX+9jkFd9Nx0LeuSiVemn6Wedw1ep/CvZRa1xEDTs7dc"
DATA "bYJ/6+IfHZuuZ2ehvArhnp7DSzOwlK++DMxZt+TU9Vs3mhRlIPWU+iiPlfSnNAPBvvLjVN+XiuWVZBZ9jyPmXHTfq2fW9cC/VvkW"
DATA "KvoMrva8sXb+yXuqwb2UOSg3/7g9ev0dttRz9sw6TrJm8eFfzjHcE8so0zjZPi/zJvScSzBxDfxz5XfpcZoyB/mwz4dX3Gd1/tk+"
DATA "63veXO9+1GQdp5L8a5Fjsdwz5YmNhaaf+Z6zNAd75l/LYyqWibZ3MnzZZ+OfLwNzvPvRU9/k2LdqmWEp7AtZL5hY6MM8LgfpeVpg"
DATA "INiXj38mJvrUgC6GUU7Z9rh8z98y+3L677tv1Qu/crAvds9EsoueJ/QcrvXz0gwE+8ryT45BU/3lu3714Z+r1muRfzm8ddVzdN/K"
DATA "xDqf/a+t8Y9jVuz+sy//cvOwZf7VHntL8c+HgT7rEHqdPuuOVthXwktu7WXac5fj1sQ723laZVkO/vnulUhPqG8+aw7TZ1J9zclA"
DATA "sE8doyXmIH3cxrBPniOEf6bcy82+UnOGbR7xuXfbvpWvd2tiYOg+jO6lzT+f8+XiX+wYbYF/tfnmUk6/XWPYl4GmtV3oOniJ529L"
DATA "8S9kzRWzb1VyrLbIP1c+Uh9C9p+X4l/I+KzBvx7GVgj/UpgI/qWzz+aZaf3mM865c2yBgS4/fPhn8r8VLzkOgnv5+OfLRJ91iIt9"
DATA "Lgaacq9l71194DNvcMdc7wz5zBu1xmwpBvrOJRz/fBjIzSEt+kjzbou88x17ufMP/Av328Y/k48x+1Zr55/JT1/2ye+GsK8XT6S4"
DATA "XF0D33KOx1x5Zxu7rut1jekW+FfDu9B1m82zGuOvRh6G8C/EzzV5WGP89DZGY3KPW7P5+m9b2y3BvhrexYzd0Jplzewz5aAv+2x+"
DATA "bmkO0VWTYS2N0dj8ixl3dG1nOmeL95/TP9/axadm2cp49dmHcXnhO/f24Ae0vOi7til5Qr+f65yt+xZTu6BmsXvoswax+Qn+QTW0"
DATA "hfWafr+xazefPdMt14AhubTVtQfUnsBAv9rFVbNsbcymrhe2tvaA2tQW+acz0NcDU82CcRvfDz1dMwStRTH1hqlmaem+euyDnq4Z"
DATA "grYqjFf4Cc21QyAQCAQCgUAg+HjkkeOfZxfF/1566KGHHn5Y/O3KlStXr149Hj07O7t48eKlS+Lvx6P741fpWcRR8d398cuXLx+/"
DATA "yx2dziz+9uij05lFu+K74uei3UcePV4V3+4jjx6/O7Uh2z3+azp6aWz1eOb8If27eGjtYN/o38G+0b/DbVyi90H92X/7aND+2Mm+"
DATA "8bzq0enM4m8n+/ZnHu27cji3sO/gn6nd0T7in2z3+K/pqOy145nzx7Gfj/7Rvpp6Uubm8VoeHvtRzS/1nGpu7s976fin+O6V8T5o"
DATA "u4djWn6J/523S4+qIfNL9PjR+2O7U9bPv5MjZFsXL6l9NfXkdI/H/Dr+Xc0v9Zxqbk7+HfplvA/argg9vw7HZu3So2rI/Dr4t79m"
DATA "2e6U9fPv5AhTX0kPzoh/cmTrDkl/ZMz8M+Q1/a6a16p/pu/SoHktrnlql2Z9/jD1lcyvg3/7Y4crmfwj2cf4pxw15zX9rprXx6M0"
DATA "r7nv0qB5Lf07tkuzPn+cEC4Yc0T4YRY7IHyPYfGZEf+ju/P8krOn/Jeck9SjdG6VZ6a5SWdt2e50jmluPRw/zcun4wqv9RlfvZ6c"
DATA "cbLv4N80i403Od7HNC+L0PNLzp7yXzP/ZnOrPDPNTTprc/6pM5acl0/XpPBan/HV68kZprmVznEyR2To/sjQ51YZk/N6vckzd6pG"
DATA "ybkPfaqeV35XXvPhmzNez+uBnGGaWymj6XWKcPmn853zj7YrvzvltVq7Ha6J84+c18xrjjf5gvYVV0OJmPnHzH8iTPPjREa/uk/3"
DATA "b8pN9cymvObn9DJB+4qroUTQfhbB1Q8iTPMjXTv51H3y6Dw31TOb8pqf08uEaW0g+a5fp4h5ftG1p/pdEZx/phw58utYD8gzH65J"
DATA "yS+1Hjhes3nNa+JNjjCtDaz+zfyha0/GPzL/2es+ya9jPSDPLP6m5pdaDxyv2bzmLekfAoFAIBAIBAKBQCAQCAQCgUAgEAgEAoFA"
DATA "IBAIBAKBQCAQCAQCgUAgEAgEAoFAIBAIREDc4Yqgs20onMbBRlNQX867AiYqEeAc72JQa+sKzrqPuoIzMajVlcTMOqdzvIubtFAz"
DATA "jzpznz04EzdmocE7h3EGG1UPg66jy1DM46z7iD04E7djITFv5p3DOIONqoerdpCknuYddeZee3AmUgtXm4Sz1NO9cxhnsFGxcL1J"
DATA "qKee6h115sP24EycWbg2BzX3FPO8neNdnFu4Ogc9zCPW/Jk9GBMtFgZdZ5vBuGfwzuEc66Lq4focNLmneUes+VN7MCZSC9fl4Il7"
DATA "bOrp3jmcY11ULNSSsHsO8u5R8xjr7rEHY+LMwpmDQVfdSljcU8zzdY51cW7hShxk3SOpp5pHrPkTe8xNpBZOSdi5g7p9aurx3jmc"
DATA "Y11UPFSTsGMDPdzTzCPenLMF4yG1cB0OjvY53dO8sxrH26hYaHewHwOn5Ju5NzOP8e5uWxg91CzUHRxTMOg+6oQh+VT3FPP8nGNd"
DATA "nFuoONhhCvLJx7inekfMucsWjInEQquDXaSgknyseyT1dO+szrEuUgunJOQcnFIw6H6WjWnskuSbu0dTb27dH9tibiKbhNRBNQVb"
DATA "HsPK2NWTT3WPmufnHOvizELFwXkKNj2G9bHrcE8xj5jzR7aYm0gstDrY/BjWx+5o38w9s3lW5zgXeQt1BycDpzEcdGdLhII+lXwG"
DATA "90zefcgWJg/NDqoUbBWChrFLk49xT/PO6hznIrVw7iCbgm2OYWbsasmnuEdTb+bdnbaYeagnIefglIKNjmF+7I7Jx7tHzfOzjjFx"
DATA "ZiHn4JSC+hgOuseCodk3jV09+VT3FPOIPR80x9xEYqHi4DwFlTHckoFz+6ax63BPM8/iHOcitdDqoD6GmzKQtW8au7p7unlz6z5g"
DATA "jrmJnIWag/oYbstAk33j2B3tU3Jvck8zz+Ic5yK18OQgzcHJwGkMN2YgsU9H3zh29eTT3Zt5d3yFio2ZhyYHSQoqY/gEwUYMnNnH"
DATA "jV3dvZl5Hs5xLrIWag4ax3ATBkr7jGN3TD7ePcW8yR57e6qHxELOwSkF2TFc20CzfdPYJcl3GrmTe6p3/s0SD1UH5ShWU1Afw20Y"
DATA "aBi8+tjVk09LvTDvSNsnC6ck5FNQGcPtDGGXfdPYZd1LMO/Uvmoh46A+hlsy0G3fOHZH+0zuBTWqX4LRwcnAaQwbDQxqNFN42UfI"
DATA "R7k3uRfUJH8Z1EHJQZWCLRp4GL0e9jHJl8+806UcLTSmoMPACiN4sm/vn2qfPnZJ8pVwb7yamYNTCtIxrBooVyKLG2iyjx+7Y/KV"
DATA "cm+8IMXBKQXnY7gBA2nhZ7ZvGrt68gU15ntJXAqyY1g3cHEEanWz2b5p7BZ273hVegoqY5gxUKmjg9pKvVA6d3DsY8ZuYffGC5MO"
DATA "6mOYZ2CVOWQ+9VrtG8fuaF9QS1HXNhk4jWHewEqT8Ax+LvvGsVs4+eTFHRxUxrDdwKVHcIx9yySfvD51DDdmIAc/WTar9inoWyT5"
DATA "Tlc4puAJgqqBspCugUBP+5ixG9RM8kXOx3AbBvKj12bfkmN3ukpmDOsG1hjBY/px9u39M9i34Ngl16mMYcVApQykBha/TuPoddgX"
DATA "1Ei2S7UbWGMEn0avzb7j1FHZPsZAMonwBhYfwZbRe4BfS/ZZDLQgsPT66DR627cv2MBxBAc1EXg9rtHblH0mA40jWHyloIHM6OXs"
DATA "2/tH7AtqocQ1EwPlSmRm4CEBd3+52z0ovhLUQNC1qOnHjd7G7OMMnI3g4wc/cvrKxzxPHXwlNP3G0cvZt/evGfuogUoVMxm4e2C3"
DATA "u7Db/UXQWaMuRJ88jPBryL6ZgcoILm4avYwx/dTR27x9NgOnz+zZt499Ju7+XPmuAGKuqyDpZxm9B/hVn3lpyFlYQ+DomSFyQ3A+"
DATA "edDR27J9BgO1z5BE28NQxl9bzxt2DcbJgxu9LdknYm+gNoLlmD2MVzFw50GMTG5/Sj918hhHb+P2jUEMFP8kqGOtsg7wsNDST508"
DATA "uNEbdPZlY3+lB7wdECcyb2Tdwc7jKiR3cOnHjN4u7OND5uJ+Gbzb/RU9ovwjMnzSr/nR6xMShHkLQ1L7GdJvHL092jfOsUfH7pc/"
DATA "lfVLFgaa0k+dPDoevWXDmn7q6IV9TGhLj3n6dTx6lwiv9MPoNYVSvLjTL+jcW4jZxosl/TB6Z6HMHqeVL5d+GL1czIoXJf3U2gX2"
DATA "zYOdPZT0Q+1iidnscdp4UeiHycMQ7OxxWvkq6YfJgwl19iDFC9LPJ2ZrD232mCbfoNNuJqb0O/5779/xL6eNlw8FnG17cfJP/mC0"
DATA "b2+g5xkQCAQCgUAgEAgEAoFAIBAIBAKBQCAQCAQCgUAgEAgEAoFAIBAIBAKBQCAQWeL/AcDFmYQ="
DATA *
