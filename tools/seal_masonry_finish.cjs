// The door uses the SAME planar stone finish as the walls. Paint each complete
// face before XYZ ownership selects visible pixels; never finish clipped shards.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs'),B=require('./prepare_mobile_reference.cjs');
const {stoneFinish}=require('./stone_edge_finish.cjs');
const spec=JSON.parse(fs.readFileSync(path.join(P.ROOT,'assets/dungeon/shared-materials/stone-finish.json')));
const masonry=kind=>['stone','inner','horn','crown','junction'].includes(kind);

// Original masonry prisms carry small geometrical bevel strips. Walls instead
// use planar faces with painted rounded edges. Remove only those masonry bevels
// while keeping each prism's outer XZ profile and front/back depth limits.
function planarMasonry(input){
 const output=[];
 for(let i=0;i<input.length;){
  const f=input[i],n=f.points.length;
  if(!['stone','inner','horn','crown'].includes(f.kind)){output.push(f);i++;continue;}
  const group=input.slice(i,i+2+3*n);
  if(group.length!==2+3*n||group[1].kind!==f.kind||group.slice(2).some((q,j)=>q.kind!==f.kind+(j%3?'-bevel':'')))throw Error('Unexpected approved masonry prism');
  const frontY=f.points[0][1],rearY=group[1].points[0][1];
  const front=Array.from({length:n},(_,j)=>{const p=group[3+3*j].points[1];return [p[0],frontY,p[2]];});
  const rear=front.map(([x,y,z])=>[x,rearY,z]);
  const stoneId='stone-'+i;
  output.push({kind:f.kind,stoneId,points:front},{kind:f.kind,stoneId,points:rear.slice().reverse()});
  for(let j=0;j<n;j++)output.push({kind:f.kind,stoneId,points:[rear[j],rear[(j+1)%n],front[(j+1)%n],front[j]]});
  i+=group.length;
 }
 return output;
}
// Sloped arch stones interpolate the three wall-plane grades. A .7 threshold
// made adjacent slopes abruptly switch from facade blue to cap grey.
function materialProfile(n){
 const kinds=['west','north','top'],weights=[n[0]**2,n[1]**2,Math.max(0,n[2])**2],sum=weights.reduce((a,b)=>a+b,0)||1;
 const w=weights.map(v=>v/sum),profiles=kinds.map(k=>B.materials.renderProfile[k]);
 const mix=key=>profiles.reduce((s,p,i)=>s+(p[key]??1)*w[i],0);
 const colors=profiles.map(p=>p.color.match(/[a-f\d]{2}/gi).map(v=>parseInt(v,16)));
 const color='#'+[0,1,2].map(c=>Math.round(colors.reduce((s,rgb,i)=>s+rgb[c]*w[i],0)).toString(16).padStart(2,'0')).join('');
 return {color,brightness:mix('brightness'),saturation:mix('saturation'),opacity:mix('opacity'),blur:mix('blur')};
}
const textures=new Map();
async function prepare(m){
 const maps=[];
 for(let id=0;id<m.faces.length;id++){
  const f=m.faces[id];if(!masonry(f.kind)){maps.push(null);continue;}
  const n=P.normal(f.points),kind=n[2]>.7?'top':Math.abs(n[0])>Math.abs(n[1])?'west':'north';
  const points=f.points.map(P.project);
  if(points.reduce((a,p,i)=>a+p[0]*points[(i+1)%points.length][1]-p[1]*points[(i+1)%points.length][0],0)<0)points.reverse();
  const lo=[0,1].map(i=>Math.floor(Math.min(...points.map(p=>p[i])))-1),hi=[0,1].map(i=>Math.ceil(Math.max(...points.map(p=>p[i])))+1);
  const frame=[...lo,hi[0]-lo[0],hi[1]-lo[1]],profile=materialProfile(n),key=JSON.stringify(profile);
  if(!textures.has(key))textures.set(key,(await sharp(path.join(P.ROOT,'assets/dungeon/shared-materials/walls-planes.png')).modulate({brightness:profile.brightness,saturation:profile.saturation}).blur(profile.blur).png().toBuffer()).toString('base64'));
  const polygon=`<polygon points="${points.map(p=>p.join(',')).join(' ')}"/>`;
  const finish=stoneFinish({face:{points,kind,bevelSeed:15+id},id,profile,textureKey:kind,textureTransform:P.textureTransform(f.points,n),mask:'',guideLines:[],connected:false,spec});
  const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="${frame[2]*4}" height="${frame[3]*4}" viewBox="${frame.join(' ')}"><defs><clipPath id="f${id}">${polygon}</clipPath><image id="t-${kind}" href="data:image/png;base64,${textures.get(key)}" width="350" height="350" preserveAspectRatio="none"/>${finish.defs}</defs><rect x="${lo[0]}" y="${lo[1]}" width="${frame[2]}" height="${frame[3]}" fill="${spec.mortar}"/>${finish.paint}</svg>`;
  maps.push({frame,width:frame[2]*4,data:await sharp(Buffer.from(svg)).ensureAlpha().raw().toBuffer()});
 }
 return maps;
}
function sample(map,screen){
 const x=Math.max(0,Math.min(map.frame[2]*4-1,Math.floor((screen[0]-map.frame[0])*4)));
 const y=Math.max(0,Math.min(map.frame[3]*4-1,Math.floor((screen[1]-map.frame[1])*4))),i=(y*map.width+x)*4;
 return [map.data[i],map.data[i+1],map.data[i+2]];
}
module.exports={planarMasonry,prepare,sample,masonry,materialProfile};
