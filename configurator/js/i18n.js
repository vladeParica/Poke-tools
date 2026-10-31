// Interface language for the configurator. The Spanish text in the code is the source; each
// js/lang/<code>.js file maps it to that language with PT.i18n.add(). "{name}" placeholders
// are filled from the second argument of t(). Missing translations fall back to Spanish.
(function (root) {
  'use strict';

  var dicts = { es: {} }, extras = { es: {} }, lang = 'es';
  var NAMES = { es: 'Español', en: 'English', ja: '日本語' };

  function fill(s, v) {
    return v ? String(s).replace(/\{(\w+)\}/g, function (m, k) { return v[k] !== undefined ? v[k] : m; }) : s;
  }
  function t(s, v) {
    var d = dicts[lang];
    return fill(d && d[s] !== undefined ? d[s] : s, v);
  }
  // dict: Spanish source -> translation. extra: per-language tables such as nature names.
  function add(code, dict, extra) {
    dicts[code] = Object.assign(dicts[code] || {}, dict);
    extras[code] = Object.assign(extras[code] || {}, extra || {});
  }
  function set(code) { lang = NAMES[code] ? code : 'es'; return lang; }

  root.PT = root.PT || {};
  root.PT.i18n = {
    t: t, add: add, set: set, NAMES: NAMES,
    lang: function () { return lang; },
    extra: function () { return extras[lang] || {}; },
    dict: function (code) { return dicts[code] || {}; }
  };
})(typeof window !== 'undefined' ? window : globalThis);
