@echo off
rem Copies the FMX styles that Sprite3DThemes.rc links into Sprite3D from
rem RAD Studio's Redist folder into this folder, once; files already here
rem are left alone, so a style can be replaced by hand.
rem
rem Run by the project's pre-build event, for every platform and
rem configuration:  call "$(PROJECTDIR)\styles\getstyles.cmd" "$(BDS)"
rem A missing style stops the build with an error naming it.

setlocal
set "SRC=%~1\Redist\styles\Fmx"
set "DST=%~dp0"
set FAILED=0

for %%S in (Dark AquaGraphite RubyGraphite GoldenGraphite) do (
  if not exist "%DST%%%S.style" (
    if exist "%SRC%\%%S.style" (
      copy /Y "%SRC%\%%S.style" "%DST%%%S.style" >nul
      echo Copied %%S.style from %SRC%
    ) else (
      echo getstyles.cmd : error : %%S.style not found in %SRC%
      set FAILED=1
    )
  )
)

exit /b %FAILED%
