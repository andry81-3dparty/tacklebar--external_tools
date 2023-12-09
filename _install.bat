@echo off

setlocal

if %IMPL_MODE%0 NEQ 0 goto IMPL

set TACKLEBAR_SCRIPTS_INSTALL=1

call "%%~dp0__init__/__init__.bat" || exit /b

call "%%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_ROOT%%/__init__/declare_builtins.bat" %%0 %%*

for %%i in (CONTOOLS_ROOT CONTOOLS_UTILITIES_BIN_ROOT) do (
  if not defined %%i (
    echo.%~nx0: error: `%%i` variable is not defined.
    exit /b 255
  ) >&2
)

rem check WSH disable
set "HKEYPATH=HKEY_CURRENT_USER\Software\Microsoft\Windows Script Host\Settings"
call "%%CONTOOLS_ROOT%%/registry/regquery.bat" "%%HKEYPATH%%" Enabled >nul 2>nul
if defined REGQUERY_VALUE if %REGQUERY_VALUE%0 EQU 0 goto WSH_DISABLED

set "HKEYPATH=HKEY_LOCAL_MACHINE\Software\Microsoft\Windows Script Host\Settings"
call "%%CONTOOLS_ROOT%%/registry/regquery.bat" "%%HKEYPATH%%" Enabled >nul 2>nul
if defined REGQUERY_VALUE if %REGQUERY_VALUE%0 EQU 0 goto WSH_DISABLED

goto WSH_ENABLED

:WSH_DISABLED
(
  echo.%~nx0: error: Windows Script Host is disabled: "%HKEYPATH%\Enabled" = %REGQUERY_VALUE%
  exit /b 255
) >&2

:WSH_ENABLED

call "%%CONTOOLS_ROOT%%/build/init_project_log.bat" "%%?~n0%%" || exit /b

rem List of issues discovered in Windows XP/7:
rem 1. Run from shortcut file (`.lnk`) in the Windows XP (but not in the Windows 7) brings truncated command line down to ~260 characters.
rem 2. Run from shortcut file (`.lnk`) loads console windows parameters (font, windows size, buffer size, etc) from the shortcut at first and from the registry
rem    (HKCU\Console) at second. If try to change and save parameters, then saves ONLY into the shortcut, which brings the shortcut file overwrite.
rem 3. Run under UAC promotion in the Windows 7+ blocks environment inheritance, blocks stdout redirection into a pipe from non-elevated process into elevated one and
rem    blocks console screen buffer change (piping locks process (stdout) screen buffer sizes).
rem    To bypass that, for example, need to:
rem     a. Save environment variables to a file from non-elevated process and load them back in an elevated process.
rem     b. Use redirection only from an elevated process.
rem     c. Change console screen buffer sizes before stdout redirection into a pipe.
rem 4. Windows antivirus software in some cases reports a `.vbs` script as not safe or requests an explicit action on each `.vbs` script execution.
rem

rem To resolve all the issues we DO NOT USE shortcut files (`.lnk`) or Visual Basic scripts (`.vbs`) for UAC promotion. Instead we use as a replacement `callf.exe` utility.
rem
rem PROs:
rem   1. Implementation is the same and portable between all the Windows versions like Windows XP/7/8/10. No need to use different implementation for each Windows version.
rem   2. No need to change console windows parameters (font, windows sizes, buffer sizes, etc) each time the project is installed. The parameters loads/saves from/to the registry and so
rem      is shared between installations.
rem   3. Process inheritance tree is retained between non-elevated process and elevated process because parent non-elevated process (`callf.exe`) awaits child elevated process.
rem   4. A single console can be shared between non-elevated and elevated processes.
rem   5. A single log file can be shared between non-elevated and elevated processes.
rem   6. The `/pause-on-exit*` flags of the `callf.exe` does not block execution on detached console versus the `pause` command of the `cmd.exe` interpreter which does block.
rem   7. Because the console window is owned or attached by the most top parent `callf.exe` process with the `/pause-on-exit*` flag, then
rem      there is no chance to skip the pause or skip a print into the console window if someone of children processes got crash or console detach,
rem      even under elevated environment.
rem
rem CONs:
rem   1. The `callf.exe` still can not redirect stdin/stdout of a child `cmd.exe` process without losing the auto completion feature (in case of interactive input - `cmd.exe /k`).
rem

rem CAUTION:
rem   The `ConSetBuffer.exe` utility has issue when changes screen buffer size under elevated environment through the `callf.exe` utility.
rem   To workaround that we have to change screen buffer sizes before the elevation.
rem
call "%%?~dp0%%._install\_install.update.terminal_params.bat" -update_screen_size -update_buffer_size

echo.Request Administrative permissions to install...

