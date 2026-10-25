// Assemble actual Godot images; positions and projection are never retouched.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const {writeGeneratedFile:write}=require('./write_generated_file.cjs');
const ROOT=path.resolve(__dirname,'..'),OUT='docs/reference/isometric-review/painted-v1/heart-shadow-v6';
async function board(name,views) {
  const layers=[],w=570*views.length,h=630;
  for(let i=0;i<views.length;i++) {
    const [file,title]=views[i],crop=await sharp(path.join(ROOT,OUT,file)).extract({left:420,top:180,width:400,height:290}).png().toBuffer();
    layers.push({input:crop,left:20+i*570,top:60});
    const detail=await sharp(path.join(ROOT,OUT,file)).extract({left:515,top:270,width:260,height:130}).resize(520,260,{kernel:'nearest'}).png().toBuffer();
    layers.push({input:detail,left:20+i*570,top:360});
    layers.push({input:Buffer.from(`<svg width="${w}" height="${h}" xmlns="http://www.w3.org/2000/svg"><g fill="#dde7f4" font-family="Segoe UI,Arial" font-size="18"><text x="${20+i*570}" y="30">${title}</text></g></svg>`),left:0,top:0});
  }
  write(path.join(ROOT,OUT,name),await sharp({create:{width:w,height:h,channels:4,background:'#0b1019'}}).composite(layers).png().toBuffer());
}
async function main(){
  await board('comparison.png',[
    ['before/MobileReference-heart-0.png','Avant : direction fixe'],
    ['captures/reference.png','Après : ombre opposée à la torche proche']
  ]);
  await board('placement-comparison.png',[
    ['captures/reference.png','Position initiale'],
    ['captures/heart-moved-left.png','Cœur déplacé : la torche à gauche prend le relais'],
    ['captures/torch-moved.png','Torche déplacée : nouvelle orientation']
  ]);
  console.log(OUT+'/comparison.png');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
