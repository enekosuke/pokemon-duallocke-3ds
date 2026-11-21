# 🎮 Pokémon DualLocke 3DS — Pack Portátil y Guía Completa

Entorno listo para jugar un **Pokémon Randomlocke / DualLocke de Nintendo 3DS** en PC (Gen 6: *X/Y*, *Rubí Omega/Zafiro Alfa*; o Gen 7: *Sol/Luna*, *Ultrasol/Ultraluna*), cada uno desde su casa y haciendo **combates entre vosotros con exactamente vuestros Pokémon randomizados**.

---

## 📦 Qué incluye este repositorio

Todo funciona de forma **portátil** dentro de una sola carpeta (no ensucia el sistema):

| Archivo | Para qué sirve |
| :--- | :--- |
| `1-Instalar-o-Reparar-Todo.bat` | Descarga e instala automáticamente **Azahar** (emulador 3DS), **UPR FVX** (randomizador con Java incluido) y **PKHeX** (Caramelos Raros + exportar a Showdown). También revisa drivers de gráfica y `.NET`. |
| `2-Abrir-Randomizer.bat` | Abre **Universal Pokémon Randomizer FVX** para randomizar la ROM. |
| `3-Abrir-Azahar.bat` | Abre el emulador de 3DS **Azahar** en modo portátil (`tools/azahar/user`). |
| `4-Abrir-PKHeX.bat` | Abre **PKHeX** para añadir Caramelos Raros / objetos o exportar tu equipo a Pokémon Showdown. |
| `5-Instalar-Mod-LayeredFS.bat` | Asistente automático para instalar el parche randomizado que os paséis por Discord. |
| `6-Backup-Save.bat` | Hace una copia de seguridad con fecha y hora de tu partida guardada (`main`). |
| `7-Tracker-DualLocke.html` | Tracker visual en navegador (marcador PVP entre vosotros, vidas, muertes, rutas y *Level Caps* de Gen 6 y 7). |

---

## 🛠️ Paso 1: Instalación inicial (en ambos PCs)

