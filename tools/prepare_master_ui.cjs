const fs = require('fs');
const path = require('path');
const sharp = require('sharp');
const root = path.resolve(__dirname, '..');
const out = path.join(root, 'assets/ui/master');
fs.mkdirSync(out,{recursive:true});
async function trapIcons() {
  const catalog=fs.readFileSync(path.join(root,'assets/dungeon/isometric-kit/catalog.tres'),'utf8');
  const entries=JSON.parse(catalog.split('entries = ')[1].split('\n')[0]);
  const atlas=path.join(root,'assets/dungeon/isometric-kit/traps/atlas-256.png');
  async function region(entry){const [left,top,width,height]=entry.region;return sharp(atlas).extract({left,top,width,height}).png().toBuffer();}
  for(const [name,state] of [['spike','triggered'],['snare','ready'],['void','ready']]) {
    const floor=entries[`trap-${name}-${state}-floor`];
    const layers=[{input:await region(floor),left:0,top:6}];
    const mechanism=entries[`trap-${name}-${state}-mechanism`];
    if(mechanism)layers.push({input:await region(mechanism),left:41,top:4});
    const composed=await sharp({create:{width:203,height:112,channels:4,background:'#00000000'}}).composite(layers).png().toBuffer();
    await sharp(composed).extract({left:37,top:1,width:130,height:100}).resize({width:96}).png().toFile(path.join(out,`trap-${name}.png`));
  }
}
// C supersedes the old iron band/round medallion. Do not restore v10/v11 art.
Promise.all([require('./prepare_header_c.cjs').prepareHeaderC(),require('./prepare_header_icons.cjs').prepareHeaderIcons(),trapIcons()]).catch(e=>{console.error(e);process.exitCode=1;});
