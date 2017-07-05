@ECHO OFF

setlocal ENABLEDELAYEDEXPANSION
SET sdk=C:\Xilinx\SDK\2017.2\bin\xsdk.bat
cmd /c "%sdk% -batch -source build-sdk.tcl"
pause
