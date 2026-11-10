//** @abstract(The Debug, glTF, Merge Animations dialog: the glTF files whose animations are
//** added to the open model, and what to do when a name is taken.)
//**
//** Add... chooses .glb and .gltf files, several at once, and adds those not listed already;
//** Remove and Clear take them off. The combo box chooses what happens to an animation whose
//** name the model already has: renamed (GLTFLib suggests a free name), replacing the old one,
//** or left out. Merge... checks there is a file and closes with mrOk. The merging itself,
//** with GLTFLib's TglTFAnimationImporter, is the caller's job: it matches each animation's
//** channels to the model's nodes by name.
//**
//** Desktop only: shown with ShowModal. For the main thread only.
unit Sprite3DGltfMergeForm;

{
  The Debug, glTF, Merge Animations dialog: the glTF files whose animations
  are added to the open model, and what to do when a name is taken. Merge...
  closes with mrOk; merging is the caller's job. Desktop only; shown with
  ShowModal. Main thread only.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, FMX.Types,
  FMX.Controls, FMX.Forms, FMX.Graphics, FMX.StdCtrls, FMX.Layouts,
  FMX.Controls.Presentation, FMX.ListBox,
  glTF.Animations;

type
  //** @abstract(The Debug, glTF, Merge Animations dialog; see the unit description.)
  TGltfMergeForm = class(TForm)
    //** @abstract(Says which model the animations go into.)
    InfoLabel: TLabel;
    //** @abstract(Names the list of files.)
    FilesLabel: TLabel;
    //** @abstract(The animation files, as full paths, in the order they were added.)
    FilesList: TListBox;
    //** @abstract(Chooses glTF files to add, several at once.)
    AddButton: TButton;
    //** @abstract(Takes the selected file off the list.)
    RemoveButton: TButton;
    //** @abstract(Takes every file off the list.)
    ClearButton: TButton;
    //** @abstract(Names the duplicates choice.)
    DuplicatesLabel: TLabel;
    //** @abstract(Rename the new animation, replace the old one, or keep the old one.)
    DuplicatesCombo: TComboBox;
    //** @abstract(The strip holding the Cancel and Merge buttons.)
    ButtonLayout: TLayout;
    //** @abstract(Closes the dialog with mrCancel.)
    CancelButton: TButton;
    //** @abstract(Closes the dialog with mrOk once there is a file.)
    MergeButton: TButton;
    //** @abstract(Chooses glTF files in a file dialog, starting in Folder.)
    //**
    //** @param(Sender AddButton.)
    procedure AddButtonClick(Sender: TObject);
    //** @abstract(Takes the selected file off the list.)
    //**
    //** @param(Sender RemoveButton.)
    procedure RemoveButtonClick(Sender: TObject);
    //** @abstract(Takes every file off the list.)
    //**
    //** @param(Sender ClearButton.)
    procedure ClearButtonClick(Sender: TObject);
    //** @abstract(Closes with mrOk if there is a file; otherwise says so.)
    //**
    //** @param(Sender MergeButton.)
    procedure MergeButtonClick(Sender: TObject);
    //** @abstract(Closes the dialog with mrCancel.)
    //**
    //** @param(Sender CancelButton.)
    procedure CancelButtonClick(Sender: TObject);
    //** @abstract(Enables Remove once a file is selected.)
    //**
    //** @param(Sender FilesList.)
    procedure FilesListChange(Sender: TObject);
  private
    //** The folder Add... opens in; the last file's folder after each add.
    FFolder: string;
    //** The files listed, as full paths, in order.
    function GetFiles: TArray<string>;
    //** DuplicatesCombo's choice as GLTFLib's action.
    function GetDuplicateAction: TglTFDuplicateAction;
    //** Adds a file to the list unless it is there already, ignoring case.
    procedure AddFile(const AFile: string);
    //** Enables Remove and Clear when there is something for them to take off.
    procedure UpdateButtons;
  public
    //** @abstract(Lets InfoLabel wrap and sets the buttons.)
    //**
    //** @param(AOwner The owner, as for any form.)
    constructor Create(AOwner: TComponent); override;
    //** @abstract(Names the model the animations are added to.)
    //**
    //** @param(AModelName The open model's file name.)
    //**
    //** @param(AAnimationCount How many animations it has now.)
    procedure SetModel(const AModelName: string; const AAnimationCount: Integer);
    //** @abstract(The files, as full paths, in order.)
    property Files: TArray<string> read GetFiles;
    //** @abstract(What to do with an animation whose name is taken: daRename, daReplace or
    //** daKeep.)
    property DuplicateAction: TglTFDuplicateAction read GetDuplicateAction;
    //** @abstract(The folder Add... opens in; set it before showing, read it after.)
    property Folder: string read FFolder write FFolder;
  end;

implementation

uses
  System.Math, FMX.Dialogs;

{$R *.fmx}

constructor TGltfMergeForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  InfoLabel.StyledSettings := InfoLabel.StyledSettings - [TStyledSetting.Other];
  InfoLabel.TextSettings.WordWrap := True;
  InfoLabel.TextSettings.VertAlign := TTextAlign.Leading;
  UpdateButtons;
end;

procedure TGltfMergeForm.SetModel(const AModelName: string; const AAnimationCount: Integer);
begin
  InfoLabel.Text := Format('The animations in these files are added to %s (%d animations ' +
    'now), matched to its nodes by name. Meshes and materials in the files are ignored.',
    [AModelName, AAnimationCount]);
end;

function TGltfMergeForm.GetFiles: TArray<string>;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to FilesList.Count - 1 do
    Result := Result + [FilesList.Items[I]];
end;

function TGltfMergeForm.GetDuplicateAction: TglTFDuplicateAction;
begin
  case DuplicatesCombo.ItemIndex of
    1: Result := daReplace;
    2: Result := daKeep;
  else
    Result := daRename;
  end;
end;

procedure TGltfMergeForm.AddFile(const AFile: string);
var
  I: Integer;
begin
  for I := 0 to FilesList.Count - 1 do
    if SameText(FilesList.Items[I], AFile) then
      Exit;
  FilesList.Items.Add(AFile);
end;

procedure TGltfMergeForm.UpdateButtons;
begin
  RemoveButton.Enabled := FilesList.ItemIndex >= 0;
  ClearButton.Enabled := FilesList.Count > 0;
end;

procedure TGltfMergeForm.AddButtonClick(Sender: TObject);
var
  Dialog: TOpenDialog;
  FileName: string;
begin
  Dialog := TOpenDialog.Create(nil);
  try
    Dialog.Title := 'Merge Animations: choose the animation files';
    Dialog.Filter := 'glTF (*.glb;*.gltf)|*.glb;*.gltf';
    Dialog.Options := Dialog.Options + [TOpenOption.ofAllowMultiSelect,
      TOpenOption.ofFileMustExist];
    if (FFolder <> '') and DirectoryExists(FFolder) then
      Dialog.InitialDir := FFolder;
    if not Dialog.Execute then
      Exit;
    for FileName in Dialog.Files do
      AddFile(FileName);
    if Dialog.Files.Count > 0 then
      FFolder := ExtractFileDir(Dialog.Files[Dialog.Files.Count - 1]);
  finally
    Dialog.Free;
  end;
  UpdateButtons;
end;

procedure TGltfMergeForm.RemoveButtonClick(Sender: TObject);
var
  Index: Integer;
begin
  Index := FilesList.ItemIndex;
  if Index < 0 then
    Exit;
  FilesList.Items.Delete(Index);
  if FilesList.Count > 0 then
    FilesList.ItemIndex := Min(Index, FilesList.Count - 1);
  UpdateButtons;
end;

procedure TGltfMergeForm.ClearButtonClick(Sender: TObject);
begin
  FilesList.Clear;
  UpdateButtons;
end;

procedure TGltfMergeForm.MergeButtonClick(Sender: TObject);
begin
  if FilesList.Count = 0 then
  begin
    ShowMessage('Add at least one file whose animations are to be merged.');
    Exit;
  end;
  ModalResult := mrOk;
end;

procedure TGltfMergeForm.CancelButtonClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TGltfMergeForm.FilesListChange(Sender: TObject);
begin
  UpdateButtons;
end;

end.
