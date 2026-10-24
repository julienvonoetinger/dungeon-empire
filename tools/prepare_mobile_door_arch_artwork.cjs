// Offline material fitting: retain the complete native-alpha source, resample its
// painted rim onto the exact approved profile rather than cropping off that rim.
const path=require('node:path'),sharp=require('sharp');
const R=require('./painted_material_renderer.cjs');
const {writeGeneratedFile:write}=require('./write_generated_file.cjs');
const OUT='docs/reference/mobile-door-frame-review/painted-art-v2/source';
const geometry=JSON.parse(R.read('docs/reference/mobile-door-frame-review/wireframe-v8/geometry.json'));
const ps=geometry.volumes.find(v=>v.part==='wood').profileXZ;
const xmin=Math.min(...ps.map(p=>p[0])),xmax=Math.max(...ps.map(p=>p[0]));
const zmin=Math.min(...ps.map(p=>p[1])),zmax=Math.max(...ps.map(p=>p[1]));
async function main(){
 const source=R.read(OUT+'/door-artwork.png'),meta=await sharp(source).metadata();
 if(!meta.hasAlpha)throw Error('The arched source must have native alpha.');
 const {data,info}=await sharp(source).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 const rows=[];let top=info.height,bottom=-1,left=info.width,right=-1;
 for(let y=0;y<info.height;y++){
  let lo=info.width,hi=-1;
  for(let x=0;x<info.width;x++)if(data[(y*info.width+x)*4+3]>8){lo=Math.min(lo,x);hi=x;}
  rows.push([lo,hi]);if(hi>=lo){top=Math.min(top,y);bottom=y;left=Math.min(left,lo);right=Math.max(right,hi);}
 }
 const width=832,height=Math.round(width*(zmax-zmin)/(xmax-xmin)),pixels=Buffer.alloc(width*height*4);
 const sample=(x,y)=>{
  const X=Math.floor(x),Y=Math.floor(y),dx=x-X,dy=y-Y,rgba=[0,0,0,0];
  for(let j=0;j<2;j++)for(let i=0;i<2;i++){
   const qx=X+i,qy=Y+j;if(qx<0||qy<0||qx>=info.width||qy>=info.height)continue;
   const k=(qy*info.width+qx)*4,w=(i?dx:1-dx)*(j?dy:1-dy),a=data[k+3]/255;
   rgba[3]+=a*w;for(let c=0;c<3;c++)rgba[c]+=data[k+c]*a*w;
  }
  return [...rgba.slice(0,3).map(c=>rgba[3]?Math.round(c/rgba[3]):0),Math.round(rgba[3]*255)];
 };
 for(let y=0;y<height;y++){
  const v=(y+.5)/height,z=zmax-v*(zmax-zmin),cuts=[];
  for(let i=0;i<ps.length;i++){
   const a=ps[i],b=ps[(i+1)%ps.length];
   if(a[1]!==b[1]&&z>=Math.min(a[1],b[1])&&z<=Math.max(a[1],b[1]))cuts.push(a[0]+(b[0]-a[0])*(z-a[1])/(b[1]-a[1]));
  }
  if(cuts.length<2)continue;
  const lo=Math.min(...cuts),hi=Math.max(...cuts),sy=top+v*(bottom-top+1)-.5;
  const row=rows[Math.max(top,Math.min(bottom,Math.round(sy)))];if(row[1]<row[0])continue;
  for(let x=0;x<width;x++){
   const world=xmin+(x+.5)/width*(xmax-xmin),u=(world-lo)/(hi-lo);if(u<0||u>1)continue;
   const sx=row[0]-.5+u*(row[1]-row[0]+1),rgba=sample(sx,sy),k=(y*width+x)*4;
   for(let c=0;c<4;c++)pixels[k+c]=rgba[c];
  }
 }
 const fitted=await sharp(pixels,{raw:{width,height,channels:4}}).png().toBuffer();
 write(path.join(R.ROOT,OUT,'door-face-fitted.png'),fitted);
 const report={sourceSha256:R.hash(source),fittedSha256:R.hash(fitted),sourceSize:[info.width,info.height],nativeAlpha:true,sourceBounds:{left,top,width:right-left+1,height:bottom-top+1},outputSize:[width,height],method:'Horizontal resampling per source-alpha row onto the approved v8 front profile; premultiplied alpha interpolation, no threshold applied to saved pixels.',guide:'wireframe-v8/geometry.json'};
 write(path.join(R.ROOT,OUT,'fit.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify(report));
}
main().catch(e=>{console.error(e);process.exitCode=1;});
