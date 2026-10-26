// Editorial comparison only: preserve ImageGen source pixels and native alpha.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const sharp = require('sharp');
const dir = __dirname;
const root = path.resolve(dir, '../../../..');
const hash = p => crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
async function frame(file) {
  const { data, info } = await sharp(file).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  let top = info.height, bottom = -1, transparent = 0;
  for (let y = 0; y < info.height; y++) for (let x = 0; x < info.width; x++) {
    const a = data[(y * info.width + x) * 4 + 3];
    if (a > 32) { top = Math.min(top, y); bottom = Math.max(bottom, y); }
    if (a === 0) transparent++;
  }
  if (bottom < top || !transparent) throw Error('Missing painted pixels or native alpha');
  top = Math.max(0, top - 24);
  bottom = Math.min(info.height - 1, bottom + 24);
  const crop = { left: 0, top, width: info.width, height: bottom - top + 1 };
  const png = await sharp(file).extract(crop).resize({ width: 1080 }).png().toBuffer();
  return { png, crop, sourceSize: [info.width, info.height], height: (await sharp(png).metadata()).height, sha256: hash(file) };
}
async function main() {
  const origin = JSON.parse(fs.readFileSync(path.join(dir, 'generation.json'))).entrave;
  const source = path.join(dir, 'source/entrave.png');
  if (hash(source) !== hash(origin)) throw Error('Source differs from ImageGen original');
  const previous = path.resolve(dir, '../v5-flush-states/source/entrave.png');
  const before = await frame(previous), after = await frame(source);
  const rowHeight = Math.max(before.height, after.height);
  const W = 1120, H = 202 + 2 * rowHeight;
  let svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" font-family="Segoe UI,Arial,sans-serif"><rect width="${W}" height="${H}" fill="#0d1420"/><text x="24" y="35" font-size="26" fill="#edf0f6">Entrave — centrage dans la case</text>`;
  ['ARMÉ', 'DÉCLENCHÉ', 'ÉPUISÉ'].forEach((label, i) => { svg += `<text x="${200 + 360 * i}" y="77" text-anchor="middle" font-size="18" font-weight="600" fill="#ceb1ec">${label}</text>`; });
  svg += `<text x="24" y="111" font-size="17" fill="#acb8cc">Avant · mécanisme trop avancé</text><text x="24" y="${rowHeight + 146}" font-size="17" fill="#e4d5f5">Après · mécanisme recentré, support au niveau des dalles</text><text x="24" y="${H - 17}" font-size="13" fill="#97a6be">Proposition visuelle · trois états · intégration au jeu à venir</text></svg>`;
  await sharp(Buffer.from(svg)).composite([
    { input: before.png, left: 20, top: 118 + Math.round((rowHeight - before.height) / 2) },
    { input: after.png, left: 20, top: rowHeight + 153 + Math.round((rowHeight - after.height) / 2) }
  ]).png().toFile(path.join(dir, 'comparison.png'));
  await sharp(source).extract(after.crop).resize({ width: 720 }).png().toFile(path.join(dir, 'states-small.png'));
  fs.writeFileSync(path.join(dir, 'states.png'), after.png);
  const baseline = JSON.parse(fs.readFileSync(path.join(dir, 'production-baseline.json')));
  for (const [file, expected] of Object.entries(baseline)) if (hash(path.join(root, file)) !== expected) throw Error('Production changed: ' + file);
  const { png: _before, ...beforeInfo } = before, { png: _after, ...afterInfo } = after;
  fs.writeFileSync(path.join(dir, 'validation.json'), JSON.stringify({
    tool: 'Built-in ImageGen', status: 'Appearance proposal; not integrated into Godot',
    nativeAlphaPreserved: true, originalByteIdentical: true, productionUnchanged: true,
    framing: 'Alpha >32 measures bounds only, with 24 source pixels padding; uniform resize, no source repaint or warp.',
    registration: 'Visual ground-footprint centering; not calibrated XYZ or native sprite anchors.',
    before: beforeInfo, after: afterInfo
  }, null, 2) + '\n');
  fs.writeFileSync(path.join(dir, 'index.html'), `<!doctype html><html lang="fr"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Entrave · centrage</title><style>body{max-width:1120px;margin:24px auto;padding:16px;background:#0d1420;color:#edf0f6;font:16px system-ui}img{display:block;width:100%;height:auto}a{color:#d0afea}p{color:#b4c0d3}.small{width:720px;max-width:100%}</style><h1>Entrave · centrage du mécanisme</h1><p>La base revient au centre du dallage dans les trois états, avec un support affleurant. Pointes et Néant sont inchangés.</p><img src="comparison.png" alt="Avant et après, états armé, déclenché et épuisé"><h2>Lecture à taille réduite</h2><img class="small" src="states-small.png" alt="Les trois états corrigés à taille réduite"><p>Proposition visuelle non intégrée au jeu. Le déclenchement reste une proposition d’état transitoire.</p><p><a href="source/entrave.png">Source originale</a> · <a href="brief.json">Prompt ImageGen</a> · <a href="validation.json">Contrôles</a></p></html>`);
  console.log(JSON.stringify({ board: [W, H], originalByteIdentical: true, productionUnchanged: true }));
}
main().catch(e => { console.error(e); process.exitCode = 1; });
