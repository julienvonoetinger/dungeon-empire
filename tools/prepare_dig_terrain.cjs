const fs=require('fs'),path=require('path'),crypto=require('crypto'),sharp=require('sharp');
const root=path.resolve(__dirname,'..');
const source=path.join(root,'docs/reference/interface-review/v21-connected-excavation/source/bedrock.png');
const output=path.join(root,'assets/previews/dig-terrain/bedrock.png');
(async()=>{
  fs.mkdirSync(path.dirname(output),{recursive:true});
  await sharp(source).resize(512,512,{fit:'inside'}).png().toFile(output);
  const metadata=await sharp(output).metadata();
  const record={tool:'Built-in ImageGen',source:'source/bedrock.png',prompt:'source/bedrock.prompt.txt',sha256:crypto.createHash('sha256').update(fs.readFileSync(source)).digest('hex'),size:[metadata.width,metadata.height],bytes:fs.statSync(output).size,rgbaBytes:metadata.width*metadata.height*4};
  fs.writeFileSync(path.join(root,'docs/reference/interface-review/v21-connected-excavation/preparation.json'),JSON.stringify(record,null,2)+'\n');
  console.log(JSON.stringify(record));
})().catch(error=>{console.error(error);process.exitCode=1;});
