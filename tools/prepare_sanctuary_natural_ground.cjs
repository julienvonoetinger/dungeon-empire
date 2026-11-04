// One continuous native painting mapped across the existing ground geometry.
// Scenery art and logical placements remain in the approved v3 preview.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const sharp = require('sharp');
const {writeGeneratedFile: write} = require('./write_generated_file.cjs');
const ROOT = path.resolve(__dirname, '..');
const read = p => fs.readFileSync(path.join(ROOT, p));
const save = (p, v) => write(path.join(ROOT, p), v);
const hash = v => crypto.createHash('sha256').update(v).digest('hex');
const REV = 'docs/reference/sanctuary-textured/v4';
const OUT = 'assets/previews/sanctuary-natural-ground/ground.png';
const map = [-1050, -900, 2100, 2100];
const candle = {name: 'Bougies2', previousGrid: [-.95,-.12], grid: [-.95,.5]};
const project = (x,y) => [128*(x-y),64*(x+y)];
async function main() {
  const source = read(REV + '/source/ground.png');
  const {width,height} = await sharp(source).metadata();
  save(OUT, source);
  const geo = JSON.parse(read('docs/reference/sanctuary-textured/v1/geometry.json'));
  const old = JSON.parse(read('docs/reference/sanctuary-textured/v3/recipe.json'));
  const previous = read('scenes/SanctuaryCoherent.tscn').toString();
  const nodeStart = previous.indexOf('[node ');
  let header = previous.slice(0, nodeStart).replace(/^\[ext_resource.*id="floor-[^"]+"\]\r?\n/gm, '');
  header += `[ext_resource type="Texture2D" path="res://${OUT}" id="natural_ground"]\n\n`;
  const resources = [...header.matchAll(/\[ext_resource /g)].length;
  header = header.replace(/load_steps=\d+/, 'load_steps=' + (resources + 1));
  const blocks = previous.slice(nodeStart).split(/\n(?=\[node )/);
  const floor = new Map(geo.segments.filter(s => s.id === 'floor-0').map(s => [s.name,s]));
  const solids = new Set([...geo.segments.filter(s => s.id !== 'floor-0').map(s => s.name), ...old.decor.filter(s => !s.ground).map(s => s.name)]);
  const bases = [], ordered = [];
  // Two-pixel guard: overlapping ground polygons sample identical world UVs.
  const g = 2 * Math.sqrt(5) / 256;
  const points = [[-g,-g],[1+g,-g],[1+g,1+g],[-g,1+g]].map(p => project(...p));
  for (let block of blocks) {
    const name = block.match(/^\[node name="([^"]+)"/)[1];
    const s = floor.get(name);
    if (s) {
      const uv = points.map(p => [(p[0]+s.position[0]-map[0])/map[2]*width,(p[1]+s.position[1]-map[1])/map[3]*height]);
      block = `[node name="${name}" type="Polygon2D" parent="."]\n` +
        `position = Vector2(${s.position.join(',')})\n` +
        'texture_repeat = 3\ntexture = ExtResource("natural_ground")\n' +
        `polygon = PackedVector2Array(${points.flat().join(',')})\n` +
        `uv = PackedVector2Array(${uv.flat().join(',')})\n` +
        `metadata/grid_position = Vector2(${s.x},${s.y})\n`;
    }
    if (name === candle.name) {
      block = block.replace(/^position = .*$/m, `position = Vector2(${project(...candle.grid).join(',')})`)
        .replace(/^metadata\/grid_position = .*$/m, `metadata/grid_position = Vector2(${candle.grid.join(',')})`);
    }
    if (solids.has(name)) {
      const grid = block.match(/metadata\/grid_position = Vector2\(([^)]+)\)/)[1].split(',').map(Number);
      ordered.push({block,depth:grid[0]+grid[1]});
    } else bases.push(block);
  }
  ordered.sort((a,b) => a.depth-b.depth);
  const scene = header + [...bases,...ordered.map(s => s.block)].join('\n');
  save('scenes/SanctuaryNaturalGround.tscn', scene);
  save(REV + '/recipe.json', JSON.stringify({source:REV+'/source/ground.png',sha256:hash(source),size:[width,height],map,
    groundPolygons:floor.size,placements:geo.segments.length,scenerySource:'scenes/SanctuaryCoherent.tscn',
    scenerySourceHash:hash(Buffer.from(previous)),candle,guard:g,textureRepeat:'mirror outside the central painted extent',
    resources,orderedSolids:ordered.length},null,2)+'\n');
  console.log(`${floor.size} ground polygons share one continuous painting; ${ordered.length} sorted solids; candle moved.`);
}
main().catch(e => {console.error(e);process.exitCode=1;});
