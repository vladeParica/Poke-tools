# CLAUDE.md — contexto del proyecto FRLG Bots

Bots en Lua para **Pokémon Rojo Fuego / Verde Hoja** en el emulador **VBA-rr**
(VBA-ReRecording, Lua 5.1). El usuario juega en español y todo lo que ve
(panel, consola, log, JSON) va **en español**. Este archivo es el contexto para
seguir trabajando sin perder lo aprendido.

## Reglas de trabajo

- **No romper lo que ya funciona.** Cada cambio en un modo no debe tocar los demás.
  El usuario lo pidió explícitamente: "estamos calibrando todos, la idea es
  mejorarlos, no arreglar uno ni dañar otro". Antes de entregar, correr las pruebas.
- **El Shiny Bot es "estándar, solo búsquedas".** Lo nuevo (entrenamiento, etc.) va
  en scripts aparte (por ejemplo, `trainbot/`).
- Editar siempre `*/src/*` y regenerar con `build.py`. Los `.lua` de la raíz de
  cada bot son generados (CRLF, para Windows).
- Lo que no se pudo probar en el juego real se dice así. Solo hay simulador.
- **Commits:** formato Conventional Commits (`feat:`, `fix:`, `docs:`,
  `refactor:`, `test:`, `chore:`…), **máximo 3 líneas** en total y **sin
  `Co-Authored-By` ni otras líneas de atribución**. El hook `.githooks/commit-msg`
  lo verifica (activar con `git config core.hooksPath .githooks`).

## Estructura

```
shinybot/   FRLG_ShinyBot.lua (generado) + .json   src/bot_body.lua, src/tables2.lua   tests/
trainbot/   FRLG_TrainBot.lua (generado) + .json   src/train_body.lua, src/train_tables.lua
            tools/gen_tables.py (datos de pret)   tests/   examples/ (JSON de Gastly, rutas)
tools/rng/  búsquedas de RNG (C y Python) para encontrar objetivos y semillas
docs/       semillas calculadas, equipo para la Liga
```

Build: `python shinybot/build.py`, `python trainbot/build.py`.
Datos del Train Bot: `python trainbot/tools/gen_tables.py`, que descarga pokefirered a `tools/pret_cache/`.

## Pruebas (simulador)

Necesitan `pip install lupa` (Lua 5.1 desde Python). Los mocks simulan memoria,
botones y la lógica mínima del juego.
- Shiny Bot: `cd shinybot/tests && python run_test.py` (se esperan PAUSED en wild,
  static, gift y roamer), `python run_rng.py`, `python run_wild.py`, `python run_cfg.py`,
  `python run_far.py`.
- Train Bot: `python trainbot/tests/run_train.py` (escenarios evs/record), `run_learn.py`
  (aprender ataques), `run_want.py` (wantedMoves). El mock simula mapa, puertas,
  enfermera, combate con menús reales, prompts de aprender ataque (opcodes 0x5A/0x5B),
  pantalla de datos, evolución (`evo`/`evono`) y casilla que cura (`tile`).

## Datos clave de Gen 3 / FRLG

- Shiny: `(TID ^ SID ^ PIDhi ^ PIDlo) < 8`.
- LCRNG: `s = s*0x41C64E6D + 0x6073`; hacia atrás: `s*0xEEB9EB65 + 0x0A3561A1`.
  `Random()` devuelve `s >> 16`.
- **Method 1** (estáticos, regalos, iniciales, roamer): PIDbajo, PIDalto, IV1
  (PS/At/Df), IV2 (Vel/AtE/DfE).
- **Method H-1** (salvajes): slot (`r%100`; tierra 20,40,50,60,70,80,85,90,94,98,99,100;
  agua 60,90,95,99,100), nivel (1 llamada), naturaleza (`r%25`), pares de PID hasta
  `PID%25 == naturaleza`, 2 llamadas de IVs. El RNG de la tasa de encuentro es aparte.
- En FRLG **Sincronía y Gran Encanto no funcionan**. En crianza la naturaleza no se hereda
  (eso es de Esmeralda).
- Físico/especial **por tipo**: Normal, Lucha, Volador, Veneno, Tierra, Roca, Bicho,
  Fantasma, Acero = físicos; el resto, especiales.
- Tele Pokémon (Teachy TV): 313 llamadas al RNG por frame. El bot la abre desde SELECT
  para llegar a avances lejanos.
- Semilla inicial: el valor de Timer1 al pulsar A en el título se guarda en `0x02020000`.
  Cada frame de retraso suma 18752 (mod 65536, múltiplo de 64). Por eso en cada
  reinicio solo se alcanzan semillas de **una clase mod 64**: conviene dar
  muchas semillas candidatas.
- Obediencia: solo afecta a Pokémon de otro entrenador original. 2ª medalla → Nv 30,
  4ª → 50, 6ª → 70, 8ª → todos.
- Vitaminas: +10 EVs solo si la estadística tiene < 100. Recalculan stats al instante.
  Los EVs de combate se reflejan al subir de nivel o al pasar por el PC.

## Direcciones (pokefirered USA; EUR igual en EWRAM)

