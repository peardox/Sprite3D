#!/usr/bin/env python3
"""Draws the palette icons of the Spritely components.

    python3 tools/gen_icons.py [--preview sheet.png]

Writes lib/icons/<Class>.ico (16, 24, 32, 48, 64 and 256 px, 32-bit with
alpha) and its source lib/icons/svg/<Class>.svg for every class in ICONS.
Run it only to REDRAW the icons; packaging them for the IDE is
tools/gen_icon_res.py, which needs no third-party module.
This one needs Pillow (pip install pillow) and rsvg-convert (librsvg).
--preview also writes a contact sheet: every icon at 16 / 24 / 32 / 48 px
on a light and a dark background, read back from the rendered frames.

Style, as in TSteamAPI's palette icons (G3DGames/TSteamAPI,
tools/gen_icons.py, whose .ico writer this is): a rounded tile in the
group colour with one white symbol on it, drawn on a 24-unit grid, in
Spritely's pear green. Cut down from peardox/SRDelphiFMX's script, which
also drew the Lenticular icons; it draws the same Spritely icons. The
tile fills the whole square so its edges land on whole pixels at every
size, and its corners leave the bottom-left pixel transparent (Delphi
takes that pixel as the transparent colour when it ignores alpha).
"""
import io
import math
import os
import shutil
import struct
import subprocess
import sys
import tempfile

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ICON_DIR = os.path.join(ROOT, "lib", "icons")
SVG_DIR = os.path.join(ICON_DIR, "svg")
SIZES = [16, 24, 32, 48, 64, 256]

W = "#FFFFFF"
# The group colours, mid-luminance so the tiles read on light and dark IDE
# themes: Spritely a pear green
SPRITELY = "#3E7F3A"
GOLD = "#E9B53C"
# Alpha under this counts as transparent, as in tools/gen_icon_res.py
CLEAR_BELOW = 64


def lighten(hex_colour, f):
    h = hex_colour.lstrip("#")
    r, g, b = (int(h[i:i + 2], 16) for i in (0, 2, 4))
    r, g, b = (round(c + (255 - c) * f) for c in (r, g, b))
    return f"#{r:02X}{g:02X}{b:02X}"


def tile(colour, gid):
    return (
        f'<defs><linearGradient id="{gid}" x1="0" y1="0" x2="0" y2="1">'
        f'<stop offset="0" stop-color="{lighten(colour, 0.16)}"/>'
        f'<stop offset="1" stop-color="{colour}"/></linearGradient></defs>'
        f'<rect x="0" y="0" width="24" height="24" rx="4.5" fill="url(#{gid})"/>'
    )


def orbital_camera():
    """A tilted orbit round a gold centre, with a camera on the orbit
    aimed at the centre."""
    cx, cy = 10.6, 14.2
    rx, ry, tilt = 8.0, 4.0, -18.0
    orbit = (f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="none" stroke="{W}" '
             f'stroke-width="1.5" transform="rotate({tilt} {cx} {cy})"/>')
    centre = f'<circle cx="{cx}" cy="{cy}" r="2.3" fill="{GOLD}"/>'
    # The camera sits on the orbit's top-right, its lens turned towards
    # the centre; drawn level, then turned about its own middle
    t = math.radians(-35)
    a = math.radians(tilt)
    ex, ey = rx * math.cos(t), ry * math.sin(t)
    px = cx + ex * math.cos(a) - ey * math.sin(a)
    py = cy + ex * math.sin(a) + ey * math.cos(a)
    aim = math.degrees(math.atan2(cy - py, cx - px))
    # Drawn with the lens along -x, then turned so the lens faces the
    # centre; the body sits outward of the orbit. A tile-coloured outline
    # parts it from the orbit line it overlaps
    shape = ('<path d="M0.2 -1.4 L-2.4 -2.5 L-2.4 2.5 L0.2 1.4 Z"/>'
             '<rect x="0" y="-2.4" width="5.6" height="4.8" rx="1.0"/>')
    place = f'translate({px:.2f} {py:.2f}) rotate({aim + 180:.2f}) scale(1.35)'
    # One solid camera: first a halo in the tile colour, so it stands clear
    # of the orbit line it sits on, then the white shape, then its window
    body = (f'<g transform="{place}" fill="{{T}}" stroke="{{T}}" stroke-width="1.6" '
            f'stroke-linejoin="round">{shape}</g>'
            f'<g transform="{place}" fill="{W}">{shape}'
            f'<circle cx="2.8" cy="0" r="1.15" fill="{{T}}"/></g>')
    return orbit + centre + body


def projection():
    """An oblique (cavalier) cube behind a camera: the camera draws the cube
    with a projection of its own. The cube's front square, its back square
    up and to the right at 45 degrees, and the edges joining them, in white;
    the camera in front of it, lower left, lens to the left, solid white on
    a tile-coloured halo so the cube's lines stop at its outline."""
    fx, fy, side = 8.6, 5.6, 9.0       # the front square's top-left and side
    dx, dy = 4.2, -3.2                 # the receding depth, up and right
    bx, by = fx + dx, fy + dy
    line = f'fill="none" stroke="{W}" stroke-width="1.4" stroke-linejoin="round"'
    back = f'<rect x="{bx}" y="{by}" width="{side}" height="{side}" {line} opacity="0.75"/>'
    edges = "".join(
        f'<line x1="{fx + ox}" y1="{fy + oy}" x2="{bx + ox}" y2="{by + oy}" '
        f'stroke="{W}" stroke-width="1.4" stroke-linecap="round"/>'
        for ox, oy in ((0, 0), (side, 0), (side, side), (0, side)))
    front = f'<rect x="{fx}" y="{fy}" width="{side}" height="{side}" {line}/>'
    shape = ('<path d="M0.2 -1.4 L-2.4 -2.5 L-2.4 2.5 L0.2 1.4 Z"/>'
             '<rect x="0" y="-2.4" width="5.6" height="4.8" rx="1.0"/>')
    place = 'translate(6.6 16.4) scale(1.45)'
    body = (f'<g transform="{place}" fill="{{T}}" stroke="{{T}}" stroke-width="1.6" '
            f'stroke-linejoin="round">{shape}</g>'
            f'<g transform="{place}" fill="{W}">{shape}'
            f'<circle cx="2.8" cy="0" r="1.15" fill="{{T}}"/></g>')
    return back + edges + front + body


