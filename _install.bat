@echo off

setlocal

call "%%~dp0._install/script_init.bat" tacklebar--external_tools install %%0 %%* || exit /b
if %IMPL_MODE%0 NEQ 0 goto IMPL

exit /b 0

:IMPL
rem CAUTION:
rem   We have to change the codepage here because the change would be revoked upon the UAC promotion.
rem

if defined FLAG_CHCP ( call "%%CONTOOLS_ROOT%%/std/chcp.bat" -p %%FLAG_CHCP%%
) else call "%%CONTOOLS_ROOT%%/std/getcp.bat"

call "%%CONTOOLS_ROOT%%/std/allocate_temp_dir.bat" . "%%?~n0%%" || ( set "LAST_ERROR=255" & goto FREE_TEMP_DIR )

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
set LAST_ERROR=%ERRORLEVEL%

:FREE_TEMP_DIR
rem cleanup temporary files
call "%%CONTOOLS_ROOT%%/std/free_temp_dir.bat"

:FREE_TEMP_DIR_END
rem restore locale
if defined FLAG_CHCP call "%%CONTOOLS_ROOT%%/std/restorecp.bat" -p

set /A NEST_LVL-=1

echo.%?~nx0%: info: installation log directory: "%PROJECT_LOG_DIR%".
echo.

exit /b %LAST_ERROR%

:MAIN
rem call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/callln.bat" "%%PYTHON_EXE_PATH%%" "%%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_ROOT%%/_install.xsh"
rem exit /b

if %WINDOWS_MAJOR_VER% GTR 5 (
  if not exist "%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_EXTERNALS_ROOT%/apps/win7/*" (
    echo.%?~nx0%: error: `.externals-win7` externals must be checkout before install.
    exit /b 255
  ) >&2
) else (
  if not exist "%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_EXTERNALS_ROOT%/apps/winxp/*" (
    echo.%?~nx0%: error: `.externals-winxp` externals must be checkout before install.
    exit /b 255
  ) >&2
)

rem echo.
echo.Required Windows version:         %WINDOWS_X64_MIN_VER_STR%+ OR %WINDOWS_X86_MIN_VER_STR%+
echo.
echo.Required set of 3dparty software included into distribution:
echo. * Notepad++ (%NOTEPADPP_MIN_VER_STR%+)
echo.   https://notepad-plus-plus.org/downloads/
echo. * Notepad++ PythonScript plugin (%NOTEPADPP_PYTHON_SCRIPT_PLUGIN_MIN_VER_STR%+)
echo.   https://github.com/bruderstein/PythonScript
echo. * WinMerge (Windows 7+, XP x86 SP3+: %WINMERGE_MIN_VER_STR%+, Windows XP x64: 2.16.2)
echo.   https://winmerge.org/downloads
echo. * Visual C++ 2008 Redistributables (%VCREDIST_2008_MIN_VER_STR%+)
echo.   https://www.catalog.update.microsoft.com/Search.aspx?q=kb2538243
echo.
echo.Required set of 3dparty software not included into distribution:
echo. * Git (%GIT_MIN_VER_STR%+)
echo.   https://git-scm.com
echo. * Bash shell for Git (%GIT_SHELL_MIN_VER_STR%+)
echo.   https://git-scm.com (builtin package)
echo.   https://www.msys2.org/#installation (`Bash` package)
echo.   https://cygwin.com (`Bash` package)
echo. * GitExtensions (%GITEXTENSIONS_MIN_VER_STR%+)
echo.   https://github.com/gitextensions/gitextensions
echo. * TortoiseSVN (%TORTOISESVN_MIN_VER_STR%+)
echo.   https://tortoisesvn.net/
echo. * ffmpeg
echo.   https://ffmpeg.org/download.html#build-windows
echo.   https://github.com/BtbN/FFmpeg-Builds/releases
echo.   https://github.com/Reino17/ffmpeg-windows-build-helpers
echo.   https://rwijnsma.home.xs4all.nl/files/ffmpeg/?C=M;O=D
echo. * msys2
echo.   https://www.msys2.org/#installation (`coreutils` package)
echo. * cygwin
echo.   https://cygwin.com (`coreutils` package)
echo.
echo.Optional set of supported 3dparty software not included into distribution:
echo. * MinTTY
echo.   https://mintty.github.io, https://github.com/mintty/mintty
echo. * ConEmu (%CONEMU_MIN_VER_STR%+)
echo.   https://github.com/Maximus5/ConEmu
echo.   NOTE: Under the Windows XP x64 SP2 only x86 version does work.
echo. * Araxis Merge (%ARAXIS_MERGE_MIN_VER_STR%+)
echo.   https://www.araxis.com/merge/documentation-windows/release-notes.en
echo.

