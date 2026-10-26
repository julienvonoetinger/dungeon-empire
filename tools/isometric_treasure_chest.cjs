// Prepare the accepted painting; never repaint or project its image pixels.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs');
const {preparedPropShadow}=require('./isometric_ritual_props.cjs');
const {writeGeneratedFile}=require('./write_generated_file.cjs');
const REVIEW='docs/reference/treasure-chest-review/v2',OUT='docs/reference/treasure-chest-review/v4-directions';
const SOURCE=REVIEW+'/source/chest-ritual-v1.png',SELECTION=REVIEW+'/selection.json';
const FIT_FILE='tools/chest_direction_sources.json';
const config=require('./chest_direction_sources.json');
const write=(p,b)=>writeGeneratedFile(path.join(P.ROOT,p),b);
const ground=([x,y])=>[(x+2*y)/256,(-x+2*y)/256];
const project=([x,y])=>[128*(x-y),64*(x+y)];
const polygon=p=>p.map(v=>v.join(',')).join(' ');
// Visible lower corners from the original; back corner is a hidden support proxy.
// This describes contact/ordering, not a reconstructed mesh or image deformation.
const fits=config.items;

async function preparedTreasureChest(){
 const selection=JSON.parse(fs.readFileSync(path.join(P.ROOT,SELECTION),'utf8'));
 if(selection.selected.id!=='ritual-chest-closed'||selection.selected.file!==SOURCE)throw Error('Ritual chest is not selected');
 for(const [file,expected] of Object.entries(selection.reviewedFiles))if(P.hash(file)!==expected)throw Error('Selected chest changed: '+file);
 for(const fit of fits)if(P.hash(fit.source)!==fit.sha256)throw Error('Chest direction source changed: '+fit.source);
 const items=[];
 for(const fit of fits){
 const {anchor:ANCHOR,foot:FOOT,source}=fit;
 const {data,info}=await sharp(path.join(P.ROOT,source)).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 const b=[info.width,info.height,-1,-1],body=[...b];
 for(let y=0;y<info.height;y++)for(let x=0;x<info.width;x++){
  const a=data[(y*info.width+x)*4+3];
  for(const [threshold,box] of [[1,b],[128,body]])if(a>=threshold){box[0]=Math.min(box[0],x);box[1]=Math.min(box[1],y);box[2]=Math.max(box[2],x);box[3]=Math.max(box[3],y);}
 }
 if(body[2]<0||b[0]===0&&b[1]===0&&b[2]===info.width-1&&b[3]===info.height-1)throw Error('Expected native-alpha chest silhouette');
 const crop={left:b[0],top:b[1],width:b[2]-b[0]+1,height:b[3]-b[1]+1};
 const target=config.gameBodyWidth/config.cameraZoom;
 const width=Math.round(crop.width*target/(body[2]-body[0]+1)),ratio=width/crop.width;
 const resized=await sharp(path.join(P.ROOT,source)).extract(crop).resize({width}).png().toBuffer();
 const meta=await sharp(resized).metadata();
 const png=await sharp(resized).extend({top:2,bottom:2,left:2,right:2,background:'#00000000'}).png().toBuffer();
 const offset=[(crop.left-ANCHOR[0])*ratio-2,(crop.top-ANCHOR[1])*ratio-2];
 const frame=[...offset,meta.width+4,meta.height+4];
 const foot=FOOT.map(p=>ground(p.map((v,i)=>(v-ANCHOR[i])*ratio)));
 const bounds={min:[...([0,1].map(c=>Math.min(...foot.map(p=>p[c]))-.018)),0],max:[...([0,1].map(c=>Math.max(...foot.map(p=>p[c]))+.018)),(ANCHOR[1]-body[1])*ratio/(256*Math.sqrt(3/8))]};
 const effect=await preparedPropShadow({...fit,shadowScale:config.gameBodyWidth/selection.selected.reviewedGameBodyWidth},foot);
 const item={id:fit.id,png,rasterScale:.75,frame,bounds,groundEffects:[effect.id],...(fit.accepted?{approvedSource:source}:{requestedSource:source}),
  decoration:{source:fit.id,label:fit.state==='closed'?'Coffre verrouillé':'Coffre ouvert',footprint:foot,gameBodyWidth:config.gameBodyWidth,chest_state:fit.state,facing:fit.facing},
  adaptation:{sourceScale:ratio,sourceCrop:crop,sourceAnchor:ANCHOR,sourceFoot:FOOT,policy:'One uniform source scale; preserve native alpha, no rotation, mirroring or repainting',support:'Calibrated source-space contact proxy inverted through the common 2:1 ground projection'}};
 const guides=`<svg xmlns="http://www.w3.org/2000/svg" width="${frame[2]}" height="${frame[3]}"><g transform="translate(${-offset[0]} ${-offset[1]})"><polygon points="${polygon(foot.map(project))}" fill="none" stroke="#f56fe4" stroke-width="1"/><path d="M -5,0 H 5 M 0,-5 V 5" stroke="#ffffff"/></g></svg>`;
 write(OUT+'/guides/'+fit.id+'.svg',guides);
 write(OUT+'/guides/'+fit.id+'.png',await sharp(png).composite([{input:Buffer.from(guides)}]).png().toBuffer());
 for(const e of [item,effect]){write(OUT+'/sprites/'+e.id+'.png',e.png);items.push(e);}
 }
 write(OUT+'/prepared.json',JSON.stringify({date:'2026-10-25',selection:SELECTION,sourceHashes:Object.fromEntries(fits.map(f=>[f.source,P.hash(f.source)])),camera:P.camera,items:items.map(({png,...rest})=>({...rest,bytes:png.length})),notes:['Original closed south art preserved. New directions and open lock correction requested; appearance subject to feedback. Original chevron retained by explicit user clarification.','Body72px at .75, reduced25% from96. Native alpha and source proportions preserved.','Short static ambient cast/contact scaled with the chest. Shared floor receiver mask. No runtime light.','Support is a placement proxy, not reconstructed physical geometry.']},null,2)+'\n');
 return items;
}
module.exports={preparedTreasureChest,referenceFiles:[SELECTION,SOURCE,FIT_FILE,...fits.map(f=>f.source),OUT+'/generation-complete.json']};
if(require.main===module)preparedTreasureChest().then(items=>console.log(JSON.stringify(items.map(({id,frame,bounds,png})=>({id,frame,bounds,bytes:png.length}))))).catch(e=>{console.error(e.stack);process.exitCode=1;});
