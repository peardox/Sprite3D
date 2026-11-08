#!/usr/bin/env python3
"""Writes LenticularDemoFMX's scene as glTF binary models for StereoModel.

(Copied unchanged from peardox/SRDelphiFMX, where LenticularDemoFMX and
StereoModel live; here it writes Spritely/models, and ProjectionTest loads
DemoSceneNoWall.glb as its test model.)

    python3 tools/gen_demo_scene.py

Standard library only. Writes, in models/:

  DemoScene.glb        the scene as LenticularDemoFMX builds it (LenticularDemoFMX/ui/
                         MainForm.pas): the 11 x 11
                         grid of spheres, the two columns of three spinning
                         cubes and the back wall
  DemoSceneNoWall.glb  the same without the back wall, which otherwise
                         makes the framed view much larger, so everything
                         else small

The scene, in LenticularDemoFMX's world units (FMX: Y down, Z away from the viewer):

  - spheres of diameter 1.4, 3 units apart across (X) and in depth (Z),
    at Y = 0, from -15 to 15 both ways; one colour per depth row, nearest
    the viewer first: red, orange-red, dark orange, orange, yellow, WHITE
    (the middle row, on the glass), light sky blue, deep sky blue, dodger
    blue, royal blue, medium blue; the middle one lime green;
  - cubes of 3 units at X = 0, Z = 0, Y = +-4.5, +-9, +-13.5, colour
    #E8A33D, each turning a full turn about its vertical axis in 8 s
    (a looping glTF animation, "CubeSpin");
  - a back wall 60 x 40 at Z = 18, colour #35507A.

glTF is Y up with the viewer on +Z, so a point (x, y, z) of LenticularDemoFMX's
scene is written as (x, -y, -z): StereoModel turns every model 180 degrees
about X when it loads it (as Sprite3D does), which puts it back where
LenticularDemoFMX has it. The colours are LenticularDemoFMX's sRGB values made linear, as
glTF's baseColorFactor is linear; the materials are plain (metallic 0,
roughness 0.5), the wall's two-sided.
"""
import json
import math
import os
import struct

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "models")

ROW_HALF = 5
ROW_STEP = 3.0
SPHERE_RADIUS = 0.7
CUBE_SIZE = 3.0
CUBE_Y = 4.5
CUBE_GAP = 4.5
CUBES_PER_COLUMN = 3
WALL_W, WALL_H = 60.0, 40.0
WALL_Z = (ROW_HALF + 1) * ROW_STEP
SPIN_SECONDS = 8.0

# FMX's TAlphaColors, nearest the viewer first (depth row -5 .. 5)
DEPTH_COLOURS = [0xFF0000, 0xFF4500, 0xFF8C00, 0xFFA500, 0xFFFF00, 0xFFFFFF,
                 0x87CEFA, 0x00BFFF, 0x1E90FF, 0x4169E1, 0x0000CD]
MAIN_COLOUR = 0x32CD32
CUBE_COLOUR = 0xE8A33D
WALL_COLOUR = 0x35507A

SPHERE_SEGMENTS = 32
SPHERE_RINGS = 16


def linear(c):
    """An sRGB 0..255 channel as linear 0..1."""
    c /= 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def rgba(colour):
    return [round(linear((colour >> 16) & 255), 5), round(linear((colour >> 8) & 255), 5),
            round(linear(colour & 255), 5), 1.0]


def gltf_point(x, y, z):
    """LenticularDemoFMX's (FMX) coordinates as glTF's."""
    return [x, -y, -z]


def sphere_mesh(r):
    pos, nrm, idx = [], [], []
    for ring in range(SPHERE_RINGS + 1):
        theta = math.pi * ring / SPHERE_RINGS
        for seg in range(SPHERE_SEGMENTS + 1):
            phi = 2 * math.pi * seg / SPHERE_SEGMENTS
            n = (math.sin(theta) * math.cos(phi), math.cos(theta), math.sin(theta) * math.sin(phi))
            nrm.append(n)
            pos.append((n[0] * r, n[1] * r, n[2] * r))
    row = SPHERE_SEGMENTS + 1
    for ring in range(SPHERE_RINGS):
        for seg in range(SPHERE_SEGMENTS):
            a = ring * row + seg
            b = a + row
            # Counter-clockwise seen from outside
            idx += [a, a + 1, b, a + 1, b + 1, b]
    return pos, nrm, idx


