//** @abstract(The Background Settings dialog: choose no background, or a transparent,
//** solid or gradient one.)
//**
//** A small modal form, laid out in its .fmx file with standard FMX controls. On the right a
//** group of four radio buttons chooses the background image style: None, Transparent, Solid
//** or Gradient. On the left a TColorPanel sets the colour: for Solid, the one colour; for
//** Gradient, the end chosen under it, From or To, whose swatches show both, with a drop-down
//** list below them for the gradient's direction; under it a Hex box shows the same colour as
//** #RRGGBB and takes one typed in. None and Transparent need no colour, so the panel is
//** disabled then; for Transparent a slider sets the size of the checker that stands for
//** transparency on screen. A preview shows the result, with the checker at a quarter of its
//** size and None as black, as the viewport shows it.
//**
//** The dialog only edits a TSprite3DBackgroundSpec: set Spec before showing it and read it
//** back after OK. Each change also calls OnPreview, so the owner can show it in the viewport
//** at once, and undo it if the dialog is cancelled. On the desktop show it with ShowModal and
//** free it afterwards; on Android and iOS, which cannot block, show it with ShowAndFree, which
//** calls OnAccept on OK, OnCancel otherwise, and frees the form when it closes.
//**
//** @preformatted(
//** TBackgroundSettingsForm
//** `-- BackPanel                          the form's opaque background
//**     |-- ColourLabel, ColourPanel       the colour being edited
//**     |-- GradientLayout                 enabled for Gradient only
//**     |   |-- FromRadio, FromBox         edit the starting colour
//**     |   |-- ToRadio, ToBox             edit the ending colour
//**     |   `-- DirectionLabel, DirectionCombo   the gradient's direction
//**     |-- HexLabel, HexEdit              the colour being edited, as #RRGGBB
//**     |-- StyleGroup                     None, Transparent, Solid, Gradient
//**     |-- PreviewLabel, PreviewRect
//**     |-- CheckerLabel, CheckerTrack     checker size, for Transparent only
//**     `-- OkButton, CancelButton
//** )
unit Sprite3DBackgroundForm;

