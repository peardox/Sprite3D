//** @abstract(The Camera dialog: three dials and a distance slider that move the camera
//** live.)
//**
//** A small modal form, laid out in its .fmx file with standard FMX controls. The Azimuth,
//** Inclination and Roll dials turn the camera round the model, and the Distance slider
//** moves it out from the distance the model was fitted at, x1 to x20, so it can never come
//** closer than the fit and end up inside the model. Every change is shown at once on the
//** camera given in Camera, as a live preview. OK keeps the result; Cancel, Esc or closing
//** the window puts the camera back as it was when the dialog opened.
//**
//** The dialog only edits a TCameraSettings: set CameraSpec, Camera, FitDistance and
//** FitOrthoHeight before showing it and read CameraSpec back after OK. On the desktop show
//** it with ShowModal and free it afterwards; on Android and iOS, which cannot block, show it
//** with ShowAndFree, which calls OnAccept on OK and frees the form when it closes.
//**
//** @preformatted(
//** TOrbitalSettingsForm
//** |-- Layout1
//** |   `-- OrbitalLayout
//** |       |-- AzimuthDial, AzimuthText, AzimuthLabel
//** |       |-- AngleDial, AngleText, AngleLabel      inclination
//** |       |-- RollDial, RollText, RollLabel
//** |       `-- DistanceLayout: DistanceLabel, DistanceTrack
//** `-- Layout2: CancelButton, OkButton
//** )
unit Sprite3DOrbitalForm;

