// Keep the native painting's proportions. Remove only excess transparent margin.
const fs=require("node:fs"),path=require("node:path"),sharp=require("sharp"),assert=require("node:assert/strict");
async function prepare(dir=__dirname){
 const {data,info}=await sharp(path.join(dir,"source/treasure-master.png")).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 let l=info.width,r=-1,t=info.height,b=-1,transparent=0;
 for(let k=0;k<data.length;k+=4){
   if(data[k+3]===0)transparent++;
   if(data[k+3]<12)continue;
   const x=(k/4)%info.width,y=Math.floor(k/4/info.width);
   l=Math.min(l,x);r=Math.max(r,x);t=Math.min(t,y);b=Math.max(b,y);
 }
 assert(transparent>info.width*info.height*.35 && l>0 && t>0 && r<info.width-1 && b<info.height-1);
 const pad=10,left=Math.max(0,l-pad),top=Math.max(0,t-pad);
 const width=Math.min(info.width,r+pad+1)-left,height=Math.min(info.height,b+pad+1)-top;
 const png=await sharp(data,{raw:info}).extract({left,top,width,height})
   .resize({width:372,kernel:"lanczos3"}).png().toBuffer();
 const meta=await sharp(png).metadata();
 const record={file:"reserve.png",width:meta.width,height:meta.height,pivot:[meta.width/2,Math.round(meta.height*.685)],bytes:png.length};
 fs.writeFileSync(path.join(dir,record.file),png);fs.writeFileSync(path.join(dir,"sprite.json"),JSON.stringify(record,null,2)+"\n");
 console.log(record);
}
if(require.main===module)prepare().catch(e=>{console.error(e);process.exitCode=1});
module.exports={prepare};
