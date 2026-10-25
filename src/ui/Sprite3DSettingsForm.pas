//** @abstract(The Settings dialog: file associations, what to load at start-up, the theme, the
//** grab size, the view's frame rate and, on Windows, which GPU to use.)
//**
//** A modal form, centred on the main form, laid out in its .fmx file with standard FMX
//** controls in groups, in two columns so it stays short enough for smaller displays; on
//** Android and iOS, which are too narrow for that, the groups go in one column that
//** scrolls:
//**
//** @preformatted(
//** TGeneralSettingsForm
//** `-- BackPanel                      the form's opaque background
//**     |-- ScrollBox
//**     |   `-- ColumnsLayout          as tall as the taller column
//**     |       |-- LeftColumn
//**     |       |   |-- AssocGroup     OpenWithCheck, AlwaysCheck, AssocNote
//**     |       |   |-- StartupGroup   None, Load default model, Load last model
//**     |       |   |-- ThemeGroup     Default @(no theme@), Dark, Aqua, Ruby, Golden Graphite
//**     |       |   `-- ResultsGroup   ResultsEdgeHintCheck
//**     |       `-- RightColumn
//**     |           |-- GrabGroup      GrabSizeCombo; Custom: GrabWidthBox, GrabHeightBox;
//**     |           |                  GrabFolderText, GrabFolderResetButton
//**     |           |-- FrameRateGroup FrameRateTrack, FrameRateValueLabel, FrameRateNote
//**     |           |-- FilesGroup     MinifyJsonCheck, MinifyJsonNote
//**     |           `-- GpuGroup       Windows only: system, low power, high power, GpuNote
//**     `-- ButtonLayout               OkButton, CancelButton
//** )
//**
//** Open With offers Sprite3D for model files in the system's Open With list; Always makes it
//** their default application, and needs Open With, except on macOS, where Open With is set by
//** the app bundle and the box only shows it. Clearing either puts back what was there before,
//** as far as it is still valid. On Android and iOS the group is disabled, as those systems
//** decide such things when the app is built. Grab size sets the size of every off-screen grab:
//** one of the square sizes in GRAB_PRESET_SIZES, or Custom, which lets the width and height be
//** typed, each from GRAB_SIZE_MIN to GRAB_SIZE_MAX pixels; Reset beside the grab folder
//** empties it, so the next grab asks for a folder again. View frame rate sets how many
//** frames a second the view is drawn at, from VIEW_FPS_MIN up to the display's refresh rate,
//** which the caller gives as Values.MaxViewFps; left at the top, a higher rate kept from a
//** faster display stays as it was. The GPU group is shown on Windows only; a
//** change there takes effect the next time Sprite3D starts.
//**
//** The dialog only edits a TSprite3DGeneralSettings: set Values before showing it and read
//** it back after OK; applying the choices is the caller's job. On the desktop show it with
//** ShowModal and free it afterwards; on Android and iOS, which cannot block, show it with
//** ShowAndFree, which calls OnAccept on OK and frees the form when it closes.
unit Sprite3DSettingsForm;

