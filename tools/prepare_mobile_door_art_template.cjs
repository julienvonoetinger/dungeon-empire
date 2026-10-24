// Front elevation silhouette for ImageGen; same approved v8 wooden leaf.
const path=require('node:path'),sharp=require('sharp');
const R=require('./painted_material_renderer.cjs');
const {writeGeneratedFile:write}=require('./write_generated_file.cjs');
const OUT='docs/reference/mobile-door-frame-review/painted-art-v2/source';
const geometry=JSON.parse(R.read('docs/reference/mobile-door-frame-review/wireframe-v8/geometry.json'));
const leaf=geometry.volumes.find(v=>v.part==='wood');
const x0=Math.min(...leaf.profileXZ.map(p=>p[0])),x1=Math.max(...leaf.profileXZ.map(p=>p[0]));
const z0=Math.min(...leaf.profileXZ.map(p=>p[1])),z1=Math.max(...leaf.profileXZ.map(p=>p[1]));
const scale=800/(x1-x0),left=112,top=70;
const points=leaf.profileXZ.map(([x,z])=>[left+(x-x0)*scale,top+(z1-z)*scale]);
const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024"><polygon points="${points.map(p=>p.join(',')).join(' ')}" fill="#63402c" stroke="#bb8a55" stroke-width="4" stroke-linejoin="round"/></svg>`;
(async()=>{
 write(path.join(R.ROOT,OUT,'arch-template.svg'),svg);
 write(path.join(R.ROOT,OUT,'arch-template.png'),await sharp(Buffer.from(svg)).png().toBuffer());
 write(path.join(R.ROOT,OUT,'template.json'),JSON.stringify({geometry:'wireframe-v8',canvas:[1024,1024],left,top,width:800,height:(z1-z0)*scale,scale,profileXZ:leaf.profileXZ},null,2)+'\n');
 console.log('Prepared exact v8 leaf silhouette template.');
})();
