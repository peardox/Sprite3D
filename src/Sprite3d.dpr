program Sprite3d;

uses
  System.StartUpCopy,
  FMX.Forms,
  Sprite3dMain in 'ui\Sprite3dMain.pas' {MainForm},
  Sprite3DHelpers in 'ui\Sprite3DHelpers.pas',
  Sprite3DCamera in 'lib\Sprite3DCamera.pas',
  Sprite3DAxes in 'lib\Sprite3DAxes.pas',
  Sprite3DGrid in 'lib\Sprite3DGrid.pas',
  Sprite3DOffscreen in 'lib\Sprite3DOffscreen.pas',
  Sprite3DStorage in 'lib\Sprite3DStorage.pas',
  Sprite3DIconWriter in 'lib\Sprite3DIconWriter.pas',
  Sprite3DOpenFiles in 'lib\Sprite3DOpenFiles.pas',
  Sprite3DBackground in 'lib\Sprite3DBackground.pas',
  Sprite3DBackgroundForm in 'ui\Sprite3DBackgroundForm.pas' {BackgroundSettingsForm},
  Sprite3DOrbitalForm in 'ui\Sprite3DOrbitalForm.pas' {OrbitalSettingsForm},
  OSPaths in 'common\OSPaths.pas',
  GpuPreference in 'common\GpuPreference.pas',
  Sprite3DFileAssoc in 'lib\Sprite3DFileAssoc.pas',
  Sprite3DStyles in 'lib\Sprite3DStyles.pas',
  Sprite3DTitleBar in 'lib\Sprite3DTitleBar.pas',
  Sprite3DFlatColour in 'lib\Sprite3DFlatColour.pas',
  Sprite3DSettingsForm in 'ui\Sprite3DSettingsForm.pas' {GeneralSettingsForm},
  Sprite3DSpriteSheet in 'lib\Sprite3DSpriteSheet.pas',
  Sprite3DAnimCapture in 'lib\Sprite3DAnimCapture.pas',
  Sprite3DAnimationForm in 'ui\Sprite3DAnimationForm.pas' {AnimationSettingsForm};

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