def box_mesh(sx, sy, sz):
    hx, hy, hz = sx / 2, sy / 2, sz / 2
    faces = [((1, 0, 0), (0, 0, -1), (0, 1, 0)), ((-1, 0, 0), (0, 0, 1), (0, 1, 0)),
             ((0, 1, 0), (1, 0, 0), (0, 0, -1)), ((0, -1, 0), (1, 0, 0), (0, 0, 1)),
             ((0, 0, 1), (1, 0, 0), (0, 1, 0)), ((0, 0, -1), (-1, 0, 0), (0, 1, 0))]
    pos, nrm, idx = [], [], []
    for n, u, v in faces:
        base = len(pos)
        for su, sv in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
            p = [n[i] * (hx, hy, hz)[i] + su * u[i] * (hx, hy, hz)[i] + sv * v[i] * (hx, hy, hz)[i]
                 for i in range(3)]
            pos.append(tuple(p))
            nrm.append(n)
        idx += [base, base + 1, base + 2, base, base + 2, base + 3]
    return pos, nrm, idx


def plane_mesh(w, h):
    """In the XY plane, facing +Z (the glTF viewer)."""
    hw, hh = w / 2, h / 2
    pos = [(-hw, -hh, 0), (hw, -hh, 0), (hw, hh, 0), (-hw, hh, 0)]
    nrm = [(0, 0, 1)] * 4
    return pos, nrm, [0, 1, 2, 0, 2, 3]


class Builder:
    def __init__(self):
        self.bin = bytearray()
        self.views, self.accessors, self.meshes, self.materials = [], [], [], []
        self.nodes, self.material_ids = [], {}

    def _add(self, data, target=None):
        while len(self.bin) % 4:
            self.bin.append(0)
        view = {"buffer": 0, "byteOffset": len(self.bin), "byteLength": len(data)}
        if target:
            view["target"] = target
        self.bin += data
        self.views.append(view)
        return len(self.views) - 1

    def accessor(self, values, kind, comp, target=None, minmax=False):
        flat = [c for v in values for c in (v if isinstance(v, (tuple, list)) else (v,))]
        fmt = {5126: "f", 5123: "H", 5125: "I"}[comp]
        view = self._add(struct.pack("<%d%s" % (len(flat), fmt), *flat), target)
        acc = {"bufferView": view, "componentType": comp, "count": len(values), "type": kind}
        if minmax:
            n = len(values[0])
            acc["min"] = [min(v[i] for v in values) for i in range(n)]
            acc["max"] = [max(v[i] for v in values) for i in range(n)]
        self.accessors.append(acc)
        return len(self.accessors) - 1

    def material(self, name, colour, double=False):
        if name in self.material_ids:
            return self.material_ids[name]
        m = {"name": name, "pbrMetallicRoughness": {"baseColorFactor": rgba(colour),
             "metallicFactor": 0.0, "roughnessFactor": 0.5}}
        if double:
            m["doubleSided"] = True
        self.materials.append(m)
        self.material_ids[name] = len(self.materials) - 1
        return self.material_ids[name]

    def mesh(self, name, geometry, material):
        pos, nrm, idx = geometry
        p = self.accessor(pos, "VEC3", 5126, 34962, minmax=True)
        n = self.accessor(nrm, "VEC3", 5126, 34962)
        i = self.accessor(idx, "SCALAR", 5123 if max(idx) < 65536 else 5125, 34963)
        self.meshes.append({"name": name, "primitives": [
            {"attributes": {"POSITION": p, "NORMAL": n}, "indices": i, "material": material}]})
        return len(self.meshes) - 1

    def node(self, name, mesh=None, translation=None):
        n = {"name": name}
        if mesh is not None:
            n["mesh"] = mesh
        if translation is not None:
            n["translation"] = translation
        self.nodes.append(n)
        return len(self.nodes) - 1


