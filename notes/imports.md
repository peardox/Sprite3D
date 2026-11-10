# Importing models: what Gorilla3D's loaders hand over

Notes for Gorilla3D's author from Sprite3D's ImportTests (10 November 2026, Gorilla3D 1.5.4,
Delphi 13, Win64). Three bugs come first: two in the USD loader and one in the FBX loader's
animations. After them are behaviours we found that seem worth confirming or documenting,
and a few questions.

## How it was tested

ImportTests (in `ImportTests/` of the Sprite3D repository) loads a file with
`TGorillaModel.LoadFromFile(nil, AFileName, [TAnimationCachingFlag.VertexPosition])`. It then
walks `TGorillaModel.Def` (a `TModelDef`) and writes what it finds as glTF 2.0:

- every `TTransformDef` becomes a node, with its `Transform` as the node's matrix;
- `VertexSource` becomes POSITION, NORMAL and TEXCOORD_0, as they are, with no conversion;
- the indices are `IndexSource`, or each `TVertexGroupDef`'s when the mesh is drawn by groups;
- `TMaterialDef` becomes a metallic-roughness material;
- textures come from `TTextureDef.GetAssetBitmapInstance(True)`;
- skins come from each `TControllerDef.Skin`: `LinkedJoints` gives the joints. Each joint
  reference's `Indices` and `Weights` give the weights (after `ApplyMeshWeights` where it
  has per-mesh sets), mapped to the drawn vertices through the mesh's `VertexIndexMap`, as
  `TSkinDef.ApplyVertexJointsRelation` does;
- animations come from each `TAnimationDef`: every stage drives the node of its
  `Reference`, and its interpolators' keys, times `Duration`, become the channel's times.

The written file was then compared, triangle by triangle, with a glTF file of the same model
whose geometry is known. A triangle matched when all three corners had the same position, UV
and normal, in the same winding order. The compare is independent of vertex order, because
the loaders reorder vertices.

Skins and animations were compared joint by joint: the weights per vertex, the inverse bind
matrices, and each joint's local transform at every key of every clip.

The test models were:

- a single-mesh bowl (glTF from a model-sharing site, and an FBX of it);
- a two-material tree (glTF, and FBX and USD files written from it by a 3D suite);
- a skinned parrot with 66 joints and 33 clips, as a GLB and as an FBX.

| Source | Result |
| --- | --- |
| GLB, glTF | Exact: every triangle, normal, UV and texture pixel matches the original. The parrot's skin (every weight to 1e-7, inverse bind matrices to 4e-7) and all 33 clips (every joint at every key, to 0.06°) match too. |
| FBX | Geometry exact, once the node's matrix and `UnitScale` are applied. Parrot: rest pose exact, 27 of the 33 clips match the GLB to about 0.5°, six do not (bug 3). |
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

## Bug 3: some FBX clips come out wrong

The parrot was loaded both as GLB and as FBX, and each joint's local rotation was compared at
every key of every clip. The GLB's clips start one frame (1/30 s) after the FBX's, which is
the GLB converter's doing, so the comparison allows for that.

