//** @abstract(The Tools, Scan Atlas dialog: the size of an atlas's frames, and the sheets
//** that make it up.)
//**
//** The frame width and height are typed or stepped, from 1 to SCAN_ATLAS_MAX_FRAME pixels.
//** The sheets are listed in the order they were added: Add... opens a file dialog for PNG
//** files, where several can be chosen at once, and adds those not listed already; Remove
//** takes the selected sheet off the list, and Clear takes them all. Scan checks there is at
//** least one sheet and closes the dialog with mrOk; whether each sheet is a whole number
//** of frames is for the scan to find. The dialog only gathers the choice: scanning is the
//** caller's job.
//**
//** Desktop only, as the Tools menu is: shown with ShowModal. For the main thread only.
unit Sprite3DScanAtlasForm;

{
  The Tools, Scan Atlas dialog: the size of an atlas's frames, and the sheets
  that make it up.

  The frame width and height are typed or stepped. Add... chooses PNG
  sheets, several at once; Remove and Clear take them off the list. Scan
  checks there is at least one sheet and closes with mrOk. Scanning is the
  caller's job. Desktop only; shown with ShowModal. Main thread only.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, FMX.Types,
  FMX.Controls, FMX.Forms, FMX.Graphics, FMX.StdCtrls, FMX.Layouts,
  FMX.Controls.Presentation, FMX.Edit, FMX.SpinBox, FMX.EditBox, FMX.ListBox;

const
  //** @abstract(The largest frame width or height the dialog accepts, in pixels.)
  SCAN_ATLAS_MAX_FRAME = 16384;

type
  //** @abstract(The Tools, Scan Atlas dialog; see the unit description.)
  TScanAtlasForm = class(TForm)
    //** @abstract(Names the frame size boxes.)
    SizeLabel: TLabel;
    //** @abstract(The width of every frame, in pixels.)
    WidthBox: TSpinBox;
    //** @abstract(The "x" between the width and height boxes.)
    ByLabel: TLabel;
    //** @abstract(The height of every frame, in pixels.)
    HeightBox: TSpinBox;
    //** @abstract(Names the list of sheets.)
    SheetsLabel: TLabel;
    //** @abstract(The sheets, as full paths, in the order they were added.)
    SheetsList: TListBox;
    //** @abstract(Chooses PNG sheets to add, several at once.)
    AddButton: TButton;
    //** @abstract(Takes the selected sheet off the list.)
    RemoveButton: TButton;
    //** @abstract(Takes every sheet off the list.)
    ClearButton: TButton;
    //** @abstract(The strip holding the Cancel and Scan buttons.)
    ButtonLayout: TLayout;
    //** @abstract(Closes the dialog with mrOk once there is a sheet to scan.)
    ScanButton: TButton;
    //** @abstract(Closes the dialog with mrCancel; nothing is scanned.)
    CancelButton: TButton;
    //** @abstract(Chooses PNG sheets in a file dialog, starting in Folder, and adds those
    //** not listed already.)
    //**
    //** @param(Sender AddButton.)
    procedure AddButtonClick(Sender: TObject);
    //** @abstract(Takes the selected sheet off the list.)
    //**
    //** @param(Sender RemoveButton.)
    procedure RemoveButtonClick(Sender: TObject);
    //** @abstract(Takes every sheet off the list.)
    //**
    //** @param(Sender ClearButton.)
    procedure ClearButtonClick(Sender: TObject);
    //** @abstract(Closes the dialog with mrOk if there is at least one sheet; otherwise says
    //** so and stays open.)
    //**
    //** @param(Sender ScanButton.)
    procedure ScanButtonClick(Sender: TObject);
    //** @abstract(Closes the dialog with mrCancel.)
    //**
    //** @param(Sender CancelButton.)
    procedure CancelButtonClick(Sender: TObject);
    //** @abstract(Enables Remove once a sheet is selected.)
    //**
    //** @param(Sender SheetsList.)
    procedure SheetsListChange(Sender: TObject);
  private
    //** The folder Add... opens in; set to the last sheet's folder after each add.
    FFolder: String;
    //** WidthBox's value, as a whole number.
    function GetFrameWidth: Integer;
    //** Puts Value in WidthBox, kept to 1 .. SCAN_ATLAS_MAX_FRAME.
    procedure SetFrameWidth(const Value: Integer);
    //** HeightBox's value, as a whole number.
    function GetFrameHeight: Integer;
    //** Puts Value in HeightBox, kept to 1 .. SCAN_ATLAS_MAX_FRAME.
    procedure SetFrameHeight(const Value: Integer);
    //** The sheets listed, as full paths, in order.
    function GetFiles: TArray<String>;
    //** Lists the sheets given, in order, replacing any listed.
    procedure SetFiles(const Value: TArray<String>);
    //** @abstract(Adds a sheet to the list unless it is there already, ignoring case.)
    //** @param(AFile The sheet, as a full path.)
    procedure AddFile(const AFile: String);
    //** @abstract(Enables Remove and Clear when there is something for them to take off.)
    procedure UpdateButtons;
  public
    //** @abstract(Sets the frame boxes' range and the buttons.)
    //**
    //** @param(AOwner The owner, as for any form.)
    constructor Create(AOwner: TComponent); override;
    //** @abstract(The width of every frame, in pixels; set it before showing the dialog.)
    property FrameWidth: Integer read GetFrameWidth write SetFrameWidth;
    //** @abstract(The height of every frame, in pixels; set it before showing the dialog.)
    property FrameHeight: Integer read GetFrameHeight write SetFrameHeight;
    //** @abstract(The sheets, as full paths, in order; may be set before showing the
    //** dialog.)
    property Files: TArray<String> read GetFiles write SetFiles;
    //** @abstract(The folder Add... opens in; set it before showing the dialog, and read it
    //** afterwards for the folder the last sheets were added from.)
    property Folder: String read FFolder write FFolder;
  end;

implementation

uses
  System.Math, FMX.Dialogs;

{$R *.fmx}

constructor TScanAtlasForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  WidthBox.Min := 1;
  WidthBox.Max := SCAN_ATLAS_MAX_FRAME;
  HeightBox.Min := 1;
  HeightBox.Max := SCAN_ATLAS_MAX_FRAME;
  UpdateButtons;
end;

function TScanAtlasForm.GetFrameWidth: Integer;
begin
  Result := Round(WidthBox.Value);
end;

procedure TScanAtlasForm.SetFrameWidth(const Value: Integer);
begin
  WidthBox.Value := EnsureRange(Value, 1, SCAN_ATLAS_MAX_FRAME);
end;

function TScanAtlasForm.GetFrameHeight: Integer;
begin
  Result := Round(HeightBox.Value);
end;

procedure TScanAtlasForm.SetFrameHeight(const Value: Integer);
begin
  HeightBox.Value := EnsureRange(Value, 1, SCAN_ATLAS_MAX_FRAME);
end;

function TScanAtlasForm.GetFiles: TArray<String>;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to SheetsList.Count - 1 do
    Result := Result + [SheetsList.Items[I]];
end;

procedure TScanAtlasForm.SetFiles(const Value: TArray<String>);
var
  FileName: String;
begin
  SheetsList.Clear;
  for FileName in Value do
    AddFile(FileName);
  UpdateButtons;
end;

procedure TScanAtlasForm.AddFile(const AFile: String);
var
  I: Integer;
begin
  for I := 0 to SheetsList.Count - 1 do
    if SameText(SheetsList.Items[I], AFile) then
      Exit;
  SheetsList.Items.Add(AFile);
end;

procedure TScanAtlasForm.UpdateButtons;
begin
  RemoveButton.Enabled := SheetsList.ItemIndex >= 0;
  ClearButton.Enabled := SheetsList.Count > 0;
end;

procedure TScanAtlasForm.AddButtonClick(Sender: TObject);
var
  Dialog: TOpenDialog;
  FileName: String;
begin
  Dialog := TOpenDialog.Create(nil);
  try
    Dialog.Title := 'Scan Atlas: choose the sheets';
    Dialog.Filter := 'PNG images (*.png)|*.png';
    Dialog.Options := Dialog.Options + [TOpenOption.ofAllowMultiSelect,
      TOpenOption.ofFileMustExist];
    if (FFolder <> String.Empty) and DirectoryExists(FFolder) then
      Dialog.InitialDir := FFolder;
    if not Dialog.Execute then
      Exit;
    // The dialog's own order, usually name order, which is the sheets' order
    for FileName in Dialog.Files do
      AddFile(FileName);
    if Dialog.Files.Count > 0 then
      FFolder := ExtractFileDir(Dialog.Files[Dialog.Files.Count - 1]);
  finally
    Dialog.Free;
  end;
  UpdateButtons;
end;

procedure TScanAtlasForm.RemoveButtonClick(Sender: TObject);
var
  Index: Integer;
begin
  Index := SheetsList.ItemIndex;
  if Index < 0 then
    Exit;
  SheetsList.Items.Delete(Index);
  if SheetsList.Count > 0 then
    SheetsList.ItemIndex := Min(Index, SheetsList.Count - 1);
  UpdateButtons;
end;

procedure TScanAtlasForm.ClearButtonClick(Sender: TObject);
begin
  SheetsList.Clear;
  UpdateButtons;
end;

procedure TScanAtlasForm.ScanButtonClick(Sender: TObject);
begin
  if SheetsList.Count = 0 then
  begin
    ShowMessage('Add at least one sheet to scan.');
    Exit;
  end;
  ModalResult := mrOk;
end;

procedure TScanAtlasForm.CancelButtonClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TScanAtlasForm.SheetsListChange(Sender: TObject);
begin
  UpdateButtons;
end;

end.
