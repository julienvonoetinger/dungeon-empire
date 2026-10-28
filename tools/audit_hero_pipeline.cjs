// Conservation audit, not an animation correctness test. Read-only unless --record.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const root = path.resolve(__dirname, '..');
const review = 'docs/reference/vulpin-review';
const manifestPath = path.join(root, review, 'pipeline-manifest.json');
const sourceHash = '035f4d448e60fefd99b5eb9c8a7f2ddd55405802dcc060018d0c9595d848e2b4';
const documents = [
  'docs/production/hero-animation-pipeline.md',
  'docs/production/hero-animation-reproduction.md',
  `${review}/README.md`, `${review}/source/README.md`,
];
const actions = [
  ['walk', 'v16-meshy-walk', 'render_walk.py', 'vulpin-walk-poses.blend', 'VulpinWalk', 'capture_vulpin_walk_preview.gd', 'native-corridors'],
  ['run', 'v17-meshy-run', 'render_run.py', 'vulpin-run-poses.blend', 'VulpinRun', 'capture_vulpin_walk_preview.gd', 'native-corridors'],
  ['hurt', 'v19-hurt-recoil', 'render_hurt.py', 'vulpin-hurt-poses.blend', 'VulpinHurt', 'capture_vulpin_hurt_preview.gd', 'native-scene'],
  ['lockpick', 'v26-lower-lock-review', 'render_lockpick.py', 'vulpin-lockpick-poses.blend', 'VulpinLockpick', 'capture_vulpin_lockpick_preview.gd', 'native-scene'],
  ['chest-open', 'v21-chest-open', 'render_chest_open.py', 'vulpin-chest-open-poses.blend', 'VulpinChestOpen', 'capture_vulpin_chest_open_preview.gd', 'native-scene'],
  ['chest-lockpick', 'v22-chest-lockpick', 'render_chest_lockpick.py', 'vulpin-chest-lockpick-poses.blend', 'VulpinChestLockpick', 'capture_vulpin_chest_lockpick_preview.gd', 'native-scene'],
  ['death', 'v24-meshy-dead', 'render_fall.py', 'vulpin-fall-poses.blend', 'VulpinDeath', 'capture_vulpin_death_preview.gd', 'native-scene'],
];
const hash = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
function filePath(relative) {
  const resolved = path.resolve(root, relative);
  if (!resolved.startsWith(root + path.sep)) throw Error(`Outside repository: ${relative}`);
  return resolved;
}
function snapshot(relative) {
  const bytes = fs.readFileSync(filePath(relative));
  return { path: relative, bytes: bytes.length, sha256: hash(bytes) };
}
function collect() {
  const files = new Set();
  function add(relative) {
    relative = relative.replace(/\\/g, '/');
    if (files.has(relative)) return;
    const absolute = filePath(relative);
    if (!fs.statSync(absolute).isFile()) throw Error(`Expected file: ${relative}`);
    files.add(relative);
    if (/\.(gd|tscn|tres|gdshader)$/.test(relative)) {
      const source = fs.readFileSync(absolute, 'utf8');
      for (const m of source.matchAll(/res:\/\/([^"'\r\n]+\.(?:gd|tscn|tres|gdshader|png|json|ttf|otf|svg))(?=["'])/g)) {
        if (!/[%{}]/.test(m[1])) add(m[1]);
      }
      if (fs.existsSync(absolute + '.uid')) add(relative + '.uid');
    }
  }
  documents.forEach(add);
  [
    'tools/audit_hero_pipeline.cjs', `${review}/.gdignore`,
    `${review}/source/Meshy_AI_Character_output.glb`,
    `${review}/v15-meshy-inspection/inspect_model.py`, `${review}/v15-meshy-inspection/inspection.json`,
    'docs/reference/door-redesign/seal-v1/wireframe-v6-clean-leaf/geometry.json',
    'tools/verify_compact_door_passage.py',
    'docs/reference/door-redesign/seal-v1/hero-fit-v11-compact/geometry.json',
    'docs/reference/door-redesign/seal-v1/hero-fit-v11-compact/passage-validation.json',
    'docs/reference/door-redesign/seal-v1/hero-fit-v12-integrated/geometry.json',
    'docs/reference/door-redesign/seal-v1/hero-fit-v12-integrated/preparation.json',
    'docs/reference/door-redesign/seal-v1/hero-fit-v12-integrated/selection.json',
    'docs/reference/door-redesign/seal-v1/hero-fit-v12-integrated/source/face-source.png',
    'docs/reference/door-redesign/seal-v1/hero-fit-v13-malefic-leaf/selection.json',
    'docs/reference/door-redesign/seal-v1/hero-fit-v13-malefic-leaf/source/face-source.png',
    'docs/reference/door-redesign/seal-v1/hero-fit-v13-malefic-leaf/source/unified-frame-prompt.txt',
    'docs/reference/door-redesign/seal-v1/hero-fit-v14-passage/README.md',
    'docs/reference/door-redesign/seal-v1/hero-fit-v14-passage/after/validation.json',
    'docs/reference/door-redesign/seal-v1/hero-fit-v14-passage/open-door-validation.json',
    'tools/isometric_seal_door.cjs', 'tools/isometric_seal_texture.cjs',
    'tools/capture_door_passage.gd', 'tools/verify_door_passage_parts.cjs',
    'scenes/VulpinIdle.tscn', `${review}/v23-static-idle/capture.gd`,
    'assets/previews/vulpin-idle/frames.tres', 'assets/previews/vulpin-idle/SOURCE.txt',
  ].forEach(add);
  for (const [asset, version, render, blend, scene, capture, native] of actions) {
    const base = `${review}/${version}`;
    for (const name of [render, blend, 'poses.json', 'prepare.cjs', 'verify_saved_poses.py', 'saved-pose-validation.json', 'validation.json', `${native}/validation.json`]) add(`${base}/${name}`);
    for (const name of ['prepare_native_preview.cjs', 'calibrate_chests.cjs', 'chest-contacts.json', 'verify_chest_clearance.py', 'chest-clearance.json', 'verify_masonry_clearance.py', 'masonry-clearance.json', 'previous-sprite-hashes.json', 'final-arm-validation.json']) {
      if (fs.existsSync(filePath(`${base}/${name}`))) add(`${base}/${name}`);
    }
    add(`scenes/${scene}.tscn`);
    add(`tools/${capture}`);
    const assetDir = `assets/previews/vulpin-${asset}`;
    for (const name of fs.readdirSync(filePath(assetDir))) {
      if (/\.(png|tres|json|import)$/.test(name) || name === 'SOURCE.txt') add(`${assetDir}/${name}`);
    }
  }
  return [...files].sort().map(snapshot);
}
function checkLinks() {
  let count = 0;
  for (const doc of documents) {
    const content = fs.readFileSync(filePath(doc), 'utf8');
    for (const match of content.matchAll(/\]\(([^)]+)\)/g)) {
      const target = match[1].split('#')[0];
      if (!target || /^[a-z]+:/i.test(target)) continue;
      const absolute = path.resolve(path.dirname(filePath(doc)), decodeURIComponent(target));
      if (!fs.existsSync(absolute)) throw Error(`Broken link in ${doc}: ${target}`);
      count++;
    }
  }
  return count;
}
function main() {
  const args = process.argv.slice(2);
  if (args.some(a => a !== '--record')) throw Error('Usage: node tools/audit_hero_pipeline.cjs [--record]');
  const model = snapshot(`${review}/source/Meshy_AI_Character_output.glb`);
  if (model.sha256 !== sourceHash || model.bytes !== 15644004) throw Error('Original model differs');
  if (args.includes('--record')) {
    const manifest = {
      schema: 1, recordedAt: new Date().toISOString(),
      scope: 'Current Vulpin source recipes, saved poses, native assets, reports and literal Godot resource dependencies. Intermediate masters, captures and abandoned experiments are not fully inventoried. Not a backup or an artistic validation.',
      source: model, files: collect(),
    };
    fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2) + '\n');
  }
  const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
  const errors = [];
  for (const expected of manifest.files) {
    try {
      const actual = snapshot(expected.path);
      if (actual.bytes !== expected.bytes || actual.sha256 !== expected.sha256) errors.push(`Changed: ${expected.path}`);
    } catch (error) { errors.push(`Missing/unreadable: ${expected.path}: ${error.message}`); }
  }
  if (errors.length) throw Error(errors.join('\n'));
  console.log(JSON.stringify({ ok: true, files: manifest.files.length, localLinks: checkLinks(), sourceHashVerified: true, mode: args.includes('--record') ? 'recorded-and-verified' : 'read-only' }));
}
try { main(); } catch (error) { console.error(error.message); process.exitCode = 1; }
