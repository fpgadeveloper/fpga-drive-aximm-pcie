@ECHO OFF

setlocal ENABLEDELAYEDEXPANSION
SET vitis=C:\Xilinx\Vitis\2024.1\bin\xsct.bat
cmd /c "%vitis% tcl\build-vitis.tcl"
pause