The rest poses agree exactly (every joint to 5e-8, at the FBX's centimetre scale), and 27
clips agree to within 0.2–0.74° on every joint. Six do not:

| Clip | Largest difference | Joint |
| --- | --- | --- |
| Dead, Dead_Falling | 123° | Parrot COG |
| Death | 25° | Arm.L |
| FlyDown, FlyGlide | 34° | Leg.L |
| Walk | 34° | Leg.R |

Seen in Gorilla3D's own view, the GLB's Walk goes straight on, and the FBX's walks downhill.
So the FBX is the one at fault, and since the rest pose and 27 clips are right, its data is
being read wrongly rather than being wrong.

The differences are confined to some clips and some joints, and vary over a clip. That points
at the per-stage heuristics in the FBX animation import: the pre-rotation detection at K=0
(`PreRotationMatrix`, `HasPrePostRotation`, `FPreRotPending`) and the absolute-key vote
(`FBaseAbsPending`, `FStoredBaseTransform`). They decide per stage, so a wrong decision would
show up as exactly this: whole clips and single limbs, by large angles.

The keys were read after loading, from `TTransformationInterpolatorDef` matrices (the only
kind the FBX loader produced), so they are what Gorilla3D itself plays.

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

9. **Features not carried.** These do not appear in `TMaterialDef` in any form we found:
   - `KHR_materials_emissive_strength` (strength 4 in the tree);
   - `KHR_materials_specular` and `KHR_materials_ior` (the parrot GLB);
   - the glTF/USD sampler wrap mode.

   None of them is needed for display, but all matter when converting.

10. **The metallic-roughness texture is split in two.** The parrot GLB's one
    `metallicRoughnessTexture` comes back as two `TTextureDef`s, on the `Roughness` and
    `Metalness` channels, with the same picture. A converter has to notice that and put it
    back together. A metallic factor of 0 came back as 0.00001.

11. **Animation keys come back as matrices at every time.** Both the GLB and FBX loaders
    give one `TTransformationInterpolatorDef` per joint. It has a key at every time any of
    that joint's channels (translation, rotation, scale) had one: the parrot GLB's 143,335
    keys became 383,685. Converting them back meant decomposing each matrix and thinning
    out the keys that interpolation gives anyway.

12. **STEP interpolation is lost.** 179 of the parrot GLB's 198 samplers per clip are STEP.
    FMX's `TInterpolationType` has no step, so they come back as LINEAR. On this model their
    values happened to be unaffected.

13. **`TJointRefDef.InvBindMatrix` is the inverse bind matrix in row-vector form.** It
    agreed to 4e-7 (GLB) and 1e-6 (FBX) with mesh-global × inverse(joint-global) at rest.
    That is worth a line in its documentation, as `CalculateInverseBindTransformMatrix`
    stores it without `.Inverse` (commented out), which made its meaning unclear.

14. **More than four weights per vertex.** The parrot FBX has more influences per vertex
    than four (376 weights beyond the four heaviest). `TVertexJoints` holds
    `GORILLA_MAX_JOINTS_PER_VERTEX`; a converter to glTF keeps four, or eight with a second
    set of attributes.

15. **The FBX loader adds a root joint.** The parrot FBX has 67 joints against the GLB's 66.
    The extra one, `Rig`, is the armature object, made a joint. The FBX also has a stray
    `Action` clip beside the 33 `Rig|...` ones, which is probably in the file itself.

16. **`SetFixedCacheFrame` poses only the skinned vertices.** With
    `TAnimationCachingFlag.VertexPosition`, `TGorillaAnimation.SetFixedCacheFrame(N)` shows
    frame N of the baked skinned vertices. The skeleton and the animated nodes stay at the
    clip's clock time, and so does anything rigidly attached to them. Gorilla3D's own
    playback, with the same caching, moves them all, so a held frame is two poses mixed.

    The test case is a bear (glTF). It has one skinned body, and four unskinned eye meshes
    under nodes "Eye Right" and "Eye Left", which are children of the head joint
    "Bear Head_07". Its Talk clip moves the head joint and also animates the two eye nodes
    directly. Played normally, the eyes move with the head. Paused and held on a frame with
    `SetFixedCacheFrame`, the body poses at that frame and the eyes stay where the pause left
    them. Every sprite capture built on held frames has the same fault.

    Frame stepping, sprite capture and thumbnails all want the whole model at frame N. Could
    `SetFixedCacheFrame` also pose the skeleton and node tree at that frame's time? Or failing
    that, is there a supported way to pose everything at an exact time with no lag? On Delphi
    13, `Skeleton.SeekTo` is evaluated on the next frame drawn, so an off-screen grab made
    straight after it may not see the new pose.

## Questions

- Is the clockwise winding the same for every loader and platform, so a converter can rely
  on it, or should it read `TCustomMeshDef.FaceOrientation` or something else?
- Are `TTransformDef.Transform` matrices always local, relative to the parent?
- Is there a supported way to ask which extensions the loaders are registered for?
  Sprite3D keeps its own list (`.usdc`, `.usda`, `.usd`, `.usdz`; `.usdz` loads), and it
  would be better to ask Gorilla3D.
- For an FBX clip, how are the pre-rotation and absolute-key decisions meant to be made,
  and can a loader option force them (for example "keys are relative" or "pre-rotation
  baked") when the heuristics guess wrong?
- Would you take the test files? The owner can send the files for bugs 1 and 2 (a 2.9 MB
  `.usda` with its texture) and for bug 3 (the parrot as GLB and FBX).
