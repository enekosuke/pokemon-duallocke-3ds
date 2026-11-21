@echo off
chcp 65001 >nul
cd /d "%~dp0"

set "AZAHAR=%~dp0tools\azahar\azahar.exe"
if not exist "%AZAHAR%" (
    echo [ERROR] Azahar no esta instalado. Ejecuta primero 1-Instalar-o-Reparar-Todo.bat
    pause
    exit /b 1
)

set "ROM_FILE="
for %%F in ("%~dp0roms\*.cci" "%~dp0roms\*.3ds" "%~dp0roms\*.cxi") do (
    if not defined ROM_FILE set "ROM_FILE=%%~fF"
)

if not defined ROM_FILE goto :no_rom
goto :has_rom

:no_rom
echo [AVISO] No se encontro ninguna ROM ^(.cci/.3ds/.cxi^) en la carpeta roms\.
echo Abriendo Azahar normalmente...
cd /d "%~dp0tools\azahar"
start "" "%AZAHAR%"
exit /b 0

:has_rom
if not exist "%~dp0tools\azahar\user\load\mods\0004000000055E00\romfs" (
    echo [AVISO] No se detecto mod LayeredFS para Pokemon Y.
    echo Si quieres aplicar la randomizacion automatica, ejecuta:
    echo   powershell -ExecutionPolicy Bypass -File scripts\randomize-auto.ps1
    echo.
    timeout /t 4 >nul
)

echo Iniciando Pokemon DualLocke 3DS...
cd /d "%~dp0tools\azahar"
start "" "%AZAHAR%" "%ROM_FILE%"
