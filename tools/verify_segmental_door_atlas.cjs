// Check the packed production resources against the sources used in the door review.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const sharp = require('sharp');

const root = path.resolve(__dirname, '..');
const review = path.join(root, 'docs/reference/door-redesign/seal-v1');
const kit = path.join(root, 'assets/dungeon/isometric-kit');
const read = file => JSON.parse(fs.readFileSync(file));

async function main() {
  const {atlas} = read(path.join(kit, 'catalog.json'));
  const tres = fs.readFileSync(path.join(kit, 'catalog.tres'), 'utf8');
  const frame = read(path.join(review, 'v16-segmental-frame/parts.json'));
  const hinge = read(path.join(review, 'v17-door-materials/hinges.json')).parts;
  const page = 'res://assets/dungeon/isometric-kit/open-doors/atlas-256.png';
  const installed = await sharp(path.join(kit, 'open-doors/atlas-256.png')).raw().toBuffer({resolveWithObject:true});
  const entries = JSON.parse(tres.match(/^entries = (.+)$/m)[1]);
  const textures = new Map([...tres.matchAll(/"(door-[\w-]+)": SubResource\("([^"]+)"\)/g)].map(m => [m[1], m[2]]));
  const pageId = tres.match(/path="res:\/\/assets\/dungeon\/isometric-kit\/open-doors\/atlas-256\.png" id="([^"]+)"/)[1];
  const regions = new Set(), checked = new Set();
  let maxError = 0;

  async function verify(id, file, meta, role) {
    const entry = atlas.regions[id];
    assert(entry, 'Missing production ID ' + id);
    assert.deepEqual(entries[id], entry, id + ' Godot resource metadata');
    assert.deepEqual(entry.offset, meta.offset, id + ' offset');
    assert.deepEqual(entry.size, meta.size, id + ' size');
    assert.deepEqual(entry.bounds, meta.bounds, id + ' bounds');
    assert.equal(entry.door_part, role, id + ' role');
    assert.equal(entry.atlas_path, page, id + ' page');
    assert(!('wall_junction' in entry), id + ' must sit on the intact wall');
    const [x,y,w,h] = entry.region;
    assert.deepEqual([w,h], meta.size, id + ' native raster density');
    assert(tres.includes(`id="${textures.get(id)}"]\natlas = ExtResource("${pageId}")\nregion = Rect2(${entry.region.join(', ')})\nfilter_clip = true`), id + ' Godot texture region');
    const rgba = await sharp(path.join(review, 'v17-door-materials/parts', file)).ensureAlpha().raw().toBuffer({resolveWithObject:true});
    assert.deepEqual([rgba.info.width,rgba.info.height], meta.size, file);
    assert(installed.info.channels === 4 && x >= 4 && y >= 4 && x+w+4 <= installed.info.width && y+h+4 <= installed.info.height, id + ' padded atlas bounds');
    for (let j=0; j<h; j++) for (let i=0; i<w; i++) {
      const a = ((y+j)*installed.info.width+x+i)*4, b = (j*w+i)*4;
      const alpha = rgba.data[b+3];
      assert.equal(installed.data[a+3], alpha, id + ' alpha');
      for (let c=0; c<3; c++) maxError = Math.max(maxError, Math.abs(installed.data[a+c]-rgba.data[b+c])*alpha/255);
    }
    assert(maxError <= 1, id + ' differs from reviewed paint');
    regions.add(entry.region.join(','));
    checked.add(id);
  }

  for (const dir of ['north','east','south','west']) {
    const prefix = 'door-' + dir + '-';
    for (const [suffix,role] of [['leaf','jamb-left'], ['jamb-right','jamb-right'], ['arch','crown']]) {
      for (const state of ['', 'open-']) {
        const id = prefix + state + suffix;
        await verify(id, dir+'-'+suffix+'.png', frame[prefix+suffix], role);
        if (state) assert.deepEqual(atlas.regions[id].region, atlas.regions[prefix+suffix].region, id + ' shares frame pixels');
      }
    }
    assert.deepEqual(atlas.regions[prefix+'leaf'].companions, [prefix+'jamb-right', prefix+'panel']);
    assert.deepEqual(atlas.regions[prefix+'open-leaf'].companions, [prefix+'open-jamb-right']);
    for (const material of ['wood','arcane','iron','grille']) {
      const id = prefix + (material === 'wood' ? '' : material+'-') + 'panel';
      await verify(id, material+'-'+dir+'-panel.png', frame[prefix+'panel'], 'panel');
      if (material === 'grille') continue;
      for (const side of ['left','right']) {
        const suffix = 'panel-' + side;
        await verify(prefix+material+'-'+suffix, material+'-'+dir+'-'+suffix+'.png', hinge[prefix+suffix], 'panel');
      }
    }
  }
  assert.deepEqual([...checked].sort(), Object.keys(atlas.regions).filter(id=>id.startsWith('door-')).sort());
  assert.equal(regions.size, 48, 'deduplicate both copies of each post and open frames');
  console.log(`${checked.size} door IDs, ${regions.size} unique atlas regions, maximum premultiplied channel difference ${maxError.toFixed(3)}`);
}
main().catch(error => { console.error(error); process.exitCode = 1; });
