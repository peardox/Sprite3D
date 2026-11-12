# Textures

Some model kits name textures that Gorilla3D cannot load: an image in a format it does not read, or a file that is not where the model says. Sprite3DBuilder met every case below on 11 November 2026, importing the packs of three artists (KayKit, Zerin and Quaternius), and fixed them in one unit, `Sprite3DModelTextures.pas`. Sprite3D loads the same kits, so since 12 November 2026 both programs use that unit, from the repository's `Shared/` folder. This page says what goes wrong, why, how the unit deals with it, and how Sprite3D calls it.

## What goes wrong

### A texture in a format the loader does not read

Zerin's text-glTF packs (Retro-Atlantis, Cave, Clocktower and Pyramid) name their textures as Photoshop documents:

```
"uri": "atlas_retroAtlantis_varB_v00.psd"
```

Gorilla3D refuses the whole model, by the file's extension:

```
AssetsManager.TextureAsset - unsupported file format ".psd"
```

The `.psd` files are there. Some have a PNG of a similar name beside them, others have none, so guessing another file's name cannot fix it. The image has to be read and made into something the loader takes.

The loader is only trusted with **PNG and JPEG**, which FMX reads on every platform. Anything else is converted.

### A texture or buffer that is not where the model says

A glTF names its files by relative `uri`. Kits get this wrong in several ways:

| Kit | The model names | The file is |
|---|---|---|
| Quaternius, Modular SciFi MegaKit | `T_Trim_01_Normal.png`, beside `glTF\Columns\Column_Round.gltf` | one folder up, in `glTF\` |
| Quaternius, a Godot sample project in a pack | `Cards_Atlas.png`, beside the model | in another folder of the project |
| Quaternius, Sci-Fi Essentials Kit (its Godot engine project) | `T_Enemies_BaseColor_png.png` | `T_Enemies_BaseColor.png`: Godot's importer put the extension into the name |
| Quaternius, Modular SciFi MegaKit | buffer `Decal_Line_90_001.bin` | `Decal_Line_90.bin`: Blender adds `_001` or `.001` to a name it has seen before |

A missing image or buffer makes Gorilla3D fail the whole model:

```
image file "T_Enemies_BaseColor_png.png" not found (model "...")
buffer file "Decal_Line_90_001.bin" not found (model "...")
```

### Gorilla3D does not take a full path in a uri

The obvious way to point a model at a file somewhere else, a copy of the glTF whose `uri` is a full path, does not work. Gorilla3D joins every `uri` to the glTF's own folder, so a full path is never found, even when the file is there:

```
buffer file "E:\...\arch_atlantis_floorEdge_1line.bin" not found
  (model "...\thumbnails\models\<key>.gltf")
