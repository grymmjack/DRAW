#!/usr/bin/env python3
"""
grd2dset.py - Convert gradient files to DRAW .dset files.

Supports:
    - Adobe Photoshop .grd (version 3 and version 5)
    - GIMP .ggr gradient files

Parses gradient color/transparency stops and renders them as ramp images,
then packs into DRAW's .dset format for use as gradients.

Usage:
    python3 grd2dset.py <input.grd|input.ggr> [options]

Options:
    -o DIR          Output directory for .dset files (default: same as input)
    -l              List gradients only (don't convert)
    --png DIR       Also export individual gradients as PNG files
    --width N       Ramp image width in pixels (default: 256)
    --height N      Ramp image height in pixels (default: 1)

Reference: https://www.selapa.net/swatches/gradients/fileformats.php
"""

import struct
import sys
import os
import math
import argparse
from pathlib import Path

# Try to import PIL for PNG export
try:
    from PIL import Image
    HAS_PIL = True
except ImportError:
    HAS_PIL = False


# =============================================================================
# DSET constants (must match DRAW's DRAWER.BI)
# =============================================================================

DSET_MAGIC = b'DST1'
DSET_VERSION = 2
DSET_MODE_GRADIENT = 3
DSET_SLOT_COUNT = 30
GRADIENT_MAX_STOPS = 16

# Per-stop color source type (matches DRAW's GRAD_STOP_* constants)
GRAD_STOP_USER = 0
GRAD_STOP_FG   = 1
GRAD_STOP_BG   = 2


# =============================================================================
# Gradient data structures
# =============================================================================

class ColorStop:
    """A single color stop in a gradient."""
    __slots__ = ('position', 'r', 'g', 'b', 'a', 'midpoint', 'stop_type')

    def __init__(self, position=0.0, r=0, g=0, b=0, a=255, midpoint=50.0, stop_type=0):
        self.position = position  # 0.0 .. 1.0
        self.r = r
        self.g = g
        self.b = b
        self.a = a
        self.midpoint = midpoint  # percent to next stop (default 50%)
        self.stop_type = stop_type  # 0=user, 1=fg, 2=bg


class GradientInfo:
    """A parsed gradient with color and transparency stops."""

    def __init__(self):
        self.name = ''
        self.color_stops = []   # list of ColorStop (with RGB, alpha=255)
        self.trans_stops = []   # list of ColorStop (only .position, .a, .midpoint used)
        self.pixels = None      # rendered RGBA bytes
        self.width = 0
        self.height = 0


# =============================================================================
# Gradient rendering
# =============================================================================

def lerp(a, b, t):
    """Linear interpolation between a and b by t."""
    return a + (b - a) * t


def find_segment(stops, t):
    """Find the two stops surrounding parameter t, return (left, right, local_t).

    local_t accounts for the midpoint between the two stops.
    """
    if not stops:
        return None, None, 0.0

    # Clamp t
    t = max(0.0, min(1.0, t))

    # Find surrounding stops
    left = stops[0]
    right = stops[-1]

    for i in range(len(stops) - 1):
        if stops[i].position <= t <= stops[i + 1].position:
            left = stops[i]
            right = stops[i + 1]
            break
    else:
        # t is beyond last stop
        if t <= stops[0].position:
            return stops[0], stops[0], 0.0
        if t >= stops[-1].position:
            return stops[-1], stops[-1], 1.0

    # Calculate local t within this segment
    span = right.position - left.position
    if span <= 0.0:
        local_t = 0.0
    else:
        local_t = (t - left.position) / span

    # Apply midpoint: remap local_t so that 0.5 maps to the midpoint position
    midpoint = left.midpoint / 100.0  # normalize to 0..1
    midpoint = max(0.01, min(0.99, midpoint))  # avoid division by zero

    if local_t <= midpoint:
        # Left half: remap [0, midpoint] → [0, 0.5]
        local_t = 0.5 * (local_t / midpoint)
    else:
        # Right half: remap [midpoint, 1] → [0.5, 1]
        local_t = 0.5 + 0.5 * ((local_t - midpoint) / (1.0 - midpoint))

    return left, right, local_t


