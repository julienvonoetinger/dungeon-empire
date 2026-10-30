// Native-alpha ImageGen sources; crop and uniformly reduce, never repaint.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const sharp = require('sharp');
const root = path.resolve(__dirname, '..');
const review = path.join(root, 'docs/reference/interface-review/v19-stone-menus');
async function prepareStoneUI() {
  const output = path.join(root, 'assets/ui/master/stone-menu');
  fs.mkdirSync(output, {recursive: true});
  const record = {method: 'alpha bounding crop, uniform contain resize; no painting', assets: {}};
  for (const [name, width, height] of [['panel',128,128],['round',384,384],['face',128,128],['button',256,64]]) {
    const source = path.join(review, 'source', (name === 'face' ? 'panel' : name) + '.png');
    const {data, info} = await sharp(source).ensureAlpha().raw().toBuffer({resolveWithObject: true});
    let x0 = info.width, y0 = info.height, x1 = -1, y1 = -1;
    for (let y = 0; y < info.height; y++) for (let x = 0; x < info.width; x++) {
      if (data[(y * info.width + x) * 4 + 3] > 8) {
        x0 = Math.min(x0, x); y0 = Math.min(y0, y);
        x1 = Math.max(x1, x); y1 = Math.max(y1, y);
      }
    }
    if (x1 < x0) throw Error('Empty source: ' + name);
    const crop = name === 'face'
      ? {left: Math.floor(info.width*.25), top: Math.floor(info.height*.25), width: Math.floor(info.width*.5), height: Math.floor(info.height*.5)}
      : {left: x0, top: y0, width: x1-x0+1, height: y1-y0+1};
    const destination = path.join(output, name + '.png');
    await sharp(source).extract(crop).resize(width, height, {fit: 'contain', background: '#00000000'}).png().toFile(destination);
    record.assets[name] = {source: path.relative(root, source).replaceAll('\\', '/'),
      sha256: crypto.createHash('sha256').update(fs.readFileSync(source)).digest('hex'),
      sourceSize: [info.width, info.height], crop, size: [width, height],
      pngBytes: fs.statSync(destination).size, rgbaBytes: width * height * 4};
  }
  fs.writeFileSync(path.join(review, 'preparation.json'), JSON.stringify(record, null, 2) + '\n');
  return record;
}
module.exports = {prepareStoneUI};
if (require.main === module) prepareStoneUI().then(r => console.log(JSON.stringify(r))).catch(e => {console.error(e); process.exitCode = 1;});
