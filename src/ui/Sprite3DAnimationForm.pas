//** @abstract(The Model, Animation Settings dialog: the frame rate animations are saved at,
//** overscan, and texture atlas pages.)
//**
//** One slider, marked FPS, sets the frames per second that the animation list's Save as
//** sprite strip, Save as Spritesheet and Save as AniGif, and batch Export, use, from
//** ANIMATION_FPS_MIN to ANIMATION_FPS_MAX. The number beside it shows the value as the
//** slider moves.
//**
//** Below it, the Overscan tick box turns overscan on for grabs and exports: each image is
//** drawn that many times larger each way and scaled back down with the filter chosen under
//** Resampling. The slider beside it sets the factor, from OVERSCAN_FACTOR_MIN to the
//** smaller of OVERSCAN_FACTOR_MAX and MaxOverscan, which the caller sets to what the
//** off-screen renderer can do; where that is below OVERSCAN_FACTOR_MIN, as where grabs are
//** screenshots, the tick box is disabled and a note says why. The slider and the drop-down
//** are only enabled while the box is ticked.
//**
//** Under Texture Atlas, Page size chooses the largest a texture atlas page may be each way,
//** one of ATLAS_PAGE_SIZES, shown as 1k to 16k, and the tick box below lets pages be any
//** size rather than powers of 2 each way.
//**
//** OK accepts the values and Cancel leaves the old ones; keeping them, and applying them,
//** is the caller's job.
//**
//** On the desktop, show it with ShowModal and read Fps afterwards; on Android and iOS, which
//** cannot block, show it with ShowAndFree, which calls OnAccept on OK, OnCancel otherwise,
//** and frees the form when it closes. For the main thread only.
unit Sprite3DAnimationForm;

