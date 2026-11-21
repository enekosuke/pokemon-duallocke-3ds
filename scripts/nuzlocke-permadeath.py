#!/usr/bin/env python3
"""
Pokemon Y (USA v1.0, kujira-2, TitleID 0004000000055E00)
Motor Nativo ARM32 de Muerte Permanente (Nuzlocke Permadeath)

Ingenieria inversa verificada sobre code.bin (base 0x00100000, .text pad 0x0053bedc..0x0053c000):
  - Hook en PostBattleEvent::Case7_Exit      @ 0x003c7b48 (tras devolver equipo, captura, dinero y evoluciones)
  - MiscSave::GetBadgeCount(MiscSave*)       @ 0x004af36c (SaveControl [fp+0x00] + 0x3410)
  - PokeParty::GetMemberCountEx(p, 1, 0)     @ 0x004a1c6c (cuenta vivos no-huevo en [fp+0x14])
  - PokeParam::IsEgg(mon, 2)                 @ 0x004a1658
  - PokeParam::IsFainted(mon)                @ 0x004a1af4 (HP == 0)
  - PokeParty::RemoveMember(party, idx)      @ 0x0039e1c4 (elimina limpiamente y compacta el equipo)

Garantias de seguridad:
  1. Combates Link / PSS PVP (battleType >= 2) son SIEMPRE inmunes (nunca borra Pokemon en combates contra tu amigo).
  2. Huevos nunca se eliminan.
  3. En wipe total / blackout (0 Pokemon vivos), conserva el slot 0 por defecto (o no borra ninguno) para evitar
     cualquier crash al teletransportar al Centro Pokemon.
  4. 100% configurable via cabecera NUZL en 0x0053bedc (sin recompilar).
"""

import argparse
import json
import os
import shutil
import struct
import sys

TITLE_ID = "0004000000055E00"
CODE_BASE = 0x00100000
HOOK_VADDR = 0x003C7B48
CAVE_CFG_VADDR = 0x0053BEDC
CAVE_CODE_VADDR = 0x0053BEE8

# Instruccion ARM32 en 0x003c7b48: `b #0x0053bee8` (reemplaza `add sp, sp, #0x4c`)
HOOK_BYTES = bytes.fromhex("e6d005ea")
ORIG_HOOK_BYTES = bytes.fromhex("4cd08de2")  # `add sp, sp, #0x4c`

# Rutina ARM32 ensamblada con Keystone y verificada con Capstone en 0x0053bee8 .. 0x0053bff4 (268 bytes)
CAVE_CODE_BYTES = bytes.fromhex(
    "ff412de918804fe20400d8e5000050e30000541300005b133800000a180094e5"
    "000050e33500000a0000d0e5010050e33200008a071088e20010d1e7000051e3"
    "2e00000a00009be5000050e32b00000a030a80e2410e80e209cdfdeb0510d8e5"
    "010050e12500003a14409be5000054e32200000a1850d4e5000055e31f00000a"
    "060055e31d00008a0400a0e10110a0e30020a0e33a97fdeb000050e30070a013"
    "0300001a0600d8e5000050e31300001a0170a0e3016045e2070056e10f0000ba"
    "060194e7000050e30a00000a0210a0e3a695fdeb000050e30600001a060194e7"
    "c996fdeb000050e30200000a0400a0e10610a0e17888f9eb016046e2edffffea"
    "ff41bde84cd08de2d52efaea"
)


def build_config_block(enabled: int, min_badges: int, on_wipe_mode: int, allow_wild: int, allow_trainer: int) -> bytes:
    return struct.pack(
        "<4sBBBBBBBB",
        b"NUZL",
        1 if enabled else 0,
        max(0, min(255, int(min_badges))),
        1 if on_wipe_mode else 0,
        1 if allow_wild else 0,
        1 if allow_trainer else 0,
        0, 0, 0,
    )


def build_ips(cfg: bytes) -> bytes:
    """Construye un parche IPS estandar de 3DS (offsets relativos a 0x00100000)."""
    records = [
        (HOOK_VADDR - CODE_BASE, HOOK_BYTES),
        (CAVE_CFG_VADDR - CODE_BASE, cfg + CAVE_CODE_BYTES),
    ]
    out = bytearray(b"PATCH")
    for offset, data in records:
        if offset >= 0x1000000 or len(data) >= 0x10000:
            raise ValueError("Offset o tamano fuera de rango IPS")
        out += struct.pack(">I", offset)[1:]  # 3-byte big-endian offset
        out += struct.pack(">H", len(data))
        out += data
    out += b"EOF"
    return bytes(out)


