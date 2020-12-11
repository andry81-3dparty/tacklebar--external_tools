@echo off

setlocal

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

rem no local logging if nested call
set WITH_LOGGING=0
if %NEST_LVL%0 EQU 0 set WITH_LOGGING=1

if %WITH_LOGGING% EQU 0 goto IMPL

rem use stdout/stderr redirection with logging
call "%%CONTOOLS_ROOT%%/std/get_wmic_local_datetime.bat"
set "LOG_FILE_NAME_SUFFIX=%RETURN_VALUE:~0,4%'%RETURN_VALUE:~4,2%'%RETURN_VALUE:~6,2%_%RETURN_VALUE:~8,2%'%RETURN_VALUE:~10,2%'%RETURN_VALUE:~12,2%''%RETURN_VALUE:~15,3%"

set "PROJECT_LOG_DIR=%PROJECT_LOG_ROOT%/%LOG_FILE_NAME_SUFFIX%.%~n0"
set "PROJECT_LOG_FILE=%PROJECT_LOG_DIR%/%LOG_FILE_NAME_SUFFIX%.%~n0.log"

if not exist "%PROJECT_LOG_DIR%" ( mkdir "%PROJECT_LOG_DIR%" || exit /b )

set IMPL_MODE=1
rem CAUTION:
rem   We should avoid use handles 3 and 4 while the redirection has take a place because handles does reuse
rem   internally from left to right when being redirected externally.
rem   Example: if `1` is redirected, then `3` is internally reused, then if `2` redirected, then `4` is internally reused and so on.
rem   The discussion of the logic:
rem   https://stackoverflow.com/questions/9878007/why-doesnt-my-stderr-redirection-end-after-command-finishes-and-how-do-i-fix-i/9880156#9880156
rem   A partial analisis:
rem   https://www.dostips.com/forum/viewtopic.php?p=14612#p14612
rem
"%COMSPEC%" /C call %0 %* 2>&1 | "%CONTOOLS_UTILITIES_BIN_ROOT%/ritchielawrence/mtee.exe" /E "%PROJECT_LOG_FILE:/=\%"
exit /b

:IMPL
set /A NEST_LVL+=1

call "%%CONTOOLS_ROOT%%/std/allocate_temp_dir.bat" . "%%?~n0%%"

call "%%CONTOOLS_ROOT%%/std/chcp.bat" 65001
set RESTORE_LOCALE=1

call :MAIN %%*
set LASTERROR=%ERRORLEVEL%

rem restore locale
if %RESTORE_LOCALE% NEQ 0 call "%%CONTOOLS_ROOT%%/std/restorecp.bat"

rem cleanup temporary files
call "%%CONTOOLS_ROOT%%/std/free_temp_dir.bat"

set /A NEST_LVL-=1

if %NEST_LVL%0 EQU 0 call "%%CONTOOLS_ROOT%%/std/pause.bat"

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

rem script flags
rem set FLAG_IGNORE_BUTTONBARS=0

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG (
  rem if "%FLAG%" == "-ignore_buttonbars" (
  rem   set FLAG_IGNORE_BUTTONBARS=1
  rem ) else
  (
    echo.%?~nx0%: error: invalid flag: %FLAG%
    exit /b -255
  ) >&2

  shift

  rem read until no flags
  goto FLAGS_LOOP
)

set "EMPTY_DIR_TMP=%SCRIPT_TEMP_CURRENT_DIR%\emptydir"

mkdir "%EMPTY_DIR_TMP%" || (
  echo.%?~n0%: error: could not create a directory: "%EMPTY_DIR_TMP%".
  exit /b 255
) >&2

