const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),sharp=require('sharp');
const DIR=__dirname,read=p=>JSON.parse(fs.readFileSync(path.join(DIR,p),'utf8'));
const reviewed=read('../geometry.json');
const faces=reviewed.models.facade.faces.filter(f=>!['floor','wall','wall-bevel'].includes(f.kind));
const colors={stone:'#46546d',horn:'#4e5d78',inner:'#303d53',recess:'#253247',leaf:'#332039',metal:'#526178',seal:'#8b32d1'};
const points=f=>f.points.map(([x,y,z])=>[512+(x-.5)*820,890-z*820]);
const area=p=>p.reduce((s,a,i)=>s+a[0]*p[(i+1)%p.length][1]-a[1]*p[(i+1)%p.length][0],0);
const body=faces.slice().sort((a,b)=>a.points.reduce((s,p)=>s+p[1]/a.points.length,0)-b.points.reduce((s,p)=>s+p[1]/b.points.length,0)).map(f=>{
  const q=points(f);if(Math.abs(area(q))<.001)return '';
  return `<polygon points="${q.map(p=>p.join(',')).join(' ')}" fill="${colors[f.kind.replace('-bevel','')]||'#46546d'}" stroke="#172031" stroke-width="1.6" stroke-linejoin="round"/>`;
}).join('');
const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024">${body}</svg>`;
fs.writeFileSync(path.join(DIR,'face-guide.svg'),svg);
sharp(Buffer.from(svg)).png().toFile(path.join(DIR,'face-guide.png')).then(()=>{
 const names=['geometry.json','wireframe-board.png','prepare.cjs','concept-selected.png'];
 const hashes=Object.fromEntries(names.map(p=>[p,crypto.createHash('sha256').update(fs.readFileSync(path.join(DIR,'..',p))).digest('hex')]));
 fs.writeFileSync(path.join(DIR,'geometry-approval.json'),JSON.stringify({date:'2026-10-26',userReply:'Ok go',status:'wireframe-approved-for-paint-and-integration',files:hashes,guideMapping:{size:[1024,1024],scale:820,xOrigin:512,xCentre:.5,zOrigin:890},newPaintingStatus:'new-painted-adaptation-not-yet-reviewed'},null,2)+'\n');
 console.log('Frontal guide and wireframe approval snapshot written.');
}).catch(e=>{console.error(e);process.exitCode=1});
