//** @abstract(ProjectionTest: can the projection FireMonkey draws a 3D scene with be reached and
//** changed from outside FMX? Tried on a lens shift and rise in a Gorilla3D view.)
//**
//** FMX keeps the projection matrix private and builds it from the camera's angle of view, so
//** Gorilla3D, which draws with what FMX gives it, cannot take one of ours (its author,
//** November 2026). This program finds where the matrices are kept (TSpritelyProjectionAccess,
//** in the Spritely package's Spritely.Projection), changes them each of the ways there are,
//** and measures what each did to the picture (TPeardoxProjectionTester,
//** ProjectionTestRunner); the log says which worked. Live, the component TSpritelyProjection
//** draws the view: perspective with any lens and the dolly zoom, orthographic, cavalier,
//** cabinet, military, plan oblique and free oblique projections, true isometric, 2:1
//** dimetric and trimetric, with lens shift and rise. The model is
//** shown through TSpritelyOrbitalCamera, whose fits follow the projection. On Windows FastMM5
//** is the memory manager, and Debug builds report leaks.
//**
//** @preformatted(
//** ui/          ProjectionTestMain, the form
//** common/      ProjectionTestMeasure (how far a picture moved), ProjectionTestRunner (the
//**              test)
//** ../lib/      Spritely.Projection (TSpritelyProjection, TSpritelyProjectionAccess), from the
//**              Spritely package
//** )
program ProjectionTest;

{
  ProjectionTest: can the projection FireMonkey draws a 3D scene with be
  reached and changed from outside FMX? Tried on a lens shift and rise in a
  Gorilla3D view: the matrices are found in memory (Spritely.Projection, from
  the Spritely package), changed each way there is, and what each did to the
  picture is measured (ProjectionTestRunner, ProjectionTestMeasure).
  TSpritelyProjection draws the live view.

    ui/          ProjectionTestMain, the form
    common/      ProjectionTestMeasure, ProjectionTestRunner
}

uses
  // On Windows FastMM5 is the memory manager, so it must come first
  {$IFDEF MSWINDOWS}
  FastMM5,
  {$ENDIF}
  System.StartUpCopy,
  FMX.Forms,
  ProjectionTestMeasure in 'common\ProjectionTestMeasure.pas',
  ProjectionTestRunner in 'common\ProjectionTestRunner.pas',
  ProjectionTestMain in 'ui\ProjectionTestMain.pas' {PeardoxProjectionTestForm};

{$R *.res}

begin
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
  {$IFDEF MSWINDOWS}
  // FastMM5 writes every leak, in full, to
  // ProjectionTest_MemoryManager_EventLog.txt beside the executable; the
  // last run's is deleted first
  FastMM_DeleteEventLogFile;
  FastMM_LogToFileEvents := FastMM_LogToFileEvents +
    [mmetUnexpectedMemoryLeakSummary, mmetUnexpectedMemoryLeakDetail];
  {$ENDIF}
  {$ENDIF}
  Application.Initialize;
  Application.CreateForm(TPeardoxProjectionTestForm, PeardoxProjectionTestForm);
  Application.Run;
end.
