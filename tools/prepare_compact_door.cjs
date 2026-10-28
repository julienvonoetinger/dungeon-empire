// Revised proportions after the tall arch and raised lock were rejected.
// A shallow crown and slimmer posts; original masonry contacts stay intact.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp'),assert=require('node:assert/strict');
const P=require('./isometric_paint_geometry.cjs'),W=require('./prepare_seal_junction_wireframe.cjs');
const {rotations,edges,band}=require('./prepare_hero_scale_door.cjs');
const DIR='docs/reference/door-redesign/seal-v1/hero-fit-v11-compact',OUT=path.join(P.ROOT,DIR);
const prior=JSON.parse(fs.readFileSync(path.join(OUT,'../hero-fit-v9/geometry.json')));
const height=z=>z<=P.H?z:z<=.82?P.H+(z-P.H)*(.84-P.H)/(.82-P.H):z<=1.063?.84+(z-.82)*(.96-.84)/.243:.96+(z-1.063)*(1.16-.96)/.382;
// Keep the exterior face on the wall axis. Remove thickness toward the
// passage, never move the whole column inwards and leave a shelf at the wall.
const slender=x=>x>.5?1-slender(1-x):x<=0?x:x<=.17?x*.1/.17:x<=.255?x-.07:.5+(x-.5)*.315/.245;
const point=([x,y,z])=>[slender(x),y,height(z)];
async function main(){
 fs.mkdirSync(OUT,{recursive:true});
 const door=edges({...structuredClone(prior.door),faces:prior.door.faces.map(f=>({...f,points:f.kind==='junction'?structuredClone(f.points):f.points.map(p=>point(p,f.kind.startsWith('leaf')))}))});
 const leaf={...prior.leaf,profileXZ:prior.leaf.profileXZ.map(([x,z])=>[slender(x),height(z)])};
 const models={};for(const[d,tr]of Object.entries(rotations))models[d]=edges({...structuredClone(door),id:d,faces:door.faces.map(f=>({...f,points:f.points.map(tr)}))});
 assert.deepEqual(door.faces.filter(f=>f.kind==='junction'),prior.door.faces.filter(f=>f.kind==='junction'));
 const mapping={size:[1024,1536],scale:820,xOrigin:512,xCentre:.5,zOrigin:1400},project=([x,y,z])=>[512+(x-.5)*820,1400-z*820];
 const surfaces=door.faces.slice().sort((a,b)=>a.points.reduce((s,p)=>s+p[1],0)/a.points.length-b.points.reduce((s,p)=>s+p[1],0)/b.points.length).map(f=>`<polygon points="${f.points.map(p=>project(p).join(',')).join(' ')}" fill="${f.kind.startsWith('leaf')?'#3c3d4a':'#414e63'}"/>`).join('');
 const lines=P.visibleEdges(door,{x:[1,0,0],y:[0,0,-1],eye:[0,1,0]}).map(e=>`<path d="M${project(e.a)}L${project(e.b)}"/>`).join('');
 const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1536">${surfaces}<g fill="none" stroke="#ff00ff" stroke-width="1.5">${lines}</g></svg>`;
 fs.writeFileSync(path.join(OUT,'face-guide-magenta.svg'),svg);await sharp(Buffer.from(svg)).png().toFile(path.join(OUT,'face-guide-magenta.png'));
 const lock=project([.5,.525,.32]),hinges=[.16,.64].map(z=>project([slender(.255),.525,z]));
 const hardware=`<g stroke="#ffc96b" fill="none" stroke-width="4"><circle cx="${lock[0]}" cy="${lock[1]}" r="16"/>${hinges.map(([x,y])=>`<rect x="${x-10}" y="${y-25}" width="20" height="50"/>`).join('')}</g>`;
 await sharp(Buffer.from(svg.replace('</svg>',hardware+'</svg>'))).png().toFile(path.join(OUT,'hardware-placement-guide.png'));
 fs.writeFileSync(path.join(OUT,'geometry.json'),JSON.stringify({status:'compact-wireframe-review',camera:P.camera,span:prior.span,door,models,leaf},null,2));
 fs.writeFileSync(path.join(OUT,'checks.json'),JSON.stringify({oldTotalHeight:1.445,totalHeight:1.16,heightReductionPercent:(1-1.16/1.445)*100,openingHeight:.96,openingWidth:.63,standingHeroHeight:.85268495519,postWidthAboveWallBefore:.17+P.T/2,postWidthAboveWall:.1+P.T/2,exteriorPostFaceUnchanged:true,masonryDepthUnchanged:true,lowJunctionsUnchanged:true,guide:{mapping},hardware:{lock:{x:.5,z:.32,pixel:lock},hinges:hinges.map((pixel,i)=>({x:slender(.255),z:[.16,.64][i],pixel})),textureOnly:true}},null,2));
 console.log('Compact geometry: height 1.16 (-19.7%); columns slimmed on passage side; exterior faces and depth retained.');
}
if(require.main===module)main().catch(e=>{console.error(e);process.exitCode=1});
module.exports={OUT,DIR,rotations,edges,band};
