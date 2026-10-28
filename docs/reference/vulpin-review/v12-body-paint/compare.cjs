const fs=require('fs'),path=require('path'),sharp=require('sharp');const dir=__dirname,old=path.resolve(dir,'../v11-painted-sprites');
function svg(w,h){return `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}"><rect width="100%" height="100%" fill="#142030"/>`}
function label(x,y,s,size=18){return `<text x="${x}" y="${y}" fill="#eee7fa" font-family="Arial" font-size="${size}">${s}</text>`}
(async()=>{
 let s=svg(920,620)+label(24,34,'Vulpin · corps et queue redessinés',23)+label(140,78,'Avant · peinture projetée')+label(590,78,'Après · parties peintes');const layers=[];
 for(let row=0;row<2;row++)for(let col=0;col<2;col++){const base=col?dir:old,input=path.join(base,'renders/se',row?'run/12.png':'idle/00.png'),image=await sharp(input).resize(384).png().toBuffer();layers.push({input:image,left:col*460+38,top:row*250+30});}
 s+=label(24,330,'Attente',15)+label(24,590,'Course',15);
 await sharp(Buffer.from(s+'</svg>')).composite(layers).png().toFile(path.join(dir,'before-after.png'));
 let native=svg(920,330)+label(24,32,'À la taille du jeu · même résolution 128',22);const rows=[];
 for(let d=0;d<4;d++)for(let v=0;v<2;v++){const direction=['se','sw','nw','ne'][d],base=v?dir:old;const image=await sharp(path.join(base,'frames/balanced',direction+'-idle-0.png')).resize(180).png().toBuffer();rows.push({input:image,left:d*230+25,top:v*132+15});native+=label(d*230+24,v*132+60,(v?'Après · ':'Avant · ')+direction.toUpperCase(),13);}
 await sharp(Buffer.from(native+'</svg>')).composite(rows).png().toFile(path.join(dir,'game-size-comparison.png'));
 console.log('Comparison boards complete');
})().catch(e=>{console.error(e);process.exitCode=1});

