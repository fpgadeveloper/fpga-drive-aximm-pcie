SET vivado=C:\Xilinx\Vivado\2022.1\bin\vivado.bat
@ECHO OFF
if exist %vivado% (
  %vivado% -mode batch -source scripts\build.tcl -notrace -tclargs kc705_lpc
) else (
  ECHO.
  ECHO ###############################
  ECHO ### Failed to locate Vivado ###
  ECHO ###############################
  ECHO.
  ECHO This batch file "%~n0.bat" did not find Vivado installed in:
  ECHO.
  ECHO     %vivado%
  ECHO.
  ECHO Fix the problem by doing one of the following:
  ECHO.
  ECHO  1. If you do not have this version of Vivado installed,
  ECHO     please install it or download the project sources from
  ECHO     a commit of the Git repository that was intended for
  ECHO     your version of Vivado.
  ECHO.
  ECHO  2. If Vivado is installed in a different location on your
  ECHO     PC, please modify the first line of this batch file 
  ECHO     to specify the correct location.
  ECHO.
  pause
)
