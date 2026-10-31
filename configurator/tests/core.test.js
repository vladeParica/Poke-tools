// Unit tests for configurator/js/core.js.  Run:  node --test configurator/tests/
const test = require('node:test');
const assert = require('node:assert/strict');
const { data, schema, core } = require('./load');

function issues(bot, cfg) {
  return core.validate(bot, core.normalize(bot, cfg, data), data, schema);
}
function errorKeys(bot, cfg) {
  return issues(bot, cfg).filter((i) => i.level === 'error').map((i) => i.key);
}

test('routeReport parses, cleans and checks a route like the bots do', () => {
  const r = core.routeReport('GO 3 20 8 10 0;3 20 9 10 4;3 20 9 10 4;4 1 9 10 2;4 1 5 8 2\nBACK 4 1 5 8 0;3 20 10 3 1;3 20 8 10 3\n');
  assert.equal(r.go.length, 3);                       // duplicate and door ghost dropped
  assert.deepEqual(r.maps.map((m) => m.g + '.' + m.n), ['3.20', '4.1']);
  assert.deepEqual(r.spot, { g: 3, n: 20, x: 8, y: 10, d: 3 });
  assert.ok(r.issues.some((i) => i.level === 'info' && /2 puntos/.test(i.msg)));
  assert.ok(r.issues.some((i) => i.level === 'warn' && /salto/.test(i.msg)));
  assert.equal(r.issues.filter((i) => i.level === 'error').length, 0);
});

test('routeReport flags files that are not routes and a way back that ends elsewhere', () => {
  assert.equal(core.routeReport('hola').issues[0].level, 'error');
  const r = core.routeReport('GO 3 20 8 10 0;3 20 9 10 4\nBACK 3 20 9 10 0;3 20 9 11 1\n');
  assert.ok(r.issues.some((i) => /no termina donde empieza/.test(i.msg)));
});

test('the bundled example routes have no errors', () => {
  for (const [name, text] of Object.entries(data.routeText)) {
    const r = core.routeReport(text);
    assert.equal(r.issues.filter((i) => i.level === 'error').length, 0, name);
    assert.ok(r.go.length > 5 && r.back.length > 5, name);
  }
});

const LOG = (lines) => lines.map(([t, m]) => '[2026-10-30 ' + t + '] [FireRed USA v1.0] ' + m).join('\n') + '\n';

test('logReport reads a Farm Bot log into sessions with money, levels and items', () => {
  const r = core.logReport(LOG([
    ['10:00:00', 'Farmeo iniciado (modo dinero): Charmander Nv.12'],
    ['10:05:00', '+$480  (total $3480)'],
    ['10:09:00', 'Charmander subio al Nv.13'],
    ['10:10:00', '+$480  (total $3960)'],
    ['10:12:00', 'Al Centro Pokemon: PS bajos'],
    ['11:00:00', 'Farmeo iniciado (modo objetos): Meowth Nv.20'],
    ['11:01:00', 'Meowth consiguio Nugget'],
    ['11:02:00', 'Meowth consiguio Nugget'],
    ['11:02:30', 'Guardado en la mochila: Nugget (tienes 2)'],
    ['11:03:00', 'FARMEO COMPLETO: 2 objetos'],
  ]));
  assert.equal(r.bot, 'farmbot');
  assert.equal(r.sessions.length, 2);
  const [a, b] = r.sessions;
  assert.equal(a.mode, 'dinero');
  assert.equal(a.earned, 960);
  assert.deepEqual(a.money.map((p) => p.v), [3000, 3480, 3960]);
  assert.deepEqual(a.levels.map((p) => p.v), [12, 13]);
  assert.equal(a.heals, 1);
  assert.deepEqual(b.items, { Nugget: 2 });
  assert.equal(b.stored, 1);
  assert.match(b.done, /COMPLETO/);
});

