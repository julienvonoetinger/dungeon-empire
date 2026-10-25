// Selected paintings stay intact. Prepare uniform-size sprites and calibrated
// floor contacts offline; Godot only places atlas regions on the common grid.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs');
const {writeGeneratedFile}=require('./write_generated_file.cjs');
const REVIEW='docs/reference/isometric-prop-review/v1',OUT=REVIEW+'/integration';
const read=p=>JSON.parse(fs.readFileSync(path.join(P.ROOT,p),'utf8').replace(/^\uFEFF/,''));
const write=(p,b)=>writeGeneratedFile(path.join(P.ROOT,p),b);
const json=(p,v)=>write(p,JSON.stringify(v,null,2)+'\n');
const project=([x,y])=>[128*(x-y),64*(x+y)];
const ground=([x,y])=>[(x+2*y)/256,(-x+2*y)/256];
const ellipse=(cx,cy,rx,ry)=>Array.from({length:32},(_,i)=>[cx+rx*Math.cos(i*Math.PI/16),cy+ry*Math.sin(i*Math.PI/16)]);
// Visible lower edges measured on the selected originals. Hidden rear contacts
// are placement proxies, not recovered 3D meshes. No artwork is warped to them.
const fits=[
 {key:'a-cristaux',id:'prop-crystals',anchor:[710,754],foot:[[456,749],[534,787],[706,857],[871,801],[973,751],[888,697],[706,650],[532,696]]},
 {key:'b-idole',id:'prop-idol',anchor:[701,800],foot:[[455,789],[701,922],[946,802],[703,677]]},
 {key:'c-stele',id:'prop-stele',anchor:[660,875],foot:[[370,872],[707,1042],[947,875],[610,708]]},
 {key:'d-vasque',id:'prop-basin',anchor:[788,635],foot:[[514,708],[555,739],[635,701],[941,739],[1035,706],[790,510]]},
 {key:'e-grimoire',id:'prop-grimoire',anchor:[746,633],foot:[[313,613],[792,894],[1180,650],[702,370]]},
 {key:'f-cierges',id:'prop-candles',anchor:[656,880],foot:ellipse(656,880,350,130),emission:[650,480]}
];
const polygon=points=>points.map(p=>p.join(',')).join(' ');
async function shadow(fit,foot){
 const direction=[.055,.025]; // Short ambient cast, away from upper-left paint.
 const screen=foot.map(project),shift=project(direction);
 const all=screen.concat(screen.map(p=>[p[0]+shift[0],p[1]+shift[1]]));
 const lo=[0,1].map(c=>Math.floor(Math.min(...all.map(p=>p[c]))-12));
 const hi=[0,1].map(c=>Math.ceil(Math.max(...all.map(p=>p[c]))+12));
 const frame=[...lo,hi[0]-lo[0],hi[1]-lo[1]],[x,y,w,h]=frame;
 const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}"><defs><filter id="soft" x="-100%" y="-100%" width="300%" height="300%"><feGaussianBlur stdDeviation="2.4"/></filter><filter id="contact" x="-100%" y="-100%" width="300%" height="300%"><feGaussianBlur stdDeviation=".8"/></filter></defs><g transform="translate(${-x} ${-y})"><polygon points="${polygon(screen)}" transform="translate(${shift.join(' ')})" fill="#030811" opacity=".22" filter="url(#soft)"/><polygon points="${polygon(screen)}" fill="#030811" opacity=".30" filter="url(#contact)"/></g></svg>`;
 const png=await sharp(Buffer.from(svg)).png().toBuffer();
 const corners=[[x,y],[x+w,y],[x+w,y+h],[x,y+h]].map(ground);
 return {id:fit.id+'-shadow',png,rasterScale:.5,frame,
  bounds:{min:[...([0,1].map(c=>Math.min(...corners.map(p=>p[c])))),0],max:[...([0,1].map(c=>Math.max(...corners.map(p=>p[c])))),0]},
  groundEffect:true,groundBlend:'mix',adaptation:{footprint:foot,castWorld:direction,contactSoftness:.8,castSoftness:2.4,kind:'short static ambient contact; not a dynamic light simulation'}};
}
async function preparedRitualProps(){
 const selection=read(REVIEW+'/selection.json'),review=read(REVIEW+'/validation.json');
 if(selection.selected.length!==6)throw Error('All six props must be selected');
 for(const [file,expected] of Object.entries(selection.reviewedFiles))if(P.hash(file)!==expected)throw Error('Selected prop reference changed: '+file);
 const items=[];
 for(const fit of fits){
  const source=review.entries.find(e=>e.id===fit.key);if(!source)throw Error('Missing selected source');
  const {crop,solidBounds}=source.inspection;
  const target=source.gameHeight/.75;
  const width=Math.round(crop.width*target/solidBounds.height);
  const resized=await sharp(path.join(P.ROOT,source.file)).extract(crop).resize({width}).png().toBuffer();
  const meta=await sharp(resized).metadata(),ratio=width/crop.width;
  const png=await sharp(resized).extend({top:2,bottom:2,left:2,right:2,background:'#00000000'}).png().toBuffer();
  const offset=[(crop.left-fit.anchor[0])*ratio-2,(crop.top-fit.anchor[1])*ratio-2];
  const frame=[...offset,meta.width+4,meta.height+4];
  const foot=fit.foot.map(p=>ground([(p[0]-fit.anchor[0])*ratio,(p[1]-fit.anchor[1])*ratio]));
  const height=(fit.anchor[1]-solidBounds.top)*ratio/(256*Math.sqrt(3/8));
  const bounds={min:[Math.min(...foot.map(p=>p[0]))-.018,Math.min(...foot.map(p=>p[1]))-.018,0],max:[Math.max(...foot.map(p=>p[0]))+.018,Math.max(...foot.map(p=>p[1]))+.018,height]};
  const effect=await shadow(fit,foot);
  const item={id:fit.id,png,rasterScale:.75,frame,bounds,groundEffects:[effect.id],approvedSource:source.file,
   decoration:{source:source.id,label:source.label,footprint:foot,gameHeight:source.gameHeight},
   adaptation:{sourceScale:ratio,sourceCrop:crop,sourceAnchor:fit.anchor,sourceFoot:fit.foot,policy:'one uniform source scale, native alpha, no rotation/mirroring/repainting',support:'source-space foot proxy inverted through common ground projection'}};
  if(fit.emission)item.light={emission:fit.emission.map((v,i)=>(v-fit.anchor[i])*ratio),radius:110,energy:.65,color:[1,.55,.20]};
  const w=frame[2],h=frame[3];
  const box=[bounds.min.slice(0,2),[bounds.max[0],bounds.min[1]],bounds.max.slice(0,2),[bounds.min[0],bounds.max[1]]].map(project);
  const guides=`<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}"><g transform="translate(${-offset[0]} ${-offset[1]})"><polygon points="${polygon(foot.map(project))}" fill="none" stroke="#f56fe4" stroke-width="1"/><polygon points="${polygon(box)}" fill="none" stroke="#55dfb8" stroke-width=".6"/><path d="M -5,0 H 5 M 0,-5 V 5" stroke="#ffffff" fill="none"/></g></svg>`;
  write(OUT+'/guides/'+fit.id+'.svg',guides);
  write(OUT+'/guides/'+fit.id+'.png',await sharp(png).composite([{input:Buffer.from(guides)}]).png().toBuffer());
  for(const e of [item,effect]){write(OUT+'/sprites/'+e.id+'.png',e.png);items.push(e);}
 }
 json(OUT+'/prepared.json',{date:'2026-10-25',selection:REVIEW+'/selection.json',camera:P.camera,items:items.map(({png,densityPng,...rest})=>({...rest,bytes:png.length})),notes:['Selected native paintings retained; supports and contact shadows are calibrated proxies.','Sprite camera is painted, not a new reconstructed 3D object. No invented orientations.','Shadows are prepared offline, receiving-floor masking and depth order are shared with the existing kit.']});
 return items;
}
module.exports={preparedRitualProps,referenceFiles:[REVIEW+'/selection.json',REVIEW+'/validation.json',...fits.map(f=>REVIEW+'/source/'+f.key+'.png')]};
if(require.main===module)preparedRitualProps().then(items=>console.log(JSON.stringify({prepared:items.length,bytes:items.reduce((n,i)=>n+i.png.length,0)}))).catch(e=>{console.error(e.stack);process.exitCode=1;});
