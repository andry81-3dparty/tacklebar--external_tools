@echo off

setlocal

set "?~0=%~0"
set "?~f0=%~f0"
set "?~dp0=%~dp0"
set "?~n0=%~n0"
set "?~nx0=%~nx0"

call "%%~dp0__init__/__init__.bat" 0 || exit /b

for %%i in (PROJECT_ROOT PROJECT_LOG_ROOT PROJECT_CONFIG_ROOT CONTOOLS_ROOT CONTOOLS_UTILITIES_BIN_ROOT) do (
  if not defined %%i (
    echo.%~nx0: error: `%%i` variable is not defined.
    exit /b 255
  ) >&2
)

if %IMPL_MODE%0 NEQ 0 goto IMPL

rem use stdout/stderr redirection with logging
call "%%CONTOOLS_ROOT%%/std/get_wmic_local_datetime.bat"
set "LOG_FILE_NAME_SUFFIX=%RETURN_VALUE:~0,4%'%RETURN_VALUE:~4,2%'%RETURN_VALUE:~6,2%_%RETURN_VALUE:~8,2%'%RETURN_VALUE:~10,2%'%RETURN_VALUE:~12,2%''%RETURN_VALUE:~15,3%"

set "PROJECT_LOG_DIR=%PROJECT_LOG_ROOT%\%LOG_FILE_NAME_SUFFIX%.%~n0"
set "PROJECT_LOG_FILE=%PROJECT_LOG_DIR%\%LOG_FILE_NAME_SUFFIX%.%~n0.log"

if not exist "%PROJECT_LOG_DIR%" ( mkdir "%PROJECT_LOG_DIR%" || exit /b )

rem Workaround for the Windows 7/XP issue:
rem 1. Windows 7: log is empty
rem 2. Windows XP: log file name is truncated

rem CAUTION:
rem   Usage of the `ver` is not reliable because rely on the `XP` suffix, which in Windows XP x64 SP1 MAY DOES NOT EXIST!
rem
call "%%CONTOOLS_ROOT%%/std/get_wmic_os_version.bat"
set "WINDOWS_VER_STR=%RETURN_VALUE%"

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

rem Pass local environment variables to elevated process through a file
set "ENVIRONMENT_VARS_FILE=%PROJECT_LOG_DIR%\environment.vars"
(
  echo."LOG_FILE_NAME_SUFFIX=%LOG_FILE_NAME_SUFFIX%"
  echo."PROJECT_LOG_DIR=%PROJECT_LOG_DIR%"
  echo."PROJECT_LOG_FILE=%PROJECT_LOG_FILE%"
  echo "COMMANDER_SCRIPTS_ROOT=%COMMANDER_SCRIPTS_ROOT%"
  echo "COMMANDER_INI=%COMMANDER_INI%"
  echo "WINDOWS_VER_STR=%WINDOWS_VER_STR%"
  echo "WINDOWS_MAJOR_VER=%WINDOWS_MAJOR_VER%"
  echo "WINDOWS_MINOR_VER=%WINDOWS_MINOR_VER%"
) > "%ENVIRONMENT_VARS_FILE%"

rem CAUTION:
rem   We should avoid use handles 3 and 4 while the redirection has take a place because handles does reuse
rem   internally from left to right when being redirected externally.
rem   Example: if `1` is redirected, then `3` is internally reused, then if `2` redirected, then `4` is internally reused and so on.
rem   The discussion of the logic:
rem   https://stackoverflow.com/questions/9878007/why-doesnt-my-stderr-redirection-end-after-command-finishes-and-how-do-i-fix-i/9880156#9880156
rem   A partial analisis:
rem   https://www.dostips.com/forum/viewtopic.php?p=14612#p14612
rem

if %WINDOWS_MAJOR_VER% GTR 5 (
  "%CONTOOLS_ROOT%/ToolAdaptors/lnk/cmd_admin.lnk" /C set "IMPL_MODE=1" ^& set "ENVIRONMENT_VARS_FILE=%ENVIRONMENT_VARS_FILE%" ^& call "%?~f0%" %* 2^>^&1 ^| "%CONTOOLS_UTILITIES_BIN_ROOT%/ritchielawrence/mtee.exe" /E "%PROJECT_LOG_FILE:/=\%"
) else "%CONTOOLS_ROOT%/ToolAdaptors/lnk/cmd_admin.lnk" /C set "IMPL_MODE=1" ^& set "ENVIRONMENT_VARS_FILE=%ENVIRONMENT_VARS_FILE%" ^& call "%?~f0%" %* 2>&1 | "%CONTOOLS_UTILITIES_BIN_ROOT%/ritchielawrence/mtee.exe" /E "%PROJECT_LOG_FILE:/=\%"
set LASTERROR=%ERRORLEVEL%

