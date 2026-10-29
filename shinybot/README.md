# Shiny Bot — `FRLG_ShinyBot.lua`

Caza shinies y Pokémon con naturaleza e IVs exactos en Rojo Fuego / Verde Hoja, a ciegas
(soft reset) o manipulando el RNG.

## Uso

1. Copia `FRLG_ShinyBot.lua` y `FRLG_ShinyBot.json` a la misma carpeta.
2. VBA-rr → *Tools → Lua Scripting → New Lua Script Window* → abre el `.lua` → *Run*.
3. Elige el modo con **8** y pulsa **7** para iniciar.

| Tecla | Acción |
|---|---|
| **7** | Iniciar / detener |
| **8** | Cambiar de modo |
| **9** | Panel: compacto, completo u oculto |
| **0** | Recargar el JSON (con el bot detenido) |

Cuando encuentra lo que buscas, el juego queda **en pausa**: guarda un estado con
**Shift+F1** y captúralo.

## Modos

| # | Modo | Qué hace |
|---|---|---|
| 1 | Salvaje | Camina en la hierba y huye hasta que sale lo que buscas |
| 2–4 | Estático, Regalo, Roamer | Soft reset a ciegas frente al Pokémon |
| 5–7 | Estático RNG, Regalo RNG, Roamer RNG | Calcula el avance exacto y pulsa A en ese frame |
| 8 | Salvaje RNG | Se acerca a un paso del encuentro y da el paso en el frame exacto |
| 9 | Partida nueva | Reinicia hasta conseguir el TID/SID que pides |
| 10 | Semilla inicial | Busca una semilla en la pantalla de título y lanza `afterSeedMode` |

Para objetivos lejanos, **registra la Tele Pokémon en SELECT**: el bot la abre para
avanzar el RNG unas 313 veces por frame.

## Configuración

Todo está en `FRLG_ShinyBot.json`, comentado línea por línea: `shiny`, `species`,
`natures`, `minIVs`/`maxIVs`, `hiddenPower`, `mode`, `initialSeeds`, `afterSeedMode`…
La referencia completa está en [docs/02-design/api-contracts.md](../docs/02-design/api-contracts.md).

Las semillas para `initialSeeds` dependen de tu TID/SID: calcúlalas con [tools/rng/](../tools/rng/).

## Varias ventanas

Puedes correr varias instancias a la vez (cada una crea `inst_N.lock`). Con
`"stopOthers": true`, la que encuentra el objetivo detiene a las demás.
