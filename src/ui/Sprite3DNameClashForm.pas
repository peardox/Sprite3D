//** @abstract(Asks what to do when a static model being opened has the name of one already in
//** the Static tab's Models list: replace it, ignore the new one, or rename the new one.)
//**
//** Prepare sets the question: the name, both files, and the free name Rename would list the
//** new model under, which its button shows. @bold(Replace) unloads the model listed and puts
//** the new one in its place, under the same name; @bold(Ignore) leaves the list as it is and
//** the new model is not opened; @bold(Rename) opens it too, under the free name. Closing the
//** dialog any other way, such as with Escape or its close box, counts as Ignore. While a
//** folder is being opened, a tick below the question answers every later clash of that
//** folder the same way; read it from ApplyToAll.
//**
//** On the desktop, show it with ShowModal; on Android and iOS, which cannot block, show it
//** with ShowAndFree, which calls OnChosen however it closes and frees the form then. Read
//** Choice once it has closed. For the main thread only.
unit Sprite3DNameClashForm;

{
  Asks what to do when a static model being opened has the name of one
  already in the Static tab's Models list: replace it, ignore the new one,
  or rename the new one. Closing it otherwise counts as Ignore. While a
  folder is being opened, a tick answers every later clash the same way.

  On the desktop, show it with ShowModal; on Android and iOS, with
  ShowAndFree, which calls OnChosen however it closes. For the main thread
  only.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, FMX.Types,
  FMX.Controls, FMX.Forms, FMX.Graphics, FMX.StdCtrls, FMX.Controls.Presentation,
  FMX.Layouts;

type
  //** @abstract(What to do with a static model whose name is already listed.)
  TNameClashChoice = (
    //** @abstract(Unload the model listed and list the new one in its place, under the same
    //** name.)
    ncReplace,
    //** @abstract(Leave the list as it is; the new model is not opened.)
    ncIgnore,
    //** @abstract(Open the new model too, under a name no other entry has.)
    ncRename);

  //** @abstract(The name clash dialog; see the unit description.)
  TNameClashForm = class(TForm)
    //** @abstract(The question: which name, and which files.)
    MessageLabel: TLabel;
    //** @abstract(Answers every later clash of the folder being opened the same way; shown
    //** only while a folder is being opened.)
    ApplyAllCheck: TCheckBox;
    //** @abstract(The strip holding the Ignore, Rename and Replace buttons.)
    ButtonLayout: TLayout;
    //** @abstract(Chooses ncIgnore; also the button Escape presses.)
    IgnoreButton: TButton;
    //** @abstract(Chooses ncRename; its caption gives the new name.)
    RenameButton: TButton;
    //** @abstract(Chooses ncReplace; the default button.)
    ReplaceButton: TButton;
    //** @abstract(Keeps the choice of the button clicked and closes the dialog.)
    //**
    //** @param(Sender IgnoreButton, RenameButton or ReplaceButton.)
    procedure ChoiceButtonClick(Sender: TObject);
    //** @abstract(Reports the choice when shown with ShowAndFree, and frees the form then.)
    //**
    //** @param(Sender The form.)
    //**
    //** @param(Action Set to caFree when shown with ShowAndFree.)
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    //** True when shown with ShowAndFree: the form reports and frees itself on closing.
    FFreeOnClose: Boolean;
    //** The button clicked; ncIgnore until one is.
    FChoice: TNameClashChoice;
    //** Called as the form closes when shown with ShowAndFree.
    FOnChosen: TNotifyEvent;
    //** Whether ApplyAllCheck was ticked when a button was clicked.
    function GetApplyToAll: Boolean;
  public
    //** @abstract(Sets the question.)
    //**
    //** @param(AName The name listed already.)
    //**
    //** @param(AListedFile The file of the model listed under it.)
    //**
    //** @param(ANewFile The file of the model being opened.)
    //**
    //** @param(ARenameTo The free name Rename would list the new model under.)
    //**
    //** @param(AInFolder True while a folder is being opened, to offer ApplyAllCheck.)
    procedure Prepare(const AName, AListedFile, ANewFile, ARenameTo: String;
      const AInFolder: Boolean);
    //** @abstract(Shows the dialog without blocking and frees it when it closes.)
    //**
    //** For Android and iOS, where ShowModal cannot block. OnChosen is called however it
    //** closes, with Choice ncIgnore unless a button chose otherwise.
    procedure ShowAndFree;
    //** @abstract(The choice made; ncIgnore if the dialog was closed without a button.)
    property Choice: TNameClashChoice read FChoice;
    //** @abstract(Whether every later clash of the folder being opened is to be answered the
    //** same way.)
    property ApplyToAll: Boolean read GetApplyToAll;
    //** @abstract(Called as the dialog closes when shown with ShowAndFree.)
    property OnChosen: TNotifyEvent read FOnChosen write FOnChosen;
  end;

implementation

{$R *.fmx}

procedure TNameClashForm.Prepare(const AName, AListedFile, ANewFile, ARenameTo: String;
  const AInFolder: Boolean);
begin
  FChoice := ncIgnore;
  MessageLabel.Text := Format('"%s" is already in the Models list.', [AName]) + sLineBreak +
    sLineBreak + 'Listed: ' + AListedFile + sLineBreak + 'Opening: ' + ANewFile;
  RenameButton.Text := Format('Rename to "%s"', [ARenameTo]);
  ApplyAllCheck.Visible := AInFolder;
  ApplyAllCheck.IsChecked := False;
end;

function TNameClashForm.GetApplyToAll: Boolean;
begin
  Result := ApplyAllCheck.Visible and ApplyAllCheck.IsChecked;
end;

procedure TNameClashForm.ChoiceButtonClick(Sender: TObject);
begin
  if Sender = ReplaceButton then
    FChoice := ncReplace
  else if Sender = RenameButton then
    FChoice := ncRename
  else
    FChoice := ncIgnore;
  ModalResult := mrOk;
  if FFreeOnClose then
    Close;
end;

procedure TNameClashForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if ModalResult <> mrOk then
    FChoice := ncIgnore;   // closed without a button
  if not FFreeOnClose then
    Exit;   // shown with ShowModal: the caller reads Choice and frees it
  if Assigned(FOnChosen) then
    FOnChosen(Self);
  Action := TCloseAction.caFree;
end;

procedure TNameClashForm.ShowAndFree;
begin
  FFreeOnClose := True;
  Show;
end;

end.
