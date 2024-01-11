@echo off

setlocal

call "%%~dp0__init__.bat" || exit /b

call "%%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_ROOT%%/__init__/declare_builtins.bat" %%0 %%* || exit /b

rem Windows 7+

if not %WINDOWS_MAJOR_VER% GTR 5 goto SKIP_NPP_PYTHONSCRIPT_PLUGIN_PYTHON_UPDATE_WIN7

echo.Updating Notepad++ PythonScript plugin Python installation...
echo.

if not exist "%DETECTED_NPP_PYTHONSCRIPT_PLUGIN_ROOT%\*" (
  echo.%?~nx0%: warning: Python update is skipped, Python root directory is not found: "%DETECTED_NPP_PYTHONSCRIPT_PLUGIN_ROOT%".
  goto SKIP_NPP_PYTHONSCRIPT_PLUGIN_PYTHON_UPDATE
) >&2

set "PYTHON_EXTRACT_TEMP_DIR=%SCRIPT_TEMP_CURRENT_DIR%/deploy/python"

call :MAKE_DIR "%%PYTHON_EXTRACT_TEMP_DIR%%"

if %DETECTED_NPP_PYTHONSCRIPT_PLUGIN_PYTHON_DLL_X64_VER% NEQ 0 (
  set "PYTHON_PACKAGE_DIR_NAME=core-python-3.12.1-x64"
) else set "PYTHON_PACKAGE_DIR_NAME=core-python-3.12.1-x86"

call :CMD "%%CONTOOLS_BUILD_TOOLS_ROOT%%/extract_files_from_archive.bat" ^
  "%%PYTHON_EXTRACT_TEMP_DIR%%" "%%PYTHON_PACKAGE_DIR_NAME%%" "%%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_EXTERNALS_ROOT%%/apps/win7/deploy/python/3.x/core/dlls/core/%%PYTHON_PACKAGE_DIR_NAME%%.7z" -y && (
  echo.
  call :XMOVE_FILE "%%PYTHON_EXTRACT_TEMP_DIR%%\%%PYTHON_PACKAGE_DIR_NAME%%\" "*.*" "%%DETECTED_NPP_PYTHONSCRIPT_PLUGIN_ROOT%%\" /E /Y || (
    echo.%?~nx0%: error: could not move Python `core` extracted directory: "%PYTHON_EXTRACT_TEMP_DIR%\%PYTHON_PACKAGE_DIR_NAME%\" -^> "%DETECTED_NPP_PYTHONSCRIPT_PLUGIN_ROOT%\"
    echo.
    exit /b 255
  ) >&2
)

:SKIP_NPP_PYTHONSCRIPT_PLUGIN_PYTHON_UPDATE

:SKIP_NPP_PYTHONSCRIPT_PLUGIN_PYTHON_UPDATE_WIN7

if not %WINDOWS_MAJOR_VER% GTR 5 goto SKIP_NPP_PYTHONSCRIPT_PLUGIN_UPDATE_WIN7

echo.Installing Notepad++ PythonScript plugin Python modules...
echo.

if not exist "%DETECTED_NPP_PYTHONSCRIPT_PLUGIN_ROOT%\lib\*" (
  echo.%?~nx0%: warning: Python lib install is skipped, Python Lib directory is not found: "%DETECTED_NPP_PYTHONSCRIPT_PLUGIN_ROOT%\lib".
  echo.
  goto SKIP_NPP_PYTHONSCRIPT_PLUGIN_PYTHON_LIBS_INSTALL
) >&2

if exist "%DETECTED_NPP_PYTHONSCRIPT_PLUGIN_ROOT%\lib\site-packages\psutil\*" (
  echo.%?~nx0%: info: Python `psutil` lib install is skipped, lib directory is found: "%DETECTED_NPP_PYTHONSCRIPT_PLUGIN_ROOT%\lib\site-packages\psutil".
  echo.
  goto SKIP_NPP_PYTHONSCRIPT_PLUGIN_PYTHON_LIB_PSUTIL_EXISTED
) >&2

set "PSUTIL_EXTRACT_TEMP_DIR=%SCRIPT_TEMP_CURRENT_DIR%/deploy/psutil"

call :MAKE_DIR "%%PSUTIL_EXTRACT_TEMP_DIR%%"

if %DETECTED_NPP_PYTHONSCRIPT_PLUGIN_PYTHON_DLL_X64_VER% NEQ 0 (
  set "PSUTIL_PACKAGE_DIR_NAME=psutil-5.9.7-x64"
) else set "PSUTIL_PACKAGE_DIR_NAME=psutil-5.9.7-x86"