```

**Every file a glTF names must be in the glTF's folder or below it, named relatively.**

### A PSD's extra channels are not transparency

Converted naively, Zerin's PSD atlases came out black with coloured specks. Vampyre, like many readers, takes any channel after the colour ones for alpha. In a PSD those channels are **saved selections and masks** as a rule. The first of them is the merged image's transparency only when the file stores its layer count as a **negative number**, which is Photoshop's own flag for it. Zerin's atlases have one saved selection, mostly empty, so most pixels came out with alpha 0, and FMX's premultiplied bitmaps turned those black.

The layer count is in the layer and mask section: in the layer info, or, at 16 and 32 bits a channel, where the layer info is empty, in an `Lr16`, `Lr32` or `Layr` tagged block after the global layer mask info. A large document (`.psb`, version 2) has 8-byte section lengths, and 8-byte lengths for those keys among others. A file with no layers has no transparency: Photoshop cannot save a flattened image with a transparent background.

### FMX's OpenGL context cannot make a texture from a 24-bit PNG

The first fix for the black textures saved opaque PNGs as 24-bit RGB. Every one then failed on Windows:

```
cannot create texture by TContextOpenGLWindows (Error = 1282)
```

**Never hand the loader a 24-bit PNG.** Opaque images go through 24 bits (which drops the extra channels) and back to 32 bits with alpha; Vampyre fills alpha with 255 on the way back.

## How the unit deals with it

`PrepareModelTextures(AModelFile, ACacheFolder, AKey, out AFixes)` is called before every load of a glTF (`.gltf`), by both programs, and returns the file to load. For every image the glTF names, it tries, in this order, the extension asked for always first:

1. The file named, if it is PNG or JPEG: used as it is.
2. The file named, in any other format Vampyre reads: made a PNG.
3. Only if the file named is not there, or cannot be read: the same file name, case ignored, nearest first. The places are the folder named and the model's folder, then the whole tree of each of the model folder's parents, up to three levels up. A disk's root, or a folder directly in it, is never searched, nor a tree of more than 100,000 files.
4. Only then, the same name with another extension, in the same places: PNG first, then JPEG, then anything Vampyre reads, made a PNG.
5. Then the name less an image extension left in it (`T_Enemies_BaseColor_png` becomes `T_Enemies_BaseColor`), in the same places.
6. Failing all of those, a 16-pixel magenta and black checker, `missing-texture.v1.png`, so the model still loads and its picture shows where the texture is missing.

A missing **buffer** is looked for by the same name in the same places, then, beside the model, under the model's own name or the name without a copy number (`_001`, `.001`). Only a file of exactly the `byteLength` the glTF gives the buffer is taken, so a wrong `.bin` cannot slip in. A buffer has no placeholder: without its geometry there is nothing to draw.

If anything had to be found or made, the model is loaded from a **copy** of the glTF in the cache's `models` folder, named after `AKey`. Every file the copy names (buffers, textures used as they are, and PNGs made) is copied **beside it**, named after the SHA-256 of its content, and every `uri` is a bare file name. A texture a hundred models share is there once, and is made or copied again only when it changes. PNGs made are named after the SHA-256 of their source with a version, `<sha>.v3.png` (`MADE_PNG_VERSION`), so changing how they are made never reuses old ones. The kit's own files are never written.

Each texture's outcome comes back in `AFixes`, for the caller to log: as named, converted, another file used (with the reason), or missing.

### Speed

The first version took 3 to 9 seconds a model on the Modular SciFi MegaKit, about a second a texture; the copy then loaded in 0.3 s. Three things were slow, and each is now done once:

- **Folder listings.** Each folder or tree searched is listed once and indexed by file name, and by name without extension for images (`TFolderListing`, `FolderListing`). Listings are kept for 30 minutes, so finding a file is a lookup, not a scan. The search stops at the first place with a usable file.
- **Whether an extension is an image.** Asked of Vampyre (`IsFileFormatSupported`) once per extension, not once per file.
- **SHA-256 of each file.** Kept for the session (`ContentHash`), and worked out again only if the file's size or write time changes.

## How Sprite3D uses it

1. **Vampyre** is the repository's `imaginglib` submodule, unchanged, used by both programs. It is pure Pascal and has no run-time libraries, so it builds for every platform Sprite3D targets.
2. **The project** has Vampyre's four folders on its base search path (`..\imaginglib\Source;..\imaginglib\Source\Libs;..\imaginglib\Extensions;..\imaginglib\Extensions\Libs`) and two defines: `DONT_LINK_JPEG2000`, as its OpenJPEG C objects exist for only some platforms and would break the others, and `DONT_LINK_WEBP`, which leaves out a WebP decoder that gives compiler hints and that model kits rarely need.
3. **The unit** is `Shared/Sprite3DModelTextures.pas`, shared with Sprite3DBuilder. It uses only `OSPaths` and `JsonText`, Vampyre and the RTL.
4. **The call.** `LoadModelFile` (`Sprite3D/ui/Sprite3DHelpers.pas`) calls `PrepareModelTextures` for a `.gltf` before `AModel.LoadFromFile`, and loads the file it returns. The cache is the settings folder, so the copies are in its `models` folder, beside `bounds`; the key naming a copy is the SHA-256 of the model file (`THashSHA2.GetHashStringFromFile`), worked out only for a `.gltf`. The fixes come back through `LoadModelFile`'s `AFixes`; `BuildLoadModel` writes each one that is not `toAsNamed` to the Debug tab, worded by `TextureFixText` as Sprite3DBuilder's `ReportTextures` words them, and says when the model was loaded from a copy (`LoadedFromCopy`). The model's slot, its bounds cache and the last model remembered all keep the model's own file name.
5. **The licence.** Vampyre is MPL 2.0: file-level copyleft, so Sprite3D's own files are not affected. `licences/Vampyre-LICENSE.txt` (the address, "used unmodified", then the MPL text) is in File, Licences, and `docs/licences-required.md` has its section.

`LoadModelFile` keeps `TAnimationCachingFlag.VertexPosition`, as Sprite3D plays animations. Sprite3DBuilder turns it off, as a thumbnail does not need it and it costs 40 to 100 ms for each rigged model.

File, Debug, glTF still reads a glTF from its own file (`LoadModelDocument`), so a kit with `.psd` textures fails there.

## Pitfalls met on the way

- **`Default()` is hidden in any unit that uses `Gorilla.DefTypes`**, which declares a `Default` of its own: `Result := Default(TSomeRecord)` gives E2066 and a cascade. Zero records field by field there.
- **Generics.** A unit that starts using `TDictionary` or `TObjectDictionary` needs `System.Generics.Collections` in its uses clause.
- **`PAlphaColorArray`** is not declared in the units a form usually uses. Read a bitmap's pixels through `PByte` arithmetic (`PCardinal(Row + X * 4)^`), as `MeasureVisible` in Sprite3DBuilder does.
- **Gorilla3D's own debug output** for rigged models (`node X_Armature in hierarchy, but not attached to skin`, `FMX.Ani.TAnimation.AniThread not available anymore`) is harmless.

## Where the code is

In `Shared/Sprite3DModelTextures.pas`:

| What | Where |
|---|---|
| The order of the search | `ResolveTexture` |
| Buffers | `ResolveBuffer`, `WithoutCopyNumber`, `LengthFits` |
| A name with an image's extension in it | `WithoutNamedExtension`, `PlaceBaseMatches` |
| Where to look | `SearchPlaces`, `TooHighToSearch`, `SEARCH_LEVELS_UP`, `TREE_FILE_LIMIT` |
| Listings and their indexes | `TFolderListing`, `FolderListing`, `LISTING_KEEP_MS` |
| PSD transparency | `MergedAlpha`, `ReadBigEndian` |
| Making a PNG | `MakePng`, `MADE_PNG_VERSION` |
| The copy and its files | `PrepareModelTextures`, `CopyIn`, `ContentHash`, `SetUri` |
| The placeholder | `PlaceholderTexture`, `PLACEHOLDER_FILE_NAME` |

Sprite3D's `README.md` (*Textures*, under Features) and Sprite3DBuilder's (*Textures*) describe the same for users.
