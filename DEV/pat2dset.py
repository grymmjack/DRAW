#!/usr/bin/env python3
"""
pat2dset.py - Convert Photoshop .pat pattern files to DRAW .dset files.

Parses Adobe Photoshop Pattern (.pat) files and converts them to DRAW's
.dset format for use as patterns, brushes, or gradients.

Usage:
    python3 pat2dset.py <input.pat> [options]

Options:
    -o DIR          Output directory for .dset files (default: same as input)
    -m MODE         DSET mode: pattern (default), brush, gradient
    -l              List patterns only (don't convert)
    --png DIR       Also export individual patterns as PNG files
    --max-size N    Skip patterns larger than NxN pixels (default: 256)
    --desaturate    Convert to grayscale (preserving alpha)

Reference: https://www.selapa.net/swatches/patterns/fileformats.php
"""

import struct
import sys
import os
import argparse
from pathlib import Path

# Try to import PIL for PNG export
try:
    from PIL import Image
    HAS_PIL = True
except ImportError:
    HAS_PIL = False


# =============================================================================
# Photoshop .pat format constants
# =============================================================================

PAT_MAGIC = b'8BPT'
PAT_VERSION = 1

# Color models
COLOR_MODELS = {
    0: 'Bitmap (B/W)',
    1: 'Grayscale',
    2: 'Indexed',
    3: 'RGB',
    4: 'CMYK',
    5: 'HSL',
    6: 'HSB',
    7: 'Multichannel',
    8: 'Duotone',
    9: 'Lab',
    10: 'Gray16',
    11: 'RGB48',
}

# DSET constants
DSET_MAGIC = b'DST1'
DSET_VERSION = 1
DSET_MODE_BRUSH = 1
DSET_MODE_PATTERN = 2
DSET_MODE_GRADIENT = 3
DSET_SLOT_COUNT = 30


# =============================================================================
# RLE (PackBits) decompression
# =============================================================================

def unpackbits(data, expected_bytes):
    """Decompress PackBits/RLE compressed data."""
    result = bytearray()
    i = 0
    while i < len(data) and len(result) < expected_bytes:
        n = data[i]
        i += 1
        if n >= 128:
            # Run: repeat next byte (257 - n) times
            count = 257 - n
            if i < len(data):
                result.extend([data[i]] * count)
                i += 1
        elif n < 128:
            # Literal: copy next (n + 1) bytes
            count = n + 1
            result.extend(data[i:i + count])
            i += count
        # n == 128: no-op (skip)
    return bytes(result[:expected_bytes])


# =============================================================================
# .pat file parser
# =============================================================================

class PatternInfo:
    """Holds parsed pattern data."""
    def __init__(self):
        self.name = ''
        self.pat_id = ''
        self.color_model = 0
        self.width = 0
        self.height = 0
        self.pixels = None  # RGBA pixel data as bytes (width * height * 4)


def read_utf16be_string(f, char_count):
    """Read a UTF-16BE string of char_count characters (including null)."""
    raw = f.read(char_count * 2)
    # Decode as UTF-16 big-endian, strip null terminators
    try:
        text = raw.decode('utf-16-be').rstrip('\x00')
    except UnicodeDecodeError:
        text = raw.hex()
    return text


def read_pascal_string(f):
    """Read a Pascal string (1-byte length prefix + ASCII chars)."""
    length = struct.unpack('B', f.read(1))[0]
    if length == 0:
        return ''
    data = f.read(length)
    return data.decode('ascii', errors='replace')


