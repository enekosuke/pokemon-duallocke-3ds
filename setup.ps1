# ==============================================================================
#  Pokemon DualLocke 3DS - Instalador Automatico (Windows)
#  Instala y configura de forma portatil:
#    - Azahar 2126.2 (Emulador 3DS portatil preconfigurado en espanol y HD 2x)
#    - Universal Pokemon Randomizer FVX v1.6.3 (con Java incluido)
#    - PKHeX (Editor de partidas para Caramelos Raros y exportar a Showdown)
#    - Verificacion de .NET Desktop Runtime, Radmin VPN y driver de GPU
#    - Si ya hay ROM en roms\, aplica automaticamente el Randomlocke (seed fija)
# ==============================================================================

param(
    [switch]$InstallRadminVPN,
    [switch]$ForceRedownload,
    [switch]$SkipAutoRandomize
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$BaseDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ToolsDir = Join-Path $BaseDir "tools"
$AzaharDir = Join-Path $ToolsDir "azahar"
$UprDir = Join-Path $ToolsDir "upr-fvx"
$PkhexDir = Join-Path $ToolsDir "pkhex"
$RomsDir = Join-Path $BaseDir "roms"

$AzaharVersion = "2126.2"
$AzaharUrl = "https://github.com/azahar-emu/azahar/releases/download/$AzaharVersion/azahar-windows-msvc-$AzaharVersion.zip"
$UprVersion = "vFVX1.6.3"
$UprUrl = "https://github.com/upr-fvx/universal-pokemon-randomizer-fvx/releases/download/$UprVersion/UPR_FVX-v1_6_3-Windows.zip"

function Write-Step($msg) {
    Write-Host ""
    Write-Host ">>> $msg" -ForegroundColor Cyan
}
function Write-Ok($msg) { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "  [AVISO] $msg" -ForegroundColor Yellow }

function Set-IniValue($lines, $key, $value) {
    $escaped = [regex]::Escape($key)
    $replaced = $false
    $out = foreach ($line in $lines) {
        if ($line -match "^$escaped=") {
            $replaced = $true
            "$key=$value"
        } else {
            $line
        }
    }
    if (-not $replaced) {
        $out += "$key=$value"
    }
    return ,$out
}

Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "   POKEMON DUALLOCKE 3DS - INSTALADOR AUTOMATICO" -ForegroundColor Magenta
Write-Host "   Carpeta: $BaseDir" -ForegroundColor Magenta
Write-Host "============================================================" -ForegroundColor Magenta

# 1. Crear carpetas necesarias
Write-Step "1/7 Creando estructura de carpetas..."
@(
    $ToolsDir,
    $RomsDir,
    (Join-Path $BaseDir "mods-para-compartir"),
    (Join-Path $BaseDir "saves-backup")
) | ForEach-Object {
    New-Item -ItemType Directory -Force -Path $_ | Out-Null
}
Write-Ok "Estructura de carpetas lista."

# 2. Comprobar tarjeta grafica y fecha del driver
Write-Step "2/7 Comprobando tarjeta grafica y drivers..."
try {
    $gpus = Get-CimInstance Win32_VideoController
    foreach ($gpu in $gpus) {
        $drvDateStr = "Desconocida"
        $isOld = $false
        if ($gpu.DriverDate) {
            $drvDate = [datetime]$gpu.DriverDate
            $drvDateStr = $drvDate.ToString("yyyy-MM-dd")
            if ($drvDate.Year -lt 2023) { $isOld = $true }
        }
        Write-Host "  GPU detectada: $($gpu.Name) | Driver: $($gpu.DriverVersion) ($drvDateStr)"
        if ($isOld -and ($gpu.Name -match "NVIDIA|AMD|Radeon|GeForce")) {
            Write-Warn "ATENCION: El driver de '$($gpu.Name)' es muy antiguo ($drvDateStr)."
            Write-Warn "Azahar (3DS) necesita drivers recientes para funcionar sin fallos graficos."
            if ($gpu.Name -match "NVIDIA|GeForce") {
                Write-Warn "Descarga el driver mas reciente en: https://www.nvidia.com/es-es/drivers/"
            }
        }
    }
} catch {
    Write-Warn "No se pudo consultar la informacion de GPU automaticamente."
}

# 3. Instalar Azahar (Emulador 3DS portatil)
Write-Step "3/7 Instalando Azahar $AzaharVersion (Emulador de 3DS)..."
$azaharExe = Join-Path $AzaharDir "azahar.exe"
if ($ForceRedownload -and (Test-Path $AzaharDir)) {
    $userBackup = Join-Path $ToolsDir "_azahar_user_backup"
    if (Test-Path (Join-Path $AzaharDir "user")) {
        Move-Item (Join-Path $AzaharDir "user") $userBackup -Force
    }
    Remove-Item $AzaharDir -Recurse -Force
}

if (-not (Test-Path $azaharExe)) {
    $azaharZip = Join-Path $ToolsDir "azahar.zip"
    $azaharTmp = Join-Path $ToolsDir "azahar_tmp"
    Write-Host "  Descargando Azahar $AzaharVersion..."
    Invoke-WebRequest -Uri $AzaharUrl -OutFile $azaharZip
    if (Test-Path $azaharTmp) { Remove-Item $azaharTmp -Recurse -Force }
    Expand-Archive -Path $azaharZip -DestinationPath $azaharTmp -Force
    $inner = Get-ChildItem $azaharTmp -Directory | Select-Object -First 1
    if ($inner -and (Test-Path (Join-Path $inner.FullName "azahar.exe"))) {
        Move-Item $inner.FullName $AzaharDir -Force
        Remove-Item $azaharTmp -Recurse -Force
    } else {
        Move-Item $azaharTmp $AzaharDir -Force
    }
    Remove-Item $azaharZip -Force

    $userBackup = Join-Path $ToolsDir "_azahar_user_backup"
    if (Test-Path $userBackup) {
        Move-Item $userBackup (Join-Path $AzaharDir "user") -Force
    }
    Write-Ok "Azahar $AzaharVersion instalado."
} else {
    Write-Ok "Azahar ya estaba instalado."
}

New-Item -ItemType Directory -Force -Path (Join-Path $AzaharDir "user\load\mods") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $AzaharDir "user\config") | Out-Null

