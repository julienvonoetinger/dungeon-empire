// Stage the playable game without altering the live editor or the visual-kit preset.
// Usage: node tools/prepare_android_game.cjs
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const root = path.resolve(__dirname, '..');
const files = new Set();
const resourceExtension = /\.(?:gdshader|gd|glb|tscn|tres|png|webp|wav|ogg|svg|ttf|otf|txt|json)$/i;

function collect(file) {
  if (files.has(file)) return;
  if (!fs.existsSync(path.join(root, file))) throw Error('Missing game dependency: ' + file);
  files.add(file);
  if (/\.(gd|tscn|tres|gdshader)$/.test(file)) {
    const source = fs.readFileSync(path.join(root, file), 'utf8');
    for (const match of source.matchAll(/res:\/\/([A-Za-z0-9_./-]+\.(?:gdshader|gd|glb|tscn|tres|png|webp|wav|ogg|svg|ttf|otf|json))/g)) collect(match[1]);
  }
}

function collectDirectory(directory) {
  for (const entry of fs.readdirSync(path.join(root, directory), { withFileTypes: true })) {
    const file = directory + '/' + entry.name;
    if (entry.isDirectory()) collectDirectory(file);
    else if (resourceExtension.test(entry.name)) collect(file);
  }
}

const projectSettings = fs.readFileSync(path.join(root, 'project.godot'), 'utf8');
const mainScene = projectSettings.match(/^run\/main_scene="res:\/\/(.+)"$/m)[1];
collect(mainScene);
for (const match of projectSettings.matchAll(/"res:\/\/([^"]+\.po)"/g)) collect(match[1]);
// These roots also cover class_name registrations and concatenated load() paths.
for (const directory of ['scripts/game', 'assets/ui', 'assets/dungeon/bedrock',
  'assets/game/introduction/procession', 'assets/game/introduction/invoker-follow',
  'assets/game/introduction/sanctuary']) collectDirectory(directory);
// The GLB importer extracts these maps on first import. Carry their import settings
// into the clean stage as well, otherwise it generates three lossless 2048px maps.
const masterMaps = new Set(['normal', 'texture_0', 'texture_0_metallic_roughness']
  .map(name => 'assets/previews/wraith-master/wraith-levitation_' + name + '.png'));
for (const file of masterMaps) collect(file);
collect('assets/ui/master/fonts/OFL.txt');

const staging = fs.mkdtempSync(path.join(root, 'artifacts/android-game-'));
// Native validation writes screenshots here. Exclude them before the first import.
fs.mkdirSync(path.join(staging, 'artifacts'));
fs.writeFileSync(path.join(staging, 'artifacts/.gdignore'), '');
function copy(file) {
  const target = path.join(staging, file);
  fs.mkdirSync(path.dirname(target), { recursive: true });
  fs.copyFileSync(path.join(root, file), target);
}
const selected = [...files].sort();
const paintedAtlasDirs = [
  'assets/game/introduction/procession/', 'assets/game/introduction/invoker-follow/',
  'assets/game/introduction/messengers/', 'assets/previews/oculin-mineur-walk/',
  'assets/previews/oculin-menuisier-walk/', 'assets/previews/oculin-scientifique-walk/',
];
const paintedBackgrounds = new Set([
  'assets/game/introduction/sanctuary/natural_ground.png', 'assets/ui/main-menu/core-sanctum.png',
]);
for (const file of [...selected, 'project.godot']) {
  copy(file);
  // Retain import settings and stable UIDs, but build a fresh import cache.
  for (const suffix of ['.uid', '.import']) if (fs.existsSync(path.join(root, file + suffix))) copy(file + suffix);
  const settingsPath = path.join(staging, file + '.import');
  if (file.startsWith('assets/game/introduction/prologue-') && file.endsWith('.webp')) {
    // Ship the painted WebP bytes. Re-encoding their decoded pixels as lossless
    // textures inflated these twenty images from 4.4 MB to 24.6 MB.
    fs.writeFileSync(settingsPath, '[remap]\n\nimporter="keep"\n');
  } else if (masterMaps.has(file)) {
    // The ritual renders the Master in a 512px viewport. Keep the colour and
    // material channels lossless and retain their mipmaps.
    const settings = fs.readFileSync(settingsPath, 'utf8');
    fs.writeFileSync(settingsPath, settings.replace(/^compress\/mode=\d+/m, 'compress/mode=0')
      .replace(/^process\/size_limit=\d+/m, 'process/size_limit=1024'));
  } else if (paintedBackgrounds.has(file)
      || (file.endsWith('.png') && paintedAtlasDirs.some(directory => file.startsWith(directory)))) {
    const settings = fs.readFileSync(settingsPath, 'utf8');
    fs.writeFileSync(settingsPath, settings.replace(/^compress\/mode=\d+/m, 'compress/mode=1')
      .replace(/^compress\/lossy_quality=[\d.]+/m, 'compress/lossy_quality=0.90'));
  }
}
const universal = fs.readFileSync(path.join(__dirname, 'android-game-export.cfg'), 'utf8');
const arm64 = universal.replaceAll('[preset.0', '[preset.1').replace('name="Android Game"', 'name="Android Game ARM64"')
  .replace('runnable=true', 'runnable=false').replace('architectures/armeabi-v7a=true', 'architectures/armeabi-v7a=false');
fs.writeFileSync(path.join(staging, 'export_presets.cfg'), universal + '\n' + arm64);
// Required by Android export even when this 2D kit uses lossless textures.
// Apply only to the fresh staging project to leave the live editor cache intact.
const projectPath = path.join(staging, 'project.godot');
const project = fs.readFileSync(projectPath, 'utf8');
fs.writeFileSync(projectPath, project.replace('[rendering]', '[rendering]\n\ntextures/vram_compression/import_etc2_astc=true'));
const inventory = {
  staging, mainScene: 'res://' + mainScene,
  sources: selected.map(file => ({ file, bytes: fs.statSync(path.join(root, file)).size,
    sha256: crypto.createHash('sha256').update(fs.readFileSync(path.join(root, file))).digest('hex') })),
};
fs.mkdirSync(path.join(root, 'build'), { recursive: true });
fs.writeFileSync(path.join(root, 'build/android-game-inventory.json'), JSON.stringify(inventory, null, 2) + '\n');
console.log(JSON.stringify({ staging, files: selected.length,
  sourceBytes: inventory.sources.reduce((total, source) => total + source.bytes, 0) }));
