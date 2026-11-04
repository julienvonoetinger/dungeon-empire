// A real below-ground stairwell, rendered with the dungeon's existing stone pipeline.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs'),Stone=require('./isometric_stone_paint.cjs');
const out=path.join(P.ROOT,'assets/game/introduction/stairwell');
const review=path.join(P.ROOT,'docs/reference/invocation-magic/stairwell');
const m={id:'stair-invocation',faces:[],edges:[],curvedStrips:[]};
function box(x,X,y,Y,z,Z,kind='stair'){
 const p=[[x,y,z],[X,y,z],[X,Y,z],[x,Y,z],[x,y,Z],[X,y,Z],[X,Y,Z],[x,Y,Z]];
 for(const ids of [[0,3,2,1],[4,5,6,7],[0,1,5,4],[1,2,6,5],[2,3,7,6],[3,0,4,7]])m.faces.push({points:ids.map(i=>p[i]),kind});
 for(const [a,b] of [[0,1],[1,2],[2,3],[3,0],[4,5],[5,6],[6,7],[7,4],[0,4],[1,5],[2,6],[3,7]])m.edges.push({a:p[a],b:p[b],kind:'wall'});
}
// The first tread meets the surface. Every following tread is lower.
for(let i=0;i<8;i++)box(-.58,.58,.9-(i+1)*.225,.9-i*.225,-.52,-i*.065);
// Retaining cheeks, with a walkable mouth instead of a vertical arch/portal.
box(-.73,-.58,-1.,.98,-.52,.045);
box(.58,.73,-1.,.98,-.52,.045,'lip');
box(-.58,.58,-1.,-.9,-.52,.045);
box(-.58,.58,.9,.98,-.08,0.,'lip');
// Masonry seams follow the same world dimensions as the existing dungeon.
for(const x of [-.73,-.58,.58,.73])for(const y of [-.65,-.30,.05,.40,.75])m.edges.push({a:[x,y,-.52],b:[x,y,.045],kind:'joint'});
async function main(){
 const ps=m.faces.flatMap(f=>f.points),qs=ps.map(P.project);
 const lo=[0,1].map(i=>Math.floor(Math.min(...qs.map(p=>p[i])))-4),hi=[0,1].map(i=>Math.ceil(Math.max(...qs.map(p=>p[i])))+4);
 m.frame=[...lo,...hi.map((v,i)=>v-lo[i])];
 m.bounds={min:[-.73,-1,-.52],max:[.73,.98,.045]};
 m.visibleEdges=P.visibleEdges(m,P.camera);
 const painted=await Stone.architecture(m);
 fs.mkdirSync(out,{recursive:true});fs.mkdirSync(review,{recursive:true});
 fs.writeFileSync(path.join(out,'stairs.png'),painted.png);
 const im=await sharp(painted.png).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 const lip=Buffer.alloc(im.data.length),caster=P.caster(m);
 for(let y=0;y<im.info.height;y++)for(let x=0;x<im.info.width;x++){
  const hit=caster([m.frame[0]+x+.5,m.frame[1]+y+.5]);
  if(hit?.face.kind==='lip')im.data.copy(lip,(y*im.info.width+x)*4,(y*im.info.width+x)*4,(y*im.info.width+x)*4+4);
 }
 await sharp(lip,{raw:{width:im.info.width,height:im.info.height,channels:4}}).png().toFile(path.join(out,'lip.png'));
 const metadata={frame:m.frame,ground:[[-.58,.9,0],[.58,.9,0],[.58,-.9,0],[-.58,-.9,0]].map(P.project),mouth:P.project([0,.9,0]),bottom:P.project([0,-.7875,-.455]),bottomGround:P.project([0,-.7875,0]),treads:8,depths:Array.from({length:8},(_,i)=>-i*.065)};
 fs.writeFileSync(path.join(out,'geometry.json'),JSON.stringify(metadata,null,2)+'\n');
 fs.writeFileSync(path.join(review,'geometry.json'),JSON.stringify({model:m,metadata,recipe:'tools/prepare_invocation_stairwell.cjs'},null,2)+'\n');
 console.log(JSON.stringify(metadata));
}
main().catch(e=>{console.error(e);process.exitCode=1;});
