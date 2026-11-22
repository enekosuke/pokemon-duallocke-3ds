# ==============================================================================
#  Panel de combate para Pokemon Y en Azahar
#  Ventana lateral pegada a Azahar que, durante un combate, muestra al Pokemon rival:
#  tipos, debilidades/resistencias, estadisticas base (de TU semilla), perfil, habilidades.
#
#  Como funciona: lee la memoria del juego por el servidor RPC de Azahar (UDP 45987).
#   - En combate, DllBattle crea una ficha por Pokemon (BTL_POKEPARAM, 0x244 bytes):
#       +0x0C especie  +0x0E PS max  +0x10 PS actuales  +0x12 objeto  +0x18 nivel  +0x19 id (0-5 tuyos, >=6 rival)
#   - Cada bando tiene una lista de 6 punteros + contador (0x1C bytes); la del rival va justo detras
#     de la tuya y su PRIMER puntero es el Pokemon que esta en el campo (se reordena al cambiar).
#   - La lista se busca por su forma (no por direccion fija) y se cachea mientras sea valida.
#  Datos: nombres/tipos/habilidades en espanol del texto del juego (ROM, a/0/7/8) y estadisticas/tipos
#  de la semilla actual (mod, romfs/a/2/1/8). No necesita Python ni nada instalado.
#
#  Uso:  battle-panel.ps1               -> abre el panel (se cierra solo al cerrar Azahar)
#        battle-panel.ps1 -EnsureConfig -> activa el RPC en qt-config.ini (con Azahar cerrado)
# ==============================================================================
param([switch]$EnsureConfig, [switch]$Demo, [int]$DemoSpecies = 697, [int]$DemoAbility = 0, [int]$DemoMine = 394, [int]$DemoMineAbility = 0, [string]$Snapshot, [string]$TestDump, [switch]$TestRpc, [string]$AzaharExe)

$ErrorActionPreference = "Stop"
$BaseDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$CfgIni  = Join-Path $BaseDir "tools\azahar\user\config\qt-config.ini"

function Set-RpcConfig {
    if (-not (Test-Path $CfgIni)) { return $false }
    $lines = [System.Collections.Generic.List[string]](Get-Content $CfgIni -Encoding UTF8)
    $changed = $false
    $want = @{ 'enable_rpc_server\default' = 'false'; 'enable_rpc_server' = 'true' }
    foreach ($k in $want.Keys) {
        $idx = -1
        for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -like "$k=*") { $idx = $i; break } }
        if ($idx -ge 0) {
            if ($lines[$idx] -ne "$k=$($want[$k])") { $lines[$idx] = "$k=$($want[$k])"; $changed = $true }
        } else {
            $dbg = -1
            for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -eq '[Debugging]') { $dbg = $i; break } }
            if ($dbg -lt 0) { $lines.Add('[Debugging]'); $dbg = $lines.Count - 1 }
            $lines.Insert($dbg + 1, "$k=$($want[$k])"); $changed = $true
        }
    }
    if ($changed) { [IO.File]::WriteAllLines($CfgIni, $lines, (New-Object Text.UTF8Encoding $false)) }
    return $changed
}