test('logReport reads Shiny Bot finds and Train Bot sessions, and rejects other files', () => {
  const s = core.logReport('[2026-10-30 10:00:00] [FireRed USA v1.0] [Instancia 1] [SHINY Star] Raikou  PID 4734A33E  Careful  IVs 22/6/0/0/0/0  tras 1500 intentos (modo Roamer RNG) | corrida iniciada 2026-10-30 09:00\n'
    + '[2026-10-30 11:00:00] [FireRed USA v1.0] [Instancia 2] [OBJETIVO] Abra  PID 0000ABCD  Timid  IVs 31/0/31/31/31/31  tras 500 intentos (modo Estatico)\n');
  assert.equal(s.bot, 'shinybot');
  assert.equal(s.finds.length, 2);
  assert.equal(s.shinies, 1);
  assert.equal(s.avgTries, 1000);
  assert.equal(s.finds[0].species, 'Raikou');
  const t = core.logReport(LOG([
    ['09:00:00', 'Entrenamiento iniciado: Abra Nv.10  EVs 0/0/0/0/0/0'],
    ['09:30:00', 'Abra evoluciono a Kadabra'],
    ['10:00:00', 'ENTRENAMIENTO COMPLETO: Kadabra Nv.20  EVs 0/0/0/252/0/252'],
  ]));
  assert.equal(t.bot, 'trainbot');
  assert.equal(t.sessions[0].species, 'Abra');
  assert.equal(t.sessions[0].evolutions, 1);
  assert.equal(core.logReport('hola\nmundo').bot, null);
});

test('stripComments keeps // inside strings', () => {
  const p = core.parseConfig('{\n  // comment\n  "notify": {"discord": "https://x.y/z"}, // tail\n  "a": 1\n}');
  assert.ok(p.ok);
  assert.equal(p.value.notify.discord, 'https://x.y/z');
});

test('parseConfig reports invalid JSON in Spanish', () => {
  const p = core.parseConfig('{ "a": }');
  assert.equal(p.ok, false);
  assert.match(p.error, /JSON inválido/);
});

test('normalize maps Spanish names the same way the bots do', () => {
  const c = core.normalize('shinybot', { natures: ['Modesta', 'timida'], minIVs: { ps: 31, vel: 30 }, hiddenPower: { type: 'fuego' }, mode: 'salvaje rng' }, data);
  assert.deepEqual(c.natures, ['Modest', 'Bashful']);
  assert.deepEqual(c.minIVs, { hp: 31, spe: 30 });
  assert.equal(c.hiddenPower.type, 'Fire');
  assert.equal(c.mode, 'Salvaje RNG');
});

test('shipped and example configs validate without errors and round-trip', () => {
  for (const bot of ['shinybot', 'trainbot']) {
    for (const p of data.presets[bot]) {
      const c = core.normalize(bot, JSON.parse(JSON.stringify(p.config)), data);
      assert.deepEqual(issues(bot, c).filter((i) => i.level === 'error'), [], p.name);
      const back = core.normalize(bot, core.parseConfig(core.serialize(bot, c, schema)).value, data);
      for (const k of Object.keys(c)) {
        const a = c[k] && typeof c[k] === 'object' && !Array.isArray(c[k]) ? Object.keys(c[k]).sort().map((x) => [x, c[k][x]]) : c[k];
        const b = back[k] && typeof back[k] === 'object' && !Array.isArray(back[k]) ? Object.keys(back[k]).sort().map((x) => [x, back[k][x]]) : back[k];
        assert.deepEqual(b, a, p.name + ' → ' + k);
      }
    }
  }
});

test('serialize writes only what the bots can parse', () => {
  const text = core.serialize('trainbot', core.normalize('trainbot', { evs: { spe: 252 }, notify: { ntfy: 'frlg-abcdefghijk' }, species: ["Farfetch'd"] }, data), schema);
  assert.doesNotMatch(text, /\\u[0-9a-f]{4}/i, 'no unicode escapes');
  assert.doesNotMatch(text, /\d[eE][+-]?\d/, 'no exponents');
  assert.doesNotMatch(text, /\/\*/, 'no block comments');
  assert.ok(text.endsWith('}\r\n'));
  const keys = Object.keys(core.parseConfig(text).value);
  assert.deepEqual(keys.sort(), schema.fields('trainbot').map((f) => f.key).sort());
});