call "%%CONTOOLS_ROOT%%/build/init_vars_file.bat" || exit /b

call "%%CONTOOLS_ROOT%%/exec/exec_callf_prefix.bat" -Y /pause-on-exit -elevate tacklebar_install -- %%*
set LASTERROR=%ERRORLEVEL%

exit /b %LASTERROR%

:IMPL
rem check for true elevated environment (required in case of Windows XP)
"%SystemRoot%\System32\net.exe" session >nul 2>nul || (
  echo.%?~nx0%: error: the script process is not properly elevated up to Administrator privileges.
  exit /b 255
) >&2

rem load initialization environment variables
if defined INIT_VARS_FILE call "%%CONTOOLS_ROOT%%/std/set_vars_from_file.bat" "%%INIT_VARS_FILE%%"

if exist "\\?\%SystemRoot%\System64\*" goto IGNORE_MKLINK_SYSTEM64

call "%%CONTOOLS_ROOT%%/ToolAdaptors/lnk/install_system64_link.bat"

if not exist "\\?\%SystemRoot%\System64\*" (
  echo.%?~nx0%: error: could not create directory link: "%SystemRoot%\System64" -^> "%SystemRoot%\System32"
  exit /b 255
) >&2

echo.

:IGNORE_MKLINK_SYSTEM64

rem CAUTION: requires `"%SystemRoot%\System64` directory installation
call "%%?~dp0%%._install\_install.update.terminal_params.bat" -update_registry || exit /b 255

rem script flags
set "FLAG_CHCP="

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG (
  if "%FLAG%" == "-chcp" (
    set "FLAG_CHCP=%~2"
    shift
  ) else (
    echo.%?~nx0%: error: invalid flag: %FLAG%
    exit /b 255
  ) >&2

  shift

  rem read until no flags
  goto FLAGS_LOOP
)

if not defined NEST_LVL set NEST_LVL=0

set /A NEST_LVL+=1

call "%%CONTOOLS_ROOT%%/std/allocate_temp_dir.bat" . "%%?~n0%%" || (
  echo.%?~nx0%: error: could not allocate temporary directory: "%SCRIPT_TEMP_CURRENT_DIR%"
  set LASTERROR=255
  goto FREE_TEMP_DIR
) >&2

rem CAUTION:
rem   We have to change the codepage here because the change would be revoked upon the UAC promotion.
rem

if defined FLAG_CHCP ( call "%%CONTOOLS_ROOT%%/std/chcp.bat" -p %%FLAG_CHCP%%
) else call "%%CONTOOLS_ROOT%%/std/getcp.bat"

set "XCOPY_FILE_CMD_BARE_FLAGS="
set "XCOPY_DIR_CMD_BARE_FLAGS="
set "XMOVE_FILE_CMD_BARE_FLAGS="
set "XMOVE_DIR_CMD_BARE_FLAGS="
if defined OEMCP (
  set XCOPY_FILE_CMD_BARE_FLAGS=%XCOPY_FILE_CMD_BARE_FLAGS% -chcp "%OEMCP%"
  set XCOPY_DIR_CMD_BARE_FLAGS=%XCOPY_DIR_CMD_BARE_FLAGS% -chcp "%OEMCP%"
  set XMOVE_FILE_CMD_BARE_FLAGS=%XMOVE_FILE_CMD_BARE_FLAGS% -chcp "%OEMCP%"
  set XMOVE_DIR_CMD_BARE_FLAGS=%XMOVE_DIR_CMD_BARE_FLAGS% -chcp "%OEMCP%"
)

call :MAIN %%*
set LASTERROR=%ERRORLEVEL%

rem restore locale
if defined FLAG_CHCP call "%%CONTOOLS_ROOT%%/std/restorecp.bat" -p

:FREE_TEMP_DIR
rem cleanup temporary files
call "%%CONTOOLS_ROOT%%/std/free_temp_dir.bat"

:FREE_TEMP_DIR_END
set /A NEST_LVL-=1

exit /b %LASTERROR%

:MAIN
rem call :CMD "%%PYTHON_EXE_PATH%%" "%%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_ROOT%%/_install.xsh"
rem exit /b
rem 
rem :CMD
rem echo.^>%*
rem echo.
rem (
rem   %*
rem )
rem exit /b

set "EMPTY_DIR_TMP=%SCRIPT_TEMP_CURRENT_DIR%\emptydir"

mkdir "%EMPTY_DIR_TMP%" || (
  echo.%?~n0%: error: could not create a directory: "%EMPTY_DIR_TMP%".
  exit /b 255
) >&2

