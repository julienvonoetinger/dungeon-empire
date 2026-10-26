const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),sharp=require('sharp');
const ROOT=path.resolve(__dirname,'../../../..');
const read=p=>JSON.parse(fs.readFileSync(path.join(ROOT,p),'utf8').replace(/^\uFEFF/,''));
async function main(){
 const cat=read('assets/dungeon/isometric-kit/catalog.json'),scene=read('docs/reference/treasure-chest-review/v4-directions/scene-inventory.json').captures.find(s=>s.capture==='corners-open');
 const ids=new Set(scene.sprites.map(s=>s.id));for(const id of ['prop-chest','prop-chest-open','prop-crystals','prop-candles','prop-idol','floor-b1','door-north-arch','door-north-leaf'])ids.add(id);
 const regions=Object.fromEntries([...ids].map(id=>[id,cat.atlas.regions[id]]));
 await sharp(path.join(__dirname,'source/bedrock-original.png')).resize(512,512,{fit:'contain',background:'#263149'}).png().toFile(path.join(__dirname,'assets/bedrock.png'));
 fs.writeFileSync(path.join(__dirname,'assets/data.js'),'window.REVIEW_DATA='+JSON.stringify({regions,sprites:scene.sprites.map(s=>({id:s.id,p:s.position,size:s.size,z:s.z})).sort((a,b)=>a.z-b.z)})+';\n');
 fs.copyFileSync(path.join(ROOT,'assets/dungeon/isometric-kit/atlas-256.png'),path.join(__dirname,'assets/architecture.png'));
 fs.copyFileSync(path.join(ROOT,'assets/dungeon/isometric-kit/chests/atlas-256.png'),path.join(__dirname,'assets/chests.png'));
 async function trimAlpha(input){const{data,info}=await sharp(input).ensureAlpha().raw().toBuffer({resolveWithObject:true});let x0=info.width,y0=info.height,x1=-1,y1=-1;for(let y=0;y<info.height;y++)for(let x=0;x<info.width;x++)if(data[(y*info.width+x)*4+3]>0){x0=Math.min(x0,x);x1=Math.max(x1,x);y0=Math.min(y0,y);y1=Math.max(y1,y);}return sharp(input).extract({left:x0,top:y0,width:x1-x0+1,height:y1-y0+1}).png().toBuffer();}
 for(const [src,name,size]of [['dig-original.png','dig.png',144],['spikes-original.png','spikes.png',144],['stone-original.png','stone.png',384]]){const p=path.join(__dirname,'source',src);await sharp(await trimAlpha(p)).resize(size,size,{fit:'contain',background:'#0000'}).png().toFile(path.join(__dirname,'assets',name));}
 async function region(id){const e=regions[id],p=e.atlas_path?e.atlas_path.replace('res://',''):'assets/dungeon/isometric-kit/atlas-256.png';return sharp(path.join(ROOT,p)).extract({left:e.region[0],top:e.region[1],width:e.region[2],height:e.region[3]}).png().toBuffer();}
 for(const [id,name]of [['prop-chest-open','chest'],['prop-chest','locked'],['prop-crystals','crystal'],['prop-candles','candles'],['prop-idol','idol'],['heart','heart']])await sharp(await region(id)).resize(144,144,{fit:'contain',background:'#0000'}).png().toFile(path.join(__dirname,'assets',name+'.png'));
 const parts=['door-north-leaf','door-north-arch'],min=[0,1].map(a=>Math.min(...parts.map(id=>regions[id].offset[a]))),max=[0,1].map(a=>Math.max(...parts.map(id=>regions[id].offset[a]+regions[id].size[a]))),layers=[];for(const id of parts)layers.push({input:await region(id),left:regions[id].offset[0]-min[0],top:regions[id].offset[1]-min[1]});
 const door=await sharp({create:{width:max[0]-min[0],height:max[1]-min[1],channels:4,background:'#0000'}}).composite(layers).png().toBuffer();await sharp(door).resize(144,144,{fit:'contain',background:'#0000'}).png().toFile(path.join(__dirname,'assets/door.png'));
 const paths=['project.godot','scripts/game/game_hud.gd','scripts/game/game_session.gd','assets/dungeon/isometric-kit/catalog.json','assets/dungeon/isometric-kit/atlas-256.png','assets/dungeon/isometric-kit/chests/atlas-256.png'];
 fs.writeFileSync(path.join(__dirname,'baseline.json'),JSON.stringify(Object.fromEntries(paths.map(p=>[p,crypto.createHash('sha256').update(fs.readFileSync(path.join(ROOT,p))).digest('hex')])),null,2)+'\n');console.log(JSON.stringify({sprites:scene.sprites.length,regions:ids.size,generatedSources:4,artworkEdits:'none; alpha-bounds crop and uniform fit only',productionWrites:0}));
}
main().catch(e=>{console.error(e);process.exitCode=1;});
