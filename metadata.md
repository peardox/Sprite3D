# Metadata

A strip, spritesheet or atlas page on its own is just pixels. To use it in a game engine or another tool you also need to know how the frames are laid out, where each sprite's anchor point is, and how much empty space there is round each frame. With **Metadata** ticked under the Animations list, Sprite3D writes all of that to a JSON file beside every strip, spritesheet or texture atlas page it saves. This page describes the file, how each value is worked out, and where the code lives.

## When it is written

- **Which exports.** Only for **Sprite strip**, **Spritesheet** and **Texture Atlas** exports: strips and spritesheets from the batch Export button or the right-click menu's Save as sprite strip and Save as Spritesheet, atlases from batch Export. AniGifs and MP4 videos have no metadata, so the box is greyed out while either is chosen. A texture atlas always has it, since without it there is no telling the animations on a page apart: while Texture Atlas is chosen the box shows ticked and greyed out, and choosing another format shows the choice kept for strips and spritesheets again.
- **The file name.** It has the same name as the image, with the extension `.json`: `walk_strip24.png` gets `walk_strip24.json`, a spritesheet `walk.png` gets `walk.json`, and an atlas page `hero_atlas_01.png` gets `hero_atlas_01.json`. An existing file of that name is replaced.
- **When.** It is written straight after the image, on the same worker thread, from the same frames. The Debug tab logs it as, for example, `Saved ...\walk_strip24.png and its .json (24 frames)`, or for an atlas page `Saved ...\hero_atlas_01.png and its .json (5 animations, 120 frames, 4096 x 2048)`.
- **Remembered.** The box is kept between sessions as `exportMetadata` in `settings.json`, and is off to begin with.

## The file

```json
{
  "meta": {
    "page": 1,
    "page_count": 1,
    "total_frames": 8,
    "creator": "Peardox",
    "creator_url": "https://example.com/peardox",
    "modeller": "Jo Bloggs",
    "modeller_url": null,
    "artist": "Jo Bloggs",
    "artist_url": null,
    "created": "2026-10-01",
    "modified": "2026-10-23T16:40:12.345+01:00",
    "file": "C:\\Models\\hero.glb"
  },
  "image": {
    "size": { "width": 6144, "height": 256 },
    "sprite_size": { "width": 256, "height": 256 },
    "layout": { "cols": 24, "rows": 1, "frame_count": 24 },
    "origin": { "x": 127, "y": 214 },
    "sprite_empty": { "left": 58, "top": 9, "right": 61, "bottom": 30 },
    "directions": [0],
    "animations": [{ "name": "walk", "frame_count": 24, "time": 1.0333 }],
    "unused": 0,
    "two_pass": false,
    "overscan": { "enabled": true, "factor": 4 }
  },
  "camera": {
    "view": "Isometric",
    "projection": "orthographic",
    "azimuth": 45,
    "inclination": 35.2644,
    "roll": 0,
    "distance": 12.5,
    "ortho_height": 3.2,
    "pan": { "enabled": false, "x": 0, "z": 0 },
    "locked": false
  },
  "frames": [
    {
      "animation": 0,
      "direction": 0,
      "frame": 0,
      "empty": { "left": 71, "top": 12, "right": 66, "bottom": 30 }
    },
    {
      "animation": 0,
      "direction": 0,
      "frame": 1,
      "empty": { "left": 64, "top": 10, "right": 63, "bottom": 30 }
    },
    ...
  ]
}
```

On an atlas page, the frames of several animations follow one another, and an animation can carry on from one page onto the next. Here the second page of an atlas starts with the last 8 frames of `walk`, whose first 16 ended the first page, then all 12 frames of `idle`:

```json
  "image": {
    ...
    "animations": [
      { "name": "walk", "frame_count": 24, "time": 1.0333 },
      { "name": "idle", "frame_count": 12, "time": 2.0 }
    ],
    ...
  },
  "frames": [
    { "animation": 0, "direction": 0, "frame": 16, "empty": { ... } },
    ...
    { "animation": 0, "direction": 0, "frame": 23, "empty": { ... } },
    { "animation": 1, "direction": 0, "frame": 0, "empty": { ... } },
    ...
  ]
```

