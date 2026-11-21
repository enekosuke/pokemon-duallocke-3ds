# ==============================================================================
#  Randomizador Automatico (Misma Semilla para ambos jugadores)
#  Genera el mod LayeredFS con presets\pokemon-y-randomlocke.rnqs y semilla fija
#  y lo instala automaticamente en Azahar.
# ==============================================================================

param(
    [string]$Seed = "random",
    [string]$PresetPath = ""
)

$ErrorActionPreference = "Stop"
if (-not $Seed -or $Seed -eq "random") {
    $Seed = [string](Get-Random -Minimum 1000000 -Maximum 99999999)
    # Semillas ya usadas por Eneko: nunca repetirlas
    while (@("20261121", "65344194", "52824960") -contains $Seed) { $Seed = [string](Get-Random -Minimum 1000000 -Maximum 99999999) }
}
$BaseDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$RomsDir = Join-Path $BaseDir "roms"
$UprDir = Join-Path $BaseDir "tools\upr-fvx"
$OrigJar = Join-Path $UprDir "UPR-FVX.jar"
$JavaExe = Join-Path $UprDir "java\bin\java.exe"
$ModsTargetRoot = Join-Path $BaseDir "tools\azahar\user\load\mods"

if (-not $PresetPath) {
    $PresetPath = Join-Path $BaseDir "presets\pokemon-y-randomlocke.rnqs"
}

if (-not (Test-Path $OrigJar) -or -not (Test-Path $JavaExe)) {
    throw "Falta UPR FVX. Ejecuta primero 1-Instalar-o-Reparar-Todo.bat"
}
if (-not (Test-Path $PresetPath)) {
    throw "No se encontro el preset: $PresetPath"
}

$romFile = Get-ChildItem -Path $RomsDir -File | Where-Object { $_.Extension -in ".cci", ".3ds", ".cxi" } | Select-Object -First 1
if (-not $romFile) {
    throw "No hay ninguna ROM (.cci/.3ds/.cxi) en la carpeta roms\. Coloca primero la ROM desencriptada ahi."
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   RANDOMIZADOR AUTOMATICO POKEMON DUALLOCKE 3DS" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  ROM:     $($romFile.Name)"
Write-Host "  Preset:  $(Split-Path -Leaf $PresetPath)"
Write-Host "  Semilla: $Seed"
Write-Host ""

$outDir = Join-Path $BaseDir "mods-para-compartir\pokemon-y-randomlocke"
if (Test-Path $outDir) { Remove-Item $outDir -Recurse -Force }
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

# Copia temporal para habilitar 3DS en modo CLI (workaround de bug upstream en CliRandomizer de FVX 1.6.3)
$tmpJar = Join-Path $UprDir "_upr_cli_temp.jar"
Copy-Item $OrigJar $tmpJar -Force

try {
    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::Open($tmpJar, [System.IO.Compression.ZipArchiveMode]::Update)
    $entry = $zip.GetEntry("com/uprfvx/romio/romio/RomOpener.class")
    $ms = New-Object System.IO.MemoryStream
    $s = $entry.Open(); $s.CopyTo($ms); $s.Dispose()
    $bytes = $ms.ToArray()
    if ($bytes[4636] -eq 0x2A -and $bytes[4637] -eq 0xB4 -and $bytes[4640] -eq 0x9A -and $bytes[4642] -eq 0x11) {
        $bytes[4640] = 0x99
    } else {
        throw "Bytecode inesperado en RomOpener.class; usa 2-Abrir-Randomizer.bat manualmente."
    }
    $entry.Delete()
    $newEntry = $zip.CreateEntry("com/uprfvx/romio/romio/RomOpener.class")
    $ws = $newEntry.Open(); $ws.Write($bytes, 0, $bytes.Length); $ws.Dispose()
    $zip.Dispose()

    Write-Host ">>> Randomizando ROM en formato LayeredFS (tarda ~20 segundos)..." -ForegroundColor Yellow
    Push-Location $UprDir
    # Limite de heap segun RAM fisica: 8 GB -> 3072M (seguro), >12 GB -> 4608M
    $ramGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1)
    $heap = if ($ramGB -le 12) { "-Xmx3072M" } else { "-Xmx4608M" }
    Write-Host "  RAM detectada: $ramGB GB -> Java $heap" -ForegroundColor DarkGray
    if ($ramGB -le 12 -and (Get-Process azahar -ErrorAction SilentlyContinue)) {
        throw "Cierra Azahar antes de randomizar (equipo con poca RAM)."
    }
    & $JavaExe $heap -jar $tmpJar cli -i $romFile.FullName -o $outDir -s $PresetPath -z $Seed -d
    $exitCode = $LASTEXITCODE
    Pop-Location
    if ($exitCode -ne 0) {
        throw "UPR FVX CLI termino con codigo de error $exitCode"
    }
} finally {
    Remove-Item $tmpJar -Force -ErrorAction SilentlyContinue
}

$titleDirs = Get-ChildItem -Path $outDir -Directory
if (-not $titleDirs -or $titleDirs.Count -eq 0) {
    throw "No se genero ninguna carpeta TitleID en $outDir"
}

foreach ($td in $titleDirs) {
    $dest = Join-Path $ModsTargetRoot $td.Name
    if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $dest | Out-Null
    Copy-Item -Path (Join-Path $td.FullName "*") -Destination $dest -Recurse -Force
    Write-Host "[OK] Mod instalado automaticamente en Azahar: $dest" -ForegroundColor Green
}

# Aplicar mejoras PRO de RomFS (IA Experta 0x07 + Caramelo Raro 10p + Regulacion 3as evoluciones hasta 4o Gimnasio)
$enhanceScript = Join-Path $BaseDir "scripts\enhance-romfs.ps1"
if ((Test-Path $enhanceScript) -and (Test-Path (Join-Path $ModsTargetRoot "0004000000055E00\romfs"))) {
    & $enhanceScript
}

# Aplicar automaticamente el Motor Nativo ARM32 PRO (Muerte Permanente + Hard Level Cap + Caramelos en Tiendas)
$romEngineScript = Join-Path $BaseDir "scripts\rom-engine.ps1"
if ((Test-Path $romEngineScript) -and (Test-Path (Join-Path $ModsTargetRoot "0004000000055E00"))) {
    & $romEngineScript -Apply
}

Write-Host ""
Write-Host "LISTO! Ya puedes abrir 0-JUGAR-POKEMON-Y.bat con un solo clic." -ForegroundColor Cyan