# Preconfigurar Azahar (carpeta roms, idioma espanol, HD 2x, sin mensajes de bienvenida)
$qtIni = Join-Path $AzaharDir "user\config\qt-config.ini"
if (-not (Test-Path $qtIni)) {
    $p = Start-Process -FilePath $azaharExe -WorkingDirectory $AzaharDir -PassThru
    Start-Sleep -Seconds 3
    if (-not $p.HasExited) { $p.CloseMainWindow() | Out-Null; Start-Sleep -Seconds 1 }
    if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }
}
if (Test-Path $qtIni) {
    $romsSlash = $RomsDir.Replace("\", "/")
    $lines = Get-Content $qtIni -Encoding UTF8
    $lines = Set-IniValue $lines "Paths\language\default" "false"
    $lines = Set-IniValue $lines "Paths\language" "es"
    $lines = Set-IniValue $lines "firstStart\default" "false"
    $lines = Set-IniValue $lines "firstStart" "false"
    $lines = Set-IniValue $lines "confirmClose\default" "false"
    $lines = Set-IniValue $lines "confirmClose" "false"
    $lines = Set-IniValue $lines "resolution_factor\default" "false"
    $lines = Set-IniValue $lines "resolution_factor" "2"
    if (-not ($lines -match "^Paths\\gamedirs\\3\\path=")) {
        $lines = Set-IniValue $lines "Paths\gamedirs\size" "3"
        $lines = Set-IniValue $lines "Paths\gamedirs\3\path" $romsSlash
        $lines = Set-IniValue $lines "Paths\gamedirs\3\deep_scan\default" "true"
        $lines = Set-IniValue $lines "Paths\gamedirs\3\deep_scan" "false"
        $lines = Set-IniValue $lines "Paths\gamedirs\3\expanded\default" "true"
        $lines = Set-IniValue $lines "Paths\gamedirs\3\expanded" "true"
    } else {
        $lines = Set-IniValue $lines "Paths\gamedirs\3\path" $romsSlash
    }
    Set-Content -Path $qtIni -Value $lines -Encoding UTF8
    Write-Ok "Azahar preconfigurado (carpeta roms\, idioma espanol, resolucion 2x HD)."
}

# 4. Instalar Universal Pokemon Randomizer FVX
Write-Step "4/7 Instalando Universal Pokemon Randomizer FVX ($UprVersion)..."
$uprJar = Join-Path $UprDir "UPR-FVX.jar"
if ($ForceRedownload -and (Test-Path $UprDir)) {
    Remove-Item $UprDir -Recurse -Force
}

if (-not (Test-Path $uprJar)) {
    $uprZip = Join-Path $ToolsDir "upr_fvx.zip"
    Write-Host "  Descargando UPR FVX $UprVersion (incluye Java embebido)..."
    Invoke-WebRequest -Uri $UprUrl -OutFile $uprZip
    Expand-Archive -Path $uprZip -DestinationPath $UprDir -Force
    Remove-Item $uprZip -Force
    Write-Ok "Universal Pokemon Randomizer FVX instalado (con Java propio)."
} else {
    Write-Ok "UPR FVX ya estaba instalado."
}

# 5. Instalar PKHeX + comprobar .NET Desktop Runtime
Write-Step "5/7 Instalando PKHeX (Caramelos Raros y exportador a Showdown)..."
$pkhexExe = Join-Path $PkhexDir "PKHeX.exe"
if ($ForceRedownload -and (Test-Path $PkhexDir)) {
    Remove-Item $PkhexDir -Recurse -Force
}

if (-not (Test-Path $pkhexExe)) {
    try {
        $cookieFile = Join-Path $env:TEMP "pkhex_pp_cookies.txt"
        $pkhexZip = Join-Path $ToolsDir "pkhex.zip"
        Write-Host "  Obteniendo enlace oficial de Project Pokemon..."
        $html = & curl.exe -sL -c $cookieFile --max-time 25 "https://projectpokemon.org/home/files/file/1-pkhex/"
        $m = [regex]::Match($html, 'https://projectpokemon\.org/home/files/file/1-pkhex/\?do=download&amp;csrfKey=([a-f0-9]+)')
        if (-not $m.Success) {
            throw "No se encontro el boton de descarga en Project Pokemon."
        }
        $dlUrl = ($m.Value -replace '&amp;', '&') + "&confirm=1"
        Write-Host "  Descargando PKHeX..."
        & curl.exe -sL -b $cookieFile --max-time 90 $dlUrl -o $pkhexZip
        Remove-Item $cookieFile -ErrorAction SilentlyContinue

        if (-not (Test-Path $pkhexZip) -or ((Get-Item $pkhexZip).Length -lt 1000000)) {
            throw "El archivo descargado de PKHeX parece incompleto."
        }
        New-Item -ItemType Directory -Force -Path $PkhexDir | Out-Null
        Expand-Archive -Path $pkhexZip -DestinationPath $PkhexDir -Force
        Remove-Item $pkhexZip -Force
        Write-Ok "PKHeX instalado."
    } catch {
        Write-Warn "No se pudo descargar PKHeX automaticamente: $_"
        Write-Warn "Puedes bajarlo manualmente de https://projectpokemon.org/home/files/file/1-pkhex/ y meter PKHeX.exe en tools\pkhex\"
    }
} else {
    Write-Ok "PKHeX ya estaba instalado."
}

$hasDotNetDesktop = $false
try {
    $runtimes = & dotnet --list-runtimes 2>$null
    if ($runtimes -match "Microsoft\.WindowsDesktop\.App\s+(8|9|10)\.") {
        $hasDotNetDesktop = $true
    }
} catch {}

if ($hasDotNetDesktop) {
    Write-Ok ".NET Windows Desktop Runtime detectado."
} else {
    Write-Warn "No se detecto .NET Desktop Runtime (necesario para abrir PKHeX)."
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "  Instalando Microsoft .NET Desktop Runtime 10 via winget..."
        & winget install --id Microsoft.DotNet.DesktopRuntime.10 --silent --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -eq 0) {
            Write-Ok ".NET Desktop Runtime 10 instalado."
        } else {
            Write-Warn "Instala manualmente .NET Desktop Runtime desde https://dotnet.microsoft.com/download/dotnet"
        }
    } else {
        Write-Warn "Descarga e instala .NET Desktop Runtime desde https://dotnet.microsoft.com/download/dotnet"
    }
}

