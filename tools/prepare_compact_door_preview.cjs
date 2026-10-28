// Isolated opaque wireframe surfaces; transparent outside the actual mesh.
// Review only: never writes the production kit or its catalogue.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs'),W=require('./prepare_seal_junction_wireframe.cjs');
const {OUT,rotations,edges,band}=require('./prepare_compact_door.cjs');
const read=p=>JSON.parse(fs.readFileSync(p));
const variants={before:read(path.join(OUT,'../hero-fit-v9/geometry.json')),after:read(path.join(OUT,'geometry.json'))};
const protectedPaths=['assets/dungeon/isometric-kit/catalog.json','assets/dungeon/isometric-kit/atlas-256.png','tools/isometric_seal_texture.cjs','tools/isometric_seal_door.cjs'];
async function main(){
 const preserved=Object.fromEntries(protectedPaths.map(p=>[p,P.hash(p)])),catalog={};
 fs.mkdirSync(path.join(OUT,'native-parts'),{recursive:true});
 for(const [version,source]of Object.entries(variants)){
  catalog[version]={};
  for(const [d,tr]of Object.entries(rotations))for(const open of [false,true]){
   const model=edges({faces:source.door.faces.filter(f=>!open||!f.kind.startsWith('leaf')).map(f=>({...f,points:f.points.map(tr)})),curvedStrips:[]});
   const fr=W.frame(model),r=P.raster(model,fr,3),normals=model.faces.map(f=>P.normal(f.points));
   const raw=Buffer.alloc(r.width*r.height*4);
   for(let i=0;i<r.owner.length;i++)if(r.owner[i]>=0){
    const fi=r.owner[i],n=normals[fi],leaf=model.faces[fi].kind.startsWith('leaf');
    const base=leaf?[38,43,54]:[75,86,104],light=.65+.2*n[2]+.15*Math.abs(n[1]);
    let color=base.map(v=>Math.round(v*light));
    if(leaf&&version==='after'){
     const w=Array.from(r.xyz.subarray(i*3,i*3+3));
     const inv={south:([x,y,z])=>[x,y,z],north:([x,y,z])=>[1-x,1-y,z],east:([x,y,z])=>[1-y,x,z],west:([x,y,z])=>[y,1-x,z]};
     const [x,y,z]=inv[d](w);
     if(Math.abs(y-.5)>.02&&(Math.hypot(x-.5,z-.32)<.015||Math.abs(x-.198)<.012&&[.16,.64].some(h=>Math.abs(z-h)<.026)))color=[255,201,107];
    }
    raw.set([...color,255],i*4);
   }
   const paths=P.visibleEdges(model,P.camera).map(e=>`<path d="M${P.project(e.a)}L${P.project(e.b)}"/>`).join('');
   const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="${r.width}" height="${r.height}" viewBox="${fr.join(' ')}"><g fill="none" stroke="#f472e7" stroke-width=".55" stroke-linejoin="round">${paths}</g></svg>`;
   const full=await sharp(raw,{raw:{width:r.width,height:r.height,channels:4}}).composite([{input:Buffer.from(svg)}]).raw().toBuffer();
   const buffers=[Buffer.alloc(full.length),Buffer.alloc(full.length)];
   // Split the already visible full mesh at native wall height. Rasterizing
   // each half separately would expose hidden rear surfaces at the seam.
   for(let y=0;y<r.height;y++)for(let x=0;x<r.width;x++){
    const i=y*r.width+x;if(!full[i*4+3])continue;let owner=r.owner[i],j=i;
    if(owner<0){seek:for(let dy=-2;dy<=2;dy++)for(let dx=-2;dx<=2;dx++){
     const X=x+dx,Y=y+dy;if(X<0||Y<0||X>=r.width||Y>=r.height)continue;
     const q=Y*r.width+X;if(r.owner[q]>=0){j=q;owner=r.owner[q];break seek;}
    }}
    if(owner<0)continue;
    const part=model.faces[owner].kind==='junction'||r.xyz[j*3+2]<P.H?0:1;
    full.copy(buffers[part],i*4,i*4,i*4+4);
   }
   for(let layer=0;layer<2;layer++){
    const id=`door-${d}${open?'-open':''}-${layer?'arch':'leaf'}`;
    const filename=`native-parts/${version}-${id}.png`;
    await sharp(buffers[layer],{raw:{width:r.width,height:r.height,channels:4}}).png().toFile(path.join(OUT,filename));
    const points=model.faces.filter(f=>!layer||f.kind!=='junction').flatMap(f=>band(f.points,layer?P.H:0,layer?3:P.H));
    const entry={offset:fr.slice(0,2),size:fr.slice(2),bounds:{min:[0,1,2].map(i=>Math.min(...points.map(p=>p[i]))),max:[0,1,2].map(i=>Math.max(...points.map(p=>p[i])))},file:filename};
    if(!layer)entry.wall_junction={axis:['north','south'].includes(d)?'v':'h',span:source.span};
    catalog[version][id]=entry;
   }
  }
 }
 fs.writeFileSync(path.join(OUT,'preview-catalog.json'),JSON.stringify(catalog,null,2));
 for(const[p,h]of Object.entries(preserved))if(P.hash(p)!==h)throw Error('Production changed: '+p);
 fs.writeFileSync(path.join(OUT,'production-preserved.json'),JSON.stringify(preserved,null,2));
 console.log('Prepared 32 isolated wireframe parts, production hashes unchanged.');
}
main().catch(e=>{console.error(e);process.exitCode=1});

