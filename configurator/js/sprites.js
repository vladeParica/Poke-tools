// Original sprites for the configurator (our own work, no third-party art).
// - Line icons: 24x24, stroke = currentColor, so every skin recolors them.
// - Pixel mascot: the Poke-tools bot as 16x16 pixel art, drawn from a character map.
// Skins can replace any sprite with their own image (see configurator/skins/README.md).
(function (root) {
  'use strict';

  function svg(body, extra) {
    return '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"' + (extra || '') + '>' + body + '</svg>';
  }

  var icons = {
    'bot-shiny': svg('<path d="M12 2.5l2.2 6.3 6.3 2.2-6.3 2.2L12 19.5l-2.2-6.3L3.5 11l6.3-2.2z"/><path d="M19 17l.8 2.2 2.2.8-2.2.8L19 23l-.8-2.2-2.2-.8 2.2-.8z"/>'),
    'bot-train': svg('<path d="M6.5 6.5v11M17.5 6.5v11M3.5 9v6M20.5 9v6M6.5 12h11"/>'),
    'bot-farm': svg('<path d="M9 3.5h6l-1.5 3h-3z"/><path d="M10.5 6.5C6 8.5 3.5 12.5 3.5 16a4.5 4.5 0 0 0 4.5 4.5h8a4.5 4.5 0 0 0 4.5-4.5c0-3.5-2.5-7.5-7-9.5"/><circle cx="12" cy="14.5" r="2.5"/>'),
    'mode-coin': svg('<circle cx="12" cy="12" r="9"/><path d="M12 6.5v11M14.5 9h-3.75a1.75 1.75 0 0 0 0 3.5h2.5a1.75 1.75 0 0 1 0 3.5H9.5"/>'),
    'stat-hp': svg('<path d="M12 20s-7-4.4-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.6-7 10-7 10z"/>'),
    'stat-atk': svg('<path d="M14.5 3.5l6 0 0 6-9.5 9.5-6-6z"/><path d="M5 13l6 6M3.5 20.5l3-3"/>'),
    'stat-def': svg('<path d="M12 3l7.5 3v5.5c0 4.6-3.2 8-7.5 9.5-4.3-1.5-7.5-4.9-7.5-9.5V6z"/>'),
    'stat-spa': svg('<circle cx="12" cy="12" r="3.5"/><path d="M12 2.5v3M12 18.5v3M2.5 12h3M18.5 12h3M5.3 5.3l2.1 2.1M16.6 16.6l2.1 2.1M5.3 18.7l2.1-2.1M16.6 7.4l2.1-2.1"/>'),
    'stat-spd': svg('<path d="M12 3l7.5 3v5.5c0 4.6-3.2 8-7.5 9.5-4.3-1.5-7.5-4.9-7.5-9.5V6z"/><path d="M12 8.5l1.1 2.4 2.4 1.1-2.4 1.1L12 15.5l-1.1-2.4L8.5 12l2.4-1.1z"/>'),
    'stat-spe': svg('<path d="M13 2.5L5 13.5h6l-1 8 8-11h-6z"/>'),
    'mode-wild': svg('<path d="M4 20c1-5 1.5-8 1-12M9 20c0-4 .5-8 3-12M15 20c-.5-4-.2-7 2-11M20 20c-.5-3-1.5-5-3-6"/><path d="M2.5 20.5h19"/>'),
    'mode-static': svg('<circle cx="12" cy="12" r="8.5"/><path d="M3.5 12h5.5M15 12h5.5"/><circle cx="12" cy="12" r="3"/>'),
    'mode-gift': svg('<rect x="3.5" y="9" width="17" height="11.5" rx="1.5"/><path d="M2.5 9h19M12 9v11.5"/><path d="M12 9c-1.5-3.5-5.5-4-5.5-1.5S10 9 12 9zM12 9c1.5-3.5 5.5-4 5.5-1.5S14 9 12 9z"/>'),
    'mode-roamer': svg('<ellipse cx="7" cy="15.5" rx="2.5" ry="3.5"/><ellipse cx="16.5" cy="8" rx="2.5" ry="3.5"/><path d="M5 9.5h.01M8.5 9h.01M14.5 2.5h.01M18 2h.01"/>'),
    'mode-seed': svg('<path d="M12 21v-8"/><path d="M12 13c0-4 3-7 8-7 0 4.5-3.5 7-8 7zM12 15c0-3.5-2.5-6-7-6 0 4 3 6 7 6z"/>'),
    'mode-newgame': svg('<rect x="3" y="5" width="18" height="14" rx="2"/><circle cx="8.5" cy="11" r="2"/><path d="M5.5 16c.6-1.6 1.6-2.5 3-2.5s2.4.9 3 2.5M14 10h4M14 13.5h3"/>'),
    'dice': svg('<rect x="3.5" y="3.5" width="17" height="17" rx="3"/><path d="M8.5 8.5h.01M15.5 8.5h.01M12 12h.01M8.5 15.5h.01M15.5 15.5h.01" stroke-width="3"/>'),
    'compass': svg('<circle cx="12" cy="12" r="9"/><path d="M15.5 8.5l-2 5-5 2 2-5z"/>'),
    'target': svg('<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><circle cx="12" cy="12" r="1"/>'),
    'spark': svg('<path d="M12 3v4M12 17v4M3 12h4M17 12h4M6 6l2.5 2.5M15.5 15.5L18 18M6 18l2.5-2.5M15.5 8.5L18 6"/>'),
    'route': svg('<circle cx="6" cy="18" r="2.5"/><circle cx="18" cy="6" r="2.5"/><path d="M8.5 18H15a3 3 0 0 0 0-6H9a3 3 0 0 1 0-6h6.5"/>'),
    'bell': svg('<path d="M6 16V11a6 6 0 0 1 12 0v5l1.5 2h-15z"/><path d="M10 20.5a2 2 0 0 0 4 0"/>'),
    'gear': svg('<circle cx="12" cy="12" r="3"/><path d="M12 2.5v3M12 18.5v3M21.5 12h-3M5.5 12h-3M18.7 5.3l-2.1 2.1M7.4 16.6l-2.1 2.1M18.7 18.7l-2.1-2.1M7.4 7.4L5.3 5.3"/>'),
    'refresh': svg('<path d="M20 11a8 8 0 0 0-14.3-4.9L3.5 8.5M4 13a8 8 0 0 0 14.3 4.9l2.2-2.4"/><path d="M3.5 3.5v5h5M20.5 20.5v-5h-5"/>'),
    'folder': svg('<path d="M3 6.5A1.5 1.5 0 0 1 4.5 5H9l2 2.5h8.5A1.5 1.5 0 0 1 21 9v9.5a1.5 1.5 0 0 1-1.5 1.5h-15A1.5 1.5 0 0 1 3 18.5z"/>'),
    'upload': svg('<path d="M12 15V3.5M7 8.5l5-5 5 5M4 15v4.5h16V15"/>'),
    'download': svg('<path d="M12 3.5V15M7 10l5 5 5-5M4 15v4.5h16V15"/>'),
    'save': svg('<path d="M5 3.5h11l3.5 3.5v12a1.5 1.5 0 0 1-1.5 1.5H5A1.5 1.5 0 0 1 3.5 19V5A1.5 1.5 0 0 1 5 3.5z"/><path d="M7.5 3.5v5h8v-5M7.5 20.5v-6h9v6"/>'),
    'copy': svg('<rect x="8.5" y="8.5" width="12" height="12" rx="2"/><path d="M15.5 8.5v-3a2 2 0 0 0-2-2h-8a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h3"/>'),
    'palette': svg('<path d="M12 3a9 9 0 1 0 0 18c1.4 0 2-1 2-2s-1-1.5-1-2.5 1-1.5 2-1.5h2a4 4 0 0 0 4-4c0-4.4-4-8-9-8z"/><path d="M7.5 11h.01M10 7h.01M15 7h.01" stroke-width="3"/>'),
    'x': svg('<path d="M6 6l12 12M18 6L6 18"/>'),
    'plus': svg('<path d="M12 5v14M5 12h14"/>'),
    'check': svg('<path d="M4.5 12.5l5 5 10-11"/>'),
    'warn': svg('<path d="M12 3.5l9.5 16.5h-19z"/><path d="M12 10v4.5M12 17.5h.01"/>'),
    'error': svg('<circle cx="12" cy="12" r="9"/><path d="M12 7.5v5.5M12 16.5h.01"/>'),
    'info': svg('<circle cx="12" cy="12" r="9"/><path d="M12 11v5.5M12 7.5h.01"/>'),
    'chevron': svg('<path d="M6 9l6 6 6-6"/>'),
    'wand': svg('<path d="M4 20L15 9M14 4v3M19 9h3M17.5 5.5L19.5 3.5M12.5 6.5l5 5"/>')
  };

  // 16x16 pixel mascot. Legend: . transparent, k outline, r red, R red shade, w white,
  // g grey shade, c cyan, C cyan light, y yellow, h highlight.
  var MASCOT = [
    '.......kk.......',
    '......kyyk......',
    '.......kk.......',
    '....kkkkkkkk....',
    '...krrhhrrrrk...',
    '..krhhrrrrrrRk..',
    '..krkkkrrkkkRk..',
    '.krrkCckkCckrRk.',
    '.krrrkkrrkkrrRk.',
    '.kkkkkkwwkkkkkk.',
    '.kkkkkwccwkkkkk.',
    '.kwwwwkwwkwwwgk.',
    '..kwwgwwwwwwgk..',
    '..kwwwwgggwwgk..',
    '...kkwwwwwwkk...',
    '.....kkkkkk.....'
  ];
  var MASCOT_COLORS = {
    k: '#1F1F2E', r: '#E8401F', R: '#B92A12', w: '#FFFFFF', g: '#C6CCD8',
    c: '#2FB8C9', C: '#B9F6FA', y: '#FFCB05', h: '#FF8A70'
  };

  function pixelArt(rows, colors, sparkle) {
    var rects = '';
    rows.forEach(function (row, y) {
      for (var x = 0; x < row.length; x++) {
        var col = colors[row[x]];
        if (col) rects += '<rect x="' + x + '" y="' + y + '" width="1" height="1" fill="' + col + '"/>';
      }
    });
    if (sparkle) {
      rects += '<path d="M14.5 .5v3M13 2h3" stroke="#FFCB05" stroke-width="1" fill="none"/>';
    }
    return '<svg viewBox="0 0 16 16" shape-rendering="crispEdges" aria-hidden="true">' + rects + '</svg>';
  }

  var sprites = {
    mascot: pixelArt(MASCOT, MASCOT_COLORS, false),
    'mascot-shiny': pixelArt(MASCOT, {
      k: '#1F1F2E', r: '#3A7BFF', R: '#2251C4', w: '#FFFFFF', g: '#C6CCD8',
      c: '#FFB000', C: '#FFF1B8', y: '#FFCB05', h: '#8DB4FF'
    }, true)
  };

  // 32x32 silhouettes drawn behind each bot's form (our own pixel art, # = filled).
  // Filled with currentColor, so every skin tints them; skins can replace them.
  var BACKDROPS = {
    'backdrop-shinybot': [   // Pikachu
      '..##..................##........',
      '..###................###........',
      '...###..............###.........',
      '...####............####.........',
      '....####..........####..........',
      '.....####........####...........',
      '.....#####......#####.......####',
      '......##############........####',
      '.......############........#####',
      '......##############.......#####',
      '.....################.....#####.',
      '.....###.########.###.....#####.',
      '.....###.########.###....#####..',
      '.....################....#####..',
      '.....################...#####...',
      '......##############....####....',
      '.......############....####.....',
      '........##########....####......',
      '.......############....####.....',
      '.....################...###.....',
      '.....################..###......',
      '.....################.###.......',
      '.....###################........',
      '.....##################.........',
      '......################..........',
      '......##############............',
      '......##############............',
      '.......############.............',
      '.....################...........',
      '....######......######..........',
      '................................',
      '................................'
    ],
    'backdrop-trainbot': [   // Machop
      '................................',
      '............##.##.##............',
      '............##.##.##............',
      '..####......########......####..',
      '.######....##########....######.',
      '.######...############...######.',
      '..####....############....####..',
      '..####....###.####.###....####..',
      '..####....############....####..',
      '..####....############....####..',
      '..####.....##########.....####..',
      '..########...######...########..',
      '..############################..',
      '..############################..',
      '..############################..',
      '..........############..........',
      '..........############..........',
      '...........##########...........',
      '...........##########...........',
      '..........############..........',
      '..........############..........',
      '..........#####..#####..........',
      '..........#####..#####..........',
      '..........#####..#####..........',
      '..........#####..#####..........',
      '..........#####..#####..........',
      '..........#####..#####..........',
      '.........######..######.........',
      '........#######..#######........',
      '................................',
      '................................',
      '................................'
    ],
    'backdrop-farmbot': [   // Meowth
      '....#.................#.........',
      '....##...............##.........',
      '....###.............###.........',
      '....####...........####.........',
      '....###################.........',
      '.....#################..........',
      '....#########.#########.........',
      '...#########...#########........',
      '...##########.##########........',
      '...#####################........',
      '...#####..#######..#####....###.',
      '#############################.##',
      '...#####################...#####',
      '.#########################..####',
      '.....#################......###.',
      '.......#############........###.',
      '.........#########.........###..',
      '........###########.......###...',
      '.......#############.....###....',
      '.......#############....###.....',
      '........###########....###......',
      '........###########...###.......',
      '........###########..###........',
      '........###########.###.........',
      '.........#############..........',
      '........####...####.............',
      '........####...####.............',
      '........####...####.............',
      '.......#####...#####............',
      '................................',
      '................................',
      '................................'
    ]
  };

  function silhouette(rows) {
    var d = '';
    rows.forEach(function (row, y) {
      for (var x = 0; x < row.length; x++) if (row[x] === '#') d += 'M' + x + ' ' + y + 'h1v1h-1z';
    });
    return '<svg viewBox="0 0 32 32" shape-rendering="crispEdges" aria-hidden="true"><path fill="currentColor" d="' + d + '"/></svg>';
  }
  Object.keys(BACKDROPS).forEach(function (k) { sprites[k] = silhouette(BACKDROPS[k]); });

  // Lets built-in skins add their own pixel sprites (see skins/aventura.js).
  function addPixel(name, rows, colors) { sprites[name] = pixelArt(rows, colors, false); }

  var api = { icons: icons, sprites: sprites, MASCOT: MASCOT, addPixel: addPixel };
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  else { root.PT = root.PT || {}; root.PT.art = api; }
})(typeof window !== 'undefined' ? window : globalThis);
