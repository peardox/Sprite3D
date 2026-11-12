"""Draws the placeholder group icons in icons/groups, one PNG per group name.

The icons are simple pictograms drawn here, so they carry no licence of their own: a
stand-in until a proper library of group icons is chosen. Each is ICON_SIZE pixels square
with a transparent background, drawn at SCALE times the size and shrunk, for smooth edges.

Run from the repository's root:  python tools/make_group_icons.py
Needs Pillow.
"""

import os
import sys

from PIL import Image, ImageDraw

ICON_SIZE = 64
SCALE = 4
S = ICON_SIZE * SCALE
OUT = os.path.join('icons', 'groups')

# Colours: light line work, with a warm and a cool accent
INK = (225, 225, 225, 255)
WOOD = (196, 132, 82, 255)
STONE = (150, 160, 175, 255)
GOLD = (236, 190, 70, 255)
FLAME = (250, 150, 60, 255)
CLOTH = (200, 70, 70, 255)
GLASS = (110, 190, 170, 255)
W = 6 * SCALE // 2  # line width


def px(v):
    """A coordinate on the 64 grid, scaled to the drawing."""
    return v * SCALE


def box(d, x0, y0, x1, y1, fill=None, outline=INK, r=2):
    d.rounded_rectangle([px(x0), px(y0), px(x1), px(y1)], radius=px(r), fill=fill,
                        outline=outline, width=W)


def line(d, pts, colour=INK, width=W):
    d.line([(px(x), px(y)) for x, y in pts], fill=colour, width=width, joint='curve')


def ellipse(d, x0, y0, x1, y1, fill=None, outline=INK):
    d.ellipse([px(x0), px(y0), px(x1), px(y1)], fill=fill, outline=outline, width=W)


def poly(d, pts, fill=None, outline=INK):
    d.polygon([(px(x), px(y)) for x, y in pts], fill=fill, outline=outline, width=W)


def wall(d):
    for row, y in enumerate(range(12, 52, 10)):
        off = 0 if row % 2 == 0 else 8
        for x in range(6 - off, 58, 16):
            box(d, max(x, 6), y, min(x + 16, 58), y + 10, fill=STONE, r=1)


def floor(d):
    poly(d, [(32, 14), (58, 30), (32, 46), (6, 30)], fill=STONE)
    line(d, [(19, 22), (45, 38)])
    line(d, [(45, 22), (19, 38)])


def stairs(d):
    pts = [(8, 54), (8, 44), (20, 44), (20, 34), (32, 34), (32, 24), (44, 24), (44, 14),
           (56, 14), (56, 54)]
    poly(d, pts, fill=STONE)


def table(d):
    box(d, 6, 20, 58, 28, fill=WOOD)
    line(d, [(12, 28), (12, 52)])
    line(d, [(52, 28), (52, 52)])


def seat(d):
    box(d, 16, 30, 48, 36, fill=WOOD)
    line(d, [(20, 36), (18, 54)])
    line(d, [(44, 36), (46, 54)])


def chair(d):
    seat(d)
    line(d, [(18, 30), (18, 10)])
    line(d, [(18, 12), (40, 12)])


def bench(d):
    box(d, 4, 30, 60, 36, fill=WOOD)
    line(d, [(10, 36), (10, 52)])
    line(d, [(54, 36), (54, 52)])


def barrel(d):
    ellipse(d, 14, 8, 50, 56, fill=WOOD)
    line(d, [(16, 22), (48, 22)])
    line(d, [(16, 42), (48, 42)])


def keg(d):
    box(d, 8, 18, 56, 46, fill=WOOD, r=10)
    line(d, [(20, 18), (20, 46)])
    line(d, [(44, 18), (44, 46)])
    line(d, [(32, 46), (32, 54)])


def crate(d):
    box(d, 10, 12, 54, 54, fill=WOOD)
    line(d, [(10, 12), (54, 54)])
    line(d, [(54, 12), (10, 54)])


def chest(d):
    box(d, 8, 26, 56, 54, fill=WOOD)
    d.pieslice([px(8), px(10), px(56), px(42)], 180, 360, fill=WOOD, outline=INK, width=W)
    box(d, 28, 30, 36, 40, fill=GOLD, r=1)


def trunk(d):
    box(d, 6, 20, 58, 54, fill=WOOD)
    line(d, [(6, 30), (58, 30)])
    box(d, 28, 26, 36, 36, fill=GOLD, r=1)


def banner(d):
    line(d, [(10, 8), (54, 8)])
    poly(d, [(16, 8), (48, 8), (48, 54), (32, 44), (16, 54)], fill=CLOTH)


def flame(d, x, y):
    poly(d, [(x, y - 14), (x + 6, y - 2), (x, y + 2), (x - 6, y - 2)], fill=FLAME)


def candle(d):
    box(d, 24, 26, 40, 56, fill=INK, outline=INK, r=1)
    flame(d, 32, 20)


def torch(d):
    line(d, [(32, 56), (32, 26)], colour=WOOD, width=W * 2)
    flame(d, 32, 20)


def coin(d):
    ellipse(d, 12, 12, 52, 52, fill=GOLD)
    ellipse(d, 22, 22, 42, 42)


def key(d):
    ellipse(d, 8, 22, 28, 42, fill=GOLD)
    line(d, [(28, 32), (56, 32)], colour=GOLD, width=W * 2)
    line(d, [(48, 32), (48, 42)], colour=GOLD, width=W * 2)
    line(d, [(40, 32), (40, 40)], colour=GOLD, width=W * 2)


def keyring(d):
    ellipse(d, 8, 8, 34, 34)
    key_small = [(26, 30), (52, 52)]
    line(d, key_small, colour=GOLD, width=W * 2)
    line(d, [(46, 46), (40, 52)], colour=GOLD, width=W * 2)


