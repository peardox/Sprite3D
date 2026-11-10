# ImportTests

A test bed for turning models that are not glTF (FBX, USD, OBJ, Collada, STL, PLY) into
glTF. It is kept apart from Sprite3D. It uses Sprite3D's camera, Spritely's
`TSpritelyOrbitalCamera`, to show the models, and GLTFLib from the
[GLTFMerge](https://github.com/G3DGames/GLTFMerge) submodule to write them. It changes nothing
of Sprite3D's, and it is not in `Sprite3DGroup.groupproj`. If it works, the exporter can move
into Sprite3D later.

## What it does

1. **Open model...** loads any file Gorilla3D reads into the left view, as Sprite3D would. The
   log lists its bounding box, what its definitions hold and which definition classes it is
   made of.
2. **Export GLB** writes it as GLB, then loads that file into the right view. The first time,
   it asks for a file name (`<model>_export.glb` beside the model by default). After that it
   writes to the same file, so changing an option and exporting again takes one click.
   **Export GLB as...** always asks.
3. The log then lists every mesh and material written, anything left out, GLTFLib's warnings,
   and both models' boxes and counts, so the two can be compared by numbers as well as by eye.

Dragging in either view turns both cameras together, and the wheel zooms both. **Fit views**
frames both again. A model named on the command line is opened at start-up.

## What is exported (first version: static meshes)

- **Nodes:** every definition in Gorilla's tree, with its transform as the node's matrix.
  Armature joints, lights and cameras become empty nodes.
- **Meshes:** POSITION, NORMAL (made unit length), TEXCOORD_0, and COLOR_0 when asked for.
  A mesh drawn by vertex groups gets one primitive per group, each with its own material.
  Indices are 16-bit when they fit, otherwise 32-bit.
- **Materials:** metallic-roughness materials. Each takes:
  - the diffuse colour and opacity as the base colour, and the emissive colour. Gorilla's
    starting diffuse, 0.75 grey, is written as white when a texture is there, as a loader
    leaves it so when the file gives no colour;
  - metallic and roughness for a PBR material. For any other material, metallic is 0 and
    roughness is estimated from the specular power, as the fourth root of 2 / (power + 2),
    or 1 when the material has no specular highlight;
  - double-sidedness, and MASK when an alpha cutoff is set, or BLEND when the material or its
    texture is transparent.
- **Textures:** diffuse, normal, emissive and ambient occlusion, embedded as PNG. They are
  taken as Gorilla draws them, with any flips it applied. Other texture channels are listed
  in the log as not exported.

Skins, animations, morph targets, lights and cameras are not exported yet.

## The options

Gorilla's loaders may keep each format's own coordinates, so ImportTests writes positions,
normals and texture coordinates as they are. A GLB written back that way matched the original
exactly, apart from the winding (see below). These boxes change the output, for testing:

| Option | What it does |
| --- | --- |
| Negate X / Y / Z | Negates that axis in every position, normal and node matrix. An odd number of negated axes mirrors the model, so the winding is reversed as well. |
| Reverse winding | Reverses every triangle. **On by default**: Gorilla3D holds triangles the other way round from glTF (a GLB written back without it had every triangle reversed). A mirror from the Negate boxes is allowed for. |
| Flip V | Writes 1 - V in the texture coordinates. |
| Vertex colours | Writes COLOR_0. Off by default, because glTF multiplies the base colour by it. |
| Textures | Embeds the textures. |
| Apply unit scale | Scales the model by Gorilla's unit scale (0.01 for an FBX in centimetres), as a parent node, so the GLB is in metres as glTF expects. Off by default, so the two views show the same size. |
| Also write .raw.glb | Also saves the GLB as built, before GLTFLib loads and re-saves it. |

Found so far (10 November 2026):

| Source | Result |
| --- | --- |
| GLB, glTF | Exact, with the default options. |
| FBX (from a 3D suite's exporter) | Exact. Node transforms are kept; tick Apply unit scale for metres. |
| USD (`.usda` from a 3D suite's exporter, Z-up) | Positions and winding exact, but upside down: tick Negate Y and Negate Z. The UVs are wrong, because Gorilla3D's USD loader ignores `primvars:st:indices`. |

If GLTFLib refuses the GLB, the bytes are saved as `<name>.raw.glb` anyway, so they can be
inspected (for example with the Khronos glTF Validator).

## Building

Open `ImportTests.dproj` in Delphi 13 (Win64). It needs:

- Gorilla3D 1.5.4, installed as for Sprite3D;
- the GLTFMerge submodule (`git submodule update --init ImportTests/GLTFMerge`). Only its
  `GLTFLib` folder is used; GLTFMerge's own `delphi-neon` submodule is not needed;
- Sprite3D's `delphi-neon` submodule (`..\delphi-neon\Source`), which is the same Neon commit
  that GLTFLib uses;
- `..\Spritely\lib`, for the camera.

If the IDE will not take the `.dproj`, delete it and open `ImportTests.dpr`. Then add
`src;GLTFMerge\GLTFLib;..\delphi-neon\Source;..\Spritely\lib` to the project's search path.

## Files

| File | What it is |
| --- | --- |
| `ImportTests.dpr`, `ImportTests.dproj` | The program. |
| `src/ImportTests.Main.pas`, `.fmx` | The window: two views, the options and the log. The controls are made in code. |
| `src/ImportTests.GltfExport.pas` | The exporter: Gorilla3D's definitions to GLB bytes, then through GLTFLib to a file. Knows nothing of the window. |
| `GLTFMerge/` | Submodule, [G3DGames/GLTFMerge](https://github.com/G3DGames/GLTFMerge) (MIT). |
