program Sprite3d;

uses
  System.StartUpCopy,
  FMX.Forms,
  Sprite3dMain in 'Sprite3dMain.pas' {Form1},
  Sprite3DCamera in 'Sprite3DCamera.pas';

begin
  { Report any dumb memory leaks - switch to false for release }
  ReportMemoryLeaksOnShutdown := True;

  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
