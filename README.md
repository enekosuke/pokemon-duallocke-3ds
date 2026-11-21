# 🎮 Pokémon DualLocke 3DS — Pack Portátil y Guía Completa

Entorno completo, portátil y preconfigurado para jugar un **Pokémon Y Randomlocke / DualLocke de Nintendo 3DS** en PC, cada uno desde su casa y haciendo **combates entre vosotros con exactamente vuestros Pokémon randomizados**.

---

## ⚡ Inicio rápido con UN SOLO CLIC

Una vez completada la instalación inicial:
* Haz doble clic en **`0-JUGAR-POKEMON-Y.bat`** → abre **Azahar** y arranca **Pokémon Y Randomlocke** directamente.

---

## 📦 Qué incluye este repositorio

| Archivo / Carpeta | Para qué sirve |
| :--- | :--- |
| `0-JUGAR-POKEMON-Y.bat` | **Botón de 1 clic:** arranca directamente **Pokémon Y Randomlocke** en Azahar. |
| `1-Instalar-o-Reparar-Todo.bat` | Instala y preconfigura todo (`Azahar`, `UPR FVX`, `PKHeX`, `.NET`, `qt-config.ini`, drivers y mod automático si hay ROM). |
| `2-Abrir-Randomizer.bat` | Abre **Universal Pokémon Randomizer FVX** por si queréis cambiar opciones a mano. |
| `3-Abrir-Azahar.bat` | Abre el menú principal del emulador **Azahar** (en español y 2x HD). |
| `4-Abrir-PKHeX.bat` | Abre **PKHeX** para añadir Caramelos Raros / objetos o exportar tu equipo a Showdown. |
| `5-Instalar-Mod-LayeredFS.bat` | Instala manualmente una carpeta de mod LayeredFS en Azahar. |
| `6-Backup-Save.bat` | Hace copia de seguridad de tu partida guardada (`main`) y te muestra su ruta exacta. |
| `7-Tracker-DualLocke.html` | Tracker visual en navegador (marcador PVP entre vosotros, vidas, muertes, rutas y *Level Caps*). |
| `presets/pokemon-y-randomlocke.rnqs` | Preset exacto de reglas (Pokémon, habilidades sin Superguarda, ataques, MTs, objetos, gimnasios/entrenadores random + evoluciones por intercambio activadas + Caramelos baratos en tiendas). |
| `scripts/randomize-auto.ps1` | Genera e instala automáticamente el mod LayeredFS con la **semilla fija `20261121`** para que ambos jugadores tengáis exactamente el mismo mundo. |

---

## 🛠️ Paso 1: Instalación inicial (en ambos PCs)

