# ==============================================================================
#  Asistente 1-Clic para Jugar Online / Combatir con tu Amigo (Azahar + Radmin)
# ==============================================================================

$ErrorActionPreference = "Stop"
$BaseDir  = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$AzaharDir = Join-Path $BaseDir "tools\azahar"
$AzaharExe = Join-Path $AzaharDir "azahar.exe"
$RoomExe   = Join-Path $AzaharDir "azahar-room.exe"
$QtIni     = Join-Path $AzaharDir "user\config\qt-config.ini"
$OnlineCfg = Join-Path $BaseDir "presets\online-config.json"
$RomsDir   = Join-Path $BaseDir "roms"

function Get-RadminIP {
    try {
        $ips = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
            Where-Object { $_.InterfaceAlias -match "Radmin" -or $_.IPAddress -like "26.*" } |
            Select-Object -ExpandProperty IPAddress
        return ($ips | Select-Object -First 1)
    } catch { return $null }
}

function Ensure-RadminOpen {
    $gui = @("C:\Program Files (x86)\Radmin VPN\RvRvpnGui.exe", "C:\Program Files\Radmin VPN\RvRvpnGui.exe") |
        Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($gui -and (-not (Get-Process RvRvpnGui -ErrorAction SilentlyContinue))) {
        Start-Process -FilePath $gui
        Start-Sleep -Seconds 2
    }
    return $gui
}

function Set-IniVal($lines, $key, $val) {
    $esc = [regex]::Escape($key)
    $found = $false
    $out = foreach ($l in $lines) {
        if ($l -match "^$esc=") { $found = $true; "$key=$val" } else { $l }
    }
    if (-not $found) { $out += "$key=$val" }
    return ,$out
}

function Preconfigure-Multiplayer($ip, $port, $nick) {
    if (-not (Test-Path $QtIni)) { return }
    # Solo escribir si Azahar esta cerrado para no pisar nada
    if (Get-Process azahar -ErrorAction SilentlyContinue) { return }
    $lines = Get-Content $QtIni -Encoding UTF8
    $lines = Set-IniVal $lines "Multiplayer\ip\default" "false"
    $lines = Set-IniVal $lines "Multiplayer\ip" $ip
    $lines = Set-IniVal $lines "Multiplayer\port\default" "false"
    $lines = Set-IniVal $lines "Multiplayer\port" "$port"
    $lines = Set-IniVal $lines "Multiplayer\room_port\default" "false"
    $lines = Set-IniVal $lines "Multiplayer\room_port" "$port"
    $lines = Set-IniVal $lines "Multiplayer\room_name\default" "false"
    $lines = Set-IniVal $lines "Multiplayer\room_name" "DualLocke3DS"
    if ($nick) {
        $lines = Set-IniVal $lines "Multiplayer\nickname\default" "false"
        $lines = Set-IniVal $lines "Multiplayer\nickname" $nick
    }
    Set-Content -Path $QtIni -Value $lines -Encoding UTF8
}

