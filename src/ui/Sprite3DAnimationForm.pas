//** @abstract(The Models, Animation Settings dialog: the frame rate animations are saved at,
//** overscan, padding, and texture atlas pages.)
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
//** are only enabled while the box is ticked. Ticking the box by hand first shows a modal
//** warning of how much longer rendering takes, unless OverscanWarning is False: OK keeps
//** the tick, Cancel takes it back, and Do not show this again, between them, stops it
//** appearing again.
//**
//** Padding sets the empty border, in pixels, every export aims to leave round the sprite on
//** the axis with least room, from 0 to MaxPadding, a quarter of the grab size.
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
  The Models, Animation Settings dialog: the frame rate animations are saved
  at, overscan, padding, and texture atlas pages.

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
  are only enabled while the box is ticked. Ticking the box by hand first
  shows a modal warning of how much longer rendering takes, unless
  OverscanWarning is False: OK keeps the tick, Cancel takes it back, and Do
  not show this again, between them, stops it appearing again.

  Padding sets the empty border, in pixels, every export aims to leave round
  the sprite on the axis with least room, from 0 to MaxPadding, a quarter of
  the grab size.

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
  //** @abstract(The Models, Animation Settings dialog; see the unit description.)
  TAnimationSettingsForm = class(TForm)
    //** @abstract(Holds the FPS row and the explanation.)
    MainLayout: TLayout;
    //** @abstract(The row with FpsLabel, FpsTrack and FpsValueLabel.)
    FpsLayout: TLayout;
    //** @abstract(The caption "FPS".)
    FpsLabel: TLabel;
    //** @abstract(The frame rate, in whole frames per second.)
    FpsTrack: TTrackBar;
    //** @abstract(The slider's value as a number.)
    FpsValueLabel: TLabel;
    //** @abstract(A line explaining what the rate is used for.)
    NoteLabel: TLabel;
    //** @abstract(The row with OverscanCheck, OverscanTrack and OverscanValueLabel.)
    OverscanLayout: TLayout;
    //** @abstract(Turns overscan on for grabs and exports.)
    OverscanCheck: TCheckBox;
    //** @abstract(The overscan factor, in whole steps.)
    OverscanTrack: TTrackBar;
    //** @abstract(The overscan factor as a number, such as @code(4x).)
    OverscanValueLabel: TLabel;
    //** @abstract(The row with FilterLabel and FilterCombo.)
    FilterLayout: TLayout;
    //** @abstract(The caption "Resampling".)
    FilterLabel: TLabel;
    //** @abstract(The filter overscanned images are scaled down with, one entry per
    //** TSprite3DResampleFilter in its order.)
    FilterCombo: TComboBox;
    //** @abstract(Says how far overscan can go at the grab size, or why it cannot be used.)
    OverscanNoteLabel: TLabel;
    //** @abstract(The row with PaddingLabel, PaddingTrack and PaddingValueLabel.)
    PaddingLayout: TLayout;
    //** @abstract(The caption "Padding".)
    PaddingLabel: TLabel;
    //** @abstract(The padding, in whole pixels, from 0 to MaxPadding.)
    PaddingTrack: TTrackBar;
    //** @abstract(The padding as a number of pixels, such as @code(2px).)
    PaddingValueLabel: TLabel;
    //** @abstract(A line explaining what padding is.)
    PaddingNoteLabel: TLabel;
    //** @abstract(The heading "Texture Atlas".)
    AtlasHeaderLabel: TLabel;
    //** @abstract(The row with AtlasSizeLabel and AtlasSizeCombo.)
    AtlasSizeLayout: TLayout;
    //** @abstract(The caption "Page size".)
    AtlasSizeLabel: TLabel;
    //** @abstract(The largest an atlas page may be each way, one entry per ATLAS_PAGE_SIZES in
    //** its order.)
    AtlasSizeCombo: TComboBox;
    //** @abstract(Lets atlas pages be any size, rather than powers of 2 each way.)
    AtlasNonPowerOf2Check: TCheckBox;
    //** @abstract(A line explaining what the page size is for.)
    AtlasNoteLabel: TLabel;
    //** @abstract(The strip holding the Cancel and OK buttons.)
    ButtonLayout: TLayout;
    //** @abstract(Closes the dialog with mrOk.)
    OkButton: TButton;
    //** @abstract(Closes the dialog with mrCancel.)
    CancelButton: TButton;
    //** @abstract(Sets the slider's range and shows the starting value.)
    //**
    //** @param(Sender The form.)
    procedure FormCreate(Sender: TObject);
    //** @abstract(Shows the slider's value beside it.)
    //**
    //** @param(Sender FpsTrack.)
    procedure FpsTrackChange(Sender: TObject);
    //** @abstract(Shows the overscan factor beside the slider.)
    //**
    //** @param(Sender OverscanTrack.)
    procedure OverscanTrackChange(Sender: TObject);
    //** @abstract(Enables the overscan slider and the filter drop-down while the box is
    //** ticked.)
    //**
    //** @param(Sender OverscanCheck.)
    procedure OverscanCheckChange(Sender: TObject);
    //** @abstract(Shows the padding beside the slider.)
    //**
    //** @param(Sender PaddingTrack.)
    procedure PaddingTrackChange(Sender: TObject);
    //** @abstract(Closes the dialog with the button's ModalResult.)
    //**
    //** @param(Sender OkButton or CancelButton.)
    procedure ButtonClick(Sender: TObject);
    //** @abstract(Reports OK or Cancel when shown with ShowAndFree, and frees the form then.)
    //**
    //** @param(Sender The form.)
    //**
    //** @param(Action Set to caFree when shown with ShowAndFree.)
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    FOnAccept: TNotifyEvent;
    FOnCancel: TNotifyEvent;
    FFreeOnClose: Boolean;
    FMaxOverscan: Integer;
    FMaxPadding: Integer;
    FGrabWidth: Integer;
    FGrabHeight: Integer;
    FOverscanWarning: Boolean;
    FOnOverscanWarningChange: TNotifyEvent;
    // True while the code, not the user, changes the Overscan tick
    FSettingOverscan: Boolean;
    procedure SetOverscanCheck(const AChecked: Boolean);
    procedure ConfirmOverscan;
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
    function GetSpritePadding: Integer;
    procedure SetSpritePadding(const Value: Integer);
    procedure SetMaxPadding(const Value: Integer);
  public
    //** @abstract(Shows the dialog without blocking and frees it when it closes.)
    //**
    //** For Android and iOS, where ShowModal cannot block. OnAccept is called if it closes
    //** with OK, OnCancel otherwise.
    procedure ShowAndFree;
    //** @abstract(The frame rate shown, in frames per second.)
    //**
    //** Set it before showing the dialog; read it after OK. Values are limited to
    //** ANIMATION_FPS_MIN to ANIMATION_FPS_MAX.
    property Fps: Integer read GetFps write SetFps;
    //** @abstract(The largest overscan factor allowed; OVERSCAN_FACTOR_MAX until set.)
    //**
    //** Set it before Overscan, to what the off-screen renderer can do, such as
    //** @code(TSprite3DOffscreen.MaxOverscan). The slider stops there. Below
    //** OVERSCAN_FACTOR_MIN, overscan cannot be used: the tick box is cleared and disabled,
    //** and the note says so. Values above OVERSCAN_FACTOR_MAX count as OVERSCAN_FACTOR_MAX.
    property MaxOverscan: Integer read FMaxOverscan write SetMaxOverscan;
    //** @abstract(Whether the Overscan box is ticked.)
    //**
    //** Setting it True has no effect while MaxOverscan is below OVERSCAN_FACTOR_MIN.
    property OverscanEnabled: Boolean read GetOverscanEnabled write SetOverscanEnabled;
    //** @abstract(The width of a grab, in pixels, for the overscan warning; 256 until set.)
    property GrabWidth: Integer read FGrabWidth write FGrabWidth;
    //** @abstract(The height of a grab, in pixels, for the overscan warning; 256 until set.)
    property GrabHeight: Integer read FGrabHeight write FGrabHeight;
    //** @abstract(Whether ticking Overscan first shows the warning; True until set.)
    //**
    //** Ticking Overscan by hand while this is True opens a modal warning that each frame is
    //** drawn GrabWidth x GrabHeight times the factor and resampled back down, which takes
    //** far longer. OK keeps the tick and Cancel takes it back. Ticking Do not show this
    //** again in it sets this False, whether OK or Cancel is pressed, and calls
    //** OnOverscanWarningChange. Setting OverscanEnabled never shows it.
    property OverscanWarning: Boolean read FOverscanWarning write FOverscanWarning;
    //** @abstract(Called on the main thread when Do not show this again changes
    //** OverscanWarning, so the caller can keep it at once.)
    property OnOverscanWarningChange: TNotifyEvent read FOnOverscanWarningChange
      write FOnOverscanWarningChange;
    //** @abstract(The overscan factor shown; limited to OVERSCAN_FACTOR_MIN to MaxOverscan.)
    //**
    //** It keeps its value while the box is not ticked, so it can be kept as a setting.
    property Overscan: Integer read GetOverscan write SetOverscan;
    //** @abstract(The resampling filter chosen.)
    property Filter: TSprite3DResampleFilter read GetFilter write SetFilter;
    //** @abstract(The largest a texture atlas page may be each way, in pixels; one of
    //** ATLAS_PAGE_SIZES.)
    //**
    //** A value that is not one of them shows as the nearest that is.
    property AtlasPageSize: Integer read GetAtlasPageSize write SetAtlasPageSize;
    //** @abstract(Whether texture atlas pages may be any size, rather than powers of 2.)
    property AtlasNonPowerOf2: Boolean read GetAtlasNonPowerOf2 write SetAtlasNonPowerOf2;
    //** @abstract(The most padding the slider allows, in pixels; a quarter of the default
    //** grab size until set.)
    //**
    //** Set it before SpritePadding, to PaddingLimit of the grab size. Values below 0 count as
    //** 0.
    property MaxPadding: Integer read FMaxPadding write SetMaxPadding;
    //** @abstract(Padding: the empty border, in pixels, exports aim to leave round the sprite
    //** on the axis with least room; limited to 0 to MaxPadding.)
    //**
    //** Not called Padding, which is the form's own.
    property SpritePadding: Integer read GetSpritePadding write SetSpritePadding;
    //** @abstract(Called on OK when shown with ShowAndFree.)
    property OnAccept: TNotifyEvent read FOnAccept write FOnAccept;
    //** @abstract(Called on Cancel, or any close but OK, when shown with ShowAndFree.)
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

  FGrabWidth := GRAB_SIZE_DEFAULT;
  FGrabHeight := GRAB_SIZE_DEFAULT;
  FOverscanWarning := True;
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

  PaddingTrack.Frequency := 1;
  PaddingTrack.Min := 0;
  SetMaxPadding(PaddingLimit(GRAB_SIZE_DEFAULT, GRAB_SIZE_DEFAULT));
  PaddingTrack.Value := 0;
  PaddingTrackChange(PaddingTrack);