if ($EnsureConfig) {
    $c = Set-RpcConfig
    Write-Host ("Panel de combate: RPC de Azahar " + $(if ($c) { "activado en qt-config.ini" } else { "ya estaba activado" }))
    exit 0
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

Add-Type -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Runtime.InteropServices;
using System.Text;

public static class Bp
{
    // ---------- ROM (romfs) ----------
    public static byte[] RomfsFile(string cci, string path)
    {
        using (var fs = new FileStream(cci, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
        using (var br = new BinaryReader(fs))
        {
            fs.Seek(0x120, SeekOrigin.Begin); long p0 = (long)br.ReadUInt32() * 0x200;
            fs.Seek(p0 + 0x1B0, SeekOrigin.Begin); long ro = p0 + (long)br.ReadUInt32() * 0x200;
            long l3 = ro + 0x1000;
            fs.Seek(l3, SeekOrigin.Begin);
            uint[] h = new uint[10]; for (int i = 0; i < 10; i++) h[i] = br.ReadUInt32();
            fs.Seek(l3 + h[3], SeekOrigin.Begin); byte[] dm = br.ReadBytes((int)h[4]);
            fs.Seek(l3 + h[7], SeekOrigin.Begin); byte[] fm = br.ReadBytes((int)h[8]);
            string[] parts = path.Split('/');
            int dir = 0;
            for (int p = 0; p < parts.Length - 1; p++)
            {
                int c = BitConverter.ToInt32(dm, dir + 8), found = -1;
                while (c != -1)
                {
                    int nl = BitConverter.ToInt32(dm, c + 20);
                    if (Encoding.Unicode.GetString(dm, c + 24, nl) == parts[p]) { found = c; break; }
                    c = BitConverter.ToInt32(dm, c + 4);
                }
                if (found < 0) return null;
                dir = found;
            }
            int fe = BitConverter.ToInt32(dm, dir + 12);
            while (fe != -1)
            {
                int nl = BitConverter.ToInt32(fm, fe + 28);
                if (Encoding.Unicode.GetString(fm, fe + 32, nl) == parts[parts.Length - 1])
                {
                    long off = BitConverter.ToInt64(fm, fe + 8), sz = BitConverter.ToInt64(fm, fe + 16);
                    fs.Seek(l3 + h[9] + off, SeekOrigin.Begin);
                    return br.ReadBytes((int)sz);
                }
                fe = BitConverter.ToInt32(fm, fe + 4);
            }
            return null;
        }
    }

    // ---------- GARC ----------
    public static List<byte[]> Garc(byte[] d)
    {
        var list = new List<byte[]>();
        int hl = BitConverter.ToInt32(d, 4), doff = BitConverter.ToInt32(d, 0x10);
        int flen = BitConverter.ToInt32(d, hl + 4), cnt = BitConverter.ToUInt16(d, hl + 8);
        int fb = hl + flen;
        for (int i = 0; i < cnt; i++)
        {
            int p = fb + 12 + BitConverter.ToInt32(d, hl + 12 + i * 4);
            int s = BitConverter.ToInt32(d, p + 4), e = BitConverter.ToInt32(d, p + 8);
            byte[] r = new byte[e - s]; Array.Copy(d, doff + s, r, 0, e - s); list.Add(r);
        }
        return list;
    }

    // ---------- Texto Gen 6 ----------
    public static string[] Text(byte[] b)
    {
        int lines = BitConverter.ToUInt16(b, 2); int so = BitConverter.ToInt32(b, 12);
        var res = new string[lines]; ushort key = 0x7C89;
        for (int i = 0; i < lines; i++)
        {
            int off = BitConverter.ToInt32(b, so + 4 + i * 8); int ln = BitConverter.ToUInt16(b, so + 8 + i * 8);
            int s = so + off; ushort k = key; var sb = new StringBuilder();
            for (int j = 0; j < ln; j++)
            {
                ushort c = (ushort)(BitConverter.ToUInt16(b, s + j * 2) ^ k);
                k = (ushort)((k << 3) | (k >> 13));
                if (c == 0) break;
                if (c == 0xE08E) sb.Append((char)0x2642); else if (c == 0xE08F) sb.Append((char)0x2640);
                else if (c == 0x10 || c == 0xFFFF) break; else if (c < 0xE000) sb.Append((char)c);
            }
            key = (ushort)(key + 0x2983);
            res[i] = sb.ToString();
        }
        return res;
    }

    // ---------- RPC de Azahar ----------
    static UdpClient udp; static Random rnd = new Random();
    static IPEndPoint ep = new IPEndPoint(IPAddress.Loopback, 45987);
    public static byte[] FileMem; public static uint FileBase;
    public static byte[] Read(uint addr, int size)
    {
        if (FileMem != null) { long o = (long)addr - FileBase; if (o < 0 || o + size > FileMem.Length) return null; var b = new byte[size]; Array.Copy(FileMem, o, b, 0, size); return b; }
        try
        {
            if (udp == null) { udp = new UdpClient(); udp.Client.ReceiveTimeout = 250; }
            var res = new byte[size]; int got = 0;
            while (got < size)
            {
                int n = Math.Min(0x8000, size - got);
                uint id = (uint)rnd.Next();
                var req = new byte[24];
                BitConverter.GetBytes(2u).CopyTo(req, 0); BitConverter.GetBytes(id).CopyTo(req, 4);
                BitConverter.GetBytes(1u).CopyTo(req, 8); BitConverter.GetBytes(8u).CopyTo(req, 12);
                BitConverter.GetBytes(addr + (uint)got).CopyTo(req, 16); BitConverter.GetBytes((uint)n).CopyTo(req, 20);
                udp.Send(req, req.Length, ep);
                byte[] rep = null;
                for (int t = 0; t < 8; t++)
                {
                    IPEndPoint from = null; byte[] r = udp.Receive(ref from);
                    if (r.Length >= 16 && BitConverter.ToUInt32(r, 4) == id && BitConverter.ToUInt32(r, 8) == 1) { rep = r; break; }
                }
                if (rep == null || rep.Length - 16 <= 0) return null;
                int len = Math.Min(rep.Length - 16, n);
                Array.Copy(rep, 16, res, got, len); got += len;
                if (len < n) return null;
            }
            return res;
        }
        catch { return null; }
    }

    public class Mon { public int Species, MaxHp, Hp, Item, Level, Id, Ability; }

    static Mon ParseMon(byte[] s)
    {
        if (s == null || s.Length < 0x1C) return null;
        var m = new Mon();
        m.Species = BitConverter.ToUInt16(s, 0x0C); m.MaxHp = BitConverter.ToUInt16(s, 0x0E);
        m.Hp = BitConverter.ToUInt16(s, 0x10); m.Item = BitConverter.ToUInt16(s, 0x12);
        m.Level = s[0x18]; m.Id = s[0x19]; m.Ability = BitConverter.ToUInt16(s, 0x16);
        if (m.Species < 1 || m.Species > 721 || m.Level < 1 || m.Level > 100 || m.MaxHp == 0 || m.Hp > m.MaxHp) return null;
        return m;
    }
    static bool Ptr(uint p) { return p >= 0x08000000 && p < 0x10000000; }

    public static uint Cached = 0;
    public static string LastError = "";

    // Devuelve [rival, tuyo] o null si no hay combate
    public static Mon[] Poll()
    {
        if (Cached != 0)
        {
            var r = TryAt(Cached);
            if (r != null) return r;
            Cached = 0;
        }
        // busca la lista de punteros por su forma en la zona de combate
        const uint lo = 0x081C0000, hi = 0x08260000;
        byte[] w = Read(lo, (int)(hi - lo));
        if (w == null) { LastError = "rpc"; return null; }
        LastError = "";
        for (int o = 0x18; o + 8 <= w.Length; o += 4)
        {
            uint cnt = BitConverter.ToUInt32(w, o);
            if (cnt < 1 || cnt > 6) continue;
            uint p0 = BitConverter.ToUInt32(w, o - 0x18), q0 = BitConverter.ToUInt32(w, o + 4);
            if (!Ptr(p0) || !Ptr(q0) || p0 == q0) continue;
            var r = TryAt(lo + (uint)o);
            if (r != null) { Cached = lo + (uint)o; return r; }
        }
        return null;
    }

    static Mon[] TryAt(uint x)
    {
        byte[] a = Read(x - 0x18, 0x20);
        if (a == null) return null;
        uint cnt = BitConverter.ToUInt32(a, 0x18);
        if (cnt < 1 || cnt > 6) return null;
        uint p0 = BitConverter.ToUInt32(a, 0), q0 = BitConverter.ToUInt32(a, 0x1C);
        if (!Ptr(p0) || !Ptr(q0)) return null;
        Mon me = ParseMon(Read(p0, 0x1C)), op = ParseMon(Read(q0, 0x1C));
        if (me == null || op == null || me.Id >= 6 || op.Id < 6) return null;
        return new Mon[] { op, me };
    }

    // ---------- Ventana de Azahar ----------
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr h);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
}
"@

# ---------------- Datos del juego ----------------
$TypeColors = @('#A8A878','#C03028','#A890F0','#A040A0','#E0C068','#B8A038','#A8B820','#705898','#B8B8D0',
                '#F08030','#6890F0','#78C850','#F8D030','#F85888','#98D8D8','#7038F8','#705848','#EE99AC')
# Tabla de tipos Gen 6: $Chart[atacante][defensor] (0, 0.5, 1, 2)
$se = @{ 1=@(0,5,8,14,16); 2=@(1,6,11); 3=@(11,17); 4=@(3,5,8,9,12); 5=@(2,6,9,14); 6=@(11,13,16); 7=@(7,13);
         8=@(5,14,17); 9=@(6,8,11,14); 10=@(4,5,9); 11=@(4,5,10); 12=@(2,10); 13=@(1,3); 14=@(2,4,11,15); 15=@(15); 16=@(7,13); 17=@(1,15,16) }
$nve = @{ 0=@(5,8); 1=@(2,3,6,13,17); 2=@(5,8,12); 3=@(3,4,5,7); 4=@(6,11); 5=@(1,4,8); 6=@(1,2,3,7,8,9,17); 7=@(16);
          8=@(8,9,10,12); 9=@(5,9,10,15); 10=@(10,11,15); 11=@(2,3,6,8,9,11,15); 12=@(11,12,15); 13=@(8,13); 14=@(8,9,10,14);
          15=@(8); 16=@(1,16,17); 17=@(3,8,9) }
$imm = @{ 0=@(7); 1=@(7); 3=@(8); 4=@(2); 7=@(0); 12=@(4); 13=@(16); 15=@(17) }
$Chart = New-Object 'double[,]' 18,18
for ($a = 0; $a -lt 18; $a++) { for ($d = 0; $d -lt 18; $d++) { $Chart[$a,$d] = 1.0 } }
foreach ($k in $se.Keys)  { foreach ($d in $se[$k])  { $Chart[$k,$d] = 2.0 } }
foreach ($k in $nve.Keys) { foreach ($d in $nve[$k]) { $Chart[$k,$d] = 0.5 } }
foreach ($k in $imm.Keys) { foreach ($d in $imm[$k]) { $Chart[$k,$d] = 0.0 } }

$rom = Get-ChildItem (Join-Path $BaseDir "roms") -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -in ".cci", ".3ds" } | Select-Object -First 1
if (-not $rom) { [System.Windows.MessageBox]::Show("No encuentro la ROM en roms\.", "Panel de combate") | Out-Null; exit 1 }
$txt = [Bp]::Garc([Bp]::RomfsFile($rom.FullName, "a/0/7/8"))
$SpeciesNames = [Bp]::Text($txt[80]); $AbilityNames = [Bp]::Text($txt[34]); $TypeNames = [Bp]::Text($txt[17])
$modPersonal = Join-Path $BaseDir "tools\azahar\user\load\mods\0004000000055E00\romfs\a\2\1\8"
$persRaw = if (Test-Path $modPersonal) { [IO.File]::ReadAllBytes($modPersonal) } else { [Bp]::RomfsFile($rom.FullName, "a/2/1/8") }
$Personal = [Bp]::Garc($persRaw)

function Get-Info([int]$sp) {
    $p = $Personal[$sp]
    $t1 = [int]$p[6]; $t2 = [int]$p[7]
    $types = if ($t1 -eq $t2) { @($t1) } else { @($t1, $t2) }
    [pscustomobject]@{
        Name = $SpeciesNames[$sp]; Types = $types
        HP = [int]$p[0]; Atk = [int]$p[1]; Def = [int]$p[2]; Spe = [int]$p[3]; SpA = [int]$p[4]; SpD = [int]$p[5]
        Abil = @([int]$p[0x18], [int]$p[0x19], [int]$p[0x1A])
    }
}
# Habilidades que cambian el dano recibido (id Gen 6 -> tipo: multiplicador). 25 = Superguarda (solo le dan los supereficaces)
$AbilityMods = @{
    18 = @{ 9 = 0.0 }              # Absorbe Fuego: inmune a Fuego
    26 = @{ 4 = 0.0 }              # Levitacion: inmune a Tierra
    10 = @{ 12 = 0.0 }             # Absorbe Elec
    31 = @{ 12 = 0.0 }             # Pararrayos
    78 = @{ 12 = 0.0 }             # Electromotor
    11 = @{ 10 = 0.0 }             # Absorbe Agua
    114 = @{ 10 = 0.0 }            # Colector
    87 = @{ 10 = 0.0; 9 = 1.25 }   # Piel Seca: inmune a Agua, Fuego x1.25
    157 = @{ 11 = 0.0 }            # Herbivoro
    47 = @{ 9 = 0.5; 14 = 0.5 }    # Sebo: Fuego y Hielo a la mitad
    85 = @{ 9 = 0.5 }              # Ignifugo: Fuego a la mitad
}
function Get-Mult([int]$atk, $defTypes, [int]$abil = 0) {
    $m = 1.0; foreach ($t in $defTypes) { $m *= $Chart[$atk,$t] }
    if ($AbilityMods.ContainsKey($abil) -and $AbilityMods[$abil].ContainsKey($atk)) { $m *= $AbilityMods[$abil][$atk] }
    if ($abil -eq 25 -and $m -lt 2) { $m = 0.0 }   # Superguarda
    return $m
}

if ($TestDump -or $TestRpc) {
    if ($TestDump) { [Bp]::FileMem = [IO.File]::ReadAllBytes($TestDump); [Bp]::FileBase = 0x08000000 }
    $sw = [Diagnostics.Stopwatch]::StartNew(); $r = [Bp]::Poll(); $ms = $sw.ElapsedMilliseconds
    if ($r) { "EN COMBATE ($ms ms) lista en 0x{0:X8}: rival {1} Nv{2} PS {3}/{4} hab {7} | tuyo {5} Nv{6} hab {8}" -f [Bp]::Cached, $SpeciesNames[$r[0].Species], $r[0].Level, $r[0].Hp, $r[0].MaxHp, $SpeciesNames[$r[1].Species], $r[1].Level, $AbilityNames[$r[0].Ability], $AbilityNames[$r[1].Ability] }
    else { "Sin combate ($ms ms) error='$([Bp]::LastError)'" }
    exit 0
}
# ---------------- Interfaz ----------------
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Panel de combate" Width="330" SizeToContent="Height" WindowStyle="None" AllowsTransparency="True"
        Background="Transparent" Topmost="True" ShowInTaskbar="False" ShowActivated="False" ResizeMode="NoResize">
  <Border CornerRadius="14" Padding="14" BorderThickness="1" BorderBrush="#3A4A6A">
    <Border.Background>
      <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
        <GradientStop Color="#F2141B2D" Offset="0"/><GradientStop Color="#F20B0F1A" Offset="1"/>
      </LinearGradientBrush>
    </Border.Background>
    <StackPanel>
      <DockPanel>
        <TextBlock x:Name="Hdr" Text="RIVAL" Foreground="#7F8FB0" FontSize="11" FontWeight="Bold" DockPanel.Dock="Left"/>
        <TextBlock x:Name="Lvl" Foreground="#C8D2E8" FontSize="12" FontWeight="SemiBold" HorizontalAlignment="Right"/>
      </DockPanel>
      <TextBlock x:Name="Name" Foreground="White" FontSize="24" FontWeight="Bold" Margin="0,2,0,4"/>
      <WrapPanel x:Name="Types" Margin="0,0,0,8"/>
      <Grid Margin="0,0,0,10">
        <Border Height="8" CornerRadius="4" Background="#26324A"/>
        <Border x:Name="HpBar" Height="8" CornerRadius="4" HorizontalAlignment="Left" Background="#4CD964"/>
      </Grid>
      <TextBlock x:Name="HpTxt" Foreground="#8FA0C0" FontSize="11" Margin="0,-6,0,8"/>

      <TextBlock Text="LE HACEN MUCHO DAÑO" Foreground="#FF6B6B" FontSize="11" FontWeight="Bold"/>
      <WrapPanel x:Name="Weak" Margin="0,4,0,8"/>
      <TextBlock Text="LE HACEN POCO DAÑO" Foreground="#6BB8FF" FontSize="11" FontWeight="Bold"/>
      <WrapPanel x:Name="Resist" Margin="0,4,0,8"/>
      <TextBlock x:Name="ImmHdr" Text="NO LE HACEN NADA" Foreground="#B0B0B0" FontSize="11" FontWeight="Bold"/>
      <WrapPanel x:Name="Immune" Margin="0,4,0,8"/>
      <TextBlock Text="SUS ATAQUES DE SU TIPO PEGAN FUERTE A" Foreground="#FFB86B" FontSize="11" FontWeight="Bold"/>
      <WrapPanel x:Name="Offense" Margin="0,4,0,10"/>

      <TextBlock Text="ESTADÍSTICAS BASE" Foreground="#7F8FB0" FontSize="11" FontWeight="Bold" Margin="0,0,0,4"/>
      <StackPanel x:Name="Stats"/>
      <Border CornerRadius="8" Background="#1C2740" Padding="10,8" Margin="0,8,0,0">
        <StackPanel x:Name="Profile"/>
      </Border>
      <TextBlock x:Name="Abil" Foreground="#8FA0C0" FontSize="11" TextWrapping="Wrap" Margin="0,8,0,0"/>
      <Border x:Name="MineBox" CornerRadius="8" Background="#17203A" Padding="10,8" Margin="0,10,0,0">
        <TextBlock x:Name="Mine" Foreground="#C8D2E8" FontSize="12" TextWrapping="Wrap"/>
      </Border>
    </StackPanel>
  </Border>
</Window>
"@
$win = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml))
$ui = @{}
foreach ($n in 'Hdr','Lvl','Name','Types','HpBar','HpTxt','Weak','Resist','ImmHdr','Immune','Offense','Stats','Profile','Abil','MineBox','Mine') { $ui[$n] = $win.FindName($n) }
$bc = New-Object System.Windows.Media.BrushConverter

