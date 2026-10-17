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
  Sprite3DBackgroundForm in 'ui\Sprite3DBackgroundForm.pas' {BackgroundSettingsForm};

{$R *.res}

begin
  { Report any dumb memory leaks - switch to false for release }
  ReportMemoryLeaksOnShutdown := True;

  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
