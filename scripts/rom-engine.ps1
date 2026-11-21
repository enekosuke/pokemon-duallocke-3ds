# ==============================================================================
#  Pokemon Y (USA v1.0, TitleID 0004000000055E00) - MOTOR NATIVO ARM32 PRO
#  Gestiona 3 parches nativos 100% configurables sobre code.bin / exefs/code.ips:
#    1. Muerte Permanente (NUZL @ 0x0053bedc, tras N medallas, PVP inmune)
#    2. Hard Level Cap    (LCAP @ 0x003517d4 / 0x003502e8 / 0x0034f538)
#       Bloquea Caramelos Raros y EXP en combate al nivel del gimnasio actual!
#    3. Caramelos Raros Infinitos en Tiendas (Shops 1..8 @ 0x0053c8a2..0x0053c9b2)
# ==============================================================================

param(
    [switch]$Apply,
    [int]$Permadeath = -1,
    [int]$MinBadges = -1,
    [int]$LevelCap = -1,
    [int]$MartCandies = -1,
    [int]$AllowWild = -1,
    [int]$AllowTrainer = -1,
    [int]$OnWipe = -1
)

$ErrorActionPreference = "Stop"
$BaseDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$TitleId = "0004000000055E00"
$CfgJson = Join-Path $BaseDir "presets\pro-rules.json"
$CodeBase = 0x00100000

function HexToBytes([string]$hex) {
    $len = $hex.Length / 2
    $b = New-Object byte[] $len
    for ($i = 0; $i -lt $len; $i++) { $b[$i] = [Convert]::ToByte($hex.Substring($i * 2, 2), 16) }
    return ,$b
}

