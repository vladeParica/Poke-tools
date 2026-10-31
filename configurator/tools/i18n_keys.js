// Lists every Spanish source text of the configurator that needs a translation:
// tr() calls, validation messages, schema labels/help/comments, example names, built-in
// skin names and the data-i18n parts of index.html. Used by tests/i18n.test.js.
//   node configurator/tools/i18n_keys.js            -> JSON list of keys
//   node configurator/tools/i18n_keys.js missing en -> keys without an English entry
const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..');
const read = (f) => fs.readFileSync(path.join(ROOT, f), 'utf8');

// String literals inside the first argument of name( ... ), e.g. tr(a ? 'x' : 'y', {...}).
function firstArgLiterals(src, name) {
  const out = [];
  const re = new RegExp('\\b' + name + '\\(', 'g');
  let m;
  while ((m = re.exec(src))) {
    let i = m.index + m[0].length, depth = 0;
    for (; i < src.length; i++) {
      const c = src[i];
      if (c === "'" || c === '"') {
        let j = i + 1, s = '';
        while (src[j] !== c) { if (src[j] === '\\') { s += src[j + 1]; j += 2; } else s += src[j++]; }
        // skip comparison operands such as kind === 'hexlist'
        if (depth === 0 && !/[=!]==\s*$/.test(src.slice(Math.max(0, i - 6), i))) out.push(s);
        i = j;
      } else if (c === '(' || c === '[' || c === '{') depth++;
      else if (c === ')' || c === ']' || c === '}') { if (depth === 0) break; depth--; }
      else if (c === ',' && depth === 0) break;
    }
  }
  return out;
}
// Second argument literal of err/warn/info(key, 'msg', ...) and checkNames(key, table, 'msg').
function messageLiterals(src) {
  const out = [];
  const re = /\b(?:err|warn|info)\([^,]+,\s*'((?:[^'\\]|\\.)*)'/g;
  let m;
  while ((m = re.exec(src))) out.push(m[1].replace(/\\(.)/g, '$1'));
  const cn = /checkNames\([^,]+,[^,]+,\s*'((?:[^'\\]|\\.)*)'/g;
  while ((m = cn.exec(src))) out.push(m[1].replace(/\\(.)/g, '$1'));
  const er = /new Error\('((?:[^'\\]|\\.)*)'\)/g;
  while ((m = er.exec(src))) out.push(m[1].replace(/\\(.)/g, '$1'));
  return out;
}
function schemaStrings() {
  const schema = require(path.join(ROOT, 'js', 'schema.js'));
  const out = [];
  const add = (s) => { if (typeof s === 'string' && s.trim()) out.push(s); };
  schema.MODES.forEach((m) => { add(m.label); add(m.desc); });
  schema.STATS.forEach((s) => { add(s.label); add(s.short); });
  Object.keys(schema.bots).forEach((b) => {
    const d = schema.bots[b];
    add(d.tagline);
    (d.header || []).forEach(add);
    d.sections.forEach((s) => {
      add(s.title); add(s.desc);
      s.fields.forEach((f) => {
        add(f.label); add(f.help); add(f.comment); add(f.unit);
        (f.options || []).forEach((o) => { if (typeof o === 'object') add(o.label); });
        (f.cards || []).forEach((c) => { add(c.label); add(c.desc); });
      });
    });
  });
  return out;
}
function presetNames() {
  const vm = require('vm');
  const ctx = { window: {} };
  vm.createContext(ctx);
  vm.runInContext(read('js/data.js'), ctx);
  const presets = ctx.window.PT.data.presets;
  return [].concat(...Object.keys(presets).map((b) => presets[b].map((p) => p.name.replace(/\.$/, ''))));
}
function htmlStrings() {
  const html = read('index.html'), out = [];
  let m;
  const text = /<([a-z0-9]+)[^>]*\bdata-i18n(?:=""|)(?=[\s>])[^>]*>([^<]*)</g;
  while ((m = text.exec(html))) out.push(m[2].trim());
  // data-i18n-html: inner markup up to the element's closing tag (no nested same tag)
  const rich = /<([a-z0-9]+)([^>]*\bdata-i18n-html[^>]*)>([\s\S]*?)<\/\1>/g;
  while ((m = rich.exec(html))) out.push(m[3].trim());
  const attr = /<[^>]*\bdata-i18n-attr="([^"]+)"[^>]*>/g;
  while ((m = attr.exec(html))) {
    m[1].split(',').forEach((a) => {
      const v = new RegExp('\\b' + a + '="([^"]*)"').exec(m[0]);
      if (v) out.push(v[1]);
    });
  }
  return out;
}
function skinNames() {
  const dir = path.join(ROOT, 'skins');
  return fs.readdirSync(dir).filter((f) => f.endsWith('.js'))
    .map((f) => (/name: '([^']+)'/.exec(fs.readFileSync(path.join(dir, f), 'utf8')) || [])[1]).filter(Boolean);
}

function keys() {
  const app = read('js/app.js'), core = read('js/core.js'), skin = read('js/skin.js');
  const all = [].concat(
    firstArgLiterals(app, 'tr'), firstArgLiterals(core, 'tr'), messageLiterals(core), messageLiterals(skin),
    schemaStrings(), presetNames(), htmlStrings(), skinNames());
  return [...new Set(all.filter((s) => s && /[A-Za-zÁÉÍÓÚáéíóúñ]/.test(s)))];
}

module.exports = { keys };

if (require.main === module) {
  const k = keys();
  if (process.argv[2] === 'missing') {
    const vm = require('vm');
    const ctx = {};
    ctx.window = ctx;   // the language files use the global PT, like in the page
    vm.createContext(ctx);
    ['js/i18n.js', 'js/lang/' + process.argv[3] + '.js'].forEach((f) => vm.runInContext(read(f), ctx));
    const d = ctx.PT.i18n.dict(process.argv[3]);
    console.log(JSON.stringify(k.filter((s) => d[s] === undefined), null, 1));
  } else {
    console.log(JSON.stringify(k, null, 1));
  }
}
