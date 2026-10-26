// Appearance review only. Original pixels stay intact; frame the painted
// subjects with padding and resize uniformly for an editorial comparison sheet.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),sharp=require('sharp');
const ROOT=path.resolve(__dirname,'..'),flush=process.argv.includes('--flush');
const DIR=path.join(ROOT,'docs/reference/trap-review',flush?'v5-flush-states':'v4-painted-states');
const hash=p=>crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
const definitions=[
 {id:'pointes',name:'Pointes',description:'Acier taillé, logements individuels et rails sombres.',captions:['Pointes rentrées · mécanisme armé','Pointes déployées','Pointes retirées · logements éteints'],original:'exec-67c46054-36e7-4a86-9d71-52195cbd4ad2.png'},
 {id:'entrave',name:'Entrave',description:'Deux mâchoires articulées, une pédale et des ressorts.',captions:['Mâchoires ouvertes · pédale prête','Mâchoires refermées','Mâchoires verrouillées · énergie éteinte'],original:'exec-088886f3-db8f-4a4e-b823-134ffb595a37.png'},
 {id:'neant',name:'Néant',description:'Un sceau d’obsidienne en retrait dans le sol.',captions:['Sceau chargé','Vortex ouvert dans le plan du sol','Sceau refermé · gravure éteinte'],original:'exec-91dd07df-8c1b-4c2a-bce3-b4cf7da39dae.png'},
];
if(flush){
 const origins=JSON.parse(fs.readFileSync(path.join(DIR,'generation.json')));
 for(const def of definitions)def.original=origins[def.id].split(/[\\/]/).pop();
 definitions[1].description='Mâchoires articulées sur un support affleurant au dallage.';
 definitions[2].description='Sceau d’obsidienne dans le même plan que les dalles.';
}
async function main(){
 fs.mkdirSync(path.join(DIR,'views'),{recursive:true});const entries=[];
 for(const def of definitions){
  const source=path.join(DIR,'source',def.id+'.png');
  const {data,info}=await sharp(source).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  let top=info.height,bottom=-1,transparent=0;
  for(let y=0;y<info.height;y++)for(let x=0;x<info.width;x++){
   const alpha=data[(y*info.width+x)*4+3];
   if(alpha>32){top=Math.min(top,y);bottom=Math.max(bottom,y);}
   if(alpha===0)transparent++;
  }
  if(bottom<top||transparent===0)throw Error('Missing native transparency: '+def.id);
  // Threshold measures framing only. Never threshold or recolor source alpha.
  top=Math.max(0,top-24);bottom=Math.min(info.height-1,bottom+24);
  const crop={left:0,top,width:info.width,height:bottom-top+1};
  const png=await sharp(source).extract(crop).resize({width:1200}).png().toBuffer();
  const meta=await sharp(png).metadata();fs.writeFileSync(path.join(DIR,'views',def.id+'.png'),png);
  // Indicative reduction, not a claim of exact native registration or DPI.
  await sharp(source).extract(crop).resize({width:720}).png().toFile(path.join(DIR,'views',def.id+'-small.png'));
  const original='C:/Users/A/.codex/generated_images/01a15ce9-67f0-77e2-a485-14b09d65f5da/'+def.original;
  if(hash(source)!==hash(original))throw Error('Source copy differs');
  entries.push({...def,source:'source/'+def.id+'.png',sourceSize:[info.width,info.height],sha256:hash(source),original,nativeAlpha:true,crop,png,height:meta.height});
 }
 const W=1240,H=150+entries.reduce((n,e)=>n+e.height+100,0)+60,layers=[];
 let svg=`<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" font-family="Segoe UI,Arial,sans-serif"><rect width="${W}" height="${H}" fill="#0d1420"/><text x="24" y="40" fill="#ecedf5" font-size="28">Pièges — ${flush?'supports au niveau du sol':'nouvelle proposition peinte'}</text><text x="24" y="72" fill="#aab5c9" font-size="17">${flush?'Pointes conservées · Entrave et Néant remontés au niveau du dallage':'Logements sombres en retrait · silhouettes lisibles · trois états présentés'}</text>`;
 for(const [i,label]of ['ARMÉ','DÉCLENCHÉ','ÉPUISÉ'].entries())svg+=`<text x="${220+i*400}" y="122" text-anchor="middle" fill="${i===1?'#c399f4':'#dce3ef'}" font-size="20" font-weight="600">${label}</text>`;
 let y=150;
 for(const e of entries){
  svg+=`<path d="M24 ${y-10}H1216" stroke="#2d374b"/><text x="24" y="${y+19}" fill="#eef0f6" font-size="23">${e.name}</text><text x="170" y="${y+18}" fill="#aab5c9" font-size="16">${e.description}</text>`;
  layers.push({input:e.png,left:20,top:y+35});
  for(let i=0;i<3;i++)svg+=`<text x="${220+i*400}" y="${y+e.height+66}" text-anchor="middle" fill="#b5bfd1" font-size="16">${e.captions[i]}</text>`;
  y+=e.height+100;
 }
 svg+=`<text x="24" y="${H-34}" fill="#9babc4" font-size="15">Étude visuelle ImageGen · nouveaux dessins non intégrés au jeu · état déclenché proposé pour une future animation</text></svg>`;
 await sharp(Buffer.from(svg)).composite(layers).png().toFile(path.join(DIR,'comparison.png'));
 const baseline=JSON.parse(fs.readFileSync(path.join(DIR,'production-baseline.json')));
 for(const [file,h]of Object.entries(baseline))if(hash(path.join(ROOT,file))!==h)throw Error('Production changed during appearance review: '+file);
 const report={status:'Unapproved painted appearance proposal; no Godot integration',tool:'Built-in ImageGen',uniformResize:true,nativeAlphaPreserved:true,previewFraming:'Vertical bounds measured at alpha>32 with 24 source pixels padding. Crop only; source alpha never modified, original source retained byte-identical.',productionUnchanged:true,registration:'Generated perspective follows guide visually; not calibrated exact XYZ or native sprite registration',states:['armed','triggered proposal','depleted'],entries:entries.map(({png,...e})=>e)};
 fs.writeFileSync(path.join(DIR,'validation.json'),JSON.stringify(report,null,2)+'\n');
 const panels=entries.map(e=>`<section><h2>${e.name}</h2><p>${e.description}</p><div class="states"><b>Armé</b><b>Déclenché</b><b>Épuisé</b></div><a href="${e.source}"><img src="views/${e.id}.png" alt="${e.name} : armé, déclenché, épuisé"></a><div class="states captions">${e.captions.map(t=>'<span>'+t+'</span>').join('')}</div><details><summary>Voir à taille réduite</summary><p>Réduction indicative pour juger la lecture, pas une capture mobile.</p><img class="small" src="views/${e.id}-small.png" alt="États à taille réduite"></details></section>`).join('');
 fs.writeFileSync(path.join(DIR,'index.html'),`<!doctype html><html lang="fr"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Pièges · nouvelle peinture et états</title><style>body{margin:24px auto;padding:16px;max-width:1240px;background:#0d1420;color:#e8ebf5;font:16px system-ui}h1{font-size:28px}p,.captions{color:#b5bfd1}section{border-top:1px solid #303a50;margin-top:32px;padding-top:12px}.states{display:grid;grid-template-columns:repeat(3,1fr);gap:12px;text-align:center}.states b:nth-child(2){color:#c399f4}img{display:block;width:100%;height:auto;margin:8px auto}.small{width:720px;max-width:100%}a{color:#c9a4f4}summary{cursor:pointer;padding:14px 0}footer{border-top:1px solid #303a50;margin-top:28px;padding-top:16px}</style><h1>Pièges · nouvelle proposition peinte</h1><p>Le logement dans le sol reste la direction retenue. ${flush ? "Cette correction remonte les supports de l’Entrave et du Néant au niveau du dallage, comme les Pointes conservées à l’identique." : "Cette passe remplace le métal gris granuleux et clarifie le mécanisme de l’Entrave."}</p><p>Les trois états sont montrés ensemble. « Déclenché » est une proposition d’état transitoire ; il n’est pas encore animé dans le jeu. Ces nouvelles images ne sont pas intégrées.</p>${panels}<footer><a href="comparison.png">Planche complète</a> · <a href="brief.json">Prompts ImageGen</a> · <a href="validation.json">Sources et contrôles</a><p>Originaux conservés, transparence native, mise à l’échelle uniforme. Pas de modification du moteur ni des atlas actuels.</p></footer></html>`);
 console.log(JSON.stringify({board:[W,H],sources:entries.map(({id,sourceSize,crop})=>({id,sourceSize,crop})),productionUnchanged:true}));
}
main().catch(e=>{console.error(e);process.exitCode=1});