function New-Badge([int]$t, [string]$suffix) {
    $b = New-Object System.Windows.Controls.Border
    $b.CornerRadius = 9; $b.Padding = '9,3'; $b.Margin = '0,0,5,5'
    $b.Background = $bc.ConvertFromString($TypeColors[$t])
    $tb = New-Object System.Windows.Controls.TextBlock
    $tb.Text = $TypeNames[$t] + $suffix; $tb.Foreground = [System.Windows.Media.Brushes]::White
    $tb.FontSize = 12; $tb.FontWeight = 'Bold'
    $b.Child = $tb; return $b
}
function Add-Line($panel, [string]$text, [string]$color) {
    $tb = New-Object System.Windows.Controls.TextBlock
    $tb.Text = $text; $tb.Foreground = $bc.ConvertFromString($color); $tb.FontSize = 12; $tb.TextWrapping = 'Wrap'; $tb.Margin = '0,1'
    [void]$panel.Children.Add($tb)
}
function Add-Stat($panel, [string]$label, [int]$v) {
    $g = New-Object System.Windows.Controls.Grid; $g.Margin = '0,2'
    foreach ($w in 64, 34, 1) { $cd = New-Object System.Windows.Controls.ColumnDefinition; $cd.Width = if ($w -eq 1) { New-Object System.Windows.GridLength 1, 'Star' } else { New-Object System.Windows.GridLength $w }; $g.ColumnDefinitions.Add($cd) }
    $l = New-Object System.Windows.Controls.TextBlock; $l.Text = $label; $l.Foreground = $bc.ConvertFromString('#8FA0C0'); $l.FontSize = 11
    $n = New-Object System.Windows.Controls.TextBlock; $n.Text = "$v"; $n.Foreground = [System.Windows.Media.Brushes]::White; $n.FontSize = 11; $n.FontWeight = 'Bold'
    [System.Windows.Controls.Grid]::SetColumn($n, 1)
    $bgb = New-Object System.Windows.Controls.Border; $bgb.Height = 7; $bgb.CornerRadius = 3; $bgb.Background = $bc.ConvertFromString('#26324A')
    $bar = New-Object System.Windows.Controls.Border; $bar.Height = 7; $bar.CornerRadius = 3; $bar.HorizontalAlignment = 'Left'
    $bar.Width = [Math]::Max(4, [Math]::Min(180, $v * 180 / 180))
    $col = if ($v -lt 50) { '#FF5A5A' } elseif ($v -lt 70) { '#FF9F43' } elseif ($v -lt 90) { '#FECA57' } elseif ($v -lt 110) { '#1DD1A1' } else { '#48DBFB' }
    $bar.Background = $bc.ConvertFromString($col)
    $cell = New-Object System.Windows.Controls.Grid; [void]$cell.Children.Add($bgb); [void]$cell.Children.Add($bar)
    [System.Windows.Controls.Grid]::SetColumn($cell, 2)
    [void]$g.Children.Add($l); [void]$g.Children.Add($n); [void]$g.Children.Add($cell)
    [void]$panel.Children.Add($g)
}
function Fmt([double]$m) { if ($m -eq 1.25) { ' x1.25' } elseif ($m -eq 4) { ' x4' } elseif ($m -eq 2) { ' x2' } elseif ($m -eq 0.25) { ' x1/4' } elseif ($m -eq 0.5) { ' x1/2' } else { '' } }

