# ==============================================================================
#  Pokemon Y (USA v1.0, TitleID 0004000000055E00)
#  Motor Nativo ARM32 de Muerte Permanente (100% Modificable, sin Python)
# ==============================================================================

param(
    [switch]$Apply,
    [int]$Enabled = -1,
    [int]$MinBadges = -1,
    [int]$AllowWild = -1,
    [int]$AllowTrainer = -1,
    [int]$OnWipe = -1
)

$ErrorActionPreference = "Stop"
$BaseDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$TitleId = "0004000000055E00"
$CfgJson = Join-Path $BaseDir "presets\nuzlocke-permadeath.json"

$CodeBase = 0x00100000
$HookOff  = 0x003C7B48 - $CodeBase
$CaveOff  = 0x0053BEDC - $CodeBase

function HexToBytes([string]$hex) {
    $len = $hex.Length / 2
    $b = New-Object byte[] $len
    for ($i = 0; $i -lt $len; $i++) {
        $b[$i] = [Convert]::ToByte($hex.Substring($i * 2, 2), 16)
    }
    return ,$b
}

$HookBytes     = HexToBytes "e6d005ea"
$OrigHookBytes = HexToBytes "4cd08de2"
$CaveCodeBytes = HexToBytes (
    "ff412de918804fe20400d8e5000050e30000541300005b133800000a180094e5" +
    "000050e33500000a0000d0e5010050e33200008a071088e20010d1e7000051e3" +
    "2e00000a00009be5000050e32b00000a030a80e2410e80e209cdfdeb0510d8e5" +
    "010050e12500003a14409be5000054e32200000a1850d4e5000055e31f00000a" +
    "060055e31d00008a0400a0e10110a0e30020a0e33a97fdeb000050e30070a013" +
    "0300001a0600d8e5000050e31300001a0170a0e3016045e2070056e10f0000ba" +
    "060194e7000050e30a00000a0210a0e3a695fdeb000050e30600001a060194e7" +
    "c996fdeb000050e30200000a0400a0e10610a0e17888f9eb016046e2edffffea" +
    "ff41bde84cd08de2d52efaea"
)

function Load-Config {
    $cfg = [ordered]@{
        enabled       = $true
        min_badges    = 1
        on_wipe_mode  = 0
        allow_wild    = $true
        allow_trainer = $true
    }
    if (Test-Path $CfgJson) {
        try {
            $j = Get-Content $CfgJson -Raw | ConvertFrom-Json
            if ($null -ne $j.enabled)       { $cfg.enabled       = [bool]$j.enabled }
            if ($null -ne $j.min_badges)    { $cfg.min_badges    = [int]$j.min_badges }
            if ($null -ne $j.on_wipe_mode)  { $cfg.on_wipe_mode  = [int]$j.on_wipe_mode }
            if ($null -ne $j.allow_wild)    { $cfg.allow_wild    = [bool]$j.allow_wild }
            if ($null -ne $j.allow_trainer) { $cfg.allow_trainer = [bool]$j.allow_trainer }
        } catch {}
    }
    return $cfg
}

function Build-Ips([byte[]]$cfgBytes) {
    $ms = New-Object System.IO.MemoryStream
    $patchHdr = [System.Text.Encoding]::ASCII.GetBytes("PATCH")
    $ms.Write($patchHdr, 0, 5)

    $payload = New-Object byte[] ($cfgBytes.Length + $CaveCodeBytes.Length)
    [Array]::Copy($cfgBytes, 0, $payload, 0, $cfgBytes.Length)
    [Array]::Copy($CaveCodeBytes, 0, $payload, $cfgBytes.Length, $CaveCodeBytes.Length)

    foreach ($rec in @(@($HookOff, $HookBytes), @($CaveOff, $payload))) {
        $off = [int]$rec[0]
        $dat = [byte[]]$rec[1]
        $ms.WriteByte([byte](($off -shr 16) -band 0xFF))
        $ms.WriteByte([byte](($off -shr 8) -band 0xFF))
        $ms.WriteByte([byte]($off -band 0xFF))
        $ms.WriteByte([byte](($dat.Length -shr 8) -band 0xFF))
        $ms.WriteByte([byte]($dat.Length -band 0xFF))
        $ms.Write($dat, 0, $dat.Length)
    }

    $eof = [System.Text.Encoding]::ASCII.GetBytes("EOF")
    $ms.Write($eof, 0, 3)
    return ,$ms.ToArray()
}

