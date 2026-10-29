# Carta del proyecto — Poke-tools

> **Fase AI-DLC:** `00-project`  ·  **Estado:** borrador (documentación retroactiva)
> **Dueño:** vladeParica  ·  **Fecha:** 2026-10-29

## Visión
Que conseguir un Pokémon shiny y perfecto, y entrenarlo con EVs exactos, en Rojo Fuego /
Verde Hoja sea cuestión de configurar un JSON y dejar el emulador trabajando, no de horas
de reinicios y combates manuales.

## Contexto
En la 3ª generación todo lo aleatorio sale de un único generador (LCRNG) cuyo estado se
puede leer en memoria. Herramientas como las de
[Devon Studios](https://github.com/DevonStudios/LuaScripts) muestran ese estado en
pantalla, pero el jugador todavía tiene que pulsar el botón en el frame exacto, caminar
hasta el encuentro o pelear cientos de combates para los EVs. VBA-rr permite que un
script Lua lea la memoria y pulse botones, así que esa parte se puede automatizar.

## Problema
Para el jugador de FRLG en emulador:
- La manipulación del RNG exige precisión de un frame (1/60 s) y mucha repetición.
- El soft reset a ciegas puede tardar miles de intentos.
- El entrenamiento de EVs exactos es tedioso y fácil de arruinar (un combate de más contra
  la especie equivocada).

## Alcance
**Dentro del alcance**
- Shiny Bot: búsqueda de shinies / naturaleza / IVs, a ciegas y con RNG (estáticos,
  regalos, roamers, salvajes), semilla inicial y SID de partida nueva.
- Train Bot: EVs y nivel, elección de rival y de ataque, aprender ataques, evolución,
  ida y vuelta al Centro Pokémon, avisos al celular.
- Herramientas de cálculo de RNG fuera del emulador (`tools/rng/`).
- Rojo Fuego y Verde Hoja, USA y Europa (ESP, FRA, ITA, GER); JPN con direcciones propias.

**Fuera del alcance (explícito)**
- Otros juegos (Rubí/Zafiro/Esmeralda, Gen 4–5) — los scripts de Devon Studios ya los
  cubren; se podrían portar más adelante.
- Otros emuladores (BizHawk, mGBA) — ver [ADR-0001](adr/0001-lua-51-en-vba-rr.md).
- Distribuir ROMs, partidas o savestates.
- Juego en línea, intercambios reales o cualquier uso en hardware original.

## Métricas de éxito
- Un objetivo RNG alcanzable (dentro de `farSearch`) se consigue sin intervención salvo
  guardar el estado al final.
- El Train Bot termina con los EVs **exactos** pedidos (sin pasarse si `allowOvershoot` es false).
- Ningún cambio en un modo rompe otro: todas las pruebas de simulador siguen dando el
  resultado esperado.
- Los modos se validan en el juego real antes de darlos por terminados (no solo en el simulador).

## Principios (no negociables)
- **No romper lo que ya funciona.** Cada cambio en un modo no debe tocar los demás.
- **El Shiny Bot solo busca.** Lo nuevo va en scripts aparte ([ADR-0003](adr/0003-bots-separados.md)).
- **Todo lo que ve el jugador va en español** (panel, consola, log, JSON).
- **Honestidad sobre lo probado:** lo que solo se probó en el simulador se dice así.
- **Nunca se suben ROMs, partidas ni savestates** al repositorio.

## Riesgos principales
| Riesgo | Impacto | Mitigación |
|---|---|---|
| Direcciones de memoria distintas por idioma/revisión | El bot lee basura o no detecta el combate | Direcciones relativas a `gEnemyParty` ([ADR-0006](adr/0006-direcciones-relativas.md)); aviso en consola cuando el idioma no está verificado; diagnóstico en el panel |
| El simulador no reproduce el juego real | Un cambio pasa las pruebas y falla en el emulador | Probar en el juego antes de dar algo por terminado; documentar lo no probado |
| Comportamientos de VBA-rr (diálogos de error, pausas) | El bot se queda trabado | Documentados en `CLAUDE.md`; se evitan `savestate.create` numerado y se pide apagar *Pause When Inactive* |
| Dos instancias pulsando botones a la vez | Acciones erráticas | Archivos de bloqueo (`inst_N.lock`, `train_running.lock`) |
| Licencia de la base (GPL-3.0) | Obligaciones al redistribuir | Repositorio bajo GPL-3.0 ([ADR-0008](adr/0008-licencia-gpl-3.md)) |

## Decisiones abiertas
- Ninguna. La licencia GPL-3.0 quedó aceptada en [ADR-0008](adr/0008-licencia-gpl-3.md).
