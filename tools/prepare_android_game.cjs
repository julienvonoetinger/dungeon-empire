// Stage the playable game without altering the live editor or the visual-kit preset.
// Usage: node tools/prepare_android_game.cjs
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const root = path.resolve(__dirname, '..');
const files = new Set();
const resourceExtension = /\.(?:gdshader|gd|tscn|tres|png|svg|ttf|otf|txt)$/i;

function collect(file) {
  if (files.has(file)) return;
  if (!fs.existsSync(path.join(root, file))) throw Error('Missing game dependency: ' + file);
  files.add(file);
  if (/\.(gd|tscn|tres|gdshader)$/.test(file)) {
    const source = fs.readFileSync(path.join(root, file), 'utf8');
    for (const match of source.matchAll(/res:\/\/([A-Za-z0-9_./-]+\.(?:gdshader|gd|tscn|tres|png|svg|ttf|otf))/g)) collect(match[1]);
  }
}

function collectDirectory(directory) {
  for (const entry of fs.readdirSync(path.join(root, directory), { withFileTypes: true })) {
    const file = directory + '/' + entry.name;
    if (entry.isDirectory()) collectDirectory(file);
    else if (resourceExtension.test(entry.name)) collect(file);
  }
}

collect('scenes/game/DungeonGame.tscn');
// These roots also cover class_name registrations and concatenated load() paths.
for (const directory of ['scripts/game', 'assets/ui', 'assets/dungeon/bedrock']) collectDirectory(directory);
collect('assets/ui/master/fonts/OFL.txt');

const staging = fs.mkdtempSync(path.join(root, 'artifacts/android-game-'));
function copy(file) {
  const target = path.join(staging, file);
  fs.mkdirSync(path.dirname(target), { recursive: true });
  fs.copyFileSync(path.join(root, file), target);
}
const selected = [...files].sort();
for (const file of [...selected, 'project.godot']) {
  copy(file);
  // Retain import settings and stable UIDs, but build a fresh import cache.
  for (const suffix of ['.uid', '.import']) if (fs.existsSync(path.join(root, file + suffix))) copy(file + suffix);
}
fs.copyFileSync(path.join(__dirname, 'android-game-export.cfg'), path.join(staging, 'export_presets.cfg'));
// Required by Android export even when this 2D kit uses lossless textures.
// Apply only to the fresh staging project to leave the live editor cache intact.
const projectPath = path.join(staging, 'project.godot');
const project = fs.readFileSync(projectPath, 'utf8');
fs.writeFileSync(projectPath, project.replace('[rendering]', '[rendering]\n\ntextures/vram_compression/import_etc2_astc=true'));
const inventory = {
  staging, mainScene: 'res://scenes/game/DungeonGame.tscn',
  sources: selected.map(file => ({ file, bytes: fs.statSync(path.join(root, file)).size,
    sha256: crypto.createHash('sha256').update(fs.readFileSync(path.join(root, file))).digest('hex') })),
};
fs.mkdirSync(path.join(root, 'build'), { recursive: true });
fs.writeFileSync(path.join(root, 'build/android-game-inventory.json'), JSON.stringify(inventory, null, 2) + '\n');
console.log(JSON.stringify({ staging, files: selected.length,
  sourceBytes: inventory.sources.reduce((total, source) => total + source.bytes, 0) }));