call "%%CONTOOLS_ROOT%%/registry/regquery.bat" "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" COMMANDER_SCRIPTS_ROOT >nul 2>nul
if defined REGQUERY_VALUE set "COMMANDER_SCRIPTS_ROOT=%REGQUERY_VALUE%"

rem return registered variables outside to reuse them again from the same process
(
  endlocal
  set "COMMANDER_SCRIPTS_ROOT=%COMMANDER_SCRIPTS_ROOT%"
  exit /b %LASTERROR%
)

:IMPL
rem Check for true elevated environment (required in case of Windows XP)
"%SystemRoot%\System32\net.exe" session >nul 2>nul || (
  echo.%?~nx0%: error: the script process is not properly elevated up to Administrator privileges.
  set LASTERROR=255
  goto EXIT
) >&2

rem Load local environment variables
for /F "usebackq eol=# tokens=* delims=" %%i in ("%ENVIRONMENT_VARS_FILE%") do set %%i

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

rem there to install
set "INSTALL_TO_DIR=%~1"

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
) else if exist "%SystemRoot%\System32\chcp.com" for /F "usebackq eol= tokens=1,* delims=:" %%i in (`@"%%SystemRoot%%\System32\chcp.com" 2^>nul`) do set "CURRENT_CP=%%j"
if defined CURRENT_CP set "CURRENT_CP=%CURRENT_CP: =%"

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

if not defined INSTALL_TO_DIR if not defined COMMANDER_SCRIPTS_ROOT (
  echo.%?~nx0%: error: INSTALL_TO_DIR must be defined if COMMANDER_SCRIPTS_ROOT is not defined
  exit /b 1
) >&2

if defined INSTALL_TO_DIR call :CANONICAL_PATH INSTALL_TO_DIR "%%INSTALL_TO_DIR%%"
if defined COMMANDER_SCRIPTS_ROOT call :CANONICAL_PATH COMMANDER_SCRIPTS_ROOT "%%COMMANDER_SCRIPTS_ROOT%%"

if defined INSTALL_TO_DIR (
  if not exist "\\?\%INSTALL_TO_DIR%\" (
    echo.%?~nx0%: error: INSTALL_TO_DIR is not a directory: "%INSTALL_TO_DIR%"
    exit /b 10
  ) >&2
) else (
  if not exist "\\?\%COMMANDER_SCRIPTS_ROOT%\" (
    echo.%?~nx0%: error: COMMANDER_SCRIPTS_ROOT is not a directory: "%COMMANDER_SCRIPTS_ROOT%"
    exit /b 11
  ) >&2
)

if not defined INSTALL_TO_DIR goto CONTINUE_INSTALL_TO_INSTALL_TO_DIR
if not defined COMMANDER_SCRIPTS_ROOT goto CONTINUE_INSTALL_TO_INSTALL_TO_DIR

if /i not "%INSTALL_TO_DIR%" == "%COMMANDER_SCRIPTS_ROOT%" (
  echo.*         INSTALL_TO_DIR="%INSTALL_TO_DIR%"
  echo.* COMMANDER_SCRIPTS_ROOT="%COMMANDER_SCRIPTS_ROOT%"
  echo.
  echo.The `COMMANDER_SCRIPTS_ROOT` variable is defined and is different to the inputed `INSTALL_TO_DIR`.
) >&2 else goto CONTINUE_INSTALL_TO_INSTALL_TO_DIR

:REPEAT_INSTALL_TO_INSTALL_TO_DIR_ASK
set "CONTINUE_INSTALL_ASK="
echo.Do you want to install into different directory [y]es/[n]o?
set /P "CONTINUE_INSTALL_ASK="

if /i "%CONTINUE_INSTALL_ASK%" == "y" goto CONTINUE_INSTALL_TO_INSTALL_TO_DIR
if /i "%CONTINUE_INSTALL_ASK%" == "n" goto CANCEL_INSTALL

goto REPEAT_INSTALL_TO_INSTALL_TO_DIR_ASK

:CONTINUE_INSTALL_TO_INSTALL_TO_DIR

if defined INSTALL_TO_DIR goto IGNORE_INSTALL_TO_COMMANDER_SCRIPTS_ROOT_ASK

