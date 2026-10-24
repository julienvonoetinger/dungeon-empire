// Offline appearance proposal. The approved leaf geometry and guides stay fixed.
const B=require('./prepare_mobile_reference.cjs');
const ART_REVISION=process.argv.includes('--art-v2')?2:1;
const sourceForRevision=revision=>`docs/reference/mobile-door-frame-review/painted-art-v${revision}/source/${revision===2?'door-face-fitted':'door-artwork'}.png`;
const SOURCE=sourceForRevision(ART_REVISION);
function leafAppearance({leaf,tr,inv,artRevision=ART_REVISION}) {
  const materials=structuredClone(B.materials);
  const materialId='door-forged-violet-v'+artRevision;
  materials.entries[materialId]={file:'../../../'+sourceForRevision(artRevision)};
  materials.renderProfile.wood={color:'#35251f',brightness:artRevision===2?.82:1,saturation:artRevision===2?.82:1,opacity:1,blur:.3};
  const x0=Math.min(...leaf.profileXZ.map(p=>p[0])),x1=Math.max(...leaf.profileXZ.map(p=>p[0]));
  const z0=Math.min(...leaf.profileXZ.map(p=>p[1])),z1=Math.max(...leaf.profileXZ.map(p=>p[1]));
  return {materials,resolveMaterials:(faces,{project})=>{
    for(const f of faces) {
      if(f.kind!=='wood')continue;
      const p=inv(f.p),onBack=Math.abs(p[1]-leaf.yMin)<1e-7,onFront=Math.abs(p[1]-leaf.yMax)<1e-7;
      // The same complete painting on both broad faces. Thin sides keep quiet wood.
      if(!onBack&&!onFront)continue;
      f.materialId=materialId;
      const y=onBack?leaf.yMin:leaf.yMax;
      const a=project(tr([x0,y,z1])),b=project(tr([x1,y,z1])),c=project(tr([x0,y,z0]));
      const u=b.map((v,i)=>(v-a[i])/350),v=c.map((v,i)=>(v-a[i])/350);
      f.textureTransform=`matrix(${u[0]} ${u[1]} ${v[0]} ${v[1]} ${a[0]} ${a[1]})`;
    }
  }};
}
module.exports={leafAppearance,SOURCE,sourceForRevision,
  approvedLeafAppearance:context=>leafAppearance({...context,artRevision:2})};
