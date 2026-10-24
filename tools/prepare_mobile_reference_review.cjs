// Side-by-side crops from real Godot captures, at identical scale (no resizing).
const path = require('node:path');
const fs = require('node:fs');
const sharp = require('sharp');
const {writeGeneratedFile} = require('./write_generated_file.cjs');
const ROOT = path.resolve(__dirname, '..');
const OUT = path.join(ROOT, 'docs/reference/mobile-optimization');
async function detailsBoard() {
  const catalog=JSON.parse(fs.readFileSync(path.join(ROOT,'assets/dungeon/mobile-reference/catalog.json'),'utf8'));
  const entries=catalog.atlases.find(a=>a.density===256).regions;
  const base=entries.pillar,mark=entries['pillar-top-carved'];
  const png=fs.readFileSync(path.join(OUT,'sprites/pillar.png'));
  const decal=fs.readFileSync(path.join(OUT,'sprites/pillar-top-carved.png'));
  const layer={input:decal,left:mark.offset[0]-base.offset[0],top:mark.offset[1]-base.offset[1]};
  const separate=await sharp({create:{width:base.size[0],height:base.size[1],channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite([layer]).png().toBuffer();
  const combined=await sharp(png).composite([layer]).png().toBuffer();
  const height=base.size[1]*3+125,width=900,layers=[];
  for(const [i,input] of [png,separate,combined].entries()) layers.push({input:await sharp(input).resize(base.size[0]*3,base.size[1]*3).png().toBuffer(),left:25+i*300,top:78});
  const labels=['Pilier de base','Dessus sculpté','Superposition'];
  const bg=Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}"><defs><pattern id="checker" width="24" height="24" patternUnits="userSpaceOnUse"><rect width="24" height="24" fill="#182030"/><path d="M0 0H12V12H0ZM12 12H24V24H12Z" fill="#202a3b"/></pattern></defs><rect width="100%" height="100%" fill="#080e19"/><rect x="315" y="68" width="270" height="${base.size[1]*3+16}" fill="url(#checker)"/><g font-family="Arial,sans-serif" fill="#e1e8f4">${labels.map((label,i)=>`<text x="${25+i*300}" y="40" font-size="22">${label}</text>`).join('')}<text x="25" y="${height-17}" font-size="18" fill="#aebdd2">Un pilier commun + un petit détail réutilisable · agrandissement ×3 pour montrer les couches</text></g></svg>`);
  writeGeneratedFile(path.join(OUT,'details-review/layers.png'),await sharp(bg).composite(layers).png().toBuffer());
}
async function board(name, title, panels, footer) {
  const crop = {left:260,top:76,width:670,height:520};
  const layers=[];
  for (let i=0;i<panels.length;i++) layers.push({input:await sharp(path.join(OUT,'captures',panels[i][0]+'.png')).extract(crop).png().toBuffer(),left:20+i*690,top:100});
  const bg=Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="1400" height="685"><rect width="100%" height="100%" fill="#080e19"/><g font-family="Arial,sans-serif"><text x="20" y="34" font-size="25" fill="#e1e8f4">${title}</text>${panels.map((p,i)=>`<text x="${20+i*690}" y="79" font-size="21" fill="#c5cfdf">${p[1]}</text>`).join('')}<text x="20" y="659" font-size="18" fill="#9aabc6">${footer}</text></g></svg>`);
  writeGeneratedFile(path.join(OUT,name+'.png'),await sharp(bg).composite(layers).png().toBuffer());
}
async function main() {
  await detailsBoard();
  await board('floor-comparison','Proportions du sol · même scène, même cadrage',[
    ['previous-floor','Sol actuel · 2 rangées par case'],['proposed-256','Proposition · 3 rangées par case']
  ],'Les piliers et murs proposés sont identiques des deux côtés. Grille logique 1 × 1 conservée.');
  await board('resolution-comparison','Résolution des sprites · même taille à l’écran',[
    ['proposed-128','128 px / case · atlas 512 × 256'],['proposed-256','256 px / case · atlas 1024 × 512']
  ],'Captures Godot à 1280 × 720 · extraits sans redimensionnement · vue fixe à 192 pixels par case.');
  const before=path.join(OUT,'join-review/before.png');
  if(fs.existsSync(before)) {
    const layers=[];
    // Freeze the depth comparison before the later ornament appearance review.
    const frozenAfter=path.join(ROOT,'docs/reference/mobile-decoration-review/source/scene-before.png');
    for(const [i,file] of [before,fs.existsSync(frozenAfter)?frozenAfter:path.join(OUT,'captures/proposed-256.png')].entries()) {
      layers.push({input:await sharp(file).extract({left:265,top:76,width:190,height:180}).resize(380,360).png().toBuffer(),left:20+i*400,top:60});
    }
    const background=Buffer.from('<svg xmlns="http://www.w3.org/2000/svg" width="820" height="445"><rect width="100%" height="100%" fill="#080e19"/><g fill="#e1e8f4" font-family="Arial" font-size="23"><text x="20" y="36">Avant · pilier toujours devant</text><text x="420" y="36">Après · ordre de profondeur</text></g></svg>');
    writeGeneratedFile(path.join(OUT,'join-review/top-corner.png'),await sharp(background).composite(layers).png().toBuffer());
  }
  console.log('Saved floor-comparison.png and resolution-comparison.png');
}
main().catch(e=>{console.error(e.stack);process.exitCode=1;});