function Show-Mon($op, $me) {
    $i = Get-Info $op.Species
    $ui.Name.Text = $i.Name
    $ui.Lvl.Text = "Nv. $($op.Level)"
    $ui.Types.Children.Clear(); foreach ($t in $i.Types) { [void]$ui.Types.Children.Add((New-Badge $t '')) }
    $frac = if ($op.MaxHp -gt 0) { $op.Hp / $op.MaxHp } else { 0 }
    $ui.HpBar.Width = [Math]::Max(0, 300 * $frac)
    $ui.HpBar.Background = $bc.ConvertFromString($(if ($frac -gt 0.5) { '#4CD964' } elseif ($frac -gt 0.2) { '#FECA57' } else { '#FF5A5A' }))
    $ui.HpTxt.Text = "PS $($op.Hp) / $($op.MaxHp)"
    foreach ($p in 'Weak','Resist','Immune','Offense') { $ui[$p].Children.Clear() }
    $weak = @(); $res = @(); $immL = @()
    for ($a = 0; $a -lt 18; $a++) {
        $m = Get-Mult $a $i.Types $op.Ability
        if ($m -ge 2) { $weak += ,@($a, $m) } elseif ($m -eq 0) { $immL += $a } elseif ($m -lt 1) { $res += ,@($a, $m) } elseif ($m -gt 1) { $weak += ,@($a, $m) }
    }
    foreach ($w in ($weak | Sort-Object { -$_[1] })) { [void]$ui.Weak.Children.Add((New-Badge $w[0] (Fmt $w[1]))) }
    foreach ($r in ($res | Sort-Object { $_[1] })) { [void]$ui.Resist.Children.Add((New-Badge $r[0] (Fmt $r[1]))) }
    foreach ($z in $immL) { [void]$ui.Immune.Children.Add((New-Badge $z '')) }
    $ui.ImmHdr.Visibility = if ($immL.Count -gt 0) { 'Visible' } else { 'Collapsed' }
    $ui.Immune.Visibility = $ui.ImmHdr.Visibility
    $off = @{}
    foreach ($t in $i.Types) { for ($d = 0; $d -lt 18; $d++) { if ($Chart[$t,$d] -ge 2) { $off[$d] = 1 } } }
    if ($off.Count -eq 0) { Add-Line $ui.Offense 'Ningún tipo' '#8FA0C0' }
    foreach ($d in ($off.Keys | Sort-Object)) { [void]$ui.Offense.Children.Add((New-Badge $d '')) }

    $ui.Stats.Children.Clear()
    Add-Stat $ui.Stats 'PS' $i.HP; Add-Stat $ui.Stats 'Ataque' $i.Atk; Add-Stat $ui.Stats 'Defensa' $i.Def
    Add-Stat $ui.Stats 'At. Esp.' $i.SpA; Add-Stat $ui.Stats 'Def. Esp.' $i.SpD; Add-Stat $ui.Stats 'Velocidad' $i.Spe
    $bst = $i.HP + $i.Atk + $i.Def + $i.SpA + $i.SpD + $i.Spe
    Add-Line $ui.Stats "Total: $bst" '#7F8FB0'

    $ui.Profile.Children.Clear()
    $atkTxt = if ($i.Atk -ge $i.SpA * 1.2) { 'Atacante FÍSICO (Ataque)' } elseif ($i.SpA -ge $i.Atk * 1.2) { 'Atacante ESPECIAL (At. Esp.)' } else { 'Atacante MIXTO (físico y especial)' }
    $defTxt = if ($i.Def -ge $i.SpD * 1.15) { 'Aguanta mejor los golpes físicos: pégale con ataques ESPECIALES' } elseif ($i.SpD -ge $i.Def * 1.15) { 'Aguanta mejor los golpes especiales: pégale con ataques FÍSICOS' } else { 'Defensas equilibradas' }
    $spdTxt = if ($i.Spe -le 45) { 'Muy lento' } elseif ($i.Spe -le 65) { 'Lento' } elseif ($i.Spe -le 85) { 'Velocidad media' } elseif ($i.Spe -le 105) { 'Rápido' } else { 'Muy rápido' }
    $bulk = $i.HP + $i.Def + $i.SpD
    $bulkTxt = if ($bulk -ge 300) { 'Muy resistente' } elseif ($bulk -ge 220) { 'Resistencia normal' } else { 'Frágil' }
    Add-Line $ui.Profile $atkTxt '#FFB86B'
    Add-Line $ui.Profile $defTxt '#6BB8FF'
    Add-Line $ui.Profile "$spdTxt ($($i.Spe))  -  $bulkTxt" '#C8D2E8'

    if ($op.Ability -gt 0 -and $op.Ability -lt $AbilityNames.Count) {
        $ui.Abil.Text = "Habilidad: " + $AbilityNames[$op.Ability] + $(if ($AbilityMods.ContainsKey($op.Ability) -or $op.Ability -eq 25) { "  (ya incluida en las debilidades de arriba)" } else { '' })
    } else {
        $ab = @(); foreach ($x in $i.Abil[0], $i.Abil[1]) { if ($x -gt 0 -and $ab -notcontains $AbilityNames[$x]) { $ab += $AbilityNames[$x] } }
        $hid = if ($i.Abil[2] -gt 0) { "  (oculta: $($AbilityNames[$i.Abil[2]]))" } else { '' }
        $ui.Abil.Text = "Habilidad posible: " + ($ab -join ' / ') + $hid
    }

    if ($me) {
        $mi = Get-Info $me.Species
        $best = 0.0; foreach ($t in $mi.Types) { $best = [Math]::Max($best, (Get-Mult $t $i.Types $op.Ability)) }
        $worst = 0.0; foreach ($t in $i.Types) { $worst = [Math]::Max($worst, (Get-Mult $t $mi.Types $me.Ability)) }
        $l1 = if ($best -ge 2) { "Tus ataques de tipo $(($mi.Types | ForEach-Object { $TypeNames[$_] }) -join '/') le hacen x$best." } elseif ($best -eq 0) { "Tus ataques de tu tipo NO le hacen nada." } elseif ($best -lt 1) { "Tus ataques de tu tipo le hacen poco." } else { "Tus ataques de tu tipo le hacen daño normal." }
        $l2 = if ($worst -ge 2) { "Cuidado: sus ataques de su tipo te hacen x$worst." } elseif ($worst -eq 0) { "Sus ataques de su tipo NO te hacen nada." } elseif ($worst -lt 1) { "Sus ataques de su tipo te hacen poco." } else { "Sus ataques de su tipo te hacen daño normal." }
        $l3 = ''
        if ($AbilityMods.ContainsKey($me.Ability)) {
            $imm = @($AbilityMods[$me.Ability].Keys | Where-Object { $AbilityMods[$me.Ability][$_] -eq 0 } | ForEach-Object { $TypeNames[$_] })
            if ($imm.Count -gt 0) { $l3 = " Tu habilidad $($AbilityNames[$me.Ability]) te hace inmune a: $($imm -join ', ')." }
        }
        $ui.Mine.Text = "Tu $($mi.Name): $l1 $l2$l3"
        $ui.MineBox.Visibility = 'Visible'
    } else { $ui.MineBox.Visibility = 'Collapsed' }
}

