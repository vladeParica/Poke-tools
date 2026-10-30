// Loads the configurator modules in Node (data.js expects a browser `window`).
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const dir = path.join(__dirname, '..', 'js');
const ctx = { window: {} };
vm.createContext(ctx);
vm.runInContext(fs.readFileSync(path.join(dir, 'data.js'), 'utf8'), ctx);

module.exports = {
  data: ctx.window.PT.data,
  schema: require(path.join(dir, 'schema.js')),
  core: require(path.join(dir, 'core.js'))
};
