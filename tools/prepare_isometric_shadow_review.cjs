// Compare the actual fixed-zoom Godot capture before/after the ground shadow.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const {writeGeneratedFile}=require('./write_generated_file.cjs');
const ROOT=path.resolve(__dirname,'..'),BASE='docs/reference/isometric-review/painted-v1',OUT=BASE+'/heart-shadow-v1';
async function main() {
  const layers=[];
  for(const [i,version] of ['before','after'].entries()) {
    const file=version==='before'?OUT+'/before/MobileReference-heart-0.png':BASE+'/captures/MobileReference-heart-0.png';
    const crop=await sharp(fs.readFileSync(path.join(ROOT,file))).extract({left:535,top:235,width:215,height:190}).png().toBuffer();
    layers.push({input:crop,left:20+i*490,top:70});
    const detail=await sharp(crop).resize(430,380,{kernel:'nearest'}).png().toBuffer();
    layers.push({input:detail,left:20+i*490,top:310});
    writeGeneratedFile(path.join(ROOT,OUT,version+'.png'),detail);
  }
  const svg='<svg xmlns="http://www.w3.org/2000/svg" width="980" height="710"><g font-family="Segoe UI,Arial,sans-serif" font-size="18" fill="#dde7f4"><text x="20" y="25">Socle — ombre portée sur le sol</text><text x="20" y="56">Avant</text><text x="510" y="56">Avec ombre</text><text x="20" y="292">Captures Godot agrandies ×2 — même caméra</text></g></svg>';
  layers.push({input:Buffer.from(svg),left:0,top:0});
  writeGeneratedFile(path.join(ROOT,OUT,'comparison.png'),await sharp({create:{width:980,height:710,channels:4,background:'#0b1019'}}).composite(layers).png().toBuffer());
  console.log('Saved '+OUT+'/comparison.png');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
