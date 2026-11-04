// Replace only the six old botanical paintings; preserve whole-cell framing.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),sharp=require('sharp');
const {writeGeneratedFile:write}=require('./write_generated_file.cjs');
const ROOT=path.resolve(__dirname,'..'),REV='docs/reference/sanctuary-textured/v6';
const read=p=>fs.readFileSync(path.join(ROOT,p)),save=(p,b)=>write(path.join(ROOT,p),b);
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
async function main(){
 const source=read(REV+'/source/dressing.png'),meta=await sharp(source).metadata();
 if(meta.width!==1536||meta.height!==1024||!meta.hasAlpha)throw Error('Expected original 1536x1024 sheet with native alpha');
 const old=JSON.parse(read('docs/reference/sanctuary-textured/v3/recipe.json'));
 const baseline=read('scenes/SanctuaryIntegrated.tscn');
 let scene=baseline.toString();const records={};
 for(const id of ['fern','violets','mushrooms','moss','wildflowers','garden']){
   const r=old.records[id],[left,top,width,height]=r.source.rect;
   const png=await sharp(source).extract({left,top,width,height}).resize(r.frame[2],r.frame[3]).png().toBuffer();
   const target='assets/previews/sanctuary-flora/'+id+'.png';save(target,png);
   scene=scene.replace('res://assets/previews/sanctuary-coherent/'+id+'.png','res://'+target);
   records[id]={frame:r.frame,rect:r.source.rect,sha256:hash(png),bytes:png.length};
 }
 save('scenes/SanctuaryFlora.tscn',scene);
 save(REV+'/recipe.json',JSON.stringify({source:REV+'/source/dressing.png',sourceHash:hash(source),size:[meta.width,meta.height],baseline:'scenes/SanctuaryIntegrated.tscn',baselineHash:hash(baseline),records},null,2)+'\n');
 console.log('Six vegetation sprites replaced; whole cells, original frames, all placements and candles retained.');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
