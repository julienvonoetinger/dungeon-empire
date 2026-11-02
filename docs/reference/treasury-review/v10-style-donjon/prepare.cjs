const fs=require("node:fs"),path=require("node:path");
const v9="../v9-sprite-unique";
const {prepare}=require(v9+"/prepare.cjs");
const baseline=require(v9+"/sprite.json");
(async()=>{
 await prepare(__dirname);
 const dest=path.join(__dirname,"sprite.json");
 const sprite=JSON.parse(fs.readFileSync(dest));
 // Register the front contact against the same floor position. A taller lid
 // should change the upper silhouette, not slide the whole hoard on the floor.
 sprite.pivot[1]=sprite.height-(baseline.height-baseline.pivot[1]);
 fs.writeFileSync(dest,JSON.stringify(sprite,null,2)+"\n");
})().catch(e=>{console.error(e);process.exitCode=1;});