def patch_code_bin(code_bin_path: str, cfg: bytes, enable_patch: bool) -> bool:
    """Aplica o revierte el parche directamente en un code.bin existente (ej. el generado por UPR FVX)."""
    if not os.path.isfile(code_bin_path):
        return False
    data = bytearray(open(code_bin_path, "rb").read())
    hook_off = HOOK_VADDR - CODE_BASE
    cave_off = CAVE_CFG_VADDR - CODE_BASE
    payload = cfg + CAVE_CODE_BYTES
    if len(data) < cave_off + len(payload):
        raise ValueError(f"code.bin inesperado ({len(data)} bytes): no parece Pokemon Y v1.0")

    cur_hook = bytes(data[hook_off : hook_off + 4])
    if cur_hook not in (ORIG_HOOK_BYTES, HOOK_BYTES):
        raise ValueError(
            f"Bytes inesperados en {HOOK_VADDR:#x}: {cur_hook.hex()} "
            "(este parche esta verificado para Pokemon Y v1.0)"
        )

    if enable_patch:
        data[hook_off : hook_off + 4] = HOOK_BYTES
        data[cave_off : cave_off + len(payload)] = payload
    else:
        data[hook_off : hook_off + 4] = ORIG_HOOK_BYTES
        data[cave_off : cave_off + len(payload)] = b"\x00" * len(payload)

    with open(code_bin_path, "wb") as f:
        f.write(data)
    return True


def base_dir() -> str:
    return os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def config_json_path() -> str:
    return os.path.join(base_dir(), "presets", "nuzlocke-permadeath.json")


def load_saved_config() -> dict:
    default = {
        "enabled": True,
        "min_badges": 1,
        "on_wipe_mode": 0,  # 0 = keep_slot0, 1 = keep_all
        "allow_wild": True,
        "allow_trainer": True,
    }
    p = config_json_path()
    if os.path.isfile(p):
        try:
            data = json.load(open(p, "r", encoding="utf-8"))
            default.update(data)
        except Exception:
            pass
    return default


def apply_config(cfg_dict: dict) -> None:
    root = base_dir()
    os.makedirs(os.path.dirname(config_json_path()), exist_ok=True)
    with open(config_json_path(), "w", encoding="utf-8") as f:
        json.dump(cfg_dict, f, indent=2)

    cfg_bytes = build_config_block(
        enabled=1 if cfg_dict["enabled"] else 0,
        min_badges=cfg_dict["min_badges"],
        on_wipe_mode=cfg_dict["on_wipe_mode"],
        allow_wild=1 if cfg_dict["allow_wild"] else 0,
        allow_trainer=1 if cfg_dict["allow_trainer"] else 0,
    )

    mod_dir = os.path.join(root, "tools", "azahar", "user", "load", "mods", TITLE_ID)
    exefs_dir = os.path.join(mod_dir, "exefs")
    os.makedirs(exefs_dir, exist_ok=True)

    # 1. Guardar code.ips en exefs/code.ips (y en mod_dir/code.ips para compatibilidad Luma/Azahar)
    ips_bytes = build_ips(cfg_bytes)
    ips_exefs = os.path.join(exefs_dir, "code.ips")
    ips_root = os.path.join(mod_dir, "code.ips")
    if cfg_dict["enabled"]:
        with open(ips_exefs, "wb") as f:
            f.write(ips_bytes)
        with open(ips_root, "wb") as f:
            f.write(ips_bytes)
    else:
        for p in (ips_exefs, ips_root):
            if os.path.exists(p):
                os.remove(p)

    # 2. Si existe code.bin (generado por UPR FVX), sincronizarlo en exefs/code.bin y parcharlo tambien
    luma_code_bin = os.path.join(mod_dir, "code.bin")
    exefs_code_bin = os.path.join(exefs_dir, "code.bin")
    if os.path.isfile(luma_code_bin):
        patch_code_bin(luma_code_bin, cfg_bytes, enable_patch=cfg_dict["enabled"])
        shutil.copy2(luma_code_bin, exefs_code_bin)
    elif os.path.isfile(exefs_code_bin):
        patch_code_bin(exefs_code_bin, cfg_bytes, enable_patch=cfg_dict["enabled"])

    print("[OK] Configuracion de Muerte Permanente aplicada:")
    print(f"  Estado:                {'ACTIVADA' if cfg_dict['enabled'] else 'DESACTIVADA'}")
    print(f"  Activar tras medallas: {cfg_dict['min_badges']} (1 = a partir de la 1a medalla / Violeta)")
    print(f"  Combates salvajes:     {'SI' if cfg_dict['allow_wild'] else 'NO'}")
    print(f"  Entrenadores/Gimnasio: {'SI' if cfg_dict['allow_trainer'] else 'NO'}")
    print(f"  Combates PVP (PSS):    INMUNES (siempre desactivado en combates contra amigos)")
    print(f"  En blackout total:     {'Deja solo slot 0 (anti-crash)' if cfg_dict['on_wipe_mode'] == 0 else 'No borra ninguno en blackout'}")
    print(f"  IPS generado:          {ips_exefs} ({len(ips_bytes)} bytes)")


