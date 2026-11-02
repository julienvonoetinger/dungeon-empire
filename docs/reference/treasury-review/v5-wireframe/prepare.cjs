// Reproduce the grayscale/pink wireframes without painting or exporting game assets.
const fs=require("node:fs"),path=require("node:path"),assert=require("node:assert/strict"),sharp=require("sharp");
const P=require("../../../../tools/isometric_paint_geometry.cjs");
const {SIDES,key,point,slots,layout,corridor}=require("./layout.cjs");
const output=__dirname, interim=path.join(P.ROOT,"artifacts/treasury-wireframe");
fs.mkdirSync(interim,{recursive:true});
const catalog=require("../../../../assets/dungeon/isometric-kit/catalog.json");
const {wallThickness:T,wallHeight:H,pillarWidth}=catalog,q=pillarWidth/2;
assert.deepEqual(catalog.camera,P.camera);
const solid=(m,profile,transform,depth1,depth2,kind)=>{
  const a=profile.map(([u,z])=>transform(u,depth1,z)),b=profile.map(([u,z])=>transform(u,depth2,z));
  m.faces.push({kind,points:a},{kind,points:b.slice().reverse()});
  a.forEach((v,i)=>{const j=(i+1)%a.length;m.faces.push({kind,points:[v,a[j],b[j],b[i]]});});
};
function boundary(cells){
  const axes=new Map();
  for(const k of cells){
    const [x,y]=k.split(",").map(Number);
    for(const [dx,dy,axis,ax,ay] of [[0,-1,1,x,y],[0,1,1,x,y+1],[-1,0,2,x,y],[1,0,2,x+1,y]]){
      if(cells.has(key([x+dx,y+dy])))continue;
      for(const p of [[ax,ay],[ax+(axis===1?1:0),ay+(axis===2?1:0)]])axes.set(key(p),(axes.get(key(p))||0)|axis);
    }
  }
  return p=>axes.get(key(p))===3;
}
const model=()=>({faces:[],edges:[],curvedStrips:[]});
function bay(b,corner,hasPillar){
  const m=model(),{side,first,count}=b,u1=first,u2=first+count;
  const a=point(side,u1),e=point(side,u2);
  const lo=hasPillar(a)?u1+q:u1,hi=hasPillar(e)?u2-q:u2;
  const starts=key(a)===key(corner),ends=key(e)===key(corner);
  assert(starts!==ends);
  const top=count===2?.87:.68, spring=count===2?.235:.20,band=count===2?.115:.086;
  const reach=hi-lo, outer=reach*(count===2?.425:.40),mid=(lo+hi)/2,inner=outer-band;
  const outerZ=top-spring-.065,innerZ=outerZ-band, seg=count===2?11:7;
  const tr=(u,v,z)=>[...point(side,u,v),z];
  function part(poly,kind,v1=-T/2,v2=T/2){solid(m,poly,tr,v1,v2,kind);}
  function rect(l,r,z,Z,kind,v1,v2){part([[l,z],[r,z],[r,Z],[l,Z]],kind,v1,v2);}
  // When an end meets ordinary masonry, its complete contact face has the
  // existing wall section T x H, including the horizontal brick-course joint.
  for(const [l,r,leftZ,rightZ] of [[lo,mid-outer,starts?top:H,top],[mid+outer,hi,top,ends?top:H]]){
    rect(l,r,0,H/2,"support");
    part([[l,H/2],[r,H/2],[r,rightZ],[l,leftZ]],"shoulder");
  }
  // Solid rear closure is recessed into the wall; the vault is never another exit.
  const depths=[0,H/2,H,(H+top)/2,top];
  for(let row=1;row<depths.length;row++){
    const cuts=row%2===0?[0,.5,1]:[0,.28,.74,1];
    for(let j=1;j<cuts.length;j++){
      rect(mid-outer+2*outer*cuts[j-1],mid-outer+2*outer*cuts[j],depths[row-1],depths[row],"back",-T/2,-T/2+.025);
    }
  }
  // Inside dressings stop at the inner surface of the solid backing. From
  // outside the camera sees masonry, not coplanar outlines of a second arch.
  const insideBack=-T/2+.025;
  rect(mid-outer,mid+outer,0,.045,"sill",insideBack,T/2);
  rect(mid-outer,mid-inner,.045,spring,"arch",insideBack,T/2);
  rect(mid+inner,mid+outer,.045,spring,"arch",insideBack,T/2);
  function arc(r,rz,i){
    const angle=Math.PI*(1-i/seg);return [mid+Math.cos(angle)*r,spring+Math.sin(angle)*rz];
  }
  for(let i=0;i<seg;i++){
    const a=arc(inner,innerZ,i),b=arc(inner,innerZ,i+1),A=arc(outer,outerZ,i),B=arc(outer,outerZ,i+1);
    part([a,b,B,A],"arch",insideBack,T/2);
    part([A,B,[B[0],top],[A[0],top]],"infill",insideBack,T/2);
  }
  const joins=[{at:a,u:lo,pillar:hasPillar(a),corner:starts},{at:e,u:hi,pillar:hasPillar(e),corner:ends}];
  return {m,joins,lo,hi,top};
}
function pier(p){
  const m=model(),tr=(x,y,z)=>[p[0]+x,p[1]+y,z];
  const levels=[0,H/2,H,.68,.87];
  for(let i=1;i<levels.length;i++)solid(m,[[-q,levels[i-1]],[q,levels[i-1]],[q,levels[i]],[-q,levels[i]]],tr,-q,q,"pier");
  return m;
}
const saved=new Map();
async function sprite(id,m){
  if(saved.has(id))return saved.get(id);
  // Only requested profile edges. Equal-depth coincident masonry faces join like the native kit.
  m.edges=m.faces.flatMap(f=>f.points.map((a,i)=>({a,b:f.points[(i+1)%f.points.length],kind:f.kind})));
  const verts=m.faces.flatMap(f=>f.points);
  const bounds=[0,1,2].map(i=>[Math.min(...verts.map(p=>p[i])),Math.max(...verts.map(p=>p[i]))]);
  const xy=verts.map(P.project),orig=[0,1].map(i=>Math.floor(Math.min(...xy.map(p=>p[i])))-2);
  const frame=[...orig,...orig.map((v,i)=>Math.ceil(Math.max(...xy.map(p=>p[i])))-v+2)],scale=2;
  const r=P.raster(m,frame,scale),raw=Buffer.alloc(r.width*r.height*4);
  const normals=m.faces.map(f=>P.normal(f.points)),palette={arch:[105,101,124],infill:[66,67,83],pier:[80,78,98],support:[80,81,92],shoulder:[78,77,91],back:[56,56,70],sill:[87,87,100]};
  for(let i=0;i<r.owner.length;i++){const j=r.owner[i];if(j<0)continue;const n=normals[j],v=.63+.3*Math.abs(n[2])+.09*Math.abs(n[1]);
    for(let c=0;c<3;c++)raw[i*4+c]=Math.round(palette[m.faces[j].kind][c]*v);raw[i*4+3]=255;
  }
  const lines=P.visibleEdges(m,P.camera).map(e=>'<path '+(e.kind==="back"?'stroke="#987d9c" ':'')+'d="M'+P.project(e.a)+' L'+P.project(e.b)+'"/>').join("");
  const svg=Buffer.from('<svg xmlns="http://www.w3.org/2000/svg" width="'+r.width+'" height="'+r.height+'" viewBox="'+frame.join(" ")+'"><g fill="none" stroke="#eb94ef" stroke-width=".78" stroke-linecap="round">'+lines+'</g></svg>');
  await sharp(raw,{raw:{width:r.width,height:r.height,channels:4}}).composite([{input:svg}]).png().toFile(path.join(interim,id+".png"));
  const info={id,frame,min:bounds.map(b=>b[0]),max:bounds.map(b=>b[1])};saved.set(id,info);return info;
}
async function main(){
  const room=["0,0","1,0","0,1","1,1"],chests=new Set(room),rows=[];
  for(let mask=0;mask<256;mask++){
    const open=slots.filter((_,i)=>mask&(1<<i));const cells=new Set([...room,...open.map(s=>key(s.outside))]);
    assert.equal(Boolean(layout(cells,chests)),open.length===1,"Mouth count mask "+mask);
  }
  for(const mouth of slots){
    const pathCells=corridor(mouth),cells=new Set([...room,...pathCells.map(key)]);
    const choice=layout(cells,chests);assert.equal(choice.mouth.id,mouth.id);
    assert(!layout(cells,new Set(room.slice(1))));
    const hasPillar=boundary(cells),objects=[],hosts=[];
    assert(hasPillar(choice.corner));
    for(const b of choice.bays){
      const result=bay(b,choice.corner,hasPillar),{side,first,count}=b;
      for(let i=0;i<count;i++){
        assert(side!==mouth.side || first+i!==mouth.slot);
        const p=point(side,first+i);
        const bits=Number(hasPillar(p))+2*Number(hasPillar(point(side,first+i+1)));
        hosts.push({prefix:"wall-"+SIDES[side].axis+"-"+bits,at:p});
      }
      const id="bay-"+side+"-"+first+"-"+count+"-"+(result.joins[0].corner?"a":"b")+result.joins.map(j=>Number(j.pillar)).join("");
      const art=await sprite(id,result.m);
      const along=SIDES[side].axis==="h"?0:1,across=1-along,axis=point(side,first)[across];
      assert(Math.abs(art.min[along]-result.lo)<1e-8 && Math.abs(art.max[along]-result.hi)<1e-8);
      assert(Math.abs(art.min[across]-(axis-T/2))<1e-8 && Math.abs(art.max[across]-(axis+T/2))<1e-8);
      objects.push(art);
    }
    hosts.push({prefix:"pillar",at:choice.corner});
    objects.push(await sprite("pier-"+choice.corner.join("-"),pier(choice.corner)));
    rows.push({id:mouth.id,side:mouth.side,slot:mouth.slot,passage:pathCells,corner:choice.corner,bays:choice.bays,hosts,objects});
  }
  const data={projection:catalog.camera,wallThickness:T,wallHeight:H,pillarWidth,perimeterMasks:256,rows};
  fs.writeFileSync(path.join(output,"layouts.json"),JSON.stringify(data,null,2)+"\n");
  console.log("8 orientations. All 256 boundary masks and contact bounds verified. "+saved.size+" wireframe modules.");
}
if(require.main===module)main().catch(e=>{console.error(e);process.exitCode=1;});
module.exports={bay,pier,boundary};
