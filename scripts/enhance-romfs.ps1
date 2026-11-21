# ==============================================================================
#  Pokemon Y (USA v1.0) - Mejoras Pro de RomFS (100% PowerShell + C# inline)
#    1. IA Experta Maxima (AI |= 0x07) en los 784 entrenadores/gimnasios (a/0/3/8)
#    2. Caramelo Raro a 10 pokedolares en tiendas (a/2/2/0 extraido del .cci)
#    3. Regulacion de 3as Evoluciones: bloquea 3as evoluciones y legendarios
#       (BST >= 580) en las 25 rutas/cuevas ANTERIORES al 4o Gimnasio, y las
#       desbloquea al 100% a partir del 4o Gimnasio (Ruta 13 en adelante)!
#    4. Evoluciones por intercambio -> por nivel (a/2/1/5): Onix, Scyther, Porygon,
#       Seadra, Feebas, Clamperl, Karrablast/Shelmet, Spritzee, Swirlix... sin objeto ni cambio
#    5. Sin legendarios/singulares en ningun encuentro salvaje (a/0/1/2, todas las zonas)
# ==============================================================================

param(
    [switch]$SkipAI,
    [switch]$SkipCandyPrice,
    [switch]$SkipEvoGate,
    [switch]$SkipTradeEvo,
    [switch]$SkipNoLegend
)

$ErrorActionPreference = "Stop"
$BaseDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$TitleId = "0004000000055E00"
$RomfsDir = Join-Path $BaseDir "tools\azahar\user\load\mods\$TitleId\romfs"
$RomsDir  = Join-Path $BaseDir "roms"

if (-not (Test-Path $RomfsDir)) {
    throw "No existe la carpeta romfs del mod en: $RomfsDir. Ejecuta primero scripts\randomize-auto.ps1"
}

$csharp = @"
using System;
using System.Collections.Generic;
using System.IO;
using System.Text;

public static class PokemonYRomfsEnhancer
{
    public static byte[] Lz11Decompress(byte[] data)
    {
        if (data.Length < 4 || data[0] != 0x11) return data;
        int size = data[1] | (data[2] << 8) | (data[3] << 16);
        byte[] dst = new byte[size];
        int srcPos = 4, dstPos = 0;
        while (dstPos < size && srcPos < data.Length)
        {
            byte flags = data[srcPos++];
            for (int bit = 7; bit >= 0 && dstPos < size && srcPos < data.Length; bit--)
            {
                if ((flags & (1 << bit)) == 0)
                {
                    dst[dstPos++] = data[srcPos++];
                }
                else
                {
                    byte b1 = data[srcPos++];
                    int ind = b1 >> 4;
                    int len, disp;
                    if (ind == 0)
                    {
                        byte b2 = data[srcPos++], b3 = data[srcPos++];
                        len = (((b1 & 0xF) << 4) | (b2 >> 4)) + 0x11;
                        disp = (((b2 & 0xF) << 8) | b3) + 1;
                    }
                    else if (ind == 1)
                    {
                        byte b2 = data[srcPos++], b3 = data[srcPos++], b4 = data[srcPos++];
                        len = (((b1 & 0xF) << 12) | (b2 << 4) | (b3 >> 4)) + 0x111;
                        disp = (((b3 & 0xF) << 8) | b4) + 1;
                    }
                    else
                    {
                        byte b2 = data[srcPos++];
                        len = ind + 1;
                        disp = (((b1 & 0xF) << 8) | b2) + 1;
                    }
                    for (int k = 0; k < len && dstPos < size; k++)
                    {
                        dst[dstPos] = dst[dstPos - disp];
                        dstPos++;
                    }
                }
            }
        }
        return dst;
    }

