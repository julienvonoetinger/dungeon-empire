// Stage only the active architecture dependency graph. The user's live editor
// and its cached dependency inventory are never reset or rewritten here.
const fs=require('node:fs'),path=require('node:path');
const {writeGeneratedFile}=require('./write_generated_file.cjs');
const root=path.resolve(__dirname,'..'),files=new Set();
const scenes=fs.readdirSync(path.join(root,'scenes')).filter(n=>n.endsWith('.tscn')).map(n=>'scenes/'+n);
function collect(file){
  if(files.has(file))return;
  if(!fs.existsSync(path.join(root,file)))throw Error('Missing active dependency '+file);
  files.add(file);
  if(/\.(gd|tscn|tres)$/.test(file)){
    const s=fs.readFileSync(path.join(root,file),'utf8');
    for(const m of s.matchAll(/res:\/\/([A-Za-z0-9_./-]+\.(?:gd|tscn|tres|png))/g))collect(m[1]);
  }
}
scenes.forEach(collect);
const selected=[...files].sort();
const preset=fs.readFileSync(path.join(root,'export_presets.cfg'),'utf8')
  .replace('export_filter="scenes"','export_filter="resources"')
  .replace(/export_files=PackedStringArray\([^\n]*\)/,'export_files=PackedStringArray('+selected.map(p=>JSON.stringify('res://'+p)).join(', ')+')');
writeGeneratedFile(path.join(root,'export_presets.cfg'),preset);
const staging='artifacts/mobile-export-stage-'+new Date().toISOString().replace(/[:.]/g,'-');
const copy=file=>{const target=path.join(root,staging,file);fs.mkdirSync(path.dirname(target),{recursive:true});fs.copyFileSync(path.join(root,file),target);};
for(const file of [...selected,'project.godot','export_presets.cfg']){
  copy(file);
  for(const suffix of ['.uid','.import'])if(fs.existsSync(path.join(root,file+suffix)))copy(file+suffix);
}
const info={staging,scenes:scenes.length,files:selected,sourceBytes:selected.reduce((sum,p)=>sum+fs.statSync(path.join(root,p)).size,0),purpose:'Fresh export dependency cache; historical assets and unrelated editor state excluded.'};
const review=process.argv.includes('--wireframe')?'migration-v1':'painted-v1';
writeGeneratedFile(path.join(root,'docs/reference/isometric-review',review,'export-inventory.json'),JSON.stringify(info,null,2)+'\n');
console.log(JSON.stringify(info));
