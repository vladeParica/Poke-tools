# PRD — Shiny Bot

> **Fase AI-DLC:** `01-requirements`  ·  **Estado:** borrador (documentación retroactiva de v4.3)
> **Autor:** vladeParica  ·  **Fecha:** 2026-10-29

## 1. Problema
Conseguir un Pokémon shiny, o con naturaleza e IVs concretos, exige miles de soft resets
a ciegas o pulsar un botón en el frame exacto que da el RNG. El jugador quiere decir
**qué** busca y dejar que el bot lo consiga.

## 2. Actores
- **Jugador**: configura el JSON, coloca al personaje y guarda el estado al final.
- **Instancia** del bot (puede haber varias en paralelo).
- **Juego** (ROM de FRLG) dentro de **VBA-rr**.

## 3. Flujo principal
1. El jugador guarda la partida frente al objetivo (o en la hierba), configura el JSON y
   carga el script; el bot reinicia el juego (`resetOnLoad`).
2. Elige el **modo** (tecla 8) y pulsa **7**.
3. **Modos a ciegas** (Salvaje, Estático, Regalo, Roamer): repite soft reset o encuentros
   y lee el Pokémon creado hasta que cumple el filtro.
4. **Modos RNG**: calibra el retraso, busca el siguiente **objetivo** dentro de
   `farSearch` avances, espera (o usa la Tele Pokémon si está lejos) y pulsa en el frame
   exacto; si falla, corrige ±1, ±2… hasta `triesPerTarget`.
5. **Semilla inicial**: prueba tiempos en el título hasta caer en una de `initialSeeds`,
   carga la partida y encadena `afterSeedMode`.
6. **Partida nueva**: reinicia la creación de partida hasta que `TID xor SID` cae en
   `newGameTSV`.
7. Al encontrarlo: escribe el log, avisa a las demás instancias (`stopOthers`) y **pausa
   el juego** para que el jugador guarde el estado.

## 4. Reglas de negocio
- Shiny: `(TID ^ SID ^ PIDalto ^ PIDbajo) < 8`.
- Method 1 para estáticos, regalos, iniciales y roamers; Method H-1 para salvajes (slot,
  nivel, naturaleza, pares de PID, IVs).
- En FRLG Sincronía y Gran Encanto **no** afectan; el bot no los usa.
- Filtros combinables: `shiny`, `species`, `natures`, `minIVs`/`maxIVs`, `minIVTotal`,
  `hiddenPower`. Naturalezas y estadísticas en inglés o español.
- Cada reinicio solo alcanza semillas de una clase mod 64: conviene dar muchas semillas.

## 5. Escenarios límite, de abuso y de riesgo
| Escenario | Comportamiento esperado |
|---|---|
| El Pokémon está a medio crear al terminar el frame | Leerlo solo tras 3 frames estables y con nivel 1–100 |
| JSON con errores (naturaleza inexistente, tipo inválido) | No inicia; explica el error en consola y espera a que se corrija y se pulse 0 |
| No hay objetivo dentro de `farSearch` o fallan varios seguidos | Si `reseed`, soft reset para otra semilla (hasta `maxReseeds`); si no, se detiene con mensaje |
| La semilla pedida no se alcanza desde el título | Sigue probando tiempos; mensaje sugiriendo dar más semillas |
| Lag o retraso variable entre la pulsación y la creación | Recalibrar; corregir el avance (±1, ±2…) |
| Varias instancias pulsando a la vez | Cada una con su `inst_N.lock`; la que encuentra crea `shiny_stop.flag` y las demás paran |
| `savestate.create(n)` numerado en VBA-rr | No se usa por defecto (`savestateSlot: null`): abre un diálogo de error |
| *Pause When Inactive* activado | Documentado: el emulador se detiene sin foco; hay que apagarlo |
| Snorlax (flauta + `setwildbattle`) | El PID se crea antes del combate; el modo Estático RNG lo cubre pulsando solo A |
| Idioma no verificado (EUR/JPN) | Aviso en consola; el panel permite comprobar la bandera de combate |

## 6. Criterios de aceptación
- [x] En el simulador, los modos Salvaje, Estático, Regalo y Roamer terminan en `PAUSED`
  con el Pokémon que cumple el filtro (`run_test.py`).
- [x] Los modos RNG calibran y aciertan el objetivo en el simulador (`run_rng.py`,
  `run_wild.py`, `run_far.py`).
- [x] Un JSON inválido no arranca el bot y muestra el error (`run_cfg.py`).
- [ ] Cada modo nuevo o modificado se confirma en el juego real antes de publicarlo.

## 7. Fuera del alcance
- Entrenar, combatir o moverse por el mapa más allá de caminar en la hierba ([ADR-0003](../00-project/adr/0003-bots-separados.md)).
- Capturar el Pokémon: el jugador lo hace tras la pausa.
- Huevos y crianza, Pickup, golpes críticos.

## 8. Decisiones abiertas
- Ninguna para esta versión.