    // Real LZ11 encoder (hash chains + greedy match, 2/3/4-byte token forms).
    // Output size stays close to the original game data, so the patched GARC
    // entries do not grow (literal-only output doubled them and could overflow
    // fixed-size buffers in the game's zone loader).
    public static byte[] Lz11CompressSafe(byte[] raw)
    {
        int n = raw.Length;
        var outp = new MemoryStream(n);
        outp.WriteByte(0x11);
        outp.WriteByte((byte)(n & 0xFF));
        outp.WriteByte((byte)((n >> 8) & 0xFF));
        outp.WriteByte((byte)((n >> 16) & 0xFF));

        const int WIN = 0x1000, MAXLEN = 0x10110, MAXCHAIN = 256;
        var head = new int[1 << 16];
        for (int k = 0; k < head.Length; k++) head[k] = -1;
        var prev = new int[n > 0 ? n : 1];

        Func<int, int> hash = p => ((raw[p] << 8) ^ (raw[p + 1] << 4) ^ raw[p + 2]) & 0xFFFF;
        Action<int> insert = p =>
        {
            if (p + 2 < n) { int h = hash(p); prev[p] = head[h]; head[h] = p; }
        };

        int pos = 0;
        var block = new MemoryStream();
        while (pos < n)
        {
            int flags = 0;
            block.SetLength(0);
            for (int bit = 7; bit >= 0 && pos < n; bit--)
            {
                int bestLen = 0, bestDisp = 0;
                if (pos + 2 < n)
                {
                    int cand = head[hash(pos)];
                    int chain = 0;
                    int maxHere = Math.Min(MAXLEN, n - pos);
                    while (cand >= 0 && pos - cand <= WIN && chain++ < MAXCHAIN)
                    {
                        int l = 0;
                        while (l < maxHere && raw[cand + l] == raw[pos + l]) l++;
                        if (l > bestLen) { bestLen = l; bestDisp = pos - cand; if (l == maxHere) break; }
                        cand = prev[cand];
                    }
                }
                if (bestLen >= 3)
                {
                    flags |= 1 << bit;
                    int d1 = bestDisp - 1;
                    if (bestLen <= 0x10)
                    {
                        block.WriteByte((byte)(((bestLen - 1) << 4) | (d1 >> 8)));
                        block.WriteByte((byte)(d1 & 0xFF));
                    }
                    else if (bestLen <= 0x110)
                    {
                        int l = bestLen - 0x11;
                        block.WriteByte((byte)(l >> 4));
                        block.WriteByte((byte)(((l & 0xF) << 4) | (d1 >> 8)));
                        block.WriteByte((byte)(d1 & 0xFF));
                    }
                    else
                    {
                        int l = bestLen - 0x111;
                        block.WriteByte((byte)(0x10 | (l >> 12)));
                        block.WriteByte((byte)((l >> 4) & 0xFF));
                        block.WriteByte((byte)(((l & 0xF) << 4) | (d1 >> 8)));
                        block.WriteByte((byte)(d1 & 0xFF));
                    }
                    for (int k = 0; k < bestLen; k++) insert(pos + k);
                    pos += bestLen;
                }
                else
                {
                    block.WriteByte(raw[pos]);
                    insert(pos);
                    pos++;
                }
            }
            outp.WriteByte((byte)flags);
            block.WriteTo(outp);
        }
        // Pad to 4 bytes like Nintendo's encoder
        while ((outp.Length & 3) != 0) outp.WriteByte(0);
        return outp.ToArray();
    }

    public static List<byte[]> ReadGarcSimple(string path, out byte[] headerPrefix, out uint[] fatbBits)
    {
        byte[] d = File.ReadAllBytes(path);
        int hl = BitConverter.ToInt32(d, 4);
        int doff = BitConverter.ToInt32(d, 0x10);
        int flen = BitConverter.ToInt32(d, hl + 4);
        int fb = hl + flen;
        int fatoCnt = BitConverter.ToUInt16(d, hl + 8);
        headerPrefix = new byte[hl];
        Array.Copy(d, 0, headerPrefix, 0, hl);
        fatbBits = new uint[fatoCnt];
        var list = new List<byte[]>(fatoCnt);
        for (int i = 0; i < fatoCnt; i++)
        {
            int fatoOff = BitConverter.ToInt32(d, hl + 12 + i * 4);
            int p = fb + 12 + fatoOff;
            uint bits = BitConverter.ToUInt32(d, p);
            fatbBits[i] = bits;
            int s = BitConverter.ToInt32(d, p + 4);
            int e = BitConverter.ToInt32(d, p + 8);
            int sz = BitConverter.ToInt32(d, p + 12);
            byte[] entry = new byte[sz];
            Array.Copy(d, doff + s, entry, 0, Math.Min(sz, e - s));
            list.Add(entry);
        }
        return list;
    }

