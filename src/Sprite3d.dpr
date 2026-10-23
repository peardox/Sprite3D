//** @abstract(Sprite3D: renders a 3D model from a chosen angle and saves it as images, icons,
//** sprite sheets, animated GIFs or MP4 video.)
//**
//** The program loads a glTF, FBX, OBJ, USD, Collada, STL or PLY model into a Gorilla3D
//** viewport, frames it with TSprite3DCamera and grabs it off screen with TSprite3DOffscreen.
//** TMainForm, in Sprite3dMain, holds the view and every command. Leaks still allocated at
//** shut-down are reported, as ReportMemoryLeaksOnShutdown is set; switch it off for a
//** release build. Builds for Windows, macOS, Linux, Android and iOS.
//**
//** @preformatted(
//** ui/    the forms and the settings kept between sessions
//** lib/   the camera, background, off-screen grabs, exporters and platform helpers
//** common/  display information, GPU preference and system folder helpers
//** )
program Sprite3d;

{
  Sprite3D: renders a 3D model from a chosen angle and saves it as images,
  icons, sprite sheets, animated GIFs or MP4 video.

  The program loads a glTF, FBX, OBJ, USD, Collada, STL or PLY model into a
  Gorilla3D viewport, frames it with TSprite3DCamera and grabs it off screen
  with TSprite3DOffscreen. TMainForm, in Sprite3dMain, holds the view and
  every command. Leaks still allocated at shut-down are reported, as
  ReportMemoryLeaksOnShutdown is set; switch it off for a release build.
  Builds for Windows, macOS, Linux, Android and iOS.

    ui/      the forms and the settings kept between sessions
    lib/     the camera, background, off-screen grabs, exporters and platform helpers
    common/  display information, GPU preference and system folder helpers
}

uses
  System.StartUpCopy,
  FMX.Forms,
  Sprite3dMain in 'ui\Sprite3dMain.pas' {MainForm},
  Sprite3DHelpers in 'ui\Sprite3DHelpers.pas',
  Sprite3DCamera in 'lib\Sprite3DCamera.pas',
  Sprite3DAxes in 'lib\Sprite3DAxes.pas',
  Sprite3DGrid in 'lib\Sprite3DGrid.pas',
  Sprite3DSweep in 'lib\Sprite3DSweep.pas',
  Sprite3DResample in 'lib\Sprite3DResample.pas',
  Sprite3DOffscreen in 'lib\Sprite3DOffscreen.pas',
  Sprite3DStorage in 'lib\Sprite3DStorage.pas',
  Sprite3DIconWriter in 'lib\Sprite3DIconWriter.pas',
  Sprite3DOpenFiles in 'lib\Sprite3DOpenFiles.pas',
  Sprite3DBackground in 'lib\Sprite3DBackground.pas',
  Sprite3DBackgroundForm in 'ui\Sprite3DBackgroundForm.pas' {BackgroundSettingsForm},
  Sprite3DOrbitalForm in 'ui\Sprite3DOrbitalForm.pas' {OrbitalSettingsForm},
  OSPaths in 'common\OSPaths.pas',
  GpuPreference in 'common\GpuPreference.pas',
  DisplayData in 'common\DisplayData.pas',
  Sprite3DFileAssoc in 'lib\Sprite3DFileAssoc.pas',
  Sprite3DStyles in 'lib\Sprite3DStyles.pas',
  Sprite3DTitleBar in 'lib\Sprite3DTitleBar.pas',
  Sprite3DSettingsForm in 'ui\Sprite3DSettingsForm.pas' {GeneralSettingsForm},
  Sprite3DSpriteSheet in 'lib\Sprite3DSpriteSheet.pas',
  Sprite3DAnimCapture in 'lib\Sprite3DAnimCapture.pas',
  Sprite3DAnimationForm in 'ui\Sprite3DAnimationForm.pas' {AnimationSettingsForm},
  Sprite3DAnimationsUsedForm in 'ui\Sprite3DAnimationsUsedForm.pas' {AnimationsUsedForm},
  Sprite3DLoadForm in 'ui\Sprite3DLoadForm.pas' {ModelLoadForm},
  Sprite3DDirectionsForm in 'ui\Sprite3DDirectionsForm.pas' {DirectionsForm},
  Sprite3DVideo in 'lib\Sprite3DVideo.pas',
  Sprite3DOpenH264 in 'lib\Sprite3DOpenH264.pas',
  Sprite3DNativeLibs in 'lib\Sprite3DNativeLibs.pas',
  Sprite3DBzip2 in 'lib\Sprite3DBzip2.pas',
  Sprite3DLibraryUpdate in 'lib\Sprite3DLibraryUpdate.pas';

{$R *.res}
// The themes' FMX styles, inside the program on every platform. The .res
// is built by styles\buildstyles.cmd in the pre-build event; see
// styles\Sprite3DThemes.rc
{$R 'styles\Sprite3DThemes.res'}

begin
  { Report any dumb memory leaks - switch to false for release }
  ReportMemoryLeaksOnShutdown := True;

  Application.Initialize;
 Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TOrbitalSettingsForm, OrbitalSettingsForm);
  Application.Run;
end.
