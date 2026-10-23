// Offline vector review guides only. Never reads or alters painted images.
// Run after the cell, entrance and door exporters. Add --png to rasterize with sharp.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const root = path.resolve(__dirname, '..');
const output = 'docs/reference/wireframe-overlays';
const color = '#ff00ff';
const read = file => fs.readFileSync(path.join(root, file), 'utf8');
const json = file => JSON.parse(read(file));
const kitPath = 'assets/dungeon/wireframe-cells/catalog.json';
const kit = json(kitPath);
const {geometry}=require('./export_wireframe_cell_kit.cjs');
const px = kit.pixelsPerCell;
const round = n => Number(n.toFixed(5));
const header = size => `<svg xmlns="http://www.w3.org/2000/svg" width="${size[0]}" height="${size[1]}" viewBox="0 0 ${size.join(' ')}">`;
const content = svg => svg.replace(/^<svg[^>]*>/, '').replace(/<\/svg>\s*$/, '');
const hash = file => crypto.createHash('sha256').update(read(file)).digest('hex');
const records = {};
const renderedFiles = [];
const sourceHashes = {};
const remember = file => { sourceHashes[file] = hash(file); return read(file); };

// Copy the already-visible wall/door/stair strokes verbatim, changing only ink.
// Their source exporters have already removed hidden and internal edges.
function coloredLines(svg) {
  const lines = svg.match(/<line\b[^>]*\/>/g) || [];
  return lines.map(line => line.replace(/stroke="[^"]+"/, `stroke="${color}"`)).join('');
}

function filledPolygons(svg) {
  const polygons = [];
  for (const match of svg.matchAll(/<polygon points="([^"]+)" fill="#ffffff"\/>/g)) {
    polygons.push(match[1].trim().split(/\s+/).map(p => p.split(',').map(Number)));
  }
  // Current wall tops are unions of simple M/L/Z quadrilaterals, not curves.
  for (const match of svg.matchAll(/<path d="([^"]*)" fill="#ffffff"\/>/g)) {
    if (/[^MLZ0-9.,\s-]/.test(match[1])) throw Error('Unsupported filled wall path; update the vector guide exporter.');
    for (const part of match[1].split('M').filter(Boolean)) {
      polygons.push(part.replace(/Z$/, '').split('L').map(p => p.split(',').map(Number)));
    }
  }
  return polygons;
}

const sub = (a,b) => a.map((v,i) => v-b[i]);
const cross = (a,b) => a[0]*b[1]-a[1]*b[0];
const lerp = (a,b,t) => a.map((v,i) => v+(b[i]-v)*t);

// Exact segment / convex polygon intervals. These polygons are the existing
// white vector faces; subtract their coverage BEFORE omitting the face fills.
// This is vector hidden-line removal, never pixel/color-based image cleanup.
function coveredInterval(a,b,polygon) {
  const area = polygon.reduce((sum,p,i) => sum+cross(p,polygon[(i+1)%polygon.length]),0);
  if (Math.abs(area)<1e-9) return null;
  const sign = Math.sign(area), delta = sub(b,a);
  let low=0, high=1;
  for (let i=0;i<polygon.length;i++) {
    const p=polygon[i], edge=sub(polygon[(i+1)%polygon.length],p);
    const start=sign*cross(edge,sub(a,p)), slope=sign*cross(edge,delta);
    if (Math.abs(slope)<1e-10) { if(start < -1e-8) return null; }
    else if(slope>0) low=Math.max(low,-start/slope);
    else high=Math.min(high,-start/slope);
    if(high<=low+1e-9) return null;
  }
  return [low,high];
}

function uncovered(a,b,polygons) {
  const covered=polygons.map(p=>coveredInterval(a,b,p)).filter(Boolean).sort((p,q)=>p[0]-q[0]);
  const spans=[]; let cursor=0;
  for(const [low,high] of covered) {
    if(low>cursor+1e-8) spans.push([lerp(a,b,cursor),lerp(a,b,low)]);
    cursor=Math.max(cursor,high);
  }
  if(cursor<1-1e-8) spans.push([lerp(a,b,cursor),b]);
  return spans;
}

