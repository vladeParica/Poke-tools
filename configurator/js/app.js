// Configurator UI. Renders the schema as forms, keeps one config per bot, validates on
// every change and saves the commented JSON next to the bot (File System Access API in
// Edge/Chrome; download elsewhere). All player-facing text is Spanish.
(function () {
  'use strict';

  var PT = window.PT, schema = PT.schema, core = PT.core, data = PT.data, skins = PT.skins;
  var DRAFT = 'pt-configurator-draft-v1', SKIN = 'pt-configurator-skin', BG = 'pt-configurator-backdrop';
  var lk = null;

  var S = {
    bot: 'shinybot',
    cfg: { shinybot: null, trainbot: null, farmbot: null },
    origin: { shinybot: '', trainbot: '', farmbot: '' },
    dir: null,
    section: { shinybot: 'mode', trainbot: 'goal', farmbot: 'mode' },
    skin: 'pokeball'
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
  // Prefs: { opacity: 0..0.4, <bot>: { species } | { image: dataURL } | { none: true } }
  function bgPrefs() { try { return JSON.parse(store(BG) || '{}') || {}; } catch (e) { return {}; } }
  function bgSave(p) {
    try { localStorage.setItem(BG, JSON.stringify(p)); return true; } catch (e) { return false; }
  }
  function speciesArt(name) {
    var i = data.species.indexOf(name);
    return i < 0 ? null : PT.art.artwork(i + 1);
  }
  function bgSource(bot) {
    var mine = bgPrefs()[bot], sk = skins.get(S.skin) || {}, over = (sk.sprites || {})['backdrop-' + bot];
    if (mine && mine.none) return null;
    if (mine && mine.image) return { src: mine.image };
    if (mine && mine.species && speciesArt(mine.species)) return { src: speciesArt(mine.species) };
    if (over) return { skin: true };
    return { src: PT.art.artwork(PT.art.backdrops[bot]) };
  }
  function backdrop() {
    var src = bgSource(S.bot);
    if (!src) return null;
    if (src.skin) return icon('backdrop-' + S.bot);
    var img = h('img', { src: src.src, alt: '', decoding: 'async', referrerpolicy: 'no-referrer' });
    img.addEventListener('error', function () { img.remove(); });
    return img;
  }
  function bgOpacity() { var o = bgPrefs().opacity; return typeof o === 'number' ? o : null; }
  function store(key, val) { try { if (val === undefined) return localStorage.getItem(key); localStorage.setItem(key, val); } catch (e) { return null; } }
  function cfg() { return S.cfg[S.bot]; }
  function def() { return schema.bots[S.bot]; }
  function fieldDef(key) { return schema.fields(S.bot).filter(function (f) { return f.key === key; })[0]; }
  function natLabel(n) { return n + ' · ' + (schema.NATURES_ES_DISPLAY[n] || ''); }
  function typeLabel(t) { return (schema.TYPES_ES_DISPLAY[t] || t) + ' (' + t + ')'; }
  function modeLabel(m) { var x = schema.MODES.filter(function (o) { return o.value === m; })[0]; return x ? x.label : m; }

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
    return h('label', { class: 'switch', for: 'f-' + f.key }, input, h('span', { class: 'track' }), h('span', { text: f.label }));
  }

  function intCtl(f) {
    var v = cfg()[f.key];
    var num = h('input', { type: 'number', id: 'f-' + f.key, min: f.min, max: f.max, step: 1, inputmode: 'numeric',
      placeholder: f.nullable ? 'vacío' : String(f.def) });
    if (v !== undefined && v !== null) num.value = v;
    else if (!f.nullable && f.def !== null) num.value = f.def;
    function commit() {
      if (num.value === '') { setVal(f.key, f.nullable ? null : f.def); return; }
      setVal(f.key, Math.round(Number(num.value)));
    }
    num.addEventListener('input', commit);
    if (!f.slider) return h('div', { class: 'row' }, num, f.unit ? h('span', { class: 'unit', text: f.unit }) : null);
    var range = h('input', { type: 'range', min: f.min, max: f.max, step: 1, 'aria-label': f.label });
    range.value = num.value || f.def;
    range.addEventListener('input', function () { num.value = range.value; commit(); });
    num.addEventListener('input', function () { range.value = num.value; });
    return h('div', { class: 'slider-row' }, range, h('div', { class: 'row' }, num, f.unit ? h('span', { class: 'unit', text: f.unit }) : null));
  }

  function textCtl(f) {
    var v = cfg()[f.key];
    var inp = h('input', { type: 'text', id: 'f-' + f.key, placeholder: f.nullable ? 'vacío = por defecto' : String(f.def), spellcheck: 'false' });
    inp.value = v === undefined || v === null ? (f.nullable ? '' : f.def) : v;
    inp.addEventListener('input', function () { setVal(f.key, inp.value.trim() === '' ? (f.nullable ? null : f.def) : inp.value.trim()); });
    return inp;
  }

  function enumCtl(f) {
    var opts = f.options.map(function (o) { return typeof o === 'string' ? { value: o, label: modeLabel(o) } : o; });
    var cur = cfg()[f.key] === undefined ? f.def : cfg()[f.key];
    if (f.segmented) {
      var wrap = h('div', { class: 'segmented', role: 'group', 'aria-label': f.label });
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
    if (f.nullable) sel.appendChild(h('option', { value: '', text: '— ninguno —' }));
    opts.forEach(function (o) { sel.appendChild(h('option', { value: o.value, text: o.label })); });
    sel.value = cur === null || cur === undefined ? '' : cur;
    sel.addEventListener('change', function () { setVal(f.key, sel.value || null); });
    return sel;
  }

  function modeCtl(f) {
    var grid = h('div', { class: 'modes', role: 'radiogroup', 'aria-label': f.label });
    var cur = cfg().mode === undefined || cfg().mode === null ? f.def : cfg().mode;
    (f.cards || schema.MODES).forEach(function (m) {
      var b = h('button', { type: 'button', class: 'mode', role: 'radio', 'aria-checked': String(cur === m.value) },
        h('span', { class: 'm-head' }, icon(m.icon), h('span', { text: m.label })),
        h('span', { class: 'm-desc', text: m.desc }),
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
      if (y[s.key]) out.appendChild(h('span', { class: 'badge' + (t[s.key] ? ' hit' : ''), title: s.label, text: '+' + y[s.key] + ' ' + s.short }));
    });
    return out;
  }

  // Chip list editor for natures, species, moves and hex values.
  function chipsCtl(f) {
    var kind = f.type, table, options;
    if (kind === 'natures') { table = lk.natures; options = data.natures.map(function (n) { return { value: n, label: schema.NATURES_ES_DISPLAY[n] }; }); }
    if (kind === 'species') { table = lk.species; options = data.species.map(function (n) { return { value: n }; }); }
    if (kind === 'moves') { table = lk.moves; options = data.moves.map(function (n) { return { value: n }; }); }
    if (kind === 'items') { table = lk.items; options = data.items.map(function (n) { return { value: n }; }); }
    var box = h('div', { class: 'chips' });
    var dl = options ? datalist(options) : null;
    var basePh = kind === 'hexlist' ? 'Ej. BC75 (Enter para añadir)' : kind === 'natures' ? 'Escribe una naturaleza…' : kind === 'moves' ? 'Escribe un ataque en inglés…' : kind === 'items' ? 'Escribe un objeto en inglés…' : 'Escribe una especie…';
    var input = h('input', { type: 'text', id: 'f-' + f.key, list: dl ? dl.id : null, spellcheck: 'false', autocomplete: 'off', placeholder: basePh });
    var addBtn = h('button', { type: 'button', class: 'btn icon', title: 'Añadir', 'aria-label': 'Añadir' }, icon('plus'));
    var msg = h('p', { class: 'help', hidden: true });

    function list() { return (cfg()[f.key] || []).slice(); }
    function draw() {
      box.innerHTML = '';
      var l = list();
      l.forEach(function (item, i) {
        var ok = kind === 'hexlist' ? /^[0-9A-F]{1,4}$/.test(item) : !!table[core.simplify(item)];
        var label = kind === 'natures' && ok ? natLabel(table[core.simplify(item)]) : item;
        var rm = h('button', { type: 'button', title: 'Quitar', 'aria-label': 'Quitar ' + item }, icon('x'));
        rm.addEventListener('click', function () { var n = list(); n.splice(i, 1); setVal(f.key, n); draw(); });
        box.appendChild(h('span', { class: 'chip' + (ok ? '' : ' bad') }, h('span', { text: label }),
          f.showYield && ok ? yieldBadges(table[core.simplify(item)]) : null, rm));
      });
      var full = f.max && l.length >= f.max;
      input.disabled = full; addBtn.disabled = full;
      input.placeholder = full ? 'Máximo ' + f.max : basePh;
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
      msg.textContent = bad.length ? 'No reconozco: ' + bad.join(', ') : '';
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
      var mn = h('input', { type: 'number', min: 0, max: 31, placeholder: '0', 'aria-label': 'IV mínimo ' + s.label });
      var mx = h('input', { type: 'number', min: 0, max: 31, placeholder: '31', 'aria-label': 'IV máximo ' + s.label });
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
      grid.appendChild(h('div', { class: 'statrow' }, icon(s.icon), h('span', { class: 'sname', text: s.label }),
        h('span', { class: 'iv-pair' }, mn, h('span', { text: 'a' }), mx),
        h('span', { class: 'quick' }, quick('31', 31, '', 'Mínimo 31'), quick('0', '', 0, 'Máximo 0 (ej. Ataque en especiales)'), quick('Libre', '', '', 'Sin filtro'))));
    });
    return grid;
  }

  function evCtl(f) {
    var wrap = h('div', { class: 'statgrid' });
    var total = h('div', { class: 'total' }, h('div', { class: 'tline' }, h('span', { text: 'Total' }), h('span', { class: 'tval' })),
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
      var range = h('input', { type: 'range', min: 0, max: 255, step: 1, 'aria-label': 'EVs de ' + s.label });
      var num = h('input', { type: 'number', min: 0, max: 255, step: 1, 'aria-label': 'EVs de ' + s.label });
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
      wrap.appendChild(h('div', { class: 'statrow' }, icon(s.icon), h('span', { class: 'sname', text: s.label }),
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
    var sel = h('select', { 'aria-label': 'Tipo de Poder Oculto' }, h('option', { value: '', text: '— sin filtro —' }));
    data.hpTypes.forEach(function (t) { sel.appendChild(h('option', { value: t, text: typeLabel(t) })); });
    sel.value = cur.type || '';
    var pow = h('input', { type: 'number', min: 30, max: 70, placeholder: '30–70', 'aria-label': 'Potencia mínima' });
    if (cur.minPower) pow.value = cur.minPower;
    function commit() {
      var o = {};
      if (sel.value) o.type = sel.value;
      if (pow.value !== '') o.minPower = Math.round(Number(pow.value));
      setVal('hiddenPower', o);
    }
    sel.addEventListener('change', commit); pow.addEventListener('input', commit);
    return h('div', { class: 'row' }, h('div', { style: 'flex:1 1 200px' }, sel), pow, h('span', { class: 'unit', text: 'potencia mínima' }));
  }

  function notifyCtl() {
    var cur = cfg().notify || {};
    var topic = h('input', { type: 'text', spellcheck: 'false', autocomplete: 'off', placeholder: 'frlg-xxxxxxxxxxxxxx', 'aria-label': 'Tema de ntfy' });
    var url = h('input', { type: 'url', spellcheck: 'false', autocomplete: 'off', placeholder: 'https://discord.com/api/webhooks/…', 'aria-label': 'Webhook de Discord' });
    topic.value = cur.ntfy || ''; url.value = cur.discord || '';
    function commit() {
      var o = {};
      if (topic.value.trim()) o.ntfy = topic.value.trim();
      if (url.value.trim()) o.discord = url.value.trim();
      setVal('notify', o);
    }
    topic.addEventListener('input', commit); url.addEventListener('input', commit);
    var gen = h('button', { type: 'button', class: 'btn', title: 'Crear un tema difícil de adivinar' }, icon('wand'), 'Generar');
    gen.addEventListener('click', function () { topic.value = core.randomTopic(); commit(); toast('Tema nuevo: suscríbete a él en la app ntfy'); });
    return h('div', { class: 'statgrid' },
      h('div', null, h('div', { class: 'help', text: 'ntfy (tema)' }), h('div', { class: 'row' }, h('div', { style: 'flex:1 1 220px' }, topic), gen)),
      h('div', null, h('div', { class: 'help', text: 'Discord (webhook)' }), url));
  }

  function routeCtl(f) {
    var cur = cfg().routeFile || f.def;
    var known = [f.def].concat(data.routes);
    var sel = h('select', { id: 'f-routeFile' });
    known.forEach(function (r) { sel.appendChild(h('option', { value: r, text: r === f.def ? r + ' (grabada con la tecla 6)' : r + ' (lista para usar)' })); });
    sel.appendChild(h('option', { value: '__other', text: 'Otro nombre…' }));
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
        toast('Curación ajustada a "' + (tile ? 'Casilla que cura' : 'Enfermera') + '" para esa ruta');
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
    return h('div', { class: 'field' + (f.half ? ' half' : ''), 'data-key': f.key },
      isBool ? null : h('label', { class: 'label', for: 'f-' + f.key }, h('span', { text: f.label }), h('code', { text: f.key })),
      h('div', { class: 'control-wrap' }, ctl),
      f.help ? h('p', { class: 'help', text: f.help }) : null);
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
    var presetSel = h('select', { 'aria-label': 'Ejemplos', title: 'Cargar un ejemplo' });
    presetSel.appendChild(h('option', { value: '', text: 'Cargar ejemplo…' }));
    data.presets[S.bot].forEach(function (p, i) { presetSel.appendChild(h('option', { value: i, text: p.name.replace(/\.$/, '') })); });
    presetSel.addEventListener('change', function () {
      if (presetSel.value === '') return;
      var p = data.presets[S.bot][Number(presetSel.value)];
      if (!confirm('Esto reemplaza la configuración actual de ' + d.name + ' por "' + p.name.replace(/\.$/, '') + '". ¿Seguir?')) { presetSel.value = ''; return; }
      S.cfg[S.bot] = presetConfig(S.bot, Number(presetSel.value));
      S.origin[S.bot] = p.name;
      renderForm();
      toast('Ejemplo cargado: ' + p.name.replace(/\.$/, ''));
    });
    nav.appendChild(h('div', { class: 'nav-head' },
      h('span', { class: 'bot-icon' }, icon(d.icon)),
      h('div', null, h('b', { text: d.name }), h('small', { text: d.tagline }))));
    nav.appendChild(presetSel);

    var list = h('div', { class: 'nav-list', role: 'tablist', 'aria-orientation': 'vertical', 'aria-label': 'Secciones' });
    var shownAdvanced = false;
    def().sections.forEach(function (s) {
      if (s.advanced && !shownAdvanced) { list.appendChild(h('div', { class: 'nav-sep', text: 'Avanzado' })); shownAdvanced = true; }
      var b = h('button', { type: 'button', role: 'tab', class: 'nav-item', 'data-nav': s.id, 'aria-selected': String(cur && cur.id === s.id) },
        h('span', { class: 'n-icon' }, icon(s.icon)), h('span', { class: 'n-title', text: s.title }), h('span', { class: 'n-badge', hidden: true }));
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
        h('span', { text: (dir < 0 ? 'Anterior: ' : 'Siguiente: ') + target.title }),
        dir > 0 ? h('span', { class: 'turn' }, icon('chevron')) : null);
      b.addEventListener('click', function () { goSection(target.id); });
      return b;
    }
    main.appendChild(h('section', { class: 'card panel', 'data-section': s.id, role: 'tabpanel' },
      h('div', { class: 'backdrop', 'aria-hidden': 'true', style: bgOpacity() === null ? null : 'opacity:' + bgOpacity() }, backdrop()),
      h('button', { type: 'button', class: 'btn small bg-btn', title: 'Cambiar el fondo', onclick: function () { openAppearance(true); } },
        icon('palette'), h('span', { text: 'Fondo' })),
      h('header', null, h('span', { class: 'sec-icon' }, icon(s.icon)),
        h('div', null, h('h2', { text: s.title }), s.desc ? h('p', { text: s.desc }) : null),
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
    sum.appendChild(h('span', { text: errs.length ? errs.length + (errs.length === 1 ? ' error: el bot no arrancaría' : ' errores: el bot no arrancaría')
      : warns.length ? 'Lista, con ' + warns.length + (warns.length === 1 ? ' aviso' : ' avisos') : 'Lista para usar' }));
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
        badge.title = p.error ? p.error + ' error(es)' : p.warn + ' aviso(s)';
      }
    });
    var ul = $('issues');
    ul.innerHTML = '';
    document.querySelectorAll('.field.has-error').forEach(function (el) { el.classList.remove('has-error'); });
    if (!issues.length) ul.appendChild(h('li', { class: 'empty', text: 'Sin problemas. Guarda y, en el juego, pulsa 0 para recargar.' }));
    issues.forEach(function (i) {
      var s = def().sections.filter(function (x) { return x.id === sectionOf(i.key); })[0];
      var b = h('button', { type: 'button' }, icon(i.level === 'error' ? 'error' : i.level === 'warn' ? 'warn' : 'info'),
        h('span', null, h('span', { text: i.msg }), s ? h('small', { text: s.title }) : null));
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
    tf.appendChild(h('span', { text: S.dir ? 'Se guardará en la carpeta "' + S.dir.name + '" como ' + def().file
      : 'Se descargará como ' + def().file + '. Ponlo junto a ' + def().script + '.' }));
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
    toast('Cargado ' + (name || 'JSON') + ' (' + schema.bots[bot].name + ')' + (unknown.length ? ' · opciones desconocidas: ' + unknown.join(', ') : ''), unknown.length ? 'warn' : 'check');
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
          toast(found.length ? 'Carpeta abierta: aún no tiene ' + schema.bots[S.bot].file + '; se creará al guardar'
            : 'Carpeta abierta (no veo el .lua del bot aquí, revisa que sea la correcta)', found.length ? 'folder' : 'warn');
        });
      });
    }).catch(function (e) { if (e && e.name !== 'AbortError') toast('No pude abrir la carpeta: ' + e.message, 'error'); });
  }

  function save() {
    var c = cfg(), d = def();
    var errs = core.validate(S.bot, c, data, schema).filter(function (i) { return i.level === 'error'; });
    if (errs.length && !confirm('Hay ' + errs.length + ' error(es): el bot no arrancará con este archivo. ¿Guardar igual?')) return;
    var text = core.serialize(S.bot, c, schema);
    if (S.dir) {
      S.dir.getFileHandle(d.file, { create: true }).then(function (fh) { return fh.createWritable(); })
        .then(function (w) { return w.write(text).then(function () { return w.close(); }); })
        .then(function () { toast('Guardado en ' + S.dir.name + '/' + d.file + '. En el juego pulsa 0 para recargarlo.'); })
        .catch(function (e) { toast('No pude guardar: ' + e.message, 'error'); });
      return;
    }
    if (window.showSaveFilePicker) {
      window.showSaveFilePicker({ suggestedName: d.file, types: [{ description: 'Configuración del bot', accept: { 'application/json': ['.json'] } }] })
        .then(function (fh) { return fh.createWritable(); })
        .then(function (w) { return w.write(text).then(function () { return w.close(); }); })
        .then(function () { toast('Guardado ' + d.file + '. Ponlo junto a ' + d.script + '.'); })
        .catch(function (e) { if (e && e.name !== 'AbortError') download(text, d.file); });
      return;
    }
    download(text, d.file);
  }

  function download(text, name) {
    var a = h('a', { href: URL.createObjectURL(new Blob([text], { type: 'application/json' })), download: name });
    document.body.appendChild(a); a.click(); a.remove();
    toast('Descargado ' + name + '. Muévelo a la carpeta del bot.', 'download');
  }

  // ---------------------------------------------------------------- skins
  function renderSkins() {
    var sel = $('skin-select');
    sel.innerHTML = '';
    skins.list().forEach(function (s) { sel.appendChild(h('option', { value: s.id, text: s.name + (s.builtin ? '' : ' ★') })); });
    sel.value = S.skin;
    var ul = $('skin-list');
    ul.innerHTML = '';
    skins.list().forEach(function (s) {
      var row = h('button', { type: 'button' }, icon(s.id === S.skin ? 'check' : 'palette'),
        h('span', { text: s.name + (s.author ? ' — ' + s.author : '') + (s.builtin ? '' : ' (importado)') }));
      row.addEventListener('click', function () { applySkin(s.id); });
      var li = h('li', null, row);
      if (!s.builtin) {
        var del = h('button', { type: 'button', class: 'btn small', text: 'Borrar' });
        del.addEventListener('click', function () { skins.remove(s.id); if (S.skin === s.id) applySkin('pokeball'); else renderSkins(); });
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
    $('bg-species').placeholder = mine.image ? 'Imagen propia' : mine.none ? 'Sin fondo' : data.species[PT.art.backdrops[S.bot] - 1];
    pv.innerHTML = '';
    if (src && src.skin) pv.appendChild(icon('backdrop-' + S.bot));
    else if (src) pv.appendChild(h('img', { src: src.src, alt: '', referrerpolicy: 'no-referrer' }));
    var o = bgOpacity(), cur = o === null ? parseFloat(getComputedStyle(document.documentElement).getPropertyValue('--backdrop-opacity')) || 0.14 : o;
    $('bg-opacity').value = Math.round(cur * 100);
    $('bg-opacity-val').textContent = Math.round(cur * 100) + '%';
  }
  function setBg(choice) {
    var p = bgPrefs();
    if (choice) p[S.bot] = choice; else delete p[S.bot];
    if (!bgSave(p)) toast('El navegador no deja guardar el fondo: solo durará esta sesión', 'warn');
    renderBg(); renderSection();
  }
  if (data.species) $('bg-species-list').innerHTML = data.species.map(function (n) { return '<option value="' + n + '">'; }).join('');
  $('bg-species').addEventListener('keydown', function (e) { if (e.key === 'Enter') { e.preventDefault(); this.blur(); } });
  $('bg-species').addEventListener('change', function () {
    var name = this.value.trim(), hit = data.species.filter(function (n) { return n.toLowerCase() === name.toLowerCase(); })[0];
    if (!name) return;
    if (!hit) { toast('No conozco ese Pokémon: elige uno de la lista (Gen 1–3)', 'warn'); this.value = ''; return; }
    setBg({ species: hit });
  });
  $('btn-bg-none').addEventListener('click', function () { setBg({ none: true }); });
  $('btn-bg-reset').addEventListener('click', function () { setBg(null); });
  $('btn-bg-upload').addEventListener('click', function () { $('bg-file').value = ''; $('bg-file').click(); });
  $('bg-file').addEventListener('change', function () {
    var f = this.files[0];
    if (!f) return;
    if (!/^image\/(png|jpeg|webp|gif)$/.test(f.type)) { toast('Usa una imagen PNG, JPG, WebP o GIF', 'warn'); return; }
    if (f.size > 1500000) { toast('La imagen pesa más de 1,5 MB: usa una más pequeña', 'warn'); return; }
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
        if (!skins.saveCustom()) toast('Skin cargado solo para esta sesión (el navegador no deja guardarlo)', 'warn');
        applySkin(s.id);
        toast('Skin "' + s.name + '" importado');
      } catch (e) { toast('Skin no válido: ' + e.message, 'error'); }
    });
  });
  $('btn-skin-export').addEventListener('click', function () {
    var a = h('a', { href: URL.createObjectURL(new Blob([skins.exportable(S.skin)], { type: 'application/json' })), download: 'skin-' + S.skin + '.json' });
    document.body.appendChild(a); a.click(); a.remove();
    toast('Skin exportado: edítalo y vuelve a importarlo', 'download');
  });

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
      .then(function () { toast('JSON copiado'); }, function () {
        var r = document.createRange(); r.selectNodeContents($('preview'));
        var sel = getSelection(); sel.removeAllRanges(); sel.addRange(r);
        toast('Selecciónalo y cópialo con Ctrl+C', 'info');
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
  applySkin(saved && skins.get(saved) ? saved : 'pokeball');
})();