def render_gradient(grad, width, height):
    """Render a gradient into RGBA pixel data.

    Creates a horizontal ramp of size width×height.
    """
    rgba = bytearray(width * height * 4)

    # Sort stops by position
    color_stops = sorted(grad.color_stops, key=lambda s: s.position)
    trans_stops = sorted(grad.trans_stops, key=lambda s: s.position)

    for x in range(width):
        t = x / max(1, width - 1) if width > 1 else 0.0

        # Evaluate color
        if color_stops:
            left, right, lt = find_segment(color_stops, t)
            r = int(lerp(left.r, right.r, lt) + 0.5)
            g = int(lerp(left.g, right.g, lt) + 0.5)
            b = int(lerp(left.b, right.b, lt) + 0.5)
        else:
            r = g = b = 0

        # Evaluate transparency
        if trans_stops:
            left, right, lt = find_segment(trans_stops, t)
            a = int(lerp(left.a, right.a, lt) + 0.5)
        else:
            a = 255

        r = max(0, min(255, r))
        g = max(0, min(255, g))
        b = max(0, min(255, b))
        a = max(0, min(255, a))

        # Fill the entire column with the same color
        for y in range(height):
            i = (y * width + x) * 4
            rgba[i + 0] = r
            rgba[i + 1] = g
            rgba[i + 2] = b
            rgba[i + 3] = a

    grad.pixels = bytes(rgba)
    grad.width = width
    grad.height = height


# =============================================================================
# GRD version 3 parser (pre-Photoshop 6)
# =============================================================================

def parse_grd_v3(f, num_gradients):
    """Parse GRD version 3 gradient entries."""
    gradients = []

    for grad_idx in range(num_gradients):
        grad = GradientInfo()

        # Gradient name: Pascal string (1-byte length + chars)
        name_len = struct.unpack('B', f.read(1))[0]
        if name_len > 0:
            grad.name = f.read(name_len).decode('ascii', errors='replace')
        else:
            grad.name = f'Gradient {grad_idx + 1}'

        # Number of color stops
        num_color_stops = struct.unpack('>H', f.read(2))[0]

        for _ in range(num_color_stops):
            stop = ColorStop()

            # Offset [0:4096] → normalize to [0:1]
            offset = struct.unpack('>I', f.read(4))[0]
            stop.position = offset / 4096.0

            # Midpoint (%)
            midpoint = struct.unpack('>I', f.read(4))[0]
            stop.midpoint = float(midpoint)

            # Color model
            color_model = struct.unpack('>H', f.read(2))[0]

            # Color values: 4 × int16
            c1, c2, c3, c4 = struct.unpack('>HHHH', f.read(8))

            if color_model == 0:  # RGB
                # Values are 0-255 range (stored in int16)
                stop.r = c1 & 0xFF
                stop.g = c2 & 0xFF
                stop.b = c3 & 0xFF
            elif color_model == 8:  # Grayscale
                # c1 = gray value * 39.0625 (10000/256)
                gray = int(c1 / 39.0625 + 0.5)
                gray = max(0, min(255, gray))
                stop.r = stop.g = stop.b = gray
            elif color_model == 1:  # HSV
                # H: 0-65535 → 0-360, S: 0-65535 → 0-1, V: 0-65535 → 0-1
                h = c1 / 65535.0 * 360.0
                s = c2 / 65535.0
                v = c3 / 65535.0
                stop.r, stop.g, stop.b = hsv_to_rgb(h, s, v)
            elif color_model == 2:  # CMYK
                c_val = c1 / 65535.0
                m_val = c2 / 65535.0
                y_val = c3 / 65535.0
                k_val = c4 / 65535.0
                stop.r, stop.g, stop.b = cmyk_to_rgb(c_val, m_val, y_val, k_val)
            elif color_model == 7:  # Lab
                L = c1 / 100.0
                a_ch = (c2 - 128)
                b_ch = (c3 - 128)
                stop.r, stop.g, stop.b = lab_to_rgb(L * 100, a_ch, b_ch)
            else:
                # Unknown model, try treating as RGB
                stop.r = c1 & 0xFF
                stop.g = c2 & 0xFF
                stop.b = c3 & 0xFF

            stop.a = 255

            # Color type: 0=user, 1=foreground, 2=background
            color_type = struct.unpack('>H', f.read(2))[0]
            if color_type == 1:  # foreground → black
                stop.r = stop.g = stop.b = 0
                stop.stop_type = GRAD_STOP_FG
            elif color_type == 2:  # background → white
                stop.r = stop.g = stop.b = 255
                stop.stop_type = GRAD_STOP_BG

            grad.color_stops.append(stop)

        # Number of transparency stops
        num_trans_stops = struct.unpack('>H', f.read(2))[0]

        for _ in range(num_trans_stops):
            stop = ColorStop()

            # Offset [0:4096]
            offset = struct.unpack('>I', f.read(4))[0]
            stop.position = offset / 4096.0

            # Midpoint (%)
            midpoint = struct.unpack('>I', f.read(4))[0]
            stop.midpoint = float(midpoint)

            # Opacity [0:255]
            opacity = struct.unpack('>H', f.read(2))[0]
            stop.a = max(0, min(255, opacity))

            grad.trans_stops.append(stop)

        # Reserved 6 bytes
        f.read(6)

        gradients.append(grad)

    return gradients


