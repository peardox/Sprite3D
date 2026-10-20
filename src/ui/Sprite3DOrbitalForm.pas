//** @abstract(The Variable camera dialog: dials for the camera's angles, a distance slider and
//** an optional pan.)
//**
//** Three dials set Azimuth, Inclination and Roll, whose readouts show whole degrees and,
//** beside the Roll dial, the same three angles to six decimal places; a slider moves the
//** camera out from the fitted distance, and, below them, the Pan box switches on two sliders
//** that move the view along the model's own X and Z axes, the directions that are not the
//** model's up. Pan is off by default and is meant for the odd case where the model should sit
//** off centre; it moves the point the camera orbits, on top of the fit, and leaves the angles
//** and the distance alone. Centre puts both sliders back to 0.
//**
//** The dialog only edits a TCameraSettings. It never touches the camera itself: each change
//** calls OnPreview, so the owner can show it at once, and the owner keeps or undoes the
//** change when the dialog closes. On the desktop show it with ShowModal and free it
//** afterwards; on Android and iOS, which cannot block, show it with ShowAndFree, which calls
//** OnAccept on OK, OnCancel otherwise, and frees the form when it closes.
//**
//** @preformatted(
//** TOrbitalSettingsForm
//** |-- Layout1
//** |   `-- OrbitalLayout
//** |       |-- AzimuthDial, AngleDial, RollDial   with their labels and readouts
//** |       |-- ExactLayout          the three angles to six decimal places
//** |       |-- PanLayout
//** |       |   |-- PanTopLayout     PanCheck, PanResetButton
//** |       |   |-- PanXLayout       PanXLabel, PanXTrack
//** |       |   `-- PanZLayout       PanZLabel, PanZTrack
//** |       `-- DistanceLayout       DistanceLabel, DistanceTrack
//** `-- Layout2                      CancelButton, OkButton
//** )
unit Sprite3DOrbitalForm;