{
  The Model, Animation Settings dialog: the frame rate animations are saved
  at, overscan, and texture atlas pages.

  One slider, marked FPS, sets the frames per second that the animation
  list's Save as sprite strip, Save as Spritesheet and Save as AniGif, and
  batch Export, use, from ANIMATION_FPS_MIN to ANIMATION_FPS_MAX. The number
  beside it shows the value as the slider moves.

  Below it, the Overscan tick box turns overscan on for grabs and exports:
  each image is drawn that many times larger each way and scaled back down
  with the filter chosen under Resampling. The slider beside it sets the
  factor, from OVERSCAN_FACTOR_MIN to the smaller of OVERSCAN_FACTOR_MAX and
  MaxOverscan, which the caller sets to what the off-screen renderer can do;
  where that is below OVERSCAN_FACTOR_MIN, as where grabs are screenshots,
  the tick box is disabled and a note says why. The slider and the drop-down
  are only enabled while the box is ticked.

  Under Texture Atlas, Page size chooses the largest a texture atlas page
  may be each way, one of ATLAS_PAGE_SIZES, shown as 1k to 16k, and the tick
  box below lets pages be any size rather than powers of 2 each way.

  OK accepts the values and Cancel leaves the old ones; keeping them, and
  applying them, is the caller's job.

  On the desktop, show it with ShowModal and read Fps afterwards; on Android
  and iOS, which cannot block, show it with ShowAndFree, which calls OnAccept
  on OK, OnCancel otherwise, and frees the form when it closes. For the main
  thread only.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Layouts, FMX.ListBox, Sprite3DResample;

type
  //** @abstract(The Model, Animation Settings dialog; see the unit description.)
  /// <summary>The Model, Animation Settings dialog; see the unit description.</summary>
  TAnimationSettingsForm = class(TForm)
    //** @abstract(Holds the FPS row and the explanation.)
    /// <summary>Holds the FPS row and the explanation.</summary>
    MainLayout: TLayout;
    //** @abstract(The row with FpsLabel, FpsTrack and FpsValueLabel.)
    /// <summary>The row with FpsLabel, FpsTrack and FpsValueLabel.</summary>
    FpsLayout: TLayout;
    //** @abstract(The caption "FPS".)
    /// <summary>The caption "FPS".</summary>
    FpsLabel: TLabel;
    //** @abstract(The frame rate, in whole frames per second.)
    /// <summary>The frame rate, in whole frames per second.</summary>
    FpsTrack: TTrackBar;
    //** @abstract(The slider's value as a number.)
    /// <summary>The slider's value as a number.</summary>
    FpsValueLabel: TLabel;
    //** @abstract(A line explaining what the rate is used for.)
    /// <summary>A line explaining what the rate is used for.</summary>
    NoteLabel: TLabel;
    //** @abstract(The row with OverscanCheck, OverscanTrack and OverscanValueLabel.)
    /// <summary>The row with OverscanCheck, OverscanTrack and OverscanValueLabel.</summary>
    OverscanLayout: TLayout;
    //** @abstract(Turns overscan on for grabs and exports.)
    /// <summary>Turns overscan on for grabs and exports.</summary>
    OverscanCheck: TCheckBox;
    //** @abstract(The overscan factor, in whole steps.)
    /// <summary>The overscan factor, in whole steps.</summary>
    OverscanTrack: TTrackBar;
    //** @abstract(The overscan factor as a number, such as @code(4x).)
    /// <summary>The overscan factor as a number, such as <c>4x</c>.</summary>
    OverscanValueLabel: TLabel;
    //** @abstract(The row with FilterLabel and FilterCombo.)
    /// <summary>The row with FilterLabel and FilterCombo.</summary>
    FilterLayout: TLayout;
    //** @abstract(The caption "Resampling".)
    /// <summary>The caption "Resampling".</summary>
    FilterLabel: TLabel;
    //** @abstract(The filter overscanned images are scaled down with, one entry per
    //** TSprite3DResampleFilter in its order.)
    /// <summary>The filter overscanned images are scaled down with, one entry per
    /// TSprite3DResampleFilter in its order.</summary>
    FilterCombo: TComboBox;
    //** @abstract(Says how far overscan can go at the grab size, or why it cannot be used.)
    /// <summary>Says how far overscan can go at the grab size, or why it cannot be
    /// used.</summary>
    OverscanNoteLabel: TLabel;
    //** @abstract(The heading "Texture Atlas".)
    /// <summary>The heading "Texture Atlas".</summary>
    AtlasHeaderLabel: TLabel;
    //** @abstract(The row with AtlasSizeLabel and AtlasSizeCombo.)
    /// <summary>The row with AtlasSizeLabel and AtlasSizeCombo.</summary>
    AtlasSizeLayout: TLayout;
    //** @abstract(The caption "Page size".)
    /// <summary>The caption "Page size".</summary>
    AtlasSizeLabel: TLabel;
    //** @abstract(The largest an atlas page may be each way, one entry per ATLAS_PAGE_SIZES in
    //** its order.)
    /// <summary>The largest an atlas page may be each way, one entry per ATLAS_PAGE_SIZES in
    /// its order.</summary>
    AtlasSizeCombo: TComboBox;
    //** @abstract(Lets atlas pages be any size, rather than powers of 2 each way.)
    /// <summary>Lets atlas pages be any size, rather than powers of 2 each way.</summary>
    AtlasNonPowerOf2Check: TCheckBox;
    //** @abstract(A line explaining what the page size is for.)
    /// <summary>A line explaining what the page size is for.</summary>
    AtlasNoteLabel: TLabel;
    //** @abstract(The strip holding the Cancel and OK buttons.)
    /// <summary>The strip holding the Cancel and OK buttons.</summary>
    ButtonLayout: TLayout;
    //** @abstract(Closes the dialog with mrOk.)
    /// <summary>Closes the dialog with mrOk.</summary>
    OkButton: TButton;
    //** @abstract(Closes the dialog with mrCancel.)
    /// <summary>Closes the dialog with mrCancel.</summary>
    CancelButton: TButton;
    //** @abstract(Sets the slider's range and shows the starting value.)
    //**
    //** @param(Sender The form.)
    /// <summary>Sets the slider's range and shows the starting value.</summary>
    /// <param name="Sender">The form.</param>
    procedure FormCreate(Sender: TObject);
    //** @abstract(Shows the slider's value beside it.)
    //**
    //** @param(Sender FpsTrack.)
    /// <summary>Shows the slider's value beside it.</summary>
    /// <param name="Sender">FpsTrack.</param>
    procedure FpsTrackChange(Sender: TObject);
    //** @abstract(Shows the overscan factor beside the slider.)
    //**
    //** @param(Sender OverscanTrack.)
    /// <summary>Shows the overscan factor beside the slider.</summary>
    /// <param name="Sender">OverscanTrack.</param>
    procedure OverscanTrackChange(Sender: TObject);
    //** @abstract(Enables the overscan slider and the filter drop-down while the box is
    //** ticked.)
    //**
    //** @param(Sender OverscanCheck.)
    /// <summary>Enables the overscan slider and the filter drop-down while the box is
    /// ticked.</summary>
    /// <param name="Sender">OverscanCheck.</param>
    procedure OverscanCheckChange(Sender: TObject);
    //** @abstract(Closes the dialog with the button's ModalResult.)
    //**
    //** @param(Sender OkButton or CancelButton.)
    /// <summary>Closes the dialog with the button's ModalResult.</summary>
    /// <param name="Sender">OkButton or CancelButton.</param>
    procedure ButtonClick(Sender: TObject);
    //** @abstract(Reports OK or Cancel when shown with ShowAndFree, and frees the form then.)
    //**
    //** @param(Sender The form.)
    //**
    //** @param(Action Set to caFree when shown with ShowAndFree.)
    /// <summary>Reports OK or Cancel when shown with ShowAndFree, and frees the form
    /// then.</summary>
    /// <param name="Sender">The form.</param>
    /// <param name="Action">Set to caFree when shown with ShowAndFree.</param>
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    FOnAccept: TNotifyEvent;
    FOnCancel: TNotifyEvent;
    FFreeOnClose: Boolean;
    FMaxOverscan: Integer;
    function GetFps: Integer;
    procedure SetFps(const Value: Integer);
    function GetOverscanEnabled: Boolean;
    procedure SetOverscanEnabled(const Value: Boolean);
    function GetOverscan: Integer;
    procedure SetOverscan(const Value: Integer);
    procedure SetMaxOverscan(const Value: Integer);
    function GetFilter: TSprite3DResampleFilter;
    procedure SetFilter(const Value: TSprite3DResampleFilter);
    procedure UpdateOverscanControls;
    function GetAtlasPageSize: Integer;
    procedure SetAtlasPageSize(const Value: Integer);
    function GetAtlasNonPowerOf2: Boolean;
    procedure SetAtlasNonPowerOf2(const Value: Boolean);
  public
    //** @abstract(Shows the dialog without blocking and frees it when it closes.)
    //**
    //** For Android and iOS, where ShowModal cannot block. OnAccept is called if it closes
    //** with OK, OnCancel otherwise.
    /// <summary>Shows the dialog without blocking and frees it when it closes.</summary>
    /// <remarks>For Android and iOS, where ShowModal cannot block. OnAccept is called if it
    /// closes with OK, OnCancel otherwise.</remarks>
    procedure ShowAndFree;
    //** @abstract(The frame rate shown, in frames per second.)
    //**
    //** Set it before showing the dialog; read it after OK. Values are limited to
    //** ANIMATION_FPS_MIN to ANIMATION_FPS_MAX.
    /// <summary>The frame rate shown, in frames per second.</summary>
    /// <remarks>Set it before showing the dialog; read it after OK. Values are limited to
    /// ANIMATION_FPS_MIN to ANIMATION_FPS_MAX.</remarks>
    property Fps: Integer read GetFps write SetFps;
    //** @abstract(The largest overscan factor allowed; OVERSCAN_FACTOR_MAX until set.)
    //**
    //** Set it before Overscan, to what the off-screen renderer can do, such as
    //** @code(TSprite3DOffscreen.MaxOverscan). The slider stops there. Below
    //** OVERSCAN_FACTOR_MIN, overscan cannot be used: the tick box is cleared and disabled,
    //** and the note says so. Values above OVERSCAN_FACTOR_MAX count as OVERSCAN_FACTOR_MAX.
    /// <summary>The largest overscan factor allowed; OVERSCAN_FACTOR_MAX until set.</summary>
    /// <remarks>Set it before Overscan, to what the off-screen renderer can do, such as
    /// <c>TSprite3DOffscreen.MaxOverscan</c>. The slider stops there. Below
    /// OVERSCAN_FACTOR_MIN, overscan cannot be used: the tick box is cleared and disabled, and
    /// the note says so. Values above OVERSCAN_FACTOR_MAX count as
    /// OVERSCAN_FACTOR_MAX.</remarks>
    property MaxOverscan: Integer read FMaxOverscan write SetMaxOverscan;
    //** @abstract(Whether the Overscan box is ticked.)
    //**
    //** Setting it True has no effect while MaxOverscan is below OVERSCAN_FACTOR_MIN.
    /// <summary>Whether the Overscan box is ticked.</summary>
    /// <remarks>Setting it True has no effect while MaxOverscan is below
    /// OVERSCAN_FACTOR_MIN.</remarks>
    property OverscanEnabled: Boolean read GetOverscanEnabled write SetOverscanEnabled;
    //** @abstract(The overscan factor shown; limited to OVERSCAN_FACTOR_MIN to MaxOverscan.)
    //**
    //** It keeps its value while the box is not ticked, so it can be kept as a setting.
    /// <summary>The overscan factor shown; limited to OVERSCAN_FACTOR_MIN to
    /// MaxOverscan.</summary>
    /// <remarks>It keeps its value while the box is not ticked, so it can be kept as a
    /// setting.</remarks>
    property Overscan: Integer read GetOverscan write SetOverscan;
    //** @abstract(The resampling filter chosen.)
    /// <summary>The resampling filter chosen.</summary>
    property Filter: TSprite3DResampleFilter read GetFilter write SetFilter;
    //** @abstract(The largest a texture atlas page may be each way, in pixels; one of
    //** ATLAS_PAGE_SIZES.)
    //**
    //** A value that is not one of them shows as the nearest that is.
    /// <summary>The largest a texture atlas page may be each way, in pixels; one of
    /// ATLAS_PAGE_SIZES.</summary>
    /// <remarks>A value that is not one of them shows as the nearest that is.</remarks>
    property AtlasPageSize: Integer read GetAtlasPageSize write SetAtlasPageSize;
    //** @abstract(Whether texture atlas pages may be any size, rather than powers of 2.)
    /// <summary>Whether texture atlas pages may be any size, rather than powers of
    /// 2.</summary>
    property AtlasNonPowerOf2: Boolean read GetAtlasNonPowerOf2 write SetAtlasNonPowerOf2;
    //** @abstract(Called on OK when shown with ShowAndFree.)
    /// <summary>Called on OK when shown with ShowAndFree.</summary>
    property OnAccept: TNotifyEvent read FOnAccept write FOnAccept;
    //** @abstract(Called on Cancel, or any close but OK, when shown with ShowAndFree.)
    /// <summary>Called on Cancel, or any close but OK, when shown with ShowAndFree.</summary>
    property OnCancel: TNotifyEvent read FOnCancel write FOnCancel;
  end;

implementation

uses
  System.Math, Sprite3DHelpers;

{$R *.fmx}

procedure TAnimationSettingsForm.FormCreate(Sender: TObject);
var
  F: TSprite3DResampleFilter;
begin
  FpsTrack.Min := ANIMATION_FPS_MIN;
  FpsTrack.Max := ANIMATION_FPS_MAX;
  FpsTrack.Frequency := 1;
  FpsTrack.Value := ANIMATION_FPS_DEFAULT;
  FpsTrackChange(FpsTrack);

  // The filters, in TSprite3DResampleFilter's order: the item index is the
  // filter
  FilterCombo.Items.Clear;
  for F := Low(TSprite3DResampleFilter) to High(TSprite3DResampleFilter) do
    FilterCombo.Items.Add(ResampleFilterName(F));
  FilterCombo.ItemIndex := Ord(rfBox);

  OverscanTrack.Frequency := 1;
  OverscanTrack.Min := OVERSCAN_FACTOR_MIN;
  OverscanTrack.Value := OVERSCAN_FACTOR_DEFAULT;
  OverscanCheck.IsChecked := False;
  SetMaxOverscan(OVERSCAN_FACTOR_MAX);

  // The page sizes, in ATLAS_PAGE_SIZES' order: 1k, 2k and so on
  AtlasSizeCombo.Items.Clear;
  for var Size in ATLAS_PAGE_SIZES do
    AtlasSizeCombo.Items.Add(Format('%dk (%d x %d)', [Size div 1024, Size, Size]));
  SetAtlasPageSize(ATLAS_PAGE_SIZE_DEFAULT);
  AtlasNonPowerOf2Check.IsChecked := False;
end;

function TAnimationSettingsForm.GetAtlasPageSize: Integer;
begin
  if (AtlasSizeCombo.ItemIndex >= Low(ATLAS_PAGE_SIZES)) and
    (AtlasSizeCombo.ItemIndex <= High(ATLAS_PAGE_SIZES)) then
    Result := ATLAS_PAGE_SIZES[AtlasSizeCombo.ItemIndex]
  else
    Result := ATLAS_PAGE_SIZE_DEFAULT;
end;

procedure TAnimationSettingsForm.SetAtlasPageSize(const Value: Integer);
var
  Best: Integer;
begin
  Best := Low(ATLAS_PAGE_SIZES);
  for var I := Low(ATLAS_PAGE_SIZES) to High(ATLAS_PAGE_SIZES) do
    if Abs(ATLAS_PAGE_SIZES[I] - Value) < Abs(ATLAS_PAGE_SIZES[Best] - Value) then
      Best := I;
  AtlasSizeCombo.ItemIndex := Best;
end;

function TAnimationSettingsForm.GetAtlasNonPowerOf2: Boolean;
begin
  Result := AtlasNonPowerOf2Check.IsChecked;
end;

procedure TAnimationSettingsForm.SetAtlasNonPowerOf2(const Value: Boolean);
begin
  AtlasNonPowerOf2Check.IsChecked := Value;
end;

procedure TAnimationSettingsForm.OverscanTrackChange(Sender: TObject);
begin
  OverscanValueLabel.Text := IntToStr(GetOverscan) + 'x';
end;

procedure TAnimationSettingsForm.OverscanCheckChange(Sender: TObject);
begin
  UpdateOverscanControls;
end;

// The slider and drop-down only while overscan is ticked; the tick box only
// where overscan is possible at all
procedure TAnimationSettingsForm.UpdateOverscanControls;
var
  Possible: Boolean;
begin
  Possible := FMaxOverscan >= OVERSCAN_FACTOR_MIN;
  if not Possible then
    OverscanCheck.IsChecked := False;
  OverscanCheck.Enabled := Possible;
  OverscanTrack.Enabled := Possible and OverscanCheck.IsChecked;
  FilterCombo.Enabled := Possible and OverscanCheck.IsChecked;
  if Possible then
    OverscanNoteLabel.Text := Format('Grabs and exports are drawn up to %dx larger each ' +
      'way and scaled down with the filter. Beyond what the GPU can draw at once, ' +
      'several slightly shifted drawings are combined, which takes longer.',
      [FMaxOverscan])
  else
    OverscanNoteLabel.Text := 'Overscan is not available here, as grabs are screenshots ' +
      'of the view.';
  OverscanTrackChange(OverscanTrack);
end;

function TAnimationSettingsForm.GetOverscanEnabled: Boolean;
begin
  Result := OverscanCheck.IsChecked and (FMaxOverscan >= OVERSCAN_FACTOR_MIN);
end;

procedure TAnimationSettingsForm.SetOverscanEnabled(const Value: Boolean);
begin
  OverscanCheck.IsChecked := Value and (FMaxOverscan >= OVERSCAN_FACTOR_MIN);
  UpdateOverscanControls;
end;

function TAnimationSettingsForm.GetOverscan: Integer;
begin
  Result := EnsureRange(Round(OverscanTrack.Value), OVERSCAN_FACTOR_MIN,
    Max(OVERSCAN_FACTOR_MIN, FMaxOverscan));
end;

procedure TAnimationSettingsForm.SetOverscan(const Value: Integer);
begin
  OverscanTrack.Value := EnsureRange(Value, OVERSCAN_FACTOR_MIN,
    Max(OVERSCAN_FACTOR_MIN, FMaxOverscan));
  OverscanTrackChange(OverscanTrack);
end;

procedure TAnimationSettingsForm.SetMaxOverscan(const Value: Integer);
begin
  FMaxOverscan := Min(Value, OVERSCAN_FACTOR_MAX);
  // A slider needs a range; with no overscan possible it is disabled anyway
  OverscanTrack.Max := Max(OVERSCAN_FACTOR_MIN + 1, FMaxOverscan);
  if OverscanTrack.Value > OverscanTrack.Max then
    OverscanTrack.Value := OverscanTrack.Max;
  UpdateOverscanControls;
end;

function TAnimationSettingsForm.GetFilter: TSprite3DResampleFilter;
begin
  if (FilterCombo.ItemIndex >= Ord(Low(TSprite3DResampleFilter))) and
    (FilterCombo.ItemIndex <= Ord(High(TSprite3DResampleFilter))) then
    Result := TSprite3DResampleFilter(FilterCombo.ItemIndex)
  else
    Result := rfBox;
end;

procedure TAnimationSettingsForm.SetFilter(const Value: TSprite3DResampleFilter);
begin
  FilterCombo.ItemIndex := Ord(Value);
end;

procedure TAnimationSettingsForm.FpsTrackChange(Sender: TObject);
begin
  FpsValueLabel.Text := IntToStr(GetFps);
end;

function TAnimationSettingsForm.GetFps: Integer;
begin
  Result := EnsureRange(Round(FpsTrack.Value), ANIMATION_FPS_MIN, ANIMATION_FPS_MAX);
end;

procedure TAnimationSettingsForm.SetFps(const Value: Integer);
begin
  FpsTrack.Value := EnsureRange(Value, ANIMATION_FPS_MIN, ANIMATION_FPS_MAX);
  FpsTrackChange(FpsTrack);
end;

procedure TAnimationSettingsForm.ButtonClick(Sender: TObject);
begin
  if not FFreeOnClose then
    Exit;   // ShowModal closes the dialog itself, from the button's ModalResult
  ModalResult := TButton(Sender).ModalResult;
  Close;
end;

procedure TAnimationSettingsForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if not FFreeOnClose then
    Exit;
  if ModalResult = mrOk then
  begin
    if Assigned(FOnAccept) then
      FOnAccept(Self);
  end
  else if Assigned(FOnCancel) then
    FOnCancel(Self);
  Action := TCloseAction.caFree;
end;

procedure TAnimationSettingsForm.ShowAndFree;
begin
  FFreeOnClose := True;
  Show;
end;

end.