| Símbolo | USA | Nota |
|---|---|---|
| gEnemyParty | 0x0202402C | base para offsets relativos |
| gPlayerParty / count | 0x02024284 / 0x02024029 | |
| gRngValue | 0x03005000 (EUR 0x03004F50) | |
| gSaveBlock1Ptr / 2Ptr | 0x03005008 / 0x0300500C (EUR 0x03004F58/5C) | se mueven al cambiar de mapa |
| gMain | 0x030030F0 | inBattle = bit1 de +0x439; callback2 = +4 |
| gActionSelectionCursor | enemy − 0x34 | LUCHA 0, MOCHILA 1, POKéMON 2, HUIR 3 |
| gMoveSelectionCursor | enemy − 0x30 | 2x2 |
| gBattleMons | enemy − 0x448 | 0x58 c/u (species, stats, moves, ivs, ability, types, pp, hp, level…) |
| gBattleBufferA[0][0] | enemy − 0x1468 | 18 = CHOOSEACTION, 20 = CHOOSEMOVE |
| gBattleControllerExecFlags | enemy − 0x464 | bit0 = jugador esperando |
| gBattlescriptCurrInstr | enemy − 0x2B8 | opcode 0x5A learn-move, 0x5B stop-learning |
| gBattleCommunication[1] | enemy − 0x1A9 | cursor SÍ/NO |
| gBattleOutcome | enemy − 0x1A2 | 4 = huyó |
| gMoveToLearn | enemy − 0xA | |
| gBattleStruct (ptr) | enemy − 0x44 | expGetterMonId en +0x10 |
| sMoveSelectionCursorPos | enemy + 0x17141 | pantalla de datos al olvidar ataque |
| gPlayerAvatar | 0x02037078 (JPN 0x02036FAC) | objectEventId en +5 |
| gObjectEvents | avatar − 0x240 | 0x24 c/u; coords +0x10/+0x12, facing +0x18 |
| SaveBlock1 | +4/+5 mapa (grupo/número); +0x30D0 roamer | |
| sWildEncounterData | 0x020386D0 | |

Party struct (100 bytes): PID, OTID, checksum +0x1C, 4 subestructuras cifradas
(orden por PID%24: G A E M), estado +0x50, nivel +0x54, PS +0x56/+0x58, stats +0x5A…+0x62.

## Comportamientos del juego/emulador descubiertos (importantes)

- VBA-rr: `savestate.create(n)` numerado abre un diálogo de error; `savestate.load`
  puede aplicarse al final del frame; "Pause When Inactive" debe estar apagado.
- El Pokémon puede estar a medio crear al terminar un frame: leerlo solo tras 3 frames
  estables y con nivel 1–100.
- La **escena de evolución ocurre con `gMain.inBattle` aún activo** (se distingue por
  `callback2` ≠ el del combate). Mantener B la cancela.
- Al cruzar puertas, SaveBlock1 cambia de mapa antes que las coordenadas del objeto y
  el bloque se mueve: las rutas grabadas tenían puntos falsos. `cleanRoute()` los filtra.
- Zona purificada de la Torre Pokémon 5F: cura al ENTRAR (casillas de mapa x10–12,
  y8–10 = memoria x17–19, y15–17). La columna de alrededor es la salida y no cura.
- Snorlax: la flauta (MSGBOX_YESNO con SÍ por defecto) y `setwildbattle` crean el PID
  antes del combate. El modo Estático RNG lo cubre pulsando solo A.

## Shiny Bot (`shinybot/`, v4.3)

Modos 1–10: Salvaje, Estático, Regalo, Roamer, Estático RNG, Regalo RNG, Roamer RNG,
Salvaje RNG, Partida nueva (elegir SID), Semilla inicial (encadena `afterSeedMode`).
Teclas: 7 iniciar/detener, 8 modo, 9 panel, 0 recargar JSON.
Multi-instancia (`inst_N.lock`, `shiny_stop.flag`); logs en `logs/`.
Salvaje RNG: se acerca a un paso del encuentro y da el paso en el frame exacto.

## Train Bot (`trainbot/`, v1.10)

Entrena al Pokémon 1 del equipo: EVs exactos y nivel, pelea solo contra especies útiles
(`evs`, `species`, `avoidSpecies`), elige el ataque de más daño (fórmula Gen 3, STAB,
tipos, habilidades), aprende ataques (`auto`/`never`/`ask` con `wantedMoves`,
`keepMoves`, `askTimeout`) y pausa al evolucionar si `evolve: true`. Graba la ruta al
Centro con la tecla 6 (ida/vuelta) y la repite. `healMode`: `nurse` o `tile`.
Avisos con ntfy/Discord (`notify`). Tecla 8: inspección (stats, IVs, EVs, ataques).
Guarda contra dos instancias (`train_running.lock`).

## Partidas del usuario

- **Partida nueva "solo shinies" (Rojo Fuego): TID 39422 / SID 4042** (xor 0x9634).
- Rojo Fuego vieja: 26945 / 3475. Verde Hoja: 34299 / 8508.
- Conseguidos: Squirtle Modest 6×31 shiny (semilla 9BAF), Snorlax Adamant/Careful shiny,
  **Gastly/Haunter Modest 6×31 shiny** (PID F9426F72, Torre Pokémon) entrenado
  252 AtE / 252 Vel / 6 PS.
- Equipo objetivo para la Liga: Arcanine, Blastoise, Nidoking, Exeggutor, Kangaskhan,
  Gengar. Ver `docs/equipo-liga.md`.

## Créditos

Direcciones base y tablas de nombres: script "FRLG_RNG_2.0.lua" (Devon Studios x Real.96).
Datos del juego: proyecto de decompilación pret/pokefirered.
