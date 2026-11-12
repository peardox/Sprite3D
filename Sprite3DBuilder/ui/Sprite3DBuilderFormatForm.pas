//** @abstract(Which Format: the question Add Artist Collections asks when a folder has none of
//** the formats chosen so far.)
//**
//** It says which folder, and which formats it has, with how many models of each; the user
//** chooses one and Import takes it, as the next default for the folders still to come. Skip
//** passes over this folder and turns down the formats it offered, so a later folder with
//** only those is passed over without asking. Only My Defaults passes over this one and every later one with
//** none of the formats chosen so far, without asking again. Stop ends the whole operation.
//** The first time, with no formats chosen yet, Only My Defaults is hidden.
//**
//** Modal; desktop only. For the main thread only.
unit Sprite3DBuilderFormatForm;

{
  Which Format: the question Add Artist Collections asks when a folder has
  none of the formats chosen so far. The user chooses one and Import takes
  it as the next default; Skip passes over this folder, and later ones with
  only the formats it offered; Only My Defaults
  passes over every such folder from now on; Stop ends the operation.

  Modal; desktop only. Main thread only.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, FMX.Types,
  FMX.Controls, FMX.Forms, FMX.Graphics, FMX.StdCtrls, FMX.Layouts, FMX.ListBox,
  FMX.Controls.Presentation;

type
  //** @abstract(What the user answered.)
  TFormatAnswer = (
    //** @abstract(Import the format chosen, and keep it as a default.)
    faImport,
    //** @abstract(Pass over this folder.)
    faSkip,
    //** @abstract(Pass over this folder and every later one with none of the defaults.)
    faOnlyDefaults,
    //** @abstract(End the whole operation.)
    faStop);

  //** @abstract(The Which Format dialog; see the unit description.)
  TFormatForm = class(TForm)
    //** @abstract(The form's opaque background.)
    BackPanel: TPanel;
    //** @abstract(The question.)
    InfoLabel: TLabel;
    //** @abstract(The formats the folder has, with their counts.)
    FormatCombo: TComboBox;
    //** @abstract(The strip holding the buttons.)
    ButtonLayout: TLayout;
    //** @abstract(Takes the format chosen.)
    ImportButton: TButton;
    //** @abstract(Passes over this folder.)
    SkipButton: TButton;
    //** @abstract(Passes over every folder with none of the defaults.)
    OnlyDefaultsButton: TButton;
    //** @abstract(Ends the operation.)
    StopButton: TButton;
    //** @abstract(Records Import.)
    //**
    //** @param(Sender ImportButton.)
    procedure ImportButtonClick(Sender: TObject);
    //** @abstract(Records Skip.)
    //**
    //** @param(Sender SkipButton.)
    procedure SkipButtonClick(Sender: TObject);
    //** @abstract(Records Only My Defaults.)
    //**
    //** @param(Sender OnlyDefaultsButton.)
    procedure OnlyDefaultsButtonClick(Sender: TObject);
    //** @abstract(Records Stop.)
    //**
    //** @param(Sender StopButton.)
    procedure StopButtonClick(Sender: TObject);
  private
    //** @abstract(The answer given; faStop until one is.)
    FAnswer: TFormatAnswer;
  end;

//** @abstract(Asks which of AFormats to take from folder AFolder.)
//**
//** @param(AFolder The folder's name, as shown.)
//**
//** @param(AFormats The formats it has, best first, as extensions with the dot.)
//**
//** @param(ACounts How many models of each, in AFormats' order.)
//**
//** @param(ADefaults The formats chosen so far, for the question; empty the first time.)
//**
//** @param(AChosen On faImport, the format chosen.)
//**
//** @returns(The answer; closing the dialog counts as faStop.)
function AskFormat(const AFolder: String; const AFormats: TArray<String>;
  const ACounts: TArray<Integer>; const ADefaults: TArray<String>;
  out AChosen: String): TFormatAnswer;

implementation

uses
  Sprite3DBuilderHelpers;

{$R *.fmx}

function AskFormat(const AFolder: String; const AFormats: TArray<String>;
  const ACounts: TArray<Integer>; const ADefaults: TArray<String>;
  out AChosen: String): TFormatAnswer;
var
  Dialog: TFormatForm;
  Names: TArray<String>;
begin
  AChosen := String.Empty;
  Dialog := TFormatForm.Create(nil);
  try
    Dialog.FAnswer := faStop;
    if Length(ADefaults) = 0 then
    begin
      Dialog.InfoLabel.Text := 'Which model format do you want from ' + AFolder +
        '? It becomes the default for every folder after it. Or skip it: later ' +
        'folders with only these formats are passed over too.';
      Dialog.OnlyDefaultsButton.Visible := False;
    end
    else
    begin
      Names := nil;
      for var Ext in ADefaults do
        Names := Names + [ModelFormatName(Ext)];
      Dialog.InfoLabel.Text := AFolder + ' has none of your formats so far (' +
        String.Join(', ', Names) + '). Import one of those it has, as your next ' +
        'default? Or skip it (later folders with only these formats are passed over ' +
        'too), or keep to your formats so far for every folder still to come.';
    end;
    Dialog.FormatCombo.Clear;
    for var I := 0 to High(AFormats) do
      Dialog.FormatCombo.Items.Add(Format('%s (%s), %d models', [ModelFormatName(AFormats[I]),
        AFormats[I], ACounts[I]]));
    Dialog.FormatCombo.ItemIndex := 0;
    Dialog.ShowModal;
    Result := Dialog.FAnswer;
    if (Result = faImport) and (Dialog.FormatCombo.ItemIndex >= 0) then
      AChosen := AFormats[Dialog.FormatCombo.ItemIndex]
    else if Result = faImport then
      Result := faSkip;
  finally
    Dialog.Free;
  end;
end;

{ TFormatForm }

procedure TFormatForm.ImportButtonClick(Sender: TObject);
begin
  FAnswer := faImport;
  ModalResult := mrOk;
end;

procedure TFormatForm.SkipButtonClick(Sender: TObject);
begin
  FAnswer := faSkip;
  ModalResult := mrOk;
end;

procedure TFormatForm.OnlyDefaultsButtonClick(Sender: TObject);
begin
  FAnswer := faOnlyDefaults;
  ModalResult := mrOk;
end;

procedure TFormatForm.StopButtonClick(Sender: TObject);
begin
  FAnswer := faStop;
  ModalResult := mrCancel;
end;

end.
