// One interior crop from the original HUD painting. No repeats or resizing.
const path = require('node:path');
const sharp = require('sharp');
const root = path.resolve(__dirname, '..');
const source = path.join(root, 'docs/reference/interface-review/v19-stone-menus/source/panel.png');
const target = path.join(root, 'assets/ui/master/stone-menu/dialogue-stone.webp');

sharp(source)
  .extract({left: 146, top: 360, width: 960, height: 320})
  .webp({lossless: true})
  .toFile(target)
  .catch(error => { console.error(error); process.exitCode = 1; });
