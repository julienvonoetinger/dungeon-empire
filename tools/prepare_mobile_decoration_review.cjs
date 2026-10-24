// Review of generated ornaments: source artwork above real, unscaled Godot crops.
const fs = require('node:fs');
const path = require('node:path');
const sharp = require('sharp');
const {writeGeneratedFile} = require('./write_generated_file.cjs');
const ROOT = path.resolve(__dirname, '..');
const OUT = path.join(ROOT, 'docs/reference/mobile-decoration-review');
const MOBILE = path.join(ROOT, 'docs/reference/mobile-optimization');

async function main() {
  const recipe = JSON.parse(fs.readFileSync(path.join(MOBILE, 'recipe.json'), 'utf8'));
  const panels = [
    ['a', 'A · Pierre sculptée', 'proposed-256'],
    ['b', 'B · Sceau ancien', 'detail-b'],
    ['c', 'C · Sceau corrompu', 'detail-c']
  ];
  const layers = [];
  for (const [i, [variant, , capture]] of panels.entries()) {
    const meta = recipe.decorationSources.find(s => s.variant === variant);
    const [x, y, w, h] = meta.visibleBounds;
    const scale = 180 / Math.max(w, h);
    // Preserve the entire original native alpha, including faint outer pixels.
    const original = fs.readFileSync(path.join(ROOT, meta.source));
    const art = await sharp(original).resize(Math.round(meta.sourceSize[0] * scale), Math.round(meta.sourceSize[1] * scale)).png().toBuffer();
    layers.push({input:art, left:Math.round(160 + i * 320 - (x + w / 2) * scale), top:Math.round(224 - (y + h / 2) * scale)});
    const frozen=path.join(OUT,'source/captures',capture+'.png');
    layers.push({input:await sharp(fs.existsSync(frozen)?frozen:path.join(MOBILE, 'captures', capture + '.png')).extract({left:265,top:76,width:190,height:180}).png().toBuffer(), left:65 + i * 320, top:420});
  }
  const background = Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="960" height="655">
    <rect width="100%" height="100%" fill="#080e19"/>
    <g font-family="Arial,sans-serif" fill="#e1e8f4">
      <text x="24" y="32" font-size="23">Décors séparés · trois propositions sur le même pilier</text>
      ${panels.map((p,i)=>`<text x="${24+i*320}" y="81" font-size="22">${p[1]}</text>`).join('')}
      <text x="24" y="369" font-size="18" fill="#aebdd2">Ci-dessus : dessin source agrandi · ci-dessous : rendu Godot à la taille de jeu</text>
      <text x="24" y="637" font-size="17" fill="#aebdd2">Extraits sans redimensionnement · 192 pixels par case · murs, sols et piliers nus sous les décors</text>
    </g></svg>`);
  writeGeneratedFile(path.join(OUT, 'comparison.png'), await sharp(background).composite(layers).png().toBuffer());
  console.log('Saved mobile-decoration-review/comparison.png');
}
main().catch(e => {console.error(e.stack);process.exitCode=1;});