// Read the exact prepared floor strokes rather than inventing another pattern.
// Its current source has only axis-aligned M/H/V paths and one gutter translation.
const floorPath = 'assets/dungeon/wireframe-cells/floor.svg';
const floorSvg = remember(floorPath);
const floorEdges = [];
for(const [,d] of floorSvg.matchAll(/<path d="([^"]+)"\/>/g)) {
  const match=d.match(/^M([\d.-]+) ([\d.-]+)([HV])([\d.-]+)$/);
  if(!match) throw Error(`Unsupported floor path: ${d}`);
  const a=[Number(match[1]),Number(match[2])],b=[...a];
  b[match[3]==='H'?0:1]=Number(match[4]);
  floorEdges.push([a,b]);
}
if(!floorEdges.length) throw Error('No prepared floor strokes found.');
// The connected motif omits three borders to avoid double seams in a room.
// An isolated image needs its complete floor boundary.
floorEdges.push([[0,0],[0,px]],[[px,0],[px,px]],[[0,px],[px,px]]);

function floorLines(anchor,polygons=[]) {
  return floorEdges.flatMap(([a,b])=>uncovered(a.map((v,i)=>v+anchor[i]),b.map((v,i)=>v+anchor[i]),polygons))
    .map(([a,b])=>`<line x1="${round(a[0])}" y1="${round(a[1])}" x2="${round(b[0])}" y2="${round(b[1])}" stroke="${color}" stroke-width="1.5"/>`).join('');
}

function save(id,body,size,anchor,sources,extra={}) {
  const svg=header(size)+`<g fill="none">${body}</g></svg>\n`;
  const relative=`${output}/${id}.svg`, absolute=path.join(root,relative);
  fs.mkdirSync(path.dirname(absolute),{recursive:true});
  fs.writeFileSync(absolute,svg);
  renderedFiles.push({absolute,svg});
  records[id]={svg:`${id}.svg`,png:`${id}.png`,imageSize:size,imageAnchor:anchor,sources,...extra};
  return svg;
}

remember(kitPath);
remember('tools/export_wireframe_cell_kit.cjs');
remember(kit.source);
const previews=[];
for(const [variant,entry] of Object.entries(kit.entries)) {
  const source=`assets/dungeon/wireframe-cells/${entry.file}`;
  remember(source);
  const svg=geometry(entry.walls,entry.piers,entry.exposedEnds,{standalone:true}).svg;
  const body=floorLines(kit.wallImageAnchor,filledPolygons(svg))+coloredLines(svg);
  const guide=save(`cells/${variant}`,body,kit.wallImageSize,kit.wallImageAnchor,[floorPath,source],{variant});
  if(variant==='w09_p00_e00') {
    const original=header(kit.wallImageSize)+floorLines(kit.wallImageAnchor,filledPolygons(svg)).replaceAll(color,'#8794a3')+content(svg)+'</svg>';
    previews.push({label:'Coin supérieur gauche',original,guide,size:kit.wallImageSize});
  }
}
save('floor',floorLines(kit.floor.imageAnchor),[px+8,px+8],kit.floor.imageAnchor,[floorPath]);

const up=kit.projection.heightUp;
const project=([x,y,z],anchor)=>[x+up[0]*z,y+up[1]*z].map((v,i)=>round(v*px+anchor[i]));
function projectedLines(edges,anchor) {
  return edges.map(e=>{
    const a=project(e.a,anchor),b=project(e.b,anchor);
    const width=e.kind==='floor'?1.5:['joint','detail'].includes(e.kind)?2:3;
    return `<line x1="${a[0]}" y1="${a[1]}" x2="${b[0]}" y2="${b[1]}" stroke="${color}" stroke-width="${width}"/>`;
  }).join('');
}