echo.* COMMANDER_SCRIPTS_ROOT="%COMMANDER_SCRIPTS_ROOT%"
echo.
echo.The explicit installation directory is not defined, the installation will be proceed into directory from the `COMMANDER_SCRIPTS_ROOT` variable.
echo.Close all scripts has been running from the previous installation directory before continue (previous installation directory will be moved and renamed).
echo.

:REPEAT_INSTALL_TO_COMMANDER_SCRIPTS_ROOT_ASK
set "CONTINUE_INSTALL_ASK="
echo.Do you want to continue [y]es/[n]o?
set /P "CONTINUE_INSTALL_ASK="

if /i "%CONTINUE_INSTALL_ASK%" == "y" goto CONTINUE_INSTALL_TO_COMMANDER_SCRIPTS_ROOT
if /i "%CONTINUE_INSTALL_ASK%" == "n" goto CANCEL_INSTALL

goto REPEAT_INSTALL_TO_COMMANDER_SCRIPTS_ROOT_ASK

:IGNORE_INSTALL_TO_COMMANDER_SCRIPTS_ROOT_ASK
:CONTINUE_INSTALL_TO_COMMANDER_SCRIPTS_ROOT

if not defined INSTALL_TO_DIR set "INSTALL_TO_DIR=%COMMANDER_SCRIPTS_ROOT%"

