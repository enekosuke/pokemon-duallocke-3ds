# Prompt para el agente de tu amigo (pegar entero en Antigravity)

Copia el bloque de abajo tal cual y pégalo en el agente de tu amigo. Sirve para actualizar su instalación existente y empezar de cero con una semilla nueva.

---

```text
Eres el agente de mi portátil. Tienes que actualizar mi instalación de Pokémon Y Randomlocke / DualLocke 3DS a la última versión del repositorio y empezar una partida 100% nueva con una semilla de randomización nueva. Haz los pasos en orden, comprueba cada uno antes de pasar al siguiente y, si algo falla, para y cuéntamelo con el error exacto. Todo en PowerShell, sin instalar nada que no se indique aquí.

DATOS DE MI EQUIPO (respétalos)
- Carpeta del proyecto: C:\Users\Enara\Downloads\Pokemon-DualLocke-3DS
- Portátil con Intel i7-8550U, SOLO 8 GB de RAM y NVIDIA GTX 1050 (driver 582.78 WHQL, ya actualizado).
- Ya está instalado: el clon del repo, tools\azahar (Azahar 2126.2 portátil), tools\upr-fvx (UPR FVX 1.6.3 con Java), tools\pkhex, Radmin VPN y la ROM roms\Pokemon Y (USA) (En,Ja,Fr,De,Es,It,Ko).cci.
- Repositorio: https://github.com/enekosuke/pokemon-duallocke-3ds
- Reglas de seguridad: NUNCA subas a GitHub la ROM (.cci/.3ds/.7z), ni tools\, ni saves-backup\. No hagas git push. No borres roms\ ni tools\. No mates azahar.exe sin que yo lo sepa.

PASO 0. PREPARAR EL EQUIPO (8 GB de RAM)
- Si hay algún azahar.exe abierto, pídeme que guarde la partida, y ciérralo antes de seguir. Cierra también navegadores y programas pesados mientras randomizas.
- Comprueba la RAM: (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB. Debe salir unos 8.
- Comprueba que existen: roms\*.cci, tools\azahar\azahar.exe, tools\upr-fvx\UPR-FVX.jar, tools\upr-fvx\java\bin\java.exe.

PASO 1. ACTUALIZAR EL CÓDIGO (con o sin Git)
- Si el comando git existe Y la carpeta tiene .git: cd C:\Users\Enara\Downloads\Pokemon-DualLocke-3DS y git pull --ff-only (si falla por cambios locales: git fetch origin y git reset --hard origin/main).
- Si git NO existe o la carpeta no tiene .git (instalación por ZIP): NO instales Git y NO te pares, usa este método sin Git:
  $tmp = Join-Path $env:TEMP "dl3ds"; Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue; New-Item -ItemType Directory $tmp | Out-Null
  Invoke-WebRequest "https://github.com/enekosuke/pokemon-duallocke-3ds/archive/refs/heads/main.zip" -OutFile "$tmp\main.zip"
  Expand-Archive "$tmp\main.zip" -DestinationPath $tmp -Force
  robocopy "$tmp\pokemon-duallocke-3ds-main" "C:\Users\Enara\Downloads\Pokemon-DualLocke-3DS" /E /XD roms tools saves-backup .git /NFL /NDL /NJH /NJS
  (robocopy devuelve códigos 0 a 7 cuando va bien; solo 8 o más es error.) Esto sobrescribe scripts, presets, README y .bat con la última versión y NO toca roms\, tools\ ni saves-backup\. Después borra $tmp.
- Comprueba que existen y están actualizados: scripts\enhance-romfs.ps1 (debe contener el texto "Lz11CompressSafe" y "MAXCHAIN"), scripts\randomize-auto.ps1 (debe contener "Xmx3072M") y scripts\rom-engine.ps1.
- NO ejecutes setup.ps1 ni 1-Instalar-o-Reparar-Todo.bat (ya está todo instalado y no hace falta).

PASO 2. CONFIGURACIÓN LIGERA DE AZAHAR (debe quedar EXACTA)
Abre tools\azahar\user\config\qt-config.ini y comprueba estas claves. Para cada una, la línea "clave\default" debe valer false y la línea "clave" el valor indicado. Si alguna no coincide, corrígela (Azahar tiene que estar cerrado):
- graphics_api = 2 (Vulkan)
- resolution_factor = 1   (NO 2)
- frame_limit = 100
- async_shader_compilation = true
- disable_right_eye_render = true
- Paths\language = es
Si ya estaban bien, no escribas nada. Muéstrame al final las 6 líneas finales.

PASO 3. COPIA DE SEGURIDAD DEL SAVE Y BORRADO LIMPIO
- Ruta del save: tools\azahar\user\sdmc\Nintendo 3DS\00000000000000000000000000000000\00000000000000000000000000000000\title\00040000\00055e00\data
- Si existe la subcarpeta data\00000001\main, copia main a saves-backup\save-anterior-AAAAMMDD-HHMMSS\main (crea la carpeta). Puedes usar 6-Backup-Save.bat.
- Después borra la carpeta data ENTERA (incluido 00000001.metadata): Remove-Item "<ruta>\data" -Recurse -Force. Si solo se borra main, el juego dice "The saved game data is corrupted".
- Comprueba que la carpeta data ya no existe.

PASO 4. GENERAR EL SISTEMA COMPLETO CON UNA SEMILLA NUEVA
- Semillas PROHIBIDAS (son de Eneko): 20261121, 65344194 y 52824960. Tampoco repitas la semilla que ya tuviera yo antes si la conoces.
- Ejecuta, con Azahar cerrado:
  powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\randomize-auto.ps1
  Sin parámetros genera una semilla aleatoria que no coincide con las prohibidas. Si prefieres elegirla tú, usa -Seed <número de 8 cifras distinto de las prohibidas>.
- Mira la salida: tiene que decir "RAM detectada: ... GB -> Java -Xmx3072M". Si dice -Xmx4608M, para y avísame (no lo ejecutes así con 8 GB). Tarda más o menos medio minuto.
- Apunta la semilla que muestra ("Semilla: NNNNNNNN").
- El script ya aplica solo, en este orden: UPR FVX con el preset presets\pokemon-y-randomlocke.rnqs, scripts\enhance-romfs.ps1 (IA experta, Caramelo Raro a 10 pokedólares y regulación de 3ªs evoluciones antes del 4º gimnasio) y scripts\rom-engine.ps1 -Apply (muerte permanente, tope de nivel y caramelos en tiendas). No hace falta ejecutarlos a mano.
- Dependencias: ninguna extra. Todo es PowerShell con .NET incluido en Windows y los programas de tools\. No instales Python ni nada más.

PASO 5. VERIFICAR EN DISCO (muéstrame los resultados)
Dentro de tools\azahar\user\load\mods\0004000000055E00\ comprueba:
- exefs\code.bin existe (unos 5 MB) y exefs\code.ips existe y pesa EXACTAMENTE 630 bytes.
- romfs\a\0\1\2 existe y pesa entre 850000 y 900000 bytes (si pesa cerca de 966000 o más, el parche de evoluciones falló: avísame, no juegues).
- romfs\a\0\3\8, romfs\a\2\2\0, romfs\a\2\1\5, romfs\a\2\1\8 existen.
- romfs\DllBattle.cro existe y pesa 1040384 bytes (arreglo del cuelgue al ganar EXP en el tope de nivel). La salida del paso 4 debe decir "Tope en combate (DllBattle.cro): aplicado".
- presets\pro-rules.json existe con permadeath true, level_cap true y mart_candies true.
- En la salida del paso 4 aparecen estas confirmaciones: "IA Experta Maxima (0x07) aplicada a N entrenadores/gimnasios" (N cambia con cada semilla, cualquier número mayor que 0 vale), "Precio del Caramelo Raro ajustado a 10 pokedolares" y "MOTOR NATIVO ARM32 PRO APLICADO".
- git status no debe mostrar ROMs ni tools\ (están ignorados).

PASO 6. ACCESOS DIRECTOS EN EL ESCRITORIO
Crea o actualiza en el Escritorio real (usa [Environment]::GetFolderPath('Desktop'), puede estar en OneDrive) con WScript.Shell:
- "Jugar Pokemon Y Randomlocke.lnk" -> C:\Users\Enara\Downloads\Pokemon-DualLocke-3DS\0-JUGAR-POKEMON-Y.bat (WorkingDirectory = la carpeta del proyecto)
- "Jugar Online Pokemon Y.lnk" -> C:\Users\Enara\Downloads\Pokemon-DualLocke-3DS\00-JUGAR-ONLINE-CON-AMIGO.bat (WorkingDirectory = la carpeta del proyecto)
No hay lanzadores nuevos que crear. Comprueba que los dos .lnk existen y apuntan bien.

PASO 7. EXPLICACIÓN FINAL PARA MÍ (lenguaje sencillo, sin tecnicismos)
Cuando termines, escríbeme esto en castellano claro:
1. Qué semilla me ha tocado y que es distinta de la de Eneko (mismas reglas, Pokémon distintos).
2. Cómo jugar: doble clic en "Jugar Pokemon Y Randomlocke" del Escritorio. Es partida nueva: la primera vez sale una pantalla para elegir idioma, elige Spanish, confirma con "Begin game" y sigue la intro. La tecla Tab activa y desactiva el turbo.
3. Reglas del sistema: a partir de la 1ª medalla, los Pokémon debilitados se pierden para siempre (en combates PVP no) y el objeto que llevaban equipado vuelve a la mochila. Hay un tope de nivel según las medallas que llevas (12, 25, 32, 34, 37, 42, 48, 59 y 68). El Caramelo Raro se compra en las tiendas por 10 pokédolares. Las evoluciones finales fuertes y los legendarios no aparecen hasta pasar el 4º gimnasio. Los Pokémon que evolucionaban por intercambio evolucionan solos al subir de nivel (30, 37, 45 o 50 según el Pokémon), sin objeto ni intercambio.
4. Cómo conectarme con Eneko: abrir Radmin VPN, encenderlo y unirme a la red que me diga él. Después doble clic en "Jugar Online Pokemon Y" y elegir la opción 2 (Unirse a sala), poner la IP 26.x.x.x de Eneko y mi apodo. En el juego usar el combate inalámbrico local del PSS, SIN pulsar el botón azul de Internet, y con el turbo desactivado durante el combate.
5. Plan B si falla la conexión: 4-Abrir-PKHeX.bat, abrir mi partida y exportar el equipo a Pokémon Showdown en [Gen 6] Custom Game.
6. Que mi partida anterior (si existía) quedó guardada en saves-backup\ y que no debo borrar esa carpeta.

Si algo no se puede hacer (por ejemplo un permiso de administrador), dímelo claro y dame el paso exacto para hacerlo yo.
```