// Same camera/box visibility used by the stair source, now retaining end faces.
function visibleBoxEdges(edges,boxes) {
  const direction=[-up[0],-up[1],1];
  const hidden=p=>boxes.some(([low,high])=>{
    let enter=0,exit=Infinity;
    for(let i=0;i<3;i++){
      enter=Math.max(enter,(low[i]-p[i])/direction[i]);
      exit=Math.min(exit,(high[i]-p[i])/direction[i]);
    }
    return exit>Math.max(enter,1e-8)+1e-9;
  });
  const visible=[],seen=new Set();
  for(const e of edges) {
    const key=[e.a,e.b].map(p=>p.map(round).join(',')).sort().join('|');
    if(seen.has(key))continue;seen.add(key);
    const n=240;let start=0,old=hidden(lerp(e.a,e.b,.5/n));
    const add=(low,high)=>{if(high-low>1e-7)visible.push({...e,a:lerp(e.a,e.b,low),b:lerp(e.a,e.b,high)});};
    for(let k=1;k<n;k++) {
      const next=hidden(lerp(e.a,e.b,(k+.5)/n));
      if(next===old)continue;
      let low=(k-.5)/n,high=(k+.5)/n;
      for(let j=0;j<28;j++){const mid=(low+high)/2;if(hidden(lerp(e.a,e.b,mid))===old)low=mid;else high=mid;}
      const cut=(low+high)/2;if(!old)add(start,cut);start=cut;old=next;
    }
    if(!old)add(start,1);
  }
  return visible;
}

const stairSourcePath='docs/reference/entrance-stairs-open-south-wireframe.json';
const stairSource=JSON.parse(remember(stairSourcePath));
const transforms={north:([x,y,z])=>[1-x,1-y,z],east:([x,y,z])=>[y,1-x,z],south:p=>p,west:([x,y,z])=>[1-y,x,z]};
for(const family of ['entrances','doors']) {
  const catalogPath=`assets/dungeon/wireframe-${family}/catalog.json`;
  const catalog=JSON.parse(remember(catalogPath));
  if(catalog.pixelsPerCell!==px||JSON.stringify(catalog.projection)!==JSON.stringify(kit.projection)) throw Error('Geometry contract mismatch.');
  for(const [direction,entry] of Object.entries(catalog.entries)) {
    let edges,source;
    if(family==='doors') {
      // These are exactly the complete isolated proposals approved for review,
      // not the later connected images which deliberately remove both end faces.
      source=`docs/reference/door-arch-facing-${direction}-wireframe.json`;
      edges=JSON.parse(remember(source)).visibleEdges;
    } else {
      source=stairSourcePath;
      const transform=transforms[direction];
      const boxes=stairSource.occludingVolumes.map(([a,b])=>{
        const p=transform(a),q=transform(b);
        return [p.map((v,i)=>Math.min(v,q[i])),p.map((v,i)=>Math.max(v,q[i]))];
      });
      const structure=stairSource.sourceEdges.filter(e=>e.kind!=='floor').map(e=>({...e,a:transform(e.a),b:transform(e.b)}));
      const paving=floorEdges.map(([a,b])=>({a:[a[0]/px,a[1]/px,0],b:[b[0]/px,b[1]/px,0],kind:'floor'}));
      edges=visibleBoxEdges([...structure,...paving],boxes);
    }
    const body=`<g stroke-linecap="round" stroke-linejoin="round">${projectedLines(edges,catalog.imageAnchor)}</g>`;
    const guide=save(`${family}/${direction}`,body,catalog.imageSize,catalog.imageAnchor,[source],{variant:entry.variant,direction,visibleSegmentCount:edges.length});
    if(direction==='south') previews.push({label:family==='doors'?'Porte double face':'Escalier',original:guide.replaceAll(color,'#1c2a3a'),guide,size:catalog.imageSize});
  }
}

