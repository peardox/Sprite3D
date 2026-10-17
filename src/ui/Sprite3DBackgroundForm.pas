//** @abstract(The Background Settings dialog: choose a transparent, solid or gradient
//** background.)
//**
//** A small modal form, laid out in its .fmx file with standard FMX controls. On the right a
//** group of three radio buttons chooses the background image style: Transparent, Solid or
//** Gradient. On the left a TColorPanel sets the colour: for Solid, the one colour; for
//** Gradient, the end chosen under it, From (the top) or To (the bottom), whose swatches
//** show both. Transparent needs no colour, so the panel is disabled then. A preview shows
//** the result, with a small checker standing for transparency.
//**
//** The dialog only edits a TSprite3DBackgroundSpec: set Spec before showing it and read it
//** back after OK. On the desktop show it with ShowModal and free it afterwards; on Android
//** and iOS, which cannot block, show it with ShowAndFree, which calls OnAccept on OK and
//** frees the form when it closes.
//**
//** @preformatted(
//** TBackgroundSettingsForm
//** |-- ColourLabel, ColourPanel       the colour being edited
//** |-- GradientLayout                 enabled for Gradient only
//** |   |-- FromRadio, FromBox         edit the top colour
//** |   `-- ToRadio, ToBox             edit the bottom colour
//** |-- StyleGroup                     Transparent, Solid, Gradient
//** |-- PreviewLabel, PreviewRect
//** `-- OkButton, CancelButton
//** )
unit Sprite3DBackgroundForm;

