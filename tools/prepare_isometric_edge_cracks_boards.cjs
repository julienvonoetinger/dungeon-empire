// Real prepared pixels; gameplay rows at .75 and labelled detail crops x3.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const {writeGeneratedFile:write}=require('./write_generated_file.cjs');
const ROOT=path.resolve(__dirname,'..'),OUT='docs/reference/isometric-decoration-review/v2-edge-cracks';
const read=p=>JSON.parse(fs.readFileSync(path.join(ROOT,p)));
const current=read('docs/reference/isometric-decoration-review/v1/prepared.json'),next=read(OUT+'/prepared.json');
const catalog=read('assets/dungeon/isometric-kit/catalog.json');
const cases=[['Actuelle','crack-short',current],['Coin fendu','corner-split',next],['Depuis le haut','vertical-hairline',next],['Depuis le côté','edge-fork',next]];
async function composite(id,surface,prepared) {
  const baseId=surface==='floor'?'floor':surface+'-0',base=catalog.atlas.regions[baseId];
  const e=prepared.entries.find(e=>e.id===id+'-'+surface);
  return sharp(path.join(ROOT,'docs/reference/isometric-review/painted-v1/sprites/'+baseId+'.png')).composite([
    {input:path.join(ROOT,e.file),left:e.offset[0]-base.offset[0],top:e.offset[1]-base.offset[1]}
  ]).png().toBuffer();
}
async function main() {
  const layers=[],labels=[],W=1200,H=615;
  for(const [i,[title,id,prepared]] of cases.entries()) {
    const x=i*300,images={};
    labels.push(`<text x="${x+15}" y="28" font-size="21">${title}</text>`,
      `<text x="${x+15}" y="55">Sol · taille de jeu</text>`,
      `<text x="${x+15}" y="190">Murs · taille de jeu</text>`,
      `<text x="${x+15}" y="335">Détail du mur ×3</text>`);
    for(const [j,surface] of ['floor','wall-h','wall-v'].entries()) {
      images[surface]=await composite(id,surface,prepared);
      const m=await sharp(images[surface]).metadata();
      layers.push({input:await sharp(images[surface]).resize(Math.round(m.width*.75),Math.round(m.height*.75)).png().toBuffer(),left:x+15+(j===2?140:0),top:j===0?65:200});
    }
    const base=catalog.atlas.regions['wall-h-0'];
    // Same central upper-course stone for each comparison; no art repainting.
    layers.push({input:await sharp(images['wall-h']).extract({left:22-base.offset[0],top:-30-base.offset[1],width:75,height:70}).resize(225,210,{kernel:'nearest'}).png().toBuffer(),left:x+30,top:350});
  }
  labels.push('<text x="15" y="596">Même pierre et projection · 3 tracés distincts raccordés aux joints · proposition non intégrée</text>');
  layers.push({input:Buffer.from(`<svg width="${W}" height="${H}" xmlns="http://www.w3.org/2000/svg"><g fill="#dce5f2" font-family="Segoe UI,Arial" font-size="14">${labels.join('')}</g></svg>`),left:0,top:0});
  write(path.join(ROOT,OUT,'comparison.png'),await sharp({create:{width:W,height:H,channels:4,background:'#101722'}}).composite(layers).png().toBuffer());
  if(fs.existsSync(path.join(ROOT,OUT,'captures/current.png'))) {
    const views=[];
    for(const [i,id] of ['current','proposed'].entries())views.push({input:await sharp(path.join(ROOT,OUT,'captures/'+id+'.png')).extract({left:335,top:165,width:620,height:360}).png().toBuffer(),left:10+640*i,top:55});
    views.push({input:Buffer.from('<svg width="1280" height="430" xmlns="http://www.w3.org/2000/svg"><g fill="#dce5f2" font-family="Segoe UI,Arial" font-size="20"><text x="18" y="30">Actuelles</text><text x="658" y="30">Proposition · mêmes placements · Godot à .75</text></g></svg>'),left:0,top:0});
    write(path.join(ROOT,OUT,'gameplay-comparison.png'),await sharp({create:{width:1280,height:430,channels:4,background:'#101722'}}).composite(views).png().toBuffer());
  }
  console.log(OUT+'/comparison.png');
}
main().catch(e=>{console.error(e.stack);process.exitCode=1;});
