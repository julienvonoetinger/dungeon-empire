// Offline texture preparation on the approved sanctuary XYZ geometry.
// Usage: NODE_PATH=<sharp installation>/node_modules node tools/export_sanctuary_textured.cjs
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs');
const {writeGeneratedFile:write}=require('./write_generated_file.cjs');
const ROOT=path.resolve(__dirname,'..'),REVIEW='docs/reference/sanctuary-textured/v1';
const OUT='assets/previews/sanctuary-textured';
const read=p=>fs.readFileSync(path.join(ROOT,p));
const geometry=JSON.parse(read(REVIEW+'/geometry.json'));
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
const save=(p,b)=>write(path.join(ROOT,p),b);
const S=2,records=new Map();
const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
const mod=(v,n)=>(v%n+n)%n;
function mirror(t){const v=mod(t,2);return v>1?2-v:v;}
async function texture(file){const {data,info}=await sharp(read(file)).removeAlpha().raw().toBuffer({resolveWithObject:true});return {data,...info};}
function sample(t,u,v,c){
  const x=mirror(u)*(t.width-1),y=mirror(v)*(t.height-1),x0=Math.floor(x),y0=Math.floor(y),dx=x-x0,dy=y-y0;
  const at=(a,b)=>t.data[(Math.min(b,t.height-1)*t.width+Math.min(a,t.width-1))*t.channels+c];
  return (at(x0,y0)*(1-dx)+at(x0+1,y0)*dx)*(1-dy)+(at(x0,y0+1)*(1-dx)+at(x0+1,y0+1)*dx)*dy;
}
const doc=(frame,body)=>Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${frame[2]*S}" height="${frame[3]*S}" viewBox="${frame.join(' ')}">${body}</svg>`);
const line=(e,color,width,dx=0,dy=0)=>{const a=P.project(e.a),b=P.project(e.b);return `<path d="M${a[0]+dx},${a[1]+dy} L${b[0]+dx},${b[1]+dy}" stroke="${color}" stroke-width="${width}" fill="none" stroke-linecap="round"/>`;};
async function output(id,frame,png){save(`${OUT}/${id}.png`,png);records.set(id,{frame,bytes:png.length,sha256:hash(png)});}
async function main(){
  const ground=await texture(REVIEW+'/source/ground.png'),stone=await texture(REVIEW+'/source/stone.png'),detail=await texture(REVIEW+'/source/rock-detail.png');
  // Eight-cell mirrored period with shared world UVs and a two-pixel filter
  // guard. Adjacent tiles sample identical material at every shared boundary.
  const guard=2*Math.sqrt(5)/P.PX, floorFrame=[-132,-4,264,136];
  const floor={faces:[{points:[[-guard,-guard,0],[1+guard,-guard,0],[1+guard,1+guard,0],[-guard,1+guard,0]]}]};
  const floorRaster=P.raster(floor,floorFrame,S);
  for(let ty=0;ty<8;ty++)for(let tx=0;tx<8;tx++){
    const r=floorRaster,rgba=Buffer.alloc(r.width*r.height*4);
    for(let k=0;k<r.owner.length;k++)if(r.owner[k]>=0){
      const x=r.xyz[k*3]+tx,y=r.xyz[k*3+1]+ty;
      for(let c=0;c<3;c++)rgba[k*4+c]=sample(ground,x/4,y/4,c)*[.64,.67,.73][c];
      rgba[k*4+3]=255;
    }
    const png=await sharp(rgba,{raw:{width:r.width,height:r.height,channels:4}}).resize(floorFrame[2],floorFrame[3]).png().toBuffer();
    await output(`floor-${tx}-${ty}`,floorFrame,png);
  }
  console.log('Prepared 64 continuous ground tiles.');
  let index=0;
  for(const original of geometry.models){
    if(original.id==='floor-0')continue;
    const m={...original,faces:original.faces.flatMap(f=>f.points.slice(1,-1).map((p,i)=>({...f,points:[f.points[0],p,f.points[i+2]]})))};
    const frame=m.frame,r=P.raster(m,frame,S),rgba=Buffer.alloc(r.width*r.height*4);
    const carved=m.id==='altar'||m.id.startsWith('Menhir');
    const normals=m.faces.map(f=>P.normal(f.points));
    const seed=index++*.71;
    for(let k=0;k<r.owner.length;k++){
      if(r.owner[k]<0)continue;
      const x=r.xyz[k*3],y=r.xyz[k*3+1],z=r.xyz[k*3+2],n=normals[r.owner[k]];
      const weights=n.map(v=>Math.pow(Math.abs(v),4)),sum=weights.reduce((a,b)=>a+b,0);
      const light=.58+.55*Math.max(0,P.dot(n,[-.38,.48,.79]));
      const foot=.79+.21*clamp(z/.32,0,1);
      const surfaceColor=[];
      for(let c=0;c<3;c++){
        let color=0;
        for(let a=0;a<3;a++){
          const u=[y,x,x][a]/1.65+seed,v=[z,z,y][a]/1.65+seed*.37;
          const broad=sample(stone,u,v,c),grain=sample(detail,u*1.3,v*1.3,c),mineral=sample(ground,u*.7,v*.7,c);
          color+=(carved?broad*.40+grain*.35+mineral*.25:broad*.10+grain*.25+mineral*.65)*weights[a]/sum;
        }
        surfaceColor.push(color);
      }
      const grey=surfaceColor[0]*.3+surfaceColor[1]*.59+surfaceColor[2]*.11;
      // A common weathered slate palette ties the worked stone to its gorge.
      for(let c=0;c<3;c++)rgba[k*4+c]=clamp(((grey*.72+surfaceColor[c]*.28)*(carved?1.24:1.08)+(carved?20:8))*light*foot,0,255);
      rgba[k*4+3]=255;
    }
    const mask=Buffer.alloc(rgba.length);for(let k=0;k<r.owner.length;k++){mask[k*4]=mask[k*4+1]=mask[k*4+2]=255;mask[k*4+3]=rgba[k*4+3];}
    const contours=m.visibleEdges.filter(e=>e.kind!=='carving');
    const carvings=m.visibleEdges.filter(e=>e.kind==='carving');
    // Subtle creases and incised relief, baked into each individual sprite.
    const strokes=(carved?contours.map(e=>line(e,'rgba(19,27,37,.24)',1.2)).join('')+
      contours.map(e=>line(e,'rgba(160,164,167,.22)',.8,-.35,-.55)).join(''):'')+
      carvings.map(e=>line(e,'rgba(170,165,155,.65)',2.7,.65,1.0)).join('')+
      carvings.map(e=>line(e,'#25282d',2.7)).join('');
    const high=await sharp(rgba,{raw:{width:r.width,height:r.height,channels:4}}).composite([{input:doc(frame,strokes)}]).png().toBuffer();
    const clipped=await sharp(high).composite([{input:mask,raw:{width:r.width,height:r.height,channels:4},blend:'dest-in'}]).png().toBuffer();
    const png=await sharp(clipped).resize(frame[2],frame[3]).png().toBuffer();
    await output(m.id,frame,png);
    // Separate soft contact shadow on the ground, below every solid object.
    const points=m.faces.flatMap(f=>f.points).filter(p=>p[2]<.001).map(p=>P.project(p));
    if(points.length){
      const center=points.reduce((s,p)=>[s[0]+p[0]/points.length,s[1]+p[1]/points.length],[0,0]);
      const unique=[...new Map(points.map(p=>[p.join(','),p])).values()].sort((a,b)=>Math.atan2(a[1]-center[1],a[0]-center[0])-Math.atan2(b[1]-center[1],b[0]-center[0]));
      const lo=[0,1].map(a=>Math.floor(Math.min(...points.map(p=>p[a])))-25),hi=[0,1].map(a=>Math.ceil(Math.max(...points.map(p=>p[a])))+25);
      const sf=[...lo,hi[0]-lo[0],hi[1]-lo[1]];
      const shadow=await sharp(doc(sf,`<polygon points="${unique.map(p=>p.join(',')).join(' ')}" fill="#080c16" fill-opacity=".65"/>`)).blur(9).resize(sf[2],sf[3]).png().toBuffer();
      await output(m.id+'-shadow',sf,shadow);
    }
    console.log('Prepared '+m.id);
  }
  const resources=[...records.keys()];
  const scene=[`[gd_scene load_steps=${resources.length+2} format=3]`,'',
    '[ext_resource type="Script" path="res://scripts/sanctuary_wireframe_view.gd" id="view"]',
    ...resources.map(id=>`[ext_resource type="Texture2D" path="res://${OUT}/${id}.png" id="${id}"]`),'',
    '[node name="SanctuaireTexture" type="Node2D"]','script = ExtResource("view")',
    `terrain_bounds = Rect2(${geometry.field.left}, ${geometry.field.top}, ${geometry.field.right-geometry.field.left}, ${geometry.field.bottom-geometry.field.top})`];
  const add=(s,id,name=s.name)=>{const f=records.get(id).frame;scene.push('',`[node name="${name}" type="Sprite2D" parent="."]`,
    `position = Vector2(${s.position.join(',')})`,`texture = ExtResource("${id}")`,'centered = false',`offset = Vector2(${f[0]},${f[1]})`,
    `metadata/grid_position = Vector2(${s.x},${s.y})`);};
  for(const s of geometry.segments.filter(s=>s.id==='floor-0'))add(s,`floor-${mod(s.x,8)}-${mod(s.y,8)}`);
  for(const s of geometry.segments.filter(s=>s.id!=='floor-0'))if(records.has(s.id+'-shadow'))add(s,s.id+'-shadow',s.name+'Ombre');
  for(const s of geometry.segments.filter(s=>s.id!=='floor-0'))add(s,s.id);
  save('scenes/SanctuaryTextured.tscn',scene.join('\n')+'\n');
  const sources=['geometry.json','source/ground.png','source/stone.png','source/rock-detail.png'];
  save(REVIEW+'/recipe.json',JSON.stringify({geometry:'unchanged approved wireframe, same camera, placements and frames',
    sources:Object.fromEntries(sources.map(p=>[p,hash(read(REVIEW+'/'+p))])),supersampling:S,
    ground:'world UVs, mirrored eight-cell period, two source-pixel filter guard',
    renderer:'offline XYZ raster, separate RGBA sprites, baked light and incisions, separate contact shadows',
    records:Object.fromEntries(records)},null,2)+'\n');
  console.log(`Prepared ${records.size} textures; scene SanctuaryTextured.tscn.`);
}
main().catch(e=>{console.error(e);process.exitCode=1;});
