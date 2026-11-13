//** @abstract(Sprite3D: renders a 3D model from a chosen angle and saves it as images, icons,
//** sprite sheets, animated GIFs or MP4 video.)
//**
//** The program loads a glTF, FBX, OBJ, USD, Collada, STL or PLY model into a Gorilla3D
//** viewport, frames it with the Spritely package's orbital camera,
//** @code(TSpritelyOrbitalCamera), and grabs it off screen with TSprite3DOffscreen. TMainForm,
//** in Sprite3dMain, holds the view and every command. Leaks still allocated at shut-down
//** are reported, as ReportMemoryLeaksOnShutdown is set; switch it off for a
//** release build. On Windows FastMM5 is the memory manager and also writes them, in full, to
//** Sprite3d_MemoryManager_EventLog.txt beside the executable. Builds for Windows, macOS, Linux, Android and iOS.
//** On Windows a copy started while another is running, as by double-clicking a model in
//** Explorer, hands its files to that one and ends; see HandOffToRunningInstance.
//**
//** @preformatted(
//** ui/    the forms and the settings kept between sessions
//** lib/   the camera, background, off-screen grabs, exporters and platform helpers
//** common/  display information, GPU preference and system folder helpers
//** )
program Sprite3d;
// {$DEFINE REPORT_LEAKS}
{
  Sprite3D: renders a 3D model from a chosen angle and saves it as images,
  icons, sprite sheets, animated GIFs or MP4 video.

  The program loads a glTF, FBX, OBJ, USD, Collada, STL or PLY model into a
  Gorilla3D viewport, frames it with the Spritely package's orbital camera,
  TSpritelyOrbitalCamera, and grabs it off screen with TSprite3DOffscreen.
  TMainForm, in Sprite3dMain, holds the view and every command. Leaks still allocated at shut-down are reported, as
  ReportMemoryLeaksOnShutdown is set; switch it off for a release build. On
  Windows FastMM5 is the memory manager and also writes them, in full, to
  Sprite3d_MemoryManager_EventLog.txt beside the executable.
  Builds for Windows, macOS, Linux, Android and iOS.
  On Windows a copy started while another is running, as by double-clicking
  a model in Explorer, hands its files to that one and ends; see
  HandOffToRunningInstance.

    ui/      the forms and the settings kept between sessions
    lib/     the camera, background, off-screen grabs, exporters and platform helpers
    common/  display information, GPU preference and system folder helpers
}

