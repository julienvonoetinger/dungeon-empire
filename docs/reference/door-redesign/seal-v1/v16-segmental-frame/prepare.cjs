// Isolated door study. Every outline comes from the same transverse XZ profile.
const fs = require('node:fs'), path = require('node:path'), assert = require('node:assert/strict'), sharp = require('sharp');
const P = require('../../../../../tools/isometric_paint_geometry.cjs');
const {rotations} = require('../../../../../tools/prepare_hero_scale_door.cjs');
const old = require('../hero-fit-v12-integrated/geometry.json');
const swept = require('../hero-fit-v11-compact/passage-validation.json');
// Each post sits on the centreline of its rail. Its footprint is one wall
// thickness in both directions, so neither face steps out into the corridor.
const left = -P.T / 2, right = 1 - left;
const back = .5 - P.T / 2, front = .5 + P.T / 2;
const spring = .87, innerLeft = P.T / 2, innerRight = 1 - innerLeft;
// Near-face tracings in reference-couronne.png (540 x 368). Each row is one
// stone; the oblique seams have different stations at the rim and at the soffit.
const outerTrace = [
  [[71,76],[104,78],[143,82]], [[143,82],[183,89],[222,97],[260,105]],
  [[260,105],[290,126],[324,151],[354,176]], [[354,176],[388,207],[420,238],[448,265]],
];
const innerTrace = [
  [[120,158],[143,153],[169,151]], [[169,151],[196,151],[230,154],[258,160]],
  [[258,160],[284,179],[311,200],[337,221]], [[337,221],[357,243],[382,273],[402,301]],
];
const pixelsPerZ = (448-71)/(right-left)*(-P.camera.y[2]/P.camera.x[0]);
const shoulder = spring+(139-76)/pixelsPerZ;
function liftTrace(trace, xmin, xmax, z) {
  const [x0,y0]=trace[0][0], [x1,y1]=trace.at(-1).at(-1);
  return trace.map(row=>row.map(([x,y])=>{
    const t=(x-x0)/(x1-x0);
    return [xmin+(xmax-xmin)*t, z+(y0+(y1-y0)*t-y)/pixelsPerZ];
  }));
}
const reflect=row=>[...row].reverse().map(([x,z])=>[1-x,z]);
function symmetricProfile(rows){
  // Average corresponding stations on the two traced stones, then construct
  // both sides from that half. All coordinates here are in the door's XZ plane.
  const half=rows.slice(0,2).map((row,i)=>{
    const opposite=reflect(rows[3-i]);
    const count=Math.max(row.length,opposite.length);
    return Array.from({length:count},(_,j)=>{
      const t=j/(count-1);
      const x=row[0][0]+(row.at(-1)[0]-row[0][0])*t;
      const u=opposite[0][0]+(opposite.at(-1)[0]-opposite[0][0])*t;
      return [(x+u)/2,(roof(row,x)+roof(opposite,u))/2];
    });
  });
  half[1].at(-1)[0]=.5;
  return [...half,...[...half].reverse().map(reflect)];
}
const outer=symmetricProfile(liftTrace(outerTrace,left,right,shoulder));
const inner=symmetricProfile(liftTrace(innerTrace,innerLeft,innerRight,spring));
for(const rows of [outer,inner]){
  assert.equal(rows[1].at(-1)[0],.5,'central joint must lie on the door axis');
  for(const [i,row] of rows.entries()){
    const opposite=rows[rows.length-1-i];
    assert.equal(row.length,opposite.length,'paired stones must have matching profiles');
    row.forEach(([x,z],j)=>{
      const other=opposite[opposite.length-1-j];
      assert(Math.abs(x+other[0]-1)<1e-10 && Math.abs(z-other[1])<1e-10,'asymmetric stone');
    });
  }
}
// Compare the silhouette at the original reference stations. The joints now
// follow frontal symmetry rather than the slightly uneven seams in the crop.
for(const [trace,points] of [[outerTrace,outer],[innerTrace,inner]]){
  const outline=points.flatMap((row,i)=>i?row.slice(1):row);
  const u0=trace[0][0][0], u1=trace.at(-1).at(-1)[0];
  for(const [u,v] of trace.flat()){
    const x=outline[0][0]+(outline.at(-1)[0]-outline[0][0])*(u-u0)/(u1-u0);
    const z=roof(outline,x);
    const sx=71+(x-left)*377/(right-left);
    const sy=139+(sx-71)*P.camera.y[0]/P.camera.x[0]-(z-spring)*pixelsPerZ;
    assert(Math.abs(sx-u)<=9 && Math.abs(sy-v)<=9,'reference profile drift');
  }
}
const parts = {leaf:[], 'jamb-right':[], arch:[], panel:[]};
function extrude(target, block, profile, near=front, far=back) {
  const a=profile.map(([x,z])=>[x,near,z]), b=profile.map(([x,z])=>[x,far,z]);
  const add=(points,surface)=>target.push({points,block,surface});
  add(a,'facade'); add([...b].reverse(),'facade');
  for(let i=0;i<a.length;i++){const j=(i+1)%a.length;add([a[i],a[j],b[j],b[i]],'edge');}
}
function voussoir(block, polygon) {
  // Each block has its own small chamfer. Use a fan inside the stone so the
  // shallow concavity of its underside never fills any part of the opening.
  const bevel=.009, faces=parts.arch, n=polygon.length;
  const c=[0,1].map(k=>polygon.reduce((sum,p)=>sum+p[k],0)/n);
  const normals=polygon.map(([x,z],i)=>{
    const next=polygon[(i+1)%n], dx=next[0]-x, dz=next[1]-z, length=Math.hypot(dx,dz);
    assert(length>0 && dx*(c[1]-z)-dz*(c[0]-x)>0,'centre inside stone fan');
    return [-dz/length,dx/length];
  });
  const inset=polygon.map((p,i)=>{
    const a=normals[(i+n-1)%n], b=normals[i], k=bevel/(1+a[0]*b[0]+a[1]*b[1]);
    return [p[0]+k*(a[0]+b[0]),p[1]+k*(a[1]+b[1])];
  });
  const vertex=([x,z],y)=>[x,y,z];
  const face=(points,surface)=>faces.push({points,block,surface});
  for(let i=0;i<n;i++){
    const j=(i+1)%n, p=polygon[i], q=polygon[j];
    for(const [y,lip] of [[front,front-bevel],[back,back+bevel]]){
      face([vertex(c,y),vertex(inset[i],y),vertex(inset[j],y)],'facade');
      face([vertex(inset[i],y),vertex(inset[j],y),vertex(q,lip),vertex(p,lip)],'bevel');
    }
    face([vertex(p,back+bevel),vertex(q,back+bevel),vertex(q,front-bevel),vertex(p,front-bevel)],'edge');
  }
}
const crown=inner.map((row,i)=>{
  const p=[...row];
  if(i===inner.length-1)p.push([right,spring]);
  p.push(...[...outer[i]].reverse());
  if(i===0)p.push([left,spring]);
  return p;
});
crown.forEach((p,i)=>voussoir('arch-'+i,p));
const profile=inner.flatMap((row,i)=>i ? row.slice(1) : row);
for(const [key,lo,hi] of [['leaf',left,profile[0][0]],['jamb-right',profile.at(-1)[0],right]]){
  // The corridor owns both lower courses. The door's first stone rests on the wall cap.
  const courses=[P.H,(P.H+spring)/2,spring];
  for(let i=1;i<courses.length;i++){
    extrude(parts[key],key+i,[[lo,courses[i-1]],[hi,courses[i-1]],[hi,courses[i]],[lo,courses[i]]]);
  }
}
const leaf=[[profile[0][0],0],...profile,[profile.at(-1)[0],0]];
extrude(parts.panel,'panel',leaf,old.leaf.frontY,old.leaf.backY);