# =============================================================================
# GRD version 5 parser (Photoshop 6+) — Adobe Descriptor format
# =============================================================================

def read_unicode_string(f):
    """Read a Unicode string: int32 length (in chars) + UTF-16BE data."""
    length = struct.unpack('>I', f.read(4))[0]
    if length == 0:
        return ''
    raw = f.read(length * 2)
    try:
        return raw.decode('utf-16-be').rstrip('\x00')
    except UnicodeDecodeError:
        return raw.hex()


def read_key(f):
    """Read a key/classID: int32 length (0 means 4 chars) + ASCII."""
    length = struct.unpack('>I', f.read(4))[0]
    if length == 0:
        length = 4
    return f.read(length).decode('ascii', errors='replace')


def read_descriptor(f):
    """Read an Adobe descriptor and return as a dict."""
    # Class name (Unicode) + class ID
    _class_name = read_unicode_string(f)
    _class_id = read_key(f)

    num_items = struct.unpack('>I', f.read(4))[0]

    result = {'__class__': _class_id}
    for _ in range(num_items):
        key = read_key(f)
        value = read_descriptor_item(f)
        result[key] = value

    return result


def read_descriptor_item(f):
    """Read a single descriptor item (type tag + value)."""
    type_tag = f.read(4).decode('ascii', errors='replace')

    if type_tag == 'obj ':  # Reference
        return read_reference(f)
    elif type_tag == 'Objc' or type_tag == 'GlbO':  # Descriptor / Global object
        return read_descriptor(f)
    elif type_tag == 'VlLs':  # List
        return read_list(f)
    elif type_tag == 'doub':  # Double
        return struct.unpack('>d', f.read(8))[0]
    elif type_tag == 'UntF':  # Unit float
        unit = f.read(4).decode('ascii', errors='replace')
        value = struct.unpack('>d', f.read(8))[0]
        return {'unit': unit, 'value': value}
    elif type_tag == 'TEXT':  # Unicode string
        return read_unicode_string(f)
    elif type_tag == 'enum':  # Enumerated
        type_id = read_key(f)
        enum_val = read_key(f)
        return {'type': type_id, 'value': enum_val}
    elif type_tag == 'long':  # Integer
        return struct.unpack('>i', f.read(4))[0]
    elif type_tag == 'comp':  # Large Integer (int64)
        return struct.unpack('>q', f.read(8))[0]
    elif type_tag == 'bool':  # Boolean
        return struct.unpack('B', f.read(1))[0] != 0
    elif type_tag == 'type' or type_tag == 'GlbC':  # Class
        _name = read_unicode_string(f)
        _id = read_key(f)
        return {'class_name': _name, 'class_id': _id}
    elif type_tag == 'alis':  # Alias (data)
        length = struct.unpack('>I', f.read(4))[0]
        return f.read(length)
    elif type_tag == 'tdta':  # Raw data
        length = struct.unpack('>I', f.read(4))[0]
        return f.read(length)
    else:
        raise ValueError(f"Unknown descriptor type tag: '{type_tag}' at offset 0x{f.tell()-4:X}")


def read_list(f):
    """Read a VlLs (value list)."""
    count = struct.unpack('>I', f.read(4))[0]
    items = []
    for _ in range(count):
        items.append(read_descriptor_item(f))
    return items


def read_reference(f):
    """Read an obj (reference) — skip over it."""
    count = struct.unpack('>I', f.read(4))[0]
    for _ in range(count):
        ref_type = f.read(4).decode('ascii', errors='replace')
        if ref_type == 'prop':  # Property
            _name = read_unicode_string(f)
            _id = read_key(f)
            _key = read_key(f)
        elif ref_type == 'Clss':  # Class
            _name = read_unicode_string(f)
            _id = read_key(f)
        elif ref_type == 'Enmr':  # Enum
            _name = read_unicode_string(f)
            _id = read_key(f)
            _type = read_key(f)
            _val = read_key(f)
        elif ref_type == 'rele':  # Offset
            _name = read_unicode_string(f)
            _id = read_key(f)
            _offset = struct.unpack('>I', f.read(4))[0]
        elif ref_type == 'Idnt':  # Identifier
            struct.unpack('>I', f.read(4))
        elif ref_type == 'indx':  # Index
            struct.unpack('>I', f.read(4))
        elif ref_type == 'name':  # Name
            _name = read_unicode_string(f)
            _id = read_key(f)
            _val = read_unicode_string(f)
    return {'__ref__': True}


