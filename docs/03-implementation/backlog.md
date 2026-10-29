# Backlog y notas de implementación — Poke-tools

> **Fase AI-DLC:** `03-implementation`
> Qué está hecho, qué falta y lo que un mantenedor necesita saber.

## Estado
Shiny Bot v4.3 y Train Bot v1.10 funcionan y se usaron en el juego real (Rojo Fuego USA).
La documentación AI-DLC se escribió después del código.

## Hecho
- [x] Shiny Bot: 10 modos, filtros de shiny / naturaleza / IVs / Poder Oculto, varias instancias.
- [x] Shiny Bot: Salvaje RNG a un paso del encuentro, Tele Pokémon para objetivos lejanos.
- [x] Shiny Bot: semilla inicial encadenada con otro modo; elegir TID/SID en partida nueva.
- [x] Train Bot: EVs exactos y nivel, decisor de combate con fórmula de daño Gen 3.
- [x] Train Bot: aprender ataques (`auto`, `never`, `ask`, `wantedMoves`, `keepMoves`), evolución.
- [x] Train Bot: rutas grabadas, curación con enfermera o casilla, avisos ntfy/Discord.
- [x] Herramientas de RNG fuera del emulador (`tools/rng/`).
- [x] Simuladores y escenarios de prueba de los dos bots.
- [x] Documentación AI-DLC, CI, licencia y plantillas de GitHub.

## Pendiente
- [ ] Que los runners de prueba **fallen solos** cuando un escenario no da el resultado
  esperado (hoy imprimen y una persona compara) — ver [estrategia de pruebas](../04-testing/test-strategy.md).
- [ ] Verificar en el juego real las direcciones derivadas para EUR y JPN ([ADR-0006](../00-project/adr/0006-direcciones-relativas.md)).
- [ ] Ideas a partir de los scripts de Devon Studios: RNG de Recogida, golpes críticos,
  versión BizHawk ([créditos](../00-project/creditos.md)).

## Notas de implementación
- **Nunca editar los `.lua` generados**: editar `src/` y correr `build.py`
  ([ADR-0002](../00-project/adr/0002-script-unico-generado.md)). El CI falla si no coinciden.
- **Comportamientos del juego y del emulador ya descubiertos** (Pokémon a medio crear,
  evolución con `inBattle` activo, puertas que mueven el SaveBlock, zona purificada,
  Snorlax, `savestate.create`): sección correspondiente de [`CLAUDE.md`](../../CLAUDE.md).
- **Direcciones de memoria**: tabla en `CLAUDE.md`; todo lo de combate es relativo a
  `gEnemyParty`.
- `trainbot/src/train_tables.lua` se regenera con `python trainbot/tools/gen_tables.py`
  (descarga pokefirered a `tools/pret_cache/`, ignorado por git).
- El Train Bot incluye las tablas de nombres del Shiny Bot (`shinybot/src/tables2.lua`)
  al generarse: cambiarlas afecta a los dos.

## Desviaciones del diseño
| El diseño decía | Se hizo | Por qué | ADR |
|---|---|---|---|
| — | — | La documentación describe el código existente; no hay desviaciones registradas | — |
