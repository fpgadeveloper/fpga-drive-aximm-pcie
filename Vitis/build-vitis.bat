@ECHO OFF

setlocal ENABLEDELAYEDEXPANSION
SET vitis=C:\Xilinx\Vitis\2023.2\bin\xsct.bat
cmd /c "%vitis% tcl\build-vitis.tcl"
pause