def bottle(d):
    poly(d, [(26, 8), (38, 8), (38, 20), (46, 30), (46, 56), (18, 56), (18, 30), (26, 20)],
         fill=GLASS)


def book(d):
    box(d, 14, 8, 50, 56, fill=CLOTH)
    line(d, [(20, 8), (20, 56)])


def shelves(d):
    box(d, 8, 6, 56, 58, fill=None)
    for y in (22, 40):
        line(d, [(8, y), (56, y)])
    for x, h in ((14, 10), (20, 12), (26, 9), (36, 11), (44, 10)):
        line(d, [(x, 20), (x, 20 - h)], colour=CLOTH)
        line(d, [(x, 38), (x, 38 - h)], colour=GLASS)


def sword(d):
    line(d, [(14, 50), (50, 14)], colour=STONE, width=W * 2)
    line(d, [(10, 40), (24, 54)])
    line(d, [(8, 56), (14, 50)], colour=WOOD, width=W * 2)


def pickaxe(d):
    line(d, [(16, 56), (40, 20)], colour=WOOD, width=W * 2)
    d.arc([px(14), px(8), px(62), px(40)], 200, 330, fill=STONE, width=W * 2)


def column(d):
    box(d, 14, 6, 50, 14, fill=STONE)
    box(d, 20, 14, 44, 50, fill=STONE)
    box(d, 14, 50, 50, 58, fill=STONE)


def post(d):
    box(d, 26, 6, 38, 58, fill=WOOD)


def rocks(d):
    poly(d, [(6, 54), (14, 34), (28, 30), (34, 54)], fill=STONE)
    poly(d, [(28, 54), (38, 24), (52, 22), (58, 54)], fill=STONE)


def rubble(d):
    for x, y, s in ((10, 44, 10), (24, 38, 12), (40, 46, 8), (46, 34, 10), (30, 50, 6)):
        poly(d, [(x, y + s), (x + s // 2, y), (x + s, y + s)], fill=STONE)


def scaffold(d):
    box(d, 10, 8, 54, 56, fill=None, r=0)
    line(d, [(10, 32), (54, 32)], colour=WOOD)
    line(d, [(10, 8), (54, 32)], colour=WOOD)
    line(d, [(10, 32), (54, 56)], colour=WOOD)


def barrier(d):
    box(d, 6, 20, 58, 32, fill=WOOD, r=1)
    line(d, [(14, 32), (14, 54)])
    line(d, [(50, 32), (50, 54)])


def bed(d):
    box(d, 6, 32, 58, 46, fill=CLOTH)
    box(d, 8, 24, 22, 32, fill=INK, r=2)
    line(d, [(6, 18), (6, 54)])
    line(d, [(58, 30), (58, 54)])


def plate(d):
    ellipse(d, 6, 22, 58, 46, fill=INK)
    ellipse(d, 18, 28, 46, 40, fill=STONE)


def bucket(d):
    poly(d, [(14, 24), (50, 24), (44, 56), (20, 56)], fill=WOOD)
    d.arc([px(14), px(6), px(50), px(42)], 180, 360, fill=INK, width=W)


def ceiling(d):
    box(d, 4, 10, 60, 20, fill=STONE, r=1)
    line(d, [(16, 20), (16, 34)])
    line(d, [(48, 20), (48, 34)])


def bar(d):
    box(d, 4, 26, 60, 56, fill=WOOD, r=1)
    line(d, [(4, 34), (60, 34)])
    poly(d, [(40, 10), (48, 10), (48, 18), (50, 26), (38, 26), (40, 18)], fill=GLASS)


def bartop(d):
    box(d, 4, 22, 60, 32, fill=WOOD, r=1)
    line(d, [(12, 32), (12, 50)])
    line(d, [(52, 32), (52, 50)])


def box_icon(d):
    box(d, 12, 20, 52, 54, fill=WOOD)
    poly(d, [(12, 20), (22, 10), (60, 10), (52, 20)], fill=WOOD)
    line(d, [(52, 54), (60, 44), (60, 10)])


def stool(d):
    ellipse(d, 16, 22, 48, 32, fill=WOOD)
    line(d, [(20, 28), (16, 54)])
    line(d, [(44, 28), (48, 54)])
    line(d, [(32, 32), (32, 54)])


ICONS = {
    'banner': banner, 'bar': bar, 'barrel': barrel, 'barrier': barrier,
    'bartop': bartop, 'bed': bed, 'bench': bench, 'book': book, 'bookcase': shelves,
    'bottle': bottle, 'box': box_icon, 'bucket': bucket, 'candle': candle,
    'ceiling': ceiling, 'chair': chair, 'chest': chest, 'coin': coin, 'column': column,
    'crate': crate, 'floor': floor, 'keg': keg, 'key': key, 'keyring': keyring,
    'pickaxe': pickaxe, 'pillar': column, 'plate': plate, 'post': post, 'rocks': rocks,
    'rubble': rubble, 'scaffold': scaffold, 'shelf': shelves, 'shelves': shelves,
    'stairs': stairs, 'stool': stool, 'sword': sword, 'table': table, 'torch': torch,
    'trunk': trunk, 'wall': wall, 'seat': seat,
}


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, draw in sorted(ICONS.items()):
        image = Image.new('RGBA', (S, S), (0, 0, 0, 0))
        draw(ImageDraw.Draw(image))
        image = image.resize((ICON_SIZE, ICON_SIZE), Image.LANCZOS)
        image.save(os.path.join(OUT, name + '.png'), optimize=True)
    print('%d icons in %s' % (len(ICONS), OUT))
    return 0


if __name__ == '__main__':
    sys.exit(main())
