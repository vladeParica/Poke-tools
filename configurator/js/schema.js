// Option schema for both bots. Keys, types and defaults mirror the CONFIG tables in
// shinybot/src/bot_body.lua and trainbot/src/train_body.lua (checked by
// configurator/tests/test_schema_parity.py). Labels and help are player-facing: Spanish.
(function (root) {
  'use strict';

  var WILD = ['Salvaje', 'Salvaje RNG'];
  var RNG = ['Estatico RNG', 'Regalo RNG', 'Roamer RNG', 'Salvaje RNG'];
  function modeIn(list) { return function (c) { return list.indexOf(c.mode) !== -1; }; }

  var STATS = [
    { key: 'hp', label: 'PS', short: 'PS', icon: 'stat-hp' },
    { key: 'atk', label: 'Ataque', short: 'At', icon: 'stat-atk' },
    { key: 'def', label: 'Defensa', short: 'Df', icon: 'stat-def' },
    { key: 'spa', label: 'At. Esp.', short: 'AtE', icon: 'stat-spa' },
    { key: 'spd', label: 'Def. Esp.', short: 'DfE', icon: 'stat-spd' },
    { key: 'spe', label: 'Velocidad', short: 'Vel', icon: 'stat-spe' }
  ];

  var MODES = [
    { value: 'Salvaje', label: 'Salvaje', icon: 'mode-wild', desc: 'Camina en la hierba y huye hasta que sale lo que buscas.' },
    { value: 'Estatico', label: 'Estático', icon: 'mode-static', desc: 'Soft reset a ciegas frente a un Pokémon fijo.' },
    { value: 'Regalo', label: 'Regalo', icon: 'mode-gift', desc: 'Soft reset a ciegas al recibir un Pokémon.' },
    { value: 'Roamer', label: 'Roamer', icon: 'mode-roamer', desc: 'Soft reset a ciegas para el legendario errante.' },
    { value: 'Estatico RNG', label: 'Estático RNG', icon: 'mode-static', rng: true, desc: 'Calcula el frame exacto y pulsa A en él.' },
    { value: 'Regalo RNG', label: 'Regalo RNG', icon: 'mode-gift', rng: true, desc: 'Frame exacto al recibir el Pokémon.' },
    { value: 'Roamer RNG', label: 'Roamer RNG', icon: 'mode-roamer', rng: true, desc: 'Frame exacto para el legendario errante.' },
    { value: 'Salvaje RNG', label: 'Salvaje RNG', icon: 'mode-wild', rng: true, desc: 'Se acerca a un paso del encuentro y lo da en el frame exacto.' },
    { value: 'Partida nueva', label: 'Partida nueva', icon: 'mode-newgame', desc: 'Reinicia hasta conseguir el TID/SID que pides.' },
    { value: 'Semilla inicial', label: 'Semilla inicial', icon: 'mode-seed', desc: 'Cae en una semilla del título y lanza otro modo.' }
  ];

  var FARM_MODES = [
    { value: 'nivel', label: 'Nivel', icon: 'stat-hp', desc: 'Pelea contra todo hasta que el primero llegue al nivel que pidas.' },
    { value: 'objetos', label: 'Objetos (Recogida)', icon: 'mode-gift', desc: 'Gana combates con Meowth (Recogida) en el equipo y guarda lo que recogen.' },
    { value: 'robar', label: 'Robar objetos', icon: 'bot-shiny', desc: 'Usa Ladrón/Antojo cuando el salvaje lleva un objeto que quieres, y huye.' },
    { value: 'dinero', label: 'Dinero', icon: 'mode-coin', desc: 'Revanchas con entrenadores usando el Buscapelea en una ruta grabada.' }
  ];
  function farmIn(list) { return function (c) { return list.indexOf(c.mode) !== -1; }; }

  var NATURES_ES_DISPLAY = {
    Hardy: 'Fuerte', Lonely: 'Huraña', Brave: 'Audaz', Adamant: 'Firme', Naughty: 'Pícara',
    Bold: 'Osada', Docile: 'Dócil', Relaxed: 'Plácida', Impish: 'Agitada', Lax: 'Floja',
    Timid: 'Miedosa', Hasty: 'Activa', Serious: 'Seria', Jolly: 'Alegre', Naive: 'Ingenua',
    Modest: 'Modesta', Mild: 'Afable', Quiet: 'Mansa', Bashful: 'Tímida', Rash: 'Alocada',
    Calm: 'Serena', Gentle: 'Amable', Sassy: 'Grosera', Careful: 'Cauta', Quirky: 'Rara'
  };

  var TYPES_ES_DISPLAY = {
    Fighting: 'Lucha', Flying: 'Volador', Poison: 'Veneno', Ground: 'Tierra', Rock: 'Roca',
    Bug: 'Bicho', Ghost: 'Fantasma', Steel: 'Acero', Fire: 'Fuego', Water: 'Agua', Grass: 'Planta',
    Electric: 'Eléctrico', Psychic: 'Psíquico', Ice: 'Hielo', Dragon: 'Dragón', Dark: 'Siniestro'
  };

  // Field types: bool, int, enum, mode, natures, species, moves, hexlist, ivRange, evs,
  // hiddenPower, notify, text, route. `nullable` = may be written as null.
  var shinybot = {
    id: 'shinybot',
    name: 'Shiny Bot',
    file: 'FRLG_ShinyBot.json',
    script: 'FRLG_ShinyBot.lua',
    icon: 'bot-shiny',
    tagline: 'Shinies y Pokémon perfectos, a ciegas o con RNG exacto.',
    header: [
      'Configuracion de FRLG_ShinyBot.lua (generada con el configurador de Poke-tools)',
      'Guarda este archivo en la MISMA carpeta que el script.',
      'Tras cambiar algo: deten el bot (7) y pulsa 0 para recargar.'
    ],
    sections: [
      { id: 'mode', title: 'Modo', icon: 'compass', desc: 'Cómo va a buscar el bot. Puedes cambiarlo en el juego con la tecla 8.', fields: [
        { key: 'mode', type: 'mode', def: null, nullable: true, label: 'Modo al cargar el script', comment: 'modo al cargar el script' }
      ] },
      { id: 'target', title: 'Qué buscar', icon: 'bot-shiny', desc: 'El bot se detiene cuando aparece un Pokémon que cumple todo esto.', fields: [
        { key: 'shiny', type: 'bool', def: true, label: 'Exigir shiny',
          help: 'Apágalo para buscar solo naturaleza o IVs.', comment: 'true = solo se detiene con un shiny' },
        { key: 'species', type: 'species', def: null, nullable: true, label: 'Especies',
          help: 'Solo en los modos Salvaje. Vacío = cualquiera.', showIf: modeIn(WILD), comment: 'solo modos Salvaje; null = cualquiera' },
        { key: 'natures', type: 'natures', def: null, nullable: true, label: 'Naturalezas',
          help: 'Vacío = cualquiera.', comment: 'null = cualquiera' },
        { key: 'hiddenPower', type: 'hiddenPower', def: null, nullable: true, label: 'Poder Oculto',
          help: 'Tipo y potencia mínima (30–70).', comment: 'ej. {"type": "Fire", "minPower": 60}' }
      ] },
      { id: 'ivs', title: 'IVs', icon: 'stat-hp', desc: 'Mínimo y máximo por estadística (0–31). Vacío = cualquiera. Para un valor exacto pon el mismo número en los dos.', fields: [
        { key: 'minIVs', type: 'ivRange', pair: 'maxIVs', def: null, nullable: true, label: 'IVs', comment: 'IVs minimos (0-31)' },
        { key: 'maxIVs', type: 'hidden', def: null, nullable: true, comment: 'IVs maximos (0-31)' },
        { key: 'minIVTotal', type: 'int', min: 0, max: 186, def: null, nullable: true, half: true, label: 'Suma mínima de IVs',
          help: '0–186. Vacío = sin mínimo.', comment: 'suma minima de los 6 IVs (0-186)' }
      ] },
      { id: 'seed', title: 'Semillas', icon: 'mode-seed', desc: 'Solo en el modo Semilla inicial: el bot prueba tiempos en el título hasta caer en una de estas semillas.', showIf: modeIn(['Semilla inicial']), fields: [
        { key: 'initialSeeds', type: 'hexlist', digits: 4, def: null, nullable: true, label: 'Semillas',
          help: 'Valores hex de 4 cifras. Dependen de tu TID/SID: calcúlalas con tools/rng. Cuantas más, más rápido.',
          comment: 'semillas del titulo (hex)' },
        { key: 'afterSeedMode', type: 'enum', options: RNG, def: null, nullable: true, label: 'Modo después de la semilla',
          help: 'El modo RNG que se lanza al caer en la semilla.', comment: 'modo a lanzar al caer en la semilla' }
      ] },
      { id: 'newgame', title: 'TID / SID', icon: 'mode-newgame', desc: 'Solo en el modo Partida nueva: reinicia hasta que TID xor SID sea uno de estos.', showIf: modeIn(['Partida nueva']), fields: [
        { key: 'newGameTSV', type: 'hexlist', digits: 4, def: null, nullable: true, label: 'TSV buscados (TID xor SID)',
          help: 'Vacío = los que hacen shiny a un Ditto 6×31 (9630, B378, 79F8).', comment: 'TID xor SID en hex; null = Ditto 6x31' }
      ] },
      { id: 'walk', title: 'Caminar', icon: 'mode-wild', desc: 'Cómo camina en la hierba en los modos Salvaje.', showIf: modeIn(WILD), fields: [
        { key: 'walkAxis', type: 'enum', options: [{ value: 'horizontal', label: 'Izquierda / derecha' }, { value: 'vertical', label: 'Arriba / abajo' }],
          def: 'horizontal', half: true, label: 'Eje', comment: '"horizontal" o "vertical"' },
        { key: 'walkFrames', type: 'int', min: 1, max: 120, def: 16, half: true, label: 'Frames por paso', help: '16 = una casilla caminando.', comment: 'frames por paso' },
        { key: 'holdB', type: 'bool', def: false, label: 'Correr con B', help: 'Solo modo Salvaje.', showIf: modeIn(['Salvaje']), comment: 'correr con B (solo Salvaje)' },
        { key: 'wildOneStep', type: 'bool', def: true, label: 'Acercarse a un paso del encuentro', showIf: modeIn(['Salvaje RNG']),
          comment: 'Salvaje RNG: acercarse a 1 paso antes de ir al frame' }
      ] },
      { id: 'rng', title: 'RNG', icon: 'dice', advanced: true, desc: 'Búsqueda del objetivo, Tele Pokémon y cambios de semilla. Los valores por defecto sirven casi siempre.', fields: [
        { key: 'farSearch', half: true, type: 'int', min: 1000, max: 100000000, def: 20000000, label: 'Avances a revisar', comment: 'avances a revisar buscando el objetivo' },
        { key: 'teachy', type: 'bool', def: true, label: 'Usar la Tele Pokémon', help: 'Regístrala en SELECT.', comment: 'usar la Tele Pokemon registrada en SELECT' },
        { key: 'teachyBeyond', half: true, type: 'int', min: 0, max: 100000000, def: 5000, label: 'Usar la Tele si ahorra más de', unit: 'avances', comment: 'usar la Tele si ahorra mas de estos avances' },
        { key: 'teachyMargin', half: true, type: 'int', min: 0, max: 1000000, def: null, nullable: true, label: 'Cerrar la Tele antes', unit: 'avances', help: 'Vacío = automático.', comment: 'null = automatico' },
        { key: 'triesPerTarget', half: true, type: 'int', min: 1, max: 100, def: 10, label: 'Intentos por objetivo', comment: 'intentos de correccion por objetivo' },
        { key: 'reseed', type: 'bool', def: true, label: 'Cambiar de semilla si no hay objetivo', help: 'Necesitas haber guardado en el lugar de la caza.', comment: 'soft reset para otra semilla' },
        { key: 'reseedAfterFailedTargets', half: true, type: 'int', min: 1, max: 100, def: 3, label: 'Objetivos fallidos antes de cambiar', comment: 'objetivos fallidos antes de cambiar de semilla' },
        { key: 'maxReseeds', half: true, type: 'int', min: 0, max: 1000, def: 10, label: 'Máximo de cambios de semilla', comment: 'maximo de cambios de semilla' }
      ] },
      { id: 'reset', title: 'Soft reset', icon: 'refresh', advanced: true, desc: 'Tiempos entre pulsaciones y reinicios en los modos a ciegas.', fields: [
        { key: 'pressGapMin', half: true, type: 'int', min: 0, max: 600, def: 2, label: 'Espera mínima entre A', unit: 'frames', comment: 'espera minima entre pulsaciones de A' },
        { key: 'pressGapMax', half: true, type: 'int', min: 0, max: 600, def: 24, label: 'Espera máxima entre A', unit: 'frames', comment: 'espera maxima (al azar)' },
        { key: 'resetTimeout', half: true, type: 'int', min: 60, max: 100000, def: 5400, label: 'Reiniciar sin resultado tras', unit: 'frames', comment: 'frames sin resultado antes de reiniciar' },
        { key: 'resetOnLoad', type: 'bool', def: true, label: 'Reiniciar el juego al cargar el script', comment: 'reiniciar el juego al cargar el script' }
      ] },
      { id: 'files', title: 'Archivos', icon: 'folder', advanced: true, desc: 'Qué hacer al encontrarlo y dónde guardar los logs.', fields: [
        { key: 'stopOthers', type: 'bool', def: true, label: 'Detener las demás ventanas', comment: 'detener las demas instancias' },
        { key: 'savestateSlot', half: true, type: 'int', min: 1, max: 10, def: null, nullable: true, label: 'Guardar estado en la ranura',
          help: 'En VBA-rr v22 da "Error creating file": mejor vacío y guardar con Shift+F1.', comment: 'ranura 1-10; null = no guardar solo' },
        { key: 'logFile', half: true, type: 'text', def: 'shiny_log.txt', label: 'Archivo de log', comment: 'log de hallazgos' },
        { key: 'logDir', half: true, type: 'text', def: 'logs', label: 'Carpeta de logs', comment: 'subcarpeta para el log y archivos de trabajo' },
        { key: 'sharedDir', half: true, type: 'text', def: null, nullable: true, label: 'Carpeta compartida', help: 'Vacío = la del script.', comment: 'null = la carpeta del script' },
        { key: 'language', type: 'enum', segmented: true, def: 'es', label: 'Idioma del bot',
          options: [{ value: 'es', label: 'Español' }, { value: 'en', label: 'English' }, { value: 'ja', label: '日本語 (romaji)' }],
          help: 'Panel, consola y log del bot. El japonés va en romaji: el emulador no muestra kana.', comment: '"es", "en" o "ja" (romaji)' }
      ] }
    ]
  };

  var trainbot = {
    id: 'trainbot',
    name: 'Train Bot',
    file: 'FRLG_TrainBot.json',
    script: 'FRLG_TrainBot.lua',
    icon: 'bot-train',
    tagline: 'EVs exactos y nivel, con viajes solos al Centro Pokémon.',
    header: [
      'Configuracion de FRLG_TrainBot.lua (generada con el configurador de Poke-tools)',
      'Guarda este archivo en la MISMA carpeta que el script.',
      'Se entrena SIEMPRE el primer Pokemon del equipo.'
    ],
    sections: [
      { id: 'goal', title: 'Objetivo', icon: 'target', desc: 'Se entrena el primer Pokémon del equipo. Se detiene al llegar a los EVs (y al nivel, si pones uno).', fields: [
        { key: 'evs', type: 'evs', def: null, nullable: true, label: 'EVs objetivo',
          comment: 'EVs objetivo; null = solo nivel' },
        { key: 'targetLevel', half: true, type: 'int', min: 1, max: 100, def: null, nullable: true, label: 'Nivel objetivo', comment: 'null = solo EVs' },
        { key: 'maxLevel', half: true, type: 'int', min: 1, max: 100, def: null, nullable: true, label: 'Nivel máximo', help: 'Se detiene aquí aunque falten EVs.', comment: 'detenerse a este nivel aunque falten EVs' },
        { key: 'allowOvershoot', type: 'bool', def: false, label: 'Permitir pasarse un poco', help: 'Ej. 253 en vez de 252.', comment: 'permitir pasarse del objetivo' }
      ] },
      { id: 'foes', title: 'Rivales', icon: 'mode-wild', desc: 'Contra quién pelea. Del resto huye. Las etiquetas muestran los EVs que da cada especie.', fields: [
        { key: 'species', type: 'species', def: null, nullable: true, label: 'Pelear solo contra',
          help: 'Vacío = el bot elige según los EVs que faltan.', showYield: true, comment: 'null = segun los EVs' },
        { key: 'avoidSpecies', type: 'species', def: null, nullable: true, label: 'Nunca pelear contra',
          help: 'Por ejemplo, las que usan Autodestrucción.', showYield: true, comment: 'especies a evitar' }
      ] },
      { id: 'battle', title: 'Combate', icon: 'stat-atk', desc: 'Cuándo curarse, cuándo huir y qué hacer con evoluciones y shinies.', fields: [
        { key: 'healBelow', type: 'int', min: 0, max: 100, def: 40, unit: '%', slider: true, label: 'Ir al Centro con PS bajo', comment: 'curarse si los PS quedan bajo este %' },
        { key: 'fleeBelow', type: 'int', min: 0, max: 100, def: 20, unit: '%', slider: true, label: 'Huir en combate con PS bajo', comment: 'huir si los PS bajan de este %' },
        { key: 'minPP', half: true, type: 'int', min: 0, max: 99, def: 3, label: 'PP mínimos', help: 'En ataques que hacen daño.', comment: 'curarse si quedan menos PP' },
        { key: 'evolve', type: 'bool', def: false, half: true, label: 'Dejar evolucionar', comment: 'false = cancela las evoluciones' },
        { key: 'stopOnShiny', type: 'bool', def: true, half: true, label: 'Pausar con un shiny salvaje', comment: 'pausar si aparece un shiny' }
      ] },
      { id: 'moves', title: 'Ataques', icon: 'spark', desc: 'Qué hacer cuando quiere aprender un ataque nuevo y ya tiene cuatro.', fields: [
        { key: 'learnMoves', type: 'enum', segmented: true, def: 'auto', label: 'Ataques nuevos',
          options: [{ value: 'auto', label: 'Automático' }, { value: 'never', label: 'Nunca' }, { value: 'ask', label: 'Preguntarme' }],
          help: 'Automático: aprende si hace más daño que el peor. Nunca olvida MOs.', comment: '"auto", "never" o "ask"' },
        { key: 'wantedMoves', type: 'moves', max: 4, def: null, nullable: true, label: 'Ataques que quiero al final',
          help: 'Máximo 4. Con esta lista solo aprende estos.', comment: 'maximo 4; solo aprende estos' },
        { key: 'keepMoves', type: 'moves', def: null, nullable: true, label: 'Nunca olvidar', comment: 'ataques que nunca debe olvidar' },
        { key: 'askTimeout', half: true, type: 'int', min: 0, max: 86400, def: 300, nullable: true, unit: 's', label: 'Esperar mi respuesta',
          help: 'Con "Preguntarme". Vacío = esperar siempre.', showIf: function (c) { return c.learnMoves === 'ask'; }, comment: 'segundos; null = esperar siempre' },
      ] },
      { id: 'route', title: 'Ruta', icon: 'route', desc: 'El camino al Centro Pokémon y de vuelta. Grábalo con la tecla 6 o usa uno listo.', fields: [
        { key: 'healMode', type: 'enum', segmented: true, def: 'nurse', label: 'Cómo se cura',
          options: [{ value: 'nurse', label: 'Enfermera' }, { value: 'tile', label: 'Casilla que cura' }],
          help: 'La casilla que cura es la zona purificada de la Torre Pokémon 5F.', comment: '"nurse" o "tile"' },
        { key: 'routeFile', type: 'route', viewer: true, def: 'FRLG_TrainRoute.txt', label: 'Archivo de ruta',
          help: 'Grábala con la tecla 6 o usa una de trainbot/examples/routes.', comment: 'ruta al Centro (tecla 6)' }
      ] },
      { id: 'notify', title: 'Avisos', icon: 'bell', desc: 'Te avisa al celular cuando termina, encuentra un shiny o se detiene.', fields: [
        { key: 'notify', type: 'notify', def: null, nullable: true, label: 'Avisos',
          help: 'ntfy: instala la app y suscríbete a un tema difícil de adivinar. Discord: URL de un webhook. Son secretos: no los compartas.',
          comment: 'avisos: {"ntfy": "tema"} y/o {"discord": "url"}' }
      ] },
      { id: 'advanced', title: 'Caminar y logs', icon: 'gear', advanced: true, desc: 'Caminata y archivos de log. Los valores por defecto sirven casi siempre.', fields: [
        { key: 'walkAxis', type: 'enum', options: [{ value: 'horizontal', label: 'Izquierda / derecha' }, { value: 'vertical', label: 'Arriba / abajo' }],
          def: 'horizontal', half: true, label: 'Eje de la caminata', comment: '"horizontal" o "vertical"' },
        { key: 'walkFrames', type: 'int', min: 1, max: 120, def: 16, half: true, label: 'Frames por paso', comment: 'frames por paso' },
        { key: 'logFile', type: 'text', def: 'train_log.txt', half: true, label: 'Archivo de log', comment: 'log' },
        { key: 'logDir', type: 'text', def: 'logs', half: true, label: 'Carpeta de logs', comment: 'subcarpeta de logs' },
        { key: 'language', type: 'enum', segmented: true, def: 'es', label: 'Idioma del bot',
          options: [{ value: 'es', label: 'Español' }, { value: 'en', label: 'English' }, { value: 'ja', label: '日本語 (romaji)' }],
          help: 'Panel, consola y log del bot. El japonés va en romaji: el emulador no muestra kana.', comment: '"es", "en" o "ja" (romaji)' }
      ] }
    ]
  };

  var farmbot = {
    id: 'farmbot',
    name: 'Farm Bot',
    file: 'FRLG_FarmBot.json',
    script: 'FRLG_FarmBot.lua',
    icon: 'bot-farm',
    tagline: 'Farmea objetos, nivel o dinero sin tocar los otros bots.',
    header: [
      'Configuracion de FRLG_FarmBot.lua (generada con el configurador de Poke-tools)',
      'Guarda este archivo en la MISMA carpeta que el script.',
      'Tras cambiar algo: deten el bot (7) y pulsa 0 para recargar.'
    ],
    sections: [
      { id: 'mode', title: 'Modo', icon: 'compass', desc: 'Qué quieres farmear.', fields: [
        { key: 'mode', type: 'mode', cards: FARM_MODES, def: 'nivel', label: 'Modo', comment: '"nivel", "objetos", "robar" o "dinero"' }
      ] },
      { id: 'goal', title: 'Meta', icon: 'target', desc: 'Cuándo se detiene. Si no pones ninguna, sigue hasta que lo pares con 7.', fields: [
        { key: 'targetLevel', type: 'int', min: 1, max: 100, def: null, nullable: true, half: true, label: 'Nivel objetivo',
          help: 'Del primero del equipo.', showIf: farmIn(['nivel']), comment: 'nivel: detenerse en este nivel' },
        { key: 'itemTarget', type: 'int', min: 1, max: 99999, def: null, nullable: true, half: true, label: 'Objetos a guardar',
          showIf: farmIn(['objetos', 'robar']), comment: 'objetos/robar: detenerse tras guardar estos objetos' },
        { key: 'moneyTarget', type: 'int', min: 1, max: 999999, def: null, nullable: true, half: true, label: 'Dinero objetivo',
          showIf: farmIn(['dinero']), comment: 'dinero: detenerse al tener este dinero' },
        { key: 'maxBattles', type: 'int', min: 1, max: 999999, def: null, nullable: true, half: true, label: 'Máximo de combates',
          comment: 'detenerse tras estos combates' },
        { key: 'takeItems', type: 'enum', segmented: true, def: 'auto', label: 'Guardar los objetos',
          options: [{ value: 'auto', label: 'El bot los quita' }, { value: 'pause', label: 'Pausar y avisarme' }],
          help: 'El bot usa START > POKÉMON > OBJETO > QUITAR (solo versiones USA).', showIf: farmIn(['objetos', 'robar']),
          comment: '"auto" o "pause"' },
        { key: 'wantedItems', type: 'items', def: null, nullable: true, label: 'Objetos que quieres',
          help: 'Solo roba estos (nombre en inglés). Vacío = cualquier objeto.', showIf: farmIn(['robar']),
          comment: 'robar: objetos que quieres; null = cualquiera' }
      ] },
      { id: 'foes', title: 'Rivales', icon: 'mode-wild', desc: 'Contra quién pelea en los modos nivel y objetos. Del resto huye.', showIf: farmIn(['nivel', 'objetos']), fields: [
        { key: 'species', type: 'species', def: null, nullable: true, label: 'Pelear solo contra', help: 'Vacío = contra todas.', comment: 'null = contra todas' },
        { key: 'avoidSpecies', type: 'species', def: null, nullable: true, label: 'Nunca pelear contra',
          help: 'Por ejemplo, las que usan Autodestrucción.', comment: 'especies a evitar' }
      ] },
      { id: 'battle', title: 'Combate', icon: 'stat-atk', desc: 'Cuándo curarse y huir. Contra entrenadores no se puede huir.', fields: [
        { key: 'healBelow', type: 'int', min: 0, max: 100, def: 40, unit: '%', slider: true, label: 'Ir al Centro con PS bajo', comment: 'curarse si los PS quedan bajo este %' },
        { key: 'fleeBelow', type: 'int', min: 0, max: 100, def: 20, unit: '%', slider: true, label: 'Huir en combate con PS bajo', comment: 'huir si los PS bajan de este %' },
        { key: 'minPP', half: true, type: 'int', min: 0, max: 99, def: 3, label: 'PP mínimos', comment: 'curarse si quedan menos PP' },
        { key: 'evolve', type: 'bool', def: false, half: true, label: 'Dejar evolucionar', comment: 'false = cancela las evoluciones' },
        { key: 'stopOnShiny', type: 'bool', def: true, half: true, label: 'Pausar con un shiny salvaje', comment: 'pausar si aparece un shiny' }
      ] },
      { id: 'moves', title: 'Ataques', icon: 'spark', desc: 'Qué hacer cuando quiere aprender un ataque nuevo. En "robar" nunca olvida Ladrón ni Antojo.', fields: [
        { key: 'learnMoves', type: 'enum', segmented: true, def: 'auto', label: 'Ataques nuevos',
          options: [{ value: 'auto', label: 'Automático' }, { value: 'never', label: 'Nunca' }, { value: 'ask', label: 'Preguntarme' }],
          comment: '"auto", "never" o "ask"' },
        { key: 'wantedMoves', type: 'moves', max: 4, def: null, nullable: true, label: 'Ataques que quiero al final', comment: 'maximo 4' },
        { key: 'keepMoves', type: 'moves', def: null, nullable: true, label: 'Nunca olvidar', comment: 'ataques que nunca debe olvidar' },
        { key: 'askTimeout', half: true, type: 'int', min: 0, max: 86400, def: 300, nullable: true, unit: 's', label: 'Esperar mi respuesta',
          showIf: function (c) { return c.learnMoves === 'ask'; }, comment: 'segundos; null = esperar siempre' }
      ] },
      { id: 'route', title: 'Rutas', icon: 'route', desc: 'Tecla 6: ruta al Centro (sirve la del Train Bot). Tecla 5: ruta por la vista de los entrenadores.', fields: [
        { key: 'healMode', type: 'enum', segmented: true, def: 'nurse', label: 'Cómo se cura',
          options: [{ value: 'nurse', label: 'Enfermera' }, { value: 'tile', label: 'Casilla que cura' }], comment: '"nurse" o "tile"' },
        { key: 'routeFile', type: 'route', viewer: true, def: 'FRLG_TrainRoute.txt', label: 'Ruta al Centro', comment: 'ruta al Centro (tecla 6)' },
        { key: 'trainerRouteFile', type: 'text', viewer: true, def: 'FRLG_FarmTrainers.txt', label: 'Ruta de entrenadores',
          help: 'Grábala con la tecla 5: empieza y termina donde usas el Buscapelea.', showIf: farmIn(['dinero']),
          comment: 'dinero: ruta grabada con la tecla 5' }
      ] },
      { id: 'notify', title: 'Avisos', icon: 'bell', desc: 'Te avisa al celular cuando termina, se detiene o tienes que quitar objetos.', fields: [
        { key: 'notify', type: 'notify', def: null, nullable: true, label: 'Avisos', comment: 'avisos: {"ntfy": "tema"} y/o {"discord": "url"}' }
      ] },
      { id: 'advanced', title: 'Caminar y logs', icon: 'gear', advanced: true, desc: 'Los valores por defecto sirven casi siempre.', fields: [
        { key: 'walkAxis', type: 'enum', options: [{ value: 'horizontal', label: 'Izquierda / derecha' }, { value: 'vertical', label: 'Arriba / abajo' }],
          def: 'horizontal', half: true, label: 'Eje de la caminata', comment: '"horizontal" o "vertical"' },
        { key: 'walkFrames', type: 'int', min: 1, max: 120, def: 16, half: true, label: 'Frames por paso', comment: 'frames por paso' },
        { key: 'logFile', type: 'text', def: 'farm_log.txt', half: true, label: 'Archivo de log', comment: 'log' },
        { key: 'logDir', type: 'text', def: 'logs', half: true, label: 'Carpeta de logs', comment: 'subcarpeta de logs' },
        { key: 'language', type: 'enum', segmented: true, def: 'es', label: 'Idioma del bot',
          options: [{ value: 'es', label: 'Español' }, { value: 'en', label: 'English' }, { value: 'ja', label: '日本語 (romaji)' }],
          help: 'Panel, consola y log del bot. El japonés va en romaji: el emulador no muestra kana.', comment: '"es", "en" o "ja" (romaji)' }
      ] }
    ]
  };

  var api = {
    STATS: STATS, MODES: MODES, FARM_MODES: FARM_MODES, NATURES_ES_DISPLAY: NATURES_ES_DISPLAY, TYPES_ES_DISPLAY: TYPES_ES_DISPLAY,
    bots: { shinybot: shinybot, trainbot: trainbot, farmbot: farmbot },
    fields: function (bot) {
      var out = [];
      api.bots[bot].sections.forEach(function (s) { s.fields.forEach(function (f) { out.push(f); }); });
      return out;
    }
  };

  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  else { root.PT = root.PT || {}; root.PT.schema = api; }
})(typeof window !== 'undefined' ? window : this);