echo.
echo.Required Windows version: %WINDOWS_MIN_VER_STR%+
echo.
echo.Required set of 3dparty software included into install:
echo. * Notepad++ (%NOTEPADPP_MIN_VER_STR%+, https://notepad-plus-plus.org/downloads/ )
echo. * Notepad++ PythonScript plugin (%NOTEPADPP_PYTHON_SCRIPT_PLUGIN_MIN_VER_STR%+, https://github.com/bruderstein/PythonScript )
echo. * WinMerge (%WINMERGE_MIN_VER_STR%+, https://winmerge.org/downloads )
echo. * Visual C++ 2008 Redistributables (%VCREDIST_2008_MIN_VER_STR%+, https://www.catalog.update.microsoft.com/Search.aspx?q=kb2538243 )
echo.
echo.Required set of 3dparty software not included into install:
echo  * ffmpeg (ffmpeg module, https://ffmpeg.org/download.html#build-windows )
echo. * msys2 (coreutils package, https://www.msys2.org/#installation )
echo. * cygwin (coreutils package, https://cygwin.com )
echo.
echo.Optional set of supported 3dparty software not included into install:
echo. * ConEmu (%CONEMU_MIN_VER_STR%+, https://github.com/Maximus5/ConEmu )
echo. * Araxis Merge (%ARAXIS_MERGE_MIN_VER_STR%+, https://www.araxis.com/merge/documentation-windows/release-notes.en )
echo.
echo. CAUTION:
echo.   You must install at least Notepad++ (with PythonScript plugin) and WinMerge (or Araxis Merge) to continue.
echo.

rem Check Windows service pack version and warn the user
if %WINDOWS_MAJOR_VER% GTR 5 goto WINDOWS_SP_VERSION_OK

call "%%CONTOOLS_ROOT%%/std/get_wmic_os_sp_major_version.bat"
if not defined RETURN_VALUE goto WINDOWS_SP_VERSION_OK
if %RETURN_VALUE% GEQ 3 goto WINDOWS_SP_VERSION_OK

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

set "COMMANDER_SCRIPTS_ROOT=%INSTALL_TO_DIR:/=\%"

echo.Updated COMMANDER_SCRIPTS_ROOT variable: "%COMMANDER_SCRIPTS_ROOT%"

rem installing...

rem CAUTION:
rem   The UAC promotion call must be BEFORE this point, because:
rem   1. The UAC promotion cancel equals to cancel the installation.

echo.Registering COMMANDER_SCRIPTS_ROOT variable: "%COMMANDER_SCRIPTS_ROOT%"...

if exist "%SystemRoot%\System32\setx.exe" (
  "%SystemRoot%\System32\setx.exe" /M COMMANDER_SCRIPTS_ROOT "%COMMANDER_SCRIPTS_ROOT%" || (
    echo.%%?~nx0%%: error: could not register `COMMANDER_SCRIPTS_ROOT` variable.
    goto CANCEL_INSTALL
  ) >&2
) else (
  "%SystemRoot%\System32\reg.exe" add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v COMMANDER_SCRIPTS_ROOT /t REG_SZ /d "%COMMANDER_SCRIPTS_ROOT%" /f || (
    echo.%%?~nx0%%: error: could not register `COMMANDER_SCRIPTS_ROOT` variable.
    goto CANCEL_INSTALL
  ) >&2

  rem trigger WM_SETTINGCHANGE
  "%SystemRoot%\System32\cscript.exe" //NOLOGO "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/registry/post_wm_settingchange.vbs"
)

echo.

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

echo.Installing Notepad++ PythonScript plugin...

rem CAUTION: We must avoid forwarding slashes and trailing back slash here altogether
for /F "eol=	 tokens=* delims=" %%i in ("%NOTEPAD_PLUS_PLUS_PYTHON_SCRIPT_PLUGIN_SETUP%\.") do set "NOTEPAD_PLUS_PLUS_PYTHON_SCRIPT_PLUGIN_SETUP=%%~fi"
for /F "eol=	 tokens=* delims=" %%i in ("%DETECTED_NPP_EDITOR%\.") do for /F "eol=	 tokens=* delims=" %%j in ("%%~dpi\.") do set "DETECTED_NPP_INSTALL_DIR=%%~fj"

rem CAUTION:
rem   The plugin installer is broken, must always point the Notepad++ installation location!
rem
call :CMD start /B /WAIT "" "%%SystemRoot%%\System32\msiexec.exe" /i "%%NOTEPAD_PLUS_PLUS_PYTHON_SCRIPT_PLUGIN_SETUP%%" INSTALLDIR="%%DETECTED_NPP_INSTALL_DIR%%"

echo.

rem Fix for the Windows XP x86/x64 or the Windows 7 x86
if %WINDOWS_MAJOR_VER% GTR 5 (
  if /i "%PROCESSOR_ARCHITECTURE%" == "AMD86" goto IGNORE_NPP_PYTHON_SCRIPT_PLUGIN_INSTALL_FIX
  if not defined PROCESSOR_ARCHITEW6432 goto IGNORE_NPP_PYTHON_SCRIPT_PLUGIN_INSTALL_FIX
)

echo.Fixing Notepad++ PythonScript plugin installation...

call :XCOPY_FILE "%%DETECTED_NPP_INSTALL_DIR%%/plugins/PythonScript" python27.dll "%%DETECTED_NPP_INSTALL_DIR%%" /Y /D /H

echo.

:IGNORE_NPP_PYTHON_SCRIPT_PLUGIN_INSTALL_FIX
echo.Updating Notepad++ PythonScript plugin configuration...

if not exist "%USERPROFILE%/Application Data/Notepad++\" (
  echo.%?~nx0%: error: Notepad++ user configuration directory is not found: "%USERPROFILE%/Application Data/Notepad++"
  goto INSTALL_WINMERGE
) >&2

echo.

echo.Updating "%USERPROFILE%\Application Data\Notepad++\plugins\Config\PythonScriptStartup.cnf"...

if exist "%USERPROFILE%/Application Data/Notepad++/plugins/Config/PythonScriptStartup.cnf" (
  for /F "useback eol= tokens=* delims=" %%i in ("%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_ROOT%/deploy/notepad++/plugins/PythonScript/Config/PythonScriptStartup.cnf") do (
    "%SystemRoot%\System32\findstr.exe" /R /C:"^%%i$" "%USERPROFILE%\Application Data\Notepad++\plugins\Config\PythonScriptStartup.cnf" >nul || (
      echo.+%%i
      (echo.%%i) >> "%USERPROFILE%\Application Data\Notepad++\plugins\Config\PythonScriptStartup.cnf"
    )
  )
) else (
  call :XCOPY_FILE "%%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_ROOT%%/deploy/notepad++/plugins/PythonScript/Config" PythonScriptStartup.cnf "%%USERPROFILE%%/Application Data/Notepad++/plugins/Config" /Y /D /H
)

echo.

echo.Updating "%USERPROFILE%\Application Data\Notepad++\plugins\Config\PythonScript\scripts\"...

set "PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR=%USERPROFILE%\Application Data\Notepad++\plugins\Config\PythonScript\scripts"

if not exist "\\?\%USERPROFILE%\Application Data\Notepad++\plugins\Config\PythonScript\scripts\" (
  echo.^>mkdir "%USERPROFILE%\Application Data\Notepad++\plugins\Config\PythonScript\scripts"
  call :MAKE_DIR "%%USERPROFILE%%\Application Data\Notepad++\plugins\Config\PythonScript\scripts"
  echo.
)

for %%i in (tacklebar\ startup.py) do (
  if exist "\\?\%USERPROFILE%\Application Data\Notepad++\plugins\Config\PythonScript\scripts\%%~i" goto NPP_PYTHON_SCRIPT_BACKUP
)

goto IGNORE_NPP_PYTHON_SCRIPT_BACKUP

:NPP_PYTHON_SCRIPT_BACKUP
set "NPP_PYTHON_SCRIPT_NEW_PREV_INSTALL_ROOT=%INSTALL_TO_DIR%\.notepadpp_tacklebar_prev_install"

if not exist "\\?\%NPP_PYTHON_SCRIPT_NEW_PREV_INSTALL_ROOT%" (
  call :MAKE_DIR "%%NPP_PYTHON_SCRIPT_NEW_PREV_INSTALL_ROOT%%"
  if not exist "\\?\%NPP_PYTHON_SCRIPT_NEW_PREV_INSTALL_ROOT%" (
    echo.%?~nx0%: error: could not create a backup file directory: "%NPP_PYTHON_SCRIPT_NEW_PREV_INSTALL_ROOT%".
    goto CANCEL_INSTALL
  ) >&2
  echo.
)

set "NPP_PYTHON_SCRIPT_NEW_PREV_INSTALL_DIR=%NPP_PYTHON_SCRIPT_NEW_PREV_INSTALL_ROOT%\notepadpp_tacklebar_prev_install_%LOG_FILE_NAME_SUFFIX%"

if not exist "\\?\%NPP_PYTHON_SCRIPT_NEW_PREV_INSTALL_DIR%" (
  echo.^>mkdir "%NPP_PYTHON_SCRIPT_NEW_PREV_INSTALL_DIR%"
  call :MAKE_DIR "%%NPP_PYTHON_SCRIPT_NEW_PREV_INSTALL_DIR%%"
  if not exist "\\?\%NPP_PYTHON_SCRIPT_NEW_PREV_INSTALL_DIR%" (
    echo.%?~nx0%: error: could not create a backup file directory: "%NPP_PYTHON_SCRIPT_NEW_PREV_INSTALL_DIR%".
    echo.%?~nx0%: warning: Notepad++ PythonScript plugin scripts installation is cancelled.
    goto INSTALL_WINMERGE
  ) >&2
  echo.
)

if exist "%PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR%\startup.py" (
  echo.%?~nx0%: warning: Notepad++ PythonScript plugin startup script has been already existed, will be replaced.
) >&2

for %%i in (tacklebar\ startup.py) do (
  if exist "%PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR%\%%~i" (
    echo.^>move: "%PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR%\%%i" -^> "%NPP_PYTHON_SCRIPT_NEW_PREV_INSTALL_DIR%\%%i"
    if not "%%~nxi" == "" (
      call :MOVE_FILE "%%PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR%%" "%%NPP_PYTHON_SCRIPT_NEW_PREV_INSTALL_DIR%%" "%%i"
      if not exist "\\?\%NPP_PYTHON_SCRIPT_NEW_PREV_INSTALL_DIR%\%%i" (
        echo.%?~nx0%: error: could not move previous installation file: "%PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR%\%%i" -^> "%NPP_PYTHON_SCRIPT_NEW_PREV_INSTALL_DIR%"
        echo.%?~nx0%: warning: Notepad++ PythonScript plugin scripts installation is cancelled.
        goto INSTALL_WINMERGE
      ) >&2
    ) else (
      call :MOVE_DIR "%PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR%\%%i" "%NPP_PYTHON_SCRIPT_NEW_PREV_INSTALL_DIR%\%%i"
      if not exist "\\?\%NPP_PYTHON_SCRIPT_NEW_PREV_INSTALL_DIR%" (
        echo.%?~nx0%: error: could not move previous installation directory: "%PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR%\%%i" -^> "%NPP_PYTHON_SCRIPT_NEW_PREV_INSTALL_DIR%"
        echo.%?~nx0%: warning: Notepad++ PythonScript plugin scripts installation is cancelled.
        goto INSTALL_WINMERGE
      ) >&2
    )
    echo.
  )
)

:IGNORE_NPP_PYTHON_SCRIPT_BACKUP
call :XCOPY_DIR "%%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_EXTERNALS_ROOT%%/contools/Scripts/Tools/ToolAdaptors/notepadplusplus/scripts/tacklebar" "%%PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR%%/tacklebar" /E /Y /D
call :XCOPY_FILE "%%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_EXTERNALS_ROOT%%/contools/Scripts/Tools/ToolAdaptors/notepadplusplus/scripts" startup.py "%%PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR%%" /Y /D /H

:INSTALL_WINMERGE
echo.

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
  mkdir "%FILE_PATH%" 2>nul || "%SystemRoot%\System32\robocopy.exe" /CREATE "%EMPTY_DIR_TMP%" "%FILE_PATH%" >nul
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
