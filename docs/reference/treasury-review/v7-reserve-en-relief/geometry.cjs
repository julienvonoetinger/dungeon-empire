// Export the approved solids, including ordinary corridor walls, as camera mattes.
const fs=require("node:fs"),path=require("node:path");
const P=require("../../../../tools/isometric_paint_geometry.cjs");
const {bay,pier,boundary}=require("../v5-wireframe/prepare.cjs");
const {key,SIDES}=require("../v5-wireframe/layout.cjs");
const layout=require("../v5-wireframe/layouts.json");
const dir=path.join(P.ROOT,"artifacts/treasury-volume");fs.mkdirSync(dir,{recursive:true});
const sheets=P.allModels(),worlds={};
for(const row of layout.rows){
 const cells=new Set(["0,0","1,0","0,1","1,1",...row.passage.map(key)]),cornerPost=boundary(cells);
 const faces=[],bays=[],pillars=new Set();
 const add=(model,at=[0,0])=>{for(const f of model.faces)faces.push(f.points.map(([x,y,z])=>[x+at[0],y+at[1],z]));};
 for(const item of row.bays){const b=bay(item,row.corner,cornerPost);add(b.m);bays.push({...item,lo:b.lo,hi:b.hi,...SIDES[item.side]});}
 add(pier(row.corner));
 for(const tag of cells){const [x,y]=tag.split(",").map(Number);
  for(const [dx,dy,axis,u,v] of [[0,-1,"h",x,y],[0,1,"h",x,y+1],[-1,0,"v",x,y],[1,0,"v",x+1,y]]){
   if(cells.has(key([x+dx,y+dy])))continue;
   const a=[u,v],end=[u+(axis==="h"),v+(axis==="v")];
   for(const pt of [a,end])if(cornerPost(pt)&&key(pt)!==key(row.corner))pillars.add(key(pt));
   const id="wall-"+axis+"-"+(Number(cornerPost(a))+2*Number(cornerPost(end)));
   if(!row.hosts.some(host=>host.prefix===id && key(host.at)===key(a)))add(sheets.find(m=>m.id===id),a);
  }
 }
 for(const k of pillars)add(sheets.find(m=>m.id==="pillar"),k.split(",").map(Number));
 worlds[row.id]={bays,faces,corner:row.corner,side:row.side,slot:row.slot};
}
fs.writeFileSync(path.join(dir,"geometry.json"),JSON.stringify({camera:P.camera,density:P.PX,frame:[-296,-180,592,504],worlds}));