# ---------------- Bucle ----------------
$azPath = if ($AzaharExe) { $AzaharExe } else { (Join-Path $BaseDir "tools\azahar\azahar.exe") }
$script:seenAz = $false; $script:noAzTicks = 0; $script:lastKey = ''; $script:idle = 0
function Get-Azahar { Get-Process azahar -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $azPath -and $_.MainWindowHandle -ne 0 } | Select-Object -First 1 }

function Place($az) {
    $r = New-Object Bp+RECT
    if (-not [Bp]::GetWindowRect($az.MainWindowHandle, [ref]$r)) { return }
    $src = [System.Windows.PresentationSource]::FromVisual($win)
    $sx = 1.0; $sy = 1.0
    if ($src) { $sx = $src.CompositionTarget.TransformToDevice.M11; $sy = $src.CompositionTarget.TransformToDevice.M22 }
    $L = $r.L / $sx; $R = $r.R / $sx; $T = $r.T / $sy
    $scrW = [System.Windows.SystemParameters]::VirtualScreenLeft + [System.Windows.SystemParameters]::VirtualScreenWidth
    $x = if ($R + $win.ActualWidth + 4 -le $scrW) { $R + 4 } elseif ($L - $win.ActualWidth - 4 -ge [System.Windows.SystemParameters]::VirtualScreenLeft) { $L - $win.ActualWidth - 4 } else { $R - $win.ActualWidth - 8 }
    $win.Left = $x; $win.Top = $T + 30
}

