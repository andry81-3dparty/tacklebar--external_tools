@echo off

if /i "%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_ROOT_INIT0_DIR%" == "%~dp0" exit /b 0

set "TACKLEBAR_EXTERNAL_TOOLS_PROJECT_ROOT_INIT0_DIR=%~dp0"

if not defined NEST_LVL set NEST_LVL=0

if not defined TACKLEBAR_EXTERNAL_TOOLS_PROJECT_ROOT                call "%%~dp0canonical_path.bat" TACKLEBAR_EXTERNAL_TOOLS_PROJECT_ROOT                "%%~dp0.."
if not defined TACKLEBAR_EXTERNAL_TOOLS_PROJECT_EXTERNALS_ROOT      call "%%~dp0canonical_path.bat" TACKLEBAR_EXTERNAL_TOOLS_PROJECT_EXTERNALS_ROOT      "%%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_ROOT%%/_externals"

if not defined PROJECT_OUTPUT_ROOT                                  call "%%~dp0canonical_path.bat" PROJECT_OUTPUT_ROOT                                  "%%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_ROOT%%/_out"
if not defined PROJECT_LOG_ROOT                                     call "%%~dp0canonical_path.bat" PROJECT_LOG_ROOT                                     "%%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_ROOT%%/.log"

if not defined TACKLEBAR_EXTERNAL_TOOLS_PROJECT_INPUT_CONFIG_ROOT   call "%%~dp0canonical_path.bat" TACKLEBAR_EXTERNAL_TOOLS_PROJECT_INPUT_CONFIG_ROOT   "%%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_ROOT%%/_config"
if not defined TACKLEBAR_EXTERNAL_TOOLS_PROJECT_OUTPUT_CONFIG_ROOT  call "%%~dp0canonical_path.bat" TACKLEBAR_EXTERNAL_TOOLS_PROJECT_OUTPUT_CONFIG_ROOT  "%%PROJECT_OUTPUT_ROOT%%/config/tacklebar"

rem retarget externals of an external project

if not defined CONTOOLS_PROJECT_EXTERNALS_ROOT                      call "%%~dp0canonical_path.bat" CONTOOLS_PROJECT_EXTERNALS_ROOT                      "%%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_EXTERNALS_ROOT%%"

rem init immediate external projects

if exist "%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_EXTERNALS_ROOT%/contools/__init__/__init__.bat" (
  call "%%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_EXTERNALS_ROOT%%/contools/__init__/__init__.bat" -no_load_user_config || exit /b
)

call "%%CONTOOLS_ROOT%%/std/get_windows_version.bat" || exit /b

rem Windows XP is minimal
call "%%CONTOOLS_ROOT%%/std/check_windows_version.bat" 5 1 || exit /b

if not exist "%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_OUTPUT_CONFIG_ROOT%\" ( mkdir "%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_OUTPUT_CONFIG_ROOT%" || exit /b 10 )
if not defined LOAD_CONFIG_VERBOSE if %INIT_VERBOSE%0 NEQ 0 set LOAD_CONFIG_VERBOSE=1

call "%%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_ROOT%%/tools/load_config_dir.bat" -lite_parse -gen_system_config "%%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_INPUT_CONFIG_ROOT%%" "%%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_OUTPUT_CONFIG_ROOT%%" || exit /b

rem init external projects

if exist "%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_EXTERNALS_ROOT%/tacklelib/__init__/__init__.bat" (
  call "%%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_EXTERNALS_ROOT%%/tacklelib/__init__/__init__.bat" -no_load_user_config || exit /b
)

if not exist "%PROJECT_OUTPUT_ROOT%\" ( mkdir "%PROJECT_OUTPUT_ROOT%" || exit /b 11 )
if not exist "%PROJECT_LOG_ROOT%\" ( mkdir "%PROJECT_LOG_ROOT%" || exit /b 12 )

if exist "%SystemRoot%\System64\" goto IGNORE_MKLINK_SYSTEM64

call "%%CONTOOLS_ROOT%%/ToolAdaptors/lnk/install_system64_link.bat"

if not exist "%SystemRoot%\System64\" (
  echo.%?~nx0%: error: could not create directory link: "%SystemRoot%\System64" -^> "%SystemRoot%\System32"
  exit /b 255
) >&2

echo.

:IGNORE_MKLINK_SYSTEM64

if defined CHCP call "%%CONTOOLS_ROOT%%/std/chcp.bat" %%CHCP%%

exit /b 0
