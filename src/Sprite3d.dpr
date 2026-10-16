program Sprite3d;

uses
  System.StartUpCopy,
  FMX.Forms,
  Sprite3dMain in 'Sprite3dMain.pas' {MainForm},
  Sprite3DCamera in 'Sprite3DCamera.pas',
  Sprite3DAxes in 'Sprite3DAxes.pas',
  Sprite3DGrid in 'Sprite3DGrid.pas';

begin
  { Report any dumb memory leaks - switch to false for release }
  ReportMemoryLeaksOnShutdown := True;

  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
