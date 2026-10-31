// Pure logic of the configurator: parse, normalize, validate and serialize bot configs.
// No DOM access, so it runs in the browser and in Node (configurator/tests).
// Messages are player-facing Spanish templates; tr() shows them in the page's language.
(function (root) {
  'use strict';

  var STAT_ALIASES = {
    hp: 'hp', ps: 'hp', atk: 'atk', ata: 'atk', attack: 'atk', ataque: 'atk',
    def: 'def', defense: 'def', defensa: 'def',
    spa: 'spa', spatk: 'spa', ate: 'spa', atesp: 'spa', ataqueespecial: 'spa',
    spd: 'spd', spdef: 'spd', dfe: 'spd', defesp: 'spd', defensaespecial: 'spd',
    spe: 'spe', speed: 'spe', vel: 'spe', velocidad: 'spe'
  };
  var STAT_ORDER = ['hp', 'atk', 'def', 'spa', 'spd', 'spe'];
  // "{name}" placeholders are filled from v. With the page's i18n loaded the text is translated;
  // in Node (tests) it stays Spanish.
  function tr(s, v) {
    var i = root.PT && root.PT.i18n;
    if (i) return i.t(s, v);
    return v ? s.replace(/\{(\w+)\}/g, function (m, k) { return v[k] !== undefined ? v[k] : m; }) : s;
  }
  var UNSAFE_PATH = /["%$`]/;
  var NTFY_TOPIC = /^[A-Za-z0-9_-]+$/;
  var DISCORD_URL = /^https:\/\/[A-Za-z0-9./_-]+$/;

  // Same normalization as the bots' simplify(): lowercase, no accents, alphanumerics only.
  function simplify(s) {
    return String(s).toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/[^a-z0-9]/g, '');
  }

  // Remove // comments outside strings (the bots only allow them between tokens).
  function stripComments(text) {
    var out = '', inStr = false;
    for (var i = 0; i < text.length; i++) {
      var c = text[i];
      if (inStr) {
        out += c;
        if (c === '\\') { out += text[i + 1] || ''; i++; } else if (c === '"') inStr = false;
      } else if (c === '"') { inStr = true; out += c; }
      else if (c === '/' && text[i + 1] === '/') { while (i < text.length && text[i] !== '\n') i++; out += '\n'; }
      else out += c;
    }
    return out;
  }

  function parseConfig(text) {
    try {
      var v = JSON.parse(stripComments(String(text).replace(/^﻿/, '')));
      if (!v || typeof v !== 'object' || Array.isArray(v)) return { ok: false, error: tr('El archivo debe ser un objeto { ... }') };
      return { ok: true, value: v };
    } catch (e) {
      return { ok: false, error: tr('JSON inválido: {msg}', { msg: e.message }) };
    }
  }

  function makeLookup(list) {
    var m = {};
    list.forEach(function (n) { m[simplify(n)] = n; });
    return m;
  }

  function lookups(data) {
    if (data._lk) return data._lk;
    var nat = makeLookup(data.natures);
    Object.keys(data.naturesEs).forEach(function (en) { nat[simplify(data.naturesEs[en])] = en; });
    var hp = makeLookup(data.hpTypes);
    Object.keys(data.hpTypesEs).forEach(function (en) { hp[simplify(data.hpTypesEs[en])] = en; });
    data._lk = { natures: nat, species: makeLookup(data.species), moves: makeLookup(data.moves), hpTypes: hp,
      modes: makeLookup(data.modes), items: makeLookup(data.items || []) };
    return data._lk;
  }

  function asList(v) {
    if (v === null || v === undefined) return null;
    var l = Array.isArray(v) ? v : [v];
    return l.length ? l : null;
  }

  function statsObj(v) {
    if (!v || typeof v !== 'object' || Array.isArray(v)) return null;
    var out = {};
    Object.keys(v).forEach(function (k) { out[STAT_ALIASES[simplify(k)] || k] = v[k]; });
    return out;
  }

  // Canonical form: English nature/type names, canonical stat keys, exact mode names.
  // Unknown values are kept as written so validate() can report them.
  function normalize(bot, cfg, data) {
    var lk = lookups(data), c = {};
    Object.keys(cfg).forEach(function (k) { c[k] = cfg[k]; });
    function mapList(key, table) {
      var l = asList(c[key]);
      c[key] = l ? l.map(function (n) { return table[simplify(n)] || n; }) : (c[key] === undefined ? undefined : null);
    }
    if (bot === 'shinybot') {
      mapList('natures', lk.natures);
      mapList('species', lk.species);
      ['minIVs', 'maxIVs'].forEach(function (k) { if (c[k] !== undefined && c[k] !== null) c[k] = statsObj(c[k]) || c[k]; });
      if (c.hiddenPower && typeof c.hiddenPower === 'object' && c.hiddenPower.type) {
        c.hiddenPower = { type: lk.hpTypes[simplify(c.hiddenPower.type)] || c.hiddenPower.type, minPower: c.hiddenPower.minPower };
      }
      ['mode', 'afterSeedMode'].forEach(function (k) { if (typeof c[k] === 'string') c[k] = lk.modes[simplify(c[k])] || c[k]; });
      ['initialSeeds', 'newGameTSV'].forEach(function (k) {
        var l = asList(c[k]);
        if (l) c[k] = l.map(function (s) { return String(s).toUpperCase(); });
      });
    } else {
      if (bot === 'farmbot') {
        if (typeof c.mode === 'string') c.mode = simplify(c.mode);
        if (typeof c.takeItems === 'string') c.takeItems = simplify(c.takeItems);
        mapList('wantedItems', lk.items);
      }
      if (c.evs !== undefined && c.evs !== null) c.evs = statsObj(c.evs) || c.evs;
      mapList('species', lk.species);
      mapList('avoidSpecies', lk.species);
      mapList('wantedMoves', lk.moves);
      mapList('keepMoves', lk.moves);
      if (typeof c.learnMoves === 'string') c.learnMoves = simplify(c.learnMoves);
    }
    return c;
  }

  function isInt(v) { return typeof v === 'number' && isFinite(v) && Math.floor(v) === v; }

  // Mirrors the checks the bots run on load, plus warnings for configs that load fine but
  // won't do what the player expects. Returns [{level: 'error'|'warn'|'info', key, msg}].
  function validate(bot, cfg, data, schema) {
    var lk = lookups(data), out = [];
    function err(key, msg, v) { out.push({ level: 'error', key: key, msg: tr(msg, v) }); }
    function warn(key, msg, v) { out.push({ level: 'warn', key: key, msg: tr(msg, v) }); }
    function info(key, msg, v) { out.push({ level: 'info', key: key, msg: tr(msg, v) }); }
    function label(f) { return f.label ? tr(f.label) : f.key; }
    var fields = schema.fields(bot), known = {};
    fields.forEach(function (f) { known[f.key] = f; });

    Object.keys(cfg).forEach(function (k) {
      if (!known[k]) err(k, 'Opción desconocida: "{key}" (el bot no arrancaría)', { key: k });
    });

    fields.forEach(function (f) {
      var v = cfg[f.key];
      if (v === undefined || v === null) return;
      if (f.type === 'bool' && typeof v !== 'boolean') err(f.key, '{label}: debe ser sí o no', { label: label(f) });
      if (f.type === 'int') {
        if (!isInt(v)) err(f.key, '{label}: debe ser un número entero', { label: label(f) });
        else if ((f.min !== undefined && v < f.min) || (f.max !== undefined && v > f.max)) err(f.key, '{label}: debe estar entre {min} y {max}', { label: label(f), min: f.min, max: f.max });
      }
      if (f.type === 'text' || f.type === 'route') {
        if (typeof v !== 'string' || !v.trim()) err(f.key, '{label}: no puede estar vacío', { label: label(f) });
      }
      if (f.type === 'enum') {
        var opts = f.options.map(function (o) { return typeof o === 'string' ? o : o.value; });
        if (opts.indexOf(v) === -1) err(f.key, '{label}: valor no válido "{value}"', { label: label(f), value: v });
      }
    });

    function checkNames(key, table, msg) {
      var l = asList(cfg[key]);
      if (!l) return;
      l.forEach(function (n) { if (!table[simplify(n)]) err(key, msg, { name: n }); });
    }

    ['logDir', 'sharedDir'].forEach(function (k) {
      if (typeof cfg[k] === 'string' && UNSAFE_PATH.test(cfg[k])) warn(k, 'La carpeta contiene " % $ o `: el bot la ignorará y usará la del script');
    });

    if (bot === 'shinybot') {
      if (cfg.mode !== undefined && cfg.mode !== null && !lk.modes[simplify(cfg.mode)]) err('mode', 'Modo desconocido: "{name}"', { name: cfg.mode });
      checkNames('natures', lk.natures, 'Naturaleza desconocida: "{name}"');
      checkNames('species', lk.species, 'Especie desconocida: "{name}"');
      var iv = { minIVs: {}, maxIVs: {} };
      ['minIVs', 'maxIVs'].forEach(function (k) {
        var o = cfg[k];
        if (o === undefined || o === null) return;
        if (typeof o !== 'object' || Array.isArray(o)) { err(k, 'IVs: formato no válido'); return; }
        Object.keys(o).forEach(function (s) {
          var c = STAT_ALIASES[simplify(s)];
          if (!c) err(k, 'Estadística desconocida en IVs: "{name}"', { name: s });
          else if (!isInt(o[s]) || o[s] < 0 || o[s] > 31) err(k, 'IV de {stat} debe estar entre 0 y 31', { stat: s });
          else iv[k][c] = o[s];
        });
      });
      STAT_ORDER.forEach(function (s) {
        if (iv.minIVs[s] !== undefined && iv.maxIVs[s] !== undefined && iv.minIVs[s] > iv.maxIVs[s]) err('minIVs', 'IV de {stat}: el mínimo es mayor que el máximo', { stat: s });
      });
      var hp = cfg.hiddenPower;
      if (hp !== undefined && hp !== null) {
        if (typeof hp !== 'object') err('hiddenPower', 'Poder Oculto: formato no válido');
        else {
          if (hp.type && !lk.hpTypes[simplify(hp.type)]) err('hiddenPower', 'Tipo de Poder Oculto desconocido: "{name}"', { name: hp.type });
          if (hp.minPower !== undefined && hp.minPower !== null && (!isInt(hp.minPower) || hp.minPower < 30 || hp.minPower > 70)) err('hiddenPower', 'La potencia del Poder Oculto va de 30 a 70');
        }
      }
      ['initialSeeds', 'newGameTSV'].forEach(function (k) {
        var l = asList(cfg[k]);
        if (l) l.forEach(function (s) { if (!/^[0-9A-Fa-f]{1,4}$/.test(String(s))) err(k, 'Valor hex no válido: "{value}" (hasta 4 cifras 0-9 A-F)', { value: s }); });
      });
      if (cfg.mode === 'Semilla inicial') {
        if (!asList(cfg.initialSeeds)) err('initialSeeds', 'El modo Semilla inicial necesita al menos una semilla');
        if (!cfg.afterSeedMode) warn('afterSeedMode', 'Sin "modo después de la semilla", el bot solo carga la partida');
        else if ((asList(cfg.initialSeeds) || []).length < 3) info('initialSeeds', 'Cada reinicio solo alcanza 1 de 64 clases de semilla: con más semillas cae antes');
      }
      if (isInt(cfg.pressGapMin) && isInt(cfg.pressGapMax) && cfg.pressGapMin > cfg.pressGapMax) err('pressGapMin', 'La espera mínima entre A es mayor que la máxima');
      if (cfg.savestateSlot) warn('savestateSlot', 'En VBA-rr v22 guardar estado solo da "Error creating file"');
      if (cfg.shiny === false && !asList(cfg.natures) && !cfg.minIVs && !cfg.minIVTotal && !cfg.hiddenPower && !asList(cfg.species)) {
        warn('shiny', 'Sin shiny ni otros filtros, el bot se detendrá con el primer Pokémon');
      }
    } else {
      var total = 0, evs = cfg.evs;
      if (evs !== undefined && evs !== null) {
        if (typeof evs !== 'object' || Array.isArray(evs)) err('evs', 'EVs: formato no válido');
        else Object.keys(evs).forEach(function (s) {
          var c = STAT_ALIASES[simplify(s)];
          if (!c) err('evs', 'EV desconocido: "{name}"', { name: s });
          else if (!isInt(evs[s]) || evs[s] < 0) err('evs', 'EVs de {stat} deben ser un entero ≥ 0', { stat: s });
          else {
            if (evs[s] > 255) warn('evs', 'EVs de {stat} se recortan a 255', { stat: s });
            total += Math.min(evs[s], 255);
            if (evs[s] > 252 && evs[s] <= 255) info('evs', 'EVs de {stat}: a nivel 100 solo cuentan de 4 en 4; 252 rinde igual que 255', { stat: s });
          }
        });
        if (total > 510) err('evs', 'Los EVs suman {n} (máximo 510)', { n: total });
      }
      if (isInt(cfg.targetLevel) && isInt(cfg.maxLevel) && cfg.maxLevel < cfg.targetLevel) warn('maxLevel', 'El nivel máximo es menor que el objetivo: nunca llegará al objetivo');
      if (bot === 'trainbot' && (evs === null || evs === undefined || total === 0) && !cfg.targetLevel && !cfg.maxLevel) warn('evs', 'Sin EVs ni nivel objetivo el bot no sabe cuándo parar');
      if (bot === 'farmbot') {
        var fm = cfg.mode === undefined ? 'nivel' : cfg.mode;
        if (['nivel', 'objetos', 'robar', 'dinero'].indexOf(fm) === -1) err('mode', 'Modo desconocido: "{name}"', { name: fm });
        if (fm === 'nivel' && !cfg.targetLevel && !cfg.maxBattles) err('targetLevel', 'El modo nivel necesita un nivel objetivo (o un máximo de combates)');
        checkNames('wantedItems', lk.items, 'Objeto desconocido: "{name}"');
        if (fm === 'robar' && !asList(cfg.wantedItems)) info('wantedItems', 'Sin lista, robará cualquier objeto que lleve el salvaje');
        if (fm === 'dinero' && !cfg.moneyTarget && !cfg.maxBattles) info('moneyTarget', 'Sin dinero objetivo, seguirá hasta que lo detengas con 7');
        if ((fm === 'objetos' || fm === 'robar') && cfg.takeItems === 'pause') info('takeItems', 'El bot pausará cada vez que haya objetos para que los quites tú');
        if (fm === 'objetos') info('mode', 'Lleva en el equipo al menos un Pokémon con Recogida (Meowth); solo recoge al GANAR');
        if (fm === 'robar') info('mode', 'El primero del equipo necesita Ladrón o Antojo y no llevar objeto');
        if (fm === 'dinero') info('mode', 'Registra el Buscapelea en SELECT y graba la ruta de entrenadores con la tecla 5');
      }
      checkNames('species', lk.species, 'Especie desconocida: "{name}"');
      checkNames('avoidSpecies', lk.species, 'Especie desconocida: "{name}"');
      checkNames('wantedMoves', lk.moves, 'Ataque desconocido: "{name}"');
      checkNames('keepMoves', lk.moves, 'Ataque desconocido: "{name}"');
      if ((asList(cfg.wantedMoves) || []).length > 4) err('wantedMoves', 'Máximo 4 ataques deseados');
      var only = asList(cfg.species) || [], avoid = asList(cfg.avoidSpecies) || [];
      only.forEach(function (n) {
        if (avoid.map(simplify).indexOf(simplify(n)) !== -1) warn('species', '{name} está en las dos listas: el bot la evitará', { name: n });
      });
      if (evs && typeof evs === 'object' && total > 0) {
        var wanted = {};
        Object.keys(evs).forEach(function (s) { var c = STAT_ALIASES[simplify(s)]; if (c && evs[s] > 0) wanted[c] = true; });
        only.forEach(function (n) {
          var y = data.evYield[lk.species[simplify(n)]];
          if (!y) return;
          var extra = Object.keys(y).filter(function (s) { return !wanted[s]; });
          if (extra.length && !cfg.allowOvershoot) warn('species', '{name} da EVs de {stats}, que no están en tu objetivo: el bot huirá de ella', { name: n, stats: extra.join(', ') });
        });
      }
      if (isInt(cfg.healBelow) && isInt(cfg.fleeBelow) && cfg.fleeBelow > cfg.healBelow) warn('fleeBelow', 'Huye con más PS de los que necesita para curarse: revisa los porcentajes');
      var n = cfg.notify;
      if (n !== undefined && n !== null) {
        if (typeof n !== 'object' || Array.isArray(n)) err('notify', 'Avisos: formato no válido');
        else {
          Object.keys(n).forEach(function (k) { if (k !== 'ntfy' && k !== 'discord') warn('notify', 'Clave de aviso desconocida: "{key}"', { key: k }); });
          if (n.ntfy !== undefined && n.ntfy !== null && !NTFY_TOPIC.test(String(n.ntfy))) err('notify', 'El tema de ntfy solo puede tener letras, números, - y _');
          if (n.ntfy && String(n.ntfy).length < 10) warn('notify', 'Tema de ntfy corto: cualquiera que lo adivine leerá tus avisos');
          if (n.discord !== undefined && n.discord !== null && !DISCORD_URL.test(String(n.discord))) err('notify', 'La URL de Discord debe empezar por https:// y no llevar caracteres raros');
        }
      }
      if (cfg.healMode === 'tile' && cfg.routeFile && !/tower|torre/i.test(cfg.routeFile)) info('healMode', 'La casilla que cura solo existe en la Torre Pokémon 5F: tu ruta debe terminar ahí');
    }
    return out;
  }

  function q(s) { return JSON.stringify(s); }

  function valueText(v) {
    if (v === null || v === undefined) return 'null';
    if (Array.isArray(v)) return '[' + v.map(valueText).join(', ') + ']';
    if (typeof v === 'object') {
      var keys = Object.keys(v);
      if (!keys.length) return 'null';
      return '{' + keys.map(function (k) { return q(k) + ': ' + valueText(v[k]); }).join(', ') + '}';
    }
    if (typeof v === 'number') return String(Math.round(v));
    return q(v);
  }

  function orderStats(o) {
    if (!o || typeof o !== 'object' || Array.isArray(o)) return o;
    var out = {};
    STAT_ORDER.forEach(function (s) { if (o[s] !== undefined) out[s] = o[s]; });
    Object.keys(o).forEach(function (s) { if (out[s] === undefined) out[s] = o[s]; });
    return out;
  }

  // Commented JSON in the same style as the files shipped with the bots: one section
  // comment per group and a short comment per key. Only // comments between tokens and
  // integer numbers, which is what both bots' parsers accept.
  function serialize(bot, cfg, schema) {
    var def = schema.bots[bot], lines = ['{'];
    def.header.forEach(function (h) { lines.push('  // ' + tr(h)); });
    var all = [];
    def.sections.forEach(function (s) {
      var group = [];
      s.fields.forEach(function (f) {
        var v = cfg[f.key];
        if (v === undefined) v = f.def;
        if (f.type === 'ivRange' || f.type === 'evs' || f.key === 'maxIVs') v = orderStats(v);
        if (Array.isArray(v) && !v.length) v = null;
        group.push({ key: f.key, text: q(f.key) + ': ' + valueText(v), comment: f.comment && tr(f.comment) });
      });
      all.push({ title: tr(s.title), items: group });
    });
    var count = all.reduce(function (n, g) { return n + g.items.length; }, 0), i = 0;
    all.forEach(function (g) {
      lines.push('');
      lines.push('  // ---------------------- ' + g.title.toUpperCase() + ' ' + '-'.repeat(Math.max(3, 40 - g.title.length)));
      g.items.forEach(function (it) {
        i++;
        var line = '  ' + it.text + (i < count ? ',' : '');
        if (it.comment) line += (line.length < 46 ? ' '.repeat(46 - line.length) : ' ') + '// ' + it.comment;
        lines.push(line);
      });
    });
    lines.push('}');
    return lines.join('\r\n') + '\r\n';
  }

  // Values taken from a loaded file that the schema doesn't know (kept so they can be shown).
  function unknownKeys(bot, cfg, schema) {
    var known = {};
    schema.fields(bot).forEach(function (f) { known[f.key] = true; });
    return Object.keys(cfg).filter(function (k) { return !known[k]; });
  }

  // Which bot a loaded config belongs to, from its keys.
  function detectBot(cfg) {
    var farm = ['itemTarget', 'moneyTarget', 'trainerRouteFile', 'takeItems', 'wantedItems', 'maxBattles'];
    if (farm.some(function (k) { return k in cfg; }) ||
        ['nivel', 'objetos', 'robar', 'dinero'].indexOf(simplify(cfg.mode || '')) !== -1) return 'farmbot';
    var train = ['evs', 'healBelow', 'learnMoves', 'routeFile', 'healMode', 'avoidSpecies', 'wantedMoves'];
    var shiny = ['mode', 'shiny', 'natures', 'minIVs', 'initialSeeds', 'farSearch', 'teachy'];
    var t = train.filter(function (k) { return k in cfg; }).length, s = shiny.filter(function (k) { return k in cfg; }).length;
    return t > s ? 'trainbot' : s > t ? 'shinybot' : null;
  }

  function randomTopic() {
    var abc = 'abcdefghijkmnpqrstuvwxyz23456789', s = 'frlg-';
    var buf = new Uint32Array(14);
    (root.crypto || require('crypto').webcrypto).getRandomValues(buf);
    for (var i = 0; i < buf.length; i++) s += abc[buf[i] % abc.length];
    return s;
  }

  // ---------------------------------------------------------------- routes
  // FRLG_TrainRoute*.txt / FRLG_FarmTrainers.txt: a "GO" and a "BACK" line of
  // "group map x y dir" points. Parsed like the bots' routeFromText() and cleaned like
  // their cleanRoute(), so the viewer shows what the bot will actually walk.
  function routePoints(line) {
    var r = [], re = /(-?\d+) (-?\d+) (-?\d+) (-?\d+) (-?\d+)/g, m;
    while ((m = re.exec(line))) r.push({ g: +m[1], n: +m[2], x: +m[3], y: +m[4], d: +m[5] });
    return r;
  }
  function samePos(a, b) { return a && b && a.g === b.g && a.n === b.n && a.x === b.x && a.y === b.y; }
  function cleanRoute(r) {
    var out = [], dropped = 0;
    r.forEach(function (q) {
      var last = out[out.length - 1], junk = q.g > 42 || q.n > 120;
      if (last && !junk) {
        if (samePos(q, last)) junk = true;
        else if ((q.g !== last.g || q.n !== last.n) && q.x === last.x && q.y === last.y) junk = true;
      }
      if (junk) dropped++; else out.push(q);
    });
    return { points: out, dropped: dropped };
  }
  // Splits a path into runs that stay on one map.
  function mapRuns(points) {
    var runs = [];
    points.forEach(function (q) {
      var cur = runs[runs.length - 1];
      if (!cur || cur.g !== q.g || cur.n !== q.n) runs.push(cur = { g: q.g, n: q.n, points: [] });
      cur.points.push(q);
    });
    return runs;
  }
  function jumps(points) {
    var n = 0;
    for (var i = 1; i < points.length; i++) {
      var a = points[i - 1], b = points[i];
      if (a.g === b.g && a.n === b.n && Math.abs(a.x - b.x) + Math.abs(a.y - b.y) > 1) n++;
    }
    return n;
  }
  // Returns { go, back, maps: [{ g, n, go: [runs], back: [runs] }], spot, heal, issues }.
  function routeReport(text) {
    var lines = String(text || '').split(/\r?\n/), goLine = null, backLine = null;
    lines.forEach(function (l) {
      var m = /^\s*(GO|BACK) (.*)$/.exec(l);
      if (m && m[1] === 'GO' && goLine === null) goLine = m[2];
      if (m && m[1] === 'BACK' && backLine === null) backLine = m[2];
    });
    var go = cleanRoute(routePoints(goLine || '')), back = cleanRoute(routePoints(backLine || ''));
    var issues = [];
    if (goLine === null && backLine === null) {
      issues.push({ level: 'error', msg: tr('No parece un archivo de ruta: faltan las líneas GO y BACK') });
    } else {
      if (!go.points.length) issues.push({ level: 'error', msg: tr('La ida (GO) está vacía: graba la ruta otra vez') });
      if (!back.points.length) issues.push({ level: 'error', msg: tr('La vuelta (BACK) está vacía: graba la ruta otra vez') });
    }
    var spot = back.points[back.points.length - 1] || null, start = go.points[0] || null;
    if (spot && start && !samePos(spot, start)) {
      issues.push({ level: 'warn', msg: tr('La vuelta no termina donde empieza la ida: el bot entrena donde acaba la vuelta') });
    }
    var j = jumps(go.points) + jumps(back.points);
    if (j) issues.push({ level: 'warn', msg: tr(j === 1 ? '{n} salto de más de una casilla en el mismo mapa: el bot puede atascarse ahí'
      : '{n} saltos de más de una casilla en el mismo mapa: el bot puede atascarse ahí', { n: j }) });
    var dropped = go.dropped + back.dropped;
    if (dropped) issues.push({ level: 'info', msg: tr(dropped === 1 ? '{n} punto repetido o de cruzar una puerta: el bot los ignora'
      : '{n} puntos repetidos o de cruzar una puerta: el bot los ignora', { n: dropped }) });
    var maps = [], byKey = {};
    [['go', go.points], ['back', back.points]].forEach(function (pair) {
      mapRuns(pair[1]).forEach(function (run) {
        var key = run.g + '.' + run.n;
        if (!byKey[key]) maps.push(byKey[key] = { g: run.g, n: run.n, go: [], back: [] });
        byKey[key][pair[0]].push(run.points);
      });
    });
    return { go: go.points, back: back.points, maps: maps, spot: spot, heal: go.points[go.points.length - 1] || null, issues: issues };
  }

  // ---------------------------------------------------------------- logs
  // shiny_log.txt / train_log.txt / farm_log.txt: one "[date] [game] [Instancia N] text"
  // line per event (see each bot's logLine). Builds the numbers the stats dialog shows.
  var LOG_LINE = /^\[(\d{4})-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)\] \[([^\]]*)\] (?:\[Instancia (\d+)\] )?(.*)$/;
  var SHINY_FIND = /^\[(SHINY Square|SHINY Star|OBJETIVO)\] (.+?)  PID ([0-9A-F]{8})  (\S+)  IVs (\S+)  tras (\d+) intentos \(modo ([^)]+)\)/;
  function logEvents(text) {
    var out = [];
    String(text || '').split(/\r?\n/).forEach(function (l) {
      var m = LOG_LINE.exec(l);
      if (m) out.push({ t: new Date(+m[1], +m[2] - 1, +m[3], +m[4], +m[5], +m[6]).getTime(), game: m[7], inst: m[8] ? +m[8] : null, msg: m[9] });
    });
    return out;
  }
  function detectLog(ev) {
    for (var i = 0; i < ev.length; i++) {
      var s = ev[i].msg;
      if (ev[i].inst !== null || SHINY_FIND.test(s) || /^\[(TID\/SID|SEMILLA)\]|^Shiny descartado/.test(s)) return 'shinybot';
      if (/^Farmeo iniciado|^FARMEO COMPLETO|^\+\$\d+|^DIAG /.test(s)) return 'farmbot';
      if (/^Entrenamiento iniciado|^ENTRENAMIENTO COMPLETO/.test(s)) return 'trainbot';
    }
    return null;
  }
  // Splits a Train/Farm log into runs: each starts with "... iniciado" (events before the
  // first start go to an "earlier" run).
  function sessions(ev, startRe) {
    var out = [];
    ev.forEach(function (e) {
      if (startRe.test(e.msg) || !out.length) out.push({ start: e.t, end: e.t, head: startRe.test(e.msg) ? e.msg : '', events: [] });
      var s = out[out.length - 1];
      s.events.push(e); s.end = e.t;
    });
    return out;
  }
  function farmSession(s) {
    var r = { start: s.start, end: s.end, head: s.head, money: [], earned: 0, levels: [], items: {}, stored: 0, found: 0,
      heals: 0, laps: 0, evolutions: 0, learned: 0, done: '', stops: [] };
    var m = /^Farmeo iniciado \(modo (\w+)\): (.+) Nv\.(\d+)/.exec(s.head);
    if (m) { r.mode = m[1]; r.species = m[2]; r.levels.push({ t: s.start, v: +m[3] }); }
    s.events.forEach(function (e) {
      var x;
      if ((x = /^\+\$(\d+)  \(total \$(\d+)\)/.exec(e.msg))) {
        if (!r.money.length) r.money.push({ t: r.start, v: +x[2] - +x[1] });
        r.money.push({ t: e.t, v: +x[2] }); r.earned += +x[1];
      } else if ((x = /^.+ subio al Nv\.(\d+)$/.exec(e.msg))) r.levels.push({ t: e.t, v: +x[1] });
      else if ((x = /^.+ consiguio (.+)$/.exec(e.msg))) { r.found++; r.items[x[1]] = (r.items[x[1]] || 0) + 1; }
      else if (/^Guardado en la mochila: /.test(e.msg)) r.stored++;
      else if (/^Al Centro Pokemon/.test(e.msg)) r.heals++;
      else if (/^Vuelta \d+:/.test(e.msg)) r.laps++;
      else if (/ evoluciono a /.test(e.msg)) r.evolutions++;
      else if (/ aprendio /.test(e.msg)) r.learned++;
      else if (/^FARMEO COMPLETO/.test(e.msg)) r.done = e.msg;
    });
    return r;
  }
  function trainSession(s) {
    var r = { start: s.start, end: s.end, head: s.head, heals: 0, evolutions: 0, learned: 0, done: '', events: [] };
    var m = /^Entrenamiento iniciado: (.+) Nv\.(\d+)  EVs (\S+)/.exec(s.head);
    if (m) { r.species = m[1]; r.level = +m[2]; r.evs = m[3]; }
    s.events.forEach(function (e) {
      if (/^Al Centro Pokemon/.test(e.msg)) r.heals++;
      else if (/ evoluciono a /.test(e.msg)) { r.evolutions++; r.events.push(e); }
      else if (/ aprendio /.test(e.msg)) { r.learned++; r.events.push(e); }
      else if (/^ENTRENAMIENTO COMPLETO/.test(e.msg)) { r.done = e.msg; r.events.push(e); }
    });
    return r;
  }
  // Returns { bot, events, sessions | finds, ... } or { bot: null } for an unknown file.
  function logReport(text) {
    var ev = logEvents(text), bot = detectLog(ev), r = { bot: bot, lines: ev.length };
    if (bot === 'shinybot') {
      r.finds = []; r.discarded = 0; r.sids = 0; r.seeds = 0;
      ev.forEach(function (e) {
        var m = SHINY_FIND.exec(e.msg);
        if (m) r.finds.push({ t: e.t, kind: m[1], species: m[2], pid: m[3], nature: m[4], ivs: m[5], tries: +m[6], mode: m[7], inst: e.inst });
        else if (/^Shiny descartado/.test(e.msg)) r.discarded++;
        else if (/^\[TID\/SID\]/.test(e.msg)) r.sids++;
        else if (/^\[SEMILLA\]/.test(e.msg)) r.seeds++;
      });
      r.shinies = r.finds.filter(function (f) { return f.kind !== 'OBJETIVO'; }).length;
      r.avgTries = r.finds.length ? Math.round(r.finds.reduce(function (a, f) { return a + f.tries; }, 0) / r.finds.length) : 0;
    } else if (bot === 'farmbot') {
      r.sessions = sessions(ev, /^Farmeo iniciado/).map(farmSession);
    } else if (bot === 'trainbot') {
      r.sessions = sessions(ev, /^Entrenamiento iniciado/).map(trainSession);
    }
    return r;
  }

  var api = {
    simplify: simplify, stripComments: stripComments, parseConfig: parseConfig, normalize: normalize,
    validate: validate, serialize: serialize, unknownKeys: unknownKeys, detectBot: detectBot,
    randomTopic: randomTopic, routeReport: routeReport, logReport: logReport, STAT_ALIASES: STAT_ALIASES, STAT_ORDER: STAT_ORDER
  };
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  else { root.PT = root.PT || {}; root.PT.core = api; }
})(typeof window !== 'undefined' ? window : globalThis);