# 6. Comprobar / Instalar Radmin VPN
Write-Step "6/7 Comprobando Radmin VPN (para combatir desde casa con Azahar)..."
$radminInstalled = (Test-Path "C:\Program Files (x86)\Radmin VPN\RvRvpnGui.exe") -or (Test-Path "C:\Program Files\Radmin VPN\RvRvpnGui.exe")
if ($radminInstalled) {
    Write-Ok "Radmin VPN ya esta instalado."
} elseif ($InstallRadminVPN) {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "  Instalando Radmin VPN via winget (acepta el aviso de administrador si aparece)..."
        & winget install --id Famatech.RadminVPN --silent --accept-package-agreements --accept-source-agreements
        $radminInstalled = (Test-Path "C:\Program Files (x86)\Radmin VPN\RvRvpnGui.exe") -or (Test-Path "C:\Program Files\Radmin VPN\RvRvpnGui.exe")
        if ($radminInstalled) { Write-Ok "Radmin VPN instalado." } else { Write-Warn "Completa el instalador de Radmin VPN desde https://www.radmin-vpn.com/" }
    } else {
        Write-Warn "winget no disponible. Descarga Radmin VPN gratis en: https://www.radmin-vpn.com/"
    }
} else {
    Write-Warn "Radmin VPN no esta instalado (necesario para salas directas de Azahar desde casa)."
    Write-Host "  Para instalarlo rapido ejecuta: winget install Famatech.RadminVPN"
    Write-Host "  O descargalo de: https://www.radmin-vpn.com/"
}