| Member | Meaning |
|---|---|
| `meta.page` | this image's page, from 1, as its file name numbers it; 1 for a strip or spritesheet |
| `meta.page_count` | how many pages the export made; 1 for a strip or spritesheet |
| `meta.total_frames` | how many frames the export made in all: for a texture atlas, over every page, every animation and every direction, the same on each page; for a strip or spritesheet, the file's own frames |
| `meta.creator`, `meta.creator_url` | who created the sprite set, and where their work is, from File, Save Project; `null` if not set |
| `meta.modeller`, `meta.modeller_url` | who made the models, and where their work is |
| `meta.artist`, `meta.artist_url` | who made the textures, and where their work is |
| `meta.created` | the day the project started, as `yyyy-mm-dd` |
| `meta.modified` | when this export was made: local date and time with its offset from UTC, ISO 8601 |
| `meta.file` | the model exported, as a full path; a project file uses the same to load it again |
| `image.size.width`, `image.size.height` | the whole image, in pixels: `cols` × the grab width by `rows` × the grab height, or for a power-of-2 atlas page, the page, which can be a little more |
| `image.sprite_size.width`, `image.sprite_size.height` | one frame, in pixels: the grab size from File, Settings, the same for every frame |
| `image.layout.cols`, `image.layout.rows` | the grid of cells the frames are laid out in |
| `image.layout.frame_count` | how many frames there are; a spritesheet can have more cells than frames |
| `image.origin.x`, `image.origin.y` | the pixel the model's centre of rotation falls on in every frame; integers |
| `image.sprite_empty` | the smallest empty section on each side over all the frames |
| `image.directions` | the directions the image holds, as bearings in degrees in export order; `[0]` without directions (see below) |
| `image.animations` | the animations the image holds, in the order they first appear; one for a strip or spritesheet, every one with frames on the page for an atlas |
| `image.animations[i].name` | the animation's name, as the Animations list shows it |
| `image.animations[i].frame_count` | how many frames it has in each direction, including any on other atlas pages |
| `image.animations[i].time` | how long it takes to play once, in seconds: the animation's own length, whatever number of frames it was saved at |
| `image.unused` | the number of empty cells after the last frame: `cols` × `rows` − `frame_count`; 0 on every atlas page but the last |
| `image.two_pass` | whether the frames were made by a **2-pass** export's second pass |
| `image.overscan.enabled` | whether **Overscan** was ticked in Model, Animation Settings |
| `image.overscan.factor` | the overscan factor set there, from its slider; given even when overscan is off |
| `camera.view` | the View, Camera view checked: `Variable`, `Isometric`, `Pixel2To1`, `ThreeQuarter`, `HeadOn`, `TopDown` or `Side`, as `settings.json` names them |
| `camera.projection` | `orthographic` or `perspective`, from View, Orthographic |
| `camera.azimuth`, `camera.inclination`, `camera.roll` | the three readouts, in degrees, as the dials show them, to four decimal places |
| `camera.distance` | the camera's distance from its orbit centre as the frames were captured, in scene units |
| `camera.ortho_height` | for orthographic projection, the height of scene the frames show, in scene units, as captured; `null` for perspective |
| `camera.pan.enabled`, `camera.pan.x`, `camera.pan.z` | whether the pan is applied, and the pan along the model's X and Z axes as multiples of its radius; kept even when not applied |
| `camera.locked` | whether View, Camera, Lock Camera was ticked |
| `frames[i]` | the frame in cell *i*, in cell order: one entry per frame |
| `frames[i].animation` | which animation it is, as an index into `animations` |
| `frames[i].direction` | which direction it is, as an index into `directions`; 0 without directions |
| `frames[i].frame` | which frame of that animation and direction it is, counted from 0 |
| `frames[i].empty` | its empty sections: an object with `left`, `top`, `right` and `bottom` |

The file is UTF-8 without a byte order mark, indented two spaces, or minified, with no indents or line breaks, when File, Settings, Minify JSON is ticked.

## Meta

`meta` comes first, so a tool can see what a file is and who made it before reading the rest. `page` and `page_count` say which page of how many the file describes: always 1 of 1 for a strip or spritesheet, and for a texture atlas the number in the file name, `hero_atlas_02.json` being page 2. `total_frames` counts every frame of the export, so a tool reading one atlas page knows how many to expect over them all; for a strip or spritesheet it equals the image's `frame_count`. The credits and `created` come from **File, Save Project...**, as they stand when the export starts; any not set are `null`. `modified` is the moment the export started, in local time with its offset from UTC, and `file` the full path of the model, as loaded. Credits are saved, with the model, the directions, the Animations list and the export choices, in a `.sprite3d` project file; see the README's *File, Save Project*.

