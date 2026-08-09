"""
ntsc.py — NTSC composite "artifact colour" decoder.

This is the effect that makes 1-bit Apple II / CGA / early-PC output come out
green and violet on a colour TV: the video dot clock beats against the 3.58 MHz
colour subcarrier, so a *monochrome* bit pattern decodes as colour.  Which hue
you get depends on the dot's position (phase), and how wide the run is
(saturation) — a lone dot is fully coloured, a wide run washes out to white
with coloured fringes at each end.

Model
-----
Dots are emitted at 7.16 MHz and sampled at 14.318 MHz (2 samples per dot).
A causal 4-tap boxcar gives luma; the same window demodulated against the
subcarrier in quadrature gives I/Q.  Phase advances 90 degrees per sample, so
one full colour cycle spans exactly 2 dots -> the *parity* of a dot's column is
its phase.

    Y = mean(w)
    I = 2 * mean(w * cos(pi/2 * n + phi)) * sat
    Q = 2 * mean(w * sin(pi/2 * n + phi)) * sat

PARAMS below were fit against a real Apple II screenshot (1068 measured dots,
RMS 22.7/255).  `capture_gain` is *not* part of the model — it only records how
much the source screenshot was dimmed by its upscaling blur, and is used to
reproduce the screenshot for verification.
"""

from __future__ import annotations
import numpy as np

# Fit against ASSETS reference: Apple II 40-column text, NTSC composite.
PARAMS = {
    "phi": 0.5760,          # subcarrier phase offset (radians)
    "sat": 0.480,           # chroma gain
    "delay": 2,             # group delay of the causal window, in 14 MHz samples
    "capture_gain": 0.730,  # brightness of the source screenshot vs. ideal
}

YIQ2RGB = np.array([
    [1.0,  0.956,  0.619],
    [1.0, -0.272, -0.647],
    [1.0, -1.106,  1.703],
])


def decode(bits, parity0=0, phi=None, sat=None, delay=None, gain=1.0, pad=8):
    """Decode a 1-bit scanline into artifact colour.

    bits     : sequence of 0/1, one per video dot.
    parity0  : phase (0 or 1) of bits[0] — i.e. its absolute dot column & 1.
               This is what makes the same glyph green at one column and
               violet at the next.
    gain     : output brightness multiplier (use PARAMS['capture_gain'] to
               reproduce a dimmed screenshot).

    Returns an (len(bits), 3) float array of RGB 0..255.
    """
    phi = PARAMS["phi"] if phi is None else phi
    sat = PARAMS["sat"] if sat is None else sat
    delay = PARAMS["delay"] if delay is None else delay

    n = len(bits)
    s = np.zeros((n + 2 * pad) * 2)
    for i, b in enumerate(bits):
        if b:
            s[(i + pad) * 2] = s[(i + pad) * 2 + 1] = 1.0
    idx = np.arange(len(s)) - 2 * pad + parity0 * 2

    out = np.zeros((n, 3))
    for i in range(n):
        acc = np.zeros(3)
        for half in (0, 1):
            j = (i + pad) * 2 + half + delay
            k = np.arange(j - 3, j + 1)
            w = s[k]
            ph = np.pi / 2 * idx[k] + phi
            Y = w.mean()
            I = 2 * (w * np.cos(ph)).mean() * sat
            Q = 2 * (w * np.sin(ph)).mean() * sat
            acc += YIQ2RGB @ np.array([Y, I, Q])
        out[i] = np.clip(acc / 2 * gain, 0, 1) * 255
    return out


def colorize_cell(mask, parity0=0, gain=1.0, context=3):
    """Colourize one glyph cell (rows x cols of 0/1) at a fixed phase.

    `context` blank dots are decoded either side so the leading edge gets the
    same fringe it would get on a real scanline.  Dots that are OFF are forced
    to pure black so the CBF loader treats them as transparent; a lit dot that
    happens to decode to black is nudged to (1,1,1) so it survives.
    """
    h, w = len(mask), len(mask[0])
    out = np.zeros((h, w, 3), dtype=int)
    for r in range(h):
        bits = [0] * context + list(mask[r]) + [0] * context
        # bits[0] sits `context` dots left of the cell, so its parity shifts
        dec = decode(bits, parity0=(parity0 - context) & 1, gain=gain)
        for c in range(w):
            if mask[r][c]:
                px = tuple(int(round(v)) for v in dec[context + c])
                out[r, c] = px if any(px) else (1, 1, 1)
    return out
