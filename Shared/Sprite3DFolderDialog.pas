//** @abstract(The system's folder dialog, letting the user choose several folders at once
//** where the platform can.)
//**
//** SelectFolders shows the dialog and returns the folders chosen, as full paths:
//**
//** @unorderedList(
//**   @item(@bold(Windows): the system's folder dialog (@code(IFileOpenDialog) picking
//**     folders), with several folders chosen by Ctrl- or Shift-clicking. If it cannot be
//**     made, FMX's own single-folder dialog is shown instead.)
//**   @item(@bold(macOS): an @code(NSOpenPanel) for folders, with several chosen by
//**     Command- or Shift-clicking.)
//**   @item(@bold(Linux): FMX's folder dialog, which chooses one folder.)
//**   @item(@bold(Android and iOS): there is no folder dialog, so it returns False at once.)
//** )
//**
//** The unit knows nothing of the application. For the main thread only, as every dialog is.
unit Sprite3DFolderDialog;

{
  The system's folder dialog, letting the user choose several folders at
  once where the platform can.

  SelectFolders shows the dialog and returns the folders chosen, as full
  paths. Windows: the system's folder dialog (IFileOpenDialog picking
  folders), several chosen by Ctrl- or Shift-clicking, falling back to FMX's
  single-folder dialog if it cannot be made. macOS: an NSOpenPanel for
  folders, several chosen likewise. Linux: FMX's folder dialog, one folder.
  Android and iOS have no folder dialog: it returns False at once.

  The unit knows nothing of the application. Main thread only.
}

interface

uses
  System.SysUtils;

//** @abstract(Whether this platform's folder dialog can choose more than one folder.)
//**
//** True on Windows and macOS, False on Linux, Android and iOS. A caller can use it to say
//** how to choose several, or to offer another way.
//**
//** @returns(True if SelectFolders can return several folders.)
function CanSelectSeveralFolders: Boolean;

//** @abstract(Shows the system's folder dialog and returns the folders chosen.)
//**
//** For the main thread only. The dialog is modal over the application's active form.
//**
//** @param(ATitle The dialog's title, or its message where the platform shows no title.)
//**
//** @param(AStartFolder The folder the dialog opens in, if it exists; otherwise the
//** platform chooses.)
//**
//** @param(AFolders On return, the folders chosen, as full paths, in the order the dialog
//** gives them; empty if none.)
//**
//** @returns(True if at least one folder was chosen; False if the dialog was cancelled, or
//** the platform has no folder dialog.)
function SelectFolders(const ATitle, AStartFolder: String;
  out AFolders: TArray<String>): Boolean;

implementation

{$IF DEFINED(MSWINDOWS)}
uses
  Winapi.Windows, Winapi.ActiveX, Winapi.ShlObj, FMX.Forms, FMX.Platform.Win, FMX.Dialogs;
{$ELSEIF DEFINED(MACOS) and not DEFINED(IOS)}
uses
  Macapi.AppKit, Macapi.Foundation, Macapi.Helpers;
{$ELSEIF DEFINED(LINUX) and not DEFINED(ANDROID)}
uses
  FMX.Dialogs;
{$ENDIF}

function CanSelectSeveralFolders: Boolean;
begin
  {$IF DEFINED(MSWINDOWS) or (DEFINED(MACOS) and not DEFINED(IOS))}
  Result := True;
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

{$IF DEFINED(MSWINDOWS) or (DEFINED(LINUX) and not DEFINED(ANDROID))}
//** @abstract(FMX's own folder dialog, choosing one folder: Linux's dialog, and Windows'
//** if the system's cannot be made.)
//** @param(ATitle The dialog's title.)
//** @param(AStartFolder The folder it opens in, if it exists.)
//** @param(AFolders On return, the one folder chosen, or empty.)
//** @returns(True if a folder was chosen.)
function SelectOneFolder(const ATitle, AStartFolder: String;
  out AFolders: TArray<String>): Boolean;
var
  Chosen: String;
begin
  AFolders := nil;
  Chosen := AStartFolder;
  if (Chosen <> String.Empty) and not DirectoryExists(Chosen) then
    Chosen := String.Empty;
  Result := SelectDirectory(ATitle, String.Empty, Chosen) and (Chosen <> String.Empty);
  if Result then
    AFolders := [Chosen];
end;
{$ENDIF}

{$IF DEFINED(MSWINDOWS)}
// The common item dialog, set to pick folders, several at once. The window
// handle is the active form's, so the dialog is modal over it as FMX's own
// dialogs are. Every call's result is checked: a failure before Show falls
// back to FMX's single-folder dialog, and a cancel (or any failure after)
// returns False.
function SelectFolders(const ATitle, AStartFolder: String;
  out AFolders: TArray<String>): Boolean;