## Export choices and camera

`two_pass` and `overscan` record the choices the frames were made with: whether they were made by a **2-pass** export, reframed from a first, measuring pass so the sprite fills the frame (see *Batch export* in the README), and whether overscan was on and at what factor. Overscan draws each frame larger and scales it down, so its edges are smoother; see *Overscan* in the README.

`camera` records how the model was viewed when the export started, so the same view can be set up again, or matched by other art. The angles are the readouts' own, as the dials show them. With directions, each direction turns the view on from `azimuth` by its bearing in `image.directions`; the camera's own `azimuth` is not changed by it. The camera is turned back once each capture ends, so every file of an export has the same `camera`.

`distance` and `ortho_height` are the capture's, not the on-screen view's. An export fits the camera to what it saves, as large as the grab allows, without changing the angles: a batch, a texture atlas among them, to the combined swept volume of every animation used, so every animation is framed alike, and a single animation saved from the right-click menu to its own. The view's distance slider does not take part. With perspective, `distance` sets the scale; with orthographic, `ortho_height` does, the frame showing that much of the scene top to bottom, and `distance` only places the camera.

## Frame coordinates

Each frame is measured on its own, as if it were a separate image of the grab size from File, Settings. Its top-left pixel is (0, 0) and its bottom-right pixel is (width − 1, height − 1), wherever the frame sits in the strip or spritesheet. The origin and every empty section use these coordinates.

```
 (0,0)                                (width-1, 0)
   +----------------------------------+
   |            top                   |
   |        +-----------+             |
   |  left  |  sprite   |    right    |
   |        |     +     |             |    + origin
   |        +-----------+             |
   |            bottom                |
   +----------------------------------+
 (0, height-1)                    (width-1, height-1)
```

## Layout

- **Sprite strip.** Every frame in one row, left to right: `cols` is the frame count and `rows` is 1. Frame *i* is the cell starting at x = *i* × width.
- **Spritesheet.** A square grid, as small as holds every frame: `cols` = `rows` = ⌈√frame_count⌉, so 30 frames make a 6 × 6 grid. Frame *i* is in column *i* mod `cols` and row *i* div `cols`, filling each row left to right before going down. Any cells after the last frame are fully transparent and are not listed in `frames`; `unused` counts them, 6 for 30 frames.
- **Texture atlas page.** The frames of the batch's animations, in the Animations list's order, each one's frames straight after the last one's, filling the grid the same way and carrying on onto the next page when this one is full. The grid is chosen for the page: see *Texture atlas pages* below.

`frames[i]` is the frame in cell *i*, in that order, and says itself which animation, direction and frame it is, so nothing has to be counted to find a frame. `frame` matches the frame numbers in the Animations list's readout less one: frame 1 there is `"frame": 0`.

## Texture atlas pages

A batch exported as **Texture Atlas** is packed onto pages no larger than the **Page size** from Model, Animation Settings each way (1k to 16k pixels):

1. **Capacity.** A full page holds ⌊page size ÷ grab width⌋ × ⌊page size ÷ grab height⌋ frames: 16 × 16 = 256 frames of 256 × 256 at 4k.
2. **Packing.** Every frame of every animation is taken in turn, in list order, and goes in the next cell. When a page is full the next frame starts a new page, even in the middle of an animation, so every page but the last is completely full, `unused` 0, and an animation of any length fits.
3. **Sizing.** Each page is then made as small as its frames allow; a full page is the largest page.
   - **Power of 2** (the default): every pair of power-of-2 widths and heights up to the page size is tried, and the one with the least area whose grid of whole cells holds the frames wins, the squarer of two the same; the grid is every whole cell that fits, so `cols` = width ÷ grab width, rounded down, and likewise `rows`. Five 256-pixel frames, say, make a 512 × 1024 page of 2 × 4 cells, 3 unused.
   - **Pages need not be a power of 2**: every number of columns is tried, with as many rows as it needs, and the least area, then the squarest, wins; the page is exactly `cols` × `rows` cells.
4. **Naming.** Pages are numbered from 01: `<model>_atlas_01.png`, `_02` and so on, each with its own `.json`. Any `<model>_atlas_<number>.png` already in the folder, with its `.json`, is deleted first, so an earlier atlas with more pages leaves none behind.

A page's `animations` lists only the animations with frames on that page; each one's `frame_count` still gives its whole length, and `frame` in each entry says which part of it the page holds. A page's `origin` is the first animation's on it. Every animation of a batch is framed with the same camera, so they all share one; if they ever differ, the Debug tab says so.

