// Code-native geometric guide: not an edit of generated character pixels.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const dir=__dirname,W=448,H=448,S=340;
const project=([x,y,z])=>[(x-y)*.5*S,(x+y)*.25*S-z*.6123724357*S];
const add=(a,b)=>a.map((v,i)=>v+b[i]);
const at=(p,c,r)=>{const q=project(p);return[q[0]+c*W+230,q[1]+r*H+398]};
const polygon=(points,color,c,r)=>`<polygon points="${points.map(p=>at(p,c,r).join(',')).join(' ')}" fill="${color}" stroke="#1d2938" stroke-width="3" stroke-linejoin="round"/>`;
function boot(p,color,c,r){const [x,y,z]=p,L=.12,B=.08,h=.07;const a=[x-L,y-B,z],b=[x+L,y-B,z],d=[x-L,y+B,z],e=[x+L,y+B,z];return polygon([a,b,e,d],color,c,r)+polygon([add(a,[0,0,h]),add(b,[0,0,h]),add(e,[0,0,h]),add(d,[0,0,h])],color,c,r)+polygon([d,e,add(e,[0,0,h]),add(d,[0,0,h])],color,c,r)}
function bone(a,b,col,c,r,width=20){const p=at(a,c,r),q=at(b,c,r);return `<path d="M${p} L${q}" fill="none" stroke="#1d2938" stroke-width="${width+6}" stroke-linecap="round"/><path d="M${p} L${q}" fill="none" stroke="${col}" stroke-width="${width}" stroke-linecap="round"/>`}
let svg=`<svg xmlns="http://www.w3.org/2000/svg" width="${W*4}" height="${H*2}"><rect width="100%" height="100%" fill="#f4f5f8"/>`;
const poses=[];
for(let i=0;i<8;i++){
 const c=i%4,r=Math.floor(i/4),phase=i/8*Math.PI*2,bob=-.015*Math.cos(phase*2),hipZ=.52+bob;
 const near=[-.22*Math.cos(phase),.14,Math.max(0,Math.sin(phase))*.12],far=[.22*Math.cos(phase),-.14,Math.max(0,-Math.sin(phase))*.12];
 poses.push({frame:i,phase:i/8,nearFoot:near,farFoot:far,pelvisZ:hipZ});
 svg+=`<rect x="${c*W+5}" y="${r*H+5}" width="${W-10}" height="${H-10}" rx="8" fill="none" stroke="#c6cdd8"/>`;
 svg+=polygon([[-.5,-.35,0],[.5,-.35,0],[.5,.35,0],[-.5,.35,0]],'#e3e8ef',c,r);
 for(const [foot,y,col] of [[far,-.14,'#ed8c35'],[near,.14,'#44b7df']]){
  const hip=[0,y,hipZ],knee=[foot[0]*.5+.06,y,(hipZ+foot[2])*.5+.01],ankle=add(foot,[0,0,.08]);
  svg+=bone(hip,knee,col,c,r,24)+bone(knee,ankle,col,c,r,22)+boot(foot,col,c,r);
 }
 // Fixed torso/large head proxies give the painter consistent silhouette scale.
 svg+=polygon([[-.14,-.2,hipZ],[.14,-.2,hipZ],[.14,-.2,.95+bob],[-.14,-.2,.95+bob]],'#8794a4',c,r);
 svg+=polygon([[-.14,.2,hipZ],[.14,.2,hipZ],[.14,.2,.95+bob],[-.14,.2,.95+bob]],'#9eabbc',c,r);
 svg+=polygon([[.14,-.2,hipZ],[.14,.2,hipZ],[.14,.2,.95+bob],[.14,-.2,.95+bob]],'#aebbc9',c,r);
 for(const [y,sign,col] of [[-.25,-1,'#ed8c35'],[.25,1,'#44b7df']]){
  const swing=.12*Math.cos(phase)*sign;
  svg+=bone([0,y,.88+bob],[swing*.5,y,.71+bob],col,c,r,18)+bone([swing*.5,y,.71+bob],[swing,y,.58+bob],col,c,r,18);
 }
 const head=at([0,0,1.26+bob],c,r),snout=at([.26,0,1.14+bob],c,r);
 svg+=`<ellipse cx="${head[0]}" cy="${head[1]}" rx="78" ry="75" fill="#bdc6d2" stroke="#455163" stroke-width="3"/><ellipse cx="${snout[0]}" cy="${snout[1]}" rx="32" ry="22" fill="#d6dde7" stroke="#455163" stroke-width="3"/>`;
 svg+=polygon([[-.05,-.23,1.42],[.08,-.21,1.72],[.14,-.10,1.46]],'#adb9c9',c,r);
 svg+=polygon([[-.05,.24,1.42],[.08,.23,1.72],[.14,.1,1.46]],'#bdc6d2',c,r);
}
svg+='</svg>';
fs.writeFileSync(path.join(dir,'source/pose-guide.svg'),svg);
fs.writeFileSync(path.join(dir,'source/pose-guide.json'),JSON.stringify({status:'Geometric animation guide, not production artwork',nearColor:'cyan',farColor:'orange',poses},null,2));
sharp(Buffer.from(svg)).png().toFile(path.join(dir,'source/pose-guide.png')).then(()=>console.log('Eight opposite-phase geometric poses rendered'));