$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromMilliseconds(700)
$timer.Add_Tick({
    try {
        $az = Get-Azahar
        if (-not $az) {
            $script:noAzTicks++
            if ($script:seenAz -and $script:noAzTicks -gt 6) { $win.Close() }
            if ($script:noAzTicks -gt 200) { $win.Close() }   # nunca se abrio Azahar
            $win.Hide(); return
        }
        $script:seenAz = $true; $script:noAzTicks = 0
        if ([Bp]::IsIconic($az.MainWindowHandle)) { $win.Hide(); return }
        $mons = [Bp]::Poll()
        if ($mons) {
            $key = "$($mons[0].Species)|$($mons[0].Hp)|$($mons[0].Level)|$($mons[0].Ability)|$($mons[1].Species)|$($mons[1].Ability)"
            $changed = ($key -ne $script:lastKey)
            if ($changed) { Show-Mon $mons[0] $mons[1]; $script:lastKey = $key }
            if (-not $win.IsVisible) { $win.Show() }
            Place $az
            if ($changed -and $Snapshot) {
                $win.UpdateLayout(); $c = $win.Content
                $bmp = New-Object System.Windows.Media.Imaging.RenderTargetBitmap ([int]$c.ActualWidth), ([int]$c.ActualHeight), 96, 96, ([System.Windows.Media.PixelFormats]::Pbgra32)
                $bmp.Render($c); $enc = New-Object System.Windows.Media.Imaging.PngBitmapEncoder
                $enc.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($bmp))
                $fs = [IO.File]::Create($Snapshot); $enc.Save($fs); $fs.Close()
                Add-Content ($Snapshot + '.log') ("{0:HH:mm:ss} {1} | pos {2},{3}" -f (Get-Date), $key, $win.Left, $win.Top)
            }
        } else {
            $script:lastKey = ''
            if ($win.IsVisible) { $win.Hide() }
        }
    } catch { }
})

