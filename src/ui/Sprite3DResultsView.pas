//** @abstract(The Results tab: plays back the animations exported to a folder, from their
//** metadata and images alone.)
//**
//** TSprite3DResultsView builds its controls inside a parent, normally the main form's
//** Results tab. Select Folder, at the bottom, picks a folder, opening at the last place
//** exports went. Every .json in it is read with ReadResultsFolder; only what the metadata
//** says is used, and only files whose @code(animations) are objects, as Sprite3D now
//** writes, each beside the .png it describes. The animations found are listed on the right,
//** the first selected. The selected animation's frames for the current direction, the first
//** to begin with, are cut from the .png files, each @code(sprite_size), and played in the
//** middle of the drawing area at the animation's own rate, its @code(frame_count) frames
//** over its @code(time) seconds. Under it are the player buttons, as on the View tab, a pair
//** to step through the directions, and a Zoom slider that never lets the animation grow
//** larger than the space it has. AniGif and MP4 exports are not read yet.
{
  The Results tab: plays back the animations exported to a folder, from
  their metadata and images alone.

  TSprite3DResultsView builds its controls inside a parent, normally the
  main form's Results tab. Select Folder, at the bottom, picks a folder,
  opening at the last place exports went. Every .json in it is read with
  ReadResultsFolder; only what the metadata says is used, and only files
  whose animations are objects, as Sprite3D now writes, each beside the .png
  it describes. The animations found are listed on the right, the first
  selected. The selected animation's frames for the current direction, the
  first to begin with, are cut from the .png files, each sprite_size, and
  played in the middle of the drawing area at the animation's own rate, its
  frame_count frames over its time seconds. Under it are the player buttons,
  as on the View tab, a pair to step through the directions, and a Zoom
  slider that never lets the animation grow larger than the space it has.
  AniGif and MP4 exports are not read yet.

  The layout:

  parent
  |-- FolderLayout (bottom)       Select Folder and the folder read
  |-- ListLayout (right)          the animations found
  `-- ViewerLayout (client)
      |-- AnimationControlsLayout (bottom)
      |   |-- the player buttons, the frame readout, the directions
      |   `-- Zoom
      `-- DrawingLayout (client)
          `-- AnimationLayout (centred)   the frame showing, sprite_size x zoom
}
unit Sprite3DResultsView;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Diagnostics,
  System.Generics.Collections, FMX.Types, FMX.Controls, FMX.Graphics, FMX.Objects,
  FMX.Layouts, FMX.StdCtrls, FMX.ListBox;

type
  //** @abstract(Where one frame is: which image, and which cell of its grid.)
  /// <summary>Where one frame is: which image, and which cell of its grid.</summary>
  TResultsCell = record
    //** @abstract(The .png holding it; empty if no file has this frame.)
    /// <summary>The .png holding it; empty if no file has this frame.</summary>
    FileName: String;
    //** @abstract(Its cell, counted from 0 left to right and then down.)
    /// <summary>Its cell, counted from 0 left to right and then down.</summary>
    Cell: Integer;
    //** @abstract(How many cells the image's grid has across.)
    /// <summary>How many cells the image's grid has across.</summary>
    Cols: Integer;
  end;

  //** @abstract(One direction of an animation: its bearing and where each frame is.)
  /// <summary>One direction of an animation: its bearing and where each frame
  /// is.</summary>
  TResultsDirection = record
    //** @abstract(The direction's compass bearing in degrees, as the metadata gives it.)
    /// <summary>The direction's compass bearing in degrees, as the metadata gives
    /// it.</summary>
    Bearing: Double;
    //** @abstract(Each frame, in order, frame_count of them.)
    /// <summary>Each frame, in order, frame_count of them.</summary>
    Frames: TArray<TResultsCell>;
  end;

  //** @abstract(An animation found in a folder's metadata.)
  /// <summary>An animation found in a folder's metadata.</summary>
  TResultsAnimation = record
    //** @abstract(Its name, as the metadata gives it.)
    /// <summary>Its name, as the metadata gives it.</summary>
    Name: String;
    //** @abstract(How many frames each direction has.)
    /// <summary>How many frames each direction has.</summary>
    FrameCount: Integer;
    //** @abstract(How long it takes to play once, in seconds.)
    /// <summary>How long it takes to play once, in seconds.</summary>
    Time: Double;
    //** @abstract(One frame's width in pixels, image.sprite_size.)
    /// <summary>One frame's width in pixels, image.sprite_size.</summary>
    SpriteWidth: Integer;
    //** @abstract(One frame's height in pixels, image.sprite_size.)
    /// <summary>One frame's height in pixels, image.sprite_size.</summary>
    SpriteHeight: Integer;
    //** @abstract(Its directions, in the order they were first found.)
    /// <summary>Its directions, in the order they were first found.</summary>
    Directions: TArray<TResultsDirection>;
  end;