## Empty sections

A frame's **empty sections** are the fully transparent columns and rows along its edges:

- `left`: the number of columns, counted from the left edge, before the first column that has anything in it.
- `right`: the number of columns after the last column that has anything in it.
- `top` and `bottom`: the same for rows.

So what the frame holds lies in columns `left` to width − 1 − `right` and rows `top` to height − 1 − `bottom`, and that rectangle is the sprite's tight bounding box in that frame.

**Empty means alpha 0.** A pixel counts as empty only when it is fully transparent. Anything at all drawn there, however faint, counts as part of the sprite, so soft anti-aliased edges and any slight halo from overscan resampling are kept inside the box, never cut off.

**A frame with nothing in it** (the model has moved out of shot, say) is empty from every side: `left` and `right` are its width, and `top` and `bottom` its height. It then never lowers `sprite_empty`.

Each frame is scanned once, row by row, reading only the alpha byte of each pixel. That is quick even for long animations at large grab sizes, and is done on the worker thread with the rest of the saving.

## Sprite empty

`sprite_empty` takes, for each side separately, the **smallest** empty section over all the frames:

```
sprite_empty.left   = min over frames of left
sprite_empty.top    = min over frames of top
sprite_empty.right  = min over frames of right
sprite_empty.bottom = min over frames of bottom
```

Cropping every frame by these four amounts gives frames that are all the same size and still hold all of every frame. The sprite never shifts within its cell from one frame to the next, so the animation plays without jitter. A crop of each frame by its own empty sections would be tighter, but then each frame would need its own offset, which each `frames[i].empty` also gives you.

The cropped frame is (width − `left` − `right`) by (height − `top` − `bottom`), and the origin within it is (`origin.x` − `left`, `origin.y` − `top`), using the `sprite_empty` values.

## Origin

The origin is the model's **centre of rotation**: its own origin, (0, 0, 0) in the model file, which the camera orbits and which [Volumes](volumes.md) explains. For a character it is often between the feet, which makes it a natural anchor or pivot for the sprite.

1. **Framed once.** The camera is framed once for the whole export, and the model never moves during it, so the origin falls in the same place in every frame. It is worked out once, as the capture starts.
2. **Projected.** The centre of rotation is carried into the camera's space and through the camera's own projection for the grab size, in perspective or orthographic projection as the view is set. That gives where it falls in a frame, to a fraction of a pixel. This is `TSprite3DCamera.ProjectToView`.
3. **Put on a pixel.** The view is then slid, by less than half a pixel across and down, so that the centre of rotation falls exactly on the centre of the pixel it was in. The slide is exact in orthographic projection and very nearly so in perspective, so the point is projected again after each slide, up to four times, until it is within a hundredth of a pixel of the centre. This is `SnapCaptureOrigin` in the main form.
4. **Reported.** The origin is that pixel's column and row, written as JSON integers (`127`, never `127.0`), and the sprite is drawn so that it really is there.

The slide is made for every strip and spritesheet, whether or not Metadata is ticked, so an image is the same either way. It is far smaller than anything the framing would notice, and the view on screen is put back when the export ends, even when View, Camera, Lock Camera is ticked. With overscan on, each frame's shifted drawings are spread evenly round the same pixel, so the origin stays on it.

If the centre of rotation is behind the camera, which a hand-placed locked camera could manage, it has no place in the frame, and `x` and `y` are `null`.

The origin can lie outside the frame, or inside a frame's empty sections, if the model's own origin is away from its geometry. It is reported all the same.

## Animations

`animations` lists the animations the image holds, in the order they first appear in it, one object each:

- `name`, as the Animations list shows it, such as `"walk"`, or `"(None)"` for the still of the bind pose.
- `frame_count`, its whole frame count in each direction, wherever its frames are.
- `time`, how long it takes to play once, in seconds. This is the animation's own length, and stays the same when its number of frames is changed in the Animations list: fewer frames over the same time is a lower frame rate for that animation alone. `frame_count / time` is the rate to play it back at. The still of the bind pose, one frame, is given 1 second.

A strip or spritesheet holds one animation, so it has a single entry; an atlas page lists every animation with frames on it. Each `frames[i]` names its animation by its index in `animations`, so an animation's frames are found by their `animation`, and put in order by their `frame`, across as many pages as they span.