    public static void WriteGarcSimple(string path, byte[] origHeader, uint[] fatbBits, List<byte[]> entries)
    {
        int n = entries.Count;
        int hl = origHeader.Length; // 0x1C for GARC v4
        int fatoLen = 12 + n * 4;
        int fatbLen = 12 + n * 16;
        int fimbHdrLen = 12;
        int dataOff = hl + fatoLen + fatbLen + fimbHdrLen;

        int curOff = 0;
        int largest = 0;
        int[] starts = new int[n];
        int[] ends = new int[n];
        int[] sizes = new int[n];
        for (int i = 0; i < n; i++)
        {
            int sz = entries[i].Length;
            if (sz > largest) largest = sz;
            int padded = (sz + 3) & ~3;
            starts[i] = curOff;
            ends[i] = curOff + padded;
            sizes[i] = sz;
            curOff += padded;
        }
        int totalSize = dataOff + curOff;

        using (var fs = new FileStream(path, FileMode.Create, FileAccess.Write))
        using (var bw = new BinaryWriter(fs))
        {
            byte[] hdr = (byte[])origHeader.Clone();
            Array.Copy(BitConverter.GetBytes(dataOff), 0, hdr, 0x10, 4);
            Array.Copy(BitConverter.GetBytes(totalSize), 0, hdr, 0x14, 4);
            Array.Copy(BitConverter.GetBytes(largest), 0, hdr, 0x18, 4);
            bw.Write(hdr);

            // FATO
            bw.Write(Encoding.ASCII.GetBytes("OTAF"));
            bw.Write(fatoLen);
            bw.Write((ushort)n);
            bw.Write((ushort)0xFFFF);
            for (int i = 0; i < n; i++) bw.Write(i * 16);

            // FATB
            bw.Write(Encoding.ASCII.GetBytes("BTAF"));
            bw.Write(fatbLen);
            bw.Write(n);
            for (int i = 0; i < n; i++)
            {
                bw.Write(fatbBits[i]);
                bw.Write(starts[i]);
                bw.Write(ends[i]);
                bw.Write(sizes[i]);
            }

            // FIMB
            bw.Write(Encoding.ASCII.GetBytes("BMIF"));
            bw.Write(fimbHdrLen);
            bw.Write(curOff);

            for (int i = 0; i < n; i++)
            {
                bw.Write(entries[i]);
                int pad = ends[i] - starts[i] - sizes[i];
                for (int k = 0; k < pad; k++) bw.Write((byte)0xFF);
            }
        }
    }

    // 1. Upgrade Trainer AI to Expert (AI |= 0x07) in a/0/3/8
    public static int PatchTrainerAI(string trdataPath)
    {
        byte[] d = File.ReadAllBytes(trdataPath);
        int hl = BitConverter.ToInt32(d, 4);
        int doff = BitConverter.ToInt32(d, 0x10);
        int flen = BitConverter.ToInt32(d, hl + 4);
        int fb = hl + flen;
        int cnt = BitConverter.ToInt32(d, fb + 8);
        int patched = 0;
        for (int i = 1; i < cnt; i++)
        {
            int fatoOff = BitConverter.ToInt32(d, hl + 12 + i * 4);
            int p = fb + 12 + fatoOff;
            int s = BitConverter.ToInt32(d, p + 4);
            int sz = BitConverter.ToInt32(d, p + 12);
            if (sz >= 16)
            {
                int aiOff = doff + s + 12;
                uint ai = BitConverter.ToUInt32(d, aiOff);
                uint newAi = ai | 0x07u; // Basic | EvaluateAttack | Expert
                if (newAi != ai)
                {
                    Array.Copy(BitConverter.GetBytes(newAi), 0, d, aiOff, 4);
                    patched++;
                }
            }
        }
        File.WriteAllBytes(trdataPath, d);
        return patched;
    }

