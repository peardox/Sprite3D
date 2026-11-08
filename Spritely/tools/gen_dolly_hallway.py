#!/usr/bin/env python3
"""Writes the dolly-zoom test scene as a glTF binary model for StereoModel.

(Copied unchanged from peardox/SRDelphiFMX; here it reads and writes
Spritely/models, for ProjectionTest.)

    python3 tools/gen_dolly_hallway.py

Standard library only; uses gen_demo_scene.py's builder and models/uvcube.glb.
Writes models/DollyHallway.glb: the UV cube standing on a long chequered
floor, between two rows of pillars, with a wall at the far end of the hallway.

It is made for the dolly zoom (TSpritelyProjection's FieldOfView with
Dolly): look along the hallway, level, with the cube as the subject. As
the lens narrows and the camera backs away the cube keeps its size while
the pillars and the far wall come forward and the floor's squares stop
shrinking with distance; as it widens the hallway stretches away.

The scene, in FMX's units (Y down, Z along the hallway), written as glTF
(x, -y, -z) as gen_demo_scene.py does, since StereoModel and
ProjectionTest turn every model 180 degrees about X:

  - the UV cube (uvcube.glb's mesh and texture, 2 units) on the floor at
    the middle;
  - a floor 16 wide and 64 long of 2-unit squares in two greys;
  - pillars 0.8 x 6 x 0.8 every 4 units along both sides, 5 units out,
    standing on the floor; every other pair coloured, so pairs can be told
    apart at a glance;
  - a blue end wall 16 x 8 at the far end only: the near end is open, so
    the camera can come in from it (owner, 8 November 2026: the near wall
    stopped the camera getting past it).
"""
import json
import os
import struct
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_demo_scene as base  # noqa: E402

ROOT = base.ROOT
OUT = os.path.join(ROOT, "models", "DollyHallway.glb")
UVCUBE = os.path.join(ROOT, "models", "uvcube.glb")

FLOOR_HALF_W = 8.0
FLOOR_HALF_L = 32.0
TILE = 2.0
FLOOR_Y = 1.0            # FMX: down is +, so the floor is 1 below the cube's middle
PILLAR_X = 5.0
PILLAR_STEP = 4.0
PILLAR_W = 0.8
PILLAR_H = 6.0
WALL_H = 8.0

TILE_A = 0xBFBFBF
TILE_B = 0x5A5A5A
PILLAR = 0xE6E1D3
PILLAR_MARK = 0xC0504D
WALL_FAR = 0x35507A


def read_glb(path):
    data = open(path, "rb").read()
    jl = struct.unpack("<I", data[12:16])[0]
    gltf = json.loads(data[20:20 + jl])
    bl = struct.unpack("<I", data[20 + jl:24 + jl])[0]
    binary = data[28 + jl:28 + jl + bl]
    return gltf, binary


def read_accessor(gltf, binary, index):
    acc = gltf["accessors"][index]
    view = gltf["bufferViews"][acc["bufferView"]]
    comps = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}[acc["type"]]
    fmt = {5126: "f", 5123: "H", 5125: "I", 5121: "B"}[acc["componentType"]]
    size = struct.calcsize(fmt)
    stride = view.get("byteStride", comps * size)
    start = view.get("byteOffset", 0) + acc.get("byteOffset", 0)
    out = []
    for i in range(acc["count"]):
        vals = struct.unpack_from("<%d%s" % (comps, fmt), binary, start + i * stride)
        out.append(vals if comps > 1 else vals[0])
    return out


def uv_cube(b):
    """uvcube.glb's mesh, texture and all, added to the builder b."""
    gltf, binary = read_glb(UVCUBE)
    prim = gltf["meshes"][0]["primitives"][0]
    pos = read_accessor(gltf, binary, prim["attributes"]["POSITION"])
    nrm = read_accessor(gltf, binary, prim["attributes"]["NORMAL"])
    uv = read_accessor(gltf, binary, prim["attributes"]["TEXCOORD_0"])
    idx = read_accessor(gltf, binary, prim["indices"])
    img = gltf["images"][gltf["textures"][0]["source"]]
    view = gltf["bufferViews"][img["bufferView"]]
    png = binary[view.get("byteOffset", 0):view.get("byteOffset", 0) + view["byteLength"]]
    image_view = b._add(png)
    p = b.accessor(pos, "VEC3", 5126, 34962, minmax=True)
    n = b.accessor(nrm, "VEC3", 5126, 34962)
    t = b.accessor(uv, "VEC2", 5126, 34962)
    i = b.accessor(idx, "SCALAR", 5123 if max(idx) < 65536 else 5125, 34963)
    b.materials.append({"name": "UVCube", "doubleSided": True,
                        "pbrMetallicRoughness": {"baseColorTexture": {"index": 0},
                                                 "metallicFactor": 0.0, "roughnessFactor": 0.5}})
    mat = len(b.materials) - 1
    b.meshes.append({"name": "UVCube", "primitives": [
        {"attributes": {"POSITION": p, "NORMAL": n, "TEXCOORD_0": t}, "indices": i,
         "material": mat}]})
    extra = {"images": [{"bufferView": image_view, "mimeType": img.get("mimeType", "image/png"),
                         "name": "cubecross"}],
             "textures": [{"sampler": 0, "source": 0}],
             "samplers": [{"magFilter": 9729, "minFilter": 9987}]}
    # Half its height, to stand it on the floor
    half = max(abs(v[1]) for v in pos)
    return len(b.meshes) - 1, half, extra


