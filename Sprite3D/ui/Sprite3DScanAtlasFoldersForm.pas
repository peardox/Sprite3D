//** @abstract(The Tools, Scan Atlas Folders dialog: the root folder to search, the sheet's
//** file name, and the size of its frames.)
//**
//** The root is typed or chosen with Browse...; every folder below it, however deep, is
//** searched for files with the sheet's name (@code(Spritesheet.png) unless the caller
//** says otherwise), ignoring case. The frame width and height are typed or stepped, from 1
//** to SCAN_ATLAS_MAX_FRAME pixels. Scan checks the root exists and the name is a name, not
//** a path, and closes with mrOk; searching and scanning are the caller's job.
//**
//** Desktop only, as the Tools menu is: shown with ShowModal. For the main thread only.
unit Sprite3DScanAtlasFoldersForm;

{
  The Tools, Scan Atlas Folders dialog: the root folder to search, the
  sheet's file name, and the size of its frames.

  The root is typed or chosen with Browse...; every folder below it is
  searched for files with the sheet's name, ignoring case. Scan checks the
  root exists and the name is a name, and closes with mrOk. Searching and
  scanning are the caller's job. Desktop only; shown with ShowModal. Main
  thread only.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, FMX.Types,
  FMX.Controls, FMX.Forms, FMX.Graphics, FMX.StdCtrls, FMX.Layouts,
  FMX.Controls.Presentation, FMX.Edit, FMX.SpinBox, FMX.EditBox;

const
  //** @abstract(The sheet's file name the dialog offers until another is given.)
  SCAN_ATLAS_FOLDERS_DEFAULT_NAME = 'Spritesheet.png';

type
  //** @abstract(The Tools, Scan Atlas Folders dialog; see the unit description.)
  TScanAtlasFoldersForm = class(TForm)
    //** @abstract(Names the root box.)
    RootLabel: TLabel;
    //** @abstract(The folder to search below, as a full path.)
    RootEdit: TEdit;
    //** @abstract(Chooses the root in the system's folder dialog.)
    BrowseButton: TButton;
    //** @abstract(Names the file name box.)
    FileNameLabel: TLabel;
    //** @abstract(The sheet's file name, without a folder.)
    FileNameEdit: TEdit;
    //** @abstract(Names the frame size boxes.)
    SizeLabel: TLabel;
    //** @abstract(The width of every frame, in pixels.)
    WidthBox: TSpinBox;
    //** @abstract(The "x" between the width and height boxes.)
    ByLabel: TLabel;
    //** @abstract(The height of every frame, in pixels.)
    HeightBox: TSpinBox;
    //** @abstract(The strip holding the Cancel and Scan buttons.)
    ButtonLayout: TLayout;
    //** @abstract(Closes the dialog with mrOk once the root and name are good.)
    ScanButton: TButton;
    //** @abstract(Closes the dialog with mrCancel; nothing is scanned.)
    CancelButton: TButton;
    //** @abstract(Chooses the root in the system's folder dialog, starting at the one typed.)
    //**
    //** @param(Sender BrowseButton.)
    procedure BrowseButtonClick(Sender: TObject);
    //** @abstract(Closes the dialog with mrOk if the root exists and the file name is a name
    //** without a folder; otherwise says what is wrong and stays open.)
    //**
    //** @param(Sender ScanButton.)
    procedure ScanButtonClick(Sender: TObject);
    //** @abstract(Closes the dialog with mrCancel.)
    //**
    //** @param(Sender CancelButton.)
    procedure CancelButtonClick(Sender: TObject);
  private
    //** RootEdit's text, trimmed.
    function GetRoot: String;
    //** Puts Value in RootEdit.
    procedure SetRoot(const Value: String);
    //** FileNameEdit's text, trimmed.
    function GetFileName: String;
    //** Puts Value in FileNameEdit, or SCAN_ATLAS_FOLDERS_DEFAULT_NAME if it is empty.
    procedure SetFileName(const Value: String);
    //** WidthBox's value, as a whole number.
    function GetFrameWidth: Integer;
    //** Puts Value in WidthBox, kept to 1 .. SCAN_ATLAS_MAX_FRAME.
    procedure SetFrameWidth(const Value: Integer);
    //** HeightBox's value, as a whole number.
    function GetFrameHeight: Integer;
    //** Puts Value in HeightBox, kept to 1 .. SCAN_ATLAS_MAX_FRAME.
    procedure SetFrameHeight(const Value: Integer);
  public
    //** @abstract(Sets the frame boxes' range and the default file name.)
    //**
    //** @param(AOwner The owner, as for any form.)
    constructor Create(AOwner: TComponent); override;
    //** @abstract(The folder to search below, as a full path.)
    property Root: String read GetRoot write SetRoot;
    //** @abstract(The sheet's file name, without a folder.)
    property FileName: String read GetFileName write SetFileName;
    //** @abstract(The width of every frame, in pixels.)
    property FrameWidth: Integer read GetFrameWidth write SetFrameWidth;
    //** @abstract(The height of every frame, in pixels.)
    property FrameHeight: Integer read GetFrameHeight write SetFrameHeight;
  end;

implementation

uses
  System.Math, System.IOUtils, FMX.Dialogs, Sprite3DScanAtlasForm;

{$R *.fmx}

constructor TScanAtlasFoldersForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  WidthBox.Min := 1;
  WidthBox.Max := SCAN_ATLAS_MAX_FRAME;
  HeightBox.Min := 1;
  HeightBox.Max := SCAN_ATLAS_MAX_FRAME;
  FileNameEdit.Text := SCAN_ATLAS_FOLDERS_DEFAULT_NAME;
end;

function TScanAtlasFoldersForm.GetRoot: String;
begin
  Result := RootEdit.Text.Trim;
end;

procedure TScanAtlasFoldersForm.SetRoot(const Value: String);
begin
  RootEdit.Text := Value;
end;

function TScanAtlasFoldersForm.GetFileName: String;
begin
  Result := FileNameEdit.Text.Trim;
end;

procedure TScanAtlasFoldersForm.SetFileName(const Value: String);
begin
  if Value.Trim = String.Empty then
    FileNameEdit.Text := SCAN_ATLAS_FOLDERS_DEFAULT_NAME
  else
    FileNameEdit.Text := Value.Trim;
end;

function TScanAtlasFoldersForm.GetFrameWidth: Integer;
begin
  Result := Round(WidthBox.Value);
end;

procedure TScanAtlasFoldersForm.SetFrameWidth(const Value: Integer);
begin
  WidthBox.Value := EnsureRange(Value, 1, SCAN_ATLAS_MAX_FRAME);
end;

function TScanAtlasFoldersForm.GetFrameHeight: Integer;
begin
  Result := Round(HeightBox.Value);
end;

procedure TScanAtlasFoldersForm.SetFrameHeight(const Value: Integer);
begin
  HeightBox.Value := EnsureRange(Value, 1, SCAN_ATLAS_MAX_FRAME);
end;

procedure TScanAtlasFoldersForm.BrowseButtonClick(Sender: TObject);
var
  Chosen: String;
begin
  Chosen := Root;
  if (Chosen = String.Empty) or not TDirectory.Exists(Chosen) then
    Chosen := TPath.GetDocumentsPath;
  if SelectDirectory('Scan Atlas Folders: the folder to search', String.Empty, Chosen) and
    (Chosen <> String.Empty) then
    Root := Chosen;
end;

procedure TScanAtlasFoldersForm.ScanButtonClick(Sender: TObject);
begin
  if (Root = String.Empty) or not TDirectory.Exists(Root) then
  begin
    ShowMessage('Choose a folder that exists to search.');
    Exit;
  end;
  if (FileName = String.Empty) or (ExtractFileName(FileName) <> FileName) then
  begin
    ShowMessage('Give the sheet''s file name, such as ' + SCAN_ATLAS_FOLDERS_DEFAULT_NAME +
      ', without a folder.');
    Exit;
  end;
  ModalResult := mrOk;
end;

procedure TScanAtlasFoldersForm.CancelButtonClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

end.
