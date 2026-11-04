// Preserve the approved geometry/canvas while preparing native painted artwork.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),sharp=require('sharp');
const ROOT=path.resolve(__dirname,'..'),review=path.join(ROOT,'docs/reference/invocation-magic/stairwell-painted');
const out=path.join(ROOT,'assets/previews/sanctuary-stairwell-painted');
async function main(){
 fs.mkdirSync(review,{recursive:true});fs.mkdirSync(out,{recursive:true});
 const geometry=fs.readFileSync(path.join(ROOT,'assets/previews/sanctuary-stairwell-wireframe/geometry.json'));
 const data=JSON.parse(geometry);
 if(process.argv.includes('--guide')){
  let svg=fs.readFileSync(path.join(ROOT,'assets/previews/sanctuary-stairwell-wireframe/stairwell.svg'),'utf8');
  svg=svg.replace(/<polygon[^>]*stroke="#dfbe80"[^>]*\/>/g,'');
  await sharp(Buffer.from(svg),{density:288}).png().toFile(path.join(review,'guide.png'));
  return;
 }
 const source=path.join(review,'source.png'),meta=await sharp(source).metadata();
 if(!meta.hasAlpha)throw Error('Native transparency required');
 if(Math.abs(meta.width/meta.height-data.frame[2]/data.frame[3])>.01)throw Error('Generated canvas aspect ratio differs from guide');
 await sharp(source).resize(data.frame[2],data.frame[3],{fit:'contain',background:{r:0,g:0,b:0,alpha:0}}).png().toFile(path.join(out,'stairs.png'));
 fs.writeFileSync(path.join(out,'geometry.json'),geometry);
 fs.writeFileSync(path.join(review,'recipe.json'),JSON.stringify({source:'source.png',sha256:crypto.createHash('sha256').update(fs.readFileSync(source)).digest('hex'),sourceSize:[meta.width,meta.height],frame:data.frame,method:'Whole painted sprite, uniform contain reduction, native alpha, same canvas registration as approved guide',generator:'tools/prepare_invocation_stairwell_painted.cjs'},null,2)+'\n');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
