@echo off
rem Builds one program's licences resource: the third-party licences and
rem notices its .dpr links into it on every platform.
rem
rem Compiles <name>.rc into <name>.res with RAD Studio's brcc32, from this
rem folder, so the file names in the .rc resolve here. <name> is the second
rem parameter: Sprite3DLicences (Sprite3D's, the default) or
rem Sprite3DBuilderLicences (Sprite3DBuilder's). The licence texts are kept
rem here once; each program's .rc names the ones it carries. Called by each
rem program's styles\buildstyles.cmd, which its project's pre-build event
rem runs for every platform and configuration:
rem   call "%~dp0..\..\licences\buildlicences.cmd" "%BDSDIR%" [name]
rem Any failure stops the build with an error saying what went wrong.

setlocal EnableDelayedExpansion
set "BRCC=%~1\bin\brcc32.exe"
set FAILED=0
set "NAME=%~2"
if "%NAME%"=="" set "NAME=Sprite3DLicences"

pushd "%~dp0"

if not exist "!NAME!.rc" (
  echo buildlicences.cmd : error : !NAME!.rc not found in %~dp0
  set FAILED=1
  goto done
)

if not exist "%BRCC%" (
  echo buildlicences.cmd : error : brcc32.exe not found at !BRCC!
  set FAILED=1
  goto done
)

"!BRCC!" -fo "!NAME!.res" "!NAME!.rc"
if errorlevel 1 (
  echo buildlicences.cmd : error : brcc32 could not compile !NAME!.rc
  set FAILED=1
)

:done
popd
exit /b %FAILED%
