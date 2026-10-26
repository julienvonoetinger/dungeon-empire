// Isolated WebGL2 review adapter for the unchanged Godot fragment body.
(async()=>{
 const {entry:e,vertex,fragment}=options,canvas=document.getElementById('raw');
 canvas.width=e.region[2];canvas.height=e.region[3];
 const gl=canvas.getContext('webgl2',{alpha:true,antialias:false,premultipliedAlpha:false,preserveDrawingBuffer:true});
 if(!gl)throw Error('WebGL2 unavailable');
 const compile=(type,source)=>{const s=gl.createShader(type);gl.shaderSource(s,source);gl.compileShader(s);if(!gl.getShaderParameter(s,gl.COMPILE_STATUS))throw Error(gl.getShaderInfoLog(s));return s;};
 const program=gl.createProgram();gl.attachShader(program,compile(gl.VERTEX_SHADER,vertex));gl.attachShader(program,compile(gl.FRAGMENT_SHADER,fragment));gl.linkProgram(program);
 if(!gl.getProgramParameter(program,gl.LINK_STATUS))throw Error(gl.getProgramInfoLog(program));
 gl.useProgram(program);
 const buffer=gl.createBuffer();gl.bindBuffer(gl.ARRAY_BUFFER,buffer);gl.bufferData(gl.ARRAY_BUFFER,new Float32Array([-1,-1,1,-1,-1,1,1,1]),gl.STATIC_DRAW);
 const pos=gl.getAttribLocation(program,'position');gl.enableVertexAttribArray(pos);gl.vertexAttribPointer(pos,2,gl.FLOAT,false,0,0);
 const load=url=>new Promise((resolve,reject)=>{const i=new Image();i.onload=()=>resolve(i);i.onerror=reject;i.src=url;});
 const [image,bg]=await Promise.all([load(options.image),load(options.background)]);
 gl.activeTexture(gl.TEXTURE0);gl.bindTexture(gl.TEXTURE_2D,gl.createTexture());gl.pixelStorei(gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL,false);
 gl.texImage2D(gl.TEXTURE_2D,0,gl.RGBA,gl.RGBA,gl.UNSIGNED_BYTE,image);
 for(const name of [gl.TEXTURE_MIN_FILTER,gl.TEXTURE_MAG_FILTER])gl.texParameteri(gl.TEXTURE_2D,name,gl.LINEAR);
 for(const name of [gl.TEXTURE_WRAP_S,gl.TEXTURE_WRAP_T])gl.texParameteri(gl.TEXTURE_2D,name,gl.CLAMP_TO_EDGE);
 const u=name=>gl.getUniformLocation(program,name),[w,h]=options.atlasSize,r=e.region;
 gl.uniform1i(u('TEXTURE'),0);gl.uniform2f(u('TEXTURE_PIXEL_SIZE'),1/w,1/h);gl.uniform4f(u('atlas_rect'),r[0]/w,r[1]/h,r[2]/w,r[3]/h);
 gl.uniform2f(u('frame_size'),...e.size);gl.uniform2f(u('vortex_center'),...e.vortex.center);gl.uniform1f(u('vortex_radius'),e.vortex.radius);
 const scene=document.getElementById('scene'),ctx=scene.getContext('2d'),detail=document.getElementById('detail'),dtx=detail.getContext('2d');
 const draw=(phase,enabled=true)=>{
  gl.viewport(0,0,canvas.width,canvas.height);gl.uniform1f(u('phase'),phase);gl.uniform1i(u('animation_enabled'),enabled?1:0);gl.drawArrays(gl.TRIANGLE_STRIP,0,4);
  ctx.clearRect(0,0,scene.width,scene.height);ctx.drawImage(bg,0,0);ctx.drawImage(canvas,options.anchor[0]+e.offset[0]*options.zoom,options.anchor[1]+e.offset[1]*options.zoom,e.size[0]*options.zoom,e.size[1]*options.zoom);
  dtx.clearRect(0,0,detail.width,detail.height);dtx.drawImage(canvas,0,0,detail.width,detail.height);
 };
 let running=true,phase=0,last=performance.now();
 const slider=document.getElementById('phase'),enabled=document.getElementById('enabled'),toggle=document.getElementById('toggle');
 toggle.onclick=()=>{running=!running;toggle.textContent=running?'Pause':'Reprendre';};
 slider.oninput=()=>{running=false;toggle.textContent='Reprendre';phase=Number(slider.value);draw(phase,enabled.checked);};
 window.vortexReview={draw,stop:()=>{running=false;window.cancelAnimationFrame(animationFrame);},raw:()=>canvas.toDataURL(),scene:()=>scene.toDataURL(),renderer:gl.getParameter(gl.RENDERER)};
 // A separate handle lets capture freeze drawing while setting an exact phase.
 let animationFrame;
 const live=now=>{if(running)phase=(phase+(now-last)/12000)%1;last=now;slider.value=phase;draw(phase,enabled.checked);animationFrame=requestAnimationFrame(live);};
 draw(0);window.reviewReady=true;animationFrame=requestAnimationFrame(live);
})().catch(e=>{window.reviewError=String(e);document.body.append(String(e));});
