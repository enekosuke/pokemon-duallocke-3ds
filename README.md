# Pokémon DualLocke 3DS — Edición PRO (Guía de Usuario + Documentación Técnica para Agentes)

Entorno completo, portátil y 100% autocontenido en una sola carpeta (`C:\Users\Usuario\Downloads\Pokemon-DualLocke-3DS`) para jugar **Pokémon Y (Nintendo 3DS, USA v1.0, Title ID `0004000000055E00`) Randomlocke / DualLocke PRO** en PC, con motor nativo ARM32 (Muerte Permanente + Hard Level Cap + Caramelos Raros infinitos en tiendas por 10₽), parches avanzados de RomFS (IA Experta + regulación de 3ªs evoluciones hasta el 4º Gimnasio) y multijugador online en 1 clic mediante Azahar + Radmin VPN.

- **Repositorio GitHub (público, sin ROMs ni binarios pesados):** `https://github.com/enekosuke/pokemon-duallocke-3ds`
- **Semillas ya usadas por Eneko (nunca repetir):** `20261121`, `65344194`, `52824960` (el script las excluye al generar una aleatoria).
- **Semilla activa actual de Eneko:** `52824960` (semillas anteriores respaldadas en `saves-backup\`).
- **Accesos directos en el Escritorio de Eneko:**
  - `Jugar Pokemon Y Randomlocke.lnk` → `0-JUGAR-POKEMON-Y.bat`
  - `Jugar Online Pokemon Y.lnk` → `00-JUGAR-ONLINE-CON-AMIGO.bat`

---

## 1. Estructura Completa de la Carpeta

```text
Pokemon-DualLocke-3DS/
├── 0-JUGAR-POKEMON-Y.bat              # 1 clic: lanza Azahar directo en Pokémon Y Randomlocke PRO
├── 00-JUGAR-ONLINE-CON-AMIGO.bat      # 1 clic: asistente online (Crear sala / Unirse / Showdown / Detener)
├── 1-Instalar-o-Reparar-Todo.bat      # Ejecuta setup.ps1 para descargar/reparar entorno portátil
├── 2-Abrir-Randomizer.bat             # Abre la GUI de Universal Pokémon Randomizer FVX
├── 3-Abrir-Azahar.bat                 # Abre el menú principal de Azahar (ES)
├── 4-Abrir-PKHeX.bat                  # Abre PKHeX (edición de save / exportación a Showdown)
├── 5-Instalar-Mod-LayeredFS.bat       # Instala manualmente un mod LayeredFS en Azahar
├── 6-Backup-Save.bat                  # Crea backup con fecha del save `main` y muestra su ruta
├── 7-Tracker-DualLocke.html           # Tracker web local (vidas, muertes, marcador PVP, Level Caps)
├── 8-Configurar-Reglas-Pro.bat        # Menú interactivo para activar/editar reglas ARM32 PRO (rom-engine.ps1)
├── 8-Configurar-Muerte-Permanente.bat # Alias de 8-Configurar-Reglas-Pro.bat
├── setup.ps1                          # Instalador portátil (Azahar, UPR FVX + JRE, PKHeX, .NET, Radmin VPN)
├── README.md                          # Esta guía completa (usuarios + referencia técnica para agentes IA)
├── PROMPT-PARA-TU-AMIGO.md            # Prompt base para configurar el portátil de un amigo
├── .gitignore                         # Excluye tools/, roms/, saves-backup/, mods-para-compartir/, cachés
│
├── presets/
│   ├── pokemon-y-randomlocke.rnqs     # Preset UPR FVX v429 (reglas PRO completas)
│   ├── pro-rules.json                 # Configuración persistente del motor ARM32 PRO
│   ├── nuzlocke-permadeath.json       # Config legada (reemplazada por pro-rules.json)
│   └── online-config.json             # [gitignored] IP del host y apodo guardados por play-online.ps1
│
├── scripts/
│   ├── randomize-auto.ps1             # Pipeline completo: UPR FVX CLI + enhance-romfs.ps1 + rom-engine.ps1
│   ├── enhance-romfs.ps1              # Parcheador RomFS/GARC en PowerShell+C# (IA 0x07, 10₽, 3ªs evos)
│   ├── rom-engine.ps1                 # Motor Nativo ARM32 en PowerShell puro (genera code.ips y parchea code.bin)
│   ├── play-online.ps1                # Lógica del asistente online 1-clic (Radmin VPN + azahar-room + Azahar)
│   ├── install-mod.ps1                # Copia mods LayeredFS a Azahar
│   ├── backup-save.ps1                # Respalda el archivo `main` de Azahar en saves-backup/
│   ├── nuzlocke-permadeath.ps1        # Versión anterior (solo permadeath; mantenida como referencia)
│   └── nuzlocke-permadeath.py         # Prototipo/auditor Python original de permadeath
│
├── roms/                              # [gitignored - NO subir a GitHub]
│   ├── Pokemon Y (USA) (En,Ja,Fr,De,Es,It,Ko).cci  # ROM desencriptada (2 GiB, incluye español)
│   ├── Pokemon Y (USA) (En,Ja,Fr,De,Es,It,Ko).7z   # Copia comprimida (908 MB) para respaldo/envío privado
│   └── LEEME.txt
│
├── tools/                             # [gitignored - portátiles locales]
│   ├── azahar/                        # Azahar 2126.2 portátil (config y datos dentro de `user\`)
│   │   ├── azahar.exe
│   │   ├── azahar-room.exe            # Servidor dedicado local para salas multijugador
│   │   └── user/
│   │       ├── config/qt-config.ini   # Config gráfica (Vulkan, 60 FPS/200%, 2x HD, Tab=Turbo 400%, ES)
│   │       ├── load/mods/0004000000055E00/
│   │       │   ├── exefs/code.bin     # Binario ARM32 parcheado
│   │       │   ├── exefs/code.ips     # Parche IPS aplicado por Azahar al arrancar
│   │       │   └── romfs/             # Archivos GARC randomizados + mejoras PRO (`a/0/1/2`, `a/0/3/8`, `a/2/2/0`...)
│   │       └── sdmc/Nintendo 3DS/00000000000000000000000000000000/00000000000000000000000000000000/title/00040000/00055e00/data/00000001/main
│   ├── upr-fvx/                       # Universal Pokémon Randomizer FVX v1.6.3 + OpenJDK 25.0.2 embebido
│   └── pkhex/                         # PKHeX.exe oficial (requiere .NET Desktop Runtime)
│
├── mods-para-compartir/               # [gitignored] Salida intermedia del randomizer
└── saves-backup/                      # [gitignored] Copias de seguridad de partidas (`main`)
```

---

## 2. Reglas y Modificaciones PRO Activas

Todo el pipeline se aplica automáticamente al ejecutar `scripts/randomize-auto.ps1` (y cada regla ARM32 es editable en cualquier momento con `8-Configurar-Reglas-Pro.bat`):

1. **Randomización base (`presets/pokemon-y-randomlocke.rnqs`, UPR FVX v429):**
   - Iniciales (sin legendarios), salvajes, estáticos y entrenadores/gimnasios 100% aleatorios.
   - Habilidades aleatorias con **Superguarda (`Wonder Guard`) baneada**.
   - Movesets aleatorios por nivel (mínimo 2 ataques ofensivos iniciales + 60% buenos ataques).
   - **MT aleatorias** + compatibilidad aleatoria (conservando MOs/movimientos de campo).
   - Objetos del suelo y habilidad Recogida aleatorios; evoluciones imposibles/por intercambio desbloqueadas por nivel/objeto.
   - **`+1` Pokémon extra en Líderes/Jefes** (`additionalBossTrainerPokemon=1`), objetos competitivos en jefes (`sensibleItemsOnly`) y mejores movesets para entrenadores normales, importantes y jefes.
2. **IA Experta máxima (`scripts/enhance-romfs.ps1` → `romfs/a/0/3/8`):**
   - Activa los bits `0x07` (`Basic | EvaluateAttack | Expert`) en los **784 entrenadores y Líderes de Gimnasio**.
3. **Caramelos Raros infinitos por 10₽ en todas las Tiendas (`rom-engine.ps1` + `enhance-romfs.ps1`):**
   - Hay 9 listas de Tienda Pokémon, una por número de medallas (0..8). Reemplaza *Antihielo* (`0x0014`) por *Caramelo Raro* (`0x0032`) en las listas de 1 a 8 medallas, y **amplía la lista de 0 medallas** (solo Poké Ball y Poción) a `[Poké Ball, Poción, Caramelo Raro]`: la lista nueva (6 bytes) va en `0x0053BFF4`, el puntero de la tabla `0x005ADCE8` apunta a ella y el contador `0x0053C6E4` pasa de 2 a 3. Así hay caramelos desde la primera tienda.
   - Ajusta el precio del ítem `#50` en `romfs/a/2/2/0` de `480` (`4800₽`) a `1` (`10₽`).
4. **Hard Level Cap nativo ARM32 (`scripts/rom-engine.ps1`):**
   - Topes por defecto según número de medallas (`0..8`): **`[12, 25, 32, 34, 37, 42, 48, 59, 68]`**.
   - Bloquea tanto el uso de Caramelos Raros desde la Mochila como la ganancia de nivel/EXP por combate al alcanzar el tope actual.
   - Respeta combates PSS con reglas Nv. 50 (filtra por dirección de retorno `lr >= 0x00540000` perteneciente a `DllBattle.cro`).
5. **Muerte Permanente nativa ARM32 (`scripts/rom-engine.ps1`):**
   - A partir de `min_badges` (por defecto `1`, es decir, tras ganar la 1ª Medalla), cualquier Pokémon debilitado en combate salvaje o entrenador es eliminado definitivamente del equipo al salir del combate.
   - Los combates **PVP / Link / PSS** (`battleType >= 2`) son **siempre inmunes**.
   - Protección anti-blackout crash (`on_wipe_mode = 0`): si caen los 6 Pokémon, conserva el slot 0 para evitar cuelgue al teletransportarse al Centro Pokémon.
6. **Regulación de 3ªs evoluciones hasta el 4º Gimnasio (`scripts/enhance-romfs.ps1` → `romfs/a/0/1/2`):**
   - Lee el árbol evolutivo real de `a/2/1/5` (89 especies de 3ª etapa) y los BST de `a/2/1/8`.
   - En las **25 zonas previas al 4º Gimnasio** (Rutas 2–12, Bosque Novarte, Gruta Conexión, Cueva Reflejos, Bahía Azul…), devoluciona encuentros salvajes de 3ª etapa a su 2ª etapa y sustituye legendarios con BST ≥ 580 por Pokémon de 1ª/2ª etapa (sin tocar caña buena/súper ni el resto del juego).
   - A partir del **4º Gimnasio (Ruta 13, Gruta Helada, Calle Victoria y resto de Kalos)** todas las 3ªs evoluciones y legendarios quedan **100% desbloqueados**.
7. **Multijugador Online 1-Clic (`00-JUGAR-ONLINE-CON-AMIGO.bat` / `scripts/play-online.ps1`):**
   - `[1] Crear Sala (Anfitrión)`: abre Radmin VPN, detecta tu IP `26.x.x.x` y la copia al portapapeles, arranca `azahar-room.exe` (`DualLocke3DS`, puerto `24872`), pre-rellena `127.0.0.1` en Azahar y lanza el juego.
   - `[2] Unirse a Sala (Amigo)`: abre Radmin VPN, guarda IP + apodo en `presets/online-config.json`, prueba conectividad (`ping`), pre-rellena Azahar y lanza el juego.
   - `[3] Plan B (Showdown)`: respalda `main` y lo abre directamente en `PKHeX.exe` para copiar el equipo a `[Gen 6] Custom Game`.
   - `[4] Detener servidor azahar-room`.

---

## 3. Uso Rápido (Comandos Diarios)

### Jugar
- **Solitario:** doble clic en `0-JUGAR-POKEMON-Y.bat` (o acceso directo `Jugar Pokemon Y Randomlocke`).
- **Online con amigo:** doble clic en `00-JUGAR-ONLINE-CON-AMIGO.bat` (o acceso directo `Jugar Online Pokemon Y`).
- **Turbo en juego:** tecla `Tab` (alterna límite 60 FPS / 400% Turbo). **Desactivar Turbo durante combates PVP en PSS.**

### Cambiar reglas PRO (sin regenerar semilla)
Ejecuta `8-Configurar-Reglas-Pro.bat` o por consola:
```powershell
& "C:\Users\Usuario\Downloads\Pokemon-DualLocke-3DS\scripts\rom-engine.ps1" -Apply
```
*(Configuración en `presets\pro-rules.json`.)*

### Generar una nueva semilla aleatoria (y empezar partida limpia)
> ⚠️ **MUY IMPORTANTE al borrar una partida en Azahar:** si solo borras `main` y dejas el archivo `00000001.metadata`, Pokémon Y mostrará *"The saved game data is corrupted"*. Para empezar partida nueva limpia hay que borrar la **carpeta `data` completa** (`...\title\00040000\00055e00\data`).

```powershell
# 1. Con Azahar cerrado, respaldar `main` si quieres conservarlo (`6-Backup-Save.bat`)
# 2. Borrar la carpeta completa de save para arrancar limpio:
Remove-Item "C:\Users\Usuario\Downloads\Pokemon-DualLocke-3DS\tools\azahar\user\sdmc\Nintendo 3DS\00000000000000000000000000000000\00000000000000000000000000000000\title\00040000\00055e00\data" -Recurse -Force -ErrorAction SilentlyContinue

# 3. Generar nueva semilla aleatoria + aplicar RomFS PRO + aplicar Motor ARM32 PRO:
& "C:\Users\Usuario\Downloads\Pokemon-DualLocke-3DS\scripts\randomize-auto.ps1" -Seed random
```

---

## 4. Referencia Técnica para Futuros Agentes IA (Ingeniería Inversa & Arquitectura)

Esta sección documenta todas las direcciones binarias, estructuras, *workarounds* y restricciones verificadas sobre **Pokémon Y USA v1.0** para que cualquier agente pueda continuar el trabajo sin volver a invertir el binario desde cero.

### 4.1. Datos del binario objetivo (`Pokemon Y USA v1.0`)
- **Title ID:** `0004000000055E00` (Product Code: `kujira-2`, NCCH desencriptado `.cci`).
- **Arquitectura:** ARM32 (ARMv6K / 3DS), little-endian.
- **Mapeo de `exefs/code.bin`:**
  - Base virtual: `0x00100000` (`file_offset = vaddr - 0x00100000`).
  - Segmento `.text`: `0x00100000 .. 0x0053C000`.
- **Carga en Azahar:** Azahar aplica `mods/0004000000055E00/exefs/code.bin` y sobre él `exefs/code.ips` (confirmado en `tools\azahar\user\log\azahar_log.txt`). `rom-engine.ps1` actualiza tanto `exefs/code.ips` como `exefs/code.bin` (y copias en la raíz del mod por compatibilidad).

### 4.2. Símbolos verificados en `code.bin`

| Símbolo / Rutina | Dirección Virtual | Notas técnicas |
| :--- | :--- | :--- |
| `GameSystem` singleton getter | `0x0014EB04` | `[r0+0x1C]` = `GameData*`; `[GameData+0x00]` = `SaveControl*`; `SaveControl+0x3410` = `MiscSave*`; `[GameData+0x14]` = `PokeParty*`. |
| `MiscSave::GetBadgeCount` | `0x004AF36C` | Devuelve `r0 = 0..8` (cuenta de bits de medallas en `MiscSave`). |
| `PokeParty::GetMemberCountEx` | `0x004A1C6C` | Con `r1 = 1` devuelve el número de Pokémon vivos no-huevo en el equipo. |
| `PokeParam::IsEgg` | `0x004A1658` | `r0 = PokeParam*`, retorna `!= 0` si es huevo. |
| `PokeParam::IsFainted` | `0x004A1AF4` | `r0 = PokeParam*`, retorna `!= 0` si PS == 0. |
| `PokeParty::RemoveMember` | `0x0039E1C4` | `r0 = PokeParty*`, `r1 = slot (0..5)`; elimina el Pokémon y compacta el equipo. |
| `PokeParam::GetLevel` | `0x00168AE4` | `r0 = PokeParam*`, devuelve nivel actual `1..100`. |
| `PokeParam::SetExp` | `0x0039D6E8` | Hook en `0x0039D714`; usado por `DllBattle.cro` (`lr >= 0x00540000`) y por PSS Lv.50 (`0x001D0558`). |
| `PokeParam::AddLevel` | `0x0039D744` | Hook en `0x0039D758`; sube niveles (Caramelos Raros / subidas directas). |
| `RareCandy` Bag check | `0x0043DFB8` | Comprobación de uso de Caramelo Raro en la Mochila (antes de consumir el objeto). |
| `PostBattleEvent::Case7_Exit` | `0x003C7B48` | Salida de combate en overworld; contiene `battleType` (`0=salvaje`, `1=entrenador`, `>=2=Link/PSS`). |
| `Poké Mart Shops 1..8` | `0x0053C8B2` .. `0x0053C9A6` | Offsets en archivo `code.bin`: `0x43C8B2, 0x43C8CC, 0x43C8EA, 0x43C90E, 0x43C934, 0x43C95A, 0x43C980, 0x43C9A6` (u16 `0x0014` → `0x0032`). |

### 4.3. Cuevas de código (Code Caves) usadas por `scripts/rom-engine.ps1`
Todas mantienen alineación de pila de 8 bytes (número par de registros en `push`/`pop`) y están validadas con Capstone/Keystone:

| Región | Dirección Virtual | Tamaño | Uso en `rom-engine.ps1` |
| :--- | :--- | :--- | :--- |
| `.text` zero-padding cave | `0x0053BEDC .. 0x0053C000` | 292 B | Bloque `NUZL` (config + lógica de Muerte Permanente). |
| `DllTrialDownload` launcher (0 callers, online 3DS muerto) | `0x003517D4 .. 0x00351838` | 100 B | Bloque `LCAP` (tabla de 9 caps `[0..8]` + `get_cap()`). |
| `DllGameSync` launcher (online 3DS muerto) | `0x003502E8 .. 0x00350348` | 96 B | Guardia `bx lr` + `check_bag_sb()` + `clamp_r5()`. |
| `DllEshop` launcher (online 3DS muerto) | `0x0034F538 .. 0x0034F594` | 92 B | Guardia `bx lr` + `for_setexp()` (filtra `lr >= 0x00540000`). |

### 4.4. Parches de RomFS / GARC (`scripts/enhance-romfs.ps1`)
- **`a/0/3/8` (Trainer Data GARC):** 784 registros de entrenador; modifica el byte/word de flags de IA aplicando `|= 0x07`.
- **`a/2/2/0` (Item Data GARC):** extraído directamente desde el RomFS Level 3 del `.cci` si no está en `mods/romfs`; modifica el precio de Caramelo Raro (ítem `#50`) de `480` (`4800₽`) a `1` (`10₽`).
- **`a/0/1/2` (Zone Encounters GARC, LZ11):**
  - Consulta especies de 3ª evolución en `a/2/1/5` (89 especies) y BST en `a/2/1/8` (Personal Data).
  - Descomprime vía LZ11 únicamente las **25 zonas previas al 4º Gimnasio**: `45, 157, 172, 259..270, 285, 286, 302..308, 334, 357`.
  - Devoluciona especies de 3ª etapa a su preevolución (2ª etapa) y reemplaza legendarios con BST ≥ 580 por Pokémon válidos de 1ª/2ª etapa, sin alterar los slots de Supercaña (`76..78`) ni las zonas posteriores al 4º Gimnasio.
  - Recomprime con un compresor LZ11 real (cadenas hash, formas de 2/3/4 bytes) para que cada entrada conserve un tamaño casi idéntico al original (el `largest` del GARC queda igual que en la ROM) y verifica el round-trip antes de escribir. **No usar compresión "solo literales"**: duplicaba el tamaño de las zonas y provocaba cuelgues al entrar en el Bosque Novarte. Reconstruye la cabecera GARC (`FATO`/`FATB`/`FIMB`).
  - Re-ejecutar `scripts\enhance-romfs.ps1 -SkipAI -SkipCandyPrice` recomprime y repara un `a/0/1/2` generado con la versión antigua.

### 4.5. Investigación ya iniciada para futura mejora opcional: "Saltar intro hasta elección de inicial"
Si en el futuro se quiere implementar un parche nativo que tras terminar la creación de personaje (`DllIntro.cro`) aparezca directamente vestido en Pueblo Acuarela delante de la mesa de iniciales:
- `rom:/DllIntro.cro` (`0x53C874`) es lanzado desde la máquina de estados en `0x3F6E60..0x3F7128`.
- Al finalizar `DllIntro.cro`, el juego crea el `NewGameProc` (vtable `0x5990BC`, `vt[3]=0x3B7F9C`, `vt[4]=0x3B80A0`).
- En `0x3B7FB8` comprueba si existe save; si es Nueva Partida (`0x3B7FF4`), copia la posición inicial desde `GameData + 0x40` (`0x3B7FFC`) e inicializa el estado base (`0x3B803C..0x3B8088`, `0x1D3998`).
- **Estrategia recomendada sin softlocks:** obtener un `main` guardado justo 1 paso antes de la mesa de Pueblo Acuarela (Pajamas OFF, Mamá y Ruta 1 completados), hacer diff de `Situation` (`0x1400`), `EventWork` (`0x14A00`), `EventFlag` (`0x14C00`) y `Fashion`, e inyectar esos valores exactos en `0x3B7FFC` usando otra cueva de CRO online muerto (`DllPGL`/`DllLiveCup`/`DllGts`).

### 4.6. Workarounds, trampas conocidas y reglas para agentes
1. **Bug upstream de UPR FVX 1.6.3 CLI (`EXTRA_MEMORY_NOT_AVAILABLE`):** `CliRandomizer` nunca llama a `romOpener.setExtraMemoryAvailable(true)`. `scripts/randomize-auto.ps1` lo resuelve automáticamente creando un JAR temporal `_upr_cli_temp.jar`, parcheando el byte `4640` de `com/uprfvx/romio/romio/RomOpener.class` (`0x9A ifne` → `0x99 ifeq`), ejecutando con un heap elegido según la RAM física (**≤ 12 GB → `-Xmx3072M`**, más RAM → `-Xmx4608M`; en equipos con poca RAM exige tener Azahar cerrado) y borrando el temporal.
2. **Invocación en PowerShell:** ejecutar los scripts con `& ".\scripts\..."` o `powershell -NoProfile -ExecutionPolicy Bypass -File ...`. Todos los scripts de producción son PowerShell + .NET/C# puro (**cero dependencia de Python** en el PC del usuario o de su amigo).
3. **Reseteo limpio de partida en Azahar:** borrar SIEMPRE la carpeta completa `title\00040000\00055e00\data` (incluyendo `00000001.metadata`), nunca solo `main`.
4. **Reglas de entorno y seguridad:**
   - **Nunca subir archivos de ROM** (`.cci`, `.3ds`, `.cxi`, `.7z`, `.zip`) ni `tools/` a GitHub (ya están en `.gitignore`).
   - **Nunca matar `azahar.exe`** mientras el usuario esté jugando sin avisarle primero para guardar partida.
   - **No modificar otros repositorios/carpetas** fuera de `C:\Users\Usuario\Downloads\Pokemon-DualLocke-3DS`.
   - `setup.ps1` detecta equipos con ≤ 12 GB de RAM y aplica el perfil ligero (`resolution_factor=1`, `frame_limit=100`) en lugar del de 2x/200 FPS.
   - **Perfil del amigo (portátil ligero):** carpeta `C:\Users\Enara\Downloads\Pokemon-DualLocke-3DS`, Intel i7-8550U, 8 GB RAM, NVIDIA GTX 1050 (driver actualizado `582.78 WHQL`), configuración ligera de Azahar (`Vulkan`, `resolution_factor=1`, `frame_limit=100`, `async_shader_compilation=true`, `disable_right_eye_render=true`) y **siempre una semilla distinta** a las de Eneko (`20261121` / `65344194`).
