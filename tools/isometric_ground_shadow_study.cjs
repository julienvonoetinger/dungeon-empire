// Experimental contact/cast variations for the offline v2 comparison only.
// Production continues to use isometric_ground_shadow.cjs until visual selection.
const sharp=require('sharp'),P=require('./isometric_paint_geometry.cjs');
const S=4,LIGHT=[-.7,-.4,1],OPACITY=.32,CONTACT=.38;
const project=(p,l)=>P.project([p[0]-p[2]*l[0]/l[2],p[1]-p[2]*l[1]/l[2],0]);
async function prepare(m,options={}) {
  const lightDirection=options.lightDirection||LIGHT,opacity=options.castOpacity??OPACITY;
  const contactOpacity=options.contactOpacity??CONTACT,softness=options.softness??1.2;
  const contactSoftness=options.contactSoftness??.7,contactSpread=options.contactSpread??0;
  const lights=[lightDirection,...Array.from({length:8},(_,i)=>{
    const a=i*Math.PI/4;return [lightDirection[0]+.22*Math.cos(a),lightDirection[1]+.22*Math.sin(a),1];
  })];
  const vertices=m.faces.flatMap(f=>f.points),screen=lights.flatMap(l=>vertices.map(p=>project(p,l)));
  const padding=Math.max(5,Math.ceil(3*Math.max(softness,contactSoftness)+contactSpread+1));
  const lo=[0,1].map(i=>Math.floor(Math.min(...screen.map(p=>p[i])))-padding);
  const hi=[0,1].map(i=>Math.ceil(Math.max(...screen.map(p=>p[i])))+padding);
  const frame=[...lo,...hi.map((v,i)=>v-lo[i])],width=frame[2]*S,height=frame[3]*S;
  const mask=async (polygons,spread=0)=>{
    const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="${frame.join(' ')}">${polygons.map(ps=>`<polygon points="${ps.map(p=>p.join(',')).join(' ')}" fill="white" stroke="white" stroke-width="${2*spread}" stroke-linejoin="round"/>`).join('')}</svg>`;
    return sharp(Buffer.from(svg)).ensureAlpha().raw().toBuffer();
  };
  const sum=new Float32Array(width*height);
  for(const light of lights) {
    const data=await mask(m.faces.map(f=>f.points.map(p=>project(p,light))));
    for(let k=0;k<sum.length;k++)sum[k]+=data[k*4+3]/(255*lights.length);
  }
  const cast=Buffer.alloc(width*height*4);
  for(let k=0;k<sum.length;k++)cast[k*4+3]=Math.round(255*opacity*sum[k]);
  const soft=await sharp(cast,{raw:{width,height,channels:4}}).blur(softness*S).raw().toBuffer();
  const footprint=m.faces.filter(f=>f.points.every(p=>Math.abs(p[2])<1e-8)).map(f=>f.points.map(P.project));
  if(!footprint.length)throw Error('Ground shadow requires a grounded support face: '+m.id);
  const contact=await sharp(await mask(footprint,contactSpread),{raw:{width,height,channels:4}}).blur(contactSoftness*S).raw().toBuffer();
  for(let k=0;k<sum.length;k++) {
    const i=k*4,a=soft[i+3]/255,b=contact[i+3]/255*contactOpacity;
    soft[i]=5;soft[i+1]=8;soft[i+2]=17;soft[i+3]=Math.round(255*(1-(1-a)*(1-b)));
  }
  // Conservative ground-plane bounds include the diffuse edge. They let the
  // renderer omit a shadow if its receiving area crosses void or stairs.
  const world=lights.flatMap(l=>vertices.map(p=>[p[0]-p[2]*l[0],p[1]-p[2]*l[1]])),margin=Math.max(.055,padding*Math.sqrt(5)/P.PX);
  const bounds={min:[0,1].map(i=>Math.min(...world.map(p=>p[i]))-margin).concat(0),max:[0,1].map(i=>Math.max(...world.map(p=>p[i]))+margin).concat(0)};
  return {id:m.id+'-shadow',frame,bounds,groundEffect:true,
    png:await sharp(soft,{raw:{width,height,channels:4}}).resize(frame[2],frame[3]).png().toBuffer(),
    adaptation:{planeZ:0,sourceGeometry:m.id,lightDirection,areaLightSamples:lights.length,castOpacity:opacity,contactOpacity,softEdgeSourcePixels:softness,contactSoftnessSourcePixels:contactSoftness,contactSpreadSourcePixels:contactSpread,scope:'Static support shadow on the ground; emissive vortex excluded; no response to local torches'}};
}
module.exports={prepare};