# --- MOD 1: PERMADEATH (NUZL) ---
$NuzlHookOff   = 0x003C7B48 - $CodeBase
$NuzlCaveOff   = 0x0053BEDC - $CodeBase
$NuzlHookBytes = HexToBytes "e6d005ea"
$NuzlOrigBytes = HexToBytes "4cd08de2"
$NuzlCodeBytes = HexToBytes (
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

# --- MOD 2: HARD LEVEL CAP (LCAP) ---
$LcapCfgOff    = 0x003517D4 - $CodeBase
$LcapGsyncOff  = 0x003502E8 - $CodeBase
$LcapEshopOff  = 0x0034F538 - $CodeBase
$LcapGetCapB   = HexToBytes "3e402de91c404fe20400d4e5000050e3c2f4f71b000050e31c0090150000501300009015000050136400a0033e80bd08030a80e2410e80e2d27605eb080050e30800a083054084e20000d4e73e80bde8"
$LcapGsyncB    = HexToBytes "1eff2fe110402de93b0500eb000059e11080bde801402de9370500eb00109de5010050e10100a031000055e10050a0810180bde8"
$LcapEshopB    = HexToBytes "1eff2fe120402de914009de5150750e36400a0332080bd38a30800eb0050a0e10400a0e16065f8eb050050e10500a0312080bde8"

$LcapBagOff    = 0x0043DFB8 - $CodeBase
$LcapBagHook   = HexToBytes "cb48fceb"
$LcapBagOrig   = HexToBytes "640059e3"

$LcapAddOff    = 0x0039D758 - $CodeBase
$LcapAddHook   = HexToBytes "e7cafeeb00f020e3"
$LcapAddOrig   = HexToBytes "640055e36450a083"

$LcapSetOff    = 0x0039D714 - $CodeBase
$LcapSetHook   = HexToBytes "88c7feeb"
$LcapSetOrig   = HexToBytes "6400a0e3"

# --- MOD 3: POKÉ MART RARE CANDIES (Shops 1..8: reemplazar Antihielo 20 -> Caramelo Raro 50) ---
# Offsets exactos en code.bin de Antihielo (0x0014) en Primary Shops 1..8 (desde Ciudad Novarte hasta la Liga!)
$MartIceHealOffsets = @(
    0x43C8B2, # Shop 1 (0-1 medallas, Ciudad Novarte)
    0x43C8CC, # Shop 2
    0x43C8EA, # Shop 3
    0x43C90E, # Shop 4
    0x43C934, # Shop 5
    0x43C95A, # Shop 6
    0x43C980, # Shop 7
    0x43C9A6  # Shop 8
)
$RareCandyU16 = [byte[]]@(0x32, 0x00) # Item ID 50 (Caramelo Raro)
$IceHealU16   = [byte[]]@(0x14, 0x00) # Item ID 20 (Antihielo original)

function Load-Config {
    $cfg = [ordered]@{
        permadeath    = $true
        min_badges    = 1
        on_wipe_mode  = 0
        allow_wild    = $true
        allow_trainer = $true
        level_cap     = $true
        caps          = @(12, 25, 32, 34, 37, 42, 48, 59, 68)
        mart_candies  = $true
    }
    if (Test-Path $CfgJson) {
        try {
            $j = Get-Content $CfgJson -Raw | ConvertFrom-Json
            if ($null -ne $j.permadeath)    { $cfg.permadeath    = [bool]$j.permadeath }
            if ($null -ne $j.min_badges)    { $cfg.min_badges    = [int]$j.min_badges }
            if ($null -ne $j.on_wipe_mode)  { $cfg.on_wipe_mode  = [int]$j.on_wipe_mode }
            if ($null -ne $j.allow_wild)    { $cfg.allow_wild    = [bool]$j.allow_wild }
            if ($null -ne $j.allow_trainer) { $cfg.allow_trainer = [bool]$j.allow_trainer }
            if ($null -ne $j.level_cap)     { $cfg.level_cap     = [bool]$j.level_cap }
            if ($null -ne $j.caps -and $j.caps.Count -eq 9) { $cfg.caps = @($j.caps | ForEach-Object { [int]$_ }) }
            if ($null -ne $j.mart_candies)  { $cfg.mart_candies  = [bool]$j.mart_candies }
        } catch {}
    }
    return $cfg
}

function Build-Ips($records) {
    $ms = New-Object System.IO.MemoryStream
    $hdr = [System.Text.Encoding]::ASCII.GetBytes("PATCH")
    $ms.Write($hdr, 0, 5)
    foreach ($rec in $records) {
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

function Apply-All($cfg) {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $CfgJson) | Out-Null
    $cfg | ConvertTo-Json | Set-Content -Path $CfgJson -Encoding UTF8

    $bPerm   = if ($cfg.permadeath) { [byte]1 } else { [byte]0 }
    $bMinB   = [byte][Math]::Max(0, [Math]::Min(255, $cfg.min_badges))
    $bWipe   = if ($cfg.on_wipe_mode -ne 0) { [byte]1 } else { [byte]0 }
    $bWild   = if ($cfg.allow_wild) { [byte]1 } else { [byte]0 }
    $bTrain  = if ($cfg.allow_trainer) { [byte]1 } else { [byte]0 }
    $nuzlCfg = [byte[]]@(0x4E, 0x55, 0x5A, 0x4C, $bPerm, $bMinB, $bWipe, $bWild, $bTrain, 0, 0, 0)

    $bCap    = if ($cfg.level_cap) { [byte]1 } else { [byte]0 }
    $lcapCfg = New-Object byte[] 16
    $lcapCfg[0]=0x4C; $lcapCfg[1]=0x43; $lcapCfg[2]=0x41; $lcapCfg[3]=0x50; $lcapCfg[4]=$bCap
    for ($i=0; $i -lt 9; $i++) { $lcapCfg[5+$i] = [byte][Math]::Max(1, [Math]::Min(100, $cfg.caps[$i])) }

    $nuzlPayload = New-Object byte[] ($nuzlCfg.Length + $NuzlCodeBytes.Length)
    [Array]::Copy($nuzlCfg, 0, $nuzlPayload, 0, $nuzlCfg.Length)
    [Array]::Copy($NuzlCodeBytes, 0, $nuzlPayload, $nuzlCfg.Length, $NuzlCodeBytes.Length)

    $lcapPayload = New-Object byte[] ($lcapCfg.Length + $LcapGetCapB.Length)
    [Array]::Copy($lcapCfg, 0, $lcapPayload, 0, $lcapCfg.Length)
    [Array]::Copy($LcapGetCapB, 0, $lcapPayload, $lcapCfg.Length, $LcapGetCapB.Length)

    $records = New-Object System.Collections.ArrayList

    # Always write NUZL & LCAP payloads with their enabled flag so toggling ON/OFF is instant and reversible
    if ($cfg.permadeath) {
        [void]$records.Add(@($NuzlHookOff, $NuzlHookBytes))
        [void]$records.Add(@($NuzlCaveOff, $nuzlPayload))
    }
    if ($cfg.level_cap) {
        [void]$records.Add(@($LcapCfgOff,   $lcapPayload))
        [void]$records.Add(@($LcapGsyncOff, $LcapGsyncB))
        [void]$records.Add(@($LcapEshopOff, $LcapEshopB))
        [void]$records.Add(@($LcapBagOff,   $LcapBagHook))
        [void]$records.Add(@($LcapAddOff,   $LcapAddHook))
        [void]$records.Add(@($LcapSetOff,   $LcapSetHook))
    }
    if ($cfg.mart_candies) {
        foreach ($mo in $MartIceHealOffsets) {
            [void]$records.Add(@($mo, $RareCandyU16))
        }
    }

    $modDir   = Join-Path $BaseDir "tools\azahar\user\load\mods\$TitleId"
    $exefsDir = Join-Path $modDir "exefs"
    New-Item -ItemType Directory -Force -Path $exefsDir | Out-Null

    $ipsExefs = Join-Path $exefsDir "code.ips"
    $ipsRoot  = Join-Path $modDir "code.ips"
    if ($records.Count -gt 0) {
        $ipsBytes = Build-Ips $records
        [System.IO.File]::WriteAllBytes($ipsExefs, $ipsBytes)
        [System.IO.File]::WriteAllBytes($ipsRoot, $ipsBytes)
    } else {
        Remove-Item $ipsExefs, $ipsRoot -Force -ErrorAction SilentlyContinue
    }

    # Sincronizar code.bin si UPR FVX lo genero
    $lumaBin  = Join-Path $modDir "code.bin"
    $exefsBin = Join-Path $exefsDir "code.bin"
    $targetBin = if (Test-Path $lumaBin) { $lumaBin } elseif (Test-Path $exefsBin) { $exefsBin } else { $null }
    if ($targetBin) {
        $data = [System.IO.File]::ReadAllBytes($targetBin)
        # 1. Permadeath
        if ($cfg.permadeath) {
            [Array]::Copy($NuzlHookBytes, 0, $data, $NuzlHookOff, 4)
            [Array]::Copy($nuzlPayload, 0, $data, $NuzlCaveOff, $nuzlPayload.Length)
        } else {
            [Array]::Copy($NuzlOrigBytes, 0, $data, $NuzlHookOff, 4)
            for ($i=0; $i -lt $nuzlPayload.Length; $i++) { $data[$NuzlCaveOff + $i] = 0 }
        }
        # 2. Level Cap
        if ($cfg.level_cap) {
            [Array]::Copy($lcapPayload, 0, $data, $LcapCfgOff, $lcapPayload.Length)
            [Array]::Copy($LcapGsyncB,  0, $data, $LcapGsyncOff, $LcapGsyncB.Length)
            [Array]::Copy($LcapEshopB,  0, $data, $LcapEshopOff, $LcapEshopB.Length)
            [Array]::Copy($LcapBagHook, 0, $data, $LcapBagOff, 4)
            [Array]::Copy($LcapAddHook, 0, $data, $LcapAddOff, 8)
            [Array]::Copy($LcapSetHook, 0, $data, $LcapSetOff, 4)
        } else {
            [Array]::Copy($LcapBagOrig, 0, $data, $LcapBagOff, 4)
            [Array]::Copy($LcapAddOrig, 0, $data, $LcapAddOff, 8)
            [Array]::Copy($LcapSetOrig, 0, $data, $LcapSetOff, 4)
        }
        # 3. Mart Rare Candies
        $mBytes = if ($cfg.mart_candies) { $RareCandyU16 } else { $IceHealU16 }
        foreach ($mo in $MartIceHealOffsets) {
            [Array]::Copy($mBytes, 0, $data, $mo, 2)
        }
        [System.IO.File]::WriteAllBytes($lumaBin, $data)
        Copy-Item $lumaBin $exefsBin -Force
    }

    Write-Host ""
    Write-Host "[OK] MOTOR NATIVO ARM32 PRO APLICADO EN AZAHAR!" -ForegroundColor Green
    Write-Host "  1. Muerte Permanente:        $(if ($cfg.permadeath) { "ACTIVADA (tras $($cfg.min_badges) medalla/s, PVP inmune)" } else { 'DESACTIVADA' })"
    Write-Host "  2. Hard Level Cap Nativo:    $(if ($cfg.level_cap) { "ACTIVADO -> [$($cfg.caps -join ', ')]" } else { 'DESACTIVADO' })"
    Write-Host "  3. Caramelos en Tiendas:     $(if ($cfg.mart_candies) { 'ACTIVADO (infinitos por 10 pokedolares en todas las Tiendas)' } else { 'DESACTIVADO' })"
    Write-Host "  Parche IPS:                  $ipsExefs"
    Write-Host ""
    Write-Host "NOTA: Si Azahar estaba abierto, guarda partida, cierralo y vuelvelo a abrir." -ForegroundColor Yellow
}

$cfg = Load-Config
$hasArgs = $Apply -or ($Permadeath -ge 0) -or ($MinBadges -ge 0) -or ($LevelCap -ge 0) -or ($MartCandies -ge 0) -or ($AllowWild -ge 0) -or ($AllowTrainer -ge 0) -or ($OnWipe -ge 0)

if ($hasArgs) {
    if ($Permadeath -ge 0)   { $cfg.permadeath    = ($Permadeath -ne 0) }
    if ($MinBadges -ge 0)    { $cfg.min_badges    = $MinBadges }
    if ($LevelCap -ge 0)     { $cfg.level_cap     = ($LevelCap -ne 0) }
    if ($MartCandies -ge 0)  { $cfg.mart_candies  = ($MartCandies -ne 0) }
    if ($AllowWild -ge 0)    { $cfg.allow_wild    = ($AllowWild -ne 0) }
    if ($AllowTrainer -ge 0) { $cfg.allow_trainer = ($AllowTrainer -ne 0) }
    if ($OnWipe -ge 0)       { $cfg.on_wipe_mode  = $OnWipe }
    Apply-All $cfg
    exit 0
}

while ($true) {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "   POKEMON Y - CONFIGURADOR DE REGLAS PRO (MOTOR NATIVO ARM32)" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  [1] Muerte Permanente:        $(if ($cfg.permadeath) { 'ACTIVADA' } else { 'DESACTIVADA' })  (PVP siempre inmune)"
    Write-Host "  [2] Medallas para Permadeath: $($cfg.min_badges)  (0=inicio, 1=tras 1a medalla, 2..8)"
    Write-Host "  [3] Hard Level Cap Nativo:    $(if ($cfg.level_cap) { 'ACTIVADO' } else { 'DESACTIVADO' })  (bloquea Caramelos + EXP combate)"
    Write-Host "  [4] Editar tabla Level Caps:  [$($cfg.caps -join ', ')]"
    Write-Host "  [5] Caramelos en Tiendas:     $(if ($cfg.mart_candies) { 'ACTIVADO (infinitos por 10p)' } else { 'DESACTIVADO' })"
    Write-Host "  [6] Muertes en salvajes:      $(if ($cfg.allow_wild) { 'SI' } else { 'NO' })"
    Write-Host "  [7] Muertes en entrenadores:  $(if ($cfg.allow_trainer) { 'SI' } else { 'NO' })"
    Write-Host "  [8] En blackout total:        $(if ($cfg.on_wipe_mode -eq 0) { 'Dejar solo slot 0 (anti-crash)' } else { 'No borrar ninguno' })"
    Write-Host "  ----------------------------------------------------------------"
    Write-Host "  [G] Guardar y aplicar todo en Azahar"
    Write-Host "  [S] Salir sin guardar"
    $opt = (Read-Host "`nElige una opcion").Trim().ToLower()
    switch ($opt) {
        "1" { $cfg.permadeath = -not $cfg.permadeath }
        "2" { $v = Read-Host "Medallas minimas (0-8)"; if ($v -match '^[0-8]$') { $cfg.min_badges = [int]$v } }
        "3" { $cfg.level_cap = -not $cfg.level_cap }
        "4" {
            Write-Host "Introduce 9 niveles separados por comas (0..8 medallas), ej: 12,25,32,34,37,42,48,59,68"
            $line = Read-Host "Caps"
            $parts = $line.Split(",") | ForEach-Object { $_.Trim() }
            if ($parts.Count -eq 9 -and ($parts | Where-Object { $_ -notmatch '^\d+$' }).Count -eq 0) {
                $cfg.caps = @($parts | ForEach-Object { [Math]::Max(1, [Math]::Min(100, [int]$_)) })
            }
        }
        "5" { $cfg.mart_candies = -not $cfg.mart_candies }
        "6" { $cfg.allow_wild = -not $cfg.allow_wild }
        "7" { $cfg.allow_trainer = -not $cfg.allow_trainer }
        "8" { $cfg.on_wipe_mode = 1 - $cfg.on_wipe_mode }
        "g" { Apply-All $cfg; break }
        "s" { break }
    }
    if ($opt -eq "g" -or $opt -eq "s") { break }
}
