# Estrategia de pruebas — Poke-tools

> **Fase AI-DLC:** `04-testing`
> Cómo se verifican los bots, incluidos los casos límite de los PRD.

## Niveles
| Nivel | Alcance | Herramientas | Qué cubre |
|---|---|---|---|
| Build | `src/` → `.lua` generado | `build.py`, CI | Que lo versionado coincide con las fuentes |
| Simulador | Bot completo contra un juego imitado | Python + lupa (Lua 5.1), `tests/mock*.lua`, `tests/run_*.py` | Modos, filtros, RNG, combates, rutas, ataques, configuración inválida |
| Juego real | Bot en VBA-rr con la ROM | Manual | Lo que el simulador no imita: tiempos reales, idiomas, rarezas del emulador |

## Cómo correrlas
```
pip install -r requirements-dev.txt
python shinybot/build.py && python trainbot/build.py   # no debe cambiar ningún archivo
cd shinybot/tests && python run_test.py && python run_rng.py && python run_wild.py \
  && python run_cfg.py && python run_far.py && cd ../..
python trainbot/tests/run_train.py && python trainbot/tests/run_learn.py && python trainbot/tests/run_want.py
```
Duración aproximada: Shiny Bot ~40 s, Train Bot ~50 s.

## Escenarios y resultado esperado

| Runner | Escenarios | Se espera |
|---|---|---|
| `shinybot/tests/run_test.py` | wild, static, gift, roamer (con y sin limpiar RAM) | Todos terminan en `PAUSED` |
| `run_rng.py` | Roamer RNG | Calibra y encuentra el objetivo (`PAUSED`) |
| `run_wild.py`, `run_far.py` | Salvaje RNG, objetivo cercano y lejano (Tele) | Se acerca a un paso, calibra y encuentra (`PAUSED`) |
| `run_cfg.py` | JSON correcto en varios modos; JSON con errores | `PAUSED` en los correctos; el inválido no arranca (`TIMEOUT` esperando a que se corrija) |
| `trainbot/tests/run_train.py` | evs, record, pokerus, level, nolearn | EVs y nivel del objetivo; ruta grabada; sin pasarse con Pokérus |
| `run_learn.py` | aprender ataques (`auto`, `never`, `ask` con y sin respuesta) | Aprende u olvida según la configuración |
| `run_want.py` | `wantedMoves` | Solo aprende los ataques pedidos |

## Caminos críticos (se prueban siempre)
- Leer al Pokémon solo cuando está completo (3 frames estables).
- No pasarse de EVs sin `allowOvershoot`, también con Pokérus.
- Configuración inválida: no arrancar y explicar el error.
- Volver al punto de entreno tras curarse; ruta con puertas.

## Datos de prueba
Los escenarios están definidos dentro de cada `mock*.lua` y `run_*.py`; usan
partidas ficticias (la del Shiny Bot es TID 12345 / SID 54321) y no necesitan ROM.

## Huecos conocidos
| Hueco | Riesgo | Decisión |
|---|---|---|
| Los runners imprimen resultados y no fallan solos | Una regresión pasa el CI si no lanza excepción | Aceptado por ahora: el CI detecta errores de ejecución y build desactualizado; añadir comprobaciones está en el [backlog](../03-implementation/backlog.md) |
| El simulador no imita tiempos ni gráficos reales | Algo que pasa en el simulador falla en el juego | Probar en el juego real antes de publicar; decirlo cuando no se pudo |
| Idiomas EUR/JPN sin pruebas en el juego real | Direcciones derivadas incorrectas | Aviso en consola + diagnóstico en el panel; pendiente de verificar |
| `tools/rng/` sin pruebas | Resultados incorrectos de búsqueda | Se validan al usar las semillas en el juego |
