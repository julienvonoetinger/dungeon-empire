const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
async function main(){const width=892,height=1436,layers=[];let labels='<text x="24" y="36" font-size="23" fill="#ece6f2">Dungeon Empire · trois interfaces de maître du donjon</text>';
const entries=[['obsidian','A · Obsidienne','Palette basse persistante · recommandation'],['forge','B · La forge','Palette au pouce · fer et braise'],['grimoire','C · Le grimoire','Familles visibles · pierre et argent']];
for(let i=0;i<entries.length;i++){const [theme,title,subtitle]=entries[i],y=69+i*448;labels+=`<text x="24" y="${y}" fill="#d4bce6" font-size="18">${title}</text><text x="868" y="${y}" text-anchor="end" fill="#a59cae" font-size="12">${subtitle}</text>`;layers.push({input:path.join(__dirname,`captures/844-${theme}.png`),left:24,top:y+14});}
labels+='<text x="24" y="1420" fill="#9e95a8" font-size="12">Maquettes interactives · sprites actuels · fond de caverne proposé · aucune intégration au jeu</text>';
layers.push({input:Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" font-family="Arial,sans-serif">${labels}</svg>`),left:0,top:0});
await sharp({create:{width,height,channels:4,background:'#121116'}}).composite(layers).png().toFile(path.join(__dirname,'comparison.png'));console.log('comparison.png: 892 x 1436');}
main().catch(e=>{console.error(e);process.exitCode=1;});