def extract_gradients_from_descriptor(desc):
    """Walk the parsed descriptor tree and extract gradient definitions."""
    gradients = []

    # Look for GrdL (gradient list) key
    grad_list = desc.get('GrdL', [])
    if not isinstance(grad_list, list):
        grad_list = [grad_list]

    for item in grad_list:
        if not isinstance(item, dict):
            continue

        # Each item should be a Grdn descriptor
        # The gradient definition is either the item itself or in 'Grad'
        grad_desc = item.get('Grad', item)
        if not isinstance(grad_desc, dict):
            continue

        grad = GradientInfo()
        grad.name = ''

        # Get name
        if 'Nm  ' in item:
            grad.name = item['Nm  ']
        elif 'Nm  ' in grad_desc:
            grad.name = grad_desc['Nm  ']

        # Determine gradient type
        grad_form = grad_desc.get('GrdF', {})
        if isinstance(grad_form, dict):
            grad_type = grad_form.get('value', 'CstS')
        else:
            grad_type = 'CstS'

        if grad_type == 'ClNs':
            # Noise gradient — we can't easily render these with simple stops
            # Generate a simple placeholder
            grad.name = grad.name or 'Noise Gradient'
            grad.color_stops = [
                ColorStop(0.0, 128, 128, 128, 255, 50),
                ColorStop(1.0, 128, 128, 128, 255, 50),
            ]
            grad.trans_stops = [
                ColorStop(0.0, a=255, midpoint=50),
                ColorStop(1.0, a=255, midpoint=50),
            ]
            gradients.append(grad)
            continue

        # Solid gradient (CstS) — parse color stops
        color_list = grad_desc.get('Clrs', [])
        if not isinstance(color_list, list):
            color_list = [color_list]

        for cs in color_list:
            if not isinstance(cs, dict):
                continue

            stop = ColorStop()

            # Location [0:4096] → [0:1]
            lctn = cs.get('Lctn', 0)
            stop.position = lctn / 4096.0

            # Midpoint (%)
            mdpn = cs.get('Mdpn', 50)
            stop.midpoint = float(mdpn)

            # Color type
            type_info = cs.get('Type', {})
            if isinstance(type_info, dict):
                color_type = type_info.get('value', 'UsrS')
            else:
                color_type = 'UsrS'

            if color_type == 'FrgC':
                stop.r = stop.g = stop.b = 0
                stop.a = 255
                stop.stop_type = GRAD_STOP_FG
            elif color_type == 'BckC':
                stop.r = stop.g = stop.b = 255
                stop.a = 255
                stop.stop_type = GRAD_STOP_BG
            else:
                # User color — parse from Clr descriptor
                clr = cs.get('Clr ', {})
                if isinstance(clr, dict):
                    clr_class = clr.get('__class__', '')
                    if clr_class == 'RGBC':
                        stop.r = int(clr.get('Rd  ', 0) + 0.5)
                        stop.g = int(clr.get('Grn ', 0) + 0.5)
                        stop.b = int(clr.get('Bl  ', 0) + 0.5)
                    elif clr_class == 'HSBC':
                        h_info = clr.get('H   ', {})
                        h = h_info.get('value', 0) if isinstance(h_info, dict) else float(h_info)
                        s = clr.get('Strt', 0) / 100.0
                        v = clr.get('Brgh', 0) / 100.0
                        stop.r, stop.g, stop.b = hsv_to_rgb(h, s, v)
                    elif clr_class == 'CMYC':
                        c_val = clr.get('Cyn ', 0) / 100.0
                        m_val = clr.get('Mgnt', 0) / 100.0
                        y_val = clr.get('Ylw ', 0) / 100.0
                        k_val = clr.get('Blck', 0) / 100.0
                        stop.r, stop.g, stop.b = cmyk_to_rgb(c_val, m_val, y_val, k_val)
                    elif clr_class == 'LbCl':
                        L = clr.get('Lmnc', 0)
                        a_ch = clr.get('A   ', 0)
                        b_ch = clr.get('B   ', 0)
                        stop.r, stop.g, stop.b = lab_to_rgb(L, a_ch, b_ch)
                    elif clr_class == 'Grsc':
                        gray = clr.get('Gry ', 0)
                        v = int(gray / 100.0 * 255 + 0.5)
                        v = max(0, min(255, v))
                        stop.r = stop.g = stop.b = v
                    elif clr_class == 'BkCl':
                        # Book/spot color — fall back to black
                        stop.r = stop.g = stop.b = 0
                    else:
                        stop.r = stop.g = stop.b = 0

                stop.r = max(0, min(255, stop.r))
                stop.g = max(0, min(255, stop.g))
                stop.b = max(0, min(255, stop.b))
                stop.a = 255

            grad.color_stops.append(stop)

        # Transparency stops
        trans_list = grad_desc.get('Trns', [])
        if not isinstance(trans_list, list):
            trans_list = [trans_list]

        for ts in trans_list:
            if not isinstance(ts, dict):
                continue

            stop = ColorStop()

            lctn = ts.get('Lctn', 0)
            stop.position = lctn / 4096.0

            mdpn = ts.get('Mdpn', 50)
            stop.midpoint = float(mdpn)

            opct = ts.get('Opct', {})
            if isinstance(opct, dict):
                stop.a = int(opct.get('value', 100) / 100.0 * 255 + 0.5)
            elif isinstance(opct, (int, float)):
                stop.a = int(opct / 100.0 * 255 + 0.5)
            else:
                stop.a = 255

            stop.a = max(0, min(255, stop.a))
            grad.trans_stops.append(stop)

        if grad.color_stops:
            gradients.append(grad)

    return gradients


