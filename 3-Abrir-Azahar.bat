@echo off
chcp 65001 >nul
cd /d "%~dp0tools\azahar"
if not exist "azahar.exe" (
    echo [ERROR] Azahar no esta instalado.
    echo Ejecuta primero: 1-Instalar-o-Reparar-Todo.bat
    pause
    exit /b 1
)
if not exist "user" mkdir "user"
start "" "%~dp0tools\azahar\azahar.exe"
