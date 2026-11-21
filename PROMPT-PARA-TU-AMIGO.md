# 🤖 Prompt para pasarle a tu amigo (para pegar en Antigravity)

Copia el bloque de abajo entero y pásaselo a tu amigo para que se lo pegue directamente a su **Antigravity**:

---

```text
Hola, quiero montar en mi portátil el entorno completo para jugar un Pokémon Randomlocke / DualLocke de Nintendo 3DS online contra mi amigo Eneko (cada uno desde su casa).

Todo el entorno, scripts y guía están en este repositorio de GitHub:
https://github.com/enekosuke/pokemon-duallocke-3ds

Por favor, haz todo esto por mí paso a paso y explícamelo en lenguaje muy sencillo (no sé mucho de ordenadores):

1. Clona el repositorio en `C:\Users\Public\Pokemon-DualLocke-3DS` o en mi carpeta de Descargas (`%USERPROFILE%\Downloads\Pokemon-DualLocke-3DS`). Si no tengo Git instalado, descárgalo como ZIP desde GitHub y descomprímelo ahí.
2. Ejecuta `setup.ps1` con `-InstallRadminVPN` (`powershell -ExecutionPolicy Bypass -File .\setup.ps1 -InstallRadminVPN`) para instalar automáticamente:
   - Azahar (emulador de 3DS en modo portátil)
   - Universal Pokémon Randomizer FVX
   - PKHeX + .NET Desktop Runtime (si me falta)
   - Radmin VPN (para poder combatir contra Eneko desde mi casa)
3. IMPORTANTE: Comprueba la fecha del driver de mi tarjeta gráfica NVIDIA GeForce GTX 1050. Si sigue siendo un driver antiguo (de 2017 o anterior a 2023), avísame claramente y dame el enlace directo oficial de NVIDIA para actualizarlo y decirme qué pulsar, porque si no Azahar con Vulkan/OpenGL me puede fallar.
4. Verifica que `Azahar`, `UPR FVX`, `PKHeX` y `Radmin VPN` han quedado correctamente instalados y dime qué falta por hacer manualmente (solo meter la ROM desencriptada en `roms\`, instalar la carpetita del mod LayeredFS que me pase Eneko usando `5-Instalar-Mod-LayeredFS.bat`, y conectarme a su red de Radmin VPN).
5. Guíame paso a paso cuando yo te diga que ya tengo la ROM y el mod que me pase Eneko.
```