### 1.1. Ejecutar el instalador
1. Descarga o clona este repositorio en tu PC (por ejemplo en `Descargas\Pokemon-DualLocke-3DS`).
2. Ejecuta en PowerShell (para instalar también Radmin VPN automáticamente):
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\setup.ps1 -InstallRadminVPN
   ```
   *(O haz doble clic en `1-Instalar-o-Reparar-Todo.bat` e instala Radmin VPN manualmente).*
3. **IMPORTANTE — Driver de tarjeta gráfica:**
   * Si `setup.ps1` avisa de que tu driver NVIDIA/AMD es antiguo (por ejemplo de 2017–2022), descárgalo desde [nvidia.com/es-es/drivers](https://www.nvidia.com/es-es/drivers/), instálalo (Express) y reinicia el PC.

### 1.2. Colocar la ROM de Pokémon Y
1. Coloca la misma ROM desencriptada **`Pokemon Y (USA) (En,Ja,Fr,De,Es,It,Ko).cci`** (o `.3ds`) dentro de la carpeta **`roms\`**.
   *(Esta ROM incluye Español; el idioma se elige al empezar la partida).*
2. Si la pusiste **después** de ejecutar `setup.ps1`, ejecuta una sola vez:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\scripts\randomize-auto.ps1
   ```
   Esto genera el parche **LayeredFS** con la semilla fija **`20261121`** y lo instala automáticamente en `tools\azahar\user\load\mods\0004000000055E00\`.
   *(Alternativamente, el primer jugador puede comprimir en `.zip` su carpeta `mods-para-compartir\pokemon-y-randomlocke\0004000000055E00` y pasársela al otro por Discord para instalarla con `5-Instalar-Mod-LayeredFS.bat`).*

---

## 🎲 Qué cambia la randomización automática (`pokemon-y-randomlocke.rnqs`)

* **Pokémon iniciales, salvajes y estáticos:** 100% random (iniciales sin legendarios).
* **Habilidades:** Random (con **Superguarda / Wonder Guard baneada** para evitar Pokémon inmortales).
* **Ataques y MTs:** Movesets por nivel random (con 2 ataques asegurados al inicio para no quedarte sin movimientos ofensivos) + MTs random manteniendo MOs de campo para no atascar la historia.
* **Gimnasios, Entrenadores y Alto Mando:** Pokémon totalmente random (sin repetidos en el mismo entrenador).
* **Objetos:** Objetos del suelo y habilidad Recogida random (tiendas normales + Caramelos Raros baratos habilitados).
* **Evoluciones:** Evoluciones por intercambio desbloqueadas para que evolucionen solos por nivel/objeto.

---

## 🎮 Paso 2: Jugar y configurar controles / velocidad

1. Haz doble clic en **`0-JUGAR-POKEMON-Y.bat`**.
2. La primera vez, ve a **Emulación → Configurar → Controles** para mapear tu teclado o mando (Xbox/PS).
3. En **Emulación → Configurar → General → Teclas rápidas**, asigna una tecla a **Alternar límite de velocidad** (por ejemplo `Tab`) para acelerar combates/diálogos cuando juegues solo.
4. En **Emulación → Configurar → Gráficos**, está preconfigurado a **2x HD**. Si tienes gráfica NVIDIA con driver actualizado, puedes probar `Vulkan` en API gráfica para máximo rendimiento (o dejar `OpenGL` si te va perfecto).

---

## 🌐 Paso 3: Conectar por VPN y combatir desde casa (Azahar + Radmin VPN)

### 3.1. Configurar Radmin VPN (una sola vez)
1. Abrid **Radmin VPN** ambos y pulsad el botón grande de **Encender**.
2. **Anfitrión (Eneko):** menú **Red → Crear red** → pon un nombre (ej. `PokemonDualLocke3DS`) y una contraseña.
3. **Amigo:** menú **Red → Unirse a una red** → escribe el mismo nombre y contraseña.
4. En Radmin VPN veréis aparecer al otro en verde. El **anfitrión** copia su **IP de Radmin VPN** (empieza por `26.x.x.x`).

### 3.2. Crear y unirse a la sala multijugador en Azahar
1. **Anfitrión:** con Azahar abierto ve a **Multijugador → Crear sala** → pon nombre de sala, deja puerto `24872`, contraseña opcional → **Crear**.
2. **Amigo:** con Azahar abierto ve a **Multijugador → Conexión directa a una sala** →
   * **Dirección IP:** pega la IP `26.x.x.x` de Radmin VPN del anfitrión.
   * **Puerto:** `24872`.
   * **Apodo:** tu nombre.
   * Pulsa **Conectar**.
3. Veréis ambos apodos en la lista de la sala de Azahar.

### 3.3. Lanzar el combate PVP dentro de Pokémon Y
1. En la pantalla inferior de Pokémon Y (una vez tengáis el **PSS** desbloqueado, a los pocos minutos de empezar), abrid el **PSS** (pantalla amarilla).
2. **IMPORTANTE:** **NO** pulséis el botón azul de Internet (los servidores de Nintendo cerraron). La sala de Azahar simula la **conexión inalámbrica local**.
3. Os apareceréis automáticamente en la fila de **Transeúntes** (o Amigos).
4. Toca el icono de tu amigo → **Combatir** → elegid reglas (Combate Individual / Doble, Nivel normal o Igualar al Nv. 50) → **¡A pelear con vuestros Pokémon randomizados!**

> ⚠️ **Regla clave durante el combate:** desactivad ambos el *Fast-Forward* (acelerador de velocidad) mientras combatís para evitar desincronizaciones.

---

## 🍬 Paso 4: Añadir Caramelos Raros (PKHeX) y Plan B (Pokémon Showdown)

### Añadir Caramelos Raros sin perder horas farmeando
1. Guarda partida dentro del juego y **cierra Azahar**.
2. Ejecuta **`6-Backup-Save.bat`** (hace copia de seguridad y te muestra la ruta exacta de tu archivo `main`).
3. Abre **`4-Abrir-PKHeX.bat`** y arrastra ese archivo `main` dentro.
4. Ve a **SAV → Items → Medicine**, busca **Rare Candy** y pon la cantidad pactada.
5. Pulsa **Save** → **File → Export SAV → Export main** (sobrescribe el `main`).

### Plan B de combate por navegador (Pokémon Showdown)
Si alguna vez queréis combatir rápido sin abrir salas:
1. Abre tu `main` en PKHeX → **Tools → Showdown → Export Party to Clipboard**.
2. Entra en [pokemonshowdown.com](https://pokemonshowdown.com/) → **Teambuilder → New Team** → formato **`[Gen 6] Custom Game`** → **Import from text** → pega tu equipo.
3. Reta a tu amigo en formato **`[Gen 6] Custom Game`**.

---

## 🆘 Solución rápida de problemas

| Problema | Solución |
| :--- | :--- |
| **Azahar da pantalla negra, se cierra o va a tirones** | Actualiza el driver de la gráfica (NVIDIA/AMD/Intel) y reinicia. Prueba cambiar en **Configurar → Gráficos → API** entre `OpenGL` y `Vulkan`. |
| **El juego sale sin randomizar** | Ejecuta `powershell -ExecutionPolicy Bypass -File scripts\randomize-auto.ps1` o comprueba que existe `tools\azahar\user\load\mods\0004000000055E00\romfs`. |
| **No nos conectamos en Azahar / Radmin VPN** | Comprobad que el Firewall de Windows no bloquee `azahar.exe` (permitir en redes Privadas y Públicas) y que ambos tenéis luz verde en Radmin VPN. |
| **PKHeX no abre** | Instala `.NET Desktop Runtime 10` ejecutando `setup.ps1` o desde [dotnet.microsoft.com](https://dotnet.microsoft.com/download/dotnet). |