    // 2. Extract a/2/2/0 (ItemData) from .cci RomFS and set Rare Candy (#50) price = 1 (10 pokedollars)
    public static bool ExtractAndPatchRareCandyPrice(string cciPath, string outItemDataPath)
    {
        using (var fs = new FileStream(cciPath, FileMode.Open, FileAccess.Read, FileShare.Read))
        using (var br = new BinaryReader(fs))
        {
            fs.Seek(0x120, SeekOrigin.Begin);
            long p0Off = (long)br.ReadUInt32() * 0x200;
            fs.Seek(p0Off + 0x1B0, SeekOrigin.Begin);
            long romfsOff = p0Off + (long)br.ReadUInt32() * 0x200;
            long lvl3 = romfsOff + 0x1000;
            fs.Seek(lvl3, SeekOrigin.Begin);
            uint hdrLen = br.ReadUInt32();
            uint dho = br.ReadUInt32(), dhl = br.ReadUInt32();
            uint dmo = br.ReadUInt32(), dml = br.ReadUInt32();
            uint fho = br.ReadUInt32(), fhl = br.ReadUInt32();
            uint fmo = br.ReadUInt32(), fml = br.ReadUInt32();
            uint dataOff = br.ReadUInt32();

            fs.Seek(lvl3 + dmo, SeekOrigin.Begin);
            byte[] dirMeta = br.ReadBytes((int)dml);
            fs.Seek(lvl3 + fmo, SeekOrigin.Begin);
            byte[] fileMeta = br.ReadBytes((int)fml);

            string[] dirs = new[] { "a", "2", "2" };
            int curDir = 0;
            foreach (string dn in dirs)
            {
                int child = BitConverter.ToInt32(dirMeta, curDir + 8);
                int found = -1;
                while (child != -1)
                {
                    int sib = BitConverter.ToInt32(dirMeta, child + 4);
                    int nlen = BitConverter.ToInt32(dirMeta, child + 20);
                    string name = Encoding.Unicode.GetString(dirMeta, child + 24, nlen);
                    if (name == dn) { found = child; break; }
                    child = sib;
                }
                if (found == -1) return false;
                curDir = found;
            }

            int fent = BitConverter.ToInt32(dirMeta, curDir + 12);
            long targetOff = -1, targetSz = -1;
            while (fent != -1)
            {
                int sib = BitConverter.ToInt32(fileMeta, fent + 4);
                long foff = BitConverter.ToInt64(fileMeta, fent + 8);
                long fsz = BitConverter.ToInt64(fileMeta, fent + 16);
                int nlen = BitConverter.ToInt32(fileMeta, fent + 28);
                string name = Encoding.Unicode.GetString(fileMeta, fent + 32, nlen);
                if (name == "0") { targetOff = lvl3 + dataOff + foff; targetSz = fsz; break; }
                fent = sib;
            }
            if (targetOff < 0) return false;

            fs.Seek(targetOff, SeekOrigin.Begin);
            byte[] idata = br.ReadBytes((int)targetSz);

            int hl = BitConverter.ToInt32(idata, 4);
            int doff = BitConverter.ToInt32(idata, 0x10);
            int flen = BitConverter.ToInt32(idata, hl + 4);
            int fb = hl + flen;
            int fatoOff50 = BitConverter.ToInt32(idata, hl + 12 + 50 * 4);
            int s50 = BitConverter.ToInt32(idata, fb + 12 + fatoOff50 + 4);
            // Set price word = 1 (1 * 10 = 10 pokedollars!)
            idata[doff + s50] = 0x01;
            idata[doff + s50 + 1] = 0x00;

            Directory.CreateDirectory(Path.GetDirectoryName(outItemDataPath));
            File.WriteAllBytes(outItemDataPath, idata);
            return true;
        }
    }

