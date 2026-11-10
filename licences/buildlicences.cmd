@echo off
rem Builds Sprite3DLicences.res, the third-party licences and notices
rem Sprite3d.dpr links into the program on every platform.
rem
rem Compiles Sprite3DLicences.rc into Sprite3DLicences.res with RAD Studio's
rem brcc32, from this folder, so the file names in the .rc resolve here.
rem Called by src\styles\buildstyles.cmd, which the project's pre-build
rem event runs for every platform and configuration:
rem   call "%~dp0..\..\licences\buildlicences.cmd" "%BDSDIR%"
rem Any failure stops the build with an error saying what went wrong.

setlocal EnableDelayedExpansion
set "BRCC=%~1\bin\brcc32.exe"
set FAILED=0

pushd "%~dp0"

if not exist "%BRCC%" (
  echo buildlicences.cmd : error : brcc32.exe not found at !BRCC!
  set FAILED=1
  goto done
)

"!BRCC!" -fo Sprite3DLicences.res Sprite3DLicences.rc
if errorlevel 1 (
  echo buildlicences.cmd : error : brcc32 could not compile Sprite3DLicences.rc
  set FAILED=1
)

:done
popd
exit /b %FAILED%
