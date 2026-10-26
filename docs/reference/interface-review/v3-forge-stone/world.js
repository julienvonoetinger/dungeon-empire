/* Disposable review renderer. The production renderer and its assets are untouched. */
window.ForgeWorld=class{
 constructor(view,canvas,data){this.view=view;this.canvas=canvas;this.ctx=canvas.getContext('2d');this.data=data;this.pan={x:0,y:0};this.integrated=true;this.placements=[];this.hover=null;this.selected=null;this.active=true;this.ready=false;this.images={};this.cells=new Map();
  for(const s of data.sprites.filter(s=>s.id.startsWith('floor'))){const e=data.regions[s.id],a=[s.p[0]-e.offset[0],s.p[1]-e.offset[1]],c={x:Math.round(a[0]/256+a[1]/128),y:Math.round(a[1]/128-a[0]/256)};this.cells.set(this.key(c),c);}
  this.loading=Promise.all(['architecture','chests','spikes','bedrock'].map(name=>new Promise((resolve,reject)=>{const img=new Image();this.images[name]=img;img.onload=resolve;img.onerror=reject;img.src=window.REVIEW_ASSETS?.[name]||`assets/${name}.png`;}))).then(()=>{this.rockPattern=this.ctx.createPattern(this.images.bedrock,'repeat');this.ready=true;this.resize();});
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
 rock(front=false){const ctx=this.ctx,r=this.view.getBoundingClientRect();ctx.save();if(front){ctx.beginPath();this.rectangle(10.10,-3,19,19,.2);this.rectangle(-3,10.10,10.10,19,.2);ctx.clip();
   // Leave excavated additions open, including their newly drawn border walls.
   ctx.beginPath();ctx.rect(-1,-1,r.width+2,r.height+2);for(const p of this.placements.filter(p=>p.tool==='dig'))this.rectangle(p.cell.x-.10,p.cell.y-.10,p.cell.x+1.10,p.cell.y+1.10,.2);ctx.clip('evenodd');
  }
  const t=this.transform();ctx.save();ctx.transform(2*t.s,t.s,-2*t.s,t.s,t.ox,t.oy-(960+156.767*.2)*t.s);ctx.fillStyle=this.rockPattern;ctx.fillRect(-2048,-2048,4096,4096);ctx.restore();ctx.fillStyle='#0b14251c';ctx.fillRect(0,0,r.width,r.height);
  // Painted relief carries the exterior; only small wall-foot chips add geometry.
  ctx.restore();
 }
 boulder(x,y,r){const pts=[[x-r,y-.4*r,.19],[x-.8*r,y+.5*r,.19],[x,y+r,.2],[x+.8*r,y+.55*r,.2],[x+r,y-.35*r,.2],[x+.1*r,y-.8*r,.20]],cap=[x-.1*r,y-.1*r,.25+r*.32];for(let i=0;i<pts.length;i++)this.polygon([pts[i],pts[(i+1)%pts.length],cap],['#27354c','#223047','#24334b','#2a3b56','#33455e','#304158'][i]);this.polygon([[x-r*.65,y-.38*r,.22+r*.11],[x+.1*r,y-.8*r,.20],cap],'#354761');}
 collar(){if(!this.integrated)return;for(let edge=0;edge<2;edge++)for(let i=0;i<23;i++){const t=5.05+i*.22,r=.045+this.hash(i,edge+2)*.048,off=10.10+this.hash(i+10,edge)*.05;const x=edge?t:off,y=edge?off:t;if(this.placements.some(p=>p.tool==='dig'&&Math.abs(p.cell.x+.5-x)<.65&&Math.abs(p.cell.y+.5-y)<.65))continue;this.boulder(x,y,r);}}
 sprite(id,p,size,alpha=1){const e=this.data.regions[id];if(!e)return;const t=this.transform(),ctx=this.ctx,img=e.atlas_path?this.images.chests:this.images.architecture;ctx.globalAlpha=alpha;ctx.drawImage(img,...e.region,t.ox+p[0]*t.s,t.oy+(p[1]-960)*t.s,size[0]*t.s,size[1]*t.s);ctx.globalAlpha=1;}
 anchored(id,c,alpha=1){const e=this.data.regions[id],p=this.point(c);this.sprite(id,[p.x+e.offset[0],p.y+e.offset[1]],e.size,alpha);}
 diamond(c,fill,stroke){this.polygon([[c.x,c.y,0],[c.x+1,c.y,0],[c.x+1,c.y+1,0],[c.x,c.y+1,0]],fill,stroke);}
 placement(p,alpha=1){const ids={chest:'prop-chest-open',locked:'prop-chest',crystal:'prop-crystals',candles:'prop-candles',idol:'prop-idol',door:'door-north-leaf'};if(p.tool==='dig'){const e=this.data.regions['floor-b1'],a=this.point(p.cell);this.sprite('floor-b1',[a.x+e.offset[0],a.y-64+e.offset[1]],e.size,alpha);}else if(p.tool==='spike'){const t=this.transform(),a=this.screen(p.cell);this.ctx.globalAlpha=alpha;this.ctx.drawImage(this.images.spikes,a.x-58*t.s,a.y-91*t.s,116*t.s,116*t.s);this.ctx.globalAlpha=1;}else{this.anchored(ids[p.tool],p.cell,alpha);if(p.tool==='door')this.anchored('door-north-arch',p.cell,alpha);}}
 wallAnchor(s){const e=this.data.regions[s.id],a=[s.p[0]-e.offset[0],s.p[1]-e.offset[1]];return {x:Math.round(a[0]/256+a[1]/128),y:Math.round(a[1]/128-a[0]/256)};}
 wallRemoved(s){if(!s.id.startsWith('wall'))return false;const a=this.wallAnchor(s);return s.id.startsWith('wall-h')?this.exists(a)&&this.exists({x:a.x,y:a.y-1}):this.exists(a)&&this.exists({x:a.x-1,y:a.y});}
 additionalWalls(){const out=[],seen=new Set();for(const p of this.placements.filter(p=>p.tool==='dig')){const {x,y}=p.cell;for(const [dx,dy,ax,ay,id]of [[0,-1,x,y,'wall-h-0'],[0,1,x,y+1,'wall-h-0'],[-1,0,x,y,'wall-v-0'],[1,0,x+1,y,'wall-v-0']])if(!this.exists({x:x+dx,y:y+dy})){const k=`${id}:${ax},${ay}`;if(seen.has(k))continue;seen.add(k);const e=this.data.regions[id],a={x:(ax-ay)*128,y:(ax+ay)*64};out.push({id,p:[a.x+e.offset[0],a.y+e.offset[1]],size:e.size,z:1});}}return out;}
 draw(){if(!this.ready)return;const ctx=this.ctx,r=this.view.getBoundingClientRect();ctx.clearRect(0,0,r.width,r.height);ctx.fillStyle=this.integrated?'#253249':'#080e18';ctx.fillRect(0,0,r.width,r.height);if(this.integrated)this.rock();
  for(const s of this.data.sprites.filter(s=>s.z===0))this.sprite(s.id,s.p,s.size);for(const p of this.placements.filter(p=>p.tool==='dig'))this.placement(p);
  if(this.hover&&this.selected&&this.active){const v=this.validate(this.hover);this.diamond(this.hover,v.valid?'#bd86f02c':'#e977713d',v.valid?'#d3a8ff':'#f5aaa4');}
  const solids=this.data.sprites.filter(s=>s.z!==0&&!this.wallRemoved(s)).concat(this.additionalWalls()).map(s=>({y:s.p[1]+s.size[1]-12,draw:()=>this.sprite(s.id,s.p,s.size)}));
  for(const p of this.placements.filter(p=>p.tool!=='dig'))solids.push({y:this.point(p.cell).y+10,draw:()=>this.placement(p)});solids.sort((a,b)=>a.y-b.y).forEach(s=>s.draw());
  if(this.integrated){this.rock(true);this.collar();}
  if(this.hover&&this.selected&&this.active&&this.validate(this.hover).valid)this.placement({tool:this.selected,cell:this.hover},.65);
 }
};
