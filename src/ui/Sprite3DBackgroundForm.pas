//** @abstract(The Background Settings dialog: choose no background, or a transparent,
//** solid, gradient or image one.)
//**
//** A small modal form, laid out in its .fmx file with standard FMX controls. On the right a
//** group of five radio buttons chooses the background image style: None, Transparent, Solid,
//** Gradient or Image. On the left a TColorPanel sets the colour: for Solid, the one colour; for
//** Gradient, the end chosen under it, From or To, whose swatches show both, with a drop-down
//** list below them for the gradient's direction; under it a Hex box shows the same colour as
//** #RRGGBB and takes one typed in. None and Transparent need no colour, so the panel is
//** disabled then; for Transparent a slider sets the size of the checker that stands for
//** transparency on screen. For Image, the file is typed or chosen with Browse (desktop
//** only), a drop-down chooses how it is fitted to the picture, a line under them gives its
//** size or why it cannot be read, nine buttons in a square under the colour place it,
//** centred unless changed, and the colour panel sets the colour where the image does not
//** reach. A preview shows the result, with the checker at a quarter of its size and None
//** as black, as the viewport shows it; for Image it shows the grab's frame (GrabWidth by
//** GrabHeight) with the whole image round it, darkening what a grab cuts off and
//** outlining the frame in black dashes over white.
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
//**     |-- AlignLayout                    AlignLabel and nine buttons, 3 by 3: the image's
//**     |                                  position, for Image but Stretch
//**     |-- StyleGroup                     None, Transparent, Solid, Gradient, Image
//**     |-- PreviewLabel, PreviewRect
//**     |-- CheckerLabel, CheckerTrack     checker size, for Transparent only
//**     |-- ImageLayout                    enabled for Image only
//**     |   |-- ImageFileLabel, ImageEdit, ImageBrowseButton   the file
//**     |   |-- FitLabel, FitCombo          how it is fitted
//**     |   `-- ImageStatusLabel           its size, or why it cannot be read
//**     `-- OkButton, CancelButton
//** )
unit Sprite3DBackgroundForm;

