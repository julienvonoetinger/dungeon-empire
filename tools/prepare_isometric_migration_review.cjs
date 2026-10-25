// Assemble human review boards from actual Godot captures; no image generation.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const {writeGeneratedFile:write}=require('./write_generated_file.cjs');
const root=path.resolve(__dirname,'..'),out=process.argv.includes('--wireframe')?'docs/reference/isometric-review/migration-v1':'docs/reference/isometric-review/painted-v1';
async function main() {
  const names=['MobileReference','WireframeDoorCross','EntranceVariants','SixRoomPreview'];
  const titles=['Salle de référence · échelle de jeu .75','Quatre orientations de portes · échelle de jeu .75','Quatre entrées · vue d’ensemble','Six salles · vue d’ensemble'];
  const panels=[];
  for(let i=0;i<names.length;i++) {
    const filename=`${out}/captures/${names[i]}-${i<2?'native':'overview'}.png`;
    panels.push({input:await sharp(path.join(root,filename)).resize(640,360).png().toBuffer(),left:(i%2)*660+10,top:Math.floor(i/2)*406+48});
  }
  const text=titles.map((title,i)=>`<text x="${(i%2)*660+18}" y="${Math.floor(i/2)*406+30}" font-family="Segoe UI,Arial,sans-serif" font-size="19" fill="#e6edf5">${title}</text>`).join('');
  panels.push({input:Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="1320" height="812">${text}</svg>`),left:0,top:0});
  write(path.join(root,out,'scene-board.png'),await sharp({create:{width:1320,height:812,channels:4,background:'#0b1019'}}).composite(panels).png().toBuffer());
  console.log('Saved '+out+'/scene-board.png (capture thumbnails, not native pixel scale)');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
