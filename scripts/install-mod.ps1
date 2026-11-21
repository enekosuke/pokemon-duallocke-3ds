# ==============================================================================
#  Asistente para instalar un Mod LayeredFS (UPR FVX) en Azahar
# ==============================================================================

$ErrorActionPreference = "Stop"
$BaseDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ModsTargetRoot = Join-Path $BaseDir "tools\azahar\user\load\mods"

$Games = @(
    @{ Num = "1"; Name = "Pokemon X";            TitleId = "0004000000055D00" },
    @{ Num = "2"; Name = "Pokemon Y";            TitleId = "0004000000055E00" },
    @{ Num = "3"; Name = "Pokemon Rubi Omega";   TitleId = "000400000011C400" },
    @{ Num = "4"; Name = "Pokemon Zafiro Alfa";  TitleId = "000400000011C500" },
    @{ Num = "5"; Name = "Pokemon Sol";          TitleId = "0004000000164800" },
    @{ Num = "6"; Name = "Pokemon Luna";         TitleId = "0004000000175E00" },
    @{ Num = "7"; Name = "Pokemon Ultrasol";     TitleId = "00040000001B5000" },
    @{ Num = "8"; Name = "Pokemon Ultraluna";    TitleId = "00040000001B5100" }
)

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   INSTALADOR DE MOD LAYEREDFS (RANDOMLOCK 3DS) EN AZAHAR" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Elige a que juego de 3DS corresponde el mod:"
foreach ($g in $Games) {
    Write-Host "  [$($g.Num)] $($g.Name)  (Title ID: $($g.TitleId))"
}
Write-Host ""
$choice = Read-Host "Escribe el numero (1-8)"
$selected = $Games | Where-Object { $_.Num -eq $choice }
if (-not $selected) {
    Write-Host "Opcion no valida." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Arrastra aqui la CARPETA del mod LayeredFS (la que contiene 'romfs' o el TitleID) y pulsa Enter:" -ForegroundColor Yellow
$sourcePath = (Read-Host "Ruta de la carpeta").Trim('"').Trim()

if (-not (Test-Path $sourcePath -PathType Container)) {
    Write-Host "La ruta indicada no es una carpeta valida: $sourcePath" -ForegroundColor Red
    exit 1
}

# Detectar si el usuario paso la carpeta padre que contiene la carpeta TitleID o ya la que contiene romfs/exefs
$effectiveSource = $sourcePath
$subTitleDir = Join-Path $sourcePath $selected.TitleId
if (Test-Path $subTitleDir -PathType Container) {
    $effectiveSource = $subTitleDir
} elseif (Test-Path (Join-Path $sourcePath "luma\titles\$($selected.TitleId)") -PathType Container) {
    $effectiveSource = Join-Path $sourcePath "luma\titles\$($selected.TitleId)"
}

$hasContent = (Test-Path (Join-Path $effectiveSource "romfs")) -or (Test-Path (Join-Path $effectiveSource "exefs")) -or (Test-Path (Join-Path $effectiveSource "code.bin"))
if (-not $hasContent) {
    Write-Host "[AVISO] No se detecto 'romfs' ni 'exefs' directamente dentro de: $effectiveSource" -ForegroundColor Yellow
    $confirm = Read-Host "¿Quieres copiarla igualmente? (s/n)"
    if ($confirm -notmatch "^[sS]") { exit 0 }
}

$destDir = Join-Path $ModsTargetRoot $selected.TitleId
if (Test-Path $destDir) {
    Write-Host "Eliminando mod anterior de $($selected.Name)..." -ForegroundColor Yellow
    Remove-Item $destDir -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $destDir | Out-Null
Copy-Item -Path (Join-Path $effectiveSource "*") -Destination $destDir -Recurse -Force

Write-Host ""
Write-Host "[OK] Mod instalado correctamente para $($selected.Name)!" -ForegroundColor Green
Write-Host "Ruta final: $destDir" -ForegroundColor Green
Write-Host "Ahora solo tienes que abrir 3-Abrir-Azahar.bat y arrancar el juego." -ForegroundColor Cyan
