(() => {
 'use strict';
 const $=id=>document.getElementById(id), game=$('game'), canvas=$('world'), ctx=canvas.getContext('2d'), data=window.REVIEW_DATA;
 const params=new URLSearchParams(location.search), capture=params.has('capture');
 if(capture)document.documentElement.classList.add('capture');
 const art=new Image(), chests=new Image();art.src='assets/architecture.png';chests.src='assets/chests.png';
 const tools={
  dig:{name:'Creuser',icon:'pick',cost:5,family:'terrain'},spike:{name:'Pointes',icon:'spike',cost:35,family:'defenses'},
  door:{name:'Porte',icon:'door',cost:40,family:'defenses',sprite:'door-north-leaf'},chest:{name:'Coffre',icon:'chest',cost:0,family:'treasure',sprite:'prop-chest-open'},
  locked:{name:'Verrouillé',icon:'chest',cost:40,family:'treasure',sprite:'prop-chest'},
  crystal:{name:'Cristaux',icon:'crystal',cost:0,proposal:true,family:'decor',sprite:'prop-crystals'},
  candles:{name:'Bougies',icon:'crystal',cost:0,proposal:true,family:'decor',sprite:'prop-candles'},
  idol:{name:'Idole',icon:'sigil',cost:0,proposal:true,family:'decor',sprite:'prop-idol'}
 };
 const groups={quick:['dig','spike','door','chest'],terrain:['dig'],defenses:['spike','door'],treasure:['chest','locked'],decor:['crystal','candles','idol']};
 const themes={obsidian:{label:'A / OBSIDIENNE',kicker:'A / RECOMMANDATION',title:'La main sur le donjon.',copy:'Une palette basse, stable, avec vos outils usuels. Le violet signale une action ; le métal reste sombre.',tradeoff:'À surveiller : rendre le changement de famille suffisamment visible.'},forge:{label:'B / LA FORGE',kicker:'B / COMMANDES AU POUCE',title:'Tout à portée de main.',copy:'Une colonne d’outils près du pouce droit. Fer vieilli et accents de braise donnent une présence plus brutale au maître du donjon.',tradeoff:'Compromis : moins de largeur pour le terrain. Un mode gaucher serait à prévoir.'},grimoire:{label:'C / LE GRIMOIRE',kicker:'C / CLARTÉ DU CATALOGUE',title:'Chaque pouvoir à sa place.',copy:'Les familles restent visibles. La pierre, l’argent terni et les sceaux créent une ambiance de rituel, sans surcharge de dorures.',tradeoff:'Compromis : un bandeau plus haut, mais des outils plus faciles à découvrir.'}};
 let selected=null,family='quick',mode='build',theme='obsidian',gold=320,history=[],placements=[],pan={x:0,y:0},pointer=null,hover=null,grid=false,toastTimer,ready=false,modal=false;
 const originalCells=new Map();
 for(const s of data.sprites.filter(s=>s.id.startsWith('floor'))){const e=data.regions[s.id],ax=s.p[0]-e.offset[0],ay=s.p[1]-e.offset[1];const x=Math.round(ax/256+ay/128),y=Math.round(ay/128-ax/256);originalCells.set(`${x},${y}`,{x,y});}
 const occupied=new Set(['5,5','5,9','9,5','9,9','7,7']);
 const icon=name=>`<svg aria-hidden="true"><use href="#icon-${name}"/></svg>`;
 const costLabel=t=>t.proposal?'Étude':t.cost?`${t.cost} or`:'Gratuit';
 const point=c=>({x:(c.x-c.y)*128,y:(c.x+c.y+1)*64});
 function transform(){const r=game.getBoundingClientRect();return {scale:.49,ox:r.width*(theme==='forge'?.45:.5)+pan.x,oy:r.height*(theme==='grimoire'?.49:.53)+pan.y};}
 function screen(c){const p=point(c),t=transform();return {x:t.ox+p.x*t.scale,y:t.oy+(p.y-960)*t.scale};}
 function cellAt(x,y){const t=transform(),wx=(x-t.ox)/t.scale,wy=(y-t.oy)/t.scale+960;return {x:Math.floor(wx/256+wy/128),y:Math.floor(wy/128-wx/256)};}
 const key=c=>`${c.x},${c.y}`;
 function exists(c){return originalCells.has(key(c))||placements.some(p=>p.tool==='dig'&&key(p.cell)===key(c));}
 function available(c,tool=selected){
  if(!tool)return {valid:false,reason:'Choisissez un outil.'};
  const t=tools[tool];if(c.x<3||c.x>11||c.y<3||c.y>11)return {valid:false,reason:'Hors de cette zone d’essai.'};
  if(t.cost>gold)return {valid:false,reason:`Il manque ${t.cost-gold} or.`};
  if(tool==='dig'){
   if(exists(c))return {valid:false,reason:'Cette case est déjà creusée.'};
   if(![[1,0],[-1,0],[0,1],[0,-1]].some(([x,y])=>exists({x:c.x+x,y:c.y+y})))return {valid:false,reason:'Commencez au bord d’une salle.'};
  }else{
   if(!exists(c))return {valid:false,reason:'Creusez cette case avant de bâtir.'};
   if(occupied.has(key(c))||placements.some(p=>p.tool!=='dig'&&key(p.cell)===key(c)))return {valid:false,reason:'Cette case est occupée.'};
  }
  return {valid:true,reason:`${t.name} · ${costLabel(t)}`};
 }
 function resize(){const r=game.getBoundingClientRect(),dpr=Math.min(2,devicePixelRatio||1);canvas.width=Math.round(r.width*dpr);canvas.height=Math.round(r.height*dpr);$('size-label').textContent=`${Math.round(r.width)} × ${Math.round(r.height)}`;ctx.setTransform(dpr,0,0,dpr,0,0);draw();}
 function sprite(id,p,size,alpha=1){const e=data.regions[id];if(!e)return;const t=transform(),a=e.atlas_path?chests:art;ctx.globalAlpha=alpha;ctx.drawImage(a,...e.region,t.ox+p[0]*t.scale,t.oy+(p[1]-960)*t.scale,size[0]*t.scale,size[1]*t.scale);ctx.globalAlpha=1;}
 function atCell(id,c,alpha=1){const e=data.regions[id],p=point(c);sprite(id,[p.x+e.offset[0],p.y+e.offset[1]],e.size,alpha);}
 function diamond(c,fill,stroke){const p=screen(c),s=transform().scale,w=128*s,h=64*s;ctx.beginPath();ctx.moveTo(p.x,p.y-h);ctx.lineTo(p.x+w,p.y);ctx.lineTo(p.x,p.y+h);ctx.lineTo(p.x-w,p.y);ctx.closePath();ctx.fillStyle=fill;ctx.fill();if(stroke){ctx.strokeStyle=stroke;ctx.lineWidth=1;ctx.stroke();}}
 function trap(c,alpha=1){const p=screen(c),s=transform().scale;ctx.save();ctx.translate(p.x,p.y);ctx.scale(s,s);ctx.globalAlpha=alpha;ctx.fillStyle='#26303f';ctx.strokeStyle='#8590a6';ctx.lineWidth=3;ctx.beginPath();ctx.moveTo(-46,0);ctx.lineTo(0,-23);ctx.lineTo(46,0);ctx.lineTo(0,23);ctx.closePath();ctx.fill();ctx.stroke();for(const [x,y]of [[-20,0],[0,-10],[20,0],[0,10]]){ctx.beginPath();ctx.moveTo(x-6,y+4);ctx.lineTo(x,y-25);ctx.lineTo(x+7,y+5);ctx.closePath();ctx.fillStyle='#c7c9d2';ctx.fill();ctx.strokeStyle='#353d50';ctx.lineWidth=2;ctx.stroke();}ctx.restore();}
 function drawPlacement(p,alpha=1){if(p.tool==='dig'){const e=data.regions['floor-b1'],c=point(p.cell);sprite('floor-b1',[c.x+e.offset[0],c.y-64+e.offset[1]],e.size,alpha);}else if(p.tool==='spike')trap(p.cell,alpha);else{atCell(tools[p.tool].sprite,p.cell,alpha);if(p.tool==='door')atCell('door-north-arch',p.cell,alpha);}}
 function draw(){if(!ready)return;const r=game.getBoundingClientRect();ctx.clearRect(0,0,r.width,r.height);
  for(const s of data.sprites.filter(s=>s.z===0))sprite(s.id,s.p,s.size);
  for(const p of placements.filter(p=>p.tool==='dig'))drawPlacement(p);
  if(grid||selected){for(const c of originalCells.values())diamond(c,'transparent',grid?'#bba2db38':'#baa5d50d');}
  if(hover&&selected&&mode==='build'&&!modal){const v=available(hover);diamond(hover,v.valid?'#bea2ef32':'#ed6c6c35',v.valid?'#d4baff':'#ff9a9a');}
  const solids=data.sprites.filter(s=>s.z!==0).map(s=>({y:s.p[1]+s.size[1]-12,draw:()=>sprite(s.id,s.p,s.size)}));
  placements.filter(p=>p.tool!=='dig').forEach(p=>solids.push({y:point(p.cell).y+10,draw:()=>drawPlacement(p)}));
  solids.sort((a,b)=>a.y-b.y).forEach(s=>s.draw());
  if(hover&&selected&&mode==='build'&&!modal&&available(hover).valid)drawPlacement({cell:hover,tool:selected},.62);
 }
 function toast(message){$('toast').textContent=message;$('toast').hidden=false;clearTimeout(toastTimer);toastTimer=setTimeout(()=>$('toast').hidden=true,2200);}
 function update(){
  $('gold').textContent=gold;$('undo').disabled=history.length===0;$('undo').setAttribute('aria-label',history.length?`Annuler ${tools[history[history.length-1].tool].name}`:'Aucune action à annuler');
  $('selection-badge').hidden=!selected||mode!=='build';if(selected){$('selection-label').textContent=`${tools[selected].name} · ${costLabel(tools[selected])}`;$('selection-badge').querySelector('use').setAttribute('href','#icon-'+tools[selected].icon);}
  $('hint').textContent=selected?(selected==='dig'?'Touchez la roche près des murs pour creuser.':'Touchez pour poser · glissez pour déplacer la vue.'):'Choisissez un outil, puis touchez les cases.';
  document.querySelectorAll('[data-tool]').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.tool===selected)));draw();
 }
 function selectTool(id){if(modal)return;selected=id;hover=null;game.classList.remove('catalog-open');update();}
 function listTools(){
  const ids=groups[family];$('tool-list').innerHTML=ids.map(id=>{const t=tools[id];return `<button class="tool" data-tool="${id}" aria-pressed="${id===selected}" aria-label="${t.name}, ${costLabel(t)}">${icon(t.icon)}<span class="tool-copy"><b>${t.name}</b><small>${costLabel(t)}</small></span></button>`;}).join('')+`<button class="tool more" id="more-tools" aria-label="Afficher les familles d’outils" aria-expanded="${game.classList.contains('catalog-open')}">${icon('more')}<span class="tool-copy"><b>Catalogue</b></span></button>`;
  $('more-tools').onclick=()=>{game.classList.toggle('catalog-open');$('more-tools').setAttribute('aria-expanded',String(game.classList.contains('catalog-open')));};
  document.querySelectorAll('[data-tool]').forEach(b=>{
   b.onclick=e=>{if(b.dataset.dragged==='yes'){b.dataset.dragged='no';return;}selectTool(b.dataset.tool);};
   b.onpointerdown=e=>{if(e.button!==0||modal)return;b.setPointerCapture(e.pointerId);pointer={kind:'tool',id:e.pointerId,x:e.clientX,y:e.clientY,tool:b.dataset.tool,moved:false};};
   b.onpointermove=e=>{if(!pointer||pointer.kind!=='tool'||pointer.id!==e.pointerId)return;if(Math.hypot(e.clientX-pointer.x,e.clientY-pointer.y)>10){pointer.moved=true;selected=pointer.tool;const r=game.getBoundingClientRect();hover=cellAt(e.clientX-r.left,e.clientY-r.top-52);update();}};
   b.onpointerup=e=>{if(!pointer||pointer.kind!=='tool')return;const p=pointer;pointer=null;if(p.moved){b.dataset.dragged='yes';const r=game.getBoundingClientRect();place(cellAt(e.clientX-r.left,e.clientY-r.top-52),p.tool);}hover=null;update();};
   b.onpointercancel=()=>{pointer=null;hover=null;draw();};
  });
  document.querySelectorAll('[data-family]').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.family===family)));
 }
 function place(c,id=selected){if(modal||mode!=='build'||!id)return;const v=available(c,id);if(!v.valid){toast(v.reason);return;}const p={cell:{...c},tool:id,cost:tools[id].cost};placements.push(p);history.push(p);gold-=p.cost;selected=id;update();toast(id==='dig'?'Tracé ajouté · raccords de murs hors de cette maquette.':`${tools[id].name} posé${id==='spike'?'es':''} · touchez une autre case.`);}
 function setMode(next){mode=next;game.dataset.mode=mode;$('build-ui').hidden=next!=='build';$('overview-ui').hidden=next!=='overview';$('raid-ui').hidden=next!=='raid';$('hint').hidden=next!=='build';game.classList.remove('catalog-open');$('phase-title').textContent=next==='build'?'AMÉNAGEMENT':next==='raid'?'RAID EN COURS':'PROCHAIN RAID';$('phase-sub').textContent=next==='build'?'Délai du raid suspendu':next==='raid'?'Aperçu · sans simulation':'25 s · aperçu figé';hover=null;update();}
 function setTheme(value){theme=themes[value]?value:'obsidian';game.dataset.theme=theme;const t=themes[theme];$('preview-name').textContent=t.label;$('note-kicker').textContent=t.kicker;$('note-title').textContent=t.title;$('note-copy').textContent=t.copy;$('tradeoff').textContent=t.tradeoff;document.querySelectorAll('[data-theme].concept').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.theme===theme)));draw();}
 function showModal(title,copy,kicker='VOTRE DOMAINE'){modal=true;$('modal-title').textContent=title;$('modal-copy').textContent=copy;$('modal-kicker').textContent=kicker;$('modal').hidden=false;$('resume').focus();draw();}
 function reset(){placements=[];history=[];gold=320;selected=null;hover=null;pan={x:0,y:0};family='quick';modal=false;$('modal').hidden=true;$('toast').hidden=true;setMode('build');listTools();update();}
 canvas.tabIndex=0;canvas.setAttribute('role','application');canvas.setAttribute('aria-description','Flèches pour choisir une case, Entrée pour poser. Glisser déplace la vue.');
 canvas.onpointerdown=e=>{if(e.button!==0||modal)return;canvas.setPointerCapture(e.pointerId);pointer={kind:'world',id:e.pointerId,x:e.clientX,y:e.clientY,panX:pan.x,panY:pan.y,moved:false};};
 canvas.onpointermove=e=>{const r=game.getBoundingClientRect();if(pointer?.kind==='world'&&pointer.id===e.pointerId){if(Math.hypot(e.clientX-pointer.x,e.clientY-pointer.y)>8)pointer.moved=true;if(pointer.moved){pan.x=Math.max(-500,Math.min(500,pointer.panX+e.clientX-pointer.x));pan.y=Math.max(-300,Math.min(300,pointer.panY+e.clientY-pointer.y));hover=null;draw();return;}}if(!modal){hover=cellAt(e.clientX-r.left,e.clientY-r.top);draw();}};
 canvas.onpointerup=e=>{if(!pointer||pointer.kind!=='world')return;const p=pointer;pointer=null;if(!p.moved){const r=game.getBoundingClientRect();const c=cellAt(e.clientX-r.left,e.clientY-r.top);if(selected)place(c);else if(mode==='build')toast('Choisissez un outil dans la palette.');}hover=null;draw();};
 canvas.onpointercancel=()=>{pointer=null;hover=null;draw();};canvas.onpointerleave=()=>{if(!pointer){hover=null;draw();}};
 canvas.onkeydown=e=>{if(!selected||modal)return;const dirs={ArrowRight:[1,0],ArrowLeft:[-1,0],ArrowUp:[0,-1],ArrowDown:[0,1]};if(dirs[e.key]){e.preventDefault();hover=hover||{x:7,y:6};hover={x:hover.x+dirs[e.key][0],y:hover.y+dirs[e.key][1]};draw();}else if(e.key==='Enter'&&hover){e.preventDefault();place(hover);}};
 $('undo').onclick=()=>{const p=history.pop();if(!p)return;placements.splice(placements.indexOf(p),1);gold+=p.cost;update();toast(`${tools[p.tool].name} annulé · ${p.cost} or restitué.`);};
 $('finish').onclick=()=>setMode('overview');$('build').onclick=()=>setMode('build');
 $('raid').onclick=()=>{history=[];selected=null;setMode('raid');};
 $('end-raid').onclick=()=>showModal('Le cœur tient bon.','Cette vue illustre le retour à l’aménagement après le raid. Aucun résultat de partie n’est simulé.','APERÇU DU BILAN');
 $('pause').onclick=()=>showModal('Le temps s’arrête.','Votre donjon attend vos ordres.');
 $('core-info').onclick=()=>showModal('Le cœur du donjon.','100 % d’intégrité · niveau 1. Vos améliorations et l’expérience seraient regroupées ici.','CŒUR');
 $('resume').onclick=()=>{modal=false;$('modal').hidden=true;if(mode==='raid')setMode('overview');else draw();$('pause').focus();};
 $('recenter').onclick=()=>{pan={x:0,y:0};hover=null;draw();};$('toggle-grid').onclick=()=>{grid=!grid;$('toggle-grid').setAttribute('aria-pressed',String(grid));draw();};
 $('background').onchange=()=>{game.dataset.backdrop=$('background').value;};
 $('format').onchange=()=>{const w=+$('format').value,h=w===740?360:w===1024?576:390;document.querySelector('.review-main').classList.toggle('wide-review',w===1024);game.style.maxWidth=w+'px';game.style.height=h+'px';resize();};
 $('reset').onclick=reset;document.querySelectorAll('.concept').forEach(b=>b.onclick=()=>setTheme(b.dataset.theme));
 document.querySelectorAll('[data-family]').forEach(b=>b.onclick=()=>{family=b.dataset.family;listTools();});
 document.addEventListener('keydown',e=>{if(e.key==='Escape'){if(modal){modal=false;$('modal').hidden=true;}else if(game.classList.contains('catalog-open'))game.classList.remove('catalog-open');else if(selected){selected=null;hover=null;update();}else setMode(mode==='build'?'overview':'build');}});
 new ResizeObserver(resize).observe(game);
 Promise.all([art.decode(),chests.decode()]).then(()=>{ready=true;setTheme(params.get('theme')||'obsidian');listTools();setMode(params.get('state')==='overview'?'overview':'build');if(params.get('tool')&&tools[params.get('tool')])selectTool(params.get('tool'));resize();window.REVIEW_READY=true;}).catch(e=>{console.error(e);toast('Le chargement des sprites a échoué.');});
 // Inspection hooks belong to this disposable review only; no game code or saves.
 window.REVIEW={state:()=>({theme,mode,selected,gold,placements:placements.length,history:history.length,pan:{...pan}}),cellScreen:screen,choose:selectTool,theme:setTheme,mode:setMode,reset};
})();
