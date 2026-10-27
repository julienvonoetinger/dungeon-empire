const fs=require('node:fs'),assert=require('node:assert/strict');
const P=require('./isometric_paint_geometry.cjs'),R=require('./isometric_trap_registration.cjs');
const Receiver=require('./isometric_trap_receiver.cjs');
const selection=JSON.parse(fs.readFileSync('docs/reference/trap-review/v12-approved-square/selection.json'));
for(const [file,hash]of Object.entries(selection.hashes))assert.equal(P.hash(file),hash,'Approved wireframe changed');
assert.equal(R.OPEN,.16,'Trap paint still uses the rejected smaller opening');
assert.ok(Math.abs(R.SPAN-.68)<1e-9);
const approved=JSON.parse(fs.readFileSync(selection.review+'/geometry.json'));
const expected=approved.model.stones.filter(s=>s.rect[1]>0&&s.rect[0]<1&&s.rect[3]>0&&s.rect[2]<1);
assert.deepEqual(Receiver.stones,expected,'Paving differs from approved rectangular stones');
let area=0;
for(const {rect:[x,X,y,Y]}of Receiver.stones){
 area+=(Math.min(1,X)-Math.max(0,x))*(Math.min(1,Y)-Math.max(0,y));
 assert.ok(X<=.16||x>=.84||Y<=.16||y>=.84,'Stone overlaps trap opening');
}
assert.ok(Math.abs(area-(1-.68**2))<1e-9);
// The colour guard ends at .07, before any geometry changed from the B floor.
for(const r of approved.replacements){
 const a=r.before,b=r.after;
 const x0=Math.min(a[0],b[0]),x1=Math.max(a[0],b[0]);
 const X0=Math.min(a[1],b[1]),X1=Math.max(a[1],b[1]);
 for(const [x,X]of [[x0,x1],[X0,X1]])if(X>x){
  assert.ok(x>=.07&&X<=.93&&b[2]>=.07&&b[3]<=.93,'Changed geometry inside material guard');
 }
}
for(const kind of ['spike','snare','void'])for(let s=0;s<3;s++){
 const reg=R.registration(kind,s);
 for(const p of [[.16,.16,0],[.84,.16,0],[.84,.84,0],[.16,.84,0],[.5,.5,.25]]){
  // sourceUV maps the floor plane. Add the separately projected height when
  // validating the inverse of an elevated source point.
  const uv=R.sourceUV(reg,p);uv[1]-=p[2]*reg.vertical;
  const q=R.sourcePoint(reg,uv,p[2]);
  assert.ok(q.every((v,i)=>Math.abs(v-p[i])<1e-9),'Registration loses centre or height');
 }
}
console.log(JSON.stringify({approvedSquare:true,rectangularStones:expected.length,pavingArea:area,registrationRoundTrips:45}));
