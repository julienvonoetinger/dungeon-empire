// Actual Godot before/after, identical cameras. --directional selects v5.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const {writeGeneratedFile}=require('./write_generated_file.cjs');
const DIRECTIONAL=process.argv.includes('--directional');
const ROOT=path.resolve(__dirname,'..'),BASE='docs/reference/isometric-review/painted-v1',OUT=BASE+(DIRECTIONAL?'/heart-shadow-v5':'/heart-shadow-v4');
async function main() {
  const panels=[];
  for(const [i,version] of ['before','after'].entries()) {
    const file=version==='before'?OUT+'/before/MobileReference-heart-0.png':BASE+'/captures/MobileReference-heart-0.png';
    const crop=await sharp(fs.readFileSync(path.join(ROOT,file))).extract({left:510,top:225,width:260,height:210}).png().toBuffer();
    const detail=await sharp(crop).resize(520,420,{kernel:'nearest'}).png().toBuffer();
    panels.push({input:crop,left:20+i*550,top:70},{input:detail,left:20+i*550,top:325});
    writeGeneratedFile(path.join(ROOT,OUT,version+'-detail.png'),detail);
  }
  const title=DIRECTIONAL?'Même cœur — ombre portée dans une seule direction':'Même cœur — ombre agrandie autour du socle';
  const after=DIRECTIONAL?'Ombre vers le bas à droite':'Ombre ×1,5';
  const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="1100" height="765"><g font-family="Segoe UI,Arial" font-size="18" fill="#dde7f4"><text x="20" y="25">${title}</text><text x="20" y="56">Avant</text><text x="570" y="56">${after}</text><text x="20" y="308">Captures Godot agrandies ×2 — mêmes caméras</text></g></svg>`;
  panels.push({input:Buffer.from(svg),left:0,top:0});
  writeGeneratedFile(path.join(ROOT,OUT,'comparison.png'),await sharp({create:{width:1100,height:765,channels:4,background:'#0b1019'}}).composite(panels).png().toBuffer());
  console.log(OUT+'/comparison.png');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
