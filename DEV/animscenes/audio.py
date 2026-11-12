"""Audio for DRAW's animated example scenes - all made on the CPU, no model.

  soundmon (~/git/soundmon, Rick's): --chip (NES 2A03 music), --opl (OPL3 FM music),
  --chipfx / --oplfx (8-bit / FM sound effects from sfxr-style archetypes). Fixed seeds,
  cached in the scene's audio/ folder, never auto-played (--no-open).
  synth: pure-Python noise / tone recipes for ambience soundmon has no engine for without a
  GPU (surf, crackle, wind, hiss, whistles, drips, gulls, clinks).
  mix(): every sound placed at a time (seconds, or a frame via Scene.t), gained, summed,
  peak-limited, written as a 16-bit mono WAV - the soundtrack DRAW gets dropped on it.

Stable Audio 3 is not used: the GPU server's ComfyUI must run with --force-fp32 or it
renders static (soundmon AGENTS.md gotcha 11).
"""
import array, math, os, random, shutil, struct, subprocess, wave

RATE = 22050
SOUNDMON = os.path.expanduser('~/git/soundmon/bin/soundmon')


# -------------------------------------------------------------- soundmon ----
def soundmon(outdir, name, desc, kind, seed, *extra):
    """kind: chip / opl / chipfx / oplfx. Returns the WAV path (cached by name)."""
    os.makedirs(outdir, exist_ok=True)
    want = os.path.join(outdir, name + '.wav')
    if os.path.exists(want):
        return want
    tmp = os.path.join(outdir, '_sm_' + name)
    shutil.rmtree(tmp, ignore_errors=True); os.makedirs(tmp)
    cmd = [SOUNDMON, desc, '--' + kind, '--seed', str(seed), '--name', name, '--no-open',
           '--no-recipe', '--output-to', tmp] + [str(e) for e in extra]
    r = subprocess.run(cmd, cwd=tmp, capture_output=True, text=True)
    wavs = sorted(f for f in os.listdir(tmp) if f.endswith('.wav'))
    if not wavs:
        raise RuntimeError('soundmon made nothing for %s: %s' % (name, (r.stdout + r.stderr)[-600:]))
    shutil.move(os.path.join(tmp, wavs[0]), want)
    shutil.rmtree(tmp, ignore_errors=True)
    return want


def load(path, rate=RATE):
    """Any audio file -> mono float list at rate (ffmpeg)."""
    r = subprocess.run(['ffmpeg', '-v', 'error', '-i', path, '-ac', '1', '-ar', str(rate),
                        '-f', 's16le', '-'], capture_output=True, check=True)
    a = array.array('h'); a.frombytes(r.stdout)
    return [v / 32768.0 for v in a]


def fit(samples, seconds, rate=RATE):
    """Stretch / squeeze (resample - pitch moves a little) to exactly seconds long: a
    loop that lines up with the animation's length."""
    n = int(round(seconds * rate)); m = len(samples)
    if m < 2 or n < 2:
        return samples[:n]
    out = []
    for i in range(n):
        p = i * (m - 1) / (n - 1); k = int(p); f = p - k
        out.append(samples[k] * (1 - f) + samples[min(m - 1, k + 1)] * f)
    return out


def loop_to(samples, seconds, rate=RATE):
    n = int(round(seconds * rate))
    if not samples:
        return [0.0] * n
    return [samples[i % len(samples)] for i in range(n)]


# ----------------------------------------------------------------- synth ----
class _Rnd:
    def __init__(s, seed):
        s.r = random.Random(seed)

    def n(s):
        return s.r.uniform(-1, 1)


def _lp(x, a):  # one-pole low-pass, a 0..1 (smaller = darker)
    y, o = 0.0, []
    for v in x:
        y += a * (v - y); o.append(y)
    return o


def _hp(x, a):
    lp = _lp(x, a)
    return [v - l for v, l in zip(x, lp)]


def env_adsr(n, a, d, s, r, rate=RATE):
    A, D, R = int(a * rate), int(d * rate), int(r * rate)
    out = []
    for i in range(n):
        if i < A:
            v = i / max(1, A)
        elif i < A + D:
            v = 1 - (1 - s) * (i - A) / max(1, D)
        elif i < n - R:
            v = s
        else:
            v = s * max(0.0, (n - i) / max(1, R))
        out.append(v)
    return out


def noise(sec, seed=1, color=0.15):
    r = _Rnd(seed)
    return _lp([r.n() for _ in range(int(sec * RATE))], color)


def surf(sec, crashes, seed=3):
    """Waves: dark noise that swells and breaks at each crash time, plus a constant wash."""
    n = int(sec * RATE); r = _Rnd(seed)
    base = _lp([r.n() for _ in range(n)], 0.05)
    hiss = _hp(_lp([r.n() for _ in range(n)], 0.6), 0.2)
    out = []
    for i in range(n):
        t = i / RATE; a = 0.25
        for c in crashes:
            d = t - c
            if -1.2 < d < 0:
                a += 0.5 * (1 + d / 1.2) ** 2
            elif 0 <= d < 2.5:
                a += 0.9 * math.exp(-d * 1.6)
        out.append(base[i] * a * 2.2 + hiss[i] * a * 0.5)
    return out