{
  The Background Settings dialog: choose a transparent, solid or gradient
  background.

  A small modal form, laid out in its .fmx file with standard FMX controls.
  On the right a group of three radio buttons chooses the background image
  style: Transparent, Solid or Gradient. On the left a TColorPanel sets the
  colour: for Solid, the one colour; for Gradient, the end chosen under it,
  From (the top) or To (the bottom), whose swatches show both. Transparent
  needs no colour, so the panel is disabled then. A preview shows the
  result, with a small checker standing for transparency.

  The dialog only edits a TSprite3DBackgroundSpec: set Spec before showing
  it and read it back after OK. On the desktop show it with ShowModal and
  free it afterwards; on Android and iOS, which cannot block, show it with
  ShowAndFree, which calls OnAccept on OK and frees the form when it
  closes.

    TBackgroundSettingsForm
    |-- ColourLabel, ColourPanel       the colour being edited
    |-- GradientLayout                 enabled for Gradient only
    |   |-- FromRadio, FromBox         edit the top colour
    |   `-- ToRadio, ToBox             edit the bottom colour
    |-- StyleGroup                     Transparent, Solid, Gradient
    |-- PreviewLabel, PreviewRect
    `-- OkButton, CancelButton
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.StdCtrls, FMX.Colors,
  FMX.Objects, FMX.Layouts, FMX.Controls.Presentation,
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
    //** @abstract(Says what ColourPanel is setting: the colour, or a gradient end.)
    /// <summary>Says what ColourPanel is setting: the colour, or a gradient end.</summary>
    ColourLabel: TLabel;
    //** @abstract(The colour picker; disabled for Transparent.)
    /// <summary>The colour picker; disabled for Transparent.</summary>
    ColourPanel: TColorPanel;
    //** @abstract(Holds the gradient end choice; enabled for Gradient only.)
    /// <summary>Holds the gradient end choice; enabled for Gradient only.</summary>
    GradientLayout: TLayout;
    //** @abstract(Makes ColourPanel set the gradient's top colour.)
    /// <summary>Makes ColourPanel set the gradient's top colour.</summary>
    FromRadio: TRadioButton;
    //** @abstract(Shows the gradient's top colour.)
    /// <summary>Shows the gradient's top colour.</summary>
    FromBox: TColorBox;
    //** @abstract(Makes ColourPanel set the gradient's bottom colour.)
    /// <summary>Makes ColourPanel set the gradient's bottom colour.</summary>
    ToRadio: TRadioButton;
    //** @abstract(Shows the gradient's bottom colour.)
    /// <summary>Shows the gradient's bottom colour.</summary>
    ToBox: TColorBox;
    //** @abstract(The "Background image style" group of radio buttons.)
    /// <summary>The "Background image style" group of radio buttons.</summary>
    StyleGroup: TGroupBox;
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
    //** @abstract(Stores ColourPanel's colour as the colour being edited.)
    //**
    //** @param(Sender ColourPanel.)
    /// <summary>Stores ColourPanel's colour as the colour being edited.</summary>
    /// <param name="Sender">ColourPanel.</param>
    procedure ColourPanelChange(Sender: TObject);
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
    procedure SetSpec(const Value: TSprite3DBackgroundSpec);
    procedure LoadColourPanel;
    procedure UpdateControls;
    procedure UpdatePreview;
    procedure MakeChecker;
  public
    //** @abstract(Frees the preview's checker tile.)
    /// <summary>Frees the preview's checker tile.</summary>
    destructor Destroy; override;
    //** @abstract(The background being edited: set it before showing, read it after OK.)
    //**
    //** Setting it shows its style and colours. CheckerSize and the checker colours are kept
    //** as given; this dialog does not change them.
    /// <summary>The background being edited: set it before showing, read it after
    /// OK.</summary>
    /// <remarks>Setting it shows its style and colours. CheckerSize and the checker colours are
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
  end;

implementation

{$R *.fmx}

const
  // The preview's checker: squares of this many pixels
  PREVIEW_CHECKER = 8;

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
  if (ModalResult = mrOk) and Assigned(FOnAccept) then
    FOnAccept(Self);
  Action := TCloseAction.caFree;
end;

procedure TBackgroundSettingsForm.ButtonClick(Sender: TObject);
begin
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

// A tile of four squares in the spec's two checker greys, for the preview
procedure TBackgroundSettingsForm.MakeChecker;
begin
  if FChecker = nil then
    FChecker := TBitmap.Create(PREVIEW_CHECKER * 2, PREVIEW_CHECKER * 2);
  if FChecker.Canvas.BeginScene then
  try
    FChecker.Canvas.Clear(FSpec.CheckerLight or $FF000000);
    FChecker.Canvas.Fill.Kind := TBrushKind.Solid;
    FChecker.Canvas.Fill.Color := FSpec.CheckerDark or $FF000000;
    FChecker.Canvas.FillRect(RectF(PREVIEW_CHECKER, 0, PREVIEW_CHECKER * 2,
      PREVIEW_CHECKER), 0, 0, [], 1);
    FChecker.Canvas.FillRect(RectF(0, PREVIEW_CHECKER, PREVIEW_CHECKER,
      PREVIEW_CHECKER * 2), 0, 0, [], 1);
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
    else
      TransparentRadio.IsChecked := True;
    end;
    FromBox.Color := FSpec.GradientFrom;
    ToBox.Color := FSpec.GradientTo;
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
    case FSpec.Kind of
      TSprite3DBackgroundKind.Gradient:
        if ToRadio.IsChecked then
          ColourPanel.Color := FSpec.GradientTo
        else
          ColourPanel.Color := FSpec.GradientFrom;
    else
      ColourPanel.Color := FSpec.Colour;
    end;
  finally
    FUpdating := False;
  end;
end;

procedure TBackgroundSettingsForm.UpdateControls;
begin
  ColourPanel.Enabled := FSpec.Kind <> TSprite3DBackgroundKind.Transparent;
  GradientLayout.Enabled := FSpec.Kind = TSprite3DBackgroundKind.Gradient;
  case FSpec.Kind of
    TSprite3DBackgroundKind.Solid:
      ColourLabel.Text := 'Colour';
    TSprite3DBackgroundKind.Gradient:
      if ToRadio.IsChecked then
        ColourLabel.Text := 'Gradient: To colour (bottom)'
      else
        ColourLabel.Text := 'Gradient: From colour (top)';
  else
    ColourLabel.Text := 'Colour (not used: transparent)';
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
        PreviewRect.Fill.Gradient.StartPosition.Point := PointF(0.5, 0);
        PreviewRect.Fill.Gradient.StopPosition.Point := PointF(0.5, 1);
        PreviewRect.Fill.Gradient.Points[0].Color := FSpec.GradientFrom or $FF000000;
        PreviewRect.Fill.Gradient.Points[1].Color := FSpec.GradientTo or $FF000000;
      end;
  else
    begin
      PreviewRect.Fill.Kind := TBrushKind.Bitmap;
      PreviewRect.Fill.Bitmap.WrapMode := TWrapMode.Tile;
      PreviewRect.Fill.Bitmap.Bitmap := FChecker;
    end;
  end;
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
  else
    FSpec.Kind := TSprite3DBackgroundKind.Transparent;
  LoadColourPanel;
  UpdateControls;
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
var
  Colour: TAlphaColor;
begin
  if FUpdating then
    Exit;
  Colour := ColourPanel.Color or $FF000000;   // backgrounds are opaque
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

end.
