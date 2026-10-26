const path=require('node:path'),sharp=require('sharp');
async function main(){await sharp(path.join(__dirname,'source/mineral-inclusion-original.png')).resize({width:256}).png().toFile(path.join(__dirname,'assets/mineral.png'));console.log('Existing top-down ImageGen mineral source, uniform256px downsample, native alpha retained.');}
main().catch(e=>{console.error(e);process.exitCode=1;});