echo.
echo.Required set of 3dparty applications included into install:
echo. * Notepad++ (%NOTEPADPP_MIN_VER_STR%+, https://notepad-plus-plus.org/downloads/ )
echo. * Notepad++ PythonScript plugin (%NOTEPADPP_PYTHON_SCRIPT_PLUGIN_MIN_VER_STR%+, https://github.com/bruderstein/PythonScript )
echo. * WinMerge (%WINMERGE_MIN_VER_STR%+, https://winmerge.org/downloads )
echo.
echo.Required set of 3dparty applications not included into install:
echo  * ffmpeg (ffmpeg module, https://ffmpeg.org/download.html#build-windows )
echo. * msys2 (coreutils package, https://www.msys2.org/#installation)
echo. * cygwin (coreutils package, https://cygwin.com )
echo.
echo.Optional set of 3dparty applications:
echo. * Araxis Merge (%ARAXIS_MERGE_MIN_VER_STR%+, https://www.araxis.com/merge/documentation-windows/release-notes.en )
echo.
echo. CAUTION:
echo.   You must install at least Notepad++ (with PythonScript plugin) and WinMerge (or Araxis Merge) to continue.
echo.

:REPEAT_INSTALL_3DPARTY_ASK
set "CONTINUE_INSTALL_ASK="
echo.Do you want to continue [y]es/[n]o?
set /P "CONTINUE_INSTALL_ASK="

if /i "%CONTINUE_INSTALL_ASK%" == "y" goto CONTINUE_INSTALL_3DPARTY_ASK
if /i "%CONTINUE_INSTALL_ASK%" == "n" goto CANCEL_INSTALL_3DPARTY_ASK

goto REPEAT_INSTALL_3DPARTY_ASK

:CANCEL_INSTALL_3DPARTY_ASK
(
  echo.%?~nx0%: info: installation is canceled.
  exit /b 127
) >&2

:CONTINUE_INSTALL_3DPARTY_ASK

echo.

echo.Installing Notepad++...

call :CMD start /B /WAIT "" "%%NOTEPAD_PLUS_PLUS_SETUP%%"

echo.

call "%%?~dp0%%.%%?~n0%%/%%?~n0%%.detect_3dparty.notepadpp.bat"

echo.

if defined DETECTED_NPP_EDITOR if exist "%DETECTED_NPP_EDITOR%" goto DETECTED_NPP_EDITOR_OK

(
  echo.%?~nx0%: error: Notepad++ must be already installed before continue.
  echo.%?~nx0%: info: installation is canceled.
  exit /b 127
) >&2

:DETECTED_NPP_EDITOR_OK

echo.Installing Notepad++ PythonScript plugin...

rem CAUTION: We must avoid forwarding slashes and trailing back slash here altogether
for /F "eol=	 tokens=* delims=" %%i in ("%NOTEPAD_PLUS_PLUS_PYTHON_SCRIPT_PLUGIN_SETUP%\.") do set "NOTEPAD_PLUS_PLUS_PYTHON_SCRIPT_PLUGIN_SETUP=%%~fi"
for /F "eol=	 tokens=* delims=" %%i in ("%DETECTED_NPP_EDITOR%\.") do for /F "eol=	 tokens=* delims=" %%j in ("%%~dpi\.") do set "DETECTED_NPP_INSTALL_DIR=%%~fj"

rem CAUTION:
rem   The plugin installer is broken, must always point the Notepad++ installation location!
rem
call :CMD start /B /WAIT "" "%%WINDIR%%\System32\msiexec.exe" /i "%%NOTEPAD_PLUS_PLUS_PYTHON_SCRIPT_PLUGIN_SETUP%%" INSTALLDIR="%%DETECTED_NPP_INSTALL_DIR%%"

echo.

echo.Updating Notepad++ PythonScript plugin configuration...

if not exist "%USERPROFILE%/AppData/Roaming/Notepad++\" (
  echo.%?~nx0%: error: Notepad++ user configuration directory is not found: "%USERPROFILE%/AppData/Roaming/Notepad++"
  goto INSTALL_WINMERGE
) >&2

echo.Updating "%USERPROFILE%\AppData\Roaming\Notepad++\plugins\Config\PythonScriptStartup.cnf"...

if exist "%USERPROFILE%/AppData/Roaming/Notepad++/plugins/Config/PythonScriptStartup.cnf" (
  for /F "useback eol= tokens=* delims=" %%i in ("%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_ROOT%/deploy/notepad++/plugins/PythonScript/Config/PythonScriptStartup.cnf") do (
    "%WINDIR%/System32/findstr.exe" /R /C:"^%%i$" "%USERPROFILE%\AppData\Roaming\Notepad++\plugins\Config\PythonScriptStartup.cnf" >nul || (
      echo.+%%i
      (echo.%%i) >> "%USERPROFILE%\AppData\Roaming\Notepad++\plugins\Config\PythonScriptStartup.cnf"
    )
  )
) else (
  call :XCOPY_FILE "%%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_ROOT%%/deploy/notepad++/plugins/PythonScript/Config" PythonScriptStartup.cnf "%%USERPROFILE%%/AppData/Roaming/Notepad++/plugins/Config" /Y /D /H
)

echo.

echo.Updating "%USERPROFILE%\AppData\Roaming\Notepad++\plugins\Config\PythonScript\scripts\"...

set "PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR=%USERPROFILE%\AppData\Roaming\Notepad++\plugins\Config\PythonScript\scripts"

if not exist "\\?\%USERPROFILE%\AppData\Roaming\Notepad++\plugins\Config\PythonScript\scripts\" (
  echo.^>mkdir "%USERPROFILE%\AppData\Roaming\Notepad++\plugins\Config\PythonScript\scripts"
  mkdir "%USERPROFILE%\AppData\Roaming\Notepad++\plugins\Config\PythonScript\scripts" 2>nul || "%WINDIR%/System32/robocopy.exe" /CREATE "%EMPTY_DIR_TMP%" "%USERPROFILE%\AppData\Roaming\Notepad++\plugins\Config\PythonScript\scripts" >nul
)

for %%i in (tacklebar\ startup.py) do (
  if exist "\\?\%USERPROFILE%\AppData\Roaming\Notepad++\plugins\Config\PythonScript\scripts\%%~i" goto PYTHON_SCRIPT_BACKUP
)

goto IGNORE_PYTHON_SCRIPT_BACKUP

:PYTHON_SCRIPT_BACKUP
if not exist "\\?\%USERPROFILE%\AppData\Roaming\Notepad++\plugins\Config\PythonScript\scripts\.tacklebar_prev_install\" (
  mkdir "%USERPROFILE%\AppData\Roaming\Notepad++\plugins\Config\PythonScript\scripts\.tacklebar_prev_install" 2>nul || "%WINDIR%/System32/robocopy.exe" /CREATE "%EMPTY_DIR_TMP%" "%USERPROFILE%\AppData\Roaming\Notepad++\plugins\Config\PythonScript\scripts\.tacklebar_prev_install" >nul
)

set "NEW_PREV_INSTALL_DIR=%PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR%\.tacklebar_prev_install\tacklebar_prev_install_%LOG_FILE_NAME_SUFFIX%"

if not exist "\\?\%NEW_PREV_INSTALL_DIR%" (
  echo.^>mkdir "%NEW_PREV_INSTALL_DIR%"
  mkdir "%NEW_PREV_INSTALL_DIR%" 2>nul || "%WINDIR%/System32/robocopy.exe" /CREATE "%EMPTY_DIR_TMP%" "%NEW_PREV_INSTALL_DIR%" >nul
  if not exist "\\?\%NEW_PREV_INSTALL_DIR%" (
    echo.%?~nx0%: error: could not create a backup file directory: "%NEW_PREV_INSTALL_DIR%".
    echo.%?~nx0%: warning: Notepad++ PythonScript plugin scripts installation is cancelled.
    goto INSTALL_WINMERGE
  ) >&2
)

if exist "%PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR%\startup.py" (
  echo.%?~nx0%: warning: Notepad++ PythonScript plugin startup script has been already existed, will be replaced.
) >&2

for %%i in (tacklebar\ startup.py) do (
  if exist "%PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR%\%%~i" (
    echo.^>move: "%PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR%\%%i" -^> "%NEW_PREV_INSTALL_DIR%"
    if not "%%~nxi" == "" (
      "%WINDIR%/System32/robocopy.exe" /MOVE "%PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR%" "%NEW_PREV_INSTALL_DIR%" "%%i" >nul
      if not exist "\\?\%NEW_PREV_INSTALL_DIR%\%%i" (
        echo.%?~nx0%: error: could not move previous installation file: "%PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR%\%%i" -^> "%NEW_PREV_INSTALL_DIR%"
        echo.%?~nx0%: warning: Notepad++ PythonScript plugin scripts installation is cancelled.
        goto INSTALL_WINMERGE
      ) >&2
    ) else (
      "%WINDIR%/System32/robocopy.exe" /MOVE /E "%PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR%\%%i\" "%NEW_PREV_INSTALL_DIR%\%%i\" "*.*" >nul
      if not exist "\\?\%NEW_PREV_INSTALL_DIR%\%%i" (
        echo.%?~nx0%: error: could not move previous installation directory: "%PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR%\%%i" -^> "%NEW_PREV_INSTALL_DIR%"
        echo.%?~nx0%: warning: Notepad++ PythonScript plugin scripts installation is cancelled.
        goto INSTALL_WINMERGE
      ) >&2
    )
  )
)

:IGNORE_PYTHON_SCRIPT_BACKUP
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
  mkdir "%~3" 2>nul || "%WINDIR%/System32/robocopy.exe" /CREATE "%EMPTY_DIR_TMP%" "%~3" >nul || (
    echo.%?~nx0%: error: could not create a target file directory: "%~3".
    exit /b 255
  ) >&2
)
call "%%CONTOOLS_ROOT%%/std/xcopy_file.bat" %%*
exit /b

:XCOPY_DIR
if not exist "\\?\%~f2" (
  echo.^>mkdir "%~2"
  mkdir "%~2" 2>nul || "%WINDIR%/System32/robocopy.exe" /CREATE "%EMPTY_DIR_TMP%" "%~2" >nul || (
    echo.%?~nx0%: error: could not create a target directory: "%~2".
    exit /b 255
  ) >&2
)
call "%%CONTOOLS_ROOT%%/std/xcopy_dir.bat" %%*
exit /b

:CMD
echo.^>%*
(%*)
exit /b

:CANONICAL_PATH
setlocal DISABLEDELAYEDEXPANSION
for /F "eol= tokens=* delims=" %%i in ("%~2\.") do set "RETURN_VALUE=%~fi"
set "RETURN_VALUE=%RETURN_VALUE:\=/%"
(
  endlocal
  set "%~1=%RETURN_VALUE%"
)
exit /b 0