def build(with_wall):
    b = Builder()
    sphere_geo = sphere_mesh(SPHERE_RADIUS)
    # One sphere mesh per colour (a mesh carries its material)
    sphere_meshes = {}
    for j in range(-ROW_HALF, ROW_HALF + 1):
        mat = b.material("Depth%+d" % j, DEPTH_COLOURS[j + ROW_HALF])
        sphere_meshes[j] = b.mesh("Sphere%+d" % j, sphere_geo, mat)
    main_mesh = b.mesh("SphereMain", sphere_geo, b.material("Main", MAIN_COLOUR))
    cube_mesh = b.mesh("Cube", box_mesh(CUBE_SIZE, CUBE_SIZE, CUBE_SIZE),
                       b.material("Cube", CUBE_COLOUR))

    children = []
    grid = b.node("Grid")
    grid_children = []
    for j in range(-ROW_HALF, ROW_HALF + 1):        # depth
        for i in range(-ROW_HALF, ROW_HALF + 1):    # across
            mesh = main_mesh if (i == 0 and j == 0) else sphere_meshes[j]
            grid_children.append(b.node("Sphere_%d_%d" % (i, j), mesh,
                                        gltf_point(i * ROW_STEP, 0.0, j * ROW_STEP)))
    b.nodes[grid]["children"] = grid_children
    children.append(grid)

    cubes = []
    for k in range(2 * CUBES_PER_COLUMN):
        side = 2 * (k // CUBES_PER_COLUMN) - 1
        y = side * (CUBE_Y + (k % CUBES_PER_COLUMN) * CUBE_GAP)
        cubes.append(b.node("Cube%d" % k, cube_mesh, gltf_point(0.0, y, 0.0)))
    children += cubes

    if with_wall:
        wall_mesh = b.mesh("Wall", plane_mesh(WALL_W, WALL_H),
                           b.material("Wall", WALL_COLOUR, double=True))
        children.append(b.node("Wall", wall_mesh, gltf_point(0.0, 0.0, WALL_Z)))

    root = b.node("DemoScene")
    b.nodes[root]["children"] = children

    # The cubes' spin: a full turn about Y in SPIN_SECONDS, keyed every
    # quarter turn (slerp between keys a quarter turn apart), looping
    times = [SPIN_SECONDS * q / 4 for q in range(5)]
    quats = []
    for q in range(5):
        a = math.pi / 2 * q
        quats.append((0.0, math.sin(a / 2), 0.0, math.cos(a / 2)))
    t_acc = b.accessor(times, "SCALAR", 5126, minmax=False)
    b.accessors[t_acc]["min"] = [times[0]]
    b.accessors[t_acc]["max"] = [times[-1]]
    q_acc = b.accessor(quats, "VEC4", 5126)
    samplers, channels = [], []
    for c in cubes:
        samplers.append({"input": t_acc, "output": q_acc, "interpolation": "LINEAR"})
        channels.append({"sampler": len(samplers) - 1, "target": {"node": c, "path": "rotation"}})

    gltf = {
        "asset": {"version": "2.0",
                  "generator": "StereoModel tools/gen_demo_scene.py (LenticularDemoFMX's scene)"},
        "scene": 0,
        "scenes": [{"name": "DemoScene", "nodes": [root]}],
        "nodes": b.nodes,
        "meshes": b.meshes,
        "materials": b.materials,
        "accessors": b.accessors,
        "bufferViews": b.views,
        "buffers": [{"byteLength": len(b.bin)}],
        "animations": [{"name": "CubeSpin", "samplers": samplers, "channels": channels}],
    }
    return gltf, bytes(b.bin)


def write_glb(path, gltf, binary):
    js = json.dumps(gltf, separators=(",", ":")).encode("ascii")
    js += b" " * (-len(js) % 4)
    binary += b"\0" * (-len(binary) % 4)
    total = 12 + 8 + len(js) + 8 + len(binary)
    with open(path, "wb") as f:
        f.write(struct.pack("<III", 0x46546C67, 2, total))
        f.write(struct.pack("<II", len(js), 0x4E4F534A))
        f.write(js)
        f.write(struct.pack("<II", len(binary), 0x004E4942))
        f.write(binary)
    print("wrote", os.path.relpath(path, ROOT), total, "bytes")


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    for name, wall in (("DemoScene.glb", True), ("DemoSceneNoWall.glb", False)):
        gltf, binary = build(wall)
        write_glb(os.path.join(OUT_DIR, name), gltf, binary)


if __name__ == "__main__":
    main()