end;

procedure TAnimationSettingsForm.PaddingTrackChange(Sender: TObject);
begin
  PaddingValueLabel.Text := IntToStr(GetSpritePadding) + 'px';
end;

function TAnimationSettingsForm.GetSpritePadding: Integer;
begin
  Result := EnsureRange(Round(PaddingTrack.Value), 0, FMaxPadding);
end;

procedure TAnimationSettingsForm.SetSpritePadding(const Value: Integer);
begin
  PaddingTrack.Value := EnsureRange(Value, 0, FMaxPadding);
  PaddingTrackChange(PaddingTrack);
end;

// A slider whose Min and Max are equal cannot be drawn, so with no room for
// padding it still runs to 1, and is disabled at 0
procedure TAnimationSettingsForm.SetMaxPadding(const Value: Integer);
begin
  FMaxPadding := Max(0, Value);
  PaddingTrack.Max := Max(1, FMaxPadding);
  PaddingTrack.Enabled := FMaxPadding > 0;
  if PaddingTrack.Value > FMaxPadding then
    PaddingTrack.Value := FMaxPadding;
  PaddingTrackChange(PaddingTrack);
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

// Ticked by hand: the warning first, if it is still wanted, the tick taken
// back until it is answered
procedure TAnimationSettingsForm.OverscanCheckChange(Sender: TObject);
begin
  if not FSettingOverscan and OverscanCheck.IsChecked and FOverscanWarning then
  begin
    SetOverscanCheck(False);
    ConfirmOverscan;
    Exit;
  end;
  UpdateOverscanControls;
