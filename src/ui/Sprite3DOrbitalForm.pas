unit Sprite3DOrbitalForm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Layouts, Sprite3DCamera;

type
  TCameraSettings = record
    Azimuth: Single;
    Roll: Single;
    PolarAngle: Single;
    Distance: Single;
    Height: Single;
  end;

  TOrbitalSettingsForm = class(TForm)
    Layout1: TLayout;
    Layout2: TLayout;
    OrbitalLayout: TLayout;
    AngleDial: TArcDial;
    AngleLabel: TLabel;
    AngleText: TLabel;
    AzimuthDial: TArcDial;
    AzimuthLabel: TLabel;
    AzimuthText: TLabel;
    RollDial: TArcDial;
    RollLabel: TLabel;
    RollText: TLabel;
    DistanceLayout: TLayout;
    DistanceLabel: TLabel;
    DistanceTrack: TTrackBar;
    CancelButton: TButton;
    OkButton: TButton;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure OkButtonClick(Sender: TObject);
    procedure AzimuthDialChange(Sender: TObject);
    procedure AngleDialChange(Sender: TObject);
    procedure RollDialChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure DistanceTrackChange(Sender: TObject);
  strict private
    { Private declarations }
    FFreeOnClose: Boolean;
    FOnAccept: TNotifyEvent;
    FCameraSettings: TCameraSettings;
    FGorillaCamera: TSprite3DCamera;
    procedure SetSpec(const ASettings: TCameraSettings);
    procedure ShowAndFree;
    procedure ApplyAngles;
    procedure ApplyDistance;
  private
  public
    { Public declarations }
    property OnAccept: TNotifyEvent read FOnAccept write FOnAccept;
    property CameraSpec: TCameraSettings read FCameraSettings write SetSpec;
    property Camera: TSprite3DCamera read FGorillaCamera write FGorillaCamera;
  end;

var
  OrbitalSettingsForm: TOrbitalSettingsForm;

implementation

{$R *.fmx}

uses Sprite3DHelpers;

procedure TOrbitalSettingsForm.OkButtonClick(Sender: TObject);
begin
  ModalResult := mrOK;
end;

procedure TOrbitalSettingsForm.RollDialChange(Sender: TObject);
begin
  FCameraSettings.Roll := Wrap360(RollDial.Value);
  ApplyAngles;
end;

procedure TOrbitalSettingsForm.AngleDialChange(Sender: TObject);
begin
  FCameraSettings.PolarAngle := Wrap360(-AngleDial.Value);
  ApplyAngles;
end;

procedure TOrbitalSettingsForm.AzimuthDialChange(Sender: TObject);
begin
  FCameraSettings.Azimuth := Wrap360(-AzimuthDial.Value);
  ApplyAngles;
end;

procedure TOrbitalSettingsForm.DistanceTrackChange(Sender: TObject);
begin
  ApplyDistance;
end;

procedure TOrbitalSettingsForm.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  if not FFreeOnClose then
    Exit;   // shown with ShowModal: the caller frees it
  if (ModalResult = mrOk) and Assigned(FOnAccept) then
    FOnAccept(Self);
  Action := TCloseAction.caFree;
end;

procedure TOrbitalSettingsForm.FormCreate(Sender: TObject);
begin
//
end;

procedure TOrbitalSettingsForm.FormShow(Sender: TObject);
begin
  AzimuthDial.Value := Wrap360(-FCameraSettings.Azimuth);
  RollDial.Value := Wrap360(FCameraSettings.Roll);
  AngleDial.Value := Wrap360(-FCameraSettings.PolarAngle);
  DistanceTrack.Value := FCameraSettings.Distance;
  ApplyAngles;
end;

procedure TOrbitalSettingsForm.SetSpec(const ASettings: TCameraSettings);
begin
  FCameraSettings.Azimuth := ASettings.Azimuth;
  FCameraSettings.Roll := ASettings.Roll;
  FCameraSettings.PolarAngle := ASettings.PolarAngle;
  FCameraSettings.Distance := ASettings.Distance;
  FCameraSettings.Height := ASettings.Height;
end;

procedure TOrbitalSettingsForm.ShowAndFree;
begin
  FFreeOnClose := True;
  Show;
end;

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

// Test only: the fitted view moved out by the distance slider's factor
procedure TOrbitalSettingsForm.ApplyDistance;
var
  Factor: Single;
begin
  Factor := DistanceTrack.Value;
  FCameraSettings.Distance := DistanceTrack.Value;
  DistanceLabel.Text := Format('Distance x%.1f', [Factor]);
  if not Assigned(Camera) or (FCameraSettings.Distance <= 0) then
    Exit;
  if Camera.IsOrthographic then
    Camera.OrthoHeight := FCameraSettings.Height * Factor
  else
    Camera.Distance := FCameraSettings.Distance * Factor;
end;

end.
