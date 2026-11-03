// Bake interchangeable painted leaves onto the approved segmental frame.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const sharp = require('sharp');
const P = require('../../../../../tools/isometric_paint_geometry.cjs');
const masonry = require('../../../../../tools/seal_masonry_finish.cjs');
const {rotations} = require('../../../../../tools/prepare_hero_scale_door.cjs');
const frame = require('../v16-segmental-frame/prepare.cjs');
const catalog = require('../v16-segmental-frame/parts.json');
const inverse = {north: rotations.north, south: rotations.south, east: rotations.west, west: rotations.east};
const root = __dirname;
const ss = 3;
const height = Math.max(...frame.profile.map(p => p[1]));
const keyZ = .32;
const orient = (faces, tr) => faces.map(f => ({...f, points:f.points.map(tr)}));

async function writeSprite(raw, box, file) {
  await sharp(raw, {raw:{width:box[2]*ss, height:box[3]*ss, channels:4}})
    .resize(box[2],box[3]).png().toFile(path.join(root,'parts',file+'.png'));
}

function crownSurfaces() {
  // One paint region per continuous surface, so the guide's sampling points
  // and internal triangle fans never turn into additional mortar joints.
  const surfaces = [];
  for (const p of frame.crown) {
    const front = p.map(([x,z]) => [x, frame.front, z]);
    const back = p.map(([x,z]) => [x, frame.back, z]);
    surfaces.push(front, back);
    let start = 0;
    for (let i = 0; i < p.length; i++) {
      const j = (i+1) % p.length, k = (i+2) % p.length;
      const a = P.sub(p[j],p[i]), b = P.sub(p[k],p[j]);
      if (j !== 0 && P.dot(a,b) > .96*Math.hypot(...a)*Math.hypot(...b)) continue;
      const chain = Array.from({length:i-start+2}, (_,n) => (start+n)%p.length);
      surfaces.push([back[start], ...chain.map(n=>front[n]), ...chain.slice(1).reverse().map(n=>back[n])]);
      start = i+1;
    }
  }
  return surfaces.map(points=>({points,kind:'crown'}));
}

async function paintStone(direction, key, box) {
  const tr = rotations[direction];
  const geometry = orient(frame.parts[key],tr);
  const material = key === 'arch' ? orient(crownSurfaces(),tr) : geometry.map(f=>({...f,kind:'stone'}));
  const mask = P.raster({faces:geometry},box,ss);
  const lookup = P.raster({faces:material},box,ss);
  const maps = await masonry.prepare({faces:material});
  const raw = Buffer.alloc(mask.owner.length*4);
  for (let i=0; i<mask.owner.length; i++) {
    if (mask.owner[i]<0) continue;
    const face = lookup.owner[i];
    assert(face>=0, 'material must cover the bevelled masonry');
    const screen = [box[0]+(i%mask.width+.5)/ss,box[1]+(Math.floor(i/mask.width)+.5)/ss];
    raw.set([...masonry.sample(maps[face],screen),255],i*4);
  }
  await writeSprite(raw,box,direction+'-'+key);
}