function roof(points,x){
  const i=points.findIndex((p,j)=>j && x<=p[0]+1e-9);
  const [a,b]=[points[i-1],points[i]];
  return a[1]+(b[1]-a[1])*(x-a[0])/(b[0]-a[0]);
}
const oldRoof=old.leaf.profileXZ.slice(1,-1);
assert(profile[0][0] < oldRoof[0][0] && profile.at(-1)[0] > oldRoof.at(-1)[0]);
// Both roofs are piecewise linear. Testing every breakpoint in their shared
// interval proves that the previous validated swept opening is contained.
for(const [x] of [...oldRoof,...profile]){
  if(x>=oldRoof[0][0] && x<=oldRoof.at(-1)[0])assert(roof(profile,x)>=roof(oldRoof,x)-1e-8);
}
assert(swept.samples.length===17 && swept.samples.every(s=>s.new_outside===0));
assert(Math.abs(left+P.T/2)<1e-9 && Math.abs(right-1-P.T/2)<1e-9);

async function raster(direction, key, tr) {
  const faces=parts[key].map(f=>({...f,points:f.points.map(tr)})), pts=faces.flatMap(f=>f.points);
  const screen=pts.map(P.project), offset=[0,1].map(i=>Math.floor(Math.min(...screen.map(p=>p[i])))-2);
  const size=[0,1].map(i=>Math.ceil(Math.max(...screen.map(p=>p[i])))+2-offset[i]);
  const ss=3, r=P.raster({faces},[...offset,...size],ss), normals=faces.map(f=>P.normal(f.points));
  const raw=Buffer.alloc(r.width*r.height*4);
  for(let y=0;y<r.height;y++)for(let x=0;x<r.width;x++){
    const k=y*r.width+x, id=r.owner[k];if(id<0)continue;
    let line=false;
    for(const dk of [-ss,ss,-ss*r.width,ss*r.width]){
      const j=r.owner[k+dk];
      if(j===undefined || j<0 || faces[id].block!==faces[j].block || Math.abs(P.dot(normals[id],normals[j]))<.83){line=true;break;}
    }
    const n=normals[id], light=.75+.24*n[2]+.10*n[1];
    const base=key==='panel'?[43,49,64]:[77,88,110], rgb=line?[177,130,177]:base.map(v=>Math.round(v*light));
    raw.set([...rgb,255],k*4);
  }
  const file='parts/'+direction+'-'+key+'.png';
  await sharp(raw,{raw:{width:r.width,height:r.height,channels:4}}).resize(...size).png().toFile(path.join(__dirname,file));
  const entry={file,offset,size,bounds:{min:[0,1,2].map(i=>Math.min(...pts.map(p=>p[i]))),max:[0,1,2].map(i=>Math.max(...pts.map(p=>p[i])))}};
  return entry;
}
async function main(){
  fs.mkdirSync(path.join(__dirname,'parts'),{recursive:true});
  const catalog={};
  for(const [direction,tr] of Object.entries(rotations))for(const key of Object.keys(parts))
    catalog['door-'+direction+'-'+key]=await raster(direction,key,tr);
  fs.writeFileSync(path.join(__dirname,'parts.json'),JSON.stringify(catalog,null,2)+'\n');
  const project=([x,z])=>[(x-left)*360+22,441-z*360].join(',');
  const polygons=Object.values(parts).flat().filter(f=>f.surface==='facade' && f.points[0][1]>.5);
  // Union the contiguous crown strips into one path per stone on the guide.
  const shapes=polygons.filter(f=>!f.block.startsWith('arch')).map(f=>({p:f.points.map(([x,y,z])=>[x,z]),fill:f.block==='panel'?'#2b3140':'#47546b'}));
  for(const p of crown)shapes.push({p,fill:'#506079'});
  const svg='<svg xmlns="http://www.w3.org/2000/svg" width="464" height="464" viewBox="0 0 464 464">'+shapes.map(s=>'<polygon points="'+s.p.map(project).join(' ')+'" fill="'+s.fill+'" stroke="#e887dc" stroke-width="1.3" stroke-linejoin="round"/>').join('')+'</svg>';
  fs.writeFileSync(path.join(__dirname,'face-guide.svg'),svg);
  console.log('Four compass views; four traced stones on intact walls; clear opening contains the previous 17-pose validated profile.');
}
module.exports = {parts, crown, profile, back, front, innerLeft, innerRight};
if (require.main === module) main().catch(error=>{console.error(error);process.exitCode=1});
