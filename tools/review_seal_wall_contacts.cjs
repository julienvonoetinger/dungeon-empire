// Read-only diagnostic: compare prepared sprite ownership to the true union of
// one door and both continuous corridor rails, at the shared XYZ projection.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs'),S=require('./isometric_seal_door.cjs');
const OUT=path.join(P.ROOT,'docs/reference/door-redesign/seal-v1/painted-v3');
async function main(){
 const fixed=process.argv.includes('--fixed');
 const catalog=JSON.parse(fs.readFileSync(path.join(P.ROOT,'assets/dungeon/isometric-kit/catalog.json'))),entries=catalog.atlas.regions;
 const atlas=await sharp(path.join(P.ROOT,'assets/dungeon/isometric-kit/atlas-256.png')).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 const sample=(e,s)=>{const u=(s[0]-e.offset[0])/e.size[0],v=(s[1]-e.offset[1])/e.size[1];if(u<0||v<0||u>=1||v>=1)return 0;const [x,y,w,h]=e.region;return atlas.data[((y+Math.floor(v*h))*atlas.info.width+x+Math.floor(u*w))*4+3]/255;};
 const door=S.geometry('south'),wall=P.models.find(m=>m.id==='wall-v-0');
 const casts=[P.caster(wall),P.caster(door),P.caster({...wall,faces:wall.faces.map(f=>({...f,points:f.points.map(p=>[p[0]+1,p[1],p[2]])}))})];
 const order=fixed?JSON.parse(fs.readFileSync(path.join(OUT,'native/draw-order.json'))).flatMap(v=>{
  if(v.id.startsWith('door-south-'))return [{...v,side:1}];
  if(v.id!=='wall-v-0')return [];
  const e=entries[v.id],at=P.ground([v.position[0]-e.offset[0],v.position[1]-e.offset[1]]);
  if(Math.abs(at[1]-2)>.0001||!([0,1].includes(Math.round(at[0]))))return [];
  return [{...v,side:Math.round(at[0])?2:0}];
 }):[];
 const frame=[-150,-110,300,255],scale=2,W=frame[2]*scale,H=frame[3]*scale;
 const views=[Buffer.alloc(W*H*4),Buffer.alloc(W*H*4),Buffer.alloc(W*H*4)],colors=[[43,119,163],[167,116,190],[41,165,124]];
 let holes=0,wrong=0;const examples=[],expectedOwners=new Int8Array(W*H),actualOwners=new Int8Array(W*H);
 for(let y=0;y<H;y++)for(let x=0;x<W;x++){
  const s=[frame[0]+(x+.5)/scale,frame[1]+(y+.5)/scale];
  const hits=casts.map(c=>c(s));let expected=-1,depth=-Infinity;
  hits.forEach((h,i)=>{if(h&&(h.depth>depth+1e-6||i===1&&h.depth>=depth-1e-6)){expected=i;depth=h.depth;}});
  let actual=-1;
  const doorA=Math.max(sample(entries['door-south-leaf'],s),sample(entries['door-south-arch'],s));
  const wallA=side=>{
   const local=[s[0]-side*128,s[1]-side*64],hit=casts[side?2:0](s);if(!hit)return 0;
   const a=sample(entries['wall-v-0'],local),q=hit.p[1];if(q<.365||q>.635)return a;
   const origin=P.ground(local),t=(.365-origin[1])/P.camera.eye[1],p=origin.map((v,i)=>v+P.camera.eye[i]*t);
   if(p.some((v,i)=>v<wall.bounds.min[i]-1e-6||v>wall.bounds.max[i]+1e-6))return 0;
   p[1]=wall.bounds.max[1]-.0003;
   return sample(entries['wall-v-0'],P.project(p))*(1-doorA);
  };
  if(wallA(0)>.5)actual=0;
  if(sample(entries['door-south-leaf'],s)>.5)actual=1;
  if(wallA(1)>.5)actual=2;
  if(sample(entries['door-south-arch'],s)>.5)actual=1;
  if(fixed){
   actual=-1;
   for(const part of order){
    let a=0;
    if(part.side===1)a=sample(entries[part.id],s);
    else {
     const local=[s[0]-(part.side===2?128:0),s[1]-(part.side===2?64:0)],origin=P.ground(local);
     const lo=wall.bounds.min.slice(),hi=wall.bounds.max.slice();lo[1]=Math.max(lo[1],part.span[0]);hi[1]=Math.min(hi[1],part.span[1]);
     const first=Math.max(...lo.map((v,i)=>(v-origin[i])/P.camera.eye[i])),last=Math.min(...hi.map((v,i)=>(v-origin[i])/P.camera.eye[i]));
     if(first<=last){
      const p=origin.map((v,i)=>v+P.camera.eye[i]*last);
      if(hi[1]<wall.bounds.max[1]-.00001&&Math.abs(p[1]-hi[1])<.00001){p[1]=wall.bounds.max[1]-.0003;a=sample(entries[part.id],P.project(p));}
      else a=sample(entries[part.id],local);
     }
    }
    if(a>.5)actual=part.side;
   }
  }
  expectedOwners[y*W+x]=expected;actualOwners[y*W+x]=actual;
  for(let i=0;i<2;i++){const id=i?actual:expected,k=(y*W+x)*4;views[i].set(id<0?[9,15,25,255]:[...colors[id],255],k);}
  const bad=expected!==actual;
  views[2].set(bad?[255,actual<0?50:180,40,255]:[20,25,36,255],(y*W+x)*4);
  if(expected>=0&&actual<0)holes++;
  if(bad){wrong++;if(examples.length<20&&s[0]<-40&&s[1]>20)examples.push({screen:s,expected,actual,hit:hits[expected]?.p});}
 }
 // Exclude the two source-pixel painted bevel/filter boundary: compare only
 // unambiguous solid interiors, where ownership must match the XYZ ray union.
 let interiorWrong=0;
 for(let y=4;y<H-4;y++)for(let x=4;x<W-4;x++){
  const k=y*W+x,expected=expectedOwners[k];if(expected<0||actualOwners[k]===expected)continue;
  let interior=true;for(let dy=-4;dy<=4;dy++)for(let dx=-4;dx<=4;dx++)if(expectedOwners[(y+dy)*W+x+dx]!==expected)interior=false;
  if(interior)interiorWrong++;
 }
 const prefix=fixed?'fixed-':'';
 for(let i=0;i<3;i++)await sharp(views[i],{raw:{width:W,height:H,channels:4}}).png().toFile(path.join(OUT,prefix+['contact-union','contact-sprites','contact-diff'][i]+'.png'));
 fs.writeFileSync(path.join(OUT,prefix+'contact-diagnostic.json'),JSON.stringify({kind:fixed?'native draw order and segmented shader equations':'legacy two-piece door over monolithic rails',holes,wrong,interiorWrong,order,examples},null,2));console.log({fixed,holes,wrong,interiorWrong});
 if(fixed&&interiorWrong)throw Error('Prepared sprite ownership still differs inside a solid contact');
}
main().catch(e=>{console.error(e);process.exitCode=1});