test('validation mirrors the bots\' rules', () => {
  assert.deepEqual(errorKeys('shinybot', { foo: 1 }), ['foo']);
  assert.ok(errorKeys('shinybot', { natures: ['Adamantx'] }).includes('natures'));
  assert.ok(errorKeys('shinybot', { species: ['Pikachuu'] }).includes('species'));
  assert.ok(errorKeys('shinybot', { minIVs: { hp: 32 } }).includes('minIVs'));
  assert.ok(errorKeys('shinybot', { minIVs: { hp: 20 }, maxIVs: { hp: 10 } }).includes('minIVs'));
  assert.ok(errorKeys('shinybot', { mode: 'Semilla inicial', initialSeeds: null }).includes('initialSeeds'));
  assert.ok(errorKeys('shinybot', { initialSeeds: ['XYZ1'] }).includes('initialSeeds'));
  assert.ok(errorKeys('shinybot', { hiddenPower: { type: 'Sound' } }).includes('hiddenPower'));
  assert.ok(errorKeys('trainbot', { evs: { atk: 252, spe: 252, hp: 10 } }).includes('evs'));
  assert.ok(errorKeys('trainbot', { evs: { luck: 4 } }).includes('evs'));
  assert.ok(errorKeys('trainbot', { wantedMoves: ['Tackle', 'Ember', 'Growl', 'Scratch', 'Leer'] }).includes('wantedMoves'));
  assert.ok(errorKeys('trainbot', { learnMoves: 'sometimes' }).includes('learnMoves'));
  assert.ok(errorKeys('trainbot', { notify: { ntfy: 'bad topic!' } }).includes('notify'));
  assert.ok(errorKeys('trainbot', { notify: { discord: 'http://insecure' } }).includes('notify'));
});

test('warnings for configs that load but misbehave', () => {
  const w = (bot, cfg) => issues(bot, cfg).filter((i) => i.level === 'warn').map((i) => i.key);
  assert.ok(w('trainbot', { logDir: 'logs"&calc' }).includes('logDir'));
  assert.ok(w('trainbot', { evs: { spe: 252 }, species: ['Geodude'] }).includes('species'), 'Geodude gives Def, not Spe');
  assert.ok(w('trainbot', { species: ['Gastly'], avoidSpecies: ['gastly'], evs: { spa: 4 } }).includes('species'));
  assert.ok(w('shinybot', { shiny: false }).includes('shiny'));
});

test('detectBot tells the three configs apart', () => {
  assert.equal(core.detectBot(data.presets.shinybot[0].config), 'shinybot');
  assert.equal(core.detectBot(data.presets.trainbot[0].config), 'trainbot');
  for (const p of data.presets.farmbot) assert.equal(core.detectBot(p.config), 'farmbot', p.name);
});

test('Farm Bot: modes, required level and item names', () => {
  assert.ok(errorKeys('farmbot', { mode: 'farmear' }).includes('mode'));
  assert.ok(errorKeys('farmbot', { mode: 'nivel' }).includes('targetLevel'));
  assert.deepEqual(errorKeys('farmbot', { mode: 'nivel', targetLevel: 30 }), []);
  assert.deepEqual(errorKeys('farmbot', { mode: 'dinero', moneyTarget: 99999 }), []);
  assert.ok(errorKeys('farmbot', { mode: 'robar', wantedItems: ['Nuggett'] }).includes('wantedItems'));
  const c = core.normalize('farmbot', { mode: 'ROBAR', wantedItems: ['tiny mushroom'], takeItems: 'Pause' }, data);
  assert.equal(c.mode, 'robar');
  assert.equal(c.takeItems, 'pause');
  assert.deepEqual(c.wantedItems, ['Tinymushroom']);
  const msgs = issues('farmbot', { mode: 'robar', wantedItems: ['Nuggett'] }).map((i) => i.msg).join(' ');
  assert.match(msgs, /Objeto desconocido/);
});

test('randomTopic is a valid, long ntfy topic', () => {
  const t = core.randomTopic();
  assert.match(t, /^[A-Za-z0-9_-]{15,}$/);
});
