@echo off
chcp 65001 >nul
cd /d "%~dp0tools\upr-fvx"
if not exist "UPR-FVX.jar" (
    echo [ERROR] Universal Pokemon Randomizer FVX no esta instalado.
    echo Ejecuta primero: 1-Instalar-o-Reparar-Todo.bat
    pause
    exit /b 1
)
call launcher.bat
