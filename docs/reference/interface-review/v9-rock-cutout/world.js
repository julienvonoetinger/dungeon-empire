/* Disposable review renderer. The production renderer and its assets are untouched. */
window.ForgeWorld=class{
 constructor(view,canvas,data){this.view=view;this.canvas=canvas;this.ctx=canvas.getContext('2d');this.data=data;this.pan={x:0,y:0};this.integrated=true;this.placements=[];this.hover=null;this.selected=null;this.active=true;this.ready=false;this.images={};this.cells=new Map();
  // The exterior material and all its mineral inclusions share the actual masonry cap plane.
  this.rockHeight=data.regions['wall-h-0'].bounds.max[2];
  this.cutoutMargin=.90;
  for(const s of data.sprites.filter(s=>s.id.startsWith('floor'))){const e=data.regions[s.id],a=[s.p[0]-e.offset[0],s.p[1]-e.offset[1]],c={x:Math.round(a[0]/256+a[1]/128),y:Math.round(a[1]/128-a[0]/256)};this.cells.set(this.key(c),c);}
  this.loading=Promise.all(['architecture','chests','spikes','dust','quiet','strata','mineral'].map(name=>new Promise((resolve,reject)=>{const img=new Image();this.images[name]=img;img.onload=resolve;img.onerror=reject;img.src=window.REVIEW_ASSETS?.[name]||`assets/${name}.png`;}))).then(()=>{this.quietPattern=this.ctx.createPattern(this.images.quiet,'repeat');this.quietPattern.setTransform(new DOMMatrix().scale(3/this.images.quiet.width));this.massLayer=document.createElement('canvas');this.ready=true;this.resize();});
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
 terrain(){
  const ctx=this.ctx,t=this.transform(),b=this.visibleBounds();
  ctx.save();ctx.transform(128*t.s,64*t.s,-128*t.s,64*t.s,t.ox,t.oy-960*t.s);
  ctx.fillStyle=this.quietPattern;ctx.fillRect(b.x0,b.y0,b.x1-b.x0,b.y1-b.y0);
  ctx.fillStyle='#1019269c';ctx.fillRect(b.x0,b.y0,b.x1-b.x0,b.y1-b.y0);ctx.restore();
  this.rockMass();
 }
 strataPatches(){const b=this.visibleBounds(),out=[],step=3.6;for(let mx=Math.floor(b.x0/step)-1;mx<=Math.ceil(b.x1/step)+1;mx++)for(let my=Math.floor(b.y0/step)-1;my<=Math.ceil(b.y1/step)+1;my++){if(this.hash(mx+103,my-41)<.33)continue;const width=3.1+this.hash(mx-13,my+5)*1.2;out.push({key:`${mx},${my}`,x:mx*step+this.hash(mx+6,my+9)*1.7,y:my*step+this.hash(mx-7,my+18)*1.7,width,height:width*this.images.strata.height/this.images.strata.width,alpha:.45+this.hash(mx,my+43)*.25});}return out;}
 mineralPatches(){const b=this.visibleBounds(),out=[],step=4.4;for(let mx=Math.floor(b.x0/step)-1;mx<=Math.ceil(b.x1/step)+1;mx++)for(let my=Math.floor(b.y0/step)-1;my<=Math.ceil(b.y1/step)+1;my++){if(this.hash(mx-34,my+62)<.40)continue;const width=1.25+this.hash(mx-11,my+72)*.65;out.push({key:`${mx},${my}`,x:mx*step+this.hash(mx+23,my-17)*1.8,y:my*step+this.hash(mx+8,my+32)*1.8,width,height:width*this.images.mineral.height/this.images.mineral.width});}return out;}
 geology(ctx,b){ctx.fillStyle=this.quietPattern;ctx.fillRect(b.x0,b.y0,b.x1-b.x0,b.y1-b.y0);for(const p of this.strataPatches()){ctx.save();ctx.globalAlpha=p.alpha;ctx.drawImage(this.images.strata,p.x-p.width/2,p.y-p.height/2,p.width,p.height);ctx.restore();}for(const p of this.mineralPatches()){ctx.save();ctx.globalAlpha=.72;ctx.drawImage(this.images.mineral,p.x-p.width/2,p.y-p.height/2,p.width,p.height);ctx.restore();}
  // Broad ambient pockets are world-space lighting, not enlarged rock texels.
  const step=5.7;for(let x=Math.floor(b.x0/step)-1;x<=Math.ceil(b.x1/step)+1;x++)for(let y=Math.floor(b.y0/step)-1;y<=Math.ceil(b.y1/step)+1;y++){const cx=x*step+this.hash(x+25,y-7)*2,cy=y*step+this.hash(x-18,y+11)*2,r=2.3+this.hash(x,y)*1.1,g=ctx.createRadialGradient(cx,cy,.2,cx,cy,r);g.addColorStop(0,'#030713a0');g.addColorStop(.45,'#03071355');g.addColorStop(1,'#03071300');ctx.fillStyle=g;ctx.fillRect(cx-r,cy-r,r*2,r*2);}
 }
 cutGeometry(){
  const cells=this.allCells(),key=cells.map(c=>this.key(c)).sort().join('|')+':'+this.cutoutMargin;
  if(this.cutCache?.key===key)return this.cutCache.contours;
  const d=this.cutoutMargin,rects=cells.map(({x,y})=>[x-d,y-d,x+1+d,y+1+d]);
  const unique=values=>[...new Set(values.map(v=>+v.toFixed(5)))].sort((a,b)=>a-b);
  const xs=unique(rects.flatMap(r=>[r[0],r[2]])),ys=unique(rects.flatMap(r=>[r[1],r[3]])),inside=new Set();
  for(let i=0;i<xs.length-1;i++)for(let j=0;j<ys.length-1;j++){
   const x=(xs[i]+xs[i+1])/2,y=(ys[j]+ys[j+1])/2;
   if(rects.some(r=>x>r[0]&&x<r[2]&&y>r[1]&&y<r[3]))inside.add(`${i},${j}`);
  }
  const links=new Map(),pointKey=p=>p.map(v=>v.toFixed(5)).join(',');
  for(const cell of inside){const [i,j]=cell.split(',').map(Number);
   for(const [di,dj,a,b]of [[0,-1,[xs[i],ys[j]],[xs[i+1],ys[j]]],[1,0,[xs[i+1],ys[j]],[xs[i+1],ys[j+1]]],[0,1,[xs[i+1],ys[j+1]],[xs[i],ys[j+1]]],[-1,0,[xs[i],ys[j+1]],[xs[i],ys[j]]]])
    if(!inside.has(`${i+di},${j+dj}`))links.set(pointKey(a),{a,b});
  }
  const contours=[];
  while(links.size){const start=links.values().next().value.a,raw=[];let p=start;
   do{const edge=links.get(pointKey(p));if(!edge)throw new Error('Open rock cut contour');links.delete(pointKey(p));raw.push(edge.a);p=edge.b;}while(pointKey(p)!==pointKey(start));
   const simple=raw.filter((p,i)=>{const a=raw[(i+raw.length-1)%raw.length],b=raw[(i+1)%raw.length];return Math.abs((p[0]-a[0])*(b[1]-p[1])-(p[1]-a[1])*(b[0]-p[0]))>1e-8;});
   // Small bevelled corners and shallow chips belong to the cut silhouette.
   const bevel=[];
   for(let i=0;i<simple.length;i++){const a=simple[(i+simple.length-1)%simple.length],p=simple[i],b=simple[(i+1)%simple.length],la=Math.hypot(p[0]-a[0],p[1]-a[1]),lb=Math.hypot(b[0]-p[0],b[1]-p[1]),r=Math.min(.12,la*.20,lb*.20);
    bevel.push([p[0]+(a[0]-p[0])*r/la,p[1]+(a[1]-p[1])*r/la],[p[0]+(b[0]-p[0])*r/lb,p[1]+(b[1]-p[1])*r/lb]);}
   const contour=[];
   for(let i=0;i<bevel.length;i++){const a=bevel[i],b=bevel[(i+1)%bevel.length],dx=b[0]-a[0],dy=b[1]-a[1],length=Math.hypot(dx,dy),steps=Math.max(1,Math.ceil(length/.48));contour.push(a);
    for(let k=1;k<steps;k++){const f=k/steps,x=a[0]+dx*f,y=a[1]+dy*f,n=(this.hash(x*31,y*31)-.5)*.045;contour.push([x+dy/length*n,y-dx/length*n]);}}
   contours.push(contour);
  }
  this.cutCache={key,contours};return contours;
 }
 rockMass(){
  const r=this.view.getBoundingClientRect(),t=this.transform(),b=this.visibleBounds(),z=this.rockHeight,dpr=this.canvas.width/r.width,layer=this.massLayer,contours=this.cutGeometry();
  if(layer.width!==this.canvas.width||layer.height!==this.canvas.height){layer.width=this.canvas.width;layer.height=this.canvas.height;}
  const ctx=layer.getContext('2d');ctx.setTransform(dpr,0,0,dpr,0,0);ctx.clearRect(0,0,r.width,r.height);
  ctx.save();ctx.transform(128*t.s,64*t.s,-128*t.s,64*t.s,t.ox,t.oy-(960+156.767*z)*t.s);this.geology(ctx,b);ctx.restore();ctx.fillStyle='#050a1555';ctx.fillRect(0,0,r.width,r.height);
  // Actually remove the exterior texture, including its alpha, inside the cut.
  ctx.save();ctx.globalCompositeOperation='destination-out';ctx.fillStyle='#000';ctx.beginPath();
  for(const contour of contours){contour.forEach(([x,y],i)=>{const p=this.project(x,y,z);i?ctx.lineTo(p.x,p.y):ctx.moveTo(p.x,p.y);});ctx.closePath();}
  ctx.fill();ctx.restore();this.ctx.drawImage(layer,0,0,r.width,r.height);
  // The exposed inner faces run from the floor to the same height as masonry.
  for(const contour of contours)for(let i=0;i<contour.length;i++){
   const a=contour[i],b=contour[(i+1)%contour.length],dx=b[0]-a[0],dy=b[1]-a[1],visible=dx-dy>1e-7;
   if(visible){const screenA=this.project(...a,0),screenB=this.project(...b,0),axis=Math.abs(dx)>Math.abs(dy)?0:1,u=a[axis],du=b[axis]-u,c=this.ctx,ux=(screenB.x-screenA.x)/du,uy=(screenB.y-screenA.y)/du;
    c.save();this.path([[...a,0],[...b,0],[...b,z],[...a,z]]);c.clip();
    c.transform(ux,uy,0,-156.767*t.s,screenA.x-u*ux,screenA.y-u*uy);
    c.fillStyle=this.quietPattern;c.fillRect(Math.min(u,b[axis]),0,Math.abs(du),z);c.fillStyle=axis===0?'#0b122378':'#07101c98';c.fillRect(Math.min(u,b[axis]),0,Math.abs(du),z);c.restore();
   }
   const p=this.project(...a,z),q=this.project(...b,z);this.ctx.beginPath();this.ctx.moveTo(p.x,p.y);this.ctx.lineTo(q.x,q.y);this.ctx.lineWidth=.8;this.ctx.strokeStyle=visible?'#56647b66':'#070d1977';this.ctx.stroke();
  }
 }
 boundaries(){const edges=[];for(const {x,y}of this.allCells())for(const [dx,dy,a,b]of [[0,-1,[x,y],[x+1,y]],[1,0,[x+1,y],[x+1,y+1]],[0,1,[x+1,y+1],[x,y+1]],[-1,0,[x,y+1],[x,y]]])if(!this.exists({x:x+dx,y:y+dy}))edges.push({a,b,n:[dx,dy]});return edges;}
 dustAt(x,y,width,alpha){const p=this.project(x,y),im=this.images.dust,w=width*this.transform().s,h=w*im.height/im.width;this.ctx.save();this.ctx.globalAlpha=alpha;this.ctx.drawImage(im,p.x-w/2,p.y-h/2,w,h);this.ctx.restore();}
 contact(front=false){if(front){this.rockMass();return;}const ctx=this.ctx,t=this.transform();for(const e of this.boundaries()){
   const mid=[(e.a[0]+e.b[0])/2,(e.a[1]+e.b[1])/2];
   const a=this.project(...e.a),b=this.project(...e.b);ctx.save();ctx.lineCap='round';ctx.strokeStyle='#060c1924';ctx.lineWidth=13*t.s;ctx.shadowColor='#050a18';ctx.shadowBlur=8*t.s;ctx.beginPath();ctx.moveTo(a.x,a.y);ctx.lineTo(b.x,b.y);ctx.stroke();ctx.restore();this.dustAt(mid[0]+e.n[0]*.16,mid[1]+e.n[1]*.16,210,.58);
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
  if(this.integrated)this.contact(true);
  if(this.showGrid){for(const c of this.allCells())this.diamond(c,'#0000','#e5c48655');}
  if(this.hover&&this.selected&&this.active&&this.validate(this.hover).valid)this.placement({tool:this.selected,cell:this.hover},.65);
 }
};
