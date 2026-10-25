// Human comparison of the floor joins and heart ground contact. Reads frozen
// before snapshots and the latest prepared sprites / actual Godot captures.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const {writeGeneratedFile}=require('./write_generated_file.cjs');
const ROOT=path.resolve(__dirname,'..'),BASE='docs/reference/isometric-review/painted-v1',OUT=BASE+'/floor-seams-v2';
const read=p=>fs.readFileSync(path.join(ROOT,p)),write=(p,b)=>writeGeneratedFile(path.join(ROOT,p),b);
async function main() {
  const panels=[];
  for(const [i,version] of ['before','after'].entries()) {
    const catalogue=JSON.parse(read(version==='before'?OUT+'/before/catalog.json':'assets/dungeon/isometric-kit/catalog.json'));
    const entry=catalogue.atlas.regions.floor,src=read(version==='before'?OUT+'/before/floor.png':BASE+'/sprites/floor.png'),layers=[];
    for(let y=0;y<5;y++)for(let x=0;x<5;x++)layers.push({input:src,left:660+(x-y)*128+entry.offset[0],top:12+(x+y)*64+entry.offset[1]});
    const patch=await sharp({create:{width:1320,height:670,channels:4,background:'#0b1019'}}).composite(layers).png().toBuffer();
    const detail=await sharp(patch).extract({left:340,top:175,width:640,height:300}).png().toBuffer();
    write(`${OUT}/${version}-patch.png`,patch);write(`${OUT}/${version}-detail.png`,detail);
    panels.push({input:await sharp(detail).resize(480,225).png().toBuffer(),left:20+i*500,top:75});
    const capture=read(version==='before'?OUT+'/before/MobileReference-heart-0.png':BASE+'/captures/MobileReference-heart-0.png');
    const heart=await sharp(capture).extract({left:530,top:230,width:220,height:190}).resize(440,380,{kernel:'nearest'}).png().toBuffer();
    write(`${OUT}/${version}-heart-contact.png`,heart);panels.push({input:heart,left:40+i*500,top:360});
  }
  const labels='<text x="20" y="25">Sol — motif assemblé à l’échelle de jeu</text><text x="20" y="57">Avant</text><text x="520" y="57">Après</text><text x="20" y="338">Socle — captures Godot agrandies ×2</text>';
  panels.push({input:Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="1020" height="760"><g font-family="Segoe UI,Arial,sans-serif" font-size="18" fill="#dde7f4">${labels}</g></svg>`),left:0,top:0});
  write(OUT+'/comparison.png',await sharp({create:{width:1020,height:760,channels:4,background:'#0b1019'}}).composite(panels).png().toBuffer());
  console.log('Saved '+OUT+'/comparison.png');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
