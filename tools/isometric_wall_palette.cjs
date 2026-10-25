// Offline shared stone grading; never edits source PNGs or alpha.
const clamp=(v,a=0,b=1)=>Math.max(a,Math.min(b,v));
const smooth=v=>{v=clamp(v);return v*v*(3-2*v);};
const luma=c=>c[0]*.2126+c[1]*.7152+c[2]*.0722;
const accent=c=>Math.min(smooth((c[0]-c[1]-4)/20),smooth((c[2]-c[1]-16)/22));
const quantiles=values=>{const sorted=[...values].sort((a,b)=>a-b);return [.05,.25,.5,.75,.95,.995].map(q=>sorted[Math.round((sorted.length-1)*q)]);};
function profile(samples){
 if(samples.length<50)throw Error('Insufficient wall plane colour samples');
 return {count:samples.length,luma:quantiles(samples.map(luma)),rgb:[0,1,2].map(c=>quantiles(samples.map(v=>v[c]))[2])};
}
function transfer(value,source,target){
 if(value<=source[0])return Math.max(0,target[0]+(value-source[0])*.6);
 for(let i=1;i<source.length;i++)if(value<=source[i])return target[i-1]+(target[i]-target[i-1])*clamp((value-source[i-1])/Math.max(.01,source[i]-source[i-1]));
 return target[target.length-1];
}
function grade(colour,source,target){
 const sy=luma(colour),ty=transfer(sy,source.luma,target.luma),sm=luma(source.rgb),tm=luma(target.rgb),keepAccent=accent(colour);
 return colour.map((channel,i)=>{
  if(i===3)return channel;
  // Common base hue with only a restrained amount of source stone chroma.
  const chroma=clamp(channel-source.rgb[i]-(sy-sm)*source.rgb[i]/Math.max(1,sm),-20,20)*.10;
  const stone=target.rgb[i]*ty/Math.max(1,tm)+chroma;
  return clamp(stone*(1-keepAccent)+channel*keepAccent,0,255);
 });
}
module.exports={luma,accent,profile,grade};