    // 4. Evoluciones por intercambio -> por nivel (a/2/1/5, en el sitio, mismo tamano).
    //    UPR FVX ya pasa los intercambios simples a nivel 37, pero deja los de objeto como
    //    "subir de nivel con el objeto equipado" (metodos 19/20) y Karrablast/Shelmet como
    //    "subir de nivel con el otro en el equipo" (metodo 22). Aqui se pasan a nivel normal.
    //    Entradas: 8 x (u16 metodo, u16 parametro, u16 especie destino). Metodo 4 = nivel.
    public static int PatchTradeEvolutions(string evoPath)
    {
        // objeto de intercambio -> nivel de evolucion
        var itemLevel = new Dictionary<int, int> {
            {221, 37}, // Roca del Rey   (Poliwhirl -> Politoed)
            {233, 30}, // Revest. Metalico (Onix -> Steelix, Scyther -> Scizor)
            {235, 45}, // Escama Dragon  (Seadra -> Kingdra)
            {252, 30}, // Mejora         (Porygon -> Porygon2)
            {324, 45}, // Disco Extrano  (Porygon2 -> Porygon-Z)
            {537, 30}, // Escama Bella   (Feebas -> Milotic)
            {325, 45}, // Tela Terrible  (Dusclops -> Dusknoir)
            {322, 45}, // Electrizador   (Electabuzz -> Electivire)
            {323, 45}, // Magmatizador   (Magmar -> Magmortar)
            {321, 50}, // Protector      (Rhydon -> Rhyperior)
            {647, 30}, // Saquito Fragante (Spritzee -> Aromatisse)
            {646, 30}, // Dulce de Nata  (Swirlix -> Slurpuff)
            {226, 30}, // Diente Marino  (Clamperl -> Huntail, macho)
            {227, 30}, // Escama Marina  (Clamperl -> Gorebyss, hembra)
        };
        byte[] d = File.ReadAllBytes(evoPath);
        int hl = BitConverter.ToInt32(d, 4);
        int doff = BitConverter.ToInt32(d, 0x10);
        int flen = BitConverter.ToInt32(d, hl + 4);
        int fb = hl + flen;
        int cnt = BitConverter.ToUInt16(d, hl + 8);
        int changed = 0;
        for (int sp = 1; sp < cnt && sp <= 721; sp++)
        {
            int p = fb + 12 + BitConverter.ToInt32(d, hl + 12 + sp * 4);
            int s = doff + BitConverter.ToInt32(d, p + 4);
            int sz = BitConverter.ToInt32(d, p + 12);
            int slots = Math.Min(8, sz / 6);
            var outList = new List<int[]>();
            var seen = new HashSet<int>();
            bool any = false;
            for (int k = 0; k < slots; k++)
            {
                int o = s + k * 6;
                int m = BitConverter.ToUInt16(d, o), prm = BitConverter.ToUInt16(d, o + 2), tgt = BitConverter.ToUInt16(d, o + 4);
                if (m == 0) continue;
                bool conv = true;
                if ((m == 19 || m == 20) && itemLevel.ContainsKey(prm)) {
                    m = (sp == 366) ? (prm == 226 ? 23 : 24) : 4;     // Clamperl: macho / hembra
                    prm = itemLevel[prm];
                } else if (m == 22 && ((sp == 588 && prm == 616) || (sp == 616 && prm == 588))) {
                    m = 4; prm = 30;                                   // Karrablast / Shelmet
                } else if (m == 5 || m == 6 || m == 7) {
                    m = 4; prm = 37;                                   // por si quedara algun intercambio puro
                } else conv = false;
                if (conv) { any = true; changed++; }
                if (conv && seen.Contains(tgt)) continue;              // duplicado dia/noche -> fuera
                seen.Add(tgt);
                outList.Add(new int[] { m, prm, tgt });
            }
            if (!any) continue;
            for (int k = 0; k < slots; k++)                            // reescribir compactado
            {
                int o = s + k * 6;
                int m = 0, prm = 0, tgt = 0;
                if (k < outList.Count) { m = outList[k][0]; prm = outList[k][1]; tgt = outList[k][2]; }
                d[o] = (byte)m; d[o + 1] = (byte)(m >> 8); d[o + 2] = (byte)prm; d[o + 3] = (byte)(prm >> 8);
                d[o + 4] = (byte)tgt; d[o + 5] = (byte)(tgt >> 8);
            }
        }
        if (changed > 0) File.WriteAllBytes(evoPath, d);
        return changed;
    }

