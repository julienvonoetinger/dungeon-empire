const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs');
const BASE='docs/reference/door-redesign/seal-v1',DIR=BASE+'/hero-fit-v13-malefic-leaf';
async function main(){
 const old=JSON.parse(fs.readFileSync(path.join(P.ROOT,BASE+'/hero-fit-v12-integrated/selection.json')));
 for(const[p,h]of Object.entries(old.files))assert.equal(P.hash(p),h,'Frozen v12 dependency '+p);
 const leafPainting=DIR+'/source/face-source.png',m=await sharp(path.join(P.ROOT,leafPainting)).metadata();
 assert.equal(m.width,1024);assert.equal(m.height,1536);assert.equal(m.hasAlpha,true);
 const sourceFiles=[leafPainting,DIR+'/source/prompt.txt',DIR+'/source/unified-frame-prompt.txt',DIR+'/source/cross-separate-hinges.png'];
 const selection={...old,date:'2026-10-28',status:'approved-geometry-new-leaf-proposal',userApproval:'Compact v11 geometry approved. User requests sinister leaf, then hinges fused into a # iron framework. New paint awaits visual feedback.',leafPainting,files:{...old.files,...Object.fromEntries(sourceFiles.map(p=>[p,P.hash(p)]))}};
 fs.writeFileSync(path.join(P.ROOT,DIR,'selection.json'),JSON.stringify(selection,null,2)+'\n');
 console.log('Selected separate leaf material; original masonry, geometry and UV fit remain frozen');
}
main().catch(e=>{console.error(e);process.exitCode=1});