# Class name -> (tile colour, symbol). Symbols may use {T} for the tile colour.
ICONS = {
    "TSpritelyOrbitalCamera": (SPRITELY, orbital_camera()),
    "TSpritelyProjection": (SPRITELY, projection()),
}


def svg_doc(body):
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">'
            + body + '</svg>\n')


def write_ico(path, frames):
    """Write an .ico by hand: 32-bit BGRA DIB frames (with AND mask) up to 64 px,
    PNG-compressed for 256 px - the layout Windows' own icons use, and the one every
    resource compiler (brcc32, rc, windres, lazres) reads."""
    blobs = []
    for im in frames:
        w, h = im.size
        if w >= 256:
            buf = io.BytesIO()
            im.save(buf, format="PNG")
            blobs.append(buf.getvalue())
            continue
        header = struct.pack("<IiiHHIIiiII", 40, w, h * 2, 1, 32, 0, 0, 0, 0, 0, 0)
        px = im.load()
        rows = []
        for y in range(h - 1, -1, -1):  # bottom-up
            rows.append(b"".join(struct.pack("BBBB", px[x, y][2], px[x, y][1], px[x, y][0], px[x, y][3])
                                 for x in range(w)))
        stride = ((w + 31) // 32) * 4
        mask_rows = []
        for y in range(h - 1, -1, -1):
            bits = bytearray(stride)
            for x in range(w):
                if px[x, y][3] == 0:
                    bits[x // 8] |= 0x80 >> (x % 8)
            mask_rows.append(bytes(bits))
        blobs.append(header + b"".join(rows) + b"".join(mask_rows))
    out = struct.pack("<HHH", 0, 1, len(frames))
    offset = 6 + 16 * len(frames)
    for im, blob in zip(frames, blobs):
        w, h = im.size
        out += struct.pack("<BBBBHHII", w % 256, h % 256, 0, 0, 1, 32, len(blob), offset)
        offset += len(blob)
    with open(path, "wb") as f:
        f.write(out + b"".join(blobs))


def render(svg_path, size, png_path):
    subprocess.run(["rsvg-convert", "-w", str(size), "-h", str(size), "-o", png_path, svg_path], check=True)


def preview(frames_by_class, path):
    sizes = (16, 24, 32, 48)
    pad = 8
    cell = max(sizes) + pad
    rows = len(frames_by_class) * 2
    sheet = Image.new("RGBA", (pad + len(sizes) * cell, pad + rows * cell), "#FFFFFF")
    y = pad
    for frames in frames_by_class.values():
        for bg in ("#F3F3F3", "#2B2B2B"):
            x = pad
            for s in sizes:
                sheet.paste(Image.new("RGBA", (cell - 2, cell - 2), bg), (x - 2, y - 2))
                sheet.alpha_composite(frames[s], (x, y))
                x += cell
            y += cell
    sheet.save(path)
    print("wrote", os.path.relpath(path, ROOT))


def main():
    if shutil.which("rsvg-convert") is None:
        sys.exit("rsvg-convert not found (librsvg): it renders the SVG sources")
    sheet = None
    if "--preview" in sys.argv:
        i = sys.argv.index("--preview")
        if i + 1 >= len(sys.argv):
            sys.exit("--preview needs a file name")
        sheet = sys.argv[i + 1]
    os.makedirs(SVG_DIR, exist_ok=True)
    all_frames = {}
    with tempfile.TemporaryDirectory() as tmp:
        for name, (colour, body) in ICONS.items():
            svg_path = os.path.join(SVG_DIR, name + ".svg")
            with open(svg_path, "w", newline="\n") as f:
                f.write(svg_doc(tile(colour, "g" + name) + body.replace("{T}", colour)))
            frames = {}
            for s in SIZES:
                png = os.path.join(tmp, f"{name}_{s}.png")
                render(svg_path, s, png)
                frames[s] = Image.open(png).convert("RGBA")
                # gen_icon_res.py clears pixels fainter than CLEAR_BELOW for
                # Delphi, so only a stronger corner pixel is an error here
                if frames[s].getpixel((0, s - 1))[3] >= CLEAR_BELOW:
                    sys.exit(f"{name} {s} px: bottom-left pixel is not transparent")
            write_ico(os.path.join(ICON_DIR, name + ".ico"), [frames[s] for s in SIZES])
            all_frames[name] = frames
            print("wrote", os.path.relpath(os.path.join(ICON_DIR, name + ".ico"), ROOT))
    if sheet:
        preview(all_frames, os.path.abspath(sheet))


if __name__ == "__main__":
    main()
