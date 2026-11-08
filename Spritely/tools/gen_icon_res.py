#!/usr/bin/env python3
"""Packages the palette icons (lib/icons/<Class>.ico) for Delphi.

    python3 tools/gen_icon_res.py

Standard library only. Writes one .dcr per set of components, linked with
{$R ...} by the unit that registers that set on its page of the palette:

  lib/Spritely.Reg.dcr     lib/Spritely.Reg.pas, the Spritely page

(Cut down from peardox/SRDelphiFMX's script, which also packaged the
Lenticular icons; it writes the same Spritely .dcr.)

A .dcr is a .res file: one BITMAP per size, named after the class in
capitals - TSPRITELYORBITALCAMERA (24 px), TSPRITELYORBITALCAMERA16 and
TSPRITELYORBITALCAMERA32. The bitmaps are 32-bit with alpha; transparent
pixels (and the faint anti-aliased fringe of the rounded corners) are
magenta with alpha 0, and the bottom-left pixel is always one of them, so
an IDE that ignores alpha still finds the transparent colour where Delphi
looks for it. Taken from G3DGames/TSteamAPI's tools/gen_icon_res.py, whose
32-bit alpha bitmaps are confirmed to show in the Delphi 13 IDE.

A new component needs its class in its set's list in SETS and its icon
drawn by tools/gen_icons.py; a missing icon or size stops the script with
a message. Output is deterministic: a file is rewritten only when its bytes
change.
"""
import os
import struct
import sys
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

ICON_DIR = "lib/icons"
# Each .dcr and every class its registration unit registers
SETS = {
    "lib/Spritely.Reg.dcr": ["TSpritelyOrbitalCamera", "TSpritelyProjection"],
}
DELPHI_SIZES = ((24, ""), (16, "16"), (32, "32"))           # size, name suffix
RT_BITMAP = 2
MEM_FLAGS = 0x1010            # MOVEABLE | DISCARDABLE
KEY = (255, 0, 255)           # RGB of fully transparent pixels in the Delphi bitmaps
CLEAR_BELOW = 64              # alpha under this counts as transparent


class IconError(Exception):
    pass


# ------------------------------------------------------------------ .ico --