function splitMap(t, at, texel, last) {
  return t<at ? texel*t/at : texel+(last-texel)*(t-at)/(1-at);
}
function pixel(source, variant, x, z) {
  const u=(x-frame.innerLeft)/(frame.innerRight-frame.innerLeft), v=1-z/height;
  let px, py;
  if (variant==='grille') {
    // Cut the rods at the soffit; the sharpened lower ends stay visible.
    px=54+u*1014; py=90+v*1281;
  } else {
    px=u*(source.info.width-1);
    py=variant==='arcane' ? splitMap(v,1-.64/height,524,source.info.height-1) : v*(source.info.height-1);
  }
  const X=Math.max(0,Math.min(source.info.width-1,Math.round(px)));
  const Y=Math.max(0,Math.min(source.info.height-1,Math.round(py)));
  return (Y*source.info.width+X)*4;
}
function partlyOpen(side) {
  const left = side==='left';
  const pivot = left ? frame.innerLeft : frame.innerRight;
  const rotate = (p,sign) => {
    const a=(left?-1:1)*sign*Math.PI/3, x=p[0]-pivot, y=p[1]-.5;
    return [pivot+Math.cos(a)*x-Math.sin(a)*y,.5+Math.sin(a)*x+Math.cos(a)*y,p[2]];
  };
  const roof = frame.profile.filter(p=>left?p[0]<=.5:p[0]>=.5);
  const outline = [[roof[0][0],0],...roof,[roof.at(-1)[0],0]];
  const front=outline.map(([x,z])=>[x,.525,z]),back=outline.map(([x,z])=>[x,.475,z]);
  const faces=[{points:front,surface:'facade'},{points:back,surface:'facade'}];
  for(let i=0;i<outline.length;i++) {
    const j=(i+1)%outline.length;
    faces.push({points:[front[i],front[j],back[j],back[i]],surface:'edge'});
  }
  return {faces:orient(faces,p=>rotate(p,1)),turn:p=>rotate(p,1),undo:p=>rotate(p,-1)};
}
// The lock overlaps the meeting stile. Its whole casing is fixed to the
// active leaf; slicing a painting down the centre would split the keyhole.
async function loadPlate(id, bare) {
  const scale = (id==='iron'?.218:.19) / 1254;
  const {data,info}=await sharp(path.join(root,'source',id+'-lock.png')).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  assert(info.width===1254 && info.height===1254);
  const cx=627, cy=500, key=(cy*info.width+cx)*4;
  assert(data[key+3]>245 && Math.max(...data.subarray(key,key+3))<30,'opaque keyhole at contact');
  const x0=.5-cx*scale, x1=x0+info.width*scale;
  const z1=keyZ+cy*scale, z0=z1-info.height*scale;
  const quad=[[x0,z0],[x0,z1],[x1,z1],[x1,z0]];
  const faces=[.527,.473].map(y=>({points:quad.map(([x,z])=>[x,y,z]),surface:'lock'}));
  function sample(x,z) {
    const X=Math.min(info.width-1,Math.max(0,Math.round((x-x0)/scale)));
    const Y=Math.min(info.height-1,Math.max(0,Math.round((z1-z)/scale)));
    return (Y*info.width+X)*4;
  }
  const sx=bare.info.width/(frame.innerRight-frame.innerLeft), sz=bare.info.height/height;
  const overlay=await sharp(data,{raw:info}).resize(Math.round((x1-x0)*sx),Math.round((z1-z0)*sz),{fit:'fill'}).png().toBuffer();
  await sharp(bare.data,{raw:bare.info}).composite([{input:overlay,left:Math.round((x0-frame.innerLeft)*sx),top:Math.round((height-z1)*sz)}])
    .png().toFile(path.join(root,'source',id+'.png'));
  return {data,faces,sample};
}
function fit(faces) {
  const points=faces.flatMap(f=>f.points),screen=points.map(P.project);
  const offset=[0,1].map(i=>Math.floor(Math.min(...screen.map(p=>p[i])))-2);
  const size=[0,1].map(i=>Math.ceil(Math.max(...screen.map(p=>p[i])))+2-offset[i]);
  const bounds={min:[0,1,2].map(i=>Math.min(...points.map(p=>p[i]))),max:[0,1,2].map(i=>Math.max(...points.map(p=>p[i])))};
  return {offset,size,bounds};
}
async function paintLeaf(direction, variant, box, source, side=null, plate=null) {
  const tr=rotations[direction], inv=inverse[direction];
  const swing=side ? partlyOpen(side) : null;
  const geometry=swing ? swing.faces : frame.parts.panel, planes=[];
  if (variant==='grille') {
    // Sweep the perforated painting through the blade thickness. The edge
    // of each iron bar is visible and the corridor stays visible in the gaps.
    const face=geometry[0], depth=.022;
    for(let i=0;i<=7;i++) {
      const y=.5+depth*(i/7-.5);
      planes.push({faces:orient([{points:face.points.map(([x,,z])=>[x,y,z])}],tr),depth:P.dot(tr([.5,y,0]),P.camera.eye)});
    }
    planes.sort((a,b)=>a.depth-b.depth);
  } else {
    planes.push({faces:orient(geometry,tr)});
  }
  if(plate && side!=='left'){
    const moved=swing ? orient(plate.faces,swing.turn) : plate.faces;
    planes.push({faces:orient(moved,tr),hardware:true});
  }
  const raw=Buffer.alloc(box[2]*box[3]*ss*ss*4);
  let bodyDepth;
  for (const [planeIndex,plane] of planes.entries()) {
    const r=P.raster(plane,box,ss);
    if(planeIndex===0)bodyDepth=r.depth;
    for(let i=0;i<r.owner.length;i++){
      const face=r.owner[i];
      if(face<0 || (plane.hardware && r.depth[i]<bodyDepth[i]))continue;
      const local=inv(r.xyz.subarray(i*3,i*3+3));
      const [x,,z]=swing?swing.undo(local):local;
      const data=plane.hardware?plate.data:source.data;
      const j=plane.hardware?plate.sample(x,z):pixel(source,variant,x,z), alpha=data[j+3];
      if (!alpha) continue;
      const edge=variant==='grille' ? planeIndex!==planes.length-1 : !plane.hardware && geometry[face].surface==='edge';
      const gain=(edge?.64:1)*(['west','east'].includes(direction)?.88:.97);
      const k=i*4, a=alpha/255, retained=raw[k+3]/255*(1-a), combined=a+retained;
      for(let c=0;c<3;c++)raw[k+c]=Math.round((data[j+c]*gain*a+raw[k+c]*retained)/combined);
      raw[k+3]=Math.round(combined*255);
    }
  }
  await writeSprite(raw,box,variant+'-'+direction+'-panel'+(side?'-'+side:''));
  return raw;
}