def parse_channel_record(f, width, height, vmal_end):
    """Parse a single channel record from the VMAL block.

    Returns (is_used, channel_data) where channel_data is bytes or None.
    is_used indicates whether this channel slot contained actual pixel data.
    """
    if f.tell() + 4 > vmal_end:
        return False, None

    is_used = struct.unpack('>I', f.read(4))[0]
    if is_used == 0:
        return False, None

    # Channel data size (int32) - total bytes for the rest of the channel
    chan_size = struct.unpack('>I', f.read(4))[0]
    chan_start = f.tell()

    # Depth (int32) - bits per sample for this channel
    depth = struct.unpack('>I', f.read(4))[0]

    # Channel rectangle: top, left, bottom, right
    ch_top, ch_left, ch_bottom, ch_right = struct.unpack('>iiii', f.read(16))
    ch_width = ch_right - ch_left
    ch_height = ch_bottom - ch_top

    # Depth again (int16)
    depth16 = struct.unpack('>H', f.read(2))[0]

    # Compression type (int8): 0=raw, 1=RLE
    compression = struct.unpack('B', f.read(1))[0]

    bytes_per_sample = max(1, depth16 // 8) if depth16 > 0 else 1
    expected_bytes = ch_width * ch_height * bytes_per_sample

    if compression == 0:
        pixel_data = f.read(expected_bytes)
    elif compression == 1:
        remaining = chan_size - (f.tell() - chan_start)
        compressed = f.read(remaining)
        pixel_data = unpackbits(compressed, expected_bytes)
    else:
        remaining = chan_size - (f.tell() - chan_start)
        f.read(remaining)
        pixel_data = bytes(expected_bytes)

    # Seek to end of channel data block
    f.seek(chan_start + chan_size)

    # For 16-bit channels, downsample to 8-bit
    if bytes_per_sample == 2 and len(pixel_data) >= expected_bytes:
        downsampled = bytearray(ch_width * ch_height)
        for i in range(ch_width * ch_height):
            hi = pixel_data[i * 2]
            downsampled[i] = hi  # Take high byte of 16-bit value
        pixel_data = bytes(downsampled)

    # If channel dimensions match pattern, return directly
    if ch_width == width and ch_height == height:
        return True, pixel_data

    # Place channel data into full-size buffer at the correct offset
    result = bytearray(width * height)
    for y in range(ch_height):
        for x in range(ch_width):
            dx = x + ch_left
            dy = y + ch_top
            if 0 <= dx < width and 0 <= dy < height:
                src_idx = y * ch_width + x
                dst_idx = dy * width + dx
                if src_idx < len(pixel_data):
                    result[dst_idx] = pixel_data[src_idx]
    return True, bytes(result)


def parse_vmal_data(f, vmal_size, color_model, pat_width, pat_height):
    """Parse the Virtual Memory Array List (VMAL) image data block.

    The VMAL block contains:
    1. Rectangle (16 bytes): top, left, bottom, right
    2. Number of channel slots (int32) - includes unused virtual slots
    3. N channel slot records (each starts with is_used int32)
    4. 4-byte separator (always 0)
    5. Alpha channel record (same structure as color channels)

    Returns (RGBA pixel data, width, height).
    """
    vmal_start = f.tell()
    vmal_end = vmal_start + vmal_size

    # Rectangle: top, left, bottom, right
    rect_top, rect_left, rect_bottom, rect_right = struct.unpack('>iiii', f.read(16))
    img_width = rect_right - rect_left
    img_height = rect_bottom - rect_top

    width = img_width if img_width > 0 else pat_width
    height = img_height if img_height > 0 else pat_height

    if width <= 0 or height <= 0:
        f.seek(vmal_end)
        return None, 0, 0

    # Number of virtual channel slots (int32)
    # This is the total number of channel slots allocated, including unused ones
    num_channel_slots = struct.unpack('>I', f.read(4))[0]

    # Determine expected color channels based on color model
    if color_model in (0, 1, 2):  # Bitmap, Grayscale, Indexed
        expected_color_channels = 1
    elif color_model == 3:  # RGB
        expected_color_channels = 3
    elif color_model == 4:  # CMYK
        expected_color_channels = 4
    elif color_model == 9:  # Lab
        expected_color_channels = 3
    else:
        expected_color_channels = 3

    # Parse all channel slots - collect only the ones with actual data
    used_channels = []
    for slot_idx in range(num_channel_slots):
        if f.tell() >= vmal_end:
            break
        is_used, chan_data = parse_channel_record(f, width, height, vmal_end)
        if is_used and chan_data is not None:
            used_channels.append(chan_data)

    # After the channel slots: 4-byte separator (always 0)
    alpha_data = None
    if f.tell() + 4 <= vmal_end:
        separator = f.read(4)  # should be 0x00000000

        # Alpha channel follows the separator
        if f.tell() < vmal_end:
            is_used, alpha_chan = parse_channel_record(f, width, height, vmal_end)
            if is_used and alpha_chan is not None:
                alpha_data = alpha_chan

    # Skip any remaining data
    f.seek(vmal_end)

    # Assemble RGBA pixel data from used_channels + alpha_data
    channels = used_channels
    num_pixels = width * height
    rgba = bytearray(num_pixels * 4)

    if color_model == 3:  # RGB
        r_data = channels[0] if len(channels) > 0 else bytes(num_pixels)
        g_data = channels[1] if len(channels) > 1 else bytes(num_pixels)
        b_data = channels[2] if len(channels) > 2 else bytes(num_pixels)
        a_data = alpha_data if alpha_data else bytes([255] * num_pixels)

        for i in range(num_pixels):
            rgba[i * 4 + 0] = r_data[i] if i < len(r_data) else 0
            rgba[i * 4 + 1] = g_data[i] if i < len(g_data) else 0
            rgba[i * 4 + 2] = b_data[i] if i < len(b_data) else 0
            rgba[i * 4 + 3] = a_data[i] if i < len(a_data) else 255

    elif color_model == 1:  # Grayscale
        g_data = channels[0] if len(channels) > 0 else bytes(num_pixels)
        a_data = alpha_data if alpha_data else bytes([255] * num_pixels)

        for i in range(num_pixels):
            v = g_data[i] if i < len(g_data) else 0
            rgba[i * 4 + 0] = v
            rgba[i * 4 + 1] = v
            rgba[i * 4 + 2] = v
            rgba[i * 4 + 3] = a_data[i] if i < len(a_data) else 255

    elif color_model == 2:  # Indexed - would need palette, treat as grayscale
        idx_data = channels[0] if len(channels) > 0 else bytes(num_pixels)
        a_data = alpha_data if alpha_data else bytes([255] * num_pixels)

        for i in range(num_pixels):
            v = idx_data[i] if i < len(idx_data) else 0
            rgba[i * 4 + 0] = v
            rgba[i * 4 + 1] = v
            rgba[i * 4 + 2] = v
            rgba[i * 4 + 3] = a_data[i] if i < len(a_data) else 255

    elif color_model == 0:  # Bitmap (B/W)
        bw_data = channels[0] if len(channels) > 0 else bytes(num_pixels)
        for i in range(num_pixels):
            v = 255 if (bw_data[i] if i < len(bw_data) else 0) == 0 else 0
            rgba[i * 4 + 0] = v
            rgba[i * 4 + 1] = v
            rgba[i * 4 + 2] = v
            rgba[i * 4 + 3] = 255

    else:
        # Unsupported color model - try as RGB
        for ch_idx in range(min(3, len(channels))):
            for i in range(num_pixels):
                if i < len(channels[ch_idx]):
                    rgba[i * 4 + ch_idx] = channels[ch_idx][i]
        if alpha_data:
            for i in range(num_pixels):
                rgba[i * 4 + 3] = alpha_data[i] if i < len(alpha_data) else 255
        else:
            for i in range(num_pixels):
                rgba[i * 4 + 3] = 255

    return bytes(rgba), width, height


def parse_pat_file(filepath):
    """Parse a Photoshop .pat file and return a list of PatternInfo objects."""
    patterns = []

    with open(filepath, 'rb') as f:
        file_size = os.fstat(f.fileno()).st_size

        # File header
        magic = f.read(4)
        if magic != PAT_MAGIC:
            raise ValueError(f"Not a Photoshop .pat file (magic: {magic!r})")

        version = struct.unpack('>H', f.read(2))[0]
        if version != PAT_VERSION:
            raise ValueError(f"Unsupported .pat version: {version}")

        num_patterns = struct.unpack('>I', f.read(4))[0]
        print(f"File: {os.path.basename(filepath)}")
        print(f"Patterns: {num_patterns}")
        print(f"File size: {file_size:,} bytes")
        print()

        # Parse each pattern
        for pat_idx in range(num_patterns):
            if f.tell() >= file_size:
                print(f"  [!] Reached end of file at pattern {pat_idx + 1}")
                break

            pat = PatternInfo()
            pat_start = f.tell()

            try:
                # Pattern header
                pat_version = struct.unpack('>I', f.read(4))[0]
                if pat_version != 1:
                    print(f"  [!] Pattern {pat_idx + 1}: unexpected version {pat_version} at offset 0x{pat_start:X}")
                    # Try to recover by scanning forward for valid pattern
                    f.seek(pat_start)
                    if not _scan_for_next_pattern(f, file_size):
                        break
                    continue

                pat.color_model = struct.unpack('>I', f.read(4))[0]
                pat.height, pat.width = struct.unpack('>HH', f.read(4))

                # Pattern name (null-terminated UTF-16BE)
                name_len = struct.unpack('>I', f.read(4))[0]
                pat.name = read_utf16be_string(f, name_len)

                # Pattern ID (Pascal string)
                pat.pat_id = read_pascal_string(f)

                # If indexed color, read palette
                palette = None
                if pat.color_model == 2:
                    palette = f.read(256 * 3)  # RGB palette
                    f.read(4)  # 4 unknown bytes

                # VMAL image data block
                vmal_version = struct.unpack('>I', f.read(4))[0]
                vmal_size = struct.unpack('>I', f.read(4))[0]

                if vmal_version != 3:
                    print(f"  [!] Pattern {pat_idx + 1} '{pat.name}': unexpected VMAL version {vmal_version}")

                # Parse the VMAL data
                rgba, actual_w, actual_h = parse_vmal_data(
                    f, vmal_size, pat.color_model, pat.width, pat.height
                )

                if rgba and actual_w > 0 and actual_h > 0:
                    pat.width = actual_w
                    pat.height = actual_h
                    pat.pixels = rgba

                    # Apply indexed palette if present
                    if palette and pat.color_model == 2:
                        new_rgba = bytearray(len(rgba))
                        for i in range(actual_w * actual_h):
                            idx = rgba[i * 4]  # index is in the red channel
                            if idx * 3 + 2 < len(palette):
                                new_rgba[i * 4 + 0] = palette[idx * 3 + 0]
                                new_rgba[i * 4 + 1] = palette[idx * 3 + 1]
                                new_rgba[i * 4 + 2] = palette[idx * 3 + 2]
                            new_rgba[i * 4 + 3] = rgba[i * 4 + 3]
                        pat.pixels = bytes(new_rgba)

                patterns.append(pat)

            except (struct.error, ValueError, OverflowError) as e:
                print(f"  [!] Error parsing pattern {pat_idx + 1} at offset 0x{f.tell():X}: {e}")
                # Try to recover
                f.seek(pat_start)
                if not _scan_for_next_pattern(f, file_size):
                    break

    return patterns


def _scan_for_next_pattern(f, file_size):
    """Try to find the next pattern by scanning for version=1 followed by valid color model."""
    start = f.tell() + 1
    for offset in range(start, min(start + 10000, file_size - 12)):
        f.seek(offset)
        try:
            v = struct.unpack('>I', f.read(4))[0]
            if v == 1:
                cm = struct.unpack('>I', f.read(4))[0]
                if cm in (0, 1, 2, 3, 4, 7, 9):
                    f.seek(offset)
                    return True
        except struct.error:
            break
    return False


# =============================================================================
# DSET file writer
# =============================================================================

def write_dset(filepath, patterns, mode=DSET_MODE_PATTERN, selected=1):
    """Write patterns to a DSET file.

    patterns: list of PatternInfo with .pixels (RGBA), .width, .height
    mode: DSET_MODE_BRUSH, DSET_MODE_PATTERN, or DSET_MODE_GRADIENT
    """
    with open(filepath, 'wb') as f:
        # Header: magic(4) + version(2) + mode(2) + selected(2) = 10 bytes
        f.write(DSET_MAGIC)
        f.write(struct.pack('<h', DSET_VERSION))
        f.write(struct.pack('<h', mode))
        f.write(struct.pack('<h', selected))

        # Write 30 slots
        for slot_idx in range(DSET_SLOT_COUNT):
            if slot_idx < len(patterns) and patterns[slot_idx].pixels:
                pat = patterns[slot_idx]
                has_image = -1  # TRUE in QB64
                f.write(struct.pack('<h', has_image))
                f.write(struct.pack('<h', pat.width))
                f.write(struct.pack('<h', pat.height))

                # Write pixel data as BGRA (QB64-PE's _UNSIGNED LONG format)
                for y in range(pat.height):
                    for x in range(pat.width):
                        i = (y * pat.width + x) * 4
                        r = pat.pixels[i + 0]
                        g = pat.pixels[i + 1]
                        b = pat.pixels[i + 2]
                        a = pat.pixels[i + 3]
                        # QB64-PE uses _RGB32/_RGBA32 which is BGRA in memory
                        pixel = (a << 24) | (r << 16) | (g << 8) | b
                        f.write(struct.pack('<I', pixel))
            else:
                has_image = 0  # FALSE
                f.write(struct.pack('<h', has_image))


def desaturate_pattern(pat):
    """Convert pattern to grayscale using ITU-R BT.601 weights."""
    if not pat.pixels:
        return
    rgba = bytearray(pat.pixels)
    for i in range(pat.width * pat.height):
        r = rgba[i * 4 + 0]
        g = rgba[i * 4 + 1]
        b = rgba[i * 4 + 2]
        gray = int(0.299 * r + 0.587 * g + 0.114 * b + 0.5)
        rgba[i * 4 + 0] = gray
        rgba[i * 4 + 1] = gray
        rgba[i * 4 + 2] = gray
        # Alpha stays the same
    pat.pixels = bytes(rgba)


# =============================================================================
# PNG export (optional)
# =============================================================================

def export_png(pat, filepath):
    """Export a pattern as a PNG file using Pillow."""
    if not HAS_PIL or not pat.pixels:
        return False
    img = Image.frombytes('RGBA', (pat.width, pat.height), pat.pixels)
    img.save(filepath, 'PNG')
    return True


# =============================================================================
# Main
# =============================================================================

def main():
    parser = argparse.ArgumentParser(
        description='Convert Photoshop .pat pattern files to DRAW .dset files.'
    )
    parser.add_argument('input', help='Input .pat file')
    parser.add_argument('-o', '--output-dir', default=None,
                        help='Output directory for .dset files')
    parser.add_argument('-m', '--mode', choices=['pattern', 'brush', 'gradient'],
                        default='pattern', help='DSET mode (default: pattern)')
    parser.add_argument('-l', '--list', action='store_true',
                        help='List patterns only (no conversion)')
    parser.add_argument('--png', default=None, metavar='DIR',
                        help='Export individual patterns as PNG files')
    parser.add_argument('--max-size', type=int, default=256,
                        help='Skip patterns larger than NxN (default: 256)')
    parser.add_argument('--desaturate', action='store_true',
                        help='Convert to grayscale')

    args = parser.parse_args()

    if not os.path.isfile(args.input):
        print(f"Error: File not found: {args.input}")
        sys.exit(1)

    # Parse the .pat file
    print("=" * 60)
    print("Photoshop .pat → DRAW .dset Converter")
    print("=" * 60)
    print()

    patterns = parse_pat_file(args.input)

    if not patterns:
        print("No patterns found or parsed successfully.")
        sys.exit(1)

    # Print pattern list
    print(f"\nParsed {len(patterns)} pattern(s):")
    print("-" * 60)
    for i, pat in enumerate(patterns):
        model_name = COLOR_MODELS.get(pat.color_model, f'Unknown({pat.color_model})')
        has_px = '✓' if pat.pixels else '✗'
        print(f"  {i + 1:3d}. [{has_px}] {pat.width:4d}×{pat.height:<4d} "
              f"{model_name:12s} {pat.name}")
    print("-" * 60)

    if args.list:
        sys.exit(0)

    # Filter out patterns that are too large or have no pixel data
    valid_patterns = []
    skipped = 0
    for pat in patterns:
        if not pat.pixels:
            skipped += 1
            continue
        if pat.width > args.max_size or pat.height > args.max_size:
            print(f"  Skipping '{pat.name}' ({pat.width}×{pat.height}) - "
                  f"exceeds max size {args.max_size}")
            skipped += 1
            continue
        valid_patterns.append(pat)

    if skipped:
        print(f"\nSkipped {skipped} pattern(s)")
    print(f"Converting {len(valid_patterns)} pattern(s)")

    # Apply desaturation
    if args.desaturate:
        for pat in valid_patterns:
            desaturate_pattern(pat)
        print("Applied desaturation filter")

    # Export PNGs if requested
    if args.png:
        png_dir = args.png
        os.makedirs(png_dir, exist_ok=True)
        for i, pat in enumerate(valid_patterns):
            safe_name = "".join(c if c.isalnum() or c in ' -_' else '_' for c in pat.name)
            png_path = os.path.join(png_dir, f"{i + 1:03d}_{safe_name}.png")
            if export_png(pat, png_path):
                print(f"  PNG: {png_path}")
        print(f"Exported {len(valid_patterns)} PNG files to {png_dir}")

    # Determine DSET mode
    mode_map = {
        'brush': DSET_MODE_BRUSH,
        'pattern': DSET_MODE_PATTERN,
        'gradient': DSET_MODE_GRADIENT,
    }
    dset_mode = mode_map[args.mode]
    mode_name = args.mode.capitalize()

    # Determine output directory
    if args.output_dir:
        out_dir = args.output_dir
    else:
        out_dir = os.path.dirname(os.path.abspath(args.input))
    os.makedirs(out_dir, exist_ok=True)

    # Split patterns into groups of DSET_SLOT_COUNT (30)
    base_name = Path(args.input).stem
    num_sets = (len(valid_patterns) + DSET_SLOT_COUNT - 1) // DSET_SLOT_COUNT

    for set_idx in range(num_sets):
        start = set_idx * DSET_SLOT_COUNT
        end = min(start + DSET_SLOT_COUNT, len(valid_patterns))
        batch = valid_patterns[start:end]

        if num_sets == 1:
            dset_name = f"{base_name}.dset"
        else:
            dset_name = f"{base_name}{set_idx + 1}.dset"

        dset_path = os.path.join(out_dir, dset_name)
        write_dset(dset_path, batch, dset_mode)
        print(f"\n  DSET: {dset_path}")
        print(f"        {len(batch)} patterns, mode={mode_name}")

    print(f"\nDone! Created {num_sets} .dset file(s)")


if __name__ == '__main__':
    main()
