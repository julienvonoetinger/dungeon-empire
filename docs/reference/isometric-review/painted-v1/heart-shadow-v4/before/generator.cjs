// Prepared ground-only shadow. Uses the rigid support, never the luminous orb.
// Godot places this atlas region beneath the architecture and the prop.
const sharp=require('sharp'),P=require('./isometric_paint_geometry.cjs');
const S=4,LIGHT=[-.7,-.4,1],OPACITY=.32,CONTACT=.38;
const project=(p,l)=>P.project([p[0]-p[2]*l[0]/l[2],p[1]-p[2]*l[1]/l[2],0]);
async function prepare(m) {
  const lights=[LIGHT,...Array.from({length:8},(_,i)=>{
    const a=i*Math.PI/4;return [LIGHT[0]+.22*Math.cos(a),LIGHT[1]+.22*Math.sin(a),1];
  })];
  const vertices=m.faces.flatMap(f=>f.points),screen=lights.flatMap(l=>vertices.map(p=>project(p,l)));
  const lo=[0,1].map(i=>Math.floor(Math.min(...screen.map(p=>p[i])))-5);
  const hi=[0,1].map(i=>Math.ceil(Math.max(...screen.map(p=>p[i])))+5);
  const frame=[...lo,...hi.map((v,i)=>v-lo[i])],width=frame[2]*S,height=frame[3]*S;
  const mask=async polygons=>{
    const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="${frame.join(' ')}">${polygons.map(ps=>`<polygon points="${ps.map(p=>p.join(',')).join(' ')}" fill="white"/>`).join('')}</svg>`;
    return sharp(Buffer.from(svg)).ensureAlpha().raw().toBuffer();
  };
  const sum=new Float32Array(width*height);
  for(const light of lights) {
    const data=await mask(m.faces.map(f=>f.points.map(p=>project(p,light))));
    for(let k=0;k<sum.length;k++)sum[k]+=data[k*4+3]/(255*lights.length);
  }
  const cast=Buffer.alloc(width*height*4);
  for(let k=0;k<sum.length;k++)cast[k*4+3]=Math.round(255*OPACITY*sum[k]);
  const soft=await sharp(cast,{raw:{width,height,channels:4}}).blur(1.2*S).raw().toBuffer();
  const footprint=m.faces.filter(f=>f.points.every(p=>Math.abs(p[2])<1e-8)).map(f=>f.points.map(P.project));
  if(!footprint.length)throw Error('Ground shadow requires a grounded support face: '+m.id);
  const contact=await sharp(await mask(footprint),{raw:{width,height,channels:4}}).blur(.7*S).raw().toBuffer();
  for(let k=0;k<sum.length;k++) {
    const i=k*4,a=soft[i+3]/255,b=contact[i+3]/255*CONTACT;
    soft[i]=5;soft[i+1]=8;soft[i+2]=17;soft[i+3]=Math.round(255*(1-(1-a)*(1-b)));
  }
  // Conservative ground-plane bounds include the diffuse edge. They let the
  // renderer omit a shadow if its receiving area crosses void or stairs.
  const world=lights.flatMap(l=>vertices.map(p=>[p[0]-p[2]*l[0],p[1]-p[2]*l[1]])),margin=.055;
  const bounds={min:[0,1].map(i=>Math.min(...world.map(p=>p[i]))-margin).concat(0),max:[0,1].map(i=>Math.max(...world.map(p=>p[i]))+margin).concat(0)};
  return {id:m.id+'-shadow',frame,bounds,groundEffect:true,
    png:await sharp(soft,{raw:{width,height,channels:4}}).resize(frame[2],frame[3]).png().toBuffer(),
    adaptation:{planeZ:0,sourceGeometry:m.id,lightDirection:LIGHT,areaLightSamples:lights.length,castOpacity:OPACITY,contactOpacity:CONTACT,softEdgeSourcePixels:1.2,contactSoftnessSourcePixels:.7,scope:'Static support shadow on the ground; emissive vortex excluded; no response to local torches'}};
}
module.exports={prepare};
