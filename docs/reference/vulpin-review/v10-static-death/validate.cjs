// Validate the prepared resources against v9, including every retained frame.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto');
const dir=__dirname,old=path.resolve(dir,'../v9-motion-correction');
const read=(base,f)=>JSON.parse(fs.readFileSync(path.join(base,f)));
const reports={},profiles=['reference','balanced','compact'];let retainedFrames=0;
for(const profile of profiles){
 const m=read(dir,`projects/${profile}/manifest.json`),previous=read(old,`projects/${profile}/manifest.json`);
 if(Object.keys(m.clips).length!==32)throw Error('Expected 8 states × 4 directions');
 for(const [name,clip] of Object.entries(m.clips)){
  if(name.endsWith('-death'))throw Error('Fall sequence remains');
  if(name.endsWith('-dead')&&(clip.frames.length!==1||clip.loop))throw Error('Corpse must be static');
  const before=previous.clips[name];
  if(clip.seconds!==before.seconds||clip.strideCells!==before.strideCells||clip.frames.length!==before.frames.length)throw Error('Unrelated timing changed: '+name);
  for(let i=0;i<clip.frames.length;i++){
   const a=fs.readFileSync(path.join(dir,'frames',profile,clip.frames[i].sprite+'.png'));
   const b=fs.readFileSync(path.join(old,'frames',profile,before.frames[i].sprite+'.png'));
   if(!a.equals(b))throw Error('Retained image changed: '+profile+' '+name+' '+i);retainedFrames++;
  }
 }
 const native=read(dir,'godot-'+profile+'.json'),loaded=read(dir,'vulpin-'+profile+'-loaded.json');
 if(native.failures.length||native.nativeAlphaMaxError!==0||loaded.clips!==32||loaded.frameSlots!==Object.values(m.clips).reduce((s,c)=>s+c.frames.length,0))throw Error('Native verification failed');
 const oldBytes=read(old,'godot-'+profile+'.json').pckBytes;
 reports[profile]={...native,decodedBytes:loaded.decodedBytes,packOnly:loaded.loadedFromPackOnly,previousPckBytes:oldBytes,savedBytes:oldBytes-native.pckBytes,savedPercent:100*(oldBytes-native.pckBytes)/oldBytes};
}
for(const d of ['se','sw','nw','ne'])if(!fs.readFileSync(path.join(dir,'source',d+'-dead.png')).equals(fs.readFileSync(path.join(old,'renders',d,'death/36.png'))))throw Error('Static source changed');
const viewer=read(dir,'native-viewer.json');if(viewer.failures.length||viewer.states!==8)throw Error('Viewer failure');
const apkHash=crypto.createHash('sha256').update(fs.readFileSync(path.resolve(dir,'../../../../build/vulpin-animations-0.1.apk'))).digest('hex');
if(apkHash!=='f67a7a75416a3752243a8389e9d7e1581907b0ba45d813f28e6994bb58b09bd3')throw Error('Historical APK changed');
const result={scope:'Static-death untextured prototype, 8 states / 4 directions. No APK or gameplay integration.',profiles:reports,retainedFramesByteIdentical:retainedFrames,staticSources:4,viewer,nativeChecks:Object.values(reports).reduce((s,r)=>s+r.checks,0),oldApkSha256:apkHash,limits:['No new physical-phone test','No final painted hero or gameplay state-machine integration','Previous reviews and APK remain historical']};
fs.writeFileSync(path.join(dir,'validation.json'),JSON.stringify(result,null,2));
console.log(JSON.stringify({retainedFrames,nativeChecks:result.nativeChecks,viewerChecks:viewer.checks,balancedBytes:reports.balanced.pckBytes,savedPercent:reports.balanced.savedPercent,failures:0}));
