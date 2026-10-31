// Configurator UI. Renders the schema as forms, keeps one config per bot, validates on
// every change and saves the commented JSON next to the bot (File System Access API in
// Edge/Chrome; download elsewhere). Player-facing text is written in Spanish and goes
// through tr() (js/i18n.js), which shows it in the chosen language.
(function () {
  'use strict';

  var PT = window.PT, schema = PT.schema, core = PT.core, data = PT.data, skins = PT.skins, i18n = PT.i18n, tr = i18n.t;
  var DRAFT = 'pt-configurator-draft-v1', SKIN = 'pt-configurator-skin', BG = 'pt-configurator-backdrop', LANG = 'pt-configurator-lang';
  var lk = null;

  var S = {
    bot: 'shinybot',
    cfg: { shinybot: null, trainbot: null, farmbot: null },
    origin: { shinybot: '', trainbot: '', farmbot: '' },
    dir: null,
    section: { shinybot: 'mode', trainbot: 'goal', farmbot: 'mode' },
    skin: 'fuego'
  };

  // ---------------------------------------------------------------- helpers
  function $(id) { return document.getElementById(id); }
  function h(tag, attrs) {
    var el = document.createElement(tag);
    if (attrs) Object.keys(attrs).forEach(function (k) {
      var v = attrs[k];
      if (v === undefined || v === null || v === false) return;
      if (k === 'text') el.textContent = v;
      else if (k === 'class') el.className = v;
      else if (k.slice(0, 2) === 'on') el.addEventListener(k.slice(2), v);
      else el.setAttribute(k, v === true ? '' : v);
    });
    for (var i = 2; i < arguments.length; i++) {
      var c = arguments[i];
      if (c === null || c === undefined || c === false) continue;
      (Array.isArray(c) ? c : [c]).forEach(function (n) { el.appendChild(typeof n === 'string' ? document.createTextNode(n) : n); });
    }
    return el;
  }
  function icon(name) { return skins.art(name, S.skin); }
  // Background behind each bot's form. The player's choice (Apariencia dialog, stored in
  // this browser per bot) wins over the skin's image, which wins over the official artwork.
  // Prefs: { opacity: 0..0.4, style: 'frlg'|'home'|'artwork', shiny: bool,
  //          <bot>: { species } | { image: dataURL } | { none: true } }
  function bgPrefs() { try { return JSON.parse(store(BG) || '{}') || {}; } catch (e) { return {}; } }
  function bgSave(p) {
    try { localStorage.setItem(BG, JSON.stringify(p)); return true; } catch (e) { return false; }
  }
  function speciesSprite(name) {
    var p = bgPrefs(), i = data.species.indexOf(name);
    if (i < 0) return null;
    var style = p.style || 'frlg';
    return { srcs: PT.art.spriteUrls(i + 1, name, style, !!p.shiny), pixel: style === 'frlg' };
  }
  function bgSource(bot) {
    var mine = bgPrefs()[bot], sk = skins.get(S.skin) || {}, over = (sk.sprites || {})['backdrop-' + bot];
    if (mine && mine.none) return null;
    if (mine && mine.image) return { srcs: [mine.image] };
    if (mine && mine.species && speciesSprite(mine.species)) return speciesSprite(mine.species);
    if (over) return { skin: true };
    if (sk.backdrop && speciesSprite(sk.backdrop)) return speciesSprite(sk.backdrop);
    return speciesSprite(data.species[PT.art.backdrops[bot] - 1]);
  }
  // An <img> that tries each source in turn and disappears if none loads.
  function bgImage(src) {
    if (src.skin) return icon('backdrop-' + S.bot);
    var i = 0, img = h('img', { src: src.srcs[0], alt: '', decoding: 'async', referrerpolicy: 'no-referrer',
      class: src.pixel ? 'pixel' : null });
    img.addEventListener('error', function () { if (++i < src.srcs.length) img.src = src.srcs[i]; else img.remove(); });
    return img;
  }
  function backdrop() { var src = bgSource(S.bot); return src ? bgImage(src) : null; }
  function bgOpacity() { var o = bgPrefs().opacity; return typeof o === 'number' ? o : null; }
  function store(key, val) { try { if (val === undefined) return localStorage.getItem(key); localStorage.setItem(key, val); } catch (e) { return null; } }
  function cfg() { return S.cfg[S.bot]; }
  function def() { return schema.bots[S.bot]; }
  function fieldDef(key) { return schema.fields(S.bot).filter(function (f) { return f.key === key; })[0]; }
  // Nature and type names in the interface language (the JSON keeps the English ones).
  function natDisplay(n) { return i18n.lang() === 'es' ? schema.NATURES_ES_DISPLAY[n] : (i18n.extra().natures || {})[n] || ''; }
  function natLabel(n) { var d = natDisplay(n); return d ? n + ' · ' + d : n; }
  function typeLabel(t) {
    var d = i18n.lang() === 'es' ? schema.TYPES_ES_DISPLAY[t] : (i18n.extra().types || {})[t];
    return d ? d + ' (' + t + ')' : t;
  }
  function modeLabel(m) { var x = schema.MODES.filter(function (o) { return o.value === m; })[0]; return x ? tr(x.label) : m; }

  var toastTimer;
  function toast(msg, ic) {
    var t = $('toast');
    t.innerHTML = '';
    t.appendChild(icon(ic || 'check'));
    t.appendChild(h('span', { text: msg }));
    t.classList.add('show');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(function () { t.classList.remove('show'); }, 3200);
  }

  function hydrateIcons(root) {
    (root || document).querySelectorAll('[data-icon]').forEach(function (el) {
      el.innerHTML = '';
      el.appendChild(icon(el.getAttribute('data-icon')));
    });
  }

  // ---------------------------------------------------------------- state
  function presetConfig(bot, i) {
    return core.normalize(bot, JSON.parse(JSON.stringify(data.presets[bot][i || 0].config)), data);
  }

  function saveDraft() {
    store(DRAFT, JSON.stringify({ bot: S.bot, cfg: S.cfg, origin: S.origin }));
  }

  function loadDraft() {
    var raw = store(DRAFT);
    if (raw) {
      try {
        var d = JSON.parse(raw);
        ['shinybot', 'trainbot', 'farmbot'].forEach(function (b) {
          if (d.cfg && d.cfg[b]) { S.cfg[b] = d.cfg[b]; S.origin[b] = (d.origin && d.origin[b]) || ''; }
        });
        if (d.bot === 'shinybot' || d.bot === 'trainbot' || d.bot === 'farmbot') S.bot = d.bot;
      } catch (e) { /* ignore broken draft */ }
    }
    ['shinybot', 'trainbot', 'farmbot'].forEach(function (b) {
      if (!S.cfg[b]) { S.cfg[b] = presetConfig(b, 0); S.origin[b] = 'Por defecto'; }
    });
  }

  function setVal(key, value) {
    if (value === '' || (Array.isArray(value) && !value.length) ||
        (value && typeof value === 'object' && !Array.isArray(value) && !Object.keys(value).length)) value = null;
    cfg()[key] = value;
    refresh();
  }

  // ---------------------------------------------------------------- controls
  function switchCtl(f) {
    var input = h('input', { type: 'checkbox', id: 'f-' + f.key });
    input.checked = cfg()[f.key] === undefined ? !!f.def : !!cfg()[f.key];
    input.addEventListener('change', function () { setVal(f.key, input.checked); });
    return h('label', { class: 'switch', for: 'f-' + f.key }, input, h('span', { class: 'track' }), h('span', { text: tr(f.label) }));
  }

  function intCtl(f) {
    var v = cfg()[f.key];
    var num = h('input', { type: 'number', id: 'f-' + f.key, min: f.min, max: f.max, step: 1, inputmode: 'numeric',
      placeholder: f.nullable ? tr('vacío') : String(f.def) });
    if (v !== undefined && v !== null) num.value = v;
    else if (!f.nullable && f.def !== null) num.value = f.def;
    function commit() {
      if (num.value === '') { setVal(f.key, f.nullable ? null : f.def); return; }
      setVal(f.key, Math.round(Number(num.value)));
    }
    num.addEventListener('input', commit);
    if (!f.slider) return h('div', { class: 'row' }, num, f.unit ? h('span', { class: 'unit', text: tr(f.unit) }) : null);
    var range = h('input', { type: 'range', min: f.min, max: f.max, step: 1, 'aria-label': tr(f.label) });
    range.value = num.value || f.def;
    range.addEventListener('input', function () { num.value = range.value; commit(); });
    num.addEventListener('input', function () { range.value = num.value; });
    return h('div', { class: 'slider-row' }, range, h('div', { class: 'row' }, num, f.unit ? h('span', { class: 'unit', text: tr(f.unit) }) : null));
  }

  function textCtl(f) {
    var v = cfg()[f.key];
    var inp = h('input', { type: 'text', id: 'f-' + f.key, placeholder: f.nullable ? tr('vacío = por defecto') : String(f.def), spellcheck: 'false' });
    inp.value = v === undefined || v === null ? (f.nullable ? '' : f.def) : v;
    inp.addEventListener('input', function () { setVal(f.key, inp.value.trim() === '' ? (f.nullable ? null : f.def) : inp.value.trim()); });
    return inp;
  }

  function enumCtl(f) {
    var opts = f.options.map(function (o) { return typeof o === 'string' ? { value: o, label: modeLabel(o) } : { value: o.value, label: tr(o.label) }; });
    var cur = cfg()[f.key] === undefined ? f.def : cfg()[f.key];
    if (f.segmented) {
      var wrap = h('div', { class: 'segmented', role: 'group', 'aria-label': tr(f.label) });
      opts.forEach(function (o) {
        var b = h('button', { type: 'button', 'aria-pressed': String(cur === o.value), text: o.label });
        b.addEventListener('click', function () {
          wrap.querySelectorAll('button').forEach(function (x) { x.setAttribute('aria-pressed', 'false'); });
          b.setAttribute('aria-pressed', 'true');
          setVal(f.key, o.value);
        });
        wrap.appendChild(b);
      });
      return wrap;
    }
    var sel = h('select', { id: 'f-' + f.key });
    if (f.nullable) sel.appendChild(h('option', { value: '', text: tr('— ninguno —') }));
    opts.forEach(function (o) { sel.appendChild(h('option', { value: o.value, text: o.label })); });
    sel.value = cur === null || cur === undefined ? '' : cur;
    sel.addEventListener('change', function () { setVal(f.key, sel.value || null); });
    return sel;
  }

  function modeCtl(f) {
    var grid = h('div', { class: 'modes', role: 'radiogroup', 'aria-label': tr(f.label) });
    var cur = cfg().mode === undefined || cfg().mode === null ? f.def : cfg().mode;
    (f.cards || schema.MODES).forEach(function (m) {
      var b = h('button', { type: 'button', class: 'mode', role: 'radio', 'aria-checked': String(cur === m.value) },
        h('span', { class: 'm-head' }, icon(m.icon), h('span', { text: tr(m.label) })),
        h('span', { class: 'm-desc', text: tr(m.desc) }),
        m.rng ? h('span', { class: 'rng', text: 'RNG' }) : null);
      b.addEventListener('click', function () {
        grid.querySelectorAll('.mode').forEach(function (x) { x.setAttribute('aria-checked', 'false'); });
        b.setAttribute('aria-checked', 'true');
        setVal('mode', m.value);
      });
      grid.appendChild(b);
    });
    return grid;
  }

  var dlCount = 0;
  function datalist(options) {
    var id = 'dl-' + (++dlCount);
    var dl = h('datalist', { id: id });
    options.forEach(function (o) { dl.appendChild(h('option', { value: o.value, label: o.label || '' })); });
    return { el: dl, id: id };
  }

  function evTargets() {
    var t = {}, evs = S.bot === 'trainbot' ? cfg().evs : null;
    if (evs) Object.keys(evs).forEach(function (s) { if (evs[s] > 0) t[s] = true; });
    return t;
  }

  function yieldBadges(name) {
    var y = data.evYield[name];
    if (!y) return null;
    var t = evTargets(), out = h('span', { class: 'yield' });
    schema.STATS.forEach(function (s) {
      if (y[s.key]) out.appendChild(h('span', { class: 'badge' + (t[s.key] ? ' hit' : ''), title: tr(s.label), text: '+' + y[s.key] + ' ' + tr(s.short) }));
    });
    return out;
  }

  // Chip list editor for natures, species, moves and hex values.
  function chipsCtl(f) {
    var kind = f.type, table, options;
    if (kind === 'natures') { table = lk.natures; options = data.natures.map(function (n) { return { value: n, label: natDisplay(n) }; }); }
    if (kind === 'species') { table = lk.species; options = data.species.map(function (n) { return { value: n }; }); }
    if (kind === 'moves') { table = lk.moves; options = data.moves.map(function (n) { return { value: n }; }); }
    if (kind === 'items') { table = lk.items; options = data.items.map(function (n) { return { value: n }; }); }
    var box = h('div', { class: 'chips' });
    var dl = options ? datalist(options) : null;
    var basePh = tr(kind === 'hexlist' ? 'Ej. BC75 (Enter para añadir)' : kind === 'natures' ? 'Escribe una naturaleza…' : kind === 'moves' ? 'Escribe un ataque en inglés…' : kind === 'items' ? 'Escribe un objeto en inglés…' : 'Escribe una especie…');
    var input = h('input', { type: 'text', id: 'f-' + f.key, list: dl ? dl.id : null, spellcheck: 'false', autocomplete: 'off', placeholder: basePh });
    var addBtn = h('button', { type: 'button', class: 'btn icon', title: tr('Añadir'), 'aria-label': tr('Añadir') }, icon('plus'));
    var msg = h('p', { class: 'help', hidden: true });

    function list() { return (cfg()[f.key] || []).slice(); }
    function draw() {
      box.innerHTML = '';
      var l = list();
      l.forEach(function (item, i) {
        var ok = kind === 'hexlist' ? /^[0-9A-F]{1,4}$/.test(item) : !!table[core.simplify(item)];
        var label = kind === 'natures' && ok ? natLabel(table[core.simplify(item)]) : item;
        var rm = h('button', { type: 'button', title: tr('Quitar'), 'aria-label': tr('Quitar {item}', { item: item }) }, icon('x'));
        rm.addEventListener('click', function () { var n = list(); n.splice(i, 1); setVal(f.key, n); draw(); });
        box.appendChild(h('span', { class: 'chip' + (ok ? '' : ' bad') }, h('span', { text: label }),
          f.showYield && ok ? yieldBadges(table[core.simplify(item)]) : null, rm));
      });
      var full = f.max && l.length >= f.max;
      input.disabled = full; addBtn.disabled = full;
      input.placeholder = full ? tr('Máximo {n}', { n: f.max }) : basePh;
      box.appendChild(h('span', { class: 'chip-input' }, input, addBtn));
    }
    function add(raw) {
      var parts = kind === 'hexlist' ? String(raw).split(/[\s,;]+/) : [raw];
      var l = list(), bad = [];
      parts.forEach(function (p) {
        p = p.trim();
        if (!p) return;
        var v;
        if (kind === 'hexlist') { v = p.replace(/^0x/i, '').toUpperCase(); if (!/^[0-9A-F]{1,4}$/.test(v)) { bad.push(p); return; } }
        else { v = table[core.simplify(p)]; if (!v) { bad.push(p); return; } }
        if (l.map(core.simplify).indexOf(core.simplify(v)) === -1 && !(f.max && l.length >= f.max)) l.push(v);
      });
      msg.hidden = !bad.length;
      msg.textContent = bad.length ? tr('No reconozco: {list}', { list: bad.join(', ') }) : '';
      if (!bad.length) input.value = '';
      setVal(f.key, l);
      draw();
    }
    input.addEventListener('keydown', function (e) { if (e.key === 'Enter') { e.preventDefault(); add(input.value); } });
    input.addEventListener('change', function () { if (table && table[core.simplify(input.value)]) add(input.value); });
    addBtn.addEventListener('click', function () { add(input.value); input.focus(); });
    draw();
    box._redraw = draw;
    return h('div', null, box, dl ? dl.el : null, msg);
  }

  function ivCtl(f) {
    var grid = h('div', { class: 'statgrid' });
    function get(k) { return cfg()[k] || {}; }
    schema.STATS.forEach(function (s) {
      var mn = h('input', { type: 'number', min: 0, max: 31, placeholder: '0', 'aria-label': tr('IV mínimo de {stat}', { stat: tr(s.label) }) });
      var mx = h('input', { type: 'number', min: 0, max: 31, placeholder: '31', 'aria-label': tr('IV máximo de {stat}', { stat: tr(s.label) }) });
      if (get('minIVs')[s.key] !== undefined) mn.value = get('minIVs')[s.key];
      if (get('maxIVs')[s.key] !== undefined) mx.value = get('maxIVs')[s.key];
      function commit(which, input) {
        var o = Object.assign({}, get(which));
        if (input.value === '') delete o[s.key]; else o[s.key] = Math.max(0, Math.min(31, Math.round(Number(input.value))));
        cfg()[which] = Object.keys(o).length ? o : null;
        refresh();
      }
      mn.addEventListener('input', function () { commit('minIVs', mn); });
      mx.addEventListener('input', function () { commit('maxIVs', mx); });
      function quick(label, a, b, title) {
        var q = h('button', { type: 'button', class: 'btn small', text: label, title: title });
        q.addEventListener('click', function () { mn.value = a; mx.value = b; commit('minIVs', mn); commit('maxIVs', mx); });
        return q;
      }
      grid.appendChild(h('div', { class: 'statrow' }, icon(s.icon), h('span', { class: 'sname', text: tr(s.label) }),
        h('span', { class: 'iv-pair' }, mn, h('span', { text: tr('a') }), mx),
        h('span', { class: 'quick' }, quick('31', 31, '', tr('Mínimo 31')), quick('0', '', 0, tr('Máximo 0 (ej. Ataque en especiales)')), quick(tr('Libre'), '', '', tr('Sin filtro')))));
    });
    return grid;
  }

  function evCtl(f) {
    var wrap = h('div', { class: 'statgrid' });
    var total = h('div', { class: 'total' }, h('div', { class: 'tline' }, h('span', { text: tr('Total') }), h('span', { class: 'tval' })),
      h('div', { class: 'bar' }, h('span')));
    function get() { return cfg().evs || {}; }
    function drawTotal() {
      var t = 0, e = get();
      Object.keys(e).forEach(function (k) { t += Math.min(255, e[k] || 0); });
      total.querySelector('.tval').textContent = t + ' / 510';
      total.querySelector('.bar > span').style.width = Math.min(100, t / 510 * 100) + '%';
      total.classList.toggle('over', t > 510);
    }
    schema.STATS.forEach(function (s) {
      var range = h('input', { type: 'range', min: 0, max: 255, step: 1, 'aria-label': tr('EVs de {stat}', { stat: tr(s.label) }) });
      var num = h('input', { type: 'number', min: 0, max: 255, step: 1, 'aria-label': tr('EVs de {stat}', { stat: tr(s.label) }) });
      var v = get()[s.key] || 0;
      range.value = v; num.value = v;
      function commit(val) {
        val = Math.max(0, Math.min(255, Math.round(Number(val) || 0)));
        range.value = val; num.value = val;
        var o = Object.assign({}, get());
        if (val) o[s.key] = val; else delete o[s.key];
        cfg().evs = Object.keys(o).length ? o : null;
        drawTotal(); refresh(); redrawYields();
      }
      range.addEventListener('input', function () { commit(range.value); });
      num.addEventListener('input', function () { if (num.value !== '') commit(num.value); });
      function quick(n) {
        var b = h('button', { type: 'button', class: 'btn small', text: String(n) });
        b.addEventListener('click', function () { commit(n); });
        return b;
      }
      wrap.appendChild(h('div', { class: 'statrow' }, icon(s.icon), h('span', { class: 'sname', text: tr(s.label) }),
        h('div', { class: 'slider-row' }, range, num), h('span', { class: 'quick' }, quick(0), quick(4), quick(252))));
    });
    drawTotal();
    return h('div', { class: 'statgrid' }, wrap, total);
  }

  function redrawYields() {
    document.querySelectorAll('.field[data-key="species"] .chips, .field[data-key="avoidSpecies"] .chips').forEach(function (c) { if (c._redraw) c._redraw(); });
  }

  function hpCtl() {
    var cur = cfg().hiddenPower || {};
    var sel = h('select', { 'aria-label': tr('Tipo de Poder Oculto') }, h('option', { value: '', text: tr('— sin filtro —') }));
    data.hpTypes.forEach(function (t) { sel.appendChild(h('option', { value: t, text: typeLabel(t) })); });
    sel.value = cur.type || '';
    var pow = h('input', { type: 'number', min: 30, max: 70, placeholder: '30–70', 'aria-label': tr('Potencia mínima') });
    if (cur.minPower) pow.value = cur.minPower;
    function commit() {
      var o = {};
      if (sel.value) o.type = sel.value;
      if (pow.value !== '') o.minPower = Math.round(Number(pow.value));
      setVal('hiddenPower', o);
    }
    sel.addEventListener('change', commit); pow.addEventListener('input', commit);
    return h('div', { class: 'row' }, h('div', { style: 'flex:1 1 200px' }, sel), pow, h('span', { class: 'unit', text: tr('potencia mínima') }));
  }

  function notifyCtl() {
    var cur = cfg().notify || {};
    var topic = h('input', { type: 'text', spellcheck: 'false', autocomplete: 'off', placeholder: 'frlg-xxxxxxxxxxxxxx', 'aria-label': tr('Tema de ntfy') });
    var url = h('input', { type: 'url', spellcheck: 'false', autocomplete: 'off', placeholder: 'https://discord.com/api/webhooks/…', 'aria-label': tr('Webhook de Discord') });
    topic.value = cur.ntfy || ''; url.value = cur.discord || '';
    function commit() {
      var o = {};
      if (topic.value.trim()) o.ntfy = topic.value.trim();
      if (url.value.trim()) o.discord = url.value.trim();
      setVal('notify', o);
    }
    topic.addEventListener('input', commit); url.addEventListener('input', commit);
    var gen = h('button', { type: 'button', class: 'btn', title: tr('Crear un tema difícil de adivinar') }, icon('wand'), tr('Generar'));
    gen.addEventListener('click', function () { topic.value = core.randomTopic(); commit(); toast(tr('Tema nuevo: suscríbete a él en la app ntfy')); });
    return h('div', { class: 'statgrid' },
      h('div', null, h('div', { class: 'help', text: tr('ntfy (tema)') }), h('div', { class: 'row' }, h('div', { style: 'flex:1 1 220px' }, topic), gen)),
      h('div', null, h('div', { class: 'help', text: tr('Discord (webhook)') }), url));
  }

  function routeCtl(f) {
    var cur = cfg().routeFile || f.def;
    var known = [f.def].concat(data.routes);
    var sel = h('select', { id: 'f-routeFile' });
    known.forEach(function (r) { sel.appendChild(h('option', { value: r, text: tr(r === f.def ? '{file} (grabada con la tecla 6)' : '{file} (lista para usar)', { file: r }) })); });
    sel.appendChild(h('option', { value: '__other', text: tr('Otro nombre…') }));
    var other = h('input', { type: 'text', spellcheck: 'false', placeholder: 'FRLG_TrainRoute_Lugar.txt', hidden: true });
    if (known.indexOf(cur) === -1) { sel.value = '__other'; other.hidden = false; other.value = cur; } else sel.value = cur;
    sel.addEventListener('change', function () {
      other.hidden = sel.value !== '__other';
      if (sel.value === '__other') { other.focus(); return; }
      setVal('routeFile', sel.value);
      var tile = /tower/i.test(sel.value);
      if (data.routes.indexOf(sel.value) !== -1 && cfg().healMode !== (tile ? 'tile' : 'nurse')) {
        cfg().healMode = tile ? 'tile' : 'nurse';
        renderForm();
        toast(tr('Curación ajustada a "{mode}" para esa ruta', { mode: tr(tile ? 'Casilla que cura' : 'Enfermera') }));
      }
    });
    other.addEventListener('input', function () { setVal('routeFile', other.value.trim() || f.def); });
    return h('div', { class: 'statgrid' }, sel, other);
  }

  var BUILDERS = {
    bool: switchCtl, int: intCtl, text: textCtl, enum: enumCtl, mode: modeCtl,
    natures: chipsCtl, species: chipsCtl, moves: chipsCtl, items: chipsCtl, hexlist: chipsCtl,
    ivRange: ivCtl, evs: evCtl, hiddenPower: hpCtl, notify: notifyCtl, route: routeCtl
  };

  function fieldEl(f) {
    if (f.type === 'hidden') return null;
    var ctl = BUILDERS[f.type](f);
    var isBool = f.type === 'bool';
    var view = f.viewer ? h('button', { type: 'button', class: 'btn small route-view', onclick: function () { viewRoute(f); } },
      icon('route'), h('span', { text: tr('Ver ruta') })) : null;
    return h('div', { class: 'field' + (f.half ? ' half' : ''), 'data-key': f.key },
      isBool ? null : h('label', { class: 'label', for: 'f-' + f.key }, h('span', { text: tr(f.label) }), h('code', { text: f.key })),
      h('div', { class: 'control-wrap' }, ctl, view),
      f.help ? h('p', { class: 'help', text: tr(f.help) }) : null);
  }

  // ---------------------------------------------------------------- render
  // One section is shown at a time; the left rail lists them like tabs.
  var SECTION_OF = {};
  function sectionOf(key) {
    if (!SECTION_OF[S.bot]) {
      var m = {};
      def().sections.forEach(function (s) { s.fields.forEach(function (f) { m[f.key] = s.id; }); });
      SECTION_OF[S.bot] = m;
    }
    return SECTION_OF[S.bot][key];
  }
  function visibleSections() {
    return def().sections.filter(function (s) { return !(s.showIf && !s.showIf(cfg())); });
  }
  function currentSection() {
    var vis = visibleSections(), id = S.section[S.bot];
    return vis.filter(function (s) { return s.id === id; })[0] || vis[0];
  }

  function renderTabs() {
    ['shinybot', 'trainbot', 'farmbot'].forEach(function (b) {
      var t = $('tab-' + b);
      t.innerHTML = '';
      t.appendChild(icon(schema.bots[b].icon));
      t.appendChild(h('span', { text: schema.bots[b].name }));
      t.setAttribute('aria-selected', String(S.bot === b));
    });
  }

  function renderNav() {
    var nav = $('sections'), d = def(), cur = currentSection();
    nav.innerHTML = '';
    var presetSel = h('select', { 'aria-label': tr('Ejemplos'), title: tr('Cargar un ejemplo') });
    presetSel.appendChild(h('option', { value: '', text: tr('Cargar ejemplo…') }));
    data.presets[S.bot].forEach(function (p, i) { presetSel.appendChild(h('option', { value: i, text: tr(p.name.replace(/\.$/, '')) })); });
    presetSel.addEventListener('change', function () {
      if (presetSel.value === '') return;
      var p = data.presets[S.bot][Number(presetSel.value)];
      if (!confirm(tr('Esto reemplaza la configuración actual de {bot} por "{name}". ¿Seguir?', { bot: d.name, name: tr(p.name.replace(/\.$/, '')) }))) { presetSel.value = ''; return; }
      S.cfg[S.bot] = presetConfig(S.bot, Number(presetSel.value));
      S.origin[S.bot] = p.name;
      renderForm();
      toast(tr('Ejemplo cargado: {name}', { name: tr(p.name.replace(/\.$/, '')) }));
    });
    nav.appendChild(h('div', { class: 'nav-head' },
      h('span', { class: 'bot-icon' }, icon(d.icon)),
      h('div', null, h('b', { text: d.name }), h('small', { text: tr(d.tagline) }))));
    nav.appendChild(presetSel);

    var list = h('div', { class: 'nav-list', role: 'tablist', 'aria-orientation': 'vertical', 'aria-label': tr('Secciones') });
    var shownAdvanced = false;
    def().sections.forEach(function (s) {
      if (s.advanced && !shownAdvanced) { list.appendChild(h('div', { class: 'nav-sep', text: tr('Avanzado') })); shownAdvanced = true; }
      var b = h('button', { type: 'button', role: 'tab', class: 'nav-item', 'data-nav': s.id, 'aria-selected': String(cur && cur.id === s.id) },
        h('span', { class: 'n-icon' }, icon(s.icon)), h('span', { class: 'n-title', text: tr(s.title) }), h('span', { class: 'n-badge', hidden: true }));
      b.addEventListener('click', function () { goSection(s.id); });
      list.appendChild(b);
    });
    list.addEventListener('keydown', function (e) {
      if (['ArrowDown', 'ArrowUp', 'ArrowLeft', 'ArrowRight'].indexOf(e.key) === -1) return;
      e.preventDefault();
      var vis = visibleSections(), i = vis.indexOf(currentSection());
      var n = vis[(i + (e.key === 'ArrowDown' || e.key === 'ArrowRight' ? 1 : -1) + vis.length) % vis.length];
      goSection(n.id);
      var btn = nav.querySelector('[data-nav="' + n.id + '"]');
      if (btn) btn.focus();
    });
    nav.appendChild(list);
  }

  function renderSection() {
    var main = $('form'), s = currentSection(), vis = visibleSections(), i = vis.indexOf(s);
    main.innerHTML = '';
    if (!s) return;
    S.section[S.bot] = s.id;
    var body = h('div', { class: 'body' });
    s.fields.forEach(function (f) { var el = fieldEl(f); if (el) body.appendChild(el); });
    var prev = vis[i - 1], next = vis[i + 1];
    function stepBtn(target, dir) {
      if (!target) return h('span');
      var b = h('button', { type: 'button', class: 'btn' + (dir > 0 ? ' primary' : '') },
        dir < 0 ? h('span', { class: 'flip' }, icon('chevron')) : null,
        h('span', { text: tr(dir < 0 ? 'Anterior: {s}' : 'Siguiente: {s}', { s: tr(target.title) }) }),
        dir > 0 ? h('span', { class: 'turn' }, icon('chevron')) : null);
      b.addEventListener('click', function () { goSection(target.id); });
      return b;
    }
    main.appendChild(h('section', { class: 'card panel', 'data-section': s.id, role: 'tabpanel' },
      h('div', { class: 'backdrop', 'aria-hidden': 'true', style: bgOpacity() === null ? null : 'opacity:' + bgOpacity() }, backdrop()),
      h('button', { type: 'button', class: 'btn small bg-btn', title: tr('Cambiar el fondo'), onclick: function () { openAppearance(true); } },
        icon('palette'), h('span', { text: tr('Fondo') })),
      h('header', null, h('span', { class: 'sec-icon' }, icon(s.icon)),
        h('div', null, h('h2', { text: tr(s.title) }), s.desc ? h('p', { text: tr(s.desc) }) : null),
        h('span', { class: 'step', text: (i + 1) + ' / ' + vis.length })),
      h('div', { class: 'scroll' }, body),
      h('footer', null, stepBtn(prev, -1), stepBtn(next, 1))));
  }

  function goSection(id) {
    S.section[S.bot] = id;
    document.querySelectorAll('.nav-item').forEach(function (b) { b.setAttribute('aria-selected', String(b.getAttribute('data-nav') === id)); });
    renderSection();
    refresh();
  }

  function renderForm() {
    renderNav();
    renderSection();
    refresh();
  }

  function highlight(text) {
    var esc = text.replace(/\r/g, '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
    return esc.split('\n').map(function (line) {
      var i = line.indexOf('//'), code = line, comment = '';
      if (i !== -1 && line.slice(0, i).split('"').length % 2 === 1) { code = line.slice(0, i); comment = '<span class="c">' + line.slice(i) + '</span>'; }
      return code.replace(/^(\s*)("[^"]+")(:)/, '$1<span class="k">$2</span>$3') + comment;
    }).join('\n');
  }

  function refresh() {
    var c = cfg();
    // The mode can hide the section on screen: jump to a visible one.
    var cur = currentSection();
    if (cur && cur.id !== S.section[S.bot]) { goSection(cur.id); return; }
    def().sections.forEach(function (s) {
      var item = document.querySelector('[data-nav="' + s.id + '"]');
      if (item) item.hidden = !!(s.showIf && !s.showIf(c));
      s.fields.forEach(function (f) {
        var el = document.querySelector('.field[data-key="' + f.key + '"]');
        if (el) el.hidden = !!(f.showIf && !f.showIf(c));
      });
    });
    var vis = visibleSections(), step = document.querySelector('.panel .step');
    if (step && cur) step.textContent = (vis.indexOf(cur) + 1) + ' / ' + vis.length;
    // validation
    var issues = core.validate(S.bot, c, data, schema);
    var errs = issues.filter(function (i) { return i.level === 'error'; });
    var warns = issues.filter(function (i) { return i.level === 'warn'; });
    var sum = $('status-summary');
    sum.className = 'summary ' + (errs.length ? 'error' : warns.length ? 'warn' : 'ok');
    sum.innerHTML = '';
    sum.appendChild(icon(errs.length ? 'error' : warns.length ? 'warn' : 'check'));
    sum.appendChild(h('span', { text: errs.length ? tr(errs.length === 1 ? '{n} error: el bot no arrancaría' : '{n} errores: el bot no arrancaría', { n: errs.length })
      : warns.length ? tr(warns.length === 1 ? 'Lista, con {n} aviso' : 'Lista, con {n} avisos', { n: warns.length }) : tr('Lista para usar') }));
    var cnt = $('issue-count');
    cnt.hidden = !(errs.length || warns.length);
    cnt.textContent = errs.length || warns.length;
    cnt.className = 'count ' + (errs.length ? 'error' : 'warn');
    // per-section badges
    var per = {};
    issues.forEach(function (i) {
      var sid = sectionOf(i.key) || null;
      if (!sid || i.level === 'info') return;
      per[sid] = per[sid] || { error: 0, warn: 0 };
      per[sid][i.level]++;
    });
    document.querySelectorAll('.nav-item').forEach(function (b) {
      var p = per[b.getAttribute('data-nav')], badge = b.querySelector('.n-badge');
      badge.hidden = !p;
      if (p) {
        badge.className = 'n-badge ' + (p.error ? 'error' : 'warn');
        badge.textContent = p.error || p.warn;
        badge.title = p.error ? tr('{n} error(es)', { n: p.error }) : tr('{n} aviso(s)', { n: p.warn });
      }
    });
    var ul = $('issues');
    ul.innerHTML = '';
    document.querySelectorAll('.field.has-error').forEach(function (el) { el.classList.remove('has-error'); });
    if (!issues.length) ul.appendChild(h('li', { class: 'empty', text: tr('Sin problemas. Guarda y, en el juego, pulsa 0 para recargar.') }));
    issues.forEach(function (i) {
      var s = def().sections.filter(function (x) { return x.id === sectionOf(i.key); })[0];
      var b = h('button', { type: 'button' }, icon(i.level === 'error' ? 'error' : i.level === 'warn' ? 'warn' : 'info'),
        h('span', null, h('span', { text: i.msg }), s ? h('small', { text: tr(s.title) }) : null));
      b.addEventListener('click', function () { focusField(i.key); });
      ul.appendChild(h('li', { class: i.level }, b));
      if (i.level === 'error') {
        var el = document.querySelector('.field[data-key="' + (i.key === 'maxIVs' ? 'minIVs' : i.key) + '"]');
        if (el) el.classList.add('has-error');
      }
    });
    // target + preview
    var tf = $('target-file');
    tf.innerHTML = '';
    tf.appendChild(icon('folder'));
    tf.appendChild(h('span', { text: S.dir ? tr('Se guardará en la carpeta "{dir}" como {file}', { dir: S.dir.name, file: def().file })
      : tr('Se descargará como {file}. Ponlo junto a {script}.', { file: def().file, script: def().script }) }));
    $('preview-name').textContent = def().file;
    $('preview').innerHTML = highlight(core.serialize(S.bot, c, schema));
    saveDraft();
  }

  function focusField(key) {
    if (key === 'maxIVs') key = 'minIVs';
    var sid = sectionOf(key);
    if (sid && sid !== S.section[S.bot]) goSection(sid);
    var el = document.querySelector('.field[data-key="' + key + '"]');
    if (!el) return;
    el.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    el.classList.remove('flash'); void el.offsetWidth; el.classList.add('flash');
    var input = el.querySelector('input:not([type=hidden]):not([disabled]), select, button');
    if (input) setTimeout(function () { input.focus({ preventScroll: true }); }, 200);
  }

  function showSide(which) {
    var json = which === 'json';
    $('side-status').setAttribute('aria-selected', String(!json));
    $('side-json').setAttribute('aria-selected', String(json));
    $('panel-status').hidden = json;
    $('panel-json').hidden = !json;
  }

  // ---------------------------------------------------------------- files
  function loadText(text, name) {
    var p = core.parseConfig(text);
    if (!p.ok) { toast(p.error, 'error'); return false; }
    var bot = core.detectBot(p.value) || S.bot;
    S.cfg[bot] = core.normalize(bot, p.value, data);
    S.origin[bot] = name || 'archivo';
    S.bot = bot;
    renderTabs(); renderForm();
    var unknown = core.unknownKeys(bot, p.value, schema);
    toast(tr('Cargado {name} ({bot})', { name: name || 'JSON', bot: schema.bots[bot].name }) +
      (unknown.length ? tr(' · opciones desconocidas: {list}', { list: unknown.join(', ') }) : ''), unknown.length ? 'warn' : 'check');
    return true;
  }

  function openFile() { $('file-open').value = ''; $('file-open').click(); }
  $('file-open').addEventListener('change', function () {
    var f = this.files[0];
    if (!f) return;
    f.text().then(function (t) { loadText(t, f.name); });
  });

  function openFolder() {
    window.showDirectoryPicker({ id: 'poke-tools-bot', mode: 'readwrite' }).then(function (dir) {
      S.dir = dir;
      var tries = [['trainbot', 'FRLG_TrainBot'], ['shinybot', 'FRLG_ShinyBot']];
      var found = [];
      return Promise.all(tries.map(function (t) {
        return dir.getFileHandle(t[1] + '.lua').then(function () { found.push(t[0]); }, function () {});
      })).then(function () {
        if (found.length === 1) S.bot = found[0];
        return dir.getFileHandle(schema.bots[S.bot].file).then(function (fh) { return fh.getFile(); }).then(function (file) {
          return file.text().then(function (t) { loadText(t, dir.name + '/' + file.name); });
        }, function () {
          renderTabs(); renderForm();
          toast(found.length ? tr('Carpeta abierta: aún no tiene {file}; se creará al guardar', { file: schema.bots[S.bot].file })
            : tr('Carpeta abierta (no veo el .lua del bot aquí, revisa que sea la correcta)'), found.length ? 'folder' : 'warn');
        });
      });
    }).catch(function (e) { if (e && e.name !== 'AbortError') toast(tr('No pude abrir la carpeta: {msg}', { msg: e.message }), 'error'); });
  }

  function save() {
    var c = cfg(), d = def();
    var errs = core.validate(S.bot, c, data, schema).filter(function (i) { return i.level === 'error'; });
    if (errs.length && !confirm(tr('Hay {n} error(es): el bot no arrancará con este archivo. ¿Guardar igual?', { n: errs.length }))) return;
    var text = core.serialize(S.bot, c, schema);
    if (S.dir) {
      S.dir.getFileHandle(d.file, { create: true }).then(function (fh) { return fh.createWritable(); })
        .then(function (w) { return w.write(text).then(function () { return w.close(); }); })
        .then(function () { toast(tr('Guardado en {path}. En el juego pulsa 0 para recargarlo.', { path: S.dir.name + '/' + d.file })); })
        .catch(function (e) { toast(tr('No pude guardar: {msg}', { msg: e.message }), 'error'); });
      return;
    }
    if (window.showSaveFilePicker) {
      window.showSaveFilePicker({ suggestedName: d.file, types: [{ description: tr('Configuración del bot'), accept: { 'application/json': ['.json'] } }] })
        .then(function (fh) { return fh.createWritable(); })
        .then(function (w) { return w.write(text).then(function () { return w.close(); }); })
        .then(function () { toast(tr('Guardado {file}. Ponlo junto a {script}.', { file: d.file, script: d.script })); })
        .catch(function (e) { if (e && e.name !== 'AbortError') download(text, d.file); });
      return;
    }
    download(text, d.file);
  }

  function download(text, name) {
    var a = h('a', { href: URL.createObjectURL(new Blob([text], { type: 'application/json' })), download: name });
    document.body.appendChild(a); a.click(); a.remove();
    toast(tr('Descargado {name}. Muévelo a la carpeta del bot.', { name: name }), 'download');
  }

  // ---------------------------------------------------------------- skins
  function renderSkins() {
    var sel = $('skin-select');
    sel.innerHTML = '';
    skins.list().forEach(function (s) { sel.appendChild(h('option', { value: s.id, text: (s.builtin ? tr(s.name) : s.name + ' ★') })); });
    sel.value = S.skin;
    var ul = $('skin-list');
    ul.innerHTML = '';
    skins.list().forEach(function (s) {
      var row = h('button', { type: 'button' }, icon(s.id === S.skin ? 'check' : 'palette'),
        h('span', { text: (s.builtin ? tr(s.name) : s.name) + (s.author ? ' — ' + s.author : '') + (s.builtin ? '' : tr(' (importado)')) }));
      row.addEventListener('click', function () { applySkin(s.id); });
      var li = h('li', null, row);
      if (!s.builtin) {
        var del = h('button', { type: 'button', class: 'btn small', text: tr('Borrar') });
        del.addEventListener('click', function () { skins.remove(s.id); if (S.skin === s.id) applySkin('fuego'); else renderSkins(); });
        li.appendChild(del);
      }
      ul.appendChild(li);
    });
  }

  function applySkin(id) {
    var s = skins.apply(id);
    S.skin = s.id;
    store(SKIN, s.id);
    var m = $('mascot'); m.innerHTML = ''; m.appendChild(icon('mascot'));
    hydrateIcons(document);
    renderSkins(); renderTabs(); renderForm();
  }

  $('skin-select').addEventListener('change', function () { applySkin(this.value); });
  $('btn-skins').addEventListener('click', function () { openAppearance(false); });

  // ---------------------------------------------------------------- log stats
  // Reads a bot log (dropped, picked, or from the opened folder) and shows its numbers:
  // tiles, a line per measure that changes over time, items as bars, finds as a table.
  var STATS = { rep: null, name: '' };
  var BOT_NAMES = { shinybot: 'Shiny Bot', trainbot: 'Train Bot', farmbot: 'Farm Bot' };
  function openStats() {
    $('btn-stats-dir').hidden = !S.dir;
    $('stats-dialog').showModal();
  }
  function readLogFromDir() {
    var c = cfg(), dir = (c.logDir || fieldDef('logDir').def || '').replace(/[\/\\]+$/, ''), file = c.logFile || fieldDef('logFile').def;
    var where = dir ? S.dir.getDirectoryHandle(dir) : Promise.resolve(S.dir);
    where.then(function (d) { return d.getFileHandle(file); }).then(function (fh) { return fh.getFile(); })
      .then(function (f) { return f.text(); })
      .then(function (t) { showLog(file, t); },
        function () { toast(tr('No encuentro {path} en "{dir}": ¿ya corriste el bot?', { path: (dir ? dir + '/' : '') + file, dir: S.dir.name }), 'warn'); });
  }
  function readLogFile(f) {
    if (!f) return;
    if (f.size > 20000000) { toast(tr('Ese archivo es demasiado grande para un log'), 'warn'); return; }
    f.text().then(function (t) { showLog(f.name, t); });
  }
  function fmtDur(ms) {
    var m = Math.round(ms / 60000);
    return m < 60 ? m + ' min' : Math.floor(m / 60) + ' h ' + (m % 60) + ' min';
  }
  function fmtTime(t) { var d = new Date(t); return ('0' + d.getHours()).slice(-2) + ':' + ('0' + d.getMinutes()).slice(-2); }
  function fmtDate(t) { var d = new Date(t); return d.getDate() + '/' + (d.getMonth() + 1) + ' ' + fmtTime(t); }
  function fmtNum(n) { return Math.round(n).toLocaleString(i18n.lang()); }
  function perHour(n, ms) { return ms >= 600000 ? ' · ' + fmtNum(n * 3600000 / ms) + '/h' : ''; }
  function tile(label, value, sub) {
    return h('div', { class: 'stat-tile' }, h('span', { class: 'help', text: label }), h('b', { text: value }), sub ? h('span', { class: 'help', text: sub }) : null);
  }
  // One measure over time: 2px line, markers with a hover title, recessive grid.
  function lineChart(title, pts, fmt) {
    var W = 640, H = 190, L = 56, R = 14, T = 14, B = 28;
    var t0 = pts[0].t, t1 = pts[pts.length - 1].t, v0 = Math.min.apply(null, pts.map(function (p) { return p.v; }));
    var v1 = Math.max.apply(null, pts.map(function (p) { return p.v; }));
    if (v1 === v0) v1 = v0 + 1;
    var X = function (t) { return L + (t1 === t0 ? (W - L - R) / 2 : (t - t0) / (t1 - t0) * (W - L - R)); };
    var Y = function (v) { return T + (1 - (v - v0) / (v1 - v0)) * (H - T - B); };
    var svg = svgEl('svg', { viewBox: '0 0 ' + W + ' ' + H, class: 'chart', role: 'img', 'aria-label': title });
    [v0, (v0 + v1) / 2, v1].forEach(function (v) {
      svg.appendChild(svgEl('line', { x1: L, x2: W - R, y1: Y(v), y2: Y(v), class: 'grid' }));
      svg.appendChild(svgEl('text', { x: L - 8, y: Y(v) + 4, 'text-anchor': 'end', class: 'tick' })).textContent = fmt(v);
    });
    svg.appendChild(svgEl('text', { x: L, y: H - 8, class: 'tick' })).textContent = fmtTime(t0);
    svg.appendChild(svgEl('text', { x: W - R, y: H - 8, 'text-anchor': 'end', class: 'tick' })).textContent = fmtTime(t1);
    svg.appendChild(svgEl('polyline', { points: pts.map(function (p) { return X(p.t) + ',' + Y(p.v); }).join(' '), class: 'series' }));
    var few = pts.length <= 60;
    pts.forEach(function (p) {
      var g = svgEl('g', { class: 'pt' });
      if (few) g.appendChild(svgEl('circle', { cx: X(p.t), cy: Y(p.v), r: 4, class: 'mark' }));
      g.appendChild(svgEl('circle', { cx: X(p.t), cy: Y(p.v), r: 11, class: 'hit' }));
      g.appendChild(svgEl('title', {})).textContent = fmtTime(p.t) + ' · ' + fmt(p.v);
      svg.appendChild(g);
    });
    return h('figure', { class: 'stat-chart' }, h('figcaption', { text: title }), svg);
  }
  function barList(title, counts) {
    var rows = Object.keys(counts).map(function (k) { return [k, counts[k]]; }).sort(function (a, b) { return b[1] - a[1]; });
    var max = rows.length ? rows[0][1] : 1;
    return h('figure', { class: 'stat-chart' }, h('figcaption', { text: title }),
      h('div', { class: 'bars' }, rows.map(function (r) {
        return h('div', { class: 'bar-row', title: r[0] + ': ' + r[1] },
          h('span', { class: 'bar-label', text: r[0] }),
          h('span', { class: 'bar-track' }, h('span', { class: 'bar', style: 'width:' + Math.max(2, r[1] / max * 100) + '%' })),
          h('span', { class: 'bar-value', text: String(r[1]) }));
      })));
  }
  function showLog(name, text) {
    var rep = core.logReport(text);
    STATS.rep = rep; STATS.name = name;
    var sel = $('stats-session');
    sel.hidden = !rep.sessions || rep.sessions.length < 2;
    sel.innerHTML = '';
    (rep.sessions || []).forEach(function (s, i) {
      sel.appendChild(h('option', { value: String(i), text: fmtDate(s.start) + (s.mode ? ' · ' + s.mode : '') + (s.species ? ' · ' + s.species : '') }));
    });
    if (rep.sessions) sel.value = String(rep.sessions.length - 1);
    renderStats();
    if (!$('stats-dialog').open) openStats();
  }
  function renderStats() {
    var rep = STATS.rep, out = $('stats-out');
    out.innerHTML = '';
    $('stats-title').textContent = tr('Estadísticas') + (rep && rep.bot ? ': ' + BOT_NAMES[rep.bot] + ' (' + STATS.name + ')' : '');
    if (!rep) return;
    if (!rep.bot) {
      out.appendChild(h('p', { class: 'help', text: tr('No reconozco "{name}": elige un log de los bots (shiny_log.txt, train_log.txt o farm_log.txt).', { name: STATS.name }) }));
      return;
    }
    if (rep.bot === 'shinybot') {
      out.appendChild(h('div', { class: 'stat-tiles' },
        tile(tr('Encontrados'), fmtNum(rep.finds.length)), tile(tr('Shinies'), fmtNum(rep.shinies)),
        tile(tr('Intentos de media'), rep.finds.length ? fmtNum(rep.avgTries) : '–'), tile(tr('Shinies descartados'), fmtNum(rep.discarded), tr('no cumplían tus filtros')),
        rep.sids ? tile(tr('TID/SID conseguidos'), fmtNum(rep.sids)) : null, rep.seeds ? tile(tr('Semillas conseguidas'), fmtNum(rep.seeds)) : null));
      if (!rep.finds.length) { out.appendChild(h('p', { class: 'help', text: tr('Este log aún no tiene hallazgos.') })); return; }
      var head = h('tr', null, [tr('Fecha'), tr('Pokémon'), tr('Tipo'), tr('Naturaleza'), tr('IVs'), tr('Intentos'), tr('Modo')].map(function (c) { return h('th', { text: c }); }));
      var rows = rep.finds.slice().reverse().map(function (f) {
        return h('tr', null, [fmtDate(f.t), f.species, f.kind === 'OBJETIVO' ? tr('Objetivo') : f.kind.replace('SHINY', 'Shiny'), f.nature, f.ivs, fmtNum(f.tries), f.mode]
          .map(function (c) { return h('td', { text: c }); }));
      });
      out.appendChild(h('div', { class: 'stat-table' }, h('table', null, h('thead', null, head), h('tbody', null, rows))));
      return;
    }
    var s = rep.sessions[+$('stats-session').value || 0] || rep.sessions[rep.sessions.length - 1], dur = s.end - s.start;
    if (rep.bot === 'farmbot') {
      var lv = s.levels.length ? s.levels[s.levels.length - 1].v - s.levels[0].v : 0;
      out.appendChild(h('div', { class: 'stat-tiles' },
        tile(tr('Duración'), fmtDur(dur), fmtDate(s.start) + (s.mode ? tr(' · modo {mode}', { mode: s.mode }) : '')),
        s.earned || s.mode === 'dinero' ? tile(tr('Dinero ganado'), '$' + fmtNum(s.earned), perHour(s.earned, dur).replace(' · ', '')) : null,
        s.found || s.mode === 'objetos' || s.mode === 'robar' ? tile(tr('Objetos'), fmtNum(s.found), (s.stored ? tr('{n} guardados', { n: s.stored }) : '') + perHour(s.found, dur)) : null,
        tile(tr('Niveles'), '+' + lv, s.species ? s.species + (s.levels.length ? ' ' + tr('Nv.') + s.levels[s.levels.length - 1].v : '') : ''),
        tile(tr('Curas'), fmtNum(s.heals)), s.laps ? tile(tr('Vueltas'), fmtNum(s.laps)) : null));
      if (s.done) out.appendChild(h('p', { class: 'stat-done' }, icon('check'), h('span', { text: s.done })));
      var charts = h('div', { class: 'stat-charts' });
      if (s.money.length > 1) charts.appendChild(lineChart(tr('Dinero'), s.money, function (v) { return '$' + fmtNum(v); }));
      if (s.levels.length > 1) charts.appendChild(lineChart(tr('Nivel del primero del equipo'), s.levels, function (v) { return tr('Nv.') + Math.round(v); }));
      if (Object.keys(s.items).length) charts.appendChild(barList(tr('Objetos conseguidos'), s.items));
      if (charts.children.length) out.appendChild(charts);
      else out.appendChild(h('p', { class: 'help', text: tr('En esta sesión no hubo cambios de dinero, nivel ni objetos todavía.') }));
    } else {
      out.appendChild(h('div', { class: 'stat-tiles' },
        tile(tr('Duración'), fmtDur(dur), fmtDate(s.start)), tile(tr('Pokémon'), s.species || '?', s.level ? tr('empezó en Nv.{n}', { n: s.level }) : ''),
        tile(tr('Viajes al Centro'), fmtNum(s.heals)), tile(tr('Evoluciones'), fmtNum(s.evolutions)), tile(tr('Ataques aprendidos'), fmtNum(s.learned))));
      if (s.events.length) {
        out.appendChild(h('ul', { class: 'stat-events' }, s.events.map(function (e) {
          return h('li', null, h('span', { class: 'help', text: fmtTime(e.t) }), h('span', { text: e.msg }));
        })));
      }
    }
    hydrateIcons(out);
  }
  $('btn-stats').addEventListener('click', openStats);
  $('btn-stats-file').addEventListener('click', function () { $('stats-file').value = ''; $('stats-file').click(); });
  $('stats-file').addEventListener('change', function () { readLogFile(this.files[0]); });
  $('btn-stats-dir').addEventListener('click', readLogFromDir);
  $('stats-session').addEventListener('change', renderStats);
  $('stats-drop').addEventListener('dragover', function (e) { e.preventDefault(); this.classList.add('over'); });
  $('stats-drop').addEventListener('dragleave', function () { this.classList.remove('over'); });
  $('stats-drop').addEventListener('drop', function (e) {
    e.preventDefault(); this.classList.remove('over');
    readLogFile(e.dataTransfer.files[0]);
  });
  PT.showLog = showLog;   // also used by the UI smoke test

  // ---------------------------------------------------------------- route viewer
  // Shows a route file: one grid per map, the way there and back, and what to fix.
  // Ready-made routes come from data.js; the player's own file is read from the opened
  // folder, or picked by hand.
  function viewRoute(f) {
    var name = cfg()[f.key] || f.def;
    if (data.routeText && data.routeText[name]) return showRoute(name, data.routeText[name]);
    if (S.dir) {
      S.dir.getFileHandle(name).then(function (fh) { return fh.getFile(); }).then(function (file) { return file.text(); })
        .then(function (t) { showRoute(name, t); }, function () {
          toast(tr('No encuentro {name} en la carpeta "{dir}": elígelo a mano', { name: name, dir: S.dir.name }), 'warn');
          $('route-file').value = ''; $('route-file').click();
        });
      return;
    }
    $('route-file').value = ''; $('route-file').click();
  }
  $('route-file').addEventListener('change', function () {
    var f = this.files[0];
    if (!f) return;
    if (f.size > 500000) { toast(tr('Ese archivo es demasiado grande para ser una ruta'), 'warn'); return; }
    f.text().then(function (t) { showRoute(f.name, t); });
  });
  $('btn-route-file').addEventListener('click', function () { $('route-file').value = ''; $('route-file').click(); });

  var SVGNS = 'http://www.w3.org/2000/svg';
  function svgEl(tag, attrs) {
    var el = document.createElementNS(SVGNS, tag);
    Object.keys(attrs).forEach(function (k) { el.setAttribute(k, attrs[k]); });
    return el;
  }
  function routeMap(m, rep) {
    var all = [].concat.apply([], m.go.concat(m.back));
    var xs = all.map(function (p) { return p.x; }), ys = all.map(function (p) { return p.y; });
    var x0 = Math.min.apply(null, xs) - 1, y0 = Math.min.apply(null, ys) - 1;
    var w = Math.max.apply(null, xs) - x0 + 2, hh = Math.max.apply(null, ys) - y0 + 2;
    var svg = svgEl('svg', { viewBox: (x0 - 0.5) + ' ' + (y0 - 0.5) + ' ' + w + ' ' + hh, width: w * 14, height: hh * 14,
      role: 'img', 'aria-label': tr('Mapa {id}', { id: m.g + '.' + m.n }) });
    var grid = '';
    for (var x = x0; x <= x0 + w; x++) grid += 'M' + (x - 0.5) + ' ' + (y0 - 0.5) + 'v' + hh;
    for (var y = y0; y <= y0 + hh; y++) grid += 'M' + (x0 - 0.5) + ' ' + (y - 0.5) + 'h' + w;
    svg.appendChild(svgEl('path', { d: grid, class: 'grid' }));
    function line(points, cls) {
      if (points.length === 1) { svg.appendChild(svgEl('circle', { cx: points[0].x, cy: points[0].y, r: 0.22, class: 'pt ' + cls })); return; }
      svg.appendChild(svgEl('polyline', { points: points.map(function (p) { return p.x + ',' + p.y; }).join(' '), class: cls }));
    }
    m.back.forEach(function (r) { line(r, 'back'); });
    m.go.forEach(function (r) { line(r, 'go'); });
    [[rep.heal, 'heal', tr('Fin de la ida')], [rep.spot, 'spot', tr('Punto de entreno')]].forEach(function (k) {
      var p = k[0];
      if (p && p.g === m.g && p.n === m.n) {
        var c = svgEl('circle', { cx: p.x, cy: p.y, r: 0.42, class: 'mark ' + k[1] });
        c.appendChild(svgEl('title', {})).textContent = k[2] + ' (' + (p.x - 7) + ', ' + (p.y - 7) + ')';
        svg.appendChild(c);
      }
    });
    var steps = function (runs) { return runs.reduce(function (n, r) { return n + r.length; }, 0); };
    return h('figure', { class: 'route-map' },
      h('figcaption', null, h('b', { text: tr('Mapa {id}', { id: m.g + '.' + m.n }) }),
        h('span', { class: 'help', text: (m.go.length ? tr('ida {n}', { n: steps(m.go) }) : '') + (m.go.length && m.back.length ? ' · ' : '') +
          (m.back.length ? tr('vuelta {n}', { n: steps(m.back) }) : '') })),
      h('div', { class: 'route-svg' }, svg));
  }
  function showRoute(name, text) {
    var rep = core.routeReport(text);
    $('route-title').textContent = tr('Ruta: {name}', { name: name });
    $('route-summary').textContent = rep.go.length || rep.back.length
      ? tr(rep.maps.length === 1 ? 'Ida {go} pasos, vuelta {back}, {maps} mapa.' : 'Ida {go} pasos, vuelta {back}, {maps} mapas.', { go: rep.go.length, back: rep.back.length, maps: rep.maps.length }) +
        ' ' + tr('Coordenadas de memoria (casilla + 7); pasa el cursor por los puntos para ver la casilla.')
      : '';
    var ul = $('route-issues');
    ul.innerHTML = '';
    if (!rep.issues.length) ul.appendChild(h('li', { class: 'ok' }, icon('check'), h('span', { text: tr('Sin problemas: el bot puede seguir esta ruta.') })));
    rep.issues.forEach(function (i) {
      ul.appendChild(h('li', { class: i.level }, icon(i.level === 'error' ? 'error' : i.level === 'warn' ? 'warn' : 'info'), h('span', { text: i.msg })));
    });
    var box = $('route-maps');
    box.innerHTML = '';
    rep.maps.forEach(function (m) { box.appendChild(routeMap(m, rep)); });
    hydrateIcons($('route-dialog'));
    if (!$('route-dialog').open) $('route-dialog').showModal();
  }

  // ---------------------------------------------------------------- background
  function openAppearance(toBackground) {
    renderSkins(); renderBg();
    $('skins-dialog').showModal();
    if (toBackground) { $('bg-section').scrollIntoView({ block: 'start' }); $('bg-species').focus(); }
  }
  function renderBg() {
    $('bg-bot').textContent = schema.bots[S.bot].name;
    var mine = bgPrefs()[S.bot] || {}, src = bgSource(S.bot), pv = $('bg-preview');
    $('bg-species').value = mine.species || '';
    var sk = skins.get(S.skin) || {};
    $('bg-species').placeholder = mine.image ? tr('Imagen propia') : mine.none ? tr('Sin fondo')
      : (sk.backdrop && data.species.indexOf(sk.backdrop) !== -1 ? sk.backdrop : data.species[PT.art.backdrops[S.bot] - 1]);
    pv.innerHTML = '';
    if (src) pv.appendChild(bgImage(src));
    $('bg-style').value = bgPrefs().style || 'frlg';
    $('bg-shiny').checked = !!bgPrefs().shiny;
    var o = bgOpacity(), cur = o === null ? parseFloat(getComputedStyle(document.documentElement).getPropertyValue('--backdrop-opacity')) || 0.14 : o;
    $('bg-opacity').value = Math.round(cur * 100);
    $('bg-opacity-val').textContent = Math.round(cur * 100) + '%';
  }
  function setBg(choice) {
    var p = bgPrefs();
    if (choice) p[S.bot] = choice; else delete p[S.bot];
    if (!bgSave(p)) toast(tr('El navegador no deja guardar el fondo: solo durará esta sesión'), 'warn');
    renderBg(); renderSection();
  }
  if (data.species) $('bg-species-list').innerHTML = data.species.map(function (n) { return '<option value="' + n + '">'; }).join('');
  $('bg-species').addEventListener('keydown', function (e) { if (e.key === 'Enter') { e.preventDefault(); this.blur(); } });
  $('bg-species').addEventListener('change', function () {
    var name = this.value.trim(), hit = data.species.filter(function (n) { return n.toLowerCase() === name.toLowerCase(); })[0];
    if (!name) return;
    if (!hit) { toast(tr('No conozco ese Pokémon: elige uno de la lista (Gen 1–3)'), 'warn'); this.value = ''; return; }
    setBg({ species: hit });
  });
  function setBgOption(key, value) {
    var p = bgPrefs();
    p[key] = value;
    bgSave(p);
    renderBg(); renderSection();
  }
  $('bg-style').addEventListener('change', function () { setBgOption('style', this.value); });
  $('bg-shiny').addEventListener('change', function () { setBgOption('shiny', this.checked); });
  $('btn-bg-none').addEventListener('click', function () { setBg({ none: true }); });
  $('btn-bg-reset').addEventListener('click', function () { setBg(null); });
  $('btn-bg-upload').addEventListener('click', function () { $('bg-file').value = ''; $('bg-file').click(); });
  $('bg-file').addEventListener('change', function () {
    var f = this.files[0];
    if (!f) return;
    if (!/^image\/(png|jpeg|webp|gif)$/.test(f.type)) { toast(tr('Usa una imagen PNG, JPG, WebP o GIF'), 'warn'); return; }
    if (f.size > 1500000) { toast(tr('La imagen pesa más de 1,5 MB: usa una más pequeña'), 'warn'); return; }
    var r = new FileReader();
    r.onload = function () { setBg({ image: String(r.result) }); };
    r.readAsDataURL(f);
  });
  $('bg-opacity').addEventListener('input', function () {
    var p = bgPrefs();
    p.opacity = Number(this.value) / 100;
    bgSave(p);
    $('bg-opacity-val').textContent = this.value + '%';
    var bd = document.querySelector('.panel > .backdrop');
    if (bd) bd.style.opacity = p.opacity;
  });
  $('btn-skin-import').addEventListener('click', function () { $('skin-file').value = ''; $('skin-file').click(); });
  $('skin-file').addEventListener('change', function () {
    var f = this.files[0];
    if (!f) return;
    f.text().then(function (t) {
      try {
        var s = skins.register(JSON.parse(t), { custom: true });
        if (!skins.saveCustom()) toast(tr('Skin cargado solo para esta sesión (el navegador no deja guardarlo)'), 'warn');
        applySkin(s.id);
        toast(tr('Skin "{name}" importado', { name: s.name }));
      } catch (e) { toast(tr('Skin no válido: {msg}', { msg: tr(e.message) }), 'error'); }
    });
  });
  $('btn-skin-export').addEventListener('click', function () {
    var a = h('a', { href: URL.createObjectURL(new Blob([skins.exportable(S.skin)], { type: 'application/json' })), download: 'skin-' + S.skin + '.json' });
    document.body.appendChild(a); a.click(); a.remove();
    toast(tr('Skin exportado: edítalo y vuelve a importarlo'), 'download');
  });

  // ---------------------------------------------------------------- language
  // Static text in index.html carries data-i18n (text), data-i18n-html (trusted markup from
  // our own dictionaries) or data-i18n-attr="title,aria-label,…"; the Spanish original is kept
  // so the page can switch language any number of times.
  function translateStatic() {
    document.querySelectorAll('[data-i18n]').forEach(function (el) {
      if (el.dataset.src === undefined) el.dataset.src = el.textContent.trim();
      el.textContent = tr(el.dataset.src);
    });
    document.querySelectorAll('[data-i18n-html]').forEach(function (el) {
      if (el.dataset.src === undefined) el.dataset.src = el.innerHTML.trim();
      el.innerHTML = tr(el.dataset.src);
    });
    document.querySelectorAll('[data-i18n-attr]').forEach(function (el) {
      el.getAttribute('data-i18n-attr').split(',').forEach(function (a) {
        var key = 'src' + a.replace(/(^|-)(\w)/g, function (m, d, c) { return c.toUpperCase(); });
        if (el.dataset[key] === undefined) el.dataset[key] = el.getAttribute(a) || '';
        el.setAttribute(a, tr(el.dataset[key]));
      });
    });
    document.documentElement.lang = i18n.lang();
    document.title = tr('Poke-tools · Configurador');
  }
  function setLang(l, remember) {
    i18n.set(l);
    if (remember) store(LANG, i18n.lang());
    $('lang-select').value = i18n.lang();
    translateStatic();
    renderSkins(); renderTabs(); renderForm();
    if ($('skins-dialog').open) renderBg();
    if ($('stats-dialog').open) renderStats();
  }
  Object.keys(i18n.NAMES).forEach(function (l) { $('lang-select').appendChild(h('option', { value: l, text: i18n.NAMES[l] })); });
  $('lang-select').addEventListener('change', function () { setLang(this.value, true); });

  // ---------------------------------------------------------------- wiring
  ['shinybot', 'trainbot', 'farmbot'].forEach(function (b) {
    $('tab-' + b).addEventListener('click', function () {
      S.bot = b; renderTabs(); renderForm();
      try { history.replaceState(null, '', '#' + b); } catch (e) { /* file:// may refuse */ }
    });
  });
  $('side-status').addEventListener('click', function () { showSide('status'); });
  $('side-json').addEventListener('click', function () { showSide('json'); });
  $('btn-open').addEventListener('click', openFile);
  $('btn-save').addEventListener('click', save);
  if (window.showDirectoryPicker) { $('btn-folder').hidden = false; $('btn-folder').addEventListener('click', openFolder); }
  $('btn-copy').addEventListener('click', function () {
    var text = core.serialize(S.bot, cfg(), schema);
    (navigator.clipboard ? navigator.clipboard.writeText(text) : Promise.reject())
      .then(function () { toast(tr('JSON copiado')); }, function () {
        var r = document.createRange(); r.selectNodeContents($('preview'));
        var sel = getSelection(); sel.removeAllRanges(); sel.addRange(r);
        toast(tr('Selecciónalo y cópialo con Ctrl+C'), 'info');
      });
  });
  document.addEventListener('keydown', function (e) {
    if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 's') { e.preventDefault(); save(); }
  });
  document.addEventListener('dragover', function (e) { e.preventDefault(); });
  document.addEventListener('drop', function (e) {
    e.preventDefault();
    var f = e.dataTransfer.files[0];
    if (f && /\.json$/i.test(f.name)) f.text().then(function (t) { loadText(t, f.name); });
  });

  // ---------------------------------------------------------------- boot
  lk = { natures: {}, species: {}, moves: {}, items: {} };
  data.natures.forEach(function (n) { lk.natures[core.simplify(n)] = n; });
  Object.keys(data.naturesEs).forEach(function (en) { lk.natures[core.simplify(data.naturesEs[en])] = en; });
  data.species.forEach(function (n) { lk.species[core.simplify(n)] = n; });
  data.moves.forEach(function (n) { lk.moves[core.simplify(n)] = n; });
  data.items.forEach(function (n) { lk.items[core.simplify(n)] = n; });

  skins.loadCustom();
  loadDraft();
  // Deep links: #shinybot / #trainbot pick the bot, ?skin=<id> picks the skin.
  if (/^#(shinybot|trainbot|farmbot)$/.test(location.hash)) S.bot = location.hash.slice(1);
  var qs = /[?&]skin=([a-z0-9-]+)/.exec(location.search);
  var saved = qs ? qs[1] : store(SKIN);
  // Language: ?lang=, then the saved choice, then the browser's language (Spanish fallback).
  var ql = /[?&]lang=([a-z]{2})/.exec(location.search), nav = (navigator.language || 'es').slice(0, 2);
  i18n.set(ql ? ql[1] : store(LANG) || (i18n.NAMES[nav] ? nav : 'es'));
  $('lang-select').value = i18n.lang();
  translateStatic();
  applySkin(saved && skins.get(saved) ? saved : 'fuego');
})();
