//** @abstract(Support routines for the Sprite3D application that are neither UI nor library.)
//**
//** The application keeps three kinds of code apart. The units in @code(ui) only handle the
//** user interface; the units in @code(lib) are a library with no knowledge of this
//** application, usable in other projects; and this unit holds what is left: the
//** application's own rules, such as where models are found, how grabs are named and saved,
//** and how a loaded model is placed. It uses the library and the RTL, never the UI.
//**
//** Loading a model through LoadModelFile also registers Gorilla3D's loaders for glTF, FBX,
//** OBJ, USD, Collada, STL and PLY files, as this unit uses them.
//**
//** All routines are for the main thread.
unit Sprite3DHelpers;

{
  Support routines for the Sprite3D application that are neither UI nor
  library.

  The application keeps three kinds of code apart. The units in ui only
  handle the user interface; the units in lib are a library with no
  knowledge of this application, usable in other projects; and this unit
  holds what is left: the application's own rules, such as where models are
  found, how grabs are named and saved, and how a loaded model is placed.
  It uses the library and the RTL, never the UI.

  Loading a model through LoadModelFile also registers Gorilla3D's loaders
  for glTF, FBX, OBJ, USD, Collada, STL and PLY files, as this unit uses
  them.

  All routines are for the main thread.
}

interface

uses
  System.SysUtils, System.Types, System.Math.Vectors,
  FMX.Graphics, FMX.Types3D, FMX.Controls3D,
  Gorilla.Model;

type
  //** @abstract(Protected-access helper for TControl3D; nothing in the project uses it yet.)
  //**
  //** Casting a TControl3D to this class exposes its protected members inside the unit that
  //** declares the cast. Because it is in the interface section, other units can use it too.
  /// <summary>Protected-access helper for TControl3D; nothing in the project uses it
  /// yet.</summary>
  /// <remarks>Casting a TControl3D to this class exposes its protected members inside the unit
  /// that declares the cast. Because it is in the interface section, other units can use it
  /// too.</remarks>
  TControl3DAccess = class(TControl3D);

//** @abstract(Shifts an angle in degrees by whole turns into the range 0 to 360.)
//**
//** @param(ADegrees Any angle in degrees, negative or past a full turn.)
//**
//** @returns(The same direction as an angle from 0 up to, but not including, 360.)
/// <summary>Shifts an angle in degrees by whole turns into the range 0 to 360.</summary>
/// <param name="ADegrees">Any angle in degrees, negative or past a full turn.</param>
/// <returns>The same direction as an angle from 0 up to, but not including, 360.</returns>
function Wrap360(const ADegrees: Single): Single;

//** @abstract(Formats an angle from Wrap360 as whole degrees for a readout.)
//**
//** Rounds to the nearest degree, so 359.6 shows as 0, never 360, and pads to three
//** characters so readouts stay the same width.
//**
//** @param(ADegrees An angle from 0 up to 360.)
//**
//** @returns(The angle as text, such as @code('  0') or @code(' 45').)
/// <summary>Formats an angle from Wrap360 as whole degrees for a readout.</summary>
/// <remarks>Rounds to the nearest degree, so 359.6 shows as 0, never 360, and pads to three
/// characters so readouts stay the same width.</remarks>
/// <param name="ADegrees">An angle from 0 up to 360.</param>
/// <returns>The angle as text, such as <c>'  0'</c> or <c>' 45'</c>.</returns>
function DegreesText(const ADegrees: Single): String;

//** @abstract(The folder that holds the application's models folder, for this platform.)
//**
//** The library path on macOS, the home folder on Linux and @code('../../../') elsewhere;
//** on Windows it is the current folder instead, returned as an empty string, if that has a
//** models subfolder.
//**
//** @returns(A folder path ending in a path delimiter, or empty for the current folder.)
/// <summary>The folder that holds the application's models folder, for this
/// platform.</summary>
/// <remarks>The library path on macOS, the home folder on Linux and <c>'../../../'</c>
/// elsewhere; on Windows it is the current folder instead, returned as an empty string, if
/// that has a models subfolder.</remarks>
/// <returns>A folder path ending in a path delimiter, or empty for the current
/// folder.</returns>
function DefaultModelDir: String;

//** @abstract(The folder grabs are saved in without asking, or empty where the user should
//** choose.)
//**
//** Android and iOS have no folder dialog, so there grabs go to a fixed Grabs folder the
//** user can reach: under the app's public storage on Android, which shows over USB or in a
//** file manager, and under its Documents folder on iOS, which shows in the Files app once
//** the app enables file sharing in its Info.plist. Elsewhere this returns an empty string.
//**
//** @returns(The fixed grab folder on Android and iOS; an empty string on other platforms.)
/// <summary>The folder grabs are saved in without asking, or empty where the user should
/// choose.</summary>
/// <remarks>Android and iOS have no folder dialog, so there grabs go to a fixed Grabs folder
/// the user can reach: under the app's public storage on Android, which shows over USB or in a
/// file manager, and under its Documents folder on iOS, which shows in the Files app once the
/// app enables file sharing in its Info.plist. Elsewhere this returns an empty
/// string.</remarks>
/// <returns>The fixed grab folder on Android and iOS; an empty string on other
/// platforms.</returns>
function DefaultGrabFolder: String;

