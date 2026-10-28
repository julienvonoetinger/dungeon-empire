// Freeze the approved geometry and register the generated mid-height lock art.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp'),assert=require('node:assert/strict');
const P=require('./isometric_paint_geometry.cjs'),M=require('./seal_masonry_finish.cjs'),Palette=require('./isometric_wall_palette.cjs');
const BASE='docs/reference/door-redesign/seal-v1',DIR=BASE+'/hero-fit-v12-integrated',OUT=path.join(P.ROOT,DIR);
const read=p=>JSON.parse(fs.readFileSync(path.join(P.ROOT,p)));
async function main(){
 for(const [a,b]of [['geometry.json','geometry.json'],['face-guide-magenta.png','face-guide-magenta.png']])fs.copyFileSync(path.join(P.ROOT,BASE,'hero-fit-v11-compact',a),path.join(OUT,b));
 const geometry=read(DIR+'/geometry.json'),mapping=read(BASE+'/hero-fit-v11-compact/checks.json').guide.mapping;
 fs.writeFileSync(path.join(OUT,'mapping.json'),JSON.stringify(mapping,null,2));
 const sourcePath=DIR+'/source/face-source.png',source=await sharp(path.join(P.ROOT,sourcePath)).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 assert.deepEqual([source.info.width,source.info.height],[1024,1536]);
 // Measured black keyhole contact point in the unchanged source. Uniform scale only;
 // this aligns it with Z=.32 while matching the painted feet/horn silhouette.
 const sourceLock=[512,1138],lockHeight=.32,scale=1;
 const translation=[mapping.xOrigin-sourceLock[0]*scale,mapping.zOrigin-lockHeight*mapping.scale-sourceLock[1]*scale];
 const sample=p=>{
  const x=Math.round((mapping.xOrigin+(p[0]-.5)*mapping.scale-translation[0])/scale),y=Math.round((mapping.zOrigin-p[2]*mapping.scale-translation[1])/scale);
  const i=(Math.max(0,Math.min(1535,y))*1024+Math.max(0,Math.min(1023,x)))*4;
  return Array.from(source.data.subarray(i,i+4));
 };
 const c=sample([.5,.525,lockHeight]);assert(Math.max(...c.slice(0,3))<35&&c[3]>200,'Tool contact must sample black keyhole');
 const points=geometry.door.faces.flatMap(f=>f.points.map(P.project)),lo=[0,1].map(i=>Math.floor(Math.min(...points.map(p=>p[i])))-5),hi=[0,1].map(i=>Math.ceil(Math.max(...points.map(p=>p[i])))+5);
 const frame=[...lo,hi[0]-lo[0],hi[1]-lo[1]],r=P.raster(geometry.door,frame,2),colors=[];
 for(let i=0;i<r.owner.length;i++){
  const f=geometry.door.faces[r.owner[i]];if(!f||!M.masonry(f.kind)||Math.abs(P.normal(f.points)[1])<.99)continue;
  const p=Array.from(r.xyz.subarray(i*3,i*3+3)),s=sample(p);
  if(s[3]>230&&Palette.accent(s)<.1&&p[0]>.05&&p[0]<.95)colors.push(s.slice(0,3));
 }
 const preparation={tool:'built-in image_gen.imagegen',source:sourcePath,geometry:DIR+'/geometry.json',mapping:DIR+'/mapping.json',fit:{uniformScale:scale,translation},palette:{source:Palette.profile(colors),targets:read(BASE+'/painted-v7-clean-leaf/preparation.json').palette.targets},hardware:{lockHeight,sourceLock,sourceHingeCenters:[[269,860],[269,1237]],hingeRegions:[[245,780,50,160],[245,1155,50,165]]},process:'Immutable original RGBA; uniform UV registration on approved XYZ. Existing wall grades on painted masonry fronts; shared stone material on sides/tops. Hinge steel kept in its two annotated receiver regions. Source glow is outside the XYZ silhouette and never exported.'};
 fs.writeFileSync(path.join(OUT,'preparation.json'),JSON.stringify(preparation,null,2));
 const inputs=['geometry.json','face-guide-magenta.png','mapping.json','preparation.json','source/face-source.png','source/prompt.txt','source/lock-correction-prompt.txt','source/alignment-prompt.txt'].map(p=>DIR+'/'+p);
 fs.writeFileSync(path.join(OUT,'selection.json'),JSON.stringify({date:'2026-10-28',userApproval:'2026-10-28: oui ça à l\'air beaucoup mieux (v11); earlier game and scene integration request',status:'approved-geometry-integrated-paint',geometry:preparation.geometry,preparation:DIR+'/preparation.json',mapping:preparation.mapping,painting:sourcePath,files:Object.fromEntries(inputs.map(p=>[p,P.hash(p)]))},null,2));
 console.log(JSON.stringify({lockHeight,sourceLock,keyholePixel:c,scale,translation,stoneSamples:colors.length}));
}
main().catch(e=>{console.error(e);process.exitCode=1});

