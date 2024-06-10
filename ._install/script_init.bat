@echo off

call "%%~dp0__init__.bat" || exit /b

call "%%TACKLEBAR_EXTERNAL_TOOLS_PROJECT_EXTERNALS_ROOT%%/tacklebar/._install/script_init.bat" %%* || exit /b

exit /b 0