def floor_tile_mesh():
    """A TILE x TILE square in the floor plane, facing up (glTF +Y)."""
    h = TILE / 2
    pos = [(-h, 0, -h), (-h, 0, h), (h, 0, h), (h, 0, -h)]
    return pos, [(0, 1, 0)] * 4, [0, 1, 2, 0, 2, 3]


def build():
    b = base.Builder()
    cube_mesh, cube_half, extra = uv_cube(b)
    tile_a = b.mesh("TileA", floor_tile_mesh(), b.material("TileA", TILE_A))
    tile_b = b.mesh("TileB", floor_tile_mesh(), b.material("TileB", TILE_B))
    pillar_geo = base.box_mesh(PILLAR_W, PILLAR_H, PILLAR_W)
    pillar = b.mesh("Pillar", pillar_geo, b.material("Pillar", PILLAR))
    pillar_mark = b.mesh("PillarMark", pillar_geo, b.material("PillarMark", PILLAR_MARK))
    wall_far = b.mesh("WallFar", base.plane_mesh(2 * FLOOR_HALF_W, WALL_H),
                      b.material("WallFar", WALL_FAR, double=True))

    children = []
    # The cube on the floor, in the middle
    children.append(b.node("UVCube", cube_mesh, base.gltf_point(0.0, FLOOR_Y - cube_half, 0.0)))
    # The floor, chequered
    floor = b.node("Floor")
    tiles = []
    nx = int(2 * FLOOR_HALF_W / TILE)
    nz = int(2 * FLOOR_HALF_L / TILE)
    for i in range(nx):
        for k in range(nz):
            x = -FLOOR_HALF_W + TILE * (i + 0.5)
            z = -FLOOR_HALF_L + TILE * (k + 0.5)
            mesh = tile_a if (i + k) % 2 == 0 else tile_b
            tiles.append(b.node("Tile_%d_%d" % (i, k), mesh, base.gltf_point(x, FLOOR_Y, z)))
    b.nodes[floor]["children"] = tiles
    children.append(floor)
    # The pillars, standing on the floor
    pillars = b.node("Pillars")
    posts = []
    steps = int(FLOOR_HALF_L / PILLAR_STEP)
    for s in range(-steps + 1, steps):
        z = s * PILLAR_STEP
        mesh = pillar_mark if s % 2 == 0 else pillar
        for side in (-1, 1):
            posts.append(b.node("Pillar_%d_%d" % (s, side), mesh,
                                base.gltf_point(side * PILLAR_X, FLOOR_Y - PILLAR_H / 2, z)))
    b.nodes[pillars]["children"] = posts
    children.append(pillars)
    # The far end wall; the near end stays open
    children.append(b.node("WallFar", wall_far,
                           base.gltf_point(0.0, FLOOR_Y - WALL_H / 2, FLOOR_HALF_L)))

    root = b.node("DollyHallway")
    b.nodes[root]["children"] = children
    gltf = {
        "asset": {"version": "2.0",
                  "generator": "StereoModel tools/gen_dolly_hallway.py (dolly zoom test)"},
        "scene": 0,
        "scenes": [{"name": "DollyHallway", "nodes": [root]}],
        "nodes": b.nodes,
        "meshes": b.meshes,
        "materials": b.materials,
        "accessors": b.accessors,
        "bufferViews": b.views,
        "buffers": [{"byteLength": len(b.bin)}],
    }
    gltf.update(extra)
    return gltf, bytes(b.bin)


def main():
    gltf, binary = build()
    base.write_glb(OUT, gltf, binary)


if __name__ == "__main__":
    main()
