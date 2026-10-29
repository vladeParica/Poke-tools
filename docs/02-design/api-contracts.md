# Contratos — Poke-tools

> **Fase AI-DLC:** `02-design`
> No hay API de red. Los contratos públicos son lo que el jugador escribe o guarda: el
> **JSON de configuración**, el **archivo de ruta**, las **teclas** y los **archivos que
> genera** cada bot. Cambiar cualquiera de ellos rompe la configuración o las rutas de
> los usuarios: se anota en el `CHANGELOG.md`.
>
> **Fuente de verdad:** la tabla `CONFIG` al principio de `shinybot/src/bot_body.lua` y de
> `trainbot/src/train_body.lua` (valores por defecto) y los JSON comentados de cada bot.

## Convenciones del JSON
- Archivo `FRLG_ShinyBot.json` / `FRLG_TrainBot.json` en la **misma carpeta** que el script.
- JSON con comentarios `//` ([ADR-0004](../00-project/adr/0004-configuracion-json-comentado.md)).
- `null` (u omitir la clave) = valor por defecto.
- Estadísticas: `hp, atk, def, spa, spd, spe` o `ps, ata, def, ate, dfe, vel`.
- Naturalezas en inglés o español; especies y ataques con el nombre en inglés del juego.
- Errores: el bot no arranca, los lista en la consola y espera a que se pulse **0**.

## Shiny Bot — `FRLG_ShinyBot.json`

| Clave | Tipo | Por defecto | Qué hace |
|---|---|---|---|
| `shiny` | bool | `true` | Exigir shiny |
| `species` | lista de texto | `null` | Solo estas especies (modos salvajes) |
| `natures` | lista de texto | `null` | Naturalezas aceptadas |
| `minIVs` / `maxIVs` | objeto estadística → 0–31 | `null` | Rango de IVs |
| `minIVTotal` | número 0–186 | `null` | Suma mínima de IVs |
| `hiddenPower` | `{type, minPower}` | `null` | Poder Oculto |
| `mode` | texto | `null` (el JSON incluido trae `"Salvaje RNG"`) | Modo al cargar |
| `newGameTSV` | lista de texto hex | `null` = TSV que dan Ditto 6×31 shiny | Partida nueva |
| `initialSeeds` | lista de texto hex | `null` | Semillas para el modo Semilla inicial |
| `afterSeedMode` | texto | `null` | Modo a lanzar al caer en la semilla |
| `walkAxis` | `"horizontal"` \| `"vertical"` | `"horizontal"` | Eje de la caminata |
| `walkFrames` | número | `16` | Frames por paso |
| `holdB` | bool | `false` | Correr (solo Salvaje) |
| `wildOneStep` | bool | `true` | Salvaje RNG: acercarse a un paso del encuentro |
| `pressGapMin` / `pressGapMax` | número | `2` / `24` | Espera al azar entre pulsaciones de A |
| `resetTimeout` | número | `5400` | Frames sin resultado antes de reiniciar |
| `farSearch` | número | `20000000` | Avances a revisar buscando objetivo |
| `teachy` | bool | `true` | Usar la Tele Pokémon (registrada en SELECT) |
| `teachyBeyond` | número | `5000` | Usarla si ahorra más de estos avances |
| `teachyMargin` | número | `null` = retraso + 1500 | Cerrarla estos avances antes |
| `triesPerTarget` | número | `10` | Intentos de corrección por objetivo |
| `reseed` | bool | `true` | Soft reset para otra semilla si no hay objetivo |
| `reseedAfterFailedTargets` | número | `3` | Objetivos fallidos antes de cambiar semilla |
| `maxReseeds` | número | `10` | Máximo de cambios de semilla |
| `savestateSlot` | 1–10 | `null` | Guardar estado solo (en VBA-rr v22 da error) |
| `logFile` | texto | `"shiny_log.txt"` | Log de hallazgos |
| `stopOthers` | bool | `true` | Detener las demás instancias al encontrar |
| `sharedDir` | texto | `null` = carpeta del script | Carpeta compartida entre instancias (`logDir` va dentro) |
| `logDir` | texto | `"logs"` | Subcarpeta de logs y archivos de trabajo |
| `resetOnLoad` | bool | `true` | Reiniciar el juego al cargar el script |

Obsoletas, se ignoran: `rngMaxSearch`, `wildMaxSearch`, `reseedBeyond`.