//** @abstract(The first free numbered file name in a folder, such as grab001.png.)
//**
//** Starts at ANumber and moves it past every name already taken, so an existing file is
//** never chosen. Numbers have at least three digits. The file is not created.
//**
//** @param(AFolder The folder to look in.)
//**
//** @param(APrefix The start of the file name, such as @code('grab').)
//**
//** @param(AExtension The extension, with its dot, such as @code('.png').)
//**
//** @param(ANumber The number to try first; on return, the number of the name returned.)
//**
//** @returns(The full path of the first name that does not exist yet.)
/// <summary>The first free numbered file name in a folder, such as grab001.png.</summary>
/// <remarks>Starts at ANumber and moves it past every name already taken, so an existing file
/// is never chosen. Numbers have at least three digits. The file is not created.</remarks>
/// <param name="AFolder">The folder to look in.</param>
/// <param name="APrefix">The start of the file name, such as <c>'grab'</c>.</param>
/// <param name="AExtension">The extension, with its dot, such as <c>'.png'</c>.</param>
/// <param name="ANumber">The number to try first; on return, the number of the name
/// returned.</param>
/// <returns>The full path of the first name that does not exist yet.</returns>
function NextNumberedFileName(const AFolder, APrefix, AExtension: String;
  var ANumber: Integer): String;

//** @abstract(Saves a grab as the next free grabNNN.png in a folder.)
//**
//** Creates the folder if needed, picks the name with NextNumberedFileName starting at
//** ANumber, saves ABitmap there as PNG and moves ANumber on to the next number. Blocks
//** while the file is written.
//**
//** @param(ABitmap The image to save; it is not freed.)
//**
//** @param(AFolder The folder to save in.)
//**
//** @param(ANumber The number to try first; on return, one past the number used. Unchanged
//** if the save fails.)
//**
//** @returns(The full path of the file written.)
//**
//** @raises(Exception If the folder cannot be created or the file cannot be written; the
//** class depends on the cause.)
/// <summary>Saves a grab as the next free grabNNN.png in a folder.</summary>
/// <remarks>Creates the folder if needed, picks the name with NextNumberedFileName starting
/// at ANumber, saves ABitmap there as PNG and moves ANumber on to the next number. Blocks
/// while the file is written.</remarks>
/// <param name="ABitmap">The image to save; it is not freed.</param>
/// <param name="AFolder">The folder to save in.</param>
/// <param name="ANumber">The number to try first; on return, one past the number used.
/// Unchanged if the save fails.</param>
/// <returns>The full path of the file written.</returns>
/// <exception cref="Exception">If the folder cannot be created or the file cannot be
/// written; the class depends on the cause.</exception>
function SaveGrab(const ABitmap: TBitmap; const AFolder: String;
  var ANumber: Integer): String;

//** @abstract(Replaces a model's contents with a model file and starts its last animation.)
//**
//** Clears AModel, loads AFileName into it, and, if the file has animations, plays the one
//** whose name sorts last. Blocks while the file loads.
//**
//** @param(AModel The model to load into; its old contents are removed first.)
//**
//** @param(AFileName A glTF, FBX, OBJ, USD, Collada, STL or PLY file.)
//**
//** @param(ABox The model's bounding box straight after loading, before anything is added
//** to it or it is moved; pass it to PlaceModel.)
//**
//** @returns(The names of the model's animations in sorted order; empty if it has none.)
//**
//** @raises(Exception If the file cannot be read or loaded; AModel is then left cleared or
//** part-loaded.)
/// <summary>Replaces a model's contents with a model file and starts its last
/// animation.</summary>
/// <remarks>Clears AModel, loads AFileName into it, and, if the file has animations, plays the
/// one whose name sorts last. Blocks while the file loads.</remarks>
/// <param name="AModel">The model to load into; its old contents are removed first.</param>
/// <param name="AFileName">A glTF, FBX, OBJ, USD, Collada, STL or PLY file.</param>
/// <param name="ABox">The model's bounding box straight after loading, before anything is
/// added to it or it is moved; pass it to PlaceModel.</param>
/// <returns>The names of the model's animations in sorted order; empty if it has
/// none.</returns>
/// <exception cref="Exception">If the file cannot be read or loaded; AModel is then left
/// cleared or part-loaded.</exception>
function LoadModelFile(const AModel: TGorillaModel; const AFileName: String;
  out ABox: TBoundingBox): TArray<String>;