echo.===============================================================================
echo.CAUTION:
echo. You must install at least Notepad++ (with PythonScript plugin) and
echo. WinMerge (or Araxis Merge) to continue.
echo.===============================================================================
echo.

rem Check Windows service pack version and warn the user
if %WINDOWS_MAJOR_VER% GTR 5 goto WINDOWS_SP_VERSION_OK

call "%%CONTOOLS_ROOT%%\wmi\get_wmic_os_sp_major_version.bat"
if not defined RETURN_VALUE goto WINDOWS_SP_VERSION_OK

rem Windows XP x64 SP2 or Windows XP x86 SP3
if %WINDOWS_X64_VER% NEQ 0 (
  if %RETURN_VALUE% GEQ 1 goto WINDOWS_SP_VERSION_OK
) else if %RETURN_VALUE% GEQ 3 goto WINDOWS_SP_VERSION_OK

echo.CAUTION:
echo. Windows XP service pack version: %RETURN_VALUE%
echo. This version of Windows XP is not supported by 3dparty software declared in the list above.
echo. You can continue to install, but if 3dparty software will stop work you have to manually find or downgrade to an old version.
echo.

:WINDOWS_SP_VERSION_OK

:REPEAT_INSTALL_3DPARTY_ASK
set "CONTINUE_INSTALL_ASK="

echo.===============================================================================
echo.CAUTION:
echo. Close all applications from the required section has been running before continue.
echo.===============================================================================
echo.
echo.Ready to install, do you want to continue [y]es/[n]o?
set /P "CONTINUE_INSTALL_ASK="

if /i "%CONTINUE_INSTALL_ASK%" == "y" goto CONTINUE_INSTALL_3DPARTY_ASK
if /i "%CONTINUE_INSTALL_ASK%" == "n" goto CANCEL_INSTALL

goto REPEAT_INSTALL_3DPARTY_ASK

:CONTINUE_INSTALL_3DPARTY_ASK
echo.

rem installing...

if not %WINDOWS_MAJOR_VER% GTR 5 (
  echo.Installing Redistributables...

  call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" start /B /WAIT "" "%%VCREDIST_2008_SETUP%%"

  echo.
)

rem NOTE:
rem   The default is Notepad++ 32-bit to use 32-bit Plugin Manager as most compatible for plugins.
set "INSTALL_NPP_X64_VER=0"

if not %WINDOWS_MAJOR_VER% GTR 5 goto REPEAT_INSTALL_NPP_X32_ASK
if %WINDOWS_X64_VER% EQU 0 goto REPEAT_INSTALL_NPP_X32_ASK

:REPEAT_INSTALL_NPP_X64_ASK
set "CONTINUE_INSTALL_ASK="
echo.Do you want to install 32-bit or 64-bit version of Notepad++: 3[2]-bit/6[4]-bit/[s]kip/[c]ancel?
set /P "CONTINUE_INSTALL_ASK="

if "%CONTINUE_INSTALL_ASK%" == "2" goto REPEAT_INSTALL_NPP_X32_ASK_END
if "%CONTINUE_INSTALL_ASK%" == "4" set "INSTALL_NPP_X64_VER=1" & goto REPEAT_INSTALL_NPP_X32_ASK_END
if /i "%CONTINUE_INSTALL_ASK%" == "s" (
  echo.%?~nx0%: warning: Notepad++ installation is skipped.
  echo.
  goto SKIP_NPP_INSTALL
) >&2
if /i "%CONTINUE_INSTALL_ASK%" == "c" goto CANCEL_INSTALL

goto REPEAT_INSTALL_NPP_X64_ASK

:REPEAT_INSTALL_NPP_X32_ASK
set "CONTINUE_INSTALL_ASK="
echo.Do you want to install 32-bit version of Notepad++: [y]es/[s]kip/[c]ancel?
set /P "CONTINUE_INSTALL_ASK="

