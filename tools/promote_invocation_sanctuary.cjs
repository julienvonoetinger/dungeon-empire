// Promote the approved v6 scenery without changing artwork or node geometry.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto');
const {writeGeneratedFile:write}=require('./write_generated_file.cjs');
const ROOT=path.resolve(__dirname,'..');
const read=p=>fs.readFileSync(path.join(ROOT,p));
const save=(p,b)=>write(path.join(ROOT,p),b);
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
const source='scenes/SanctuaryFlora.tscn';
const original=read(source);
let scene=original.toString();
const assets={};
scene=scene.replace(/\[ext_resource type="Texture2D" path="res:\/\/([^"]+)" id="([^"]+)"\]/g,(_,file,id)=>{
 const target='assets/game/introduction/sanctuary/'+id+'.png';
 const bytes=read(file);save(target,bytes);
 assets[id]={source:file,target,sha256:hash(bytes),bytes:bytes.length};
 return `[ext_resource type="Texture2D" path="res://${target}" id="${id}"]`;
});
scene=scene.replace(/^\[ext_resource type="Script"[^\n]+\n/gm,'')
 .replace(/^script = ExtResource\("view"\)\r?\n/gm,'')
 .replace(/^terrain_bounds = [^\n]+\n/gm,'')
 .replace('[node name="SanctuairePeint"','[node name="Sanctuary"')
 .replace(/load_steps=\d+/,'load_steps='+(Object.keys(assets).length+1));
if(scene.includes('res://assets/previews/')||scene.includes('sanctuary_wireframe_view'))throw Error('Preview dependency remains');
save('scenes/game/InvocationSanctuary.tscn',scene);
save('docs/reference/sanctuary-textured/integration/recipe.json',JSON.stringify({source,sourceHash:hash(original),scene:'scenes/game/InvocationSanctuary.tscn',assets},null,2)+'\n');
console.log(Object.keys(assets).length+' byte-identical textures promoted; scenery geometry unchanged.');
