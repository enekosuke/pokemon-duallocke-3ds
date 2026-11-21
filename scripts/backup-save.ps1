# ==============================================================================
#  Copia de seguridad automatica de partidas guardadas (main) de Azahar
# ==============================================================================

$ErrorActionPreference = "Stop"
$BaseDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$SdmcRoot = Join-Path $BaseDir "tools\azahar\user\sdmc\Nintendo 3DS"
$BackupRoot = Join-Path $BaseDir "saves-backup"

$TitleMap = @{
    "00055d00" = "Pokemon-X"
    "00055e00" = "Pokemon-Y"
    "0011c400" = "Pokemon-Rubi-Omega"
    "0011c500" = "Pokemon-Zafiro-Alfa"
    "00164800" = "Pokemon-Sol"
    "00175e00" = "Pokemon-Luna"
    "001b5000" = "Pokemon-Ultrasol"
    "001b5100" = "Pokemon-Ultraluna"
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   BACKUP DE PARTIDAS GUARDADAS (POKEMON 3DS)" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

if (-not (Test-Path $SdmcRoot)) {
    Write-Host "[AVISO] Todavia no existe ninguna partida guardada en Azahar." -ForegroundColor Yellow
    Write-Host "Abre el juego, guarda partida dentro del juego y vuelve a ejecutar esto."
    exit 0
}

$saves = Get-ChildItem -Path $SdmcRoot -Recurse -Filter "main" -File -ErrorAction SilentlyContinue
if (-not $saves -or $saves.Count -eq 0) {
    Write-Host "[AVISO] No se encontro ningun archivo 'main' de Pokemon 3DS." -ForegroundColor Yellow
    exit 0
}

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
New-Item -ItemType Directory -Force -Path $BackupRoot | Out-Null

foreach ($s in $saves) {
    $gameName = "Pokemon-3DS"
    foreach ($key in $TitleMap.Keys) {
        if ($s.FullName.ToLower().Contains($key)) {
            $gameName = $TitleMap[$key]
            break
        }
    }
    $destFolder = Join-Path $BackupRoot "${gameName}_${timestamp}"
    New-Item -ItemType Directory -Force -Path $destFolder | Out-Null
    Copy-Item -Path $s.FullName -Destination (Join-Path $destFolder "main") -Force
    Write-Host "[OK] Backup guardado: $destFolder\main" -ForegroundColor Green
    Write-Host "     Original (para abrir en PKHeX): $($s.FullName)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Consejo: Antes de editar tu 'main' en PKHeX (para meter Caramelos Raros)," -ForegroundColor Cyan
Write-Host "cierra Azahar, haz este backup y edita el archivo 'Original' mostrado arriba." -ForegroundColor Cyan
