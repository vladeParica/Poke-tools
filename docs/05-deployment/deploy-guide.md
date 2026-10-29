# Instalación y publicación — Poke-tools

> **Fase AI-DLC:** `05-deployment`
> No hay servidores: "desplegar" es instalar el script en la PC del jugador y publicar
> una versión en GitHub.

## 1. Requisitos del jugador
| Qué | Para qué | Notas |
|---|---|---|
| VBA-rr con Lua | Ejecutar los bots | Desactivar *Pause When Inactive* |
| ROM de Rojo Fuego o Verde Hoja | El juego | No se incluye ni se distribuye |
| `curl` | Avisos del Train Bot (opcional) | Viene con Windows 10/11 |

## 2. Instalación
1. Descarga el `.lua` y el `.json` del bot (desde la carpeta `shinybot/` o `trainbot/`,
   o desde una versión publicada en *Releases*).
2. Ponlos juntos en una carpeta. Para el Train Bot, añade la ruta (`FRLG_TrainRoute*.txt`)
   si usas una ya grabada.
3. Guarda la partida en el lugar donde va a trabajar el bot (los modos con soft reset
   vuelven a esa partida).
4. VBA-rr → *Tools → Lua Scripting → New Lua Script Window* → abre el `.lua` → *Run*.
5. Comprueba en la consola la línea `Juego: FireRed USA…` (juego e idioma detectados).
6. Pulsa **7**.

**Configuración secreta:** el único dato sensible es `notify` (tema de ntfy o webhook de
Discord). Va en tu JSON local; no lo subas a ningún repositorio.

## 3. Actualizar
1. Detén el bot (**7**) y cierra la ventana de Lua.
2. Reemplaza solo el `.lua`; **conserva tu JSON y tus rutas**.
3. Revisa el [CHANGELOG](../../CHANGELOG.md) por si alguna opción cambió de nombre.

**Volver atrás:** usa el `.lua` de la versión anterior (en *Releases* o en el historial de git).

## 4. Publicar una versión (mantenedor)
1. Actualiza la versión en el `print` de inicio del bot (`src/`), regenera con `build.py`.
2. Corre todas las pruebas ([estrategia](../04-testing/test-strategy.md)) y prueba en el juego real.
3. Pasa las entradas de `[Sin publicar]` del `CHANGELOG.md` a la nueva versión.
4. Commit `chore: version shinybot vX.Y` (o `trainbot`), etiqueta `shinybot-vX.Y` /
   `trainbot-vX.Y` y sube (con el OK del dueño).
5. Crea el *Release* en GitHub adjuntando el `.lua` y el `.json` del bot.

## 5. Lista antes de publicar
- [ ] CI en verde (build al día + simulador sin errores)
- [ ] Probado en el juego real (o anotado que no se pudo)
- [ ] `CHANGELOG.md` y [contratos](../02-design/api-contracts.md) al día si cambió el JSON, la ruta o las teclas
- [ ] Ningún JSON con `notify` real, ninguna ROM ni partida en el commit