{
  The Variable camera dialog: dials for the camera's angles, a distance
  slider and an optional pan.

  Three dials set Azimuth, Inclination and Roll, whose readouts show whole
  degrees and, beside the Roll dial, the same three angles to six decimal
  places; a slider moves the camera out from the fitted distance, and, below
  them, the Pan box switches on two sliders that move the view along the
  model's own X and Z axes, the directions that are not the model's up. Pan
  is off by default and is meant for the odd case where the model should sit
  off centre; it moves the point the camera orbits, on top of the fit, and
  leaves the angles and the distance alone. Centre puts both sliders back to
  0.

  The dialog only edits a TCameraSettings. It never touches the camera
  itself: each change calls OnPreview, so the owner can show it at once,
  and the owner keeps or undoes the change when the dialog closes. On the
  desktop show it with ShowModal and free it afterwards; on Android and
  iOS, which cannot block, show it with ShowAndFree, which calls OnAccept
  on OK, OnCancel otherwise, and frees the form when it closes.

    TOrbitalSettingsForm
    |-- Layout1
    |   `-- OrbitalLayout
    |       |-- AzimuthDial, AngleDial, RollDial   with their labels and readouts
    |       |-- ExactLayout          the three angles to six decimal places
    |       |-- PanLayout
    |       |   |-- PanTopLayout     PanCheck, PanResetButton
    |       |   |-- PanXLayout       PanXLabel, PanXTrack
    |       |   `-- PanZLayout       PanZLabel, PanZTrack
    |       `-- DistanceLayout       DistanceLabel, DistanceTrack
    `-- Layout2                      CancelButton, OkButton
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Layouts;

type
  //** @abstract(Everything the Variable camera dialog edits.)
  /// <summary>Everything the Variable camera dialog edits.</summary>
  TCameraSettings = record
    //** @abstract(The Azimuth readout, in degrees, 0 to 360.)
    /// <summary>The Azimuth readout, in degrees, 0 to 360.</summary>
    Azimuth: Single;
    //** @abstract(The Roll readout, in degrees, 0 to 360.)
    /// <summary>The Roll readout, in degrees, 0 to 360.</summary>
    Roll: Single;
    //** @abstract(The Inclination readout, in degrees, 0 to 360.)
    /// <summary>The Inclination readout, in degrees, 0 to 360.</summary>
    PolarAngle: Single;
    //** @abstract(How far the camera is moved out from the fitted distance, 1 to 20.)
    /// <summary>How far the camera is moved out from the fitted distance, 1 to 20.</summary>
    Distance: Single;
    //** @abstract(Whether the pan is applied.)
    /// <summary>Whether the pan is applied.</summary>
    PanEnabled: Boolean;
    //** @abstract(The pan along the model's X axis, as a multiple of its radius.)
    /// <summary>The pan along the model's X axis, as a multiple of its radius.</summary>
    PanX: Single;
    //** @abstract(The pan along the model's Z axis, as a multiple of its radius.)
    /// <summary>The pan along the model's Z axis, as a multiple of its radius.</summary>
    PanZ: Single;
  end;

  //** @abstract(The Variable camera dialog.)
  //**
  //** Set CameraSpec and OnPreview before showing it, and read CameraSpec back after OK.
  /// <summary>The Variable camera dialog.</summary>
  /// <remarks>Set CameraSpec and OnPreview before showing it, and read CameraSpec back after
  /// OK.</remarks>
  TOrbitalSettingsForm = class(TForm)
    //** @abstract(Holds everything above the buttons.)
    /// <summary>Holds everything above the buttons.</summary>
    Layout1: TLayout;
    //** @abstract(Holds the OK and Cancel buttons.)
    /// <summary>Holds the OK and Cancel buttons.</summary>
    Layout2: TLayout;
    //** @abstract(Holds the dials, the pan and the distance slider.)
    /// <summary>Holds the dials, the pan and the distance slider.</summary>
    OrbitalLayout: TLayout;
    //** @abstract(Sets the inclination.)
    /// <summary>Sets the inclination.</summary>
    AngleDial: TArcDial;
    //** @abstract(Names the inclination dial.)
    /// <summary>Names the inclination dial.</summary>
    AngleLabel: TLabel;
    //** @abstract(Shows the inclination in degrees.)
    /// <summary>Shows the inclination in degrees.</summary>
    AngleText: TLabel;
    //** @abstract(Sets the azimuth.)
    /// <summary>Sets the azimuth.</summary>
    AzimuthDial: TArcDial;
    //** @abstract(Names the azimuth dial.)
    /// <summary>Names the azimuth dial.</summary>
    AzimuthLabel: TLabel;
    //** @abstract(Shows the azimuth in degrees.)
    /// <summary>Shows the azimuth in degrees.</summary>
    AzimuthText: TLabel;
    //** @abstract(Sets the roll.)
    /// <summary>Sets the roll.</summary>
    RollDial: TArcDial;
    //** @abstract(Names the roll dial.)
    /// <summary>Names the roll dial.</summary>
    RollLabel: TLabel;
    //** @abstract(Shows the roll in degrees.)
    /// <summary>Shows the roll in degrees.</summary>
    RollText: TLabel;
    //** @abstract(Holds the exact angles, right of the Roll dial.)
    /// <summary>Holds the exact angles, right of the Roll dial.</summary>
    ExactLayout: TLayout;
    //** @abstract(Names AzimuthExactText.)
    /// <summary>Names AzimuthExactText.</summary>
    AzimuthExactLabel: TLabel;
    //** @abstract(The azimuth in degrees to six decimal places.)
    /// <summary>The azimuth in degrees to six decimal places.</summary>
    AzimuthExactText: TLabel;
    //** @abstract(Names AngleExactText.)
    /// <summary>Names AngleExactText.</summary>
    AngleExactLabel: TLabel;
    //** @abstract(The inclination in degrees to six decimal places.)
    /// <summary>The inclination in degrees to six decimal places.</summary>
    AngleExactText: TLabel;
    //** @abstract(Names RollExactText.)
    /// <summary>Names RollExactText.</summary>
    RollExactLabel: TLabel;
    //** @abstract(The roll in degrees to six decimal places.)
    /// <summary>The roll in degrees to six decimal places.</summary>
    RollExactText: TLabel;
    //** @abstract(Holds the pan's controls.)
    /// <summary>Holds the pan's controls.</summary>
    PanLayout: TLayout;
    //** @abstract(Holds PanCheck and PanResetButton.)
    /// <summary>Holds PanCheck and PanResetButton.</summary>
    PanTopLayout: TLayout;
    //** @abstract(Switches the pan on or off; off by default.)
    /// <summary>Switches the pan on or off; off by default.</summary>
    PanCheck: TCheckBox;
    //** @abstract(Puts both pan sliders back to 0.)
    /// <summary>Puts both pan sliders back to 0.</summary>
    PanResetButton: TButton;
    //** @abstract(Holds the X pan slider and its label.)
    /// <summary>Holds the X pan slider and its label.</summary>
    PanXLayout: TLayout;
    //** @abstract(Shows the X pan.)
    /// <summary>Shows the X pan.</summary>
    PanXLabel: TLabel;
    //** @abstract(Sets the pan along the model's X axis.)
    /// <summary>Sets the pan along the model's X axis.</summary>
    PanXTrack: TTrackBar;
    //** @abstract(Holds the Z pan slider and its label.)
    /// <summary>Holds the Z pan slider and its label.</summary>
    PanZLayout: TLayout;
    //** @abstract(Shows the Z pan.)
    /// <summary>Shows the Z pan.</summary>
    PanZLabel: TLabel;
    //** @abstract(Sets the pan along the model's Z axis.)
    /// <summary>Sets the pan along the model's Z axis.</summary>
    PanZTrack: TTrackBar;
    //** @abstract(Holds the distance slider and its label.)
    /// <summary>Holds the distance slider and its label.</summary>
    DistanceLayout: TLayout;
    //** @abstract(Shows the distance factor.)
    /// <summary>Shows the distance factor.</summary>
    DistanceLabel: TLabel;
    //** @abstract(Sets the distance factor, 1 to 20.)
    /// <summary>Sets the distance factor, 1 to 20.</summary>
    DistanceTrack: TTrackBar;
    //** @abstract(Closes the dialog and drops the changes.)
    /// <summary>Closes the dialog and drops the changes.</summary>
    CancelButton: TButton;
    //** @abstract(Closes the dialog and keeps the changes.)
    /// <summary>Closes the dialog and keeps the changes.</summary>
    OkButton: TButton;
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
    //** @abstract(Closes the dialog with the button's result.)
    //**
    //** @param(Sender The button clicked.)
    /// <summary>Closes the dialog with the button's result.</summary>
    /// <param name="Sender">The button clicked.</param>
    procedure ButtonClick(Sender: TObject);
    //** @abstract(Takes the azimuth from its dial.)
    //**
    //** @param(Sender The dial.)
    /// <summary>Takes the azimuth from its dial.</summary>
    /// <param name="Sender">The dial.</param>
    procedure AzimuthDialChange(Sender: TObject);
    //** @abstract(Takes the inclination from its dial.)
    //**
    //** @param(Sender The dial.)
    /// <summary>Takes the inclination from its dial.</summary>
    /// <param name="Sender">The dial.</param>
    procedure AngleDialChange(Sender: TObject);
    //** @abstract(Takes the roll from its dial.)
    //**
    //** @param(Sender The dial.)
    /// <summary>Takes the roll from its dial.</summary>
    /// <param name="Sender">The dial.</param>
    procedure RollDialChange(Sender: TObject);
    //** @abstract(Sets every control from CameraSpec.)
    //**
    //** @param(Sender The form.)
    /// <summary>Sets every control from CameraSpec.</summary>
    /// <param name="Sender">The form.</param>
    procedure FormShow(Sender: TObject);
    //** @abstract(Takes the distance factor from its slider.)
    //**
    //** @param(Sender The slider.)
    /// <summary>Takes the distance factor from its slider.</summary>
    /// <param name="Sender">The slider.</param>
    procedure DistanceTrackChange(Sender: TObject);
    //** @abstract(Switches the pan on or off.)
    //**
    //** @param(Sender The check box.)
    /// <summary>Switches the pan on or off.</summary>
    /// <param name="Sender">The check box.</param>
    procedure PanCheckChange(Sender: TObject);
    //** @abstract(Takes the pan from both sliders.)
    //**
    //** @param(Sender The slider moved.)
    /// <summary>Takes the pan from both sliders.</summary>
    /// <param name="Sender">The slider moved.</param>
    procedure PanTrackChange(Sender: TObject);
    //** @abstract(Puts both pan sliders back to 0.)
    //**
    //** @param(Sender The button.)
    /// <summary>Puts both pan sliders back to 0.</summary>
    /// <param name="Sender">The button.</param>
    procedure PanResetButtonClick(Sender: TObject);
  strict private
    FFreeOnClose: Boolean;
    FUpdating: Boolean;   // set while code sets the controls, to hold back previews
    FOnAccept: TNotifyEvent;
    FOnCancel: TNotifyEvent;
    FOnPreview: TNotifyEvent;
    FCameraSettings: TCameraSettings;
    procedure SetSpec(const ASettings: TCameraSettings);
    procedure ShowReadouts;
    procedure UpdatePanControls;
    procedure Preview;
  public
    //** @abstract(Shows the dialog without blocking, for Android and iOS, and frees it when it
    //** closes.)
    //**
    //** OnAccept is called if it closes with OK, OnCancel otherwise.
    /// <summary>Shows the dialog without blocking, for Android and iOS, and frees it when it
    /// closes.</summary>
    /// <remarks>OnAccept is called if it closes with OK, OnCancel otherwise.</remarks>
    procedure ShowAndFree;
    //** @abstract(Called on OK when shown with ShowAndFree.)
    /// <summary>Called on OK when shown with ShowAndFree.</summary>
    property OnAccept: TNotifyEvent read FOnAccept write FOnAccept;
    //** @abstract(Called on Cancel, or any close but OK, when shown with ShowAndFree.)
    /// <summary>Called on Cancel, or any close but OK, when shown with ShowAndFree.</summary>
    property OnCancel: TNotifyEvent read FOnCancel write FOnCancel;
    //** @abstract(Called after every change, with the dialog as Sender, so the owner can show
    //** CameraSpec at once.)
    /// <summary>Called after every change, with the dialog as Sender, so the owner can show
    /// CameraSpec at once.</summary>
    property OnPreview: TNotifyEvent read FOnPreview write FOnPreview;
    //** @abstract(The settings being edited.)
    //**
    //** Set it before the dialog is shown; read it after OK.
    /// <summary>The settings being edited.</summary>
    /// <remarks>Set it before the dialog is shown; read it after OK.</remarks>
    property CameraSpec: TCameraSettings read FCameraSettings write SetSpec;
  end;

var
  //** @abstract(The instance the project file creates; the main form makes its own.)
  /// <summary>The instance the project file creates; the main form makes its own.</summary>
  OrbitalSettingsForm: TOrbitalSettingsForm;

implementation

{$R *.fmx}

uses
  System.Math, Sprite3DHelpers;

// An angle from 0 to 360 as the same direction from -180 to 180: above 180
// it counts back from 360, so 359 is -1
function Signed180(const ADegrees: Single): Single;
begin
  Result := Wrap360(ADegrees);
  if Result > 180 then
    Result := Result - 360;
end;

// Shows AText in a dial's readout, which covers its dial exactly and centres
// its text on the dial's middle. The text is never trimmed: the font starts
// at the readout's full size and steps down only while the text is too wide,
// as a sign makes -100 and beyond.
procedure ShowReadout(const ALabel: TLabel; const AText: String);
const
  FULL_SIZE = 72;
  SMALLEST_SIZE = 24;
  SIDE_ROOM = 8;   // pixels kept clear at the edges, so the text stays inside
var
  Canvas: TCanvas;
  Size: Single;
begin
  ALabel.Text := AText;
  Canvas := TCanvasManager.MeasureCanvas;
  Size := FULL_SIZE;
  Canvas.Font.Assign(ALabel.TextSettings.Font);
  Canvas.Font.Size := Size;
  while (Size > SMALLEST_SIZE) and
    (Canvas.TextWidth(AText) > ALabel.Width - 2 * SIDE_ROOM) do
  begin
    Size := Size - 2;
    Canvas.Font.Size := Size;
  end;
  ALabel.TextSettings.Font.Size := Size;
end;

// An angle in degrees to six decimal places, with the degree sign
function ExactDegreesText(const ADegrees: Single): String;
begin
  Result := FormatFloat('0.000000', ADegrees) + #$00B0;
end;

procedure TOrbitalSettingsForm.ButtonClick(Sender: TObject);
begin
  if not FFreeOnClose then
    Exit;   // ShowModal closes the dialog itself
  ModalResult := TButton(Sender).ModalResult;
  Close;
end;

procedure TOrbitalSettingsForm.RollDialChange(Sender: TObject);
begin
  // Negated like the other two dials, so the angle grows clockwise
  FCameraSettings.Roll := Wrap360(-RollDial.Value);
  ShowReadouts;
  Preview;
end;

procedure TOrbitalSettingsForm.AngleDialChange(Sender: TObject);
begin
  FCameraSettings.PolarAngle := Wrap360(-AngleDial.Value);
  ShowReadouts;
  Preview;
end;

procedure TOrbitalSettingsForm.AzimuthDialChange(Sender: TObject);
begin
  FCameraSettings.Azimuth := Wrap360(-AzimuthDial.Value);
  ShowReadouts;
  Preview;
end;

procedure TOrbitalSettingsForm.DistanceTrackChange(Sender: TObject);
begin
  FCameraSettings.Distance := DistanceTrack.Value;
  ShowReadouts;
  Preview;
end;

procedure TOrbitalSettingsForm.PanCheckChange(Sender: TObject);
begin
  FCameraSettings.PanEnabled := PanCheck.IsChecked;
  UpdatePanControls;
  Preview;
end;

procedure TOrbitalSettingsForm.PanTrackChange(Sender: TObject);
begin
  FCameraSettings.PanX := PanXTrack.Value;
  FCameraSettings.PanZ := PanZTrack.Value;
  ShowReadouts;
  Preview;
end;

procedure TOrbitalSettingsForm.PanResetButtonClick(Sender: TObject);
begin
  FUpdating := True;
  try
    PanXTrack.Value := 0;
    PanZTrack.Value := 0;
  finally
    FUpdating := False;
  end;
  PanTrackChange(Sender);
end;

procedure TOrbitalSettingsForm.FormClose(Sender: TObject;
  var Action: TCloseAction);
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

procedure TOrbitalSettingsForm.FormShow(Sender: TObject);
var
  Spec: TCameraSettings;
begin
  // Setting a control's value fires its OnChange, which reads the value
  // back; work from a copy so the angles round-trip exactly
  Spec := FCameraSettings;
  FUpdating := True;
  try
    AzimuthDial.Value := Wrap360(-Spec.Azimuth);
    RollDial.Value := Wrap360(-Spec.Roll);
    AngleDial.Value := Wrap360(-Spec.PolarAngle);
    DistanceTrack.Value := Spec.Distance;
    PanXTrack.Min := -PAN_LIMIT;
    PanXTrack.Max := PAN_LIMIT;
    PanZTrack.Min := -PAN_LIMIT;
    PanZTrack.Max := PAN_LIMIT;
    PanXTrack.Value := EnsureRange(Spec.PanX, -PAN_LIMIT, PAN_LIMIT);
    PanZTrack.Value := EnsureRange(Spec.PanZ, -PAN_LIMIT, PAN_LIMIT);
    PanCheck.IsChecked := Spec.PanEnabled;
  finally
    FUpdating := False;
  end;
  FCameraSettings := Spec;
  FCameraSettings.PanX := PanXTrack.Value;
  FCameraSettings.PanZ := PanZTrack.Value;
  ShowReadouts;
  UpdatePanControls;
end;

procedure TOrbitalSettingsForm.SetSpec(const ASettings: TCameraSettings);
begin
  FCameraSettings := ASettings;
end;

procedure TOrbitalSettingsForm.ShowAndFree;
begin
  FFreeOnClose := True;
  Show;
end;

procedure TOrbitalSettingsForm.ShowReadouts;
begin
  // Trimmed: DegreesText pads to three places, which would push a short
  // number off the dial's centre
  ShowReadout(AzimuthText, Trim(DegreesText(FCameraSettings.Azimuth)));
  // Inclination reads as -180 to 180, so just below level is -1, not 359
  ShowReadout(AngleText, Trim(DegreesText(Signed180(FCameraSettings.PolarAngle))));
  ShowReadout(RollText, Trim(DegreesText(FCameraSettings.Roll)));
  // The same angles in full, as the camera gets them
  AzimuthExactText.Text := ExactDegreesText(FCameraSettings.Azimuth);
  AngleExactText.Text := ExactDegreesText(Signed180(FCameraSettings.PolarAngle));
  RollExactText.Text := ExactDegreesText(FCameraSettings.Roll);
  DistanceLabel.Text := Format('Distance x%.1f', [FCameraSettings.Distance]);
  PanXLabel.Text := Format('X %+.2f', [FCameraSettings.PanX]);
  PanZLabel.Text := Format('Z %+.2f', [FCameraSettings.PanZ]);
end;

// The sliders keep their values while the pan is off, so switching it back
// on returns to the same place
procedure TOrbitalSettingsForm.UpdatePanControls;
begin
  PanXLayout.Enabled := FCameraSettings.PanEnabled;
  PanZLayout.Enabled := FCameraSettings.PanEnabled;
  PanResetButton.Enabled := FCameraSettings.PanEnabled;
end;

procedure TOrbitalSettingsForm.Preview;
begin
  if not FUpdating and Assigned(FOnPreview) then
    FOnPreview(Self);
end;

end.
