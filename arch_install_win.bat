@echo off
net session >nul 2>&1
if %errorlevel% neq 0 (
	echo Requesting Admin..
powershell  -Command "start-process '%~f0' -Verb runAs"
	exit /b
)
pushd %~dp0
:StartScript
powershell -WindowStyle Maximize -ExecutionPolicy Bypass -File .\resources\arch_install.ps1
:EXIT
pause