async function main(){
  fs.mkdirSync(path.join(root,'parts'),{recursive:true});
  const sources={},plates={};
  for (const id of ['wood','iron','arcane','grille']) {
    const mechanical=id==='wood'||id==='iron';
    sources[id]=await sharp(path.join(root,'source',id+(mechanical?'-bare':'')+'.png')).ensureAlpha().raw().toBuffer({resolveWithObject:true});
    const {width,height:h}=sources[id].info;
    assert(width===1122 && h===1402,'measured source registration requires original canvas');
    if(mechanical)plates[id]=await loadPlate(id,sources[id]);
  }
  const hinges={};
  for(const direction of Object.keys(rotations)){
    for(const key of Object.keys(frame.parts)){
      const meta=catalog['door-'+direction+'-'+key],box=[...meta.offset,...meta.size];
      if(key!=='panel') {await paintStone(direction,key,box);continue;}
      let opaqueArea=0;
      for(const [id,source] of Object.entries(sources)){
        const raw=await paintLeaf(direction,id,box,source,null,plates[id]);
        let area=0;
        for(let i=3;i<raw.length;i+=4)area+=raw[i]/255;
        if(!opaqueArea)opaqueArea=area;
        if(id==='grille')assert(area/opaqueArea>.45 && area/opaqueArea<.85,'open space between bars');
        else assert.equal(area,opaqueArea,'solid leaves must cover the same aperture');
        if(id!=='grille')for(const side of ['left','right']) {
          const swing=partlyOpen(side);
          // Same sorting extents for all materials, including an overhanging lock case.
          const shell=side==='right' ? swing.faces.concat(orient(plates.iron.faces,swing.turn)) : swing.faces;
          const meta=fit(orient(shell,rotations[direction]));
          hinges['door-'+direction+'-panel-'+side]=meta;
          await paintLeaf(direction,id,[...meta.offset,...meta.size],source,side,plates[id]);
        }
      }
    }
  }
  fs.writeFileSync(path.join(root,'hinges.json'),JSON.stringify({parts:hinges},null,2)+'\n');
  console.log('Shared arch, four closed types, separate left/right hinged leaves in four orientations. Keyholes and grille coverage verified.');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
