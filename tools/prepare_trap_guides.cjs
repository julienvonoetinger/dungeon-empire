// Exact 2:1 guides for disposable trap appearance edits, not game resources.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs');
const DIR=path.join(P.ROOT,'docs/reference/trap-review/v1/guides');
function face(m,points,kind){m.faces.push({points,kind});}
function box(m,x,X,y,Y,z,Z,kind){const p=[[x,y,z],[X,y,z],[X,Y,z],[x,Y,z],[x,y,Z],[X,y,Z],[X,Y,Z],[x,Y,Z]];for(const ids of [[0,3,2,1],[4,5,6,7],[0,1,5,4],[1,2,6,5],[2,3,7,6],[3,0,4,7]])face(m,ids.map(i=>p[i]),kind);}
function base(id){const m={id,faces:[]};box(m,-.27,.27,-.27,.27,0,.023,'stone');box(m,-.245,.245,-.245,.245,.023,.027,'iron');return m;}
function spike(m,x,y){const a=.048,z=.035,Z=.17;const p=[[x-a,y-a,z],[x+a,y-a,z],[x+a,y+a,z],[x-a,y+a,z]];for(let i=0;i<4;i++)face(m,[p[i],p[(i+1)%4],[x,y,Z]],'steel');}
function ring(m,r,R,a,A,z,Z,kind){const f=t=>[Math.cos(t),Math.sin(t)];for(let i=0;i<20;i++){const s=a+(A-a)*i/20,t=a+(A-a)*(i+1)/20,p=(v,h,q)=>[f(v)[0]*h,f(v)[1]*h,q];face(m,[p(s,r,Z),p(s,R,Z),p(t,R,Z),p(t,r,Z)],kind);face(m,[p(s,R,z),p(t,R,z),p(t,R,Z),p(s,R,Z)],kind);face(m,[p(s,r,z),p(s,r,Z),p(t,r,Z),p(t,r,z)],kind);}}
async function main(){
 fs.mkdirSync(DIR,{recursive:true});const models=[];
 const spikes=base('pointes');for(const x of [-.16,0,.16])for(const y of [-.16,0,.16]){box(spikes,x-.06,x+.06,y-.06,y+.06,.027,.033,'socket');spike(spikes,x,y);}models.push(spikes);
 const snare=base('entrave');box(snare,-.075,.075,-.075,.075,.027,.037,'trigger');
 for(const [a,A] of [[.12,Math.PI-.12],[Math.PI+.12,2*Math.PI-.12]]){
  ring(snare,.175,.205,a,A,.03,.075,'iron');
  for(let i=0;i<4;i++){const t=a+(A-a)*(i+.5)/4,r=.175,d=.025;const p=(v,h,z)=>[Math.cos(v)*h,Math.sin(v)*h,z];face(snare,[p(t-d/r,r,.075),p(t+d/r,r,.075),p(t,.115,.09)],'steel');face(snare,[p(t-d/r,r,.075),p(t,.115,.09),p(t-d/r,r,.04)],'steel');}
 }
 for(const x of [-.22,.22])box(snare,x-.025,x+.025,-.04,.04,.027,.09,'steel');models.push(snare);
 const neant=base('neant');const circle=[];for(let i=0;i<80;i++){const a=i*Math.PI/40;circle.push([Math.cos(a)*.17,Math.sin(a)*.17,.028]);}face(neant,circle,'void');ring(neant,.17,.19,0,Math.PI*2,.028,.036,'violet');ring(neant,.19,.23,0,Math.PI*2,.027,.037,'stone');models.push(neant);
 const colors={stone:['#45536e','#29384e','#233047'],iron:['#333e52','#243046','#1a2639'],socket:['#141b29','#111a27','#101724'],steel:['#9aaec8','#687e9c','#485c79'],trigger:['#685279','#3f3655','#332e46'],void:['#10091d','#10091d','#10091d'],violet:['#a959dc','#6e3494','#47235e']};
 for(const m of models){
  // A depth buffer is required: a whole floor polygon sorted by its centre
  // would incorrectly cover the raised rear mechanisms.
  const mesh=P.raster(m,[-96,-72,192,128],8),raw=Buffer.alloc(mesh.width*mesh.height*4);
  const palette=m.faces.map(f=>{const n=P.normal(f.points);return colors[f.kind][n[2]>.7?0:Math.abs(n[0])>Math.abs(n[1])?2:1].slice(1).match(/../g).map(v=>parseInt(v,16));});
  for(let y=0;y<mesh.height;y++)for(let x=0;x<mesh.width;x++){const k=y*mesh.width+x,owner=mesh.owner[k];if(owner<0)continue;let edge=false;for(const [dx,dy] of [[-1,0],[1,0],[0,-1],[0,1]]){const X=x+dx,Y=y+dy;if(X<0||Y<0||X>=mesh.width||Y>=mesh.height||mesh.owner[Y*mesh.width+X]!==owner)edge=true;}raw.set(edge?[17,27,42,255]:[...palette[owner],255],k*4);}
  const png=await sharp(raw,{raw:{width:mesh.width,height:mesh.height,channels:4}}).png().toBuffer();fs.writeFileSync(path.join(DIR,m.id+'.png'),png);
  fs.writeFileSync(path.join(DIR,m.id+'.svg'),`<svg xmlns="http://www.w3.org/2000/svg" width="1536" height="1024"><image width="1536" height="1024" href="data:image/png;base64,${png.toString('base64')}"/></svg>`);
 }
 fs.writeFileSync(path.join(DIR,'geometry.json'),JSON.stringify({camera:P.camera,footprint:.54,baseHeight:.023,screenGroundDiamond:[1105.92,552.96],models},null,2));
}
main().catch(e=>{console.error(e);process.exitCode=1});
