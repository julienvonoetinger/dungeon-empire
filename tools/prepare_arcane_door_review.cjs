// Isolated magic-seal material variation; production geometry, stone and kit stay fixed.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const assert = require('node:assert/strict');
const sharp = require('sharp');
const P = require('./isometric_paint_geometry.cjs');
const Door = require('./isometric_seal_door.cjs');
const Texture = require('./isometric_seal_texture.cjs');

const REVIEW = 'docs/reference/door-redesign/seal-v1/arcane-v1';
const RUNTIME = 'assets/previews/mycean-unlock/door';
const SOURCE = REVIEW + '/source/face-source.png';
const DIRECTIONS = ['south', 'north', 'east', 'west'];
const SEAL_HEIGHT = .64;
const absolute = p => path.resolve(P.ROOT, p);
const digest = data => crypto.createHash('sha256').update(data).digest('hex');
const hash = p => digest(fs.readFileSync(absolute(p)));
const read = p => JSON.parse(fs.readFileSync(absolute(p), 'utf8'));
const files = dir => fs.readdirSync(dir, {withFileTypes: true}).flatMap(entry =>
  entry.isDirectory() ? files(path.join(dir, entry.name)) : [path.join(dir, entry.name)]);
const write = (p, data) => {
  fs.mkdirSync(path.dirname(absolute(p)), {recursive: true});
  fs.writeFileSync(absolute(p), data);
};
let checks = 0;
function check(condition, message) { checks++; assert(condition, message); }
function equal(actual, expected, message) { checks++; assert.deepEqual(actual, expected, message); }

async function rgba(png) {
  return sharp(png).ensureAlpha().raw().toBuffer({resolveWithObject: true});
}