if "%CONTINUE_INSTALL_ASK%" == "y" goto REPEAT_INSTALL_NPP_X32_ASK_END
if /i "%CONTINUE_INSTALL_ASK%" == "s" (
  echo.%?~nx0%: warning: Notepad++ installation is skipped.
  echo.
  goto SKIP_NPP_INSTALL
) >&2
if /i "%CONTINUE_INSTALL_ASK%" == "c" goto CANCEL_INSTALL

goto REPEAT_INSTALL_NPP_X32_ASK

:REPEAT_INSTALL_NPP_X32_ASK_END

if not %WINDOWS_MAJOR_VER% GTR 5 goto SELECT_NPP_INSTALL_DIR_END

echo.Checking previous Notepad++ installation...
echo.

rem detect previous installation and avoid cross bitness installation
call "%%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_EXTERNALS_ROOT%%/tacklebar/._install/_install.detect_3dparty.notepadpp.bat"

if not defined DETECTED_NPP_EDITOR goto PREVIOUS_NPP_INSTALL_DIR_OK
if %DETECTED_NPP_EDITOR_X64_VER%0 EQU %INSTALL_NPP_X64_VER%0 goto PREVIOUS_NPP_INSTALL_DIR_OK

(
  echo.%?~nx0%: warning: previous Notepad++ installation has different bitness: "%DETECTED_NPP_EDITOR%".
  echo.
) >&2

:SELECT_NPP_INSTALL_DIR
echo "Selecting new Notepad++ installation directory..."
echo.

set "INSTALL_NPP_TO_DIR="
for /F "usebackq tokens=* delims="eol^= %%i in (`@"%%CONTOOLS_UTILITIES_BIN_ROOT%%/contools/wxFileDialog.exe" "" "%%DETECTED_NPP_ROOT%%" "Select new Notepad++ installation directory..." -d`) do set "INSTALL_NPP_TO_DIR=%%~fi"

if not defined INSTALL_NPP_TO_DIR (
  echo.%?~nx0%: warning: Notepad++ installation is skipped.
  echo.
  goto SKIP_NPP_INSTALL
) >&2

if /i not "%DETECTED_NPP_ROOT%" == "%INSTALL_NPP_TO_DIR%" goto SELECT_NPP_INSTALL_DIR_END

echo.%?~nx0%: error: you can not select previous Notepad++ installation directory with different bitness.
echo.

goto SELECT_NPP_INSTALL_DIR

:PREVIOUS_NPP_INSTALL_DIR_OK
echo.%?~nx0%: info: previous Notepad++ installation has the same bitness or does not exist: "%DETECTED_NPP_EDITOR%".
echo.

:SELECT_NPP_INSTALL_DIR_END

echo.Installing Notepad++...
echo.

set "NOTEPAD_PLUS_PLUS_SETUP_CMD_LINE="
if defined INSTALL_NPP_TO_DIR set "NOTEPAD_PLUS_PLUS_SETUP_CMD_LINE= /D=%INSTALL_NPP_TO_DIR%"

if %WINDOWS_MAJOR_VER% GTR 5 (
  if %INSTALL_NPP_X64_VER% NEQ 0 (
    call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" start /B /WAIT "" "%%NOTEPAD_PLUS_PLUS_SETUP_WIN7_X64%%"%%NOTEPAD_PLUS_PLUS_SETUP_CMD_LINE%%
  ) else (
    call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" start /B /WAIT "" "%%NOTEPAD_PLUS_PLUS_SETUP_WIN7_X86%%"%%NOTEPAD_PLUS_PLUS_SETUP_CMD_LINE%%
  )
) else (
  call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" start /B /WAIT "" "%%NOTEPAD_PLUS_PLUS_SETUP_WINXP_X86%%"
)

:SKIP_NPP_INSTALL

call "%%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_EXTERNALS_ROOT%%/tacklebar/._install/_install.detect_3dparty.notepadpp.bat"

if not defined DETECTED_NPP_EDITOR goto SKIP_NPP_EDITOR_POSTINSTALL
if not exist "\\?\%DETECTED_NPP_EDITOR%" goto SKIP_NPP_EDITOR_POSTINSTALL

if %WINDOWS_MAJOR_VER% GTR 5 goto IGNORE_NPP_EDITOR_PATCHES

echo.Applying Notepad++ patches...
echo.