function Patch-CodeBin([string]$path, [byte[]]$cfgBytes, [bool]$enable) {
    if (-not (Test-Path $path)) { return }
    $data = [System.IO.File]::ReadAllBytes($path)
    $payloadLen = $cfgBytes.Length + $CaveCodeBytes.Length
    if ($data.Length -lt ($CaveOff + $payloadLen)) {
        throw "code.bin inesperado ($($data.Length) bytes): no parece Pokemon Y v1.0"
    }
    $curHex = ($data[$HookOff..($HookOff+3)] | ForEach-Object { "{0:x2}" -f $_ }) -join ""
    if ($curHex -ne "4cd08de2" -and $curHex -ne "e6d005ea") {
        throw "Bytes inesperados en 0x3c7b48 ($curHex): este parche es para Pokemon Y v1.0"
    }
    if ($enable) {
        [Array]::Copy($HookBytes, 0, $data, $HookOff, 4)
        [Array]::Copy($cfgBytes, 0, $data, $CaveOff, $cfgBytes.Length)
        [Array]::Copy($CaveCodeBytes, 0, $data, $CaveOff + $cfgBytes.Length, $CaveCodeBytes.Length)
    } else {
        [Array]::Copy($OrigHookBytes, 0, $data, $HookOff, 4)
        for ($i = 0; $i -lt $payloadLen; $i++) { $data[$CaveOff + $i] = 0 }
    }
    [System.IO.File]::WriteAllBytes($path, $data)
}

function Apply-Config($cfg) {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $CfgJson) | Out-Null
    $cfg | ConvertTo-Json | Set-Content -Path $CfgJson -Encoding UTF8

    $bEnabled = if ($cfg.enabled) { [byte]1 } else { [byte]0 }
    $bBadges  = [byte][Math]::Max(0, [Math]::Min(255, $cfg.min_badges))
    $bWipe    = if ($cfg.on_wipe_mode -ne 0) { [byte]1 } else { [byte]0 }
    $bWild    = if ($cfg.allow_wild) { [byte]1 } else { [byte]0 }
    $bTrainer = if ($cfg.allow_trainer) { [byte]1 } else { [byte]0 }
    $cfgBytes = [byte[]]@(0x4E, 0x55, 0x5A, 0x4C, $bEnabled, $bBadges, $bWipe, $bWild, $bTrainer, 0, 0, 0)

    $modDir   = Join-Path $BaseDir "tools\azahar\user\load\mods\$TitleId"
    $exefsDir = Join-Path $modDir "exefs"
    New-Item -ItemType Directory -Force -Path $exefsDir | Out-Null

    $ipsBytes = Build-Ips $cfgBytes
    $ipsExefs = Join-Path $exefsDir "code.ips"
    $ipsRoot  = Join-Path $modDir "code.ips"

    if ($cfg.enabled) {
        [System.IO.File]::WriteAllBytes($ipsExefs, $ipsBytes)
        [System.IO.File]::WriteAllBytes($ipsRoot, $ipsBytes)
    } else {
        Remove-Item $ipsExefs, $ipsRoot -Force -ErrorAction SilentlyContinue
    }

    $lumaBin  = Join-Path $modDir "code.bin"
    $exefsBin = Join-Path $exefsDir "code.bin"
    if (Test-Path $lumaBin) {
        Patch-CodeBin $lumaBin $cfgBytes $cfg.enabled
        Copy-Item $lumaBin $exefsBin -Force
    } elseif (Test-Path $exefsBin) {
        Patch-CodeBin $exefsBin $cfgBytes $cfg.enabled
    }

    Write-Host ""
    Write-Host "[OK] Parche ARM32 de Muerte Permanente aplicado en Azahar!" -ForegroundColor Green
    Write-Host "  Estado:                $(if ($cfg.enabled) { 'ACTIVADA' } else { 'DESACTIVADA' })"
    Write-Host "  Activar tras medallas: $($cfg.min_badges)  (1 = a partir de la 1a medalla / Violeta)"
    Write-Host "  Combates salvajes:     $(if ($cfg.allow_wild) { 'SI' } else { 'NO' })"
    Write-Host "  Entrenadores/Gimnasio: $(if ($cfg.allow_trainer) { 'SI' } else { 'NO' })"
    Write-Host "  Combates PVP (PSS):    INMUNES (nunca borra Pokemon contra tu amigo)"
    Write-Host "  En blackout total:     $(if ($cfg.on_wipe_mode -eq 0) { 'Deja solo slot 0 (anti-crash)' } else { 'No borra ninguno en blackout' })"
    Write-Host "  IPS generado:          $ipsExefs ($($ipsBytes.Length) bytes)"
    Write-Host ""
    Write-Host "NOTA: Si Azahar estaba abierto, guarda partida, cierralo y vuelvelo a abrir para que cargue el cambio." -ForegroundColor Yellow
}

