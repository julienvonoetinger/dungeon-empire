// Keep native ImageGen images unchanged in the four-view delivery pack.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),assert=require('node:assert/strict'),sharp=require('sharp');
const root=__dirname,hash=b=>crypto.createHash('sha256').update(b).digest('hex');
const views=[['front','01-front.png'],['left','02-left.png'],['back','03-back.png'],['right','04-right.png']];
async function main(){
 const records=[];
 for(const [id,file] of views){
  const bytes=fs.readFileSync(path.join(root,'source',id+'.png'));
  const metadata=await sharp(bytes).metadata();assert(metadata.hasAlpha,id+' native alpha');
  const {data,info}=await sharp(bytes).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  let clear=0,solid=0,edge=0,bounds=[info.width,info.height,-1,-1];
  for(let y=0;y<info.height;y++)for(let x=0;x<info.width;x++){
   const a=data[(y*info.width+x)*4+3];if(a===0)clear++;
   if(a>240){solid++;bounds[0]=Math.min(bounds[0],x);bounds[1]=Math.min(bounds[1],y);bounds[2]=Math.max(bounds[2],x);bounds[3]=Math.max(bounds[3],y);if(x===0||y===0||x===info.width-1||y===info.height-1)edge++;}
  }
  assert(clear>info.width*info.height*.2,id+' transparent margins');
  assert(solid>info.width*info.height*.12,id+' subject coverage');
  assert(bounds[3]-bounds[1]>info.height*.75,id+' full character');
  assert.equal(edge,0,id+' silhouette clipped');assert.equal(info.width,info.height);
  const target=path.join(root,'meshy','character',file);fs.mkdirSync(path.dirname(target),{recursive:true});fs.writeFileSync(target,bytes);
  assert.equal(hash(fs.readFileSync(target)),hash(bytes));
  records.push({id,file:'meshy/character/'+file,width:info.width,height:info.height,sha256:hash(bytes),bytes:bytes.length,solidBounds:bounds,nativeAlpha:true,byteIdenticalToSource:true});
 }
 assert.equal(new Set(records.map(r=>r.width+'x'+r.height)).size,1,'Common view canvas');
 const spread=k=>Math.max(...records.map(r=>r.solidBounds[k]))-Math.min(...records.map(r=>r.solidBounds[k]));
 const report={tool:'built-in ImageGen',status:'references-only',records,topSpreadPixels:spread(1),soleSpreadPixels:spread(3),totalPngBytes:records.reduce((s,r)=>s+r.bytes,0),limits:'Independent illustrations, not calibrated mesh renders; reconstruction and rigging untested.'};
 fs.writeFileSync(path.join(root,'validation.json'),JSON.stringify(report,null,2)+'\n');
 // Review board only: whole native images uniformly reduced, never used as Meshy input.
 const layers=[];
 for(let i=0;i<views.length;i++)layers.push({input:await sharp(path.join(root,'source',views[i][0]+'.png')).resize(440,440).png().toBuffer(),left:i*440,top:0});
 await sharp({create:{width:1760,height:440,channels:4,background:'#343843'}}).composite(layers).png().toFile(path.join(root,'four-views.png'));
 // Equal visible height for an honest species/elder comparison, review only.
 const comparison=[];
 const refs=[path.resolve(root,'../../summoner-race-review/v3-meshy-turnaround/meshy/01-front.png'),path.join(root,'source/front.png')];
 for(let i=0;i<refs.length;i++){
  const {data,info}=await sharp(refs[i]).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  let x0=info.width,y0=info.height,x1=0,y1=0;
  for(let y=0;y<info.height;y++)for(let x=0;x<info.width;x++)if(data[(y*info.width+x)*4+3]>16){x0=Math.min(x0,x);y0=Math.min(y0,y);x1=Math.max(x1,x);y1=Math.max(y1,y);}
  const png=await sharp(refs[i]).extract({left:x0,top:y0,width:x1-x0+1,height:y1-y0+1}).resize({height:540}).png().toBuffer();
  const m=await sharp(png).metadata();comparison.push({input:png,left:Math.round(i*650+(650-m.width)/2),top:85});
 }
 comparison.push({input:Buffer.from('<svg width="1300" height="680"><g fill="#f5f1e8" font-family="Segoe UI,Arial" font-size="27" text-anchor="middle"><text x="325" y="45">Oculin de base</text><text x="975" y="45">Invocateur ancien</text></g><text x="650" y="662" fill="#adb2c0" font-family="Segoe UI,Arial" font-size="16" text-anchor="middle">Comparaison à hauteur visuelle égale</text><path d="M650 70 V635" stroke="#586071"/></svg>'),left:0,top:0});
 await sharp({create:{width:1300,height:680,channels:4,background:'#303540'}}).composite(comparison).png().toFile(path.join(root,'comparison-base.png'));
 console.log(JSON.stringify(report,null,2));
}
main().catch(e=>{console.error(e);process.exitCode=1;});
