const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),assert=require('node:assert/strict'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs');
const DIR='docs/reference/door-redesign/seal-v1/hero-fit-v10-integrated',OUT=path.join(P.ROOT,DIR);
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
async function inventory(){
 const c=JSON.parse(fs.readFileSync(path.join(P.ROOT,'assets/dungeon/isometric-kit/catalog.json'))),regions={};
 for(const[id,e]of Object.entries(c.atlas.regions)){
  const[left,top,width,height]=e.region,p=(e.atlas_path||c.atlas.pages[0].path).replace('res://','');
  const pixels=await sharp(path.join(P.ROOT,p)).extract({left,top,width,height}).ensureAlpha().raw().toBuffer();
  const{region,atlas_path,...metadata}=e;regions[id]={metadata,pixels:hash(pixels)};
 }
 return{regions,pages:c.atlas.pages,rgba:c.atlas.uncompressedRGBABytes,png:c.atlas.sourceBytes};
}
async function main(){
 const now=await inventory(),baseline=path.join(OUT,'before.json');
 if(process.argv.includes('--record')){assert(!fs.existsSync(baseline));fs.writeFileSync(baseline,JSON.stringify(now,null,2));console.log('Recorded '+Object.keys(now.regions).length+' regions');return;}
 const S=require('./isometric_seal_door.cjs'),ref=JSON.parse(fs.readFileSync(path.join(OUT,'geometry.json'))),before=JSON.parse(fs.readFileSync(baseline));
 const results=[];
 for(const d of ['south','east','north','west']){
  const closed=S.geometry(d),open=S.geometry(d,true);
  assert.deepEqual(closed.faces,ref.models[d].faces.slice(0,ref.door.faces.length),'Shared kit must use approved taller door '+d);
  assert.deepEqual(open.faces,closed.faces.filter(f=>!f.kind.startsWith('leaf')),'Open keeps exact frame '+d);
  for(const state of [false,true]){
   const r=await S.paint(d,state);
   assert.deepEqual(r.parts[0].wallJunction.span,[1/3,2/3]);
   const joined=await sharp({create:{width:r.full.frame[2],height:r.full.frame[3],channels:4,background:'#0000'}}).composite(r.parts.map(p=>({input:p.png,left:p.frame[0]-r.full.frame[0],top:p.frame[1]-r.full.frame[1]}))).ensureAlpha().raw().toBuffer();
   const full=await sharp(r.full.png).ensureAlpha().raw().toBuffer();let alpha=0,color=0;
   for(let i=0;i<full.length;i+=4){alpha=Math.max(alpha,Math.abs(full[i+3]-joined[i+3]));for(let c=0;c<3;c++)color=Math.max(color,Math.abs(full[i+c]*full[i+3]-joined[i+c]*joined[i+3])/255);}
   assert(alpha<=1&&color<=1,'No split seam '+d+state);
   if(!process.argv.includes('--generator-only'))for(const part of r.parts){
    const actual=now.regions[part.id];assert.deepEqual(actual.metadata.offset,part.frame.slice(0,2));assert.deepEqual(actual.metadata.size,part.frame.slice(2));assert.deepEqual(actual.metadata.bounds,part.bounds);
   }
   if(state){
    const ray=P.raster(open,r.full.frame,1),old=P.raster(closed,r.full.frame,1);let clear=0;
    for(let y=4;y<ray.height-4;y++)for(let x=4;x<ray.width-4;x++){
     const k=y*ray.width+x,fi=old.owner[k];if(fi<0||!closed.faces[fi].kind.startsWith('leaf'))continue;
     let empty=true;for(let dy=-4;dy<=4;dy++)for(let dx=-4;dx<=4;dx++)if(ray.owner[k+dy*ray.width+dx]>=0)empty=false;
     if(empty){assert.equal(full[k*4+3],0,'Open wood residue');clear++;}
    }assert(clear>1500,'Enough clear open aperture');
   }
   results.push({direction:d,open:state,alpha,color});
  }
 }
 let nonDoor=0;for(const[id,e]of Object.entries(before.regions))if(!id.startsWith('door-')){assert.deepEqual(now.regions[id],e,'Unrelated art '+id);nonDoor++;}
 assert.deepEqual(Object.keys(now.regions).sort(),Object.keys(before.regions).sort());
 const report={nonDoor,results,rgba:now.rgba,rgbaDelta:now.rgba-before.rgba,png:now.png,pngDelta:now.png-before.png};
 fs.writeFileSync(path.join(OUT,process.argv.includes('--generator-only')?'generator-validation.json':'export-validation.json'),JSON.stringify(report,null,2));console.log(JSON.stringify(report));
}
main().catch(e=>{console.error(e.message);process.exitCode=1});