//** @abstract(The animations described by the metadata files in a folder.)
//**
//** Every .json in AFolder, in name order, is read. One is used only if it is Sprite3D
//** metadata whose @code(animations) are objects with @code(name), @code(frame_count) and
//** @code(time), and the .png of the same name is beside it. Each animation is listed once,
//** in the order first found, with each of its directions, by bearing, in the order first
//** found; where two files hold the same frame, the first one read is used. A file whose
//** @code(sprite_size) differs from that already found for one of its animations adds nothing
//** to that animation.
//**
//** @param(AFolder The folder to read.)
//**
//** @param(AUsed Set to how many metadata files were used.)
//**
//** @param(ASkipped Set to how many .json files could not be used.)
/// <summary>The animations described by the metadata files in a folder.</summary>
/// <remarks>Every .json in AFolder, in name order, is read. One is used only if it is
/// Sprite3D metadata whose <c>animations</c> are objects with <c>name</c>,
/// <c>frame_count</c> and <c>time</c>, and the .png of the same name is beside it. Each
/// animation is listed once, in the order first found, with each of its directions, by
/// bearing, in the order first found; where two files hold the same frame, the first one
/// read is used. A file whose <c>sprite_size</c> differs from that already found for one of
/// its animations adds nothing to that animation.</remarks>
/// <param name="AFolder">The folder to read.</param>
/// <param name="AUsed">Set to how many metadata files were used.</param>
/// <param name="ASkipped">Set to how many .json files could not be used.</param>
function ReadResultsFolder(const AFolder: String; out AUsed, ASkipped: Integer):
  TArray<TResultsAnimation>;

type
  //** @abstract(The Results tab's controls and player; see the unit description.)
  /// <summary>The Results tab's controls and player; see the unit description.</summary>
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
    procedure UpdateControls;
    procedure ShowMessageText(const AText: String);
    function HasFrames: Boolean;
    function CurrentAnimation: TResultsAnimation;
    function FrameSeconds: Double;
  public
    //** @abstract(Builds the controls in AParent, empty until a folder is read.)
    /// <summary>Builds the controls in AParent, empty until a folder is read.</summary>
    constructor Create(AOwner: TComponent; const AParent: TFmxObject); reintroduce;
    //** @abstract(Frees the frames.)
    /// <summary>Frees the frames.</summary>
    destructor Destroy; override;
    //** @abstract(Reads AFolder's metadata, lists its animations and selects the first.)
    /// <summary>Reads AFolder's metadata, lists its animations and selects the
    /// first.</summary>
    procedure LoadFolder(const AFolder: String);
    //** @abstract(Whether the tab is showing: playing only runs while it is. The first time,
    //** the folder OnDefaultFolder gives is read.)
    /// <summary>Whether the tab is showing: playing only runs while it is. The first time,
    /// the folder OnDefaultFolder gives is read.</summary>
    procedure SetActive(const AActive: Boolean);
    //** @abstract(An export has written to AFolder: if it is the folder read, it is read
    //** again, now if the tab is showing, otherwise when it next shows.)
    /// <summary>An export has written to AFolder: if it is the folder read, it is read
    /// again, now if the tab is showing, otherwise when it next shows.</summary>
    procedure FolderChanged(const AFolder: String);
    //** @abstract(Gives the folder Select Folder opens at, and that is read when the tab
    //** first shows: where exports last went.)
    /// <summary>Gives the folder Select Folder opens at, and that is read when the tab first
    /// shows: where exports last went.</summary>
    property OnDefaultFolder: TFunc<String> read FOnDefaultFolder write FOnDefaultFolder;
    //** @abstract(The folder read, or empty.)
    /// <summary>The folder read, or empty.</summary>
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

// Adds what one metadata file says to AAnimations; False if it is not
// metadata this can use
function ReadMetadataFile(const AFileName: String;
  var AAnimations: TArray<TResultsAnimation>): Boolean;
