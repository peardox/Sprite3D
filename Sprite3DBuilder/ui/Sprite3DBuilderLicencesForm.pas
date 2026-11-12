//** @abstract(File, Licences: the third-party licences and notices Sprite3DBuilder carries.)
//**
//** A drop-down chooses one of the licences ThirdPartyLicences lists, from Sprite3DLicences,
//** and the memo below shows its text, read from the program's own resources. Save All...
//** (desktop only) writes every one of them to a single text file, such as
//** @code(THIRD-PARTY-NOTICES.txt), to ship beside the program. ShowLicences shows the dialog,
//** opened at one licence if asked: Settings' Cisco Licence... opens it at Cisco's.
//**
//** Modal on the desktop; on Android and iOS, which cannot block, shown and freed when it
//** closes. For the main thread only.
unit Sprite3DBuilderLicencesForm;

{
  File, Licences: the third-party licences and notices Sprite3DBuilder carries.

  A drop-down chooses one of the licences ThirdPartyLicences lists, and the
  memo below shows its text, read from the program's own resources. Save
  All... (desktop only) writes them all to one text file to ship beside the
  program. ShowLicences shows the dialog, opened at one licence if asked.

  Modal on the desktop; on Android and iOS shown and freed when it closes.
  Main thread only.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, FMX.Types,
  FMX.Controls, FMX.Forms, FMX.Graphics, FMX.StdCtrls, FMX.Layouts, FMX.ListBox,
  FMX.Controls.Presentation, FMX.Memo, FMX.Memo.Types, FMX.ScrollBox, Sprite3DLicences;

type
  //** @abstract(The File, Licences dialog; see the unit description.)
  TLicencesForm = class(TForm)
    //** @abstract(The form's opaque background.)
    BackPanel: TPanel;
    //** @abstract(Chooses the licence shown.)
    LicenceCombo: TComboBox;
    //** @abstract(The chosen licence's text, read only.)
    LicenceMemo: TMemo;
    //** @abstract(The strip holding the Save All and Close buttons.)
    ButtonLayout: TLayout;
    //** @abstract(Writes every licence to one text file; desktop only.)
    SaveAllButton: TButton;
    //** @abstract(Closes the dialog.)
    CloseButton: TButton;
    //** @abstract(Fills the drop-down and shows the first licence.)
    //** @param(Sender The form.)
    procedure FormCreate(Sender: TObject);
    //** @abstract(Shows the licence chosen.)
    //** @param(Sender LicenceCombo.)
    procedure LicenceComboChange(Sender: TObject);
    //** @abstract(Asks where to save, then writes AllLicencesText there as UTF-8.)
    //** @param(Sender SaveAllButton.)
    procedure SaveAllButtonClick(Sender: TObject);
    //** @abstract(Closes the dialog.)
    //** @param(Sender CloseButton.)
    procedure CloseButtonClick(Sender: TObject);
    //** @abstract(Frees the dialog as it closes when it was not shown modally.)
    //** @param(Sender The form.)
    //** @param(Action Set to caFree on Android and iOS.)
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    //** The licences in the drop-down, in its order.
    FLicences: TArray<TSprite3DLicence>;
  public
    //** @abstract(Shows the licence held in this resource, if it is one of them.)
    //** @param(AResource One of the LICENCE_ constants of Sprite3DLicences.)
    procedure SelectLicence(const AResource: String);
  end;

//** @abstract(Shows the File, Licences dialog.)
//**
//** Modal on the desktop, returning when it is closed; on Android and iOS it returns at once
//** and the dialog frees itself when closed.
//**
//** @param(AResource The licence to open it at, one of the LICENCE_ constants; empty for the
//** first.)
procedure ShowLicences(const AResource: String = '');

implementation

uses
  System.IOUtils, FMX.Dialogs;

{$R *.fmx}

procedure ShowLicences(const AResource: String);
var
  Dialog: TLicencesForm;
begin
  Dialog := TLicencesForm.Create(nil);
  {$IF DEFINED(ANDROID) or DEFINED(IOS)}
  Dialog.SelectLicence(AResource);
  Dialog.Show;   // FormClose frees it
  {$ELSE}
  try
    Dialog.SelectLicence(AResource);
    Dialog.ShowModal;
  finally
    Dialog.Free;
  end;
  {$ENDIF}
end;

procedure TLicencesForm.FormCreate(Sender: TObject);
var
  Licence: TSprite3DLicence;
begin
  FLicences := ThirdPartyLicences;
  LicenceCombo.Items.BeginUpdate;
  try
    LicenceCombo.Items.Clear;
    for Licence in FLicences do
      LicenceCombo.Items.Add(Licence.Title);
  finally
    LicenceCombo.Items.EndUpdate;
  end;
  {$IF DEFINED(ANDROID) or DEFINED(IOS)}
  // No file dialogs to save with
  SaveAllButton.Visible := False;
  {$ENDIF}
  if LicenceCombo.Count > 0 then
    LicenceCombo.ItemIndex := 0;
  LicenceComboChange(LicenceCombo);
end;

procedure TLicencesForm.SelectLicence(const AResource: String);
var
  I: Integer;
begin
  for I := 0 to High(FLicences) do
    if SameText(FLicences[I].Resource, AResource) then
    begin
      LicenceCombo.ItemIndex := I;
      LicenceComboChange(LicenceCombo);
      Exit;
    end;
end;

procedure TLicencesForm.LicenceComboChange(Sender: TObject);
var
  Index: Integer;
begin
  Index := LicenceCombo.ItemIndex;
  if (Index < 0) or (Index > High(FLicences)) then
  begin
    LicenceMemo.Text := String.Empty;
    Exit;
  end;
  LicenceMemo.Text := LicenceText(FLicences[Index].Resource);
  LicenceMemo.GoToTextBegin;
end;

procedure TLicencesForm.SaveAllButtonClick(Sender: TObject);
var
  Dialog: TSaveDialog;
begin
  Dialog := TSaveDialog.Create(nil);
  try
    Dialog.Title := 'Save every licence and notice';
    Dialog.FileName := 'THIRD-PARTY-NOTICES.txt';
    Dialog.DefaultExt := 'txt';
    Dialog.Filter := 'Text files (*.txt)|*.txt';
    Dialog.Options := Dialog.Options + [TOpenOption.ofOverwritePrompt];
    if not Dialog.Execute then
      Exit;
    try
      // UTF-8 without a byte-order mark; Cisco's licence has curly quotes
      TFile.WriteAllBytes(Dialog.FileName, TEncoding.UTF8.GetBytes(AllLicencesText));
    except
      on E: Exception do
        ShowMessage('Can''t save ' + Dialog.FileName + sLineBreak + E.Message);
    end;
  finally
    Dialog.Free;
  end;
end;

procedure TLicencesForm.CloseButtonClick(Sender: TObject);
begin
  {$IF DEFINED(ANDROID) or DEFINED(IOS)}
  Close;
  {$ELSE}
  ModalResult := mrClose;
  {$ENDIF}
end;

procedure TLicencesForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  {$IF DEFINED(ANDROID) or DEFINED(IOS)}
  Action := TCloseAction.caFree;
  {$ENDIF}
end;

end.
