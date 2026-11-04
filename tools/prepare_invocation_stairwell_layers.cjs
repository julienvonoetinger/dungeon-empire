// Register approved painted pixels to the frozen entrance geometry; no repaint.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs');
const root=path.resolve(__dirname,'..'),out=path.join(root,'assets/game/introduction/stairwell-v2');
async function main(){
 const source=path.join(root,'assets/previews/sanctuary-stairwell-painted');
 const geometry=JSON.parse(fs.readFileSync(path.join(source,'geometry.json')));
 const model=JSON.parse(fs.readFileSync(path.join(root,'docs/reference/invocation-magic/stairwell-wireframe/geometry.json'))).model;
 const cast=P.caster(model),bytes=fs.readFileSync(path.join(source,'stairs.png'));
 const {data,info}=await sharp(bytes).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 const mask=Buffer.alloc(info.width*info.height),archMask=Buffer.alloc(mask.length),aperture=Buffer.alloc(data.length);
 for(let y=0;y<info.height;y++)for(let x=0;x<info.width;x++){
  const k=y*info.width+x,hit=cast([geometry.frame[0]+x+.5,geometry.frame[1]+y+.5]);
  if(hit&&hit.face.kind==='side'&&hit.p[0]>.90)mask[k]=255;
  if(hit&&hit.face.kind==='arch')archMask[k]=255;
  // The opaque painted tunnel interior is a mask, not a new painted surface.
  if(data[k*4+3]>0&&Math.max(...data.subarray(k*4,k*4+3))<49){aperture[k*4]=255;aperture[k*4+1]=255;aperture[k*4+2]=255;aperture[k*4+3]=data[k*4+3];}
 }
 const expanded=await sharp(mask,{raw:{width:info.width,height:info.height,channels:1}}).dilate(2).toColourspace('b-w').raw().toBuffer();
 if(expanded.length!==mask.length)throw Error('Foreground classification must remain one channel');
 const front=Buffer.from(data);
 for(let k=0;k<mask.length;k++)if(!expanded[k])front[k*4+3]=0;
 fs.mkdirSync(out,{recursive:true});fs.writeFileSync(path.join(out,'stairs.png'),bytes);
 fs.copyFileSync(path.join(source,'geometry.json'),path.join(out,'geometry.json'));
 await sharp(front,{raw:{width:info.width,height:info.height,channels:4}}).png().toFile(path.join(out,'foreground.png'));
 const expandedArch=await sharp(archMask,{raw:{width:info.width,height:info.height,channels:1}}).dilate(2).toColourspace('b-w').raw().toBuffer();
 const arch=Buffer.from(data);
 for(let k=0;k<mask.length;k++)if(!expandedArch[k])arch[k*4+3]=0;
 await sharp(arch,{raw:{width:info.width,height:info.height,channels:4}}).png().toFile(path.join(out,'arch.png'));
 await sharp(aperture,{raw:{width:info.width,height:info.height,channels:4}}).png().toFile(path.join(out,'aperture.png'));
 console.log('Approved entrance copied byte-identically; geometry-based foreground mask, painted tunnel mask.');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
