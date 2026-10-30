// Approved C artwork: straight cuts and one uniform resize per piece, no repaint.
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const sharp = require('sharp');
const root = path.resolve(__dirname, '..');
const review = path.join(root, 'docs/reference/interface-review/v14-header-c-integrated');
async function prepareHeaderC() {
  const source = path.join(review, 'source/header-c.png');
  const output = path.join(root, 'assets/ui/master');
  const pieces = {left: [20, 173, 860, 342], center: [880, 173, 410, 342], right: [1290, 173, 860, 342]};
  fs.mkdirSync(output, {recursive: true});
  const record = {source: path.relative(root, source).replaceAll('\\', '/'),
    sha256: crypto.createHash('sha256').update(fs.readFileSync(source)).digest('hex'),
    sourceEyeCenter: [1084, 340], runeRadius: 105, outputHeight: 192, pieces: {}};
  for (const [name, [left, top, width, height]] of Object.entries(pieces)) {
    const file = path.join(output, `header-c-${name}.png`);
    await sharp(source).extract({left, top, width, height}).resize({height: 192}).png().toFile(file);
    const info = await sharp(file).metadata();
    record.pieces[name] = {crop: [left, top, width, height], size: [info.width, info.height], bytes: fs.statSync(file).size};
  }
  fs.writeFileSync(path.join(review, 'preparation.json'), JSON.stringify(record, null, 2) + '\n');
  return record;
}
module.exports = {prepareHeaderC};
if (require.main === module) prepareHeaderC().then(r => console.log(JSON.stringify(r))).catch(e => {console.error(e);process.exitCode=1;});
