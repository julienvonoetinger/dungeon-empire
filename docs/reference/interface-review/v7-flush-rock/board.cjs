const path=require('node:path'),sharp=require('sharp');
async function main(){
 const w=1064,h=1296;
 const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" font-family="Arial,sans-serif"><text x="20" y="29" font-size="21" fill="#e1e4ef">Roche extérieure · hauteur et intégration</text><text x="20" y="52" font-size="12" fill="#acaec3">Version précédente · amas posés et roche plus haute que les murs</text><text x="20" y="659" font-size="15" fill="#c7addf">Proposition · roche au niveau des murs, minéraux inclus dans la matière</text><text x="20" y="1277" font-size="12" fill="#a8afc2">Même salle, mêmes murs, même échelle · proposition de maquette uniquement</text></svg>`;
 await sharp({create:{width:w,height:h,channels:4,background:'#111722'}}).composite([{input:path.join(__dirname,'../v6-rock-variety/captures/1024-peek.png'),left:20,top:66},{input:path.join(__dirname,'captures/1024-peek.png'),left:20,top:674},{input:Buffer.from(svg),left:0,top:0}]).png().toFile(path.join(__dirname,'comparison.png'));
 console.log('comparison.png');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
