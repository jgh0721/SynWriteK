@echo off
pushd "%~dp0"
cls
echo.
echo.
echo.
echo This will update SynWrite installation in the "%InstDir%" folder.
echo.
pause
del SynWrite.rar
wget http://uvviewsoft.com/bb/SynWrite.rar
unrar x -y SynWrite.rar *.* .
del SynWrite.rar
