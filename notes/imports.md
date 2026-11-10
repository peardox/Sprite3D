# Importing models: what Gorilla3D's loaders hand over

Notes for Gorilla3D's author from Sprite3D's ImportTests (10 November 2026, Gorilla3D 1.5.4,
Delphi 13, Win64). Two bugs in the USD loader come first. After them are behaviours we found
that seem worth confirming or documenting, and a few questions.

## How it was tested

ImportTests (in `ImportTests/` of the Sprite3D repository) loads a file with
`TGorillaModel.LoadFromFile(nil, AFileName, [TAnimationCachingFlag.VertexPosition])`. It then
walks `TGorillaModel.Def` (a `TModelDef`) and writes what it finds as glTF 2.0:

- every `TTransformDef` becomes a node, with its `Transform` as the node's matrix;
- `VertexSource` becomes POSITION, NORMAL and TEXCOORD_0, as they are, with no conversion;
- the indices are `IndexSource`, or each `TVertexGroupDef`'s when the mesh is drawn by groups;
- `TMaterialDef` becomes a metallic-roughness material;
- textures come from `TTextureDef.GetAssetBitmapInstance(True)`.

The written file was then compared, triangle by triangle, with a glTF file of the same model
whose geometry is known. A triangle matched when all three corners had the same position, UV
and normal, in the same winding order. The compare is independent of vertex order, because
the loaders reorder vertices.

The test models were:

- a single-mesh bowl (glTF from a model-sharing site, and an FBX of it);
- a two-material tree (glTF, and FBX and USD files written from it by a 3D suite).

| Source | Result |
| --- | --- |
| GLB, glTF | Exact: every triangle, normal, UV and texture pixel matches the original. |
| FBX | Exact, once the node's matrix and `UnitScale` are applied. |
| USD (`.usda`, Z-up) | Positions and winding exact. UVs wrong (bug 1); turned upside down relative to the other loaders (bug 2). |

## Bug 1: the USD loader ignores the indices of indexed primvars

The tree's `.usda` stores its UVs as an indexed faceVarying primvar, which is the usual way
3D suites write them:

```
texCoord2f[] primvars:st = [(0.3050685, 0.39120525), ...]      (14,582 values)
    interpolation = "faceVarying"
int[] primvars:st:indices = [44, 70, 0, 44, 0, 32, ...]        (39,708, one per face corner)
int[] faceVertexIndices = [44, 70, 0, 44, 0, 32, ...]          (39,708)
```

For face corner n, the UV is `st[st:indices[n]]`. The loader instead takes `st[n]`, the n-th
value in order, and ignores `st:indices`. As a result, every texture on such a mesh is
scrambled.

The evidence, counting matching face corners out of the 39,708:

| How the UV is read | Matches the glTF original | Matches what the loader produced |
| --- | --- | --- |
| `st[st:indices[n]]`, V flipped | 39,695 (the 13 others are rounding) | 4 |
| `st[n]`, V flipped | 4 | 14,569 of the 14,582 corners that have a value |

The flip of V is right; only the index lookup is missing. The same probably applies to any
indexed primvar: `normals` or `primvars:normals` with `:indices`, and `displayColor`. In this
file the normals are faceVarying without indices, and they came through correctly.

## Bug 2: USD's Z-up is turned the other way from the other loaders

The file has `upAxis = "Z"` and `metersPerUnit = 1`, with no transforms on its prims. The
loader leaves the points as they are, which is fine, and puts this matrix on the model
definition (`TModelDef.Transform`):

```
glTF column-major: [1,0,0,0,  0,0,1,0,  0,-1,0,0,  0,0,0,1]
which maps (x, y, z) to (x, -z, y)
```

That makes up −Y. The glTF and FBX loaders leave +Y as up. For example, the FBX loader puts
the exporter's −90° turn about X on the mesh node, which maps Z-up to +Y up. So the same
model, loaded from USD, is upside down compared with the same model loaded from glTF or FBX.
An application that turns models 180° about X for FMX's Y-down screen, as Sprite3D does,
shows USD models upside down.