var
  Value: TJSONValue;
  Root, Image, Item: TJSONObject;
  List, Frames: TJSONArray;
  Png, Name: String;
  SpriteWidth, SpriteHeight, Cols, Count, AnimationIndex, DirectionIndex, Frame: Integer;
  Time: Double;
  Bearings: TArray<Double>;
  // For each of this file's animations, its index in AAnimations, or -1 if
  // this file's frames of it are not used
  Targets: TArray<Integer>;
  Animation: TResultsAnimation;
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
      AnimationIndex := FindAnimation(AAnimations, Name);
      if AnimationIndex < 0 then
      begin
        Animation.Name := Name;
        Animation.FrameCount := Count;
        Animation.Time := Time;
        Animation.SpriteWidth := SpriteWidth;
        Animation.SpriteHeight := SpriteHeight;
        Animation.Directions := nil;
        AAnimations := AAnimations + [Animation];
        AnimationIndex := High(AAnimations);
      end
      else if (AAnimations[AnimationIndex].SpriteWidth <> SpriteWidth) or
        (AAnimations[AnimationIndex].SpriteHeight <> SpriteHeight) or
        (AAnimations[AnimationIndex].FrameCount <> Count) then
        // Another export of it, at another size or length: not mixed in
        AnimationIndex := -1;
      Targets := Targets + [AnimationIndex];
    end;
    // Where each frame is: cell I of this image
    for var I := 0 to Frames.Count - 1 do
    begin
      if not (Frames.Items[I] is TJSONObject) then
        Continue;
      Item := TJSONObject(Frames.Items[I]);
      if not Item.TryGetValue<Integer>('animation', AnimationIndex) or
        not Item.TryGetValue<Integer>('direction', DirectionIndex) or
        not Item.TryGetValue<Integer>('frame', Frame) then
        Continue;
      if (AnimationIndex < 0) or (AnimationIndex > High(Targets)) or
        (DirectionIndex < 0) or (DirectionIndex > High(Bearings)) then
        Continue;
      AnimationIndex := Targets[AnimationIndex];
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
      end;
    end;
    Result := True;
  finally
    Value.Free;
  end;
end;

function ReadResultsFolder(const AFolder: String; out AUsed, ASkipped: Integer):
  TArray<TResultsAnimation>;
var
  Files: TArray<String>;
