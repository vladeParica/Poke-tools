// "Aventura" skin: parchment and fire-red colors with its own 16x16 pixel sprites for the
// mascot, the bots, the stats and the modes. Original art drawn from character maps.
(function (PT) {
  'use strict';

  // Legend: . transparent, k outline, w white, s/S grey, r/R red, y/Y yellow, g/G green,
  // b/B blue, p/P purple, n/N brown, h highlight. Capital = darker shade.
  var C = {
    k: '#2B2D42', w: '#FFFFFF', s: '#C9C3B6', S: '#8E8778', r: '#E04A2F', R: '#A8301C',
    y: '#FFC93C', Y: '#D99A1E', g: '#5DBB63', G: '#2F7D3A', b: '#4A7BD9', B: '#2C4FA0',
    p: '#9B6BDB', P: '#6A3FA8', n: '#B07A45', N: '#7A4F2A', h: '#FFE8B0'
  };

  var SHIELD = [
    '................',
    '..kkkkkkkkkkkk..',
    '..kwbbbbbbbbBk..',
    '..kbwbbbbbbbBk..',
    '..kbbbbyybbbBk..',
    '..kbbbbyybbbBk..',
    '..kbbyyyyyybBk..',
    '..kbbyyyyyybBk..',
    '..kbbbbyybbbBk..',
    '...kbbbyybbBk...',
    '...kbbbbbbbBk...',
    '....kbbbbbBk....',
    '.....kbbbBk.....',
    '......kbBk......',
    '.......kk.......',
    '................'
  ];

  var art = {
    'stat-hp': [
      '................',
      '................',
      '...kkk....kkk...',
      '..krrrk..krrrk..',
      '.krwwrrkkrrrrRk.',
      '.krwrrrrrrrrrRk.',
      '.krrrrrrrrrrrRk.',
      '.krrrrrrrrrrrRk.',
      '..krrrrrrrrrRk..',
      '...krrrrrrrRk...',
      '....krrrrrRk....',
      '.....krrrRk.....',
      '......krRk......',
      '.......kk.......',
      '................',
      '................'
    ],
    'stat-atk': [
      '.............kkk',
      '............kwsk',
      '...........kwsk.',
      '..........kwsk..',
      '.........kwsk...',
      '........kwsk....',
      '.......kwsk.....',
      '..kk..kwsk......',
      '..kYkkwsk.......',
      '...kYksk........',
      '....kYk.........',
      '...knkYk........',
      '..knk.kYk.......',
      '.knk...kk.......',
      '.kk.............',
      '................'
    ],
    'stat-def': SHIELD,
    'stat-spa': [
      '................',
      '.....kkkkkk.....',
      '...kkppppppkk...',
      '..kpwwppppppPk..',
      '..kpwppppppPPk..',
      '.kpppppppppPPPk.',
      '.kpppppppppPPPk.',
      '.kpppppppppPPPk.',
      '.kpppppppppPPPk.',
      '..kpppppppPPPk..',
      '..kPpppppPPPPk..',
      '...kkPPPPPPkk...',
      '.....kkkkkk.....',
      '....kYYYYYYk....',
      '...kYYYYYYYYk...',
      '...kkkkkkkkkk...'
    ],
    'stat-spe': [
      '................',
      '........kkkkk...',
      '.......kyyyyk...',
      '......kyyyyk....',
      '.....kyyyyk.....',
      '....kyyyyk......',
      '...kyyyyykkkk...',
      '..kyyyyyyyyYk...',
      '..kkkkkyyyYk....',
      '......kyyYk.....',
      '.....kyyYk......',
      '....kyyYk.......',
      '...kyYk.........',
      '...kYk..........',
      '...kk...........',
      '................'
    ],
    'bot-shiny': [
      '................',
      '.......kk.......',
      '......kyyk......',
      '......kyyk......',
      '.....kyyyYk.....',
      '...kkyyyyYYkk...',
      '.kkyyyywwyyYYkk.',
      '.kyyyyywwyyyYYk.',
      '..kkYyyyyyyYkk..',
      '....kkYyyYkk....',
      '.....kyyYYk.....',
      '......kyYk......',
      '......kyYk......',
      '.......kk.......',
      '................',
      '................'
    ],
    'bot-train': [
      '................',
      '................',
      '.kkkk......kkkk.',
      '.krrk......krrk.',
      '.krrk......krrk.',
      '.krrkkkkkkkkrrk.',
      '.krrkwwwwwwkrrk.',
      '.krrkSSSSSSkrrk.',
      '.krrkkkkkkkkrrk.',
      '.krrk......krrk.',
      '.kRRk......kRRk.',
      '.kkkk......kkkk.',
      '................',
      '................',
      '................',
      '................'
    ],
    'bot-farm': [
      '................',
      '......kkkk......',
      '.....knnnNk.....',
      '......kYYk......',
      '.....kyyyYk.....',
      '....knnnnnNk....',
      '...knnnnnnnNk...',
      '..knnhnnnnnnNk..',
      '.knnnnnyynnnnNk.',
      '.knnnnyYYynnnNk.',
      '.knnnnyYYynnnNk.',
      '.knnnnnyynnnnNk.',
      '.knnnnnnnnnnNNk.',
      '..kNnnnnnnnNNk..',
      '...kkkkkkkkkk...',
      '................'
    ],
    'mode-coin': [
      '................',
      '.....kkkkkk.....',
      '...kkyyyyyykk...',
      '..kyhyyyyyyyYk..',
      '..kyhyYYYYyyYk..',
      '.kyhyYyyyyYyyYk.',
      '.kyyyYyyyyYyyYk.',
      '.kyyyYyyyyYyyYk.',
      '.kyyyYyyyyYyyYk.',
      '.kyyyyYYYYyyYYk.',
      '..kyyyyyyyyYYk..',
      '..kYyyyyyyYYYk..',
      '...kkYYYYYYkk...',
      '.....kkkkkk.....',
      '................',
      '................'
    ],
    'mode-wild': [
      '................',
      '................',
      '................',
      '...k.......k....',
      '..kgk.....kgk...',
      '..kgk..k..kgk.k.',
      '.kgGk.kgk.kgGkgk',
      '.kgGkkgGk.kgGkgk',
      'kggGkkgGkkggGgGk',
      'kgggGkgGGkgggGGk',
      'kgggGggGGggggGGk',
      'kGGGGGGGGGGGGGGk',
      'nnnnnnnnnnnnnnnn',
      'NNNNNNNNNNNNNNNN',
      '................',
      '................'
    ],
    'mode-static': [
      '................',
      '...........kkk..',
      '............k...',
      '...........kkk..',
      '.....kkkkkk.....',
      '...kksssssskk...',
      '..kswwssssssSk..',
      '.kswssssssssSSk.',
      '.kssssssssSSSSk.',
      '.kssssssSSSSSSk.',
      '.kSSSSSSSSSSSSk.',
      '.kkkkkkkkkkkkkk.',
      '................',
      '................',
      '................',
      '................'
    ],
    'mode-gift': [
      '................',
      '................',
      '....kk....kk....',
      '...kyyk..kyyk...',
      '....kyykkyyk....',
      '.kkkkkkkkkkkkkk.',
      '.krrrrryyrrrrRk.',
      '.kRRRRRyYRRRRRk.',
      '.kkkkkkkkkkkkkk.',
      '..krrrryyrrrRk..',
      '..krrrryyrrrRk..',
      '..krrrryyrrrRk..',
      '..kRRRRyYRRRRk..',
      '..kkkkkkkkkkkk..',
      '................',
      '................'
    ],
    'mode-roamer': [
      '........NN.NN.NN',
      '........NN.NN.NN',
      '................',
      '..........NNNN..',
      '.........NNNNNN.',
      '.........NNNNNN.',
      '..........NNNN..',
      '................',
      '................',
      'NN.NN.NN........',
      'NN.NN.NN........',
      '................',
      '..NNNN..........',
      '.NNNNNN.........',
      '.NNNNNN.........',
      '..NNNN..........'
    ],
    'mode-seed': [
      '................',
      '................',
      '..kkk......kkk..',
      '.kgggk....kgggk.',
      '.kggggk..kggggk.',
      '..kGGggkkggGGk..',
      '...kkGGkkGGkk...',
      '......kGGk......',
      '......kGGk......',
      '......kGGk......',
      '..kkkkkGGkkkkk..',
      '.knnnnnnnnnnnnk.',
      '.kNnnnnnnnnnnNk.',
      '..kNNNNNNNNNNk..',
      '...kkkkkkkkkk...',
      '................'
    ],
    'mode-newgame': [
      '................',
      '..kkkkkkkkkkkk..',
      '..kssssssssssk..',
      '..ksSSSSSSSSsk..',
      '..ksSrrrrrrSsk..',
      '..ksSrwwwwrSsk..',
      '..ksSrrrrrrSsk..',
      '..ksSrwwrrrSsk..',
      '..ksSrrrrrrSsk..',
      '..ksSSSSSSSSsk..',
      '..kssssssssssk..',
      '..kssssssssssk..',
      '..ksSsSsSsSssk..',
      '..kkkkkkkkkkkk..',
      '................',
      '................'
    ]
  };

  var sprites = {};
  Object.keys(art).forEach(function (name) {
    PT.art.addPixel('aventura-' + name, art[name], C);
    sprites[name] = 'aventura-' + name;
  });
  // Special Defense: the same shield in green with a light emblem.
  PT.art.addPixel('aventura-stat-spd', SHIELD, Object.assign({}, C, { b: C.g, B: C.G, y: C.h }));
  sprites['stat-spd'] = 'aventura-stat-spd';
  // The mascot in the skin's colors: fire-orange body and green eyes.
  PT.art.addPixel('aventura-mascot', PT.art.MASCOT, Object.assign({}, C, {
    k: '#2B2D42', r: '#F08A24', R: '#C2621A', g: '#D8D0BE', c: '#2F9E5B', C: '#B8F0C8', h: '#FFC27A'
  }));
  sprites.mascot = 'aventura-mascot';

  PT.registerSkin({
    id: 'aventura',
    name: 'Aventura',
    author: 'Poke-tools',
    pixelated: true,
    vars: {
      '--bg': '#efe4c8',
      '--surface': '#fffaf0',
      '--surface-2': '#f6edd6',
      '--border': '#2b2d42',
      '--text': '#2b2d42',
      '--muted': '#6b6253',
      '--accent': '#d6402c',
      '--accent-ink': '#fffaf0',
      '--accent-2': '#2f8f5b',
      '--accent-soft': 'rgba(214, 64, 44, .12)',
      '--ok': '#2f8f5b',
      '--warn': '#c77d0a',
      '--error': '#b3261e',
      '--header-bg': '#2b2d42',
      '--header-ink': '#fffaf0',
      '--radius': '6px',
      '--radius-sm': '3px',
      '--shadow': '3px 3px 0 rgba(43, 45, 66, .30)',
      '--font-body': '"Trebuchet MS", "Segoe UI", sans-serif',
      '--font-display': '"Trebuchet MS", "Segoe UI", sans-serif',
      '--bg-pattern': 'repeating-linear-gradient(45deg, rgba(43, 45, 66, .035) 0 8px, transparent 8px 16px)'
    },
    sprites: sprites
  });
})(window.PT);
