@echo off
:: Verifica se está rodando como admin
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Abrindo PowerShell como Administrador...
    powershell -Command "Start-Process PowerShell -ArgumentList '-NoExit -ExecutionPolicy Bypass -File \"%~dp0script.ps1\"' -Verb RunAs"
    exit /b
)

:: Se já for admin
powershell -NoExit -ExecutionPolicy Bypass -File "%~dp0script.ps1"