    // 3. Regulate Stage-3 evolutions & 580+ BST legendaries before Gym 4 in a/0/1/2
    public static int PatchPreGym4Encounters(string encPath, string evoPath, string personalPath)
    {
        byte[] tmpH; uint[] tmpB;
        var evos = ReadGarcSimple(evoPath, out tmpH, out tmpB);
        var pers = ReadGarcSimple(personalPath, out tmpH, out tmpB);

        // Build pre-evo map & Stage-3 -> Stage-2 map
        var preEvo = new Dictionary<int, int>();
        for (int sp = 1; sp <= 721 && sp < evos.Count; sp++)
        {
            byte[] b = evos[sp];
            for (int k = 0; k < 8 && (k + 1) * 6 <= b.Length; k++)
            {
                int method = BitConverter.ToUInt16(b, k * 6);
                int target = BitConverter.ToUInt16(b, k * 6 + 4);
                if (method != 0 && target >= 1 && target <= 721 && !preEvo.ContainsKey(target))
                    preEvo[target] = sp;
            }
        }
        var stage3To2 = new Dictionary<int, int>();
        for (int sp = 1; sp <= 721; sp++)
        {
            if (preEvo.ContainsKey(sp) && preEvo.ContainsKey(preEvo[sp]))
                stage3To2[sp] = preEvo[sp];
        }

        // Identify high-BST legendaries/ubers (>= 580 BST) and build safe Stage 1/2 pool
        var highBst = new HashSet<int>();
        var safePool = new List<int>();
        for (int sp = 1; sp <= 721 && sp < pers.Count; sp++)
        {
            byte[] p = pers[sp];
            if (p.Length < 6) continue;
            int bst = p[0] + p[1] + p[2] + p[3] + p[4] + p[5];
            if (bst >= 580) highBst.Add(sp);
            else if (!stage3To2.ContainsKey(sp)) safePool.Add(sp);
        }

        // Exact Kalos map indices BEFORE Gym 4 (Routes 2-12, Santalune Forest, Caves, Azure Bay, etc.)
        // From Gym 4 onwards (Route 13+, Frost Cavern, Lost Hotel, Terminus Cave, Victory Road) ALL Stage-3 unlock!
        var preGym4Maps = new HashSet<int> {
            45, 157, 172, 259, 260, 261, 262, 263, 264, 266, 267, 268, 269, 270,
            285, 286, 302, 303, 304, 305, 306, 307, 308, 334, 357
        };

        byte[] encHdr; uint[] encBits;
        var encEntries = ReadGarcSimple(encPath, out encHdr, out encBits);
        int replacedSlots = 0;

        foreach (int mapIdx in preGym4Maps)
        {
            if (mapIdx >= encEntries.Count - 1) continue;
            byte[] raw = encEntries[mapIdx];
            bool wasLz = (raw.Length >= 4 && raw[0] == 0x11);
            byte[] dec = wasLz ? Lz11Decompress(raw) : (byte[])raw.Clone();
            if (dec.Length < 0x18) continue;
            int encOff = BitConverter.ToInt32(dec, 0x10) + 0x10;
            if (dec.Length - encOff < 0x178) continue;

            bool changed = false;
            for (int k = 0; k < 94; k++)
            {
                // Keep Super Rod slots (76..78) unlocked since Super Rod is obtained post-Gym 4!
                if (k >= 76 && k <= 78) continue;
                int slotOff = encOff + k * 4;
                ushort spRaw = BitConverter.ToUInt16(dec, slotOff);
                int sp = spRaw & 0x7FF;
                int formBits = spRaw & 0xF800;
                if (sp <= 0 || sp > 721) continue;

                int newSp = sp;
                if (stage3To2.ContainsKey(sp))
                {
                    newSp = stage3To2[sp];
                    formBits = 0;
                }
                else if (highBst.Contains(sp) && safePool.Count > 0)
                {
                    // Deterministic replacement based on mapIdx + slot + species (preserves seed uniqueness!)
                    int pick = ((mapIdx * 131 + k * 37 + sp * 17) & 0x7FFFFFFF) % safePool.Count;
                    newSp = safePool[pick];
                    formBits = 0;
                }

                if (newSp != sp)
                {
                    ushort val = (ushort)(newSp | formBits);
                    dec[slotOff] = (byte)(val & 0xFF);
                    dec[slotOff + 1] = (byte)((val >> 8) & 0xFF);
                    changed = true;
                    replacedSlots++;
                }
            }
            // Recomprimir siempre las zonas reguladas (aunque no cambie ningun slot):
            // repara GARCs generados antes con el compresor "solo literales" que inflaba las entradas.
            if (changed || wasLz)
            {
                byte[] packed = wasLz ? Lz11CompressSafe(dec) : dec;
                if (wasLz)
                {
                    // Round-trip check: never write an entry the game could not decode identically
                    byte[] back = Lz11Decompress(packed);
                    if (back.Length != dec.Length) throw new InvalidOperationException("LZ11 round-trip size mismatch en zona " + mapIdx);
                    for (int q = 0; q < dec.Length; q++)
                        if (back[q] != dec[q]) throw new InvalidOperationException("LZ11 round-trip mismatch en zona " + mapIdx + " offset " + q);
                }
                encEntries[mapIdx] = packed;
            }
        }

        WriteGarcSimple(encPath, encHdr, encBits, encEntries);
        return replacedSlots;
    }