uses
  // On Windows FastMM5 is the memory manager, so it must come first; it
  // writes the full leak report to a file beside the executable
  {$IFDEF MSWINDOWS}
  FastMM5,
  {$ENDIF}
  System.StartUpCopy,
  FMX.Forms,
  Sprite3dMain in 'ui\Sprite3dMain.pas' {MainForm},
  Sprite3DHelpers in 'ui\Sprite3DHelpers.pas',
  Sprite3DAxes in 'lib\Sprite3DAxes.pas',
  Sprite3DGrid in '..\Shared\Sprite3DGrid.pas',
  Sprite3DSweep in '..\Shared\Sprite3DSweep.pas',
  Sprite3DResample in '..\Shared\Sprite3DResample.pas',
  Sprite3DOffscreen in '..\Shared\Sprite3DOffscreen.pas',
  Sprite3DStorage in '..\Shared\Sprite3DStorage.pas',
  Sprite3DIconWriter in 'lib\Sprite3DIconWriter.pas',
  Sprite3DOpenFiles in '..\Shared\Sprite3DOpenFiles.pas',
  Sprite3DBackground in '..\Shared\Sprite3DBackground.pas',
  Sprite3DBackgroundForm in 'ui\Sprite3DBackgroundForm.pas' {BackgroundSettingsForm},
  Sprite3DOrbitalForm in 'ui\Sprite3DOrbitalForm.pas' {OrbitalSettingsForm},
  OSPaths in '..\Shared\OSPaths.pas',
  JsonText in '..\Shared\JsonText.pas',
  GpuPreference in '..\Shared\GpuPreference.pas',
  DisplayData in '..\Shared\DisplayData.pas',
  Sprite3DFileAssoc in '..\Shared\Sprite3DFileAssoc.pas',
  Sprite3DStyles in '..\Shared\Sprite3DStyles.pas',
  Sprite3DTitleBar in '..\Shared\Sprite3DTitleBar.pas',
  Sprite3DSettingsForm in 'ui\Sprite3DSettingsForm.pas' {GeneralSettingsForm},
  Sprite3DSpriteSheet in 'lib\Sprite3DSpriteSheet.pas',
  Sprite3DAnimFrames in '..\Shared\Sprite3DAnimFrames.pas',
  Sprite3DAnimCapture in 'lib\Sprite3DAnimCapture.pas',
  Sprite3DAnimationForm in 'ui\Sprite3DAnimationForm.pas' {AnimationSettingsForm},
  Sprite3DAnimationsUsedForm in 'ui\Sprite3DAnimationsUsedForm.pas' {AnimationsUsedForm},
  Sprite3DLoadForm in 'ui\Sprite3DLoadForm.pas' {ModelLoadForm},
  Sprite3DDirectionsForm in 'ui\Sprite3DDirectionsForm.pas' {DirectionsForm},
  Sprite3DExportForm in 'ui\Sprite3DExportForm.pas' {ExportProgressForm},
  Sprite3DResultsView in 'ui\Sprite3DResultsView.pas',
  Sprite3DCreditsForm in 'ui\Sprite3DCreditsForm.pas' {CreditsForm},
  Sprite3DVideo in 'lib\Sprite3DVideo.pas',
  Sprite3DOpenH264 in 'lib\Sprite3DOpenH264.pas',
  Sprite3DNativeLibs in 'lib\Sprite3DNativeLibs.pas',
  Sprite3DBzip2 in 'lib\Sprite3DBzip2.pas',
  Sprite3DLibraryUpdate in 'lib\Sprite3DLibraryUpdate.pas',
  Sprite3DFileSearch in 'lib\Sprite3DFileSearch.pas',
  Sprite3DOpenDirectoryForm in 'ui\Sprite3DOpenDirectoryForm.pas' {OpenDirectoryForm},
  Sprite3DNameClashForm in 'ui\Sprite3DNameClashForm.pas' {NameClashForm},
  Sprite3DPngReader in 'lib\Sprite3DPngReader.pas',
  Sprite3DLicences in 'lib\Sprite3DLicences.pas',
  Sprite3DFolderDialog in '..\Shared\Sprite3DFolderDialog.pas',
  Sprite3DSpriteScan in 'lib\Sprite3DSpriteScan.pas',
  Sprite3DGltfExport in 'lib\Sprite3DGltfExport.pas',
  Sprite3DGltfDocument in 'lib\Sprite3DGltfDocument.pas',
  Sprite3DModelTextures in '..\Shared\Sprite3DModelTextures.pas',
  Sprite3DModelAnimations in '..\Shared\Sprite3DModelAnimations.pas',
  Sprite3DGltfExportForm in 'ui\Sprite3DGltfExportForm.pas' {GltfExportForm},
  Sprite3DGltfMergeForm in 'ui\Sprite3DGltfMergeForm.pas' {GltfMergeForm},
  Sprite3DGltfSplitForm in 'ui\Sprite3DGltfSplitForm.pas' {GltfSplitForm},
  Sprite3DGltfPartsForm in 'ui\Sprite3DGltfPartsForm.pas' {GltfPartsForm},
  Sprite3DSpriteScanForm in 'ui\Sprite3DSpriteScanForm.pas' {SpriteScanForm},
  Sprite3DScanAtlasForm in 'ui\Sprite3DScanAtlasForm.pas' {ScanAtlasForm},
  Sprite3DScanAtlasFoldersForm in 'ui\Sprite3DScanAtlasFoldersForm.pas' {ScanAtlasFoldersForm},
  Sprite3DLicencesForm in 'ui\Sprite3DLicencesForm.pas' {LicencesForm};

{$R *.res}
// The themes' FMX styles, inside the program on every platform. The .res
// is built by styles\buildstyles.cmd in the pre-build event; see
// styles\Sprite3DThemes.rc
{$R 'styles\Sprite3DThemes.res'}
// The third-party licences and notices, from licences\Sprite3DLicences.rc,
// which the pre-build step compiles; File, Licences shows them
{$R '..\licences\Sprite3DLicences.res'}

begin
  // A model opened from Explorer while Sprite3D is already running goes to
  // the copy running, which loads it, rather than opening a second window;
  // this copy then ends at once. See HandOffToRunningInstance.
  if HandOffToRunningInstance('Sprite3D') then
    Exit;

  { Report any dumb memory leaks - switch to false for release }
  // ReportMemoryLeaksOnShutdown := True;
  {$IF DEFINED(MSWINDOWS)}
  // FastMM5 also writes every leak, in full, to
  // Sprite3d_MemoryManager_EventLog.txt in the executable's folder, its
  // default place, so no path is given. It adds to that file each run, so
  // the last run's is deleted first, leaving this run's leaks alone in it.
  {$IF DEFINED(REPORT_LEAKS)}
  FastMM_DeleteEventLogFile;
  FastMM_LogToFileEvents := FastMM_LogToFileEvents +
    [mmetUnexpectedMemoryLeakSummary, mmetUnexpectedMemoryLeakDetail];
  {$ENDIF}
  {$ENDIF}

  Application.Initialize;
 Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TOrbitalSettingsForm, OrbitalSettingsForm);
  Application.Run;
end.
