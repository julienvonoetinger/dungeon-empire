const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs'),S=require('./isometric_seal_door.cjs');
const DIR='docs/reference/door-redesign/seal-v1/hero-fit-v14-passage',OUT=path.join(P.ROOT,DIR);
const inv={south:p=>p,north:([x,y,z])=>[1-x,1-y,z],east:([x,y,z])=>[y,1-x,z],west:([x,y,z])=>[1-y,x,z]};
async function main(){
 fs.mkdirSync(OUT,{recursive:true});const results=[],errors=[];
 for(const d of ['south','east','north','west'])for(const open of [false,true]){
  const r=await S.paint(d,open),ref=JSON.parse(fs.readFileSync(path.join(P.ROOT,'docs/reference/door-redesign/seal-v1/hero-fit-v12-integrated/geometry.json')));
  const faces=ref.models[d].faces.slice(0,ref.door.faces.length).filter(f=>!open||!f.kind.startsWith('leaf'));
  assert.deepEqual(r.model.faces,faces,'Do not change approved geometry');
  for(const p of r.parts){
   const stone=p.faces.filter(f=>!f.kind.startsWith('leaf')),wood=p.faces.filter(f=>f.kind.startsWith('leaf'));
   if(stone.length&&wood.length)errors.push(p.id+': panel and stone share one sort support');
   if(!stone.length)continue;
   const points=stone.flatMap(f=>f.points.map(inv[d])),xs=points.map(p=>p[0]),zs=points.map(p=>p[2]);
   if(Math.min(...zs)<.91&&Math.min(...xs)<.3&&Math.max(...xs)>.7)errors.push(p.id+': one low support spans both sides of the passage');
  }
  const full=await sharp(r.full.png).ensureAlpha().raw().toBuffer();
  const joined=await sharp({create:{width:r.full.frame[2],height:r.full.frame[3],channels:4,background:'#0000'}}).composite(r.parts.map(p=>({input:p.png,left:p.frame[0]-r.full.frame[0],top:p.frame[1]-r.full.frame[1]}))).ensureAlpha().raw().toBuffer();
  let alpha=0,color=0;for(let i=0;i<full.length;i+=4){alpha=Math.max(alpha,Math.abs(full[i+3]-joined[i+3]));for(let c=0;c<3;c++)color=Math.max(color,Math.abs(full[i+c]*full[i+3]-joined[i+c]*joined[i+3])/255);}
  if(alpha>1||color>1)errors.push(d+open+': compositing seam '+alpha+'/'+color);
  if(!open){const before=await sharp(path.join(P.ROOT,'docs/reference/door-redesign/seal-v1/hero-fit-v13-malefic-leaf/after-'+d+'.png')).ensureAlpha().raw().toBuffer();assert(full.equals(before),'Painting must remain byte identical');}
  results.push({direction:d,open,parts:r.parts.map(p=>({id:p.id,bounds:p.bounds,role:p.doorPart})),alpha,color});
 }
 fs.writeFileSync(path.join(OUT,process.argv.includes('--before')?'before-check.json':'partition-validation.json'),JSON.stringify({results,errors},null,2));
 assert.equal(errors.length,0,errors.join('\n'));console.log('PASS: geometry and original paint retained; independent passage supports; no compositing seams');
}
main().catch(e=>{console.error(e.message);process.exitCode=1});
