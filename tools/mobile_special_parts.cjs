// Prepared 3D projections only. No image deformation or pixel generation in Godot.
const sharp=require('sharp');
const R=require('./painted_material_renderer.cjs');
const B=require('./prepare_mobile_reference.cjs');
const {writeGeneratedFile:write}=require('./write_generated_file.cjs');
const path=require('node:path');
const OUT='docs/reference/mobile-kit';
const source=JSON.parse(R.read('docs/reference/door-arch-cell-west-east-wireframe.json'));
const stairSource=JSON.parse(R.read('docs/reference/entrance-stairs-open-south-wireframe.json'));
const {T,H,PX}=B;
const forward={south:p=>p,north:([x,y,z])=>[1-x,1-y,z],east:([x,y,z])=>[y,1-x,z],west:([x,y,z])=>[1-y,x,z]};
const inverse={south:forward.south,north:forward.north,east:forward.west,west:forward.east};
const save=(p,b)=>write(path.join(R.ROOT,OUT,p),b);
const lerp=(a,b,t)=>a.map((v,i)=>v+(b[i]-v)*t);
const round=n=>+n.toFixed(6);
const cross=(a,b)=>a[0]*b[1]-a[1]*b[0];
const inner=source.frame.innerRadius,ratio=(inner+T/2)/inner;
function expand(p,part) {
  const [x,y,z]=p;
  if(part==='arch') {
    const dx=x-.5,dz=z-H,r=Math.hypot(dx,dz),s=(r+T/2)/r;
    return [.5+dx*s,y,H+dz*s];
  }
  return [.5+(x-.5)*ratio,y,z>H?H+(z-H)*ratio:z];
}
function bounds(points) {return {min:[0,1,2].map(i=>Math.min(...points.map(p=>p[i]))),max:[0,1,2].map(i=>Math.max(...points.map(p=>p[i])))};}
function silhouette(surfaces,project) {
  return `<path fill="#fff" d="${surfaces.map(s=>{
    const p=s.points.map(project),area=p.reduce((sum,a,i)=>sum+cross(a,p[(i+1)%p.length]),0);
    if(area<0)p.reverse();return 'M'+p.map(q=>q.join(',')).join('L')+'Z';
  }).join('')}"/>`;
}
function hidden(p,ray,volumes) {
  return volumes.some(v=>{
    const a=(v.yMin-p[1])/ray[1],b=(v.yMax-p[1])/ray[1];
    let enter=Math.max(0,Math.min(a,b)),exit=Math.max(a,b);
    for(let i=0;i<v.profileXZ.length;i++) {
      const a=v.profileXZ[i],b=v.profileXZ[(i+1)%v.profileXZ.length],e=[b[0]-a[0],b[1]-a[1]];
      const value=cross(e,[p[0]-a[0],p[2]-a[1]]),slope=cross(e,[ray[0],ray[2]]);
      if(Math.abs(slope)<1e-12){if(value<=1e-10)return false;}
      else if(slope>0)enter=Math.max(enter,-value/slope);else exit=Math.min(exit,-value/slope);
      if(exit<=Math.max(enter,1e-8)+1e-9)return false;
    }
    return exit>Math.max(enter,1e-8)+1e-9;
  });
}
function visibleEdges(edges,volumes,ray) {
  const result=[],seen=new Set(),N=120;
  for(const e of edges){
    const key=[e.a,e.b].map(p=>p.map(round).join(',')).sort().join('|');if(seen.has(key))continue;seen.add(key);
    let start=0,old=hidden(lerp(e.a,e.b,.5/N),ray,volumes);
    const add=(a,b)=>{if(b-a>1e-7)result.push({...e,a:lerp(e.a,e.b,a),b:lerp(e.a,e.b,b)});};
    for(let k=1;k<N;k++){
      const next=hidden(lerp(e.a,e.b,(k+.5)/N),ray,volumes);if(next===old)continue;
      let lo=(k-.5)/N,hi=(k+.5)/N;
      for(let j=0;j<24;j++){const mid=(lo+hi)/2;if(hidden(lerp(e.a,e.b,mid),ray,volumes)===old)lo=mid;else hi=mid;}
      const cut=(lo+hi)/2;if(!old)add(start,cut);start=cut;old=next;
    }
    if(!old)add(start,1);
  }
  return result;
}
async function doorPart(direction,part,options={}) {
  const tr=forward[direction],inv=inverse[direction];
  const transform=p=>expand(p,part);
  const destination=options.output||OUT;
  const volumes=source.occludingVolumes.filter(v=>v.part===part).map(v=>({...v,profileXZ:v.profileXZ.map(([x,z])=>{const p=transform([x,0,z]);return [p[0],p[2]];})}));
  const origin=inv([0,0,0]),ray=inv([.18,.9,1]).map((v,i)=>v-origin[i]);
  let edges=source.sourceEdges.filter(e=>part==='closed-door'?['door','detail'].includes(e.kind):
    (e.kind==='frame'||e.kind==='joint'&&Math.min(e.a[2],e.b[2])>=H-1e-8&&[e.a,e.b].every(p=>p[1]>=source.frame.centerY-T/2-1e-8&&p[1]<=source.frame.centerY+T/2+1e-8))&&e.role!=='apparent-contour')
    .map(e=>({...e,a:transform(e.a),b:transform(e.b)}));
  const curves=part==='arch'?[[inner+T/2,inner+T/2],[source.frame.outerRadius+T/2,source.frame.outerRadius+T/2]]:[[inner+T/2,inner+T/2]];
  if(part==='closed-door')for(const sign of [-1,1]){const x=.5+sign*curves[0][0];edges.push({a:[x,source.door.yMin,H],b:[x,source.door.yMax,H],kind:'door'});}
  if(part==='arch')for(const [rx] of curves)for(const sign of [-1,1])edges.push({a:[.5+sign*rx,.5-T/2,H],b:[.5+sign*rx,.5+T/2,H],kind:'frame'});
  for(let i=1;i<56;i++)for(const [rx,rz] of curves){
    const facing=a=>ray[0]*Math.cos(a)/rx+ray[2]*Math.sin(a)/rz;
    if(facing((i-.5)*Math.PI/56)*facing((i+.5)*Math.PI/56)<0){
      const at=y=>[.5+rx*Math.cos(i*Math.PI/56),y,H+rz*Math.sin(i*Math.PI/56)];
      edges.push({a:at(part==='arch'?.5-T/2:source.door.yMin),b:at(part==='arch'?.5+T/2:source.door.yMax),kind:part==='arch'?'frame':'door'});
    }
  }
  return paintDoorModel(direction,part,volumes,edges,{output:destination,
    rx:ratio,rz:ratio,forward:p=>tr(expand(p,'closed-door'))});
}
async function paintDoorModel(direction,part,volumes,edges,options={}) {
  const tr=forward[direction],inv=inverse[direction];
  const origin=inv([0,0,0]),ray=inv([.18,.9,1]).map((v,i)=>v-origin[i]);
  const savePart=(p,b)=>write(path.join(R.ROOT,options.output||OUT,p),b);
  const visible=visibleEdges(edges,volumes,ray);
  const surfaces=[];
  volumes.forEach((v,index)=>{
    const a=v.profileXZ.map(([x,z])=>tr([x,v.yMin,z])),b=v.profileXZ.map(([x,z])=>tr([x,v.yMax,z]));
    surfaces.push({points:a,part,index},{points:b,part,index},...a.map((p,i)=>({points:[p,a[(i+1)%a.length],b[(i+1)%b.length],b[i]],part,index})));
  });
  const points=surfaces.flatMap(s=>s.points),screen=points.map(B.project);
  const min=[0,1].map(i=>Math.floor(Math.min(...screen.map(p=>p[i])))-3),max=[0,1].map(i=>Math.ceil(Math.max(...screen.map(p=>p[i])))+3);
  const size=max.map((v,i)=>Math.ceil((v-min[i])/2)*2),anchor=min.map(v=>-v);
  const project=p=>B.project(p).map((v,i)=>v+anchor[i]);
  const id=`door-${direction}-${options.suffix||(part==='arch'?'arch':'leaf')}`;
  const makeGuide=edges=>R.svg(size,edges.map(e=>{
    const a=project(tr(e.a)),b=project(tr(e.b));
    return `<line x1="${a[0]}" y1="${a[1]}" x2="${b[0]}" y2="${b[1]}" stroke="#ff00ff" stroke-width="${e.kind==='detail'?1.2:1.6}"/>`;
  }).join(''));
  const guide=makeGuide(visible.filter(e=>!e.paintOnly));
  const rx=options.rx||ratio,rz=options.rz||ratio;
  const model={id,size,anchor,surfaces,floor:false,clipPaint:true,drawAccent:false,door:options.door||source.door,forward:options.forward||tr,
    inverse:options.inverse||(p=>{const q=inv(p);return [.5+(q[0]-.5)/rx,q[1],q[2]>H?H+(q[2]-H)/rz:q[2]];}),
    silhouette:silhouette(surfaces,project),resolveMaterials:faces=>{
      faces.forEach(f=>{if(f.kind!=='wood'&&f.kind!=='metal')f.materialId='walls-planes';});
      if(options.resolveMaterials)options.resolveMaterials(faces,{project,anchor});
    }};
  if(visible.some(e=>e.paintOnly))model.paintGuide=makeGuide(visible);
  // Single-material smooth parts need the fixed silhouette only. Avoid a
  // redundant raster part mask attenuating their uninked cut edges twice.
  if(options.singleMaterialPart)delete model.door;
  const result=await R.render(model,guide,options.materials||B.materials);
  const png=await sharp(result.png).resize(size[0],size[1]).png().toBuffer();
  savePart(`sprites/${id}.png`,png);savePart(`overlays/${id}.png`,await sharp(result.overlay).resize(size[0],size[1]).png().toBuffer());savePart(`guides/${id}.svg`,guide);
  return {id,png:result.png,frame:[...min,...size],bounds:bounds(points),report:result.report};
}

