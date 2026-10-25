// Isolated visual study. Point source belongs to the frozen vortex geometry;
// no production textures, selection files or torch behavior are changed.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs');
const OUT='docs/reference/isometric-review/painted-v1/heart-self-light-v1';
const write=(p,b)=>{const file=path.join(P.ROOT,OUT,p);fs.mkdirSync(path.dirname(file),{recursive:true});fs.writeFileSync(file,b);};
const S=3,RADIUS=1.45,CAST=.24,CONTACT=.44;
const projectGround=(p,light)=>{
  if(p[2]>=light[2])throw Error('Light must be above every rigid support vertex.');
  const t=light[2]/(light[2]-p[2]);
  return [light[0]+(p[0]-light[0])*t,light[1]+(p[1]-light[1])*t,0];
};
async function main(){
  if(process.argv.includes('--boards')){
    const panels=[['current','Actuel · sans torche'],['self-lit','Essai · lumière du cœur']];
    const overlays=panels.map(([id],i)=>({input:path.join(P.ROOT,OUT,id+'.png'),left:16+i*656,top:56}));
    const text=panels.map(([,label],i)=>`<text x="${16+i*656}" y="34">${label}</text>`).join('');
    overlays.push({input:Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="1328" height="510"><g fill="#dbe5f1" font-family="Segoe UI,Arial" font-size="19">${text}<text x="16" y="499" font-size="15">Captures Godot · même cœur, mêmes dalles et caméra .75 · proposition isolée</text></g></svg>`),left:0,top:0});
    write('comparison.png',await sharp({create:{width:1328,height:514,channels:4,background:'#0b1019'}}).composite(overlays).png().toBuffer());
    console.log(OUT+'/comparison.png');return;
  }
  const m=P.models.find(m=>m.id==='heart'),emitter=m.orb.centre;
  const samples=[emitter,...Array.from({length:8},(_,i)=>{
    const a=i*Math.PI/4,r=m.orb.radius*.7;return [emitter[0]+r*Math.cos(a),emitter[1]+r*Math.sin(a),emitter[2]];
  })];
  const vertices=m.faces.flatMap(f=>f.points),projections=samples.map(l=>m.faces.map(f=>f.points.map(p=>P.project(projectGround(p,l)))));
  const all=projections.flat(2),extent=[RADIUS*P.PX/Math.sqrt(2),RADIUS*P.PX/(2*Math.sqrt(2))];
  const lo=[0,1].map(i=>Math.floor(Math.min(-extent[i],...all.map(p=>p[i])))-12);
  const hi=[0,1].map(i=>Math.ceil(Math.max(extent[i],...all.map(p=>p[i])))+12);
  const frame=[...lo,...hi.map((v,i)=>v-lo[i])],width=frame[2]*S,height=frame[3]*S;
  const mask=async polys=>{
    const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="${frame.join(' ')}">${polys.map(p=>`<polygon points="${p.map(p=>p.join(',')).join(' ')}" fill="white"/>`).join('')}</svg>`;
    return sharp(Buffer.from(svg)).ensureAlpha().raw().toBuffer();
  };
  const coverage=new Float32Array(width*height);
  for(const polys of projections){const data=await mask(polys);for(let k=0;k<coverage.length;k++)coverage[k]+=data[k*4+3]/(255*samples.length);}
  const occlusion=Buffer.alloc(width*height*4);
  for(let k=0;k<coverage.length;k++)occlusion[k*4+3]=Math.round(coverage[k]*255);
  const soft=await sharp(occlusion,{raw:{width,height,channels:4}}).blur(2*S).raw().toBuffer();
  const footprints=m.faces.filter(f=>f.points.every(p=>Math.abs(p[2])<1e-8)).map(f=>f.points.map(P.project));
  const contact=await sharp(await mask(footprints),{raw:{width,height,channels:4}}).blur(.9*S).raw().toBuffer();
  const shade=Buffer.alloc(width*height*4),glow=Buffer.alloc(width*height*4);
  for(let y=0;y<height;y++)for(let x=0;x<width;x++){
    const k=y*width+x,i=4*k,screen=[lo[0]+(x+.5)/S,lo[1]+(y+.5)/S],p=P.ground(screen);
    const r=Math.hypot(p[0]-emitter[0],p[1]-emitter[1]),h=emitter[2];
    const edge=Math.max(0,Math.min(1,(RADIUS-r)/.35));
    const falloff=Math.pow(h*h/(r*r+h*h),1.5)*edge*edge*(3-2*edge);
    const blocked=soft[i+3]/255,a=CAST*blocked,b=CONTACT*contact[i+3]/255;
    shade[i]=5;shade[i+1]=8;shade[i+2]=17;shade[i+3]=Math.round(255*(1-(1-a)*(1-b)));
    glow[i]=123;glow[i+1]=38;glow[i+2]=220;
    glow[i+3]=Math.round(255*Math.min(1,1.3*falloff)*(1-blocked));
  }
  const entries=[];
  for(const [id,raw,blend] of [['shadow',shade,'mix'],['glow',glow,'add']]){
    const png=await sharp(raw,{raw:{width,height,channels:4}}).resize(frame[2],frame[3]).png().toBuffer();
    write(id+'.png',png);entries.push({id,file:OUT+'/'+id+'.png',frame,blend,bytes:png.length});
  }
  write('prepared.json',JSON.stringify({status:'isolated appearance proposal',emitter,emitterSource:'frozen heart.orb.centre',radiusWorld:RADIUS,areaSamples:samples,castOpacity:CAST,contactOpacity:CONTACT,glowEnergy:1.3,edgeSoftnessSourcePx:2,entries,
    geometrySHA256:P.hash('docs/reference/isometric-review/migration-v1/geometry.json'),
    unchangedSourceHashes:Object.fromEntries(['assets/dungeon/isometric-kit/atlas-256.png','assets/dungeon/isometric-kit/catalog.json','assets/dungeon/isometric-kit/catalog.tres','scripts/mobile_dungeon_renderer.gd','tools/isometric_ground_shadow.cjs'].map(p=>[p,P.hash(p)])),
    notes:['Point projection: L+(P-L)*L.z/(L.z-P.z), projected onto ground z=0.','Nine samples approximate a compact area source at the vortex centre; luminous vortex is excluded from blockers.','Violet additive floor light uses the same occlusion. Shadow darkness is an artistic ambient-occlusion approximation, not full physical illumination.','Only the ground receives these baked effects; no new point light or torch dependency.','Production remains unchanged pending appearance feedback.']},null,2)+'\n');
  console.log(JSON.stringify({out:OUT,frame,entries:entries.map(e=>({id:e.id,bytes:e.bytes}))}));
}
main().catch(e=>{console.error(e.stack);process.exitCode=1;});
