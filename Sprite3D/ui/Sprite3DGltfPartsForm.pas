//** @abstract(The Debug, glTF, Add Parts dialog: parts made for the open model's skeleton,
//** such as clothes or body parts, to put on it.)
//**
//** Add files... loads .glb and .gltf files into a GLTFLib TglTFPartLibrary, which lists
//** every skinned mesh in them as a part, with the bones it covers; each is listed with a box
//** to tick. A .gltf whose textures or buffers had to be found or made, as when a model is
//** opened (a .psd texture, a file not where it says), is loaded from its copy
//** (GltfFileToRead), and listed under its own name. Clear empties the list, Tick all ticks every part. Put on... checks one is
//** ticked and closes with mrOk. Putting them on, with TglTFPartApplier, is the caller's
//** job: each part is bound to the model's bones by name, an earlier part it replaces is
//** taken off, and the body under it is hidden. The dialog owns the library, so the caller
//** puts the parts on before freeing it.
//**
//** Desktop only: shown with ShowModal. For the main thread only.
unit Sprite3DGltfPartsForm;

{
  The Debug, glTF, Add Parts dialog: parts made for the open model's
  skeleton to put on it. Add files... loads them into a TglTFPartLibrary
  (a .gltf from its copy, if it needed one), which the dialog owns; Put on... closes with mrOk. Putting them on is the
  caller's job, before freeing the dialog. Desktop only; shown with
  ShowModal. Main thread only.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, FMX.Types,
  FMX.Controls, FMX.Forms, FMX.Graphics, FMX.StdCtrls, FMX.Layouts,
  FMX.Controls.Presentation, FMX.ListBox, System.Generics.Collections,
  glTF.Parts;

type
  //** @abstract(The Debug, glTF, Add Parts dialog; see the unit description.)
  TGltfPartsForm = class(TForm)
    //** @abstract(Says which model the parts go on.)
    InfoLabel: TLabel;
    //** @abstract(Names the list of parts.)
    PartsLabel: TLabel;
    //** @abstract(Every part found, with a box to tick.)
    PartsList: TListBox;
    //** @abstract(Chooses glTF files to load parts from, several at once.)
    AddButton: TButton;
    //** @abstract(Takes every part off the list.)
    ClearButton: TButton;
    //** @abstract(Ticks every part.)
    TickAllButton: TButton;
    //** @abstract(The strip holding the Cancel and Put on buttons.)
    ButtonLayout: TLayout;
    //** @abstract(Closes the dialog with mrCancel.)
    CancelButton: TButton;
    //** @abstract(Closes the dialog with mrOk once a part is ticked.)
    ApplyButton: TButton;
    //** @abstract(Loads parts from glTF files chosen in a file dialog, starting in Folder.)
    //**
    //** @param(Sender AddButton.)
    procedure AddButtonClick(Sender: TObject);
    //** @abstract(Takes every part off the list.)
    //**
    //** @param(Sender ClearButton.)
    procedure ClearButtonClick(Sender: TObject);
    //** @abstract(Ticks every part.)
    //**
    //** @param(Sender TickAllButton.)
    procedure TickAllButtonClick(Sender: TObject);
    //** @abstract(Closes with mrOk if a part is ticked; otherwise says so.)
    //**
    //** @param(Sender ApplyButton.)
    procedure ApplyButtonClick(Sender: TObject);
    //** @abstract(Closes the dialog with mrCancel.)
    //**
    //** @param(Sender CancelButton.)
    procedure CancelButtonClick(Sender: TObject);
    //** @abstract(Keeps the buttons in step with the ticks.)
    //**
    //** @param(Sender PartsList.)
    procedure PartsListChangeCheck(Sender: TObject);
  private
    //** The parts loaded; owned.
    FLibrary: TglTFPartLibrary;
    //** The folder Add files... opens in.
    FFolder: string;
    //** What loading the files said.
    FLog: TStringList;
    //** The file each file read was chosen as, by the file read: a .gltf's copy, when it
    //** needed one, maps to the file chosen; owned.
    FShownNames: TDictionary<string, string>;
    //** @abstract(The name to show for a file the library read: the file chosen, for a copy.)
    //**
    //** @param(AFileName The file read.)
    //**
    //** @returns(Its file name, without the folder.)
    function ShownFileName(const AFileName: string): string;
    //** The parts ticked that could be read.
    function GetTickedParts: TArray<TglTFPart>;
    //** Lists every part in the library, unticked.
    procedure ListParts;
    //** Enables the buttons that have something to act on.
    procedure UpdateButtons;
  public
    //** @abstract(Makes the library and lets InfoLabel wrap.)
    //**
    //** @param(AOwner The owner, as for any form.)
    constructor Create(AOwner: TComponent); override;
    //** @abstract(Frees the library and its parts.)
    destructor Destroy; override;
    //** @abstract(Names the model the parts go on.)
    //**
    //** @param(AModelName The open model's file name.)
    procedure SetModel(const AModelName: string);
    //** @abstract(The parts ticked; they belong to the dialog's library, so use them before
    //** freeing the dialog.)
    property TickedParts: TArray<TglTFPart> read GetTickedParts;
    //** @abstract(What loading the files said, for the Debug tab.)
    property Log: TStringList read FLog;
    //** @abstract(The folder Add files... opens in; set it before showing, read it after.)
    property Folder: string read FFolder write FFolder;
  end;

implementation

uses
  FMX.Dialogs, Sprite3DHelpers, Sprite3DModelTextures;

{$R *.fmx}

constructor TGltfPartsForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FLibrary := TglTFPartLibrary.Create;
  FLog := TStringList.Create;
  FShownNames := TDictionary<string, string>.Create;
  InfoLabel.StyledSettings := InfoLabel.StyledSettings - [TStyledSetting.Other];
  InfoLabel.TextSettings.WordWrap := True;
  InfoLabel.TextSettings.VertAlign := TTextAlign.Leading;
  UpdateButtons;
end;

destructor TGltfPartsForm.Destroy;
begin
  FLibrary.Free;
  FLog.Free;
  FShownNames.Free;
  inherited;
end;

procedure TGltfPartsForm.SetModel(const AModelName: string);
begin
  InfoLabel.Text := 'Parts rigged to the same skeleton as ' + AModelName + ' are put on it, ' +
    'bound to its bones by name. A part replaces one it covers, and hides the body under it.';
end;

procedure TGltfPartsForm.ListParts;
var
  I: Integer;
  Part: TglTFPart;
  Text: string;
begin
  PartsList.Clear;
  for I := 0 to FLibrary.Count - 1 do
  begin
    Part := FLibrary[I];
    if Part.Error <> '' then
      Text := Format('%s (%s): %s', [Part.Name, ShownFileName(Part.FileName), Part.Error])
    else
      Text := Format('%s (%s): %d triangles, covers %s', [Part.Name,
        ShownFileName(Part.FileName), Part.TriangleCount,
        Part.CoveredText(TglTFPartOptions.Default)]);
    PartsList.Items.Add(Text);
    // A part that could not be read cannot be ticked
    PartsList.ListItems[I].Enabled := Part.Error = '';
  end;
  UpdateButtons;
end;

function TGltfPartsForm.ShownFileName(const AFileName: string): string;
var
  Chosen: string;
begin
  if FShownNames.TryGetValue(AFileName, Chosen) then
    Result := ExtractFileName(Chosen)
  else
    Result := ExtractFileName(AFileName);
end;

function TGltfPartsForm.GetTickedParts: TArray<TglTFPart>;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to PartsList.Count - 1 do
    if PartsList.ListItems[I].IsChecked and (FLibrary[I].Error = '') then
      Result := Result + [FLibrary[I]];
end;

procedure TGltfPartsForm.UpdateButtons;
begin
  ClearButton.Enabled := PartsList.Count > 0;
  TickAllButton.Enabled := PartsList.Count > 0;
  ApplyButton.Enabled := Length(GetTickedParts) > 0;
end;

procedure TGltfPartsForm.AddButtonClick(Sender: TObject);
var
  Dialog: TOpenDialog;
  Files: TArray<string>;
  FileName, Chosen: string;
  Fixes: TArray<TSprite3DTextureFix>;
begin
  Dialog := TOpenDialog.Create(nil);
  try
    Dialog.Title := 'Add Parts: choose the files holding the parts';
    Dialog.Filter := 'glTF (*.glb;*.gltf)|*.glb;*.gltf';
    Dialog.Options := Dialog.Options + [TOpenOption.ofAllowMultiSelect,
      TOpenOption.ofFileMustExist];
    if (FFolder <> '') and DirectoryExists(FFolder) then
      Dialog.InitialDir := FFolder;
    if not Dialog.Execute then
      Exit;
    Files := nil;
    for FileName in Dialog.Files do
      Files := Files + [FileName];
    if Length(Files) > 0 then
      FFolder := ExtractFileDir(Files[High(Files)]);
  finally
    Dialog.Free;
  end;
  // A .gltf from a copy naming what was found or made, if it needs one, as
  // the open model is: GLTFLib cannot read a .psd or find a file that is
  // not where the model says; the copy is listed under the file's own name
  try
    for var I := 0 to High(Files) do
    begin
      Chosen := Files[I];
      Files[I] := GltfFileToRead(Chosen, Fixes);
      if Files[I] <> Chosen then
        FShownNames.AddOrSetValue(Files[I], Chosen);
      FLog.AddStrings(TextureFixReport(ExtractFileName(Chosen), Fixes));
    end;
  except
    on E: Exception do
    begin
      FLog.Add('A part file could not be made ready: ' + E.Message);
      ShowMessage('A part file could not be made ready: ' + E.Message);
      Exit;
    end;
  end;
  // Loaded here, so the parts can be listed and ticked; small files load
  // quickly, so on the main thread
  FLibrary.Log.Clear;
  try
    FLibrary.LoadFiles(Files);
  except
    on E: Exception do
      ShowMessage('The parts could not be loaded: ' + E.Message);
  end;
  FLog.AddStrings(FLibrary.Log);
  ListParts;
end;

procedure TGltfPartsForm.ClearButtonClick(Sender: TObject);
begin
  FLibrary.Clear;
  FShownNames.Clear;
  ListParts;
end;

procedure TGltfPartsForm.TickAllButtonClick(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to PartsList.Count - 1 do
    if PartsList.ListItems[I].Enabled then
      PartsList.ListItems[I].IsChecked := True;
  UpdateButtons;
end;

procedure TGltfPartsForm.ApplyButtonClick(Sender: TObject);
begin
  if Length(GetTickedParts) = 0 then
  begin
    ShowMessage('Tick at least one part to put on.');
    Exit;
  end;
  ModalResult := mrOk;
end;

procedure TGltfPartsForm.CancelButtonClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TGltfPartsForm.PartsListChangeCheck(Sender: TObject);
begin
  UpdateButtons;
end;

end.
