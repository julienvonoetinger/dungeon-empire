const sharp=require("sharp"),fs=require("node:fs"),path=require("node:path"),assert=require("node:assert/strict");
const dir=__dirname,root=path.resolve(dir,"../../../.."),verify=require("./verification.json"),rows=require("./reserve.json");
const floors=require("../v6-textures/floor-keys.json"),cat=require(path.join(root,"assets/dungeon/isometric-kit/catalog.json"));
const layouts=require("../v5-wireframe/layouts.json").rows;
const P=require("../../../../tools/isometric_paint_geometry.cjs");
async function main(){
 assert.equal(Object.keys(rows).length,8);assert.deepEqual(verify.failures,[]);
 let chestPixels=0,groundSamples=0;
 for(const [id,row] of Object.entries(rows)){
   const sideOfAlcove=layouts.find(layout=>layout.id===id).bays[0].side;
   assert.equal(row.originalChest,{W:"prop-chest-open-east",N:"prop-chest-open"}[sideOfAlcove]);
   for(const [total,visible] of Object.values(row.details)){assert(visible/total>.85);chestPixels+=visible;}
   const [side,slot]=[id[0],Number(id[1])-1];
   let gold=0;
   for(let x=0;x<2;x++)for(let y=0;y<2;y++){
     const reg=cat.atlas.regions[floors[x+","+y]], [left,top,width,height]=reg.region;
     const base=await sharp(path.join(root,"assets/dungeon/isometric-kit/atlas-256.png")).extract({left,top,width,height}).ensureAlpha().raw().toBuffer();
     const p=await sharp(path.join(dir,"sprites","sol-"+id+"-"+x+"-"+y+".png")).ensureAlpha().raw().toBuffer();
     for(let i=0;i<p.length;i+=4){
       assert.equal(p[i+3],base[i+3]);
       if(!p[i+3])continue;
       const k=i/4,[u,v]=P.ground([reg.offset[0]+k%width+.5,reg.offset[1]+Math.floor(k/width)+.5]),ax=x+u,ay=y+v;
       const depth={N:ay,E:2-ax,S:2-ay,W:ax}[side],off=(side==="N"||side==="S"?ax:ay)-slot-.5;
       const diff=p[i]!==base[i]||p[i+1]!==base[i+1]||p[i+2]!==base[i+2];
       if(depth>=0&&depth<=.22&&Math.abs(off)<.34){assert(!diff,id+" threshold must stay clear");groundSamples++;}
       if(diff)gold++;
     }
   }
   assert(gold>300);
 }
 assert(groundSamples>1000);
 await sharp(path.join(dir,"vues","S1.webp")).extract({left:248,top:85,width:482,height:305}).webp({lossless:true}).toFile(path.join(dir,"detail.webp"));
 console.log("8 correctly faced, legible coffers; "+chestPixels+" matching lock/lid samples; "+groundSamples+" clean threshold samples; 32 floor silhouettes; "+verify.checks+" native checks.");
}
main().catch(e=>{console.error(e);process.exitCode=1;});
