//** @abstract(Lays out a sequence of frames as a sprite strip, a spritesheet, texture atlas
//** pages or an animated GIF, and writes them to files.)
//**
//** The frames are TSprite3DImage records: plain RGBA pixels with straight (not
//** premultiplied) alpha, top row first, all the same size. ImageFromBitmap makes one from an
//** FMX bitmap, such as a grab from TSprite3DOffscreen, so the frames take no GPU resources
//** and no canvas is involved.
//**
//** ComposeStrip puts the frames side by side in one row; ComposeSheet puts them in a square
//** grid, left to right and then top to bottom. SavePng writes such an image as a PNG file and
//** SaveAnimatedGif writes the frames as a looping GIF. Both writers are plain Pascal over
//** streams, using only System.ZLib, so they behave the same on every platform and are not
//** limited by the largest bitmap the GPU or FMX canvas accepts: a strip of a hundred frames
//** of 256 pixels is written as easily as a single frame.
//**
//** GIF keeps 256 colours per frame and on/off transparency, so each frame gets its own
//** palette of up to 255 colours, chosen by median cut, plus one transparent entry; pixels
//** less than half opaque become transparent. Every frame replaces the last (disposal "restore
//** to background"), so transparent sprites animate cleanly.
//**
//** A texture atlas puts the frames of several animations on shared pages: PlanAtlasPages
//** decides which frames go on each page, filling every page but the last, and how large
//** each page is, and ComposeAtlasPage lays a page out.
//**
//** MeasureFrameEmpty measures the fully transparent border round a frame, and
//** SaveSheetMetadata writes a strip's, a spritesheet's or an atlas page's metadata as JSON
//** beside it: the image's size and layout, where the model's centre of rotation falls in a
//** frame, the animations it holds, and each frame's transparent border with the smallest of
//** each side over all of them.
//**
//** Nothing here keeps state, and every routine may be called on any thread, except
//** ImageFromBitmap, which reads an FMX bitmap and so belongs on the main thread.
//**
//** @preformatted(
//** frames: TArray<TSprite3DImage>
//** |-- ComposeStrip  -> TSprite3DImage, Count x 1 frames  -> SavePng
//** |-- ComposeRows   -> TSprite3DImage, rows of N frames   -> SavePng
//** |-- ComposeSheet  -> TSprite3DImage, N x N frames      -> SavePng
//** |-- PlanAtlasPages, then ComposeAtlasPage per page     -> SavePng
//** |-- SaveAnimatedGif                                    -> .gif
//** `-- SaveSheetMetadata, from MeasureFrameEmpty          -> .json beside the .png
//** )
unit Sprite3DSpriteSheet;