//** @abstract(Centres a loaded model on its bounding box and turns it right way up.)
//**
//** Moves AModel to the centre of ABox and turns it 180 degrees about X, which the
//** application's models need to stand upright.
//**
//** @param(AModel The model to place.)
//**
//** @param(ABox The box LoadModelFile returned for it.)
/// <summary>Centres a loaded model on its bounding box and turns it right way up.</summary>
/// <remarks>Moves AModel to the centre of ABox and turns it 180 degrees about X, which the
/// application's models need to stand upright.</remarks>
/// <param name="AModel">The model to place.</param>
/// <param name="ABox">The box LoadModelFile returned for it.</param>
procedure PlaceModel(const AModel: TGorillaModel; const ABox: TBoundingBox);

implementation

uses
  System.Classes, System.Math, System.IOUtils,
  Gorilla.Animation,
  Gorilla.GLB.Loader,
  Gorilla.GLTF.Loader,
  Gorilla.OBJ.Loader,
  Gorilla.USD.Loader,
  Gorilla.FBX.Loader,
  Gorilla.DAE.Loader,
  Gorilla.STL.Loader,
  Gorilla.PLY.Loader;

const
  // The turn every loaded model is given so that it stands upright
  MODEL_ROTATION: TPoint3D = (X: 180; Y: 0; Z: 0);

function Wrap360(const ADegrees: Single): Single;
begin
  Result := ADegrees - 360 * Floor(ADegrees / 360);
end;

function DegreesText(const ADegrees: Single): String;
begin
  Result := Format('%3d', [Round(ADegrees) mod 360]);
end;

function DefaultModelDir: String;
begin
  {$IF DEFINED(MACOS)}
  Result := IncludeTrailingPathDelimiter(TPath.GetLibraryPath);
  {$ELSEIF DEFINED(LINUX)}
  Result := IncludeTrailingPathDelimiter(TPath.GetHomePath);
  {$ELSE}
  Result := '../../../';
  {$ENDIF}

  {$IF DEFINED(MSWINDOWS)}
  if DirectoryExists('models') then
    Result := String.Empty;
  {$ENDIF}
end;

function DefaultGrabFolder: String;
begin
  {$IF DEFINED(ANDROID)}
  Result := TPath.Combine(TPath.GetPublicPath, 'Grabs');
  {$ELSEIF DEFINED(IOS)}
  Result := TPath.Combine(TPath.GetDocumentsPath, 'Grabs');
  {$ELSE}
  Result := String.Empty;   // desktop: the user chooses
  {$ENDIF}
end;

function NextNumberedFileName(const AFolder, APrefix, AExtension: String;
  var ANumber: Integer): String;
begin
  repeat
    Result := TPath.Combine(AFolder,
      Format('%s%.3d%s', [APrefix, ANumber, AExtension]));
    if not FileExists(Result) then
      Break;
    Inc(ANumber);
  until False;
end;

function SaveGrab(const ABitmap: TBitmap; const AFolder: String;
  var ANumber: Integer): String;
var
  Number: Integer;
begin
  // Work on a copy, so ANumber is untouched if anything below fails
  Number := ANumber;
  ForceDirectories(AFolder);
  Result := NextNumberedFileName(AFolder, 'grab', '.png', Number);
  ABitmap.SaveToFile(Result);
  ANumber := Number + 1;
end;

function LoadModelFile(const AModel: TGorillaModel; const AFileName: String;
  out ABox: TBoundingBox): TArray<String>;
var
  Names: TStringList;
begin
  AModel.Clear;
  AModel.LoadFromFile(nil, AFileName, []);

  Names := TStringList.Create;
  try
    Names.Sorted := True;
    for var AnimName in AModel.AnimationManager.Animations.Keys do
      Names.Add(AnimName);
    if Names.Count > 0 then
      AModel.AnimationManager.PlayAnimation(Names[Names.Count - 1]);
    Result := Names.ToStringArray;
  finally
    Names.Free;
  end;

  // Taken before the caller adds axes or a grid to the model, which would
  // otherwise count towards it
  ABox := AModel.GetBoundingBox();
end;

procedure PlaceModel(const AModel: TGorillaModel; const ABox: TBoundingBox);
begin
  AModel.Position.Point := Point3D(ABox.TopLeftNear.X + (ABox.Width / 2),
                                   ABox.TopLeftNear.Y + (ABox.Height / 2),
                                   ABox.TopLeftNear.Z + (ABox.Depth / 2));
  AModel.RotationAngle.X := MODEL_ROTATION.X;
  AModel.RotationAngle.Y := MODEL_ROTATION.Y;
  AModel.RotationAngle.Z := MODEL_ROTATION.Z;
end;

end.