{
  The Settings dialog: file associations, what to load at start-up, the
  theme, the grab size, the view's frame rate and, on Windows, which GPU to
  use.

  A modal form, centred on the main form, laid out in its .fmx file with
  standard FMX controls in groups, in two columns so it stays short enough
  for smaller displays; on Android and iOS, which are too narrow for that,
  the groups go in one column that scrolls:

    TGeneralSettingsForm
    `-- BackPanel                      the form's opaque background
        |-- ScrollBox
        |   `-- ColumnsLayout          as tall as the taller column
        |       |-- LeftColumn
        |       |   |-- AssocGroup     OpenWithCheck, AlwaysCheck, AssocNote
        |       |   |-- StartupGroup   None, Load default model, Load last model
        |       |   |-- ThemeGroup     Default (no theme), Dark, Aqua, Ruby, Golden Graphite
        |       |   `-- ResultsGroup   ResultsEdgeHintCheck
        |       `-- RightColumn
        |           |-- GrabGroup      GrabSizeCombo; Custom: GrabWidthBox, GrabHeightBox;
        |           |                  GrabFolderText, GrabFolderResetButton
        |           |-- FrameRateGroup FrameRateTrack, FrameRateValueLabel, FrameRateNote
        |           |-- FilesGroup     MinifyJsonCheck, MinifyJsonNote
        |           `-- GpuGroup       Windows only: system, low power, high power, GpuNote
        `-- ButtonLayout               OkButton, CancelButton

  Open With offers Sprite3D for model files in the system's Open With list;
  Always makes it their default application, and needs Open With, except on
  macOS, where Open With is set by the app bundle and the box only shows it.
  Clearing either puts back what was there before, as far as it is still
  valid. On Android and iOS the group is disabled, as those systems decide
  such things when the app is built. Grab size sets the size of every
  off-screen grab: one of the square sizes in GRAB_PRESET_SIZES, or Custom,
  which lets the width and height be typed, each from GRAB_SIZE_MIN to
  GRAB_SIZE_MAX pixels; Reset beside the grab folder empties it, so the next
  grab asks for a folder again. View frame rate sets how many frames a second
  the view is drawn at, from VIEW_FPS_MIN up to the display's refresh rate,
  which the caller gives as Values.MaxViewFps; left at the top, a higher
  rate kept from a faster display stays as it was. The GPU group is shown on
  Windows only; a change there takes effect the next time Sprite3D starts.

  The dialog only edits a TSprite3DGeneralSettings: set Values before
  showing it and read it back after OK; applying the choices is the
  caller's job. On the desktop show it with ShowModal and free it
  afterwards; on Android and iOS, which cannot block, show it with
  ShowAndFree, which calls OnAccept on OK and frees the form when it
  closes.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.StdCtrls,
  FMX.Layouts, FMX.Controls.Presentation, FMX.ListBox, FMX.Edit, FMX.EditBox,
  FMX.SpinBox, Sprite3DHelpers;

type
  //** @abstract(The Settings dialog.)
  //**
  //** Set Values before showing it, and read Values back after OK.
  /// <summary>The Settings dialog.</summary>
  /// <remarks>Set Values before showing it, and read Values back after OK.</remarks>
  TGeneralSettingsForm = class(TForm)
    //** @abstract(The form's opaque background.)
    /// <summary>The form's opaque background.</summary>
    BackPanel: TPanel;
    //** @abstract(Scrolls the groups on screens too small for them.)
    /// <summary>Scrolls the groups on screens too small for them.</summary>
    ScrollBox: TVertScrollBox;
    //** @abstract(Holds LeftColumn and RightColumn, as tall as the taller of them.)
    /// <summary>Holds LeftColumn and RightColumn, as tall as the taller of them.</summary>
    ColumnsLayout: TLayout;
    //** @abstract(The left column: AssocGroup, StartupGroup, ThemeGroup and ResultsGroup.)
    //**
    //** On Android and iOS it holds every group, in one column, and RightColumn is hidden.
    /// <summary>The left column: AssocGroup, StartupGroup, ThemeGroup and
    /// ResultsGroup.</summary>
    /// <remarks>On Android and iOS it holds every group, in one column, and RightColumn is
    /// hidden.</remarks>
    LeftColumn: TLayout;
    //** @abstract(The right column: GrabGroup, FrameRateGroup, FilesGroup and GpuGroup.)
    /// <summary>The right column: GrabGroup, FrameRateGroup, FilesGroup and
    /// GpuGroup.</summary>
    RightColumn: TLayout;
    //** @abstract(The file association choices.)
    /// <summary>The file association choices.</summary>
    AssocGroup: TGroupBox;
    //** @abstract(Offers Sprite3D under Open With for model files.)
    /// <summary>Offers Sprite3D under Open With for model files.</summary>
    OpenWithCheck: TCheckBox;
    //** @abstract(Makes Sprite3D the default application for model files.)
    /// <summary>Makes Sprite3D the default application for model files.</summary>
    AlwaysCheck: TCheckBox;
    //** @abstract(Explains what the platform allows.)
    /// <summary>Explains what the platform allows.</summary>
    AssocNote: TLabel;
    //** @abstract(The start-up choices.)
    /// <summary>The start-up choices.</summary>
    StartupGroup: TGroupBox;
    //** @abstract(Start with no model.)
    /// <summary>Start with no model.</summary>
    StartupNoneRadio: TRadioButton;
    //** @abstract(Start with the sample model.)
    /// <summary>Start with the sample model.</summary>
    StartupDefaultRadio: TRadioButton;
    //** @abstract(Start with the model last opened.)
    /// <summary>Start with the model last opened.</summary>
    StartupLastRadio: TRadioButton;
    //** @abstract(The theme choices.)
    /// <summary>The theme choices.</summary>
    ThemeGroup: TGroupBox;
    //** @abstract(FMX's own platform style.)
    /// <summary>FMX's own platform style.</summary>
    ThemeDefaultRadio: TRadioButton;
    //** @abstract(The Dark FMX style.)
    /// <summary>The Dark FMX style.</summary>
    ThemeDarkRadio: TRadioButton;
    //** @abstract(The Aqua Graphite FMX style: dark grey with blue.)
    /// <summary>The Aqua Graphite FMX style: dark grey with blue.</summary>
    ThemeAquaRadio: TRadioButton;
    //** @abstract(The Ruby Graphite FMX style: dark grey with red.)
    /// <summary>The Ruby Graphite FMX style: dark grey with red.</summary>
    ThemeRubyRadio: TRadioButton;
    //** @abstract(The Golden Graphite FMX style: dark grey with gold.)
    /// <summary>The Golden Graphite FMX style: dark grey with gold.</summary>
    ThemeGoldenRadio: TRadioButton;
    //** @abstract(The Results tab's choices.)
    /// <summary>The Results tab's choices.</summary>
    ResultsGroup: TGroupBox;
    //** @abstract(Gives the Results tab's empty border values a hint explaining them.)
    /// <summary>Gives the Results tab's empty border values a hint explaining
    /// them.</summary>
    ResultsEdgeHintCheck: TCheckBox;
    //** @abstract(The GPU choices; Windows only.)
    /// <summary>The GPU choices; Windows only.</summary>
    GpuGroup: TGroupBox;
    //** @abstract(How Sprite3D writes its files.)
    /// <summary>How Sprite3D writes its files.</summary>
    FilesGroup: TGroupBox;
    //** @abstract(Writes every JSON file minified, with no indents or line breaks.)
    /// <summary>Writes every JSON file minified, with no indents or line breaks.</summary>
    MinifyJsonCheck: TCheckBox;
    //** @abstract(Says which files Minify JSON changes.)
    /// <summary>Says which files Minify JSON changes.</summary>
    MinifyJsonNote: TLabel;
    //** @abstract(The view's frame rate.)
    /// <summary>The view's frame rate.</summary>
    FrameRateGroup: TGroupBox;
    //** @abstract(Chooses the view's frame rate, VIEW_FPS_MIN to Values.MaxViewFps.)
    /// <summary>Chooses the view's frame rate, VIEW_FPS_MIN to Values.MaxViewFps.</summary>
    FrameRateTrack: TTrackBar;
    //** @abstract(The frame rate FrameRateTrack is at.)
    /// <summary>The frame rate FrameRateTrack is at.</summary>
    FrameRateValueLabel: TLabel;
    //** @abstract(Says how far the slider goes, and why.)
    /// <summary>Says how far the slider goes, and why.</summary>
    FrameRateNote: TLabel;
    //** @abstract(The off-screen grab size choices.)
    /// <summary>The off-screen grab size choices.</summary>
    GrabGroup: TGroupBox;
    //** @abstract(Chooses a square grab size, or Custom; filled in by FormCreate.)
    /// <summary>Chooses a square grab size, or Custom; filled in by FormCreate.</summary>
    GrabSizeCombo: TComboBox;
    //** @abstract(Holds the custom width and height; enabled for Custom only.)
    /// <summary>Holds the custom width and height; enabled for Custom only.</summary>
    GrabCustomLayout: TLayout;
    //** @abstract(Names GrabWidthBox.)
    /// <summary>Names GrabWidthBox.</summary>
    GrabWidthLabel: TLabel;
    //** @abstract(The custom width, GRAB_SIZE_MIN to GRAB_SIZE_MAX pixels.)
    /// <summary>The custom width, GRAB_SIZE_MIN to GRAB_SIZE_MAX pixels.</summary>
    GrabWidthBox: TSpinBox;
    //** @abstract(Names GrabHeightBox.)
    /// <summary>Names GrabHeightBox.</summary>
    GrabHeightLabel: TLabel;
    //** @abstract(The custom height, GRAB_SIZE_MIN to GRAB_SIZE_MAX pixels.)
    /// <summary>The custom height, GRAB_SIZE_MIN to GRAB_SIZE_MAX pixels.</summary>
    GrabHeightBox: TSpinBox;
    //** @abstract(Names the grab folder.)
    /// <summary>Names the grab folder.</summary>
    GrabFolderLabel: TLabel;
    //** @abstract(The folder File, Grab saves into, or a note that it will be asked for.)
    /// <summary>The folder File, Grab saves into, or a note that it will be asked
    /// for.</summary>
    GrabFolderText: TLabel;
    //** @abstract(Clears the grab folder, so the next grab asks for one.)
    /// <summary>Clears the grab folder, so the next grab asks for one.</summary>
    GrabFolderResetButton: TButton;
    //** @abstract(Let Windows choose the GPU.)
    /// <summary>Let Windows choose the GPU.</summary>
    GpuSystemRadio: TRadioButton;
    //** @abstract(Ask for the low-power GPU.)
    /// <summary>Ask for the low-power GPU.</summary>
    GpuLowRadio: TRadioButton;
    //** @abstract(Ask for the high-performance GPU.)
    /// <summary>Ask for the high-performance GPU.</summary>
    GpuHighRadio: TRadioButton;
    //** @abstract(Says that a GPU change needs a restart.)
    /// <summary>Says that a GPU change needs a restart.</summary>
    GpuNote: TLabel;
    //** @abstract(Holds the OK and Cancel buttons.)
    /// <summary>Holds the OK and Cancel buttons.</summary>
    ButtonLayout: TLayout;
    //** @abstract(Closes the dialog and keeps the choices.)
    /// <summary>Closes the dialog and keeps the choices.</summary>
    OkButton: TButton;
    //** @abstract(Closes the dialog and drops the choices.)
    /// <summary>Closes the dialog and drops the choices.</summary>
    CancelButton: TButton;
    //** @abstract(Sets up the groups for this platform and sizes the form to fit them.)
    //**
    //** @param(Sender The form.)
    /// <summary>Sets up the groups for this platform and sizes the form to fit
    /// them.</summary>
    /// <param name="Sender">The form.</param>
    procedure FormCreate(Sender: TObject);
    //** @abstract(Reports OK when shown with ShowAndFree, and frees the form then.)
    //**
    //** @param(Sender The form.)
    //**
    //** @param(Action Set to caFree when shown with ShowAndFree.)
    /// <summary>Reports OK when shown with ShowAndFree, and frees the form then.</summary>
    /// <param name="Sender">The form.</param>
    /// <param name="Action">Set to caFree when shown with ShowAndFree.</param>
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    //** @abstract(Keeps Always in step with Open With.)
    //**
    //** @param(Sender The check box.)
    /// <summary>Keeps Always in step with Open With.</summary>
    /// <param name="Sender">The check box.</param>
    procedure OpenWithCheckChange(Sender: TObject);
    //** @abstract(Reads the controls into Values on OK, then closes the dialog.)
    //**
    //** @param(Sender The button clicked.)
    /// <summary>Reads the controls into Values on OK, then closes the dialog.</summary>
    /// <param name="Sender">The button clicked.</param>
    procedure ButtonClick(Sender: TObject);
    //** @abstract(Shows a preset's size in the boxes, or enables them for Custom.)
    //**
    //** @param(Sender The drop-down.)
    /// <summary>Shows a preset's size in the boxes, or enables them for Custom.</summary>
    /// <param name="Sender">The drop-down.</param>
    procedure GrabSizeComboChange(Sender: TObject);
    //** @abstract(Shows the frame rate FrameRateTrack is at.)
    //**
    //** @param(Sender FrameRateTrack.)
    /// <summary>Shows the frame rate FrameRateTrack is at.</summary>
    /// <param name="Sender">FrameRateTrack.</param>
    procedure FrameRateTrackChange(Sender: TObject);
    //** @abstract(Clears the grab folder; it takes effect on OK.)
    //**
    //** @param(Sender The button.)
    /// <summary>Clears the grab folder; it takes effect on OK.</summary>
    /// <param name="Sender">The button.</param>
    procedure GrabFolderResetButtonClick(Sender: TObject);
  private
    FValues: TSprite3DGeneralSettings;
    FFreeOnClose: Boolean;
    FOnAccept: TNotifyEvent;
    procedure SetValues(const Value: TSprite3DGeneralSettings);
    procedure ReadControls;
    procedure UpdateAssocControls;
    procedure FitHeight;
    {$IF DEFINED(ANDROID) or DEFINED(IOS)}
    procedure UseOneColumn;
    {$ENDIF}
    function CustomIndex: Integer;
    procedure ShowGrabFolder;
  public
    //** @abstract(Shows the dialog without blocking, for Android and iOS, and frees it when it
    //** closes.)
    //**
    //** OnAccept is called if it closes with OK.
    /// <summary>Shows the dialog without blocking, for Android and iOS, and frees it when it
    /// closes.</summary>
    /// <remarks>OnAccept is called if it closes with OK.</remarks>
    procedure ShowAndFree;
    //** @abstract(The choices being edited.)
    //**
    //** Set it before the dialog is shown; read it after OK.
    /// <summary>The choices being edited.</summary>
    /// <remarks>Set it before the dialog is shown; read it after OK.</remarks>
    property Values: TSprite3DGeneralSettings read FValues write SetValues;
    //** @abstract(Called on OK when shown with ShowAndFree.)
    /// <summary>Called on OK when shown with ShowAndFree.</summary>
    property OnAccept: TNotifyEvent read FOnAccept write FOnAccept;
  end;

implementation

uses
  System.Math, Sprite3DFileAssoc;

{$R *.fmx}

procedure TGeneralSettingsForm.FormCreate(Sender: TObject);
begin
  case TSprite3DFileAssociations.Support of
    asFull:
      AssocNote.Text := 'Clearing a box puts back the application used before, if it is ' +
        'still installed.';
    asDefaultOnly:
      AssocNote.Text := 'Open With comes from the application bundle. Clearing Always ' +
        'puts back the application used before, if it is still installed.';
  else
    AssocNote.Text := 'This system decides which apps open files; choose Sprite3D in its ' +
      'chooser when you open a model.';
    AssocGroup.Enabled := False;
  end;
  {$IF not DEFINED(MSWINDOWS)}
  GpuGroup.Visible := False;
  {$ENDIF}
  {$IF DEFINED(ANDROID) or DEFINED(IOS)}
  // A phone is too narrow for two columns
  UseOneColumn;
  {$ENDIF}

  // The preset sizes, then Custom last
  GrabSizeCombo.Items.Clear;
  for var Size in GRAB_PRESET_SIZES do
    GrabSizeCombo.Items.Add(Format('%d x %d', [Size, Size]));
  GrabSizeCombo.Items.Add('Custom');
  GrabWidthBox.Min := GRAB_SIZE_MIN;
  GrabWidthBox.Max := GRAB_SIZE_MAX;
  GrabWidthBox.Value := GRAB_SIZE_DEFAULT;
  GrabHeightBox.Min := GRAB_SIZE_MIN;
  GrabHeightBox.Max := GRAB_SIZE_MAX;
  GrabHeightBox.Value := GRAB_SIZE_DEFAULT;
  GrabSizeCombo.ItemIndex := GrabSizeCombo.Items.IndexOf(
    Format('%d x %d', [GRAB_SIZE_DEFAULT, GRAB_SIZE_DEFAULT]));

  FitHeight;
end;

{$IF DEFINED(ANDROID) or DEFINED(IOS)}
// Every group in the left column, in the order they were, the right column
// hidden: for screens too narrow for two columns
procedure TGeneralSettingsForm.UseOneColumn;
var
  Groups: TArray<TControl>;
  Y: Single;
begin
  Groups := nil;
  for var I := 0 to RightColumn.ChildrenCount - 1 do
    if RightColumn.Children[I] is TControl then
      Groups := Groups + [TControl(RightColumn.Children[I])];
  // Below the left column's own, in order: top-aligned controls are laid
  // out by their Y
  Y := 10000;
  for var Group in Groups do
  begin
    Group.Parent := LeftColumn;
    Group.Position.Y := Y;
    Y := Y + 1000;
  end;
  RightColumn.Visible := False;
  LeftColumn.Align := TAlignLayout.Client;
end;
{$ENDIF}

// The height of the visible groups in AColumn, with their margins
function ColumnHeight(const AColumn: TControl): Single;
var
  Group: TControl;
begin
  Result := 0;
  if not AColumn.Visible then
    Exit;
  for var I := 0 to AColumn.ChildrenCount - 1 do
    if AColumn.Children[I] is TControl then
    begin
      Group := TControl(AColumn.Children[I]);
      if Group.Visible then
        Result := Result + Group.Height + Group.Margins.Top + Group.Margins.Bottom;
    end;
end;

// The columns as tall as the taller of them, and the form as tall as that
// and the buttons. Mobile forms fill the screen and scroll instead.
procedure TGeneralSettingsForm.FitHeight;
var
  Total: Single;
begin
  ColumnsLayout.Height := Max(ColumnHeight(LeftColumn), ColumnHeight(RightColumn)) + 8;
  Total := ColumnsLayout.Height + ButtonLayout.Height + ButtonLayout.Margins.Top +
    ButtonLayout.Margins.Bottom;
  ClientHeight := Round(Total) + 8;
end;

procedure TGeneralSettingsForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if not FFreeOnClose then
    Exit;   // shown with ShowModal: the caller frees it
  if (ModalResult = mrOk) and Assigned(FOnAccept) then
    FOnAccept(Self);
  Action := TCloseAction.caFree;
end;

procedure TGeneralSettingsForm.ButtonClick(Sender: TObject);
begin
  if Sender = OkButton then
    ReadControls;
  if not FFreeOnClose then
    Exit;   // ShowModal closes the dialog itself
  ModalResult := TButton(Sender).ModalResult;
  Close;
end;

function TGeneralSettingsForm.CustomIndex: Integer;
begin
  Result := GrabSizeCombo.Count - 1;
end;

// The folder as kept, or what happens with none. Values.SaveFolder holds the
// choice; the dialog only empties it.
procedure TGeneralSettingsForm.ShowGrabFolder;
begin
  if FValues.SaveFolder = String.Empty then
    GrabFolderText.Text := '(none: asked for at the next grab)'
  else
    GrabFolderText.Text := FValues.SaveFolder;
  GrabFolderText.Hint := GrabFolderText.Text;
  GrabFolderResetButton.Enabled := FValues.SaveFolder <> String.Empty;
end;

procedure TGeneralSettingsForm.GrabFolderResetButtonClick(Sender: TObject);
begin
  FValues.SaveFolder := String.Empty;
  ShowGrabFolder;
end;

procedure TGeneralSettingsForm.GrabSizeComboChange(Sender: TObject);
var
  Index: Integer;
begin
  Index := GrabSizeCombo.ItemIndex;
  GrabCustomLayout.Enabled := Index = CustomIndex;
  // A preset fills the boxes with its size, so Custom starts from it
  if (Index >= 0) and (Index < CustomIndex) then
  begin
    GrabWidthBox.Value := GRAB_PRESET_SIZES[Index];
    GrabHeightBox.Value := GRAB_PRESET_SIZES[Index];
  end;
end;

procedure TGeneralSettingsForm.OpenWithCheckChange(Sender: TObject);
begin
  UpdateAssocControls;
end;

// Always needs Open With, except where Open With is fixed (macOS); there
// the Open With box only shows the bundle's state
procedure TGeneralSettingsForm.UpdateAssocControls;
begin
  if TSprite3DFileAssociations.Support = asDefaultOnly then
  begin
    OpenWithCheck.Enabled := False;
    AlwaysCheck.Enabled := True;
    Exit;
  end;
  if not OpenWithCheck.IsChecked then
    AlwaysCheck.IsChecked := False;
  AlwaysCheck.Enabled := OpenWithCheck.IsChecked;
end;

procedure TGeneralSettingsForm.SetValues(const Value: TSprite3DGeneralSettings);
begin
  FValues := Value;
  OpenWithCheck.IsChecked := Value.OpenWith;
  AlwaysCheck.IsChecked := Value.AlwaysOpenWith;
  UpdateAssocControls;

  case Value.StartupAction of
    saNone: StartupNoneRadio.IsChecked := True;
    saLastModel: StartupLastRadio.IsChecked := True;
  else
    StartupDefaultRadio.IsChecked := True;
  end;

  case Value.Theme of
    thDark: ThemeDarkRadio.IsChecked := True;
    thAquaGraphite: ThemeAquaRadio.IsChecked := True;
    thRubyGraphite: ThemeRubyRadio.IsChecked := True;
    thGoldenGraphite: ThemeGoldenRadio.IsChecked := True;
  else
    ThemeDefaultRadio.IsChecked := True;
  end;

  // A square preset size picks its entry; anything else is Custom
  GrabSizeCombo.ItemIndex := CustomIndex;
  if Value.GrabWidth = Value.GrabHeight then
    for var I := Low(GRAB_PRESET_SIZES) to High(GRAB_PRESET_SIZES) do
      if GRAB_PRESET_SIZES[I] = Value.GrabWidth then
        GrabSizeCombo.ItemIndex := I;
  GrabWidthBox.Value := Value.GrabWidth;
  GrabHeightBox.Value := Value.GrabHeight;
  GrabCustomLayout.Enabled := GrabSizeCombo.ItemIndex = CustomIndex;
  ShowGrabFolder;

  // Up to the display's refresh rate; a rate kept from a faster display is
  // brought down to it
  FrameRateTrack.Min := VIEW_FPS_MIN;
  FrameRateTrack.Max := Max(VIEW_FPS_MIN, Value.MaxViewFps);
  FrameRateTrack.Value := EnsureRange(Value.ViewFps, VIEW_FPS_MIN, Round(FrameRateTrack.Max));
  FrameRateNote.Text := Format('From %d up to %d, the display''s refresh rate.',
    [VIEW_FPS_MIN, Round(FrameRateTrack.Max)]);
  FrameRateTrackChange(FrameRateTrack);

  MinifyJsonCheck.IsChecked := Value.MinifyJson;
  ResultsEdgeHintCheck.IsChecked := Value.ResultsEdgeHint;

  case Value.GpuMode of
    gmPowerSaving: GpuLowRadio.IsChecked := True;
    gmHighPerformance: GpuHighRadio.IsChecked := True;
  else
    GpuSystemRadio.IsChecked := True;
  end;
end;

procedure TGeneralSettingsForm.ReadControls;
begin
  if AssocGroup.Enabled then
  begin
    FValues.OpenWith := OpenWithCheck.IsChecked;
    FValues.AlwaysOpenWith := AlwaysCheck.IsChecked;
  end;

  if StartupNoneRadio.IsChecked then
    FValues.StartupAction := saNone
  else if StartupLastRadio.IsChecked then
    FValues.StartupAction := saLastModel
  else
    FValues.StartupAction := saDefaultModel;

  if ThemeDarkRadio.IsChecked then
    FValues.Theme := thDark
  else if ThemeAquaRadio.IsChecked then
    FValues.Theme := thAquaGraphite
  else if ThemeRubyRadio.IsChecked then
    FValues.Theme := thRubyGraphite
  else if ThemeGoldenRadio.IsChecked then
    FValues.Theme := thGoldenGraphite
  else
    FValues.Theme := thDefault;

  // The boxes always hold the size: a preset's, or the custom one
  FValues.GrabWidth := EnsureRange(Round(GrabWidthBox.Value), GRAB_SIZE_MIN, GRAB_SIZE_MAX);
  FValues.GrabHeight := EnsureRange(Round(GrabHeightBox.Value), GRAB_SIZE_MIN, GRAB_SIZE_MAX);

  // Left at the top, a higher rate asked for on a faster display is kept,
  // to be used there again; the caller keeps the view within this display
  if (Round(FrameRateTrack.Value) < Round(FrameRateTrack.Max)) or
    (FValues.ViewFps < Round(FrameRateTrack.Max)) then
    FValues.ViewFps := EnsureRange(Round(FrameRateTrack.Value), VIEW_FPS_MIN,
      Max(VIEW_FPS_MIN, FValues.MaxViewFps));

  FValues.MinifyJson := MinifyJsonCheck.IsChecked;
  FValues.ResultsEdgeHint := ResultsEdgeHintCheck.IsChecked;

  if GpuGroup.Visible then
  begin
    if GpuLowRadio.IsChecked then
      FValues.GpuMode := gmPowerSaving
    else if GpuHighRadio.IsChecked then
      FValues.GpuMode := gmHighPerformance
    else
      FValues.GpuMode := gmSystem;
  end;
end;

procedure TGeneralSettingsForm.FrameRateTrackChange(Sender: TObject);
begin
  FrameRateValueLabel.Text := IntToStr(Round(FrameRateTrack.Value));
end;

procedure TGeneralSettingsForm.ShowAndFree;
begin
  FFreeOnClose := True;
  Show;
end;

end.
