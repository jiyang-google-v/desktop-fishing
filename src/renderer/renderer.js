const el=id=>document.getElementById(id);
const escapeHtml=value=>String(value).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const rarity={common:'常见',uncommon:'少见',rare:'稀有',legendary:'传说'};
let current=null,panelMode='book',replacement=false,inFlight=false,confirmAction=null,catchKey=null,panelKey=null;
const errors={full:'鱼缸已满，请选择一条鱼进行替换。',pending:'请先安置这次鱼获。','save-failed':'保存失败，本次操作未完成，请检查磁盘空间后重试。',blocked:'存档不可用，操作已暂停。',unknown:'这条鱼已不在鱼缸中。'};
const reasons={ready:['准备出发','放钩后切换到其他工作窗口，鱼钩会随专注慢慢下潜。'],foreground:['暂歇片刻','游戏在前台，本次进度已保留。切到其他窗口后继续。'],working:['正在探索深海','鱼钩正在下潜，休息时回来收杆，揭晓这次相遇。'],idle:['等待你回来','键鼠空闲超过 10 分钟，已暂停并保留深度。'],locked:['海面暂时安静','电脑已锁屏，进度暂停。'],sleeping:['海面暂时安静','电脑正在休眠，进度暂停。'],unsupported:['专注检测暂不可用','仅 Windows 支持专注计时；检测失败时会保守暂停。'],pending:['遇见一位新朋友','这次鱼获已锁定，收进鱼缸或放生后即可再次放钩。'],'max-depth':['抵达 200 米','已到最深处，可以收杆揭晓鱼获。'],'save-blocked':['存档需要处理','为保护已有数据，已暂停操作。']};
function fishName(c){return current.fish.find(f=>f.id===c.speciesId)?.name||'未知鱼种';}
function ask(title,message,action){confirmAction=action;el('confirm-title').textContent=title;el('confirm-message').textContent=message;el('confirmation').showModal();}
async function act(callback){
 if(inFlight)return;inFlight=true;draw(current);
 try{const result=await callback();if(result.state)draw(result.state);el('notice').textContent=result.ok?'':(errors[result.reason]||'操作未完成，请重试。');return result;}catch{el('notice').textContent='操作失败，请稍后重试。';}finally{inFlight=false;if(current)draw(current);}
}
function draw(s){
 if(!s)return;current=s;
 const [title,description]=reasons[s.pauseReason]||reasons.ready;
 el('status-title').textContent=title;el('status').textContent=description;
 el('depth').textContent=s.depth.toFixed(1);const seconds=Math.floor(s.focusSeconds);
 el('time').textContent=String(Math.floor(seconds/60)).padStart(2,'0')+':'+String(seconds%60).padStart(2,'0');
 el('progress').style.width=(s.depth/2)+'%';el('line').style.height=(15+s.depth/200*75)+'%';el('line').hidden=!s.cast;
 el('day-label').textContent=s.isNight?'夜晚的海':'白昼的海';el('layer').textContent=s.depth<30?'表层 · 0–30 m':s.depth<100?'浅海 · 30–100 m':'深水 · 100–200 m';
 document.body.classList.toggle('night',s.isNight);document.body.classList.toggle('working',s.pauseReason==='working');
 el('cast').disabled=inFlight||s.blocked||s.cast||!!s.pendingCatch;el('reel').disabled=inFlight||s.blocked||!s.cast;
 el('book-count').textContent=Object.keys(s.encyclopedia).length+' / '+s.fish.length;el('tank-count').textContent=s.aquarium.length+' / 6';
 if(s.warning)el('notice').textContent=s.warning;
 const key=JSON.stringify([s.pendingCatch,s.aquarium.length,inFlight,s.blocked]);
 if(key!==catchKey){catchKey=key;renderCatch();}
 if(el('collection').open)renderPanel();
}
function renderCatch(){
 const c=current.pendingCatch;
 if(!c){el('catch').innerHTML='<span class="eyebrow">下一次相遇</span><p>鱼获由收杆时的深度和昼夜决定。发现过的鱼会留在图鉴中。</p>';return;}
 const f=current.fish.find(f=>f.id===c.speciesId);
 el('catch').innerHTML='<span class="eyebrow">本次鱼获 · '+escapeHtml(rarity[f.rarity]||f.rarity)+'</span><h3>'+escapeHtml(f.name)+'</h3><p>'+c.lengthCm+' cm · '+c.depth.toFixed(1)+' m</p><div class="actions"><button id="keep" class="primary">'+(current.aquarium.length>=6?'选择替换':'收进鱼缸')+'</button><button id="release">放生</button></div>';
 el('keep').disabled=el('release').disabled=inFlight||current.blocked;
 el('keep').onclick=()=>current.aquarium.length>=6?openPanel('tank',true):act(()=>window.fishing.settle({action:'keep'}));
 el('release').onclick=()=>ask('放生这条鱼？','鱼获将离开，发现次数和体长纪录会保留在图鉴中。',()=>act(()=>window.fishing.settle({action:'release'})));
}
function openPanel(mode,replace=false){panelMode=mode;replacement=replace;panelKey=null;renderPanel();if(!el('collection').open)el('collection').showModal();}
function renderPanel(){
 const key=JSON.stringify([panelMode,replacement,current.encyclopedia,current.aquarium,current.pendingCatch,inFlight,current.blocked]);if(key===panelKey)return;panelKey=key;
 el('panel-title').textContent=panelMode==='book'?'鱼类图鉴':'精选鱼缸';
 el('panel-description').textContent=panelMode==='book'?'每一次相遇都留下纪录。未发现的鱼种等待你探索。':replacement?'选择要替换的鱼；取消会保留原鱼和本次鱼获。':'最多展示 6 条亲自挑选的鱼。同种鱼也可以拥有不同的体长。';
 if(panelMode==='book'){
  el('panel').innerHTML='<div class="cards">'+current.fish.map(f=>{const record=current.encyclopedia[f.id];return '<article class="card '+(record?'':'undiscovered')+'"><span class="fish-icon" aria-hidden="true">'+(record?'◡':'?')+'</span><h3>'+escapeHtml(record?f.name:'尚未发现')+'</h3><p>'+(record?escapeHtml(rarity[f.rarity])+' · 捕获 '+record.count+' 次':'等待一次惊喜相遇')+'</p><small>'+(record?'最大体长 '+record.recordCm+' cm':'???')+'</small></article>';}).join('')+'</div>';return;
 }
 if(!current.aquarium.length){el('panel').innerHTML='<div class="empty">鱼缸还很安静。<p>收杆后选择「收进鱼缸」，邀请第一位朋友住进来。</p></div>';return;}
 el('panel').innerHTML='<div class="cards">'+current.aquarium.map(c=>'<article class="card"><span class="fish-icon" aria-hidden="true">◡</span><h3>'+escapeHtml(fishName(c))+'</h3><p>'+c.lengthCm+' cm</p><button data-catch="'+escapeHtml(c.catchId)+'">'+(replacement?'替换这条鱼':'放生')+'</button></article>').join('')+'</div>';
 el('panel').querySelectorAll('[data-catch]').forEach(button=>{
  button.disabled=inFlight||current.blocked;
  button.onclick=()=>{
   const id=button.dataset.catch,old=current.aquarium.find(c=>c.catchId===id);if(!old)return;
   if(replacement){
    if(!current.pendingCatch)return;
    ask('确认替换？','将放生 '+fishName(old)+'（'+old.lengthCm+' cm），让本次鱼获住进来。图鉴纪录仍会保留。',async()=>{const result=await act(()=>window.fishing.settle({action:'replace',targetId:id}));if(result?.ok){replacement=false;panelKey=null;renderPanel();el('collection').close();}});
   }else ask('放生鱼缸里的鱼？',fishName(old)+'（'+old.lengthCm+' cm）将离开鱼缸，图鉴纪录会保留。',()=>act(()=>window.fishing.remove(id)));
  };
 });
}
el('cast').onclick=()=>act(()=>window.fishing.cast());el('reel').onclick=()=>act(()=>window.fishing.reel());
el('book').onclick=()=>current&&openPanel('book');el('tank').onclick=()=>current&&openPanel('tank');
el('close-panel').onclick=()=>el('collection').close();
el('confirm-cancel').onclick=()=>{confirmAction=null;el('confirmation').close();};
el('confirmation').addEventListener('cancel',()=>{confirmAction=null;});
el('confirm-ok').onclick=()=>{const action=confirmAction;confirmAction=null;el('confirmation').close();action?.();};
window.fishing.subscribe(draw);window.fishing.state().then(draw).catch(()=>{el('notice').textContent='无法载入游戏状态，请重新启动。';});
