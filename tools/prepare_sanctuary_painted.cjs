// Native painted sprites: crop isolated sheet cells and scale complete objects
// uniformly, preserving source alpha. No procedural repaint of the artwork.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs');
const {writeGeneratedFile:write}=require('./write_generated_file.cjs');
const COHERENT=process.argv.includes('--coherent');
const ROOT=path.resolve(__dirname,'..'),REV='docs/reference/sanctuary-textured/'+(COHERENT?'v3':'v2'),OUT='assets/previews/'+(COHERENT?'sanctuary-coherent':'sanctuary-painted');
const sceneName=COHERENT?'SanctuaryCoherent':'SanctuaryPainted';
const read=p=>fs.readFileSync(path.join(ROOT,p)),save=(p,b)=>write(path.join(ROOT,p),b);
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
const geo=JSON.parse(read('docs/reference/sanctuary-textured/v1/geometry.json'));
const layouts=JSON.parse(read(REV+'/guides/layout.json'));
const records={},items=[],mod=(v,n)=>(v%n+n)%n;
async function put(id,png,frame,source){save(`${OUT}/${id}.png`,png);records[id]={frame,sha256:hash(png),bytes:png.length,source};}
async function cell(file,col,row,cols,rows){
  const meta=await sharp(read(file)).metadata();
  const left=Math.round(col*meta.width/cols),top=Math.round(row*meta.height/rows);
  const width=Math.round((col+1)*meta.width/cols)-left,height=Math.round((row+1)*meta.height/rows)-top;
  const png=await sharp(read(file)).extract({left,top,width,height}).png().toBuffer();
  const {data,info}=await sharp(png).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  let x0=width,y0=height,x1=-1,y1=-1;
  for(let y=0;y<height;y++)for(let x=0;x<width;x++)if(data[(y*width+x)*4+3]>=192){x0=Math.min(x0,x);x1=Math.max(x1,x);y0=Math.min(y0,y);y1=Math.max(y1,y);}
  if(x1<0)throw Error('No solid object in '+file+' '+col+','+row);
  return {png,width,height,bounds:[x0,y0,x1+1,y1+1],source:{file,rect:[left,top,width,height],solidBounds:[x0,y0,x1+1,y1+1]}};
}
async function main(){
  // Whole generated objects, same logical locations and approximately the
  // approved silhouette sizes. Natural painted chips/foliage may extend them.
  for(const [sheet,layout] of Object.entries(layouts))for(const e of layout.entries){
    const c=await cell(`${REV}/source/${sheet}.png`,...e.cell,layout.grid,layout.grid);
    const [a,b,x,y]=c.bounds,solidW=x-a,solidH=y-b;
    const scale=Math.min((e.frame[3]-6)/solidH,(e.frame[2]-6)*1.08/solidW);
    // At the two reviewed viewport sizes, no painted rock may need enlarging
    // its native source pixels. Large outcrops use individual full-size sources.
    if(COHERENT && scale*Math.max(720/1130,390/660)>1.01)
      throw Error('Insufficient source pixel density: '+e.id+' scale '+scale);
    const width=Math.max(1,Math.round(c.width*scale)),height=Math.max(1,Math.round(c.height*scale));
    const dx=e.frame[0]+e.frame[2]/2-(a+x)/2*scale,dy=e.frame[1]+e.frame[3]-3-y*scale;
    const png=await sharp(c.png).resize(width,height).png().toBuffer();
    await put(e.id,png,[dx,dy,width,height],{...c.source,uniformScale:scale});
  }
  console.log('Prepared 43 complete painted terrain and ritual sprites.');
  const dressingNames=['candles','candle-dish','candle-bowl','fern','violets','mushrooms','moss','wildflowers','garden'];
  const targetWidths=COHERENT?[46,52,66,90,48,54,125,45,102]:[46,52,66,118,75,73,142,66,140];
  for(let i=0;i<9;i++){
    const c=await cell(`${REV}/source/dressing.png`,i%3,Math.floor(i/3),3,3),[a,b,x,y]=c.bounds;
    const scale=targetWidths[i]/(x-a),w=Math.round(c.width*scale),h=Math.round(c.height*scale);
    await put(dressingNames[i],await sharp(c.png).resize(w,h).png().toBuffer(),[-(a+x)/2*scale,-y*scale,w,h],{...c.source,uniformScale:scale});
  }
  const {data,info}=await sharp(read(REV+'/source/ground.png')).removeAlpha().raw().toBuffer({resolveWithObject:true});
  const mirror=t=>{const a=mod(t,2);return a>1?2-a:a;};
  function sample(u,v,c){const x=mirror(u)*(info.width-1),y=mirror(v)*(info.height-1),a=Math.floor(x),b=Math.floor(y),dx=x-a,dy=y-b;
    const at=(i,j)=>data[(Math.min(j,info.height-1)*info.width+Math.min(i,info.width-1))*info.channels+c];
    return (at(a,b)*(1-dx)+at(a+1,b)*dx)*(1-dy)+(at(a,b+1)*(1-dx)+at(a+1,b+1)*dx)*dy;}
  const g=2*Math.sqrt(5)/P.PX,frame=[-132,-4,264,136];
  const raster=P.raster({faces:[{points:[[-g,-g,0],[1+g,-g,0],[1+g,1+g,0],[-g,1+g,0]]}]},frame,2);
  for(let y=0;y<8;y++)for(let x=0;x<8;x++){
    const rgba=Buffer.alloc(raster.width*raster.height*4);
    for(let k=0;k<raster.owner.length;k++)if(raster.owner[k]>=0){
      const period=COHERENT?1:4;
      for(let c=0;c<3;c++)rgba[k*4+c]=sample((raster.xyz[k*3]+x)/period,(raster.xyz[k*3+1]+y)/period,c)*(COHERENT?1.12:.9);
      rgba[k*4+3]=255;
    }
    await put(`floor-${x}-${y}`,await sharp(rgba,{raw:{width:raster.width,height:raster.height,channels:4}}).resize(frame[2],frame[3]).png().toBuffer(),frame,{file:REV+'/source/ground.png',worldUV:[x,y],period:COHERENT?2:8});
  }
  // Reuse the already validated ground-contact shadows from the geometry bake.
  const old=JSON.parse(read('docs/reference/sanctuary-textured/v1/recipe.json'));
  for(const [id,r] of Object.entries(old.records))if(id.endsWith('-shadow'))await put(id,read(`assets/previews/sanctuary-textured/${id}.png`),r.frame,{file:`assets/previews/sanctuary-textured/${id}.png`});
  // Flora sits in asymmetric pockets beside the route, not along road edges.
  const decor=[
    ['fern',-1.5,1.3,1],['violets',-1.05,2.1,.85],['mushrooms',2.05,-.5,.85],
    ['garden',-2.5,.5,.85],['fern',1.4,-2.1,.8],['violets',2.4,-1.4,.8],
    ['moss',-1.8,-.8,1],['moss',2.6,.6,.8],['moss',1.6,2.2,.75],
    ['fern',.8,3.75,1.1],['violets',1.18,4.1,.8],['mushrooms',3.2,1.5,.8],
    ['garden',4.6,2.45,.95],['moss',3.35,2.45,.9],['wildflowers',.5,3.1,.9],
    ['garden',4.2,6.55,1.25],['fern',6.8,4.5,1.1],['violets',6.25,4.4,1.05],
    ['mushrooms',4.7,6.9,.95],['wildflowers',2.8,5.3,.7],['moss',3.15,5.9,1],
    ['fern',-3.8,-1.3,1.3],['garden',-2.1,-3.2,1.2],['violets',2.9,-3.1,1],
    ['mushrooms',-4.3,2.5,.9],['fern',-1.7,4.5,1.1],['garden',5.7,3.5,1],
    ['moss',-2.8,2.4,1.3],['moss',4.9,4.4,1.25],['moss',1.9,6.1,1.1]
  ];
  for(const [i,[id,x,y,scale]] of decor.entries())items.push({id,x,y,scale,name:'Vegetation'+i,position:P.project([x,y,0]),ground:id==='moss'});
  const candles=[[-.46,1.68,'candles'],[1.69,-.42,'candles'],[-.95,-.12,'candle-dish'],[.13,-.92,'candles'],[1.60,1.15,'candle-bowl'],[.92,1.96,'candles']];
  for(const [i,[x,y,id]] of candles.entries())items.push({id,x,y,scale:1,name:'Bougies'+i,position:P.project([x,y,0])});
  const resources=Object.keys(records),scene=[`[gd_scene load_steps=${resources.length+2} format=3]`,'',
    '[ext_resource type="Script" path="res://scripts/sanctuary_wireframe_view.gd" id="view"]',
    ...resources.map(id=>`[ext_resource type="Texture2D" path="res://${OUT}/${id}.png" id="${id}"]`),'',
    '[node name="SanctuairePeint" type="Node2D"]','script = ExtResource("view")',
    `terrain_bounds = Rect2(${geo.field.left},${geo.field.top},${geo.field.right-geo.field.left},${geo.field.bottom-geo.field.top})`];
  const add=(s,id=s.id,name=s.name)=>{const f=records[id].frame;scene.push('',`[node name="${name}" type="Sprite2D" parent="."]`,
    `position = Vector2(${s.position.join(',')})`,`texture = ExtResource("${id}")`,'centered = false',
    `offset = Vector2(${f[0]},${f[1]})`,`scale = Vector2(${s.scale||1},${s.scale||1})`,`metadata/grid_position = Vector2(${s.x},${s.y})`);};
  for(const s of geo.segments.filter(s=>s.id==='floor-0'))add(s,`floor-${mod(s.x,8)}-${mod(s.y,8)}`);
  for(const s of items.filter(s=>s.ground))add(s);
  for(const s of geo.segments.filter(s=>s.id!=='floor-0'))add(s,s.id+'-shadow',s.name+'Ombre');
  const solids=[...geo.segments.filter(s=>s.id!=='floor-0'),...items.filter(s=>!s.ground)].sort((a,b)=>a.x+a.y-b.x-b.y);
  for(const s of solids)add(s);
  save('scenes/'+sceneName+'.tscn',scene.join('\n')+'\n');
  save(REV+'/recipe.json',JSON.stringify({method:'native ImageGen whole sprites, independent alpha layers, uniform scaling and unchanged logical terrain placements',
    geometryHash:hash(read('docs/reference/sanctuary-textured/v1/geometry.json')),
    sources:Object.fromEntries([...Object.keys(layouts),'dressing','ground'].map(n=>[n,hash(read(`${REV}/source/${n}.png`))])),records,decor:items},null,2)+'\n');
  console.log(`${resources.length} native textures, ${solids.length} sorted solids; ${sceneName}.tscn ready.`);
}
main().catch(e=>{console.error(e);process.exitCode=1;});
