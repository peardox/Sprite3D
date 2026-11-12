//** @abstract(ImportTests: loads a model in any format Gorilla3D reads, writes it as GLB
//** through GLTFLib, and shows the two side by side.)
//**
//** A test bed for converting FBX, USD and other models to glTF, kept apart from Sprite3D:
//** it uses Sprite3D's camera (Spritely) to show the models, GLTFLib from the GLTFMerge
//** submodule to write them, and changes nothing of Sprite3D's. See README.md.
//**
//** @preformatted(
//** src/        the window and the exporter
//** GLTFMerge/  submodule; only its GLTFLib folder is used
//** )
program ImportTests;

{
  ImportTests: loads a model in any format Gorilla3D reads, writes it as GLB
  through GLTFLib, and shows the two side by side. Kept apart from Sprite3D;
  see README.md.
}

uses
  System.StartUpCopy,
  FMX.Forms,
  ImportTests.Main in 'src\ImportTests.Main.pas' {ImportTestsForm},
  Sprite3DGltfExport in '..\Sprite3D\lib\Sprite3DGltfExport.pas';

begin
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}
  Application.Initialize;
  Application.CreateForm(TImportTestsForm, ImportTestsForm);
  Application.Run;
end.
