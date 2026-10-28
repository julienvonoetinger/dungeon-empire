// Selected paint registered to the native socket plane; raised surfaces are
// projected separately. Periodic kit paving owns the border. Original source
// paintings remain immutable; registration is an integration adaptation.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs'),FloorVariants=require('./isometric_floor_variants.cjs');
const REVIEW='docs/reference/trap-review/v7-integrated-paint';
const selection=JSON.parse(fs.readFileSync(path.join(P.ROOT,REVIEW,'selection.json')));
const referenceFiles=[REVIEW+'/selection.json','tools/isometric_trap_registration.cjs','tools/isometric_trap_receiver.cjs',...require('./isometric_trap_receiver.cjs').referenceFiles,...Object.values(selection.sources)];
const states=['ready','triggered','spent'];
const kinds=['spike','snare','void'];
function silhouettes(kind,state){
 if(kind==='void'||kind==='spike'&&state==='spent')return [];
 if(kind==='spike'){
  const points=state==='ready'?[[334,353],[291,378],[377,379],[246,407],[334,406],[423,407],[290,433],[378,433],[334,461]]:[[975,336],[925,367],[1027,367],[875,394],[975,397],[1076,394],[925,425],[1025,425],[975,454]];
  const dx=state==='ready'?12:28,up=state==='ready'?12:48,down=state==='ready'?9:18;
  return points.map(([x,y])=>[[x,y-up],[x+dx,y+down*.5],[x,y+down],[x-dx,y+down*.5]]);
 }
 const shift=state==='ready'?0:state==='triggered'?633:1264;
 const open=[[250,280],[228,288],[206,308],[188,338],[181,365],[185,386],[204,404],[235,416],[244,432],[276,442],[323,452],[358,452],[401,443],[429,436],[443,418],[473,407],[493,387],[504,362],[495,336],[474,307],[451,287],[431,278],[445,307],[451,327],[418,324],[430,345],[400,343],[413,369],[388,375],[381,353],[361,353],[361,326],[323,326],[323,350],[300,351],[299,374],[270,370],[285,345],[252,349],[267,322],[237,330],[241,306]];
 const closed=[[340,272],[320,274],[295,292],[277,319],[264,353],[252,351],[240,360],[237,385],[246,405],[265,411],[279,430],[320,444],[324,452],[359,452],[361,445],[402,435],[423,415],[443,406],[450,386],[443,363],[429,354],[419,355],[407,320],[389,292],[363,275],[344,272],[342,285]];
 return [(state==='ready'?open:closed).map(([x,y])=>[x+shift,y])];
}
async function preparedInsetTraps(preparedFloor){
 const R=require('./isometric_trap_registration.cjs');
 for(const [file,hash] of Object.entries(selection.hashes))if(P.hash(file)!==hash)throw Error('Selected trap paint changed: '+file);
 const host=preparedFloor||(await FloorVariants.preparedFloorVariants())[0];
 const floor=await require('./isometric_trap_receiver.cjs').preparedReceiver(host);
 const base=await sharp(floor.png).ensureAlpha().raw().toBuffer();
 const items=[],report=[],frame=floor.frame;
 // All raised states share a padded frame derived from their projected XYZ.
 const models={};
 for(const kind of kinds)for(let s=0;s<3;s++)models[kind+'-'+states[s]]=R.mechanism(kind,states[s],R.registration(kind,s),silhouettes(kind,states[s]));
 const projected=Object.values(models).flatMap(m=>m.faces.flatMap(f=>f.points.map(P.project)));
 const lo=[0,1].map(i=>Math.floor(Math.min(...projected.map(p=>p[i])))-4);
 const hi=[0,1].map(i=>Math.ceil(Math.max(...projected.map(p=>p[i])))+4);
 const mechanismFrame=[...lo,...hi.map((v,i)=>v-lo[i])];
 const mechanismBounds={min:[R.enlarged(.16),R.enlarged(.16),0],max:[R.enlarged(.84),R.enlarged(.84),.40*R.FOOTPRINT_SCALE]};
 for(const kind of kinds){
  const source=selection.sources[kind];
  const painting=await sharp(path.join(P.ROOT,source)).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  for(let s=0;s<3;s++){
   const state=states[s],polys=silhouettes(kind,state),reg=R.registration(kind,s);
   const model=models[kind+'-'+state];
   const png=await R.renderFloor(kind,s,painting,polys,frame,base);
   items.push({id:`trap-${kind}-${state}-floor`,frame,bounds:{min:[0,0,0],max:[1,1,0]},png,rasterScale:.75,trap:{kind,state,layer:'floor'},approvedSource:source});
   if(kind!=='void'){
    const png=await R.renderMechanism(model,painting,polys,mechanismFrame);
    items.push({id:`trap-${kind}-${state}-mechanism`,frame:mechanismFrame,bounds:mechanismBounds,png,rasterScale:.75,trap:{kind,state,layer:'mechanism'},approvedSource:source});
   }
   report.push({kind,state,source,registration:reg,groundSquare:[R.OPEN,R.OPEN,R.OPEN+R.SPAN,R.OPEN+R.SPAN],sourceSilhouettes:polys,raisedFaces:model.faces.length,groundAnchor:[.5,.5,0],mechanismFrame,mechanismBounds});
  }
 }
 const out=path.join(P.ROOT,'docs/reference/trap-review/v12-approved-square');
 fs.mkdirSync(out,{recursive:true});
 fs.writeFileSync(path.join(out,'preparation.json'),JSON.stringify({policy:'Paint registered in the native 2:1 ground plane. Raised point facets and height-aware jaw surface are separately projected; no raised copy baked into the floor. Jaw surface is a 2.5D proxy, not a hidden-volume reconstruction. Source paintings immutable.',states:report},null,2)+'\n');
 return items;
}
module.exports={preparedInsetTraps,referenceFiles};
