// Display actual prepared composites at .75, then marked detail enlargements.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const {writeGeneratedFile:write}=require('./write_generated_file.cjs');
const ROOT=path.resolve(__dirname,'..'),OUT='docs/reference/isometric-decoration-review/v1';
const read=p=>JSON.parse(fs.readFileSync(path.join(ROOT,p),'utf8'));
const prepared=read(OUT+'/prepared.json'),catalog=read('assets/dungeon/isometric-kit/catalog.json');
const ids=['crack-short','crack-branch','chip-worn','crack-corrupt'];
const titles=['Fissure courte','Fracture ramifiée','Pierre ébréchée','Corruption discrète'];
async function composite(id,surface) {
  const baseId=surface==='floor'?'floor':surface+'-0',base=catalog.atlas.regions[baseId];
  const entry=prepared.entries.find(e=>e.id===id+'-'+surface);
  return sharp(path.join(ROOT,'docs/reference/isometric-review/painted-v1/sprites/'+baseId+'.png')).composite([
    {input:path.join(ROOT,entry.file),left:entry.offset[0]-base.offset[0],top:entry.offset[1]-base.offset[1]}
  ]).png().toBuffer();
}
async function main(){
  const layers=[],labels=[],W=1280,H=500;
  for(let i=0;i<ids.length;i++) {
    const x=i*320,images={};
    labels.push(`<text x="${x+18}" y="28" font-size="19">${titles[i]}</text>`,
      `<text x="${x+18}" y="55">Sol · taille de jeu</text>`,
      `<text x="${x+18}" y="199">Murs · taille de jeu</text>`,
      `<text x="${x+18}" y="340">Détails ×2</text>`);
    for(const [j,surface] of ['floor','wall-h','wall-v'].entries()) {
      images[surface]=await composite(ids[i],surface);
      const m=await sharp(images[surface]).metadata();
      const scaled=await sharp(images[surface]).resize(Math.round(m.width*.75),Math.round(m.height*.75)).png().toBuffer();
      layers.push({input:scaled,left:x+18+(j===2?150:0),top:j===0?65:210});
    }
    layers.push({input:await sharp(images.floor).extract({left:90,top:32,width:90,height:72}).resize(135,108,{kernel:'nearest'}).png().toBuffer(),left:x+10,top:355});
    layers.push({input:await sharp(images['wall-h']).extract({left:30,top:25,width:90,height:72}).resize(135,108,{kernel:'nearest'}).png().toBuffer(),left:x+165,top:355});
  }
  labels.push('<text x="18" y="488">4 dessins sources · 3 plans isométriques · décors transparents séparés</text>');
  layers.push({input:Buffer.from(`<svg width="${W}" height="${H}" xmlns="http://www.w3.org/2000/svg"><g fill="#dce5f2" font-family="Segoe UI,Arial" font-size="14">${labels.join('')}</g></svg>`),left:0,top:0});
  write(path.join(ROOT,OUT,'variants.png'),await sharp({create:{width:W,height:H,channels:4,background:'#101722'}}).composite(layers).png().toBuffer());
  const views=[];
  for(const [i,id] of ['bare','mixed'].entries())views.push({input:await sharp(path.join(ROOT,OUT,'captures/'+id+'.png')).extract({left:335,top:165,width:620,height:360}).png().toBuffer(),left:10+640*i,top:55});
  views.push({input:Buffer.from('<svg width="1280" height="430" xmlns="http://www.w3.org/2000/svg"><g fill="#dce5f2" font-family="Segoe UI,Arial" font-size="20"><text x="18" y="30">Sans détails</text><text x="658" y="30">Avec les quatre motifs · capture Godot à .75</text></g></svg>'),left:0,top:0});
  write(path.join(ROOT,OUT,'scene-comparison.png'),await sharp({create:{width:1280,height:430,channels:4,background:'#101722'}}).composite(views).png().toBuffer());
  console.log(OUT+'/variants.png');
}
main().catch(e=>{console.error(e.stack);process.exitCode=1;});
