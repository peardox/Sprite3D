@echo off
rem PasDoc reference of Sprite3D, Sprite3DBuilder and Spritely, as HTML and as HTML Help
rem (.chm), one set for each part:
rem   docs\html\api            HTML: Sprite3D's reusable units, Sprite3D\lib
rem                            and Shared (the API; Shared is used by
rem                            Sprite3DBuilder too)
rem   docs\html\spritely       HTML: the Spritely components (Spritely\lib),
rem                            without the design-time registration unit
rem   docs\html\Sprite3d       HTML: the program: Sprite3D\Sprite3d.dpr, its
rem                            forms (Sprite3D\ui) and the lib and Shared
rem                            units it uses
rem   docs\html\Sprite3DBuilder HTML: the other program, the same way, from
rem                            Sprite3DBuilder\Sprite3DBuilder.dpr
rem   docs\html\ProjectionTest HTML: Spritely's test program, its .dpr and its
rem                            own units (it takes Spritely from the package)
rem   docs\chm\<each>          HTML Help as docs\html\<each>, as a .chm
rem
rem What each program's reference holds is read from its .dpr's uses clause
rem (the units named "in '...'", relative to the .dpr), so a new form or unit
rem is picked up without changing this script. Units from outside the
rem program's folder (named "..\...") are left out, but for ..\Shared\, the
rem units shared with Sprite3DBuilder. The programs themselves
rem are listed below (PROGRAMS), as folder and name, since they are not all
rem in the root.
rem
rem The options are those the help has always been built with:
rem --staronly (only //** comments are read) and --auto-abstract.
rem
rem Needs pasdoc on the PATH (or set PASDOC=full path). The .chm files need
rem Microsoft HTML Help Workshop's hhc.exe (set HHC=full path if it is not
rem in the default folder); without it the HTML Help projects are written
rem but not compiled. Run from anywhere; the output folders are git-ignored.
rem docs\html and docs\chm are deleted first, with everything in them, so no
rem page of an earlier run (or of a unit since removed) is left behind;
rem nothing else in docs\ is touched (docs\lib and docs\ui, the help kept in
rem the repository, stay as they are).
rem
rem Dark colours: after each run, tools\pasdoc-dark.css (HTML: dark only when
rem the browser or system asks for it) or tools\pasdoc-chm-dark.css (HTML
rem Help: always dark, as the viewer cannot ask) is appended to the
rem pasdoc.css that PasDoc wrote, so PasDoc's own stylesheet stays as it is
rem and no copy of it is kept here. Set PASDOC_DARK=0 to leave them out.
rem
rem Defines: PasDoc defines no platform symbols itself, so the Win64 view is
rem chosen here; code for the other platforms, inside {$IF} blocks, is left
rem out of the reference. FastMM_FullDebugModeWhenDLLAvailable is left
rem undefined, the Release view of the .dpr files. The FFmpeg headers in
rem Sprite3D\ffmpeg are not compiled in, and are never parsed.

setlocal
cd /d "%~dp0.."

if "%PASDOC%"=="" set PASDOC=pasdoc

rem pasdoc installed? (a full path in PASDOC, or a program on the PATH)
set FOUND=0
if exist "%PASDOC%" set FOUND=1
if %FOUND%==0 where "%PASDOC%" >nul 2>&1 && set FOUND=1
if %FOUND%==0 (
  echo pasdoc was not found ^(looked for: %PASDOC%^).
  echo Install it from https://github.com/pasdoc/pasdoc/releases/
  echo ^(download the archive for Windows, unpack it and put its bin folder on the PATH,
  echo or set PASDOC=full path of pasdoc.exe before running this script^)
  endlocal & exit /b 1
)

if "%HHC%"=="" set HHC=%ProgramFiles(x86)%\HTML Help Workshop\hhc.exe

set COMMON=--define PASDOC --define MSWINDOWS --define WIN64 --define CPUX64 --staronly --auto-abstract --visible-members protected,public,published,automated --inherited-members default-hide --write-uses-list --verbosity 3
set SUBTITLE=sprites from 3D models

set FAILED=0
set RUNS=0

rem The API: every unit in Sprite3D\lib and Shared
set APISRC=
for %%F in (Sprite3D\lib\*.pas Shared\*.pas) do call :addapi "%%F"

rem Spritely: every unit in Spritely\lib but the registration (*.Reg)
set SPRSRC=
for %%F in (Spritely\lib\*.pas) do call :addspritely "%%F"

echo ==== Cleaning the output folders
call :clean docs\html
call :clean docs\chm

call :run html api docs\html\api --name Sprite3D --title "Sprite3D API - %SUBTITLE%" %APISRC%
call :run htmlhelp api docs\chm\api --name Sprite3D --title "Sprite3D API - %SUBTITLE%" %APISRC%
call :run html spritely docs\html\spritely --name Spritely --title "Spritely - camera components for Gorilla3D" %SPRSRC%
call :run htmlhelp spritely docs\chm\spritely --name Spritely --title "Spritely - camera components for Gorilla3D" %SPRSRC%
call :program Sprite3D Sprite3d "Sprite3D - %SUBTITLE%"
call :program Sprite3DBuilder Sprite3DBuilder "Sprite3DBuilder - a level builder for 3D model kits"
call :program Spritely\ProjectionTest ProjectionTest "ProjectionTest - Spritely's projection test"