{
  The Background Settings dialog: choose no background, or a transparent,
  solid, gradient or image one.

  A small modal form, laid out in its .fmx file with standard FMX controls.
  On the right a group of five radio buttons chooses the background image
  style: None, Transparent, Solid, Gradient or Image. On the left a TColorPanel
  sets the colour: for Solid, the one colour; for Gradient, the end chosen
  under it, From or To, whose swatches show both, with a drop-down list
  below them for the gradient's direction; under it a Hex box shows the
  same colour as #RRGGBB and takes one typed in. None and Transparent need
  no colour, so the panel is disabled then; for Transparent a slider sets
  the size of the checker that stands for transparency on screen. For Image,
  the file is typed or chosen with Browse (desktop only), a drop-down
  chooses how it is fitted to the picture, a line under them gives its size
  or why it cannot be read, nine buttons in a square under the colour place
  it, centred unless changed, and the colour panel sets the colour where the
  image does not reach. A preview shows the result, with the checker at a
  quarter of its size and None as black, as the viewport shows it; for
  Image it shows the grab's frame (GrabWidth by GrabHeight) with the whole
  image round it, darkening what a grab cuts off and outlining the frame in
  black dashes over white.

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
        |-- AlignLayout                    AlignLabel and nine buttons, 3 by 3: the image's
        |                                  position, for Image but Stretch
        |-- StyleGroup                     None, Transparent, Solid, Gradient, Image
        |-- PreviewLabel, PreviewRect
        |-- CheckerLabel, CheckerTrack     checker size, for Transparent only
        |-- ImageLayout                    enabled for Image only
        |   |-- ImageFileLabel, ImageEdit, ImageBrowseButton   the file
        |   |-- FitLabel, FitCombo          how it is fitted
        |   `-- ImageStatusLabel           its size, or why it cannot be read
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
  TBackgroundSettingsForm = class(TForm)
    //** @abstract(Fills the form and holds every other control, giving it an opaque
    //** background.)
    BackPanel: TPanel;
    //** @abstract(Says what ColourPanel is setting: the colour, or a gradient end.)
    ColourLabel: TLabel;
    //** @abstract(The colour picker; disabled for None and Transparent.)
    ColourPanel: TColorPanel;
    //** @abstract(The caption beside HexEdit.)
    HexLabel: TLabel;
    //** @abstract(The colour being edited as #RRGGBB; type one in to set it exactly.)
    //**
    //** Enabled with ColourPanel. A typed colour is taken when Enter is pressed or the box is
    //** left, and also when OK is clicked.
    HexEdit: TEdit;
    //** @abstract(Holds the gradient end choice; enabled for Gradient only.)
    GradientLayout: TLayout;
    //** @abstract(Makes ColourPanel set the gradient's starting colour.)
    FromRadio: TRadioButton;
    //** @abstract(Shows the gradient's starting colour.)
    FromBox: TColorBox;
    //** @abstract(Makes ColourPanel set the gradient's ending colour.)
    ToRadio: TRadioButton;
    //** @abstract(Shows the gradient's ending colour.)
    ToBox: TColorBox;
    //** @abstract(The caption beside DirectionCombo.)
    DirectionLabel: TLabel;
    //** @abstract(Chooses which way the gradient runs; its items are in
    //** TSprite3DGradientDirection's order.)
    DirectionCombo: TComboBox;
    //** @abstract(The "Background image style" group of radio buttons.)
    StyleGroup: TGroupBox;
    //** @abstract(Chooses the None style: no background is drawn.)
    NoneRadio: TRadioButton;
    //** @abstract(Chooses the Transparent style.)
    TransparentRadio: TRadioButton;
    //** @abstract(Chooses the Solid style.)
    SolidRadio: TRadioButton;
    //** @abstract(Chooses the Gradient style.)
    GradientRadio: TRadioButton;
    //** @abstract(Chooses the Image style.)
    ImageRadio: TRadioButton;
    //** @abstract(The caption above PreviewRect.)
    PreviewLabel: TLabel;
    //** @abstract(Shows the background as chosen; a checker stands for transparency.)
    PreviewRect: TRectangle;
    //** @abstract(Shows the checker size chosen with CheckerTrack.)
    CheckerLabel: TLabel;
    //** @abstract(Sets the checker size, 8 to 256 pixels in steps of 8; enabled for
    //** Transparent only.)
    CheckerTrack: TTrackBar;
    //** @abstract(Closes the dialog with mrOk; the default button.)
    OkButton: TButton;
    //** @abstract(Closes the dialog with mrCancel; also Esc.)
    CancelButton: TButton;
    //** @abstract(Holds the image's file, fit and status; enabled for Image only.)
    ImageLayout: TLayout;
    //** @abstract(The caption above ImageEdit.)
    ImageFileLabel: TLabel;
    //** @abstract(The image file's full path; typed in, or set by ImageBrowseButton.)
    //**
    //** A typed path is taken when Enter is pressed or the box is left, and also when OK is
    //** clicked.
    ImageEdit: TEdit;
    //** @abstract(Chooses the image file with the system's file dialog; hidden on Android and
    //** iOS, which have none.)
    ImageBrowseButton: TButton;
    //** @abstract(The caption beside FitCombo.)
    FitLabel: TLabel;
    //** @abstract(Chooses how the image is fitted to the picture; its items are in
    //** TSprite3DImageFit's order.)
    FitCombo: TComboBox;
    //** @abstract(The image's size in pixels, or why it cannot be read; its hint gives the
    //** whole of it.)
    ImageStatusLabel: TLabel;
    //** @abstract(Holds AlignLabel and the nine image position buttons; enabled for Image,
    //** but for Stretch, which fills the picture.)
    AlignLayout: TLayout;
    //** @abstract(The caption above the image position buttons.)
    AlignLabel: TLabel;
    //** @abstract(Places the image at the top left; Tag 0, Ord of its
    //** TSprite3DImageAlign.)
    AlignTopLeftRadio: TRadioButton;
    //** @abstract(Places the image at the top; Tag 1, Ord of its
    //** TSprite3DImageAlign.)
    AlignTopRadio: TRadioButton;
    //** @abstract(Places the image at the top right; Tag 2, Ord of its
    //** TSprite3DImageAlign.)
    AlignTopRightRadio: TRadioButton;
    //** @abstract(Places the image at the left; Tag 3, Ord of its
    //** TSprite3DImageAlign.)
    AlignLeftRadio: TRadioButton;
    //** @abstract(Places the image in the centre; Tag 4, Ord of its
    //** TSprite3DImageAlign.)
    AlignCentreRadio: TRadioButton;
    //** @abstract(Places the image at the right; Tag 5, Ord of its
    //** TSprite3DImageAlign.)
    AlignRightRadio: TRadioButton;
    //** @abstract(Places the image at the bottom left; Tag 6, Ord of its
    //** TSprite3DImageAlign.)
    AlignBottomLeftRadio: TRadioButton;
    //** @abstract(Places the image at the bottom; Tag 7, Ord of its
    //** TSprite3DImageAlign.)
    AlignBottomRadio: TRadioButton;
    //** @abstract(Places the image at the bottom right; Tag 8, Ord of its
    //** TSprite3DImageAlign.)
    AlignBottomRightRadio: TRadioButton;
    //** @abstract(Makes the preview's checker tile.)
    //**
    //** @param(Sender The form.)
    procedure FormCreate(Sender: TObject);
    //** @abstract(After ShowAndFree: calls OnAccept if the dialog was closed with OK, and frees
    //** the form.)
    //**
    //** Does nothing after ShowModal, whose caller reads the result and frees the form.
    //**
    //** @param(Sender The form.)
    //**
    //** @param(Action Set to caFree after ShowAndFree.)
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    //** @abstract(Takes the newly chosen style into Spec and updates the controls.)
    //**
    //** @param(Sender The radio button that changed.)
    procedure StyleChange(Sender: TObject);
    //** @abstract(Loads the chosen gradient end's colour into ColourPanel.)
    //**
    //** @param(Sender The radio button that changed.)
    procedure GradientEndChange(Sender: TObject);
    //** @abstract(Takes DirectionCombo's choice as the gradient's direction.)
    //**
    //** @param(Sender DirectionCombo.)
    procedure DirectionComboChange(Sender: TObject);
    //** @abstract(Stores ColourPanel's colour as the colour being edited.)
    //**
    //** @param(Sender ColourPanel.)
    procedure ColourPanelChange(Sender: TObject);
    //** @abstract(Takes the colour typed into HexEdit as the colour being edited.)
    //**
    //** Accepts RRGGBB or AARRGGBB, with or without a leading #; the alpha is ignored, as
    //** backgrounds are opaque. Anything else puts the current colour back in the box.
    //**
    //** @param(Sender HexEdit.)
    procedure HexEditChange(Sender: TObject);
    //** @abstract(Takes CheckerTrack's value, to the nearest 8, as the checker size.)
    //**
    //** @param(Sender CheckerTrack.)
    procedure CheckerTrackChange(Sender: TObject);
    //** @abstract(After ShowAndFree, closes the dialog with the button's ModalResult.)
    //**
    //** Under ShowModal the buttons' ModalResult closes the dialog by itself; a form shown
    //** with Show needs closing explicitly.
    //**
    //** @param(Sender OkButton or CancelButton.)
    procedure ButtonClick(Sender: TObject);
    //** @abstract(Takes the path typed into ImageEdit as the image file.)
    //**
    //** @param(Sender ImageEdit.)
    procedure ImageEditChange(Sender: TObject);
    //** @abstract(Chooses the image file with the system's file dialog, opening in the
    //** present file's folder.)
    //**
    //** @param(Sender ImageBrowseButton.)
    procedure ImageBrowseButtonClick(Sender: TObject);
    //** @abstract(Takes FitCombo's choice as how the image is fitted.)
    //**
    //** @param(Sender FitCombo.)
    procedure FitComboChange(Sender: TObject);
    //** @abstract(Takes the image position button turned on, by its Tag, as ImageAlign.)
    //**
    //** @param(Sender The radio button that changed.)
    procedure AlignRadioChange(Sender: TObject);
  private
    FSpec: TSprite3DBackgroundSpec;
    FUpdating: Boolean;   // set while code changes controls, to ignore their events
    FChecker: TBitmap;
    FFreeOnClose: Boolean;
    FOnAccept: TNotifyEvent;
    FOnCancel: TNotifyEvent;
    FOnPreview: TNotifyEvent;
    //** @abstract(Backing fields for GrabWidth and GrabHeight.)
    FGrabWidth, FGrabHeight: Integer;
    procedure SetSpec(const Value: TSprite3DBackgroundSpec);
    //** @abstract(The Image preview: the grab's frame and the whole image round it, the part
    //** of the image outside the frame darkened and the frame outlined in white and black
    //** dashes, all scaled to fit PreviewRect.)
    //**
    //** @returns(A new bitmap at twice PreviewRect's size, owned by the caller.)
    function NewImagePreview: TBitmap;
    procedure LoadColourPanel;
    function EditedColour: TAlphaColor;
    procedure SetEditedColour(const AColour: TAlphaColor);
    procedure ShowHex;
    procedure UpdateControls;
    procedure UpdatePreview;
    procedure MakeChecker;
  public
    //** @abstract(Frees the preview's checker tile.)
    destructor Destroy; override;
    //** @abstract(The background being edited: set it before showing, read it after OK.)
    //**
    //** Setting it shows its style, colours and checker size. The checker colours are kept as
    //** given; this dialog does not change them.
    property Spec: TSprite3DBackgroundSpec read FSpec write SetSpec;
    //** @abstract(Shows the dialog without blocking, and frees it when it closes.)
    //**
    //** For platforms where ShowModal cannot block, such as Android and iOS. When the dialog
    //** closes with OK, OnAccept is called while Spec can still be read; then the form frees
    //** itself, so do not use it after that.
    procedure ShowAndFree;
    //** @abstract(Called after ShowAndFree when the dialog closes with OK; read Spec in it.)
    property OnAccept: TNotifyEvent read FOnAccept write FOnAccept;
    //** @abstract(Called after ShowAndFree when the dialog closes any way but OK.)
    //**
    //** The owner puts back the background it had before, undoing the previews.
    property OnCancel: TNotifyEvent read FOnCancel write FOnCancel;
    //** @abstract(Called after every change, with the dialog as Sender, so the owner can show
    //** Spec in the viewport at once.)
    //**
    //** The dialog never changes the viewport itself; on Cancel the owner undoes what the
    //** previews showed.
    property OnPreview: TNotifyEvent read FOnPreview write FOnPreview;
    //** @abstract(The grab size, in pixels, whose frame the Image preview outlines; 0, the
    //** default, for the preview's own shape.)
    //**
    //** Set them before showing the dialog.
    property GrabWidth: Integer read FGrabWidth write FGrabWidth;
    //** @abstract(See GrabWidth.)
    property GrabHeight: Integer read FGrabHeight write FGrabHeight;
  end;

implementation

uses
  System.Math, FMX.Dialogs;

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
  // A colour or path typed but not yet entered still counts
  if (Sender = OkButton) and HexEdit.Enabled then
    HexEditChange(HexEdit);
  if (Sender = OkButton) and ImageLayout.Enabled then
    ImageEditChange(ImageEdit);
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
      TSprite3DBackgroundKind.Image:
        ImageRadio.IsChecked := True;
    else
      NoneRadio.IsChecked := True;
    end;
    ImageEdit.Text := FSpec.ImageFile;
    FitCombo.ItemIndex := Ord(FSpec.ImageFit);
    // The position button whose Tag is the alignment
    for var I := 0 to AlignLayout.ChildrenCount - 1 do
      if (AlignLayout.Children[I] is TRadioButton) and
        (TRadioButton(AlignLayout.Children[I]).Tag = Ord(FSpec.ImageAlign)) then
        TRadioButton(AlignLayout.Children[I]).IsChecked := True;
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
    TSprite3DBackgroundKind.Solid, TSprite3DBackgroundKind.Image:
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
var
  Picture: TBitmap;
  Problem: String;
begin
  ColourPanel.Enabled := FSpec.Kind in [TSprite3DBackgroundKind.Solid,
    TSprite3DBackgroundKind.Gradient, TSprite3DBackgroundKind.Image];
  HexEdit.Enabled := ColourPanel.Enabled;
  HexLabel.Enabled := ColourPanel.Enabled;
  CheckerTrack.Enabled := FSpec.Kind = TSprite3DBackgroundKind.Transparent;
  CheckerLabel.Enabled := CheckerTrack.Enabled;
  CheckerLabel.Text := Format('Checker size: %d px', [FSpec.CheckerSize]);
  GradientLayout.Enabled := FSpec.Kind = TSprite3DBackgroundKind.Gradient;
  ImageLayout.Enabled := FSpec.Kind = TSprite3DBackgroundKind.Image;
  // Stretch fills the picture, so there is nothing to place
  AlignLayout.Enabled := ImageLayout.Enabled and
    (FSpec.ImageFit <> TSprite3DImageFit.Stretch);
  {$IF DEFINED(ANDROID) or DEFINED(IOS)}
  ImageBrowseButton.Visible := False;   // no file dialog: the path is typed
  {$ENDIF}
  // The image's size, or why there is none; only while Image is chosen, so
  // nothing is read otherwise
  if ImageLayout.Enabled then
  begin
    Picture := BackgroundImage(FSpec.ImageFile, Problem);
    if Picture <> nil then
      ImageStatusLabel.Text := Format('%d x %d pixels', [Picture.Width, Picture.Height])
    else
      ImageStatusLabel.Text := Problem;
  end
  else
    ImageStatusLabel.Text := ' ';
  ImageStatusLabel.Hint := ImageStatusLabel.Text;
  ImageStatusLabel.ShowHint := True;
  case FSpec.Kind of
    TSprite3DBackgroundKind.Solid:
      ColourLabel.Text := 'Colour';
    TSprite3DBackgroundKind.Image:
      ColourLabel.Text := 'Colour where the image does not reach';
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
var
  Picture: TBitmap;
begin
  case FSpec.Kind of
    TSprite3DBackgroundKind.Image:
      begin
        // The grab's frame, outlined, with the whole image round it, so what
        // a grab cuts off shows too
        Picture := NewImagePreview;
        try
          PreviewRect.Fill.Kind := TBrushKind.Bitmap;
          PreviewRect.Fill.Bitmap.WrapMode := TWrapMode.TileStretch;
          PreviewRect.Fill.Bitmap.Bitmap := Picture;   // copied
        finally
          Picture.Free;
        end;
      end;
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

function TBackgroundSettingsForm.NewImagePreview: TBitmap;
const
  // Drawn at twice the preview's size, so the outline stays crisp
  DETAIL = 2;
  // Behind everything: what is neither the frame nor the image
  SURROUND = $FF2B2B2B;
  // Laid over what a grab cuts off
  CUT_SHADE = $A0000000;
var
  Picture: TBitmap;
  Problem: String;
  PW, PH: Integer;
  GW, GH, Scale, OffX, OffY: Single;
  Frame, Img, Union: TRectF;

  function Mapped(const R: TRectF): TRectF;
  begin
    Result := TRectF.Create(R.Left * Scale + OffX, R.Top * Scale + OffY,
      R.Right * Scale + OffX, R.Bottom * Scale + OffY);
  end;

begin
  PW := Max(Round(PreviewRect.Width * DETAIL), 1);
  PH := Max(Round(PreviewRect.Height * DETAIL), 1);
  // The frame in the grab's own pixels, so Original size is exact; without
  // a grab size, the preview's shape
  GW := FGrabWidth;
  GH := FGrabHeight;
  if (GW <= 0) or (GH <= 0) then
  begin
    GW := PW;
    GH := PH;
  end;
  Frame := TRectF.Create(0, 0, GW, GH);
  Picture := BackgroundImage(FSpec.ImageFile, Problem);
  if Picture <> nil then
    Img := FSpec.ImageRect(Picture.Width, Picture.Height, GW, GH, 1)
  else
    Img := Frame;
  // Everything there is to see, scaled to fit the preview and centred in it
  Union := TRectF.Union(Frame, Img);
  Scale := Min(PW / Max(Union.Width, 1), PH / Max(Union.Height, 1));
  OffX := (PW - Union.Width * Scale) / 2 - Union.Left * Scale;
  OffY := (PH - Union.Height * Scale) / 2 - Union.Top * Scale;
  Frame := Mapped(Frame);
  Img := Mapped(Img);
  Result := TBitmap.Create(PW, PH);
  try
    if Result.Canvas.BeginScene then
    try
      Result.Canvas.Clear(SURROUND);
      // The grab: the colour, and the image over it, as NewBitmap draws it
      Result.Canvas.Fill.Kind := TBrushKind.Solid;
      Result.Canvas.Fill.Color := FSpec.Colour or $FF000000;
      Result.Canvas.FillRect(Frame, 0, 0, [], 1);
      if Picture <> nil then
        Result.Canvas.DrawBitmap(Picture, TRectF.Create(0, 0, Picture.Width,
          Picture.Height), Img, 1, False);
      // What a grab cuts off, darkened: everything outside the frame
      Result.Canvas.Fill.Color := CUT_SHADE;
      Result.Canvas.FillRect(TRectF.Create(0, 0, PW, Frame.Top), 0, 0, [], 1);
      Result.Canvas.FillRect(TRectF.Create(0, Frame.Bottom, PW, PH), 0, 0, [], 1);
      Result.Canvas.FillRect(TRectF.Create(0, Frame.Top, Frame.Left, Frame.Bottom), 0, 0,
        [], 1);
      Result.Canvas.FillRect(TRectF.Create(Frame.Right, Frame.Top, PW, Frame.Bottom), 0, 0,
        [], 1);
      // The frame's edge: black dashes over a white line, which shows over
      // any image
      Frame.Inflate(-DETAIL / 2, -DETAIL / 2);
      Result.Canvas.Stroke.Kind := TBrushKind.Solid;
      Result.Canvas.Stroke.Thickness := DETAIL;
      Result.Canvas.Stroke.Dash := TStrokeDash.Solid;
      Result.Canvas.Stroke.Color := TAlphaColors.White;
      Result.Canvas.DrawRect(Frame, 0, 0, [], 1);
      Result.Canvas.Stroke.Dash := TStrokeDash.Dash;
      Result.Canvas.Stroke.Color := TAlphaColors.Black;
      Result.Canvas.DrawRect(Frame, 0, 0, [], 1);
    finally
      Result.Canvas.EndScene;
    end;
  except
    Result.Free;
    raise;
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
  else if Sender = TransparentRadio then
    FSpec.Kind := TSprite3DBackgroundKind.Transparent
  else if Sender = ImageRadio then
    FSpec.Kind := TSprite3DBackgroundKind.Image
  else
    FSpec.Kind := TSprite3DBackgroundKind.None;
  LoadColourPanel;
  UpdateControls;
  UpdatePreview;
end;

procedure TBackgroundSettingsForm.ImageEditChange(Sender: TObject);
var
  Path: String;
begin
  if FUpdating then
    Exit;
  Path := ImageEdit.Text.Trim;
  if Path = FSpec.ImageFile then
    Exit;
  FSpec.ImageFile := Path;
  UpdateControls;
  UpdatePreview;
end;

procedure TBackgroundSettingsForm.ImageBrowseButtonClick(Sender: TObject);
{$IF not (DEFINED(ANDROID) or DEFINED(IOS))}
var
  Dialog: TOpenDialog;
begin
  Dialog := TOpenDialog.Create(nil);
  try
    Dialog.Title := 'Background Image';
    Dialog.Filter := 'Images (*.png;*.jpg;*.jpeg;*.bmp;*.gif)|*.png;*.jpg;*.jpeg;*.bmp;*.gif|' +
      'All files|*.*';
    if FSpec.ImageFile <> String.Empty then
    begin
      Dialog.InitialDir := ExtractFilePath(FSpec.ImageFile);
      Dialog.FileName := ExtractFileName(FSpec.ImageFile);
    end;
    if not Dialog.Execute then
      Exit;
    FUpdating := True;
    try
      ImageEdit.Text := Dialog.FileName;
    finally
      FUpdating := False;
    end;
    FSpec.ImageFile := Dialog.FileName;
  finally
    Dialog.Free;
  end;
  UpdateControls;
  UpdatePreview;
end;
{$ELSE}
begin
  // No file dialog here; the button is hidden
end;
{$ENDIF}

procedure TBackgroundSettingsForm.FitComboChange(Sender: TObject);
begin
  if FUpdating or (FitCombo.ItemIndex < 0) then
    Exit;
  FSpec.ImageFit := TSprite3DImageFit(EnsureRange(FitCombo.ItemIndex,
    Ord(Low(TSprite3DImageFit)), Ord(High(TSprite3DImageFit))));
  UpdateControls;
  UpdatePreview;
end;

procedure TBackgroundSettingsForm.AlignRadioChange(Sender: TObject);
begin
  // Each change fires for the button turned off as well as the one turned on
  if FUpdating or not TRadioButton(Sender).IsChecked then
    Exit;
  FSpec.ImageAlign := TSprite3DImageAlign(EnsureRange(TRadioButton(Sender).Tag,
    Ord(Low(TSprite3DImageAlign)), Ord(High(TSprite3DImageAlign))));
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