call :CMD "%%CONTOOLS_BUILD_TOOLS_ROOT%%/extract_files_from_archive.bat" ^
  "%%PSUTIL_EXTRACT_TEMP_DIR%%" "%%PSUTIL_PACKAGE_DIR_NAME%%/Lib/site-packages" "%%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_EXTERNALS_ROOT%%/apps/win7/deploy/python/3.x/modules/psutil/%%PSUTIL_PACKAGE_DIR_NAME%%.7z" -y && (
  echo.
  call :XMOVE_FILE "%%PSUTIL_EXTRACT_TEMP_DIR%%\%%PSUTIL_PACKAGE_DIR_NAME%%\Lib\site-packages\" "*.*" "%%DETECTED_NPP_PYTHONSCRIPT_PLUGIN_ROOT%%\lib\site-packages\" /E /Y || (
    echo.%?~nx0%: error: could not move Python `psutil` extracted directory: "%PSUTIL_EXTRACT_TEMP_DIR%\%PSUTIL_PACKAGE_DIR_NAME%\Lib\site-packages\" -^> "%DETECTED_NPP_PYTHONSCRIPT_PLUGIN_ROOT%\lib\site-packages\"
    echo.
    exit /b 255
  ) >&2
)

:SKIP_NPP_PYTHONSCRIPT_PLUGIN_PYTHON_LIB_PSUTIL_EXISTED
:SKIP_NPP_PYTHONSCRIPT_PLUGIN_PYTHON_LIBS_INSTALL

:SKIP_NPP_PYTHONSCRIPT_PLUGIN_UPDATE_WIN7


rem Windows XP+

if %WINDOWS_MAJOR_VER% GTR 5 goto SKIP_NPP_PYTHONSCRIPT_PLUGIN_PYTHON_UPDATE_WINXP

rem Fix for the Windows XP x86/x64 or the Windows 7+ x86
rem if %WINDOWS_MAJOR_VER% GTR 5 if %WINDOWS_X64_VER% NEQ 0 goto SKIP_NPP_PYTHONSCRIPT_PLUGIN_PYTHON_UPDATE_WIN7

echo.Updating Notepad++ PythonScript plugin Python installation...
echo.

call :XCOPY_FILE "%%DETECTED_NPP_INSTALL_DIR%%/plugins/PythonScript" python27.dll "%%DETECTED_NPP_INSTALL_DIR%%" /Y /D /H

:SKIP_NPP_PYTHONSCRIPT_PLUGIN_PYTHON_UPDATE_WINXP

if %WINDOWS_MAJOR_VER% GTR 5 goto SKIP_NPP_PYTHONSCRIPT_PLUGIN_UPDATE_WINXP

echo.Installing Notepad++ PythonScript plugin Python dlls...
echo.

rem if not exist "%DETECTED_NPP_PYTHONSCRIPT_PLUGIN_ROOT%\dlls\*" (
rem   echo.%?~nx0%: warning: Python dlls install is skipped, Python dlls directory is not found: "%DETECTED_NPP_PYTHONSCRIPT_PLUGIN_ROOT%\dlls".
rem   echo.
rem   goto SKIP_NPP_PYTHONSCRIPT_PLUGIN_PYTHON_DLLS_INSTALL
rem ) >&2

rem CAUTION:
rem   PythonScript Python reads the registry for PythonPath from `HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Python\PythonCore\2.7\PythonPath`,
rem   does find and load the `_ctypes.pyd` from there.
rem   To workaround an external installation, we must to copy the Dll file into the Lib directory.
rem
if exist "%DETECTED_NPP_PYTHONSCRIPT_PLUGIN_ROOT%\lib\_ctypes.pyd" (
  echo.%?~nx0%: info: Python `_ctypes` dll install is skipped, dll file is found: "%DETECTED_NPP_PYTHONSCRIPT_PLUGIN_ROOT%\lib\_ctypes.pyd".
  echo.
  goto SKIP_NPP_PYTHONSCRIPT_PLUGIN_PYTHON_DLL_CTYPES_EXISTED
) >&2

set "CTYPES_EXTRACT_TEMP_DIR=%SCRIPT_TEMP_CURRENT_DIR%/deploy/ctypes"

call :MAKE_DIR "%%CTYPES_EXTRACT_TEMP_DIR%%"

rem if not exist "\\?\%DETECTED_NPP_PYTHONSCRIPT_PLUGIN_ROOT%\dlls\*" call :MAKE_DIR "%DETECTED_NPP_PYTHONSCRIPT_PLUGIN_ROOT%\dlls"

call :CMD "%%CONTOOLS_BUILD_TOOLS_ROOT%%/extract_files_from_archive.bat" ^
  "%%CTYPES_EXTRACT_TEMP_DIR%%" "ctypes-python-2.7.18/DLLs/_ctypes.pyd" "%%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_EXTERNALS_ROOT%%/apps/winxp/deploy/python/2.x/core/dlls/ctypes/ctypes-python-2.7.18.7z" -y && (
  echo.
  call :XMOVE_FILE "%%CTYPES_EXTRACT_TEMP_DIR%%\ctypes-python-2.7.18\DLLs\" "_ctypes.pyd" "%%DETECTED_NPP_PYTHONSCRIPT_PLUGIN_ROOT%%\lib\" /E /Y || (
    echo.%?~nx0%: error: could not move Python `ctypes` extracted file: "%CTYPES_EXTRACT_TEMP_DIR%\ctypes-python-2.7.18\DLLs\_ctypes.pyd" -^> "%DETECTED_NPP_PYTHONSCRIPT_PLUGIN_ROOT%\lib\_ctypes.pyd"
    echo.
    exit /b 255
  ) >&2
)

