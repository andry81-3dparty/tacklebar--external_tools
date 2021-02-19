@echo off

setlocal

set "?~0=%~0"
set "?~f0=%~f0"
set "?~dp0=%~dp0"
set "?~n0=%~n0"
set "?~nx0=%~nx0"

set TACKLEBAR_SCRIPTS_INSTALL=1

call "%%~dp0__init__/__init__.bat" 0 || exit /b

for %%i in (PROJECT_ROOT PROJECT_LOG_ROOT PROJECT_CONFIG_ROOT CONTOOLS_ROOT CONTOOLS_UTILITIES_BIN_ROOT) do (
  if not defined %%i (
    echo.%~nx0: error: `%%i` variable is not defined.
    exit /b 255
  ) >&2
)

if %IMPL_MODE%0 NEQ 0 goto IMPL

call "%%~dp0._install\_install.update.terminal_params.bat" -update_screen_size -update_buffer_size

rem use stdout/stderr redirection with logging
call "%%CONTOOLS_ROOT%%\wmi\get_wmic_local_datetime.bat"
set "LOG_FILE_NAME_SUFFIX=%RETURN_VALUE:~0,4%'%RETURN_VALUE:~4,2%'%RETURN_VALUE:~6,2%_%RETURN_VALUE:~8,2%'%RETURN_VALUE:~10,2%'%RETURN_VALUE:~12,2%''%RETURN_VALUE:~15,3%"

set "PROJECT_LOG_DIR=%PROJECT_LOG_ROOT%\%LOG_FILE_NAME_SUFFIX%.%~n0"
set "PROJECT_LOG_FILE=%PROJECT_LOG_DIR%\%LOG_FILE_NAME_SUFFIX%.%~n0.log"

if not exist "%PROJECT_LOG_DIR%" ( mkdir "%PROJECT_LOG_DIR%" || exit /b )

rem CAUTION:
rem   In Windowx XP an elevated call under data protection flag will block the wmic tool, so we have to use `ver` command instead!
rem
for /F "usebackq tokens=1,2,* delims=[]" %%i in (`ver`) do for /F "tokens=1,2,* delims= " %%l in ("%%j") do set "WINDOWS_VER_STR=%%m"

set WINDOWS_MAJOR_VER=0
set WINDOWS_MINOR_VER=0
for /F "eol= tokens=1,2,* delims=." %%i in ("%WINDOWS_VER_STR%") do ( set "WINDOWS_MAJOR_VER=%%i" & set "WINDOWS_MINOR_VER=%%j" )

if %WINDOWS_MAJOR_VER% GTR 5 goto WINDOWS_VER_OK
if %WINDOWS_MAJOR_VER% EQU 5 if %WINDOWS_MINOR_VER% GEQ 1 goto WINDOWS_VER_OK

(
  echo.%~nx0: error: unsupported version of Windows: "%WINDOWS_VER_STR%"
  set LASTERROR=255
  goto EXIT
) >&2

:WINDOWS_VER_OK

set WINDOWS_X64_VER=0
if defined PROCESSOR_ARCHITEW6432 ( set "WINDOWS_X64_VER=1" ) else if /i not "%PROCESSOR_ARCHITECTURE%" == "x86" set WINDOWS_X64_VER=1

rem CAUTION:
rem   Specific case for Windows XP x64 SP2, where both PROCESSOR_ARCHITECTURE and PROCESSOR_ARCHITEW6432 are equal to AMD64 for 32-bit cmd.exe process!
rem
set PROC_X64_VER=0
if /i not "%PROCESSOR_ARCHITECTURE%" == "x86" if not defined PROCESSOR_ARCHITEW6432 set PROC_X64_VER=1

rem register initialization environment variables
(
for %%i in (TACKLEBAR_SCRIPTS_INSTALL LOG_FILE_NAME_SUFFIX PROJECT_LOG_DIR PROJECT_LOG_FILE COMMANDER_SCRIPTS_ROOT COMMANDER_PATH COMMANDER_INI ^
            WINDOWS_VER_STR WINDOWS_MAJOR_VER WINDOWS_MINOR_VER WINDOWS_X64_VER PROC_X64_VER COMSPEC COMSPECLNK ^
            TERMINAL_SCREEN_WIDTH TERMINAL_SCREEN_HEIGHT TERMINAL_SCREEN_BUFFER_HEIGHT) do ^
if defined %%i ( for /F "usebackq eol= tokens=1,* delims==" %%j in (`set %%i 2^>nul`) do if /i "%%i" == "%%j" echo.%%j=%%k) else echo.#%%i=
) > "%PROJECT_LOG_DIR%\init.vars"

