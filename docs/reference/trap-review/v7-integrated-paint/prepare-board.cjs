const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
async function main(){
 const W=1130,H=960,layers=[];
 let svg=`<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" font-family="Segoe UI,Arial,sans-serif"><rect width="${W}" height="${H}" fill="#0d1420"/><text x="24" y="39" fill="#edf0f6" font-size="27">Pièges intégrés — captures Godot</text>`;
 const states=['ready','triggered','spent'];
 ['ARMÉ','DÉCLENCHÉ','ÉPUISÉ'].forEach((name,i)=>svg+=`<text x="${205+i*360}" y="83" text-anchor="middle" fill="#cbb1e9" font-size="19">${name}</text>`);
 for(const [j,[kind,name]] of [['spike','Pointes'],['snare','Entrave'],['void','Néant']].entries()){
  const y=110+j*270;
  svg+=`<text x="24" y="${y+18}" fill="#e2e7f2" font-size="21">${name}</text>`;
  for(let i=0;i<3;i++)layers.push({input:await sharp(path.join(__dirname,states[i]+'-'+kind+'.png')).extract({left:300,top:145,width:360,height:220}).png().toBuffer(),left:25+i*360,top:y+32});
 }
 svg+=`<text x="24" y="936" fill="#a8b6cd" font-size="14">Captures natives rapprochées · atlas mobile · centre et support communs aux trois états</text></svg>`;
 await sharp(Buffer.from(svg)).composite(layers).png().toFile(path.join(__dirname,'states-board.png'));
 fs.writeFileSync(path.join(__dirname,'index.html'),`<!doctype html><html lang="fr"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Pièges intégrés</title><style>body{max-width:1130px;margin:24px auto;padding:16px;background:#0d1420;color:#edf0f6;font:16px system-ui}img{display:block;width:100%;height:auto;margin:24px 0}p{color:#b4c0d3}a{color:#d0afea}</style><h1>Pièges intégrés au donjon</h1><p>Pointes et Néant de la proposition v5 ; Entrave recentrée de la v6. Les trois états répondent au déclenchement réel et aux charges restantes.</p><img src="ready-mobile.png" alt="Les trois pièges dans le donjon au zoom du jeu"><img src="states-board.png" alt="Captures natives des trois états de chaque piège"><p>La planche assemble des extraits de captures Godot à zoom rapproché. Ce zoom sert uniquement à la revue ; la caméra du jeu reste fixe.</p><p><a href="native-validation.json">Vérifications natives</a> · <a href="export-validation.json">Atlas et raccords</a> · <a href="selection.json">Sources validées</a> · <a href="preparation.json">Préparation</a></p><p>Contrôlé sur ordinateur. Pas de test tactile ni de profilage sur téléphone.</p></html>`);
 console.log('Native state board saved');
}
main().catch(e=>{console.error(e);process.exitCode=1});
