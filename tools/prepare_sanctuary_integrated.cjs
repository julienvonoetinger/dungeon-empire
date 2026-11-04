// Native ImageGen material/contour corrections on complete sprite sources.
// Preserve v3 cell framing and registration, including when moss reaches lower.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),sharp=require('sharp');
const {writeGeneratedFile:write}=require('./write_generated_file.cjs');
const ROOT=path.resolve(__dirname,'..');
const REV='docs/reference/sanctuary-textured/v5';
const OUT='assets/previews/sanctuary-integrated';
const read=p=>fs.readFileSync(path.join(ROOT,p));
const save=(p,b)=>write(path.join(ROOT,p),b);
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
async function main(){
  const old=JSON.parse(read('docs/reference/sanctuary-textured/v3/recipe.json'));
  const layouts=JSON.parse(read('docs/reference/sanctuary-textured/v3/guides/layout.json'));
  let scene=read('scenes/SanctuaryNaturalGround.tscn').toString();
  const sources={},records={};
  for(const name of Object.keys(layouts)){
    const file=REV+'/source/'+name+'.png';
    if(!fs.existsSync(path.join(ROOT,file))){
      if(process.argv.includes('--pilot'))continue;
      throw Error('Missing corrected source '+file);
    }
    const source=read(file),meta=await sharp(source).metadata();
    const original=await sharp(read('docs/reference/sanctuary-textured/v3/source/'+name+'.png')).metadata();
    if(meta.width!==original.width||meta.height!==original.height||!meta.hasAlpha)
      throw Error('Source canvas or native alpha differs: '+name);
    sources[name]={file,sha256:hash(source),size:[meta.width,meta.height]};
    for(const e of layouts[name].entries){
      const r=old.records[e.id], [left,top,width,height]=r.source.rect;
      const png=await sharp(source).extract({left,top,width,height}).resize(r.frame[2],r.frame[3]).png().toBuffer();
      const out=OUT+'/'+e.id+'.png'; save(out,png);
      scene=scene.replace('res://assets/previews/sanctuary-coherent/'+e.id+'.png','res://'+out);
      records[e.id]={frame:r.frame,source:file,rect:r.source.rect,bytes:png.length,sha256:hash(png)};
    }
  }
  save('scenes/SanctuaryIntegrated.tscn',scene);
  save(REV+'/recipe.json',JSON.stringify({method:'native whole-sprite paint corrections, unchanged canvas registration',baseline:'scenes/SanctuaryNaturalGround.tscn',baselineHash:hash(read('scenes/SanctuaryNaturalGround.tscn')),sources,records},null,2)+'\n');
  console.log(Object.keys(records).length+' complete sprites replaced; all node transforms, ground and candles retained.');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