rem List of issues discovered in Windows 7/XP:
rem 1. Run from shortcut file (`.lnk`) in the Windows XP (but not in the Windows 7) brings truncated command line down to ~260 characters.
rem 2. Run from shortcut file (`.lnk`) loads console windows parameters (font, windows size, buffer size, etc) from the shortcut at first and from the registry
rem    (HKCU\Console) at second. If try to change and save parameters, then saves ONLY into the shortcut, which brings the shortcut file overwrite.
rem 3. Run under UAC promotion in the Windows 7+ blocks environment inheritance, blocks stdout redirection into a pipe from non-elevated process into elevated one and
rem    blocks console screen buffer change (piping locks process (stdout) screen buffer sizes).
rem    To bypass that, for example, need to:
rem     a. Save environment variables to a file from non-elevated process and load them back in an elevated process.
rem     b. Use redirection only from an elevated process.
rem     c. Change console screen buffer sizes before stdout redirection into a pipe.
rem

rem To resolve all the issues we DO NOT USE shortcut files (.lnk) for UAC promotion. Instead we use as a replacement `winshell_call.vbs` + `call.vbs` scripts.
rem
rem The PROs:
rem   1. No need to change console windows parameters (font, windows sizes, buffer sizes, etc) each time the project is installed. The parameters loads/saves from/to the registry and so
rem      is shared between installations.
rem   2. Implementation is the same and portable between all the Windows versions like Windows XP/7. No need now to use different implementation for each Windows version.
rem   3. Process inheritance tree is retained between non-elevated process and elevated process because parent non-elevated process (`winchell_call.vbs`) awaits current directory
rem      release in the child elevated process (`call.vbs`) instead of awaits a child process exit and so independent to security permission from the Windows
rem      (in the Windows all elevated processes isolated from non-elevated processes and so can not be enumerated or can not be watched for exit by non-elevated processes).
rem
rem The CONs:
rem   1. To preserve the process inheritance tree between a non-elevated process and an elevated process, there is another process in the inheritance chain,
rem      compared to running a shortcut from a file with the UAC promotion flag raised.
rem   2. Implementation of the `winshell_call.vbs` script has race condition timeout because of the inner `ShellExecute` API call which does not support return code and
rem      does not have builtin child process exit await logic. So there is a chance that the parent non-elevated process will close before close the child elevated process.
rem

rem CAUTION:
rem   We should avoid use handles 3 and 4 while the redirection has take a place because handles does reuse
rem   internally from left to right when being redirected externally.
rem   Example: if `1` is redirected, then `3` is internally reused, then if `2` redirected, then `4` is internally reused and so on.
rem   The discussion of the logic:
rem   https://stackoverflow.com/questions/9878007/why-doesnt-my-stderr-redirection-end-after-command-finishes-and-how-do-i-fix-i/9880156#9880156
rem   A partial analisis:
rem   https://www.dostips.com/forum/viewtopic.php?p=14612#p14612
rem

"%SystemRoot%\System32\wscript.exe" //NOLOGO "%CONTOOLS_ROOT%/ToolAdaptors/vbs/winshell_call.vbs" -nowindow -verb runas -make_temp_dir_as_cwd "{{CWD}}" -wait_delete_cwd ^
  "%SystemRoot%\System32\wscript.exe" //NOLOGO "%CONTOOLS_ROOT%/ToolAdaptors/vbs/call.vbs" -D "{{CWD}}" -u -ra "%%" "%%?01%%" -v "?01" "%%" ^
    "%COMSPEC%" /C set "%%22TACKLEBAR_SCRIPTS_INSTALL=1%%22" ^& set "%%22IMPL_MODE=1%%22" ^& set "%%22INIT_VARS_FILE=%PROJECT_LOG_DIR%\init.vars%%22" ^& ^
      @"%%22%?~dp0%._install\_install.update.terminal_params.bat%%22" -update_screen_size -update_buffer_size ^& ^
      @"%%22%?~f0%%%22" %* 2^>^&1 ^| "%%22%CONTOOLS_UTILITIES_BIN_ROOT%/ritchielawrence/mtee.exe%%22" /E "%%22%PROJECT_LOG_FILE:/=\%%%22"
set LASTERROR=%ERRORLEVEL%
goto EXIT

:IMPL
rem check for true elevated environment (required in case of Windows XP)
"%SystemRoot%\System32\net.exe" session >nul 2>nul || (
  echo.%?~nx0%: error: the script process is not properly elevated up to Administrator privileges.
  set LASTERROR=255
  goto EXIT
) >&2

rem load initialization environment variables
for /F "usebackq eol=# tokens=* delims=" %%i in ("%INIT_VARS_FILE%") do set "%%i"

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
    exit /b -255
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

call :MAIN %%*
set LASTERROR=%ERRORLEVEL%

rem restore locale
if defined FLAG_CHCP call "%%CONTOOLS_ROOT%%/std/restorecp.bat" -p

