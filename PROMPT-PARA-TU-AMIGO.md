# 🤖 Prompt para pasarle a tu amigo (pegar entero en su Antigravity)

Copia este texto completo y pásaselo a tu amigo para que lo pegue tal cual en su **Antigravity**:

---

```text
Hola, quiero que me montes y configures AL MILÍMETRO mi portátil para jugar un Pokémon Y Randomlocke / DualLocke de Nintendo 3DS online contra mi amigo Eneko (cada uno desde su casa). No sé mucho de ordenadores, así que haz tú todos los comandos posibles por mí y explícame con pasos clarísimos lo poco que tenga que pulsar yo.

Todo el entorno, instalador, preset de randomización y guía están en este repositorio de GitHub:
https://github.com/enekosuke/pokemon-duallocke-3ds

Ejecuta estos pasos en orden y verifica cada uno:

1. DESCARGA DEL ENTORNO:
   - Clona o descarga el repo https://github.com/enekosuke/pokemon-duallocke-3ds en `%USERPROFILE%\Downloads\Pokemon-DualLocke-3DS` (si no tengo `git`, descarga el ZIP de `https://github.com/enekosuke/pokemon-duallocke-3ds/archive/refs/heads/main.zip` y extráelo ahí).

2. INSTALACIÓN AUTOMÁTICA DE PROGRAMAS + RADMIN VPN:
   - Entra en esa carpeta y ejecuta:
     `powershell -NoProfile -ExecutionPolicy Bypass -File .\setup.ps1 -InstallRadminVPN`
   - Esto instalará Azahar 2126.2 (portátil, preconfigurado en español y HD 2x), Universal Pokémon Randomizer FVX v1.6.3, PKHeX, .NET Windows Desktop Runtime (si falta) y Radmin VPN.
   - Si Radmin VPN no quedó instalado por algún aviso de administrador (UAC), dime exactamente cómo aceptar la ventana o instálalo con `winget install Famatech.RadminVPN` y espera a que lo confirme.

3. REVISIÓN OBLIGATORIA DE DRIVER GRÁFICO (GTX 1050):
   - Comprueba la fecha y versión real del driver de mi NVIDIA GeForce GTX 1050 con PowerShell (`Get-CimInstance Win32_VideoController`).
   - Mi portátil tenía un driver de mayo de 2017 (`22.21.13.8205`). Si sigue siendo antiguo (anterior a 2023), DÍMELO EN MAYÚSCULAS como aviso prioritario y dame el enlace directo de NVIDIA (`https://www.nvidia.com/es-es/drivers/`) explicándome paso a paso qué elegir (GeForce -> GeForce GTX 10 Series (Notebooks) -> GeForce GTX 1050 -> Windows 10/11 64-bit -> Game Ready Driver) e instalarlo como "Instalación rápida" y reiniciar el PC.

4. FIREWALL PARA MULTIJUGADOR (AZAHAR + RADMIN VPN):
   - Revisa o añade reglas de firewall de Windows (si tienes permisos, o dime si hace falta) para que `tools\azahar\azahar.exe` pueda conectarse sin bloqueos por Radmin VPN.

5. ROM Y PARChE RANDOMLOCKE EXACTO (MISMA SEMILLA QUE ENEKO):
   - Comprueba si ya tengo una ROM `.cci` o `.3ds` (o un `.7z`/`.zip`) en `%USERPROFILE%\Downloads` o en `roms\`. Si tengo un archivo comprimido de Pokémon Y en Descargas, descomprímelo tú directamente en `roms\`.
   - En cuanto esté la ROM `.cci`/`.3ds` de Pokémon Y en `roms\`, ejecuta:
     `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\randomize-auto.ps1`
   - Eso generará exactamente la misma partida randomizada de Eneko (`presets\pokemon-y-randomlocke.rnqs` + semilla `20261121`) y la instalará automáticamente en `tools\azahar\user\load\mods\0004000000055E00\`.
   - Si todavía no he puesto la ROM, dime exactamente qué archivo tengo que meter en `roms\` (la misma ROM `Pokemon Y (USA) (En,Ja,Fr,De,Es,It,Ko).cci` desencriptada que tiene Eneko) y que en cuanto la meta te avise para que tú ejecutes `randomize-auto.ps1` por mí.

6. VERIFICACIÓN FINAL Y GUÍA DE USO PARA MÍ:
   - Al terminar, haz un resumen claro de qué está listo (`Azahar`, `UPR FVX`, `PKHeX`, `Radmin VPN`, `Driver GPU`, `ROM` y `Mod Randomlocke`) y explícame con botones sencillos:
     a) Cómo abrir el juego con un clic (`0-JUGAR-POKEMON-Y.bat`) y configurar mi mando/teclado la primera vez.
     b) Cómo abrir Radmin VPN, encenderlo y unirme a la red que cree Eneko.
     c) Cómo conectarme en Azahar (`Multijugador -> Conexión directa a una sala` con la IP `26.x.x.x` de Radmin VPN de Eneko y puerto `24872`) y combatir dentro del juego por el PSS (sin darle al botón de Internet).
```
