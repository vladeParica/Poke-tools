# Arquitectura — Poke-tools

> **Fase AI-DLC:** `02-design`  ·  **Estado:** aceptada (describe el código actual)
> **ADRs relacionadas:** [0001](../00-project/adr/0001-lua-51-en-vba-rr.md) ·
> [0002](../00-project/adr/0002-script-unico-generado.md) ·
> [0003](../00-project/adr/0003-bots-separados.md) ·
> [0004](../00-project/adr/0004-configuracion-json-comentado.md) ·
> [0005](../00-project/adr/0005-pruebas-con-simulador.md) ·
> [0006](../00-project/adr/0006-direcciones-relativas.md) ·
> [0007](../00-project/adr/0007-rutas-grabadas.md)

## 1. Estilo
Cada bot es un **script Lua monolítico** que corre dentro del emulador y funciona como
una **máquina de estados por frame**: en cada frame lee la memoria del juego, decide y
pone en cola los botones a pulsar. No hay servidor, base de datos ni procesos aparte;
el estado vive en memoria del script y en archivos de texto junto a él.

| Capa | Tecnología | ADR |
|---|---|---|
| Ejecución | VBA-rr con Lua 5.1 | [ADR-0001](../00-project/adr/0001-lua-51-en-vba-rr.md) |
| Código fuente | `src/*.lua` unido por `build.py` (Python 3) | [ADR-0002](../00-project/adr/0002-script-unico-generado.md) |
| Configuración | JSON con comentarios | [ADR-0004](../00-project/adr/0004-configuracion-json-comentado.md) |
| Persistencia | Archivos de texto (logs, rutas, bloqueos) | — |
| Avisos | `curl` en segundo plano → ntfy.sh / Discord | — |
| Datos del juego | Tablas generadas desde pret/pokefirered | — |
| Pruebas | Python + lupa (Lua 5.1) + simuladores Lua | [ADR-0005](../00-project/adr/0005-pruebas-con-simulador.md) |
| Cálculo de RNG fuera del emulador | C (fuerza bruta 2^32) y Python | — |

## 2. Componentes

Comunes a los dos bots (repetidos en cada uno, ver [ADR-0003](../00-project/adr/0003-bots-separados.md)):
- **Detección del juego** — lee la cabecera de la ROM y elige direcciones ([ADR-0006](../00-project/adr/0006-direcciones-relativas.md)).
- **Lector de memoria** — descifra el Pokémon (PID, OTID, 4 subestructuras en orden
  `PID % 24`), lee el combate y la posición en el mapa.
- **Configuración** — quita comentarios, parsea el JSON, valida y normaliza nombres.
- **Cola de botones** — pulsaciones con duración en frames (`joypad.set`).
- **Panel** — texto sobre el juego (`gui.text`), tres niveles con la tecla 9.
- **Log y bloqueos** — archivos en `logDir`.

Shiny Bot (`shinybot/src/bot_body.lua`):
- **Modos** — un paso por frame según el modo activo (10 modos).
- **Motor de RNG** — LCRNG hacia delante y hacia atrás, Method 1 y H-1, búsqueda del
  objetivo, calibración del retraso, uso de la Tele Pokémon.
- **Filtro** — shiny, especie, naturaleza, IVs, Poder Oculto.
- **Coordinación de instancias** — `inst_N.lock`, `shiny_stop.flag`.

Train Bot (`trainbot/src/train_body.lua`):
- **Caminata y encuentros** — camina en el eje elegido hasta el combate.
- **Decisor de combate** — pelear o huir (`shouldFight`), elegir ataque (`bestMove`, fórmula de daño Gen 3).
- **Aprender ataques / evolución** — detecta los prompts (opcodes 0x5A/0x5B) y la escena de evolución.
- **Navegación** — graba, limpia (`cleanRoute`, `fixRoute`) y repite rutas; cura con enfermera o casilla.
- **Avisos** — `notify()` con curl.

Diagramas: [contexto](../architecture/c4-context.md) ·
[contenedores](../architecture/c4-container.md) ·
[componentes Shiny Bot](../architecture/c4-component-shinybot.md) ·
[componentes Train Bot](../architecture/c4-component-trainbot.md).

## 3. Modelo de datos
- **Pokémon del equipo / rival** (100 bytes): PID, OTID, checksum, subestructuras
  cifradas (especie, objeto, ataques, PP, EVs, IVs, habilidad), estado, nivel, PS, stats.
- **Objetivo RNG**: avance, PID, naturaleza, IVs, slot (salvajes).
- **Ruta**: listas `GO` y `BACK` de pasos `{grupo, mapa, x, y, dir}`.
- **Configuración**: tabla `CONFIG` (valores por defecto) + JSON del usuario.
- **Tablas del juego**: nombres (especies, naturalezas, ataques), estadísticas base, EVs
  por especie, ataques por nivel, tipos.

## 4. Control de acceso
No aplica: todo corre en la PC del jugador con sus permisos. Los únicos datos que salen
son los avisos opcionales ([modelo de amenazas](threat-model.md)).

## 5. Atributos de calidad
- **Corrección:** el valor del producto es acertar el frame y no pasarse de EVs; cada modo
  tiene escenarios en el simulador.
- **Robustez:** las situaciones previstas (juego reiniciado, ruta bloqueada, otra
  instancia, configuración inválida) detienen el bot con un mensaje en español (`halt`).
  Archivos y avisos van dentro de `pcall`. Un error de programación no previsto detiene
  el script y VBA-rr muestra el error en la consola de Lua.
- **Aislamiento:** un cambio en un modo no debe afectar a los demás ([ADR-0003](../00-project/adr/0003-bots-separados.md)).
- **Rendimiento:** la búsqueda de objetivos recorre hasta `farSearch` avances (20 millones
  por defecto). En Salvaje RNG la tabla de valores se construye por tramos de 100 000
  avances por frame para no congelar el emulador.
- **Portabilidad:** USA verificada; EUR y JPN por desplazamientos ([ADR-0006](../00-project/adr/0006-direcciones-relativas.md)).
