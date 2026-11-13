"""Draws Sprite3DBuilder's program icon: stone blocks and an amber block being placed on a
tiled teal floor, seen isometrically, so it cannot be mistaken for Sprite3D's axis cube.

Writes Sprite3DBuilder/Sprite3DBuilder_Icon.ico, at the sizes Windows 10 and 11 use (16 to
64 pixels as 32-bit bitmaps, 256 as PNG), and puts the same images into the main icon of
Sprite3DBuilder/Sprite3DBuilder.res, leaving every other resource in it as it was. The .res
is first read and written back, and must come out byte for byte the same, or nothing is
written. 24 pixels and under draw fewer blocks and thicker edges, so they still read.

Run from the repository's root:  python tools/make_builder_icon.py   (needs Pillow)
"""
import io
import math
import struct
import sys

from PIL import Image, ImageDraw

ICO = 'Sprite3DBuilder/Sprite3DBuilder_Icon.ico'
RES = 'Sprite3DBuilder/Sprite3DBuilder.res'
SIZES = [16, 20, 24, 32, 40, 48, 64, 256]
C30, S30 = math.cos(math.radians(30)), 0.5

def shade(c, f):
    return tuple(max(0, min(255, int(v * f))) for v in c[:3]) + (255,)

def render(size, simple=False):
    SS = 4 if size >= 64 else 8
    W = size * SS
    img = Image.new('RGBA', (W, W), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # The drawing's bounds in tile units, so it fills the square with a margin
    def Q(x, y, z):
        return ((x - y) * C30, (x + y) * S30 - z)
    corners = [Q(x, y, z) for x in (-1.5, 1.5) for y in (-1.5, 1.5) for z in (-0.28, 2.0)]
    minx = min(p[0] for p in corners); maxx = max(p[0] for p in corners)
    miny = min(p[1] for p in corners); maxy = max(p[1] for p in corners)
    margin = W * (0.04 if size >= 32 else 0.02)
    unit = (W - 2 * margin) / max(maxx - minx, maxy - miny)
    ox = W / 2 - (minx + maxx) / 2 * unit
    oy = W / 2 - (miny + maxy) / 2 * unit

    def P(x, y, z):
        q = Q(x, y, z)
        return (ox + q[0] * unit, oy + q[1] * unit)

    edge = (24, 28, 36, 255)
    lw = max(1, round(W / (110 if not simple else 48)))
    # The floor: 3 x 3 tiles, two teals in a checker, centred on 0,0
    teal_a, teal_b = (38, 150, 150), (28, 118, 124)
    n = 3
    for i in range(n):
        for j in range(n):
            x0, y0 = i - n / 2, j - n / 2
            pts = [P(x0, y0, 0), P(x0 + 1, y0, 0), P(x0 + 1, y0 + 1, 0), P(x0, y0 + 1, 0)]
            col = teal_a if (i + j) % 2 == 0 else teal_b
            d.polygon(pts, fill=col + (255,), outline=None if simple else edge, width=lw)
    # The floor's two visible sides, a slab's thickness
    t = 0.28
    front_l = [P(-1.5, 1.5, 0), P(1.5, 1.5, 0), P(1.5, 1.5, -t), P(-1.5, 1.5, -t)]
    front_r = [P(1.5, -1.5, 0), P(1.5, 1.5, 0), P(1.5, 1.5, -t), P(1.5, -1.5, -t)]
    d.polygon(front_l, fill=shade(teal_b, 0.62), outline=edge, width=lw)
    d.polygon(front_r, fill=shade(teal_b, 0.45), outline=edge, width=lw)
    d.polygon([P(-1.5, -1.5, 0), P(1.5, -1.5, 0), P(1.5, 1.5, 0), P(-1.5, 1.5, 0)],
              outline=edge, width=lw)

    def block(x, y, z, col, h=1.0):
        top = [P(x, y, z + h), P(x + 1, y, z + h), P(x + 1, y + 1, z + h), P(x, y + 1, z + h)]
        left = [P(x, y + 1, z + h), P(x + 1, y + 1, z + h), P(x + 1, y + 1, z), P(x, y + 1, z)]
        right = [P(x + 1, y, z + h), P(x + 1, y + 1, z + h), P(x + 1, y + 1, z), P(x + 1, y, z)]
        d.polygon(top, fill=shade(col, 1.15), outline=edge, width=lw)
        d.polygon(left, fill=shade(col, 0.85), outline=edge, width=lw)
        d.polygon(right, fill=shade(col, 0.62), outline=edge, width=lw)

    amber = (236, 160, 44)
    stone = (196, 186, 170)
    # Back to front, so nearer blocks are drawn over farther ones
    if simple:
        # Small sizes: one stack and the block placed, so each still reads
        block(-1.5, -1.5, 0, stone)
        block(-1.5, -1.5, 1, stone)
        block(0.5, 0.5, 0, amber)
    else:
        block(-1.5, -1.5, 0, stone)        # back corner
        block(-1.5, -1.5, 1, stone)        # a wall two high at the back
        block(-0.5, -1.5, 0, stone)
        block(-1.5, -0.5, 0, stone)
        block(0.5, 0.5, 0, amber)          # a block being placed at the front
    img = img.resize((size, size), Image.LANCZOS)
    return img

def bmp_entry(im):
    w, h = im.size
    px = im.convert('RGBA').load()
    hdr = struct.pack('<IiiHHIIiiII', 40, w, h * 2, 1, 32, 0, 0, 0, 0, 0, 0)
    rows = b''
    for y in range(h - 1, -1, -1):
        for x in range(w):
            r, g, b, a = px[x, y]
            rows += bytes((b, g, r, a))
    stride = ((w + 31) // 32) * 4
    mask = b''
    for y in range(h - 1, -1, -1):
        bits = bytearray(stride)
        for x in range(w):
            if px[x, y][3] == 0:
                bits[x // 8] |= 0x80 >> (x % 8)
        mask += bytes(bits)
    return hdr + rows + mask

def png_entry(im):
    b = io.BytesIO(); im.save(b, 'PNG', optimize=True); return b.getvalue()

def images():
    out = []
    for s in SIZES:
        im = render(s, simple=s <= 24)
        out.append((s, png_entry(im) if s >= 256 else bmp_entry(im)))
    return out

def write_ico(path, imgs):
    head = struct.pack('<HHH', 0, 1, len(imgs))
    off = 6 + 16 * len(imgs); dirs = b''; data = b''
    for s, blob in imgs:
        dirs += struct.pack('<BBBBHHII', s % 256, s % 256, 0, 0, 1, 32, len(blob), off + len(data))
        data += blob
    open(path, 'wb').write(head + dirs + data)

# ---- .res: read entries keeping raw headers, so a rewrite can be checked
def read_res(path):
    d = open(path, 'rb').read(); p = 0; out = []
    while p < len(d):
        ds, hs = struct.unpack_from('<II', d, p)
        out.append([d[p + 8:p + hs], d[p + hs:p + hs + ds]])
        p += hs + ds; p += (4 - p % 4) % 4
    return out

def write_res(entries):
    b = b''
    for hdr, data in entries:
        e = struct.pack('<II', len(data), 8 + len(hdr)) + hdr + data
        b += e + b'\0' * ((4 - len(e) % 4) % 4)
    return b

def type_id(hdr):
    t, = struct.unpack_from('<H', hdr, 0)
    if t == 0xFFFF:
        return struct.unpack_from('<H', hdr, 2)[0], struct.unpack_from('<H', hdr, 6)[0] if struct.unpack_from('<H', hdr, 4)[0] == 0xFFFF else None
    return None, None



def main():
    entries = read_res(RES)
    if write_res(entries) != open(RES, 'rb').read():
        sys.exit(RES + ': could not be read back exactly; nothing written')
    imgs = images()
    blobs = dict(imgs)
    group = [e for e in entries if struct.unpack_from('<H', e[0], 0)[0] == 0xFFFF and
             struct.unpack_from('<H', e[0], 2)[0] == 14]
    icons = {}
    for e in entries:
        t, i = type_id(e[0])
        if t == 3:
            icons[i] = e
    if len(group) != 1:
        sys.exit(RES + ': expected one main icon; nothing written')
    g = bytearray(group[0][1])
    for k in range(struct.unpack_from('<H', g, 4)[0]):
        o = 6 + 14 * k
        size = g[o] or 256
        ident = struct.unpack_from('<H', g, o + 12)[0]
        if size not in blobs or ident not in icons:
            sys.exit(RES + ': its icon sizes are not %s; nothing written' % SIZES)
        icons[ident][1] = blobs[size]
        struct.pack_into('<I', g, o + 8, len(blobs[size]))
    group[0][1] = bytes(g)
    write_ico(ICO, imgs)
    open(RES, 'wb').write(write_res(entries))
    print('Wrote %s and the main icon of %s, %d sizes' % (ICO, RES, len(imgs)))


if __name__ == '__main__':
    main()
