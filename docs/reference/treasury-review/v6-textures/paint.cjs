// Paint the V5 wall geometry and bake the coin layer only into the actual floor textures.
const fs=require("node:fs"),path=require("node:path"),assert=require("node:assert/strict"),sharp=require("sharp");
const P=require("../../../../tools/isometric_paint_geometry.cjs");
const Stone=require("../../../../tools/seal_masonry_finish.cjs");
const {bay,pier,boundary}=require("../v5-wireframe/prepare.cjs");
const {SIDES,key}=require("../v5-wireframe/layout.cjs");
const {rows,wallThickness:T}=require("../v5-wireframe/layouts.json");
const catalog=require("../../../../assets/dungeon/isometric-kit/catalog.json"),floorKeys=require("./floor-keys.json");
const dir=__dirname,out=path.join(dir,"sprites"),done=new Set(),floorCache=new Map(),coffer={};
const clamp=(x,lo,hi)=>Math.max(lo,Math.min(hi,x));
const smooth=x=>{const t=clamp(x,0,1);return t*t*(3-2*t);};

async function floorPigment(){
  // One common pixel-to-world scale. Preserve negative space and the shape of
  // each coin, including if an artist supplies a non-square replacement sheet.
  const {data,info}=await sharp(path.join(dir,"source","monnaie-plan.png"))
    .resize(640,640,{fit:"contain",position:"northwest",background:"#00000000"})
    .ensureAlpha().raw().toBuffer({resolveWithObject:true});
  return (u,v)=>{
    if(u<0||u>1||v<0||v>1)return [0,0,0,0];
    const x=u*(info.width-1),y=v*(info.height-1),ix=Math.floor(x),iy=Math.floor(y);
    const rgba=[0,0,0,0];
    for(const [dx,wx] of [[0,1-(x-ix)],[1,x-ix]])for(const [dy,wy] of [[0,1-(y-iy)],[1,y-iy]]){
      const index=(Math.min(iy+dy,info.height-1)*info.width+Math.min(ix+dx,info.width-1))*4;
      const alpha=data[index+3]/255*wx*wy;
      for(let c=0;c<3;c++)rgba[c]+=data[index+c]*alpha;
      rgba[3]+=alpha;
    }
    return rgba;
  };
}
function local(side,p){
  const s=SIDES[side],dx=p[0]-s.start[0],dy=p[1]-s.start[1];
  return [dx*s.step[0]+dy*s.step[1],dx*s.inside[0]+dy*s.inside[1]];
}
async function wall(obj,m,side){
  if(done.has(obj.id))return;
  done.add(obj.id);
  const frame=obj.frame,ss=3,r=P.raster(m,frame,ss),visible=new Set(r.owner);
  const maps=await Stone.prepare({faces:m.faces.map((f,i)=>({...f,kind:visible.has(i)?"stone":"unused"}))});
  const rgba=Buffer.alloc(r.width*r.height*4);
  const inner=m.faces.map(f=>{
    if(!side || f.kind!=="back")return false;
    const n=P.normal(f.points),s=SIDES[side].inside;
    return n[0]*s[0]+n[1]*s[1]>.98 && f.points.every(p=>Math.abs(local(side,p)[1]+T/2-.025)<1e-5);
  });
  for(let i=0;i<r.owner.length;i++){
    const fi=r.owner[i];if(fi<0)continue;
    const x=i%r.width,y=Math.floor(i/r.width);
    const rgb=Stone.sample(maps[fi],[frame[0]+(x+.5)/ss,frame[1]+(y+.5)/ss]);
    // Only the actual inward plane of the blind recess receives ambient shade.
    const shade=inner[fi]?.80:1;
    for(let c=0;c<3;c++)rgba[i*4+c]=Math.round(rgb[c]*shade);
    rgba[i*4+3]=255;
  }
  const bytes=await sharp(rgba,{raw:{width:r.width,height:r.height,channels:4}}).resize(frame[2],frame[3]).png().toBuffer();
  fs.writeFileSync(path.join(out,obj.id+".png"),bytes);
  coffer[obj.id]={material:"walls-planes",frame,bytes:bytes.length};
}
function ground(coin,row,p){
  const inward=local(row.side,p)[1],offset=Math.abs(local(row.side,p)[0]-row.slot-.5);
  const clear=1-(1-smooth((inward-.23)/.3))*(1-smooth((offset-.35)/.17));
  const side=row.bays[0].side,along=SIDES[side].axis==="h"?0:1;
  const a=(p[along]-row.corner[along])*(row.corner[along]===0?1:-1),b=local(side,p)[1];
  // Sample the square sheet in the ground plane. Turning the corner permutes
  // or reflects the two axes; there is no second projection in the artwork.
  const scale=2.0;
  const ink=coin((a+.04)/scale,(b+.035)/scale);
  const mask=clear*smooth((2-a)/.13)*smooth((2-b)/.15);
  const lum=ink[0]*.29+ink[1]*.57+ink[2]*.14,shade=.85+.06*smooth(b/.55);
  return {premul:ink.slice(0,3).map(v=>(v*.89+lum*.11)*shade*mask),alpha:ink[3]*mask};
}
async function floor(id,row,x,y,coin,destination=out){
  const tile=floorKeys[x+","+y],reg=catalog.atlas.regions[tile];
  if(!floorCache.has(tile)){
    const [left,top,width,height]=reg.region;
    const src=await sharp(path.join(P.ROOT,"assets/dungeon/isometric-kit/atlas-256.png")).extract({left,top,width,height}).ensureAlpha().raw().toBuffer();
    floorCache.set(tile,src);
  }
  const base=floorCache.get(tile),pixels=Buffer.from(base),[w,h]=reg.size,off=reg.offset;
  let painted=0;
  for(let ypx=0;ypx<h;ypx++)for(let xpx=0;xpx<w;xpx++){
    const i=(ypx*w+xpx)*4;if(!base[i+3])continue;
    const [u,v]=P.ground([xpx+off[0]+.5,ypx+off[1]+.5]);
    const ink=ground(coin,row,[x+u,y+v]);
    if(ink.alpha<.005)continue; painted++;
    for(let c=0;c<3;c++)pixels[i+c]=Math.round(base[i+c]*(1-ink.alpha)+ink.premul[c]);
  }
  const bytes=await sharp(pixels,{raw:{width:w,height:h,channels:4}}).png().toBuffer();
  fs.writeFileSync(path.join(destination,id+".png"),bytes);return {tile,painted,bytes:bytes.length};
}
async function main(){
  fs.mkdirSync(out,{recursive:true});
  const coin=await floorPigment(),floors={};
  for(const row of rows){
    const cells=new Set(["0,0","1,0","0,1","1,1",...row.passage.map(key)]),hasPillar=boundary(cells);
    for(let j=0;j<row.bays.length;j++){
      const b=row.bays[j],m=bay(b,row.corner,hasPillar);
      await wall(row.objects[j],m.m,b.side);
    }
    await wall(row.objects[2],pier(row.corner),null);
    for(let y=0;y<2;y++)for(let x=0;x<2;x++){
      const id="sol-"+row.id+"-"+x+"-"+y;floors[id]=await floor(id,row,x,y,coin);
    }
    assert.equal(row.objects.length,3);
  }
  fs.writeFileSync(path.join(dir,"materials.json"),JSON.stringify({walls:coffer,floors},null,2)+"\n");
  console.log(done.size+" prepared wall modules; "+Object.keys(floors).length+" registered floor tiles.");
}
if(require.main===module)main().catch(e=>{console.error(e);process.exitCode=1;});
module.exports={floor};