:FREE_TEMP_DIR
rem cleanup temporary files
call "%%CONTOOLS_ROOT%%/std/free_temp_dir.bat"

:FREE_TEMP_DIR_END
set /A NEST_LVL-=1

:EXIT
if %NEST_LVL%0 EQU 0 if defined OEMCP ( call "%%CONTOOLS_ROOT%%/std/pause.bat" -chcp "%%OEMCP%%" ) else call "%%CONTOOLS_ROOT%%/std/pause.bat"

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
echo.Required set of 3dparty software included into install:
echo. * Notepad++ (%NOTEPADPP_MIN_VER_STR%+, https://notepad-plus-plus.org/downloads/ )
echo. * Notepad++ PythonScript plugin (%NOTEPADPP_PYTHON_SCRIPT_PLUGIN_MIN_VER_STR%+, https://github.com/bruderstein/PythonScript )
echo. * WinMerge (%WINMERGE_MIN_VER_STR%+, https://winmerge.org/downloads )
echo. * Visual C++ 2008 Redistributables (%VCREDIST_2008_MIN_VER_STR%+, https://www.catalog.update.microsoft.com/Search.aspx?q=kb2538243 )
echo.
echo.Required set of 3dparty software not included into install:
echo  * ffmpeg (ffmpeg module,
echo.           https://ffmpeg.org/download.html#build-windows, https://github.com/BtbN/FFmpeg-Builds/releases,
echo.           https://github.com/Reino17/ffmpeg-windows-build-helpers, https://rwijnsma.home.xs4all.nl/files/ffmpeg/?C=M;O=D )
echo. * msys2 (coreutils package, https://www.msys2.org/#installation )
echo. * cygwin (coreutils package, https://cygwin.com )
echo.
echo.Optional set of supported 3dparty software not included into install:
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
echo.Do you want to continue [y]es/[n]o?
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

if defined DETECTED_NPP_EDITOR if exist "%DETECTED_NPP_EDITOR%" goto DETECTED_NPP_EDITOR_OK

(
  echo.%?~nx0%: error: Notepad++ must be already installed before continue.
  goto CANCEL_INSTALL
) >&2

:DETECTED_NPP_EDITOR_OK

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
if defined OEMCP ( call "%%CONTOOLS_ROOT%%/std/xcopy_file.bat" -chcp "%%OEMCP%%" %%*
) else call "%%CONTOOLS_ROOT%%/std/xcopy_file.bat" %%*
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
if defined OEMCP ( call "%%CONTOOLS_ROOT%%/std/xcopy_dir.bat" -chcp "%%OEMCP%%" %%*
) else  call "%%CONTOOLS_ROOT%%/std/xcopy_dir.bat" %%*
exit /b

:MAKE_DIR
for /F "eol= tokens=* delims=" %%i in ("%~1\.") do set "FILE_PATH=%%~fi"

if exist "%SystemRoot%\System32\robocopy.exe" (
  mkdir "%FILE_PATH%" 2>nul || if exist "%SystemRoot%\System32\robocopy.exe" ( "%SystemRoot%\System32\robocopy.exe" /CREATE "%EMPTY_DIR_TMP%" "%FILE_PATH%" >nul )
) else mkdir "%FILE_PATH%" 2>nul
exit /b

:MOVE_FILE
for /F "eol= tokens=* delims=" %%i in ("%~1\.") do set "FROM_FILE_PATH=%%~fi"
for /F "eol= tokens=* delims=" %%i in ("%~2\.") do set "TO_FILE_PATH=%%~fi"

if exist "%SystemRoot%\System32\robocopy.exe" (
  "%SystemRoot%\System32\robocopy.exe" /MOVE "%FROM_FILE_PATH%" "%TO_FILE_PATH%" "%~3" >nul
) else move "%FROM_FILE_PATH%\%~3" "%TO_FILE_PATH%\%~3" >nul
exit /b

:MOVE_DIR
for /F "eol= tokens=* delims=" %%i in ("%~1\.") do set "FROM_FILE_DIR=%%~fi"
for /F "eol= tokens=* delims=" %%i in ("%~2\.") do set "TO_FILE_DIR=%%~fi"

if exist "%SystemRoot%\System32\robocopy.exe" (
  "%SystemRoot%\System32\robocopy.exe" /MOVE /E "%FROM_FILE_DIR%" "%TO_FILE_DIR%" "*.*" >nul
) else (
  if exist "\\?\%TO_FILE_DIR%\" rmdir /Q "%TO_FILE_DIR%"
  "%SystemRoot%\System32\cscript.exe" //NOLOGO "%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/shell/move_dir.vbs" "%FROM_FILE_DIR%" "%TO_FILE_DIR%"
)
exit /b

:CMD
echo.^>%*
(%*)
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