{
  The Camera dialog: three dials and a distance slider that move the camera
  live.

  A small modal form, laid out in its .fmx file with standard FMX controls.
  The Azimuth, Inclination and Roll dials turn the camera round the model,
  and the Distance slider moves it out from the distance the model was
  fitted at, x1 to x20, so it can never come closer than the fit and end up
  inside the model. Every change is shown at once on the camera given in
  Camera, as a live preview. OK keeps the result; Cancel, Esc or closing the
  window puts the camera back as it was when the dialog opened.

  The dialog only edits a TCameraSettings: set CameraSpec, Camera,
  FitDistance and FitOrthoHeight before showing it and read CameraSpec back
  after OK. On the desktop show it with ShowModal and free it afterwards; on
  Android and iOS, which cannot block, show it with ShowAndFree, which calls
  OnAccept on OK and frees the form when it closes.

    TOrbitalSettingsForm
    |-- Layout1
    |   `-- OrbitalLayout
    |       |-- AzimuthDial, AzimuthText, AzimuthLabel
    |       |-- AngleDial, AngleText, AngleLabel      inclination
    |       |-- RollDial, RollText, RollLabel
    |       `-- DistanceLayout: DistanceLabel, DistanceTrack
    `-- Layout2: CancelButton, OkButton
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Layouts, Sprite3DCamera;

type
  //** @abstract(The camera angles and distance the Camera dialog edits.)
  //**
  //** Angles are as the dials' readouts show them, in degrees from 0 to 359. Azimuth goes to
  //** the camera reversed, 360 minus the readout, so the view turns the right way for the
  //** dial.
  /// <summary>The camera angles and distance the Camera dialog edits.</summary>
  /// <remarks>Angles are as the dials' readouts show them, in degrees from 0 to 359. Azimuth
  /// goes to the camera reversed, 360 minus the readout, so the view turns the right way for
  /// the dial.</remarks>
  TCameraSettings = record
    //** @abstract(The Azimuth readout, in degrees.)
    /// <summary>The Azimuth readout, in degrees.</summary>
    Azimuth: Single;
    //** @abstract(The Roll readout, in degrees.)
    /// <summary>The Roll readout, in degrees.</summary>
    Roll: Single;
    //** @abstract(The Inclination readout, the camera's PolarAngle, in degrees.)
    /// <summary>The Inclination readout, the camera's PolarAngle, in degrees.</summary>
    PolarAngle: Single;
    //** @abstract(How far out from the fitted view the camera is, x1 to x20.)
    //**
    //** In perspective it multiplies the fitted distance; in orthographic projection, the
    //** fitted view height. 1 is the fit itself; values below 1 count as 1.
    /// <summary>How far out from the fitted view the camera is, x1 to x20.</summary>
    /// <remarks>In perspective it multiplies the fitted distance; in orthographic projection,
    /// the fitted view height. 1 is the fit itself; values below 1 count as 1.</remarks>
    DistanceFactor: Single;
  end;

  //** @abstract(The Camera dialog; edits a TCameraSettings with a live preview.)
  //**
  //** Create it and set CameraSpec, Camera, FitDistance and FitOrthoHeight. On the desktop,
  //** call ShowModal and, if it returns mrOk, read CameraSpec, then free the form; on any
  //** other result the camera has already been put back. Where ShowModal cannot block, as on
  //** Android and iOS, set OnAccept and call ShowAndFree instead.
  /// <summary>The Camera dialog; edits a TCameraSettings with a live preview.</summary>
  /// <remarks>Create it and set CameraSpec, Camera, FitDistance and FitOrthoHeight. On the
  /// desktop, call ShowModal and, if it returns mrOk, read CameraSpec, then free the form; on
  /// any other result the camera has already been put back. Where ShowModal cannot block, as
  /// on Android and iOS, set OnAccept and call ShowAndFree instead.</remarks>
  TOrbitalSettingsForm = class(TForm)
    //** @abstract(Fills the form above the buttons; holds OrbitalLayout.)
    /// <summary>Fills the form above the buttons; holds OrbitalLayout.</summary>
    Layout1: TLayout;
    //** @abstract(The strip along the bottom holding CancelButton and OkButton.)
    /// <summary>The strip along the bottom holding CancelButton and OkButton.</summary>
    Layout2: TLayout;
    //** @abstract(Holds the dials, their readouts and labels, and DistanceLayout.)
    /// <summary>Holds the dials, their readouts and labels, and DistanceLayout.</summary>
    OrbitalLayout: TLayout;
    //** @abstract(Sets the inclination, the camera's PolarAngle; see AngleDialChange.)
    /// <summary>Sets the inclination, the camera's PolarAngle; see
    /// <see cref="AngleDialChange"/>.</summary>
    AngleDial: TArcDial;
    //** @abstract(The caption "Inclination" under AngleDial.)
    /// <summary>The caption "Inclination" under AngleDial.</summary>
    AngleLabel: TLabel;
    //** @abstract(Shows the inclination in whole degrees.)
    /// <summary>Shows the inclination in whole degrees.</summary>
    AngleText: TLabel;
    //** @abstract(Sets the camera's Azimuth; see AzimuthDialChange.)
    /// <summary>Sets the camera's Azimuth; see <see cref="AzimuthDialChange"/>.</summary>
    AzimuthDial: TArcDial;
    //** @abstract(The caption "Azimuth" under AzimuthDial.)
    /// <summary>The caption "Azimuth" under AzimuthDial.</summary>
    AzimuthLabel: TLabel;
    //** @abstract(Shows the azimuth in whole degrees.)
    /// <summary>Shows the azimuth in whole degrees.</summary>
    AzimuthText: TLabel;
    //** @abstract(Sets the camera's Roll; see RollDialChange.)
    /// <summary>Sets the camera's Roll; see <see cref="RollDialChange"/>.</summary>
    RollDial: TArcDial;
    //** @abstract(The caption "Roll" under RollDial.)
    /// <summary>The caption "Roll" under RollDial.</summary>
    RollLabel: TLabel;
    //** @abstract(Shows the roll in whole degrees.)
    /// <summary>Shows the roll in whole degrees.</summary>
    RollText: TLabel;
    //** @abstract(The strip holding DistanceLabel and DistanceTrack.)
    /// <summary>The strip holding DistanceLabel and DistanceTrack.</summary>
    DistanceLayout: TLayout;
    //** @abstract(Shows the distance factor, as "Distance x1.0".)
    /// <summary>Shows the distance factor, as "Distance x1.0".</summary>
    DistanceLabel: TLabel;
    //** @abstract(Sets the distance factor, x1 to x20; see DistanceTrackChange.)
    /// <summary>Sets the distance factor, x1 to x20; see
    /// <see cref="DistanceTrackChange"/>.</summary>
    DistanceTrack: TTrackBar;
    //** @abstract(Closes the dialog with mrCancel, putting the camera back; also Esc.)
    /// <summary>Closes the dialog with mrCancel, putting the camera back; also
    /// Esc.</summary>
    CancelButton: TButton;
    //** @abstract(Closes the dialog with mrOk, keeping the camera as it is; also Enter.)
    /// <summary>Closes the dialog with mrOk, keeping the camera as it is; also
    /// Enter.</summary>
    OkButton: TButton;
    //** @abstract(Puts the camera back unless the dialog closed with OK; after ShowAndFree,
    //** also calls OnAccept on OK and frees the form.)
    //**
    //** @param(Sender The form.)
    //**
    //** @param(Action Set to caFree after ShowAndFree.)
    /// <summary>Puts the camera back unless the dialog closed with OK; after ShowAndFree,
    /// also calls OnAccept on OK and frees the form.</summary>
    /// <param name="Sender">The form.</param>
    /// <param name="Action">Set to caFree after ShowAndFree.</param>
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    //** @abstract(Turns the dials and slider to CameraSpec and remembers it, to put back on
    //** Cancel.)
    //**
    //** @param(Sender The form.)
    /// <summary>Turns the dials and slider to CameraSpec and remembers it, to put back on
    /// Cancel.</summary>
    /// <param name="Sender">The form.</param>
    procedure FormShow(Sender: TObject);
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
    //** @abstract(Takes AzimuthDial's angle and shows it on the camera.)
    //**
    //** @param(Sender AzimuthDial.)
    /// <summary>Takes AzimuthDial's angle and shows it on the camera.</summary>
    /// <param name="Sender">AzimuthDial.</param>
    procedure AzimuthDialChange(Sender: TObject);
    //** @abstract(Takes AngleDial's angle and shows it on the camera.)
    //**
    //** @param(Sender AngleDial.)
    /// <summary>Takes AngleDial's angle and shows it on the camera.</summary>
    /// <param name="Sender">AngleDial.</param>
    procedure AngleDialChange(Sender: TObject);
    //** @abstract(Takes RollDial's angle and shows it on the camera.)
    //**
    //** @param(Sender RollDial.)
    /// <summary>Takes RollDial's angle and shows it on the camera.</summary>
    /// <param name="Sender">RollDial.</param>
    procedure RollDialChange(Sender: TObject);
    //** @abstract(Takes DistanceTrack's factor and moves the camera out to match.)
    //**
    //** @param(Sender DistanceTrack.)
    /// <summary>Takes DistanceTrack's factor and moves the camera out to match.</summary>
    /// <param name="Sender">DistanceTrack.</param>
    procedure DistanceTrackChange(Sender: TObject);
  private
    FFreeOnClose: Boolean;
    FOnAccept: TNotifyEvent;
    FCameraSettings: TCameraSettings;
    FOriginal: TCameraSettings;   // as the dialog opened, put back on Cancel
    FUpdating: Boolean;           // set while the dials are turned in code
    FGorillaCamera: TSprite3DCamera;
    FFitDistance: Single;
    FFitOrthoHeight: Single;
    procedure SetSpec(const ASettings: TCameraSettings);
    procedure ShowSettings;
    procedure ApplyAngles;
    procedure ApplyDistance;
  public
    //** @abstract(Shows the dialog without blocking, and frees it when it closes.)
    //**
    //** For platforms where ShowModal cannot block, such as Android and iOS. When the dialog
    //** closes with OK, OnAccept is called while CameraSpec can still be read; then the form
    //** frees itself, so do not use it after that.
    /// <summary>Shows the dialog without blocking, and frees it when it closes.</summary>
    /// <remarks>For platforms where ShowModal cannot block, such as Android and iOS. When the
    /// dialog closes with OK, OnAccept is called while CameraSpec can still be read; then the
    /// form frees itself, so do not use it after that.</remarks>
    procedure ShowAndFree;
    //** @abstract(Called after ShowAndFree when the dialog closes with OK; read CameraSpec
    //** in it.)
    /// <summary>Called after ShowAndFree when the dialog closes with OK; read CameraSpec in
    /// it.</summary>
    property OnAccept: TNotifyEvent read FOnAccept write FOnAccept;
    //** @abstract(The angles and distance being edited: set before showing, read after OK.)
    /// <summary>The angles and distance being edited: set before showing, read after
    /// OK.</summary>
    property CameraSpec: TCameraSettings read FCameraSettings write SetSpec;
    //** @abstract(The camera the dialog previews on; nil for no preview.)
    //**
    //** Not owned. Every dial and slider change is applied to it at once, and Cancel puts it
    //** back.
    /// <summary>The camera the dialog previews on; nil for no preview.</summary>
    /// <remarks>Not owned. Every dial and slider change is applied to it at once, and Cancel
    /// puts it back.</remarks>
    property Camera: TSprite3DCamera read FGorillaCamera write FGorillaCamera;
    //** @abstract(The camera distance the model was fitted at, which the factor multiplies
    //** in perspective.)
    /// <summary>The camera distance the model was fitted at, which the factor multiplies in
    /// perspective.</summary>
    property FitDistance: Single read FFitDistance write FFitDistance;
    //** @abstract(The view height the model was fitted at, which the factor multiplies in
    //** orthographic projection.)
    /// <summary>The view height the model was fitted at, which the factor multiplies in
    /// orthographic projection.</summary>
    property FitOrthoHeight: Single read FFitOrthoHeight write FFitOrthoHeight;
  end;

implementation

{$R *.fmx}

uses
  System.Math, Sprite3DHelpers;

procedure TOrbitalSettingsForm.AzimuthDialChange(Sender: TObject);
begin
  if FUpdating then
    Exit;
  FCameraSettings.Azimuth := Wrap360(-AzimuthDial.Value);
  ApplyAngles;
end;

procedure TOrbitalSettingsForm.AngleDialChange(Sender: TObject);
begin
  if FUpdating then
    Exit;
  FCameraSettings.PolarAngle := Wrap360(-AngleDial.Value);
  ApplyAngles;
end;

procedure TOrbitalSettingsForm.RollDialChange(Sender: TObject);
begin
  if FUpdating then
    Exit;
  FCameraSettings.Roll := Wrap360(RollDial.Value);
  ApplyAngles;
end;

procedure TOrbitalSettingsForm.DistanceTrackChange(Sender: TObject);
begin
  if FUpdating then
    Exit;
  FCameraSettings.DistanceFactor := DistanceTrack.Value;
  ApplyDistance;
end;

procedure TOrbitalSettingsForm.ButtonClick(Sender: TObject);
begin
  if not FFreeOnClose then
    Exit;   // ShowModal closes the dialog itself
  ModalResult := TButton(Sender).ModalResult;
  Close;
end;

procedure TOrbitalSettingsForm.FormShow(Sender: TObject);
begin
  FOriginal := FCameraSettings;
  ShowSettings;
end;

procedure TOrbitalSettingsForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  // Anything but OK, including Esc and the window's close box, undoes the
  // preview
  if ModalResult <> mrOk then
  begin
    FCameraSettings := FOriginal;
    ApplyAngles;
    ApplyDistance;
  end;
  if not FFreeOnClose then
    Exit;   // shown with ShowModal: the caller frees it
  if (ModalResult = mrOk) and Assigned(FOnAccept) then
    FOnAccept(Self);
  Action := TCloseAction.caFree;
end;

procedure TOrbitalSettingsForm.SetSpec(const ASettings: TCameraSettings);
begin
  FCameraSettings := ASettings;
  FCameraSettings.DistanceFactor := Max(FCameraSettings.DistanceFactor, 1);
  FOriginal := FCameraSettings;
end;

procedure TOrbitalSettingsForm.ShowAndFree;
begin
  FFreeOnClose := True;
  Show;
end;

// Turns the dials and slider to the settings without their OnChange
// echoing back, then shows the settings on the camera
procedure TOrbitalSettingsForm.ShowSettings;
begin
  FUpdating := True;
  try
    AzimuthDial.Value := -FCameraSettings.Azimuth;
    AngleDial.Value := -FCameraSettings.PolarAngle;
    RollDial.Value := FCameraSettings.Roll;
    DistanceTrack.Value := EnsureRange(FCameraSettings.DistanceFactor, DistanceTrack.Min,
      DistanceTrack.Max);
  finally
    FUpdating := False;
  end;
  ApplyAngles;
  ApplyDistance;
end;

// The readouts, and the camera's angles; azimuth goes to the camera
// reversed, as on the main form
procedure TOrbitalSettingsForm.ApplyAngles;
begin
  AzimuthText.Text := DegreesText(FCameraSettings.Azimuth);
  AngleText.Text := DegreesText(FCameraSettings.PolarAngle);
  RollText.Text := DegreesText(FCameraSettings.Roll);
  if Assigned(FGorillaCamera) then
  begin
    FGorillaCamera.Azimuth := Wrap360(-FCameraSettings.Azimuth);
    FGorillaCamera.PolarAngle := FCameraSettings.PolarAngle;
    FGorillaCamera.Roll := FCameraSettings.Roll;
  end;
end;

// The label, and the camera moved out from the fitted view by the factor:
// the fitted distance times it in perspective, the fitted view height
// times it in orthographic projection. The factor is never below 1, so the
// camera never comes closer than the fit, which keeps it outside the model.
procedure TOrbitalSettingsForm.ApplyDistance;
var
  Factor: Single;
begin
  Factor := Max(FCameraSettings.DistanceFactor, 1);
  DistanceLabel.Text := Format('Distance x%.1f', [Factor]);
  if not Assigned(FGorillaCamera) then
    Exit;
  if FGorillaCamera.IsOrthographic then
  begin
    if FFitOrthoHeight > 0 then
      FGorillaCamera.OrthoHeight := FFitOrthoHeight * Factor;
  end
  else if FFitDistance > 0 then
    FGorillaCamera.Distance := FFitDistance * Factor;
end;

end.