async function main() {
  const protectedFiles = [
    ...files(absolute('assets/dungeon/isometric-kit')),
    ...Texture.referenceFiles.map(absolute),
    ...['isometric_seal_texture.cjs', 'isometric_seal_door.cjs', 'seal_masonry_finish.cjs',
      'isometric_paint_geometry.cjs', 'isometric_wall_palette.cjs'].map(p => absolute('tools/' + p)),
  ];
  const baseline = Object.fromEntries([...new Set(protectedFiles)].map(p => [p, hash(p)]));
  const source = await rgba(absolute(SOURCE));
  const sourceMetadata = await sharp(absolute(SOURCE)).metadata();
  const generation = read(REVIEW + '/source/generation.json');
  equal(hash(SOURCE), generation.selected.sha256, 'Selected source is an unchanged native copy');
  equal(hash(REVIEW + '/source/' + generation.initial.archive), generation.initial.sha256, 'Rejected source is an unchanged native copy');
  equal([source.info.width, source.info.height], [1024, 1536], 'Registered source canvas');
  check(sourceMetadata.hasAlpha, 'Native source has an alpha channel');
  const sourcePixel = (x, y) => [...source.data.subarray((y * source.info.width + x) * 4, (y * source.info.width + x) * 4 + 4)];
  let clearPixels = 0, paintedPixels = 0;
  for (let i = 3; i < source.data.length; i += 4) {
    if (source.data[i] === 0) clearPixels++;
    if (source.data[i] > 240) paintedPixels++;
  }
  check(clearPixels > 0 && paintedPixels > 10000, 'Source retains native transparency and solid painting');
  const keyhole = sourcePixel(512, 1138);
  check(keyhole.slice(0, 3).every(v => v < 35) && keyhole[3] > 240, 'Mechanical keyhole remains black at its existing contact');
  const mapping = read('docs/reference/door-redesign/seal-v1/hero-fit-v12-integrated/mapping.json');
  const preparation = read('docs/reference/door-redesign/seal-v1/hero-fit-v12-integrated/preparation.json');
  const sealSource = [mapping.xOrigin, (mapping.zOrigin - SEAL_HEIGHT * mapping.scale - preparation.fit.translation[1]) / preparation.fit.uniformScale];
  check(Math.abs(sealSource[1] - 875.6) < 1e-9, 'Spell target uses the original UV registration');
  const crystal = sourcePixel(Math.round(sealSource[0]), Math.round(sealSource[1]));
  check(crystal[3] > 240 && crystal[2] > crystal[1] + 30 && crystal[0] > crystal[1] + 30, 'Spell target samples the violet central crystal');

  const catalog = {}, preservation = [], outputs = [], fullViews = [];
  for (const direction of DIRECTIONS) {
    const original = await Door.paint(direction, false);
    const proposal = await Door.paint(direction, false, SOURCE);
    equal(proposal.model, original.model, direction + ': exact original XYZ');
    equal(proposal.full.frame, original.full.frame, direction + ': exact full image frame');
    equal(proposal.full.bounds, original.full.bounds, direction + ': exact full support');
    equal(proposal.parts.length, 4, direction + ': all four depth supports remain');
    const oldFull = await rgba(original.full.png), newFull = await rgba(proposal.full.png);
    let alphaDifferences = 0;
    for (let k = 3; k < oldFull.data.length; k += 4) if (oldFull.data[k] !== newFull.data[k]) alphaDifferences++;
    equal(alphaDifferences, 0, direction + ': exact silhouette alpha');
    const panel = original.parts.find(p => p.doorPart === 'panel');
    const panelMask = (await rgba(panel.png)).data;
    for (let i = 0; i < proposal.parts.length; i++) {
      const part = proposal.parts[i], old = original.parts[i];
      for (const field of ['id', 'frame', 'bounds', 'doorPart', 'wallJunction', 'companions', 'rasterScale']) {
        equal(part[field], old[field], part.id + ': exact ' + field);
      }
      const a = (await rgba(part.png)).data, b = (await rgba(old.png)).data;
      let differences = 0, outsideFringe = 0, alphaChanges = 0;
      for (let k = 0; k < a.length; k += 4) {
        if (a[k + 3] !== b[k + 3]) alphaChanges++;
        if (a.subarray(k, k + 4).equals(b.subarray(k, k + 4))) continue;
        differences++;
        if (part.doorPart === 'panel') continue;
        const pixel = k / 4;
        const x = pixel % part.frame[2] + part.frame[0] - panel.frame[0];
        const y = Math.floor(pixel / part.frame[2]) + part.frame[1] - panel.frame[1];
        let nearPanel = false;
        for (let dy = -3; dy <= 3; dy++) for (let dx = -3; dx <= 3; dx++) {
          const X = x + dx, Y = y + dy;
          if (X >= 0 && Y >= 0 && X < panel.frame[2] && Y < panel.frame[3] && panelMask[(Y * panel.frame[2] + X) * 4 + 3] > 0) nearPanel = true;
        }
        if (!nearPanel) outsideFringe++;
      }
      equal(alphaChanges, 0, part.id + ': exact part alpha');
      equal(outsideFringe, 0, part.id + ': stone unchanged outside existing 3px panel filter fringe');
      if (part.doorPart === 'panel') check(differences > 25, part.id + ': distinct arcane painting');
      preservation.push({id: part.id, role: part.doorPart, changedPixels: differences, outsidePanelFringeChanges: outsideFringe, alphaChanges});
      const file = part.id + '.png';
      catalog[part.id] = {file, offset: part.frame.slice(0, 2), size: part.frame.slice(2), bounds: part.bounds,
        door_part: part.doorPart, companions: part.companions, wall_junction: part.wallJunction};
      outputs.push([RUNTIME + '/' + file, part.png], [REVIEW + '/parts/' + file, part.png]);
    }
    // Demonstrate that providing a different leaf material cannot affect any open-frame pixels.
    const openOriginal = await Door.paint(direction, true);
    const openOverride = await Door.paint(direction, true, SOURCE);
    equal(openOverride.model, openOriginal.model, direction + ': original open geometry');
    equal(digest(openOverride.full.png), digest(openOriginal.full.png), direction + ': open frame pixel-identical');
    equal(openOriginal.parts.length, 3, direction + ': original open three-support split');
    for (let i = 0; i < openOriginal.parts.length; i++) {
      equal(digest(openOverride.parts[i].png), digest(openOriginal.parts[i].png), openOriginal.parts[i].id + ': original open pixels');
    }
    outputs.push([REVIEW + '/door-' + direction + '.png', proposal.full.png], [REVIEW + '/production-door-' + direction + '.png', original.full.png]);
    fullViews.push({direction, png: proposal.full.png, frame: proposal.full.frame});
  }
  equal(Object.keys(catalog).length, 16, 'Only 16 closed-door preview parts');
  for (const [p, originalHash] of Object.entries(baseline)) equal(hash(p), originalHash, 'Production input unchanged: ' + p);
  const hashes = Object.fromEntries(outputs.filter(([p]) => p.startsWith(RUNTIME)).map(([p, data]) => [path.basename(p), digest(data)]));
  const sourceFiles = files(absolute(REVIEW + '/source'));
  const sourceHashes = Object.fromEntries(sourceFiles.map(p => [path.relative(absolute(REVIEW), p).replaceAll('\\', '/'), hash(p)]));
  const manifest = {
    version: 1, status: 'isolated-preview-only', generator: 'tools/prepare_arcane_door_review.cjs',
    source: SOURCE, sourceSha256: hash(SOURCE), directions: DIRECTIONS, closedPartCount: 16,
    approvedProductionSelection: 'docs/reference/door-redesign/seal-v1/hero-fit-v15-iron-crystals/selection.json',
    seal: {height: SEAL_HEIGHT, source: sealSource, canonicalFront: [.5, .525, SEAL_HEIGHT],
      directionNormals: {south: [0, 1], north: [0, -1], east: [1, 0], west: [-1, 0]},
      worldTarget: 'door cell + (0.5,0.5) + facing normal * 0.025, z=0.64', targetRgba: crystal},
    mechanicalKeyhole: {height: .32, source: [512, 1138], rgba: keyhole},
    unchangedOpenResources: 'Use production door-{direction}-open-{leaf,arch,jamb-right}; no new open textures.',
    files: hashes,
    warning: 'The legacy -leaf suffix is the left jamb. The actual door leaf is -panel; load all four closed pieces because original opaque seam pixels overlap by 2px.'
  };
  const report = {
    status: 'pass', checks, sourceHashes, generatorSha256: hash('tools/prepare_arcane_door_review.cjs'),
    source: {width: source.info.width, height: source.info.height, clearPixels, paintedPixels, keyhole, crystal},
    geometryUnchanged: true, framesAndSupportsUnchanged: true, fullAndPartAlphaUnchanged: true,
    stoneUnchangedOutsidePanelFringe: true, filterFringePixels: 3, opaqueOverlapPixels: 2,
    openFramePartsUnchanged: 12, productionFilesUnchanged: Object.keys(baseline).length,
    parts: preservation, runtimeBytes: outputs.filter(([p]) => p.startsWith(RUNTIME)).reduce((n, [, data]) => n + data.length, 0),
    protectedProduction: Object.fromEntries(Object.entries(baseline).map(([p, h]) => [path.relative(P.ROOT, p).replaceAll('\\', '/'), h])),
    limits: 'Static painted-seal variant on existing smooth geometry. Native Mycean animation, beam contact, controls and screenshots are verified separately. No gameplay integration, save I/O, APK, commit or push.'
  };
  for (const [p, data] of outputs) write(p, data);
  write(RUNTIME + '/catalog.json', JSON.stringify(catalog, null, 2) + '\n');
  write(REVIEW + '/preview-catalog.json', JSON.stringify(Object.fromEntries(Object.entries(catalog).map(([id, entry]) => [id, {...entry, file: 'parts/' + entry.file}])), null, 2) + '\n');
  write(RUNTIME + '/manifest.json', JSON.stringify(manifest, null, 2) + '\n');
  write(REVIEW + '/preservation.json', JSON.stringify(report, null, 2) + '\n');
  const cell = 440, images = [];
  for (let i = 0; i < fullViews.length; i++) {
    const rendered = await sharp(fullViews[i].png).resize({width: cell - 32, height: cell - 32, fit: 'inside'}).png().toBuffer({resolveWithObject: true});
    images.push({input: rendered.data, left: i % 2 * cell + Math.floor((cell - rendered.info.width) / 2), top: Math.floor(i / 2) * cell + Math.floor((cell - rendered.info.height) / 2)});
  }
  write(REVIEW + '/four-directions.png', await sharp({create: {width: cell * 2, height: cell * 2, channels: 4, background: {r: 16, g: 23, b: 34, alpha: 1}}}).composite(images).png().toBuffer());
  console.log(JSON.stringify({checks, runtimeParts: 16, runtimeBytes: report.runtimeBytes, unchangedOpenParts: 12, protectedFiles: Object.keys(baseline).length, seal: manifest.seal, keyhole, catalog: RUNTIME + '/catalog.json'}, null, 2));
}

main().catch(error => { console.error(error); process.exitCode = 1; });