begin
  Result := nil;
  AUsed := 0;
  ASkipped := 0;
  if (AFolder = String.Empty) or not TDirectory.Exists(AFolder) then
    Exit;
  Files := TDirectory.GetFiles(AFolder, '*.json');
  TArray.Sort<String>(Files, TComparer<String>.Construct(
    function(const A, B: String): Integer
    begin
      Result := CompareText(A, B);
    end));
  for var FileName in Files do
    if ReadMetadataFile(FileName, Result) then
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
  FDirectionIndex := 0;
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
  // Bottom: Select Folder and the folder read
  FFolderLayout := TLayout.Create(Self);
  FFolderLayout.Parent := FParent;
  FFolderLayout.Align := TAlignLayout.Bottom;
  FFolderLayout.Height := 36;
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
  FFolderLabel := TLabel.Create(Self);
  FFolderLabel.Parent := FFolderLayout;
  FFolderLabel.Align := TAlignLayout.Client;
  FFolderLabel.Margins.Left := 8;
  FFolderLabel.TextSettings.WordWrap := False;
  FFolderLabel.Text := String.Empty;

  // Right: the animations found
  FListLayout := TLayout.Create(Self);
  FListLayout.Parent := FParent;
  FListLayout.Align := TAlignLayout.Right;
  FListLayout.Width := 220;
  FListLayout.Padding.Rect := TRectF.Create(4, 4, 4, 0);
  FList := TListBox.Create(Self);
  FList.Parent := FListLayout;
  FList.Align := TAlignLayout.Client;
  FList.OnChange := ListChange;

  // The rest: the drawing area, and the controls under it
  FViewerLayout := TLayout.Create(Self);
  FViewerLayout.Parent := FParent;
  FViewerLayout.Align := TAlignLayout.Client;

  FAnimationControlsLayout := TLayout.Create(Self);
  FAnimationControlsLayout.Parent := FViewerLayout;
  FAnimationControlsLayout.Align := TAlignLayout.Bottom;
  FAnimationControlsLayout.Height := 68;

  // First row: the player, the frame readout, the directions
  FTransportLayout := TLayout.Create(Self);
  FTransportLayout.Parent := FAnimationControlsLayout;
  FTransportLayout.Align := TAlignLayout.Top;
  FTransportLayout.Height := 36;
  FTransportLayout.Padding.Rect := TRectF.Create(4, 4, 4, 2);
  FFirstButton := AddIconButton(FTransportLayout, ICON_FIRST, 'First frame',
    FirstButtonClick);
  FPreviousButton := AddIconButton(FTransportLayout, ICON_PREVIOUS, 'Previous frame',
    PreviousButtonClick);
  FPlayButton := AddIconButton(FTransportLayout, ICON_PLAY, 'Play', PlayButtonClick);
  FNextButton := AddIconButton(FTransportLayout, ICON_NEXT, 'Next frame',
    NextButtonClick);
  FLastButton := AddIconButton(FTransportLayout, ICON_LAST, 'Last frame',
    LastButtonClick);
  FFrameLabel := AddLabel(FTransportLayout, TAlignLayout.Left, 70);
  FFrameLabel.Margins.Left := 6;
  FFrameLabel.Hint := 'The frame showing';
  FDirPreviousButton := AddTextButton(FTransportLayout, '<', 'Previous direction',
    DirPreviousButtonClick);
  FDirPreviousButton.Margins.Left := 8;
  FDirNextButton := AddTextButton(FTransportLayout, '>', 'Next direction',
    DirNextButtonClick);
  FDirLabel := AddLabel(FTransportLayout, TAlignLayout.Left, 170);
  FDirLabel.Margins.Left := 6;
  FRateLabel := AddLabel(FTransportLayout, TAlignLayout.Client, 0);
  FRateLabel.Margins.Left := 6;

  // Second row: Zoom
  FZoomLayout := TLayout.Create(Self);
  FZoomLayout.Parent := FAnimationControlsLayout;
  FZoomLayout.Align := TAlignLayout.Client;
  FZoomLayout.Padding.Rect := TRectF.Create(4, 2, 8, 4);
  FZoomLabel := AddLabel(FZoomLayout, TAlignLayout.Left, 90);
  FZoomTrack := TTrackBar.Create(Self);
  FZoomTrack.Parent := FZoomLayout;
  FZoomTrack.Align := TAlignLayout.Client;
  FZoomTrack.Min := ZOOM_MIN;
  FZoomTrack.Max := 1;
  FZoomTrack.Frequency := 0;
  FZoomTrack.Value := 1;
  FZoomTrack.Hint := 'Magnify the animation, as far as the space for it allows';
  FZoomTrack.ShowHint := True;
  FZoomTrack.OnChange := ZoomTrackChange;

  // The drawing area, the animation centred in it
  FDrawingLayout := TLayout.Create(Self);
  FDrawingLayout.Parent := FViewerLayout;
  FDrawingLayout.Align := TAlignLayout.Client;
  FDrawingLayout.ClipChildren := True;
  FDrawingLayout.OnResized := DrawingLayoutResized;
  FAnimationLayout := TLayout.Create(Self);
  FAnimationLayout.Parent := FDrawingLayout;
  FAnimationLayout.Align := TAlignLayout.Center;
  FAnimationLayout.Width := 1;
  FAnimationLayout.Height := 1;
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
begin
  SetPlaying(False);
  FFolder := AFolder;
  FLoaded := True;
  FAnimations := ReadResultsFolder(AFolder, Used, Skipped);
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
    FFolderLabel.Text := AFolder;
    if Skipped > 0 then
      ShowMessageText(Format('No animation metadata this can play was found in %s: ' +
        '%d .json files could not be used. Only metadata from this version of Sprite3D, ' +
        'beside its .png, is read.', [AFolder, Skipped]))
    else
      ShowMessageText('No animation metadata was found in ' + AFolder);
    UpdateControls;
    Exit;
  end;
  FFolderLabel.Text := Format('%s: %d animations from %d metadata files',
    [AFolder, Length(FAnimations), Used]);
  if Skipped > 0 then
    FFolderLabel.Text := FFolderLabel.Text + Format(' (%d not used)', [Skipped]);
  ShowMessageText(String.Empty);
  // The first is the default
  FList.ItemIndex := 0;
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
  // The default is to play, at the rate it was saved at
  SetPlaying(HasFrames);
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
  FPlaying := APlaying and HasFrames;
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
  Fit := Min(FDrawingLayout.Width / Max(1, Animation.SpriteWidth),
    FDrawingLayout.Height / Max(1, Animation.SpriteHeight));
  if Fit <= 0 then
    Exit;   // not laid out yet
  FSyncing := True;
  try
    FZoomTrack.Min := Min(ZOOM_MIN, Fit);
    FZoomTrack.Max := Fit;
    if FZoomTrack.Value > Fit then
      FZoomTrack.Value := Fit;
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
  FZoomLabel.Text := Format('Zoom %.2fx', [Zoom]);
end;

procedure TSprite3DResultsView.ZoomTrackChange(Sender: TObject);
begin
  if not FSyncing then
    ApplyZoom;
end;

procedure TSprite3DResultsView.DrawingLayoutResized(Sender: TObject);
begin
  UpdateZoomRange;
end;

procedure TSprite3DResultsView.UpdateControls;
var
  Usable: Boolean;
  Animation: TResultsAnimation;
  Bearing: String;
begin
  Usable := HasFrames;
  FFirstButton.Enabled := Usable;
  FPreviousButton.Enabled := Usable;
  FPlayButton.Enabled := Usable;
  FNextButton.Enabled := Usable;
  FLastButton.Enabled := Usable;
  FZoomTrack.Enabled := Usable;
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
