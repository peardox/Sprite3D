unit Sprite3DOrbitalForm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Layouts;

type
  TOrbitalSettingsForm = class(TForm)
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
    OkButton: TButton;
    CancelButton: TButton;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure OkButtonClick(Sender: TObject);
  private
    { Private declarations }
    FFreeOnClose: Boolean;
    FOnAccept: TNotifyEvent;
    procedure ShowAndFree;
  public
    { Public declarations }
    property OnAccept: TNotifyEvent read FOnAccept write FOnAccept;
  end;

var
  OrbitalSettingsForm: TOrbitalSettingsForm;

implementation

{$R *.fmx}

procedure TOrbitalSettingsForm.OkButtonClick(Sender: TObject);
begin
  ModalResult := mrOK;
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

procedure TOrbitalSettingsForm.ShowAndFree;
begin
  FFreeOnClose := True;
  Show;
end;

end.