# 7. Si ya hay una ROM en roms\ y falta el mod en Azahar, aplicar Randomlocke automatico
Write-Step "7/7 Comprobando ROM y parche Randomlocke..."
$hasRom = Get-ChildItem -Path $RomsDir -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -in ".cci", ".3ds", ".cxi" } | Select-Object -First 1
$hasMod = (Get-ChildItem -Path (Join-Path $AzaharDir "user\load\mods") -Directory -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0
if ($hasRom -and (-not $hasMod) -and (-not $SkipAutoRandomize)) {
    Write-Host "  ROM detectada ($($hasRom.Name)) sin mod instalado. Aplicando preset Randomlocke (nueva semilla aleatoria)..."
    & (Join-Path $BaseDir "scripts\randomize-auto.ps1")
} elseif ($hasMod) {
    Write-Ok "Parche LayeredFS Randomlocke ya instalado en Azahar."
} else {
    Write-Warn "Falta la ROM en roms\. Cuando la pongas, ejecuta: scripts\randomize-auto.ps1"
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "   INSTALACION COMPLETADA" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host "Resumen de verificacion:"
Write-Host "  Azahar:     $(if (Test-Path $azaharExe) { 'OK' } else { 'FALTA' })"
Write-Host "  UPR FVX:    $(if (Test-Path $uprJar) { 'OK' } else { 'FALTA' })"
Write-Host "  PKHeX:      $(if (Test-Path $pkhexExe) { 'OK' } else { 'FALTA' })"
Write-Host "  Radmin VPN: $(if ($radminInstalled) { 'OK' } else { 'PENDIENTE' })"
Write-Host "  ROM:        $(if ($hasRom) { $hasRom.Name } else { 'FALTA en roms\' })"
Write-Host "  Mod Random: $(if ((Get-ChildItem -Path (Join-Path $AzaharDir 'user\load\mods') -Directory -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0) { 'INSTALADO' } else { 'PENDIENTE' })"
Write-Host ""
Write-Host "Para jugar con un clic: 0-JUGAR-POKEMON-Y.bat" -ForegroundColor Cyan
