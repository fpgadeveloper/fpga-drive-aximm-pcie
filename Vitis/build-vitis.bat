@ECHO OFF

setlocal ENABLEDELAYEDEXPANSION
SET vitis=C:\Xilinx\Vitis\2019.2\bin\xsct.bat
cmd /c "%vitis% build-vitis.tcl"
pause