function Launch-PokemonY {
    $rom = Get-ChildItem -Path $RomsDir -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -in ".cci", ".3ds", ".cxi" } | Select-Object -First 1
    if ($rom) {
        Start-Process -FilePath $AzaharExe -ArgumentList "`"$($rom.FullName)`"" -WorkingDirectory $AzaharDir
    } else {
        Start-Process -FilePath $AzaharExe -WorkingDirectory $AzaharDir
    }
}

$saved = @{ host_ip = ""; nickname = $env:USERNAME; port = 24872 }
if (Test-Path $OnlineCfg) {
    try {
        $j = Get-Content $OnlineCfg -Raw | ConvertFrom-Json
        if ($j.host_ip)  { $saved.host_ip  = $j.host_ip }
        if ($j.nickname) { $saved.nickname = $j.nickname }
        if ($j.port)     { $saved.port     = [int]$j.port }
    } catch {}
}

Write-Host "================================================================" -ForegroundColor Magenta
Write-Host "   POKEMON DUALLOCKE 3DS - ASISTENTE ONLINE 1-CLIC" -ForegroundColor Magenta
Write-Host "================================================================" -ForegroundColor Magenta
Write-Host "  [1] CREAR SALA (Anfitrion) -> Levanta servidor automatico + copia tu IP"
Write-Host "  [2] UNIRSE A SALA (Amigo)  -> Test de ping + pre-rellena IP y abre el juego"
Write-Host "  [3] PLAN B (Showdown)      -> Abre tu guardado 'main' directo en PKHeX"
Write-Host "  [4] Detener servidor de sala (azahar-room)"
Write-Host ""
$choice = (Read-Host "Elige opcion (1-4)").Trim()

switch ($choice) {
    "1" {
        $gui = Ensure-RadminOpen
        $myIp = Get-RadminIP
        if (-not $myIp) {
            Write-Host "[AVISO] No se detecto IP de Radmin VPN (26.x.x.x)." -ForegroundColor Yellow
            Write-Host "Asegurate de encender Radmin VPN y crear/unirte a vuestra red privada."
        } else {
            Write-Host "[OK] Tu IP de Radmin VPN es: $myIp" -ForegroundColor Green
            try { Set-Clipboard -Value $myIp; Write-Host "     (Copiada automaticamente al portapapeles -> pega con Ctrl+V a tu amigo!)" -ForegroundColor Cyan } catch {}
        }

        # Levantar azahar-room.exe dedicado en puerto 24872
        Get-Process azahar-room -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        if (Test-Path $RoomExe) {
            Start-Process -FilePath $RoomExe -WorkingDirectory $AzaharDir -WindowStyle Minimized -ArgumentList @(
                "--room-name", "DualLocke3DS",
                "--port", "$($saved.port)",
                "--max_members", "4",
                "--preferred-app", "Pokemon Y",
                "--preferred-app-id", "0004000000055E00"
            )
            Write-Host "[OK] Servidor de sala 'DualLocke3DS' ACTIVO en puerto $($saved.port)!" -ForegroundColor Green
        }

        Preconfigure-Multiplayer "127.0.0.1" $saved.port $saved.nickname
        Write-Host ""
        Write-Host "=== QUE HACER AHORA (2 CLICS) ===" -ForegroundColor Cyan
        Write-Host "  1. En Azahar (que se abre ahora): Multijugador -> Conexion directa -> Conectar"
        Write-Host "     (Ya viene pre-rellenada 127.0.0.1:$($saved.port) porque la sala corre en tu PC!)"
        Write-Host "  2. Dentro de Pokemon Y abre el PSS (SIN darle al boton azul de Internet)."
        Write-Host "     Cuando tu amigo entre, aparece en Transeuntes -> toca su avatar -> Combatir!"
        Write-Host "  3. Recuerda bajar velocidad a 100% (quitar Turbo) durante el combate PVP." -ForegroundColor Yellow
        if (-not (Get-Process azahar -ErrorAction SilentlyContinue)) { Launch-PokemonY }
    }
    "2" {
        Ensure-RadminOpen | Out-Null
        $ipPrompt = if ($saved.host_ip) { "IP 26.x.x.x de tu amigo [Enter para usar $($saved.host_ip)]" } else { "Escribe la IP 26.x.x.x de Radmin VPN de tu amigo" }
        $inIp = (Read-Host $ipPrompt).Trim()
        if ($inIp) { $saved.host_ip = $inIp }
        if (-not $saved.host_ip) { Write-Host "IP vacia. Cancelado." -ForegroundColor Red; exit 1 }

        $inNick = (Read-Host "Tu apodo [Enter para usar $($saved.nickname)]").Trim()
        if ($inNick) { $saved.nickname = $inNick }
        $saved | ConvertTo-Json | Set-Content -Path $OnlineCfg -Encoding UTF8

        Write-Host "Comprobando conexion Radmin VPN con $($saved.host_ip)..." -ForegroundColor Cyan
        $okPing = Test-Connection -ComputerName $saved.host_ip -Count 1 -Quiet -ErrorAction SilentlyContinue
        if ($okPing) {
            Write-Host "[OK] Conexion directa con $($saved.host_ip) VERIFICADA!" -ForegroundColor Green
        } else {
            Write-Host "[AVISO] No responde al ping todavia. Revisa que ambos esteis en la MISMA red de Radmin VPN con luz verde." -ForegroundColor Yellow
        }

        Preconfigure-Multiplayer $saved.host_ip $saved.port $saved.nickname
        Write-Host ""
        Write-Host "=== QUE HACER AHORA (2 CLICS) ===" -ForegroundColor Cyan
        Write-Host "  1. En Azahar (que se abre ahora): Multijugador -> Conexion directa -> Conectar"
        Write-Host "     (La IP $($saved.host_ip):$($saved.port) ya esta guardada y lista!)"
        Write-Host "  2. Dentro de Pokemon Y abre el PSS (SIN darle al boton azul de Internet)."
        Write-Host "     Toca el avatar de tu amigo en Transeuntes -> Combatir!"
        if (-not (Get-Process azahar -ErrorAction SilentlyContinue)) { Launch-PokemonY }
    }
    "3" {
        & (Join-Path $BaseDir "scripts\backup-save.ps1")
        $sdmc = Join-Path $AzaharDir "user\sdmc\Nintendo 3DS"
        $mainFile = Get-ChildItem -Path $sdmc -Recurse -Filter "main" -File -ErrorAction SilentlyContinue | Select-Object -First 1
        $pkhex = Join-Path $BaseDir "tools\pkhex\PKHeX.exe"
        if ($mainFile -and (Test-Path $pkhex)) {
            Write-Host "Abriendo tu partida directamente en PKHeX..." -ForegroundColor Green
            Write-Host "Para Showdown: Tools -> Showdown -> Export Party to Clipboard -> pega en pokemonshowdown.com ([Gen 6] Custom Game)" -ForegroundColor Cyan
            Start-Process -FilePath $pkhex -ArgumentList "`"$($mainFile.FullName)`""
        } else {
            Write-Host "[AVISO] No se encontro guardado 'main' o PKHeX." -ForegroundColor Yellow
        }
    }
    "4" {
        Get-Process azahar-room -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Write-Host "[OK] Servidor de sala detenido." -ForegroundColor Green
    }
}