// Add upright jambs inside the ORIGINAL arch opening. Its existing sprite is
// deliberately not regenerated or resized. Profiles share its exact polygonal arc.
async function insetDoorParts(direction,{output=OUT,leafHalfWidth=.29,jambInner=.30}={}) {
  const profile=source.door.profileXZ.map(([x,z])=>{const p=expand([x,0,z],'closed-door');return [p[0],p[2]];});
  function clip(points,x,keepRight){
    const result=[];
    for(let i=0;i<points.length;i++){
      const a=points[i],b=points[(i+1)%points.length],A=keepRight?a[0]>=x:a[0]<=x,Bb=keepRight?b[0]>=x:b[0]<=x;
      if(A)result.push(a);
      if(A!==Bb)result.push(lerp(a,b,(x-a[0])/(b[0]-a[0])));
    }
    return result;
  }
  const slice=(lo,hi)=>clip(clip(profile,lo,true),hi,false);
  const topAt=x=>{
    let top=0;
    for(let i=0;i<profile.length;i++){
      const a=profile[i],b=profile[(i+1)%profile.length];
      if(Math.abs(b[0]-a[0])<1e-10)continue;
      if(x>=Math.min(a[0],b[0])-1e-8&&x<=Math.max(a[0],b[0])+1e-8)top=Math.max(top,a[1]+(b[1]-a[1])*(x-a[0])/(b[0]-a[0]));
    }
    return top;
  };
  const borders=(volumes,kind)=>volumes.flatMap(v=>{
    const edges=[];
    for(const y of [v.yMin,v.yMax])v.profileXZ.forEach((p,i)=>edges.push({a:[p[0],y,p[1]],b:[v.profileXZ[(i+1)%v.profileXZ.length][0],y,v.profileXZ[(i+1)%v.profileXZ.length][1]],kind}));
    const inv=inverse[direction],o=inv([0,0,0]),ray=inv([.18,.9,1]).map((n,i)=>n-o[i]);
    v.profileXZ.forEach((p,i)=>{
      const a=v.profileXZ[(i-1+v.profileXZ.length)%v.profileXZ.length],b=v.profileXZ[(i+1)%v.profileXZ.length];
      const facing=(a,b)=>ray[0]*(b[1]-a[1])-ray[2]*(b[0]-a[0]);
      if(p[1]<=H+1e-7||Math.abs(p[0]-a[0])<1e-8||Math.abs(p[0]-b[0])<1e-8||facing(a,p)*facing(p,b)<0)
        edges.push({a:[p[0],v.yMin,p[1]],b:[p[0],v.yMax,p[1]],kind});
    });return edges;
  });
  const leafVolumes=[{part:'closed-door',profileXZ:slice(.5-leafHalfWidth,.5+leafHalfWidth),yMin:source.door.yMin,yMax:source.door.yMax}];
  const rx=leafHalfWidth/inner,leafEdges=borders(leafVolumes,'door');
  for(const e of source.sourceEdges.filter(e=>e.kind==='detail')){
    const transform=p=>{
      const x=.5+(p[0]-.5)*rx;
      return [x,p[1],e.role?.includes('plank-seam')&&p[2]>H+.01?topAt(x):p[2]];
    };
    leafEdges.push({...e,a:transform(e.a),b:transform(e.b)});
  }
  const leaf=await paintDoorModel(direction,'closed-door',leafVolumes,leafEdges,{output,rx,rz:1});
  const jambVolumes=[slice(.5-(inner+T/2),.5-jambInner),slice(.5+jambInner,.5+(inner+T/2))]
    .map(profileXZ=>({part:'pillar',profileXZ,yMin:.5-T/2,yMax:.5+T/2}));
  const jambs=[];
  for(const [index,v] of jambVolumes.entries()){
    const jambEdges=borders([v],'frame');
    const lo=Math.min(...v.profileXZ.map(p=>p[0])),hi=Math.max(...v.profileXZ.map(p=>p[0]));
    for(const z of [H/2,H,H*1.5]){
      const reaches=v.profileXZ.flatMap((a,i)=>{
        const b=v.profileXZ[(i+1)%v.profileXZ.length];
        if(Math.abs(a[1]-b[1])<1e-9||z<Math.min(a[1],b[1])||z>Math.max(a[1],b[1]))return [];
        return [a[0]+(b[0]-a[0])*(z-a[1])/(b[1]-a[1])];
      });
      if(reaches.length<2)continue;
      const x0=Math.min(...reaches),x1=Math.max(...reaches);
      for(const y of [v.yMin,v.yMax])jambEdges.push({a:[x0,y,z],b:[x1,y,z],kind:'joint'});
      for(const x of [lo,hi])if(z<=topAt(x)+1e-8)jambEdges.push({a:[x,v.yMin,z],b:[x,v.yMax,z],kind:'joint'});
    }
    jambs.push(await paintDoorModel(direction,'pillar',[v],jambEdges,{output,suffix:'jamb-'+(index===0?'left':'right')}));
  }
  return [leaf,...jambs];
}
async function stairs(direction) {
  const tr=forward[direction],items=[];
  // A wider opening follows the centered rails; the five rises remain unchanged.
  for(const [i,step] of stairSource.stairs.steps.entries()){
    const lo=[T/2, i===0?T/2:step.y0,0],hi=[1-T/2,step.y1,step.top];
    const A=tr(lo),Bv=tr(hi),a=A.map((v,j)=>Math.min(v,Bv[j])),b=A.map((v,j)=>Math.max(v,Bv[j]));
    const [x,y,z]=a,[X,Y,Z]=b;
    const faces=[B.face([[x,Y,z],[X,Y,z],[X,Y,Z],[x,Y,Z]],'north',200+i),
      B.face([[X,y,z],[X,Y,z],[X,Y,Z],[X,y,Z]],'west',200+i),
      B.face([[x,y,Z],[X,y,Z],[X,Y,Z],[x,Y,Z]],'floor',220+i,'floors-calm')];
    const item=await B.paint(`stair-${direction}-${i}`,{faces,hull:faces.map(f=>f.points)},OUT);
    item.bounds={min:a,max:b};items.push(item);
  }
  // All five steps can be baked together: rails lie outside their footprint.
  // Keep their source parts/guides for authoring, but ship one stair sprite.
  const ordered=[...items].sort((a,b)=>{
    const depth=i=>(i.bounds.min[0]+i.bounds.max[0])*.18+(i.bounds.min[1]+i.bounds.max[1])*.9;
    return depth(a)-depth(b);
  });
  const x=Math.min(...items.map(i=>i.frame[0])),y=Math.min(...items.map(i=>i.frame[1]));
  const w=Math.max(...items.map(i=>i.frame[0]+i.frame[2]))-x,h=Math.max(...items.map(i=>i.frame[1]+i.frame[3]))-y;
  const png=await sharp({create:{width:w*R.SCALE,height:h*R.SCALE,channels:4,background:'#00000000'}})
    .composite(ordered.map(i=>({input:i.png,left:(i.frame[0]-x)*R.SCALE,top:(i.frame[1]-y)*R.SCALE}))).png().toBuffer();
  const id=`stair-${direction}`;
  save(`sprites/${id}.png`,await sharp(png).resize(w,h).png().toBuffer());
  const guideLayers=[];
  for(const item of ordered){
    const left=(item.frame[0]-x)*R.SCALE,top=(item.frame[1]-y)*R.SCALE;
    guideLayers.push({input:item.png,left,top,blend:'dest-out'});
    const input=await sharp(R.read(`${OUT}/guides/${item.id}.svg`)).resize(item.frame[2]*R.SCALE,item.frame[3]*R.SCALE).png().toBuffer();
    guideLayers.push({input,left,top});
  }
  const guide=await sharp({create:{width:w*R.SCALE,height:h*R.SCALE,channels:4,background:'#00000000'}}).composite(guideLayers).png().toBuffer();
  save(`guides/${id}.png`,await sharp(guide).resize(w,h).png().toBuffer());
  const overlay=await sharp(png).composite([{input:guide}]).png().toBuffer();
  save(`overlays/${id}.png`,await sharp(overlay).resize(w,h).png().toBuffer());
  return [{id,png,frame:[x,y,w,h],bounds:{min:[0,1,2].map(j=>Math.min(...items.map(i=>i.bounds.min[j]))),max:[0,1,2].map(j=>Math.max(...items.map(i=>i.bounds.max[j])))},
    report:{id,composition:'Five prepared steps, baked in support order',parts:items.map(i=>i.report)}}];
}
async function specials({doors=null}={}){const items=[];for(const direction of Object.keys(forward)){
  if(doors)items.push(...await doors(direction));
  else for(const part of ['closed-door','arch'])items.push(await doorPart(direction,part));
  items.push(...await stairs(direction));console.log('Prepared specials '+direction);
}return items;}
module.exports={specials,doorPart,insetDoorParts,paintDoorModel};