call :chm docs\chm\api
call :chm docs\chm\spritely
call :chm docs\chm\Sprite3d
call :chm docs\chm\Sprite3DBuilder
call :chm docs\chm\ProjectionTest

echo.
if %FAILED%==0 (echo PasDoc: all %RUNS% runs finished; start at docs\html\api\index.html) else (echo PasDoc: %FAILED% step^(s^) FAILED - see above)
endlocal & exit /b %FAILED%

rem ---- :addapi <unit.pas> - adds one unit to the api run
:addapi
set APISRC=%APISRC% "%~1"
exit /b 0

rem ---- :addspritely <Spritely\lib\unit.pas> - adds one unit to the
rem      spritely run, unless it is the design-time registration unit
rem      (*.Reg.pas)
:addspritely
set "UNITNAME=%~n1"
if /i "%UNITNAME:~-4%"==".Reg" exit /b 0
set SPRSRC=%SPRSRC% "%~1"
exit /b 0

rem ---- :program <folder> <name> <title> - HTML and HTML Help runs for one
rem      program: <folder>\<name>.dpr, plus each unit its uses clause names
rem      "in '...'"
:program
set DIR=%~1
set APP=%~2
set APPTITLE=%~3
if not exist "%DIR%\%APP%.dpr" (
  echo ==== %DIR%\%APP%.dpr not found - %APP% left out
  set /a FAILED+=1
  exit /b 0
)
set SRCS="%DIR%\%APP%.dpr"
for /f "usebackq tokens=2 delims='" %%P in (`findstr /l /c:" in '" "%DIR%\%APP%.dpr"`) do call :addsrc "%DIR%" "%%P"
call :run html %APP% docs\html\%APP% --name %APP% --title "%APPTITLE%" %SRCS%
call :run htmlhelp %APP% docs\chm\%APP% --name %APP% --title "%APPTITLE%" %SRCS%
exit /b 0

rem ---- :addsrc <folder> <path from the .dpr> - adds one unit of a program
rem      as <folder>\<path>; a path outside the folder (..\) is left out,
rem      but for the shared units (..\Shared\)
:addsrc
set "SRC=%~2"
if /i "%SRC:~0,10%"=="..\Shared\" goto addsrckeep
if "%SRC:~0,3%"=="..\" exit /b 0
:addsrckeep
set SRCS=%SRCS% "%~1\%SRC%"
exit /b 0

rem ---- :clean <folder> - deletes one output folder with everything in it
:clean
if not exist "%~1\" (
  echo %1: not there yet
  exit /b 0
)
rmdir /s /q "%~1"
if exist "%~1\" (
  echo %1: could NOT be deleted completely - is a file in it open ^(browser, .chm viewer^)?
  set /a FAILED+=1
) else (
  echo %1: deleted
)
exit /b 0

rem ---- :run <format> <label> <output folder> <name, title and sources...>
:run
set FMT=%1
set LABEL=%2
set OUT=%3
shift & shift & shift
set ARGS=
:collect
if "%~1"=="" goto collected
set ARGS=%ARGS% %1
shift
goto collect
:collected
echo.
echo ==== PasDoc %FMT% (%LABEL%) -^> %OUT%
if not exist "%OUT%" mkdir "%OUT%"
set /a RUNS+=1
"%PASDOC%" --format %FMT% --output %OUT% %COMMON% %ARGS%
if errorlevel 1 (echo ==== PasDoc %FMT% %LABEL% FAILED & set /a FAILED+=1 & exit /b 0)
call :dark %FMT% %OUT%
exit /b 0

rem ---- :dark <format> <output folder> - appends the dark colours for that
rem      format to the pasdoc.css PasDoc wrote there
:dark
if "%PASDOC_DARK%"=="0" exit /b 0
set DARKCSS=tools\pasdoc-dark.css
if /i "%~1"=="htmlhelp" set DARKCSS=tools\pasdoc-chm-dark.css
if not exist "%DARKCSS%" (
  echo ==== %DARKCSS% not found - %~2 left in PasDoc's own colours
  set /a FAILED+=1
  exit /b 0
)
if not exist "%~2\pasdoc.css" (
  echo ==== %~2\pasdoc.css not found - dark colours not added
  set /a FAILED+=1
  exit /b 0
)
(echo.& type "%DARKCSS%") >> "%~2\pasdoc.css"
echo ==== Dark colours from %DARKCSS% added to %~2\pasdoc.css
exit /b 0

rem ---- :chm <folder> - compiles the HTML Help project PasDoc wrote there
:chm
if not exist "%~1\" exit /b 0
if not exist "%HHC%" (
  echo ==== %1: hhc.exe not found at "%HHC%" - .hhp written, .chm not compiled
  exit /b 0
)
for %%F in ("%~1\*.hhp") do (
  echo ==== Compiling %%F
  "%HHC%" "%%F"
  rem hhc.exe exits with 1 on SUCCESS and 0 on failure
  if not errorlevel 1 (echo ==== %%F: .chm NOT compiled & set /a FAILED+=1)
)
exit /b 0