if not exist "%DETECTED_NPP_ROOT%/updater/libcurl.dll.bak" move "%DETECTED_NPP_ROOT%\updater\libcurl.dll" "%DETECTED_NPP_ROOT%\updater\libcurl.dll.bak" >nul

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_dir.bat" "%%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_EXTERNALS_ROOT%%/apps/winxp/deploy/libcurl" "%%DETECTED_NPP_ROOT%%/updater" /E /Y /D

:IGNORE_NPP_EDITOR_PATCHES

:REPEAT_INSTALL_NPP_PYTHONSCRIPT_PLUGIN_ASK
set "CONTINUE_INSTALL_ASK="
echo.Do you want to install Notepad++ PythonScript plugin: [y]es/[s]kip/[c]ancel?
set /P "CONTINUE_INSTALL_ASK="

if "%CONTINUE_INSTALL_ASK%" == "y" goto REPEAT_INSTALL_NPP_PYTHONSCRIPT_PLUGIN_ASK_END
if /i "%CONTINUE_INSTALL_ASK%" == "s" (
  echo.%?~nx0%: warning: Notepad++ installation is skipped.
  echo.
  goto SKIP_NPP_PYTHONSCRIPT_PLUGIN_INSTALL
) >&2
if /i "%CONTINUE_INSTALL_ASK%" == "c" goto CANCEL_INSTALL

goto REPEAT_INSTALL_NPP_PYTHONSCRIPT_PLUGIN_ASK

:REPEAT_INSTALL_NPP_PYTHONSCRIPT_PLUGIN_ASK_END

echo.Installing Notepad++ PythonScript plugin...
echo.

rem CAUTION: We must avoid forwarding slashes and trailing back slash here altogether
for /F "eol=	 tokens=* delims=" %%i in ("%DETECTED_NPP_EDITOR%\.") do for /F "eol=	 tokens=* delims=" %%j in ("%%~dpi\.") do set "DETECTED_NPP_INSTALL_DIR=%%~fj"

if %WINDOWS_MAJOR_VER% GTR 5 (
  if %DETECTED_NPP_EDITOR_X64_VER% NEQ 0 (
    rem CAUTION: We must avoid forwarding slashes and trailing back slash here altogether
    for /F "eol=	 tokens=* delims=" %%i in ("%NOTEPAD_PLUS_PLUS_PYTHON_SCRIPT_PLUGIN_SETUP_WIN7_X64%\.") do set "NOTEPAD_PLUS_PLUS_PYTHON_SCRIPT_PLUGIN_SETUP_WIN7_X64=%%~fi"

    rem CAUTION:
    rem   The plugin installer is broken, we must always point the Notepad++ installation location!
    rem
    call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" start /B /WAIT "" "%%SystemRoot%%\System32\msiexec.exe" /i "%%NOTEPAD_PLUS_PLUS_PYTHON_SCRIPT_PLUGIN_SETUP_WIN7_X64%%" INSTALLDIR="%%DETECTED_NPP_INSTALL_DIR%%"
  ) else (
    rem CAUTION: We must avoid forwarding slashes and trailing back slash here altogether
    for /F "eol=	 tokens=* delims=" %%i in ("%NOTEPAD_PLUS_PLUS_PYTHON_SCRIPT_PLUGIN_SETUP_WIN7_X86%\.") do set "NOTEPAD_PLUS_PLUS_PYTHON_SCRIPT_PLUGIN_SETUP_WIN7_X86=%%~fi"

    rem CAUTION:
    rem   The plugin installer is broken, we must always point the Notepad++ installation location!
    rem
    call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" start /B /WAIT "" "%%SystemRoot%%\System32\msiexec.exe" /i "%%NOTEPAD_PLUS_PLUS_PYTHON_SCRIPT_PLUGIN_SETUP_WIN7_X86%%" INSTALLDIR="%%DETECTED_NPP_INSTALL_DIR%%"
  )
) else (
  rem CAUTION: We must avoid forwarding slashes and trailing back slash here altogether
  for /F "eol=	 tokens=* delims=" %%i in ("%NOTEPAD_PLUS_PLUS_PYTHON_SCRIPT_PLUGIN_SETUP_WINXP_X86%\.") do set "NOTEPAD_PLUS_PLUS_PYTHON_SCRIPT_PLUGIN_SETUP_WINXP_X86=%%~fi"

  rem CAUTION:
  rem   The plugin installer is broken, we must always point the Notepad++ installation location!
  rem
  call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" start /B /WAIT "" "%%SystemRoot%%\System32\msiexec.exe" /i "%%NOTEPAD_PLUS_PLUS_PYTHON_SCRIPT_PLUGIN_SETUP_WINXP_X86%%" INSTALLDIR="%%DETECTED_NPP_INSTALL_DIR%%"
)

