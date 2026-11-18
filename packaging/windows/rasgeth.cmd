@echo off
rem rasgeth: Rasgeth's command line (G36.15), with the Node and the server that came with the
rem installer. It finds the Rasgeth this user runs in its data folder (token.txt, address.txt):
rem the folder chosen in the installer, as the registry says (the key HKCU\Software\RedGiant
rem keeps its name since before 3.9.0), unless REDGIANT_DATA_DIR is set.
setlocal
set "RG_APP=%~dp0.."
if not defined REDGIANT_DATA_DIR for /f "tokens=2,*" %%a in ('reg query "HKCU\Software\RedGiant" /v DataDir 2^>nul ^| findstr /i "REG_"') do set "REDGIANT_DATA_DIR=%%b"
if not defined REDGIANT_DATA_DIR if exist "%LOCALAPPDATA%\RedGiant\data\" if not exist "%LOCALAPPDATA%\Rasgeth\data\" set "REDGIANT_DATA_DIR=%LOCALAPPDATA%\RedGiant\data"
if not defined REDGIANT_DATA_DIR set "REDGIANT_DATA_DIR=%LOCALAPPDATA%\Rasgeth\data"
"%RG_APP%\node\node.exe" "%RG_APP%\server\cli\main.js" %*
exit /b %ERRORLEVEL%
