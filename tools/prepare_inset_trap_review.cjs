const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs');
const OUT=path.join(P.ROOT,'docs/reference/trap-review/v3-integrated');
async function main(){
 const layers=[];
 const title='<svg xmlns="http://www.w3.org/2000/svg" width="960" height="310" font-family="Segoe UI,Arial"><rect width="960" height="310" fill="#0c121d"/><text x="20" y="30" fill="#e3e9f1" font-size="22">Pièges encastrés · rendu Godot</text><g fill="#b1bed3" font-size="17"><text x="20" y="66">Pointes</text><text x="340" y="66">Entrave</text><text x="660" y="66">Néant</text></g></svg>';
 for(const [i,kind]of ['spike','snare','void'].entries()){
  // Actual native 2x detail crop, no repaint or geometric modification.
  layers.push({input:await sharp(path.join(OUT,'ready-'+kind+'.png')).extract({left:330,top:145,width:300,height:220}).png().toBuffer(),left:10+i*320,top:80});
 }
 const top=await sharp(Buffer.from(title)).composite(layers).png().toBuffer();
 await sharp({create:{width:960,height:880,channels:4,background:'#0c121d'}}).composite([{input:top,left:0,top:0},{input:Buffer.from('<svg xmlns="http://www.w3.org/2000/svg" width="960" height="30"><text x="20" y="21" fill="#b1bed3" font-family="Segoe UI,Arial" font-size="15">Vue de jeu à l’échelle fixe 0,75 · états prêts</text></svg>'),left:0,top:310},{input:path.join(OUT,'ready-mobile.png'),left:0,top:340}]).png().toFile(path.join(OUT,'review-board.png'));
 for(const name of fs.readdirSync(path.join(P.ROOT,'docs/reference/isometric-review/painted-v1/sprites')).filter(n=>n.startsWith('trap-'))){
  fs.copyFileSync(path.join(P.ROOT,'docs/reference/isometric-review/painted-v1/sprites',name),path.join(OUT,name));
 }
 fs.writeFileSync(path.join(OUT,'index.html'),`<!doctype html><meta charset="utf-8"><title>Pièges encastrés</title><style>body{background:#0c121d;color:#d8e0ef;font:16px system-ui;max-width:1100px;margin:32px auto;padding:16px}img{max-width:100%;height:auto}a{color:#c6a0eb}</style><h1>Pièges encastrés</h1><p>Wireframe validé, mise en texture intégrée. Captures natives Godot, sans modification de l’interface ni des règles. Métal préparé à partir d’une matière ImageGen et de la géométrie commune.</p><img src="review-board.png" alt="Trois pièges intégrés au sol"><h2>Épuisés</h2><img src="spent-mobile.png" alt="Pointes et mâchoires rentrées, sceau éteint"><p>Vérifications : huit situations statiques, deux atlas précédents et 136 régions inchangés ; nouveau feuillet 512 × 512, 106 068 octets PNG, 1 Mio RGBA. Pas de validation sur téléphone ni de raid complet. L’apparence reste soumise au retour utilisateur.</p><p><a href="source/generation.json">Prompt et provenance ImageGen</a> · <a href="export-validation.json">Contrôles d’export</a> · <a href="native-validation.json">Contrôles Godot</a></p>`);
 console.log('Native trap review board written.');
}
main().catch(e=>{console.error(e);process.exitCode=1});