end;

// Ticks or clears Overscan without the warning
procedure TAnimationSettingsForm.SetOverscanCheck(const AChecked: Boolean);
begin
  FSettingOverscan := True;
  try
    OverscanCheck.IsChecked := AChecked;
  finally
    FSettingOverscan := False;
  end;
  UpdateOverscanControls;
end;

// The overscan warning, a modal sub-dialog made here: OK, on the right,
// ticks Overscan, Cancel, on the left, leaves it clear; Do not show this
// again, between them, stops it
// appearing again either way. ShowModal with a result procedure works on
// every platform: on the desktop it blocks, on Android and iOS it returns at
// once and the procedure runs when the dialog closes.
procedure TAnimationSettingsForm.ConfirmOverscan;
var
  Warning: TForm;
  Text: TLabel;
  Buttons: TLayout;
  OkButton, CancelButton: TButton;
  NeverCheck: TCheckBox;
  Factor: Integer;
begin
  Factor := GetOverscan;
  // Owned, and so freed, by this dialog, over which it is centred
  Warning := TForm.CreateNew(Self);
  Warning.Caption := 'Overscan';
  Warning.BorderStyle := TFmxFormBorderStyle.Single;
  Warning.BorderIcons := [TBorderIcon.biSystemMenu];
  Warning.Position := TFormPosition.OwnerFormCenter;
  Warning.ClientWidth := 460;
  Warning.ClientHeight := 210;

  Buttons := TLayout.Create(Warning);
  Buttons.Parent := Warning;
  Buttons.Align := TAlignLayout.Bottom;
  Buttons.Height := 44;
  Buttons.Padding.Rect := TRectF.Create(16, 8, 16, 10);
  OkButton := TButton.Create(Warning);
  OkButton.Parent := Buttons;
  OkButton.Align := TAlignLayout.Right;
  OkButton.Width := 80;
  OkButton.Text := 'OK';
  OkButton.ModalResult := mrOk;
  OkButton.Default := True;
  CancelButton := TButton.Create(Warning);
  CancelButton.Parent := Buttons;
  CancelButton.Align := TAlignLayout.Left;
  CancelButton.Width := 80;
  CancelButton.Text := 'Cancel';
  CancelButton.ModalResult := mrCancel;
  CancelButton.Cancel := True;
  // Between Cancel, on the left, and OK, on the right, as in the other
  // dialogs
  NeverCheck := TCheckBox.Create(Warning);
  NeverCheck.Parent := Buttons;
  NeverCheck.Align := TAlignLayout.Center;
  NeverCheck.Width := 170;
  NeverCheck.Height := 19;
  NeverCheck.Text := 'Do not show this again';

  Text := TLabel.Create(Warning);
  Text.Parent := Warning;
  Text.Align := TAlignLayout.Client;
  Text.Margins.Rect := TRectF.Create(16, 16, 16, 4);
  Text.TextSettings.WordWrap := True;
  Text.TextSettings.VertAlign := TTextAlign.Leading;
  Text.Text := Format('Using this option will drastically increase render time, as each ' +
    'frame needs to be rendered at a resolution of %d x %d, %d times the grab size each ' +
    'way at the current factor of %dx, then resampled back down to %d x %d, which is a ' +
    'highly CPU intensive operation.', [FGrabWidth * Factor, FGrabHeight * Factor, Factor,
    Factor, FGrabWidth, FGrabHeight]) + sLineBreak + sLineBreak +
    'It is recommended that you only use this option when you are ready to create the ' +
    'final production-ready frames.';

  Warning.ShowModal(
    procedure(AResult: TModalResult)
    begin
      if NeverCheck.IsChecked and FOverscanWarning then
      begin
        FOverscanWarning := False;
        if Assigned(FOnOverscanWarningChange) then
          FOnOverscanWarningChange(Self);
      end;
      if AResult = mrOk then
        SetOverscanCheck(True);
    end);
end;

// The slider and drop-down only while overscan is ticked; the tick box only
// where overscan is possible at all
procedure TAnimationSettingsForm.UpdateOverscanControls;
var
  Possible: Boolean;
begin
  Possible := FMaxOverscan >= OVERSCAN_FACTOR_MIN;
  if not Possible and OverscanCheck.IsChecked then
  begin
    FSettingOverscan := True;
    try
      OverscanCheck.IsChecked := False;
    finally
      FSettingOverscan := False;
    end;
  end;
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
  // Set by the caller, not ticked by hand: no warning
  SetOverscanCheck(Value and (FMaxOverscan >= OVERSCAN_FACTOR_MIN));
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
