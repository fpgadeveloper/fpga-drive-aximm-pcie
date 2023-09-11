@ECHO OFF

setlocal ENABLEDELAYEDEXPANSION
SET vitis=C:\Xilinx\Vitis\2022.1\bin\xsct.bat
cmd /c "%vitis% scripts\build-vitis.tcl"
pause
