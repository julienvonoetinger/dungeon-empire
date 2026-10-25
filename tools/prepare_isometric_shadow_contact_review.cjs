const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs'),Shadow=require('./isometric_ground_shadow_study.cjs');
const {writeGeneratedFile}=require('./write_generated_file.cjs');
const BASE='docs/reference/isometric-review/painted-v1',OUT=BASE+'/heart-shadow-v2';
const read=p=>fs.readFileSync(path.join(P.ROOT,p)),write=(p,b)=>writeGeneratedFile(path.join(P.ROOT,p),b);
async function main() {
  const model=P.models.find(m=>m.id==='heart'),catalog=JSON.parse(read('assets/dungeon/isometric-kit/catalog.json'));
  const variants=[['current','Actuelle',null],['contact','Contact diffus',{castOpacity:.32,softness:2.4,contactOpacity:.7,contactSoftness:2.8,contactSpread:1.5}],['cast','Contact + ombre étendue',{lightDirection:[-1.1,-.7,1],castOpacity:.40,softness:3.2,contactOpacity:.7,contactSoftness:2.8,contactSpread:1.5}]];
  const recipe=[],panels=[],origin=[200,235];
  for(const [i,[id,label,settings]] of variants.entries()) {
    const item=settings?await Shadow.prepare(model,settings):{png:read(BASE+'/sprites/heart-shadow.png'),frame:[...catalog.atlas.regions['heart-shadow'].offset,...catalog.atlas.regions['heart-shadow'].size]};
    write(`${OUT}/${id}.png`,item.png);recipe.push({id,label,settings,frame:item.frame,bounds:item.bounds,adaptation:item.adaptation});
    const layers=[],floor=catalog.atlas.regions.floor,heart=catalog.atlas.regions.heart;
    for(let y=-2;y<=2;y++)for(let x=-2;x<=2;x++) {
      const p=P.project([x,y,0]);layers.push({input:read(BASE+'/sprites/floor.png'),left:origin[0]+p[0]+floor.offset[0]+400,top:origin[1]+p[1]+floor.offset[1]+400});
    }
    layers.push({input:item.png,left:origin[0]+item.frame[0]+400,top:origin[1]+item.frame[1]+400});
    layers.push({input:read(BASE+'/sprites/heart.png'),left:origin[0]+heart.offset[0]+400,top:origin[1]+heart.offset[1]+400});
    const assembled=await sharp({create:{width:1200,height:1100,channels:4,background:'#0b1019'}}).composite(layers).png().toBuffer();
    const scene=await sharp(assembled).extract({left:400,top:400,width:400,height:330}).resize(300,248).png().toBuffer();
    panels.push({input:scene,left:20+i*320,top:72});
    panels.push({input:await sharp(scene).resize(600,496,{kernel:'nearest'}).extract({left:140,top:180,width:300,height:300}).png().toBuffer(),left:20+i*320,top:370});
    write(`${OUT}/${id}-scene.png`,scene);
  }
  write(OUT+'/recipe.json',JSON.stringify({purpose:'Offline visual study at .75 scale. Current heart/floor unchanged; no scene lighting.',variants:recipe},null,2)+'\n');
  const labels=variants.map((v,i)=>`<text x="${20+i*320}" y="52">${v[1]}</text>`).join('');
  panels.push({input:Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="980" height="690"><g font-family="Segoe UI,Arial" font-size="17" fill="#dde7f4"><text x="20" y="24">Étude de contact — mêmes sprites et même échelle</text>${labels}<text x="20" y="350">Détail ×2 de l’assise</text></g></svg>`),left:0,top:0});
  write(OUT+'/comparison.png',await sharp({create:{width:980,height:690,channels:4,background:'#0b1019'}}).composite(panels).png().toBuffer());
  console.log(OUT+'/comparison.png');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
