const {app, BrowserWindow, ipcMain, powerMonitor} = require('electron');
const fs = require('node:fs');
const path = require('node:path');
const {execFile} = require('node:child_process');
const {promisify} = require('node:util');
const execFileAsync=promisify(execFile);
const {depthFor,canAccrue,pickFish,addToAquarium,fish} = require('./shared/game');
let win, cast=false, focusSeconds=0, locked=false, sleeping=false, lastTick=Date.now();
let encyclopedia={},aquarium=[],lastCatch=null;
const savePath=()=>path.join(app.getPath('userData'),'save.json');
function load(){try{const d=JSON.parse(fs.readFileSync(savePath(),'utf8'));focusSeconds=Math.max(0,Number(d.focusSeconds)||0);encyclopedia=d.encyclopedia||{};aquarium=Array.isArray(d.aquarium)?d.aquarium.slice(0,6):[];}catch{}}
function save(){try{fs.writeFileSync(savePath(),JSON.stringify({version:1,focusSeconds,encyclopedia,aquarium},null,2));}catch(e){console.error('Save failed',e.message)}}
async function inputStatus(){
 if(process.platform!=='win32')return {supported:false,idleSeconds:Infinity};
 try{
  const script=path.join(__dirname,'windows','input-status.ps1');
  const {stdout}=await execFileAsync('powershell.exe',['-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',script],{timeout:4000,windowsHide:true});
  const data=JSON.parse(stdout.trim());
  return {supported:true,idleSeconds:Number(data.idleSeconds)};
 }catch{return {supported:false,idleSeconds:Infinity};}
}
function snapshot(){return {cast,depth:Math.round(depthFor(focusSeconds)*10)/10,focusSeconds:Math.floor(focusSeconds),locked,sleeping,foreground:!!win?.isFocused(),encyclopedia,aquarium,lastCatch,fish};}
let busy=false;
async function tick(){
 const now=Date.now(),elapsed=Math.max(0,Math.min((now-lastTick)/1000,2));lastTick=now;
 if(busy)return;busy=true;
 try{
  const status=await inputStatus();
  if(canAccrue({cast,foreground:win?.isFocused(),locked,sleeping,...status}))focusSeconds+=elapsed;
  if(win&&!win.isDestroyed())win.webContents.send('game:state',snapshot());
 }finally{busy=false;}
}
app.whenReady().then(()=>{
 load();
 win=new BrowserWindow({width:1100,height:760,minWidth:850,minHeight:600,backgroundColor:'#d9e8e8',webPreferences:{preload:path.join(__dirname,'preload.js'),contextIsolation:true,nodeIntegration:false}});
 win.loadFile(path.join(__dirname,'renderer','index.html'));
 powerMonitor.on('lock-screen',()=>locked=true);
 powerMonitor.on('unlock-screen',()=>{locked=false;lastTick=Date.now()});
 powerMonitor.on('suspend',()=>{sleeping=true;save()});
 powerMonitor.on('resume',()=>{sleeping=false;lastTick=Date.now()});
 setInterval(tick,1000);setInterval(save,30000);
 win.on('close',save);
});
ipcMain.handle('game:state',()=>snapshot());
ipcMain.handle('game:cast',()=>{cast=true;focusSeconds=0;lastCatch=null;lastTick=Date.now();return snapshot()});
ipcMain.handle('game:reel',()=>{
 if(!cast)return snapshot();cast=false;
 const h=new Date().getHours(),isNight=h<6||h>=18;
 const selected=pickFish(depthFor(focusSeconds),isNight);
 if(selected){const lengthCm=Math.round((10+Math.random()*70)*10)/10;const prev=encyclopedia[selected.id]||{count:0,recordCm:0};encyclopedia[selected.id]={count:prev.count+1,recordCm:Math.max(prev.recordCm,lengthCm)};lastCatch={id:selected.id,name:selected.name,rarity:selected.rarity,lengthCm};}
 save();return snapshot();
});
ipcMain.handle('game:aquarium-add',(_event,id)=>{if(!fish.some(f=>f.id===id))return {ok:false,reason:'unknown',state:snapshot()};const result=addToAquarium(aquarium,id);if(result.ok){aquarium=result.aquarium;save()}return {...result,state:snapshot()}});
ipcMain.handle('game:aquarium-remove',(_event,index)=>{if(Number.isInteger(index)&&index>=0&&index<aquarium.length){aquarium.splice(index,1);save()}return snapshot()});
app.on('before-quit',save);
app.on('window-all-closed',()=>{app.quit()});
