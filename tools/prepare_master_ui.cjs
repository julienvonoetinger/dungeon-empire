const fs = require('fs');
const path = require('path');
const sharp = require('sharp');
const root = path.resolve(__dirname, '..');
const source = path.join(root, 'docs/reference/interface-review/v10-master-mobile/source');
const out = path.join(root, 'assets/ui/master');
async function prepare(name,width) {
  const input=path.join(source,name+'.png');
  const {data,info}=await sharp(input).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  let left=info.width,top=info.height,right=0,bottom=0;
  for(let y=0;y<info.height;y++)for(let x=0;x<info.width;x++) {
    if(data[(y*info.width+x)*4+3]>8){left=Math.min(left,x);top=Math.min(top,y);right=Math.max(right,x);bottom=Math.max(bottom,y);}
  }
  left=Math.max(0,left-3);top=Math.max(0,top-3);right=Math.min(info.width-1,right+3);bottom=Math.min(info.height-1,bottom+3);
  await sharp(input).extract({left,top,width:right-left+1,height:bottom-top+1}).resize({width}).png().toFile(path.join(out,name+'.png'));
}
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
Promise.all([prepare('header',1024),prepare('eye',192),trapIcons()]).catch(e=>{console.error(e);process.exitCode=1;});
