// Compare real gameplay pixels first, with a separately labelled enlargement.
const path=require('node:path'),sharp=require('sharp');
const {writeGeneratedFile}=require('./write_generated_file.cjs');
const ROOT=path.resolve(__dirname,'..');
async function main() {
  const captures=path.join(ROOT,'docs/reference/mobile-optimization/captures');
  const layers=[];
  for(const [i,name]of ['detail-a','proposed-256'].entries()) {
    const source=path.join(captures,name+'.png');
    layers.push({input:await sharp(source).extract({left:265,top:76,width:220,height:180}).png().toBuffer(),left:95+i*400,top:100});
    layers.push({input:await sharp(source).extract({left:270,top:78,width:76,height:90}).resize(228,270,{kernel:'nearest'}).png().toBuffer(),left:91+i*400,top:348});
  }
  const background=Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="820" height="672"><rect width="100%" height="100%" fill="#080e19"/><g font-family="Arial,sans-serif" fill="#e1e8f4">
  <text x="24" y="32" font-size="24">Même pilier · même distance de jeu</text>
  <text x="24" y="76" font-size="21">Avant · petit relief ajouté</text><text x="424" y="76" font-size="21">Après · grand creux dans la pierre</text>
  <text x="24" y="315" font-size="18" fill="#aebdd2">En haut : captures sans redimensionnement · dessus du pilier ≈ 46 pixels</text>
  <text x="24" y="650" font-size="17" fill="#aebdd2">En bas : mêmes pixels agrandis ×3 · contour, corps et raccords du pilier conservés</text>
  </g></svg>`);
  writeGeneratedFile(path.join(ROOT,'docs/reference/pillar-cap-review/comparison.png'),await sharp(background).composite(layers).png().toBuffer());
  console.log('Saved pillar-cap-review/comparison.png');
}
main().catch(e=>{console.error(e.stack);process.exitCode=1;});
