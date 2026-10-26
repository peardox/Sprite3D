//** @abstract(The Results tab: plays back the animations exported to a folder, from their
//** metadata and images alone.)
//**
//** TSprite3DResultsView builds its controls inside a parent, normally the main form's Results
//** tab. Select Folder, at the bottom, picks a folder, opening at the last place exports went.
//** Every .json in it is read with ReadResultsFolder; only what the metadata says is used, and
//** only files whose @code(animations) are objects, as Sprite3D now writes, each beside the
//** .png it describes. Beside Select Folder is the folder, with the name of the model its
//** exports were made from, from @code(meta.file) without its folder, cut short with an
//** ellipsis if need be. The animations found are listed on the right, the first selected. The
//** selected animation's frames for the current direction, the first to begin with, are cut
//** from the .png files, each @code(sprite_size), and played in the middle of the drawing area
//** at the animation's own rate, its @code(frame_count) frames over its @code(time) seconds,
//** over a grey checker that shows where it is transparent, with a 1-pixel yellow border round
//** it. Under it are a pair to step through the directions, with the direction showing, then
//** the player buttons, as on the Animated tab, with the frame showing, and the frame count
//** and rate; a static model's stills have nothing to play, so show the directions alone; then a Zoom slider that never lets the animation grow larger than the space it
//** has, and beside it a Grid Size slider for the checker's squares, in sprite pixels. The
//** checker zooms with the animation; Show grid, at the right of the Select Folder row, hides
//** or shows it. Directly under the list, level with that row, is a side, Left, Top, Right or
//** Bottom, with buttons that jump, paused, to the previous or next edge case: a frame, in any
//** animation and direction read, whose empty border on a side is its image's
//** @code(sprite_empty); hidden for a static model's stills, which are never edge cases. They
//** go through every side's in turn, left, top, right then bottom,
//** the side showing following, and say which of them all and which of its side's it is.
//** AniGif and MP4 exports are not read yet.
//**
//** The layout:
//**
//** @preformatted(
//** parent
//** |-- ListLayout @(right, the full height@)
//** |   |-- the animations found
//** |   `-- the empty finder @(bottom, level with the Select Folder row@): the side, the
//** |       previous and next edge case on any side, and which is showing
//** `-- MainLayout @(client@)
//**     |-- FolderLayout @(bottom@)
//**     |   |-- Select Folder
//**     |   |-- the folder read and its model, with an ellipsis if need be
//**     |   `-- @(right@) the frame's empty border on each side, while paused, then Show
//**     |       grid, apart from the empty finder
//**     `-- ViewerLayout @(client@)
//**         |-- AnimationControlsLayout @(bottom@)
//**         |   |-- the directions, the player buttons, the frame readout, the rate
//**         |   `-- Zoom; Grid Size
//**         `-- DrawingLayout @(client@)
//**             |-- the yellow border @(centred@), 2 pixels larger each way
//**             `-- AnimationLayout @(centred@)   sprite_size x zoom
//**                 |-- the checker, squares of Grid Size sprite pixels
//**                 `-- the frame showing, over it
//** )
unit Sprite3DResultsView;

