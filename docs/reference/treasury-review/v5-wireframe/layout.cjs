// Design fixture only. Coordinates are relative to the four floor cells of the reservoir.
const SIDES = {
  N:{start:[0,0],step:[1,0],inside:[0,1],axis:"h",far:true},
  E:{start:[2,0],step:[0,1],inside:[-1,0],axis:"v",far:false},
  S:{start:[0,2],step:[1,0],inside:[0,-1],axis:"h",far:false},
  W:{start:[0,0],step:[0,1],inside:[1,0],axis:"v",far:true}
};
const key=p=>p.join(",");
const point=(side,u,inset=0)=>SIDES[side].start.map((v,i)=>v+u*SIDES[side].step[i]+inset*SIDES[side].inside[i]);
const slots=Object.keys(SIDES).flatMap(side=>[0,1].map(slot=>({
  side, slot, id:side+(slot+1), outside:point(side,slot+.5,-.5).map(Math.floor)
})));
const corners=[
  {p:[0,0],ends:{N:0,W:0}}, {p:[2,0],ends:{N:1,E:0}},
  {p:[0,2],ends:{S:0,W:1}}, {p:[2,2],ends:{S:1,E:1}}
];
function layout(floor,chests){
  const inside=["0,0","1,0","0,1","1,1"];
  if(!inside.every(k=>floor.has(k)&&chests.has(k))) return null;
  const mouths=slots.filter(s=>floor.has(key(s.outside)));
  if(mouths.length!==1) return null;
  const mouth=mouths[0];
  // Maximize the visible rear faces, then favor a full rear span. A one-cell
  // secondary arch always stays on the corner's own edge, never on the mouth.
  const options=[];
  for(const corner of corners){
    const sides=Object.keys(corner.ends);
    if(sides.some(s=>mouth.side===s && mouth.slot===corner.ends[s]))continue;
    for(const side of sides){
      if(!SIDES[side].far || side===mouth.side)continue;
      const other=sides.find(s=>s!==side);
      const proximity=Math.abs(corner.p[0]-(mouth.outside[0]+.5))+Math.abs(corner.p[1]-(mouth.outside[1]+.5));
      options.push({corner,side,other,rank:(SIDES[other].far?10:0)+proximity});
    }
  }
  options.sort((a,b)=>b.rank-a.rank);
  const {corner,side,other}=options[0];
  return {mouth,corner:corner.p,bays:[{side,first:0,count:2},{side:other,first:corner.ends[other],count:1}]};
}
function corridor(mouth){
  return [0,1,2].map(i=>mouth.outside.map((v,k)=>v-i*SIDES[mouth.side].inside[k]));
}
module.exports={SIDES,key,point,slots,layout,corridor};
