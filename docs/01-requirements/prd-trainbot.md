# PRD — Train Bot

> **Fase AI-DLC:** `01-requirements`  ·  **Estado:** borrador (documentación retroactiva de v1.10)
> **Autor:** vladeParica  ·  **Fecha:** 2026-10-29

## 1. Problema
Entrenar EVs exactos exige cientos de combates contra especies concretas, huir de las
demás, curarse a tiempo y no pasarse del objetivo. Un error (un combate de más contra la
especie equivocada) arruina el reparto. El jugador quiere fijar los EVs y el nivel y
dejar que el bot lo haga.

## 2. Actores
- **Jugador**: configura el JSON, graba (o elige) la **ruta**, coloca al personaje.
- **Train Bot** (una sola instancia).
- **Servicio de avisos** opcional: ntfy.sh o un webhook de Discord.

## 3. Flujo principal
1. El jugador pone al Pokémon a entrenar primero en el equipo, configura `evs` /
   `targetLevel` y la ruta, y pulsa **7** en el punto de entreno.
2. El bot camina por la hierba (`walkAxis`, `walkFrames`) hasta que hay combate.
3. En combate decide: **pelear** si la especie da EVs útiles (o está en `species`) y no
   está en `avoidSpecies`; si no, **huir**.
4. Elige el ataque de más daño (fórmula de daño de Gen 3, STAB, tipos, habilidades;
   físico/especial según el tipo).
5. Gestiona lo que pase en el combate: subir de nivel, aprender ataques
   (`learnMoves`/`wantedMoves`/`keepMoves`), evolución (`evolve`), shiny salvaje
   (`stopOnShiny`).
6. Tras cada combate suma los EVs ganados; si quedan PS bajo `healBelow` o PP bajo
   `minPP`, recorre la ruta `GO`, se cura (enfermera o casilla) y vuelve por `BACK`.
7. Al llegar al objetivo se detiene, lo registra, avisa (`notify`) y pausa el juego.

## 4. Reglas de negocio
- EVs: máx. 255 por estadística y 510 en total. Pokérus ×2 y Brazal Firme ×2 por combate.
- Sin `allowOvershoot`, no pelea si el combate lo pasaría del objetivo; si cada combate
  da más EVs de los que faltan, se detiene y explica por qué.
- Con `learnMoves: "auto"` aprende un ataque si hace más daño que el peor; nunca olvida
  MOs ni `keepMoves`; con `wantedMoves` solo aprende esos.
- `evolve: false` cancela la evolución manteniendo B.
- Físico/especial por tipo (Normal, Lucha, Volador, Veneno, Tierra, Roca, Bicho,
  Fantasma, Acero = físicos).

## 5. Escenarios límite, de abuso y de riesgo
| Escenario | Comportamiento esperado |
|---|---|
| Rival con Autodestrucción / Explosión | `avoidSpecies` por defecto los evita (Geodude, Voltorb, Koffing…) |
| El Pokémon pierde y aparece en el Centro | Si está sobre la ruta de vuelta, la sigue; si no, se detiene con mensaje |
| El personaje no está en el punto de entreno ni en la ruta | No arranca: "El personaje no está en el punto de entreno" |
| Ruta grabada con pasos falsos en las puertas | `cleanRoute()` los filtra al cargar y la guarda corregida |
| Un NPC bloquea la ruta | Se detiene: "No pude volver al punto de entreno" |
| Escena de evolución con `gMain.inBattle` todavía activo | Se distingue por `callback2`; mantiene B si `evolve: false` |
| Prompt de aprender ataque (opcodes 0x5A/0x5B) | Responde según `learnMoves`; con `ask` avisa y espera `askTimeout` |
| Aparece un shiny salvaje | Pausa (`stopOnShiny`) y avisa |
| Dos ventanas con el Train Bot | La segunda no arranca (`train_running.lock` reciente) |
| `notify` con un tema o una URL maliciosos | Solo acepta tema `[A-Za-z0-9_-]` y URL `https://` con caracteres seguros; el texto se filtra antes de pasarlo a curl |
| Pokérus o Brazal Firme hacen imposible el número exacto | Se detiene y sugiere `allowOvershoot` u otro método |

## 6. Criterios de aceptación
- [x] Escenarios `evs`, `record`, `pokerus`, `level` y `nolearn` terminan con los EVs y el
  nivel pedidos en el simulador (`run_train.py`).
- [x] Aprende y rechaza ataques según `learnMoves` y `wantedMoves` (`run_learn.py`, `run_want.py`).
- [x] Graba, limpia y repite la ruta, incluida la casilla que cura (`tile`).
- [ ] Cada cambio se confirma en el juego real antes de publicarlo.

## 7. Fuera del alcance
- Entrenar a más de un Pokémon a la vez o al que no va primero (Repartir Experiencia).
- Usar objetos en combate o vitaminas.
- Calcular caminos solo ([ADR-0007](../00-project/adr/0007-rutas-grabadas.md)).

## 8. Decisiones abiertas
- Ninguna para esta versión.