def png_decode(data):
    """Minimal PNG reader: 8-bit RGBA or RGB, not interlaced (what icon tools write)."""
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise IconError("not a PNG")
    pos, idat, w = 8, b"", 0
    while pos < len(data):
        length, kind = struct.unpack(">I4s", data[pos:pos + 8])
        body = data[pos + 8:pos + 8 + length]
        if kind == b"IHDR":
            w, h, depth, ctype, _, _, interlace = struct.unpack(">IIBBBBB", body)
            if depth != 8 or ctype not in (2, 6) or interlace:
                raise IconError(f"PNG frame is depth {depth}, colour type {ctype}, interlace {interlace}; "
                                "only 8-bit RGB / RGBA without interlace is read")
            bpp = 4 if ctype == 6 else 3
        elif kind == b"IDAT":
            idat += body
        pos += 12 + length
    raw = zlib.decompress(idat)
    stride = w * bpp
    rows, prev, i = [], bytearray(stride), 0
    for _ in range(h):
        ftype, line = raw[i], bytearray(raw[i + 1:i + 1 + stride])
        i += 1 + stride
        for x in range(stride):
            a = line[x - bpp] if x >= bpp else 0
            b = prev[x]
            c = prev[x - bpp] if x >= bpp else 0
            if ftype == 1:
                line[x] = (line[x] + a) & 255
            elif ftype == 2:
                line[x] = (line[x] + b) & 255
            elif ftype == 3:
                line[x] = (line[x] + (a + b) // 2) & 255
            elif ftype == 4:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                line[x] = (line[x] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
        rows.append([tuple(line[x:x + bpp]) + ((255,) if bpp == 3 else ()) for x in range(0, stride, bpp)])
        prev = line
    return w, h, rows


def dib_decode(data):
    """32-bit BI_RGB icon frame (BITMAPINFOHEADER, height doubled for the AND mask)."""
    size, w, h2, _, bits, comp = struct.unpack("<IiiHHI", data[:20])
    h = abs(h2) // 2
    if bits != 32 or comp != 0:
        raise IconError(f"bitmap frame is {bits}-bit (compression {comp}); only 32-bit with alpha is read")
    pix = data[size:size + w * h * 4]
    rows = []
    for y in range(h):
        line = pix[y * w * 4:(y + 1) * w * 4]
        rows.append([(line[x + 2], line[x + 1], line[x], line[x + 3]) for x in range(0, w * 4, 4)])
    if h2 > 0:            # bottom-up
        rows.reverse()
    return w, h, rows


def read_ico(path):
    """{size: rows of (r, g, b, a)} for every square frame of an .ico."""
    data = open(path, "rb").read()
    reserved, kind, count = struct.unpack("<HHH", data[:6])
    if reserved != 0 or kind != 1:
        raise IconError(f"{path}: not an .ico file")
    frames = {}
    for i in range(count):
        w, h, _, _, _, _, length, offset = struct.unpack("<BBBBHHII", data[6 + 16 * i:22 + 16 * i])
        blob = data[offset:offset + length]
        fw, fh, rows = png_decode(blob) if blob[:4] == b"\x89PNG" else dib_decode(blob)
        if fw == fh:
            frames[fw] = rows
    return frames


# --------------------------------------------------------- frame writers --

def bitmap_resource(rows):
    """BITMAP resource data: BITMAPINFOHEADER + 32-bit BGRA pixels, bottom-up.
    Pixels below CLEAR_BELOW alpha (anti-aliased corner fringes) become fully
    transparent magenta, so the bottom-left pixel is always the key colour and
    no tile pixel shares it."""
    w, h = len(rows[0]), len(rows)
    out = bytearray(struct.pack("<IiiHHIIiiII", 40, w, h, 1, 32, 0, w * h * 4, 0, 0, 0, 0))
    for row in reversed(rows):
        for r, g, b, a in row:
            if a < CLEAR_BELOW:
                r, g, b, a = KEY + (0,)
            elif (r, g, b) == KEY:
                b = 254          # an opaque pixel must never match the key
            out += bytes((b, g, r, a))
    if out[40:44] != bytes((KEY[2], KEY[1], KEY[0], 0)):
        raise IconError(f"{w} px bitmap: bottom-left pixel is not transparent")
    return bytes(out)


# ------------------------------------------------------------- .res file --

def res_entry(rtype, name, data):
    """One entry of a 32-bit .res file: numeric type, upper-case string name."""
    name_bytes = name.upper().encode("utf-16-le") + b"\x00\x00"
    head = struct.pack("<HH", 0xFFFF, rtype) + name_bytes
    head += b"\x00" * (-len(head) % 4)
    head += struct.pack("<IHHII", 0, MEM_FLAGS, 0, 0, 0)
    entry = struct.pack("<II", len(data), 8 + len(head)) + head + data
    return entry + b"\x00" * (-len(entry) % 4)


def res_file(entries):
    # the empty first entry every .res file starts with
    empty = struct.pack("<IIHHHHIHHII", 0, 32, 0xFFFF, 0, 0xFFFF, 0, 0, 0, 0, 0, 0)
    return empty + b"".join(entries)


def write(path, data):
    full = os.path.join(ROOT, path)
    old = open(full, "rb").read() if os.path.exists(full) else None
    if old != data:
        open(full, "wb").write(data)
        print("wrote", path)
    else:
        print("unchanged", path)


def load(classes, sizes):
    """{class: {size: rows}}; raises IconError naming every missing icon or size."""
    icons, missing = {}, []
    for cls in classes:
        path = os.path.join(ROOT, ICON_DIR, cls + ".ico")
        if not os.path.exists(path):
            missing.append(f"{ICON_DIR}/{cls}.ico")
            continue
        frames = read_ico(path)
        lacking = [str(s) for s in sizes if s not in frames]
        if lacking:
            missing.append(f"{ICON_DIR}/{cls}.ico lacks {', '.join(lacking)} px")
        icons[cls] = frames
    if missing:
        raise IconError("missing icons (draw them with tools/gen_icons.py):\n  " + "\n  ".join(missing))
    return icons


def main():
    try:
        for dcr, classes in SETS.items():
            icons = load(classes, [s for s, _ in DELPHI_SIZES])
            write(dcr, res_file([res_entry(RT_BITMAP, cls + suffix, bitmap_resource(icons[cls][size]))
                                 for cls in classes for size, suffix in DELPHI_SIZES]))
            print(f"{dcr}: {len(classes)} components packaged")
    except IconError as e:
        sys.exit(str(e))


if __name__ == "__main__":
    main()