def parse_grd_v5(f):
    """Parse GRD version 5 (Photoshop 6+)."""
    # Skip 4 bytes after version (always 00 00 00 10)
    f.read(4)

    try:
        desc = read_descriptor(f)
    except (struct.error, ValueError, UnicodeDecodeError) as e:
        print(f"  [!] Error parsing v5 descriptor: {e}")
        return []

    return extract_gradients_from_descriptor(desc)


# =============================================================================
# GRD file parser (entry point)
# =============================================================================

def parse_grd_file(filepath):
    """Parse a Photoshop .grd gradient file."""
    with open(filepath, 'rb') as f:
        file_size = os.fstat(f.fileno()).st_size

        # File signature: 8BGR (4 bytes)
        magic = f.read(4)
        if magic != b'8BGR':
            raise ValueError(f"Not a Photoshop .grd file (magic: {magic!r})")

        # Version: int16
        version = struct.unpack('>H', f.read(2))[0]

        print(f"File: {os.path.basename(filepath)}")
        print(f"Version: {version}")
        print(f"File size: {file_size:,} bytes")
        print()

        if version == 3:
            num_gradients = struct.unpack('>H', f.read(2))[0]
            print(f"Gradients: {num_gradients}")
            return parse_grd_v3(f, num_gradients)

        elif version == 5:
            return parse_grd_v5(f)

        else:
            raise ValueError(f"Unsupported .grd version: {version}")


# =============================================================================
# GIMP .ggr gradient parser
# =============================================================================

def parse_ggr_file(filepath):
    """Parse a GIMP .ggr gradient file.

    GGR format:
        Line 1: "GIMP Gradient"
        Line 2: "Name: <name>"
        Line 3: <number_of_segments>
        Lines 4+: <left_pos> <left_r> <left_g> <left_b> <left_a>
                  <mid_pos> <right_r> <right_g> <right_b> <right_a>
                  <blend_type> <color_type> [<left_color_type> <right_color_type>]
    """
    gradients = []

    with open(filepath, 'r', encoding='utf-8', errors='replace') as f:
        lines = f.readlines()

    if not lines or lines[0].strip() != 'GIMP Gradient':
        raise ValueError("Not a GIMP gradient file (missing header)")

    grad = GradientInfo()

    # Name
    if len(lines) > 1 and lines[1].strip().startswith('Name:'):
        grad.name = lines[1].strip()[5:].strip()
    else:
        grad.name = Path(filepath).stem

    # Number of segments
    if len(lines) < 3:
        raise ValueError("Malformed GGR file: missing segment count")

    num_segments = int(lines[2].strip())

    # Parse segments into color stops
    # GGR uses segments (left endpoint to right endpoint)
    # We collect unique endpoints as stops
    seen_positions = {}

    for i in range(num_segments):
        if 3 + i >= len(lines):
            break

        parts = lines[3 + i].strip().split()
        if len(parts) < 13:
            continue

        left_pos = float(parts[0])
        mid_pos = float(parts[1])
        right_pos = float(parts[2])

        left_r = int(float(parts[3]) * 255 + 0.5)
        left_g = int(float(parts[4]) * 255 + 0.5)
        left_b = int(float(parts[5]) * 255 + 0.5)
        left_a = int(float(parts[6]) * 255 + 0.5)

        right_r = int(float(parts[7]) * 255 + 0.5)
        right_g = int(float(parts[8]) * 255 + 0.5)
        right_b = int(float(parts[9]) * 255 + 0.5)
        right_a = int(float(parts[10]) * 255 + 0.5)

        # blend_type: 0=linear, 1=curved, 2=sinusoidal, 3=spherical_inc, 4=spherical_dec
        # color_type: 0=RGB, 1=HSV_CCW, 2=HSV_CW, 3=segment (Gimp 2.10+)
        # We only support linear/RGB for now; the others still produce usable results

        # Midpoint as percentage of the segment
        seg_span = right_pos - left_pos
        if seg_span > 0:
            midpoint_pct = ((mid_pos - left_pos) / seg_span) * 100.0
        else:
            midpoint_pct = 50.0

        # Add left endpoint
        left_key = f"{left_pos:.6f}"
        if left_key not in seen_positions:
            color_stop = ColorStop(left_pos, left_r, left_g, left_b, 255, midpoint_pct)
            grad.color_stops.append(color_stop)

            trans_stop = ColorStop(left_pos, a=left_a, midpoint=midpoint_pct)
            grad.trans_stops.append(trans_stop)

            seen_positions[left_key] = True

        # Add right endpoint (will be deduplicated if segments share an edge)
        right_key = f"{right_pos:.6f}"
        if right_key not in seen_positions:
            color_stop = ColorStop(right_pos, right_r, right_g, right_b, 255, 50.0)
            grad.color_stops.append(color_stop)

            trans_stop = ColorStop(right_pos, a=right_a, midpoint=50.0)
            grad.trans_stops.append(trans_stop)

            seen_positions[right_key] = True

    if grad.color_stops:
        gradients.append(grad)

    print(f"File: {os.path.basename(filepath)}")
    print(f"Format: GIMP Gradient (.ggr)")
    print(f"Segments: {num_segments}")
    print()

    return gradients


