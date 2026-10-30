// Skin registry for the configurator. Built-in skins live in configurator/skins/*.js and
// call PT.registerSkin(); players can also import a skin as a .json file. Imported skins
// are data only and are sanitized: known CSS variables, data: images and data: fonts.
(function (root) {
  'use strict';

  var VARS = ['--bg', '--bg-pattern', '--surface', '--surface-2', '--border', '--text', '--muted',
    '--accent', '--accent-ink', '--accent-2', '--accent-soft', '--ok', '--warn', '--error',
    '--header-bg', '--header-ink', '--radius', '--radius-sm', '--shadow',
    '--font-body', '--font-display', '--font-mono', '--backdrop-opacity'];
  var SPRITES = ['mascot', 'backdrop-shinybot', 'backdrop-trainbot', 'backdrop-farmbot'].concat(Object.keys((root.PT && root.PT.art && root.PT.art.icons) || {}));
  var IMG = /^data:image\/(png|gif|webp|svg\+xml)[;,]/i;
  var FONT = /^data:(font\/(woff2?|ttf|otf)|application\/(font-woff2?|x-font-ttf|octet-stream))[;,]/i;
  var STORE = 'pt-configurator-custom-skins';

  var registry = {}, order = [];

  function cleanValue(v) {
    if (typeof v !== 'string' || v.length > 200000) return null;
    if (/[;{}<>]/.test(v)) return null;
    var urls = v.match(/url\(([^)]*)\)/gi) || [];
    for (var i = 0; i < urls.length; i++) {
      var inner = urls[i].slice(4, -1).trim().replace(/^["']|["']$/g, '');
      if (!IMG.test(inner)) return null;
    }
    if (/expression\s*\(|javascript:/i.test(v)) return null;
    return v;
  }

  // Returns a safe copy of a skin, or throws with a Spanish message.
  function sanitize(skin) {
    if (!skin || typeof skin !== 'object') throw new Error('El skin debe ser un objeto JSON');
    var id = String(skin.id || '').toLowerCase().replace(/[^a-z0-9-]/g, '').slice(0, 40);
    if (!id) throw new Error('El skin necesita un "id" (letras, números y guiones)');
    var out = {
      id: id,
      name: String(skin.name || id).slice(0, 60),
      author: skin.author ? String(skin.author).slice(0, 60) : '',
      dark: !!skin.dark,
      pixelated: !!skin.pixelated,
      vars: {}, sprites: {}, fonts: []
    };
    Object.keys(skin.vars || {}).forEach(function (k) {
      if (VARS.indexOf(k) === -1) return;
      var v = cleanValue(skin.vars[k]);
      if (v !== null) out.vars[k] = v;
    });
    Object.keys(skin.sprites || {}).forEach(function (k) {
      var v = skin.sprites[k];
      if (SPRITES.indexOf(k) === -1 || typeof v !== 'string') return;
      if (IMG.test(v) || (root.PT.art.sprites[v])) out.sprites[k] = v;
    });
    (skin.fonts || []).slice(0, 4).forEach(function (f) {
      if (!f || typeof f.family !== 'string' || typeof f.src !== 'string') return;
      var fam = f.family.replace(/[^A-Za-z0-9 _-]/g, '').slice(0, 40);
      if (fam && FONT.test(f.src)) out.fonts.push({ family: fam, src: f.src });
    });
    return out;
  }

  function register(skin, opts) {
    var s = sanitize(skin);
    s.builtin = !(opts && opts.custom);
    if (!registry[s.id]) order.push(s.id);
    registry[s.id] = s;
    return s;
  }

  function loadCustom() {
    try {
      var list = JSON.parse(root.localStorage.getItem(STORE) || '[]');
      list.forEach(function (s) { try { register(s, { custom: true }); } catch (e) { /* skip broken */ } });
    } catch (e) { /* storage unavailable */ }
  }

  function saveCustom() {
    try {
      var list = order.map(function (id) { return registry[id]; }).filter(function (s) { return !s.builtin; });
      root.localStorage.setItem(STORE, JSON.stringify(list));
      return true;
    } catch (e) { return false; }
  }

  function remove(id) {
    if (!registry[id] || registry[id].builtin) return;
    delete registry[id];
    order.splice(order.indexOf(id), 1);
    saveCustom();
  }

  var fontStyle = null;
  function apply(id) {
    var s = registry[id] || registry[order[0]];
    var st = root.document.documentElement.style;
    VARS.forEach(function (k) { st.removeProperty(k); });
    Object.keys(s.vars).forEach(function (k) { st.setProperty(k, s.vars[k]); });
    st.setProperty('color-scheme', s.dark ? 'dark' : 'light');
    root.document.documentElement.dataset.skin = s.id;
    if (!fontStyle) {
      fontStyle = root.document.createElement('style');
      root.document.head.appendChild(fontStyle);
    }
    fontStyle.textContent = s.fonts.map(function (f) {
      return '@font-face{font-family:"' + f.family + '";src:url("' + f.src + '");font-display:swap}';
    }).join('');
    return s;
  }

  // Returns a node for a sprite or icon, honoring the active skin's replacements.
  function art(name, skinId) {
    var s = registry[skinId] || {}, over = (s.sprites || {})[name];
    var wrap = root.document.createElement('span');
    wrap.className = 'art art-' + name;
    if (over && IMG.test(over)) {
      var img = root.document.createElement('img');
      img.src = over; img.alt = ''; img.decoding = 'async';
      if (s.pixelated) img.style.imageRendering = 'pixelated';
      wrap.appendChild(img);
    } else {
      var key = over || name;
      wrap.innerHTML = root.PT.art.sprites[key] || root.PT.art.icons[key] || '';
    }
    return wrap;
  }

  function list() { return order.map(function (id) { return registry[id]; }); }

  // A JSON a player can edit to start their own skin.
  function exportable(id) {
    var s = registry[id];
    return JSON.stringify({
      id: s.builtin ? s.id + '-mio' : s.id, name: s.builtin ? s.name + ' (mío)' : s.name,
      author: s.author, dark: s.dark, pixelated: s.pixelated, vars: s.vars, sprites: s.sprites, fonts: s.fonts
    }, null, 2);
  }

  root.PT = root.PT || {};
  root.PT.skins = { VARS: VARS, register: register, sanitize: sanitize, loadCustom: loadCustom, saveCustom: saveCustom,
    remove: remove, apply: apply, art: art, list: list, get: function (id) { return registry[id]; }, exportable: exportable };
  root.PT.registerSkin = register;
})(window);