:SKIP_NPP_PYTHONSCRIPT_PLUGIN_PYTHON_DLL_CTYPES_EXISTED
:SKIP_NPP_PYTHONSCRIPT_PLUGIN_PYTHON_DLLS_INSTALL

echo.Installing Notepad++ PythonScript plugin Python modules...
echo.

if not exist "%DETECTED_NPP_PYTHONSCRIPT_PLUGIN_ROOT%\lib\*" (
  echo.%?~nx0%: warning: Python lib install is skipped, Python Lib directory is not found: "%DETECTED_NPP_PYTHONSCRIPT_PLUGIN_ROOT%\lib".
  echo.
  goto SKIP_NPP_PYTHONSCRIPT_PLUGIN_PYTHON_LIBS_INSTALL
) >&2

if exist "%DETECTED_NPP_PYTHONSCRIPT_PLUGIN_ROOT%\lib\site-packages\psutil\*" (
  echo.%?~nx0%: info: Python `psutil` lib install is skipped, lib directory is found: "%DETECTED_NPP_PYTHONSCRIPT_PLUGIN_ROOT%\lib\site-packages\psutil".
  echo.
  goto SKIP_NPP_PYTHONSCRIPT_PLUGIN_PYTHON_LIB_PSUTIL_EXISTED
) >&2

set "PSUTIL_EXTRACT_TEMP_DIR=%SCRIPT_TEMP_CURRENT_DIR%/deploy/psutil"

call :MAKE_DIR "%%PSUTIL_EXTRACT_TEMP_DIR%%"

set "PSUTIL_PACKAGE_DIR_NAME=psutil-5.9.5"

call :CMD "%%CONTOOLS_BUILD_TOOLS_ROOT%%/extract_files_from_archive.bat" ^
  "%%PSUTIL_EXTRACT_TEMP_DIR%%" "%%PSUTIL_PACKAGE_DIR_NAME%%/Lib/site-packages" "%%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_EXTERNALS_ROOT%%/apps/winxp/deploy/python/2.x/modules/psutil/%%PSUTIL_PACKAGE_DIR_NAME%%.7z" -y && (
  echo.
  call :XMOVE_FILE "%%PSUTIL_EXTRACT_TEMP_DIR%%\%%PSUTIL_PACKAGE_DIR_NAME%%\Lib\site-packages\" "*.*" "%%DETECTED_NPP_PYTHONSCRIPT_PLUGIN_ROOT%%\lib\site-packages\" /E /Y || (
    echo.%?~nx0%: error: could not move Python `psutil` extracted directory: "%PSUTIL_EXTRACT_TEMP_DIR%\%PSUTIL_PACKAGE_DIR_NAME%\Lib\site-packages\" -^> "%DETECTED_NPP_PYTHONSCRIPT_PLUGIN_ROOT%\lib\site-packages\"
    echo.
    exit /b 255
  ) >&2
)

:SKIP_NPP_PYTHONSCRIPT_PLUGIN_PYTHON_LIB_PSUTIL_EXISTED
:SKIP_NPP_PYTHONSCRIPT_PLUGIN_PYTHON_LIBS_INSTALL

:SKIP_NPP_PYTHONSCRIPT_PLUGIN_UPDATE_WINXP

exit /b 0

:XCOPY_FILE
if not exist "\\?\%~f3\*" (
  echo.^>mkdir "%~3"
  call :MAKE_DIR "%%~3" || exit /b
)
call "%%CONTOOLS_ROOT%%/std/xcopy_file.bat"%%XCOPY_FILE_CMD_BARE_FLAGS%% %%*
echo.
exit /b

:XCOPY_DIR
if not exist "\\?\%~f2\*" (
  call :MAKE_DIR "%%~2" || exit /b
)
call "%%CONTOOLS_ROOT%%/std/xcopy_dir.bat"%%XCOPY_DIR_CMD_BARE_FLAGS%% %%*
echo.
exit /b

:MAKE_DIR
for /F "eol= tokens=* delims=" %%i in ("%~1\.") do set "FILE_PATH=%%~fi"

echo.^>mkdir "%FILE_PATH%"
mkdir "%FILE_PATH%" 2>nul || if exist "\\?\%SystemRoot%\System32\robocopy.exe" ( "%SystemRoot%\System32\robocopy.exe" /CREATE "%EMPTY_DIR_TMP%" "%FILE_PATH%" >nul ) else type 2>nul || (
  echo.%?~nx0%: error: could not create a target file directory: "%FILE_PATH%".
  echo.
  exit /b 255
) >&2
echo.
exit /b

:XMOVE_FILE
call "%%CONTOOLS_ROOT%%/std/xmove_file.bat"%%XMOVE_FILE_CMD_BARE_FLAGS%% %%*
echo.
exit /b

:XMOVE_DIR
call "%%CONTOOLS_ROOT%%/std/xmove_dir.bat"%%XMOVE_DIR_CMD_BARE_FLAGS%% %%*
echo.
exit /b

:CMD
echo.^>%*
(
  %*
)
exit /b
