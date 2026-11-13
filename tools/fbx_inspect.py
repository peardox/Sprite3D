"""Reports what an FBX file holds that matters to Sprite3D and Sprite3DBuilder.

Usage, with Python 3 and nothing else:

    python3 tools/fbx_inspect.py MODEL.fbx [MORE.fbx ...]

For each file it prints:

  - its kind (binary or ASCII), FBX version, the program that wrote it,
    the up axis and the unit scale factor (1.0 is centimetres);
  - its objects counted by kind: meshes, bones, skins, materials and so on;
  - every texture it names, each name as given: the Filename, FileName and
    RelativeFilename of its Texture and Video objects and their Path and
    RelPath properties, and whether the texture is held in the file itself;
  - its animation takes, how many curves they have, and how many of those
    move (a key differs from the curve's first). A take with no moving
    curve is a still take, which Sprite3DModelAnimations leaves out;
  - two checks of the way Sprite3DModelTextures rewrites a binary FBX when
    it puts its texture names right: that reading the nodes and writing
    them back unchanged gives the file byte for byte, and that its rule for
    the footer's padding gives the footer the file has.

The reader is the same, node for node, as ReadFbxNode and WriteFbxNode in
Shared/Sprite3DModelTextures.pas, so a file this reads and writes back is
one the programs can rewrite. ASCII FBX files get their texture names only.

Written on 12 and 13 November 2026 to look into Synty's FBX packs: texture
paths left from the exporting machine, and the "Take 001" Maya leaves in
every file. The model's own files are only read.
"""

import struct
import sys
import zlib
from collections import Counter

MAGIC = b'Kaydara FBX Binary  \x00'
HEADER_SIZE = 27
WIDE_VERSION = 7500
FOOTER_TAIL = 140
# FBX time: ticks in a second
TICKS_PER_SECOND = 46186158000


class Node:
    """A node as read: its name, its properties' bytes as the file has them,
    its children, and whether it had a nested list."""

    def __init__(self):
        self.name = b''
        self.props = []
        self.children = []
        self.nested = False

    def child(self, name):
        for c in self.children:
            if c.name == name:
                return c
        return None


def read_node(data, offset, wide):
    """Reads one node from offset; returns (node, next offset), node None for
    the null record that ends a list."""
    width = 8 if wide else 4
    fmt = '<Q' if wide else '<I'
    end = struct.unpack_from(fmt, data, offset)[0]
    count = struct.unpack_from(fmt, data, offset + width)[0]
    offset += 3 * width
    name_length = data[offset]
    offset += 1
    if end == 0:
        return None, offset
    node = Node()
    node.name = data[offset:offset + name_length]
    offset += name_length
    for _ in range(count):
        kind = chr(data[offset])
        offset += 1
        start = offset
        if kind == 'C':
            size = 1
        elif kind == 'Y':
            size = 2
        elif kind in 'IF':
            size = 4
        elif kind in 'DL':
            size = 8
        elif kind in 'fdlib':
            size = 12 + struct.unpack_from('<I', data, offset + 8)[0]
        elif kind in 'SR':
            size = 4 + struct.unpack_from('<I', data, offset)[0]
        else:
            raise ValueError('property of unknown type %r at %d' % (kind, offset - 1))
        node.props.append((kind, data[start:start + size]))
        offset = start + size
    node.nested = offset < end
    while offset < end:
        child, offset = read_node(data, offset, wide)
        if child is None:
            break
        node.children.append(child)
    return node, end


def write_node(out, node, wide):
    """Writes a node, its offsets and lengths worked out afresh, as
    WriteFbxNode does."""
    width = 8 if wide else 4
    fmt = '<Q' if wide else '<I'
    start = len(out)
    out += bytes(3 * width)
    out.append(len(node.name))
    out += node.name
    props_start = len(out)
    for kind, raw in node.props:
        out += kind.encode('latin1')
        out += raw
    props_length = len(out) - props_start
    if node.nested:
        for child in node.children:
            write_node(out, child, wide)
        out += bytes(3 * width + 1)
    struct.pack_into(fmt, out, start, len(out))
    struct.pack_into(fmt, out, start + width, len(node.props))
    struct.pack_into(fmt, out, start + 2 * width, props_length)


def footer_for(offset, footer):
    """The footer as WriteFbxFooter writes it after nodes ending at offset."""
    zeros = (4 - (offset + 16)) % 16
    if zeros <= 4:
        zeros += 16
    return footer[:16] + bytes(zeros) + footer[-FOOTER_TAIL:]


def value(kind, raw):
    """A property's value, for the kinds read here."""
    if kind == 'S':
        length = struct.unpack_from('<I', raw, 0)[0]
        return raw[4:4 + length].decode('utf-8', 'replace')
    if kind in 'IFDLCY':
        return struct.unpack({'I': '<i', 'F': '<f', 'D': '<d', 'L': '<q', 'C': '<?',
                              'Y': '<h'}[kind], raw)[0]
    if kind in 'fdlib':
        count, encoding, length = struct.unpack_from('<III', raw, 0)
        body = raw[12:12 + length]
        if encoding == 1:
            body = zlib.decompress(body)
        return list(struct.unpack('<%d%s' % (count, {'f': 'f', 'd': 'd', 'l': 'q', 'i': 'i',
                                                   'b': '?'}[kind]), body))
    return raw