$cfg = Load-Config
$hasArgs = $Apply -or ($Enabled -ge 0) -or ($MinBadges -ge 0) -or ($AllowWild -ge 0) -or ($AllowTrainer -ge 0) -or ($OnWipe -ge 0)

if ($hasArgs) {
    if ($Enabled -ge 0)      { $cfg.enabled       = ($Enabled -ne 0) }
    if ($MinBadges -ge 0)    { $cfg.min_badges    = $MinBadges }
    if ($AllowWild -ge 0)    { $cfg.allow_wild    = ($AllowWild -ne 0) }
    if ($AllowTrainer -ge 0) { $cfg.allow_trainer = ($AllowTrainer -ne 0) }
    if ($OnWipe -ge 0)       { $cfg.on_wipe_mode  = $OnWipe }
    Apply-Config $cfg
    exit 0
}

while ($true) {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "   POKEMON Y - CONFIGURADOR DE MUERTE PERMANENTE (ARM32)" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  [1] Muerte permanente:       $(if ($cfg.enabled) { 'ACTIVADA' } else { 'DESACTIVADA' })"
    Write-Host "  [2] Medallas minimas:        $($cfg.min_badges)  (0=desde inicio, 1=tras 1a medalla, 2..8)"
    Write-Host "  [3] Muertes en salvajes:     $(if ($cfg.allow_wild) { 'SI' } else { 'NO' })"
    Write-Host "  [4] Muertes en entrenadores: $(if ($cfg.allow_trainer) { 'SI' } else { 'NO' })"
    Write-Host "  [5] En wipe/blackout total:  $(if ($cfg.on_wipe_mode -eq 0) { 'Dejar solo slot 0 (anti-crash)' } else { 'No borrar nada en wipe' })"
    Write-Host "  ------------------------------------------------------------"
    Write-Host "  [G] Guardar y aplicar en Azahar"
    Write-Host "  [S] Salir sin guardar"
    $opt = (Read-Host "`nElige una opcion").Trim().ToLower()
    switch ($opt) {
        "1" { $cfg.enabled = -not $cfg.enabled }
        "2" {
            $v = Read-Host "Numero de medallas minimas (0-8, recomendado 1)"
            if ($v -match '^[0-8]$') { $cfg.min_badges = [int]$v }
        }
        "3" { $cfg.allow_wild = -not $cfg.allow_wild }
        "4" { $cfg.allow_trainer = -not $cfg.allow_trainer }
        "5" { $cfg.on_wipe_mode = 1 - $cfg.on_wipe_mode }
        "g" { Apply-Config $cfg; break }
        "s" { break }
    }
    if ($opt -eq "g" -or $opt -eq "s") { break }
}
