// Isolated texture review on the approved v6 XYZ receiver. No runtime export.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs'),M=require('./seal_masonry_finish.cjs');
const Palette=require('./isometric_wall_palette.cjs'),W=require('./prepare_seal_junction_wireframe.cjs');
const ROOT=P.ROOT,BASE='docs/reference/door-redesign/seal-v1',DIR=BASE+'/painted-v7-clean-leaf',OUT=path.join(ROOT,DIR);
const geometry=JSON.parse(fs.readFileSync(path.join(ROOT,BASE,'wireframe-v6-clean-leaf/geometry.json')));
const fitGuide=JSON.parse(fs.readFileSync(path.join(ROOT,BASE,'wireframe-v6-clean-leaf/checks.json'))).guide.mapping;
const protectedPaths=['assets/dungeon/isometric-kit/atlas-256.png','assets/dungeon/isometric-kit/catalog.json','assets/dungeon/isometric-kit/catalog.tres','assets/dungeon/isometric-kit/traps/atlas-256.png','tools/isometric_seal_door.cjs','scripts/door_wall_junction.gd','shaders/door_wall_junction.gdshader',BASE+'/wireframe-v6-clean-leaf/geometry.json',BASE+'/wireframe-v6-clean-leaf/face-guide-magenta.png',DIR+'/source/face-source.png'];
const before=Object.fromEntries(protectedPaths.map(p=>[p,P.hash(p)]));
const directionKind=n=>n[2]>.7?'top':Math.abs(n[0])>Math.abs(n[1])?'west':'north';
const inverses={south:p=>p,north:([x,y,z])=>[1-x,1-y,z],east:([x,y,z])=>[1-y,x,z],west:([x,y,z])=>[y,1-x,z]};
async function decoded(p){return sharp(path.join(ROOT,p)).ensureAlpha().raw().toBuffer({resolveWithObject:true});}
function bounds({data,info}){let x=info.width,y=info.height,X=-1,Y=-1;for(let j=0;j<info.height;j++)for(let i=0;i<info.width;i++)if(data[(j*info.width+i)*4+3]>32){x=Math.min(x,i);y=Math.min(y,j);X=Math.max(X,i);Y=Math.max(Y,j);}return [x,y,X-x+1,Y-y+1];}
function sample(image,x,y){
 const {data,info}=image;x=Math.max(0,Math.min(info.width-1,x));y=Math.max(0,Math.min(info.height-1,y));
 const X=Math.floor(x),Y=Math.floor(y),dx=x-X,dy=y-Y,c=[0,0,0,0];
 for(const [u,v,w]of [[0,0,(1-dx)*(1-dy)],[1,0,dx*(1-dy)],[0,1,(1-dx)*dy],[1,1,dx*dy]]){const k=(Math.min(Y+v,info.height-1)*info.width+Math.min(X+u,info.width-1))*4,a=data[k+3]/255;c[3]+=a*w;for(let n=0;n<3;n++)c[n]+=data[k+n]*a*w;}
 if(c[3])for(let n=0;n<3;n++)c[n]/=c[3];return c;
}
async function wallProfiles(){
 const cat=JSON.parse(fs.readFileSync(path.join(ROOT,'assets/dungeon/isometric-kit/catalog.json'))),e=cat.atlas.regions['wall-v-0'];
 const [left,top,width,height]=e.region,img=await sharp(path.join(ROOT,'assets/dungeon/isometric-kit/atlas-256.png')).extract({left,top,width,height}).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 const m=P.models.find(m=>m.id==='wall-v-0'),fr=[...e.offset,...e.size],r=P.raster(m,fr,2),colors={top:[],north:[],west:[]};
 for(let k=0;k<r.owner.length;k++){const fi=r.owner[k];if(fi<0)continue;const q=sample(img,((k%r.width)+.5)/r.width*width, (Math.floor(k/r.width)+.5)/r.height*height);if(q[3]>.99&&Palette.accent(q)<.1)colors[directionKind(P.normal(m.faces[fi].points))].push(q.slice(0,3));}
 return Object.fromEntries(Object.entries(colors).map(([kind,c])=>[kind,Palette.profile(c)]));
}
async function main(){
 const source=await decoded(DIR+'/source/face-source.png'),guide=await decoded(BASE+'/wireframe-v6-clean-leaf/face-guide-magenta.png');
 const a=bounds(source),b=bounds(guide),scale=Math.min(b[2]/a[2],b[3]/a[3]),shift=[b[0]+b[2]/2-(a[0]+a[2]/2)*scale,b[1]+b[3]-(a[1]+a[3])*scale];
 const faceSample=p=>sample(source,(fitGuide.xOrigin+(p[0]-fitGuide.xCentre)*fitGuide.scale-shift[0])/scale,(fitGuide.zOrigin-p[2]*fitGuide.scale-shift[1])/scale);
 const ref=geometry.door,refFrame=W.frame(ref),rr=P.raster(ref,refFrame,2),stoneSamples=[];
 for(let k=0;k<rr.owner.length;k++){const f=ref.faces[rr.owner[k]];if(!f||!M.masonry(f.kind)||Math.abs(P.normal(f.points)[1])<.99)continue;const c=faceSample(Array.from(rr.xyz.subarray(k*3,k*3+3)));if(c[3]>.95&&Palette.accent(c)<.1)stoneSamples.push(c.slice(0,3));}
 const originalStone=Palette.profile(stoneSamples),targetStone=await wallProfiles();
 const records=[];
 for(const d of ['south','east','north','west']){
  const inv=inverses[d],door=structuredClone(geometry.models[d]),doorCount=geometry.door.faces.length;
  // Context walls use exactly the same stone finish as the active wall kit.
  const materialModel={...door,faces:door.faces.map(f=>f.kind==='wall'?{...f,kind:'junction'}:f)},maps=await M.prepare(materialModel);
  const fr=W.frame(door),r=P.raster(door,fr,4),raw=Buffer.alloc(r.width*r.height*4),normals=door.faces.map(f=>P.normal(f.points));
  let fallback=0,sourcePixels=0;
  for(let k=0;k<r.owner.length;k++){
   const fi=r.owner[k];if(fi<0)continue;const f=door.faces[fi],world=Array.from(r.xyz.subarray(k*3,k*3+3)),p=inv(world),n=normals[fi];let rgb;
   const localNormal=fi<doorCount?P.normal(ref.faces[fi].points):[0,0,0];
   if(fi<doorCount&&Math.abs(localNormal[1])>.99){
    const c=faceSample(p);if(c[3]>.1){
     sourcePixels++;
     if(M.masonry(f.kind))rgb=Palette.grade(c,originalStone,targetStone[directionKind(n)]).slice(0,3);
     else if(f.kind.startsWith('seal'))rgb=c.slice(0,3);
     else {const factor=directionKind(n)==='west'?.60:.79;rgb=c.slice(0,3).map(v=>v*factor);}
    }else fallback++;
   }
   if(!rgb&&maps[fi])rgb=M.sample(maps[fi],P.project(world));
   if(!rgb){const q=faceSample(p);rgb=q[3]>.1?q.slice(0,3).map(v=>v*.66):[24,29,43];}
   raw.set([...rgb.map(v=>Math.round(Math.max(0,Math.min(255,v)))),255],k*4);
  }
  const png=await sharp(raw,{raw:{width:r.width,height:r.height,channels:4}}).resize(fr[2],fr[3]).png().toBuffer();
  fs.writeFileSync(path.join(OUT,`door-${d}.png`),png);
  const large=await sharp(png).resize(fr[2]*3,fr[3]*3).png().toBuffer();fs.writeFileSync(path.join(OUT,`door-${d}-detail.png`),large);
  const wire=await W.render(door,fr,3,{magenta:true});fs.writeFileSync(path.join(OUT,`guide-${d}.png`),wire);
  records.push({direction:d,frame:fr,sourcePixels,fallback,faceCount:door.faces.length,leafFaces:door.faces.filter(f=>f.kind==='leaf').length});
 }
 const title=Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="1400" height="900"><rect width="1400" height="900" fill="#0b101a"/><g font-family="Segoe UI,sans-serif" fill="#e3e6ef"><text x="34" y="44" font-size="28">Porte — texture sur le wireframe validé</text><text x="34" y="78" font-size="17" fill="#bfc7d5">Pierre assortie aux murs · bois prune · ferrures et sceau uniquement peints sur le battant</text><text x="34" y="119" font-size="19">Vue A</text><text x="715" y="119" font-size="19">Vue B</text><text x="34" y="646" font-size="19">Échelle de jeu (.75) — vérification de la lisibilité</text><text x="34" y="873" font-size="15" fill="#bfc7d5">Aperçus calculés sur la géométrie 2:1 · nouvelle peinture en revue, pas encore intégrée au jeu</text></g></svg>`);
 const layers=[{input:title,left:0,top:0}];
 for(const [i,d]of ['south','east'].entries())layers.push({input:await sharp(path.join(OUT,`door-${d}.png`)).resize({width:630,height:470,fit:'inside'}).png().toBuffer(),left:34+680*i,top:140});
 for(const [i,r]of records.entries()){const [w,h]=r.frame.slice(2).map(v=>Math.round(v*.75));layers.push({input:await sharp(path.join(OUT,`door-${r.direction}.png`)).resize(w,h).png().toBuffer(),left:44+i*340,top:672});}
 await sharp({create:{width:1400,height:900,channels:4,background:'#0b101a'}}).composite(layers).png().toFile(path.join(OUT,'painted-board.png'));
 const fit={sourceBounds:a,guideBounds:b,uniformScale:scale,translation:shift,relativeAspectDifference:(a[2]/a[3])/(b[2]/b[3])-1};
 fs.writeFileSync(path.join(OUT,'preparation.json'),JSON.stringify({tool:'built-in image_gen.imagegen',source:'source/face-source.png',guide:BASE+'/wireframe-v6-clean-leaf/face-guide-magenta.png',approvedGeometry:BASE+'/wireframe-v6-clean-leaf/geometry.json',approval:'2026-10-27: ok maintenant crée la texture correspondante',fit,records,palette:{source:originalStone,targets:targetStone},process:'Immutable original generated RGBA. Uniform image registration; XYZ UV sampling on approved smooth leaf and masonry front. Generated stone front graded with existing wall palette transfer; side/top stone uses existing shared B material. No modelled leaf hardware.',limits:'Offline context preview, not a native Godot capture. Generated painting approximates the guide; prepared silhouettes and projection derive from approved XYZ. No new gameplay/export change.'},null,2));
 for(const [p,h]of Object.entries(before))assert.equal(P.hash(p),h,'Source/runtime modified: '+p);
 fs.writeFileSync(path.join(OUT,'protected-hashes.json'),JSON.stringify(before,null,2));
 fs.writeFileSync(path.join(OUT,'index.html'),`<!doctype html><html lang="fr"><meta charset="utf-8"><title>Porte — texture et aperçu isométrique</title><style>body{margin:24px;background:#0b101a;color:#e3e6ef;font:17px system-ui}main{max-width:1400px;margin:auto}img{max-width:100%;height:auto}a{color:#d5b4fa}p{max-width:1050px;line-height:1.6}.source{width:520px}</style><main><h1>Texture de la porte</h1><p>Peinture créée à partir du guide magenta validé. Les détails du battant sont dans l’image ; sa géométrie reste lisse. Les pieds rejoignent les murs sur leurs joints. Ces aperçus utilisent la projection exacte du kit et le matériau de pierre des murs pour les côtés et dessus.</p><a href="painted-board.png"><img src="painted-board.png" alt="Texture de porte dans deux orientations et à l'échelle du jeu"></a><h2>Peinture source et guide</h2><p>Source ImageGen originale, conservée avec sa transparence. La pierre de l’aperçu est ajustée à la palette des murs ; la peinture n’a pas encore remplacé les sprites du jeu.</p><a href="source/face-source.png"><img class="source" src="source/face-source.png" alt="Peinture frontale originale"></a><a href="../wireframe-v6-clean-leaf/face-guide-magenta.png"><img class="source" src="../wireframe-v6-clean-leaf/face-guide-magenta.png" alt="Guide magenta utilisé"></a><p><a href="source/prompt.txt">Prompt ImageGen</a> · <a href="preparation.json">Préparation et limites</a> · <a href="protected-hashes.json">Sources conservées</a></p></main>`);
 console.log(JSON.stringify({review:OUT,fit,sourceSamples:stoneSamples.length,records,protected:protectedPaths.length}));
}
main().catch(e=>{console.error(e);process.exitCode=1});