{
  Lays out a sequence of frames as a sprite strip, a spritesheet, texture
  atlas pages or an animated GIF, and writes them to files.

  The frames are TSprite3DImage records: plain RGBA pixels with straight
  (not premultiplied) alpha, top row first, all the same size.
  ImageFromBitmap makes one from an FMX bitmap, such as a grab from
  TSprite3DOffscreen, so the frames take no GPU resources and no canvas is
  involved.

  ComposeStrip puts the frames side by side in one row; ComposeSheet puts
  them in a square grid, left to right and then top to bottom. SavePng
  writes such an image as a PNG file and SaveAnimatedGif writes the frames
  as a looping GIF. Both writers are plain Pascal over streams, using only
  System.ZLib, so they behave the same on every platform and are not limited
  by the largest bitmap the GPU or FMX canvas accepts: a strip of a hundred
  frames of 256 pixels is written as easily as a single frame.

  GIF keeps 256 colours per frame and on/off transparency, so each frame
  gets its own palette of up to 255 colours, chosen by median cut, plus one
  transparent entry; pixels less than half opaque become transparent. Every
  frame replaces the last (disposal "restore to background"), so transparent
  sprites animate cleanly.

  A texture atlas puts the frames of several animations on shared pages:
  PlanAtlasPages decides which frames go on each page, filling every page
  but the last, and how large each page is, and ComposeAtlasPage lays a page
  out.

  MeasureFrameEmpty measures the fully transparent border round a frame,
  and SaveSheetMetadata writes a strip's, a spritesheet's or an atlas page's
  metadata as JSON beside it: the image's size and layout, where the model's
  centre of rotation falls in a frame, the animations it holds, and each
  frame's transparent border with the smallest of each side over all of
  them.

  Nothing here keeps state, and every routine may be called on any thread,
  except ImageFromBitmap, which reads an FMX bitmap and so belongs on the
  main thread.

    frames: TArray<TSprite3DImage>
    |-- ComposeStrip  -> TSprite3DImage, Count x 1 frames  -> SavePng
    |-- ComposeRows   -> TSprite3DImage, rows of N frames   -> SavePng
    |-- ComposeSheet  -> TSprite3DImage, N x N frames      -> SavePng
    |-- PlanAtlasPages, then ComposeAtlasPage per page     -> SavePng
    |-- SaveAnimatedGif                                    -> .gif
    `-- SaveSheetMetadata, from MeasureFrameEmpty          -> .json beside the .png
}

interface

uses
  System.SysUtils, System.Classes, System.Types, FMX.Graphics;

type
  //** @abstract(An image as plain RGBA bytes with straight alpha, top row first.)
  //**
  //** Pixel (X, Y) starts at byte @code(@(Y * Width + X@) * 4) of Pixels, in the order red,
  //** green, blue, alpha. The colour is not premultiplied by alpha, as PNG and GIF expect.
  //** A record of value type apart from Pixels, which is a reference-counted dynamic array,
  //** so copies share the pixels until one is changed through SetLength or a new array.
  /// <summary>An image as plain RGBA bytes with straight alpha, top row first.</summary>
  /// <remarks>Pixel (X, Y) starts at byte <c>(Y * Width + X) * 4</c> of Pixels, in the order
  /// red, green, blue, alpha. The colour is not premultiplied by alpha, as PNG and GIF expect.
  /// A record of value type apart from Pixels, which is a reference-counted dynamic array, so
  /// copies share the pixels until one is changed through SetLength or a new array.</remarks>
  TSprite3DImage = record
    //** @abstract(The width in pixels.)
    /// <summary>The width in pixels.</summary>
    Width: Integer;
    //** @abstract(The height in pixels.)
    /// <summary>The height in pixels.</summary>
    Height: Integer;
    //** @abstract(Width * Height * 4 bytes of RGBA, top row first.)
    /// <summary>Width * Height * 4 bytes of RGBA, top row first.</summary>
    Pixels: TBytes;
    //** @abstract(A new image of the given size with every pixel fully transparent.)
    //**
    //** @param(AWidth The width in pixels; at least 1.)
    //**
    //** @param(AHeight The height in pixels; at least 1.)
    //**
    //** @returns(The image.)
    //**
    //** @raises(EArgumentException If either size is less than 1.)
    //**
    //** @raises(EOutOfMemory If the pixels cannot be allocated.)
    /// <summary>A new image of the given size with every pixel fully transparent.</summary>
    /// <param name="AWidth">The width in pixels; at least 1.</param>
    /// <param name="AHeight">The height in pixels; at least 1.</param>
    /// <returns>The image.</returns>
    /// <exception cref="EArgumentException">If either size is less than 1.</exception>
    /// <exception cref="EOutOfMemory">If the pixels cannot be allocated.</exception>
    class function Create(const AWidth, AHeight: Integer): TSprite3DImage; static;
  end;

  //** @abstract(The fully transparent border round a frame: how many whole columns or rows
  //** at each edge have nothing in them.)
  //**
  //** The frame's pixels run from (0, 0) at the top left to (width - 1, height - 1) at the
  //** bottom right. Left is the number of columns from the left edge before the first one
  //** with any pixel that is not fully transparent, Right the number after the last such
  //** column, and Top and Bottom the same for rows; so what is drawn lies in columns Left to
  //** width - 1 - Right and rows Top to height - 1 - Bottom. A frame with nothing in it at all
  //** is empty from every side: Left and Right are its width, Top and Bottom its height.
  /// <summary>The fully transparent border round a frame: how many whole columns or rows at
  /// each edge have nothing in them.</summary>
  /// <remarks>The frame's pixels run from (0, 0) at the top left to (width - 1, height - 1)
  /// at the bottom right. Left is the number of columns from the left edge before the first
  /// one with any pixel that is not fully transparent, Right the number after the last such
  /// column, and Top and Bottom the same for rows; so what is drawn lies in columns Left to
  /// width - 1 - Right and rows Top to height - 1 - Bottom. A frame with nothing in it at all
  /// is empty from every side: Left and Right are its width, Top and Bottom its
  /// height.</remarks>
  TSprite3DFrameEmpty = record
    //** @abstract(Empty columns at the left edge.)
    /// <summary>Empty columns at the left edge.</summary>
    Left: Integer;
    //** @abstract(Empty rows at the top edge.)
    /// <summary>Empty rows at the top edge.</summary>
    Top: Integer;
    //** @abstract(Empty columns at the right edge.)
    /// <summary>Empty columns at the right edge.</summary>
    Right: Integer;
    //** @abstract(Empty rows at the bottom edge.)
    /// <summary>Empty rows at the bottom edge.</summary>
    Bottom: Integer;
  end;

  //** @abstract(A run of one animation's frames on a texture atlas page.)
  /// <summary>A run of one animation's frames on a texture atlas page.</summary>
  TSprite3DAtlasSlice = record
    //** @abstract(The animation, as an index into the frame counts given to PlanAtlasPages.)
    /// <summary>The animation, as an index into the frame counts given to
    /// PlanAtlasPages.</summary>
    Animation: Integer;
    //** @abstract(Its first frame on the page, counted from 0 within the animation.)
    /// <summary>Its first frame on the page, counted from 0 within the animation.</summary>
    First: Integer;
    //** @abstract(How many of its frames, from First on, are on the page.)
    /// <summary>How many of its frames, from First on, are on the page.</summary>
    Count: Integer;
  end;

  //** @abstract(One page of a texture atlas, as PlanAtlasPages lays it out.)
  /// <summary>One page of a texture atlas, as PlanAtlasPages lays it out.</summary>
  TSprite3DAtlasPage = record
    //** @abstract(The runs of frames on the page, in order: which animation, and which of its
    //** frames.)
    /// <summary>The runs of frames on the page, in order: which animation, and which of its
    /// frames.</summary>
    Slices: TArray<TSprite3DAtlasSlice>;
    //** @abstract(The number of frames on the page, the Count of all its slices.)
    /// <summary>The number of frames on the page, the Count of all its slices.</summary>
    FrameCount: Integer;
    //** @abstract(The columns of the page's grid of cells.)
    /// <summary>The columns of the page's grid of cells.</summary>
    Cols: Integer;
    //** @abstract(The rows of the page's grid of cells.)
    /// <summary>The rows of the page's grid of cells.</summary>
    Rows: Integer;
    //** @abstract(The page's width in pixels: a power of 2, or Cols cells wide.)
    /// <summary>The page's width in pixels: a power of 2, or Cols cells wide.</summary>
    Width: Integer;
    //** @abstract(The page's height in pixels: a power of 2, or Rows cells high.)
    /// <summary>The page's height in pixels: a power of 2, or Rows cells high.</summary>
    Height: Integer;
  end;

  //** @abstract(Which frame of which animation and direction an image's frame is.)
  /// <summary>Which frame of which animation and direction an image's frame is.</summary>
  TSprite3DFrameRef = record
    //** @abstract(The animation, as an index into TSprite3DSheetInfo.Animations.)
    /// <summary>The animation, as an index into TSprite3DSheetInfo.Animations.</summary>
    Animation: Integer;
    //** @abstract(The direction, as an index into TSprite3DSheetInfo.Directions; 0 for the
    //** single dummy direction.)
    /// <summary>The direction, as an index into TSprite3DSheetInfo.Directions; 0 for the
    /// single dummy direction.</summary>
    Direction: Integer;
    //** @abstract(The frame within that animation and direction, counted from 0.)
    /// <summary>The frame within that animation and direction, counted from 0.</summary>
    Frame: Integer;
  end;

  //** @abstract(The @code(camera) section SaveSheetMetadata writes: the camera as the export
  //** started.)
  //**
  //** The angles are the readouts' own, as the dials show them; with directions, each
  //** direction's bearing turns the view on from Azimuth.
  /// <summary>The <c>camera</c> section SaveSheetMetadata writes: the camera as the export
  /// started.</summary>
  /// <remarks>The angles are the readouts' own, as the dials show them; with directions,
  /// each direction's bearing turns the view on from Azimuth.</remarks>
  TSprite3DSheetCamera = record
    //** @abstract(The View, Camera view checked, such as Isometric or Variable.)
    /// <summary>The View, Camera view checked, such as Isometric or Variable.</summary>
    View: String;
    //** @abstract(True for orthographic projection, False for perspective.)
    /// <summary>True for orthographic projection, False for perspective.</summary>
    Orthographic: Boolean;
    //** @abstract(The Azimuth readout, in degrees.)
    /// <summary>The Azimuth readout, in degrees.</summary>
    Azimuth: Single;
    //** @abstract(The Inclination readout, in degrees.)
    /// <summary>The Inclination readout, in degrees.</summary>
    Inclination: Single;
    //** @abstract(The Roll readout, in degrees.)
    /// <summary>The Roll readout, in degrees.</summary>
    Roll: Single;
    //** @abstract(The camera's distance from its orbit centre as the frames were captured,
    //** in scene units.)
    //**
    //** The export fits the camera to what it saves, so this is the capture's distance, not
    //** the on-screen view's: for a batch, fitted to the combined swept volume of every
    //** animation used.
    /// <summary>The camera's distance from its orbit centre as the frames were captured, in
    /// scene units.</summary>
    /// <remarks>The export fits the camera to what it saves, so this is the capture's
    /// distance, not the on-screen view's: for a batch, fitted to the combined swept volume
    /// of every animation used.</remarks>
    Distance: Single;
    //** @abstract(The height of scene the frames show, in scene units, as captured; used
    //** only with Orthographic.)
    /// <summary>The height of scene the frames show, in scene units, as captured; used only
    /// with Orthographic.</summary>
    OrthoHeight: Single;
    //** @abstract(Whether the pan is applied.)
    /// <summary>Whether the pan is applied.</summary>
    PanEnabled: Boolean;
    //** @abstract(The pan along the model's X axis, as a multiple of its radius.)
    /// <summary>The pan along the model's X axis, as a multiple of its radius.</summary>
    PanX: Single;
    //** @abstract(The pan along the model's Z axis, as a multiple of its radius.)
    /// <summary>The pan along the model's Z axis, as a multiple of its radius.</summary>
    PanZ: Single;
    //** @abstract(Whether View, Camera, Lock Camera is ticked.)
    /// <summary>Whether View, Camera, Lock Camera is ticked.</summary>
    Locked: Boolean;
  end;

  //** @abstract(The @code(meta) section SaveSheetMetadata writes first: which page, who made
  //** it, and when; and the export's choices and camera, for the other sections.)
  //**
  //** Empty text is written as @code(null). TwoPass and the overscan go in the @code(image)
  //** section, and Camera is the @code(camera) section.
  /// <summary>The <c>meta</c> section SaveSheetMetadata writes first: which page, who made
  /// it, and when; and the export's choices and camera, for the other sections.</summary>
  /// <remarks>Empty text is written as <c>null</c>. TwoPass and the overscan go in the
  /// <c>image</c> section, and Camera is the <c>camera</c> section.</remarks>
  TSprite3DSheetMeta = record
    //** @abstract(This image's page, from 1, as its file name numbers it; 1 for a strip or
    //** spritesheet.)
    /// <summary>This image's page, from 1, as its file name numbers it; 1 for a strip or
    /// spritesheet.</summary>
    Page: Integer;
    //** @abstract(How many pages the export made; 1 for a strip or spritesheet.)
    /// <summary>How many pages the export made; 1 for a strip or spritesheet.</summary>
    PageCount: Integer;
    //** @abstract(How many frames the export made in all, over every page; 0 or less means
    //** this image's frames, as for a strip or spritesheet.)
    /// <summary>How many frames the export made in all, over every page; 0 or less means this
    /// image's frames, as for a strip or spritesheet.</summary>
    TotalFrames: Integer;
    //** @abstract(Who created the sprite set.)
    /// <summary>Who created the sprite set.</summary>
    Creator: String;
    //** @abstract(Where the creator's work is.)
    /// <summary>Where the creator's work is.</summary>
    CreatorUrl: String;
    //** @abstract(Who made the models.)
    /// <summary>Who made the models.</summary>
    Modeller: String;
    //** @abstract(Where the modeller's work is.)
    /// <summary>Where the modeller's work is.</summary>
    ModellerUrl: String;
    //** @abstract(Who made the textures.)
    /// <summary>Who made the textures.</summary>
    Artist: String;
    //** @abstract(Where the artist's work is.)
    /// <summary>Where the artist's work is.</summary>
    ArtistUrl: String;
    //** @abstract(The day the project started, as ISO 8601 text.)
    /// <summary>The day the project started, as ISO 8601 text.</summary>
    Created: String;
    //** @abstract(When this export was made, as ISO 8601 text.)
    /// <summary>When this export was made, as ISO 8601 text.</summary>
    Modified: String;
    //** @abstract(The model file exported, as a full path.)
    /// <summary>The model file exported, as a full path.</summary>
    ModelFile: String;
    //** @abstract(Whether the frames were made by a 2-pass export's second pass.)
    /// <summary>Whether the frames were made by a 2-pass export's second pass.</summary>
    TwoPass: Boolean;
    //** @abstract(Whether Overscan was ticked in Model, Animation Settings.)
    /// <summary>Whether Overscan was ticked in Model, Animation Settings.</summary>
    OverscanEnabled: Boolean;
    //** @abstract(The overscan factor set in Model, Animation Settings, used or not.)
    /// <summary>The overscan factor set in Model, Animation Settings, used or not.</summary>
    Overscan: Integer;
    //** @abstract(The camera as the export started.)
    /// <summary>The camera as the export started.</summary>
    Camera: TSprite3DSheetCamera;
  end;

  //** @abstract(What SaveSheetMetadata writes about an image besides its frames.)
  /// <summary>What SaveSheetMetadata writes about an image besides its frames.</summary>
  TSprite3DSheetInfo = record
    //** @abstract(The whole image's width, in pixels.)
    /// <summary>The whole image's width, in pixels.</summary>
    Width: Integer;
    //** @abstract(The whole image's height, in pixels.)
    /// <summary>The whole image's height, in pixels.</summary>
    Height: Integer;
    //** @abstract(The columns of the image's grid of cells.)
    /// <summary>The columns of the image's grid of cells.</summary>
    Cols: Integer;
    //** @abstract(The rows of the image's grid of cells.)
    /// <summary>The rows of the image's grid of cells.</summary>
    Rows: Integer;
    //** @abstract(The pixel the centre of rotation falls on in a frame.)
    /// <summary>The pixel the centre of rotation falls on in a frame.</summary>
    Origin: TPoint;
    //** @abstract(False writes @code(null) for the origin, Origin being unused.)
    /// <summary>False writes <c>null</c> for the origin, Origin being unused.</summary>
    OriginKnown: Boolean;
    //** @abstract(The directions the image holds, as compass bearings in degrees, in the order
    //** they are exported; empty for the single dummy 0.)
    /// <summary>The directions the image holds, as compass bearings in degrees, in the order
    /// they are exported; empty for the single dummy 0.</summary>
    Directions: TArray<Double>;
    //** @abstract(The names of the animations the image holds, in order.)
    /// <summary>The names of the animations the image holds, in order.</summary>
    Animations: TArray<String>;
    //** @abstract(How many frames each of Animations has in all, on this image or not.)
    /// <summary>How many frames each of Animations has in all, on this image or
    /// not.</summary>
    AnimationFrames: TArray<Integer>;
    //** @abstract(How long each of Animations takes to play once, in seconds: the animation's
    //** own length, whatever number of frames it was saved at.)
    /// <summary>How long each of Animations takes to play once, in seconds: the animation's
    /// own length, whatever number of frames it was saved at.</summary>
    AnimationTimes: TArray<Double>;
    //** @abstract(For each of the image's frames, in order, which animation, direction and
    //** frame it is.)
    /// <summary>For each of the image's frames, in order, which animation, direction and
    /// frame it is.</summary>
    Frames: TArray<TSprite3DFrameRef>;
    //** @abstract(The @code(meta) section: page, credits, dates and model.)
    /// <summary>The <c>meta</c> section: page, credits, dates and model.</summary>
    Meta: TSprite3DSheetMeta;
  end;

  //** @abstract(An image's metadata, measured from its frames and kept to be written later.)
  //**
  //** Made by MeasureSheetMetadata while the frames are at hand and written by
  //** WriteSheetMetadata, so the frames can be let go as soon as the image is saved. It holds
  //** each frame's empty border, not the frames.
  /// <summary>An image's metadata, measured from its frames and kept to be written
  /// later.</summary>
  /// <remarks>Made by MeasureSheetMetadata while the frames are at hand and written by
  /// WriteSheetMetadata, so the frames can be let go as soon as the image is saved. It holds
  /// each frame's empty border, not the frames.</remarks>
  TSprite3DSheetMetadata = record
    //** @abstract(The file to write.)
    /// <summary>The file to write.</summary>
    FileName: String;
    //** @abstract(One frame's width in pixels.)
    /// <summary>One frame's width in pixels.</summary>
    FrameWidth: Integer;
    //** @abstract(One frame's height in pixels.)
    /// <summary>One frame's height in pixels.</summary>
    FrameHeight: Integer;
    //** @abstract(Each frame's empty border, in the order of the cells.)
    /// <summary>Each frame's empty border, in the order of the cells.</summary>
    Empties: TArray<TSprite3DFrameEmpty>;
    //** @abstract(The rest of what is written; Meta may be changed before writing.)
    /// <summary>The rest of what is written; Meta may be changed before writing.</summary>
    Info: TSprite3DSheetInfo;
  end;

//** @abstract(Copies an FMX bitmap into a TSprite3DImage, removing premultiplied alpha.)
//**
//** FMX bitmaps hold their colour premultiplied by alpha; the copy divides it back out, so a
//** half-transparent edge keeps its true colour. Works with whichever byte order the
//** platform's bitmaps use. For the main thread only. The bitmap is not changed or freed.
//**
//** @param(ABitmap The bitmap to copy; not nil and not empty.)
//**
//** @returns(The copy.)
//**
//** @raises(EArgumentException If ABitmap is nil or empty.)
//**
//** @raises(EInvalidOperation If the bitmap cannot be mapped for reading.)
/// <summary>Copies an FMX bitmap into a TSprite3DImage, removing premultiplied alpha.</summary>
/// <remarks>FMX bitmaps hold their colour premultiplied by alpha; the copy divides it back
/// out, so a half-transparent edge keeps its true colour. Works with whichever byte order the
/// platform's bitmaps use. For the main thread only. The bitmap is not changed or
/// freed.</remarks>
/// <param name="ABitmap">The bitmap to copy; not nil and not empty.</param>
/// <returns>The copy.</returns>
/// <exception cref="EArgumentException">If ABitmap is nil or empty.</exception>
/// <exception cref="EInvalidOperation">If the bitmap cannot be mapped for reading.</exception>
function ImageFromBitmap(const ABitmap: TBitmap): TSprite3DImage;

//** @abstract(Puts the frames side by side in one row: a sprite strip.)
//**
//** Frame I is at X = I * frame width. The result is one frame high and Length(AFrames)
//** frames long.
//**
//** @param(AFrames The frames, in order; at least one, all the same size.)
//**
//** @returns(The strip.)
//**
//** @raises(EArgumentException If there are no frames or they differ in size.)
//**
//** @raises(EOutOfMemory If the strip is too large to allocate.)
/// <summary>Puts the frames side by side in one row: a sprite strip.</summary>
/// <remarks>Frame I is at X = I * frame width. The result is one frame high and
/// Length(AFrames) frames long.</remarks>
/// <param name="AFrames">The frames, in order; at least one, all the same size.</param>
/// <returns>The strip.</returns>
/// <exception cref="EArgumentException">If there are no frames or they differ in
/// size.</exception>
/// <exception cref="EOutOfMemory">If the strip is too large to allocate.</exception>
function ComposeStrip(const AFrames: TArray<TSprite3DImage>): TSprite3DImage;

//** @abstract(Puts the frames in rows of ACols: a strip of several rows, such as one row per
//** direction.)
//**
//** Frame I is in column @code(I mod ACols) and row @code(I div ACols); there are as many
//** rows as the frames need, and cells after the last frame are fully transparent.
//**
//** @param(AFrames The frames, in order; at least one, all the same size.)
//**
//** @param(ACols The number of columns; at least 1.)
//**
//** @returns(The image, ACols frames wide.)
//**
//** @raises(EArgumentException If there are no frames, they differ in size, or ACols is
//** below 1.)
//**
//** @raises(EOutOfMemory If the image is too large to allocate.)
/// <summary>Puts the frames in rows of ACols: a strip of several rows, such as one row per
/// direction.</summary>
/// <remarks>Frame I is in column <c>I mod ACols</c> and row <c>I div ACols</c>; there are as
/// many rows as the frames need, and cells after the last frame are fully
/// transparent.</remarks>
/// <param name="AFrames">The frames, in order; at least one, all the same size.</param>
/// <param name="ACols">The number of columns; at least 1.</param>
/// <returns>The image, ACols frames wide.</returns>
/// <exception cref="EArgumentException">If there are no frames, they differ in size, or
/// ACols is below 1.</exception>
/// <exception cref="EOutOfMemory">If the image is too large to allocate.</exception>
function ComposeRows(const AFrames: TArray<TSprite3DImage>;
  const ACols: Integer): TSprite3DImage;

//** @abstract(Puts the frames in a square grid: a spritesheet.)
//**
//** The grid has ACells columns and ACells rows, where ACells is the smallest number whose
//** square holds every frame, so 30 frames make a 6 by 6 grid. Frame I is in column
//** @code(I mod ACells) and row @code(I div ACells): the frames run left to right along a
//** row, then carry on at the start of the next row down. Cells after the last frame are left
//** fully transparent.
//**
//** @param(AFrames The frames, in order; at least one, all the same size.)
//**
//** @param(ACells On return, the number of columns, which is also the number of rows.)
//**
//** @returns(The spritesheet.)
//**
//** @raises(EArgumentException If there are no frames or they differ in size.)
//**
//** @raises(EOutOfMemory If the spritesheet is too large to allocate.)
/// <summary>Puts the frames in a square grid: a spritesheet.</summary>
/// <remarks>The grid has ACells columns and ACells rows, where ACells is the smallest number
/// whose square holds every frame, so 30 frames make a 6 by 6 grid. Frame I is in column
/// <c>I mod ACells</c> and row <c>I div ACells</c>: the frames run left to right along a row,
/// then carry on at the start of the next row down. Cells after the last frame are left fully
/// transparent.</remarks>
/// <param name="AFrames">The frames, in order; at least one, all the same size.</param>
/// <param name="ACells">On return, the number of columns, which is also the number of
/// rows.</param>
/// <returns>The spritesheet.</returns>
/// <exception cref="EArgumentException">If there are no frames or they differ in
/// size.</exception>
/// <exception cref="EOutOfMemory">If the spritesheet is too large to allocate.</exception>
function ComposeSheet(const AFrames: TArray<TSprite3DImage>;
  out ACells: Integer): TSprite3DImage;

//** @abstract(Writes an image as a 32-bit RGBA PNG file.)
//**
//** The file is written in full, replacing any file of that name, with 8-bit RGBA, no
//** interlacing and zlib compression. The folder must exist. Blocks while it writes.
//**
//** @param(AImage The image to write.)
//**
//** @param(AFileName The file to write.)
//**
//** @raises(EArgumentException If the image is empty.)
//**
//** @raises(EFCreateError If the file cannot be created.)
//**
//** @raises(EWriteError If writing fails part way.)
/// <summary>Writes an image as a 32-bit RGBA PNG file.</summary>
/// <remarks>The file is written in full, replacing any file of that name, with 8-bit RGBA, no
/// interlacing and zlib compression. The folder must exist. Blocks while it
/// writes.</remarks>
/// <param name="AImage">The image to write.</param>
/// <param name="AFileName">The file to write.</param>
/// <exception cref="EArgumentException">If the image is empty.</exception>
/// <exception cref="EFCreateError">If the file cannot be created.</exception>
/// <exception cref="EWriteError">If writing fails part way.</exception>
procedure SavePng(const AImage: TSprite3DImage; const AFileName: String);

//** @abstract(Writes the frames as an animated GIF that loops for ever.)
//**
//** Each frame gets its own palette of up to 255 colours, chosen by median cut, and one
//** transparent entry; a pixel less than half opaque is written as transparent. Every frame
//** is shown for ADelay hundredths of a second and then cleared, so transparent frames do
//** not build up on each other. The file replaces any of that name; the folder must exist.
//** Blocks while it writes.
//**
//** @param(AFrames The frames, in order; at least one, all the same size and each at most
//** 65535 pixels wide and high.)
//**
//** @param(AFileName The file to write.)
//**
//** @param(ADelay How long each frame shows, in hundredths of a second. Values below 2 are
//** written as 2, since browsers slow down shorter delays to a tenth of a second.)
//**
//** @raises(EArgumentException If there are no frames, they differ in size or they are
//** too large for GIF.)
//**
//** @raises(EFCreateError If the file cannot be created.)
//**
//** @raises(EWriteError If writing fails part way.)
/// <summary>Writes the frames as an animated GIF that loops for ever.</summary>
/// <remarks>Each frame gets its own palette of up to 255 colours, chosen by median cut, and
/// one transparent entry; a pixel less than half opaque is written as transparent. Every
/// frame is shown for ADelay hundredths of a second and then cleared, so transparent frames do
/// not build up on each other. The file replaces any of that name; the folder must exist.
/// Blocks while it writes.</remarks>
/// <param name="AFrames">The frames, in order; at least one, all the same size and each at
/// most 65535 pixels wide and high.</param>
/// <param name="AFileName">The file to write.</param>
/// <param name="ADelay">How long each frame shows, in hundredths of a second. Values below 2
/// are written as 2, since browsers slow down shorter delays to a tenth of a
/// second.</param>
/// <exception cref="EArgumentException">If there are no frames, they differ in size or they
/// are too large for GIF.</exception>
/// <exception cref="EFCreateError">If the file cannot be created.</exception>
/// <exception cref="EWriteError">If writing fails part way.</exception>
procedure SaveAnimatedGif(const AFrames: TArray<TSprite3DImage>; const AFileName: String;
  const ADelay: Integer);

//** @abstract(Measures the fully transparent border round a frame.)
//**
//** A pixel counts as empty only when its alpha is 0; anything at all drawn there, however
//** faint, counts as part of the sprite.
//**
//** @param(AFrame The frame.)
//**
//** @returns(The border; see TSprite3DFrameEmpty.)
/// <summary>Measures the fully transparent border round a frame.</summary>
/// <remarks>A pixel counts as empty only when its alpha is 0; anything at all drawn there,
/// however faint, counts as part of the sprite.</remarks>
/// <param name="AFrame">The frame.</param>
/// <returns>The border; see TSprite3DFrameEmpty.</returns>
function MeasureFrameEmpty(const AFrame: TSprite3DImage): TSprite3DFrameEmpty;

//** @abstract(Plans the pages of a texture atlas: which frames of which animations go on each
//** page, and each page's grid and size.)
//**
//** A texture atlas is the frames of several animations on shared pages. Every frame is a
//** cell of AFrameWidth by AFrameHeight; a page is a grid of such cells no larger than
//** AMaxSize each way, so it holds at most @code(@(AMaxSize div AFrameWidth@) * @(AMaxSize
//** div AFrameHeight@)) frames. The animations' frames are taken in order, every frame of
//** the first, then every frame of the next, and so on, and fill each page in turn: an
//** animation that does not fit in what is left of a page carries on at the start of the
//** next. So every page but the last is full, a full grid with no cell to spare.
//**
//** Each page is then made as small as its frames allow; for a full page that is the
//** largest page. With ANonPowerOf2 False, its width and height are the smallest powers of 2
//** whose grid of whole cells holds them, the smaller area first and then the squarer; its
//** grid is every whole cell that fits. With ANonPowerOf2 True, it is exactly as large as a
//** grid of whole cells that holds them, chosen the same way. The frames fill the grid left
//** to right and then top to bottom. Animations with no frames are skipped.
//**
//** @param(AFrameCounts The number of frames of each animation, in the order they are to
//** be laid out.)
//**
//** @param(AFrameWidth The width of every frame, in pixels; at least 1.)
//**
//** @param(AFrameHeight The height of every frame, in pixels; at least 1.)
//**
//** @param(AMaxSize The most a page may be each way, in pixels, such as one of 1024 to
//** 16384.)
//**
//** @param(ANonPowerOf2 True lets a page be any size; False keeps both sides powers of 2.)
//**
//** @returns(The pages, in order; empty if there are no frames, or a frame is larger than
//** AMaxSize.)
/// <summary>Plans the pages of a texture atlas: which frames of which animations go on each
/// page, and each page's grid and size.</summary>
/// <remarks><para>A texture atlas is the frames of several animations on shared pages. Every
/// frame is a cell of AFrameWidth by AFrameHeight; a page is a grid of such cells no larger
/// than AMaxSize each way, so it holds at most <c>(AMaxSize div AFrameWidth) * (AMaxSize div
/// AFrameHeight)</c> frames. The animations' frames are taken in order, every frame of the
/// first, then every frame of the next, and so on, and fill each page in turn: an animation
/// that does not fit in what is left of a page carries on at the start of the next. So every
/// page but the last is full, a full grid with no cell to spare.</para>
/// <para>Each page is then made as small as its frames allow; for a full page that is the
/// largest page. With ANonPowerOf2 False, its width and height are the smallest powers of 2
/// whose grid of whole cells holds them, the smaller area first and then the squarer; its
/// grid is every whole cell that fits. With ANonPowerOf2 True, it is exactly as large as a
/// grid of whole cells that holds them, chosen the same way. The frames fill the grid left
/// to right and then top to bottom. Animations with no frames are skipped.</para></remarks>
/// <param name="AFrameCounts">The number of frames of each animation, in the order they are
/// to be laid out.</param>
/// <param name="AFrameWidth">The width of every frame, in pixels; at least 1.</param>
/// <param name="AFrameHeight">The height of every frame, in pixels; at least 1.</param>
/// <param name="AMaxSize">The most a page may be each way, in pixels, such as one of 1024 to
/// 16384.</param>
/// <param name="ANonPowerOf2">True lets a page be any size; False keeps both sides powers of
/// 2.</param>
/// <returns>The pages, in order; empty if there are no frames, or a frame is larger than
/// AMaxSize.</returns>
function PlanAtlasPages(const AFrameCounts: TArray<Integer>; const AFrameWidth,
  AFrameHeight, AMaxSize: Integer;
  const ANonPowerOf2: Boolean): TArray<TSprite3DAtlasPage>;

//** @abstract(Lays out one texture atlas page from PlanAtlasPages.)
//**
//** Frame I goes in column @code(I mod APage.Cols) and row @code(I div APage.Cols); the rest
//** of the page, spare cells and any strip too narrow for a whole cell, is fully
//** transparent.
//**
//** @param(AFrames The page's frames, in order: the frames of each of APage.Slices in
//** turn; all the same size.)
//**
//** @param(APage The page.)
//**
//** @returns(The page, APage.Width by APage.Height.)
//**
//** @raises(EArgumentException If there are no frames, they differ in size, or there are
//** more than the page's grid holds.)
//**
//** @raises(EOutOfMemory If the page is too large to allocate.)
/// <summary>Lays out one texture atlas page from PlanAtlasPages.</summary>
/// <remarks>Frame I goes in column <c>I mod APage.Cols</c> and row <c>I div APage.Cols</c>;
/// the rest of the page, spare cells and any strip too narrow for a whole cell, is fully
/// transparent.</remarks>
/// <param name="AFrames">The page's frames, in order: the frames of each of APage.Slices in
/// turn; all the same size.</param>
/// <param name="APage">The page.</param>
/// <returns>The page, APage.Width by APage.Height.</returns>
/// <exception cref="EArgumentException">If there are no frames, they differ in size, or
/// there are more than the page's grid holds.</exception>
/// <exception cref="EOutOfMemory">If the page is too large to allocate.</exception>
function ComposeAtlasPage(const AFrames: TArray<TSprite3DImage>;
  const APage: TSprite3DAtlasPage): TSprite3DImage;

//** @abstract(Writes the metadata of a sprite strip, spritesheet or texture atlas page as a
//** JSON file.)
//**
//** Each frame is measured with MeasureFrameEmpty. The file is:
//**
//** @preformatted(
//** {
//**   "meta": {
//**     "page": 1, "page_count": 1, "total_frames": 8,
//**     "creator": "...", "creator_url": "...",
//**     "modeller": "...", "modeller_url": "...",
//**     "artist": "...", "artist_url": "...",
//**     "created": "2026-10-01", "modified": "2026-10-23T16:40:00.000+01:00",
//**     "file": "C:\\Models\\hero.glb"
//**   },
//**   "image": {
//**     "size": { "width": 2048, "height": 256 },
//**     "sprite_size": { "width": 256, "height": 256 },
//**     "layout": { "cols": 8, "rows": 1, "frame_count": 8 },
//**     "origin": { "x": 127, "y": 201 },
//**     "sprite_empty": { "left": 61, "top": 12, "right": 58, "bottom": 40 },
//**     "directions": [0],
//**     "animations": [
//**       { "name": "walk", "frame_count": 8, "time": 1.0333 }
//**     ],
//**     "unused": 0,
//**     "two_pass": false,
//**     "overscan": { "enabled": true, "factor": 4 }
//**   },
//**   "camera": {
//**     "view": "Isometric", "projection": "orthographic",
//**     "azimuth": 45, "inclination": 35.2644, "roll": 0,
//**     "distance": 12.5, "ortho_height": 3.2,
//**     "pan": { "enabled": false, "x": 0, "z": 0 },
//**     "locked": false
//**   },
//**   "frames": [
//**     {
//**       "animation": 0,
//**       "direction": 0,
//**       "frame": 0,
//**       "empty": { "left": 64, "top": 12, "right": 60, "bottom": 40 }
//**     },
//**     ...
//**   ]
//** }
//** )
//**
//** @code(meta) comes first, from AInfo.Meta: the page, from 1, the number of pages, the
//** number of frames the export made over every page in @code(total_frames), the credits,
//** the day the project started, when this export was made, and the model file; empty
//** text is @code(null). @code(size) is the whole image's, from AInfo, and
//** @code(sprite_size) one frame's, the grab size. @code(origin) is the pixel the model's
//** centre of rotation falls on in every frame, in the frame's own pixels, (0, 0) the top
//** left pixel, as whole numbers; @code(null) for each if it is not known.
//** @code(sprite_empty) holds, for each side, the smallest of the frames' empty borders, so
//** cropping every frame by it loses nothing from any of them. @code(directions) lists the
//** directions the image holds, as compass bearings in degrees in the order they are
//** exported; one direction is the single dummy entry 0.
//** @code(animations) lists the animations the image holds, each as its @code(name), its
//** @code(frame_count), how many frames it has in all, so one that carries on onto another
//** atlas page shows its whole length, and its @code(time), how long it takes to play once
//** in seconds, its own length whatever number of frames it was saved at, so
//** frame_count / time is its frame rate. @code(unused) is the number of the grid's cells
//** after the last
//** frame, which hold nothing. @code(two_pass) is whether a 2-pass export made them, and
//** @code(overscan) whether overscan was on and its factor. @code(camera) is the camera as
//** the export started: the View, Camera view, the projection, the Azimuth, Inclination and
//** Roll readouts in degrees, the distance from the orbit centre and, orthographic, the
//** height of scene shown, both as captured, in scene units, the pan, and whether the
//** camera was locked. @code(frames) has one entry per frame, in the order of the
//** cells, saying which animation and direction it is, as indices into @code(animations)
//** and @code(directions), which frame of that animation and direction, counted from 0, and
//** its empty sections in @code(empty). The file is replaced if it exists; the folder must
//** exist.
//**
//** @param(AFileName The file to write, normally the image's name with the extension
//** .json.)
//**
//** @param(AFrames The frames, in order, as laid out in the image; at least one, all the same
//** size.)
//**
//** @param(AInfo The image's size, grid, origin, directions, animations, and which each
//** frame is.)
//**
//** @raises(EArgumentException If there are no frames, they differ in size, AInfo's grid
//** cannot hold them, or AInfo.Frames does not match them or names an animation or
//** direction it does not list.)
//**
//** @raises(EInOutError or another file exception if the file cannot be written.)
/// <summary>Writes the metadata of a sprite strip, spritesheet or texture atlas page as a JSON
/// file.</summary>
/// <remarks><para>Each frame is measured with MeasureFrameEmpty. The file holds first a
/// <c>meta</c> object, from AInfo.Meta, with <c>page</c>, <c>page_count</c>,
/// <c>total_frames</c> (the frames the export made over every page), <c>creator</c>,
/// <c>creator_url</c>, <c>modeller</c>, <c>modeller_url</c>, <c>artist</c>, <c>artist_url</c>,
/// <c>created</c>, <c>modified</c> and <c>file</c>, empty text being <c>null</c>; then an
/// <c>image</c> object, with <c>size</c> and <c>sprite_size</c> (each <c>width</c>,
/// <c>height</c>), <c>layout</c> (<c>cols</c>, <c>rows</c>, <c>frame_count</c>), <c>origin</c>
/// (<c>x</c>, <c>y</c>), <c>sprite_empty</c> (<c>left</c>, <c>top</c>, <c>right</c>,
/// <c>bottom</c>), <c>directions</c>, <c>animations</c> (each <c>name</c>,
/// <c>frame_count</c>, <c>time</c>),
/// <c>unused</c>, <c>two_pass</c> and <c>overscan</c> (<c>enabled</c>, <c>factor</c>); then a
/// <c>camera</c> object, with <c>view</c>, <c>projection</c>, <c>azimuth</c>,
/// <c>inclination</c>, <c>roll</c>, <c>distance</c>, <c>ortho_height</c>, <c>pan</c>
/// (<c>enabled</c>, <c>x</c>, <c>z</c>) and <c>locked</c>, the camera as the export started;
/// and a <c>frames</c> array of one object per frame, with <c>animation</c>, <c>direction</c>,
/// <c>frame</c> and <c>empty</c>, an object of its <c>left</c>, <c>top</c>, <c>right</c>,
/// <c>bottom</c>.</para>
/// <para><c>size</c> is the whole image's, from AInfo, and <c>sprite_size</c> one frame's,
/// the grab size. <c>origin</c> is the pixel the model's
/// centre of rotation falls on in every frame, in the frame's own pixels, (0, 0) the top left
/// pixel, as whole numbers; <c>null</c> for each if it is not known. <c>sprite_empty</c>
/// holds, for each side, the smallest of the frames' empty borders, so cropping every frame
/// by it loses nothing from any of them. <c>directions</c> lists the directions the image
/// holds, as compass bearings in degrees in the order they are exported; one direction is
/// the single dummy entry 0. <c>animations</c> lists the animations the image holds, each as
/// its <c>name</c>, its <c>frame_count</c>, how many frames it has in all, so one that carries
/// on onto another atlas page shows its whole length, and its <c>time</c>, how long it takes
/// to play once in seconds, its own length whatever number of frames it was saved at, so
/// frame_count / time is its frame rate. <c>unused</c> is the
/// number of the grid's cells after the last frame, which hold nothing. <c>two_pass</c> is
/// whether a 2-pass export made them, and <c>overscan</c> whether overscan was on and its factor.
/// <c>camera</c> is the camera as the export started: the View, Camera view, the
/// projection, the Azimuth, Inclination and Roll readouts in degrees, the distance from the
/// orbit centre and, orthographic, the height of scene shown, both as captured, in scene
/// units, the pan, and whether the camera was locked. <c>frames</c> has one
/// entry per frame, in the order of the cells, saying which animation and direction it is,
/// as indices into <c>animations</c> and <c>directions</c>, which frame of that animation
/// and direction, counted from 0, and its empty sections in <c>empty</c>. The file is
/// replaced if it exists; the folder must exist.</para></remarks>
/// <param name="AFileName">The file to write, normally the image's name with the extension
/// .json.</param>
/// <param name="AFrames">The frames, in order, as laid out in the image; at least one, all
/// the same size.</param>
/// <param name="AInfo">The image's size, grid, origin, directions, animations, and which
/// each frame is.</param>
/// <exception cref="EArgumentException">If there are no frames, they differ in size, AInfo's
/// grid cannot hold them, or AInfo.Frames does not match them or names an animation or
/// direction it does not list.</exception>
/// <exception cref="EInOutError">Or another file exception, if the file cannot be
/// written.</exception>
procedure SaveSheetMetadata(const AFileName: String; const AFrames: TArray<TSprite3DImage>;
  const AInfo: TSprite3DSheetInfo);

//** @abstract(Copies of the frames, each with a 1-pixel border of opaque black round its edge.)
//**
//** A debugging aid, to show where each frame's cell ends in a strip, spritesheet or atlas
//** page. Each copy has its own pixels; the frames given are not changed, so they can still
//** be measured. A frame with no pixels, or fewer than its size needs, is copied without a
//** border. Safe on any thread; it touches nothing but its arguments.
//**
//** @param(AFrames The frames, in RGBA, as captured.)
//**
//** @returns(One new image per frame, in the same order; the caller owns them, as records
//** that free themselves.)
/// <summary>Copies of the frames, each with a 1-pixel border of opaque black round its
/// edge.</summary>
/// <remarks>A debugging aid, to show where each frame's cell ends in a strip, spritesheet or
/// atlas page. Each copy has its own pixels; the frames given are not changed, so they can
/// still be measured. A frame with no pixels, or fewer than its size needs, is copied without
/// a border. Safe on any thread; it touches nothing but its arguments.</remarks>
/// <param name="AFrames">The frames, in RGBA, as captured.</param>
/// <returns>One new image per frame, in the same order; the caller owns them, as records that
/// free themselves.</returns>
function FramesWithBorder(const AFrames: TArray<TSprite3DImage>): TArray<TSprite3DImage>;

//** @abstract(Checks and measures what SaveSheetMetadata would write, without writing it.)
//**
//** The frames are checked against AInfo as @link(SaveSheetMetadata) checks them, and each
//** is measured with @link(MeasureFrameEmpty). The result holds each frame's empty border,
//** not the frames, so they can be let go as soon as this returns; pass it to
//** @link(WriteSheetMetadata) later, after changing its @code(Info.Meta) if need be. Nothing
//** is written. Safe on any thread.
//**
//** @param(AFileName The metadata file to write later, normally the image's name with the
//** extension .json.)
//**
//** @param(AFrames The frames, in order, as laid out in the image; at least one, all the
//** same size.)
//**
//** @param(AInfo The image's size, grid, origin, directions, animations, and which each frame
//** is.)
//**
//** @returns(What WriteSheetMetadata needs; a record, owned by the caller.)
//**
//** @raises(EArgumentException In the same cases as SaveSheetMetadata: there are no frames,
//** they differ in size, AInfo's grid cannot hold them, an animation has no frame count or
//** time, or AInfo.Frames does not match the frames or names an animation or direction it
//** does not list.)
//**
//** @seealso(WriteSheetMetadata)
/// <summary>Checks and measures what SaveSheetMetadata would write, without writing
/// it.</summary>
/// <remarks>The frames are checked against AInfo as <see cref="SaveSheetMetadata"/> checks
/// them, and each is measured with <see cref="MeasureFrameEmpty"/>. The result holds each
/// frame's empty border, not the frames, so they can be let go as soon as this returns; pass
/// it to <see cref="WriteSheetMetadata"/> later, after changing its <c>Info.Meta</c> if need
/// be. Nothing is written. Safe on any thread.</remarks>
/// <param name="AFileName">The metadata file to write later, normally the image's name with
/// the extension .json.</param>
/// <param name="AFrames">The frames, in order, as laid out in the image; at least one, all
/// the same size.</param>
/// <param name="AInfo">The image's size, grid, origin, directions, animations, and which each
/// frame is.</param>
/// <returns>What WriteSheetMetadata needs; a record, owned by the caller.</returns>
/// <exception cref="EArgumentException">In the same cases as SaveSheetMetadata: there are no
/// frames, they differ in size, AInfo's grid cannot hold them, an animation has no frame
/// count or time, or AInfo.Frames does not match the frames or names an animation or
/// direction it does not list.</exception>
/// <seealso cref="WriteSheetMetadata"/>
function MeasureSheetMetadata(const AFileName: String; const AFrames: TArray<TSprite3DImage>;
  const AInfo: TSprite3DSheetInfo): TSprite3DSheetMetadata;

//** @abstract(The smallest of each side over the given empty borders, as sprite_empty is.)
//**
//** Cropping every frame by the result loses nothing from any of them. Frames with nothing
//** drawn count as empty right across, so they never lower it unless every frame is empty.
//** Safe on any thread.
//**
//** @param(AEmpties Empty borders, as @link(MeasureFrameEmpty) gives them; may be from
//** several images.)
//**
//** @returns(The least left, top, right and bottom; all 0 if AEmpties is empty.)
/// <summary>The smallest of each side over the given empty borders, as sprite_empty
/// is.</summary>
/// <remarks>Cropping every frame by the result loses nothing from any of them. Frames with
/// nothing drawn count as empty right across, so they never lower it unless every frame is
/// empty. Safe on any thread.</remarks>
/// <param name="AEmpties">Empty borders, as <see cref="MeasureFrameEmpty"/> gives them; may
/// be from several images.</param>
/// <returns>The least left, top, right and bottom; all 0 if AEmpties is empty.</returns>
function LeastFrameEmpty(const AEmpties: TArray<TSprite3DFrameEmpty>): TSprite3DFrameEmpty;

//** @abstract(Writes metadata measured by MeasureSheetMetadata, as SaveSheetMetadata does.)
//**
//** The file is written exactly as @link(SaveSheetMetadata) would have written it from the
//** frames, @code(sprite_empty) being the least of the image's own frames' empty borders.
//** It is replaced if it exists; its folder must exist. Blocks until written; may be called
//** on any thread.
//**
//** @param(AMetadata What @link(MeasureSheetMetadata) returned, its Info.Meta changed if need
//** be.)
//**
//** @raises(EInOutError Or another file exception, if the file cannot be written.)
/// <summary>Writes metadata measured by MeasureSheetMetadata, as SaveSheetMetadata
/// does.</summary>
/// <remarks>The file is written exactly as <see cref="SaveSheetMetadata"/> would have written
/// it from the frames, <c>sprite_empty</c> being the least of the image's own frames' empty
/// borders. It is replaced if it exists; its folder must exist. Blocks until written; may be
/// called on any thread.</remarks>
/// <param name="AMetadata">What <see cref="MeasureSheetMetadata"/> returned, its Info.Meta
/// changed if need be.</param>
/// <exception cref="EInOutError">Or another file exception, if the file cannot be
/// written.</exception>
procedure WriteSheetMetadata(const AMetadata: TSprite3DSheetMetadata); overload;
//** @abstract(Writes metadata measured by MeasureSheetMetadata with a given sprite_empty.)
//**
//** As the overload without ASpriteEmpty, but @code(sprite_empty) is ASpriteEmpty rather
//** than the least of the image's own frames, as a 2-pass export writes the least over every
//** frame it made into every one of its files. Each frame's own @code(empty) is unchanged.
//** Blocks until written; may be called on any thread.
//**
//** @param(AMetadata What @link(MeasureSheetMetadata) returned, its Info.Meta changed if need
//** be.)
//**
//** @param(ASpriteEmpty The values written as @code(sprite_empty).)
//**
//** @raises(EInOutError Or another file exception, if the file cannot be written.)
/// <summary>Writes metadata measured by MeasureSheetMetadata with a given
/// sprite_empty.</summary>
/// <remarks>As the overload without ASpriteEmpty, but <c>sprite_empty</c> is ASpriteEmpty
/// rather than the least of the image's own frames, as a 2-pass export writes the least over
/// every frame it made into every one of its files. Each frame's own <c>empty</c> is
/// unchanged. Blocks until written; may be called on any thread.</remarks>
/// <param name="AMetadata">What <see cref="MeasureSheetMetadata"/> returned, its Info.Meta
/// changed if need be.</param>
/// <param name="ASpriteEmpty">The values written as <c>sprite_empty</c>.</param>
/// <exception cref="EInOutError">Or another file exception, if the file cannot be
/// written.</exception>
procedure WriteSheetMetadata(const AMetadata: TSprite3DSheetMetadata;
  const ASpriteEmpty: TSprite3DFrameEmpty); overload;

//** @abstract(A name made safe to use as a file name on every platform.)
//**
//** Characters that Windows, macOS, Linux, Android or iOS reject or treat specially in file
//** names, such as @code(/ \ : * ? " < > |) and control characters, become underscores, and
//** leading and trailing spaces and dots are removed. An empty result becomes
//** @code('animation').
//**
//** @param(AName The name, such as an animation's name.)
//**
//** @returns(The safe name, without a folder or extension.)
/// <summary>A name made safe to use as a file name on every platform.</summary>
/// <remarks>Characters that Windows, macOS, Linux, Android or iOS reject or treat specially in
/// file names, such as <c>/ \ : * ? " &lt; &gt; |</c> and control characters, become
/// underscores, and leading and trailing spaces and dots are removed. An empty result becomes
/// <c>'animation'</c>.</remarks>
/// <param name="AName">The name, such as an animation's name.</param>
/// <returns>The safe name, without a folder or extension.</returns>
function SafeFileStem(const AName: String): String;

implementation

uses
  System.UITypes, System.Math, System.ZLib, System.Generics.Collections,
  System.Generics.Defaults, System.JSON, System.IOUtils, OSPaths, JsonText;

{ TSprite3DImage }

class function TSprite3DImage.Create(const AWidth, AHeight: Integer): TSprite3DImage;
begin
  if (AWidth < 1) or (AHeight < 1) then
    raise EArgumentException.CreateFmt('An image of %d x %d pixels is not possible.',
      [AWidth, AHeight]);
  Result.Width := AWidth;
  Result.Height := AHeight;
  // A new dynamic array is zero-filled: every pixel transparent black
  SetLength(Result.Pixels, Int64(AWidth) * AHeight * 4);
end;

function ImageFromBitmap(const ABitmap: TBitmap): TSprite3DImage;
var
  Data: TBitmapData;
  X, Y, A: Integer;
  Colour: TAlphaColorRec;
  Dst: PByte;
begin
  if (ABitmap = nil) or ABitmap.IsEmpty then
    raise EArgumentException.Create('There is no image to copy.');
  Result := TSprite3DImage.Create(ABitmap.Width, ABitmap.Height);
  if not ABitmap.Map(TMapAccess.Read, Data) then
    raise EInvalidOperation.Create('Cannot read the grabbed image.');
  try
    Dst := @Result.Pixels[0];
    for Y := 0 to Result.Height - 1 do
      for X := 0 to Result.Width - 1 do
      begin
        // GetPixel hides the platform's byte order; the colour it gives is
        // still premultiplied, as stored
        Colour := TAlphaColorRec(Data.GetPixel(X, Y));
        A := Colour.A;
        if A = 0 then
        begin
          Dst[0] := 0;
          Dst[1] := 0;
          Dst[2] := 0;
        end
        else if A = 255 then
        begin
          Dst[0] := Colour.R;
          Dst[1] := Colour.G;
          Dst[2] := Colour.B;
        end
        else
        begin
          Dst[0] := Min(255, (Colour.R * 255 + A div 2) div A);
          Dst[1] := Min(255, (Colour.G * 255 + A div 2) div A);
          Dst[2] := Min(255, (Colour.B * 255 + A div 2) div A);
        end;
        Dst[3] := A;
        Inc(Dst, 4);
      end;
  finally
    ABitmap.Unmap(Data);
  end;
end;

// Every frame present and the same size; their common size
procedure CheckFrames(const AFrames: TArray<TSprite3DImage>; out AWidth,
  AHeight: Integer);
var
  Frame: TSprite3DImage;
begin
  if Length(AFrames) = 0 then
    raise EArgumentException.Create('There are no frames.');
  AWidth := AFrames[0].Width;
  AHeight := AFrames[0].Height;
  for Frame in AFrames do
    if (Frame.Width <> AWidth) or (Frame.Height <> AHeight) or
      (Length(Frame.Pixels) <> Int64(AWidth) * AHeight * 4) or (AWidth < 1) or
      (AHeight < 1) then
      raise EArgumentException.Create('The frames are not all the same size.');
end;

// Copies AFrame into ADest with its top left corner at (AX, AY)
procedure Blit(const AFrame: TSprite3DImage; var ADest: TSprite3DImage;
  const AX, AY: Integer);
var
  Y: Integer;
  RowBytes: NativeInt;
begin
  RowBytes := NativeInt(AFrame.Width) * 4;
  for Y := 0 to AFrame.Height - 1 do
    Move(AFrame.Pixels[NativeInt(Y) * RowBytes],
      ADest.Pixels[(NativeInt(AY + Y) * ADest.Width + AX) * 4], RowBytes);
end;

function ComposeStrip(const AFrames: TArray<TSprite3DImage>): TSprite3DImage;
var
  W, H, I: Integer;
begin
  CheckFrames(AFrames, W, H);
  Result := TSprite3DImage.Create(W * Length(AFrames), H);
  for I := 0 to High(AFrames) do
    Blit(AFrames[I], Result, I * W, 0);
end;

function ComposeRows(const AFrames: TArray<TSprite3DImage>;
  const ACols: Integer): TSprite3DImage;
var
  W, H, I, Rows: Integer;
begin
  CheckFrames(AFrames, W, H);
  if ACols < 1 then
    raise EArgumentException.Create('A strip needs at least one column.');
  Rows := (Length(AFrames) + ACols - 1) div ACols;
  Result := TSprite3DImage.Create(W * ACols, H * Rows);
  for I := 0 to High(AFrames) do
    Blit(AFrames[I], Result, (I mod ACols) * W, (I div ACols) * H);
end;

function ComposeSheet(const AFrames: TArray<TSprite3DImage>;
  out ACells: Integer): TSprite3DImage;
var
  W, H, I: Integer;
begin
  CheckFrames(AFrames, W, H);
  ACells := Ceil(Sqrt(Length(AFrames)));
  while ACells * ACells < Length(AFrames) do   // guard against rounding
    Inc(ACells);
  Result := TSprite3DImage.Create(W * ACells, H * ACells);
  for I := 0 to High(AFrames) do
    Blit(AFrames[I], Result, (I mod ACells) * W, (I div ACells) * H);
end;

{ PNG }

var
  CrcTable: array[0..255] of Cardinal;

procedure InitCrcTable;
var
  N, K: Integer;
  C: Cardinal;
begin
  for N := 0 to 255 do
  begin
    C := Cardinal(N);
    for K := 0 to 7 do
      if (C and 1) <> 0 then
        C := $EDB88320 xor (C shr 1)
      else
        C := C shr 1;
    CrcTable[N] := C;
  end;
end;

function UpdateCrc(const ACrc: Cardinal; const ABytes: TBytes): Cardinal;
var
  I: Integer;
begin
  Result := ACrc;
  for I := 0 to High(ABytes) do
    Result := CrcTable[(Result xor ABytes[I]) and $FF] xor (Result shr 8);
end;

procedure WriteBE32(const AStream: TStream; const AValue: Cardinal);
var
  B: array[0..3] of Byte;
begin
  B[0] := Byte(AValue shr 24);
  B[1] := Byte(AValue shr 16);
  B[2] := Byte(AValue shr 8);
  B[3] := Byte(AValue);
  AStream.WriteBuffer(B, 4);
end;

// One chunk: length, type, data, and the CRC of type and data
procedure WriteChunk(const AStream: TStream; const AType: AnsiString;
  const AData: TBytes);
var
  TypeBytes: TBytes;
  Crc: Cardinal;
begin
  SetLength(TypeBytes, 4);
  Move(AType[1], TypeBytes[0], 4);
  WriteBE32(AStream, Cardinal(Length(AData)));
  AStream.WriteBuffer(TypeBytes, 4);
  if Length(AData) > 0 then
    AStream.WriteBuffer(AData, Length(AData));
  Crc := UpdateCrc($FFFFFFFF, TypeBytes);
  Crc := UpdateCrc(Crc, AData) xor $FFFFFFFF;
  WriteBE32(AStream, Crc);
end;

procedure SavePng(const AImage: TSprite3DImage; const AFileName: String);
const
  SIGNATURE: array[0..7] of Byte = (137, 80, 78, 71, 13, 10, 26, 10);
var
  Stream: TFileStream;
  Header, Raw, Zipped: TBytes;
  Y: Integer;
  RowBytes, Src, Dst: NativeInt;
begin
  if (AImage.Width < 1) or (AImage.Height < 1) or
    (Length(AImage.Pixels) <> Int64(AImage.Width) * AImage.Height * 4) then
    raise EArgumentException.Create('There is no image to save.');

  // IHDR: size, 8 bits per channel, colour type 6 (RGBA), deflate, no
  // filtering beyond each row's own filter byte, no interlace
  SetLength(Header, 13);
  Header[0] := Byte(AImage.Width shr 24);
  Header[1] := Byte(AImage.Width shr 16);
  Header[2] := Byte(AImage.Width shr 8);
  Header[3] := Byte(AImage.Width);
  Header[4] := Byte(AImage.Height shr 24);
  Header[5] := Byte(AImage.Height shr 16);
  Header[6] := Byte(AImage.Height shr 8);
  Header[7] := Byte(AImage.Height);
  Header[8] := 8;
  Header[9] := 6;
  Header[10] := 0;
  Header[11] := 0;
  Header[12] := 0;

  // Each row is a filter byte, here 0 (none), then its pixels
  RowBytes := NativeInt(AImage.Width) * 4;
  SetLength(Raw, (RowBytes + 1) * AImage.Height);
  Src := 0;
  Dst := 0;
  for Y := 0 to AImage.Height - 1 do
  begin
    Raw[Dst] := 0;
    Move(AImage.Pixels[Src], Raw[Dst + 1], RowBytes);
    Inc(Src, RowBytes);
    Inc(Dst, RowBytes + 1);
  end;
  ZCompress(Raw, Zipped, zcDefault);   // a zlib stream, as IDAT wants
  Raw := nil;

  Stream := TFileStream.Create(OSFriendlyPath(AFileName), fmCreate);
  try
    Stream.WriteBuffer(SIGNATURE, Length(SIGNATURE));
    WriteChunk(Stream, 'IHDR', Header);
    WriteChunk(Stream, 'IDAT', Zipped);
    WriteChunk(Stream, 'IEND', nil);
  finally
    Stream.Free;
  end;
end;

{ GIF }

const
  GIF_TRANSPARENT = 255;   // palette entry kept for transparent pixels
  GIF_MAX_COLOURS = 255;   // the rest of the 256 entries
  GIF_BINS = 32768;        // 5 bits each of red, green and blue

type
  // One cell of the 5-5-5 colour histogram, with the sums for its average
  TColourBin = record
    Key: Integer;
    Count: Int64;
    SumR, SumG, SumB: Int64;
  end;

  // A box of the median cut: a run of Bins, and the bins' extent
  TColourBox = record
    Lo, Hi: Integer;   // inclusive indices into the bins array
    Count: Int64;
    MinC, MaxC: array[0..2] of Integer;
  end;

  // One frame as palette indices, with its palette
  TGifFrame = record
    Palette: array[0..255] of TAlphaColorRec;
    Indices: TBytes;
  end;

function BinChannel(const AKey, AChannel: Integer): Integer; inline;
begin
  case AChannel of
    0: Result := (AKey shr 10) and 31;
    1: Result := (AKey shr 5) and 31;
  else
    Result := AKey and 31;
  end;
end;

procedure MeasureBox(const ABins: TArray<TColourBin>; var ABox: TColourBox);
var
  I, C, V: Integer;
begin
  ABox.Count := 0;
  for C := 0 to 2 do
  begin
    ABox.MinC[C] := 31;
    ABox.MaxC[C] := 0;
  end;
  for I := ABox.Lo to ABox.Hi do
  begin
    Inc(ABox.Count, ABins[I].Count);
    for C := 0 to 2 do
    begin
      V := BinChannel(ABins[I].Key, C);
      ABox.MinC[C] := Min(ABox.MinC[C], V);
      ABox.MaxC[C] := Max(ABox.MaxC[C], V);
    end;
  end;
end;

// Palette and indices for one frame. Opaque colours are counted on a 5-5-5
// grid; up to 255 cells become entries directly, otherwise median cut
// splits them into 255 boxes, each entry the weighted average of its box.
function QuantizeFrame(const AFrame: TSprite3DImage): TGifFrame;
var
  Hist: array of TColourBin;
  Lookup: array of Byte;
  Bins: TArray<TColourBin>;
  Boxes: TArray<TColourBox>;
  BoxCount, I, J, Best, Axis, Split, PixelCount: Integer;
  Score, BestScore, Half, Running: Int64;
  P: PByte;
  Key: Integer;
  Box: TColourBox;
  SortAxis: Integer;
begin
  FillChar(Result.Palette, SizeOf(Result.Palette), 0);
  SetLength(Hist, GIF_BINS);
  SetLength(Lookup, GIF_BINS);
  PixelCount := AFrame.Width * AFrame.Height;

  P := @AFrame.Pixels[0];
  for I := 0 to PixelCount - 1 do
  begin
    if P[3] >= 128 then
    begin
      Key := (Integer(P[0] shr 3) shl 10) or (Integer(P[1] shr 3) shl 5) or (P[2] shr 3);
      Inc(Hist[Key].Count);
      Inc(Hist[Key].SumR, P[0]);
      Inc(Hist[Key].SumG, P[1]);
      Inc(Hist[Key].SumB, P[2]);
    end;
    Inc(P, 4);
  end;
  J := 0;
  for I := 0 to GIF_BINS - 1 do
    if Hist[I].Count > 0 then
      Inc(J);
  SetLength(Bins, J);
  J := 0;
  for I := 0 to GIF_BINS - 1 do
    if Hist[I].Count > 0 then
    begin
      Hist[I].Key := I;
      Bins[J] := Hist[I];
      Inc(J);
    end;
  Hist := nil;

  if Length(Bins) > 0 then
  begin
    // Start with one box holding every colour, then split the box with the
    // most spread, weighted by how many pixels it covers, at its median
    SetLength(Boxes, 1);
    Boxes[0].Lo := 0;
    Boxes[0].Hi := High(Bins);
    MeasureBox(Bins, Boxes[0]);
    BoxCount := 1;
    while BoxCount < GIF_MAX_COLOURS do
    begin
      Best := -1;
      BestScore := 0;
      for I := 0 to BoxCount - 1 do
        if Boxes[I].Hi > Boxes[I].Lo then
        begin
          Score := 0;
          for J := 0 to 2 do
            Score := Max(Score, Int64(Boxes[I].MaxC[J] - Boxes[I].MinC[J] + 1));
          Score := Score * Boxes[I].Count;
          if Score > BestScore then
          begin
            BestScore := Score;
            Best := I;
          end;
        end;
      if Best < 0 then
        Break;   // every box is a single colour: nothing left to split

      Box := Boxes[Best];
      Axis := 0;
      for J := 1 to 2 do
        if Box.MaxC[J] - Box.MinC[J] > Box.MaxC[Axis] - Box.MinC[Axis] then
          Axis := J;
      SortAxis := Axis;
      TArray.Sort<TColourBin>(Bins, TComparer<TColourBin>.Construct(
        function(const L, R: TColourBin): Integer
        begin
          Result := BinChannel(L.Key, SortAxis) - BinChannel(R.Key, SortAxis);
        end), Box.Lo, Box.Hi - Box.Lo + 1);

      // The split leaves at least one bin on each side
      Half := Box.Count div 2;
      Running := 0;
      Split := Box.Lo;
      for J := Box.Lo to Box.Hi - 1 do
      begin
        Inc(Running, Bins[J].Count);
        Split := J;
        if Running >= Half then
          Break;
      end;

      Boxes[Best].Lo := Box.Lo;
      Boxes[Best].Hi := Split;
      MeasureBox(Bins, Boxes[Best]);
      SetLength(Boxes, BoxCount + 1);
      Boxes[BoxCount].Lo := Split + 1;
      Boxes[BoxCount].Hi := Box.Hi;
      MeasureBox(Bins, Boxes[BoxCount]);
      Inc(BoxCount);
    end;

    // Each box becomes an entry; each of its cells maps to it
    for I := 0 to BoxCount - 1 do
    begin
      Box := Boxes[I];
      Score := 0;   // reused as the sums
      Running := 0;
      Half := 0;
      for J := Box.Lo to Box.Hi do
      begin
        Inc(Score, Bins[J].SumR);
        Inc(Running, Bins[J].SumG);
        Inc(Half, Bins[J].SumB);
        Lookup[Bins[J].Key] := I;
      end;
      Result.Palette[I].R := Byte((Score + Box.Count div 2) div Box.Count);
      Result.Palette[I].G := Byte((Running + Box.Count div 2) div Box.Count);
      Result.Palette[I].B := Byte((Half + Box.Count div 2) div Box.Count);
      Result.Palette[I].A := 255;
    end;
  end;

  SetLength(Result.Indices, PixelCount);
  P := @AFrame.Pixels[0];
  for I := 0 to PixelCount - 1 do
  begin
    if P[3] >= 128 then
      Result.Indices[I] := Lookup[(Integer(P[0] shr 3) shl 10) or
        (Integer(P[1] shr 3) shl 5) or (P[2] shr 3)]
    else
      Result.Indices[I] := GIF_TRANSPARENT;
    Inc(P, 4);
  end;
end;

type
  // GIF's variable-length LZW, least significant bit first, 8-bit symbols
  TGifLzw = class
  private
    FCodes: array of Word;    // FCodes[Prefix shl 8 or Symbol]: the code
    FStamps: array of Word;   // valid only where FStamps[...] = FStamp
    FStamp: Word;
    FOut: TBytes;
    FOutLen: Integer;
    FAcc: Cardinal;
    FBits: Integer;
    FSize: Integer;
    procedure Emit(const ACode: Integer);
    procedure PutByte(const AByte: Byte);
    procedure ResetTable;
  public
    constructor Create;
    function Encode(const AIndices: TBytes): TBytes;
  end;

const
  LZW_CLEAR = 256;
  LZW_END = 257;
  LZW_FIRST = 258;
  LZW_MAX = 4096;

constructor TGifLzw.Create;
begin
  inherited Create;
  SetLength(FCodes, LZW_MAX * 256);
  SetLength(FStamps, LZW_MAX * 256);
  FStamp := 0;
end;

procedure TGifLzw.ResetTable;
begin
  // A new stamp empties the table without clearing it
  if FStamp = High(Word) then
  begin
    FillChar(FStamps[0], Length(FStamps) * SizeOf(Word), 0);
    FStamp := 0;
  end;
  Inc(FStamp);
  FSize := 9;
end;

procedure TGifLzw.PutByte(const AByte: Byte);
begin
  if FOutLen = Length(FOut) then
    SetLength(FOut, Max(4096, Length(FOut) * 2));
  FOut[FOutLen] := AByte;
  Inc(FOutLen);
end;

procedure TGifLzw.Emit(const ACode: Integer);
begin
  FAcc := FAcc or (Cardinal(ACode) shl FBits);
  Inc(FBits, FSize);
  while FBits >= 8 do
  begin
    PutByte(Byte(FAcc));
    FAcc := FAcc shr 8;
    Dec(FBits, 8);
  end;
end;

function TGifLzw.Encode(const AIndices: TBytes): TBytes;
var
  I, Prefix, Next, Key: Integer;
  Symbol: Byte;
begin
  FOut := nil;
  FOutLen := 0;
  FAcc := 0;
  FBits := 0;
  ResetTable;
  Next := LZW_FIRST;
  Emit(LZW_CLEAR);
  if Length(AIndices) > 0 then
  begin
    Prefix := AIndices[0];
    for I := 1 to High(AIndices) do
    begin
      Symbol := AIndices[I];
      Key := (Prefix shl 8) or Symbol;
      if FStamps[Key] = FStamp then
        Prefix := FCodes[Key]
      else
      begin
        Emit(Prefix);
        if Next < LZW_MAX then
        begin
          FCodes[Key] := Next;
          FStamps[Key] := FStamp;
          Inc(Next);
          // The decoder, one entry behind, widens once it would need it
          if (Next > (1 shl FSize)) and (FSize < 12) then
            Inc(FSize);
        end
        else
        begin
          // Table full: start again
          Emit(LZW_CLEAR);
          ResetTable;
          Next := LZW_FIRST;
        end;
        Prefix := Symbol;
      end;
    end;
    Emit(Prefix);
    // Reading that code the decoder adds an entry, which can widen the
    // end code
    if Next < LZW_MAX then
    begin
      Inc(Next);
      if (Next > (1 shl FSize)) and (FSize < 12) then
        Inc(FSize);
    end;
  end;
  Emit(LZW_END);
  if FBits > 0 then
    PutByte(Byte(FAcc));
  SetLength(FOut, FOutLen);
  Result := FOut;
  FOut := nil;
end;

procedure WriteLE16(const AStream: TStream; const AValue: Integer);
var
  B: array[0..1] of Byte;
begin
  B[0] := Byte(AValue);
  B[1] := Byte(AValue shr 8);
  AStream.WriteBuffer(B, 2);
end;

procedure WriteByte(const AStream: TStream; const AValue: Byte);
begin
  AStream.WriteBuffer(AValue, 1);
end;

procedure SaveAnimatedGif(const AFrames: TArray<TSprite3DImage>; const AFileName: String;
  const ADelay: Integer);
const
  NETSCAPE: AnsiString = 'NETSCAPE2.0';
var
  W, H, I, Pos, Len: Integer;
  Stream: TFileStream;
  Lzw: TGifLzw;
  Frame: TGifFrame;
  Data: TBytes;
  Header: AnsiString;
begin
  CheckFrames(AFrames, W, H);
  if (W > 65535) or (H > 65535) then
    raise EArgumentException.Create('The frames are too large for a GIF.');

  Lzw := TGifLzw.Create;
  try
    Stream := TFileStream.Create(OSFriendlyPath(AFileName), fmCreate);
    try
      Header := 'GIF89a';
      Stream.WriteBuffer(Header[1], 6);
      // Logical screen: the frame size, no global colour table
      WriteLE16(Stream, W);
      WriteLE16(Stream, H);
      WriteByte(Stream, 0);   // no global table
      WriteByte(Stream, 0);   // background colour index
      WriteByte(Stream, 0);   // pixel aspect ratio not given

      // Loop for ever
      WriteByte(Stream, $21);
      WriteByte(Stream, $FF);
      WriteByte(Stream, 11);
      Stream.WriteBuffer(NETSCAPE[1], 11);
      WriteByte(Stream, 3);
      WriteByte(Stream, 1);
      WriteLE16(Stream, 0);   // 0: no limit
      WriteByte(Stream, 0);

      for I := 0 to High(AFrames) do
      begin
        Frame := QuantizeFrame(AFrames[I]);

        // Graphic control: restore to background, transparent entry 255
        WriteByte(Stream, $21);
        WriteByte(Stream, $F9);
        WriteByte(Stream, 4);
        WriteByte(Stream, (2 shl 2) or 1);
        WriteLE16(Stream, Max(2, ADelay));
        WriteByte(Stream, GIF_TRANSPARENT);
        WriteByte(Stream, 0);

        // Image: the whole screen, with its own 256-entry colour table
        WriteByte(Stream, $2C);
        WriteLE16(Stream, 0);
        WriteLE16(Stream, 0);
        WriteLE16(Stream, W);
        WriteLE16(Stream, H);
        WriteByte(Stream, $80 or 7);
        for Pos := 0 to 255 do
        begin
          WriteByte(Stream, Frame.Palette[Pos].R);
          WriteByte(Stream, Frame.Palette[Pos].G);
          WriteByte(Stream, Frame.Palette[Pos].B);
        end;

        // LZW data in sub-blocks of up to 255 bytes
        WriteByte(Stream, 8);
        Data := Lzw.Encode(Frame.Indices);
        Pos := 0;
        while Pos < Length(Data) do
        begin
          Len := Min(255, Length(Data) - Pos);
          WriteByte(Stream, Len);
          Stream.WriteBuffer(Data[Pos], Len);
          Inc(Pos, Len);
        end;
        WriteByte(Stream, 0);
      end;

      WriteByte(Stream, $3B);   // trailer
    finally
      Stream.Free;
    end;
  finally
    Lzw.Free;
  end;
end;

{ Metadata }

function MeasureFrameEmpty(const AFrame: TSprite3DImage): TSprite3DFrameEmpty;
var
  X, Y, MinX, MaxX, MinY, MaxY: Integer;
  Alpha: PByte;
begin
  MinX := AFrame.Width;
  MaxX := -1;
  MinY := AFrame.Height;
  MaxY := -1;
  if Length(AFrame.Pixels) >= Int64(AFrame.Width) * AFrame.Height * 4 then
    for Y := 0 to AFrame.Height - 1 do
    begin
      Alpha := @AFrame.Pixels[(NativeInt(Y) * AFrame.Width) * 4 + 3];
      for X := 0 to AFrame.Width - 1 do
      begin
        if Alpha^ <> 0 then
        begin
          if X < MinX then
            MinX := X;
          if X > MaxX then
            MaxX := X;
          if Y < MinY then
            MinY := Y;
          MaxY := Y;
        end;
        Inc(Alpha, 4);
      end;
    end;
  if MaxX < 0 then
  begin
    // Nothing drawn: empty from every side
    Result.Left := AFrame.Width;
    Result.Right := AFrame.Width;
    Result.Top := AFrame.Height;
    Result.Bottom := AFrame.Height;
  end
  else
  begin
    Result.Left := MinX;
    Result.Right := AFrame.Width - 1 - MaxX;
    Result.Top := MinY;
    Result.Bottom := AFrame.Height - 1 - MaxY;
  end;
end;

// The smallest page for ACount cells of AW by AH, at most AMaxSize each way:
// powers of 2 unless ANonPowerOf2, then the least area, then the squarer.
// False if none holds them.
function SizeAtlasPage(const ACount, AW, AH, AMaxSize: Integer; const ANonPowerOf2: Boolean;
  var APage: TSprite3DAtlasPage): Boolean;
var
  BestArea: Int64;
  BestSkew: Integer;

  procedure Consider(const AWidth, AHeight, ACols, ARows: Integer);
  var
    Area: Int64;
    Skew: Integer;
  begin
    if Int64(ACols) * ARows < ACount then
      Exit;
    Area := Int64(AWidth) * AHeight;
    Skew := Abs(AWidth - AHeight);
    if (Area < BestArea) or ((Area = BestArea) and (Skew < BestSkew)) then
    begin
      BestArea := Area;
      BestSkew := Skew;
      APage.Width := AWidth;
      APage.Height := AHeight;
      APage.Cols := ACols;
      APage.Rows := ARows;
    end;
  end;

var
  MaxCols, MaxRows, C, R, PW, PH: Integer;
begin
  BestArea := High(Int64);
  BestSkew := MaxInt;
  MaxCols := AMaxSize div AW;
  MaxRows := AMaxSize div AH;
  if ANonPowerOf2 then
    for C := 1 to Min(MaxCols, ACount) do
    begin
      R := (ACount + C - 1) div C;
      if R <= MaxRows then
        Consider(C * AW, R * AH, C, R);
    end
  else
  begin
    PW := 1;
    while PW <= AMaxSize do
    begin
      if PW >= AW then
      begin
        PH := 1;
        while PH <= AMaxSize do
        begin
          if PH >= AH then
            Consider(PW, PH, PW div AW, PH div AH);
          PH := PH * 2;
        end;
      end;
      PW := PW * 2;
    end;
  end;
  Result := BestArea < High(Int64);
end;

function PlanAtlasPages(const AFrameCounts: TArray<Integer>; const AFrameWidth,
  AFrameHeight, AMaxSize: Integer;
  const ANonPowerOf2: Boolean): TArray<TSprite3DAtlasPage>;
var
  Capacity: Int64;
  Page: TSprite3DAtlasPage;
  Pages: TArray<TSprite3DAtlasPage>;
  Slice: TSprite3DAtlasSlice;
  Done, Room: Integer;

  procedure ClosePage;
  begin
    if Page.FrameCount = 0 then
      Exit;
    // The page always fits: it holds no more than the full page's grid
    if SizeAtlasPage(Page.FrameCount, AFrameWidth, AFrameHeight, AMaxSize, ANonPowerOf2,
      Page) then
      Pages := Pages + [Page];
    Page := Default(TSprite3DAtlasPage);
  end;

begin
  Pages := nil;
  Page := Default(TSprite3DAtlasPage);
  if (AFrameWidth < 1) or (AFrameHeight < 1) then
    Capacity := 0
  else
    Capacity := Int64(AMaxSize div AFrameWidth) * (AMaxSize div AFrameHeight);
  if Capacity < 1 then
    Exit(nil);   // not even one frame fits a page
  for var I := 0 to High(AFrameCounts) do
  begin
    Done := 0;
    // As much of the animation as the page has room for, then the rest on
    // the next page, and the next
    while Done < AFrameCounts[I] do
    begin
      if Page.FrameCount >= Capacity then
        ClosePage;
      Room := Capacity - Page.FrameCount;
      Slice.Animation := I;
      Slice.First := Done;
      Slice.Count := Min(Room, AFrameCounts[I] - Done);
      Page.Slices := Page.Slices + [Slice];
      Inc(Page.FrameCount, Slice.Count);
      Inc(Done, Slice.Count);
    end;
  end;
  ClosePage;
  Result := Pages;
end;

function ComposeAtlasPage(const AFrames: TArray<TSprite3DImage>;
  const APage: TSprite3DAtlasPage): TSprite3DImage;
var
  W, H, I: Integer;
begin
  CheckFrames(AFrames, W, H);
  if (APage.Cols < 1) or (Int64(APage.Cols) * APage.Rows < Length(AFrames)) or
    (APage.Cols * W > APage.Width) or (APage.Rows * H > APage.Height) then
    raise EArgumentException.CreateFmt('%d frames of %d x %d do not fit a %d x %d page.',
      [Length(AFrames), W, H, APage.Width, APage.Height]);
  Result := TSprite3DImage.Create(APage.Width, APage.Height);
  for I := 0 to High(AFrames) do
    Blit(AFrames[I], Result, (I mod APage.Cols) * W, (I div APage.Cols) * H);
end;

function MeasureSheetMetadata(const AFileName: String; const AFrames: TArray<TSprite3DImage>;
  const AInfo: TSprite3DSheetInfo): TSprite3DSheetMetadata;
var
  W, H, I, Directions: Integer;
begin
  CheckFrames(AFrames, W, H);
  if (AInfo.Cols < 1) or (AInfo.Rows < 1) or
    (Int64(AInfo.Cols) * AInfo.Rows < Length(AFrames)) then
    raise EArgumentException.CreateFmt('%d frames do not fit %d columns by %d rows.',
      [Length(AFrames), AInfo.Cols, AInfo.Rows]);
  if Length(AInfo.AnimationFrames) <> Length(AInfo.Animations) then
    raise EArgumentException.Create('Each animation needs its frame count.');
  if Length(AInfo.AnimationTimes) <> Length(AInfo.Animations) then
    raise EArgumentException.Create('Each animation needs its time.');
  if Length(AInfo.Frames) <> Length(AFrames) then
    raise EArgumentException.Create('Each frame needs its animation, direction and number.');
  // The single dummy direction, if none is listed
  Directions := Max(1, Length(AInfo.Directions));
  for var Ref in AInfo.Frames do
    if (Ref.Animation < 0) or (Ref.Animation >= Length(AInfo.Animations)) or
      (Ref.Direction < 0) or (Ref.Direction >= Directions) or (Ref.Frame < 0) then
      raise EArgumentException.Create('A frame names an animation or direction that is ' +
        'not listed.');
  Result.FileName := AFileName;
  Result.FrameWidth := W;
  Result.FrameHeight := H;
  Result.Info := AInfo;
  SetLength(Result.Empties, Length(AFrames));
  for I := 0 to High(AFrames) do
    Result.Empties[I] := MeasureFrameEmpty(AFrames[I]);
end;

function FramesWithBorder(const AFrames: TArray<TSprite3DImage>): TArray<TSprite3DImage>;

  procedure Paint(var AImage: TSprite3DImage; const AX, AY: Integer);
  var
    At: NativeInt;
  begin
    At := (NativeInt(AY) * AImage.Width + AX) * 4;
    AImage.Pixels[At] := 0;         // R
    AImage.Pixels[At + 1] := 0;     // G
    AImage.Pixels[At + 2] := 0;     // B
    AImage.Pixels[At + 3] := 255;   // A
  end;

begin
  SetLength(Result, Length(AFrames));
  for var I := 0 to High(AFrames) do
  begin
    Result[I] := AFrames[I];
    // Its own pixels, so the frame given is not drawn on
    Result[I].Pixels := Copy(AFrames[I].Pixels);
    if (Result[I].Width < 1) or (Result[I].Height < 1) or
      (Length(Result[I].Pixels) < Int64(Result[I].Width) * Result[I].Height * 4) then
      Continue;
    for var X := 0 to Result[I].Width - 1 do
    begin
      Paint(Result[I], X, 0);
      Paint(Result[I], X, Result[I].Height - 1);
    end;
    for var Y := 0 to Result[I].Height - 1 do
    begin
      Paint(Result[I], 0, Y);
      Paint(Result[I], Result[I].Width - 1, Y);
    end;
  end;
end;

function LeastFrameEmpty(const AEmpties: TArray<TSprite3DFrameEmpty>): TSprite3DFrameEmpty;
var
  I: Integer;
begin
  // The smallest of each side over every frame; nothing drawn when there
  // are none
  if Length(AEmpties) = 0 then
  begin
    Result.Left := 0;
    Result.Top := 0;
    Result.Right := 0;
    Result.Bottom := 0;
    Exit;
  end;
  Result := AEmpties[0];
  for I := 1 to High(AEmpties) do
  begin
    Result.Left := Min(Result.Left, AEmpties[I].Left);
    Result.Top := Min(Result.Top, AEmpties[I].Top);
    Result.Right := Min(Result.Right, AEmpties[I].Right);
    Result.Bottom := Min(Result.Bottom, AEmpties[I].Bottom);
  end;
end;

// Writes the metadata file from what has been measured; ALeast is written as
// sprite_empty
procedure WriteMetadataFile(const AFileName: String; const AFrameWidth, AFrameHeight: Integer;
  const AEmpties: TArray<TSprite3DFrameEmpty>; const AInfo: TSprite3DSheetInfo;
  const ALeast: TSprite3DFrameEmpty);
var
  I: Integer;
  Root, Image, Item: TJSONObject;
  Frames, List: TJSONArray;

  function Sides(const AEmpty: TSprite3DFrameEmpty): TJSONObject;
  begin
    Result := TJSONObject.Create;
    Result.AddPair('left', TJSONNumber.Create(AEmpty.Left));
    Result.AddPair('top', TJSONNumber.Create(AEmpty.Top));
    Result.AddPair('right', TJSONNumber.Create(AEmpty.Right));
    Result.AddPair('bottom', TJSONNumber.Create(AEmpty.Bottom));
  end;

  // Text, or null if there is none
  function Text(const AValue: String): TJSONValue;
  begin
    if AValue.Trim = String.Empty then
      Result := TJSONNull.Create
    else
      Result := TJSONString.Create(AValue.Trim);
  end;

  // An angle or factor, to four places, which is more than a Single holds
  // reliably
  function Amount(const AValue: Single): TJSONNumber;
  begin
    Result := TJSONNumber.Create(RoundTo(AValue, -4));
  end;

  // A whole number, written without a decimal point, or null if not known
  function Coordinate(const AValue: Integer): TJSONValue;
  begin
    if AInfo.OriginKnown then
      Result := TJSONNumber.Create(AValue)
    else
      Result := TJSONNull.Create;
  end;

begin
  Root := TJSONObject.Create;
  try
    // Which page, who made it and when, first
    Item := TJSONObject.Create;
    Root.AddPair('meta', Item);
    Item.AddPair('page', TJSONNumber.Create(Max(1, AInfo.Meta.Page)));
    Item.AddPair('page_count', TJSONNumber.Create(Max(1, AInfo.Meta.PageCount)));
    // Over every page; a single image's own when not given
    if AInfo.Meta.TotalFrames > 0 then
      Item.AddPair('total_frames', TJSONNumber.Create(AInfo.Meta.TotalFrames))
    else
      Item.AddPair('total_frames', TJSONNumber.Create(Length(AEmpties)));
    Item.AddPair('creator', Text(AInfo.Meta.Creator));
    Item.AddPair('creator_url', Text(AInfo.Meta.CreatorUrl));
    Item.AddPair('modeller', Text(AInfo.Meta.Modeller));
    Item.AddPair('modeller_url', Text(AInfo.Meta.ModellerUrl));
    Item.AddPair('artist', Text(AInfo.Meta.Artist));
    Item.AddPair('artist_url', Text(AInfo.Meta.ArtistUrl));
    Item.AddPair('created', Text(AInfo.Meta.Created));
    Item.AddPair('modified', Text(AInfo.Meta.Modified));
    Item.AddPair('file', Text(AInfo.Meta.ModelFile));
    Image := TJSONObject.Create;
    Root.AddPair('image', Image);
    Item := TJSONObject.Create;
    Image.AddPair('size', Item);
    Item.AddPair('width', TJSONNumber.Create(AInfo.Width));
    Item.AddPair('height', TJSONNumber.Create(AInfo.Height));
    // One frame, the grab size
    Item := TJSONObject.Create;
    Image.AddPair('sprite_size', Item);
    Item.AddPair('width', TJSONNumber.Create(AFrameWidth));
    Item.AddPair('height', TJSONNumber.Create(AFrameHeight));
    Item := TJSONObject.Create;
    Image.AddPair('layout', Item);
    Item.AddPair('cols', TJSONNumber.Create(AInfo.Cols));
    Item.AddPair('rows', TJSONNumber.Create(AInfo.Rows));
    Item.AddPair('frame_count', TJSONNumber.Create(Length(AEmpties)));
    Item := TJSONObject.Create;
    Image.AddPair('origin', Item);
    Item.AddPair('x', Coordinate(AInfo.Origin.X));
    Item.AddPair('y', Coordinate(AInfo.Origin.Y));
    Image.AddPair('sprite_empty', Sides(ALeast));
    List := TJSONArray.Create;
    Image.AddPair('directions', List);
    if Length(AInfo.Directions) = 0 then
      List.Add(0)
    else
      for var Direction in AInfo.Directions do
        List.Add(Direction);
    // Each animation's name, its frames in all, and its own length in
    // seconds, which a changed frame count leaves as it is
    List := TJSONArray.Create;
    Image.AddPair('animations', List);
    for I := 0 to High(AInfo.Animations) do
    begin
      Item := TJSONObject.Create;
      List.AddElement(Item);
      Item.AddPair('name', AInfo.Animations[I]);
      Item.AddPair('frame_count', TJSONNumber.Create(AInfo.AnimationFrames[I]));
      Item.AddPair('time', Amount(AInfo.AnimationTimes[I]));
    end;
    Image.AddPair('unused', TJSONNumber.Create(Int64(AInfo.Cols) * AInfo.Rows -
      Length(AEmpties)));
    Image.AddPair('two_pass', TJSONBool.Create(AInfo.Meta.TwoPass));
    Item := TJSONObject.Create;
    Image.AddPair('overscan', Item);
    Item.AddPair('enabled', TJSONBool.Create(AInfo.Meta.OverscanEnabled));
    Item.AddPair('factor', TJSONNumber.Create(AInfo.Meta.Overscan));
    // The camera as the export started
    Item := TJSONObject.Create;
    Root.AddPair('camera', Item);
    Item.AddPair('view', Text(AInfo.Meta.Camera.View));
    if AInfo.Meta.Camera.Orthographic then
      Item.AddPair('projection', 'orthographic')
    else
      Item.AddPair('projection', 'perspective');
    Item.AddPair('azimuth', Amount(AInfo.Meta.Camera.Azimuth));
    Item.AddPair('inclination', Amount(AInfo.Meta.Camera.Inclination));
    Item.AddPair('roll', Amount(AInfo.Meta.Camera.Roll));
    // As captured: the export's own fit, not the on-screen view's
    Item.AddPair('distance', Amount(AInfo.Meta.Camera.Distance));
    if AInfo.Meta.Camera.Orthographic then
      Item.AddPair('ortho_height', Amount(AInfo.Meta.Camera.OrthoHeight))
    else
      Item.AddPair('ortho_height', TJSONNull.Create);
    var Pan := TJSONObject.Create;
    Item.AddPair('pan', Pan);
    Pan.AddPair('enabled', TJSONBool.Create(AInfo.Meta.Camera.PanEnabled));
    Pan.AddPair('x', Amount(AInfo.Meta.Camera.PanX));
    Pan.AddPair('z', Amount(AInfo.Meta.Camera.PanZ));
    Item.AddPair('locked', TJSONBool.Create(AInfo.Meta.Camera.Locked));
    // One entry per frame, in the order of the cells: which it is, and its
    // empty sections
    Frames := TJSONArray.Create;
    Root.AddPair('frames', Frames);
    for I := 0 to High(AEmpties) do
    begin
      Item := TJSONObject.Create;
      Frames.AddElement(Item);
      Item.AddPair('animation', TJSONNumber.Create(AInfo.Frames[I].Animation));
      Item.AddPair('direction', TJSONNumber.Create(AInfo.Frames[I].Direction));
      Item.AddPair('frame', TJSONNumber.Create(AInfo.Frames[I].Frame));
      // One set of empty sections per frame
      Item.AddPair('empty', Sides(AEmpties[I]));
    end;
    // UTF-8 without a byte order mark, which some JSON readers reject
    TFile.WriteAllBytes(OSFriendlyPath(AFileName), JsonToBytes(Root));
  finally
    Root.Free;
  end;
end;

procedure WriteSheetMetadata(const AMetadata: TSprite3DSheetMetadata);
begin
  WriteSheetMetadata(AMetadata, LeastFrameEmpty(AMetadata.Empties));
end;

procedure WriteSheetMetadata(const AMetadata: TSprite3DSheetMetadata;
  const ASpriteEmpty: TSprite3DFrameEmpty);
begin
  WriteMetadataFile(AMetadata.FileName, AMetadata.FrameWidth, AMetadata.FrameHeight,
    AMetadata.Empties, AMetadata.Info, ASpriteEmpty);
end;

procedure SaveSheetMetadata(const AFileName: String; const AFrames: TArray<TSprite3DImage>;
  const AInfo: TSprite3DSheetInfo);
begin
  WriteSheetMetadata(MeasureSheetMetadata(AFileName, AFrames, AInfo));
end;

function SafeFileStem(const AName: String): String;
const
  BAD = '/\:*?"<>|';
var
  I: Integer;
begin
  Result := AName;
  for I := 1 to Length(Result) do
    if (Result[I] < ' ') or (Pos(Result[I], BAD) > 0) then
      Result[I] := '_';
  Result := Result.Trim([' ', '.']);
  if Result = String.Empty then
    Result := 'animation';
end;

initialization
  InitCrcTable;

end.
