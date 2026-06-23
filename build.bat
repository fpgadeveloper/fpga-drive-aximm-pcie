@echo off
rem
rem Copyright (C) 2025-2026, Opsero Electronic Design Inc.  All rights reserved.
rem
rem SPDX-License-Identifier: MIT
rem
rem build.bat -- run build.py from plain Command Prompt or PowerShell, no git
rem bash required. Finds a working Python 3 in this order: the py launcher,
rem python on PATH (the Microsoft Store stub is rejected because it cannot
rem run code), then the interpreter bundled with the AMD tools.
rem
rem Usage mirrors build.sh exactly:
rem   build.bat list
rem   build.bat xsa --target <target>
rem   build.bat standalone --target <target>
rem   build.bat all --target all
setlocal
set "DIR=%~dp0"
set "BUILD_SHIM=build.bat"

py -3 -c "import sys" >nul 2>&1
if not errorlevel 1 ( py -3 "%DIR%build.py" %* & goto :done )

python -c "import sys" >nul 2>&1
if not errorlevel 1 ( python "%DIR%build.py" %* & goto :done )

rem AMD-bundled Python: <root>\<version>\tps\win64\python-*\python.exe
for %%R in (C:\AMDDesignTools C:\Xilinx C:\AMD D:\AMDDesignTools D:\Xilinx E:\AMDDesignTools E:\Xilinx) do (
  if exist "%%R" (
    for /d %%V in ("%%R\*") do (
      for /d %%P in ("%%V\tps\win64\python-*") do (
        if exist "%%P\python.exe" ( "%%P\python.exe" "%DIR%build.py" %* & goto :done )
      )
    )
  )
)

echo ERROR: no Python 3 found (tried 'py -3', 'python', and the AMD-bundled tps python). 1>&2
echo Install Python 3, or install the AMD tools which include one. 1>&2
exit /b 1

:done
exit /b %errorlevel%
