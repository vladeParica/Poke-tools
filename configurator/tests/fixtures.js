// Configs exported by the configurator, used to check that the real bots accept them.
// Prints {"shinybot": [text, ...], "trainbot": [text, ...]} as JSON.
const { data, schema, core } = require('./load');

const rich = {
  shinybot: {
    mode: 'semilla inicial',
    initialSeeds: ['bc75', 'A0'],
    afterSeedMode: 'Regalo RNG',
    natures: ['Modesta', 'Timid'],
    minIVs: { ps: 31, vel: 30 },
    maxIVs: { ataque: 0 },
    minIVTotal: 150,
    hiddenPower: { type: 'Fuego', minPower: 60 },
    species: ['pikachu'],
    shiny: false,
    teachyMargin: 2000
  },
  trainbot: {
    evs: { spa: 252, spe: 252, hp: 4 },
    targetLevel: 50,
    maxLevel: 60,
    species: ['gastly', 'Haunter'],
    avoidSpecies: ['Geodude'],
    learnMoves: 'ask',
    askTimeout: null,
    wantedMoves: ['thunderbolt', 'Psychic', 'Giga Drain', 'Night Shade'],
    keepMoves: ['Night Shade'],
    notify: { ntfy: 'frlg-abcdefghijk', discord: 'https://discord.com/api/webhooks/123/abc_DEF-ghi' },
    healMode: 'tile',
    routeFile: 'FRLG_TrainRoute_Tower.txt'
  }
};

const out = {};
for (const bot of ['shinybot', 'trainbot']) {
  const configs = data.presets[bot].map((p) => p.config).concat([rich[bot]]);
  out[bot] = configs.map((c) => {
    const n = core.normalize(bot, JSON.parse(JSON.stringify(c)), data);
    const errors = core.validate(bot, n, data, schema).filter((i) => i.level === 'error');
    if (errors.length) throw new Error(bot + ': fixture has errors: ' + JSON.stringify(errors));
    return core.serialize(bot, n, schema);
  });
}
process.stdout.write(JSON.stringify(out));
