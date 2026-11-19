#!/usr/bin/env python3
"""Patch vendored libmypaint for DRAW (DEV/mypaint/vendor.sh): no json-c, builds as C++."""
import re, sys, pathlib
D = pathlib.Path(sys.argv[1])

def edit(name, fn):
    p = D / name
    s = p.read_text()
    t = fn(s)
    if t != s:
        t = "/* DRAW: patched by DEV/mypaint/patch.py */\n" + t
    p.write_text(t)

def brush(s):
    s = s.replace('#include <json.h>', '/* json-c removed: DRAW parses .myb itself */')
    s = s.replace('    json_object *brush_json;', '    void *brush_json; /* unused in DRAW */')
    s = s.replace('    self->brush_json = json_object_new_object();', '    self->brush_json = NULL;')
    s = s.replace('''    if (self->brush_json) {
        json_object_put(self->brush_json);
    }''', '')
    a = s.index('// Compat wrapper, for supporting libjson')
    b = s.index('mypaint_brush_from_string(MyPaintBrush *self, const char *string)')
    b = s.rindex('\n', 0, b)            # start of the return-type line before it
    b = s.rindex('\n', 0, b - 1)
    e = s.index('\n}\n', b) + 3          # end of mypaint_brush_from_string
    s = s[:a] + '''/* DRAW: .myb JSON parsing lives in native/mypaint_draw.h */
gboolean
mypaint_brush_from_string(MyPaintBrush *self, const char *string)
{
    (void)self; (void)string;
    return FALSE;
}
''' + s[e:]
    return s
edit('mypaint-brush.c', brush)

# C++: malloc / realloc / calloc results need casts
def casts(s):
    def fix(m):
        lhs, typ, call = m.group(1), m.group(2), m.group(3)
        return f'{lhs}({typ}){call}'
    # "T *x = malloc(" / "x = malloc(" where a declared pointer type is visible on the line
    s = re.sub(r'(\b(\w+)\s*\*\s*\w+\s*=\s*)((?:malloc|calloc|realloc)\()',
               lambda m: f'{m.group(1)}({m.group(2)} *){m.group(3)}', s)
    return s
for f in D.glob('*.c'):
    edit(f.name, casts)

# C++: the remaining implicit conversions, one by one (g++ errors on v1.6.1)
def rep(name, pairs):
    def fn(s):
        for a, b in pairs:
            if a not in s:
                raise SystemExit(f'patch.py: {name}: not found: {a!r}')
            s = s.replace(a, b)
        return s
    edit(name, fn)
rep('mypaint-symmetry.c', [
    ('data->symmetry_matrices = allocated;', 'data->symmetry_matrices = (MyPaintTransform *)allocated;'),
    ('.state_current = {.type = -1},', '.state_current = {.type = (MyPaintSymmetryType)-1},'),
])
rep('tilemap.c', [('self->map = malloc(', 'self->map = (void **)malloc(')])
rep('operationqueue.c', [('Fifo *op_queue = item;', 'Fifo *op_queue = (Fifo *)item;')])
rep('mypaint-tiled-surface.c', [('self->bboxes = malloc(', 'self->bboxes = (MyPaintRectangle *)malloc(')])
rep('mypaint-brush.c', [
    ('            mypaint_brush_set_mapping_n(self, s, i, 0);', '            mypaint_brush_set_mapping_n(self, (MyPaintBrushSetting)s, (MyPaintBrushInput)i, 0);'),
    ('        const float def = mypaint_brush_setting_info(s)->def;\n        mypaint_brush_set_base_value(self, s, def);',
     '        const float def = mypaint_brush_setting_info((MyPaintBrushSetting)s)->def;\n        mypaint_brush_set_base_value(self, (MyPaintBrushSetting)s, def);'),
])
# C++17: no 'register'
edit('rng-double.c', lambda s: re.sub(r'\bregister\s+', '', s))