var
  Dialog: IFileOpenDialog;
  Options: DWORD;
  StartItem, Item: IShellItem;
  Items: IShellItemArray;
  Count, I: DWORD;
  Path: PWideChar;
  Owner: HWND;
begin
  AFolders := nil;
  Result := False;
  if Failed(CoCreateInstance(CLSID_FileOpenDialog, nil, CLSCTX_INPROC_SERVER,
    IFileOpenDialog, Dialog)) or Failed(Dialog.GetOptions(Options)) or
    Failed(Dialog.SetOptions(Options or FOS_PICKFOLDERS or FOS_ALLOWMULTISELECT or
    FOS_FORCEFILESYSTEM or FOS_PATHMUSTEXIST)) then
  begin
    Result := SelectOneFolder(ATitle, AStartFolder, AFolders);
    Exit;
  end;
  Dialog.SetTitle(PWideChar(ATitle));
  if (AStartFolder <> String.Empty) and DirectoryExists(AStartFolder) and
    Succeeded(SHCreateItemFromParsingName(PWideChar(AStartFolder), nil, IShellItem,
    StartItem)) then
    Dialog.SetFolder(StartItem);
  Owner := 0;
  if Screen.ActiveForm <> nil then
    Owner := FormToHWND(Screen.ActiveForm)
  else if Application.MainForm <> nil then
    Owner := FormToHWND(Application.MainForm);
  // S_OK only when folders were chosen; cancelling gives ERROR_CANCELLED
  if Dialog.Show(Owner) <> S_OK then
    Exit;
  if Failed(Dialog.GetResults(Items)) or Failed(Items.GetCount(Count)) then
    Exit;
  if Count = 0 then
    Exit;
  for I := 0 to Count - 1 do
  begin
    Item := nil;
    if Failed(Items.GetItemAt(I, Item)) or (Item = nil) then
      Continue;
    Path := nil;
    if Succeeded(Item.GetDisplayName(SIGDN_FILESYSPATH, Path)) and (Path <> nil) then
      try
        AFolders := AFolders + [String(Path)];
      finally
        CoTaskMemFree(Path);
      end;
  end;
  Result := Length(AFolders) > 0;
end;

{$ELSEIF DEFINED(MACOS) and not DEFINED(IOS)}
// An NSOpenPanel for folders only, several at once. It runs modal itself,
// as FMX's own open dialogs do on macOS. NSModalResponseOK is 1.
function SelectFolders(const ATitle, AStartFolder: String;
  out AFolders: TArray<String>): Boolean;
const
  MODAL_RESPONSE_OK = 1;
var
  Panel: NSOpenPanel;
  URLs: NSArray;
  URL: NSURL;
  I: NSUInteger;
begin
  AFolders := nil;
  Result := False;
  Panel := TNSOpenPanel.Wrap(TNSOpenPanel.OCClass.openPanel);
  Panel.setCanChooseDirectories(True);
  Panel.setCanChooseFiles(False);
  Panel.setAllowsMultipleSelection(True);
  // An open panel shows its message, not a title, above the folders
  Panel.setMessage(StrToNSStr(ATitle));
  if (AStartFolder <> String.Empty) and DirectoryExists(AStartFolder) then
    Panel.setDirectoryURL(TNSURL.Wrap(TNSURL.OCClass.fileURLWithPath(
      StrToNSStr(AStartFolder))));
  if Panel.runModal <> MODAL_RESPONSE_OK then
    Exit;
  URLs := Panel.URLs;
  if (URLs = nil) or (URLs.count = 0) then
    Exit;
  for I := 0 to URLs.count - 1 do
  begin
    URL := TNSURL.Wrap(URLs.objectAtIndex(I));
    if URL.isFileURL then
      AFolders := AFolders + [NSStrToStr(URL.path)];
  end;
  Result := Length(AFolders) > 0;
end;

{$ELSEIF DEFINED(LINUX) and not DEFINED(ANDROID)}
// FMX's folder dialog chooses one folder on Linux
function SelectFolders(const ATitle, AStartFolder: String;
  out AFolders: TArray<String>): Boolean;
begin
  Result := SelectOneFolder(ATitle, AStartFolder, AFolders);
end;

{$ELSE}
// Android and iOS have no folder dialog
function SelectFolders(const ATitle, AStartFolder: String;
  out AFolders: TArray<String>): Boolean;
begin
  AFolders := nil;
  Result := False;
end;
{$ENDIF}

end.
