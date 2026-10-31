// Every Spanish source text of the configurator has an English and a Japanese translation
// with the same {placeholders}, and the dictionaries have no leftovers.
//   node --test configurator/tests/i18n.test.js
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const { keys } = require('../tools/i18n_keys.js');

const dir = path.join(__dirname, '..', 'js');
const ctx = {};
ctx.window = ctx;   // the language files use the global PT, like in the page
vm.createContext(ctx);
['i18n.js', 'lang/en.js', 'lang/ja.js'].forEach((f) => vm.runInContext(fs.readFileSync(path.join(dir, f), 'utf8'), ctx));
const i18n = ctx.PT.i18n;
const KEYS = keys();
const placeholders = (s) => (String(s).match(/\{\w+\}/g) || []).sort().join(',');

test('the key list covers the interface', () => {
  assert.ok(KEYS.length > 400, 'only ' + KEYS.length + ' keys found');
  for (const k of ['Guardar', 'Siguiente: {s}', '{label}: debe estar entre {min} y {max}', 'Salvaje RNG', 'Exigir shiny']) {
    assert.ok(KEYS.includes(k), 'missing key ' + k);
  }
});

for (const lang of ['en', 'ja']) {
  test(lang + ': every text is translated, with the same placeholders', () => {
    const d = i18n.dict(lang);
    const missing = KEYS.filter((k) => typeof d[k] !== 'string' || !d[k].trim());
    assert.deepEqual(missing, [], 'untranslated in ' + lang);
    const bad = KEYS.filter((k) => placeholders(k) !== placeholders(d[k]));
    assert.deepEqual(bad, [], 'placeholders differ in ' + lang);
    const unused = Object.keys(d).filter((k) => !KEYS.includes(k));
    assert.deepEqual(unused, [], 'unused entries in ' + lang);
  });
}

test('t() fills placeholders and falls back to Spanish', () => {
  i18n.set('en');
  assert.equal(i18n.t('Máximo {n}', { n: 4 }), 'Maximum 4');
  assert.equal(i18n.t('texto sin traducir'), 'texto sin traducir');
  i18n.set('xx');
  assert.equal(i18n.lang(), 'es');
  i18n.set('ja');
  assert.equal(i18n.extra().natures.Adamant, 'いじっぱり');
  i18n.set('es');
});
