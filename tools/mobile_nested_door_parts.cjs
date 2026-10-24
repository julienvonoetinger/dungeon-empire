// Painted proposal from the USER-APPROVED v8 wireframe (v7 remains reproducible).
// Production defaults
// and the original outer arch sprites remain unchanged.
const R=require('./painted_material_renderer.cjs');
const B=require('./prepare_mobile_reference.cjs');
const {paintDoorModel}=require('./mobile_special_parts.cjs');
const {H,T}=B,N=56,back=.5-T/2,front=.5+T/2;
const forward={south:p=>p,north:([x,y,z])=>[1-x,1-y,z],east:([x,y,z])=>[y,1-x,z],west:([x,y,z])=>[1-y,x,z]};
const inverse={south:forward.south,north:forward.north,east:forward.west,west:forward.east};
const arc=(r,a,y)=>[.5+r*Math.cos(a),y,H+r*Math.sin(a)];
const edge=(a,b,paintOnly=false,kind='frame')=>({a,b,paintOnly,kind});
function camera(direction) {
  const inv=inverse[direction],o=inv([0,0,0]);return inv([.18,.9,1]).map((v,i)=>v-o[i]);
}
function ringEdges(direction,lo,hi,y0,y1,stones) {
  const edges=[],ray=camera(direction);
  for(const y of [y0,y1])for(const r of [lo,hi])for(let i=0;i<N;i++)
    edges.push(edge(arc(r,i*Math.PI/N,y),arc(r,(i+1)*Math.PI/N,y)));
  for(const y of [y0,y1]) {
    for(const a of [0,Math.PI])edges.push(edge(arc(lo,a,y),arc(hi,a,y),!stones));
    if(stones)for(let i=1;i<stones;i++)edges.push(edge(arc(lo,i*Math.PI/stones,y),arc(hi,i*Math.PI/stones,y),false,'joint'));
  }
  for(const r of [lo,hi]) {
    for(const a of [0,Math.PI])edges.push(edge(arc(r,a,y0),arc(r,a,y1),!stones));
    const facing=a=>ray[0]*Math.cos(a)/r+ray[2]*Math.sin(a)/r;
    for(let i=1;i<N;i++)if(facing((i-.5)*Math.PI/N)*facing((i+.5)*Math.PI/N)<0)
      edges.push(edge(arc(r,i*Math.PI/N,y0),arc(r,i*Math.PI/N,y1)));
  }
  return edges;
}
function boxEdges(v,smooth=false) {
  const xs=v.profileXZ.map(p=>p[0]),lo=Math.min(...xs),hi=Math.max(...xs),edges=[];
  for(const y of [v.yMin,v.yMax]) {
    for(const z of smooth?[0,H]:[0,H/2,H])edges.push(edge([lo,y,z],[hi,y,z],smooth&&z===H));
    for(const x of [lo,hi])edges.push(edge([x,y,0],[x,y,H]));
  }
  for(const x of [lo,hi])for(const z of smooth?[0,H]:[0,H/2,H])edges.push(edge([x,v.yMin,z],[x,v.yMax,z],smooth&&z===H));
  return edges;
}
function leafEdges(direction,v,geometry) {
  const ps=v.profileXZ,edges=[],ray=camera(direction);
  for(const y of [v.yMin,v.yMax])for(let i=0;i<ps.length;i++)edges.push(edge([ps[i][0],y,ps[i][1]],[ps[(i+1)%ps.length][0],y,ps[(i+1)%ps.length][1]],false,'door'));
  for(let i=0;i<ps.length;i++) {
    const a=ps[(i-1+ps.length)%ps.length],p=ps[i],b=ps[(i+1)%ps.length];
    const facing=(a,b)=>ray[0]*(b[1]-a[1])-ray[2]*(b[0]-a[0]);
    if(p[1]<=H+1e-8||facing(a,p)*facing(p,b)<0)edges.push(edge([p[0],v.yMin,p[1]],[p[0],v.yMax,p[1]],false,'door'));
  }
  // v8 has no internal artwork guides. Preserve v7 details for historical exports.
  edges.push(...geometry.sourceEdges.filter(e=>e.kind==='wood'&&e.detail).map(e=>({...e,kind:'detail'})));
  return edges;
}
async function nestedDoorParts(direction,output,{revision=8,leafAppearance=null}={}) {
  const geometry=JSON.parse(R.read(`docs/reference/mobile-door-frame-review/wireframe-v${revision}/geometry.json`));
  const {smallInnerRadius:ri,smallOuterRadius:ro,wallBack,wallFront}=geometry.proposal;
  const items=[],tr=forward[direction],inv=inverse[direction];
  const masonry=geometry.volumes.filter(v=>v.part==='masonry');
  const smooth=geometry.volumes.filter(v=>v.part==='smooth-wall');
  const upper=vs=>vs.filter(v=>Math.min(...v.profileXZ.map(p=>p[1]))>=H-1e-8);
  const lower=vs=>vs.filter(v=>Math.min(...v.profileXZ.map(p=>p[1]))<H-1e-8);
  const leaf=geometry.volumes.find(v=>v.part==='wood');
  const door={profileXZ:leaf.profileXZ,yMin:leaf.yMin,yMax:leaf.yMax,bands:[],handle:revision>=8?null:{x:.66,z:.215,radius:.022}};
  const leafOptions=leafAppearance?leafAppearance({direction,leaf,tr,inv,geometry}):{};
  items.push(await paintDoorModel(direction,'closed-door',[leaf],leafEdges(direction,leaf,geometry),{...leafOptions,output,suffix:'leaf',door,forward:tr,inverse:inv}));
  items.push(await paintDoorModel(direction,'arch',upper(masonry),ringEdges(direction,ri,ro,back,front,7),{output,suffix:'inner-arch'}));
  for(const [i,v] of lower(masonry).entries())items.push(await paintDoorModel(direction,'pillar',[v],boxEdges(v),{output,suffix:'jamb-'+(i?'right':'left')}));
  const materials=structuredClone(B.materials);
  for(const k of ['top','north','west'])materials.renderProfile[k].opacity=.20;
  // One quiet material coordinate system over the WHOLE smooth panel. Separate
  // prepared parts keep depth sorting correct without seams at their cut plane.
  const options={output,materials,singleMaterialPart:true,resolveMaterials:(faces,{project})=>{
    for(const f of faces) {
      const p=inv(f.p),y=Math.abs(p[1]-wallBack)<Math.abs(p[1]-wallFront)?wallBack:wallFront;
      const a=project(tr([0,y,1])),u=project(tr([1,y,1])).map((v,i)=>(v-a[i])/350),v=project(tr([0,y,0])).map((v,i)=>(v-a[i])/350);
      f.textureTransform=`matrix(${u[0]} ${u[1]} ${v[0]} ${v[1]} ${a[0]} ${a[1]})`;
      f.bevelSeed=401;
    }
  }};
  items.push(await paintDoorModel(direction,'pillar',upper(smooth),ringEdges(direction,ro,geometry.originalArch.innerRadius,wallBack,wallFront,0),{...options,suffix:'smooth-upper'}));
  for(const [i,v] of lower(smooth).entries())items.push(await paintDoorModel(direction,'pillar',[v],boxEdges(v,true),{...options,suffix:'smooth-'+(i?'right':'left')}));
  return items;
}
module.exports={nestedDoorParts};
