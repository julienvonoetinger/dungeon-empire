// Controlled visual study: replace the material, then remove the vortex.
// Ground, anchor, geometry and shadow remain identical. Production is untouched.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs');
const Props=require('./isometric_prop_paint.cjs');
const {writeGeneratedFile}=require('./write_generated_file.cjs');
const BASE='docs/reference/isometric-review/painted-v1',OUT=BASE+'/heart-contact-diagnostic-v3';
const read=p=>fs.readFileSync(path.join(P.ROOT,p)),write=(p,b)=>writeGeneratedFile(path.join(P.ROOT,p),b);
const clamp=x=>Math.max(0,Math.min(1,x)),smooth=x=>{x=clamp(x);return x*x*(3-2*x);};
function sample(im,x,y) {
  const {data,info}=im;if(x<0||y<0||x>info.width-1||y>info.height-1)return [0,0,0,0];
  const X=Math.floor(x),Y=Math.floor(y),dx=x-X,dy=y-Y,r=[0,0,0,0];
  for(const [u,v,w] of [[0,0,(1-dx)*(1-dy)],[1,0,dx*(1-dy)],[0,1,(1-dx)*dy],[1,1,dx*dy]]) {
    const i=(Math.min(Y+v,info.height-1)*info.width+Math.min(X+u,info.width-1))*4,a=data[i+3]/255;
    r[3]+=a*w;for(let c=0;c<3;c++)r[c]+=data[i+c]*a*w;
  }
  if(r[3]>1e-8)for(let c=0;c<3;c++)r[c]/=r[3];return r;
}
async function withVortex(raw,mesh,frame,m) {
  // Same approved source, placement, spatial feather and depth condition as
  // the production compositor. This review changes only the rigid material.
  const source=Props.sources.heart;if(P.hash(source[0])!==source[1])throw Error('Heart source changed');
  const im=await sharp(read(source[0])).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  const unit=im.info.width/289,centre=P.project(m.orb.centre),scale=P.PX*m.orb.radius/54,out=Buffer.from(raw);
  for(let y=0;y<mesh.height;y++)for(let x=0;x<mesh.width;x++) {
    const k=y*mesh.width+x,i=k*4,sx=frame[0]+(x+.5)/4,sy=frame[1]+(y+.5)/4;
    const u=144.5+(sx-centre[0])/scale,v=88+(sy-centre[1])/scale;
    const topGlow=1-smooth((v-35)/30),circle=1-smooth((Math.hypot(u-144.5,v-88)-54-12*topGlow)/(3+6*topGlow));
    const neck=(1-smooth((Math.abs(u-144.5)-7)/6))*smooth((v-125)/8)*(1-smooth((v-168)/6));
    const mask=Math.max(circle,neck),z=-sy/(P.PX*-P.camera.y[2]),diff=sx*2/P.PX,p=[diff/2,-diff/2,z];
    if(mask<=0||P.dot(p,P.camera.eye)<mesh.depth[k]-1e-8)continue;
    const col=sample(im,u*unit,v*unit),a=col[3]*mask,old=out[i+3]/255,A=a+old*(1-a);
    if(A<=0)continue;
    for(let c=0;c<3;c++)out[i+c]=Math.round((col[c]*a+out[i+c]*old*(1-a))/A);out[i+3]=Math.round(A*255);
  }
  return out;
}
async function main() {
  const cat=JSON.parse(read('assets/dungeon/isometric-kit/catalog.json')),model=P.models.find(m=>m.id==='heart');
  const entry=cat.atlas.regions.heart,frame=[...entry.offset,...entry.size],mesh=P.raster(model,frame,4);
  const original=read(BASE+'/sprites/heart.png');
  const neutral=Buffer.alloc(mesh.width*mesh.height*4);
  const normals=model.faces.map(f=>P.normal(f.points));
  for(let k=0;k<mesh.owner.length;k++)if(mesh.owner[k]>=0) {
    const i=k*4,n=normals[mesh.owner[k]],c=n[2]>.7?[66,80,109]:Math.abs(n[0])>.5?[31,42,64]:[42,54,79];
    neutral[i]=c[0];neutral[i+1]=c[1];neutral[i+2]=c[2];neutral[i+3]=255;
  }
  const encode=buf=>sharp(buf,{raw:{width:mesh.width,height:mesh.height,channels:4}}).resize(frame[2],frame[3]).png().toBuffer();
  const neutralOrb=await encode(await withVortex(neutral,mesh,frame,model)),plain=await encode(neutral);
  write(OUT+'/neutral-with-vortex.png',neutralOrb);write(OUT+'/pedestal-neutral.png',plain);
  const variants=[['current','Image actuelle',original],['neutral-orb','Matière neutre, même vortex',neutralOrb],['neutral','Volume neutre seul',plain]];
  const layers=[],origin=[200,235],floor=cat.atlas.regions.floor,shadow=cat.atlas.regions['heart-shadow'];
  for(let y=-3;y<=3;y++)for(let x=-3;x<=3;x++) {
    const p=P.project([x,y,0]);layers.push({input:read(BASE+'/sprites/floor.png'),left:origin[0]+p[0]+floor.offset[0]+600,top:origin[1]+p[1]+floor.offset[1]+600});
  }
  layers.push({input:read(BASE+'/sprites/heart-shadow.png'),left:origin[0]+shadow.offset[0]+600,top:origin[1]+shadow.offset[1]+600});
  const ground=await sharp({create:{width:1800,height:1500,channels:4,background:'#0b1019'}}).composite(layers).png().toBuffer(),panels=[];
  for(const [i,[id,label,png]] of variants.entries()) {
    const full=await sharp(ground).composite([{input:png,left:origin[0]+frame[0]+600,top:origin[1]+frame[1]+600}]).png().toBuffer();
    const crop=await sharp(full).extract({left:600,top:600,width:400,height:336}).resize(300,252).png().toBuffer();
    const detail=await sharp(full).extract({left:670,top:738,width:260,height:162}).resize(390,243,{kernel:'nearest'}).png().toBuffer();
    write(OUT+'/'+id+'-game.png',crop);write(OUT+'/'+id+'-detail.png',detail);
    panels.push({input:crop,left:55+i*410,top:80},{input:detail,left:10+i*410,top:380});
  }
  const labels=variants.map((v,i)=>`<text x="${20+i*410}" y="57">${v[1]}</text>`).join('');
  const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="1230" height="650"><g font-family="Segoe UI,Arial" font-size="17" fill="#dde7f4"><text x="20" y="25">Diagnostic visuel — même géométrie, même sol, même ombre</text>${labels}<text x="20" y="356">Détail du socle — l’emplacement au sol reste identique</text></g></svg>`;
  panels.push({input:Buffer.from(svg),left:0,top:0});
  write(OUT+'/comparison.png',await sharp({create:{width:1230,height:650,channels:4,background:'#0b1019'}}).composite(panels).png().toBuffer());
  write(OUT+'/recipe.json',JSON.stringify({purpose:'Offline diagnostic, not a proposed replacement artwork',geometry:P.hash('docs/reference/isometric-review/migration-v1/geometry.json'),heart:P.hash(BASE+'/sprites/heart.png'),floor:P.hash(BASE+'/sprites/floor.png'),shadow:P.hash(BASE+'/sprites/heart-shadow.png'),anchor:[0,0,0],gameScale:.75,groundZ:0,variants:variants.map(([id,label])=>({id,label})),neutralColors:{top:[66,80,109],x:[31,42,64],y:[42,54,79]},notes:['Original image and cast shadow unchanged.','Middle panel uses the same approved vortex source, placement and depth; only rigid material differs.','Right panel removes that vortex to expose the rigid structure.','No scene lights, production change, automated tests or artistic approval.']},null,2)+'\n');
  console.log(OUT+'/comparison.png');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