## Train Bot — `FRLG_TrainBot.json`

| Clave | Tipo | Por defecto | Qué hace |
|---|---|---|---|
| `evs` | objeto estadística → 0–255 | `null` = solo nivel | EVs objetivo (máx. 510 en total) |
| `targetLevel` | número | `null` | Nivel objetivo |
| `maxLevel` | número | `null` | Detenerse a este nivel aunque falten EVs |
| `species` | lista de texto | `null` = según los EVs | Pelear solo contra estas |
| `avoidSpecies` | lista de texto | `null` (el JSON incluido trae las que se autodestruyen) | Nunca pelear contra estas |
| `allowOvershoot` | bool | `false` | Permitir pasarse del objetivo |
| `healBelow` | % | `40` | Curarse tras el combate bajo este % de PS |
| `fleeBelow` | % | `20` | Huir en pleno combate bajo este % |
| `minPP` | número | `3` | Curarse si quedan menos PP en ataques que hacen daño |
| `learnMoves` | `"auto"` \| `"never"` \| `"ask"` | `"auto"` | Qué hacer con ataques nuevos |
| `wantedMoves` | lista (máx. 4) | `null` | Solo aprender estos |
| `keepMoves` | lista | `null` | Nunca olvidar estos |
| `askTimeout` | segundos | `300` | Con `ask`: cuánto esperar antes de decidir solo |
| `evolve` | bool | `false` | Dejar evolucionar |
| `stopOnShiny` | bool | `true` | Pausar con un shiny salvaje |
| `notify` | `{ntfy, discord}` | `null` | Avisos al celular |
| `walkAxis` / `walkFrames` | como el Shiny Bot | | |
| `routeFile` | texto | `"FRLG_TrainRoute.txt"` | Archivo de ruta |
| `healMode` | `"nurse"` \| `"tile"` | `"nurse"` | Enfermera o casilla que cura |
| `logFile` / `logDir` | texto | `"train_log.txt"` / `"logs"` | Log |

`notify.ntfy` debe cumplir `[A-Za-z0-9_-]+`; `notify.discord` debe empezar por `https://`.
Si no, el aviso no se envía.

## Archivo de ruta — `FRLG_TrainRoute*.txt`

```
GO grupo mapa x y dir;grupo mapa x y dir;...
BACK grupo mapa x y dir;...
```
- `GO`: del punto de entreno al lugar de curación. `BACK`: de vuelta.
- `x`, `y`: coordenadas de memoria (casilla del mapa + 7). `dir`: 0 ninguna, 1 abajo,
  2 arriba, 3 izquierda, 4 derecha.
- El último paso de `BACK` es el **punto de entreno**. Detalles y rutas listas en
  [`trainbot/examples/routes/`](../../trainbot/examples/routes/README.md).

## Teclas

| Tecla | Shiny Bot | Train Bot |
|---|---|---|
| 6 | — | Grabar ruta (ida, curación, vuelta) |
| 7 | Iniciar / detener | Iniciar / detener |
| 8 | Cambiar modo | Ficha completa del Pokémon |
| 9 | Panel compacto / completo / oculto | Panel compacto / completo / oculto |
| 0 | Recargar JSON | Recargar JSON (con el bot detenido) |

## Archivos que generan los bots

| Archivo | Bot | Dónde | Para qué |
|---|---|---|---|
| `shiny_log.txt` | Shiny | `logDir` | Hallazgos con PID, naturaleza, IVs e intentos |
| `inst_N.lock` | Shiny | `logDir` | Instancia N viva (varias ventanas) |
| `shiny_stop.flag` | Shiny | `logDir` | Una instancia encontró el objetivo: las demás paran |
| `train_log.txt` | Train | `logDir` | Combates, EVs, ataques aprendidos, curaciones |
| `train_running.lock` | Train | `logDir` | Impide dos Train Bot a la vez |
| `FRLG_TrainRoute.txt` | Train | carpeta del script | Ruta grabada con la tecla 6 |

## Memoria del juego
Las direcciones y estructuras que leen los bots (equipo, combate, mapa, RNG) están en la
sección **Direcciones** de [`CLAUDE.md`](../../CLAUDE.md), con la versión USA como
referencia y la regla de desplazamientos de [ADR-0006](../00-project/adr/0006-direcciones-relativas.md).
