// Isometric/dimetric 2:1 visual spike. All export is offline and review-only.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),sharp=require('sharp');
const {writeGeneratedFile}=require('./write_generated_file.cjs');
const {build,visibleEdges,drawing,project}=require('./prepare_ground_perspective_review.cjs');
const ROOT=path.resolve(__dirname,'..');
const OUT=path.join(ROOT,'docs/reference/isometric-review/wireframe-v1');
// Equal screen-unit scale for the two orthogonal camera basis vectors.
// A 1x1 horizontal square projects to a diamond 1 wide, .5 high.
// This is a 30-degree elevated, 45-degree azimuth orthographic camera.
const camera={x:[.5,-.5,0],y:[.25,.25,-Math.sqrt(3/8)],eye:[Math.sqrt(3/8),Math.sqrt(3/8),.5]};
const gridColor='#f18bbe';
const write=(p,data)=>writeGeneratedFile(path.join(OUT,p),data);
const fmt=n=>+n.toFixed(6);
const text=(x,y,size,value,fill='#e6edf5')=>`<text x="${x}" y="${y}" font-family="Segoe UI,Arial,sans-serif" font-size="${size}" fill="${fill}">${value}</text>`;
const svg=(w,h,body)=>`<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">${body}</svg>`;
const background=(w,h)=>`<rect width="${w}" height="${h}" fill="#0b1019"/>`;
async function save(name,w,h,body) {
  const source=svg(w,h,body);write(`${name}.svg`,source);
  write(`${name}.png`,await sharp(Buffer.from(source)).png().toBuffer());
}
function gridEdges(cells) {
  return cells.flatMap(([x,y])=>{
    const corners=[[x,y,0],[x+1,y,0],[x+1,y+1,0],[x,y+1,0]];
    return corners.map((a,i)=>({a,b:corners[(i+1)%4],kind:'floor'}));
  });
}
function strokes(edges,origin,scale,dashed=true) {
  return edges.map(e=>{
    const a=project(e.a,camera).map((v,i)=>v*scale+origin[i]);
    const b=project(e.b,camera).map((v,i)=>v*scale+origin[i]);
    return `<line x1="${fmt(a[0])}" y1="${fmt(a[1])}" x2="${fmt(b[0])}" y2="${fmt(b[1])}" stroke="${gridColor}" stroke-width="1.4" ${dashed?'stroke-dasharray="5 4"':''}/>`;
  }).join('');
}
function diagram(cells,origin,scale,labels=false) {
  let body=strokes(gridEdges(cells),origin,scale,false);
  if(labels)for(const [x,y] of cells) {
    const p=project([x+.5,y+.5,0],camera).map((v,i)=>v*scale+origin[i]);
    body+=`<text x="${fmt(p[0])}" y="${fmt(p[1]+4)}" text-anchor="middle" font-family="Segoe UI,Arial" font-size="12" fill="#b6c2d2">${x},${y}</text>`;
  }
  return body;
}
async function main() {
  const model=build();
  const edges=visibleEdges(model,camera);
  const gridModel={...model,edges:gridEdges(model.cells),curvedStrips:[]};
  const visibleGrid=visibleEdges(gridModel,camera);
  const origin=[615,192],scale=192;
  let room=drawing(model,edges,camera,origin,scale,1.4).replaceAll('#51b4c9','#498899');
  // Clip logical-grid lines behind the camera-facing vortex too.
  const o=project(model.heart.orbCentre,camera).map((v,i)=>v*scale+origin[i]);
  room+=`<defs><mask id="gridOrb"><rect width="1280" height="780" fill="white"/><circle cx="${o[0]}" cy="${o[1]}" r="${model.heart.orbRadius*scale+1}" fill="black"/></mask></defs><g mask="url(#gridOrb)">${strokes(visibleGrid,origin,scale)}</g>`;
  let body=background(1280,780)+text(30,40,26,'Piste isométrique — un repère commun');
  body+=text(30,71,16,'Même salle et mêmes dimensions logiques · grille en losanges 2:1 proposée · murs à deux rangées','#afbdd0');
  body+=room;
  body+=text(48,644,16,'Chaque losange rose représente une case 1 × 1.',gridColor);
  body+=text(48,673,15,'Le dallage, les murs, les piliers et le socle suivent les deux axes diagonaux.','#afbdd0');
  body+=text(48,702,15,'Le cœur reste un volume schématique pour cette étude de perspective.','#afbdd0');
  body+=text(48,748,14,'Proposition hors Godot ; sprites peints et scènes actives conservés.','#8395ac');
  body+=diagram([[0,0]],[1070,626],192);
  body+=text(984,741,14,'1 case : 192 × 96 px','#afbdd0');
  await save('room-grid',1280,780,body);
  await save('room',1280,780,background(1280,780)+text(30,40,26,'Wireframe isométrique — sans grille de contrôle')+drawing(model,edges,camera,origin,scale,1.4));
  await save('room-transparent',1280,780,drawing(model,edges,camera,origin,scale,1.4));

  body=background(1240,750)+text(30,40,25,'La grille logique reste identique');
  body+=text(30,71,15,'Les coordonnées et les voisins restent les mêmes. Seule leur représentation à l’écran change.','#afbdd0');
  body+=text(32,122,18,'Plan logique : cases carrées');
  const unit=70,left=55,top=173;
  for(const [x,y] of model.cells) {
    body+=`<rect x="${left+x*unit}" y="${top+y*unit}" width="${unit}" height="${unit}" fill="none" stroke="${gridColor}" stroke-width="1.2"/>`;
    body+=text(left+x*unit+22,top+y*unit+40,12,`${x},${y}`,'#b6c2d2');
  }
  body+=text(580,122,18,'Affichage isométrique : les mêmes cases');
  body+=diagram(model.cells,[885,208],110,true);
  body+=text(570,533,16,'2 axes au sol : diagonales opposées','#afbdd0');
  body+=text(570,563,16,'Hauteur : verticale à l’écran','#afbdd0');
  body+=text(570,593,16,'Couloir : toujours 1 case de large','#afbdd0');
  body+=text(32,703,15,'Rose = case de construction ; les petites dalles à l’intérieur sont uniquement le motif du sol.','#afbdd0');
  await save('logical-grid',1240,750,body);
  const hash=p=>crypto.createHash('sha256').update(fs.readFileSync(path.join(ROOT,p))).digest('hex');
  const record={status:'isometric feasibility wireframe, not a production migration or approved camera',
    reference:{url:'https://emeldalee.artstation.com/projects/4bevKn',title:'2D Casual Isometric Object pack',artist:'Jeeyoung Lee',
      observation:'Viewed terrain, masonry, stairs and editor diamond-grid screenshots using the browser.',
      ratio:'2:1 is our proposed working ratio, not a measured claim about the reference images.'},
    generator:'tools/prepare_isometric_wireframe_review.cjs',camera,
    logicalCell:[1,1],sourceDiamond:[256,128],displayDiamond:[192,96],displayZoom:.75,
    note:'Common 2:1 game isometry (dimetric). Equal-sized projected ground axes; height projects vertically. This is not an affine warp of existing PNGs.',
    mapping:'screen_px = 256 * ((x-y)/2, (x+y)/4 - sqrt(3/8)*z)',
    reuse:['logical occupancy','cardinal/diagonal neighbour rules','wall thickness and height','two brick courses','pillar geometry','offline wireframe export/hidden-edge approach'],
    laterWork:['validate screen-scale passage and foreground-wall occlusion','reproject door/stair/torch rigid geometry','adapt heart and other painted props to this viewpoint','bake new sprites and atlas','adapt placement, picking and depth ordering in Godot'],
    baselineHashes:Object.fromEntries(['assets/dungeon/mobile-kit/atlas-256.png','assets/dungeon/mobile-kit/catalog.tres','scenes/MobileReference.tscn'].map(p=>[p,hash(p)])),
    model,visibleEdges:edges,visibleGrid};
  write('geometry.json',JSON.stringify(record,null,2)+'\n');
  console.log(JSON.stringify({output:OUT,logicalCells:model.cells.length,visibleSegments:edges.length,displayDiamond:[192,96]}));
}
main().catch(error=>{console.error(error);process.exitCode=1;});