    // 5. Sin legendarios ni singulares en ningun encuentro salvaje (todas las zonas de a/0/1/2).
    //    Los estaticos de la historia (Xerneas, Zygarde, Mewtwo, aves) no estan aqui y no se tocan.
    //    Sustituto determinista (zona + hueco + especie) de un Pokemon no legendario; en las zonas
    //    previas al 4o gimnasio el sustituto respeta la regulacion (sin 3as etapas ni BST >= 580).
    public static readonly int[] Legendaries = {
        144,145,146,150,151, 243,244,245,249,250,251, 377,378,379,380,381,382,383,384,385,386,
        480,481,482,483,484,485,486,487,488,489,490,491,492,493,494,
        638,639,640,641,642,643,644,645,646,647,648,649, 716,717,718,719,720,721 };

    public static int PatchNoWildLegendaries(string encPath, string evoPath, string personalPath)
    {
        byte[] tmpH; uint[] tmpB;
        var evos = ReadGarcSimple(evoPath, out tmpH, out tmpB);
        var pers = ReadGarcSimple(personalPath, out tmpH, out tmpB);
        var legend = new HashSet<int>(Legendaries);
        var preEvo = new Dictionary<int, int>();
        for (int sp = 1; sp <= 721 && sp < evos.Count; sp++)
            for (int k = 0; k < 8 && (k + 1) * 6 <= evos[sp].Length; k++)
            {
                int m = BitConverter.ToUInt16(evos[sp], k * 6), t = BitConverter.ToUInt16(evos[sp], k * 6 + 4);
                if (m != 0 && t >= 1 && t <= 721 && !preEvo.ContainsKey(t)) preEvo[t] = sp;
            }
        var poolAll = new List<int>(); var poolEarly = new List<int>();
        for (int sp = 1; sp <= 721 && sp < pers.Count; sp++)
        {
            if (legend.Contains(sp) || pers[sp].Length < 6) continue;
            poolAll.Add(sp);
            int bst = pers[sp][0] + pers[sp][1] + pers[sp][2] + pers[sp][3] + pers[sp][4] + pers[sp][5];
            bool stage3 = preEvo.ContainsKey(sp) && preEvo.ContainsKey(preEvo[sp]);
            if (bst < 580 && !stage3) poolEarly.Add(sp);
        }
        var preGym4Maps = new HashSet<int> {
            45, 157, 172, 259, 260, 261, 262, 263, 264, 266, 267, 268, 269, 270,
            285, 286, 302, 303, 304, 305, 306, 307, 308, 334, 357 };

        byte[] encHdr; uint[] encBits;
        var encEntries = ReadGarcSimple(encPath, out encHdr, out encBits);
        int replaced = 0;
        for (int mapIdx = 0; mapIdx < encEntries.Count - 1; mapIdx++)
        {
            byte[] raw = encEntries[mapIdx];
            bool wasLz = (raw.Length >= 4 && raw[0] == 0x11);
            byte[] dec = wasLz ? Lz11Decompress(raw) : (byte[])raw.Clone();
            if (dec.Length < 0x18) continue;
            int encOff = BitConverter.ToInt32(dec, 0x10) + 0x10;
            if (encOff < 0x14 || dec.Length - encOff < 0x178) continue;
            var pool = preGym4Maps.Contains(mapIdx) ? poolEarly : poolAll;
            bool changed = false;
            for (int k = 0; k < 94; k++)
            {
                int slotOff = encOff + k * 4;
                int sp = BitConverter.ToUInt16(dec, slotOff) & 0x7FF;
                if (!legend.Contains(sp)) continue;
                int newSp = pool[((mapIdx * 131 + k * 37 + sp * 17) & 0x7FFFFFFF) % pool.Count];
                dec[slotOff] = (byte)(newSp & 0xFF);
                dec[slotOff + 1] = (byte)((newSp >> 8) & 0xFF);   // forma 0
                changed = true; replaced++;
            }
            if (!changed) continue;
            byte[] packed = wasLz ? Lz11CompressSafe(dec) : dec;
            if (wasLz)
            {
                byte[] back = Lz11Decompress(packed);
                if (back.Length != dec.Length) throw new InvalidOperationException("LZ11 round-trip size mismatch en zona " + mapIdx);
                for (int q = 0; q < dec.Length; q++)
                    if (back[q] != dec[q]) throw new InvalidOperationException("LZ11 round-trip mismatch en zona " + mapIdx);
            }
            encEntries[mapIdx] = packed;
        }
        if (replaced > 0) WriteGarcSimple(encPath, encHdr, encBits, encEntries);
        return replaced;
    }
}
"@

