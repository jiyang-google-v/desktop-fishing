const {app,BrowserWindow,ipcMain,powerMonitor}=require('electron');
const path=require('node:path');const {execFile}=require('node:child_process');
const {promisify}=require('node:util');const {performance}=require('node:perf_hooks');
const execFileAsync=promisify(execFile);
const {depthFor,canAccrue,fish}=require('./shared/game');
const {createState,castLine,reelLine,settleCatch,removeCatch,MAX_SECONDS}=require('./shared/session');
const {readSave,writeSave}=require('./shared/storage');
let win,state=createState(),locked=false,sleeping=false,blocked=false,warning=null;
let status={supported:process.platform==='win32',idleSeconds:Infinity},busy=false,epoch=0,lastTick=performance.now(),lastEligible=false;
let tickTimer,saveTimer;
const savePath=()=>path.join(app.getPath('userData'),'save.json');
function resetClock(){epoch++;lastEligible=false;lastTick=performance.now();}
function persist(){if(blocked)return;try{writeSave(savePath(),state);}catch{warning='存档写入失败，请检查磁盘空间和文件权限。';}}
async function inputStatus(){
 if(process.platform!=='win32')return {supported:false,idleSeconds:Infinity};
 try{
  const {stdout}=await execFileAsync('powershell.exe',['-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',path.join(__dirname,'windows','input-status.ps1')],{timeout:4000,windowsHide:true});
  const seconds=Number(JSON.parse(stdout.trim()).idleSeconds);
  return {supported:Number.isFinite(seconds)&&seconds>=0,idleSeconds:seconds};
 }catch{return {supported:false,idleSeconds:Infinity};}
}
function pauseReason(){
 if(blocked)return 'save-blocked';if(!state.cast)return state.pendingCatch?'pending':'ready';
 if(sleeping)return 'sleeping';if(locked)return 'locked';if(win?.isFocused())return 'foreground';
 if(!status.supported)return 'unsupported';if(status.idleSeconds>600)return 'idle';
 if(state.focusSeconds>=MAX_SECONDS)return 'max-depth';return 'working';
}
function snapshot(){return {...state,depth:depthFor(state.focusSeconds),locked,sleeping,foreground:!!win?.isFocused(),pauseReason:pauseReason(),warning,blocked,fish,isNight:new Date().getHours()<6||new Date().getHours()>=18};}
function publish(){if(win&&!win.isDestroyed())win.webContents.send('game:state',snapshot());}
async function tick(){
 if(busy)return;busy=true;
 const token=epoch;
 try{
  if(state.cast&&!blocked&&!locked&&!sleeping&&!win?.isFocused())status=await inputStatus();
  const now=performance.now(),elapsed=(now-lastTick)/1000;lastTick=now;
  const eligible=!blocked&&canAccrue({cast:state.cast,foreground:win?.isFocused(),locked,sleeping,...status});
  if(token===epoch&&lastEligible&&eligible&&elapsed>=0&&elapsed<=5)state.focusSeconds=Math.min(MAX_SECONDS,state.focusSeconds+elapsed);
  lastEligible=token===epoch&&eligible;
  publish();
 }finally{busy=false;}
}
function transition(event,action){
 if(event.sender!==win?.webContents||blocked)return {ok:false,reason:'blocked',state:snapshot()};
 const next=JSON.parse(JSON.stringify(state));const result=action(next);
 if(result.ok){
  try{writeSave(savePath(),next);}catch{warning='操作未保存，请检查磁盘空间后重试。';publish();return {ok:false,reason:'save-failed',state:snapshot()};}
  state=next;resetClock();warning=null;
 }
 publish();return {...result,state:snapshot()};
}
app.whenReady().then(()=>{
 const loaded=readSave(savePath());state=loaded.state;blocked=!!loaded.blocked;warning=loaded.warning||null;
 win=new BrowserWindow({width:1100,height:790,minWidth:850,minHeight:650,backgroundColor:'#edf2ef',autoHideMenuBar:true,webPreferences:{preload:path.join(__dirname,'preload.js'),contextIsolation:true,nodeIntegration:false,sandbox:true}});
 win.webContents.setWindowOpenHandler(()=>({action:'deny'}));
 win.webContents.on('will-navigate',event=>event.preventDefault());
 win.loadFile(path.join(__dirname,'renderer','index.html'));
 for(const event of ['focus','blur'])win.on(event,()=>{resetClock();publish();});
 powerMonitor.on('lock-screen',()=>{locked=true;resetClock();publish();});
 powerMonitor.on('unlock-screen',()=>{locked=false;resetClock();publish();});
 powerMonitor.on('suspend',()=>{sleeping=true;resetClock();persist();});
 powerMonitor.on('resume',()=>{sleeping=false;resetClock();publish();});
 tickTimer=setInterval(tick,1000);saveTimer=setInterval(persist,30000);
 win.on('close',persist);
});
ipcMain.handle('game:state',()=>snapshot());
ipcMain.handle('game:cast',event=>transition(event,castLine));
ipcMain.handle('game:reel',event=>transition(event,reelLine));
ipcMain.handle('game:settle',(event,request)=>transition(event,s=>settleCatch(s,request)));
ipcMain.handle('game:aquarium-remove',(event,id)=>transition(event,s=>removeCatch(s,id)));
app.on('before-quit',()=>{clearInterval(tickTimer);clearInterval(saveTimer);persist();});
app.on('window-all-closed',()=>app.quit());
