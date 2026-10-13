const {contextBridge,ipcRenderer}=require('electron');
contextBridge.exposeInMainWorld('fishing',{
 state:()=>ipcRenderer.invoke('game:state'),
 cast:()=>ipcRenderer.invoke('game:cast'),
 reel:()=>ipcRenderer.invoke('game:reel'),
 settle:request=>ipcRenderer.invoke('game:settle',request),
 remove:id=>ipcRenderer.invoke('game:aquarium-remove',id),
 subscribe:callback=>{const listener=(_event,state)=>callback(state);ipcRenderer.on('game:state',listener);return ()=>ipcRenderer.removeListener('game:state',listener);}
});