:SKIP_NPP_PYTHONSCRIPT_PLUGIN_INSTALL

call "%%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_EXTERNALS_ROOT%%/tacklebar/._install/_install.detect_3dparty.notepadpp.pythonscript_plugin.bat"

call "%%?~dp0%%.%%?~n0%%/%%?~n0%%.postinstall.notepadpp.pythonscript_plugin.bat" || goto CANCEL_INSTALL

:SKIP_NPP_EDITOR_POSTINSTALL

set "INSTALL_WINMERGE_X64_VER=0"

if not %WINDOWS_MAJOR_VER% GTR 5 goto REPEAT_INSTALL_WINMERGE_SETUP_X32_ASK
if %WINDOWS_X64_VER% EQU 0 goto REPEAT_INSTALL_WINMERGE_SETUP_X32_ASK

:REPEAT_INSTALL_WINMERGE_SETUP_X64_ASK
set "CONTINUE_INSTALL_ASK="
echo.Do you want to install 32-bit or 64-bit version of WinMerge: 3[2]-bit/6[4]-bit/[s]kip/[c]ancel?
set /P "CONTINUE_INSTALL_ASK="

if "%CONTINUE_INSTALL_ASK%" == "2" goto REPEAT_INSTALL_WINMERGE_SETUP_X32_ASK_END
if "%CONTINUE_INSTALL_ASK%" == "4" set "INSTALL_WINMERGE_X64_VER=1" & goto REPEAT_INSTALL_WINMERGE_SETUP_X32_ASK_END
if /i "%CONTINUE_INSTALL_ASK%" == "s" (
  echo.%?~nx0%: warning: WinMerge installation is skipped.
  echo.
  goto SKIP_WINMERGE_INSTALL
) >&2
if /i "%CONTINUE_INSTALL_ASK%" == "c" goto CANCEL_INSTALL

goto REPEAT_INSTALL_WINMERGE_SETUP_X64_ASK

:REPEAT_INSTALL_WINMERGE_SETUP_X32_ASK
set "CONTINUE_INSTALL_ASK="
echo.Do you want to install 32-bit version of WinMerge: [y]es/[s]kip/[c]ancel?
set /P "CONTINUE_INSTALL_ASK="

if "%CONTINUE_INSTALL_ASK%" == "y" goto REPEAT_INSTALL_WINMERGE_SETUP_X32_ASK_END
if /i "%CONTINUE_INSTALL_ASK%" == "s" (
  echo.%?~nx0%: warning: WinMerge installation is skipped.
  echo.
  goto SKIP_WINMERGE_INSTALL
) >&2
if /i "%CONTINUE_INSTALL_ASK%" == "c" goto CANCEL_INSTALL

goto REPEAT_INSTALL_WINMERGE_SETUP_X32_ASK

:REPEAT_INSTALL_WINMERGE_SETUP_X32_ASK_END

echo.Installing WinMerge...
echo.

if %WINDOWS_MAJOR_VER% GTR 5 (
  if %INSTALL_WINMERGE_X64_VER% NEQ 0 (
    call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" start /B /WAIT "" "%%WINMERGE_SETUP_WIN7_X64%%"
  ) else (
    call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" start /B /WAIT "" "%%WINMERGE_SETUP_WIN7_X86%%"
  )
) else (
  if %INSTALL_WINMERGE_X64_VER% NEQ 0 (
    call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" start /B /WAIT "" "%%WINMERGE_SETUP_WINXP_X64%%"
  ) else (
    call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" start /B /WAIT "" "%%WINMERGE_SETUP_WINXP_X86%%"
  )
)

:SKIP_WINMERGE_INSTALL

call "%%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_EXTERNALS_ROOT%%/tacklebar/._install/_install.detect_3dparty.winmerge.bat"

echo.%?~nx0%: info: installation is complete.
echo.

exit /b 0

:CANCEL_INSTALL
(
  echo.%?~nx0%: info: installation is canceled.
  echo.
  exit /b 127
) >&2
