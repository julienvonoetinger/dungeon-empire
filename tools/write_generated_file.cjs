const fs=require('node:fs'),path=require('node:path');

// Godot may be importing the previous PNG while an offline export runs.
// Replace completed files atomically instead of truncating an in-use image.
function writeGeneratedFile(file,data) {
  fs.mkdirSync(path.dirname(file),{recursive:true});
  const temporary=file+'.pending-'+process.pid;
  fs.writeFileSync(temporary,data);
  try {
    for(let attempt=0;;attempt++) {
      try {fs.renameSync(temporary,file);break;}
      catch(error) {
        if(attempt>=9||!['UNKNOWN','EBUSY','EPERM','EACCES'].includes(error.code))throw error;
        Atomics.wait(new Int32Array(new SharedArrayBuffer(4)),0,0,200);
      }
    }
  } finally {if(fs.existsSync(temporary))fs.unlinkSync(temporary);}
}
module.exports={writeGeneratedFile};
