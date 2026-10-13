const fs=require('node:fs');const {createState,restoreState}=require('./session');
function parse(file){return restoreState(JSON.parse(fs.readFileSync(file,'utf8')));}
function readSave(file){
  if(!fs.existsSync(file)&&!fs.existsSync(file+'.bak'))return {state:createState()};
  try{return {state:parse(file)};}catch(error){
    if(error.message.includes('version'))return {state:createState(),blocked:true,warning:'存档来自不支持的版本，已暂停操作以保护数据。'};
    try{return {state:parse(file+'.bak'),recovered:true,warning:'主存档损坏，已恢复上一次备份。'};}catch{return {state:createState(),blocked:true,warning:'存档和备份均无法读取，已暂停操作。请备份存档后再处理。'};}
  }
}
function writeSave(file,state){
  if(fs.existsSync(file)){
    let valid=false;
    try{parse(file);valid=true;}catch(error){if(error.message.includes('version'))throw error;}
    if(valid)fs.copyFileSync(file,file+'.bak');
  }
  const temp=file+'.tmp';
  fs.writeFileSync(temp,JSON.stringify(state,null,2));
  fs.renameSync(temp,file);
}
module.exports={readSave,writeSave};