Add-Type -TypeDefinition $csharp -Language CSharp

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   APLICANDO MEJORAS PRO EN ROMFS (POKEMON Y)" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

if (-not $SkipAI) {
    $trPath = Join-Path $RomfsDir "a\0\3\8"
    if (Test-Path $trPath) {
        $n = [PokemonYRomfsEnhancer]::PatchTrainerAI($trPath)
        Write-Host "  [OK] IA Experta Maxima (0x07) aplicada a $n entrenadores/gimnasios en a/0/3/8." -ForegroundColor Green
    } else {
        Write-Host "  [AVISO] No se encontro a/0/3/8 en romfs." -ForegroundColor Yellow
    }
}

if (-not $SkipCandyPrice) {
    $cci = Get-ChildItem -Path $RomsDir -File | Where-Object { $_.Extension -in ".cci", ".3ds" } | Select-Object -First 1
    if ($cci) {
        $outItem = Join-Path $RomfsDir "a\2\2\0"
        $ok = [PokemonYRomfsEnhancer]::ExtractAndPatchRareCandyPrice($cci.FullName, $outItem)
        if ($ok) {
            Write-Host "  [OK] Precio del Caramelo Raro ajustado a 10 pokedolares en a/2/2/0!" -ForegroundColor Green
        } else {
            Write-Host "  [AVISO] No se pudo localizar a/2/2/0 dentro de la ROM." -ForegroundColor Yellow
        }
    } else {
        Write-Host "  [AVISO] No hay ROM .cci/.3ds en roms\ para extraer a/2/2/0." -ForegroundColor Yellow
    }
}

if (-not $SkipEvoGate) {
    $encPath = Join-Path $RomfsDir "a\0\1\2"
    $evoPath = Join-Path $RomfsDir "a\2\1\5"
    $perPath = Join-Path $RomfsDir "a\2\1\8"
    if ((Test-Path $encPath) -and (Test-Path $evoPath) -and (Test-Path $perPath)) {
        $slots = [PokemonYRomfsEnhancer]::PatchPreGym4Encounters($encPath, $evoPath, $perPath)
        Write-Host "  [OK] Regulacion pre-4o Gimnasio aplicada: $slots slots de 3a evolucion/legendarios regulados en Rutas 2-12." -ForegroundColor Green
        Write-Host "       (A partir del 4o Gimnasio / Ruta 13 en adelante TODAS las 3as evoluciones estan 100% desbloqueadas!)" -ForegroundColor Cyan
    } else {
        Write-Host "  [AVISO] Faltan GARCs a/0/1/2, a/2/1/5 o a/2/1/8 en romfs." -ForegroundColor Yellow
    }
}

if (-not $SkipNoLegend) {
    $encPath = Join-Path $RomfsDir "a\0\1\2"
    $evoPath = Join-Path $RomfsDir "a\2\1\5"
    $perPath = Join-Path $RomfsDir "a\2\1\8"
    if ((Test-Path $encPath) -and (Test-Path $evoPath) -and (Test-Path $perPath)) {
        $n = [PokemonYRomfsEnhancer]::PatchNoWildLegendaries($encPath, $evoPath, $perPath)
        Write-Host "  [OK] Sin legendarios en encuentros salvajes ($n huecos sustituidos; 0 = ya estaba aplicado)." -ForegroundColor Green
    } else {
        Write-Host "  [AVISO] Faltan GARCs a/0/1/2, a/2/1/5 o a/2/1/8 en romfs." -ForegroundColor Yellow
    }
}
if (-not $SkipTradeEvo) {
    $evoPath = Join-Path $RomfsDir "a\2\1\5"
    if (Test-Path $evoPath) {
        $n = [PokemonYRomfsEnhancer]::PatchTradeEvolutions($evoPath)
        Write-Host "  [OK] Evoluciones por intercambio pasadas a nivel ($n cambios; 0 = ya estaba aplicado)." -ForegroundColor Green
    } else {
        Write-Host "  [AVISO] No se encontro a/2/1/5 en romfs." -ForegroundColor Yellow
    }
}