echo.
echo.Required Windows version: %WINDOWS_X64_MIN_VER_STR%+ OR %WINDOWS_X86_MIN_VER_STR%+
echo.
echo.Required set of 3dparty software included into distribution:
echo. * Notepad++ (%NOTEPADPP_MIN_VER_STR%+, https://notepad-plus-plus.org/downloads/ )
echo. * Notepad++ PythonScript plugin (%NOTEPADPP_PYTHON_SCRIPT_PLUGIN_MIN_VER_STR%+, https://github.com/bruderstein/PythonScript )
echo. * WinMerge (%WINMERGE_MIN_VER_STR%+, https://winmerge.org/downloads )
echo. * Visual C++ 2008 Redistributables (%VCREDIST_2008_MIN_VER_STR%+, https://www.catalog.update.microsoft.com/Search.aspx?q=kb2538243 )
echo.
echo.Required set of 3dparty software not included into distribution:
echo. * ffmpeg (ffmpeg module,
echo.           https://ffmpeg.org/download.html#build-windows, https://github.com/BtbN/FFmpeg-Builds/releases,
echo.           https://github.com/Reino17/ffmpeg-windows-build-helpers, https://rwijnsma.home.xs4all.nl/files/ffmpeg/?C=M;O=D )
echo. * msys2 (coreutils package, https://www.msys2.org/#installation )
echo. * cygwin (coreutils package, https://cygwin.com )
echo.
echo.Optional set of supported 3dparty software not included into distribution:
echo. * MinTTY (https://mintty.github.io, https://github.com/mintty/mintty)
echo. * ConEmu (%CONEMU_MIN_VER_STR%+, https://github.com/Maximus5/ConEmu )
echo.   NOTE: Under the Windows XP x64 SP2 only x86 version does work.
echo. * Araxis Merge (%ARAXIS_MERGE_MIN_VER_STR%+, https://www.araxis.com/merge/documentation-windows/release-notes.en )
echo.
echo. CAUTION:
echo.   You must install at least Notepad++ (with PythonScript plugin) and WinMerge (or Araxis Merge) to continue.
echo.

rem Check Windows service pack version and warn the user
if %WINDOWS_MAJOR_VER% GTR 5 goto WINDOWS_SP_VERSION_OK

call "%%CONTOOLS_ROOT%%\wmi\get_wmic_os_sp_major_version.bat"
if not defined RETURN_VALUE goto WINDOWS_SP_VERSION_OK

rem Windows XP x64 SP2 or Windows XP x86 SP3
if %WINDOWS_X64_VER% NEQ 0 (
  if %RETURN_VALUE% GEQ 1 goto WINDOWS_SP_VERSION_OK
) else if %RETURN_VALUE% GEQ 3 goto WINDOWS_SP_VERSION_OK

echo. CAUTION:
echo.   Windows XP service pack version: %RETURN_VALUE%
echo.   This version of Windows XP is not supported by 3dparty software declared in the list above.
echo.   You can continue to install, but if 3dparty software will stop work you have to manually find or downgrade to an old version.
echo.

:WINDOWS_SP_VERSION_OK

:REPEAT_INSTALL_3DPARTY_ASK
set "CONTINUE_INSTALL_ASK="

echo.Ready to install, do you want to continue [y]es/[n]o?
set /P "CONTINUE_INSTALL_ASK="

if /i "%CONTINUE_INSTALL_ASK%" == "y" goto CONTINUE_INSTALL_3DPARTY_ASK
if /i "%CONTINUE_INSTALL_ASK%" == "n" goto CANCEL_INSTALL

goto REPEAT_INSTALL_3DPARTY_ASK

:CONTINUE_INSTALL_3DPARTY_ASK
echo.

rem installing...

echo.Installing Redistributables...

call :CMD start /B /WAIT "" "%%VCREDIST_2008_SETUP%%"

echo.

echo.Installing Notepad++...

call :CMD start /B /WAIT "" "%%NOTEPAD_PLUS_PLUS_SETUP%%"

echo.

call "%%?~dp0%%.%%?~n0%%/%%?~n0%%.detect_3dparty.notepadpp.bat"

echo.

if not defined DETECTED_NPP_EDITOR goto SKIP_NPP_EDITOR_POSTINSTALL
if not exist "\\?\%DETECTED_NPP_EDITOR%" goto SKIP_NPP_EDITOR_POSTINSTALL

if %WINDOWS_MAJOR_VER% GTR 5 goto IGNORE_NPP_EDITOR_PATCHES

echo.Applying Notepad++ patches...

if not exist "%DETECTED_NPP_ROOT%/updater/libcurl.dll.bak" move "%DETECTED_NPP_ROOT%\updater\libcurl.dll" "%DETECTED_NPP_ROOT%\updater\libcurl.dll.bak" >nul

call :XCOPY_DIR "%%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_ROOT%%/deploy/libcurl" "%%DETECTED_NPP_ROOT%%/updater" /E /Y /D

echo.

:IGNORE_NPP_EDITOR_PATCHES

echo.Installing Notepad++ PythonScript plugin...

rem CAUTION: We must avoid forwarding slashes and trailing back slash here altogether
for /F "eol=	 tokens=* delims=" %%i in ("%NOTEPAD_PLUS_PLUS_PYTHON_SCRIPT_PLUGIN_SETUP%\.") do set "NOTEPAD_PLUS_PLUS_PYTHON_SCRIPT_PLUGIN_SETUP=%%~fi"
for /F "eol=	 tokens=* delims=" %%i in ("%DETECTED_NPP_EDITOR%\.") do for /F "eol=	 tokens=* delims=" %%j in ("%%~dpi\.") do set "DETECTED_NPP_INSTALL_DIR=%%~fj"

rem CAUTION:
rem   The plugin installer is broken, must always point the Notepad++ installation location!
rem
call :CMD start /B /WAIT "" "%%SystemRoot%%\System32\msiexec.exe" /i "%%NOTEPAD_PLUS_PLUS_PYTHON_SCRIPT_PLUGIN_SETUP%%" INSTALLDIR="%%DETECTED_NPP_INSTALL_DIR%%"

echo.

rem Fix for the Windows XP x86/x64 or the Windows 7+ x86
if %WINDOWS_MAJOR_VER% GTR 5 if %WINDOWS_X64_VER% NEQ 0 goto IGNORE_NPP_PYTHON_SCRIPT_PLUGIN_INSTALL_FIX

echo.Fixing Notepad++ PythonScript plugin installation...

call :XCOPY_FILE "%%DETECTED_NPP_INSTALL_DIR%%/plugins/PythonScript" python27.dll "%%DETECTED_NPP_INSTALL_DIR%%" /Y /D /H

echo.

:IGNORE_NPP_PYTHON_SCRIPT_PLUGIN_INSTALL_FIX

:SKIP_NPP_EDITOR_POSTINSTALL

echo.Installing WinMerge...

call :CMD start /B /WAIT "" "%%WINMERGE_SETUP%%"

echo.

exit /b 0

:XCOPY_FILE
if not exist "\\?\%~f3" (
  echo.^>mkdir "%~3"
  call :MAKE_DIR "%%~3" || (
    echo.%?~nx0%: error: could not create a target file directory: "%~3".
    exit /b 255
  ) >&2
  echo.
)
call "%%CONTOOLS_ROOT%%/std/xcopy_file.bat"%%XCOPY_FILE_CMD_BARE_FLAGS%% %%*
exit /b

:XCOPY_DIR
if not exist "\\?\%~f2" (
  echo.^>mkdir "%~2"
  call :MAKE_DIR "%%~2" || (
    echo.%?~nx0%: error: could not create a target directory: "%~2".
    exit /b 255
  ) >&2
  echo.
)
call "%%CONTOOLS_ROOT%%/std/xcopy_dir.bat"%%XCOPY_DIR_CMD_BARE_FLAGS%% %%*
exit /b

:MAKE_DIR
for /F "eol= tokens=* delims=" %%i in ("%~1\.") do set "FILE_PATH=%%~fi"

mkdir "%FILE_PATH%" 2>nul || if exist "\\?\%SystemRoot%\System32\robocopy.exe" ( "%SystemRoot%\System32\robocopy.exe" /CREATE "%EMPTY_DIR_TMP%" "%FILE_PATH%" >nul ) else type 2>nul || (
  echo.%?~nx0%: error: could not create a target file directory: "%FILE_PATH%".
  exit /b 255
) >&2
exit /b

:XMOVE_FILE
call "%%CONTOOLS_ROOT%%/std/xmove_file.bat"%%XMOVE_FILE_CMD_BARE_FLAGS%% %%*
exit /b

:XMOVE_DIR
call "%%CONTOOLS_ROOT%%/std/xmove_dir.bat"%%XMOVE_DIR_CMD_BARE_FLAGS%% %%*
exit /b

:CMD
echo.^>%*
(
  %*
)
exit /b

:CANONICAL_PATH
setlocal DISABLEDELAYEDEXPANSION
for /F "eol= tokens=* delims=" %%i in ("%~2\.") do set "RETURN_VALUE=%%~fi"
rem set "RETURN_VALUE=%RETURN_VALUE:\=/%"
(
  endlocal
  set "%~1=%RETURN_VALUE%"
)
exit /b 0

:CANCEL_INSTALL
(
  echo.%?~nx0%: info: installation is canceled.
  exit /b 127
) >&2