# =============================================================================
# Color space conversions
# =============================================================================

def hsv_to_rgb(h, s, v):
    """Convert HSV (h: 0-360, s: 0-1, v: 0-1) to RGB (0-255 each)."""
    h = h % 360.0
    c = v * s
    x = c * (1.0 - abs((h / 60.0) % 2.0 - 1.0))
    m = v - c

    if h < 60:
        r, g, b = c, x, 0
    elif h < 120:
        r, g, b = x, c, 0
    elif h < 180:
        r, g, b = 0, c, x
    elif h < 240:
        r, g, b = 0, x, c
    elif h < 300:
        r, g, b = x, 0, c
    else:
        r, g, b = c, 0, x

    return (
        int((r + m) * 255 + 0.5),
        int((g + m) * 255 + 0.5),
        int((b + m) * 255 + 0.5),
    )


def cmyk_to_rgb(c, m, y, k):
    """Convert CMYK (0-1 each) to RGB (0-255 each)."""
    r = int((1.0 - c) * (1.0 - k) * 255 + 0.5)
    g = int((1.0 - m) * (1.0 - k) * 255 + 0.5)
    b = int((1.0 - y) * (1.0 - k) * 255 + 0.5)
    return max(0, min(255, r)), max(0, min(255, g)), max(0, min(255, b))


def lab_to_rgb(L, a, b):
    """Convert CIE Lab to RGB (0-255 each) using D65 illuminant."""
    # Lab → XYZ
    fy = (L + 16.0) / 116.0
    fx = a / 500.0 + fy
    fz = fy - b / 200.0

    eps = 0.008856
    kappa = 903.3

    xr = fx ** 3 if fx ** 3 > eps else (116.0 * fx - 16.0) / kappa
    yr = ((L + 16.0) / 116.0) ** 3 if L > kappa * eps else L / kappa
    zr = fz ** 3 if fz ** 3 > eps else (116.0 * fz - 16.0) / kappa

    # D65 reference white
    X = xr * 0.95047
    Y = yr * 1.00000
    Z = zr * 1.08883

    # XYZ → sRGB (linear)
    rl = 3.2404542 * X - 1.5371385 * Y - 0.4985314 * Z
    gl = -0.9692660 * X + 1.8760108 * Y + 0.0415560 * Z
    bl = 0.0556434 * X - 0.2040259 * Y + 1.0572252 * Z

    # sRGB gamma
    def gamma(v):
        if v <= 0.0031308:
            return 12.92 * v
        return 1.055 * (v ** (1.0 / 2.4)) - 0.055

    r = int(gamma(max(0, rl)) * 255 + 0.5)
    g = int(gamma(max(0, gl)) * 255 + 0.5)
    b_out = int(gamma(max(0, bl)) * 255 + 0.5)

    return max(0, min(255, r)), max(0, min(255, g)), max(0, min(255, b_out))


# =============================================================================
# DSET file writer
# =============================================================================

