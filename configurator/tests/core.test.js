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

test('detectBot tells the two configs apart', () => {
  assert.equal(core.detectBot(data.presets.shinybot[0].config), 'shinybot');
  assert.equal(core.detectBot(data.presets.trainbot[0].config), 'trainbot');
});

test('randomTopic is a valid, long ntfy topic', () => {
  const t = core.randomTopic();
  assert.match(t, /^[A-Za-z0-9_-]{15,}$/);
});