def text(node, index):
    if index < len(node.props) and node.props[index][0] == 'S':
        return value(*node.props[index])
    return ''


def walk(nodes):
    for node in nodes:
        yield node
        yield from walk(node.children)


def properties70(node):
    """A node's Properties70 as {name: last value}."""
    found = {}
    p70 = node.child(b'Properties70') if node else None
    if p70:
        for p in p70.children:
            if p.name == b'P' and p.props:
                found[text(p, 0)] = value(*p.props[-1]) if len(p.props) > 4 else None
    return found


def inspect_binary(name, data):
    version = struct.unpack_from('<I', data, 23)[0]
    wide = version >= WIDE_VERSION
    nodes = []
    offset = HEADER_SIZE
    while offset < len(data):
        node, offset = read_node(data, offset, wide)
        if node is None:
            break
        nodes.append(node)
    footer = data[offset:]
    top = {n.name: n for n in nodes}

    creator = ''
    for n in walk(nodes):
        if n.name == b'Creator' and n.props:
            creator = text(n, 0)
            break
    settings = properties70(top.get(b'GlobalSettings'))
    print('%s: binary FBX %d (%d-bit offsets), %s' % (name, version, 64 if wide else 32,
                                                     creator or 'creator not given'))
    print('  up axis %s, unit scale factor %s' % (settings.get('UpAxis'),
                                                  settings.get('UnitScaleFactor')))

    objects = top.get(b'Objects')
    kinds = Counter()
    by_id = {}
    for item in (objects.children if objects else []):
        sub = text(item, 2) if len(item.props) > 2 else ''
        kinds[(item.name.decode('latin1'), sub)] += 1
        if item.props and item.props[0][0] == 'L':
            by_id[value(*item.props[0])] = item
    print('  objects: ' + ', '.join('%s%s %d' % (k, ' (%s)' % s if s else '', n)
                                    for (k, s), n in sorted(kinds.items())))

    print('  textures:')
    any_texture = False
    for item in (objects.children if objects else []):
        if item.name not in (b'Texture', b'Video'):
            continue
        label = text(item, 1).replace('\x00\x01', ' / ')
        names = []
        for field in item.children:
            if field.name in (b'Filename', b'FileName', b'RelativeFilename'):
                names.append((field.name.decode(), text(field, 0)))
            elif field.name == b'Content' and field.props and field.props[0][0] == 'R' \
                    and len(field.props[0][1]) > 4:
                names.append(('Content', 'held in the file (%d bytes)' %
                              (len(field.props[0][1]) - 4)))
        for key, val in properties70(item).items():
            if key in ('Path', 'RelPath') and val:
                names.append((key, val))
        for key, val in names:
            if val:
                any_texture = True
                print('    %-24s %-16s %s' % (label, key, val))
    if not any_texture:
        print('    none')

    stacks = [n for n in (objects.children if objects else []) if n.name == b'AnimationStack']
    curves = [n for n in (objects.children if objects else []) if n.name == b'AnimationCurve']
    moving = 0
    for curve in curves:
        keys = curve.child(b'KeyValueFloat')
        values = value(*keys.props[0]) if keys and keys.props else []
        if values and max(values) - min(values) > 1e-4:
            moving += 1
    for stack in stacks:
        span = properties70(stack)
        stop = span.get('LocalStop') or 0
        print('  take %s: %.3f s' % (text(stack, 1).replace('\x00\x01', ' / '),
                                     (stop or 0) / TICKS_PER_SECOND))
    if stacks or curves:
        print('  animation curves: %d, of which %d move%s' % (
            len(curves), moving, '' if moving else ' (a still take: not an animation)'))
    else:
        print('  no animation takes')

    out = bytearray(data[:HEADER_SIZE])
    for node in nodes:
        write_node(out, node, wide)
    out += bytes(25 if wide else 13)
    out += footer
    same = bytes(out) == data
    rebuilt = footer_for(offset, footer) == footer if len(footer) >= 16 + 4 + FOOTER_TAIL \
        else None
    print('  checks: written back %s; footer padding %s' % (
        'byte for byte' if same else 'DIFFERENT',
        'as the rule gives' if rebuilt else ('not laid out as expected' if rebuilt is None
                                             else 'NOT as the rule gives')))


def inspect_ascii(name, data):
    lines = data.decode('utf-8', 'replace').splitlines()
    print('%s: ASCII FBX' % name)
    print('  textures:')
    found = False
    for line in lines:
        s = line.strip()
        if s.startswith(('Filename:', 'FileName:', 'RelativeFilename:', 'P: "Path"',
                         'P: "RelPath"')):
            found = True
            print('    ' + s)
    if not found:
        print('    none')


def main(paths):
    if not paths:
        print(__doc__)
        return 1
    for path in paths:
        with open(path, 'rb') as f:
            data = f.read()
        if data.startswith(MAGIC):
            inspect_binary(path, data)
        elif data.lstrip().startswith(b';'):
            inspect_ascii(path, data)
        else:
            print('%s: not an FBX file' % path)
        print()
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