def write_dset(filepath, gradients, selected=1):
    """Write rendered gradients to a DSET v2 file with grad_defs metadata.

    gradients: list of GradientInfo with .pixels (RGBA), .width, .height
    """
    with open(filepath, 'wb') as f:
        # Header: magic(4) + version(2) + mode(2) + selected(2) = 10 bytes
        f.write(DSET_MAGIC)
        f.write(struct.pack('<h', DSET_VERSION))
        f.write(struct.pack('<h', DSET_MODE_GRADIENT))
        f.write(struct.pack('<h', selected))

        # Write 30 slot images
        for slot_idx in range(DSET_SLOT_COUNT):
            if slot_idx < len(gradients) and gradients[slot_idx].pixels:
                grad = gradients[slot_idx]
                has_image = -1  # TRUE in QB64
                f.write(struct.pack('<h', has_image))
                f.write(struct.pack('<h', grad.width))
                f.write(struct.pack('<h', grad.height))

                # Write pixel data as BGRA (QB64-PE's _UNSIGNED LONG format)
                for y in range(grad.height):
                    for x in range(grad.width):
                        i = (y * grad.width + x) * 4
                        r = grad.pixels[i + 0]
                        g = grad.pixels[i + 1]
                        b = grad.pixels[i + 2]
                        a = grad.pixels[i + 3]
                        # QB64-PE uses ARGB in memory (little-endian → BGRA bytes)
                        pixel = (a << 24) | (r << 16) | (g << 8) | b
                        f.write(struct.pack('<I', pixel))
            else:
                has_image = 0  # FALSE
                f.write(struct.pack('<h', has_image))

        # V2: Write grad_defs metadata for each slot
        for slot_idx in range(DSET_SLOT_COUNT):
            if slot_idx < len(gradients) and gradients[slot_idx].color_stops:
                grad = gradients[slot_idx]
                uses_fg = any(s.stop_type == GRAD_STOP_FG for s in grad.color_stops)
                uses_bg = any(s.stop_type == GRAD_STOP_BG for s in grad.color_stops)
                color_count = min(len(grad.color_stops), GRADIENT_MAX_STOPS)
                opacity_count = min(len(grad.trans_stops), GRADIENT_MAX_STOPS)
                # Encode gradient name as 32-byte fixed string
                name_bytes = grad.name[:32].encode('ascii', errors='replace')
                name_bytes = name_bytes.ljust(32, b'\x00')
            else:
                uses_fg = False
                uses_bg = False
                color_count = 0
                opacity_count = 0
                name_bytes = b'\x00' * 32

            # family: GRADIENT_FAMILY_HORIZONTAL = 1
            f.write(struct.pack('<h', 1))
            f.write(struct.pack('<h', color_count))
            f.write(struct.pack('<h', opacity_count))
            f.write(struct.pack('<h', -1 if uses_fg else 0))  # QB64 TRUE=-1
            f.write(struct.pack('<h', -1 if uses_bg else 0))
            f.write(name_bytes)
            f.write(struct.pack('<h', -1))    # ditherMode = DITHER_NONE
            f.write(struct.pack('<f', 0.5))   # ditherStrength

            # Color stops (16 slots)
            if slot_idx < len(gradients) and gradients[slot_idx].color_stops:
                grad = gradients[slot_idx]
                for j in range(GRADIENT_MAX_STOPS):
                    if j < len(grad.color_stops):
                        s = grad.color_stops[j]
                        f.write(struct.pack('<f', s.position))
                        pixel = (s.a << 24) | (s.r << 16) | (s.g << 8) | s.b
                        f.write(struct.pack('<I', pixel))
                    else:
                        f.write(struct.pack('<f', 0.0))
                        f.write(struct.pack('<I', 0))
            else:
                for j in range(GRADIENT_MAX_STOPS):
                    f.write(struct.pack('<f', 0.0))
                    f.write(struct.pack('<I', 0))

            # Opacity stops (16 slots)
            if slot_idx < len(gradients) and gradients[slot_idx].trans_stops:
                grad = gradients[slot_idx]
                for j in range(GRADIENT_MAX_STOPS):
                    if j < len(grad.trans_stops):
                        s = grad.trans_stops[j]
                        f.write(struct.pack('<f', s.position))
                        f.write(struct.pack('<h', s.a))
                    else:
                        f.write(struct.pack('<f', 0.0))
                        f.write(struct.pack('<h', 255))
            else:
                for j in range(GRADIENT_MAX_STOPS):
                    f.write(struct.pack('<f', 0.0))
                    f.write(struct.pack('<h', 255))

            # Stop types (16 slots)
            if slot_idx < len(gradients) and gradients[slot_idx].color_stops:
                grad = gradients[slot_idx]
                for j in range(GRADIENT_MAX_STOPS):
                    if j < len(grad.color_stops):
                        f.write(struct.pack('<h', grad.color_stops[j].stop_type))
                    else:
                        f.write(struct.pack('<h', GRAD_STOP_USER))
            else:
                for j in range(GRADIENT_MAX_STOPS):
                    f.write(struct.pack('<h', GRAD_STOP_USER))


