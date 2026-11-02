const fs=require("node:fs"),path=require("node:path"),sharp=require("sharp"),assert=require("node:assert/strict");
const dir=__dirname,root=path.resolve(dir,"../../../.."),work=path.join(root,"artifacts/treasury-volume");
const geo=require(path.join(work,"geometry.json"));
const out=path.join(dir,"sprites");fs.mkdirSync(out,{recursive:true});
function section(){
  const s=require(path.join(work,"section.json"));
  const line=([[x,z],[u,v]])=>"M"+(85+500*x).toFixed(2)+" "+(500-500*z).toFixed(2)+" L"+(85+500*u).toFixed(2)+" "+(500-500*v).toFixed(2);
  const svg='<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 610 555"><rect width="610" height="555" rx="6" fill="#151d2a"/><defs><clipPath id="plot"><rect x="10" y="46" width="590" height="458"/></clipPath></defs>'+
    '<g font-family="system-ui,sans-serif" fill="#e4ded0"><text x="22" y="30" font-size="20">Coupe verticale dans la grande alcôve</text><text x="22" y="537" font-size="15">Fond de niche</text><text x="430" y="537" font-size="15">Vers la salle →</text></g>'+
    '<g clip-path="url(#plot)"><path d="M20 500H590" stroke="#9ba8bc"/>'+
    '<path fill="none" stroke-width="1.5" stroke="#77849b" d="'+s.stone.map(line).join(" ")+'"/>'+
    '<path fill="none" stroke-width="1.55" stroke="#e6b25e" d="'+s.gold.map(line).join(" ")+'"/></g></svg>';
  fs.writeFileSync(path.join(dir,"coupe.svg"),svg);
}
async function main(){
 const reports={};
 for(const id of Object.keys(geo.worlds)){
    const source=path.join(work,id+".png"),[x,y,w,h]=geo.frame;
    const rgba=await sharp(source).resize(w,h).ensureAlpha().raw().toBuffer();
    let l=w,t=h,rr=-1,bb=-1,opaque=0;
    for(let k=0;k<rgba.length;k+=4){
      if(rgba[k+3]<=3){rgba.fill(0,k,k+4);continue;}
      if(rgba[k+3]>220)opaque++;
      const xx=(k/4)%w,yy=Math.floor(k/4/w);
      l=Math.min(l,xx);t=Math.min(t,yy);rr=Math.max(rr,xx);bb=Math.max(bb,yy);
    }
    assert(opaque>3000,id+" missing rendered contents");
    const sprite=await sharp(rgba,{raw:{width:w,height:h,channels:4}}).extract({left:l,top:t,width:rr-l+1,height:bb-t+1}).webp({lossless:true}).toBuffer();
    fs.writeFileSync(path.join(out,id+".webp"),sprite);
    const meta=require(path.join(work,id+".json"));
    assert(meta.bays[0].peak>.36&&meta.bays[1].peak>.24&&meta.blockedCentres>0&&meta.visibleCentres>0);
    reports[id]={...meta,frame:[x+l,y+t,rr-l+1,bb-t+1],bytes:sprite.length};
 }
 fs.writeFileSync(path.join(dir,"reserve.json"),JSON.stringify(reports,null,2)+"\n");section();
}
main().catch(e=>{console.error(e);process.exitCode=1;});
