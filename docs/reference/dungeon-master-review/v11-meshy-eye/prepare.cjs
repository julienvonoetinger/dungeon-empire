// Package whole native images; no repainting, mirroring or geometric alignment.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),assert=require('node:assert/strict'),sharp=require('sharp');
const root=__dirname,hash=b=>crypto.createHash('sha256').update(b).digest('hex');
const nativeRoot='C:/Users/A/.codex/generated_images/01a1a181-6ee9-7241-b413-6580736dc500';
const entries=[
 ['front','eye/01-front.png','exec-8c1ce648-0f35-483c-9512-9ed64b04a755.png','Face'],
 ['left','eye/02-left.png','exec-8d07c967-c227-4789-831b-633be33db602.png','Profil gauche'],
 ['back','eye/03-back.png','exec-041188ba-4999-4404-afee-0dc7efef7ae3.png','Dos'],
 ['right','eye/04-right.png','exec-612f2ce6-f706-48e4-b003-0a991fc12443.png','Profil droit'],
 ['volute','accessory/volute.png','exec-f5a57381-f367-4a35-aab3-89655eae2fd3.png','Volute — objet séparé']
];
async function main(){
 const records=[];
 const provenancePath=path.join(root,'provenance.json');
 const previous=fs.existsSync(provenancePath)?JSON.parse(fs.readFileSync(provenancePath,'utf8')):null;
 for(const [id,file,native] of entries){
  const bytes=fs.readFileSync(path.join(root,'source',id+'.png')),sha256=hash(bytes);
  // First run verifies native bytes. Later reproduction needs only the archived hashes.
  if(previous)assert.equal(sha256,previous.records.find(r=>r.id===id).sha256,'Archived source '+id);
  else assert.equal(sha256,hash(fs.readFileSync(path.join(nativeRoot,native))),'Native source '+id);
  const m=await sharp(bytes).metadata();assert(m.hasAlpha,id+' alpha');
  const {data,info}=await sharp(bytes).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  let clear=0,solid=0,edge=0,bounds=[info.width,info.height,-1,-1];
  for(let y=0;y<info.height;y++)for(let x=0;x<info.width;x++){
   const a=data[(y*info.width+x)*4+3];if(a===0)clear++;if(a>240)solid++;
   if(a>16){bounds[0]=Math.min(bounds[0],x);bounds[1]=Math.min(bounds[1],y);bounds[2]=Math.max(bounds[2],x);bounds[3]=Math.max(bounds[3],y);if(x===0||y===0||x===info.width-1||y===info.height-1)edge++;}
  }
  assert(clear>info.width*info.height*.3,id+' margins');assert(solid>info.width*info.height*.15,id+' opaque volume');
  assert.equal(edge,0,id+' unclipped');assert.equal(info.width,info.height,id+' square');
  const output=path.join(root,'meshy',file);fs.mkdirSync(path.dirname(output),{recursive:true});fs.writeFileSync(output,bytes);
  assert.equal(hash(fs.readFileSync(output)),sha256,'Byte-identical delivery');
  records.push({id,file:'meshy/'+file,native:path.join(nativeRoot,native),prompt:'source/prompt-'+id+'.txt',sha256,bytes:bytes.length,width:info.width,height:info.height,bounds,transparentPixels:clear,opaquePixels:solid,edgePixels:edge});
 }
 assert.equal(new Set(records.map(r=>r.width+'x'+r.height)).size,1,'Common canvas');
 const eye=records.slice(0,4),spread=k=>Math.max(...eye.map(r=>r.bounds[k]))-Math.min(...eye.map(r=>r.bounds[k]));
 const report={tool:'built-in ImageGen',status:'illustrated references only',records,eyeTopSpread:spread(1),eyeBottomSpread:spread(3),totalBytes:records.reduce((sum,r)=>sum+r.bytes,0),limits:'Independent illustrations, not calibrated views from a single mesh. Meshy reconstruction, part separation and animation untested.'};
 fs.writeFileSync(provenancePath,JSON.stringify(report,null,2)+'\n');
 const layers=[];
 for(let i=0;i<4;i++)layers.push({input:await sharp(path.join(root,'source',entries[i][0]+'.png')).resize(400,400).png().toBuffer(),left:i*400,top:40});
 const labels=entries.slice(0,4).map((e,i)=>`<text x="${i*400+200}" y="30">${e[3]}</text>`).join('');
 layers.push({input:Buffer.from(`<svg width="1600" height="450"><g fill="#eee9ff" font-family="Segoe UI,Arial" font-size="23" text-anchor="middle">${labels}</g></svg>`),left:0,top:0});
 await sharp({create:{width:1600,height:450,channels:4,background:'#30343e'}}).composite(layers).png().toFile(path.join(root,'four-views.png'));
 console.log(JSON.stringify({images:records.length,totalBytes:report.totalBytes,topSpread:report.eyeTopSpread,bottomSpread:report.eyeBottomSpread,validation:'native hashes, alpha, opaque coverage, margins and copies pass'}));
}
main().catch(error=>{console.error(error);process.exitCode=1;});
