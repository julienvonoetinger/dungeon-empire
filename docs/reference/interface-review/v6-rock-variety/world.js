/* Disposable review renderer. The production renderer and its assets are untouched. */
window.ForgeWorld=class{
 constructor(view,canvas,data){this.view=view;this.canvas=canvas;this.ctx=canvas.getContext('2d');this.data=data;this.pan={x:0,y:0};this.integrated=true;this.placements=[];this.hover=null;this.selected=null;this.active=true;this.ready=false;this.images={};this.cells=new Map();
  for(const s of data.sprites.filter(s=>s.id.startsWith('floor'))){const e=data.regions[s.id],a=[s.p[0]-e.offset[0],s.p[1]-e.offset[1]],c={x:Math.round(a[0]/256+a[1]/128),y:Math.round(a[1]/128-a[0]/256)};this.cells.set(this.key(c),c);}
  this.loading=Promise.all(['architecture','chests','spikes','mass','dust','quiet','strata','outcrop','rubble'].map(name=>new Promise((resolve,reject)=>{const img=new Image();this.images[name]=img;img.onload=resolve;img.onerror=reject;img.src=window.REVIEW_ASSETS?.[name]||`assets/${name}.png`;}))).then(()=>{this.massPattern=this.ctx.createPattern(this.images.mass,'repeat');this.massPattern.setTransform(new DOMMatrix().scale(2/this.images.mass.width));this.quietPattern=this.ctx.createPattern(this.images.quiet,'repeat');this.quietPattern.setTransform(new DOMMatrix().scale(3/this.images.quiet.width));this.massLayer=document.createElement('canvas');this.ready=true;this.resize();});
 }
 key(c){return `${c.x},${c.y}`;}
 hash(x,y){const n=Math.sin(x*127.1+y*311.7+17.3)*43758.5453;return n-Math.floor(n);}
 transform(){const r=this.view.getBoundingClientRect();return {s:.49,ox:r.width/2+this.pan.x,oy:r.height*.54+this.pan.y};}
 project(x,y,z=0){const t=this.transform();return {x:t.ox+(x-y)*128*t.s,y:t.oy+((x+y)*64-156.767*z-960)*t.s};}
 point(c){return {x:(c.x-c.y)*128,y:(c.x+c.y+1)*64};}
 screen(c){return this.project(c.x+.5,c.y+.5);}
 at(x,y){const t=this.transform(),a=(x-t.ox)/t.s,b=(y-t.oy)/t.s+960;return {x:Math.floor(a/256+b/128),y:Math.floor(b/128-a/256)};}
 exists(c){return this.cells.has(this.key(c))||this.placements.some(p=>p.tool==='dig'&&this.key(p.cell)===this.key(c));}
 resize(){const r=this.view.getBoundingClientRect(),dpr=Math.min(2,devicePixelRatio||1);this.canvas.width=Math.max(1,Math.round(r.width*dpr));this.canvas.height=Math.max(1,Math.round(r.height*dpr));this.ctx.setTransform(dpr,0,0,dpr,0,0);this.draw();}
 path(points){const ctx=this.ctx;ctx.beginPath();points.forEach((p,i)=>{const q=Array.isArray(p)?this.project(...p):p;i?ctx.lineTo(q.x,q.y):ctx.moveTo(q.x,q.y);});ctx.closePath();}
 polygon(points,fill,stroke){this.path(points);this.ctx.fillStyle=fill;this.ctx.fill();if(stroke){this.ctx.strokeStyle=stroke;this.ctx.lineWidth=.75;this.ctx.stroke();}}
 rectangle(x0,y0,x1,y1,z){const p=[[x0,y0,z],[x1,y0,z],[x1,y1,z],[x0,y1,z]].map(v=>this.project(...v));p.forEach((q,i)=>i?this.ctx.lineTo(q.x,q.y):this.ctx.moveTo(q.x,q.y));this.ctx.closePath();}
 allCells(){return [...this.cells.values(),...this.placements.filter(p=>p.tool==='dig').map(p=>p.cell)];}
 visibleBounds(){const r=this.view.getBoundingClientRect(),corners=[[0,0],[r.width,0],[r.width,r.height],[0,r.height]].map(([x,y])=>this.at(x,y));return {x0:Math.min(...corners.map(c=>c.x))-3,y0:Math.min(...corners.map(c=>c.y))-3,x1:Math.max(...corners.map(c=>c.x))+4,y1:Math.max(...corners.map(c=>c.y))+4};}
 terrain(){this.rockMass(false);this.rockFaces();}
 strataPatches(){const b=this.visibleBounds(),out=[],step=3.6;for(let mx=Math.floor(b.x0/step)-1;mx<=Math.ceil(b.x1/step)+1;mx++)for(let my=Math.floor(b.y0/step)-1;my<=Math.ceil(b.y1/step)+1;my++){if(this.hash(mx+103,my-41)<.33)continue;const width=3.1+this.hash(mx-13,my+5)*1.2;out.push({key:`${mx},${my}`,x:mx*step+this.hash(mx+6,my+9)*1.7,y:my*step+this.hash(mx-7,my+18)*1.7,width,height:width*this.images.strata.height/this.images.strata.width,alpha:.45+this.hash(mx,my+43)*.25});}return out;}
 geology(ctx,b){ctx.fillStyle=this.quietPattern;ctx.fillRect(b.x0,b.y0,b.x1-b.x0,b.y1-b.y0);for(const p of this.strataPatches()){ctx.save();ctx.globalAlpha=p.alpha;ctx.drawImage(this.images.strata,p.x-p.width/2,p.y-p.height/2,p.width,p.height);ctx.restore();}
  // Broad ambient pockets are world-space lighting, not enlarged rock texels.
  const step=5.7;for(let x=Math.floor(b.x0/step)-1;x<=Math.ceil(b.x1/step)+1;x++)for(let y=Math.floor(b.y0/step)-1;y<=Math.ceil(b.y1/step)+1;y++){const cx=x*step+this.hash(x+25,y-7)*2,cy=y*step+this.hash(x-18,y+11)*2,r=2.3+this.hash(x,y)*1.1,g=ctx.createRadialGradient(cx,cy,.2,cx,cy,r);g.addColorStop(0,'#030713a0');g.addColorStop(.45,'#03071355');g.addColorStop(1,'#03071300');ctx.fillStyle=g;ctx.fillRect(cx-r,cy-r,r*2,r*2);}
 }
 reliefs(){const b=this.visibleBounds(),t=this.transform(),out=[],step=3.2,cells=this.allCells();for(let mx=Math.floor(b.x0/step)-1;mx<=Math.ceil(b.x1/step)+1;mx++)for(let my=Math.floor(b.y0/step)-1;my<=Math.ceil(b.y1/step)+1;my++){if(this.hash(mx-23,my+31)<.25)continue;const x=mx*step+this.hash(mx+8,my+17)*1.6,y=my*step+this.hash(mx-27,my+8)*1.6,kind=this.hash(mx+8,my-4),name=kind>.30&&kind<.75?'outcrop':'rubble',width=250+this.hash(mx-54,my+82)*75,im=this.images[name],p=this.project(x,y,.67),w=width*t.s,h=w*im.height/im.width,rect={x:p.x-w/2,y:p.y-h*.84,w,h};
   // Screen-space rejection is translation/scale invariant; foreground relief must not hide a playable cell.
   if(cells.some(c=>{const q=this.project(c.x,c.y),a={x:q.x-128*t.s-6,y:q.y-48*t.s-6,w:256*t.s+12,h:176*t.s+12};return rect.x<a.x+a.w&&rect.x+w>a.x&&rect.y<a.y+a.h&&rect.y+h>a.y;}))continue;
   out.push({key:`${mx},${my}`,x,y,name,rect,draw:()=>{this.ctx.drawImage(im,rect.x,rect.y,w,h);}});
  }return out.sort((a,b)=>a.x+a.y-b.x-b.y);}
 rockTop(e){return e.n[0]+e.n[1]<0?.64+this.hash(e.a[0]+e.b[0],e.a[1]+e.b[1])*.06:.285;}
 rockFaces(){const ctx=this.ctx,t=this.transform();for(const e of this.boundaries().filter(e=>e.n[0]+e.n[1]<0)){const h=this.rockTop(e),p=this.project(...e.a),dx=e.b[0]-e.a[0],dy=e.b[1]-e.a[1];ctx.save();this.path([[...e.a,0],[...e.b,0],[...e.b,h],[...e.a,h]]);ctx.clip();ctx.transform((dx-dy)*128*t.s,(dx+dy)*64*t.s,0,-156.767*t.s,p.x,p.y);ctx.fillStyle=this.massPattern;ctx.fillRect(0,0,1,h);ctx.fillStyle='#030814a0';ctx.fillRect(0,0,1,h);ctx.restore();}}
 rockMass(front){const r=this.view.getBoundingClientRect(),t=this.transform(),b=this.visibleBounds(),z=.285,dpr=this.canvas.width/r.width,layer=this.massLayer;if(layer.width!==this.canvas.width||layer.height!==this.canvas.height){layer.width=this.canvas.width;layer.height=this.canvas.height;}const ctx=layer.getContext('2d');ctx.setTransform(dpr,0,0,dpr,0,0);ctx.clearRect(0,0,r.width,r.height);ctx.save();ctx.transform(128*t.s,64*t.s,-128*t.s,64*t.s,t.ox,t.oy-(960+156.767*.67)*t.s);this.geology(ctx,b);ctx.restore();ctx.fillStyle='#050a1555';ctx.fillRect(0,0,r.width,r.height);
  // Soft light on the excavation lip is derived from each exposed grid edge.
  for(const e of this.boundaries()){const h=this.rockTop(e),a=this.project(...e.a,h),b=this.project(...e.b,h);ctx.save();ctx.strokeStyle='#52617d33';ctx.lineWidth=18*t.s;ctx.lineCap='round';ctx.shadowColor='#52617d';ctx.shadowBlur=18*t.s;ctx.beginPath();ctx.moveTo(a.x,a.y);ctx.lineTo(b.x,b.y);ctx.stroke();ctx.restore();}
  if(front){ctx.save();ctx.globalCompositeOperation='destination-out';ctx.fillStyle='#000';
   const erase=points=>{ctx.beginPath();points.map(p=>this.project(p[0],p[1],p[2]??z)).forEach((p,i)=>i?ctx.lineTo(p.x,p.y):ctx.moveTo(p.x,p.y));ctx.closePath();ctx.fill();};
   // Union subtraction, not even-odd clipping: shared edges and concave rooms remain open.
   for(const {x,y}of this.allCells())erase([[x,y],[x+1,y],[x+1,y+1],[x,y+1]]);
   for(const e of this.boundaries()){const fringe=[],h=this.rockTop(e);for(let i=0;i<=6;i++){const a=i/6,x=e.a[0]+(e.b[0]-e.a[0])*a,y=e.a[1]+(e.b[1]-e.a[1])*a,d=.16+this.hash(x*7,y*7)*.035;fringe.push([x+e.n[0]*d,y+e.n[1]*d,h]);}ctx.shadowColor='#000';ctx.shadowBlur=2*t.s;erase([e.a,e.b,...fringe.reverse()]);}
   // Clear the tiny corner spaces left between two exposed boundary strips.
   for(const {x,y}of this.allCells())for(const [dx,dy,cx,cy]of [[-1,-1,x,y],[1,-1,x+1,y],[1,1,x+1,y+1],[-1,1,x,y+1]])if(!this.exists({x:x+dx,y})&&!this.exists({x,y:y+dy}))erase([[cx,cy],[cx+dx*.19,cy],[cx+dx*.19,cy+dy*.19],[cx,cy+dy*.19]]);
   ctx.restore();
  }
  this.ctx.drawImage(layer,0,0,r.width,r.height);
 }
 boundaries(){const edges=[];for(const {x,y}of this.allCells())for(const [dx,dy,a,b]of [[0,-1,[x,y],[x+1,y]],[1,0,[x+1,y],[x+1,y+1]],[0,1,[x+1,y+1],[x,y+1]],[-1,0,[x,y+1],[x,y]]])if(!this.exists({x:x+dx,y:y+dy}))edges.push({a,b,n:[dx,dy]});return edges;}
 dustAt(x,y,width,alpha){const p=this.project(x,y),im=this.images.dust,w=width*this.transform().s,h=w*im.height/im.width;this.ctx.save();this.ctx.globalAlpha=alpha;this.ctx.drawImage(im,p.x-w/2,p.y-h/2,w,h);this.ctx.restore();}
 contact(front=false){if(front){this.rockMass(true);return;}const ctx=this.ctx,t=this.transform();for(const e of this.boundaries()){
   const mid=[(e.a[0]+e.b[0])/2,(e.a[1]+e.b[1])/2];
   if(!front){const a=this.project(...e.a),b=this.project(...e.b);ctx.save();ctx.lineCap='round';ctx.strokeStyle='#060c1924';ctx.lineWidth=13*t.s;ctx.shadowColor='#050a18';ctx.shadowBlur=8*t.s;ctx.beginPath();ctx.moveTo(a.x,a.y);ctx.lineTo(b.x,b.y);ctx.stroke();ctx.restore();this.dustAt(mid[0]+e.n[0]*.16,mid[1]+e.n[1]*.16,210,.58);}
   else { // Native dust fringe touches only the outside of the dynamically derived boundary.
    const d=.65,eps=-.045;ctx.save();this.path([[...e.a,0],[...e.b,0],[e.b[0]+e.n[0]*d,e.b[1]+e.n[1]*d,0],[e.a[0]+e.n[0]*d,e.a[1]+e.n[1]*d,0]]);ctx.clip();
    this.dustAt(mid[0]+e.n[0]*(.12+eps),mid[1]+e.n[1]*(.12+eps),185,.52);ctx.restore();
   }
  }}
 sprite(id,p,size,alpha=1){const e=this.data.regions[id];if(!e)return;const t=this.transform(),ctx=this.ctx,img=e.atlas_path?this.images.chests:this.images.architecture;ctx.globalAlpha=alpha;ctx.drawImage(img,...e.region,t.ox+p[0]*t.s,t.oy+(p[1]-960)*t.s,size[0]*t.s,size[1]*t.s);ctx.globalAlpha=1;}
 anchored(id,c,alpha=1){const e=this.data.regions[id],p=this.point(c);this.sprite(id,[p.x+e.offset[0],p.y+e.offset[1]],e.size,alpha);}
 diamond(c,fill,stroke){this.polygon([[c.x,c.y,0],[c.x+1,c.y,0],[c.x+1,c.y+1,0],[c.x,c.y+1,0]],fill,stroke);}
 placement(p,alpha=1){const ids={chest:'prop-chest-open',locked:'prop-chest',crystal:'prop-crystals',candles:'prop-candles',idol:'prop-idol',door:'door-north-leaf'};if(p.tool==='dig'){const e=this.data.regions['floor-b1'],a=this.point(p.cell);this.sprite('floor-b1',[a.x+e.offset[0],a.y-64+e.offset[1]],e.size,alpha);}else if(p.tool==='spike'){const t=this.transform(),a=this.screen(p.cell);this.ctx.globalAlpha=alpha;this.ctx.drawImage(this.images.spikes,a.x-58*t.s,a.y-91*t.s,116*t.s,116*t.s);this.ctx.globalAlpha=1;}else{this.anchored(ids[p.tool],p.cell,alpha);if(p.tool==='door')this.anchored('door-north-arch',p.cell,alpha);}}
 wallAnchor(s){const e=this.data.regions[s.id],a=[s.p[0]-e.offset[0],s.p[1]-e.offset[1]];return {x:Math.round(a[0]/256+a[1]/128),y:Math.round(a[1]/128-a[0]/256)};}
 wallRemoved(s){if(!s.id.startsWith('wall'))return false;const a=this.wallAnchor(s);return s.id.startsWith('wall-h')?this.exists(a)&&this.exists({x:a.x,y:a.y-1}):this.exists(a)&&this.exists({x:a.x-1,y:a.y});}
 additionalWalls(){const out=[],seen=new Set();for(const p of this.placements.filter(p=>p.tool==='dig')){const {x,y}=p.cell;for(const [dx,dy,ax,ay,id]of [[0,-1,x,y,'wall-h-0'],[0,1,x,y+1,'wall-h-0'],[-1,0,x,y,'wall-v-0'],[1,0,x+1,y,'wall-v-0']])if(!this.exists({x:x+dx,y:y+dy})){const k=`${id}:${ax},${ay}`;if(seen.has(k))continue;seen.add(k);const e=this.data.regions[id],a={x:(ax-ay)*128,y:(ax+ay)*64};out.push({id,p:[a.x+e.offset[0],a.y+e.offset[1]],size:e.size,z:1});}}return out;}
 draw(){if(!this.ready)return;const ctx=this.ctx,r=this.view.getBoundingClientRect();ctx.clearRect(0,0,r.width,r.height);ctx.fillStyle=this.integrated?'#253249':'#080e18';ctx.fillRect(0,0,r.width,r.height);if(this.integrated){this.terrain();this.contact();}
  for(const s of this.data.sprites.filter(s=>s.z===0))this.sprite(s.id,s.p,s.size);for(const p of this.placements.filter(p=>p.tool==='dig'))this.placement(p);
  if(this.hover&&this.selected&&this.active){const v=this.validate(this.hover);this.diamond(this.hover,v.valid?'#bd86f02c':'#e977713d',v.valid?'#d3a8ff':'#f5aaa4');}
  const solids=this.data.sprites.filter(s=>s.z!==0&&!this.wallRemoved(s)).concat(this.additionalWalls()).map(s=>({y:s.p[1]+s.size[1]-12,draw:()=>this.sprite(s.id,s.p,s.size)}));
  for(const p of this.placements.filter(p=>p.tool!=='dig'))solids.push({y:this.point(p.cell).y+10,draw:()=>this.placement(p)});solids.sort((a,b)=>a.y-b.y).forEach(s=>s.draw());
  if(this.integrated){this.contact(true);for(const p of this.reliefs())p.draw();}
  if(this.showGrid){for(const c of this.allCells())this.diamond(c,'#0000','#e5c48655');}
  if(this.hover&&this.selected&&this.active&&this.validate(this.hover).valid)this.placement({tool:this.selected,cell:this.hover},.65);
 }
};