if ($Demo) {
    $o = New-Object Bp+Mon; $o.Species = $DemoSpecies; $o.Level = 21; $o.MaxHp = 65; $o.Hp = 40; $o.Ability = $DemoAbility
    $m = New-Object Bp+Mon; $m.Species = $DemoMine; $m.Level = 25; $m.MaxHp = 68; $m.Hp = 62; $m.Ability = $DemoMineAbility
    Show-Mon $o $m
    if ($Snapshot) {
        $root = $win.Content; $win.Content = $null
        $root.Measure((New-Object System.Windows.Size 330, ([double]::PositiveInfinity)))
        $root.Arrange((New-Object System.Windows.Rect 0, 0, 330, $root.DesiredSize.Height))
        $bmp = New-Object System.Windows.Media.Imaging.RenderTargetBitmap 330, ([int]$root.DesiredSize.Height), 96, 96, ([System.Windows.Media.PixelFormats]::Pbgra32)
        $bmp.Render($root)
        $enc = New-Object System.Windows.Media.Imaging.PngBitmapEncoder
        $enc.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($bmp))
        $fs = [IO.File]::Create($Snapshot); $enc.Save($fs); $fs.Close()
        exit 0
    }
    $win.Left = 100; $win.Top = 100
    $win.Add_MouseLeftButtonDown({ $win.Close() })
    [void]$win.ShowDialog()
    exit 0
}

$createdNew = $false
$mutex = New-Object System.Threading.Mutex($true, "PokemonY_BattlePanel", [ref]$createdNew)
if (-not $createdNew) { exit 0 }   # ya hay un panel abierto

$timer.Start()
$app = New-Object System.Windows.Application
$app.ShutdownMode = 'OnExplicitShutdown'
$win.Add_Closed({ $timer.Stop(); $app.Shutdown() })
[void]$app.Run()