{
  The Results tab: plays back the animations exported to a folder, from
  their metadata and images alone.

  TSprite3DResultsView builds its controls inside a parent, normally the
  main form's Results tab. Select Folder, at the bottom, picks a folder,
  opening at the last place exports went. Every .json in it is read with
  ReadResultsFolder; only what the metadata says is used, and only files
  whose animations are objects, as Sprite3D now writes, each beside the .png
  it describes. Beside Select Folder is the folder, with the name of the
  model its exports were made from, from meta.file without its folder, cut
  short with an ellipsis if need be. The animations found are listed on the
  right, the first selected. The selected animation's frames for the current
  direction, the first to begin with, are cut from the .png files, each
  sprite_size, and played in the middle of the drawing area at the
  animation's own rate, its frame_count frames over its time seconds, over a
  grey checker that shows where it is transparent, with a 1-pixel yellow
  border round it. Under it are a pair to step through the directions, with
  the direction showing, then the player buttons, as on the Animated tab,
  with the frame showing, and the frame count and rate; a static model's
  stills show the directions alone; then a Zoom slider that never lets
  the animation grow larger than the space it has, and beside it a Grid Size
  slider for the checker's squares, in sprite pixels. The checker zooms with
  the animation; Show grid, at the right of the Select Folder row, hides or
  shows it. Directly under the list, level with that row, is a side, Left,
  Top, Right or Bottom, with buttons that jump, paused, to the previous or
  next edge case: a frame, in any animation and direction read, whose empty
  border on a side is its image's sprite_empty; hidden for a static model's
  stills, which are never edge cases. They go through every side's
  in turn, left, top, right then bottom, the side showing following, and say
  which of them all and which of its side's it is. AniGif and MP4 exports are
  not read yet.

  The layout:

  parent
  |-- ListLayout (right, the full height)
  |   |-- the animations found
  |   `-- the empty finder (bottom, level with the Select Folder row): the side, the
  |       previous and next edge case on any side, and which is showing
  `-- MainLayout (client)
      |-- FolderLayout (bottom)
      |   |-- Select Folder
      |   |-- the folder read and its model, with an ellipsis if need be
      |   `-- (right) the frame's empty border on each side, then Show grid, apart
      |       from the empty finder
      `-- ViewerLayout (client)
          |-- AnimationControlsLayout (bottom)
          |   |-- the directions, the player buttons, the frame readout, the rate
          |   `-- Zoom; Grid Size
          `-- DrawingLayout (client)
              |-- the yellow border (centred), 2 pixels larger each way
              `-- AnimationLayout (centred)   sprite_size x zoom
                  |-- the checker, squares of Grid Size sprite pixels
                  `-- the frame showing, over it
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Diagnostics,
  System.Generics.Collections, FMX.Types, FMX.Controls, FMX.Graphics, FMX.Objects,
  FMX.Layouts, FMX.StdCtrls, FMX.ListBox;

type
  //** @abstract(The four sides of an empty border, in the order left, top, right, bottom.)
  TResultsSides = array[0..3] of Integer;

  //** @abstract(Where one frame is: which image, and which cell of its grid.)
  TResultsCell = record
    //** @abstract(The .png holding it; empty if no file has this frame.)
    FileName: String;
    //** @abstract(Its cell, counted from 0 left to right and then down.)
    Cell: Integer;
    //** @abstract(How many cells the image's grid has across.)
    Cols: Integer;
    //** @abstract(Whether Empty and SpriteEmpty were given in the metadata.)
    HasEmpty: Boolean;
    //** @abstract(This frame's empty border, frames[i].empty: left, top, right, bottom.)
    Empty: TResultsSides;
    //** @abstract(The image's image.sprite_empty, the least of its frames' empty borders:
    //** left, top, right, bottom.)
    SpriteEmpty: TResultsSides;
  end;

  //** @abstract(Where one frame is among a folder's animations: which animation, which of its
  //** directions, and which frame.)
  TResultsFrameRef = record
    //** @abstract(The animation, as an index into the animations read.)
    Animation: Integer;
    //** @abstract(The direction, as an index into that animation's Directions.)
    Direction: Integer;
    //** @abstract(The frame, counted from 0.)
    Frame: Integer;
  end;

  //** @abstract(One direction of an animation: its bearing and where each frame is.)
  TResultsDirection = record
    //** @abstract(The direction's compass bearing in degrees, as the metadata gives it.)
    Bearing: Double;
    //** @abstract(Each frame, in order, frame_count of them.)
    Frames: TArray<TResultsCell>;
  end;

  //** @abstract(An animation found in a folder's metadata.)
  TResultsAnimation = record
    //** @abstract(Its name, as the metadata gives it.)
    Name: String;
    //** @abstract(How many frames each direction has.)
    FrameCount: Integer;
    //** @abstract(How long it takes to play once, in seconds.)
    Time: Double;
    //** @abstract(One frame's width in pixels, image.sprite_size.)
    SpriteWidth: Integer;
    //** @abstract(One frame's height in pixels, image.sprite_size.)
    SpriteHeight: Integer;
    //** @abstract(Its directions, in the order they were first found.)
    Directions: TArray<TResultsDirection>;
    //** @abstract(True if it is a static model's stills, one frame in each direction,
    //** rather than an animation.)
    //**
    //** A still has nothing to play, so the player, its frame readout and the frame count
    //** and rate are hidden while it is selected, and so is the edge case finder; stills are
    //** never edge cases.)
    IsStill: Boolean;
  end;

//** @abstract(The animations described by the metadata files in a folder.)
//**
//** Every .json in AFolder, in name order, is read. One is used only if it is Sprite3D
//** metadata whose @code(animations) are objects with @code(name), @code(frame_count) and
//** @code(time), and the .png of the same name is beside it; metadata from before that
//** change is skipped. Each animation is listed once, in the order first found, with each of
//** its directions, by bearing, in the order first found; where two files hold the same
//** frame, the first one read is used. A file whose @code(sprite_size) or
//** @code(frame_count) for an animation differs from what was already found for it adds
//** nothing to that animation. A static model's stills, frames with @code(animation)
//** @code(null) and a @code(model) index into @code(meta.model), are listed as an entry of
//** one frame named after the model, each direction's still shown for a second. Each
//** frame's @code(empty) and its image's @code(sprite_empty) are kept with it. Only the
//** .json files are read, not the images.
//** Blocks while reading; touches no controls, so may be called on any thread.
//**
//** @param(AFolder The folder to read; nothing is found if it is empty or not there.)
//**
//** @param(AUsed Set to how many metadata files were used.)
//**
//** @param(ASkipped Set to how many .json files could not be used.)
//**
//** @param(AModels Set to the names of the model files the metadata used was made from,
//** from each file's @code(meta.file) with its folder taken off, each once, in the order
//** found; empty if none gives one.)
//**
//** @returns(The animations found, each with at least one frame placed; empty if none. A
//** dynamic array of records, owned by the caller.)
function ReadResultsFolder(const AFolder: String; out AUsed, ASkipped: Integer;
  out AModels: TArray<String>): TArray<TResultsAnimation>;

type
  //** @abstract(The Results tab's controls and player; see the unit description.)
  TSprite3DResultsView = class(TComponent)
  private
    FParent: TFmxObject;
    FFolderLayout: TLayout;
    FFolderButton: TButton;
    FFolderLabel: TLabel;
    FListLayout: TLayout;
    FList: TListBox;
    FViewerLayout: TLayout;
    FDrawingLayout: TLayout;
    FAnimationLayout: TLayout;
    FImage: TImage;
    // Behind FImage: the transparency checker, at the sprite's resolution,
    // stretched the same way, so it zooms with the frame exactly
    FGridImage: TImage;
    FGridLayout: TLayout;
    FZoomHalf: TLayout;
    FGridCheck: TCheckBox;
    // At the right of the Select Folder row: the frame's empty border on each
    // side, then Show grid; and whether the values' hint is shown
    FFolderRightLayout: TLayout;
    FEmptyLabel: TLabel;
    FShowEdgeHint: Boolean;
    FMainLayout: TLayout;
    FOnShowGridChange: TNotifyEvent;
    // The zoom chosen; what is shown is this or, if less, what fits
    FZoomWanted: Single;
    FOnZoomChange: TNotifyEvent;
    FGridTrack: TTrackBar;
    FGridLabel: TLabel;
    FGridSize: Integer;
    // The sprite size and grid size FGridImage was last drawn for
    FGridDrawnFor: TPoint;
    FGridDrawnSize: Integer;
    FMessageLabel: TLabel;
    FAnimationControlsLayout: TLayout;
    FTransportLayout: TLayout;
    FZoomLayout: TLayout;
    FFirstButton: TButton;
    FPreviousButton: TButton;
    FPlayButton: TButton;
    FNextButton: TButton;
    FLastButton: TButton;
    FFrameLabel: TLabel;
    FDirPreviousButton: TButton;
    FDirNextButton: TButton;
    FDirLabel: TLabel;
    FRateLabel: TLabel;
    FZoomTrack: TTrackBar;
    FZoomLabel: TLabel;
    // Around the animation, on the drawing area
    FBorder: TRectangle;
    // Third row: which side, and the frames whose empty on it is the
    // image's sprite_empty
    FEdgeLayout: TLayout;
    FEdgeBox: TComboBox;
    FEdgePreviousButton: TButton;
    FEdgeNextButton: TButton;
    FEdgeLabel: TLabel;
    // Every edge case read: each frame, of every animation and direction,
    // whose empty border on a side is its image's sprite_empty on that side,
    // a static model's stills left out; side by side, left, top, right then bottom, and within a side in list
    // order, then direction, then frame; FEdgeSides says which side each
    // is, and FEdgeSideStart and FEdgeSideCount where each side's run is.
    // Rebuilt when the folder changes. FEdgeAt is the edge case last gone
    // to, or -1; it is let go once another frame shows.
    FEdgeMatches: TArray<TResultsFrameRef>;
    FEdgeSides: TArray<Integer>;
    FEdgeSideStart: array[0..3] of Integer;
    FEdgeSideCount: array[0..3] of Integer;
    FEdgeAt: Integer;
    // True while the code, not the user, changes the side shown
    FSyncingEdgeBox: Boolean;
    FTimer: TTimer;
    // What was read, and what is showing
    FFolder: String;
    FLoaded: Boolean;
    FActive: Boolean;
    FAnimations: TArray<TResultsAnimation>;
    FAnimationIndex: Integer;
    FDirectionIndex: Integer;
    FFrames: TObjectList<TBitmap>;
    FFrame: Integer;
    // Playing: the clock since play started, and the frame it started from
    FPlaying: Boolean;
    FClock: TStopwatch;
    FStartFrame: Integer;
    FSyncing: Boolean;
    FOnDefaultFolder: TFunc<String>;
    procedure BuildControls;
    function AddIconButton(const AParent: TControl; const AIcon, AHint: String;
      const AOnClick: TNotifyEvent): TButton;
    function AddTextButton(const AParent: TControl; const AText, AHint: String;
      const AOnClick: TNotifyEvent): TButton;
    procedure IconButtonApplyStyle(Sender: TObject);
    procedure FolderButtonClick(Sender: TObject);
    procedure ListChange(Sender: TObject);
    procedure FirstButtonClick(Sender: TObject);
    procedure PreviousButtonClick(Sender: TObject);
    procedure PlayButtonClick(Sender: TObject);
    procedure NextButtonClick(Sender: TObject);
    procedure LastButtonClick(Sender: TObject);
    procedure DirPreviousButtonClick(Sender: TObject);
    procedure DirNextButtonClick(Sender: TObject);
    procedure EdgeBoxChange(Sender: TObject);
    procedure EdgePreviousButtonClick(Sender: TObject);
    procedure EdgeNextButtonClick(Sender: TObject);
    procedure SeekEdge(const AStep: Integer);
    function StillShowing: Boolean;
    procedure FindEdgeMatches;
    function EdgeMatchIndex: Integer;
    function IsShowing(const ARef: TResultsFrameRef): Boolean;
    procedure ShowEdgeSide(const ASide: Integer);
    procedure JumpTo(const ARef: TResultsFrameRef);
    procedure UpdateEdgeLabel;
    procedure UpdateEmptyLabel;
    procedure SetShowEdgeHint(const Value: Boolean);
    procedure ZoomTrackChange(Sender: TObject);
    procedure DrawingLayoutResized(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
    procedure SelectAnimation(const AIndex: Integer);
    procedure SelectDirection(const AIndex: Integer);
    procedure BuildFrames;
    procedure ShowFrame(const AFrame: Integer);
    procedure SetPlaying(const APlaying: Boolean);
    procedure StepTo(const AFrame: Integer);
    procedure UpdateZoomRange;
    procedure ApplyZoom;
    procedure GridTrackChange(Sender: TObject);
    procedure GridCheckChange(Sender: TObject);
    procedure SetZoom(const Value: Single);
    function GetShowGrid: Boolean;
    procedure SetShowGrid(const Value: Boolean);
    procedure ZoomLayoutResized(Sender: TObject);
    procedure UpdateGridRange;
    procedure DrawGrid;
    procedure UpdateControls;
    procedure ShowMessageText(const AText: String);
    function HasFrames: Boolean;
    function CurrentAnimation: TResultsAnimation;
    function FrameSeconds: Double;
  public
    //** @abstract(Builds the Results tab's controls in AParent, empty until a folder is
    //** read.)
    //**
    //** Nothing is read yet: the first folder is read by @link(SetActive) or
    //** @link(LoadFolder). Main thread only.
    //**
    //** @param(AOwner Owns the view, and frees it and every control it makes; normally the
    //** main form.)
    //**
    //** @param(AParent The control the view is built in, normally the Results tab; it must
    //** outlive the view.)
    constructor Create(AOwner: TComponent; const AParent: TFmxObject); reintroduce;
    //** @abstract(Stops playing and frees the frames.)
    //**
    //** The controls' events are unhooked first, so none reaches the view while its owner
    //** frees them. Main thread only.
    destructor Destroy; override;
    //** @abstract(Reads a folder's metadata, lists its animations and plays the first.)
    //**
    //** The folder is read with @link(ReadResultsFolder), replacing whatever was shown. The
    //** first animation is selected at its first direction and played at its own rate; its
    //** images are loaded then. If nothing usable is found, the drawing area says so. Blocks
    //** while the metadata and the first animation's images are read. Main thread only.
    //**
    //** @param(AFolder The folder to read.)
    procedure LoadFolder(const AFolder: String);
    //** @abstract(Tells the view whether its tab is showing, so it plays only while it is.)
    //**
    //** Hidden, the player's timer stops; shown, it carries on from the frame showing. The
    //** first time it is shown, or the first time after @link(FolderChanged) for the folder
    //** read, a folder is read: the one read before, or else the one OnDefaultFolder gives,
    //** if it is there. Main thread only.
    //**
    //** @param(AActive True when the tab has been shown, False when another has.)
    procedure SetActive(const AActive: Boolean);
    //** @abstract(Tells the view an export has written to a folder, so it can show the new
    //** files.)
    //**
    //** If AFolder is the folder read, it is read again: now if the tab is showing,
    //** otherwise when it is next shown. Any other folder is ignored. Main thread only.
    //**
    //** @param(AFolder The folder the export wrote to.)
    procedure FolderChanged(const AFolder: String);
    //** @abstract(Gives the folder where exports last went, for Select Folder and the first
    //** look.)
    //**
    //** Select Folder... opens there, and it is read the first time the tab shows if no
    //** folder has been read yet. It may return an empty string. Called on the main thread.
    property OnDefaultFolder: TFunc<String> read FOnDefaultFolder write FOnDefaultFolder;
    //** @abstract(Whether Show grid is ticked, so the checker is drawn behind the animation.)
    //**
    //** True until set. Setting it does not call OnShowGridChange. Main thread only.
    property ShowGrid: Boolean read GetShowGrid write SetShowGrid;
    //** @abstract(Called on the main thread when Show grid is ticked or cleared by hand, so
    //** the owner can keep the choice.)
    property OnShowGridChange: TNotifyEvent read FOnShowGridChange write FOnShowGridChange;
    //** @abstract(Whether the frame's empty border values, at the right of the Select Folder
    //** row, have a hint saying what they are; True until set.)
    //**
    //** File, Settings turns it off. Main thread only.
    property ShowEdgeHint: Boolean read FShowEdgeHint write SetShowEdgeHint;
    //** @abstract(The zoom chosen, as a multiple of the sprite size; 1 until set.)
    //**
    //** What is shown is this, or less where the drawing area is too small for it: the Zoom
    //** slider never goes past what fits, and comes back up towards this as the space grows.
    //** Setting it, as from a kept setting, shows it at once as far as the space allows, and
    //** does not call OnZoomChange; moving the slider by hand sets it and calls
    //** OnZoomChange. A value of 0 or less counts as 1. Main thread only.
    property Zoom: Single read FZoomWanted write SetZoom;
    //** @abstract(Called on the main thread each time Zoom is moved by hand, so the owner can
    //** keep the zoom chosen.)
    property OnZoomChange: TNotifyEvent read FOnZoomChange write FOnZoomChange;
    //** @abstract(The folder last read, or empty if none has been.)
    property Folder: String read FFolder;
  end;

implementation

uses
  System.Math, System.IOUtils, System.JSON, System.Generics.Defaults, FMX.Dialogs,
  Sprite3DHelpers;

const
  // How often the player looks at the clock, in milliseconds; which frame
  // shows comes from the clock, so this only bounds how late a frame can be
  TICK_MS = 10;
  // The smallest the animation can be drawn, unless even that does not fit
  ZOOM_MIN = 0.25;
  // Bearings closer than this are the same direction
  BEARING_TOLERANCE = 1E-3;

{ Reading }

// The animation called AName in AAnimations, or -1
function FindAnimation(const AAnimations: TArray<TResultsAnimation>;
  const AName: String): Integer;
begin
  for var I := 0 to High(AAnimations) do
    if AAnimations[I].Name = AName then
      Exit(I);
  Result := -1;
end;

// The direction of ABearing in AAnimation, added if it has none yet
function DirectionFor(var AAnimation: TResultsAnimation; const ABearing: Double): Integer;
var
  Direction: TResultsDirection;
begin
  for var I := 0 to High(AAnimation.Directions) do
    if Abs(AAnimation.Directions[I].Bearing - ABearing) < BEARING_TOLERANCE then
      Exit(I);
  Direction.Bearing := ABearing;
  SetLength(Direction.Frames, AAnimation.FrameCount);
  AAnimation.Directions := AAnimation.Directions + [Direction];
  Result := High(AAnimation.Directions);
end;

const
  SIDE_NAMES: array[0..3] of String = ('left', 'top', 'right', 'bottom');
  // How long a static model's still is played for, as the export shows it in
  // a GIF; one frame per direction
  STILL_SECONDS = 1.0;
  // The edge buttons' icons, plain triangles in a 24 by 24 box, pointing
  // left and right
  ICON_BACK = 'M16 6v12l-9-6z';
  // Grid Size: its range in sprite pixels, never more than half the
  // sprite's smaller side, and where it starts
  GRID_MIN = 1;
  GRID_MAX = 16;
  GRID_DEFAULT = 8;
  // The height of the Zoom and Grid Size rows
  SLIDER_ROW_HEIGHT = 26;
  // The checker's greys, as the view's Transparent background has them
  GRID_LIGHT = $FFCCCCCC;
  GRID_DARK = $FF999999;
  // What the empty finder says on any frame that is not a match
  EDGE_FINDER = 'Edge Case Finder';
  // The height of the Select Folder row and of the empty finder level with it
  BOTTOM_ROW_HEIGHT = 36;
  // At the right of the Select Folder row: the space the empty border
  // values have, wide enough for four 4-digit values, the gap between them
  // and Show grid, Show grid's width, and the space right of it
  EMPTY_VALUES_WIDTH = 150;
  EMPTY_VALUES_GAP = 16;
  GRID_CHECK_WIDTH = 90;
  GRID_CHECK_RIGHT = 16;
  // The animation list's width; the empty finder below it is as wide
  LIST_WIDTH = 300;
  ICON_FORWARD = 'M8 6v12l9-6z';
  SIDE_CAPTIONS: array[0..3] of String = ('Left', 'Top', 'Right', 'Bottom');

// An empty border object, { left, top, right, bottom }, into ASides; False,
// with ASides all 0, if AValue is not one
function ReadSides(const AValue: TJSONValue; out ASides: TResultsSides): Boolean;
begin
  for var K := 0 to 3 do
    ASides[K] := 0;
  Result := AValue is TJSONObject;
  if not Result then
    Exit;
  for var K := 0 to 3 do
    if not TJSONObject(AValue).TryGetValue<Integer>(SIDE_NAMES[K], ASides[K]) then
      Exit(False);
end;

// The model file's name, without its folder, from meta.file; the folder
// is cut at the last / or \ alike, as the file may have been written on
// another platform. Empty if the metadata gives none.
function ModelFileName(const ARoot: TJSONObject): String;
var
  Path: String;
  At: Integer;
begin
  Result := String.Empty;
  if not ARoot.TryGetValue<String>('meta.file', Path) then
    Exit;
  At := Max(Path.LastIndexOf('/'), Path.LastIndexOf('\'));
  Result := Path.Substring(At + 1).Trim;
end;

// Adds what one metadata file says to AAnimations, and its model file's
// name to AModels if it is not there yet; False if it is not metadata this
// can use
function ReadMetadataFile(const AFileName: String;
  var AAnimations: TArray<TResultsAnimation>; var AModels: TArray<String>): Boolean;
var
  Value: TJSONValue;
  Root, Image, Item: TJSONObject;
  List, Frames: TJSONArray;
  Png, Name: String;
  SpriteWidth, SpriteHeight, Cols, Count, AnimationIndex, DirectionIndex, Frame: Integer;
  SpriteEmpty, FrameEmpty: TResultsSides;
  HasSpriteEmpty: Boolean;
  Model: String;
  Names: TArray<String>;
  Known: Boolean;
  Time: Double;
  Bearings: TArray<Double>;
  // For each of this file's animations, its index in AAnimations, or -1 if
  // this file's frames of it are not used; and the same for each of its
  // models, whose stills are listed as one-frame entries named after them
  Targets: TArray<Integer>;
  ModelTargets: TArray<Integer>;
  ModelIndex: Integer;
  Animation: TResultsAnimation;

  // The entry for AName, of ACount frames lasting ATime, in AAnimations:
  // found, or added; -1 if another export of it, at another size or length,
  // is listed already, as the two are not mixed
  function Target(const AName: String; const ACount: Integer; const ATime: Double;
    const AIsStill: Boolean): Integer;
  begin
    Result := FindAnimation(AAnimations, AName);
    if Result < 0 then
    begin
      Animation.Name := AName;
      Animation.IsStill := AIsStill;
      Animation.FrameCount := ACount;
      Animation.Time := ATime;
      Animation.SpriteWidth := SpriteWidth;
      Animation.SpriteHeight := SpriteHeight;
      Animation.Directions := nil;
      AAnimations := AAnimations + [Animation];
      Result := High(AAnimations);
    end
    else if (AAnimations[Result].SpriteWidth <> SpriteWidth) or
      (AAnimations[Result].SpriteHeight <> SpriteHeight) or
      (AAnimations[Result].FrameCount <> ACount) or
      (AAnimations[Result].IsStill <> AIsStill) then
      Result := -1;
  end;

begin
  Result := False;
  Png := TPath.ChangeExtension(AFileName, '.png');
  if not TFile.Exists(Png) then
    Exit;
  try
    Value := TJSONObject.ParseJSONValue(TFile.ReadAllText(AFileName, TEncoding.UTF8));
  except
    Exit;
  end;
  try
    if not (Value is TJSONObject) then
      Exit;
    Root := TJSONObject(Value);
    if not (Root.Values['image'] is TJSONObject) or not (Root.Values['frames'] is TJSONArray) then
      Exit;
    Image := TJSONObject(Root.Values['image']);
    Frames := TJSONArray(Root.Values['frames']);
    if not Image.TryGetValue<Integer>('sprite_size.width', SpriteWidth) or
      not Image.TryGetValue<Integer>('sprite_size.height', SpriteHeight) or
      not Image.TryGetValue<Integer>('layout.cols', Cols) or
      (SpriteWidth < 1) or (SpriteHeight < 1) or (Cols < 1) then
      Exit;
    // The least empty border of the image's frames, to compare each with
    HasSpriteEmpty := ReadSides(Image.Values['sprite_empty'], SpriteEmpty);
    // The directions, by bearing; one dummy 0 without directions
    Bearings := nil;
    if Image.Values['directions'] is TJSONArray then
      for var Bearing in TJSONArray(Image.Values['directions']) do
        if Bearing is TJSONNumber then
          Bearings := Bearings + [TJSONNumber(Bearing).AsDouble];
    if Length(Bearings) = 0 then
      Bearings := [0.0];
    // The animations: objects with a name, frame count and time; the older
    // list of names alone says nothing of the time, so is not used
    if not (Image.Values['animations'] is TJSONArray) then
      Exit;
    List := TJSONArray(Image.Values['animations']);
    Targets := nil;
    for var Entry in List do
    begin
      if not (Entry is TJSONObject) then
        Exit;
      Item := TJSONObject(Entry);
      if not Item.TryGetValue<String>('name', Name) or
        not Item.TryGetValue<Integer>('frame_count', Count) or
        not Item.TryGetValue<Double>('time', Time) or (Count < 1) then
        Exit;
      Targets := Targets + [Target(Name, Count, Time, False)];
    end;
    // The models, meta.model: a static model's stills, one frame each,
    // shown for STILL_SECONDS, are listed under its name; an animated
    // model's are listed but none of its frames indexes it
    ModelTargets := nil;
    if (Root.Values['meta'] is TJSONObject) and
      (TJSONObject(Root.Values['meta']).Values['model'] is TJSONArray) then
      for var Entry in TJSONArray(TJSONObject(Root.Values['meta']).Values['model']) do
        if (Entry is TJSONObject) and TJSONObject(Entry).TryGetValue<String>('name', Name) and
          (Name <> String.Empty) then
          ModelTargets := ModelTargets + [Target(Name, 1, STILL_SECONDS, True)]
        else
          ModelTargets := ModelTargets + [-1];
    // Where each frame is: cell I of this image
    for var I := 0 to Frames.Count - 1 do
    begin
      if not (Frames.Items[I] is TJSONObject) then
        Continue;
      Item := TJSONObject(Frames.Items[I]);
      if not Item.TryGetValue<Integer>('direction', DirectionIndex) or
        not Item.TryGetValue<Integer>('frame', Frame) or
        (DirectionIndex < 0) or (DirectionIndex > High(Bearings)) then
        Continue;
      // An animation's frame, or else a model's still, its model's only frame
      if Item.TryGetValue<Integer>('animation', AnimationIndex) then
      begin
        if (AnimationIndex < 0) or (AnimationIndex > High(Targets)) then
          Continue;
        AnimationIndex := Targets[AnimationIndex];
      end
      else if Item.TryGetValue<Integer>('model', ModelIndex) then
      begin
        if (ModelIndex < 0) or (ModelIndex > High(ModelTargets)) then
          Continue;
        AnimationIndex := ModelTargets[ModelIndex];
        Frame := 0;
      end
      else
        Continue;
      if AnimationIndex < 0 then
        Continue;
      if (Frame < 0) or (Frame >= AAnimations[AnimationIndex].FrameCount) then
        Continue;
      DirectionIndex := DirectionFor(AAnimations[AnimationIndex], Bearings[DirectionIndex]);
      // The first file read with this frame keeps it
      if AAnimations[AnimationIndex].Directions[DirectionIndex].Frames[Frame].FileName =
        String.Empty then
      begin
        AAnimations[AnimationIndex].Directions[DirectionIndex].Frames[Frame].FileName := Png;
        AAnimations[AnimationIndex].Directions[DirectionIndex].Frames[Frame].Cell := I;
        AAnimations[AnimationIndex].Directions[DirectionIndex].Frames[Frame].Cols := Cols;
        AAnimations[AnimationIndex].Directions[DirectionIndex].Frames[Frame].HasEmpty :=
          HasSpriteEmpty and ReadSides(Item.Values['empty'], FrameEmpty);
        AAnimations[AnimationIndex].Directions[DirectionIndex].Frames[Frame].Empty :=
          FrameEmpty;
        AAnimations[AnimationIndex].Directions[DirectionIndex].Frames[Frame].SpriteEmpty :=
          SpriteEmpty;
      end;
    end;
    // The models the frames were made from, each named once: meta.file, or
    // where that is null, as for an atlas page of several static models,
    // each file meta.model lists
    Names := nil;
    Model := ModelFileName(Root);
    if Model <> String.Empty then
      Names := [Model]
    else if (Root.Values['meta'] is TJSONObject) and
      (TJSONObject(Root.Values['meta']).Values['model'] is TJSONArray) then
      for var Entry in TJSONArray(TJSONObject(Root.Values['meta']).Values['model']) do
        if (Entry is TJSONObject) and TJSONObject(Entry).TryGetValue<String>('file', Model) then
        begin
          Model := Model.Substring(Max(Model.LastIndexOf('/'), Model.LastIndexOf('\')) + 1).Trim;
          if Model <> String.Empty then
            Names := Names + [Model];
        end;
    for Model in Names do
    begin
      Known := False;
      for var Other in AModels do
        Known := Known or SameText(Other, Model);
      if not Known then
        AModels := AModels + [Model];
    end;
    Result := True;
  finally
    Value.Free;
  end;
end;

function ReadResultsFolder(const AFolder: String; out AUsed, ASkipped: Integer;
  out AModels: TArray<String>): TArray<TResultsAnimation>;
var
  Files: TArray<String>;
begin
  Result := nil;
  AUsed := 0;
  ASkipped := 0;
  AModels := nil;
  if (AFolder = String.Empty) or not TDirectory.Exists(AFolder) then
    Exit;
  Files := TDirectory.GetFiles(AFolder, '*.json');
  TArray.Sort<String>(Files, TComparer<String>.Construct(
    function(const A, B: String): Integer
    begin
      Result := CompareText(A, B);
    end));
  for var FileName in Files do
    if ReadMetadataFile(FileName, Result, AModels) then
      Inc(AUsed)
    else
      Inc(ASkipped);
  // An animation none of whose frames could be placed has nothing to show
  for var I := High(Result) downto 0 do
    if Length(Result[I].Directions) = 0 then
      Delete(Result, I, 1);
end;

{ TSprite3DResultsView }

constructor TSprite3DResultsView.Create(AOwner: TComponent; const AParent: TFmxObject);
begin
  inherited Create(AOwner);
  FParent := AParent;
  FFrames := TObjectList<TBitmap>.Create(True);
  FAnimationIndex := -1;
  FEdgeAt := -1;
  FShowEdgeHint := True;
  FDirectionIndex := 0;
  FZoomWanted := 1;
  FTimer := TTimer.Create(Self);
  FTimer.Enabled := False;
  FTimer.Interval := TICK_MS;
  FTimer.OnTimer := TimerTimer;
  BuildControls;
  ShowMessageText('Select a folder of exports to play them back here.');
  UpdateControls;
end;

destructor TSprite3DResultsView.Destroy;
begin
  // Nothing reacts while the controls go: freeing the list or resizing the
  // drawing area would otherwise call back into a half-freed view
  if Assigned(FTimer) then
  begin
    FTimer.Enabled := False;
    FTimer.OnTimer := nil;
  end;
  if Assigned(FList) then
    FList.OnChange := nil;
  if Assigned(FDrawingLayout) then
    FDrawingLayout.OnResized := nil;
  if Assigned(FZoomTrack) then
    FZoomTrack.OnChange := nil;
  if Assigned(FGridTrack) then
    FGridTrack.OnChange := nil;
  if Assigned(FGridCheck) then
    FGridCheck.OnChange := nil;
  if Assigned(FZoomLayout) then
    FZoomLayout.OnResized := nil;
  if Assigned(FEdgeBox) then
    FEdgeBox.OnChange := nil;
  FreeAndNil(FFrames);
  inherited;
end;

function TSprite3DResultsView.AddIconButton(const AParent: TControl; const AIcon,
  AHint: String; const AOnClick: TNotifyEvent): TButton;
var
  Icon: FMX.Objects.TPath;
begin
  Result := TButton.Create(Self);
  Result.Parent := AParent;
  // Left-aligned controls are ordered by their X: each goes after the last
  Result.Position.X := AParent.ChildrenCount * 1000;
  Result.Align := TAlignLayout.Left;
  Result.Width := 30;
  Result.Margins.Right := 2;
  Result.Text := String.Empty;
  Result.Hint := AHint;
  Result.ShowHint := True;
  Result.OnClick := AOnClick;
  Result.OnApplyStyleLookup := IconButtonApplyStyle;
  Icon := FMX.Objects.TPath.Create(Self);
  Icon.Parent := Result;
  Icon.Align := TAlignLayout.Center;
  Icon.Width := 24;
  Icon.Height := 24;
  Icon.WrapMode := TPathWrapMode.Original;
  Icon.Data.Data := AIcon;
  Icon.Stroke.Kind := TBrushKind.None;
  Icon.Fill.Color := TAlphaColors.Black;   // the theme's colour once styled
  Icon.HitTest := False;
  Result.TagObject := Icon;
end;

function TSprite3DResultsView.AddTextButton(const AParent: TControl; const AText,
  AHint: String; const AOnClick: TNotifyEvent): TButton;
begin
  Result := TButton.Create(Self);
  Result.Parent := AParent;
  Result.Position.X := AParent.ChildrenCount * 1000;
  Result.Align := TAlignLayout.Left;
  Result.Width := 30;
  Result.Margins.Right := 2;
  Result.Text := AText;
  Result.Hint := AHint;
  Result.ShowHint := True;
  Result.OnClick := AOnClick;
end;

// An icon takes the colour the theme gives the button's text
procedure TSprite3DResultsView.IconButtonApplyStyle(Sender: TObject);
var
  Button: TButton;
begin
  Button := Sender as TButton;
  if Button.TagObject is FMX.Objects.TPath then
    FMX.Objects.TPath(Button.TagObject).Fill.Color := Button.ResultingTextSettings.FontColor;
end;

procedure TSprite3DResultsView.BuildControls;
var
  Row: TLayout;

  function AddLabel(const AParent: TControl; const AAlign: TAlignLayout;
    const AWidth: Single): TLabel;
  begin
    Result := TLabel.Create(Self);
    Result.Parent := AParent;
    Result.Position.X := AParent.ChildrenCount * 1000;
    Result.Align := AAlign;
    if AWidth > 0 then
      Result.Width := AWidth;
    Result.TextSettings.WordWrap := False;
    Result.HitTest := False;
  end;

begin
  // Right: the animations found, with the empty finder directly under
  // them; this column runs the full height
  FListLayout := TLayout.Create(Self);
  FListLayout.Parent := FParent;
  FListLayout.Align := TAlignLayout.Right;
  FListLayout.Width := LIST_WIDTH;
  FListLayout.Padding.Rect := TRectF.Create(4, 4, 4, 0);
  // At the foot of the column, level with the Select Folder row: a side,
  // and back and forward to the frames whose empty border on that side is
  // the image's sprite_empty
  FEdgeLayout := TLayout.Create(Self);
  FEdgeLayout.Parent := FListLayout;
  FEdgeLayout.Align := TAlignLayout.Bottom;
  FEdgeLayout.Height := BOTTOM_ROW_HEIGHT;
  FEdgeLayout.Padding.Rect := TRectF.Create(0, 4, 0, 4);
  FEdgeBox := TComboBox.Create(Self);
  FEdgeBox.Parent := FEdgeLayout;
  FEdgeBox.Position.X := 0;
  FEdgeBox.Align := TAlignLayout.Left;
  FEdgeBox.Width := 84;
  for var Caption in SIDE_CAPTIONS do
    FEdgeBox.Items.Add(Caption);
  FEdgeBox.ItemIndex := 0;
  FEdgeBox.Hint := 'The side of the edge case showing, and the side the next one is ' +
    'looked for from: edge cases are the frames whose empty border on a side is the ' +
    'least of all the frames, sprite_empty, gone through left, top, right then bottom';
  FEdgeBox.ShowHint := True;
  FEdgeBox.OnChange := EdgeBoxChange;
  FEdgePreviousButton := AddIconButton(FEdgeLayout, ICON_BACK,
    'The previous edge case, in any animation and direction, on to the side before after ' +
    'the first on this side',
    EdgePreviousButtonClick);
  FEdgePreviousButton.Margins.Left := 4;
  FEdgeNextButton := AddIconButton(FEdgeLayout, ICON_FORWARD,
    'The next edge case, in any animation and direction, on to the side after after the ' +
    'last on this side',
    EdgeNextButtonClick);
  FEdgeLabel := AddLabel(FEdgeLayout, TAlignLayout.Client, 0);
  FEdgeLabel.Margins.Left := 6;
  // The values themselves are in the hint, as the row is narrow
  FEdgeLabel.HitTest := True;
  FEdgeLabel.ShowHint := True;
  FList := TListBox.Create(Self);
  FList.Parent := FListLayout;
  FList.Align := TAlignLayout.Client;
  FList.OnChange := ListChange;

  // Left: everything else, the Select Folder row at its foot. Top- and
  // bottom-aligned controls are always laid out before right-aligned ones,
  // so the row is kept in here to keep it clear of the list's column.
  FMainLayout := TLayout.Create(Self);
  FMainLayout.Parent := FParent;
  FMainLayout.Align := TAlignLayout.Client;
  FFolderLayout := TLayout.Create(Self);
  FFolderLayout.Parent := FMainLayout;
  FFolderLayout.Align := TAlignLayout.Bottom;
  FFolderLayout.Height := BOTTOM_ROW_HEIGHT;
  FFolderLayout.Padding.Rect := TRectF.Create(4, 4, 4, 4);
  FFolderButton := TButton.Create(Self);
  FFolderButton.Parent := FFolderLayout;
  FFolderButton.Align := TAlignLayout.Left;
  FFolderButton.Width := 110;
  FFolderButton.Text := 'Select Folder...';
  FFolderButton.Hint := 'Choose a folder of exports to play back; it opens where the ' +
    'last export went';
  FFolderButton.ShowHint := True;
  FFolderButton.OnClick := FolderButtonClick;
  // At the right of the row, in a layout of their own, fixed in size, with
  // each at a fixed place in it rather than aligned, so Show grid never
  // moves whether the values show or not: the frame's empty border on each
  // side, right-aligned in its own space, a gap, then Show grid, kept apart
  // from the empty finder
  FFolderRightLayout := TLayout.Create(Self);
  FFolderRightLayout.Parent := FFolderLayout;
  FFolderRightLayout.Align := TAlignLayout.Right;
  FFolderRightLayout.Width := EMPTY_VALUES_WIDTH + EMPTY_VALUES_GAP + GRID_CHECK_WIDTH +
    GRID_CHECK_RIGHT;
  FEmptyLabel := TLabel.Create(Self);
  FEmptyLabel.Parent := FFolderRightLayout;
  FEmptyLabel.Align := TAlignLayout.Vertical;
  FEmptyLabel.Position.X := 0;
  FEmptyLabel.Width := EMPTY_VALUES_WIDTH;
  FEmptyLabel.TextSettings.HorzAlign := TTextAlign.Trailing;
  FEmptyLabel.TextSettings.WordWrap := False;
  FEmptyLabel.HitTest := True;
  FEmptyLabel.Text := String.Empty;
  FGridCheck := TCheckBox.Create(Self);
  FGridCheck.Parent := FFolderRightLayout;
  FGridCheck.Align := TAlignLayout.Vertical;
  FGridCheck.Position.X := EMPTY_VALUES_WIDTH + EMPTY_VALUES_GAP;
  FGridCheck.Width := GRID_CHECK_WIDTH;
  FGridCheck.Text := 'Show grid';
  FGridCheck.Hint := 'Draw the checker behind the animation, showing where it is ' +
    'transparent';
  FGridCheck.ShowHint := True;
  FGridCheck.IsChecked := True;
  FGridCheck.OnChange := GridCheckChange;
  // The folder read and its model, between Select Folder and Show grid,
  // cut short with an ellipsis where it would run into Show grid; the whole
  // of it is its hint
  FFolderLabel := TLabel.Create(Self);
  FFolderLabel.Parent := FFolderLayout;
  FFolderLabel.Align := TAlignLayout.Client;
  FFolderLabel.Margins.Left := 8;
  FFolderLabel.TextSettings.WordWrap := False;
  FFolderLabel.TextSettings.Trimming := TTextTrimming.Character;
  FFolderLabel.HitTest := True;
  FFolderLabel.ShowHint := True;
  FFolderLabel.Text := String.Empty;

  // The rest: the drawing area, and the controls under it
  FViewerLayout := TLayout.Create(Self);
  FViewerLayout.Parent := FMainLayout;
  FViewerLayout.Align := TAlignLayout.Client;

  FAnimationControlsLayout := TLayout.Create(Self);
  FAnimationControlsLayout.Parent := FViewerLayout;
  FAnimationControlsLayout.Align := TAlignLayout.Bottom;
  // The player's row, then the sliders' row
  FAnimationControlsLayout.Height := 36 + SLIDER_ROW_HEIGHT + 8;

  // First row: the directions and their readout, then the player and the
  // frame readout, then the frame count and rate; the player, its readout
  // and the rate are hidden for a static model's stills
  FTransportLayout := TLayout.Create(Self);
  FTransportLayout.Parent := FAnimationControlsLayout;
  FTransportLayout.Align := TAlignLayout.Top;
  FTransportLayout.Height := 36;
  FTransportLayout.Padding.Rect := TRectF.Create(4, 4, 4, 2);
  FDirPreviousButton := AddTextButton(FTransportLayout, '<', 'Previous direction',
    DirPreviousButtonClick);
  FDirNextButton := AddTextButton(FTransportLayout, '>', 'Next direction',
    DirNextButtonClick);
  // Wide enough for "Direction 16 of 16 (337.5°)", and no wider, so the
  // rate has the room it needs
  FDirLabel := AddLabel(FTransportLayout, TAlignLayout.Left, 150);
  FDirLabel.Margins.Left := 4;
  FFirstButton := AddIconButton(FTransportLayout, ICON_FIRST, 'First frame',
    FirstButtonClick);
  FFirstButton.Margins.Left := 8;
  FPreviousButton := AddIconButton(FTransportLayout, ICON_PREVIOUS, 'Previous frame',
    PreviousButtonClick);
  FPlayButton := AddIconButton(FTransportLayout, ICON_PLAY, 'Play', PlayButtonClick);
  FNextButton := AddIconButton(FTransportLayout, ICON_NEXT, 'Next frame',
    NextButtonClick);
  FLastButton := AddIconButton(FTransportLayout, ICON_LAST, 'Last frame',
    LastButtonClick);
  FFrameLabel := AddLabel(FTransportLayout, TAlignLayout.Left, 64);
  FFrameLabel.Margins.Left := 4;
  FFrameLabel.Hint := 'The frame showing';
  FRateLabel := AddLabel(FTransportLayout, TAlignLayout.Client, 0);
  FRateLabel.Margins.Left := 2;

  // Second row: Zoom on the left half, Grid Size on the right
  FZoomLayout := TLayout.Create(Self);
  FZoomLayout.Parent := FAnimationControlsLayout;
  FZoomLayout.Align := TAlignLayout.Client;
  FZoomLayout.Padding.Rect := TRectF.Create(4, 2, 8, 4);
  FZoomLayout.OnResized := ZoomLayoutResized;
  // The left half: Zoom, at the top
  FZoomHalf := TLayout.Create(Self);
  FZoomHalf.Parent := FZoomLayout;
  FZoomHalf.Position.X := 0;
  FZoomHalf.Align := TAlignLayout.Left;
  FZoomHalf.Width := 200;
  FZoomHalf.Margins.Right := 8;
  Row := TLayout.Create(Self);
  Row.Parent := FZoomHalf;
  Row.Align := TAlignLayout.Top;
  Row.Height := SLIDER_ROW_HEIGHT;
  FZoomLabel := AddLabel(Row, TAlignLayout.Left, 90);
  FZoomTrack := TTrackBar.Create(Self);
  FZoomTrack.Parent := Row;
  FZoomTrack.Align := TAlignLayout.Client;
  FZoomTrack.Min := ZOOM_MIN;
  FZoomTrack.Max := 1;
  FZoomTrack.Frequency := 0;
  FZoomTrack.Value := 1;
  FZoomTrack.Hint := 'Magnify the animation, as far as the space for it allows';
  FZoomTrack.ShowHint := True;
  FZoomTrack.OnChange := ZoomTrackChange;
  // The right half: Grid Size, the checker's squares in sprite pixels
  FGridLayout := TLayout.Create(Self);
  FGridLayout.Parent := FZoomLayout;
  FGridLayout.Align := TAlignLayout.Client;
  Row := TLayout.Create(Self);
  Row.Parent := FGridLayout;
  Row.Align := TAlignLayout.Top;
  Row.Height := SLIDER_ROW_HEIGHT;
  FGridLabel := AddLabel(Row, TAlignLayout.Left, 90);
  FGridTrack := TTrackBar.Create(Self);
  FGridTrack.Parent := Row;
  FGridTrack.Align := TAlignLayout.Client;
  FGridTrack.Min := GRID_MIN;
  FGridTrack.Max := GRID_MAX;
  FGridTrack.Frequency := 1;
  FGridSize := GRID_DEFAULT;
  FGridTrack.Value := FGridSize;
  FGridTrack.Hint := 'The size of the checker''s squares behind the animation, in the ' +
    'sprite''s own pixels';
  FGridTrack.ShowHint := True;
  FGridTrack.OnChange := GridTrackChange;
  FGridLabel.Text := Format('Grid %dpx', [FGridSize]);

  // The drawing area, the animation centred in it
  FDrawingLayout := TLayout.Create(Self);
  FDrawingLayout.Parent := FViewerLayout;
  FDrawingLayout.Align := TAlignLayout.Client;
  FDrawingLayout.ClipChildren := True;
  FDrawingLayout.OnResized := DrawingLayoutResized;
  // A 1-pixel yellow border round the animation, drawn on the drawing area
  // just outside it: centred like it and 2 pixels larger each way, so it
  // covers none of the animation's own pixels
  FBorder := TRectangle.Create(Self);
  FBorder.Parent := FDrawingLayout;
  FBorder.Align := TAlignLayout.Center;
  FBorder.Fill.Kind := TBrushKind.None;
  FBorder.Stroke.Kind := TBrushKind.Solid;
  FBorder.Stroke.Color := TAlphaColors.Yellow;
  FBorder.Stroke.Thickness := 1;
  FBorder.HitTest := False;
  FBorder.Visible := False;
  FAnimationLayout := TLayout.Create(Self);
  FAnimationLayout.Parent := FDrawingLayout;
  FAnimationLayout.Align := TAlignLayout.Center;
  FAnimationLayout.Width := 1;
  FAnimationLayout.Height := 1;
  // The checker first, so the frame is drawn over it
  FGridImage := TImage.Create(Self);
  FGridImage.Parent := FAnimationLayout;
  FGridImage.Align := TAlignLayout.Client;
  FGridImage.WrapMode := TImageWrapMode.Stretch;
  FGridImage.DisableInterpolation := True;
  FGridImage.HitTest := False;
  FGridImage.Visible := False;
  FImage := TImage.Create(Self);
  FImage.Parent := FAnimationLayout;
  FImage.Align := TAlignLayout.Client;
  FImage.WrapMode := TImageWrapMode.Stretch;
  // Pixels stay sharp when magnified
  FImage.DisableInterpolation := True;
  FImage.HitTest := False;
  FMessageLabel := TLabel.Create(Self);
  FMessageLabel.Parent := FDrawingLayout;
  FMessageLabel.Align := TAlignLayout.Client;
  FMessageLabel.TextSettings.HorzAlign := TTextAlign.Center;
  FMessageLabel.TextSettings.VertAlign := TTextAlign.Center;
  FMessageLabel.TextSettings.WordWrap := True;
  FMessageLabel.HitTest := False;
end;

procedure TSprite3DResultsView.ShowMessageText(const AText: String);
begin
  FMessageLabel.Text := AText;
  FMessageLabel.Visible := AText <> String.Empty;
end;

function TSprite3DResultsView.HasFrames: Boolean;
begin
  Result := FFrames.Count > 0;
end;

function TSprite3DResultsView.CurrentAnimation: TResultsAnimation;
begin
  Result := FAnimations[FAnimationIndex];
end;

// Whether the entry selected is a static model's stills
function TSprite3DResultsView.StillShowing: Boolean;
begin
  Result := (FAnimationIndex >= 0) and (FAnimationIndex <= High(FAnimations)) and
    FAnimations[FAnimationIndex].IsStill;
end;

// How long each frame shows: the animation's time over its frames
function TSprite3DResultsView.FrameSeconds: Double;
var
  Time: Double;
begin
  Result := 0;
  if (FAnimationIndex < 0) or (CurrentAnimation.FrameCount < 1) then
    Exit;
  Time := CurrentAnimation.Time;
  if Time <= 0 then
    Time := 1;   // no length given: a second
  Result := Time / CurrentAnimation.FrameCount;
end;

procedure TSprite3DResultsView.FolderButtonClick(Sender: TObject);
var
  Folder: String;
begin
  {$IF DEFINED(ANDROID) or DEFINED(IOS)}
  // No folder dialog there: exports always go to the one folder
  if Assigned(FOnDefaultFolder) then
    LoadFolder(FOnDefaultFolder());
  {$ELSE}
  // Where the last export went, or the folder read, or Documents
  Folder := String.Empty;
  if Assigned(FOnDefaultFolder) then
    Folder := FOnDefaultFolder();
  if (Folder = String.Empty) or not TDirectory.Exists(Folder) then
    Folder := FFolder;
  if (Folder = String.Empty) or not TDirectory.Exists(Folder) then
    Folder := TPath.GetDocumentsPath;
  if SelectDirectory('Results Folder', String.Empty, Folder) and (Folder <> String.Empty) then
    LoadFolder(Folder);
  {$ENDIF}
end;

procedure TSprite3DResultsView.LoadFolder(const AFolder: String);
var
  Used, Skipped: Integer;
  Models: TArray<String>;
begin
  SetPlaying(False);
  FFolder := AFolder;
  FLoaded := True;
  FAnimations := ReadResultsFolder(AFolder, Used, Skipped, Models);
  // The folder, and the model the exports in it were made from, as the
  // metadata names it; how much was read is in the hint
  FFolderLabel.Text := AFolder;
  if Length(Models) > 0 then
    FFolderLabel.Text := FFolderLabel.Text + '  (' + String.Join(', ', Models) + ')';
  FFolderLabel.Hint := FFolderLabel.Text;
  FEdgeMatches := nil;
  FEdgeSides := nil;
  FEdgeAt := -1;
  FAnimationIndex := -1;
  FFrames.Clear;
  FImage.Bitmap.SetSize(0, 0);
  FSyncing := True;
  try
    FList.BeginUpdate;
    try
      FList.Clear;
      for var Animation in FAnimations do
        FList.Items.Add(Animation.Name);
    finally
      FList.EndUpdate;
    end;
  finally
    FSyncing := False;
  end;
  if Length(FAnimations) = 0 then
  begin
    if Skipped > 0 then
      ShowMessageText(Format('No animation metadata this can play was found in %s: ' +
        '%d .json files could not be used. Only metadata from this version of Sprite3D, ' +
        'beside its .png, is read.', [AFolder, Skipped]))
    else
      ShowMessageText('No animation metadata was found in ' + AFolder);
    UpdateControls;
    Exit;
  end;
  FFolderLabel.Hint := FFolderLabel.Hint + sLineBreak + Format('%d animations from %d ' +
    'metadata files', [Length(FAnimations), Used]);
  if Skipped > 0 then
    FFolderLabel.Hint := FFolderLabel.Hint + Format('; %d .json files not used', [Skipped]);
  ShowMessageText(String.Empty);
  // The first is the default
  FList.ItemIndex := 0;
  FindEdgeMatches;
  if FAnimationIndex <> 0 then
    SelectAnimation(0);
end;

procedure TSprite3DResultsView.ListChange(Sender: TObject);
begin
  if FSyncing or (FList.ItemIndex < 0) then
    Exit;
  SelectAnimation(FList.ItemIndex);
end;

// An animation chosen: its first direction, played from its first frame
procedure TSprite3DResultsView.SelectAnimation(const AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex > High(FAnimations)) then
    Exit;
  FAnimationIndex := AIndex;
  FDirectionIndex := 0;
  BuildFrames;
  UpdateZoomRange;
  StepTo(0);
  // The default is to play, at the rate it was saved at; a still has
  // nothing to play, so stays paused, its empty border showing
  SetPlaying(HasFrames and not StillShowing);
end;

// Another direction: the same frame of it, playing on if it was
procedure TSprite3DResultsView.SelectDirection(const AIndex: Integer);
var
  WasPlaying: Boolean;
  Frame: Integer;
begin
  if FAnimationIndex < 0 then
    Exit;
  WasPlaying := FPlaying;
  SetPlaying(False);
  FDirectionIndex := AIndex;
  Frame := FFrame;
  BuildFrames;
  StepTo(Frame);
  SetPlaying(WasPlaying and HasFrames);
end;

// The current direction's frames, each cut from its image at the sprite
// size; a frame no image holds is left transparent
procedure TSprite3DResultsView.BuildFrames;
var
  Animation: TResultsAnimation;
  Sources: TObjectDictionary<String, TBitmap>;
  Source, Frame: TBitmap;
  Problems: TArray<String>;
  X, Y: Integer;
begin
  FFrames.Clear;
  FImage.Bitmap.SetSize(0, 0);
  if FAnimationIndex < 0 then
    Exit;
  Animation := CurrentAnimation;
  if (FDirectionIndex < 0) or (FDirectionIndex > High(Animation.Directions)) then
    FDirectionIndex := 0;
  Problems := nil;
  // Each image once, however many frames it holds
  Sources := TObjectDictionary<String, TBitmap>.Create([doOwnsValues]);
  try
    for var Cell in Animation.Directions[FDirectionIndex].Frames do
    begin
      Frame := TBitmap.Create(Animation.SpriteWidth, Animation.SpriteHeight);
      FFrames.Add(Frame);
      Frame.Clear(TAlphaColors.Null);
      if Cell.FileName = String.Empty then
        Continue;
      if not Sources.TryGetValue(Cell.FileName, Source) then
      begin
        Source := nil;
        try
          Source := TBitmap.CreateFromFile(Cell.FileName);
        except
          on E: Exception do
            Problems := Problems + [ExtractFileName(Cell.FileName) + ': ' + E.Message];
        end;
        Sources.Add(Cell.FileName, Source);
      end;
      if Source = nil then
        Continue;
      X := (Cell.Cell mod Cell.Cols) * Animation.SpriteWidth;
      Y := (Cell.Cell div Cell.Cols) * Animation.SpriteHeight;
      if (X + Animation.SpriteWidth <= Source.Width) and
        (Y + Animation.SpriteHeight <= Source.Height) then
        Frame.CopyFromBitmap(Source, TRect.Create(X, Y, X + Animation.SpriteWidth,
          Y + Animation.SpriteHeight), 0, 0);
    end;
  finally
    Sources.Free;
  end;
  UpdateGridRange;
  DrawGrid;
  if Length(Problems) > 0 then
    ShowMessageText('Some frames could not be read:' + sLineBreak +
      String.Join(sLineBreak, Problems))
  else
    ShowMessageText(String.Empty);
  ApplyZoom;
end;

procedure TSprite3DResultsView.ShowFrame(const AFrame: Integer);
begin
  if not HasFrames then
    Exit;
  FFrame := EnsureRange(AFrame, 0, FFrames.Count - 1);
  FImage.Bitmap := FFrames[FFrame];
  FFrameLabel.Text := Format('%d / %d', [FFrame + 1, FFrames.Count]);
  // Every frame, playing or not, so it never shows a match that has gone
  UpdateEdgeLabel;
end;

// Shows AFrame, wrapping round, held there; playing carries on from it
procedure TSprite3DResultsView.StepTo(const AFrame: Integer);
begin
  if not HasFrames then
  begin
    FFrameLabel.Text := '- / -';
    Exit;
  end;
  ShowFrame(((AFrame mod FFrames.Count) + FFrames.Count) mod FFrames.Count);
  if FPlaying then
  begin
    FStartFrame := FFrame;
    FClock := TStopwatch.StartNew;
  end;
  UpdateControls;
end;

procedure TSprite3DResultsView.SetPlaying(const APlaying: Boolean);
begin
  FPlaying := APlaying and HasFrames and not StillShowing;
  if FPlaying then
  begin
    FStartFrame := FFrame;
    FClock := TStopwatch.StartNew;
  end;
  FTimer.Enabled := FPlaying and FActive;
  UpdateControls;
end;

// The frame due now: as many frames on from where play started as the time
// since allows, at the animation's own rate, round and round
procedure TSprite3DResultsView.TimerTimer(Sender: TObject);
var
  Seconds: Double;
  Frame: Integer;
begin
  if not FPlaying or not HasFrames then
    Exit;
  Seconds := FrameSeconds;
  if Seconds <= 0 then
    Exit;
  Frame := (FStartFrame + Trunc(FClock.Elapsed.TotalSeconds / Seconds)) mod FFrames.Count;
  if Frame <> FFrame then
    ShowFrame(Frame);
end;

procedure TSprite3DResultsView.FirstButtonClick(Sender: TObject);
begin
  SetPlaying(False);
  StepTo(0);
end;

procedure TSprite3DResultsView.PreviousButtonClick(Sender: TObject);
begin
  SetPlaying(False);
  StepTo(FFrame - 1);
end;

procedure TSprite3DResultsView.PlayButtonClick(Sender: TObject);
begin
  SetPlaying(not FPlaying);
end;

procedure TSprite3DResultsView.NextButtonClick(Sender: TObject);
begin
  SetPlaying(False);
  StepTo(FFrame + 1);
end;

procedure TSprite3DResultsView.LastButtonClick(Sender: TObject);
begin
  SetPlaying(False);
  StepTo(FFrames.Count - 1);
end;

procedure TSprite3DResultsView.DirPreviousButtonClick(Sender: TObject);
var
  Count: Integer;
begin
  if FAnimationIndex < 0 then
    Exit;
  Count := Length(CurrentAnimation.Directions);
  if Count > 1 then
    SelectDirection((FDirectionIndex + Count - 1) mod Count);
end;

procedure TSprite3DResultsView.DirNextButtonClick(Sender: TObject);
var
  Count: Integer;
begin
  if FAnimationIndex < 0 then
    Exit;
  Count := Length(CurrentAnimation.Directions);
  if Count > 1 then
    SelectDirection((FDirectionIndex + 1) mod Count);
end;

// Every edge case read, side by side, left, top, right then bottom; within a
// side, in the list's order, then each animation's directions in order, then
// frame order. An edge case is a frame whose empty border on a side equals
// its own image's sprite_empty on that side: the frames that come closest to
// that edge. Every image has at least one on each side. A frame can be an
// edge case on more than one side. A static model's stills are never edge
// cases: the finder is hidden while one is showing, so none could be shown
// as one.
procedure TSprite3DResultsView.FindEdgeMatches;
var
  Cell: TResultsCell;
  Ref: TResultsFrameRef;
begin
  FEdgeMatches := nil;
  FEdgeSides := nil;
  FEdgeAt := -1;
  for var Side := 0 to 3 do
  begin
    FEdgeSideStart[Side] := Length(FEdgeMatches);
    for var A := 0 to High(FAnimations) do
    begin
      if FAnimations[A].IsStill then
        Continue;
      for var D := 0 to High(FAnimations[A].Directions) do
        for var F := 0 to High(FAnimations[A].Directions[D].Frames) do
        begin
          Cell := FAnimations[A].Directions[D].Frames[F];
          if Cell.HasEmpty and (Cell.Empty[Side] = Cell.SpriteEmpty[Side]) then
          begin
            Ref.Animation := A;
            Ref.Direction := D;
            Ref.Frame := F;
            FEdgeMatches := FEdgeMatches + [Ref];
            FEdgeSides := FEdgeSides + [Side];
          end;
        end;
    end;
    FEdgeSideCount[Side] := Length(FEdgeMatches) - FEdgeSideStart[Side];
  end;
end;

// Whether ARef is the frame showing
function TSprite3DResultsView.IsShowing(const ARef: TResultsFrameRef): Boolean;
begin
  Result := (ARef.Animation = FAnimationIndex) and (ARef.Direction = FDirectionIndex) and
    (ARef.Frame = FFrame);
end;

// Where the frame showing is among the edge cases: the one last gone to, if
// it is still showing; otherwise the frame's own edge case on the side shown
// in the drop-down, if it is one. If it is neither, -(1 + the index of the
// first edge case on that side after it), so a search knows where to start
// from, which may be the start of the next side.
function TSprite3DResultsView.EdgeMatchIndex: Integer;
var
  Side, Last: Integer;
  Here, There: Int64;

  function Key(const AAnimation, ADirection, AFrame: Integer): Int64;
  begin
    // List order, then direction, then frame, as each side's run is
    Result := (Int64(AAnimation) shl 40) or (Int64(ADirection) shl 20) or AFrame;
  end;

begin
  if (FEdgeAt >= 0) and (FEdgeAt <= High(FEdgeMatches)) and
    IsShowing(FEdgeMatches[FEdgeAt]) then
    Exit(FEdgeAt);
  FEdgeAt := -1;
  Side := EnsureRange(FEdgeBox.ItemIndex, 0, 3);
  Last := FEdgeSideStart[Side] + FEdgeSideCount[Side] - 1;
  Here := Key(FAnimationIndex, FDirectionIndex, FFrame);
  for var I := FEdgeSideStart[Side] to Last do
  begin
    There := Key(FEdgeMatches[I].Animation, FEdgeMatches[I].Direction,
      FEdgeMatches[I].Frame);
    if There = Here then
      Exit(I);
    if There > Here then
      Exit(-(1 + I));
  end;
  Result := -(1 + Last + 1);
end;

// Shows a particular frame of a particular animation and direction, paused:
// the animation selected in the list, its direction's frames built if they
// are not showing already
procedure TSprite3DResultsView.JumpTo(const ARef: TResultsFrameRef);
begin
  if (ARef.Animation < 0) or (ARef.Animation > High(FAnimations)) then
    Exit;
  SetPlaying(False);
  if ARef.Animation <> FAnimationIndex then
  begin
    FSyncing := True;
    try
      FList.ItemIndex := ARef.Animation;
    finally
      FSyncing := False;
    end;
    FAnimationIndex := ARef.Animation;
    FDirectionIndex := ARef.Direction;
    BuildFrames;
    UpdateZoomRange;
  end
  else if ARef.Direction <> FDirectionIndex then
  begin
    FDirectionIndex := ARef.Direction;
    BuildFrames;
  end;
  StepTo(ARef.Frame);
  UpdateControls;
end;

// The previous or next edge case, AStep -1 or 1, round and round, over
// every side, animation and direction read, from the frame showing, which is
// shown paused, and the drop-down then shows its side; nothing happens if
// there is none
procedure TSprite3DResultsView.SeekEdge(const AStep: Integer);
var
  Count, At, Target: Integer;
begin
  Count := Length(FEdgeMatches);
  if Count = 0 then
  begin
    UpdateEdgeLabel;
    Exit;
  end;
  At := EdgeMatchIndex;
  if At >= 0 then
    // On a match: the one before or after it
    Target := At + AStep
  else if AStep > 0 then
    // Between matches: the first after the frame showing
    Target := -At - 1
  else
    // ... or the last before it
    Target := -At - 2;
  Target := ((Target mod Count) + Count) mod Count;
  ShowEdgeSide(FEdgeSides[Target]);
  JumpTo(FEdgeMatches[Target]);
  FEdgeAt := Target;
  UpdateEdgeLabel;
end;

// The drop-down set to ASide, without that counting as the user's choice
procedure TSprite3DResultsView.ShowEdgeSide(const ASide: Integer);
begin
  if FEdgeBox.ItemIndex = ASide then
    Exit;
  FSyncingEdgeBox := True;
  try
    FEdgeBox.ItemIndex := ASide;
  finally
    FSyncingEdgeBox := False;
  end;
end;

procedure TSprite3DResultsView.EdgePreviousButtonClick(Sender: TObject);
begin
  SeekEdge(-1);
end;

procedure TSprite3DResultsView.EdgeNextButtonClick(Sender: TObject);
begin
  SeekEdge(1);
end;

// A side chosen by hand: the edge cases are looked for from there, so Next
// goes to that side's first after the frame showing
procedure TSprite3DResultsView.EdgeBoxChange(Sender: TObject);
begin
  if FSyncingEdgeBox then
    Exit;
  FEdgeAt := -1;
  UpdateEdgeLabel;
end;

// The frame showing's empty border on each side, as "(left,top,right,bottom)",
// such as "(12,0,9,31)", while paused; nothing while playing, without a frame
// or without empty borders in the metadata. Its hint, unless ShowEdgeHint is
// False, says what they are.
procedure TSprite3DResultsView.UpdateEmptyLabel;
var
  Cell: TResultsCell;
begin
  if FEmptyLabel = nil then
    Exit;
  FEmptyLabel.Text := String.Empty;
  if HasFrames and (FAnimationIndex >= 0) and not FPlaying then
  begin
    Cell := CurrentAnimation.Directions[FDirectionIndex].Frames[FFrame];
    if Cell.HasEmpty then
      FEmptyLabel.Text := Format('(%d,%d,%d,%d)', [Cell.Empty[0], Cell.Empty[1],
        Cell.Empty[2], Cell.Empty[3]]);
  end;
  FEmptyLabel.ShowHint := FShowEdgeHint and (FEmptyLabel.Text <> String.Empty);
  if FEmptyLabel.ShowHint and StillShowing then
    FEmptyLabel.Hint := 'The still''s empty border, in pixels: (left, top, right, ' +
      'bottom), the columns or rows wholly transparent at that edge of the frame.'
  else if FEmptyLabel.ShowHint then
    FEmptyLabel.Hint := 'The frame''s empty border, in pixels: (left, top, right, ' +
      'bottom), the columns or rows wholly transparent at that edge of the frame. A value ' +
      'equal to the image''s sprite_empty on that side makes the frame an edge case.'
  else
    FEmptyLabel.Hint := String.Empty;
end;

procedure TSprite3DResultsView.SetShowEdgeHint(const Value: Boolean);
begin
  FShowEdgeHint := Value;
  UpdateEmptyLabel;
end;

// Which of the edge cases the frame showing is, of all of them and of its
// side's, as "12 of 40 (3 of 9 top)"; "Edge Case Finder" on any other frame.
// The values, and how many edge cases there are, are in the hint either way.
procedure TSprite3DResultsView.UpdateEdgeLabel;
var
  Side, At: Integer;
  Cell: TResultsCell;
  Text: String;
begin
  // The values beside Show grid follow the frame showing too
  UpdateEmptyLabel;
  if FEdgeLabel = nil then
    Exit;
  if not HasFrames or (FAnimationIndex < 0) then
  begin
    FEdgeLabel.Text := EDGE_FINDER;
    FEdgeLabel.Hint := String.Empty;
    Exit;
  end;
  if Length(FEdgeMatches) = 0 then
  begin
    FEdgeLabel.Text := EDGE_FINDER;
    FEdgeLabel.Hint := 'The metadata read gives no empty borders';
    Exit;
  end;
  Cell := CurrentAnimation.Directions[FDirectionIndex].Frames[FFrame];
  At := EdgeMatchIndex;
  if At >= 0 then
    Side := FEdgeSides[At]
  else
    Side := EnsureRange(FEdgeBox.ItemIndex, 0, 3);
  if At >= 0 then
    // Which edge case of all, and which of its side's
    FEdgeLabel.Text := Format('%d of %d (%d of %d %s)', [At + 1, Length(FEdgeMatches),
      At - FEdgeSideStart[Side] + 1, FEdgeSideCount[Side], SIDE_NAMES[Side]])
  else
    FEdgeLabel.Text := EDGE_FINDER;
  // The values, in the hint
  if Cell.HasEmpty then
    Text := Format('sprite_empty %s is %d; this frame''s empty %s is %d', [SIDE_NAMES[Side],
      Cell.SpriteEmpty[Side], SIDE_NAMES[Side], Cell.Empty[Side]])
  else
    Text := 'This frame has no empty border in the metadata';
  if At >= 0 then
    Text := Text + Format(': edge case %d of %d, %d of %d on the %s', [At + 1,
      Length(FEdgeMatches), At - FEdgeSideStart[Side] + 1, FEdgeSideCount[Side],
      SIDE_NAMES[Side]])
  else
    Text := Text + Format(': not an edge case on the %s; %d in all', [SIDE_NAMES[Side],
      Length(FEdgeMatches)]);
  FEdgeLabel.Hint := Text;
end;

// Zoom can never be more than fits the drawing area; the slider's top is
// that, and a value past it comes down to it
procedure TSprite3DResultsView.UpdateZoomRange;
var
  Fit: Single;
  Animation: TResultsAnimation;
begin
  if FAnimationIndex < 0 then
    Exit;
  Animation := CurrentAnimation;
  // The border takes a pixel each side
  Fit := Min((FDrawingLayout.Width - 2) / Max(1, Animation.SpriteWidth),
    (FDrawingLayout.Height - 2) / Max(1, Animation.SpriteHeight));
  if Fit <= 0 then
    Exit;   // not laid out yet
  // The zoom chosen, as far as the space allows: a smaller space shows it
  // smaller, and a larger one brings it back up to what was chosen
  FSyncing := True;
  try
    FZoomTrack.Min := Min(ZOOM_MIN, Fit);
    FZoomTrack.Max := Fit;
    FZoomTrack.Value := EnsureRange(FZoomWanted, FZoomTrack.Min, Fit);
  finally
    FSyncing := False;
  end;
  ApplyZoom;
end;

// The animation's size: the sprite size times the zoom
procedure TSprite3DResultsView.ApplyZoom;
var
  Zoom: Single;
begin
  if FAnimationIndex < 0 then
    Exit;
  Zoom := Min(FZoomTrack.Value, FZoomTrack.Max);
  FAnimationLayout.Width := Max(1, Round(CurrentAnimation.SpriteWidth * Zoom));
  FAnimationLayout.Height := Max(1, Round(CurrentAnimation.SpriteHeight * Zoom));
  FBorder.Width := FAnimationLayout.Width + 2;
  FBorder.Height := FAnimationLayout.Height + 2;
  FBorder.Visible := HasFrames;
  // The checker is stretched with the frame, so it needs no redrawing here
  FGridImage.Visible := HasFrames and FGridCheck.IsChecked;
  FZoomLabel.Text := Format('Zoom %.2fx', [Zoom]);
end;

// Grid Size's top: GRID_MAX, but never more than half the sprite's smaller
// side; the size chosen comes down to it if need be
procedure TSprite3DResultsView.UpdateGridRange;
var
  Top: Integer;
begin
  if FAnimationIndex < 0 then
    Exit;
  Top := Max(GRID_MIN, Min(GRID_MAX, Min(CurrentAnimation.SpriteWidth,
    CurrentAnimation.SpriteHeight) div 2));
  FSyncing := True;
  try
    FGridTrack.Max := Top;
    FGridSize := EnsureRange(FGridSize, GRID_MIN, Top);
    FGridTrack.Value := FGridSize;
  finally
    FSyncing := False;
  end;
  FGridLabel.Text := Format('Grid %dpx', [FGridSize]);
end;

// The checker, at the sprite's own size: squares of FGridSize sprite pixels,
// light at the top left. FGridImage stretches it as FImage stretches the
// frame, without smoothing, so at any zoom each square covers exactly
// FGridSize of the frame's pixels. Drawn only when the sprite size or the
// grid size has changed, not for every frame.
procedure TSprite3DResultsView.DrawGrid;
var
  W, H: Integer;
  Grid: TBitmap;
  Data: TBitmapData;
begin
  if FAnimationIndex < 0 then
    Exit;
  W := CurrentAnimation.SpriteWidth;
  H := CurrentAnimation.SpriteHeight;
  if (W < 1) or (H < 1) then
    Exit;
  if (FGridDrawnFor.X = W) and (FGridDrawnFor.Y = H) and (FGridDrawnSize = FGridSize) then
    Exit;
  Grid := TBitmap.Create(W, H);
  try
    if Grid.Map(TMapAccess.Write, Data) then
      try
        for var Y := 0 to H - 1 do
          for var X := 0 to W - 1 do
            if ((X div FGridSize) + (Y div FGridSize)) mod 2 = 0 then
              Data.SetPixel(X, Y, GRID_LIGHT)
            else
              Data.SetPixel(X, Y, GRID_DARK);
      finally
        Grid.Unmap(Data);
      end;
    // Assign copies it: the image keeps its own
    FGridImage.Bitmap.Assign(Grid);
  finally
    Grid.Free;
  end;
  FGridDrawnFor := TPoint.Create(W, H);
  FGridDrawnSize := FGridSize;
end;

procedure TSprite3DResultsView.GridTrackChange(Sender: TObject);
begin
  if FSyncing then
    Exit;
  FGridSize := EnsureRange(Round(FGridTrack.Value), GRID_MIN, Max(GRID_MIN,
    Round(FGridTrack.Max)));
  FGridLabel.Text := Format('Grid %dpx', [FGridSize]);
  DrawGrid;
end;

// Show grid ticked or cleared by hand: the checker shown or hidden, Grid
// Size usable only while it is shown, and the owner told so it can keep it
procedure TSprite3DResultsView.GridCheckChange(Sender: TObject);
begin
  FGridImage.Visible := HasFrames and FGridCheck.IsChecked;
  UpdateControls;
  if not FSyncing and Assigned(FOnShowGridChange) then
    FOnShowGridChange(Self);
end;

function TSprite3DResultsView.GetShowGrid: Boolean;
begin
  Result := FGridCheck.IsChecked;
end;

procedure TSprite3DResultsView.SetShowGrid(const Value: Boolean);
begin
  FSyncing := True;
  try
    FGridCheck.IsChecked := Value;
  finally
    FSyncing := False;
  end;
  FGridImage.Visible := HasFrames and Value;
  UpdateControls;
end;

// Zoom takes the left half of the row, Grid Size the right
procedure TSprite3DResultsView.ZoomLayoutResized(Sender: TObject);
begin
  FZoomHalf.Width := Max(0, (FZoomLayout.Width - FZoomLayout.Padding.Left -
    FZoomLayout.Padding.Right) / 2 - FZoomHalf.Margins.Right);
end;

// Zoom moved by hand: that is the zoom chosen from now on, and the owner is
// told so it can keep it
procedure TSprite3DResultsView.ZoomTrackChange(Sender: TObject);
begin
  if FSyncing then
    Exit;
  FZoomWanted := FZoomTrack.Value;
  ApplyZoom;
  if Assigned(FOnZoomChange) then
    FOnZoomChange(Self);
end;

procedure TSprite3DResultsView.SetZoom(const Value: Single);
begin
  if Value > 0 then
    FZoomWanted := Value
  else
    FZoomWanted := 1;
  UpdateZoomRange;
end;

procedure TSprite3DResultsView.DrawingLayoutResized(Sender: TObject);
begin
  UpdateZoomRange;
end;

procedure TSprite3DResultsView.UpdateControls;
var
  Usable, Still: Boolean;
  Animation: TResultsAnimation;
  Bearing: String;
begin
  Usable := HasFrames;
  // A still has nothing to play: no player, frame readout or rate
  Still := StillShowing;
  FFirstButton.Visible := not Still;
  FPreviousButton.Visible := not Still;
  FPlayButton.Visible := not Still;
  FNextButton.Visible := not Still;
  FLastButton.Visible := not Still;
  FFrameLabel.Visible := not Still;
  FRateLabel.Visible := not Still;
  // Nor an edge case finder: its controls are hidden, its row kept, so the
  // list keeps its height
  FEdgeBox.Visible := not Still;
  FEdgePreviousButton.Visible := not Still;
  FEdgeNextButton.Visible := not Still;
  FEdgeLabel.Visible := not Still;
  FFirstButton.Enabled := Usable;
  FPreviousButton.Enabled := Usable;
  FPlayButton.Enabled := Usable;
  FNextButton.Enabled := Usable;
  FLastButton.Enabled := Usable;
  FZoomTrack.Enabled := Usable;
  FGridTrack.Enabled := Usable and FGridCheck.IsChecked and (FGridTrack.Max > FGridTrack.Min);
  FGridCheck.Enabled := Usable;
  FEdgeBox.Enabled := Usable;
  FEdgePreviousButton.Enabled := Usable;
  FEdgeNextButton.Enabled := Usable;
  UpdateEdgeLabel;
  if FPlaying then
  begin
    FMX.Objects.TPath(FPlayButton.TagObject).Data.Data := ICON_PAUSE;
    FPlayButton.Hint := 'Pause';
  end
  else
  begin
    FMX.Objects.TPath(FPlayButton.TagObject).Data.Data := ICON_PLAY;
    FPlayButton.Hint := 'Play';
  end;
  if FAnimationIndex < 0 then
  begin
    FFrameLabel.Text := '- / -';
    FDirLabel.Text := String.Empty;
    FRateLabel.Text := String.Empty;
    FDirPreviousButton.Enabled := False;
    FDirNextButton.Enabled := False;
    FZoomLabel.Text := 'Zoom';
    Exit;
  end;
  Animation := CurrentAnimation;
  FDirPreviousButton.Enabled := Length(Animation.Directions) > 1;
  FDirNextButton.Enabled := Length(Animation.Directions) > 1;
  Bearing := FormatFloat('0.##', Animation.Directions[FDirectionIndex].Bearing,
    TFormatSettings.Invariant);
  FDirLabel.Text := Format('Direction %d of %d (%s)', [FDirectionIndex + 1,
    Length(Animation.Directions), Bearing + #176]);
  if Animation.Time > 0 then
    FRateLabel.Text := Format('%d frames in %.3f s, %.2f fps', [Animation.FrameCount,
      Animation.Time, Animation.FrameCount / Animation.Time])
  else
    FRateLabel.Text := Format('%d frames, no time given', [Animation.FrameCount]);
end;

procedure TSprite3DResultsView.SetActive(const AActive: Boolean);
begin
  FActive := AActive;
  if FActive and not FLoaded then
  begin
    // The first look, or the folder was written to meanwhile
    if FFolder <> String.Empty then
      LoadFolder(FFolder)
    else if Assigned(FOnDefaultFolder) and (FOnDefaultFolder() <> String.Empty) and
      TDirectory.Exists(FOnDefaultFolder()) then
      LoadFolder(FOnDefaultFolder());
  end;
  FTimer.Enabled := FPlaying and FActive;
  if FActive and FPlaying then
  begin
    // Carry on from the frame showing
    FStartFrame := FFrame;
    FClock := TStopwatch.StartNew;
  end;
  if FActive then
    UpdateZoomRange;
end;

procedure TSprite3DResultsView.FolderChanged(const AFolder: String);
begin
  if (FFolder = String.Empty) or not SameFileName(ExcludeTrailingPathDelimiter(AFolder),
    ExcludeTrailingPathDelimiter(FFolder)) then
    Exit;
  FLoaded := False;
  if FActive then
    LoadFolder(FFolder);
end;

end.
