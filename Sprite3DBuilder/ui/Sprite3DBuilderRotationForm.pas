//** @abstract(The Rotation Snap dialog: the step, in degrees, the palette's Rotate and Bend
//** tools turn pieces by. Made in code; see TRotationSnapForm.Execute.)
//**
unit Sprite3DBuilderRotationForm;

{
  The Rotation Snap dialog: the step, in degrees, the palette's Rotate and
  Bend tools turn pieces by.

  A small modal form, made in code rather than laid out in an .fmx file,
  centred on the main form:

    TRotationSnapForm
    `-- BackPanel                 the form's opaque background, as the theme draws a panel
        |-- StepLabel, StepBox, DegreesLabel
        |-- PresetLayout          15, 22.5, 30, 45 and 90: each sets StepBox
        |-- NoteLabel             Shift turns freely
        `-- ButtonLayout          OkButton, CancelButton

  Desktop only, as the palette is: Execute shows it with ShowModal.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.StdCtrls, FMX.Layouts, FMX.Edit,
  FMX.Controls.Presentation;

type
  //** @abstract(The Rotation Snap dialog.) Use Execute.
  TRotationSnapForm = class(TForm)
  private
    //** A plain edit box, read by ReadStep: TNumberBox needs TNumValueType
    //** for decimals, which is not where it was expected in Delphi 13
    //** (owner, 12 November 2026, 20:33: E2003)
    FStepBox: TEdit;
    FMin, FMax: Single;
    //** @abstract(A preset button: puts its step in the box.)
    procedure PresetClick(Sender: TObject);
    //** @abstract(Shows the step as it will be kept, or the default if it is not a number.)
    procedure StepBoxExit(Sender: TObject);
    //** @abstract(The step typed, read with a point or a comma before its decimals and kept
    //** within the bounds; False if it is not a number.)
    function ReadStep(out ADegrees: Single): Boolean;
    //** @abstract(A step as the box shows it: up to two decimals, a point before them.)
    function ShowStep(const ADegrees: Single): String;
  public
    //** @abstract(Shows the dialog, modally, and returns the step chosen.)
    //**
    //** @param(ADegrees The step to show at first; set to the step chosen if the user
    //** clicks OK, left alone otherwise.)
    //**
    //** @param(AMin The smallest step allowed.)
    //**
    //** @param(AMax The largest step allowed.)
    //**
    //** @returns(True if the user clicked OK.)
    class function Execute(var ADegrees: Single; const AMin, AMax: Single): Boolean;
  end;

implementation

uses
  System.Math;

const
  PRESETS: array[0..4] of Single = (15, 22.5, 30, 45, 90);
  PAD = 12;

procedure TRotationSnapForm.PresetClick(Sender: TObject);
begin
  FStepBox.Text := ShowStep(PRESETS[TButton(Sender).Tag]);
end;

function TRotationSnapForm.ShowStep(const ADegrees: Single): String;
begin
  Result := FormatFloat('0.##', ADegrees, TFormatSettings.Invariant);
end;

// The step typed, with a point or a comma before its decimals, kept within
// FMin to FMax; False if it is not a number
function TRotationSnapForm.ReadStep(out ADegrees: Single): Boolean;
var
  Value: Double;
begin
  Result := TryStrToFloat(StringReplace(Trim(FStepBox.Text), ',', '.', []), Value,
    TFormatSettings.Invariant);
  if Result then
    ADegrees := EnsureRange(Value, FMin, FMax)
  else
    ADegrees := 0;
end;

// Shows the step as it will be kept, or, if it is not a number, the default
procedure TRotationSnapForm.StepBoxExit(Sender: TObject);
var
  Step: Single;
begin
  if not ReadStep(Step) then
    Step := PRESETS[3];
  FStepBox.Text := ShowStep(Step);
end;

class function TRotationSnapForm.Execute(var ADegrees: Single;
  const AMin, AMax: Single): Boolean;
var
  Form: TRotationSnapForm;
  Back: TPanel;
  Lbl: TLabel;
  Row: TLayout;
  Btn: TButton;
  Y, Step: Single;
begin
  Form := TRotationSnapForm.CreateNew(nil);
  try
    Form.Caption := 'Rotation Snap';
    Form.BorderStyle := TFmxFormBorderStyle.Single;
    Form.BorderIcons := [TBorderIcon.biSystemMenu];
    Form.Position := TFormPosition.MainFormCenter;
    Form.ClientWidth := 330;
    Form.ClientHeight := 176;

    Back := TPanel.Create(Form);
    Back.Parent := Form;
    Back.Align := TAlignLayout.Contents;

    Y := PAD;
    Lbl := TLabel.Create(Form);
    Lbl.Parent := Back;
    Lbl.SetBounds(PAD, Y + 3, 120, 22);
    Lbl.Text := 'Turn in steps of';

    Form.FMin := AMin;
    Form.FMax := AMax;
    Form.FStepBox := TEdit.Create(Form);
    Form.FStepBox.Parent := Back;
    Form.FStepBox.SetBounds(PAD + 124, Y, 90, 26);
    Form.FStepBox.FilterChar := '0123456789.,';
    Form.FStepBox.MaxLength := 6;
    Form.FStepBox.Text := Form.ShowStep(ADegrees);
    Form.FStepBox.OnExit := Form.StepBoxExit;

    Lbl := TLabel.Create(Form);
    Lbl.Parent := Back;
    Lbl.SetBounds(PAD + 220, Y + 3, 80, 22);
    Lbl.Text := 'degrees';

    // A button for each common step
    Y := Y + 36;
    Row := TLayout.Create(Form);
    Row.Parent := Back;
    Row.SetBounds(PAD, Y, Form.ClientWidth - 2 * PAD, 26);
    for var I := 0 to High(PRESETS) do
    begin
      Btn := TButton.Create(Form);
      Btn.Parent := Row;
      Btn.SetBounds(I * 62, 0, 56, 26);
      Btn.Text := FormatFloat('0.##', PRESETS[I]) + #176;
      Btn.Tag := I;
      Btn.OnClick := Form.PresetClick;
    end;

    Y := Y + 36;
    Lbl := TLabel.Create(Form);
    Lbl.Parent := Back;
    Lbl.SetBounds(PAD, Y, Form.ClientWidth - 2 * PAD, 40);
    Lbl.TextSettings.WordWrap := True;
    Lbl.Text := Format('From %s to %s degrees.  Hold Shift while turning a piece to turn ' +
      'it freely instead.', [Form.ShowStep(AMin), Form.ShowStep(AMax)]);

    Row := TLayout.Create(Form);
    Row.Parent := Back;
    Row.SetBounds(PAD, Form.ClientHeight - PAD - 28, Form.ClientWidth - 2 * PAD, 28);
    Btn := TButton.Create(Form);
    Btn.Parent := Row;
    Btn.SetBounds(Row.Width - 2 * 88 - 8, 0, 88, 28);
    Btn.Text := 'OK';
    Btn.Default := True;
    Btn.ModalResult := mrOk;
    Btn := TButton.Create(Form);
    Btn.Parent := Row;
    Btn.SetBounds(Row.Width - 88, 0, 88, 28);
    Btn.Text := 'Cancel';
    Btn.Cancel := True;
    Btn.ModalResult := mrCancel;

    // Not a number: as Cancel
    Result := (Form.ShowModal = mrOk) and Form.ReadStep(Step);
    if Result then
      ADegrees := Step;
  finally
    Form.Free;
  end;
end;

end.