// Standalone pier: the exact current square T x T x H volume, one horizontal
// joint, no paving or vertical masonry cuts. Its origin is its NW ground corner.
const pillarSvg=geometry(0,1,0,{standalone:true}).svg;
const pillarSize=[96,144];
const pillarGuide=save('pillar',coloredLines(pillarSvg),pillarSize,kit.wallImageAnchor,[kit.source,'tools/export_wireframe_cell_kit.cjs'],{worldBounds:[[0,0,0],[kit.wallThickness,kit.wallThickness,kit.wallHeight]],courseJoints:kit.courseJoints});
previews.push({label:'Pilier seul (échelle ×2)',original:pillarGuide.replaceAll(color,'#1c2a3a'),guide:pillarGuide,size:pillarSize,scale:2});

const manifest={id:'wireframe-control-overlays-v2-isolated',generator:'tools/export_wireframe_overlays.cjs',purpose:'Complete ISOLATED transparent guides for reviewing future painted sprites individually; not production art.',color,background:'transparent',projection:kit.projection,pixelsPerCell:px,strokeWidths:{outline:3,joints:2,floor:1.5},policy:'Include all visible end faces and floor boundaries for a piece viewed ALONE. Keep hidden lines absent. Same geometry, camera, anchors and scale as the connected kit. Use the standalone door proposals, not the connected textures. Never use these closed-end guides as the connected runtime catalogue.',sourceHashes,entries:records};
fs.writeFileSync(path.join(root,output,'catalog.json'),JSON.stringify(manifest,null,2)+'\n');

// Separate, opaque review sheet; the actual guides above have no background.
const sheetWidth=1400,sheetHeight=1040;
const panels=previews.map(({label,original,guide,size,scale=1},i)=>{
  const x=28+(i%2)*700,y=100+Math.floor(i/2)*470;
  const image=(svg,dx)=>`<g transform="translate(${x+dx} ${y+34}) scale(${scale})">${content(svg)}</g>`;
  return `<text x="${x}" y="${y}" fill="#ecf0ff" font-size="21">${label}</text><text x="${x}" y="${y+23}" fill="#aeb9ce" font-size="13">Pièce isolée complète</text><text x="${x+330}" y="${y+23}" fill="#aeb9ce" font-size="13">Calque transparent — arêtes visibles seulement</text><rect x="${x}" y="${y+34}" width="${size[0]*scale}" height="${size[1]*scale}" fill="#fff"/><rect x="${x+330}" y="${y+34}" width="${size[0]*scale}" height="${size[1]*scale}" fill="url(#checker)"/>${image(original,0)}${image(guide,330)}`;
}).join('');
const sheet=header([sheetWidth,sheetHeight])+`<defs><pattern id="checker" width="24" height="24" patternUnits="userSpaceOnUse"><rect width="24" height="24" fill="#273044"/><path d="M0 0H12V12H0Z M12 12H24V24H12Z" fill="#354058"/></pattern></defs><rect width="${sheetWidth}" height="${sheetHeight}" fill="#101522"/><g font-family="Arial,sans-serif"><text x="28" y="38" fill="#ecf0ff" font-size="26">Calques de contrôle — pièces isolées complètes</text><text x="28" y="65" fill="#aeb9ce" font-size="16">Magenta #ff00ff · fond transparent · extrémités fermées · aucune arête cachée</text>${panels}</g></svg>`;
const sheetPath=path.join(root,output,'comparison.svg');
fs.writeFileSync(sheetPath,sheet);
renderedFiles.push({absolute:sheetPath,svg:sheet});

async function main() {
  if(process.argv.includes('--png')) {
    const sharp=require('sharp');
    for(const {absolute,svg} of renderedFiles) await sharp(Buffer.from(svg)).png().toFile(absolute.replace(/\.svg$/,'.png'));
  }
  console.log(`Exported ${Object.keys(records).length} transparent magenta guides${process.argv.includes('--png')?' as SVG + RGBA PNG':' as SVG'} and one comparison sheet to ${output}.`);
}
main().catch(error=>{console.error(error);process.exitCode=1;});