The turn that matches the other loaders is (x, y, z) to (x, z, −y), a −90° turn about X:

```
glTF column-major: [1,0,0,0,  0,0,-1,0,  0,1,0,0,  0,0,0,1]
```

Also, `GetBoundingBox` on the loaded USD model gave the Z-up box (2.919 × 2.919 × 4.231),
which does not seem to include that matrix. The glTF and FBX models' boxes match what is
drawn.

## Behaviours worth confirming or documenting

These may all be intended; they are listed because a converter has to know them.

1. **Triangles are held clockwise.** Every loader hands over triangles in the opposite order
   to glTF's counter-clockwise front faces. A GLB loaded and written back with its indices
   as they are came out with every triangle reversed. A double-sided material hid it on
   screen. It seems to be a fixed rule, as FMX's front faces are clockwise, but it isn't
   written down anywhere we could find.

2. **A colour the file does not give stays at `TMaterialDef`'s starting value.** A glTF
   material with only a `baseColorTexture` came back with `Diffuse` = 0.75 grey, the
   constructor's value. glTF's default is white. A converter cannot tell "the file said
   0.75" from "the file said nothing". Could the loaders set the format's own defaults
   (glTF: base colour 1, metallic 1, roughness 1)? Or could they flag which values were
   read?

3. **`TGorillaModel.Def` is declared as `TCustomDef`.** For a loaded model it is always a
   `TModelDef`, so it has to be cast. Declaring it as `TModelDef`, or adding a typed
   accessor, would save every caller the cast.

4. **The FBX loader keeps node transforms and the unit scale separate.** The tree's FBX
   (centimetres) loads with ×100 and a −90° X turn on the mesh node's matrix, and
   `UnitScale` = 0.01 on the model. The vertices are untouched. That is good for
   converting, as nothing is baked in, but the model is shown 100 times larger than its
   glTF version. Is applying `UnitScale` left to the application on purpose?

5. **The glTF loader flattens the node hierarchy.** A five-node hierarchy (two rotations that
   cancel, and empty grouping nodes) came back as the model and one mesh node, with no
   matrices. That is fine for display. Does it bake non-identity transforms into the
   vertices, or keep them on the mesh node?

6. **Meshes split on reload.** The FBX loader gives one `TMeshDef` with two `TVertexGroupDef`
   children for a two-material mesh. A GLB of that mesh (one mesh, two primitives) loads
   back as separate meshes. The vertex and triangle totals are equal, so nothing is lost.

7. **A material table with one more entry.** A glTF with one or two materials loads with one
   more entry in `TModelDef.Materials` than the file has, presumably a default material. No
   mesh uses it.

8. **Texture flips.** `GetAssetBitmapInstance(True)` gives the bitmap flipped as it is drawn,
   so writing it out as it is, with the UVs as they are, was right for glTF and FBX. That
   was exactly what was needed.

9. **Features not carried.** `KHR_materials_emissive_strength` (strength 4 in the tree) does
   not appear in `TMaterialDef`, nor does the glTF/USD sampler wrap mode in any form we
   found. Neither is needed for display, but both matter when converting.

## Questions

- Is the clockwise winding the same for every loader and platform, so a converter can rely
  on it, or should it read `TCustomMeshDef.FaceOrientation` or something else?
- Are `TTransformDef.Transform` matrices always local, relative to the parent?
- Is there a supported way to ask which extensions the loaders are registered for?
  Sprite3D keeps its own list (`.usdc`, `.usda`, `.usd`, `.usdz`; `.usdz` loads), and it
  would be better to ask Gorilla3D.
- Would you take the Bug 1 and Bug 2 test file (a 2.9 MB `.usda` with its texture)? The
  owner can send it.