### 1.1. Ejecutar el instalador
1. Descarga o clona este repositorio en tu PC (por ejemplo en `Descargas\Pokemon-DualLocke-3DS`).
2. Haz doble clic en **`1-Instalar-o-Reparar-Todo.bat`**.
3. Espera 1–2 minutos mientras descarga y verifica todo automáticamente.
   * Si el script avisa de que **tu driver de tarjeta gráfica NVIDIA es antiguo** (por ejemplo de 2017–2021), actualízalo desde [nvidia.com/es-es/drivers](https://www.nvidia.com/es-es/drivers/) y reinicia el PC. Esto evita pantallazos o bajones de FPS en Azahar.
4. Instala **Radmin VPN** (gratis, necesario solo si queréis combatir dentro del propio juego de 3DS desde casa):
   * Descarga: [radmin-vpn.com](https://www.radmin-vpn.com/) (o en PowerShell: `winget install Famatech.RadminVPN`).

### 1.2. Colocar la ROM base
1. Consigue la ROM **desencriptada** (`.3ds`, `.cci` o `.cxi`) del mismo juego de Pokémon 3DS para los dos.
2. Métela dentro de la carpeta **`roms\`**.
   > ⚠️ **Importante:** la ROM debe estar **desencriptada** (*decrypted*). Si está encriptada, ni el Randomizer ni Azahar podrán abrirla.

---

## 🎲 Paso 2: Randomizar el juego (solo lo hace UNA persona)

> 💡 **Consejo para DualLocke:** solo uno de los dos tiene que randomizar. Al exportar en formato **LayeredFS**, se crea una carpetita de pocos megas que se comprime en `.zip` y se pasa por Discord al otro jugador. Así **ambos jugáis exactamente el mismo juego randomizado** sin pasar archivos de 3 GB.

1. Abre **`2-Abrir-Randomizer.bat`**.
2. Arriba a la derecha pulsa **Open ROM** y selecciona tu ROM de la carpeta `roms\`.
3. Configura los ajustes recomendados para vuestro Randomlocke:
   * **Starters, Statics & Trades:**
     * *Starter Pokémon:* **Random (completely)** o **Random (basic Pokémon with 2 evolutions)** *(recomendado para que los iniciales evolucionen)*.
     * *Static Pokémon:* **Random**.
   * **Wild Pokémon (Pokémon salvajes):**
     * Marca **Random** (puedes elegir **Similar Strength** para que no salga un legendario al nivel 3 en la Ruta 1, o **Completely Random** para caos total).
   * **Pokémon Abilities (Habilidades):**
     * Marca **Random** y activa **Ban Wonder Guard** *(muy recomendado para evitar Pokémon casi inmortales con Superguarda)*.
   * **Moves & Movesets (Ataques):**
     * *Movesets:* **Random (preferring same type)** *(equilibrado)* o **Random (completely)** *(caos total)*.
     * *TMs (MTs):* **Random**.
   * **Trainers Pokémon (Gimnasios, Entrenadores y Alto Mando):**
     * Marca **Random** (opcional: activa **Similar Strength** y/o **Level Modifier +10%** si lo queréis más difícil).
   * **Field Items / Shops (Objetos):**
     * *Field Items:* **Random** (marca *Ban Bad Items* si no quieres basura inútil).
     * *Shops:* opcional **Random**.
   * **Pokémon Evolutions / Misc Tweaks:**
     * Activa **Change Impossible Evolutions** *(imprescindible: permite que Pokémon que evolucionaban por intercambio evolucionen por nivel u objeto)*.
     * Activa **Fastest Text** *(opcional, agiliza muchísimo la partida)*.
4. Pulsa **Randomize (Save)**.
5. Cuando pregunte el formato de salida de 3DS, elige **LayeredFS directory** y guárdalo dentro de **`mods-para-compartir\`** (por ejemplo `mods-para-compartir\mi-randomlocke`).
6. **Para ti:** ejecuta **`5-Instalar-Mod-LayeredFS.bat`**, elige el juego (1–8) y arrastra esa carpeta `mi-randomlocke`.
7. **Para tu amigo:** comprime la carpeta `mi-randomlocke` en `.zip`, pásasela por Discord y él solo tiene que descomprimirla y ejecutar su **`5-Instalar-Mod-LayeredFS.bat`**.

---

## ▶️ Paso 3: Arrancar y configurar Azahar (en ambos PCs)

1. Abre **`3-Abrir-Azahar.bat`**.
2. Haz doble clic en la zona central (*Añadir carpeta de juegos*) y elige la carpeta **`roms\`**.
3. Configura tus controles en **Emulación → Configurar → Controles** (teclado o mando de Xbox/PS).
4. En **Emulación → Configurar → Gráficos**:
   * **API gráfica:** `Vulkan` (si tienes NVIDIA con driver actualizado) u `OpenGL` si te diera algún fallo visual.
   * **Resolución interna:** `2x` o `3x` para verlo en HD.
5. En **Emulación → Configurar → General → Teclas rápidas**, asigna una tecla cómoda a **Toggle Speed Limit** (por ejemplo `Tab` o `Espacio`) para acelerar combates y diálogos.
6. Haz doble clic en el juego. ¡Si todo está bien, tus iniciales y Pokémon ya serán random!

---

## 🍬 Paso 4: Añadir Caramelos Raros (o cualquier objeto) con PKHeX

En los Lockes modernos es muy común usar **Caramelos Raros** respetando el **Level Cap** (mira `7-Tracker-DualLocke.html`) para no perder horas subiendo niveles en la hierba.

1. **Guarda partida dentro del juego** y **CIERRA Azahar por completo**.
2. Ejecuta **`6-Backup-Save.bat`**. Te hará una copia de seguridad automática y te imprimirá en pantalla la ruta exacta de tu archivo **`main`**.
3. Abre **`4-Abrir-PKHeX.bat`** y arrastra tu archivo `main` dentro de la ventana de PKHeX.
4. Ve a la pestaña **SAV → Items**.
5. En la pestaña **Medicine** (Medicinas), busca **Rare Candy** (*Caramelo Raro*) y pon la cantidad pactada (por ejemplo `50` o `99`).
6. Pulsa **Save** en la ventana de Items y luego ve a **File → Export SAV → Export main** sobrescribiendo tu `main`.
7. Vuelve a abrir Azahar y carga tu partida.

---

## ⚔️ Paso 5: Cómo combatir entre vosotros cada uno desde su casa

Tenéis **dos métodos** que funcionan al 100% con vuestros Pokémon, habilidades y ataques randomizados:

### Método A — Combate directo dentro del juego de 3DS (Salas de Azahar + Radmin VPN)
*El más divertido: combatís dentro del propio juego con vuestras animaciones, música y Pokémon exactos.*

1. **Conectaros en Radmin VPN (una sola vez):**
   * Uno crea una red en Radmin VPN (**Red → Crear red**, nombre y contraseña).
   * El otro hace **Red → Unirse a una red** con ese nombre y contraseña.
   * El anfitrión copia su **IP de Radmin VPN** (empieza por `26.x.x.x`).
2. **Crear y unirse a la sala en Azahar:**
   * **Anfitrión:** en Azahar ve a **Multijugador → Crear sala** (pon un nombre, contraseña opcional y deja el puerto por defecto `24872`) → **Crear**.
   * **Amigo:** en Azahar ve a **Multijugador → Conexión directa a una sala**, pega la **IP `26.x.x.x`** del anfitrión, puerto `24872`, elige un apodo y pulsa **Conectar**.
   * Arriba/abajo en Azahar veréis a ambos conectados en la sala.
3. **Lanzar el combate dentro del juego:**
   * **En Gen 6 (X/Y, Rubí Omega/Zafiro Alfa):** abre el **PSS** en la pantalla inferior *(¡sin conectar a internet! Solo comunicación inalámbrica local)*. Apareceréis automáticamente en **Transeúntes**. Toca el icono de tu amigo → **Combatir**.
   * **En Gen 7 (Sol/Luna, Ultrasol/Ultraluna):** abre el menú → **Festi Plaza** *(en modo inalámbrico local, sin pulsar el botón azul de internet)*. Pulsa **Combatir → Conexión local** y elige a tu amigo.

> ⚠️ **Regla de oro para evitar desincronización:** ambos debéis llevar instalado **exactamente el mismo parche LayeredFS** y no usar *Fast-Forward* durante el combate.

### Método B — Plan B ultrarrápido por navegador (Pokémon Showdown)
*Úsalo si queréis combates rapidísimos o si algún día usáis semillas distintas con ataques/habilidades diferentes.*

1. Cierra Azahar y abre tu archivo `main` en **`4-Abrir-PKHeX.bat`**.
2. En PKHeX ve a **Tools → Showdown → Export Party to Clipboard** *(copia tus 6 Pokémon exactos con nivel, IVs, EVs, naturaleza, habilidad, objeto y ataques random)*.
3. Entra en [pokemonshowdown.com](https://pokemonshowdown.com/) → **Teambuilder → New Team**.
4. En formato elige **`[Gen 6] Custom Game`** (si jugáis X/Y/RO/ZA) o **`[Gen 7] Custom Game`** (si jugáis Sol/Luna/US/UM).
   * *Importante:* usa **Custom Game** porque es el único formato que acepta ataques y habilidades randomizadas.
5. Pulsa **Import from text**, pega el texto y guarda el equipo.
6. Busca el nombre de usuario de tu amigo en Showdown → **Challenge** → elige el formato `Custom Game` → **¡A combatir!**

---

## 🆘 Solución de problemas comunes

| Problema | Solución |
| :--- | :--- |
| **Azahar da pantalla negra, se cierra o va lento** | Actualiza el driver de tu gráfica (NVIDIA/AMD/Intel). Si sigue fallando, cambia en Azahar **Gráficos → API** de `Vulkan` a `OpenGL` (o viceversa). |
| **El Randomizer dice que la ROM está encriptada** | Necesitas una ROM desencriptada (*decrypted* `.3ds` / `.cci`). |
| **PKHeX no abre al hacer doble clic** | Falta `.NET Windows Desktop Runtime`. Ejecuta `1-Instalar-o-Reparar-Todo.bat` o instálalo desde [dotnet.microsoft.com](https://dotnet.microsoft.com/download/dotnet). |
| **El mod randomizado no se aplica al abrir el juego** | Ejecuta `5-Instalar-Mod-LayeredFS.bat` y asegúrate de haber elegido el juego correcto (X, Y, RO, ZA, Sol, Luna, US o UM). En Azahar, clic derecho al juego → *Abrir carpeta de mods*: dentro debe haber una carpeta `romfs`. |
| **No nos vemos en el PSS / Festi Plaza** | Comprobad que ambos estáis conectados en **Radmin VPN** (luz azul/verde), en la misma **sala de Azahar**, y que **NO** habéis activado el botón de Internet dentro del juego (es conexión **local**). |