def crackle(sec, rate_per_s=18, seed=5, gain=0.6):
    n = int(sec * RATE); r = random.Random(seed); out = [0.0] * n
    bed = _lp([r.uniform(-1, 1) for _ in range(n)], 0.02)
    for i in range(n):
        out[i] = bed[i] * 0.6
    for _ in range(int(sec * rate_per_s)):
        p = r.randrange(n); L = r.randint(20, 160); g = r.uniform(0.2, 1.0) * gain
        for k in range(L):
            if p + k < n:
                out[p + k] += g * r.uniform(-1, 1) * (1 - k / L) ** 2
    return out


def wind(sec, seed=7):
    n = int(sec * RATE); r = _Rnd(seed)
    x = _lp([r.n() for _ in range(n)], 0.03)
    return [v * (0.6 + 0.4 * math.sin(i / RATE * 0.9) * math.sin(i / RATE * 0.37 + 1)) * 3 for i, v in enumerate(x)]


def hiss(sec, seed=9, gain=0.3):
    n = int(sec * RATE); r = _Rnd(seed)
    x = _hp([r.n() for _ in range(n)], 0.3)
    e = env_adsr(n, 0.2, 0.1, 0.8, 0.4)
    return [v * g * gain for v, g in zip(x, e)]


def tone(sec, f0, f1=None, wave_='sine', vib=0.0, a=0.005, r=0.05, gain=0.5):
    f1 = f0 if f1 is None else f1
    n = int(sec * RATE); ph = 0.0; out = []
    e = env_adsr(n, a, 0.0, 1.0, r)
    for i in range(n):
        t = i / max(1, n - 1)
        f = f0 * (f1 / f0) ** t * (1 + vib * math.sin(i / RATE * 2 * math.pi * 6))
        ph += f / RATE
        p = ph % 1.0
        if wave_ == 'sine':
            v = math.sin(2 * math.pi * p)
        elif wave_ == 'square':
            v = 1.0 if p < 0.5 else -1.0
        elif wave_ == 'tri':
            v = 4 * abs(p - 0.5) - 1
        else:
            v = 2 * p - 1
        out.append(v * e[i] * gain)
    return out


def whistle(sec=1.2, f0=900, f1=2400, seed=11):
    """A firework rocket going up: a rising whistle with breathy noise."""
    t = tone(sec, f0, f1, 'sine', vib=0.01, a=0.05, r=0.08, gain=0.35)
    h = hiss(sec, seed, 0.15)
    return [a + b for a, b in zip(t, h)]


def drip(f=1400, seed=13):
    return tone(0.12, f * 0.6, f * 1.6, 'sine', a=0.001, r=0.08, gain=0.5)


def gull(seed=17):
    out = []
    for k in range(3):
        out += tone(0.16, 1500 - k * 60, 900, 'saw', vib=0.03, a=0.01, r=0.06, gain=0.18)
        out += [0.0] * int(0.05 * RATE)
    return _lp(out, 0.35)


def clink(f=2600, seed=19):
    n = int(0.6 * RATE); out = []
    for i in range(n):
        t = i / RATE
        v = (math.sin(2 * math.pi * f * t) + 0.6 * math.sin(2 * math.pi * f * 2.76 * t) +
             0.3 * math.sin(2 * math.pi * f * 5.4 * t)) * math.exp(-t * 9)
        out.append(v * 0.25)
    return out


def thud(f=70, sec=0.5):
    n = int(sec * RATE); out = []
    for i in range(n):
        t = i / RATE
        out.append(math.sin(2 * math.pi * (f * (1 + 2 * math.exp(-t * 30))) * t) * math.exp(-t * 7) * 0.9)
    return out


def chatter(sec, seed=23):
    """Cafe murmur: band-passed noise with a slow syllable-ish wobble."""
    n = int(sec * RATE); r = _Rnd(seed)
    x = _hp(_lp([r.n() for _ in range(n)], 0.18), 0.04)
    rr = random.Random(seed)
    ph = [rr.uniform(0, 6) for _ in range(4)]
    return [v * 1.6 * (0.55 + 0.45 * abs(math.sin(i / RATE * 3.1 + ph[0]) * math.sin(i / RATE * 4.7 + ph[1])))
            for i, v in enumerate(x)]


# ------------------------------------------------------------------- mix ----
def mix(out, seconds, events, peak_db=-1.0, fade=0.01):
    """events: (samples_or_path, at_seconds, gain). Writes a 16-bit mono WAV of exactly
    `seconds`, peak-limited (soft knee) and normalised to peak_db."""
    n = int(round(seconds * RATE)); buf = [0.0] * n
    for src, at, gain in events:
        s = load(src) if isinstance(src, str) else src
        o = int(round(at * RATE))
        for i, v in enumerate(s):
            j = o + i
            if 0 <= j < n:
                buf[j] += v * gain
            elif j >= n:
                break
    pk = max(1e-9, max(abs(v) for v in buf))
    tgt = 10 ** (peak_db / 20.0)
    g = tgt / pk
    F = int(fade * RATE)
    data = array.array('h')
    for i, v in enumerate(buf):
        v *= g
        if F and (i < F):
            v *= i / F
        if F and (i > n - F):
            v *= (n - i) / F
        data.append(max(-32767, min(32767, int(v * 32767))))
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    w = wave.open(out, 'wb'); w.setnchannels(1); w.setsampwidth(2); w.setframerate(RATE)
    w.writeframes(data.tobytes()); w.close()
    return out
