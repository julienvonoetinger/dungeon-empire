// Lock and lid checks compare the rendered native atlas colors at their actual
// projected positions, not just whether the intended resource name was selected.
const fs=require("node:fs"),path=require("node:path"),sharp=require("sharp"),assert=require("node:assert/strict");
const dir=__dirname,work=path.resolve(dir,"../../../../artifacts/treasury-painted");
const chest=require(path.join(work,"chest.json")),geo=require(path.join(work,"../treasury-volume/geometry.json"));
const out=path.join(dir,"sprites");
async function exposure(raw,w,h,report,c){
 const {data,info}=await sharp(path.join(work,c.id+"-master.png")).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 const [fx,fy]=geo.frame,checks={lock:[0,0],lid:[0,0]};
 const ox=report.projectedAnchor[0]+c.offset[0]-fx,oy=report.projectedAnchor[1]+c.offset[1]-fy;
 // Compare pigment at the SAME screen-pixel centers, sampling the full-size
 // master. Atlas texel centers and display pixel centers do not coincide.
 for(let yy=Math.ceil(oy);yy<oy+c.size[1]-.5;yy++)for(let xx=Math.ceil(ox);xx<ox+c.size[0]-.5;xx++){
    const x=Math.floor((xx+.5-ox)*info.width/c.size[0]),y=Math.floor((yy+.5-oy)*info.height/c.size[1]);
    const k=4*(y*info.width+x);
    if(data[k+3]<245)continue;
    const [r,g,b]=data.subarray(k,k+3);
    let family;
    if(y>info.height*.44 && y<info.height*.8 && b>100 && b>r*1.04 && r>g*1.6)family="lock";
    else if(y<info.height*.53 && r>58 && g>r*.94 && b>g*1.10)family="lid";
    if(!family)continue;
    assert(xx>=0&&xx<w&&yy>=0&&yy<h);const j=4*(yy*w+xx);checks[family][0]++;
    const [R,G,B]=raw.subarray(j,j+3);
    const present=family==="lock"?B>83&&B>R&&R>G*1.25:R>42&&G>R*.89&&B>G*1.045;
    if(raw[j+3]>230&&present)checks[family][1]++;
 }
 for(const [kind,[total,matches]] of Object.entries(checks)){
    assert(total>25 && matches/total>.85,report.id+" "+kind+" visibility "+matches+"/"+total);
 }
 return checks;
}
async function main(){
 const reports={};
 for(const id of Object.keys(geo.worlds)){
    const report=require(path.join(work,id+".json"));
    const c=chest[geo.worlds[id].bays[0].side];
    assert.equal(report.cofferPixelHash,c.sha256);
    assert.equal(report.originalChest,c.id);
    assert.deepEqual(report.purses,["sac-ouvert","sac-lie"]);
    assert(report.peak[0]>.36&&report.peak[1]>.24&&report.hiddenCoinCentres>0&&report.visibleCoinCentres>0);
    const [x,y,w,h]=geo.frame;
    const rgba=await sharp(path.join(work,id+".png")).resize(w,h).ensureAlpha().raw().toBuffer();
    const details=await exposure(rgba,w,h,report,c);
    let l=w,t=h,r=-1,b=-1;
    for(let i=0;i<rgba.length;i+=4){
       if(rgba[i+3]<=3){rgba.fill(0,i,i+4);continue;}
       const xx=(i/4)%w,yy=Math.floor(i/4/w);l=Math.min(l,xx);t=Math.min(t,yy);r=Math.max(r,xx);b=Math.max(b,yy);
    }
    const frame=[x+l,y+t,r-l+1,b-t+1];
    const sprite=await sharp(rgba,{raw:{width:w,height:h,channels:4}}).extract({left:l,top:t,width:frame[2],height:frame[3]}).webp({lossless:true}).toBuffer();
    fs.writeFileSync(path.join(out,id+".webp"),sprite);
    reports[id]={...report,details,master:c.master,masterHash:c.masterHash,frame,bytes:sprite.length};
    console.log(id,details);
 }
 fs.writeFileSync(path.join(dir,"reserve.json"),JSON.stringify(reports,null,2)+"\n");
}
main().catch(e=>{console.error(e);process.exitCode=1});
