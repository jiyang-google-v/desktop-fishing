const {randomUUID} = require('node:crypto');
const {fish, depthFor, pickFish} = require('./game');
const MAX_SECONDS = 3000;
function createState(){return {version:2,cast:false,sessionId:null,focusSeconds:0,encyclopedia:{},aquarium:[],pendingCatch:null};}
function castLine(s,id=randomUUID){
  if(s.cast || s.pendingCatch)return {ok:false,reason:s.pendingCatch?'pending':'already-cast'};
  s.cast=true;s.sessionId=id();s.focusSeconds=0;return {ok:true};
}
function reelLine(s,{hour=new Date().getHours(),random=Math.random,id=randomUUID}={}){
  if(!s.cast)return {ok:false,reason:'not-cast'};
  const selected=pickFish(depthFor(s.focusSeconds),hour<6||hour>=18,random);
  s.cast=false;
  if(selected){
    const lengthCm=Math.round((10+random()*70)*10)/10;
    const previous=s.encyclopedia[selected.id]||{count:0,recordCm:0};
    s.encyclopedia[selected.id]={count:previous.count+1,recordCm:Math.max(previous.recordCm,lengthCm)};
    s.pendingCatch={catchId:id(),speciesId:selected.id,lengthCm,depth:depthFor(s.focusSeconds),caughtAt:new Date().toISOString()};
  }
  return {ok:true};
}
function settleCatch(s,{action,targetId}={}){
  if(!s.pendingCatch)return {ok:false,reason:'no-catch'};
  if(action==='keep'){
    if(s.aquarium.length>=6)return {ok:false,reason:'full'};
    s.aquarium.push(s.pendingCatch);
  }else if(action==='replace'){
    const index=s.aquarium.findIndex(c=>c.catchId===targetId);
    if(index<0)return {ok:false,reason:'unknown'};
    s.aquarium[index]=s.pendingCatch;
  }else if(action!=='release')return {ok:false,reason:'invalid-action'};
  s.pendingCatch=null;s.sessionId=null;return {ok:true};
}
function removeCatch(s,catchId){
  const index=s.aquarium.findIndex(c=>c.catchId===catchId);
  if(index<0)return {ok:false,reason:'unknown'};
  s.aquarium.splice(index,1);return {ok:true};
}
function restoreState(data){
  if(!data || typeof data!=='object' || Array.isArray(data))throw new Error('Invalid save');
  if(data.version!==1 && data.version!==2)throw new Error('Unsupported save version');
  const s=createState(),known=new Set(fish.map(f=>f.id));
  const number=(v,max)=>Number.isFinite(v)&&v>=0?Math.min(v,max):0;
  s.focusSeconds=number(data.focusSeconds,MAX_SECONDS);
  for(const [id,entry] of Object.entries(data.encyclopedia||{})){
    if(known.has(id)&&entry&&typeof entry==='object')s.encyclopedia[id]={count:Math.floor(number(entry.count,Number.MAX_SAFE_INTEGER)),recordCm:number(entry.recordCm,100000)};
  }
  const valid=c=>c && typeof c.catchId==='string' && c.catchId.length>0 && known.has(c.speciesId) && Number.isFinite(c.lengthCm)&&c.lengthCm>=0;
  const clean=c=>({catchId:c.catchId,speciesId:c.speciesId,lengthCm:c.lengthCm,depth:number(c.depth,200),caughtAt:typeof c.caughtAt==='string'?c.caughtAt:null});
  const seen=new Set();
  for(const [i,item] of (Array.isArray(data.aquarium)?data.aquarium:[]).entries()){
    const c=data.version===1?{catchId:'legacy-'+i,speciesId:item,lengthCm:s.encyclopedia[item]?.recordCm||0,depth:0,caughtAt:null}:item;
    if(valid(c)&&!seen.has(c.catchId)&&s.aquarium.length<6){s.aquarium.push(clean(c));seen.add(c.catchId);}
  }
  if(data.version===2){
    if(valid(data.pendingCatch)&&!seen.has(data.pendingCatch.catchId))s.pendingCatch=clean(data.pendingCatch);
    s.cast=Boolean(data.cast&&!s.pendingCatch);
    s.sessionId=typeof data.sessionId==='string'?data.sessionId:null;
    if(s.cast&&!s.sessionId)s.sessionId=randomUUID();
  }
  return s;
}
module.exports={createState,castLine,reelLine,settleCatch,removeCatch,restoreState,MAX_SECONDS};
