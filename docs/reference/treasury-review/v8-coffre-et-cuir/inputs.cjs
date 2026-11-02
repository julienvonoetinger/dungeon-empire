const fs=require("node:fs"),path=require("node:path"),sharp=require("sharp"),crypto=require("node:crypto");
const assert=require("node:assert/strict"),dir=__dirname,root=path.resolve(dir,"../../../..");
const work=path.join(root,"artifacts/treasury-painted"),out=path.join(dir,"sprites");
const {floor}=require("../v6-textures/paint.cjs");
const {rows}=require("../v5-wireframe/layouts.json");
const catalog=require(path.join(root,"assets/dungeon/isometric-kit/catalog.json"));
const fits=require(path.join(root,"tools/chest_direction_sources.json")).items;
function random(seed){return ()=>{seed=(Math.imul(1664525,seed)+1013904223)>>>0;return seed/4294967296;};}
async function trimmed(id){
 const im=await sharp(path.join(dir,"source",id+".png")).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 const {width:w,height:h}=im.info;let l=w,r=0,t=h,b=0;
 for(let k=0;k<im.data.length;k+=4)if(im.data[k+3]>=80){const x=(k/4)%w,y=Math.floor(k/(4*w));l=Math.min(l,x);r=Math.max(r,x);t=Math.min(t,y);b=Math.max(b,y);}
 assert(r>l&&b>t);const tex=sharp(im.data,{raw:im.info}).extract({left:l,top:t,width:r-l+1,height:b-t+1});
 if(id==="monnaie")tex.resize(160,160,{fit:"fill"});else tex.resize({height:320});
 await tex.png().toFile(path.join(work,id+".png"));
}
async function main(){
 fs.mkdirSync(work,{recursive:true});fs.mkdirSync(out,{recursive:true});
 for(const id of ["monnaie","sac-lie","sac-ouvert"])await trimmed(id);
 // Rectify one plain painted face from the production chest master. The mesh
 // (or floor projection) will provide its actual new perspective and thickness.
 const plain=await sharp(path.join(root,fits.find(x=>x.id==="prop-chest-open").source))
   .extract({left:500,top:536,width:50,height:24}).resize(160,160,{fit:"fill"}).ensureAlpha().raw().toBuffer();
 for(let y=0;y<160;y++)for(let x=0;x<160;x++){
   const radius=Math.hypot(x+.5-80,y+.5-80);
   plain[4*(160*y+x)+3]=Math.round(255*Math.min(1,Math.max(0,79.5-radius)));
 }
 await sharp(plain,{raw:{width:160,height:160,channels:4}}).png().toFile(path.join(work,"plain-coin.png"));
 const chest={};
 for(const [side,id] of [["N","prop-chest-open"],["W","prop-chest-open-east"]]){
    const e=catalog.atlas.regions[id], [left,top,width,height]=e.region;
    const src=e.atlas_path.replace("res://","");
    const bytes=await sharp(path.join(root,src)).extract({left,top,width,height}).png().toBuffer();
    fs.writeFileSync(path.join(work,id+".png"),bytes);
    const fit=fits.find(x=>x.id===id),original=path.join(root,fit.source);
    const hash=crypto.createHash("sha256").update(fs.readFileSync(original)).digest("hex");
    assert.equal(hash,fit.sha256);
    const {data,info}=await sharp(original).ensureAlpha().raw().toBuffer({resolveWithObject:true});
    let x0=info.width,y0=info.height,x1=-1,y1=-1;
    for(let k=0;k<data.length;k+=4)if(data[k+3]){
        const x=(k/4)%info.width,y=Math.floor(k/4/info.width);
        x0=Math.min(x,x0);y0=Math.min(y,y0);x1=Math.max(x,x1);y1=Math.max(y,y1);
    }
    const ratio=(e.size[0]-4)/(x1-x0+1);
    assert(Math.abs(e.offset[0]-(x0-fit.anchor[0])*ratio+2)<.00001);
    assert(Math.abs(e.offset[1]-(y0-fit.anchor[1])*ratio+2)<.00001);
    const high=await sharp(original).extract({left:x0,top:y0,width:x1-x0+1,height:y1-y0+1})
      .resize((e.size[0]-4)*3,(e.size[1]-4)*3,{fit:"fill"}).png().toBuffer();
    await sharp(high).extend({top:6,bottom:6,left:6,right:6,background:"#00000000"}).png().toFile(path.join(work,id+"-master.png"));
    chest[side]={id,src,master:fit.source,masterHash:hash,region:e.region,size:e.size,offset:e.offset,bounds:e.bounds,facing:e.decoration.facing,
      sha256:crypto.createHash("sha256").update(bytes).digest("hex")};
 }
 fs.writeFileSync(path.join(work,"chest.json"),JSON.stringify(chest,null,2));
 const n=768,rand=random(28203);const layers=[];
 // Two banks and isolated strays. Paint circular impressions overhead and let
 // the native floor projection compress them exactly once.
 for(let i=0;i<620;i++){
    const x=rand(),y=rand(),long=Math.max(0,1-y/(.47*(1-.35*x)))*Math.max(0,1-x/.88);
    const short=Math.max(0,1-x/.32)*Math.max(0,1-y/.62);
    if(rand()>.04+1.75*Math.max(long,short))continue;
    const size=Math.round(n*(.023+rand()*.013));
    layers.push({x,y,size,angle:rand()*360});
 }
 // Add small clusters near the wall behind the true volume.
 for(let i=0;i<112;i++){const x=rand()*.90,y=Math.pow(rand(),2)*.14; layers.push({x,y,size:Math.round(n*(.022+rand()*.011)),angle:rand()*360});}
 const tiles=[];
 for(const [i,{x,y,size,angle}] of layers.entries()){
    const stamp=await sharp(path.join(work,i%5===0?"monnaie.png":"plain-coin.png")).resize(size,size).png().toBuffer();
    const {data,info}=await sharp(stamp).rotate(angle,{background:"#00000000"}).png().toBuffer({resolveWithObject:true});
    tiles.push({input:data,left:Math.min(n-info.width,Math.max(0,Math.round(x*n-info.width/2))),top:Math.min(n-info.height,Math.max(0,Math.round(y*n-info.height/2)))});
 }
 const sheet=await sharp({create:{width:n,height:n,channels:4,background:"#00000000"}}).composite(tiles).png().toBuffer();
 const rgba=await sharp(sheet).ensureAlpha().raw().toBuffer();
 const pigment=(u,v)=>{if(u<0||v<0||u>1||v>1)return [0,0,0,0];const i=4*(Math.round(v*(n-1))*n+Math.round(u*(n-1))),a=rgba[i+3]/255;return [rgba[i]*a,rgba[i+1]*a,rgba[i+2]*a,a];};
 for(const row of rows)for(let y=0;y<2;y++)for(let x=0;x<2;x++)
    await floor("sol-"+row.id+"-"+x+"-"+y,row,x,y,pigment,out);
 console.log("Native chest faces, both purses, mint and 32 floor tiles prepared.");
}
main().catch(e=>{console.error(e);process.exitCode=1;});