# =============================================================================
# PNG export (optional)
# =============================================================================

def export_png(grad, filepath):
    """Export a gradient ramp as a PNG file using Pillow."""
    if not HAS_PIL or not grad.pixels:
        return False
    img = Image.frombytes('RGBA', (grad.width, grad.height), grad.pixels)
    img.save(filepath, 'PNG')
    return True


# =============================================================================
# Main
# =============================================================================

def main():
    parser = argparse.ArgumentParser(
        description='Convert Photoshop .grd / GIMP .ggr gradient files to DRAW .dset files.'
    )
    parser.add_argument('input', help='Input .grd or .ggr file')
    parser.add_argument('-o', '--output-dir', default=None,
                        help='Output directory for .dset files (default: same as input)')
    parser.add_argument('-l', '--list', action='store_true',
                        help='List gradients only (no conversion)')
    parser.add_argument('--png', default=None, metavar='DIR',
                        help='Export individual gradients as PNG files')
    parser.add_argument('--width', type=int, default=256,
                        help='Ramp image width in pixels (default: 256)')
    parser.add_argument('--height', type=int, default=1,
                        help='Ramp image height in pixels (default: 1)')

    args = parser.parse_args()

    if not os.path.isfile(args.input):
        print(f"Error: File not found: {args.input}")
        sys.exit(1)

    ext = Path(args.input).suffix.lower()

    print("=" * 60)
    print("Gradient → DRAW .dset Converter")
    print("=" * 60)
    print()

    # Parse input file
    if ext == '.ggr':
        gradients = parse_ggr_file(args.input)
    elif ext == '.grd':
        gradients = parse_grd_file(args.input)
    else:
        print(f"Error: Unsupported file extension '{ext}'")
        print("Supported: .grd (Photoshop), .ggr (GIMP)")
        sys.exit(1)

    if not gradients:
        print("No gradients found or parsed successfully.")
        sys.exit(1)

    # Print gradient list
    print(f"\nParsed {len(gradients)} gradient(s):")
    print("-" * 60)
    for i, grad in enumerate(gradients):
        nc = len(grad.color_stops)
        nt = len(grad.trans_stops)

        # Show first and last color for quick reference
        if grad.color_stops:
            first = grad.color_stops[0]
            last = grad.color_stops[-1]
            preview = (f"#{first.r:02X}{first.g:02X}{first.b:02X}"
                       f" → #{last.r:02X}{last.g:02X}{last.b:02X}")
        else:
            preview = "(no stops)"

        print(f"  {i + 1:3d}. {grad.name:40s} "
              f"C:{nc:2d} T:{nt:2d}  {preview}")
    print("-" * 60)

    if args.list:
        sys.exit(0)

    # Render all gradients
    ramp_w = max(2, args.width)
    ramp_h = max(1, args.height)
    print(f"\nRendering at {ramp_w}×{ramp_h} pixels...")

    for grad in gradients:
        render_gradient(grad, ramp_w, ramp_h)

    # Export PNGs if requested
    if args.png:
        png_dir = args.png
        os.makedirs(png_dir, exist_ok=True)
        exported = 0
        for i, grad in enumerate(gradients):
            safe_name = "".join(c if c.isalnum() or c in ' -_' else '_' for c in grad.name)
            if not safe_name:
                safe_name = f"gradient_{i+1}"
            png_path = os.path.join(png_dir, f"{i + 1:03d}_{safe_name}.png")
            if export_png(grad, png_path):
                print(f"  PNG: {png_path}")
                exported += 1
        print(f"Exported {exported} PNG files to {png_dir}")

    # Determine output directory
    if args.output_dir:
        out_dir = args.output_dir
    else:
        out_dir = os.path.dirname(os.path.abspath(args.input))
    os.makedirs(out_dir, exist_ok=True)

    # Split gradients into groups of DSET_SLOT_COUNT (30)
    base_name = Path(args.input).stem
    num_sets = (len(gradients) + DSET_SLOT_COUNT - 1) // DSET_SLOT_COUNT

    for set_idx in range(num_sets):
        start = set_idx * DSET_SLOT_COUNT
        end = min(start + DSET_SLOT_COUNT, len(gradients))
        batch = gradients[start:end]

        if num_sets == 1:
            dset_name = f"{base_name}.dset"
        else:
            dset_name = f"{base_name}{set_idx + 1}.dset"

        dset_path = os.path.join(out_dir, dset_name)
        write_dset(dset_path, batch)
        print(f"\n  DSET: {dset_path}")
        print(f"        {len(batch)} gradient(s), {ramp_w}×{ramp_h}px")

    print(f"\nDone! Created {num_sets} .dset file(s)")


if __name__ == '__main__':
    main()
