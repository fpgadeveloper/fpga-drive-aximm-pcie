@ECHO OFF

setlocal ENABLEDELAYEDEXPANSION
SET sdk=C:\Xilinx\SDK\2018.2\bin\xsdk.bat
cmd /c "%sdk% -batch -source build-sdk.tcl"
pause