{
  The Background Settings dialog: choose no background, or a transparent,
  solid or gradient one.

  A small modal form, laid out in its .fmx file with standard FMX controls.
  On the right a group of four radio buttons chooses the background image
  style: None, Transparent, Solid or Gradient. On the left a TColorPanel
  sets the colour: for Solid, the one colour; for Gradient, the end chosen
  under it, From or To, whose swatches show both, with a drop-down list
  below them for the gradient's direction; under it a Hex box shows the
  same colour as #RRGGBB and takes one typed in. None and Transparent need
  no colour, so the panel is disabled then; for Transparent a slider sets
  the size of the checker that stands for transparency on screen. A
  preview shows the result, with the checker at a quarter of its size and
  None as black, as the viewport shows it.

  The dialog only edits a TSprite3DBackgroundSpec: set Spec before showing
  it and read it back after OK. Each change also calls OnPreview, so the
  owner can show it in the viewport at once, and undo it if the dialog is
  cancelled. On the desktop show it with ShowModal and free it afterwards;
  on Android and iOS, which cannot block, show it with ShowAndFree, which
  calls OnAccept on OK, OnCancel otherwise, and frees the form when it
  closes.

    TBackgroundSettingsForm
    `-- BackPanel                          the form's opaque background
        |-- ColourLabel, ColourPanel       the colour being edited
        |-- GradientLayout                 enabled for Gradient only
        |   |-- FromRadio, FromBox         edit the starting colour
        |   |-- ToRadio, ToBox             edit the ending colour
        |   `-- DirectionLabel, DirectionCombo   the gradient's direction
        |-- HexLabel, HexEdit              the colour being edited, as #RRGGBB
        |-- StyleGroup                     None, Transparent, Solid, Gradient
        |-- PreviewLabel, PreviewRect
        |-- CheckerLabel, CheckerTrack     checker size, for Transparent only
        `-- OkButton, CancelButton
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.StdCtrls, FMX.Colors,
  FMX.Objects, FMX.Layouts, FMX.Controls.Presentation, FMX.Edit, FMX.ListBox,
  Sprite3DBackground;

type
  //** @abstract(The Background Settings dialog; edits a TSprite3DBackgroundSpec.)
  //**
  //** Create it and set Spec. On the desktop, call ShowModal and, if it returns mrOk, read
  //** Spec, then free the form. Where ShowModal cannot block, as on Android and iOS, set
  //** OnAccept and call ShowAndFree instead. For the main thread only.
  /// <summary>The Background Settings dialog; edits a TSprite3DBackgroundSpec.</summary>
  /// <remarks>Create it and set Spec. On the desktop, call ShowModal and, if it returns
  /// mrOk, read Spec, then free the form. Where ShowModal cannot block, as on Android and iOS,
  /// set OnAccept and call ShowAndFree instead. For the main thread only.</remarks>
  TBackgroundSettingsForm = class(TForm)
    //** @abstract(Fills the form and holds every other control, giving it an opaque
    //** background.)
    /// <summary>Fills the form and holds every other control, giving it an opaque
    /// background.</summary>
    BackPanel: TPanel;
    //** @abstract(Says what ColourPanel is setting: the colour, or a gradient end.)
    /// <summary>Says what ColourPanel is setting: the colour, or a gradient end.</summary>
    ColourLabel: TLabel;
    //** @abstract(The colour picker; disabled for None and Transparent.)
    /// <summary>The colour picker; disabled for None and Transparent.</summary>
    ColourPanel: TColorPanel;
    //** @abstract(The caption beside HexEdit.)
    /// <summary>The caption beside HexEdit.</summary>
    HexLabel: TLabel;
    //** @abstract(The colour being edited as #RRGGBB; type one in to set it exactly.)
    //**
    //** Enabled with ColourPanel. A typed colour is taken when Enter is pressed or the box is
    //** left, and also when OK is clicked.
    /// <summary>The colour being edited as #RRGGBB; type one in to set it exactly.</summary>
    /// <remarks>Enabled with ColourPanel. A typed colour is taken when Enter is pressed or the
    /// box is left, and also when OK is clicked.</remarks>
    HexEdit: TEdit;
    //** @abstract(Holds the gradient end choice; enabled for Gradient only.)
    /// <summary>Holds the gradient end choice; enabled for Gradient only.</summary>
    GradientLayout: TLayout;
    //** @abstract(Makes ColourPanel set the gradient's starting colour.)
    /// <summary>Makes ColourPanel set the gradient's starting colour.</summary>
    FromRadio: TRadioButton;
    //** @abstract(Shows the gradient's starting colour.)
    /// <summary>Shows the gradient's starting colour.</summary>
    FromBox: TColorBox;
    //** @abstract(Makes ColourPanel set the gradient's ending colour.)
    /// <summary>Makes ColourPanel set the gradient's ending colour.</summary>
    ToRadio: TRadioButton;
    //** @abstract(Shows the gradient's ending colour.)
    /// <summary>Shows the gradient's ending colour.</summary>
    ToBox: TColorBox;
    //** @abstract(The caption beside DirectionCombo.)
    /// <summary>The caption beside DirectionCombo.</summary>
    DirectionLabel: TLabel;
    //** @abstract(Chooses which way the gradient runs; its items are in
    //** TSprite3DGradientDirection's order.)
    /// <summary>Chooses which way the gradient runs; its items are in
    /// TSprite3DGradientDirection's order.</summary>
    DirectionCombo: TComboBox;
    //** @abstract(The "Background image style" group of radio buttons.)
    /// <summary>The "Background image style" group of radio buttons.</summary>
    StyleGroup: TGroupBox;
    //** @abstract(Chooses the None style: no background is drawn.)
    /// <summary>Chooses the None style: no background is drawn.</summary>
    NoneRadio: TRadioButton;
    //** @abstract(Chooses the Transparent style.)
    /// <summary>Chooses the Transparent style.</summary>
    TransparentRadio: TRadioButton;
    //** @abstract(Chooses the Solid style.)
    /// <summary>Chooses the Solid style.</summary>
    SolidRadio: TRadioButton;
    //** @abstract(Chooses the Gradient style.)
    /// <summary>Chooses the Gradient style.</summary>
    GradientRadio: TRadioButton;
    //** @abstract(The caption above PreviewRect.)
    /// <summary>The caption above PreviewRect.</summary>
    PreviewLabel: TLabel;
    //** @abstract(Shows the background as chosen; a checker stands for transparency.)
    /// <summary>Shows the background as chosen; a checker stands for transparency.</summary>
    PreviewRect: TRectangle;
    //** @abstract(Shows the checker size chosen with CheckerTrack.)
    /// <summary>Shows the checker size chosen with CheckerTrack.</summary>
    CheckerLabel: TLabel;
    //** @abstract(Sets the checker size, 8 to 256 pixels in steps of 8; enabled for
    //** Transparent only.)
    /// <summary>Sets the checker size, 8 to 256 pixels in steps of 8; enabled for Transparent
    /// only.</summary>
    CheckerTrack: TTrackBar;
    //** @abstract(Closes the dialog with mrOk; the default button.)
    /// <summary>Closes the dialog with mrOk; the default button.</summary>
    OkButton: TButton;
    //** @abstract(Closes the dialog with mrCancel; also Esc.)
    /// <summary>Closes the dialog with mrCancel; also Esc.</summary>
    CancelButton: TButton;
    //** @abstract(Makes the preview's checker tile.)
    //**
    //** @param(Sender The form.)
    /// <summary>Makes the preview's checker tile.</summary>
    /// <param name="Sender">The form.</param>
    procedure FormCreate(Sender: TObject);
    //** @abstract(After ShowAndFree: calls OnAccept if the dialog was closed with OK, and frees
    //** the form.)
    //**
    //** Does nothing after ShowModal, whose caller reads the result and frees the form.
    //**
    //** @param(Sender The form.)
    //**
    //** @param(Action Set to caFree after ShowAndFree.)
    /// <summary>After ShowAndFree: calls OnAccept if the dialog was closed with OK, and frees
    /// the form.</summary>
    /// <remarks>Does nothing after ShowModal, whose caller reads the result and frees the
    /// form.</remarks>
    /// <param name="Sender">The form.</param>
    /// <param name="Action">Set to caFree after ShowAndFree.</param>
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    //** @abstract(Takes the newly chosen style into Spec and updates the controls.)
    //**
    //** @param(Sender The radio button that changed.)
    /// <summary>Takes the newly chosen style into Spec and updates the controls.</summary>
    /// <param name="Sender">The radio button that changed.</param>
    procedure StyleChange(Sender: TObject);
    //** @abstract(Loads the chosen gradient end's colour into ColourPanel.)
    //**
    //** @param(Sender The radio button that changed.)
    /// <summary>Loads the chosen gradient end's colour into ColourPanel.</summary>
    /// <param name="Sender">The radio button that changed.</param>
    procedure GradientEndChange(Sender: TObject);
    //** @abstract(Takes DirectionCombo's choice as the gradient's direction.)
    //**
    //** @param(Sender DirectionCombo.)
    /// <summary>Takes DirectionCombo's choice as the gradient's direction.</summary>
    /// <param name="Sender">DirectionCombo.</param>
    procedure DirectionComboChange(Sender: TObject);
    //** @abstract(Stores ColourPanel's colour as the colour being edited.)
    //**
    //** @param(Sender ColourPanel.)
    /// <summary>Stores ColourPanel's colour as the colour being edited.</summary>
    /// <param name="Sender">ColourPanel.</param>
    procedure ColourPanelChange(Sender: TObject);
    //** @abstract(Takes the colour typed into HexEdit as the colour being edited.)
    //**
    //** Accepts RRGGBB or AARRGGBB, with or without a leading #; the alpha is ignored, as
    //** backgrounds are opaque. Anything else puts the current colour back in the box.
    //**
    //** @param(Sender HexEdit.)
    /// <summary>Takes the colour typed into HexEdit as the colour being edited.</summary>
    /// <remarks>Accepts RRGGBB or AARRGGBB, with or without a leading #; the alpha is
    /// ignored, as backgrounds are opaque. Anything else puts the current colour back in the
    /// box.</remarks>
    /// <param name="Sender">HexEdit.</param>
    procedure HexEditChange(Sender: TObject);
    //** @abstract(Takes CheckerTrack's value, to the nearest 8, as the checker size.)
    //**
    //** @param(Sender CheckerTrack.)
    /// <summary>Takes CheckerTrack's value, to the nearest 8, as the checker size.</summary>
    /// <param name="Sender">CheckerTrack.</param>
    procedure CheckerTrackChange(Sender: TObject);
    //** @abstract(After ShowAndFree, closes the dialog with the button's ModalResult.)
    //**
    //** Under ShowModal the buttons' ModalResult closes the dialog by itself; a form shown
    //** with Show needs closing explicitly.
    //**
    //** @param(Sender OkButton or CancelButton.)
    /// <summary>After ShowAndFree, closes the dialog with the button's ModalResult.</summary>
    /// <remarks>Under ShowModal the buttons' ModalResult closes the dialog by itself; a form
    /// shown with Show needs closing explicitly.</remarks>
    /// <param name="Sender">OkButton or CancelButton.</param>
    procedure ButtonClick(Sender: TObject);
  private
    FSpec: TSprite3DBackgroundSpec;
    FUpdating: Boolean;   // set while code changes controls, to ignore their events
    FChecker: TBitmap;
    FFreeOnClose: Boolean;
    FOnAccept: TNotifyEvent;
    FOnCancel: TNotifyEvent;
    FOnPreview: TNotifyEvent;
    procedure SetSpec(const Value: TSprite3DBackgroundSpec);
    procedure LoadColourPanel;
    function EditedColour: TAlphaColor;
    procedure SetEditedColour(const AColour: TAlphaColor);
    procedure ShowHex;
    procedure UpdateControls;
    procedure UpdatePreview;
    procedure MakeChecker;
  public
    //** @abstract(Frees the preview's checker tile.)
    /// <summary>Frees the preview's checker tile.</summary>
    destructor Destroy; override;
    //** @abstract(The background being edited: set it before showing, read it after OK.)
    //**
    //** Setting it shows its style, colours and checker size. The checker colours are kept as
    //** given; this dialog does not change them.
    /// <summary>The background being edited: set it before showing, read it after
    /// OK.</summary>
    /// <remarks>Setting it shows its style, colours and checker size. The checker colours are
    /// kept as given; this dialog does not change them.</remarks>
    property Spec: TSprite3DBackgroundSpec read FSpec write SetSpec;
    //** @abstract(Shows the dialog without blocking, and frees it when it closes.)
    //**
    //** For platforms where ShowModal cannot block, such as Android and iOS. When the dialog
    //** closes with OK, OnAccept is called while Spec can still be read; then the form frees
    //** itself, so do not use it after that.
    /// <summary>Shows the dialog without blocking, and frees it when it closes.</summary>
    /// <remarks>For platforms where ShowModal cannot block, such as Android and iOS. When the
    /// dialog closes with OK, OnAccept is called while Spec can still be read; then the form
    /// frees itself, so do not use it after that.</remarks>
    procedure ShowAndFree;
    //** @abstract(Called after ShowAndFree when the dialog closes with OK; read Spec in it.)
    /// <summary>Called after ShowAndFree when the dialog closes with OK; read Spec in
    /// it.</summary>
    property OnAccept: TNotifyEvent read FOnAccept write FOnAccept;
    //** @abstract(Called after ShowAndFree when the dialog closes any way but OK.)
    //**
    //** The owner puts back the background it had before, undoing the previews.
    /// <summary>Called after ShowAndFree when the dialog closes any way but OK.</summary>
    /// <remarks>The owner puts back the background it had before, undoing the
    /// previews.</remarks>
    property OnCancel: TNotifyEvent read FOnCancel write FOnCancel;
    //** @abstract(Called after every change, with the dialog as Sender, so the owner can show
    //** Spec in the viewport at once.)
    //**
    //** The dialog never changes the viewport itself; on Cancel the owner undoes what the
    //** previews showed.
    /// <summary>Called after every change, with the dialog as Sender, so the owner can show
    /// Spec in the viewport at once.</summary>
    /// <remarks>The dialog never changes the viewport itself; on Cancel the owner undoes what
    /// the previews showed.</remarks>
    property OnPreview: TNotifyEvent read FOnPreview write FOnPreview;
  end;

implementation

uses
  System.Math;

{$R *.fmx}

const
  // The preview shows the checker at this fraction of its size
  PREVIEW_SCALE = 4;
  // ...but its squares no smaller than this
  PREVIEW_MIN_SQUARE = 2;
  // The slider moves in steps of this many pixels
  CHECKER_STEP = 8;

procedure TBackgroundSettingsForm.FormCreate(Sender: TObject);
begin
  FSpec := TSprite3DBackgroundSpec.Default;
  MakeChecker;
  SetSpec(FSpec);
end;

destructor TBackgroundSettingsForm.Destroy;
begin
  FChecker.Free;
  inherited;
end;

procedure TBackgroundSettingsForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if not FFreeOnClose then
    Exit;   // shown with ShowModal: the caller frees it
  if ModalResult = mrOk then
  begin
    if Assigned(FOnAccept) then
      FOnAccept(Self);
  end
  else if Assigned(FOnCancel) then
    FOnCancel(Self);
  Action := TCloseAction.caFree;
end;

procedure TBackgroundSettingsForm.CheckerTrackChange(Sender: TObject);
var
  Size: Integer;
begin
  if FUpdating then
    Exit;
  Size := Max(Round(CheckerTrack.Value / CHECKER_STEP) * CHECKER_STEP, CHECKER_STEP);
  if Size = FSpec.CheckerSize then
    Exit;
  FSpec.CheckerSize := Size;
  MakeChecker;
  UpdateControls;
  UpdatePreview;
end;

procedure TBackgroundSettingsForm.ButtonClick(Sender: TObject);
begin
  // A colour typed but not yet entered still counts
  if (Sender = OkButton) and HexEdit.Enabled then
    HexEditChange(HexEdit);
  if not FFreeOnClose then
    Exit;   // ShowModal closes the dialog itself
  ModalResult := TButton(Sender).ModalResult;
  Close;
end;

procedure TBackgroundSettingsForm.ShowAndFree;
begin
  FFreeOnClose := True;
  Show;
end;

// A tile of four squares in the spec's two checker greys, for the preview,
// each square a quarter of the checker size
procedure TBackgroundSettingsForm.MakeChecker;
var
  Square: Integer;
begin
  Square := Max(FSpec.CheckerSize div PREVIEW_SCALE, PREVIEW_MIN_SQUARE);
  if FChecker = nil then
    FChecker := TBitmap.Create(Square * 2, Square * 2)
  else
    FChecker.SetSize(Square * 2, Square * 2);
  if FChecker.Canvas.BeginScene then
  try
    FChecker.Canvas.Clear(FSpec.CheckerLight or $FF000000);
    FChecker.Canvas.Fill.Kind := TBrushKind.Solid;
    FChecker.Canvas.Fill.Color := FSpec.CheckerDark or $FF000000;
    FChecker.Canvas.FillRect(RectF(Square, 0, Square * 2, Square), 0, 0, [], 1);
    FChecker.Canvas.FillRect(RectF(0, Square, Square, Square * 2), 0, 0, [], 1);
  finally
    FChecker.Canvas.EndScene;
  end;
end;

procedure TBackgroundSettingsForm.SetSpec(const Value: TSprite3DBackgroundSpec);
begin
  FSpec := Value;
  FUpdating := True;
  try
    case FSpec.Kind of
      TSprite3DBackgroundKind.Solid:
        SolidRadio.IsChecked := True;
      TSprite3DBackgroundKind.Gradient:
        GradientRadio.IsChecked := True;
      TSprite3DBackgroundKind.Transparent:
        TransparentRadio.IsChecked := True;
    else
      NoneRadio.IsChecked := True;
    end;
    FromBox.Color := FSpec.GradientFrom;
    DirectionCombo.ItemIndex := Ord(FSpec.GradientDirection);
    ToBox.Color := FSpec.GradientTo;
    CheckerTrack.Value := EnsureRange(FSpec.CheckerSize, Round(CheckerTrack.Min),
      Round(CheckerTrack.Max));
  finally
    FUpdating := False;
  end;
  if FChecker <> nil then
    MakeChecker;
  LoadColourPanel;
  UpdateControls;
  UpdatePreview;
end;

// Puts the colour being edited into the panel, without that counting as an
// edit
procedure TBackgroundSettingsForm.LoadColourPanel;
begin
  FUpdating := True;
  try
    ColourPanel.Color := EditedColour;
  finally
    FUpdating := False;
  end;
  ShowHex;
end;

// The colour ColourPanel and HexEdit are editing: the chosen gradient end
// for Gradient, otherwise Colour
function TBackgroundSettingsForm.EditedColour: TAlphaColor;
begin
  if FSpec.Kind = TSprite3DBackgroundKind.Gradient then
  begin
    if ToRadio.IsChecked then
      Result := FSpec.GradientTo
    else
      Result := FSpec.GradientFrom;
  end
  else
    Result := FSpec.Colour;
end;

// Stores AColour, made opaque, as the colour being edited, and shows it in
// the gradient's swatch and the preview
procedure TBackgroundSettingsForm.SetEditedColour(const AColour: TAlphaColor);
var
  Colour: TAlphaColor;
begin
  Colour := AColour or $FF000000;   // backgrounds are opaque
  case FSpec.Kind of
    TSprite3DBackgroundKind.Solid:
      FSpec.Colour := Colour;
    TSprite3DBackgroundKind.Gradient:
      if ToRadio.IsChecked then
      begin
        FSpec.GradientTo := Colour;
        ToBox.Color := Colour;
      end
      else
      begin
        FSpec.GradientFrom := Colour;
        FromBox.Color := Colour;
      end;
  end;
  UpdatePreview;
end;

// Puts the colour being edited into HexEdit as #RRGGBB
procedure TBackgroundSettingsForm.ShowHex;
begin
  FUpdating := True;
  try
    HexEdit.Text := '#' + IntToHex(EditedColour and $00FFFFFF, 6);
  finally
    FUpdating := False;
  end;
end;

procedure TBackgroundSettingsForm.UpdateControls;
begin
  ColourPanel.Enabled := FSpec.Kind in [TSprite3DBackgroundKind.Solid,
    TSprite3DBackgroundKind.Gradient];
  HexEdit.Enabled := ColourPanel.Enabled;
  HexLabel.Enabled := ColourPanel.Enabled;
  CheckerTrack.Enabled := FSpec.Kind = TSprite3DBackgroundKind.Transparent;
  CheckerLabel.Enabled := CheckerTrack.Enabled;
  CheckerLabel.Text := Format('Checker size: %d px', [FSpec.CheckerSize]);
  GradientLayout.Enabled := FSpec.Kind = TSprite3DBackgroundKind.Gradient;
  case FSpec.Kind of
    TSprite3DBackgroundKind.Solid:
      ColourLabel.Text := 'Colour';
    TSprite3DBackgroundKind.Gradient:
      if ToRadio.IsChecked then
        ColourLabel.Text := 'Gradient: To colour'
      else
        ColourLabel.Text := 'Gradient: From colour';
    TSprite3DBackgroundKind.Transparent:
      ColourLabel.Text := 'Colour (not used: transparent)';
  else
    ColourLabel.Text := 'Colour (not used: no background)';
  end;
end;

procedure TBackgroundSettingsForm.UpdatePreview;
begin
  case FSpec.Kind of
    TSprite3DBackgroundKind.Solid:
      begin
        PreviewRect.Fill.Kind := TBrushKind.Solid;
        PreviewRect.Fill.Color := FSpec.Colour or $FF000000;
      end;
    TSprite3DBackgroundKind.Gradient:
      begin
        PreviewRect.Fill.Kind := TBrushKind.Gradient;
        PreviewRect.Fill.Gradient.Style := TGradientStyle.Linear;
        // From one edge or corner of the rectangle to the opposite one
        case FSpec.GradientDirection of
          TSprite3DGradientDirection.LeftToRight:
            begin
              PreviewRect.Fill.Gradient.StartPosition.Point := PointF(0, 0.5);
              PreviewRect.Fill.Gradient.StopPosition.Point := PointF(1, 0.5);
            end;
          TSprite3DGradientDirection.TopLeftToBottomRight:
            begin
              PreviewRect.Fill.Gradient.StartPosition.Point := PointF(0, 0);
              PreviewRect.Fill.Gradient.StopPosition.Point := PointF(1, 1);
            end;
          TSprite3DGradientDirection.TopRightToBottomLeft:
            begin
              PreviewRect.Fill.Gradient.StartPosition.Point := PointF(1, 0);
              PreviewRect.Fill.Gradient.StopPosition.Point := PointF(0, 1);
            end;
        else
          begin
            PreviewRect.Fill.Gradient.StartPosition.Point := PointF(0.5, 0);
            PreviewRect.Fill.Gradient.StopPosition.Point := PointF(0.5, 1);
          end;
        end;
        PreviewRect.Fill.Gradient.Points[0].Color := FSpec.GradientFrom or $FF000000;
        PreviewRect.Fill.Gradient.Points[1].Color := FSpec.GradientTo or $FF000000;
      end;
    TSprite3DBackgroundKind.Transparent:
      begin
        PreviewRect.Fill.Kind := TBrushKind.Bitmap;
        PreviewRect.Fill.Bitmap.WrapMode := TWrapMode.Tile;
        PreviewRect.Fill.Bitmap.Bitmap := FChecker;
      end;
  else
    // None: what the viewport shows with nothing drawn behind the scene
    begin
      PreviewRect.Fill.Kind := TBrushKind.Solid;
      PreviewRect.Fill.Color := TAlphaColors.Black;
    end;
  end;
  // The viewport shows the same, live
  if Assigned(FOnPreview) then
    FOnPreview(Self);
end;

procedure TBackgroundSettingsForm.StyleChange(Sender: TObject);
begin
  // Each change fires for the button turned off as well as the one turned on
  if FUpdating or not TRadioButton(Sender).IsChecked then
    Exit;
  if Sender = SolidRadio then
    FSpec.Kind := TSprite3DBackgroundKind.Solid
  else if Sender = GradientRadio then
    FSpec.Kind := TSprite3DBackgroundKind.Gradient
  else if Sender = TransparentRadio then
    FSpec.Kind := TSprite3DBackgroundKind.Transparent
  else
    FSpec.Kind := TSprite3DBackgroundKind.None;
  LoadColourPanel;
  UpdateControls;
  UpdatePreview;
end;

procedure TBackgroundSettingsForm.DirectionComboChange(Sender: TObject);
begin
  if FUpdating or (DirectionCombo.ItemIndex < 0) then
    Exit;
  FSpec.GradientDirection := TSprite3DGradientDirection(EnsureRange(DirectionCombo.ItemIndex,
    Ord(Low(TSprite3DGradientDirection)), Ord(High(TSprite3DGradientDirection))));
  UpdatePreview;
end;

procedure TBackgroundSettingsForm.GradientEndChange(Sender: TObject);
begin
  if FUpdating or not TRadioButton(Sender).IsChecked then
    Exit;
  LoadColourPanel;
  UpdateControls;
end;

procedure TBackgroundSettingsForm.ColourPanelChange(Sender: TObject);
begin
  if FUpdating then
    Exit;
  SetEditedColour(ColourPanel.Color);
  ShowHex;
end;

procedure TBackgroundSettingsForm.HexEditChange(Sender: TObject);
var
  Hex: String;
  Value: Int64;
begin
  if FUpdating then
    Exit;
  Hex := HexEdit.Text.Trim;
  if Hex.StartsWith('#') then
    Hex := Hex.Substring(1);
  if ((Length(Hex) = 6) or (Length(Hex) = 8)) and TryStrToInt64('$' + Hex, Value) then
  begin
    SetEditedColour(TAlphaColor(Value and $00FFFFFF));
    FUpdating := True;
    try
      ColourPanel.Color := EditedColour;
    finally
      FUpdating := False;
    end;
  end;
  ShowHex;   // tidies what was typed, or puts the colour back if it was not one
end;

end.