## Unused

`unused` is the number of cells of the grid after the last frame, which are fully transparent: `cols` × `rows` − `frame_count`. It is 0 for a strip, can be more for a spritesheet whose frames don't make a square, and is 0 on every atlas page but the last, which counts the room left over.

## Directions

`directions` lists the directions the image holds, as compass bearings in degrees, in the order they were exported: with **Directions** ticked under the Animations list, every direction of Model, Directions, in the order set there, such as `[90, 180, 270, 0, 135, 225, 315, 45]`. Each frame's `direction` is an index into it. Without directions, `directions` is `[0]`, a single dummy entry, and every frame's `direction` is 0.

With directions, each animation is captured once per direction, in their order, before the next animation:

- **Sprite strip.** One row per direction, in order: `cols` is the frames of one direction and `rows` the number of directions. The file is still `<animation>_strip<frames>.png`, `<frames>` being one direction's.
- **Spritesheet.** Every direction's frames, the first direction's then the next's, in the square grid.
- **Texture atlas.** The same order, each animation's directions in turn, filling the pages as before; a page's `animations` lists each animation once, whatever directions of it the page holds.
- **AniGif and MP4.** One file per direction, `<animation>_dir01.gif`, `_dir02` and so on, numbered in direction order; they have no metadata.

Each animation's `frame_count` is the frames of one direction of it, which is how many each direction has, and the range of each frame's `frame`; its `time` is likewise one direction's.

## In the code

| Where | What |
|---|---|
| `src/lib/Sprite3DSpriteSheet.pas` | `TSprite3DFrameEmpty`, `MeasureFrameEmpty` (one frame's empty sections) and `SaveSheetMetadata` (the whole file, from a `TSprite3DSheetInfo`), beside `ComposeStrip`, `ComposeSheet`, and `PlanAtlasPages` with `ComposeAtlasPage` for atlas pages |
| `src/lib/Sprite3DCamera.pas` | `TSprite3DCamera.ProjectToView`, where a point falls in a view of a given size, and `ShiftView`, which slides the view by pixels |
| `src/ui/Sprite3dMain.pas` | `StartCapture` decides whether metadata is written; `SnapCaptureOrigin` puts the origin on a pixel; `SaveSheet` writes a strip or spritesheet and then its `.json`; `SaveAtlasBatch` and `SaveAtlas` make and write the atlas pages at the end of a batch; `EndCapture` undoes the slide |
| `src/ui/Sprite3DHelpers.pas` | the `ExportMetadata`, `ExportDirections`, `AtlasPageSize` and `AtlasNonPowerOf2` settings |
| `src/ui/Sprite3DAnimationForm.pas` | Model, Animation Settings, with the Texture Atlas page size and power-of-2 choice |

Each routine's own documentation comments, in the source, give the details.

## Limits

- **Alpha 0 only.** The threshold is fixed at fully transparent. A model with a faint glow, or a background that isn't transparent, leaves little or no empty section.
- **One origin per image.** The framing never changes within an export, and turning the camera to a direction turns it about a point on the turning axis, which the centre of rotation is on, so one origin serves every frame of every direction. With View, Camera, Variable, Pan ticked the camera turns about a point off that axis, so the model moves round the frame from one direction to another.
- **Cells are not trimmed.** Strips, spritesheets and atlas pages keep every cell at the full grab size; the metadata only says how much could be cropped.

## Further reading

- [Sprite (computer graphics)](https://en.wikipedia.org/wiki/Sprite_(computer_graphics)), Wikipedia: sprites, strips and sheets.
- [Texture atlas](https://en.wikipedia.org/wiki/Texture_atlas), Wikipedia: many images packed into one, as the Texture Atlas export does.
- [Power of two](https://en.wikipedia.org/wiki/Power_of_two#Computer_science), Wikipedia: why textures have often been kept to power-of-2 sizes.
- [Alpha compositing](https://en.wikipedia.org/wiki/Alpha_compositing), Wikipedia: what the alpha channel holds, and why only alpha 0 is truly empty.
- [Minimum bounding box](https://en.wikipedia.org/wiki/Minimum_bounding_box), Wikipedia: the tight box the empty sections describe.
- [3D projection](https://en.wikipedia.org/wiki/3D_projection), Wikipedia: perspective and orthographic projection, as used to place the origin.
- [Volumes](volumes.md): how each export is framed, and the centre of rotation.
- [Directions](directions.md): the directions `directions` lists.
