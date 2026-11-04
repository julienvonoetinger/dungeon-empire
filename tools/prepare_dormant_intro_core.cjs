// Render the existing approved pedestal without its separate vortex billboard.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto');
const P=require('./isometric_paint_geometry.cjs');
const Props=require('./isometric_prop_paint.cjs');
async function main(){
 const model=P.models.find(m=>m.id==='heart');
 const dormant=await Props.heart(model,{includeVortex:false});
 const out=path.join(P.ROOT,'assets/game/introduction/core-dormant.png');
 fs.writeFileSync(out,dormant.png);
 const review=path.join(P.ROOT,'docs/reference/invocation-magic/core-dormant.json');
 fs.writeFileSync(review,JSON.stringify({recipe:'tools/prepare_dormant_intro_core.cjs',source:Props.sources.heart,frame:dormant.frame,bounds:dormant.bounds,sha256:crypto.createHash('sha256').update(dormant.png).digest('hex'),description:'Original rigid pedestal and painted mapping; vortex billboard omitted. Full active core and atlas unchanged.'},null,2)+'\n');
 console.log(out);
}
main().catch(error=>{console.error(error);process.exitCode=1;});
