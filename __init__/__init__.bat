@echo off

if /i "%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_ROOT_INIT0_DIR%" == "%~dp0" exit /b 0

set "TACKLEBAR_EXTERNAL_TOOLS_PROJECT_ROOT_INIT0_DIR=%~dp0"

rem CAUTION:
rem   Here is declared ONLY a basic set of system variables required immediately in this file.
rem   All the rest system variables will be loaded from the `config.*.vars` files.
rem

call :MAIN %%*
set "LASTERROR=%ERRORLEVEL%"

(
  set "MUST_LOAD_CONFIG="
  set "LASTERROR="
  exit /b %LASTERROR%
)

:MAIN
set "MUST_LOAD_CONFIG=%~1"
if not defined MUST_LOAD_CONFIG set "MUST_LOAD_CONFIG=1"

if not defined NEST_LVL set NEST_LVL=0

rem basic set of system variables
call :CANONICAL_PATH TACKLEBAR_EXTERNAL_TOOLS_PROJECT_ROOT                      "%%~dp0.."

call :CANONICAL_PATH TACKLEBAR_EXTERNAL_TOOLS_PROJECT_CONFIG_ROOT               "%%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_ROOT%%/_config"

if not defined PROJECT_OUTPUT_ROOT call :CANONICAL_PATH PROJECT_OUTPUT_ROOT     "%%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_ROOT%%/_out"

call :CANONICAL_PATH TACKLEBAR_EXTERNAL_TOOLS_PROJECT_OUTPUT_CONFIG_ROOT        "%%PROJECT_EXTERNAL_TOOLS_OUTPUT_ROOT%%/config/tacklebar"

call :CANONICAL_PATH TACKLEBAR_EXTERNAL_TOOLS_PROJECT_EXTERNALS_ROOT            "%%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_ROOT%%/_externals"

call :CANONICAL_PATH CONTOOLS_ROOT                                              "%%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_EXTERNALS_ROOT%%/contools/Scripts/Tools"

if not exist "%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_OUTPUT_CONFIG_ROOT%\" ( mkdir "%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_OUTPUT_CONFIG_ROOT%" || exit /b 10 )

if not exist "%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_CONFIG_ROOT%/config.system.vars.in" (
  echo.%~nx0: error: `%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_CONFIG_ROOT%/config.system.vars.in` must exist.
  exit /b 255
) >&2

rem explicitly generate `config.system.vars`
if not exist "%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_OUTPUT_CONFIG_ROOT%/config.system.vars" (
  copy "%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_CONFIG_ROOT:/=\%\config.system.vars.in" "%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_OUTPUT_CONFIG_ROOT:/=\%\config.system.vars" /B /Y >nul || exit /b 11
)

set CONFIG_INDEX=system
call :LOAD_CONFIG || exit /b

if defined CHCP chcp %CHCP%

for %%i in (PROJECT_ROOT ^
  PROJECT_LOG_ROOT PROJECT_CONFIG_ROOT PROJECT_OUTPUT_ROOT ^
  CONTOOLS_ROOT CONTOOLS_UTILITIES_BIN_ROOT) do (
  if not defined %%i (
    echo.%~nx0: error: `%%i` variable is not defined.
    exit /b 255
  ) >&2
)

if not exist "%PROJECT_LOG_ROOT%\" mkdir "%PROJECT_LOG_ROOT%"

set CONFIG_INDEX=0

:LOAD_CONFIG_LOOP
if not exist "%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_CONFIG_ROOT%/config.%CONFIG_INDEX%.vars.in" goto LOAD_CONFIG_END
call :LOAD_CONFIG || exit /b
set /A CONFIG_INDEX+=1
goto LOAD_CONFIG_LOOP

:LOAD_CONFIG
call "%%CONTOOLS_ROOT%%/std/load_config.bat" "%%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_CONFIG_ROOT%%" "%%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_OUTPUT_CONFIG_ROOT%%" "config.%%CONFIG_INDEX%%.vars" && exit /b

if %MUST_LOAD_CONFIG% NEQ 0 (
  echo.%~nx0: error: `%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_OUTPUT_CONFIG_ROOT%/config.%CONFIG_INDEX%.vars` is not loaded.
  exit /b 255
)

exit /b 0

:LOAD_CONFIG_END
rem initialize externals
call "%%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_EXTERNALS_ROOT%%/contools/__init__/__init__.bat" || exit /b

exit /b 0

:CANONICAL_PATH
setlocal DISABLEDELAYEDEXPANSION
set "RETURN_VALUE=%~dpf2"
set "RETURN_VALUE=%RETURN_VALUE:\=/%"
if "%RETURN_VALUE:~-1%" == "/" set "RETURN_VALUE=%RETURN_VALUE:~0,-1%"
(
  endlocal
  set "%~1=%RETURN_VALUE%"
)
exit /b 0
