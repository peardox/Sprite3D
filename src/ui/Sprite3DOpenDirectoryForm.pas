//** @abstract(The File, Open Directory dialog: a folder, and which of the model files in it
//** and its sub-folders to open.)
//**
//** The folder is typed, or chosen with Browse..., which opens the system's folder dialog on
//** the desktop; Android and iOS have none, so there Browse... is disabled and the folder is
//** typed. The file spec is typed or picked from the drop-down: one or more patterns, such
//** as @code(*.glb) or @code(*.glb;*.gltf), as SplitFileSpec in Sprite3DFileSearch reads
//** them. Open checks that the folder exists and that the spec has a pattern, and says what
//** is wrong instead of closing if not. The dialog only gathers the choice: searching the
//** folder and opening the models is the caller's job.
//**
//** On the desktop, show it with ShowModal and read Folder and Spec after mrOk; on Android
//** and iOS, which cannot block, show it with ShowAndFree, which calls OnAccept on Open and
//** frees the form when it closes. For the main thread only.
unit Sprite3DOpenDirectoryForm;

{
  The File, Open Directory dialog: a folder, and which of the model files in
  it and its sub-folders to open.

  The folder is typed, or chosen with Browse... on the desktop. The file
  spec is one or more patterns, such as *.glb or *.glb;*.gltf. Open checks
  both before closing. Searching and opening is the caller's job.

  On the desktop, show it with ShowModal; on Android and iOS, with
  ShowAndFree, which calls OnAccept on Open. For the main thread only.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, FMX.Types,
  FMX.Controls, FMX.Forms, FMX.Graphics, FMX.StdCtrls, FMX.Edit, FMX.ComboEdit,
  FMX.Controls.Presentation, FMX.Layouts;

type
  //** @abstract(The File, Open Directory dialog; see the unit description.)
  TOpenDirectoryForm = class(TForm)
    //** @abstract(Names FolderEdit.)
    FolderLabel: TLabel;
    //** @abstract(The folder to search, with its sub-folders.)
    FolderEdit: TEdit;
    //** @abstract(Opens the system's folder dialog to fill FolderEdit; disabled on Android
    //** and iOS.)
    BrowseButton: TButton;
    //** @abstract(Names SpecEdit.)
    SpecLabel: TLabel;
    //** @abstract(The file spec, typed or picked: each model format alone, and glTF in both
    //** forms; AllSpec adds every format.)
    SpecEdit: TComboEdit;
    //** @abstract(Says what Open does, under the boxes.)
    NoteLabel: TLabel;
    //** @abstract(The strip holding the Cancel and Open buttons.)
    ButtonLayout: TLayout;
    //** @abstract(Closes the dialog with mrOk once the folder and spec are usable.)
    OkButton: TButton;
    //** @abstract(Closes the dialog with mrCancel; nothing is opened.)
    CancelButton: TButton;
    //** @abstract(Chooses the folder in the system's folder dialog, starting at the one typed
    //** if it exists.)
    //**
    //** @param(Sender BrowseButton.)
    procedure BrowseButtonClick(Sender: TObject);
    //** @abstract(Closes the dialog with mrOk if the folder exists and the spec has a
    //** pattern; otherwise says which is wrong and stays open.)
    //**
    //** @param(Sender OkButton.)
    procedure OkButtonClick(Sender: TObject);
    //** @abstract(Closes the dialog with mrCancel.)
    //**
    //** @param(Sender CancelButton.)
    procedure CancelButtonClick(Sender: TObject);
    //** @abstract(Reports Open when shown with ShowAndFree, and frees the form then.)
    //**
    //** @param(Sender The form.)
    //**
    //** @param(Action Set to caFree when shown with ShowAndFree.)
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    //** True when shown with ShowAndFree: the form reports and frees itself on closing.
    FFreeOnClose: Boolean;
    //** Called on Open when shown with ShowAndFree.
    FOnAccept: TNotifyEvent;
    //** FolderEdit's text, trimmed.
    function GetFolder: String;
    //** Puts Value in FolderEdit.
    procedure SetFolder(const Value: String);
    //** SpecEdit's text, trimmed.
    function GetSpec: String;
    //** Puts Value in SpecEdit, unless it is empty.
    procedure SetSpec(const Value: String);
    //** Adds Value to SpecEdit's drop-down, unless it is there.
    procedure SetAllSpec(const Value: String);
    //** Ends the dialog with AResult, closing it too when shown with ShowAndFree.
    procedure CloseWith(const AResult: TModalResult);
  public
    //** @abstract(Disables Browse... where there is no folder dialog.)
    //**
    //** @param(AOwner The owner, as for any form.)
    constructor Create(AOwner: TComponent); override;
    //** @abstract(Shows the dialog without blocking and frees it when it closes.)
    //**
    //** For Android and iOS, where ShowModal cannot block. OnAccept is called if it closes
    //** with Open.
    procedure ShowAndFree;
    //** @abstract(The folder shown, trimmed; set it before showing the dialog.)
    property Folder: String read GetFolder write SetFolder;
    //** @abstract(The file spec shown, trimmed; set it before showing the dialog, or it shows
    //** @code(*.glb).)
    property Spec: String read GetSpec write SetSpec;
    //** @abstract(A spec for every model format, added at the foot of the drop-down if it is
    //** not there already; set it before showing the dialog.)
    property AllSpec: String write SetAllSpec;
    //** @abstract(Called on Open when shown with ShowAndFree.)
    property OnAccept: TNotifyEvent read FOnAccept write FOnAccept;
  end;

implementation

uses
  System.IOUtils, FMX.Dialogs, Sprite3DFileSearch;

{$R *.fmx}

constructor TOpenDirectoryForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  {$IF DEFINED(ANDROID) or DEFINED(IOS)}
  BrowseButton.Enabled := False;
  {$ENDIF}
end;

function TOpenDirectoryForm.GetFolder: String;
begin
  Result := FolderEdit.Text.Trim;
end;

procedure TOpenDirectoryForm.SetFolder(const Value: String);
begin
  FolderEdit.Text := Value;
end;

function TOpenDirectoryForm.GetSpec: String;
begin
  Result := SpecEdit.Text.Trim;
end;

procedure TOpenDirectoryForm.SetSpec(const Value: String);
begin
  if Value.Trim <> String.Empty then
    SpecEdit.Text := Value.Trim;
end;

procedure TOpenDirectoryForm.SetAllSpec(const Value: String);
begin
  if (Value <> String.Empty) and (SpecEdit.Items.IndexOf(Value) < 0) then
    SpecEdit.Items.Add(Value);
end;

procedure TOpenDirectoryForm.BrowseButtonClick(Sender: TObject);
{$IF not (DEFINED(ANDROID) or DEFINED(IOS))}
var
  Chosen: String;
{$ENDIF}
begin
  {$IF not (DEFINED(ANDROID) or DEFINED(IOS))}
  Chosen := Folder;
  if (Chosen = String.Empty) or not TDirectory.Exists(Chosen) then
    Chosen := TPath.GetDocumentsPath;
  if SelectDirectory('Open Directory', String.Empty, Chosen) and (Chosen <> String.Empty) then
    Folder := Chosen;
  {$ENDIF}
end;

procedure TOpenDirectoryForm.OkButtonClick(Sender: TObject);
begin
  if (Folder = String.Empty) or not TDirectory.Exists(Folder) then
  begin
    ShowMessage('Choose a folder that exists.');
    Exit;
  end;
  if Length(SplitFileSpec(Spec)) = 0 then
  begin
    ShowMessage('Give at least one pattern of files to open, such as *.glb.');
    Exit;
  end;
  CloseWith(mrOk);
end;

procedure TOpenDirectoryForm.CancelButtonClick(Sender: TObject);
begin
  CloseWith(mrCancel);
end;

// ShowModal ends when ModalResult is set; a form shown with ShowAndFree is
// closed as well
procedure TOpenDirectoryForm.CloseWith(const AResult: TModalResult);
begin
  ModalResult := AResult;
  if FFreeOnClose then
    Close;
end;

procedure TOpenDirectoryForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if not FFreeOnClose then
    Exit;   // shown with ShowModal: the caller frees it
  if (ModalResult = mrOk) and Assigned(FOnAccept) then
    FOnAccept(Self);
  Action := TCloseAction.caFree;
end;

procedure TOpenDirectoryForm.ShowAndFree;
begin
  FFreeOnClose := True;
  Show;
end;

end.
