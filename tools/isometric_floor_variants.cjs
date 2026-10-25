// B layout adaptation: complete stones and approved calm material, painted
// offline. Shared crossing stones make every pair of variants compatible.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs'),Stone=require('./isometric_stone_paint.cjs');
const ROOT='docs/reference/isometric-floor-variation-review/v1',OUT=ROOT+'/integration';
const referenceFiles=[ROOT+'/selection.json',ROOT+'/source/b-formats-varies.png'];
const {writeGeneratedFile}=require('./write_generated_file.cjs');
const save=(file,data)=>writeGeneratedFile(path.join(P.ROOT,OUT,file),data);
const json=(file,data)=>save(file,JSON.stringify(data,null,2)+'\n');
const rounded=n=>+n.toFixed(9);
const edgeKey=e=>[e.a,e.b].map(p=>p.map(rounded).join(',')).sort().join('|');
const rect=(x,X,y,Y,seed)=>({rect:[x,X,y,Y],seed});

function rectangles(variant){
 const result=[];
 // A complete periodic course crosses north/south. Corner stones also cross
 // east/west; every duplicate uses the same shape, material UV and bevel seed.
 for(const y of [-.16,.84]){
  for(const x of [0,1])result.push(rect(x-.15,x+.18,y,y+.32,100));
  result.push(rect(.18,.52,y,y+.32,101),rect(.52,.85,y,y+.32,102));
 }
 // Staggered east/west crossing stones: there is no joint at a logical border.
 for(const x of [0,1])result.push(rect(x-.16,x+.16,.16,.50,110),rect(x-.08,x+.28,.50,.84,111));
 const add=(x,X,y,Y)=>result.push(rect(x,X,y,Y,200+variant*20+result.length));
 const row=(cuts,y,Y)=>cuts.slice(1).forEach((X,i)=>add(cuts[i],X,y,Y));
 if(variant===1){row([.16,.53,.84],.16,.50);row([.28,.62,.92],.50,.84);}
 else if(variant===2){row([.16,.66,.84],.16,.50);row([.28,.47,.92],.50,.84);}
 else if(variant===3){
  add(.44,.72,.16,.84);
  add(.16,.44,.16,.50);add(.72,.84,.16,.50);
  add(.28,.44,.50,.84);add(.72,.92,.50,.84);
 } else if(variant===4){
  add(.28,.84,.38,.62);
  add(.16,.28,.16,.50);add(.84,.92,.50,.84);
  row([.28,.57,.84],.16,.38);row([.28,.50,.84],.62,.84);
 } else throw Error('Unknown floor arrangement '+variant);
 return result;
}
const points=({rect:[x,X,y,Y]})=>[[x,y,0],[X,y,0],[X,Y,0],[x,Y,0]];
function geometry(variant){
 const stones=rectangles(variant),edges=new Map(),fullEdges=new Map();
 for(const stone of stones){
  const ps=points(stone);
  ps.forEach((a,i)=>{
   const b=ps[(i+1)%4],axis=a[0]===b[0]?1:0,other=1-axis;
   const complete={a,b,kind:'floor'};fullEdges.set(edgeKey(complete),complete);
   if(a[other]<0||a[other]>1||Math.max(a[axis],b[axis])<0||Math.min(a[axis],b[axis])>1)return;
   const p=a.map(v=>Math.max(0,Math.min(1,v))),q=b.map(v=>Math.max(0,Math.min(1,v)));
   if(Math.hypot(...p.map((v,j)=>v-q[j]))<1e-8)return;
   const e={a:p,b:q,kind:'floor'};edges.set(edgeKey(e),e);
  });
 }
 const base=structuredClone(P.models.find(m=>m.id==='floor'));
 base.visibleEdges=[...edges.values()];base.edges=base.visibleEdges;
 return {variant,stones,model:base,fullEdges:[...fullEdges.values()]};
}
function checkGeometry(models){
 for(const {variant,stones} of models){
  let area=0;
  for(let i=0;i<stones.length;i++){
   const [x,X,y,Y]=stones[i].rect;
   area+=Math.max(0,Math.min(1,X)-Math.max(0,x))*Math.max(0,Math.min(1,Y)-Math.max(0,y));
   for(let j=0;j<i;j++){
    const [a,A,b,B]=stones[j].rect;
    if(Math.min(1,X,A)-Math.max(0,x,a)>1e-8&&Math.min(1,Y,B)-Math.max(0,y,b)>1e-8)throw Error('Overlapping floor stones B'+variant);
   }
  }
  if(Math.abs(area-1)>1e-8)throw Error('Incomplete floor coverage B'+variant+': '+area);
 }
 // Entire complete-stone definitions, not sparse visual probes, must match
 // in a boundary strip wider than the existing colour/filter guard.
 const strip=(stones,axis,at,shift)=>stones.filter(s=>s.rect[axis*2]<at+.06&&s.rect[axis*2+1]>at-.06)
  .map(s=>({rect:s.rect.map((v,i)=>rounded(v-(Math.floor(i/2)===axis?shift:0))),seed:s.seed}))
  .sort((a,b)=>JSON.stringify(a).localeCompare(JSON.stringify(b)));
 for(const a of models)for(const b of models)for(const axis of [0,1]){
  const lhs=strip(a.stones,axis,1,1),rhs=strip(b.stones,axis,0,0);
  if(JSON.stringify(lhs)!==JSON.stringify(rhs))throw Error(`Incompatible boundary B${a.variant}/B${b.variant} axis${axis}`);
 }
 return {arrangements:models.length,fullAreaPerCell:1,compatibleDirectedPairs:models.length**2*2,boundaryStrip:.06};
}
function face(stone){
 const ps=points(stone);
 return {points:ps.map(P.project),p:ps.reduce((s,p)=>s.map((v,i)=>v+p[i]/4),[0,0,0]),normal:[0,0,1],
  kind:'floor',part:'floor',materialId:'floors-calm',bevelSeed:stone.seed,textureTransform:P.textureTransform(ps,[0,0,1])};
}
async function preparedFloorVariants(){
 const selection=JSON.parse(fs.readFileSync(path.join(P.ROOT,ROOT,'selection.json'),'utf8'));
 if(selection.selected.length!==1||selection.selected[0].id!=='B')throw Error('Floor B is not selected');
 for(const [file,hash] of Object.entries(selection.reviewedFiles))if(P.hash(file)!==hash)throw Error('Selected floor reference changed: '+file);
 const models=[1,2,3,4].map(geometry),checks=checkGeometry(models),items=[];
 const base=await Stone.architecture(P.models.find(m=>m.id==='floor'));
 const alpha=await sharp(base.png).extractChannel('alpha').raw().toBuffer();
 for(const m of models){
  // Lanczos downsampling sees beyond a 2px alpha guard. Paint a wider colour
  // neighbourhood first, then crop and apply the unchanged geometric alpha.
  // The same stone now has identical RGB on both sides, even in filter gutters.
  const item=await Stone.paint(m.model,{faces:m.stones.map(face),edges:m.fullEdges,floorGuard:6});
  const colour=await sharp(item.png).extract({left:base.frame[0]-item.frame[0],top:base.frame[1]-item.frame[1],width:base.frame[2],height:base.frame[3]})
   .ensureAlpha().raw().toBuffer({resolveWithObject:true});
  for(let i=0;i<alpha.length;i++)colour.data[i*4+3]=alpha[i];
  item.png=await sharp(colour.data,{raw:{width:colour.info.width,height:colour.info.height,channels:4}}).png().toBuffer();
  item.frame=base.frame;
  Object.assign(item.report,{temporaryColourGuard:6,filterGuardSourcePixels:2,outputFrame:item.frame,canvas:item.frame.slice(2).map(v=>v*4),alphaPolicy:'Unchanged base floor geometric alpha applied after wider colour downsampling.'});
  item.id='floor-b'+m.variant;
  item.floorVariant={family:'b',arrangement:m.variant,edgeProfile:'shared-complete-stones-v1'};
  item.adaptation='B slab-size/layout direction rebuilt in exact isometric wireframe with the unchanged calm base material. Not a pixel copy of concept PNG.';
  item.approvedSource=ROOT+'/source/b-formats-varies.png';
  const guide=`<svg xmlns="http://www.w3.org/2000/svg" width="${item.frame[2]}" height="${item.frame[3]}" viewBox="${item.frame.join(' ')}">${Stone.ink(m.model.visibleEdges)}</svg>`;
  const guidePNG=await sharp(Buffer.from(guide)).png().toBuffer();
  save('sprites/'+item.id+'.png',item.png);save('guides/'+item.id+'.svg',guide);save('guides/'+item.id+'.png',guidePNG);
  save('overlays/'+item.id+'.png',await sharp(item.png).composite([{input:guidePNG}]).png().toBuffer());
  items.push(item);
 }
 json('geometry.json',{camera:P.camera,logicalCell:[1,1],sourcePixelsPerCell:P.PX,checks,models:models.map(m=>({id:'floor-b'+m.variant,stones:m.stones,edges:m.model.visibleEdges,bounds:m.model.bounds}))});
 json('prepared.json',{adaptation:items[0].adaptation,geometryChecks:checks,items:items.map(({id,frame,bounds,floorVariant,report,png})=>({id,frame,bounds,floorVariant,report,bytes:png.length}))});
 return items;
}
module.exports={preparedFloorVariants,referenceFiles,geometry,checkGeometry};
if(require.main===module)preparedFloorVariants().then(items=>console.log(JSON.stringify({prepared:items.length,bytes:items.reduce((n,i)=>n+i.png.length,0)}))).catch(e=>{console.error(e.stack);process.exitCode=1;});
