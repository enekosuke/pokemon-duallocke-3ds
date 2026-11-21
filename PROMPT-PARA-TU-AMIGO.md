# 🤖 Prompt para pasarle a tu amigo (pegar entero en su Antigravity)

Copia este texto completo y pásaselo a tu amigo para que lo pegue tal cual en su **Antigravity**:

---

```text
Hola, quiero que me montes y configures AL MILÍMETRO mi portátil para jugar un Pokémon Y Randomlocke / DualLocke de Nintendo 3DS online contra mi amigo Eneko (cada uno desde su casa). No sé mucho de ordenadores, así que haz tú todos los comandos posibles por mí y déjamelo EXACTAMENTE igual que a él: listo para abrir y jugar con un solo clic (`0-JUGAR-POKEMON-Y.bat`), pero con UNA SEMILLA DISTINTA para que mi partida tenga Pokémon aleatorios diferentes a los suyos (con las mismas reglas).

Todo el entorno, instalador, preset de randomización y guía están en este repositorio de GitHub:
https://github.com/enekosuke/pokemon-duallocke-3ds

Ejecuta estos pasos en orden y verifica cada uno sin saltarte nada:

1. DESCARGA DEL ENTORNO:
   - Clona o descarga el repositorio `https://github.com/enekosuke/pokemon-duallocke-3ds` en `%USERPROFILE%\Downloads\Pokemon-DualLocke-3DS` (si no tengo `git`, descarga el ZIP de `https://github.com/enekosuke/pokemon-duallocke-3ds/archive/refs/heads/main.zip` y extráelo ahí manteniendo la carpeta `Pokemon-DualLocke-3DS`).

2. INSTALACIÓN AUTOMÁTICA DE TODO + RADMIN VPN:
   - Entra en `%USERPROFILE%\Downloads\Pokemon-DualLocke-3DS` y ejecuta:
     `powershell -NoProfile -ExecutionPolicy Bypass -File .\setup.ps1 -InstallRadminVPN`
   - Esto instala y preconfigura en modo portátil:
     * Azahar 2126.2 (en español, resolución 2x HD, carpeta `roms\` añadida)
     * Universal Pokémon Randomizer FVX v1.6.3 (con Java incluido)
     * PKHeX + .NET Windows Desktop Runtime (para Caramelos Raros y exportar equipo)
     * Radmin VPN (para conectar mi PC con el de Eneko desde casa)
   - Si Radmin VPN no quedó instalado porque saltó o falló el aviso de administrador (UAC), avísame claramente o ejecuta `winget install Famatech.RadminVPN` y dime qué botón pulsar.

3. REVISIÓN OBLIGATORIA DEL DRIVER DE MI GRÁFICA (GTX 1050):
   - Comprueba la fecha y versión real del driver de mi NVIDIA GeForce GTX 1050 con:
     `Get-CimInstance Win32_VideoController | Select-Object Name, DriverVersion, DriverDate`
   - Mi portátil tenía un driver de mayo de 2017 (`22.21.13.8205`). Si sigue siendo anterior a 2023, AVÍSAME EN MAYÚSCULAS al principio de tu respuesta y dame el enlace oficial (`https://www.nvidia.com/es-es/drivers/`) indicándome paso a paso qué elegir (`GeForce` -> `GeForce GTX 10 Series (Notebooks)` -> `GeForce GTX 1050` -> `Windows 10/11 64-bit` -> `Game Ready Driver`), darle a `Instalación rápida` y reiniciar el portátil.

4. FIREWALL PARA MULTIJUGADOR (AZAHAR + RADMIN VPN):
   - Comprueba si hay reglas de Firewall de Windows bloqueando `tools\azahar\azahar.exe` y añade reglas de entrada/salida si tienes permisos (o dime en 2 pasos cómo permitir Azahar si salta el aviso del Firewall de Windows al abrirlo).

5. ROM DE POKÉMON Y + GENERACIÓN DE MI SEMILLA DISTINTA (MISMO PRESET QUE ENEKO):
   - Busca si ya tengo la ROM de Pokémon Y (`.cci`, `.3ds`, `.7z` o `.zip`) en `%USERPROFILE%\Downloads` o en `roms\`. Si está comprimida (`.7z` o `.zip`), descomprímela tú automáticamente en `roms\` (limpiando archivos basura si los hubiera y dejando el `.cci` / `.3ds` limpio dentro de `roms\`).
   - En cuanto la ROM esté en `roms\`, ejecuta:
     `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\randomize-auto.ps1`
   - IMPORTANTE: NO uses la semilla `20261121` (esa es la de Eneko). El script sin parámetros genera automáticamente una semilla nueva aleatoria distinta usando exactamente el mismo archivo de reglas (`presets\pokemon-y-randomlocke.rnqs`: iniciales, salvajes, estáticos, habilidades sin Superguarda, ataques, MTs, objetos, gimnasios y entrenadores random + evoluciones por intercambio activadas + Caramelos Raros baratos) y lo instala automáticamente en `tools\azahar\user\load\mods\0004000000055E00\`.
   - Si todavía no tengo la ROM descargada en el PC, dímelo claro: necesito el archivo desencriptado `Pokemon Y (USA) (En,Ja,Fr,De,Es,It,Ko).cci` (o `.3ds`) metido en la carpeta `roms\`, y que en cuanto lo ponga o lo descargue te avise para que tú termines este paso por mí.

6. ACCESO DIRECTO DE 1 CLIC Y COMPROBACIÓN FINAL:
   - Crea también un acceso directo en mi Escritorio apuntando a `0-JUGAR-POKEMON-Y.bat` llamado `Jugar Pokemon Y Randomlocke` para que solo tenga que hacer doble clic ahí.
   - Verifica en disco que existen: `tools\azahar\azahar.exe`, `tools\azahar\user\config\qt-config.ini`, `tools\upr-fvx\UPR-FVX.jar`, `tools\pkhex\PKHeX.exe`, Radmin VPN, la ROM en `roms\` y el mod en `tools\azahar\user\load\mods\0004000000055E00\romfs`.
   - Al final, explícame como para alguien que no sabe de informática:
     a) Cómo abrir el juego con 1 clic (`Jugar Pokemon Y Randomlocke` en el Escritorio) y configurar mi teclado/mando la primera vez en Azahar.
     b) Cómo abrir Radmin VPN, encenderlo (`Encender`) y hacer `Red -> Unirse a una red` con el nombre y contraseña que me diga Eneko.
     c) Cómo conectarme a su sala en Azahar (`Multijugador -> Conexión directa a una sala`, metiendo su IP `26.x.x.x` y puerto `24872`) y retarle por el **PSS** dentro del juego (sin pulsar el botón azul de Internet).
     d) Cómo exportar mi equipo con `4-Abrir-PKHeX.bat` a Pokémon Showdown (`[Gen 6] Custom Game`) por si alguna vez preferimos combatir rápido en navegador.
```
