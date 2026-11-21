@echo off
chcp 65001 >nul
cd /d "%~dp0tools\pkhex"
if not exist "PKHeX.exe" (
    echo [ERROR] PKHeX no esta instalado.
    echo Ejecuta primero: 1-Instalar-o-Reparar-Todo.bat
    pause
    exit /b 1
)
start "" "%~dp0tools\pkhex\PKHeX.exe"