def interactive_menu() -> None:
    cfg = load_saved_config()
    while True:
        print("\n============================================================")
        print("   POKEMON Y - CONFIGURADOR DE MUERTE PERMANENTE (ARM32)")
        print("============================================================")
        print(f"  [1] Muerte permanente:      {'ACTIVADA' if cfg['enabled'] else 'DESACTIVADA'}")
        print(f"  [2] Medallas minimas:       {cfg['min_badges']}  (0=desde el inicio, 1=tras 1a medalla, 2..8)")
        print(f"  [3] Muertes en salvajes:    {'SI' if cfg['allow_wild'] else 'NO'}")
        print(f"  [4] Muertes en entrenadores:{'SI' if cfg['allow_trainer'] else 'NO'}")
        print(f"  [5] En wipe/blackout total: {'Dejar slot 0 (anti-crash)' if cfg['on_wipe_mode'] == 0 else 'No borrar nada en wipe'}")
        print("  ------------------------------------------------------------")
        print("  [G] Guardar y aplicar parche en Azahar")
        print("  [S] Salir sin guardar")
        opt = input("\nElige una opcion: ").strip().lower()
        if opt == "1":
            cfg["enabled"] = not cfg["enabled"]
        elif opt == "2":
            val = input("Numero de medallas minimas (0-8, recomendado 1): ").strip()
            if val.isdigit() and 0 <= int(val) <= 8:
                cfg["min_badges"] = int(val)
        elif opt == "3":
            cfg["allow_wild"] = not cfg["allow_wild"]
        elif opt == "4":
            cfg["allow_trainer"] = not cfg["allow_trainer"]
        elif opt == "5":
            cfg["on_wipe_mode"] = 1 - cfg["on_wipe_mode"]
        elif opt == "g":
            apply_config(cfg)
            return
        elif opt == "s":
            return


def main() -> None:
    ap = argparse.ArgumentParser(description="Configura el parche nativo ARM32 de Muerte Permanente para Pokemon Y")
    ap.add_argument("--apply", action="store_true", help="Aplica la configuracion (guardada o por argumentos) sin menu")
    ap.add_argument("--enabled", type=int, choices=[0, 1])
    ap.add_argument("--min-badges", type=int)
    ap.add_argument("--allow-wild", type=int, choices=[0, 1])
    ap.add_argument("--allow-trainer", type=int, choices=[0, 1])
    ap.add_argument("--on-wipe", type=int, choices=[0, 1], help="0=dejar slot 0 (anti-crash), 1=no borrar en blackout")
    args = ap.parse_args()

    if not args.apply and all(
        v is None for v in (args.enabled, args.min_badges, args.allow_wild, args.allow_trainer, args.on_wipe)
    ):
        interactive_menu()
        return

    cfg = load_saved_config()
    if args.enabled is not None:
        cfg["enabled"] = bool(args.enabled)
    if args.min_badges is not None:
        cfg["min_badges"] = args.min_badges
    if args.allow_wild is not None:
        cfg["allow_wild"] = bool(args.allow_wild)
    if args.allow_trainer is not None:
        cfg["allow_trainer"] = bool(args.allow_trainer)
    if args.on_wipe is not None:
        cfg["on_wipe_mode"] = args.on_wipe
    apply_config(cfg)


if __name__ == "__main__":
    main()
