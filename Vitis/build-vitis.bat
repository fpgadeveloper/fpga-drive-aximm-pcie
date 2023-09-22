@ECHO OFF

setlocal ENABLEDELAYEDEXPANSION
SET vitis=C:\Xilinx\Vitis\2022.1\bin\xsct.bat
cmd /c "%vitis% tcl\build-vitis.tcl"
pause
