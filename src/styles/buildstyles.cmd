@echo off
rem Builds Sprite3DThemes.res, the FMX styles Sprite3D's themes use, which
rem Sprite3d.dpr links into the program on every platform.
rem
rem 1. Copies any of the four .style files missing from this folder out of
rem    RAD Studio's Redist\styles\Fmx; files already here are left alone, so
rem    a style can be replaced by hand.
rem 2. Compiles Sprite3DThemes.rc into Sprite3DThemes.res with RAD Studio's
rem    brcc32, from this folder, so the file names in the .rc resolve here.
rem
rem Run by the project's pre-build event, for every platform and
rem configuration, before anything is compiled:
rem   call "$(PROJECTDIR)\styles\buildstyles.cmd" "$(BDS)"
rem Any failure stops the build with an error saying what went wrong.

rem Paths are expanded with !...! inside brackets, as RAD Studio's usual
rem folder, Program Files (x86), would otherwise end a bracketed block.
setlocal EnableDelayedExpansion
set "BDSDIR=%~1"
set "SRC=%BDSDIR%\Redist\styles\Fmx"
set "BRCC=%BDSDIR%\bin\brcc32.exe"
set FAILED=0

pushd "%~dp0"

for %%S in (Dark AquaGraphite RubyGraphite GoldenGraphite) do (
  if not exist "%%S.style" (
    if exist "%SRC%\%%S.style" (
      copy /Y "%SRC%\%%S.style" "%%S.style" >nul
      echo Copied %%S.style from !SRC!
    ) else (
      echo buildstyles.cmd : error : %%S.style not found in this folder or in !SRC!
      set FAILED=1
    )
  )
)
if %FAILED% neq 0 goto done

if not exist "%BRCC%" (
  echo buildstyles.cmd : error : brcc32.exe not found at !BRCC!
  set FAILED=1
  goto done
)

"!BRCC!" -fo Sprite3DThemes.res Sprite3DThemes.rc
if errorlevel 1 (
  echo buildstyles.cmd : error : brcc32 could not compile Sprite3DThemes.rc
  set FAILED=1
)

:done
popd
exit /b %FAILED%
